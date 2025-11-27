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

The WIT-SVID is a sub-profiling of this token format for use in SPIFFE contexts. This document does not redefine key elements specified within the upstream [WIMSE Workload Credentials][1] document and as such the reader should be familiar with this document and its contents before implementing WIT-SVID.

WIT-SVIDs are [JSON Web Tokens (JWT)][6] encoded using [JSON Web Signature (JWS)][2] compact serialization.

### 2. JOSE Header

This section describes the JOSE header parameters that are defined for the WIT-SVID.

The WIT-SVID specification does not introduce any JOSE header parameters beyond those defined by the upstream document for the WIT. However, it does set additional restrictions and provide SPIFFE-specific guidance on some parameters.

### 2.1. Key ID - `kid`

Unique identifier of the key-pair used by the issuer to sign the WIT-SVID. The `kid` header parameter is defined by the [JSON Web Signature (JWS)][2] document.

For a WIT-SVID, this parameter MUST be present. This differs from the upstream WIT itself where this parameter is optional.

The format of the value of this parameter is unspecified and it MUST be treated by verifiers as a case-sensitive string.

The issuer MUST ensure that the value set within the `kid` parameter is unique to each issuing key-pair.

### 2.2. Type - `typ`

The `typ` header parameter is defined by the [JSON Web Signature (JWS)][2] document.

For a WIT-SVID, this parameter MUST be present and MUST be set to `wit+jwt`.

### 2.3. Algorithm - `alg`

Identifies the cryptographic algorithm used to sign the WIT-SVID. The `alg` header parameter is defined by the [JSON Web Signature (JWS)][2] document.

For a WIT-SVID, this parameter MUST be present, and, set to one of the following supported values:

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

Validators MUST reject WIT-SVIDs with an unsupported `alg` parameter value.

### 2.3. Additional Header Parameters

It is permitted for an implementation to include additional header parameters not specified in this document or the upstream document.

### 3. Claims

This section describes the claims that are defined for the WIT-SVID.

The WIT-SVID specification does not introduce any claims beyond those defined by the upstream document for the WIT. However, it does set additional restrictions and provide SPIFFE-specific guidance on some claims.

<--
Within this section, I've tried to abide by the following "structure" for each claim:

- Definition
- Requirements
- Advisory information on purpose/usage.
-->

TODO:

- `iss` claim. This is RECOMMENDED in the WIT specification. Do we wish to mirror this, or, make it mandatory?

### 3.1. Subject - `sub`

The identity of the workload holding the WIT-SVID.

The `sub` claim MUST be present and MUST be set to the SPIFFE ID of the workload to which it is issued.

This is the primary claim against which workload identity is asserted.

For example: `spiffe://example.org/service`.

### 3.2. JWT ID - `jti`

A unique identifier for this WIT-SVID. The meaning of this claim is defined by [RFC 7519][6].

The `jti` claim MAY be present. If present, the issuer MUST abide by the requirements set by [RFC 7519][6] and ensure that there is a negligible probability that the same value will be used by more than one WIT-SVID within the scope of the trust domain.

Typically, the `jti` will be an opaque randomly generated value of sufficient entropy as to make the chance of collision negligible.

Primarily, this claim enables distinguishing one or more WIT-SVIDs that contain the same SPIFFE ID for the purposes of auditing. For example, if a validator of a WIT-SVID records the JTI within an audit log event, this audit log event can be correlated with the one emitted by the issuer which allows the lineage of the credential to be ascertained.

Due to the nature of how this claim uniquely identifies the WIT-SVID, it could be leveraged for revocation of an individual WIT-SVID. There are no mechanisms defined within SPIFFE for the propagation of WIT-SVID revocations and this is considered out of the scope of the specification.

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

SPIFFE bundles may contain JWK entries for many different SVID types. Implementations MUST extract the WIT-SVID specification keys before using them for validation purposes. Entries representing WIT-SVID signing keys can be identified by the value of their `use` parameter, which must be `wit-svid`. If there are no entries with the `wit-svid` use parameter, then the trust domain that the bundle represents does not support WIT-SVID.

## 7. Security Considerations

### 7.1 Proof of Possession

The WIT-SVID MUST NOT be used as a bearer token and MUST be presented with a proof of possession of the key-pair within the `cnf` claim.

### 7.2 Transport Security

## Appendix A. Example WIT-SVID

Signed JWT: `eyJhbGciOiJFUzI1NiIsInR5cCI6IndpdCtqd3QifQ.eyJjbmYiOnsiandrIjp7ImFsZyI6IkVTMjU2IiwiY3J2IjoiUC0yNTYiLCJrdHkiOiJFQyIsIngiOiJ2amFOU1c4ZmRXLXh1Z0QtUDRpSHVTQVdzbGFRZlF5LTZjaXhHMzlWdl9JIiwieSI6ImFzUWlreFZxZzNoTTFDa0k4LVhwT3pfSkhDU1BNREtnbzVXSW53R2R0bkEifX0sImV4cCI6MTc2NDE1MzY4MCwiaWF0IjoxNzY0MTUwMDgwLCJqdGkiOiJEQkIyXzN4eDg0UjB5N2RmZFBJaDJCNndpWGdaUVhGSW9JYU1jbXk2LXowIiwic3ViIjoic3BpZmZlOi8vZXhhbXBsZS5jb20vbXktd29ya2xvYWQifQ.MQMj9fhGtMRSSZexqJXgYJXIItbtPq884dsEGaUxzzPRYA4DE_2926EtJm3KNDAaDhBnHD996rPqFq3UNAB3hA`

Header:

```json
{
  "alg": "ES256",
  "typ": "wit+jwt"
}
```

Payload:

```json
{
  "cnf": {
    "jwk": {
      "alg": "ES256",
      "crv": "P-256",
      "kty": "EC",
      "x": "vjaNSW8fdW-xugD-P4iHuSAWslaQfQy-6cixG39Vv_I",
      "y": "asQikxVqg3hM1CkI8-XpOz_JHCSPMDKgo5WInwGdtnA"
    }
  },
  "exp": 1764153680,
  "iat": 1764150080,
  "jti": "DBB2_3xx84R0y7dfdPIh2B6wiXgZQXFIoIaMcmy6-z0",
  "sub": "spiffe://example.com/my-workload"
}
```

## Appendix B. Comparing WIMSE WIT with SPIFFE WIT-SVID

The following summarises the differences between the IETF WIMSE WIT and the SPIFFE WIT-SVID.

- JOSE Headers
  - `kid` is not defined by the WIT specification, but is mandatory in WIT-SVID.
- Claims
  - `sub` is defined within the WIT specifications, but, in WIT-SVID is constrained to be the SPIFFE ID.

## Appendix C. Comparing the JWT-SVID and WIT-SVID

TODO: Is this topic appropriate for this document? Does it better belong in SPIFFE-ID.md? or not within the specification at all? I feel this should be covered somewhere since the WIT and JWT are "visually" "similar" and likely to be confused.

<--
TODO: Update these datatracker links to use rfc-editor.org where possible.
-->

[1]: https://datatracker.ietf.org/doc/draft-ietf-wimse-workload-creds/
[2]: https://datatracker.ietf.org/doc/rfc7515
[3]: https://datatracker.ietf.org/doc/rfc7517
[4]: https://datatracker.ietf.org/doc/draft-ietf-wimse-wpt/
[5]: https://datatracker.ietf.org/doc/draft-ietf-wimse-http-signature/
[6]: https://datatracker.ietf.org/doc/rfc7519
