# The SPIFFE Workload Endpoint

## Status of this Memo

This document specifies an identity endpoint standard for the internet community, and requests discussion and suggestions for improvements. Distribution of this document is unlimited.

## Abstract

Portable and interoperable cryptographic identity for networked workloads is perhaps *the* core use case for SPIFFE. In order to wholly address this requirement, the community must converge upon a standardized way to both retrieve identity and consume identity-related services at runtime.

The SPIFFE Workload Endpoint specification addresses this by defining an endpoint from which SPIFFE verifiable identity documents (SVIDs) and related services may be served. Specifically, it outlines how to locate the endpoint, and how to serve or consume with it. The exact set of services exposed by this endpoint is out of scope for this document, with the notable exception of the [SPIFFE Workload API](SPIFFE_Workload_API.md).

## Table of Contents

1\. [Introduction](#1-introduction)  
2\. [Accessibility](#2-accessibility)  
3\. [Transport](#3-transport)  
3.1. [Transport Security](#31-transport-security)  
4\. [Locating the Endpoint](#4-locating-the-endpoint)  
5\. [Authentication](#5-authentication)  
6\. [Error Codes](#6-error-codes)  
7\. [Extensibility and Services Rendered](#7-extensibility-and-services-rendered)  
Appendix A. [List of Error Codes](#appendix-a-list-of-error-codes)  

## 1. Introduction

The SPIFFE Workload Endpoint is an API endpoint through which a workload, or running compute process, may access identity-related services (such as identity issuance or identity validation) at runtime. Any number of identity-related services may be exposed by this endpoint, though at a bare minimum, workloads running in compliant environments can expect availability of the [SPIFFE Workload API](SPIFFE_Workload_API.md).

This document details the accessibility and scope of the SPIFFE Workload Endpoint, its transport protocol, authentication procedure, and extensibility/discovery mechanism.

## 2. Accessibility

The SPIFFE Workload Endpoint often serves as the mechanism for initial identity bootstrapping, including the delivery and management of roots of trust. Since a workload in its early stages may have no prior knowledge of its identity or whom it should trust, it is very difficult to secure access to the endpoint. As a result, the SPIFFE Workload Endpoint SHOULD be exposed through a local endpoint, and implementers SHOULD NOT expose the same endpoint instance to more than one host. Keeping the endpoint and related traffic confined to a single host mitigates bootstrap problems as they relate to initial authentication and issuance security. Please see the [Transport](#3-transport) and [Authentication](#5-authentication) sections for more detail.

## 3. Transport

The SPIFFE Workload Endpoint MUST be served over gRPC, and compliant clients MUST support gRPC. It may be exposed as either a Unix Domain Socket (UDS) or a TCP listen socket. Implementations SHOULD prefer Unix Domain Socket transport, however TCP is supported for implementations in which Unix Domain Sockets are impractical or impossible. TCP transport MUST NOT be used unless the underlying network allows the Workload Endpoint server to strongly authenticate the workload based on source IP address (e.g., over a localhost or link-local network), or other strong network-level assertions (e.g., via an SDN policy). 

As a hardening measure against [Server Side Request Forgery](https://www.owasp.org/index.php/Server_Side_Request_Forgery) (SSRF) attacks, every client request to the SPIFFE Workload Endpoint MUST include the static gRPC metadata key `workload.spiffe.io` with a value of `true` (case sensitive). Requests not including this metadata key/value MUST be rejected by the SPIFFE Workload Endpoint (see the [Error Codes](#6-error-codes) section for more information). This prevents an attacker from exploiting an SSRF vulnerability to access the SPIFFE Workload Endpoint unless the vulnerability also gives the attacker control over outgoing gRPC metadata.

### 3.1 Transport Security

Transport Layer Security MUST NOT be required, despite the fact that gRPC strongly prefers it. Since the SPIFFE Workload Endpoint often delivers and manages roots of trust, we can not expect the workload to have advanced knowledge of active roots. As a result, the workload may have no way of validating the authenticity of the presented identity in early stages, except by virtue of the privileged position of the Workload API implementation. This is another reason that SPIFFE Workload Endpoint instances should not be exposed to more than a single host. Please see the [Authentication](#5-authentication) section for more information.

## 4. Locating the Endpoint

Clients may be explicitly configured with the socket location, or may utilize the well-known environment variable `SPIFFE_ENDPOINT_SOCKET`. If not explicitly configured, conforming clients MUST fall back to the environment variable.

The value of the `SPIFFE_ENDPOINT_SOCKET` environment variable is structured as an [RFC 3986](https://www.ietf.org/rfc/rfc3986.txt) URI. The scheme MUST be set to either `unix` or `tcp`, which indicates that the endpoint is served over a Unix Domain Socket or a TCP listen socket, respectively.

If the scheme is set to `unix`, then the authority component MUST NOT be set, and the path component MUST be set to the absolute path of the SPIFFE Workload Endpoint Unix Domain Socket (e.g. `unix:///path/to/endpoint.sock`). The scheme and path components are mandatory, and no other component may be set.

If the scheme is set to `tcp`, then the host component of the authority MUST be set to an IP address, and the port component of the authority MUST be set to the TCP port number of the SPIFFE Workload Endpoint TCP listen socket. The scheme, host, and port components are mandatory, and no other component may be set. As an example, `tcp://127.0.0.1:8000` is valid, and `tcp://127.0.0.1:8000/foo` is not.

## 5. Authentication

The SPIFFE Workload Endpoint often serves as the mechanism for initial identity bootstrapping. As a result, it is expected that the workload does not have any "secret" material which it can use to authenticate itself. To accommodate this very important use case, the SPIFFE Workload Endpoint MUST NOT require any direct authentication of its clients. 

In place of direct client authentication, implementers SHOULD perform out-of-band authenticity checks. This may include techniques such as kernel introspection or orchestrator interrogation. As an example, it is possible to understand which process is calling the API by examining kernel socket state. Another approach is to allow an orchestrator to place a Unix Domain Socket into a particular container, informing the SPIFFE Workload Endpoint implementation of the container's properties/identity. This information can then be used as an authentication mechanism.

It should be noted that while the method(s) by which this is done is implementation-specific, the chosen method(s) MUST NOT require the workload to actively participate.

## 6. Error Codes

A number of error conditions may be encountered by the client when interacting with the SPIFFE Workload Endpoint. For instance, the client request may have omitted the mandatory security header (see the Transport section for more information), or the SPIFFE Workload Endpoint implementation may still be initializing or otherwise unavailable.

Implementations receiving a client request that does not contain the mandatory security header MUST respond with gRPC status code "InvalidArgument". Clients encountering the "InvalidArgument" status code SHOULD NOT retry, as this indicates that an error has been made in the client implementation, and is not recoverable. 

In the event that the SPIFFE Workload Endpoint implementation is running but unavailable, for instance if it is still initializing or it is performing load shedding, clients will receive the gRPC status code "Unavailable". Clients receiving this code OR clients which are unable to reach the SPIFFE Workload Endpoint MAY retry with a backoff.

Finally, in the event that a SPIFFE Workload Endpoint service does not have an identity defined for a given caller/client, the service SHOULD respond with gRPC code "PermissionDenied". Clients receiving this code MAY retry with a backoff, as such a response could be encountered if the service implementation is eventually consistent.

Please see [Appendix A](#appendix-a-list-of-error-codes) for a summary of error conditions and codes.

## 7. Extensibility and Services Rendered

The SPIFFE Workload Endpoint may expose a variety of identity-related services, such as identity issuance or identity validation. Individual services are exposed through the use of the gRPC/Protobuf service primitive. A new (uniquely named) service must be introduced in order to extend the SPIFFE Workload Endpoint.

Since it is the promise of this specification to provide strong portability, the authors feel that allowing extension of existing logical services works against the spirit of SPIFFE. Should additional functionality be rendered by adding endpoints to existing logical services, a portability guarantee cannot be made in the event that a dependent workload moves from one SPIFFE-compliant environment to another. In light of this, existing gRPC logical services such as the SPIFFE Workload API MUST NOT be extended directly. Rather, the endpoint may be augmented with the addition of independent logical services not described in the SPIFFE specification set.

While all SPIFFE Workload Endpoint implementations MUST expose the SPIFFE Workload API, it may at times be difficult to know what additional services are supported in a given environment. As a result, endpoint implementers SHOULD include support for [gRPC Server Reflection](https://github.com/grpc/grpc/blob/master/doc/server-reflection.md). If a client encounters an endpoint which does not support gRPC Server Reflection, it SHOULD assume that the only available services are those defined in the SPIFFE Workload API.

## Appendix A. List of Error Codes

This section enumerates the various error codes that may be returned by a SPIFFE Workload Endpoint implementation, the conditions under which they may be returned, and how they should be handled. Please see the [Error Codes](#6-error-codes) section as well as the [gRPC Code package documentation](https://godoc.org/google.golang.org/grpc/codes) for more information about these codes.

| Code | Condition | Client Behavior |
| ---- | --------- | -------- |
| InvalidArgument | The gRPC security header is not present in the client request. Please see the [Transport](#3-transport) section for more information. | Report an error, don't retry. |
| Unavailable | The SPIFFE Workload Endpoint implementation is unable to handle the request. | Retry with a backoff. |
| PermissionDenied | The client is not permitted to perform the requested operation. Depending on the implementation, this may indicate that the workload has started before the identity or trust domain has been provisioned. | Retry with a backoff. |
