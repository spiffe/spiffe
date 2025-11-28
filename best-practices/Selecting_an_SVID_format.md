# Best practice - Selecting an SVID format

## Status of this Memo
This document provides information and guidance on the selection of SPIFFE Verifiable Identity Document (SVID) formats for use across common workload identity scenarios. Distribition of this document is unlimited.

## Table of Contents

## 1. Background

The SPIFFE standards defines support for multiple SVID formats:

* X.509 SVID
* JWT SVID
* WIT SVID

Each of these document formats has a unique set of features and constraints that require consideration before their selection. 

## 2. Overview of Formats

### 2.1 X.509-SVID

X.509-SVIDs are short-lived X.509 certificates containing a SPIFFE ID in the Subject Alternative Name.

## 2.2 JWT-SVID

JWT-SVIDs are signed JSON Web Tokens (JWT) containing a SPIFFE ID in the `sub` claim 

## 2.3 WIT-SVID

WIT-SVIDs are signed JWTs containing a SPIFFE ID in the `sub` claim, but further enhanced over JWT-SVIDs with a public key binding.

# 3. Comparison Matrix

## 5. Comparison Matrix

| Property              | X.509-SVID                                     | JWT-SVID                                              | WIT-SVID                                                   |
|-----------------------|------------------------------------------------|-------------------------------------------------------|------------------------------------------------------------|
| **Primary use**       | Transport-level identity (mTLS)                | Request/API-level identity (bearer)                   | Request/API-level identity with proof-of-possession        |
| **Layer**             | Transport                                      | Application                                           | Application                                                |
| **Format**            | X.509 certificate                              | Signed JWT                                            | Signed JWT with public key binding                         |
| **Token semantics**   | Holder-of-key (private key bound to cert)      | Bearer token                                          | Holder-of-key via explicit proof-of-possesion key binding  |
| **Rotation**          | Frequent, automatic                            | Short-lived tokens                                    | Short-lived tokens + workload-bound key material           |
| **Verification**      | Cert chain + SAN/SPIFFE ID                     | JWS signature + claims validation                     | JWS signature + claims + **PoP verification**              |
| **Replay resistance** | Strong (TLS handshake + key possession)        | Weak unless TTL is very short                         | Strong (proof-of-possesion)                                |
| **Maturity**          | Very high (meshes, RPC stacks, proxies)        | High (gateways, APIs, cloud services)                 | Emerging                                                   |
| **Best for**          | In-mesh mTLS, long-lived connections           | API gateways, cloud federation, stateless requests    | Application layer calls requiring integrity guarantees     |

# 4. Selection Criteria

## 4.1 When to use X.509-SVID

## 4.2 When to use JWT-SVID

## 4.3 When to use WIT-SVID

# 5. Security Considerations

## 5.1 Threat Models

## 5.2 Mitigations

# 6. Appendix
