# The WIT SPIFFE Verifiable Identity Document

> [!WARNING]  
> This version of the document belongs to an experimental branch of the SPIFFE standards that explores integration with the WIMSE standards. Contents of this document are subject to breaking change and should not be considered stable.
>
> The current stable version of this document can be found at https://github.com/spiffe/spiffe/blob/main/standards/SPIFFE_Workload_Endpoint.md

## Status of this Memo

This document specifies an identity document standard for the internet community, and requests discussion and suggestions for improvements. Distribution of this document is unlimited.

## Table of Contents

## 1. Introduction

The Workload Identity Token (WIT) is a token format specified by the IETF WIMSE working group in the [WIMSE Workload Credentials][1] document. The WIT binds a public key to the identity of a workload.

The WIT-SVID is a sub-profiling of this token format for use in SPIFFE contexts. This document will not redefine key elements specified within the upstream [WIMSE Workload Credentials][1] document and as such the reader should be familiar with this document and its contents before implementing WIT-SVID.

WIT-SVIDs are JSON Web Signature (JWS) data structures.

### 2. JOSE Header

In addition to headers made mandatory by the upstream document, the WIT-SVID profile makes mandatory the following headers:

- Key ID - `kid`

TODO: Should we summarize `alg`/`typ` even if these will not differ from the WIMSE WIT?

### 2.1. Key ID - `kid`

The `kid` header is defined by the [JSON Web Signature (JWS)][2] document.

For a WIT-SVID, this header is mandatory. This differs from the upstream WIT itself where this header is optional.

The precise structure of this header is unspecified, and, it MUST be treated by verifiers as a case-sensitive string.

The issuer MUST ensure that the value set within the `kid` header is unique to each issuing key-pair.

### 2.2. Additional Headers

It is permitted for an implementation to include additional headers not specified in this document or the upstream document.

### 3. Claims

The WIT-SVID specification does not introduce any claims beyond those defined by the upstream document. However, it does set additional restrictions on some claims.

TODO:

- `iss` claim. This is RECOMMENDED in the WIT specification. Do we wish to mirror this, or, make it mandatory?
- `jti` claim. This is OPTIONAL in the WIT specification. Do we wish to mirror this, or, make it mandatory?

### 3.1. Subject - `sub`

The `sub` claim MUST be present and set to the SPIFFE ID of the workload to which it is issued. This is the primary claim against which workload identity is asserted.

For example: `spiffe://example.org/service`.

### 3.2. JWT ID - `jti`

The `jti` claim provides a unique identifier for the WIT-SVID. It is defined by [RFC 7519][6].

Primarily, this claim enables distinguishing one or more WIT-SVIDs that contain the same SPIFFE ID for the purposes of auditing. For example, if a validator of a WIT-SVID records the JTI within an audit log event, this audit log event can be correlated with the one emitted by the issuer, allowing the lineage of the credential to be ascertained.

TODO: Do we repeat from RFC 7519 that the issuer MUST ensure that this field is unique?
TODO: In WIT-SVID, is this a MAY/SHOULD/MUST?
TODO: Do we make any comment here on revocation?

### 3.2. Additional Claims

It is permitted for an implementation to include additional claims not specified in this document or the upstream document.

## 4. Token Signing and Validation

## 5. Token Presentation

This section describes the manner in which a WIT-SVID may be presented from one workload to another for the purposes of authentication.

The WIT-SVID MUST always be presented by the workload with proof of possession of the key-pair contained within the `cnf`. In other words, the WIT-SVID MUST NOT be presented as a bearer token.

WIMSE defines protocols for presentation of the WIT. It is recommended that that an implementor use one of these defined protocols, however, it is not required. At the time of writing, there are two protocols:

- [WIMSE Workload Proof Token][4]
- [WIMSE Workload-To-Workload Authentication with HTTP Signatures][5]

## 6. Representation in the SPIFFE Bundle

This section describes how the WIT-SVID signing keys are published to and consumed from a SPIFFE bundle. Please see the [SPIFFE Trust Domain and Bundle](SPIFFE_Trust_Domain_and_Bundle.md) specification for more information about SPIFFE bundles.

### 6.1 Publishing SPIFFE Bundle Elements

WIT-SVID signing keys for a given trust domain are represented in the SPIFFE bundle as [RFC 7517][3]-compliant JWK entries, one entry per signing key.

The `use` parameter of the JWK entry MUST be set to `wit-svid`. Additionally, the `kid` parameter of each JWK entry must be set.

### 6.2 Consuming SPIFFE Bundle Elements

SPIFFE bundles may contain JWK entries for many different SVID types. Implementations MUST extract the WIT-SVId specification keys before using them for validation purposes. Entries representing WIT-SVID signing keys can be identified by the value of their `use` parameter, which must be `wit-svid`. If there are no entries with the `wit-svid` use parameter, then the trust domain that the bundle represents does not support WIT-SVID.

## 7. Security Considerations

### 7.1 Proof of Possession

The WIT-SVID MUST NOT be used as a bearer token and MUST be presented with a proof of possession of the key-pair within the `cnf` claim.

### 7.2 Transport Security

## Appendix A. Comparing WIMSE WIT with SPIFFE WIT-SVID

The following summarises the differences between the IETF WIMSE WIT and the SPIFFE WIT-SVID.

- JOSE Headers
  - `kid` is not defined by the WIT specification, but is mandatory in WIT-SVID.
- Claims
  - `sub` is defined within the WIT specifications, but, is specifically defined to be the SPIFFE ID in a WIT-SIVD.

## Appendix B. Comparing the JWT-SVID and WIT-SVID

TODO: Is this topic appropriate for this document? Does it better belong in SPIFFE-ID.md? or not within the specification at all? I feel this should be covered somewhere since the WIT and JWT are "visually" "similar" and likely to be confused.

[1]: https://datatracker.ietf.org/doc/draft-ietf-wimse-workload-creds/
[2]: https://datatracker.ietf.org/doc/rfc7515
[3]: https://datatracker.ietf.org/doc/rfc7517
[4]: https://datatracker.ietf.org/doc/draft-ietf-wimse-wpt/
[5]: https://datatracker.ietf.org/doc/draft-ietf-wimse-http-signature/
[6]: https://datatracker.ietf.org/doc/rfc7519
