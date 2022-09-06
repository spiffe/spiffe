# The JWT SPIFFE Verifiable Identity Document

## Status of this Memo
This document specifies an identity document standard for the internet community, and requests discussion and suggestions for improvements. Distribution of this document is unlimited.

## Table of Contents

1\. [Introduction](#1-introduction)  
2\. [JOSE Header](#2-jose-header)  
2.1. [Algorithm](#21-algorithm)  
2.2. [Key ID](#22-key-id)  
2.3. [Type](#23-type)  
3\. [JWT Claims](#3-jwt-claims)  
3.1. [Subject](#31-subject)  
3.2. [Audience](#32-audience)  
3.3. [Expiration Time](#33-expiration-time)  
4\. [Token Signing and Validation](#4-token-signing-and-validation)  
5\. [Token Transmission](#5-token-transmission)  
5.1. [Serialization](#51-serialization)  
5.2. [HTTP](#52-http)  
5.3. [gRPC](#53-grpc)  
6\. [Representation in the SPIFFE Bundle](#6-representation-in-the-spiffe-bundle)  
6.1. [Publishing SPIFFE Bundle Elements](#61-publishing-spiffe-bundle-elements)  
6.2. [Consuming a SPIFFE Bundle](#62-consuming-a-spiffe-bundle)  
7\. [Security Considerations](#7-security-considerations)  
7.1. [Replay Protection](#71-replay-protection)  
7.2. [Audience](#72-audience)  
7.3. [Transport Security](#73-transport-security)  
Appendix A. [Validation Reference](#appendix-a-validation-reference)  

## 1. Introduction
JWT-SVID is the first token-based SVID in the SPIFFE specification set. Aimed at providing immediate value in solving difficulties associated with asserting identity across Layer 7 boundaries, compatibility with existing applications and libraries is a core requirement.

JWT-SVIDs are standard JWT tokens with a handful of restrictions applied. JOSE has historically proven difficult to implement securely, gaining a reputation in the security community as a technology which is likely to introduce vulnerabilities in its deployments and implementations. JWT-SVID takes steps to mitigate these problems as much as is reasonably possible without breaking compatibility with existing applications and libraries.

JWT-SVIDs are JSON Web Signature (JWS) data structures utilizing JWS Compact Serialization in all cases. JWS JSON Serialization MUST NOT be used.

## 2. JOSE Header
Historically, complexity introduced by the cryptographic agility of the JOSE header has led to a series of vulnerabilities in popular JWT implementations. To avoid such pitfalls, this specification restricts some of the allowances originally afforded. This section describes the permitted registered headers, as well as their values. Any header not described here, registered or private, MUST NOT be included in the JWT-SVID JOSE Header.

Only JWS is supported.

### 2.1. Algorithm
The `alg` header MUST be set to one of the values defined in [RFC 7518][7] sections [3.3][8], [3.4][9], or [3.5][10]. Validators receiving a token with the `alg` parameter set to a different value MUST reject the token.

The supported `alg` values are:

`alg` Param Value | Digital Signature Algorithm
------------------|-----------------------------
RS256 | RSASSA-PKCS1-v1_5 using SHA-256
RS384 | RSASSA-PKCS1-v1_5 using SHA-384
RS512 | RSASSA-PKCS1-v1_5 using SHA-512
ES256 | ECDSA using P-256 and SHA-256
ES384 | ECDSA using P-384 and SHA-384
ES512 | ECDSA using P-521 and SHA-512
PS256 | RSASSA-PSS using SHA-256 and MGF1 with SHA-256
PS384 | RSASSA-PSS using SHA-384 and MGF1 with SHA-384
PS512 | RSASSA-PSS using SHA-512 and MGF1 with SHA-512

### 2.2. Key ID
The `kid` header is optional.

### 2.3. Type
The `typ` header is optional. If set, its value MUST be either `JWT` or `JOSE`.

## 3. JWT Claims
The JWT-SVID specification does not introduce any new claims, though it does set some restrictions on the registered claims defined by [RFC 7519][1]. Registered claims not described in this document, in addition to private claims, MAY be used as implementers see fit. It should be noted, however, that reliance on claims which are not defined here may impact interoperability, as the producing and consuming applications must independently agree. Implementers should exercise caution when introducing additional claims and carefully consider the impact on SVID interoperability, particularly in environments where the implementer does not control both the producer and the consumer. If the use of additional claims is absolutely necessary, they should be made collision-resistant per [RFC 7519][1] recommendations.

This section outlines the requirements and restrictions placed upon existing registered claims by the JWT-SVID specification.

### 3.1. Subject
The `sub` claim MUST be set to the SPIFFE ID of the workload to which it is issued. This is the primary claim against which workload identity is asserted.

### 3.2. Audience
The `aud` claim MUST be present, containing one or more values. Validators MUST reject tokens without an `aud` claim set, or if the value that the validator identifies with is not present as an `aud` element. It is strongly recommended that the number of values be limited to one in normal cases. Please see the Security Considerations section for more information.

The values chosen are site-specific, and SHOULD be scoped to the service which it is intended to be presented to. For example, `reports` or `spiffe://example.org/reports` are suitable values for tokens which are presented to the reports service. Values such as `production` or `spiffe://example.org/` are discouraged due to their wide scope, opening the possibility for impersonation if just a single service in `production` is compromised.

### 3.3. Expiration Time
The `exp` claim MUST be set, and validators MUST reject tokens without this claim. Implementers are encouraged to keep the validity period as small as is reasonably possible, however this specification does not set any hard upper limits on its value.

## 4. Token Signing and Validation
JWT-SVID signing and validation semantics are the same as regular JWTs/JWSs. Validators MUST ensure that the `alg` header is set to a supported value before processing.

JWT-SVID signatures are computed and validated following the steps outlined in [RFC 7519 section 7][2]. The `aud` and `exp` claims MUST be present and processed according to [RFC 7519][1] sections [4.1.3][3] and [4.1.4][4]. Validators receiving tokens without the `aud` and `exp` claims set MUST reject the token.

## 5. Token Transmission
This section describes the manner in which a JWT-SVID may be transmitted from one workload to another.

### 5.1. Serialization
JWT-SVIDs MUST be serialized using the Compact Serialization method described in [RFC 7515 Section 3.1][5], as required by [RFC 7519 Section 1][12]. Note that this precludes the use of a JWS Unprotected Header, as mandated in the [JOSE Header](#2-jose-header) section.

### 5.2. HTTP
JWT-SVIDs transmitted via HTTP SHOULD be transmitted in the “Authorization” header (“authorization” for HTTP/2) using the “Bearer” authentication scheme defined in [RFC 6750 section 2.1][6]. For example, `Authorization: Bearer <serialized_token>` in HTTP/1.1 and `authorization: Bearer <serialized_token>` in HTTP/2.

### 5.3. gRPC
The gRPC protocol uses HTTP/2. As a result, the HTTP transmission guidelines in the [HTTP section](#52-http) equally apply. Concretely, gRPC implementations SHOULD set a metadata key `authorization` with a value of `Bearer <serialized_token>`.

## 6. Representation in the SPIFFE Bundle
This section describes how JWT-SVID signing keys are published to and consumed from a SPIFFE bundle. Please see the [SPIFFE Trust Domain and Bundle](SPIFFE_Trust_Domain_and_Bundle.md) specification for more information about SPIFFE bundles.

### 6.1. Publishing SPIFFE Bundle Elements
JWT-SVID signing keys for a given trust domain are represented in the SPIFFE bundle as [RFC 7517][11]-compliant JWK entries, one entry per signing key.

The `use` parameter of each JWK entry MUST be set to `jwt-svid`. Additionally, the `kid` parameter of each JWK entry MUST be set.

### 6.2. Consuming a SPIFFE Bundle
SPIFFE bundles may contain JWK entries for many different SVID types. Implementations MUST extract the JWT-SVID specific keys before using them for validation purposes. Entries representing JWT-SVID signing keys can be identified by the value of their `use` parameter, which must be `jwt-svid`. If there are no entries with the `jwt-svid` use value, then the trust domain that the bundle represents does not support JWT-SVID.

Once the JWK entries are extracted, they can be used directly for JWT-SVID validation as described in [RFC 7517][11].

## 7. Security Considerations
This section outlines the security considerations that implementers and users should take into account when using JWT-SVID.

### 7.1. Replay Protection
Being a bearer token, JWT-SVIDs are susceptible to replay attacks. By requiring that the `aud` and `exp` claims be set, this specification has taken steps to improve the situation, but is unable to solve it completely while retaining validation compatibility with [RFC 7515][1]. It is very important to understand this risk. Use of an aggressive value for the `exp` claim is recommended. Some users may wish to leverage the `jti` claim despite the added overhead. While use of the `jti` claim is permitted by this specification, it should be noted that JWT-SVID validators are not required to track `jti` uniqueness.

### 7.2. Audience
There is an implicit trust granted to recipients of JWT-SVIDs. Tokens sent to one audience can be replayed to another audience should more than one be present. For example, if Alice has a token with audiences Bob and Chuck, and transmits that token to Chuck, then Chuck can impersonate Alice by sending the same token to Bob. As such, care should be taken when minting a JWT-SVID with more than one audience. Single audience JWT-SVID tokens are strongly recommended to limit the scope of replayability.

### 7.3. Transport Security
JWT-SVIDs share the same risks as other bearer token schemes, namely interception of the bearer token grants an attacker the full privileges afforded by the JWT-SVID due to their inherent replay-ability. There are mitigations to limit the impact, such as mandated expiration via the `exp` claim but there will always be a window of vulnerability. For this reason, all hops/links along the communication channels over which JWT-SVIDs are transmitted should provide confidentiality (e.g. from workload to load balancer, from the load balancer to another workload). Notable exceptions are non-network links with reasonable security assumptions regarding exposure, for example a Unix domain socket between two processes within the same host.

## Appendix A. Validation Reference
The following table provides a quick reference for anyone implementing a JWT-SVID validator. If using an off-the-shelf library, it is the responsibility of the implementer to ensure that the following validation steps are being taken.

Additionally, please see the [JWT-SVID Schema](JWT-SVID.schema) for a more formal reference.

Field | Type | Requirement
------|------|------------
`alg` | `Header` | Set to one of the values in the table in section [2.1](#21-algorithm). Reject otherwise.
`aud` | `Claim` | At least one value present. Users should configure at least one acceptable value in advance. Reject otherwise.
`exp` | `Claim` | Must be set. Must not be in the past (a small amount of leeway is acceptable). Reject otherwise.

[1]: https://tools.ietf.org/html/rfc7519
[2]: https://tools.ietf.org/html/rfc7519#section-7
[3]: https://tools.ietf.org/html/rfc7519#section-4.1.3
[4]: https://tools.ietf.org/html/rfc7519#section-4.1.4
[5]: https://tools.ietf.org/html/rfc7515#section-3.1
[6]: https://tools.ietf.org/html/rfc6750#section-2.1
[7]: https://tools.ietf.org/html/rfc7518
[8]: https://tools.ietf.org/html/rfc7518#section-3.3
[9]: https://tools.ietf.org/html/rfc7518#section-3.4
[10]: https://tools.ietf.org/html/rfc7518#section-3.5
[11]: https://tools.ietf.org/html/rfc7517
[12]: https://tools.ietf.org/html/rfc7519#section-1
