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
5.4. [Profile Messages](#54-profile-messages)  
5.5. [Default Values and Redacted Information](#55-default-values-and-redacted-information)  
Appendix A. [Sample Implementation State Machines](#appendix-a-sample-implementation-state-machines)  

## 1. Introduction

The SPIFFE Workload API is an API which provides information and services that enable workloads, or compute processes, to leverage SPIFFE identities and SPIFFE-based authentication systems. It is served by the [SPIFFE Workload Endpoint](SPIFFE_Workload_Endpoint.md), and comprises a number of services, or *profiles*.

Currently, only one profile is defined: the [X.509-SVID Profile](#5-x509-svid-profile). As such, supporting this profile is mandatory. Future versions of this specification may introduce additional profiles, and the X.509-SVID Profile may become optional.

## 2. Extensibility

The SPIFFE Workload API MUST NOT be extended beyond this specification. Implementers wishing to provide extended functionality may do so by introducing new gRPC services, according to the [extensibility method](SPIFFE_Workload_Endpoint.md#7-extensibility-and-services-rendered) outlined in the SPIFFE Workload Endpoint specification.

## 3. Service Definition

The SPIFFE Workload API service definition is captured as a Protocol Buffer version 3 (proto3), defined below. Please see the individual Workload API Profiles for message definitions associated with each method.

```protobuf
syntax = "proto3";

message X509SVIDRequest {  }

service SpiffeWorkloadAPI {
    // X.509-SVID Profile
    // Fetch all SPIFFE identities the workload is entitled to, as
    // well as related information like trust bundles and CRLs. As
    // this information changes, subsequent messages will be sent.
    rpc FetchX509SVID(X509SVIDRequest) returns (stream X509SVIDResponse);
}
```


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

The X.509-SVID Profile will always provide a Trust Bundle for the Trust Domain in which an SVID resides, however, it may also provide bundles for foreign Trust Domains. This enables workloads to communicate *across* Trust Domains, and is the primary mechanism through which federation is enabled. A bundle representing a foreign Trust Domain is known as a *Federated Bundle*.

When authenticating a client from a foreign trust domain, the authenticator chooses the bundle representing the client’s presented trust domain for validation. Similarly, when authenticating a server, the client uses the bundle representing the server’s trust domain. If no matching bundle is present for the SVID in use, then the peer is untrusted. This approach is required in order to account for the lack of widespread support for SAN URI Name Constraints in common X.509 libraries. Please see [Section 4.2](X509-SVID.md#42-name-constraints) of the X509-SVID specification for more information.

### 5.3 Default Identity

It is often the case that a workload doesn’t know what identity it should assume. Determining when to assume what identity is a site-specific concern, and as a result, the SPIFFE specifications don’t reason about how to do this.

In order to support the widest variety of use cases, the X.509-SVID Profile supports the issuance of multiple identities, while also defining a default identity. It is expected that workloads which are aware of multiple identities can handle decision making on their own. Workloads which don’t understand how to leverage multiple identities may use the default identity. The default identity is the first in the list. Protocol buffers ensure that the order of the list is preserved.

### 5.4 Profile Messages

The X.509-SVID Profile messages are expressed as a Protocol Buffer version 3 (proto3). They are defined below. For the specific service definition for this profile, please see the SPIFFE Workload API [Service Definition](#3-service-definition).

```protobuf
// The X509SVIDResponse message carries a set of X.509 SVIDs and their
// associated information. It also carries a set of global CRLs, and a
// TTL to inform the workload when it should check back next.
message X509SVIDResponse {
    // A list of X509SVID messages, each of which includes a single
    // SPIFFE Verifiable Identity Document, along with its private key
    // and bundle.
    repeated X509SVID svids = 1;

    // ASN.1 DER encoded
    repeated bytes crl = 2;

    // CA certificate bundles belonging to foreign Trust Domains that the
    // workload should trust, keyed by the SPIFFE ID of the foreign
    // domain. Bundles are ASN.1 DER encoded.
    map<string, bytes> federated_bundles = 3;
}

// The X509SVID message carries a single SVID and all associated
// information, including CA bundles.
message X509SVID {
    // The SPIFFE ID of the SVID in this entry
    string spiffe_id = 1;

    // ASN.1 DER encoded certificate chain. MAY include intermediates,
    // the leaf certificate (or SVID itself) MUST come first.
    bytes x509_svid = 2;

    // ASN.1 DER encoded PKCS#8 private key. MUST be unencrypted.
    bytes x509_svid_key = 3;

    // CA certificates belonging to the Trust Domain
    // ASN.1 DER encoded
    bytes bundle = 4;

}
```


All fields in the `X509SVID` message are mandatory, and MUST contain a non-default value. Clients receiving an `X509SVID` message in which any field has a default value SHOULD report an error and discard the message.

The only mandatory field in the `X509SVIDResponse` message is the `svids` field. If the client is not entitled to an SVID, then the server SHOULD respond with the "PermissionDenied" gRPC status code (see the [Error Codes](SPIFFE_Workload_Endpoint.md#6-error-codes) section in the SPIFFE Workload Endpoint specification for more information). The `crl` field and the `federated_bundles` field are optional, and may contain a default value.

### 5.5 Default Values and Redacted Information

SPIFFE Workload API clients may at times encounter fields in the `X509SVIDResponse` message that have a default value, or may notice that information included in a previous response is not included in the latest response. For instance, a client may encounter a default value in the `federated_bundles` field after having previously received a federated bundle.

Since every message MUST include the full set of information (see the [Workload API Client and Server Behavior](#51-workload-api-client-and-server-behavior) section), clients SHOULD interpret the absence of data as a redaction. As an example, if a client has loaded a federated bundle for `spiffe://foo.bar`, and receives a message that does not include a bundle for `spiffe://foo.bar`, then the bundle SHOULD be unloaded.

If the server redacts all SVIDs from a workload, it SHOULD send the "PermissionDenied" gRPC status code (terminating the gRPC response stream). The client SHOULD cease using the redacted SVIDS. The client MAY attempt to reconnect with another call to the FetchX509SVID RPC after a backoff.

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
