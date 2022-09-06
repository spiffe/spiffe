# The SPIFFE Trust Domain and Bundle

## Status of this Memo
This document specifies an identity document standard for the internet community, and requests discussion and suggestions for improvements. Distribution of this document is unlimited.

## Abstract
The SPIFFE standard provides a specification for a framework capable of bootstrapping and issuing interoperable identity to services across heterogeneous environments and organizations. It defines a concept known as "trust domains" which are used to delineate administrative and/or security boundaries. Trust domains isolate issuing authorities and differentiate identity namespaces, but can also be loosely coupled to provide federation.

This document describes the semantics of SPIFFE trust domains, how they are represented, and the mechanism by which they may be coupled together.

## Table of Contents
1\. [Introduction](#1-introduction)  
2\. [Trust Domains](#2-trust-domains)  
3\. [SPIFFE Bundles](#3-spiffe-bundles)  
4\. [SPIFFE Bundle Format](#4-spiffe-bundle-format)  
4.1. [JWK Set](#41-jwk-set)  
4.1.1. [Sequence Number](#411-sequence-number)  
4.1.2. [Refresh Hint](#412-refresh-hint)  
4.1.3. [Keys](#413-keys)  
4.2. [JWK](#42-jwk)  
4.2.1. [Key Type](#421-key-type)  
4.2.2. [Public Key Use](#422-public-key-use)  
5\. [Security Considerations](#5-security-considerations)
5.1. [SPIFFE Bundle Refresh Hint](#51-spiffe-bundle-refresh-hint)
5.2. [Reusing Cryptographic Keys Across Trust Domains](#52-reusing-cryptographic-keys-across-trust-domains)
Appendix A. [SPIFFE Bundle Example](#appendix-a-spiffe-bundle-example)  

## 1. Introduction
SPIFFE trust domains represent the basis by which a SPIFFE ID is qualified, indicating the realm or authority under which any given SPIFFE ID has been issued. They are backed by an issuing authority, which is tasked with managing the issuance of SPIFFE identities within its respective trust domain. While the name of a trust domain consists of a simple human-readable string, it is also necessary to express the cryptographic keys in use by the trust domain's issuing authority, enabling others to validate the identities it issues. These keys are expressed as a "SPIFFE bundle", which goes hand in hand with the trust domain that it represents.

This specification defines the nature and semantics of both SPIFFE trust domains and SPIFFE bundles.

## 2. Trust Domains
A SPIFFE trust domain is an identity namespace which is backed by an issuing authority with a set of cryptographic keys. Together, these keys serve as the cryptographic anchor for all identities residing in the trust domain.

Trust domains have a 1:N relationship with the keys that back them. A single trust domain may be represented by multiple keys and key types. For example, the former may be leveraged during root rotation, while the latter is necessary in avoiding multi-protocol attacks should more than one SVID type be in use.

It should be noted that while it is possible to share cryptographic keys amongst many trust domains, we strongly advise that each authoritative key be used in a single trust domain. Key reuse can degrade trust domain isolation (e.g. between staging and production) and introduces additional security challenges (e.g. requiring a name constraint system for secondary issuers). Please see the [Security Considerations](#5-security-considerations) section for more information on this topic.

For more information about how a trust domain namespace is represented, please see [Section 2][1] of the SPIFFE ID specification.

## 3. SPIFFE Bundles
A SPIFFE bundle is an object containing a trust domain's cryptographic keys. The keys within the bundle are considered authoritative for the trust domain that the bundle represents, and are used to prove the validity of [SVIDs][2] that reside in that trust domain.

SPIFFE bundles are designed for use within and between SPIFFE control plane implementations. They are not meant for direct consumption by workloads, however this specification does not preclude such use.

When storing or otherwise managing SPIFFE bundles, it is important to independently record the name of the trust domain that the bundle represents, nominally through the use of a `<trust_domain_name, bundle>` tuple. When validating an SVID, validators must choose the bundle corresponding to the trust domain that the SVID resides in, so maintaining this relationship is required in most scenarios.

Note that the contents of a trust domain's bundle are expected to change over time as the keys it contains are rotated. Keys are added and revoked by issuing a new bundle with new keys included and revoked keys omitted. It is the responsibility of the SPIFFE implementation to distribute bundle content updates to workloads as needed. The exact format and method by which these updates are delivered is out of scope for this specification. Please see the [SPIFFE Workload API][3] specification for information on delivering updates to workloads.

## 4. SPIFFE Bundle Format
SPIFFE bundles are represented as an [RFC 7517][4] compliant JWK Set. JWK was chosen for two major reasons. First, it provides a flexible format for representing various types of cryptographic keys (and documents like X.509), affording some degree of future proofing in the event that new SVID formats are defined. Second, it is widely supported and deployed, used primarily for inter-domain federation, which is a core goal of the SPIFFE project.

### 4.1. JWK Set
This section defines the parameters of the JWK Set. Parameters not defined here MAY be included as implementers see fit, however SPIFFE implementations MUST NOT require their presence in order to function.

#### 4.1.1. Sequence Number
The parameter `spiffe_sequence` SHOULD be set. This sequence number may be used by SPIFFE control planes for many purposes, including propagation measurement and update ordering/supersession. When present, its value MUST be a monotonically increasing integer, and MUST be changed whenever the contents of the bundle are updated.

It should be noted that, while JSON integer type is variable width with no maximum limit defined, many implementations may parse it into a fixed width type. Care should be taken to ensure that the resulting type has at least 64 bits of precision in order to mitigate overflow.

#### 4.1.2. Refresh Hint
The parameter `spiffe_refresh_hint` SHOULD be set. The refresh hint indicates how often a consumer should check back for updates. Bundle publishers may advertise a refresh hint as a function of their key rotation frequency. It should also be noted that the refresh hint may also affect how rapidly a key redaction is propagated. When set, its value MUST be an integer representing the suggested consumer refresh interval in seconds. As the name suggests, the refresh interval is only a hint and consumers may check for updates more or less frequently depending on implementation.

#### 4.1.3. Keys
The parameter `keys` MUST be present. Its value is an array of JWKs. Clients encountering unknown key types or uses MUST ignore the corresponding JWK element. Please see [Section 5][5] of RFC 7517 for more information about the semantics of the `keys` parameter.

The `keys` parameter may contain an empty array. A trust domain which publishes an empty key array indicates that the trust domain has revoked any previously-published keys. Clients may also encounter bundles which after processing yield no usable keys (i.e. no JWKs pass validation described below), and are effectively empty. This may indicate that the trust domain has migrated to a new key type or use not understood by the client. In both cases, workloads MUST treat all SVIDs from the trust domain as invalid and untrusted.

### 4.2. JWK
This section defines high level requirements of the JWK elements which are included as part of the JWK Set. A JWK element represents a single cryptographic key, meant for authenticating a single type of SVID. While the exact requirements for safe use of a JWK vary by SVID type, there are some top level requirements which we outline in this section. SVID specifications MUST define the appropriate value for the `use` parameter (see section `Public Key Use` below), and MAY place further requirements or restrictions on its JWK elements as necessary.

Implementers SHOULD NOT include parameters which are defined neither here nor in the respective SVID specification.

#### 4.2.1. Key Type
The `kty` parameter MUST be set, and its behavior follows [Section 4.1][6] of RFC 7517. Clients encountering an unknown key type MUST ignore the entire JWK element.

#### 4.2.2. Public Key Use
The `use` parameter MUST be set. Its value indicates the type of identity document (or SVID) that it is authoritative for. At the time of this writing, only two SVID types are supported: `x509-svid` and `jwt-svid`. The values are case sensitive. Please see the respective SVID specifications for more information about `use` values. Clients encountering either a missing `use` parameter or an unknown `use` value MUST ignore the entire JWK element.

## 5. Security Considerations
This section outlines security-related considerations that should be made while implementing and deploying a SPIFFE control plane.

### 5.1. SPIFFE Bundle Refresh Hint
SPIFFE bundles include an optional `refresh_hint` field meant to indicate the frequency at which consumers should attempt to refresh their copy of the bundle. This value has a clear impact on how quickly keys can be rotated, but it also impacts how quickly keys can be redacted. Refresh hint values should be carefully chosen with this in mind.

Since this field is not mandatory, it is possible to encounter SPIFFE bundles that do not have a `refresh_hint` set. In this case, a client has the option of using a suitable interval by examining SVID validity periods. It should be acknowledged that omitting a `refresh_hint` will likely impact the ability of a trust domain to rapidly revoke compromised keys. Clients should default to a relatively low (e.g. five minutes) refresh interval to be able to retrieve updated trust bundles in a timely manner.

### 5.2. Reusing Cryptographic Keys Across Trust Domains
This specification discourages sharing cryptographic keys across trust domains since the practice degrades trust domain isolation and introduces additional security challenges. When a root key is shared across multiple trust domains, it becomes critically important that authentication and authorization implementations carefully check the trust domain name component of an identity and that the trust domain name component be easily and habitually expressed in authorization policies.

Suppose that a naïve implementation imported (ie. fully trusted) a particular root key and that the authentication system were configured to authenticate the SPIFFE identity of any SVID which chained up to the trusted root key. If the naïve implementation is not configured to only trust a specific trust domain, then any identity issued in any trust domain could be authenticated (so long as the SVID chains up to the trusted root key).

Continuing the above example where a naïve implementation imports a particular CA certificate, suppose that the authentication did not disambiguate trust domains and that any SVID which chained up to a trusted root key were accepted by the authentication system. Then it would become incumbent on the authorization system to only authorize specific trust domains. In other words, authorization policies need to be explicitly configured to check the trust domain name component of an SVID. The security concern here is that a naïve authorization implementation may blindly trust that the authentication system has filtered out untrusted trust domains.

In summary, a security-in-depth best practice is to maintain a one-to-one mapping between trust domain and root keys so as to reduce subtle (yet catastrophic) authentication and authorization implementation errors. Systems which do reuse root keys across trust domains should ensure that (a) the SVID-issuing system (eg. CA) correctly implements authorization checks prior to issuing SVIDs and (b) that relying parties (ie. systems consuming the SVIDs) correctly implement robust authentication and authorization systems capable of disambiguating multiple trust domains.

## Appendix A. SPIFFE Bundle Example
In the following example, we configure an initial SPIFFE bundle for the trust domain named `example.com` and then demonstrate how the bundle is updated during root key rotation.

Initial X.509 CA certificate for trust domain `example.com`:

```
Certificate #1:
    Data:
        Version: 3 (0x2)
        Serial Number:
            df:d0:ad:fd:32:9f:b8:15:76:f5:d4:b9:e3:be:b5:a7
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O = example.com
        Validity
            Not Before: Jan  1 08:00:45 2019 GMT
            Not After : Apr  1 08:00:45 2019 GMT
        Subject: O = example.com
        X509v3 extensions:
            X509v3 Key Usage: critical
                Certificate Sign
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Alternative Name:
                URI:spiffe://example.com/
[...]
```

Note that the certificate:
1. is self-signed (Issuer and Subject are the same);
1. has the CA flag set to true;
1. and is a SVID (has a spiffe URI SAN).

The corresponding trust bundle for `example.com`:
```
Trust bundle #1 for example.com:
{
        "spiffe_sequence": 1,
        "spiffe_refresh_hint": 2419200,
        "keys": [
                {
                        "kty": "RSA",
                        "use": "x509-svid",
                        "x5c": ["<base64 DER encoding of Certificate #1>"],
                        "n": "<base64urlUint-encoded value>",
                        "e": "AQAB"
                }
        ]
}
```

The above trust bundle is revision 1 as indicated by the `spiffe_sequence` field and indicates that clients should poll for updates of the trust bundle every 2419200 seconds (or 28 days). Note that `x5c` parameter contains the base64-encoded DER certificate as specified in RFC7517 [Section 4.7][10]. Encoding methods for the key-specific values (eg. `n` and `e`) are described in RFC7518 [Section 6][11].

In preparation for the eventual expiration of `example.com`’s CA certificate, a replacement certificate is generated and added to the trust bundle:
```
Certificate #2:
    Data:
        Version: 3 (0x2)
        Serial Number:
            a4:dc:5f:05:8a:a2:bf:88:9d:a4:fa:1e:9a:a5:db:74
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O = example.com
        Validity
            Not Before: Feb  15 08:00:45 2019 GMT
            Not After : Jul  1 08:00:45 2019 GMT
        Subject: O = example.com
        X509v3 extensions:
            X509v3 Key Usage: critical
                Certificate Sign
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Alternative Name:
                URI:spiffe://example.com/
[...]
```

The updated trust bundle for `example.com` published on Feb 15:
```
Trust bundle #2 for example.com:
{
        "spiffe_sequence": 2,
        "spiffe_refresh_hint": 2419200,
        "keys": [
                {
                        "kty": “RSA”,
                        "use": "x509-svid",
                        "x5c": ["<base64 DER encoding of Certificate #1>"],
                        "n": "<base64urlUint-encoded value>",
                        "e": "AQAB"
                },
                {
                        "kty": “RSA”,
                        "use": "x509-svid",
                        "x5c": ["<base64 DER encoding of Certificate #2>"],
                        "n": "<base64urlUint-encoded value>",
                        "e": "AQAB"
                }
        ]
}
```

In trust bundle #2, note that the `spiffe_sequence` parameter has been incremented and the second root certificate for `example.com` has been added. Once this new trust bundle is published and distributed, validators will accept SVIDs signed by either the original or the replacement root certificate. By publishing the replacement certificate well ahead of the expiration of the original certificate, validators have ample opportunity to refresh the trust bundle of example.com and learn of the pending replacement certificate.

[1]: https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE-ID.md#2-spiffe-identity
[2]: https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE-ID.md#3-spiffe-verifiable-identity-document
[3]: https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE_Workload_API.md
[4]: https://tools.ietf.org/html/rfc7517
[5]: https://tools.ietf.org/html/rfc7517#section-5
[6]: https://tools.ietf.org/html/rfc7517#section-4.1
[7]: https://openid.net/connect/
[8]: https://github.com/spiffe/spiffe/blob/master/standards/X509-SVID.md
[9]: https://tools.ietf.org/html/rfc8555
[10]: https://tools.ietf.org/html/rfc7517#section-4.7
[11]: https://tools.ietf.org/html/rfc7518#section-6
