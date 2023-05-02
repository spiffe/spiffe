# The SPIFFE Workload API

## Status of this Memo

This document specifies an identity API standard for the internet community, and requests discussion and suggestions for improvements. Distribution of this document is unlimited.

## Abstract

Portable and interoperable cryptographic identity for networked workloads is perhaps *the* core use case for SPIFFE. In order to wholly address this requirement, the community must converge upon a standardized way to retrieve, validate, and interact with SPIFFE identities. This specification outlines the API signatures and client/server behavior required in order to support SPIFFE-based authentication systems.

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

The SPIFFE Workload API is an API which provides information and services that enable workloads, or compute processes, to leverage SPIFFE identities and SPIFFE-based authentication systems. It is served by the [SPIFFE Workload Endpoint](SPIFFE_Workload_Endpoint.md), and comprises a number of services, or *profiles*.

Currently, there are two profiles:

- [X.509-SVID Profile](#5-x509-svid-profile)
- [JWT-SVID Profile](#6-jwt-svid-profile)

Both profiles are mandatory and MUST be supported by SPIFFE implementations. However, operators MAY administratively disable a specific profile in their deployment.

Future versions of this specification may introduce additional profiles or make one or more profiles optional.

## 2. Extensibility

The SPIFFE Workload API MUST NOT be extended beyond this specification. Implementers wishing to provide extended functionality may do so by introducing new gRPC services, according to the [extensibility method](SPIFFE_Workload_Endpoint.md#7-extensibility-and-services-rendered) outlined in the SPIFFE Workload Endpoint specification.

## 3. Service Definition

The SPIFFE Workload API is defined by a Protocol Buffer (version 3) service definition. The complete definition is found in [workloadapi.proto](workloadapi.proto).

Profiles are implemented as a group of related RPCs within a single `WorkloadAPI` service.

## 4. Client and Server Behavior

### 4.1 Identifying the Caller

The SPIFFE Workload API supports any number of local clients, allowing it to bootstrap the identity of any process that can reach it. Typically, it is desirable to assign identities on a per-process basis, where certain processes are granted certain identities. In order to do this, the SPIFFE Workload API implementation must be able to ascertain the identity of the caller.

The SPIFFE Workload Endpoint specification mandates the absence of direct client authentication, instead relying on out-of-band authenticity checks. As a result, it is the responsibility of the SPIFFE Workload Endpoint implementation to identify the caller. Information about the caller can then be used by the SPIFFE Workload API to determine the appropriate content to serve. For more information, please see the [Authentication](SPIFFE_Workload_Endpoint.md#5-authentication) section of the SPIFFE Workload Endpoint specification.

### 4.2 Connection Lifetime

Clients of the SPIFFE Workload API SHOULD maintain an open connection for as long as is reasonably possible, waiting on server response messages to be received on the stream. The connection may, at any time, be terminated by either the server or the client. In this case, the client SHOULD immediately establish a new connection. This helps ensure that the workload retains the most up-to-date set of identity related materials. SPIFFE Workload API server implementors may assume this property, and by not receiving messages in a timely manner, the workload may fall out-of-date, potentially impacting its availability.

### 4.3 Stream Responses

The SPIFFE Workload API includes RPCs utilizing gRPC server-side streams in order to facilitate rapid propagation of updates like revocations and CA certificate introductions. This enables clients to loop over server responses, accepting updated responses as they occur.

Every stream response message sent by the server MUST include the full set of information, and not just the information which has changed. This avoids complexity associated with state tracking on both Client and Server implementations, including the need for anti-entropy mechanisms.

The exact timing of server response messages is implementation-specific, and SHOULD be dictated by events which change the response, such as an SVID rotation, a CRL update, etc. Receiving a request message from the client MUST be considered a response-generating event. In other words, the first response message of the server response stream (on a connection-by-connection basis) MUST be sent as soon as possible, without delay.

Finally, implementers of SPIFFE Workload API servers should be careful about pushing updated response messages *too* rapidly. Some software may reload automatically upon receiving new information, potentially causing a period of unavailability should all instances reload at once. As a result, implementers may introduce some splay/jitter in the transmission of widespread updates.

For additional clarity, please see [Appendix A](#appendix-a.-sample-implementation-state-machines) for sample implementation state machines.

### 4.4 Default Values and Redacted Information

SPIFFE Workload API response messages are complete updates to previously sent response messages. When a response message contains fields which are set to default or empty values, clients MUST interpret the values of those fields to have been set to their default or empty values; previously received, non-default or non-empty values MUST NOT be retained by a client after receiving a default or empty value for the fields. For instance, a client receiving a default value in the `federated_bundles` field should discard the previously received `federated_bundles` value.

Since every message MUST include the full set of information (see the [Stream Responses](#42-stream-responses) section), clients SHOULD interpret the absence of data as a redaction. As an example, if a client has loaded a bundle for `spiffe://foo.bar`, and receives a message that does not include a bundle for `spiffe://foo.bar`, then the bundle SHOULD be unloaded.

### 4.5 Mandatory Fields

Messages exchanged for the profile RPCs are comprised of both mandatory and optional fields. Servers receiving a message in which a mandatory field has a default value SHOULD respond with the "InvalidArgument" gRPC status code (see the [Error Codes](SPIFFE_Workload_Endpoint.md#6-error-codes) section in the SPIFFE Workload Endpoint specification for more information). Clients receiving a message in which a mandatory field has a default value SHOULD report an error and discard the message.

### 4.6 Federated Bundles

Various RPCs defined in this specification can return trust bundles for foreign trust domains. Inclusion of foreign bundles enables workloads to communicate *across* trust domains, and is the primary mechanism through which federation is enabled. A bundle representing a foreign trust domain is known as a *Federated Bundle*.

When authenticating a client, the authenticator chooses the bundle representing the client’s presented trust domain for validation. Similarly, when authenticating a server, the client uses the bundle representing the server’s trust domain. If no matching bundle is present for the SVID in use, then the peer is untrusted. This approach is required in order to account for the lack of widespread support for SAN URI Name Constraints in common X.509 libraries. Please see [Section 4.2](X509-SVID.md#42-name-constraints) of the X509-SVID specification for more information.

## 5. X.509-SVID Profile

The X.509-SVID Profile of the SPIFFE Workload API provides a set of gRPC methods which can be used by workloads to retrieve [X.509-SVIDs](X509-SVID.md) and their related trust bundles. This profile outlines the signature of these methods, as well as related client and server behavior.

### 5.1 Profile Definition

The X.509-SVID Profile RPCs and associated messages are defined below. For the complete Workload API service definition, see [workloadapi.proto](workloadapi.proto).

```protobuf
service SpiffeWorkloadAPI {
    /////////////////////////////////////////////////////////////////////////
    // X509-SVID Profile
    /////////////////////////////////////////////////////////////////////////

    // Fetch X.509-SVIDs for all SPIFFE identities the workload is entitled to,
    // as well as related information like trust bundles and CRLs. As this
    // information changes, subsequent messages will be streamed from the
    // server.
    rpc FetchX509SVID(X509SVIDRequest) returns (stream X509SVIDResponse);

    // Fetch trust bundles and CRLs. Useful for clients that only need to
    // validate SVIDs without obtaining an SVID for themself. As this
    // information changes, subsequent messages will be streamed from the
    // server.
    rpc FetchX509Bundles(X509BundlesRequest) returns (stream X509BundlesResponse);

    // ... RPCS for other profiles ...
}


// The X509SVIDRequest message conveys parameters for requesting an X.509-SVID.
// There are currently no such parameters.
message X509SVIDRequest {  }

// The X509SVIDResponse message carries X.509-SVIDs and related information,
// including a set of global CRLs and a list of bundles the workload may use
// for federating with foreign trust domains.
message X509SVIDResponse {
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

// The X509BundlesRequest message conveys parameters for requesting X.509
// bundles. There are currently no such parameters.
message X509BundlesRequest {
}

// The X509BundlesResponse message carries a set of global CRLs and a map of
// trust bundles the workload should trust.
message X509BundlesResponse {
    // Optional. ASN.1 DER encoded certificate revocation lists.
    repeated bytes crl = 1;

    // Required. CA certificate bundles belonging to trust domains that the
    // workload should trust, keyed by the SPIFFE ID of the trust domain.
    // Bundles are ASN.1 DER encoded.
    map<string, bytes> bundles = 2;
}
```

### 5.2 Profile RPCs

#### 5.2.1 FetchX509SVID

The `FetchX509SVID` RPC streams back X509-SVIDs, and X.509 bundles for both the trust domain in which the server resides and foreign trust domains. These bundles MUST only be used to authenticate X509-SVIDs.

The `X509SVIDRequest` request message is currently empty and is a placeholder for future expansion.

The `X509SVIDResponse` response consists of a mandatory `svids` field, which MUST contain one or more `X509SVID` messages (one for each identity granted to the client). The `crl` and `federated_bundles` fields are optional. 

All fields in the `X509SVID` message are mandatory, with the exception of the `hint` field. When the `hint` field is set (i.e. non-empty), SPIFFE Workload API servers MUST ensure its value is unique amongst the set of returned SVIDs in any given `X509SVIDResponse` message. In the event that a SPIFFE Workload API client encounters more than one `X509SVID` message with the same `hint` value set, then the first message in the list SHOULD be selected.

If the client is not entitled to receive any X509-SVIDs, then the server SHOULD respond with the "PermissionDenied" gRPC status code (see the [Error Codes](SPIFFE_Workload_Endpoint.md#6-error-codes) section in the SPIFFE Workload Endpoint specification for more information). Under such a case, the client MAY attempt to reconnect with another call to the `FetchX509SVID` RPC after a backoff.

As mentioned in [Stream Responses](#42-stream-responses), each `X509SVIDResponse` message returned on the `FetchX509SVID` stream contains the complete set of authorized SVIDs and bundles for the client at that point in time. As such, if the server redacts SVIDs from a subsequent response (or all SVIDs, i.e., returns a "PermissionDenied" gRPC status code) the client SHOULD cease using the redacted SVIDS.

#### 5.2.2 FetchX509Bundles

The `FetchX509Bundles` RPC streams back X.509 bundles for both the trust domain in which the server resides and foreign trust domains. These bundles MUST only be used to authenticate X509-SVIDs.

The `X509BundlesRequest` request message is currently empty and is a placeholder for future expansion.

The `X509BundlesResponse` response message has a mandatory `bundles` field, which MUST contain at least the trust bundle for the trust domain in which the server resides. The `crl` field is optional.

If the client is not entitled to receive any X.509 bundles, then the server SHOULD respond with the "PermissionDenied" gRPC status code (see the [Error Codes](SPIFFE_Workload_Endpoint.md#6-error-codes) section in the SPIFFE Workload Endpoint specification for more information). The client MAY attempt to reconnect with another call to the `FetchX509Bundles` RPC after a backoff.

As mentioned in [Stream Responses](#42-stream-responses), each `X509BundleResponse` response contains the complete set of authorized X.509 bundles for the client at that point in time. As such, if the server redacts bundles from a subsequent response (or all bundles, i.e., returns a "PermissionDenied" gRPC status code) the client SHOULD cease using the redacted bundles.

### 5.3 Default Identity

It is often the case that a workload doesn’t know what identity it should assume. Determining when to assume what identity is a site-specific concern, and as a result, the SPIFFE specifications don’t reason about how to do this.

In order to support the widest variety of use cases, the X.509-SVID Profile supports the issuance of multiple identities, while also defining a default identity. It is expected that workloads which are aware of multiple identities can handle decision making on their own. Workloads which don’t understand how to leverage multiple identities may use the default identity. The default identity is the first in the `svids` list returned in the `X509SVIDResponse` message. Protocol buffers ensure that the order of the list is preserved.

Workloads that understand how to use multiple identities may leverage the optional `hint` field, which can be used to disambiguate identities and inform the workload of which identity should be used for what purpose. For example, `internal` and `external` to denote an SVID for internal or external use, respectively. SPIFFE Workload API implementations SHOULD NOT support values of more than 1024 bytes in length. The exact value of the `hint` field is an operator choice and is otherwise unconstrained by this specification.

It is the workload's responsibility to handle the absence of an expected hint, or the presence of an unexpected one (e.g. fail, warn, etc).

## 6. JWT-SVID Profile

The JWT-SVID Profile of the SPIFFE Workload API provides a set of gRPC methods which can be used by workloads to retrieve JWT-SVIDs and their related trust bundles. This profile outlines the signature of these methods, as well as related client and server behavior.

### 6.1 Profile Definition

The JWT-SVID Profile RPCs and associated messages are defined below. For the complete Workload API service definition, see [workloadapi.proto](workloadapi.proto).

```protobuf
service SpiffeWorkloadAPI {
    /////////////////////////////////////////////////////////////////////////
    // JWT-SVID Profile
    /////////////////////////////////////////////////////////////////////////

    // Fetch JWT-SVIDs for all SPIFFE identities the workload is entitled to,
    // for the requested audience. If an optional SPIFFE ID is requested, only
    // the JWT-SVID for that SPIFFE ID is returned.
    rpc FetchJWTSVID(JWTSVIDRequest) returns (JWTSVIDResponse);

    // Fetches the JWT bundles, formatted as JWKS documents, keyed by the
    // SPIFFE ID of the trust domain. As this information changes, subsequent
    // messages will be streamed from the server.
    rpc FetchJWTBundles(JWTBundlesRequest) returns (stream JWTBundlesResponse);

    // Validates a JWT-SVID against the requested audience. Returns the SPIFFE
    // ID of the JWT-SVID and JWT claims.
    rpc ValidateJWTSVID(ValidateJWTSVIDRequest) returns (ValidateJWTSVIDResponse);

    // ... RPCs for other profiles ...
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
// There are currently no request parameters.
message JWTBundlesRequest { }

// The JWTBundlesReponse conveys JWT bundles.
message JWTBundlesResponse {
    // Required. JWK encoded JWT bundles, keyed by the SPIFFE ID of the trust
    // domain.
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
    // Required. The SPIFFE ID of the validated JWT-SVID.
    string spiffe_id = 1;

    // Required. Claims contained within the payload of the validated JWT-SVID.
    // This includes both SPIFFE-required and non-required claims.
    google.protobuf.Struct claims = 2;
}
```

### 6.2 Profile RPCs

#### 6.2.1 FetchJWTSVID

The `FetchJWTSVID` RPC allows clients to request one or more short-lived JWT-SVIDs for a specific audience.

The `JWTSVIDRequest` request message contains a mandatory `audience` field, which MUST contain the value to embed in the audience claim of the returned JWT-SVIDs. The `spiffe_id` field is optional, and is used to request a JWT-SVID for a specific SPIFFE ID. If unspecified, the server MUST return JWT-SVIDs for all identities authorized for the client. 

The `JWTSVIDResponse` response message consists of a mandatory `svids` field, which MUST contain one or more `JWTSVID` messages.

All fields in the `JWTSVID` message are mandatory, with the exception of the `hint` field. When the `hint` field is set (i.e. non-empty), SPIFFE Workload API servers MUST ensure its value is unique amongst the set of returned SVIDs in any given `JWTSVIDResponse` message. In the event that a SPIFFE Workload API client encounters more than one `JWTSVID` message with the same `hint` value set, then the first message in the list SHOULD be selected.

If the client is not authorized for any identities, or not authorized for the specific identity requested via the `spiffe_id` field, then the server SHOULD respond with the "PermissionDenied" gRPC status code (see the [Error Codes](SPIFFE_Workload_Endpoint.md#6-error-codes) section in the SPIFFE Workload Endpoint specification for more information).

#### 6.2.2 FetchJWTBundles

The `FetchJWTBundles` RPC streams back JWT bundles for both the trust domain in which the server resides and foreign trust domains. These bundles MUST only be used to authenticate JWT-SVIDs.

The `JWTBundlesRequest` request message is currently empty and is a placeholder for future expansion.

The `JWTBundlesResponse` response message consists of a mandatory `bundles` field, which MUST contain at least the JWT bundle for the trust domain in which the server resides.

The returned bundles are encoded as a standard JWK Set as defined by [RFC 7517](https://tools.ietf.org/html/rfc7517) containing the JWT-SVID signing keys for the trust domain. These keys may only represent a subset of the keys present in the SPIFFE trust bundle for the trust domain. The server MUST NOT include keys with other uses in the returned JWT bundles.

If the client is not entitled to receive any JWT bundles, then the server SHOULD respond with the "PermissionDenied" gRPC status code (see the [Error Codes](SPIFFE_Workload_Endpoint.md#6-error-codes) section in the SPIFFE Workload Endpoint specification for more information). The client MAY attempt to reconnect with another call to the `FetchJWTBundles` RPC after a backoff.

As mentioned in [Stream Responses](#42-stream-responses), each `JWTBundleResponse` response contains the complete set of authorized JWT bundles for the client at that point in time. As such, if the server redacts bundles from a subsequent response (or all bundles, i.e., returns a "PermissionDenied" gRPC status code) the client SHOULD cease using the redacted bundles.

#### 6.2.3 ValidateJWTSVID

The `ValidateJWTSVID` RPC validates JWT-SVIDs for a specific audience on behalf of a client. Further, the server MUST parse and validate the JWT-SVID according to the rules outlined in the [JWT-SVID](JWT-SVID.md) specification. The claims embedded in the JWT-SVID payload SHOULD be provided in the `claims` field in the `ValidateJWTSVIDResponse`; the claims defined by this specification above are required, however implementations MAY filter non-SPIFFE claims before returning them to the client. SPIFFE claims are required for interoperability.

All fields in the `ValidateJWTSVIDRequest` and `ValidateJWTSVIDResponse` message are mandatory.

### 6.3 JWT-SVID Validation

Workload API clients SHOULD use the `ValidateJWTSVID` method for JWT validation if supported by the client, allowing the SPIFFE Workload API to perform validation on their behalf. Doing this removes the need for the workload to implement validation logic, which can be error prone.

When interfacing with legacy JWT validators, the `FetchJWTBundles` method can be used to fetch JWKS bundles that can be used to validate JWT-SVID signatures. For instance, if the SPIFFE Workload API is available but the JWT validating software is not aware of the Workload API (and thus cannot call `ValidateJWTSVID`), implementations can instead individually retrieve each bundle and feed them to the legacy workload for validation.

The `FetchJWTBundles` method returns bundles keyed by the SPIFFE ID of the trust domain. When validating a JWT-SVID, the validator MUST use the bundle corresponding to the trust domain of the subject. If a JWT bundle for the specified trust domain is not present, then the token is untrusted.

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
4. The client is updating its configuration with the SVIDs, CRLs, and bundles received in the server response. It may at this time compare the received information to the current configuration to determine if a reload is necessary.
5. The client has encountered a fatal condition and must exit.
6. The client is performing an exponential backoff.
