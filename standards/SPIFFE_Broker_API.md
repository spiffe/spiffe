# The SPIFFE Broker API

## Status of this Memo

This document specifies an identity API standard for the internet community, and requests discussion and suggestions for improvements. Distribution of this document is unlimited.

## Abstract

Brokers are trusted infrastructure components that can act on-behalf-of workloads. This API enables them to retrieve the SVIDs and trust bundles of workloads it represents by referencing the workloads by its process ID.

## Table of Contents

1\. [Introduction](#1-introduction)  
2\. [Extensibility](#2-extensibility)  
3\. [Service Definition](#3-service-definition)  
4\. [Client and Server Behavior](#4-client-and-server-behavior)  
4.1. [Identifying the Caller](#41-identifying-the-caller)  
4.2. [Connection Lifetime](#42-connection-lifetime)  
4.3. [Stream Responses](#43-stream-responses)  
4.4. [Default Values and Redacted Information](#44-default-values-and-redacted-information)  
4.5. [Mandatory Fields](#45-mandatory-fields)  
4.6. [Federated Bundles](#46-federated-bundles)  
5\. [X.509-SVID Profile](#5-x509-svid-profile)  
5.1. [Profile Definition](#51-profile-definition)  
5.2. [Profile RPCs](#52-profile-rpcs)  
5.3. [Default Identity](#53-default-identity)  
6\. [JWT-SVID Profile](#6-jwt-svid-profile)  
6.1. [Profile Definition](#61-profile-definition)  
6.2. [Profile RPCs](#62-profile-rpcs)  
6.3. [JWT-SVID Validation](#63-jwt-svid-validation)  

## 1. Introduction

The SPIFFE Broker API enables Brokers to retrieve SVIDs and bundles for workloads they represent. It is served by the [SPIFFE Broker Endpoint](SPIFFE_Broker_Endpoint.md), and comprises a number of services, or *profiles*.

Currently, there are two profiles:

- [X.509-SVID Profile](#5-x509-svid-profile)
- [JWT-SVID Profile](#6-jwt-svid-profile)

Both profiles are mandatory and MUST be supported by SPIFFE implementations. However, operators MAY administratively disable a specific profile in their deployment.

Future versions of this specification may introduce additional profiles or make one or more profiles optional.

## 2. Extensibility

Extending the SPIFFE Broker API outside of the standard is prohibited and instead, implementers should introduce new gRPC services, according to the [extensibility method](./SPIFFE_Broker_Endpoint.md#7-extensibility-and-services-rendered) outlined in the SPIFFE Broker Endpoint specification.

## 3. Service Definition

The SPIFFE Broker API is defined by a Protocol Buffer (version 3) service definition. The complete definition is found in [brokerapi.proto](brokerapi.proto).

Profiles are implemented as a group of related RPCs within a single `API` service in the `spiffe.broker` package.

## 3.1 Workload Reference

The SPIFFE Broker API requires a mechanism to identify the entity for which the
server should issue an SVID. This reference system enables Brokers to request
identity materials on behalf of specific entities while maintaining proper
isolation and security boundaries.

References fall into two broad categories:

* **Local references** identify a running process co-located with the Broker
  (e.g., process ID). They are only meaningful in the local execution
  environment and have a process-like lifecycle.
* **Object references** identify an addressable object in a control plane that
  represents an identity (e.g., a Kubernetes object). They are valid across the
  scope of that control plane (e.g., the cluster) and have a lifecycle tied to
  the object's existence in that control plane.

Throughout this specification, "workload" is used as a shorthand for the entity
that the reference resolves to, regardless of whether that entity is a running
process or a control-plane object.

References MUST satisfy the following requirements:

* Uniqueness: Each reference MUST uniquely identify a single entity within its
  applicable scope (the local node for local references; the relevant control
  plane for object references) at any given time
* Scope: Local references MUST NOT be used across network boundaries or
  different nodes; object references MUST NOT be used across control planes
  (e.g., across Kubernetes clusters)
* Dereferenceability: The server MUST be able to verify that the referenced
  entity exists and is accessible for identity operations

### 3.1.1 Reference Resolution

Each request message in the SPIFFE Broker API carries exactly one workload reference. Clients MUST provide a reference; servers MUST reject requests that lack one or whose reference type is not understood by the server.

References MUST be resolved on the server and the server MUST verify the existence
of the referenced workload.

Servers MUST NOT trust reference data provided by the client without independent
verification. For example, when a client provides a PID reference, the server SHOULD
independently verify the process exists and collect workload identity attributes
through secure channels (e.g., /proc filesystem, container runtime APIs) rather than
accepting client-provided attributes at face value.

### 3.1.2 Reference scope

Some references — such as the process ID — are only meaningful and discoverable
on the local node. Clients MUST ensure that local references are not sent to
remote Broker APIs and servers MUST deny requests originating from outside the
node that contain local references. This mitigates situations where a Broker
requests credentials with a process ID from a different node, where that
process ID is used by a different workload.

Object references (such as `KubernetesObjectReference`) are valid across the
control plane that owns the referenced object — for example, anywhere within
the same Kubernetes cluster — and MAY be sent across the network within that
scope. Object references MUST NOT be honored by a server bound to a different
control plane (e.g., a different cluster); servers MUST reject object
references that name a control plane they do not serve.

### 3.1.3 Builtin Reference Types

The specification currently defines two builtin workload reference types.

**Process ID (PID) Reference**: Identifies a workload by its process identifier. The PID MUST be a positive integer. This reference type is universally supported across POSIX-compliant systems.

Example:
```protobuf
WorkloadReference {
  reference: Any {
    type_url: "type.googleapis.com/WorkloadPIDReference"
    value: <packed WorkloadPIDReference { pid: 1234 }>
  }
}
```

**Kubernetes Object Reference**: Identifies a workload by an arbitrary Kubernetes
object — built-in or custom — for which the server is expected to issue an SVID.
The `resource` field MUST be set to `<plural>.<group>` for non-core API groups, or
`<plural>` for the core API group. This is the same format accepted by `kubectl`
and used as the name of `CustomResourceDefinition` objects in the Kubernetes API.
At least one of `name` or `uid` MUST be specified; when both are specified together
with `namespace` (for namespaced resources), the server MUST verify that the
object resolved by name has the specified UID at the time of issuing the SVIDs and
MUST return an error otherwise. `namespace` MUST be set when `name` is set on a
namespaced resource. `namespace` MUST NOT be set when `name` is not set
(a namespace alone does not identify any object; the server resolves the
namespace from the UID when the object is identified by `uid` alone).
`namespace` MUST be empty when the resource is cluster-scoped.

This single reference type covers a range of Kubernetes identification patterns
that earlier drafts of this specification expressed with multiple dedicated
reference messages. In particular, identifying a Pod by its UID alone — a
common pattern for Brokers running alongside the Kubernetes runtime that
already know the pod UID but not its namespaced name — is expressed by setting
`resource = "pods"` and `uid = <pod uid>` (with `name` and `namespace` left
empty); see the corresponding example below.

The advantages of using `<plural>.<group>` for the `resource` field are:

- It is a well-known format that Kubernetes users are familiar with from `kubectl` commands.
- It is the exact name of `CustomResourceDefinition` objects in the Kubernetes API.
- It does not contain uppercase letters, fitting naturally into URIs (such as a SPIFFE ID, when a runtime chooses to embed the resource in the path).
- It can be split into the `<plural>` and `<group>` components and relayed to a
  `SubjectAccessReview` request without additional lookups (e.g. mapping `Kind` to
  `<plural>`).

Note that SPIFFE does not specify how runtimes should attest workloads referenced
by a `KubernetesObjectReference`, but this design facilitates implementations that
choose to attest via the recommended `SubjectAccessReview` API in Kubernetes.

The mapping from a Kubernetes object to a SPIFFE ID is implementation-defined;
this specification does not mandate a particular SPIFFE ID format. A RECOMMENDED
default — used in the examples below — is
`spiffe://<trust domain>/<resource>/<namespace>/<name>` for namespaced resources
and `spiffe://<trust domain>/<resource>/<name>` for cluster-scoped resources.
Runtimes MAY use other formats to satisfy ecosystem conventions or stronger
identity guarantees:

- **Istio-style**: `spiffe://<trust domain>/ns/<namespace>/sa/<serviceaccount>`.
  An Istio-aligned implementation that attests workloads referenced by a
  `KubernetesObjectReference` (resource = `serviceaccounts`) would naturally
  emit this format.
- **UID-suffixed**: `spiffe://<trust domain>/<resource>/<namespace>/<name>/<uid>`
  (or a similar variant). Appending the object's UID disambiguates successive
  incarnations of the same `<namespace>/<name>` (e.g., a Pod that was deleted
  and recreated, or a CRD instance recreated with the same name): each
  incarnation gets a distinct SPIFFE ID, and a relying party policy granting
  trust to the older incarnation does not automatically transfer to the new
  one. This is a stronger guarantee than name-only formats but produces
  longer-lived audit trails of past UIDs in policy.

Regardless of the exact format chosen, operators are strongly encouraged to
choose trust domains that identify a specific Kubernetes cluster (for example,
by encoding the cluster name in the trust domain). The path portion of the
SPIFFE ID — whether `<resource>/<namespace>/<name>`, `ns/<namespace>/sa/<sa>`,
or anything else — is not globally unique; it is normal for the same path to
exist in multiple clusters. The trust domain is the only component that
distinguishes otherwise identical SPIFFE IDs across clusters. Encoding the
cluster in the trust domain allows relying parties to decide, on a per-cluster
basis, which SVIDs to accept (for example, by federating with only a subset of
cluster trust domains).

Examples — references and the corresponding SPIFFE ID under the recommended
default format, assuming a trust domain of `prod-us-east.k8s.example.com`
(a trust domain dedicated to a specific Kubernetes cluster):

Namespaced core resource (Pod) by name and UID:
```protobuf
WorkloadReference {
  reference: Any {
    type_url: "type.googleapis.com/KubernetesObjectReference"
    value: <packed KubernetesObjectReference {
      resource: "pods"
      namespace: "shop"
      name: "checkout-7c9f"
      uid: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    }>
  }
}
```
SPIFFE ID: `spiffe://prod-us-east.k8s.example.com/pods/shop/checkout-7c9f`

Pod by UID only — the common case for Brokers that observe pod UIDs from the
Kubernetes runtime but do not have the pod's namespaced name handy. The server
resolves the pod by UID and derives the namespace and name when emitting the
SPIFFE ID:
```protobuf
WorkloadReference {
  reference: Any {
    type_url: "type.googleapis.com/KubernetesObjectReference"
    value: <packed KubernetesObjectReference {
      resource: "pods"
      uid: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    }>
  }
}
```
SPIFFE ID: resolved by the server from the UID, e.g.
`spiffe://prod-us-east.k8s.example.com/pods/shop/checkout-7c9f`

Namespaced non-core resource (Deployment) by namespaced name only:
```protobuf
WorkloadReference {
  reference: Any {
    type_url: "type.googleapis.com/KubernetesObjectReference"
    value: <packed KubernetesObjectReference {
      resource: "deployments.apps"
      namespace: "shop"
      name: "checkout"
    }>
  }
}
```
SPIFFE ID: `spiffe://prod-us-east.k8s.example.com/deployments.apps/shop/checkout`

Namespaced ServiceAccount by namespaced name (a common identity anchor for
workloads in Kubernetes):
```protobuf
WorkloadReference {
  reference: Any {
    type_url: "type.googleapis.com/KubernetesObjectReference"
    value: <packed KubernetesObjectReference {
      resource: "serviceaccounts"
      namespace: "shop"
      name: "checkout"
    }>
  }
}
```
SPIFFE ID: `spiffe://prod-us-east.k8s.example.com/serviceaccounts/shop/checkout`

Namespaced custom resource (Flux Kustomization) by UID only:
```protobuf
WorkloadReference {
  reference: Any {
    type_url: "type.googleapis.com/KubernetesObjectReference"
    value: <packed KubernetesObjectReference {
      resource: "kustomizations.kustomize.toolkit.fluxcd.io"
      uid: "0fa1b2c3-4d5e-6f70-8192-a3b4c5d6e7f8"
    }>
  }
}
```
SPIFFE ID: resolved by the server from the UID, e.g.
`spiffe://prod-us-east.k8s.example.com/kustomizations.kustomize.toolkit.fluxcd.io/flux-system/apps`

Cluster-scoped core resource (Node) by name:
```protobuf
WorkloadReference {
  reference: Any {
    type_url: "type.googleapis.com/KubernetesObjectReference"
    value: <packed KubernetesObjectReference {
      resource: "nodes"
      name: "ip-10-0-1-42.ec2.internal"
    }>
  }
}
```
SPIFFE ID: `spiffe://prod-us-east.k8s.example.com/nodes/ip-10-0-1-42.ec2.internal`

### 3.1.4 Extensibility

The SPIFFE Broker API is designed to support additional reference types without modification to the protocol definition. The `WorkloadReference.reference` field uses `google.protobuf.Any`, allowing any message type to be packed and used as a reference.

Standard reference types defined by this specification can be packed into the Any field. Implementations MAY define and use vendor-specific or implementation-specific reference types by packing their custom message types into the Any field.

Implementations extending the reference types SHOULD document their extensions, including the fully-qualified type name used in the Any field, to avoid conflicts with other implementations. Servers that receive a reference type they do not recognize MUST reject the request with an InvalidArgument status.

## 4. Client and Server Behavior

### 4.1 Authenticating and authorizing the Caller

The SPIFFE Broker API makes use of the authentication and authorization at the [SPIFFE Broker Endpoint](./SPIFFE_Broker_Endpoint.md#5-authentication-and-authorization) to identify and authorize the caller.

Implementations MUST maintain a strict allow-only policy that prevents any caller that is not authorized to leverage the SPIFFE Broker API.

### 4.2 Remote procedure scope

Every invocation of a remote procedure (RPC) at the SPIFFE Broker API, including its request and responses (potentially multiple), are in context of a concrete workload. Clients are expected to invoke RPCs for each workload they represent individually and isolate them for each other accordingly. An X509 Bundle response, for instance, is only valid for the workload the request has referenced and MUST NOT be applied, visible or in any other way impact other workloads. Same applies to all other RPCs in the scope of the SPIFFE Broker API.

If multiple workloads communicate with each other, and the client of the SPIFFE Broker API is involved, it MUST ensure that the corresponding certificates are accordingly separated. For instance, the SVID and bundle of the client is only used for client-side operations, and the SVID and bundle of the server is only used for server-side operations.

### 4.3 Connection Lifetime

Clients of the SPIFFE Broker API SHOULD maintain an open connection for as long as is reasonably possible, waiting on server response messages to be received on the stream. The connection may, at any time, be terminated by either the server or the client. In this case, the client SHOULD immediately establish a new connection. This helps ensure that the client and the workloads it represents retain the most up-to-date set of identity related materials. SPIFFE Broker API server implementers may assume this property, and by not receiving messages in a timely manner, the client may fall out-of-date, potentially impacting its availability.

Compared to the SPIFFE Workload API, the connection between server and client can exist beyond the lifecycle of a workload the client represents. While the SPIFFE Workload API closes the connection, the SPIFFE Broker API only terminates a specific invocation of an RPC within it. The connection between server and client itself can remain open as it handles multiple invocations representing various workloads.

### 4.4 Stream Responses

The SPIFFE Broker API includes RPCs utilizing gRPC server-side streams in order to facilitate rapid propagation of updates, for instance changes to the bundles. This enables clients to loop over server responses, accepting updated responses as they occur.

Every stream response message sent by the server MUST include the full set of information, and not just the information which has changed. This only covers the workload referenced in the corresponding request and not other workloads. See [remote procedure scope](#42-remote-procedure-scope) for details.

The exact timing of server response messages is implementation-specific, and SHOULD be dictated by events which change the response, such as an SVID rotation. Receiving a request message from the client MUST be considered a response-generating event. In other words, the first response message of the server response stream (on a connection-by-connection basis) MUST be sent as soon as possible, without delay.

Finally, implementers of SPIFFE Broker API servers should be careful about pushing updated response messages *too* rapidly. Some software may reload automatically upon receiving new information, potentially causing a period of unavailability should all instances reload at once. As a result, implementers may introduce some splay/jitter in the transmission of widespread updates.

### 4.5 Default Values and Redacted Information

Clients and servers MUST implement the same default values behavior as described in section 4.4 of the [SPIFFE Workload API](./SPIFFE_Workload_API.md).

### 4.6 Mandatory Fields

Messages exchanged for the profile RPCs are comprised of both mandatory and optional fields. Servers receiving a message in which a mandatory field has a default value SHOULD respond with the "InvalidArgument" gRPC status code (see the [Error Codes](SPIFFE_Broker_Endpoint.md#6-error-codes) section in the SPIFFE Broker Endpoint specification for more information). Clients receiving a message in which a mandatory field has a default value SHOULD report an error and discard the message.

### 4.7 Federated Bundles

Response messages of the SPIFFE Broker API contain federated bundles. The usage and expected client behavior MUST be the same as described in section 4.6 of the [SPIFFE Workload API](./SPIFFE_Workload_API.md).

It is important to highlight that bundles MUST only be used in the context of the workload that was referenced in the corresponding request as described in [Section 4.2 Remote Procedure Scope](#42-remote-procedure-scope) and [Section 4.4 Stream Responses](#44-stream-responses) of this specification.

### 4.8 Workload References and SVID entitlements

Implementations MUST validate that the workload reference points to an existing, accessible workload before processing any identity requests. The server MUST return appropriate gRPC status codes to indicate different failure conditions:

| Situation | gRPC Status Code | google.rpc.ErrorInfo.reason |
|-----------|------------------|------------------------------|
| The request omits the reference, or the reference is malformed or invalid (e.g., negative PID) | InvalidArgument | WORKLOAD_REFERENCE_INVALID |
| The referenced workload does not exist or cannot be found | NotFound | WORKLOAD_NOT_FOUND |
| The referenced workload exists but is not entitled to receive an SVID or bundle | PermissionDenied | WORKLOAD_NOT_ENTITLED |

Servers SHOULD include `google.rpc.ErrorInfo` details with the error response containing:
- `reason`: One of the error reasons specified in the table above
- `domain`: "spiffe.io"
- `metadata`: Optional contextual information such as the PID value or other debugging details

Clients MAY inspect ErrorInfo details for structured error information but MUST handle cases where only the status code is available.

### 4.9 Workload Lifecycle

Both server and client MUST monitor the state of the workload and ensure that no operations are performed beyond the lifetime of the workload. For instance, the server MUST not send responses to the client once the workload has stopped. Clients on the other hand MUST drop all the data received for the workload, removing it from file systems or other locations it potentially have stored it in addition.

What constitutes "stopped" depends on the reference type. For local references
(such as a process ID), the workload is considered stopped when the underlying
process terminates. For object references (such as a
`KubernetesObjectReference`), the workload is considered stopped when the
referenced object no longer exists in the control plane, or — when the
reference pinned a UID alongside a name — when the object resolved by name no
longer matches the pinned UID.

## 5. X.509-SVID Profile

The X.509-SVID Profile of the SPIFFE Broker API provides a set of gRPC methods which can be used by Brokers to retrieve [X.509-SVIDs](X509-SVID.md) and their related trust bundles on behalf of workloads. This profile outlines the signature of these methods, as well as related client and server behavior.

### 5.1 Profile Definition

The X.509-SVID Profile RPCs and associated messages are defined below. For the complete Broker API service definition, see [brokerapi.proto](brokerapi.proto).

```protobuf
service API {
    /////////////////////////////////////////////////////////////////////////
    // X509-SVID Profile
    /////////////////////////////////////////////////////////////////////////

    // Fetch X.509-SVIDs for all SPIFFE identities the referenced workload is
    // entitled to, as well as related information like trust bundles. As this
    // information changes, subsequent messages will be streamed from the server.
    rpc SubscribeToX509SVID(SubscribeToX509SVIDRequest) returns (stream SubscribeToX509SVIDResponse);

    // Fetch trust bundles of the referenced workload. Useful in situations that
    // only need to validate SVIDs without obtaining an SVID for themself. As this
    // information changes, subsequent messages will be streamed from the server.
    rpc SubscribeToX509Bundles(SubscribeToX509BundlesRequest) returns (stream SubscribeToX509BundlesResponse);

    // ... RPCS for other profiles ...
}

// The WorkloadReference message represents a single reference to a workload.
message WorkloadReference {
    // Required. The reference to the workload.
    google.protobuf.Any reference = 1;
}

// The WorkloadPIDReference message conveys a process id reference of a workload.
message WorkloadPIDReference {
    // Required. The process id of the workload.
    int32 pid = 1;
}

// The SubscribeToX509SVIDRequest message conveys parameters for requesting an X.509-SVID.
message SubscribeToX509SVIDRequest {
    // Required. The reference identifying the workload.
    WorkloadReference reference = 1;
}

// The SubscribeToX509SVIDResponse message carries X.509-SVIDs and related information,
// including a list of bundles the workload may use for federating with foreign
// trust domains.
message SubscribeToX509SVIDResponse {
    // Required. A list of X509SVID messages, each of which includes a single
    // X.509-SVID, its private key, and the bundle for the trust domain.
    repeated X509SVID svids = 1;

    // Optional. ASN.1 DER encoded certificate revocation lists.
    repeated bytes crl = 2;

    // Optional. CA certificate bundles belonging to foreign trust domains that
    // the workload should trust, keyed by the SPIFFE ID of the foreign trust
    // domain. Bundles are ASN.1 DER encoded.
    map<string, bytes> federated_bundles = 3;
}

// The X509SVID message carries a single SVID and all associated information,
// including the X.509 bundle for the trust domain.
message X509SVID {
    // Required. The SPIFFE ID of the SVID in this entry
    string spiffe_id = 1;

    // Required. ASN.1 DER encoded certificate chain. MAY include
    // intermediates, the leaf certificate (or SVID itself) MUST come first.
    bytes x509_svid = 2;

    // Required. ASN.1 DER encoded PKCS#8 private key. MUST be unencrypted.
    bytes x509_svid_key = 3;

    // Required. ASN.1 DER encoded X.509 bundle for the trust domain.
    bytes bundle = 4;

    // Optional. An operator-specified string used to provide guidance on how this
    // identity should be used by a workload when more than one SVID is returned.
    // For example, `internal` and `external` to indicate an SVID for internal or
    // external use, respectively.
    string hint = 5;
}

// The SubscribeToX509BundlesRequest message conveys parameters for requesting X.509
// bundles.
message SubscribeToX509BundlesRequest {
    // Required. The reference identifying the workload.
    WorkloadReference reference = 1;
}

// The SubscribeToX509BundlesResponse message carries a map of trust bundles the workload
// should trust.
message SubscribeToX509BundlesResponse {
    // Optional. ASN.1 DER encoded certificate revocation lists.
    repeated bytes crl = 1;

    // Required. CA certificate bundles belonging to trust domains that the
    // workload should trust, keyed by the SPIFFE ID of the trust domain.
    // Bundles are ASN.1 DER encoded.
    map<string, bytes> bundles = 2;
}
```

### 5.2 Profile RPCs

#### 5.2.1 SubscribeToX509SVID

The `SubscribeToX509SVID` RPC enables Brokers to retrieve X509-SVIDs and X.509 bundles on behalf of a referenced workload via a streaming response. The returned materials are workload-specific and MUST only be used for operations involving that particular workload. Brokers MUST NOT use these SVIDs or bundles for any other workload or purpose.

The `SubscribeToX509SVIDRequest` request message contains a mandatory workload reference.

The `SubscribeToX509SVIDResponse` response consists of a mandatory `svids` field, which MUST contain one or more `X509SVID` messages (one for each identity granted to the client, on-behalf of the workload). The `federated_bundles` field is optional.

All fields in the `X509SVID` message are mandatory, with the exception of the `hint` field. When the `hint` field is set (i.e. non-empty), SPIFFE Broker API servers MUST ensure its value is unique amongst the set of returned SVIDs in any given `SubscribeToX509SVIDResponse` message. In the event that a client receives more than one `X509SVID` message with the same `hint` value set, then the first message in the list SHOULD be selected.

If the referenced workload does not exist or is not entitled to receive any X509-SVIDs, then the server MUST respond with an appropriate gRPC status code as specified in [Section 4.8](#48-workload-references-and-svid-entitlements). Under such a case, the Broker MAY attempt to reconnect with another call to the `SubscribeToX509SVID` RPC after a backoff.

As mentioned in [Stream Responses](#43-stream-responses), each `SubscribeToX509SVIDResponse` message returned on the `SubscribeToX509SVID` stream contains the complete set of authorized SVIDs and bundles of the workload at that point in time. As such, if the server redacts SVIDs from a subsequent response that was in context of the referenced workload the Broker SHOULD cease using the redacted SVIDs. This includes situations where the server returns a Permission denied, where the Broker is expected to drop all previous received SVIDs and bundles.

#### 5.2.2 SubscribeToX509Bundles

The `SubscribeToX509Bundles` RPC streams back X.509 bundles for the workload to the Broker. These bundles MUST only be used to authenticate X509-SVIDs and MUST only be used for operations involving the referenced workload. They MUST not be used for any other workload.

The `SubscribeToX509BundlesRequest` request message contains a mandatory workload reference.

The `SubscribeToX509BundlesResponse` response message has a mandatory `bundles` field, which MUST contain at least the trust bundle for the trust domain in which the server resides.

If the referenced workload does not exist or is not entitled to receive any X.509 bundles, then the server MUST respond with an appropriate gRPC status code as specified in [Section 4.8](#48-workload-references-and-svid-entitlements). Under such a case, the Broker MAY attempt to reconnect with another call to the `SubscribeToX509Bundles` RPC after a backoff.

As mentioned in [Stream Responses](#43-stream-responses), each `SubscribeToX509BundlesResponse` response contains the complete set of authorized X.509 bundles of the workload at that point in time. As such, if the server redacts bundles from a subsequent response that was in context of the referenced workload the Broker SHOULD cease using the bundles. This includes situations where the server returns a Permission denied, where the Broker is expected to drop all previous received bundles.

### 5.3 Default Identity

Servers and clients of Broker API are expected to follow the behavior as defined in section 5.3 of the [SPIFFE Workload API](./SPIFFE_Workload_API.md#53-default-identity) when multiple identities are returned.

The Broker is expected to use the default identity in situations where it cannot determine the expected usage and is not able to deliver multiple identities to the workload. When it is able to deliver multiple identities to workloads it MUST identify these identities with their corresponding `hint` as delivered by the SPIFFE Broker API and clients MUST be able to use these identifiers to identify identities.

## 6. JWT-SVID Profile

The JWT-SVID Profile of the SPIFFE Broker API provides a set of gRPC methods which can be used by a Broker to retrieve JWT-SVIDs and their related trust bundles on behalf of workloads. This profile outlines the signature of these methods, as well as related client and server behavior.

### 6.1 Profile Definition

The JWT-SVID Profile RPCs and associated messages are defined below. For the complete Broker API service definition, see [brokerapi.proto](brokerapi.proto).

```protobuf
service API {
    /////////////////////////////////////////////////////////////////////////
    // JWT-SVID Profile
    /////////////////////////////////////////////////////////////////////////

    // Fetch JWT-SVIDs for all SPIFFE identities the referenced workload is
    // entitled to, for the requested audience. If an optional SPIFFE ID is
    // requested, only the JWT-SVID for that SPIFFE ID is returned.
    rpc FetchJWTSVID(FetchJWTSVIDRequest) returns (FetchJWTSVIDResponse);

    // Fetches the JWT bundles, formatted as JWKS documents, keyed by the
    // SPIFFE ID of the trust domain. As this information changes, subsequent
    // messages will be streamed from the server.
    rpc SubscribeToJWTBundles(SubscribeToJWTBundlesRequest) returns (stream SubscribeToJWTBundlesResponse);

    // ... RPCs for other profiles ...
}

// The WorkloadReference message represents a single reference to a workload.
message WorkloadReference {
    // Required. The reference to the workload.
    google.protobuf.Any reference = 1;
}

// The WorkloadPIDReference message conveys a process id reference of a workload.
message WorkloadPIDReference {
    // Required. The process id of the workload.
    int32 pid = 1;
}

// The FetchJWTSVIDRequest message conveys parameters for requesting JWT-SVIDs.
message FetchJWTSVIDRequest {
    // Required. The reference identifying the workload.
    WorkloadReference reference = 1;

    // Required. The audience(s) the workload intends to authenticate against.
    repeated string audience = 2;

    // Optional. The requested SPIFFE ID for the JWT-SVID. If unset, all
    // JWT-SVIDs to which the workload is entitled are requested.
    string spiffe_id = 3;
}

// The FetchJWTSVIDResponse message conveys JWT-SVIDs.
message FetchJWTSVIDResponse {
    // Required. The list of returned JWT-SVIDs.
    repeated JWTSVID svids = 1;
}

// The JWTSVID message carries the JWT-SVID token and associated metadata.
message JWTSVID {
    // Required. The SPIFFE ID of the JWT-SVID.
    string spiffe_id = 1;

    // Required. Encoded JWT using JWS Compact Serialization.
    string svid = 2;

    // Optional. An operator-specified string used to provide guidance on how this
    // identity should be used by a workload when more than one SVID is returned.
    // For example, `internal` and `external` to denote an SVID for internal or
    // external use, respectively.
    string hint = 3;
}

// The SubscribeToJWTBundlesRequest message conveys parameters for requesting JWT bundles.
message SubscribeToJWTBundlesRequest {
    // Required. The reference identifying the workload.
    WorkloadReference reference = 1;
}

// The SubscribeToJWTBundlesResponse message conveys JWT bundles.
message SubscribeToJWTBundlesResponse {
    // Required. JWK encoded JWT bundles, keyed by the SPIFFE ID of the trust
    // domain.
    map<string, bytes> bundles = 1;
}
```

### 6.2 Profile RPCs

#### 6.2.1 FetchJWTSVID

The `FetchJWTSVID` RPC allows a Broker to request one or more short-lived JWT-SVIDs with a specific audience for a workload.

The `FetchJWTSVIDRequest` request message contains a mandatory workload reference. It also contains a mandatory `audience` field, which MUST contain the value to embed in the audience claim of the returned JWT-SVIDs. The `spiffe_id` field is optional, and is used to request a JWT-SVID for a specific SPIFFE ID. If unspecified, the server MUST return JWT-SVIDs for all identities authorized for the workload.

The `FetchJWTSVIDResponse` response message consists of a mandatory `svids` field, which MUST contain one or more `JWTSVID` messages.

All fields in the `JWTSVID` message are mandatory, with the exception of the `hint` field. When the `hint` field is set (i.e. non-empty), SPIFFE Broker API servers MUST ensure its value is unique amongst the set of returned SVIDs in any given `FetchJWTSVIDResponse` message. In the event that a SPIFFE Broker API client encounters more than one `JWTSVID` message with the same `hint` value set, then the first message in the list SHOULD be selected.

If the referenced workload does not exist or is not entitled to receive any JWT-SVIDs, then the server MUST respond with an appropriate gRPC status code as specified in [Section 4.8](#48-workload-references-and-svid-entitlements). Under such a case, the Broker MAY attempt to reconnect with another call to the `FetchJWTSVID` RPC after a backoff.

#### 6.2.2 SubscribeToJWTBundles

The `SubscribeToJWTBundles` RPC streams back JWT bundles for the workload to the Broker. These bundles MUST only be used to authenticate JWT-SVIDs and MUST only be used for operations involving the referenced workload. They MUST NOT be used for any other workload.

The `SubscribeToJWTBundlesRequest` request message contains a mandatory workload reference.

The `SubscribeToJWTBundlesResponse` response message consists of a mandatory `bundles` field, which MUST contain at least the JWT bundle for the trust domain in which the server resides.

The returned bundles are encoded as a standard JWK Set as defined by [RFC 7517](https://tools.ietf.org/html/rfc7517) containing the JWT-SVID signing keys for the trust domain. These keys may only represent a subset of the keys present in the SPIFFE trust bundle for the trust domain. The server MUST NOT include keys with other uses in the returned JWT bundles.

If the referenced workload does not exist or is not entitled to receive any JWT bundles, then the server MUST respond with an appropriate gRPC status code as specified in [Section 4.8](#48-workload-references-and-svid-entitlements). Under such a case, the Broker MAY attempt to reconnect with another call to the `SubscribeToJWTBundles` RPC after a backoff.

As mentioned in [Stream Responses](#43-stream-responses), each `SubscribeToJWTBundlesResponse` response contains the complete set of authorized JWT bundles of the workload at that point in time. As such, if the server redacts bundles from a subsequent response that was in context of the referenced workload the Broker SHOULD cease using the redacted bundles. This includes situations where the server returns a Permission denied, where the Broker is expected to drop all previous received bundles.

## Appendix A. Sample Implementation State Machines

### Workload State Machine

1. The workload is starting
2. The workload is making a request to a peer workload.
3. The request is re-routed to a egress gateway on the same node. Broker steps 1-6 are followed.
4. The egress gateway returns the response of the peer workload.

### Broker State Machine

1. The broker is observing a request from a new workload
2. The broker identifies the workload by the process ID that has made the request
3. The broker requests an X.509-SVID from the Broker API using the process ID (PID) as a reference. SPIFFE Server State steps 1-6 are followed.
4. The Broker API responds with an X.509-SVID and corresponding bundle for the workload
5. The broker makes the request to the peer workload using the X.509-SVID and bundle as authentication artifacts.
6. The broker returns the response from the peer workload to the workload that has made the request.

### SPIFFE Server State Machine

1. The SPIFFE server is receiving the request from the Broker with the workloads PID reference
2. The SPIFFE server identifies the broker, authenticating and authorising it as a trusted infrastructure component that is allowed to use the Broker API
3. The SPIFFE server uses the PID reference to locate the process.
4. The SPIFFE server uses the located process to collect attributes of the workload. This may include container and container platform attributes.
5. The SPIFFE server uses collected attributes to authenticate the workload and issues an X.509-SVID
6. The SPIFFE server returns the X.509-SVID and corresponding bundle belonging to the workload