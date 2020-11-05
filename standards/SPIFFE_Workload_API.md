# The SPIFFE Workload API

## Status of this Memo

This document specifies an experimental identity API standard for the internet community, and requests discussion and suggestions for improvements. It is a work in progress. Distribution of this document is unlimited.

## Abstract

Portable and interoperable cryptographic identity for networked workloads is perhaps *the* core use case for SPIFFE. In order to wholly address this requirement, the community must converge upon a standardized way to retrieve, validate, and interact with SPIFFE identities. This specification outlines the API signatures and client/server behavior required in order to support SPIFFE-based authentication systems.

## Table of Contents

1\. [Introduction](#1-introduction)
2\. [Extensibility](#2-extensibility)
3\. [Service Defintion](#3-service-definition)
4\. [Identifying the Caller](#4-identifying-the-caller)
5\. [X.509-SVID Profile](#5-x509-svid-profile)
5.1. [Workload API Client and Server Behavior](#51-workload-api-client-and-server-behavior)
5.2. [Federated Bundles](#52-federated-bundles)
5.3. [Default Identity](#53-default-identity)
5.4. [Profile Definition](#54-profile-definition)
5.5. [Default Values and Redacted Information](#55-default-values-and-redacted-information)
6\. [JWT-SVID Profile](#6-jwt-svid-profile)
6.1 [Client and Server Behavior](#61-client-and-server-behavior)
6.2 [Default Identity](#62-default-identity)
6.3 [Fetching Bundles](#63-fetching-bundles)
6.4 [Profile Definition](#64-profile-definition)
6.5. [Default Values and Redacted Information](#65-default-values-and-redacted-information)

## 1. Introduction

The SPIFFE Workload API is an API which provides information and services that enable workloads, or compute processes, to leverage SPIFFE identities and SPIFFE-based authentication systems. It is served by the [SPIFFE Workload Endpoint](SPIFFE_Workload_Endpoint.md), and comprises a number of services, or *profiles*.

Currently, there are two profiles, both of which are mandatory:

- [X.509-SVID Profile](#5-x509-svid-profile)
- [JWT-SVID Profile](#6-jwt-svid-profile)

Future versions of this specification may introduce additional profiles or make one or more profiles optional.

## 2. Extensibility

The SPIFFE Workload API MUST NOT be extended beyond this specification. Implementers wishing to provide extended functionality may do so by introducing new gRPC services, according to the [extensibility method](SPIFFE_Workload_Endpoint.md#7-extensibility-and-services-rendered) outlined in the SPIFFE Workload Endpoint specification.

## 3. Service Definition

The SPIFFE Workload API is defined by a Protocol Buffer (version 3) service definition. The complete definition is found in [workloadapi.proto](workloadapi.proto).

All profiles are implemented as a group of related RPCs within a single `WorkloadAPI` service.

## 4. Identifying the Caller

The SPIFFE Workload API supports any number of local clients, allowing it to bootstrap the identity of any process that can reach it. Typically, it is desirable to assign identities on a per-process basis, where certain processes are granted certain identities. In order to do this, the SPIFFE Workload API implementation must be able to ascertain the identity of the caller.

The SPIFFE Workload Endpoint specification mandates the absence of direct client authentication, instead relying on out-of-band authenticity checks. As a result, it is the responsibility of the SPIFFE Workload Endpoint implementation to identify the caller. Information about the caller can then be used by the SPIFFE Workload API to determine the appropriate identities to serve. For more information, please see the [Authentication](SPIFFE_Workload_Endpoint.md#5-authentication) section of the SPIFFE Workload Endpoint specification.

## 5. X.509-SVID Profile

The X.509-SVID Profile of the SPIFFE Workload API provides a set of gRPC methods which can be used by workloads to retrieve [X.509-SVIDs](X509-SVID.md) and their related trust bundles. This profile outlines the signature of these methods, as well as related client and server behavior.

### 5.1 Workload API Client and Server Behavior

The SPIFFE Workload API is implemented as a gRPC server-side stream in order to facilitate rapid propagation of updates like revocations and CA certificate introductions. This enables clients to loop over server responses, accepting updated responses as they occur.

Every response message sent by the server MUST include the full set of information, and not just the information which has changed. This avoids complexity associated with state tracking on both Client and Server implementations, including the need for anti-entropy mechanisms.

The exact timing of server response messages is implementation-specific, and SHOULD be dictated by events which change the response, such as an SVID rotation, a CRL update, etc. Receiving a request message from the client MUST be considered a response-generating event. In other words, the first response message of the server response stream (on a connection-by-connection basis) MUST be sent as soon as possible, without delay.

Clients of the SPIFFE Workload API SHOULD maintain an open connection for as long as is reasonably possible, waiting on server response messages to be received on the stream. The connection may, at any time, be terminated by either the server or the client. In this case, the client SHOULD immediately establish a new connection. This helps ensure that the workload retains the most up-to-date set of SVIDs, CRLs, and Bundles. SPIFFE Workload API server implementors may assume this property, and by not receiving messages in a timely manner, the workload may fall out-of-date, potentially impacting its availability.

Finally, implementers of SPIFFE Workload API servers should be careful about pushing updated response messages *too* rapidly. Some software may reload automatically upon receiving new information, potentially causing a period of unavailability should all instances reload at once. As a result, implementers may introduce some splay/jitter in the transmission of widespread updates.

For additional clarity, please see [Appendix A](#appendix-a.-sample-implementation-state-machines) for sample implementation state machines.

### 5.2 Federated Bundles

The `FetchX509SVID` RPC will always provide a Trust Bundle for the Trust Domain in which an SVID resides, however, it may also provide bundles for foreign Trust Domains.

The `FetchX509Bundles` RPC returns a set of Trust Bundles keyed by the SPIFFE ID of the trust domain.  Since this RPC does not return an SVID, all bundles are encoded in the same way in the response, whether they are for the trust domain in which the server resides or are foreign.

Inclusion of foreign bundles enables workloads to communicate *across* Trust Domains, and is the primary mechanism through which federation is enabled. A bundle representing a foreign Trust Domain is known as a *Federated Bundle*.

When authenticating a client from a foreign trust domain, the authenticator chooses the bundle representing the client’s presented trust domain for validation. Similarly, when authenticating a server, the client uses the bundle representing the server’s trust domain. If no matching bundle is present for the SVID in use, then the peer is untrusted. This approach is required in order to account for the lack of widespread support for SAN URI Name Constraints in common X.509 libraries. Please see [Section 4.2](X509-SVID.md#42-name-constraints) of the X509-SVID specification for more information.

### 5.3 Default Identity

It is often the case that a workload doesn’t know what identity it should assume. Determining when to assume what identity is a site-specific concern, and as a result, the SPIFFE specifications don’t reason about how to do this.

In order to support the widest variety of use cases, the X.509-SVID Profile supports the issuance of multiple identities, while also defining a default identity. It is expected that workloads which are aware of multiple identities can handle decision making on their own. Workloads which don’t understand how to leverage multiple identities may use the default identity. The default identity is the first in the list. Protocol buffers ensure that the order of the list is preserved.

### 5.4 Profile Definition

The X.509-SVID Profile RPCs and associated messages are defined below. For the complete Workload API service definition, see [workloadapi.proto](workloadapi.proto).

```protobuf
service SpiffeWorkloadAPI {
    /////////////////////////////////////////////////////////////////////////
    // X509-SVID Profile
    /////////////////////////////////////////////////////////////////////////

    // Fetch X.509-SVIDs for all SPIFFE identities the workload is entitled to,
    // as well as related information like trust bundles and CRLs. As this
    // information changes, subsequent messages will be sent.
    rpc FetchX509SVID(X509SVIDRequest) returns (stream X509SVIDResponse);

    // Fetch trust bundles and CRLs. Useful for clients that only need to
    // validate SVIDs without obtaining an SVID for themself. As this
    // information changes, subsequent messages will be sent.
    rpc FetchX509Bundles(X509BundlesRequest) returns (stream X509BundlesResponse);

    // ... other profiles RPCs ...
}

// The X509SVIDRequest message conveys parameters for requesting an X.509-SVID.
// There are currently no such parameters.
message X509SVIDRequest {  }

// The X509SVIDResponse message carries X.509-SVIDs and related information,
// including a global CRL and list of bundles the workload is federated with.
message X509SVIDResponse {
    // A list of X509SVID messages, each of which includes a single
    // X.509-SVID, its private key, and the X.509 bundle for the Trust Domain.
    repeated X509SVID svids = 1;

    // An ASN.1 DER encoded CRL.
    repeated bytes crl = 2;

    // CA certificate bundles belonging to foreign Trust Domains that the
    // workload should trust, keyed by the SPIFFE ID of the foreign
    // domain. Bundles are ASN.1 DER encoded.
    map<string, bytes> federated_bundles = 3;
}

// The X509SVID message carries a single SVID and all associated
// information, including X.509 bundle for the Trust Domain.
message X509SVID {
    // The SPIFFE ID of the SVID in this entry
    string spiffe_id = 1;

    // ASN.1 DER encoded certificate chain. MAY include intermediates,
    // the leaf certificate (or SVID itself) MUST come first.
    bytes x509_svid = 2;

    // ASN.1 DER encoded PKCS#8 private key. MUST be unencrypted.
    bytes x509_svid_key = 3;

    // ASN.1 DER encoded X.509 bundle for the Trust Domain.
    bytes bundle = 4;
}

// The X509BundlesRequest message conveys parameters for requesting X.509
// bundles. There are currently no such parameters.
message X509BundlesRequest {
}

// The X509BundlesResponse message carries a global CRL and a
// map of trust bundles the workload should trust.
message X509BundlesResponse {
    // ASN.1 DER encoded certificate revocation list.
    repeated bytes crl = 1;

    // CA certificate bundles belonging to Trust Domains that the
    // workload should trust, keyed by the SPIFFE ID of the trust
    // domain. Bundles are ASN.1 DER encoded.
    map<string, bytes> bundles = 2;
}
```

All fields in the `X509SVID` message are mandatory, and MUST contain a non-default value. Clients receiving an `X509SVID` message in which any field has a default value SHOULD report an error and discard the message.

The only mandatory field in the `X509SVIDResponse` message is the `svids` field. If the client is not entitled to an SVID, then the server SHOULD respond with the "PermissionDenied" gRPC status code (see the [Error Codes](SPIFFE_Workload_Endpoint.md#6-error-codes) section in the SPIFFE Workload Endpoint specification for more information). The `crl` field and the `federated_bundles` field are optional, and may contain a default value.

The `X509BundlesResponse` message MUST contain at least one trust bundle.  If the client is not entitled to receive any X.509 bundles, the server SHOULD respond with the "PermissionDenied" gRPC status code.

### 5.5 Default Values and Redacted Information

SPIFFE Workload API clients may at times encounter fields in the response message that have a default value, or may notice that information included in a previous response is not included in the latest response. For instance, a client may encounter a default value in the `federated_bundles` field after having previously received a federated bundle.

Since every message MUST include the full set of information (see the [Workload API Client and Server Behavior](#51-workload-api-client-and-server-behavior) section), clients SHOULD interpret the absence of data as a redaction. As an example, if a client has loaded a bundle for `spiffe://foo.bar`, and receives a message that does not include a bundle for `spiffe://foo.bar`, then the bundle SHOULD be unloaded.

If the server redacts all SVIDs from a workload, it SHOULD send the "PermissionDenied" gRPC status code (terminating the gRPC response stream). The client SHOULD cease using the redacted SVIDS. The client MAY attempt to reconnect with another call to the `FetchX509SVID` RPC after a backoff.

If the server redacts all trust bundles from a client using the `FetchX509Bundles` RPC, it SHOULD send the "PermissionDenied" gRPC status code (terminating the gRPC response stream). The client SHOULD cease using the redacted trust bundles. The client MAY attempt to reconnect with another call to the `FetchX509Bundles` RPC after a backoff.

## 6. JWT-SVID Profile

The JWT-SVID Profile of the SPIFFE Workload API provides a set of gRPC methods which can be used by workloads to retrieve JWT-SVIDs and their related trust bundles. This profile outlines the signature of these methods, as well as related client and server behavior.

### 6.1 Client and Server Behavior

The JWT-SVID Workload API profile exposes three gRPC methods: FetchJWTSVID, FetchJWTBundles, and ValidateJWTSVID.

The FetchJWTSVID and ValidateJWTSVID methods operate in a 1:1 request/response pattern. A single request made to the FetchJWTSVID method generates a single response containing the JWT-SVID(s) described in the request. Similarly, a single request made to the ValidateJWTSVID method generates a single response providing information about the token provided in the request. It should be noted that, under some implementations, the cost of creating a new connection may be high. Clients are encouraged to reuse connections when possible.

The FetchJWTBundles method is different. It is implemented as a gRPC server-side stream in order to facilitate rapid propagation of updates, namely key introductions or redactions. Every response message sent by the server MUST include the full set of information, and not just the information which has changed. This avoids complexity associated with state tracking on both Client and Server implementations.

The client and server behavior of FetchJWTBundles is identical to that of the X509-SVID profile. Please see the Client and Server Behavior section of the X509-SVID profile for more detailed information.

### 6.2 Default Identity

It is often the case that a workload doesn’t know what identity it should assume. Determining when to assume what identity is a site-specific concern, and as a result, the SPIFFE specifications don’t reason about how to do this.

In order to support the widest variety of use cases, the JWT-SVID Profile supports the issuance of multiple identities, while also defining a default identity. It is expected that workloads which are aware of multiple identities can handle decision making on their own. Workloads which don’t understand how to leverage multiple identities may use the default identity. The default identity is the first in the list. Protocol buffers ensure that the order of the list is preserved.

### 6.3 Fetching Bundles

The JWT-SVID Workload API profile exposes a method for fetching JWKS bundles that can be used to validate JWT-SVID signatures. This method is exposed for the purpose of supporting legacy JWT validators. For instance, if the SPIFFE Workload API is available but the JWT validating software is not aware of the Workload API, it is possible to write a small shim that can retrieve the bundles and feed them to the legacy workload.

JWT-SVID signing keys may represent only a subset of the keys present in a SPIFFE trust bundle. Implementers of the SPIFFE Workload API MUST NOT include keys with other uses in the returned JWKS bundles. In other words, the SPIFFE Workload API should only provide JWT-SVID validators with bundle members that are valid JWT-SVID signers.

The JWTBundlesResponse message includes a map of JWKS bundles, keyed by trust domain. When validating a JWT-SVID, the validator should use the bundle corresponding to the trust domain of the subject. If a JWT bundle for the specified trust domain is not present, then the token is untrusted.

Please note that nominally, workloads will use the ValidateJWTSVID method for JWT validation, allowing the SPIFFE Workload API to perform validation on their behalf. Doing this removes the need for the workload to implement validation logic, which can be error prone.

### 6.4 Profile Definition

The JWT-SVID Profile RPCs and associated messages are defined below. For the complete Workload API service definition, see [workloadapi.proto](workloadapi.proto).

```
service SpiffeWorkloadAPI {
    /////////////////////////////////////////////////////////////////////////
    // JWT-SVID Profile
    /////////////////////////////////////////////////////////////////////////

    // Fetch JWT-SVIDs for all SPIFFE identities the workload is entitled to,
    // for the requested audience. If an optional SPIFFE ID is requested, only
    // the JWT-SVID for that SPIFFE ID is returned.
    rpc FetchJWTSVID(JWTSVIDRequest) returns (JWTSVIDResponse);

    // Fetches the JWT bundles, formatted as JWKS documents, keyed by
    // trust domain. As this information changes, subsequent messages
    // will be sent.
    rpc FetchJWTBundles(JWTBundlesRequest) returns (stream JWTBundlesResponse);

    // Validates a JWT-SVID against the requested audience. Returns
    // the SPIFFE ID of the JWT-SVID and JWT claims.
    rpc ValidateJWTSVID(ValidateJWTSVIDRequest) returns (ValidateJWTSVIDResponse);

    // ... other profiles RPCs ...
}

message JWTSVIDRequest {
    // Required. The audience the workload intends to authenticate against.
    repeated string audience = 1;

    // Optional. The requested SPIFFE ID for the JWT-SVID. If unset, JWT-SVIDs
    // for all identities the workload is entitled to are returned.
    string spiffe_id = 2;
}

// The JWTSVIDResponse message conveys JWT-SVIDs.
message JWTSVIDResponse {
    // The list of returned JWT-SVIDs.
    repeated JWTSVID svids = 1;
}

// The JWTSVID message carries the JWT-SVID token and associated metadata.
message JWTSVID {
    // The SPIFFE ID of the JWT-SVID.
    string spiffe_id = 1;

    // Encoded JWT using JWS Compact Serialization.
    string svid = 2;
}

// The JWTBundlesRequest message conveys parameters for requesting JWT bundles.
// There are currently no such parameters.
message JWTBundlesRequest { }

// The JWTBundlesReponse conveys JWT bundles.
message JWTBundlesResponse {
    // JWK encoded JWT bundles, keyed by the SPIFFE ID of the Trust Domain.
    map<string, bytes> bundles = 1;
}

// The ValidateJWTSVIDRequest message conveys request parameters for
// JWT-SVID validation.
message ValidateJWTSVIDRequest {
    // Required. The audience of the validating party. The JWT-SVID must
    // contain an audience claim which contains this value in order to
    // succesfully validate.
    string audience = 1;

    // Required. The JWT-SVID to validate, encoded using JWS Compact
    // Serialization.
    string svid = 2;
}

// The ValidateJWTSVIDReponse message conveys the JWT-SVID validation results.
message ValidateJWTSVIDResponse {
    // The SPIFFE ID of the validated JWT-SVID.
    string spiffe_id = 1;

    // Arbitrary claims contained within the payload of the validated JWT-SVID.
    google.protobuf.Struct claims = 2;
}
```

All fields in the JWTSVID, JWTSVIDResponse, and ValidateJWTSVIDResponse messages are mandatory. Clients which encounter a field with a default value in any of these messages SHOULD report an error and discard the message.

The `audience` field in the JWTSVIDRequest message is mandatory, as well as the `audience` and `svid` fields in the ValidateJWTSVIDRequest message. Workload API implementations MUST reject requests in which these fields are not set with gRPC error code InvalidArgument.

The `JWTBundlesResponse` message MUST contain at least one trust bundle.  If the client is not entitled to receive any JWT bundles, the server SHOULD respond with the "PermissionDenied" gRPC status code.

### 6.5 Default Values and Redacted Information

SPIFFE Workload API clients may at times encounter fields in the response message that have a default value, or may notice that information included in a previous response is not included in the latest response. For instance, a client may encounter a missing bundle value that was previously received in the `bundles` from the `FetchJWTBundles` RPC.

Since every message MUST include the full set of information (see the [Workload API Client and Server Behavior](#51-workload-api-client-and-server-behavior) section), clients SHOULD interpret the absence of data as a redaction. As an example, if a client has loaded a bundle for `spiffe://foo.bar`, and receives a message that does not include a bundle for `spiffe://foo.bar`, then the bundle SHOULD be unloaded.

If the server redacts all trust bundles from a client using the `FetchJWTBundles` RPC, it SHOULD send the "PermissionDenied" gRPC status code (terminating the gRPC response stream). The client SHOULD cease using the redacted trust bundles. The client MAY attempt to reconnect with another call to the `FetchJWTBundles` RPC after a backoff.

## Appendix A. Sample Implementation State Machines

In order to provide clarity, the authors thought it would be useful to include sample state diagrams of both client and server implementations of the SPIFFE Workload API. It should be noted that there are many ways in which this may be implemented while remaining conformant to this specification, and that this particular implementation is for reference only.

### Server State Machine

![Sample server implementation](https://github.com/evan2645/spiffe/blob/aa1ed9f389b31bae5c75919993d1adb4ce924f88/standards/img/workload_api_server_diagram.png)
1. The SPIFFE Workload Endpoint listener is starting.
2. The gRPC server is started with the SPIFFE Workload API handler, and is now accepting connections.
3. An incoming FetchX509SVIDRequest is being validated. This includes checking for the mandatory security header, and ensuring that the caller has an identity available to it.
4. The Workload API is sending a FetchX509SVIDResponse to the client.
5. The Workload API is in a waiting state. Transitioning out of the waiting state requires an interrupt or a cancellation. A typical reason to interrupt the waiting state is that the information contained in the response has been updated (e.g. an SVID has rotated, or a CRL has changed).
6. Validation is being performed on a pending response. Ensure that the client is still entitled to an identity and that the request has not been cancelled.
7. The server is closing the stream, providing the client with the correct error code for the condition encountered.
8. The server has encountered an fatal condition and must stop. This can occur if the listener could not be created, or if the gRPC server encounters a fatal error.

### Client State Machine

![Sample client implementation](https://github.com/evan2645/spiffe/blob/aa1ed9f389b31bae5c75919993d1adb4ce924f88/standards/img/workload_api_client_diagram.png)
1. The Workload API client is dialing the SPIFFE Workload Endpoint.
2. The client is invoking the FetchX509SVID RPC call, sending a request to the server.
3. The client is blocked on receiving an X509SVIDResponse message from the server.
4. The client is updating its configuration with the SVIDs, CRLs, and Bundles received in the server response. It may at this time compare the received information to the current configuration to determine if a reload is necessary.
5. The client has encountered a fatal condition and must exit.
6. The client is performing an exponential backoff.
