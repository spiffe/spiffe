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

As the WIT-SVID is a sub-profiling of the WIMSE WIT, all WIT-SVIDs are WIMSE WITs and implementations designed to consume WIMSE WITs will be compatible with WIT-SVIDs. Conversely, not all WITs are WIT-SVIDs and implementations designed specifically for WIT-SVIDs may not function with WITs or other profiles of WITs.

WIT-SVIDs are [JSON Web Tokens (JWT)][6] encoded using [JSON Web Signature (JWS)][2] compact serialization.

### 2. JOSE Header

This section describes the JOSE header parameters that are defined for the WIT-SVID.

The WIT-SVID specification does not introduce any JOSE header parameters beyond those defined by the upstream document for the WIT. However, it does set additional restrictions and provide SPIFFE-specific guidance on some parameters.

### 2.1. Key ID - `kid`

Unique identifier of the key-pair used by the issuer to sign the WIT-SVID. The `kid` header parameter is defined by the [JSON Web Signature (JWS)][2] document.

For a WIT-SVID, this parameter MUST be present. This differs from the upstream WIT itself and the JWT-SVID where this parameter is optional.

The format of the value of this parameter is unspecified and it MUST be treated by verifiers as a case-sensitive string.

The issuer MUST ensure that the value set within the `kid` parameter is unique to each issuing key-pair.

This parameter allows a validator to select the correct public key from a trust bundle for validating the signature of a WIT-SVID without enumerating all keys.

### 2.2. Type - `typ`

The `typ` header parameter is defined by the [JSON Web Signature (JWS)][2] document.

For a WIT-SVID, this parameter MUST be present and MUST be set to `wit+jwt`.

### 2.3. Algorithm - `alg`

Identifies the cryptographic algorithm used to sign the WIT-SVID. The `alg` header parameter is defined by the [JSON Web Signature (JWS)][2] document.

For a WIT-SVID, this parameter MUST be present and set to one of the following supported values:

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

Implementations SHOULD NOT provide additional header parameters not specified by this document.

Validators should ignore unknown header parameters except where those header parameters are specified by the `crit` header parameter as per [RFC7515][2].

### 3. Claims

This section describes the claims that are defined for the WIT-SVID.

The WIT-SVID specification does not introduce any claims beyond those defined by the upstream document for the WIT. However, it does set additional restrictions and provide SPIFFE-specific guidance on some claims.

### 3.1. Subject - `sub`

The identity of the workload holding the WIT-SVID.

The `sub` claim MUST be present and MUST be set to the SPIFFE ID of the workload to which it is issued.

This is the primary claim against which workload identity is asserted.

For example: `spiffe://example.org/service`.

### 3.2 Confirmation - `cnf`

The public key of the workload. The meaning of this claim and the structure of its value is defined by [RFC7800][7] and [WIMSE Workload Credentials][1].

The `cnf` claim MUST be present and validators MUST reject WIT-SVIDs without this claim. The structure of this claim MUST be as described by [RFC7800][7] and [WIMSE Workload Credentials][1].

In addition to the requirements set out in RFC7800 and WIMSE Workload Credentials, the `cnf.jwk.alg` claim MUST have one of the following supported values:

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

### 3.3. JWT ID - `jti`

A unique identifier for this WIT-SVID. The meaning of this claim and the structure of its value is defined by [RFC7519][6].

The `jti` claim MAY be present. If present, the issuer MUST abide by the requirements set by [RFC 7519][6] and ensure that there is a negligible probability that the same value will be used by more than one WIT-SVID within the scope of the trust domain.

Typically, the `jti` will be an opaque randomly generated value of sufficient entropy as to make the chance of collision negligible.

Primarily, this claim enables distinguishing one or more WIT-SVIDs that contain the same SPIFFE ID for the purposes of auditing. For example, if a validator of a WIT-SVID records the JTI within an audit log event, this audit log event can be correlated with the one emitted by the issuer which allows the lineage of the credential to be ascertained.

Due to the nature of how this claim uniquely identifies the WIT-SVID, it could be leveraged for revocation of an individual WIT-SVID. There are no mechanisms defined within SPIFFE for the propagation of WIT-SVID revocations and this is considered out of the scope of the specification.

Implementations MAY issue a WIT-SVID with the same `jti` to two different instances of the workload on the same node. As such, the `jti` SHOULD NOT be used for replay protection.

### 3.3. Expiry - `exp`

The timestamp at which this WIT-SVID is no longer valid. The meaning of this claim and the structure of its value is defined by [RFC7519][6].

The `exp` claim MUST be present and validators MUST reject WIT-SVIDs that do not include this claim and MUST reject WIT-SVIDs when the time indicated by `exp` is in the past. Validators MAY allow a small amount of leeway (e.g seconds to at most a couple of minutes) when comparing the expiry time to the current time to account for clock skew.

This claim is the primary control of the length of time for which a WIT-SVID is valid. This specification does not set any hard upper or lower limits on the length of the validity period.

It is recommended to choose a reasonable value that balances the cost of issuing and distributing WIT-SVIDs to workloads against limiting the period of time in which an exfiltrated WIT-SVID and key-pair remains useful to a bad actor. This is typically a period ranging from minutes to hours.

### 3.4. Not Before - `nbf`

The timestamp at which this WIT-SVID became valid. The meaning of this claim and the structure of its value is defined by [RFC7519][6].

The `nbf` claim SHOULD be present and validators MUST reject WIT-SVIDs when the time indicated by `nbf` is in the future.

Notably, this value may be set to a time shortly in the past relative to the time of issuance, this permits a certain degree of clock skew between validator and issuer.

Validators MAY use the difference between the `nbf` and `exp` to determine the lifespan of the WIT-SVIDs and MAY reject WIT-SVIDs where the lifespan exceeds an administratively configured lifespan policy.

### 3.5. Issued At - `iat`

The timestamp at which this WIT-SVID was issued. The meaning of this claim and the structure of its value is defined by [RFC7519][6].

The `iat` claim SHOULD be present. This claim MUST NOT be used for limiting the earliest validity of a WIT-SVID, this is the purpose of the `nbf` claim.

This claim exists to assist with auditing and diagnostics.

### 3.6. Issuer - `iss`

The issuer of this WIT-SVID. The meaning of this claim is defined by [RFC7519][6].

The `iss` claim MAY be present. When present, it SHOULD NOT be a value compatible with OpenID Connect Discovery - this is to prevent the validation and acceptance of the WIT-SVID as an OIDC ID Token without validation of a proof of possession.

Within SPIFFE, there already exists mechanisms for the distribution of trust bundles and the trust domain part of the `sub` broadly identifies the issuer. In many cases, this makes the `iss` claim redundant. The specification has intentionally been left relaxed for the `iss` claim to support the usage of alternative trust distribution models and developments to the specification in future.

### 3.7. Additional Claims

It is permitted for an implementation to include additional claims not specified in this document or the upstream document.

When encountering additional claims that it does not recognize, a validator should ignore them.

## 4. Token Issuance and Validation

This section describes the manner in which a WIT-SVID may be issued and validated.

The process of signing a WIT-SVID does not differ significantly from the well-established method for signing a JWT-SVID or a JWT. Implementors should follow the canonical process set out by [RFC7519][6]. However, they should bear in mind the following specific requirements for WIT-SVIDs:

- The issuer MUST use one of the permitted algorithms for signing the WIT-SVID JWT as per [2.3. Algorithm - `alg`](#23-algorithm---alg).
- The issuer MUST set the `alg`, `typ` and `kid` header parameters.
- The issuer MUST set the `sub`, `exp` and `cnf` claims.
- The issuer MUST set the `cnf.jwk.alg` claim to one of the permitted algorithms as per [3.2 Confirmation - `cnf`](#32-confirmation---cnf)
- The issuer SHOULD set the `jti`, `nbf` and `iat` claims.

The issuer MAY issue the same WIT-SVID, or WIT-SVIDs with the same key within the `cnf`, to instances of the same workload running on the same host. This may be useful in cases where an implementor wishes to have a local agent of the issuer cache WIT-SVIDs for workloads for performance or reliability reasons. Implementors should consider how this impacts the relationship between a WIT-SVID and a specific instance of a workload for the purposes of auditing or revocation.

The process of validating a WIT-SVID is similar to the well-established process for validating a JWT-SVID or a JWT more generally. Implementors should follow the canonical process set out by [RFC7519][6]. However, they should bear in mind the following specific requirements for WIT-SVIDs:

- The validator MUST NOT accept the WIT-SVID without an appropriate proof of posession of the key-pair contained within the `cnf`.

## 5. Token Presentation

This section describes the manner in which a WIT-SVID may be presented from one workload to another for the purposes of authentication.

The WIT-SVID MUST always be presented by the workload with proof of possession of the key-pair contained within the `cnf`. In other words, the WIT-SVID MUST NOT be presented as a bearer token and therefore MUST NOT be presented using the HTTP `Authorization` header.

WIMSE defines protocols for presentation of the WIT and accompanying proof of possession. It is recommended that that an implementor use one of these defined protocols. The use of other protocols is permitted if they meet the requirements set out above. At the time of writing, there are two protocols specified by WIMSE for WIT:

- [WIMSE Workload Proof Token][4]
- [WIMSE Workload-To-Workload Authentication with HTTP Signatures][5]

## 6. Representation in the SPIFFE Bundle

This section describes how the WIT-SVID signing keys are published to and consumed from a SPIFFE bundle. Please see the [SPIFFE Trust Domain and Bundle](SPIFFE_Trust_Domain_and_Bundle.md) specification for more information about SPIFFE bundles.

### 6.1 Publishing SPIFFE Bundle Elements

WIT-SVID signing keys for a given trust domain are represented in the SPIFFE bundle as [RFC 7517][3]-compliant JWK entries, one entry per signing key.

The `use` parameter of the JWK entry MUST be set to `wit-svid`.

The `kid` parameter of each JWK entry must be set. The value of the `kid` parameter MUST be unique within the scope of the SPIFFE bundle. No other JWK, whether for JWT-SVID or WIT-SVID, may have use the same value.

### 6.2 Consuming SPIFFE Bundle Elements

SPIFFE bundles may contain JWK entries for many different SVID types. Implementations MUST extract the WIT-SVID specification keys before using them for validation purposes. Entries representing WIT-SVID signing keys can be identified by the value of their `use` parameter, which must be `wit-svid`. If there are no entries with the `wit-svid` use parameter, then the trust domain that the bundle represents does not support WIT-SVID.

## 7. Security Considerations

### 7.1 Mandatory Proof of Possession

The WIT-SVID MUST NOT be used as a bearer token and MUST be presented with a proof of possession of the key-pair within the `cnf` claim.

Similarly, the WIT-SVID MUST NOT be accepted without appropriate proof of possession of the key-pair within the `cnf` claim. See [5. Token Presentation](#5-token-presentation) for information on appropriate protocols for the presentation and acceptance of the WIT-SVID for authentication.

Implementors should take care to ensure that the WIT-SVID will not be accepted by validators that may be expecting a JWT-SVID or JWT (e.g. OIDC Workload Identity Federation).

### 7.2 Proof of Possession and Mitigation of Tampering and Replay

When choosing a proof of possession mechanism, consider how the characteristics of the mechanism will mitigate the impact of an attacker intercepting the WIT-SVID, proof of possession and potentially the request itself. There are broadly two scenarios to consider:

- Tampering: When the attacker intercepts and modifies a legitimate request to be malicious.
- Replay: When the attacker intercepts the request and uses the WIT-SVID and PoP and uses these to make their own request.

A key characteristic to consider is how tightly scoped the proof of possession is, that is, how specific it is to the request being made by the sender.

A tightly scoped proof of possession limits the extent to which an attacker can tamper with the intentions of the request and limits the actions an attacker can take when replaying. A loosely scoped proof of possession (e.g. one that is only scoped to the intended recipient) would allow an attacker to perform a wide range of actions. A good proof of possession would be scoped to a specific action with a specific set of parameters.

The scope of a proof of possession must be understood and enforced by the recipient to be of any value. If the sender includes a trait of the request within a proof of possesion but the recipient does not validate this against the received request, then it has served no purpose.

Additionally, the lifespan of a Proof of Possession MUST be limited and SHOULD be limited to a shortest period necessary to serve its intended purpose. This reduces the window in which they can be replayed by an attacker. In ideal circumstances, the lifespan could feasibly be set to a small number of seconds, however the lower bound of this value may be constrained by factors such as clock skew and network latency.

Recipients MAY choose to prevent replay by only permitting a distinct proof of possession to be used at most once. This may be implemented by recording some unique identifier of the proof of possesion (e.g. in the case of the WIMSE WPT, the `jti` claim). This requires a degree of coordination between the sender and the recipient as the sender must be aware that it can only use a proof of possession once.

### 7.3 Transport Security

The WIT-SVID and corresponding proof of possession MUST be transmitted over a secure channel (e.g. server authenticated TLS).

## Appendix A. Example WIT-SVID

This appendix provides an example WIT-SVID.

Signed JWT: `eyJhbGciOiJFUzI1NiIsImtpZCI6ImxRU2kzaFpGbmRhMkQtWEprajF6bDdmb0pvdWl3STRuckF5aHk0alppSmciLCJ0eXAiOiJ3aXQrand0In0.eyJjbmYiOnsiandrIjp7ImFsZyI6IkVTMjU2IiwiY3J2IjoiUC0yNTYiLCJrdHkiOiJFQyIsIngiOiJyelA3bUxDS0FIV21zTTZYMEV3VklTQ19oSTN1amN1OTVmZlVreWVER0dvIiwieSI6InVPcmZEbGp0WDltM2pZLWhzeWhMSllheHRHa3pEdjVlNWttQ2U1OFo5N2cifX0sImV4cCI6MTc2NTQ1NjUwMywiaWF0IjoxNzY1NDUyOTAzLCJqdGkiOiIxeWoxOVY0TWNPQXpNY0ZpN3F2c2dfQWdDeGxyWTVFX3g1MDl3bEtLUXRjIiwic3ViIjoic3BpZmZlOi8vZXhhbXBsZS5jb20vbXktd29ya2xvYWQifQ.sfhEvZNdY_kWrICF08lX0u__rn39YnTavnW-VPBS20zgowDh6-X43v5eOUKZbjZf06yLBQM-Mry5w1g1QFsCkg`

Header:

```json
{
  "alg": "ES256",
  "kid": "lQSi3hZFnda2D-XJkj1zl7foJouiwI4nrAyhy4jZiJg",
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
      "x": "rzP7mLCKAHWmsM6X0EwVISC_hI3ujcu95ffUkyeDGGo",
      "y": "uOrfDljtX9m3jY-hsyhLJYaxtGkzDv5e5kmCe58Z97g"
    }
  },
  "exp": 1765456503,
  "iat": 1765452903,
  "jti": "1yj19V4McOAzMcFi7qvsg_AgCxlrY5E_x509wlKKQtc",
  "sub": "spiffe://example.com/my-workload"
}
```

## Appendix B. Comparing WIMSE WIT with SPIFFE WIT-SVID

This appendix summarises the differences between the IETF WIMSE WIT and the SPIFFE WIT-SVID.

Key:

- ✓: Mandatory (MUST)
- ~: Optional (SHOULD, MAY)
- ✗: Prohibited (SHOULD NOT, MUST NOT)
- *: Note below

Header Parameter             | WIT-SVID | WIMSE WIT
-----------------------------|----------|----------
`kid`                        | ✓        | ~
`typ`                        | ✓        | ✓
`alg`                        | ✓*       | ✓
Additional header parameters | ✗        | ~

Notes:

- `alg`: The WIT-SVID requires the `alg` header parameter to be a value specified within this document. The WIMSE WIT accepts any algorithm registered in the IANA JOSE registry with the exception of `none`.

Claim             | WIT-SVID | WIMSE WIT
------------------|----------|----------
`sub`             | ✓*       | ✓
`cnf`             | ✓*       | ✓
`jti`             | ~        | ~
`exp`             | ✓        | ✓
`iat`             | ~        | ~
`nbf`             | ~        | ~
`iss`             | ~*       | ~
Additional claims | ~        | ~

Notes:

- `sub` claim: The WIT-SVID requires that this must be a SPIFFE ID. The WIMSE WIT requirs that this be a WIMSE Workload Identifier. A SPIFFE ID is a WIMSE Workload Identifier.
- `cnf.jwk.alg`: The WIT-SVID requires the `cnf.jwk.alg` claim to be a value specified within this document. The WIMSE WIT accepts any algorithm registered in the IANA JOSE registry with the exception of `none`.
- `iss`: Both the WIT-SVID and WIMSE WIT allow the optional inclusion of the `iss` claim. The WIT-SVID requires that if this is included, that this is not a value compatible with OpenID Connect Discovery.

## Appendix C. Comparing the JWT-SVID and WIT-SVID

This appendix explores the differences between the JWT-SVID and WIT-SVID from a structural and presentational point of view. For a more in-depth exploration of the types of SVIDs and guidance on selecting between them, see the [Best Practices: SVID Type Comparison document][8].

Whilst at first glance the JWT-SVID and WIT-SVID may look quite similar, there are a number of key differences.

Unique to the WIT-SVID is the inclusion of a public key belonging to the workload. When authenticating with the WIT-SVID it is required for the workload to also perform a proof of possession using the private key. This differs from JWT-SVIDs which are bearer tokens - presentation of the JWT-SVID alone is enough to authenticate using it. This creates a difference in how they must be handled, with a JWT-SVID being more susceptible to replay by a bad actor who has intercepted it.

Because of their bearer nature, it is strongly recommended that JWT-SVIDs have an extremely short lifespan (e.g. seconds to a few minutes) in order to mitigate potential re-use. Since the proof of possession mechanism of WIT-SVIDs provides some mitigation against these kinds of attacks, a lifespan as short as that typically seen for JWT-SVIDs is not necessary and the lifespan of WIT-SVIDs may be more similar to that of X509-SVIDs.

Notably, the WIT-SVID makes the `kid` header parameter mandatory whereas the JWT-SVID does not. This change was intended to reflect reality: a significant number of JWT-SVID validation implementations (e.g `go-spiffe`, SPIRE) within the SPIFFE ecosystem will reject a spec-compliant JWT-SVID without the `kid` parameter, making this a de-facto requirement. A similar situation would be likely to occur if the `kid` header parameter was optional for the WIT-SVID. Therefore, making this mandatory from the outset increases the chances of the implementations and the specification being in coherence in regards to the `kid` header parameter.

## Appendix D. Comparing the X509-SVID and WIT-SVID

This appendix explores the differences between the X509-SVID and WIT-SVID from a structural and presentational point of view. For a more in-depth exploration of the types of SVIDs and guidance on selecting between them, see the [Best Practices: SVID Type Comparison document][8].

Whilst at first glance the X509-SVID and WIT-SVID may be quite visually distinct, they share a number of common traits:

- Both contain a public key belonging to the workload and when authenticating using the SVID, the workload must demonstrate possession using the corresponding private key. The possession of the X509-SVID or the WIT-SVID alone is not enough to authenticate using it and because of this, they do not need to be treated as "sensitive" values.
- Both are likely to have lifespans of comparable lengths (e.g minutes to hours).
- Both are cryptographically signed by an issuer, and, a validator uses this signature to ensure that it is a legitimate credential and has not been tampered with.

They do however differ in a number of key ways:

- X509-SVIDs are X.509 certificates - it is an extremely mature standard and good support for authentication based on them (e.g TLS) is available in most languages. WITs are much less mature and language support is likely to be initially limited.
- X509-SVIDs are typically presented and mutually authenticated at the network layer using TLS. They authenticate a channel. A WIT-SVID would typically be sent along with a single request on the application layer. They authenticate a single invocation.
- X509-SVIDs are serialized in ASN.1, whereas WIT-SVIDs are JWTs and are serialized using JSON. JSON is often considered easier to work with and understand.

It's entirely feasible that in some environments, both may even be used within the same connection (e.g the client presents a WIT-SVID and the server presents an X509-SVID.)

[1]: https://datatracker.ietf.org/doc/draft-ietf-wimse-workload-creds/
[2]: https://www.rfc-editor.org/rfc/rfc7515.html
[3]: https://www.rfc-editor.org/rfc/rfc7517.html
[4]: https://datatracker.ietf.org/doc/draft-ietf-wimse-wpt/
[5]: https://datatracker.ietf.org/doc/draft-ietf-wimse-http-signature/
[6]: https://www.rfc-editor.org/rfc/rfc7519.html
[7]: https://www.rfc-editor.org/rfc/rfc7800.html
[8]: https://example.com/todo-svid-type-compare
