# Best Current Practice - Selecting an SVID format

## Status of this Memo
This document provides information and guidance on the selection of [SPIFFE Verifiable Identity Document](/standards/SPIFFE.md#3-the-spiffe-verifiable-identity-document) (SVID) formats for use across common workload identity scenarios. Distribution of this document is unlimited.

## Abstract
The SPIFFE standard specifies multiple compliant SVID formats. Selection of the most appropriate for use is dependent on numerous factors, including but not limited to: client library availability, desired security properties, interoperability, certificate vs. token semantics, and the nature of expected workload-to-workload networking.

This document outlines the best current practices to consider when selecting an SVID format for use in a SPIFFE-based identity system.

## Table of Contents

1\. [Background](#1-background)  
2\. [Overview of Formats](#2-overview-of-formats)  
2.1. [X.509-SVID](#21-x509-svid)  
2.2. [JWT-SVID](#22-jwt-svid)  
2.3. [WIT-SVID](#23-wit-svid)  
3\. [Comparison Matrix](#3-compirison-matrix)  
4\. [Selection Criteria](#4-selection-criteria)  
4.1 [When to use X.509-SVID](#41-when-to-use-x509-svid)  
4.2 [When to use JWT-SVID](#42-when-to-use-jwt-svid)  
4.3 [When to use WIT-SVID](#43-when-to-use-wit-svid)  
4.4 [Heuristics](#44-heuristics)  
5\. [Security Considerations](#5-security-considerations)  
5.1 [Threat Models](#51-threat-models)  
5.2 [Mitigations](#52-mitigations)  
6\. [Appendix](#6-appendix)  

## 1. Background
The [SPIFFE standard](/standards/SPIFFE.md) defines support for multiple SVID formats:

* [X.509-SVID](/standards/X509-SVID.md)
* [JWT-SVID](/standards/JWT-SVID.md)
* WIT-SVID (Workload Identity Token)

This has been an additive process over the history of SPIFFE. The standard was originally written with X.509-SVID as the only supported SVID format, and JWT-SVID was subsequently added as the first token-based SVID to aid in interoperability with Layer 7 networking.

More recently, WIT-SVID has been proposed as an additional token-based SVID format to make use of authentication concepts developed as part of the IETF [Workloads In Multi-System Environments (WIMSE)](https://datatracker.ietf.org/group/wimse/documents/) working group. This represents an enhancement over the existing JWT-SVID semantics by codifying proof-of-possession information as part of the mandatory claims of the token.

## 2. Overview of Formats
This section provides a brief description of the available SVID formats for contextual and comparative clarity. Full specification details for each can be found in their corresponding standardization (linked) documents.

### 2.1 X.509-SVID
[X.509-SVIDs](/standards/X509-SVID.md) are short-lived X.509 certificates containing a SPIFFE ID in the Subject Alternative Name. They are issued by the certificate authority (CA) of their SPIFFE trust domain, and used to authenticate during mutual TLS (mTLS) between workloads.

Casting SVID information to an X.509 certificate format also allows for transport-level encryption to be used between peers with mutual TLS support, meaning X.509-SVIDs enable secure communication in transit between workloads that have such capabilities.

### 2.2 JWT-SVID
[JWT-SVIDs](/standards/JWT-SVID.md) are signed JSON Web Tokens (JWT) containing a SPIFFE ID in the `sub` claim. It is issued and signed by the JWT issuer of the SPIFFE trust domain, and is used to authenticate in the application layer between workloads.

JWT-SVIDs are bearer tokens, and do not enable any kind of encryption or cryptographic protection against impersonation. Various recommendations exist to mitigate against known vulnerabilities of the JWT as an identity token, and should be followed when JWT-SVIDs are used in SPIFFE.

### 2.3 WIT-SVID
WIT-SVIDs are signed JWTs containing a SPIFFE ID in the `sub` claim and a public key binding, with proof-of-possession metadata regarding the signing key available in a `cnf` claim.

WIT-SVIDs differ from JWT-SVIDs in that they are proof-of-possession tokens (i.e. **not** bearer tokens). This provides enhanced security guarantees about caller provenance, integrity, and non-repudiation while still maintaining the interoperability of using token-based authentication in the application layer.

## 3. Comparison Matrix

|                       | X.509-SVID                                     | JWT-SVID                                              | WIT-SVID                                                   |
|-----------------------|------------------------------------------------|-------------------------------------------------------|------------------------------------------------------------|
| **Primary use**       | Transport-level identity (mTLS)                | Request/API-level identity (bearer)                   | Request/API-level identity with proof-of-possession        |
| **Layer**             | Transport                                      | Application                                           | Application                                                |
| **Format**            | X.509 certificate                              | Signed JWT                                            | Signed JWT with public key binding                         |
| **Token semantics**   | Holder-of-key (private key bound to cert)      | Bearer token                                          | Holder-of-key (private key bound to token)                 |
| **Rotation**          | Frequent, automatic                            | Short-lived tokens                                    | Short-lived tokens, key material                           |
| **Verification**      | Certificate chain                              | JWS signature, claims                                 | JWS signature, claims, proof-of-possession                 |
| **Replay resistance** | Strong: TLS handshake, key possession          | Weak: stateless token expiry                          | Strong: key possession                                     |
| **Maturity**          | High                                           | High                                                  | Emerging                                                   |

## 4. Selection Criteria
This section provides guidance on scenarios where a single SVID format can be considered favorable when compared with the alternatives. This should not be considered exhaustive, and there are likely to be cases where multiple or any of the formats could be argued to be suitable.

### 4.1 When to use X.509-SVID
X.509-SVIDs are the preferred choice for systems requiring transport layer authentication and automated credential rotation. Deployment contexts where these might be considerations include:

* Mutual TLS is desirable or already in use (e.g. service meshes),
* Workload-to-workload connections are persistent and long-lived,
* All workloads have TLS capabilities (either natively or via enabling process such as proxies)

### 4.2 When to use JWT-SVID
JWT-SVIDs are the preferred choice for systems where application layer authentication is required (in contrast to authentication in the transport layer). This might apply when:

* Systems do not have native or platform-enabled TLS support across all workloads,
* Identity metadata needs to be inspected in-flight to perform actions such as routing and proxying,
* Used in highly heterogeneous environments where third party identity integration (e.g. OIDC) is common

Layer 7 networking is the typical context requiring token-based authentication throughout each of the participating applications.

### 4.3 When to use WIT-SVID
WIT-SVIDs are the preferred choice for systems where application layer authentication is required (as with JWT-SVID), but there is an additional need for stronger security assurances regarding message integrity or provenance. Specifically, this will be in cases where:

* Workloads need to safeguard against impersonation more strongly than with simple token expiry,
* Callers must provide per-request proof of identity

It should be noted that while WIT-SVID is an additive improvement to the token-based authentication semantics of JWT-SVID, support for proof-of-possession verification and handling of WIT-specific claims and concepts (such as the Workload Proof Token) needs to be implemented in both server and client applications.

### 4.4 Heuristics

* Where TLS is available across all workloads, favor X.509-SVIDs.
* Where TLS is not available across all workloads, favor token-based SVID formats.
  * Where client library support is available, favor WIT-SVID.
  * Else, use JWT-SVID.

## 5. Security Considerations
This section outlines security considerations that should be taken into account when selecting one of the SVID formats. 

### 5.1 Threat Models

### 5.2 Mitigations

## 6. Appendix
