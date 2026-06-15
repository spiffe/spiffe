# The SPIFFE Broker API

> [!IMPORTANT]
> **New in June 2026** — The Broker API is a new addition to the SPIFFE
> specification. Users and implementers should confirm implementation
> compatibility within their environment before adoption.

## Status of this Memo

This document specifies an identity API standard for the internet community, and requests discussion and suggestions for improvements. Distribution of this document is unlimited.

## Abstract

Brokers are trusted infrastructure components that can act on-behalf-of workloads. This API enables them to retrieve the SVIDs and trust bundles of workloads they represent by referencing each workload with a workload reference (for example, a process ID or a Kubernetes object).

## Table of Contents

1\. [Introduction](#1-introduction)  
2\. [Extensibility](#2-extensibility)  
3\. [Service Definition](#3-service-definition)  
3.1. [Workload Reference](#31-workload-reference)  
3.1.1. [Reference Resolution](#311-reference-resolution)  
3.1.2. [Reference scope](#312-reference-scope)  
3.1.3. [Builtin Reference Types](#313-builtin-reference-types)  
3.1.4. [Extensibility](#314-extensibility)  
4\. [Client and Server Behavior](#4-client-and-server-behavior)  
4.1. [Authenticating and authorizing the Caller](#41-authenticating-and-authorizing-the-caller)  
4.2. [Remote procedure scope](#42-remote-procedure-scope)  
4.3. [Connection Lifetime](#43-connection-lifetime)  
4.4. [Stream Responses](#44-stream-responses)  
4.5. [Default Values and Redacted Information](#45-default-values-and-redacted-information)  
4.6. [Mandatory Fields](#46-mandatory-fields)  
4.7. [Federated Bundles](#47-federated-bundles)  
4.8. [Workload References and SVID entitlements](#48-workload-references-and-svid-entitlements)  
4.9. [Workload Lifecycle](#49-workload-lifecycle)  
5\. [X.509-SVID Profile](#5-x509-svid-profile)  
5.1. [Profile Definition](#51-profile-definition)  
5.2. [Profile RPCs](#52-profile-rpcs)  
5.3. [Default Identity](#53-default-identity)  
6\. [JWT-SVID Profile](#6-jwt-svid-profile)  
6.1. [Profile Definition](#61-profile-definition)  
6.2. [Profile RPCs](#62-profile-rpcs)  
Appendix A. [Sample Implementation State Machines](#appendix-a-sample-implementation-state-machines)  

## 1. Introduction

The SPIFFE Broker API enables Brokers to retrieve SVIDs and bundles for workloads they represent. It is served by the [SPIFFE Broker Endpoint](SPIFFE_Broker_Endpoint.md), and comprises a number of services, or *profiles*.

Currently, there are two profiles:

- [X.509-SVID Profile](#5-x509-svid-profile)
- [JWT-SVID Profile](#6-jwt-svid-profile)

Both profiles are mandatory and MUST be supported by SPIFFE implementations. However, operators MAY administratively disable a specific profile in their deployment.

Future versions of this specification may introduce additional profiles or make one or more profiles optional.

## 2. Extensibility

Implementations MUST NOT add or modify RPCs outside of this standard. Custom workload reference types MAY be defined using the extension point described in [Section 3.1.4](#314-extensibility). Any other extensions MUST be introduced as new gRPC services, as described in the [extensibility method](./SPIFFE_Broker_Endpoint.md#7-extensibility-and-services-rendered) of the SPIFFE Broker Endpoint specification.

## 3. Service Definition

The SPIFFE Broker API is defined by a Protocol Buffer (version 3) service definition. The complete definition is found in [brokerapi.proto](brokerapi.proto).

Profiles are implemented as a group of related RPCs within a single `API` service in the `spiffe.broker` package.

### 3.1 Workload Reference

The SPIFFE Broker API requires a mechanism to identify the entity for which the server should issue an SVID. This reference system enables Brokers to request identity materials on behalf of specific entities while maintaining proper isolation and security boundaries.

References fall into two broad categories:

* **Local references** identify a running process co-located with the Broker (e.g., process ID). They are only meaningful in the local execution environment and have a process-like lifecycle.
* **Object references** identify an addressable object in a control plane that represents an identity (e.g., a Kubernetes object). They are valid across the scope of that control plane (e.g., the cluster) and have a lifecycle tied to the object's existence in that control plane.

Throughout this specification, "workload" is used as a shorthand for the entity that the reference resolves to, regardless of whether that entity is a running process or a control-plane object.

References MUST satisfy the following requirements:

* Uniqueness: Each reference MUST uniquely identify a single entity within its applicable scope (the local node for local references; the relevant control plane for object references) at any given time
* Scope: Local references MUST NOT be used across network boundaries or different nodes; object references MUST NOT be used across control planes (e.g., across Kubernetes clusters)
* Dereferenceability: The server MUST be able to verify that the referenced entity exists and is accessible for identity operations

### 3.1.1 Reference Resolution

Each request message in the SPIFFE Broker API carries exactly one workload reference. Clients MUST provide a reference; servers MUST reject requests that lack one or whose reference type is not understood by the server.

References MUST be resolved on the server and the server MUST verify the existence of the referenced workload.

Servers MUST NOT trust reference data provided by the client without independent verification. For example, when a client provides a PID reference, the server SHOULD independently verify the process exists and collect workload identity attributes through secure channels (e.g., /proc filesystem, container runtime APIs) rather than accepting client-provided attributes at face value.

### 3.1.2 Reference scope

Some references — such as the process ID — are only meaningful and discoverable on the local node. Clients MUST ensure that local references are not sent to remote Broker API servers, and deployments MUST ensure servers do not receive requests originating from outside the node they run on. This mitigates situations where a Broker requests credentials with a process ID from a different node, where that process ID is used by a different workload.

Object references (such as `KubernetesObjectReference`) are valid across the control plane that owns the referenced object — for example, anywhere within the same Kubernetes cluster — and MAY be sent across the network within that scope. Object references MUST NOT be honored by a server bound to a different control plane (e.g., a different cluster); servers MUST reject object references that name a control plane they do not serve.

### 3.1.3 Builtin Reference Types

The specification currently defines two builtin workload reference types.

**Process ID (PID) Reference**: Identifies a workload by its process identifier. The PID MUST be a positive integer. This reference type is universally supported across POSIX-compliant systems.

Example:
```protobuf
WorkloadReference {
  reference: Any {
    type_url: "type.googleapis.com/spiffe.broker.WorkloadPIDReference"
    value: <packed WorkloadPIDReference { pid: 1234 }>
  }
}
```

**Kubernetes Object Reference**: Identifies a workload by an arbitrary Kubernetes object — built-in or custom — for which the server is expected to issue an SVID. The reference is composed of three fields:

- `type` is a structured `KubernetesObjectType` message carrying the resource's `plural` and `group`, both required. For non-core resources the `group` MUST be set to the API group name (e.g., `apps`, `example.com`). For core resources the `group` MUST be set to the literal string `core`.
- `key` is a structured `KubernetesObjectKey` message identifying the specific instance within that type by `namespace` and `name`. `key.namespace` MUST be set for namespaced resources and MUST be empty for cluster-scoped ones; `key.name` is required when `key` is set.
- `uid` is the UID of the referenced Kubernetes object as assigned by Kubernetes.

At least one of `key` or `uid` MUST be specified. When both are specified, the server MUST verify that the object resolved by `key` has the specified UID at the time of issuing the SVIDs and MUST return an error otherwise. When only `uid` is specified, the server resolves the object — and its namespace, if any — from the UID.

This single reference type covers a range of Kubernetes identification patterns that earlier drafts of this specification expressed with multiple dedicated reference messages. In particular, identifying a Pod by its UID alone — a common pattern for Brokers running alongside the Kubernetes runtime that already know the pod UID but not its namespaced name — is expressed by setting `type = { plural: "pods", group: "core" }` and `uid = <pod uid>` (with `key` left unset); see the corresponding example below.

The mapping from a Kubernetes object to a SPIFFE ID is implementation-defined; this specification does not mandate a particular SPIFFE ID format.

Examples:

Namespaced core resource (Pod) by name and UID:
```protobuf
WorkloadReference {
  reference: Any {
    type_url: "type.googleapis.com/spiffe.broker.KubernetesObjectReference"
    value: <packed KubernetesObjectReference {
      type: { plural: "pods", group: "core" }
      key: { namespace: "shop", name: "checkout-7c9f" }
      uid: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    }>
  }
}
```

Pod by UID only — the common case for Brokers that observe pod UIDs from the
Kubernetes runtime but do not have the pod's namespaced name handy:
```protobuf
WorkloadReference {
  reference: Any {
    type_url: "type.googleapis.com/spiffe.broker.KubernetesObjectReference"
    value: <packed KubernetesObjectReference {
      type: { plural: "pods", group: "core" }
      uid: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    }>
  }
}
```

Namespaced non-core resource (Deployment) by namespaced name only:
```protobuf
WorkloadReference {
  reference: Any {
    type_url: "type.googleapis.com/spiffe.broker.KubernetesObjectReference"
    value: <packed KubernetesObjectReference {
      type: { plural: "deployments", group: "apps" }
      key: { namespace: "shop", name: "checkout" }
    }>
  }
}
```

Namespaced ServiceAccount by namespaced name (a common identity anchor for
workloads in Kubernetes):
```protobuf
WorkloadReference {
  reference: Any {
    type_url: "type.googleapis.com/spiffe.broker.KubernetesObjectReference"
    value: <packed KubernetesObjectReference {
      type: { plural: "serviceaccounts", group: "core" }
      key: { namespace: "shop", name: "checkout" }
    }>
  }
}
```

Namespaced custom resource (Flux Kustomization) by UID only:
```protobuf
WorkloadReference {
  reference: Any {
    type_url: "type.googleapis.com/spiffe.broker.KubernetesObjectReference"
    value: <packed KubernetesObjectReference {
      type: { plural: "kustomizations", group: "kustomize.toolkit.fluxcd.io" }
      uid: "0fa1b2c3-4d5e-6f70-8192-a3b4c5d6e7f8"
    }>
  }
}
```

Cluster-scoped core resource (Node) by name:
```protobuf
WorkloadReference {
  reference: Any {
    type_url: "type.googleapis.com/spiffe.broker.KubernetesObjectReference"
    value: <packed KubernetesObjectReference {
      type: { plural: "nodes", group: "core" }
      key: { name: "ip-10-0-1-42.ec2.internal" }
    }>
  }
}
```

### 3.1.4 Extensibility

The SPIFFE Broker API is designed to support additional reference types without modification to the protocol definition. The `WorkloadReference.reference` field uses `google.protobuf.Any`, allowing any message type to be packed and used as a reference.

Standard reference types defined by this specification can be packed into the Any field. Implementations MAY define and use vendor-specific or implementation-specific reference types by packing their custom message types into the Any field.

Implementations extending the reference types SHOULD document their extensions, including the fully-qualified type name used in the Any field, to avoid conflicts with other implementations. Servers that receive a reference type they do not recognize MUST reject the request with an InvalidArgument status.

## 4. Client and Server Behavior

### 4.1 Authenticating and authorizing the Caller

The SPIFFE Broker API makes use of the authentication and authorization at the [SPIFFE Broker Endpoint](./SPIFFE_Broker_Endpoint.md#5-authentication-and-authorization) to identify and authorize the caller.

Implementations MUST maintain a strict allow-only policy that prevents any caller that is not authorized to leverage the SPIFFE Broker API.

Implementations MAY enforce more fine-grained access control by inspecting data carried in the request. For example, an implementation MAY restrict a given caller to a subset of reference types (such as only `WorkloadPIDReference`, or only `KubernetesObjectReference` against a specific namespace), to a subset of audiences in `FetchJWTSVID`, or to a subset of requested SPIFFE IDs. The exact policy model is implementation-defined.

### 4.2 Remote procedure scope

Every invocation of a remote procedure (RPC) at the SPIFFE Broker API, including its request and responses (potentially multiple), are in context of a concrete workload. Clients are expected to invoke RPCs for each workload they represent individually and isolate them from each other accordingly. An X509 Bundle response, for instance, is only valid for the workload the request has referenced and MUST NOT be applied, visible or in any other way impact other workloads. Same applies to all other RPCs in the scope of the SPIFFE Broker API.

If multiple workloads communicate with each other, and the client of the SPIFFE Broker API is involved, it MUST ensure that the corresponding certificates are accordingly separated. For instance, the SVID and bundle of the client is only used for client-side operations, and the SVID and bundle of the server is only used for server-side operations.

### 4.3 Connection Lifetime

Clients of the SPIFFE Broker API SHOULD maintain an open connection for as long as is reasonably possible, waiting on server response messages to be received on the stream. The connection may, at any time, be terminated by either the server or the client. In this case, the client SHOULD immediately establish a new connection. This helps ensure that the client and the workloads it represents retain the most up-to-date set of identity related materials. SPIFFE Broker API server implementers may assume this property, and by not receiving messages in a timely manner, the client may fall out-of-date, potentially impacting its availability.

Compared to the SPIFFE Workload API, the connection between server and client can exist beyond the lifecycle of a workload the client represents. While the SPIFFE Workload API closes the connection, the SPIFFE Broker API only terminates a specific invocation of an RPC within it. The connection between server and client itself can remain open as it handles multiple invocations representing various workloads.

### 4.4 Stream Responses

The SPIFFE Broker API includes RPCs utilizing gRPC server-side streams in order to facilitate rapid propagation of updates, for instance changes to the bundles. This enables clients to loop over server responses, accepting updated responses as they occur.

Every stream response message sent by the server MUST include the full set of information, and not just the information which has changed. This only covers the workload referenced in the corresponding request and not other workloads. See [remote procedure scope](#42-remote-procedure-scope) for details.

The exact timing of server response messages is implementation-specific, and SHOULD be dictated by events which change the response, such as an SVID rotation. Receiving a request message from the client MUST be considered a response-generating event. In other words, the first response message of the server response stream (on a connection-by-connection basis) MUST be sent as soon as possible, without delay.

Finally, implementers of SPIFFE Broker API servers should be careful about pushing updated response messages *too* rapidly. Some software may reload automatically upon receiving new information, potentially causing a period of unavailability should all instances reload at once. As a result, implementers may introduce some splay/jitter in the transmission of widespread updates. Likewise, Brokers SHOULD apply their own jitter when distributing updates out to multiple workloads.

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

Server and client MUST ensure that no operations are performed beyond the lifetime of the workload in a timely manner. Once the workload has stopped, the server MUST stop sending responses for that workload, and the client MUST drop all data it received for the workload, removing it from file systems or other locations where it may have been stored.

What constitutes "stopped" depends on the reference type. For local references (such as a process ID), the workload is considered stopped when the underlying process terminates. For object references (such as a `KubernetesObjectReference`), the workload is considered stopped when the referenced object no longer exists in the control plane, or — when the reference pinned a UID alongside a name — when the object resolved by name no longer matches the pinned UID.

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

// The WorkloadPIDReference message conveys a process id reference of a workload
// running in the same environment.
message WorkloadPIDReference {
    // Required. The process id of the workload. MUST be a positive integer.
    // For workloads running inside container runtimes that maintain a separate
    // sandbox (e.g. the `pause` container in containerd or CRI-O), this MUST
    // be the PID of the workload's own process, not the sandbox PID.
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

    // Optional. ASN.1 DER encoded (not PEM) certificate revocation lists.
    repeated bytes crl = 2;

    // Optional. CA certificate bundles belonging to foreign trust domains that
    // the workload should trust, keyed by the SPIFFE ID of the foreign trust
    // domain. Bundles are ASN.1 DER encoded (not PEM).
    map<string, bytes> federated_bundles = 3;
}

// The X509SVID message carries a single SVID and all associated information,
// including the X.509 bundle for the trust domain.
message X509SVID {
    // Required. The SPIFFE ID of the SVID in this entry
    string spiffe_id = 1;

    // Required. ASN.1 DER encoded (not PEM) certificate chain. MAY include
    // intermediates, the leaf certificate (or SVID itself) MUST come first.
    bytes x509_svid = 2;

    // Required. ASN.1 DER encoded (not PEM) PKCS#8 private key. MUST be unencrypted.
    bytes x509_svid_key = 3;

    // Required. ASN.1 DER encoded (not PEM) X.509 bundle for the trust domain.
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
    // Optional. ASN.1 DER encoded (not PEM) certificate revocation lists.
    repeated bytes crl = 1;

    // Required. CA certificate bundles belonging to trust domains that the
    // workload should trust, keyed by the SPIFFE ID of the trust domain.
    // Bundles are ASN.1 DER encoded (not PEM).
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

As mentioned in [Stream Responses](#44-stream-responses), each `SubscribeToX509SVIDResponse` message returned on the `SubscribeToX509SVID` stream contains the complete set of authorized SVIDs and bundles of the workload at that point in time. As such, if the server redacts SVIDs from a subsequent response that was in context of the referenced workload the Broker SHOULD cease using the redacted SVIDs. This includes situations where the server returns a `PermissionDenied`, in which case the Broker is expected to drop all previously received SVIDs and bundles **for the referenced workload only**. SVIDs and bundles held on behalf of other workloads are not affected, see [Section 4.2 Remote procedure scope](#42-remote-procedure-scope).

#### 5.2.2 SubscribeToX509Bundles

The `SubscribeToX509Bundles` RPC streams back X.509 bundles for the workload to the Broker. These bundles MUST only be used to authenticate X509-SVIDs and MUST only be used for operations involving the referenced workload. They MUST not be used for any other workload.

The `SubscribeToX509BundlesRequest` request message contains a mandatory workload reference.

The `SubscribeToX509BundlesResponse` response message has a mandatory `bundles` field, which MUST contain at least the trust bundle for the trust domain in which the server resides.

If the referenced workload does not exist or is not entitled to receive any X.509 bundles, then the server MUST respond with an appropriate gRPC status code as specified in [Section 4.8](#48-workload-references-and-svid-entitlements). Under such a case, the Broker MAY attempt to reconnect with another call to the `SubscribeToX509Bundles` RPC after a backoff.

As mentioned in [Stream Responses](#44-stream-responses), each `SubscribeToX509BundlesResponse` response contains the complete set of authorized X.509 bundles of the workload at that point in time. As such, if the server redacts bundles from a subsequent response that was in context of the referenced workload the Broker SHOULD cease using the bundles. This includes situations where the server returns a `PermissionDenied`, in which case the Broker is expected to drop all previously received bundles **for the referenced workload only**; bundles held on behalf of other workloads MUST NOT be affected (see [Section 4.2 Remote procedure scope](#42-remote-procedure-scope)).

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

// The WorkloadPIDReference message conveys a process id reference of a workload
// running in the same environment.
message WorkloadPIDReference {
    // Required. The process id of the workload. MUST be a positive integer.
    // For workloads running inside container runtimes that maintain a separate
    // sandbox (e.g. the `pause` container in containerd or CRI-O), this MUST
    // be the PID of the workload's own process, not the sandbox PID.
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

The `FetchJWTSVIDRequest` request message contains a mandatory workload reference. It also contains a mandatory `audience` field, which MUST contain the values to embed in the audience claim of the returned JWT-SVIDs. The `spiffe_id` field is optional, and is used to request a JWT-SVID for a specific SPIFFE ID. If unspecified, the server MUST return JWT-SVIDs for all identities authorized for the workload.

The `FetchJWTSVIDResponse` response message consists of a mandatory `svids` field, which MUST contain one or more `JWTSVID` messages.

All fields in the `JWTSVID` message are mandatory, with the exception of the `hint` field. When the `hint` field is set (i.e. non-empty), SPIFFE Broker API servers MUST ensure its value is unique amongst the set of returned SVIDs in any given `FetchJWTSVIDResponse` message. In the event that a SPIFFE Broker API client encounters more than one `JWTSVID` message with the same `hint` value set, then the first message in the list SHOULD be selected.

If the referenced workload does not exist or is not entitled to receive any JWT-SVIDs, then the server MUST respond with an appropriate gRPC status code as specified in [Section 4.8](#48-workload-references-and-svid-entitlements). Under such a case, the Broker MAY attempt to reconnect with another call to the `FetchJWTSVID` RPC after a backoff.

#### 6.2.2 SubscribeToJWTBundles

The `SubscribeToJWTBundles` RPC streams back JWT bundles for the workload to the Broker. These bundles MUST only be used to authenticate JWT-SVIDs and MUST only be used for operations involving the referenced workload. They MUST NOT be used for any other workload.

The `SubscribeToJWTBundlesRequest` request message contains a mandatory workload reference.

The `SubscribeToJWTBundlesResponse` response message consists of a mandatory `bundles` field, which MUST contain at least the JWT bundle for the trust domain in which the server resides.

The returned bundles are encoded as a standard JWK Set as defined by [RFC 7517](https://tools.ietf.org/html/rfc7517) containing the JWT-SVID signing keys for the trust domain. These keys may only represent a subset of the keys present in the SPIFFE trust bundle for the trust domain. The server MUST NOT include keys with other uses in the returned JWT bundles.

If the referenced workload does not exist or is not entitled to receive any JWT bundles, then the server MUST respond with an appropriate gRPC status code as specified in [Section 4.8](#48-workload-references-and-svid-entitlements). Under such a case, the Broker MAY attempt to reconnect with another call to the `SubscribeToJWTBundles` RPC after a backoff.

As mentioned in [Stream Responses](#44-stream-responses), each `SubscribeToJWTBundlesResponse` response contains the complete set of authorized JWT bundles of the workload at that point in time. As such, if the server redacts bundles from a subsequent response that was in context of the referenced workload the Broker SHOULD cease using the redacted bundles. This includes situations where the server returns a `PermissionDenied`, in which case the Broker is expected to drop all previously received bundles **for the referenced workload only**; bundles held on behalf of other workloads MUST NOT be affected (see [Section 4.2 Remote procedure scope](#42-remote-procedure-scope)).

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