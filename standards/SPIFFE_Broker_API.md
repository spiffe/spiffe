# The SPIFFE Broker API

## Status of this Memo

This document specifies an identity API standard for the internet community, and requests discussion and suggestions for improvements. Distribution of this document is unlimited.

## Abstract

Brokers are trusted infrastructure components that can act on-behalf-of workloads. This API enables them to retrieve SVIDs and bundles of workloads it represents by referencing the workloads by its process ID.

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

Profiles are implemented as a group of related RPCs within a single `BrokerAPI` service.

## 3.1 Workload Reference

The SPIFFE Broker API requires a mechanism to uniquely identify and reference workloads running within the same environment as the Broker. This reference system enables Brokers to request identity materials on behalf of specific workloads while maintaining proper isolation and security boundaries.

Workload references MUST satisfy the following requirements:

* Uniqueness: Each reference must uniquely identify a single workload within the local environment at any given time
* Local Scope: References are valid only within the local execution environment and MUST NOT be used across network boundaries or different nodes
* Dereferenceability: The server must be able to verify that the referenced workload exists and is accessible for identity operations

Currently, the specification defines process identifiers (Process ID, or PID) as the primary workload reference mechanism. Future versions of this specification may introduce additional reference types to support different operating system primitives, such as Windows process handles or container runtime identifiers. Future extension to the SPIFFE Broker API specification will be made through the extensible oneof reference field structure that is present in all request messages.

## 4. Client and Server Behavior

### 4.1 Authenticating and authorizing the Caller

The SPIFFE Broker API makes use of the authentication and authorization at the [SPIFFE Broker Endpoint](./SPIFFE_Broker_Endpoint.md#5-authentication-and-authorization) to identify and authorize the caller.

Implementations MUST maintain a strict allow-only policy that prevents any caller that is not authorized to leverage the SPIFFE Broker API.

### 4.2 Remote procedure scope

Every invocation of a remote procedure (RPC) at the SPIFFE Broker API, including its request and responses (potentially multiple), are in context of a concrete workload. Clients are expected to invoke RPCs for each workload they represent individually and isolate them for each other accordingly. An X509 Bundle response, for instance, is only valid for the workload the request has referenced and MUST NOT be applied, visible or in any other way impact other workloads. Same applies to all other RPCs in the scope of the SPIFFE Broker API.

If multiple workloads communicate with each other, and the client of the SPIFFE Broker API is involved, it MUST ensure that the corresponding certificates are accordingly separated. For instance, the SVID and bundle of the client is only used for client-side operations, and the SVID and bundle of the server is only used for server-side operations.

### 4.3 Connection Lifetime

Clients of the SPIFFE Broker API SHOULD maintain an open connection for as long as is reasonably possible, waiting on server response messages to be received on the stream. The connection may, at any time, be terminated by either the server or the client. In this case, the client SHOULD immediately establish a new connection. This helps ensure that the client and the workloads it represents retain the most up-to-date set of identity related materials. SPIFFE Broker API server implementors may assume this property, and by not receiving messages in a timely manner, the client may fall out-of-date, potentially impacting its availability.

Compared to the SPIFFE Workload API, the connection between server and client can exist beyond the lifecycle of a workload the client represents. While the SPIFFE Workload API closes the connection, the SPIFFE Broker API only terminates a specific invocation of an RPC within it. The connection between server and client itself can remain open as it handles multiple invocations representing various workloads.

### 4.4 Stream Responses

The SPIFFE Broker API includes RPCs utilizing gRPC server-side streams in order to facilitate rapid propagation of updates, for instance changes to the bundles. This enables clients to loop over server responses, accepting updated responses as they occur.

Every stream response message sent by the server MUST include the full set of information, and not just the information which has changed. This only covers the workload referenced in the corresponding request and not other workloads. See [remote procedure scope](#42-remote-procedure-scope) for details.

The exact timing of server response messages is implementation-specific, and SHOULD be dictated by events which change the response, such as an SVID rotation. Receiving a request message from the client MUST be considered a response-generating event. In other words, the first response message of the server response stream (on a connection-by-connection basis) MUST be sent as soon as possible, without delay.

Finally, implementers of SPIFFE Broker API servers should be careful about pushing updated response messages *too* rapidly. Some software may reload automatically upon receiving new information, potentially causing a period of unavailability should all instances reload at once. As a result, implementers may introduce some splay/jitter in the transmission of widespread updates.

> Note Arndt: do we want to jitter responses for Brokers too, or should this behaviour not be implemented there instead? Or both?

### 4.5 Default Values and Redacted Information

Client and servers MUST implement the same default values behavior as described in section 4.4 of the [SPIFFE Workload API](./SPIFFE_Workload_API.md).

### 4.6 Mandatory Fields

Messages exchanged for the profile RPCs are comprised of both mandatory and optional fields. Servers receiving a message in which a mandatory field has a default value SHOULD respond with the "InvalidArgument" gRPC status code (see the [Error Codes](SPIFFE_Broker_Endpoint.md#6-error-codes) section in the SPIFFE Broker Endpoint specification for more information). Clients receiving a message in which a mandatory field has a default value SHOULD report an error and discard the message.

### 4.7 Federated Bundles

Response messages of the SPIFFE Broker API contain federated bundles. The usage and expected client behavior MUST be the same as described in section 4.6 of the [SPIFFE Workload API](./SPIFFE_Workload_API.md).

It is important to highlight that bundles MUST only be used in the context of the workload that was referenced in the corresponding request as described in [Section 4.2 Remote Procedure Scope](#42-remote-procedure-scope) and [Section 4.4 Stream Responses](#44-stream-responses) of this specification.

### 4.8 Workload References and SVID entitlements

Implementations MUST validate that workload references point to existing, accessible workloads before processing any identity requests. Invalid or stale references or situations where the workload itself exists but is not entitled to receive an SVID or bundle SHOULD result in the gRPC error code "PreconditionFailed".

To differentiate between these situations the server MUST use `WorkloadReferenceError` with gRPC Rich Error Details when returning "PreconditionFailed". See [Section 7](#7-workload-reference-error) for details.

### 4.9 Workload Lifecycle

Both, server and client MUST monitor the state of the workload and ensure that no operations are performed beyond the lifetime of the workload. For instance, the server MUST not send responses to the client once the workload has stopped. Clients on the other hand MUST drop all the data received for the workload, removing it from file systems or other locations it potentially have stored it in addition.

## 5. X.509-SVID Profile

The X.509-SVID Profile of the SPIFFE Broker API provides a set of gRPC methods which can be used by Brokers to retrieve [X.509-SVIDs](X509-SVID.md) and their related trust bundles on behalf of workloads. This profile outlines the signature of these methods, as well as related client and server behavior.

### 5.1 Profile Definition

The X.509-SVID Profile RPCs and associated messages are defined below. For the complete Broker API service definition, see [brokerapi.proto](brokerapi.proto).

```protobuf

service SpiffeBrokerAPI {
    /////////////////////////////////////////////////////////////////////////
    // X509-SVID Profile
    /////////////////////////////////////////////////////////////////////////

    // Fetch X.509-SVIDs for all SPIFFE identities the referenced workload is 
    // entitled to, as well as related information like trust bundles. As this
    // information changes, subsequent messages will be streamed from the server.
    rpc FetchX509SVID(X509SVIDRequest) returns (stream X509SVIDResponse);

    // Fetch trust bundles of the referenced workload. Useful in situations that
    // only need to validate SVIDs without obtaining an SVID for themself. As this
    // information changes, subsequent messages will be streamed from the server.
    rpc FetchX509Bundles(X509BundlesRequest) returns (stream X509BundlesResponse);

    // ... RPCS for other profiles ...
}

// The WorkloadPIDReference message conveys a process id reference of a workload 
// running in the same environment.
message WorkloadPIDReference {
    // Required. The process id of the workload.
    string pid = 1;
}

// The X509SVIDRequest message conveys parameters for requesting an X.509-SVID.
message X509SVIDRequest {
    // Required. The reference identifying the workload.
    oneof reference {
        WorkloadPIDReference pid = 1;
    }
}

// The X509SVIDResponse message carries X.509-SVIDs and related information,
// including a list of bundles the workload may use for federating with foreign
// trust domains.
message X509SVIDResponse {
    // Required. A list of X509SVID messages, each of which includes a single
    // X.509-SVID, its private key, and the bundle for the trust domain.
    repeated X509SVID svids = 1;

    // Optional. CA certificate bundles belonging to foreign trust domains that
    // the workload should trust, keyed by the SPIFFE ID of the foreign trust
    // domain. Bundles are ASN.1 DER encoded.
    map<string, bytes> federated_bundles = 2;
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

// The X509BundlesRequest message conveys parameters for requesting X.509
// bundles.
message X509BundlesRequest {
    // Required. The reference identifying the workload.
    oneof reference {
        WorkloadPIDReference pid = 1;
    }
}

// The X509BundlesResponse message carries a map of trust bundles the workload 
// should trust.
message X509BundlesResponse {
    // Required. CA certificate bundles belonging to trust domains that the
    // workload should trust, keyed by the SPIFFE ID of the trust domain.
    // Bundles are ASN.1 DER encoded.
    map<string, bytes> bundles = 1;
}
```

### 5.2 Profile RPCs

#### 5.2.1 FetchX509SVID

The `FetchX509SVID` RPC enables Brokers to retrieve X509-SVIDs and X.509 bundles on behalf of a referenced workload via a streaming response. The returned materials are workload-specific and MUST only be used for operations involving that particular workload. Brokers MUST NOT use these SVIDs or bundles for any other workload or purpose.

The `X509SVIDRequest` request message contains a mandatory workload reference. According to the `oneof` section only one reference is permitted.

The `X509SVIDResponse` response consists of a mandatory `svids` field, which MUST contain one or more `X509SVID` messages (one for each identity granted to the client, on-behalf of the workload). The `federated_bundles` field is optional.

All fields in the `X509SVID` message are mandatory, with the exception of the `hint` field. When the `hint` field is set (i.e. non-empty), SPIFFE Broker API servers MUST ensure its value is unique amongst the set of returned SVIDs in any given `X509SVIDResponse` message. In the event that a client receives more than one `X509SVID` message with the same `hint` value set, then the first message in the list SHOULD be selected.

If the referenced workload does not exist or is not entitled to receive any X509-SVIDs, then the server SHOULD respond with the "FailedPrecondition" gRPC status code. See [Section 7](#7-workload-reference-error) for details. Under such a case, the Broker MAY attempt to reconnect with another call to the `FetchX509SVID` RPC after a backoff.

As mentioned in [Stream Responses](#43-stream-responses), each `X509SVIDResponse` message returned on the `FetchX509SVID` stream contains the complete set of authorized SVIDs and bundles of the workload at that point in time. As such, if the server redacts SVIDs from a subsequent response that was in context of the referenced workload the Broker SHOULD cease using the redacted SVIDS. This includes situations where the server returns a Permission denied, where the Broker is expected to drop all previous received SVIDs and bundles.

#### 5.2.2 FetchX509Bundles

The `FetchX509Bundles` RPC streams back X.509 bundles for the workload to the Broker. These bundles MUST only be used to authenticate X509-SVIDs and MUST only be used for operations involving the referenced workload. They MUST not be used for any other workload.

The `X509BundlesRequest` request message contains a reference to the workload.

The `X509BundlesResponse` response message has a mandatory `bundles` field, which MUST contain at least the trust bundle for the trust domain in which the server resides.

If the referenced workload does not exist or is not entitled to receive any X.509 bundles, then the server SHOULD respond with the "FailedPrecondition" gRPC status code. See [Section 7](#7-workload-reference-error) for details. Under such a case, the Broker MAY attempt to reconnect with another call to the `FetchX509Bundles` RPC after a backoff.

As mentioned in [Stream Responses](#43-stream-responses), each `X509BundleResponse` response contains the complete set of authorized X.509 bundles of the workload at that point in time. As such, if the server redacts bundles from a subsequent response that was in context of the referenced workload the Broker SHOULD cease using the bundles. This includes situations where the server returns a Permission denied, where the Broker is expected to drop all previous received bundles.

### 5.3 Default Identity

Servers and clients of Broker API are expected to follow the behavior as defined in section 5.3 of the [SPIFFE Workload API](./SPIFFE_Workload_API.md#53-default-identity) when multiple identities are returned.

The Broker is expected to use the default identity in situations where it cannot determine the expected usage and is not able to deliver multiple identities to the workload. When it is able to deliver multiple identities to workloads it MUST identify these identities with their corresponding `hint` as delivered by the SPIFFE Broker API and clients MUST be able to use these identifier to identify identities.

## 6. JWT-SVID Profile

The JWT-SVID Profile of the SPIFFE Broker API provides a set of gRPC methods which can be used by a Broker to retrieve JWT-SVIDs and their related trust bundles on behalf of workloads. This profile outlines the signature of these methods, as well as related client and server behavior.

### 6.1 Profile Definition

The JWT-SVID Profile RPCs and associated messages are defined below. For the complete Broker API service definition, see [brokerapi.proto](brokerapi.proto).

```protobuf
service SpiffeBrokerAPI {
    /////////////////////////////////////////////////////////////////////////
    // JWT-SVID Profile
    /////////////////////////////////////////////////////////////////////////

    // Fetch JWT-SVIDs for all SPIFFE identities the referenced workload is 
    // entitled to, for the requested audience. If an optional SPIFFE ID is 
    // requested, only the JWT-SVID for that SPIFFE ID is returned.
    rpc FetchJWTSVID(JWTSVIDRequest) returns (JWTSVIDResponse);

    // Fetches the JWT bundles, formatted as JWKS documents, keyed by the
    // SPIFFE ID of the trust domain. As this information changes, subsequent
    // messages will be streamed from the server.
    rpc FetchJWTBundles(JWTBundlesRequest) returns (stream JWTBundlesResponse);

    // ... RPCs for other profiles ...
}

// The WorkloadPIDReference message conveys a process id reference of a workload 
// running in the same environment.
message WorkloadPIDReference {
    // Required. The process id of the workload.
    string pid = 1;
}

// The JWTSVIDRequest message conveys parameters for requesting JWT-SVIDs.
message JWTSVIDRequest {
    // Required. The reference identifying the workload.
    oneof reference {
        WorkloadPIDReference pid = 1;
    }

    // Required. The audience(s) the workload intends to authenticate against.
    repeated string audience = 2;

    // Optional. The requested SPIFFE ID for the JWT-SVID. If unset, all
    // JWT-SVIDs to which the workload is entitled are requested.
    string spiffe_id = 3;
}

// The JWTSVIDResponse message conveys JWT-SVIDs.
message JWTSVIDResponse {
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

// The JWTBundlesRequest message conveys parameters for requesting JWT bundles.
message JWTBundlesRequest { 
    // Required. The reference identifying the workload.
    oneof reference {
        WorkloadPIDReference pid = 1;
    }
}

// The JWTBundlesReponse conveys JWT bundles.
message JWTBundlesResponse {
    // Required. JWK encoded JWT bundles, keyed by the SPIFFE ID of the trust
    // domain.
    map<string, bytes> bundles = 1;
}
```

### 6.2 Profile RPCs

#### 6.2.1 FetchJWTSVID


The `FetchJWTSVID` RPC allows a Broker to request one or more short-lived JWT-SVIDs with a specific audience for a workload.

The `JWTSVIDRequest` request contains a reference to the workload for which the Broker wants to request the JWT-SVID. It also contains a mandatory `audience` field, which MUST contain the value to embed in the audience claim of the returned JWT-SVIDs. The `spiffe_id` field is optional, and is used to request a JWT-SVID for a specific SPIFFE ID. If unspecified, the server MUST return JWT-SVIDs for all identities authorized for the workload.

The `JWTSVIDResponse` response message consists of a mandatory `svids` field, which MUST contain one or more `JWTSVID` messages.

All fields in the `JWTSVID` message are mandatory, with the exception of the `hint` field. When the `hint` field is set (i.e. non-empty), SPIFFE Broker API servers MUST ensure its value is unique amongst the set of returned SVIDs in any given `JWTSVIDResponse` message. In the event that a SPIFFE Broker API client encounters more than one `JWTSVID` message with the same `hint` value set, then the first message in the list SHOULD be selected.

If the referenced workload does not exist or is not entitled to receive any JWT-SVIDs, then the server SHOULD respond with the "FailedPrecondition" gRPC status code. See [Section 7](#7-workload-reference-error) for details. Under such a case, the Broker MAY attempt to reconnect with another call to the `FetchJWTSVID` RPC after a backoff.

#### 6.2.2 FetchJWTBundles

The `FetchJWTBundles` RPC streams back JWT bundles for the workload to the Broker. These bundles MUST only be used to authenticate JWT-SVIDs and MUST only be used for operations involving the referenced workload. They MUST NOT be used for any other workload.

The `JWTBundlesRequest` request message contains a reference to the workload.

The `JWTBundlesResponse` response message consists of a mandatory `bundles` field, which MUST contain at least the JWT bundle for the trust domain in which the server resides.

The returned bundles are encoded as a standard JWK Set as defined by [RFC 7517](https://tools.ietf.org/html/rfc7517) containing the JWT-SVID signing keys for the trust domain. These keys may only represent a subset of the keys present in the SPIFFE trust bundle for the trust domain. The server MUST NOT include keys with other uses in the returned JWT bundles.

If the referenced workload does not exist or is not entitled to receive any JWT bundles, then the server SHOULD respond with the "FailedPrecondition" gRPC status code. See [Section 7](#7-workload-reference-error) for details. Under such a case, the Broker MAY attempt to reconnect with another call to the `FetchJWTBundles` RPC after a backoff.

As mentioned in [Stream Responses](#43-stream-responses), each `JWTBundlesResponse` response contains the complete set of authorized JWT bundles of the workload at that point in time. As such, if the server redacts bundles from a subsequent response that was in context of the referenced workload the Broker SHOULD cease using the redacted bundles. This includes situations where the server returns a Permission denied, where the Broker is expected to drop all previous received bundles.

# 7. Workload Reference Error

The `WorkloadReferenceError` is used in situations where the client itself is authenticated and authorized, but the server is not able to respond due to the workload referenced in the request. It is only sent in combination with the gRPC error code "FailedPrecondition" and contains a mandatory `error` field.

```protobuf
// The WorkloadReferenceError message is used to convey errors related to workload references.
message WorkloadReferenceError {
    // Required. The error code.
    WorkloadReferenceErrorCode code = 1;
}

// The WorkloadReferenceErrorCode enum defines the possible error codes for workload reference errors.
enum WorkloadReferenceErrorCode {
    UNSPECIFIED = 0;

    // The workload reference is invalid, e.g., it does not match the expected format.
    WORKLOAD_REFERENCE_INVALID = 1;

    // The referenced workload could not be found.
    WORKLOAD_REFERENCE_NOT_FOUND = 2;

    // The workload is not entitled to the receive the requested SVID or bundle.
    WORKLOAD_NOT_ENTITLED = 3;
}
```

The error field is used to differentiate between the following situations:

| Situation | Workload Reference Error Code |
|-----------|-------------------------------|
| The reference submitted by the client is not well-formatted. | WORKLOAD_REFERENCE_INVALID |
| The referenced workload does not exist. | WORKLOAD_REFERENCE_NOT_FOUND | 
| The referenced workload exists but is not entitled to receive an SVID or bundle. | WORKLOAD_NOT_ENTITLED |

Clients receiving a "WorkloadReferenceError" error may retry the request after a backoff, but need to be aware that unless the state of the system has changed the same error will be returned again. The client MAY also choose to stop retrying the request and report an error to the user.

## Appendix A. Sample Implementation State Machines

> TODO Arndt: SPIFFE Workload API contains an example state machine - should we do something similar for the Broker API?
