# The SPIFFE Trust Domain and Bundle

## Status of this Memo
This document specifies an experimental identity document standard for the internet community, and requests discussion and suggestions for improvements. Distribution of this document is unlimited.

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
5\. [SPIFFE Bundle Endpoint](#5-spiffe-bundle-endpoint)  
5.1. [Endpoint Stability](#51-endpoint-stability)  
5.2. [Authenticating the Bundle Endpoint](#52-authenticating-the-bundle-endpoint)  
5.2.1. [Web PKI](#521-web-pki)  
5.2.2. [SPIFFE Authentication](#522-spiffe-authentication)  
6\. [Security Considerations](#6-security-considerations)  
6.1. [Securing SPIFFE Bundle Transmission](#61-securing-spiffe-bundle-transmission)  
6.2. [SPIFFE Bundle Refresh Hint](#62-spiffe-bundle-refresh-hint)  
6.3. [Using Web PKI on a SPIFFE Bundle Endpoint](#63-using-web-pki-on-a-spiffe-bundle-endpoint)  
6.4. [Reusing Cryptographic Keys Across Trust Domains](#64-reusing-cryptographic-keys-across-trust-domains)  
Appendix A. [SPIFFE Bundle Example](#appendix-a-spiffe-bundle-example)  
Appendix B. [Bundle Endpoint Authentication Examples](#appendix-b-bundle-endpoint-authentication-examples)  
Appendix B.1. [Web PKI-based Endpoint Authentication](#appendix-b1-web-pki-based-endpoint-authentication)
Appendix B.2. [SPIFFE-based Endpoint Authentication](#appendix-b2-spiffe-based-endpoint-authentication)

## 1. Introduction
SPIFFE trust domains represent the basis by which a SPIFFE ID is qualified, indicating the realm or authority under which any given SPIFFE ID has been issued. They are backed by an issuing authority, which is tasked with managing the issuance of SPIFFE identities within its respective trust domain. While the name of a trust domain consists of a simple human-readable string, it is also necessary to express the cryptographic keys in use by the trust domain's issuing authority, enabling others to validate the identities it issues. These keys are expressed as a "SPIFFE bundle", which goes hand in hand with the trust domain that it represents.

This specification defines the nature and semantics of both SPIFFE trust domains and bundles. It also defines the "bundle endpoint", a mechanism by which SPIFFE bundles may be communicated between trust domains.

## 2. Trust Domains
A SPIFFE trust domain is an identity namespace which is backed by an issuing authority with a set of cryptographic keys. Together, these keys serve as the cryptographic anchor for all identities residing in the trust domain.

Trust domains have a 1:N relationship with the keys that back them. A single trust domain may be represented by multiple keys and key types. For example, the former may be leveraged during root rotation, while the latter is necessary in avoiding multi-protocol attacks should more than one SVID type be in use.

It should be noted that while it is possible to share cryptographic keys amongst many trust domains, we strongly advise that each authoritative key be used in a single trust domain. Key reuse can degrade trust domain isolation (e.g. between staging and production) and introduces additional security challenges (e.g. requiring a name constraint system for secondary issuers). Please see the [Security Considerations](#6-security-considerations) section for more information on this topic.

For more information about how a trust domain namespace is represented, please see [Section 2][1] of the SPIFFE ID specification.

## 3. SPIFFE Bundles
A SPIFFE bundle is an object containing a trust domain's cryptographic keys. The keys within the bundle are considered authoritative for the trust domain that the bundle represents, and are used to prove the validity of [SVIDs][2] that reside in that trust domain.

SPIFFE bundles are designed for use within and between SPIFFE control plane implementations. They are not meant for direct consumption by workloads, however this specification does not preclude such use.

When storing or otherwise managing SPIFFE bundles, it is important to independently record the name of the trust domain that the bundle represents, nominally through the use of a `<trust_domain, bundle>` tuple. When validating an SVID, validators must choose the bundle corresponding to the trust domain that the SVID resides in, so maintaining this relationship is required in most scenarios.

Note that the contents of a trust domain's bundle are expected to change over time as the keys it contains are rotated. It is the responsibility of the SPIFFE implementation to distribute bundle content updates to workloads as needed. The exact format and method by which these updates are delivered is out of scope for this specification. Please see the [SPIFFE Bundle Endpoint](#5-spiffe-bundle-endpoint) section for more information about SPIFFE bundle rotation, and the [SPIFFE Workload API][3] specification for information on delivering updates to workloads.

## 4. SPIFFE Bundle Format
SPIFFE bundles are represented as an [RFC 7517][4] compliant JWK set. JWK was chosen for two major reasons. First, it provides a flexible format for representing various types of cryptographic keys (and documents like X.509), affording some degree of future proofing in the event that new SVID formats are defined. Second, it is widely supported and deployed, used primarily for inter-domain federation, which is a core goal of the SPIFFE project.

### 4.1. JWK Set
This section defines the parameters of the JWK Set. Parameters not defined here MAY be included as implementers see fit, however SPIFFE implementations MUST NOT require their presence in order to function.

#### 4.1.1. Sequence Number
The parameter `spiffe_sequence` SHOULD be set. This sequence number may be used by SPIFFE control planes for many purposes, including propagation measurement and update ordering/supersession. When present, its value MUST be a monotonically increasing integer, and MUST be changed whenever the contents of the bundle are updated.

It should be noted that, while JSON integer type is variable width with no maximum limit defined, many implementations may parse it into a fixed width type. Care should be taken to ensure that the resulting type has at least 64 bits of precision in order to mitigate overflow.

#### 4.1.2. Refresh Hint
The parameter `spiffe_refresh_hint` SHOULD be set. The refresh hint indicates how often a consumer should check back for updates. Bundle publishers may advertise a refresh hint as a function of their key rotation frequency. It should also be noted that the refresh hint may also affect how rapidly a key redaction is propagated. When set, its value MUST be an integer representing the suggested consumer refresh interval in seconds. As the name suggests, the refresh interval is only a hint and consumers may check for updates more or less frequently depending on implementation.

#### 4.1.3. Keys
The parameter `keys` MUST be present. Its value is an array of JWKs. Clients encountering unknown key types or uses MUST ignore the corresponding JWK element. Please see [Section 5][5] of RFC 7517 for more information about the semantics of the `keys` parameter.

### 4.2. JWK
This section defines high level requirements of the JWK elements which are included as part of the JWK Set. A JWK element represents a single cryptographic key, meant for authenticating a single type of SVID. While the exact requirements for safe use of a JWK vary by SVID type, there are some top level requirements which we outline in this section. SVID specifications MUST define the appropriate value for the `use` parameter (see section `Public Key Use` below), and MAY place further requirements or restrictions on its JWK elements as necessary.

Implementers SHOULD NOT include parameters which are defined neither here nor in the respective SVID specification.

#### 4.2.1. Key Type
The `kty` parameter MUST be set, and its behavior follows [Section 4.1][6] of RFC 7517. Clients encountering an unknown key type MUST ignore the entire JWK element.

#### 4.2.2. Public Key Use
The `use` parameter MUST be set. Its value indicates the type of identity document (or SVID) that it is authoritative for. At the time of this writing, only two SVID types are supported: `x509-svid` and `jwt-svid`. The values are case sensitive. Please see the respective SVID specifications for more information about `use` values. Clients encountering unknown `use` values MUST ignore the entire JWK element.

## 5. SPIFFE Bundle Endpoint
It is often desirable to allow workloads in one trust domain to communicate with workloads in another. In order to accomplish this, it is necessary for the validator to possess the bundle of the foreign trust domain in which the remote workload (or identity) resides. As a result, a mechanism for transferring bundles is necessary.

The primary mechanism by which SPIFFE bundles are transferred is similar to, and fully compatible with, the `jwks_uri` mechanism defined in the [OpenID Connect][7] specification, and is known as the "bundle endpoint". When used in conjunction with OpenID Connect Discovery, it MUST be a TLS-protected HTTP endpoint (i.e. with the `https` scheme set). 

All bundle endpoint servers and clients SHOULD support TLS-protected HTTP transport in order to preserve interoperability between SPIFFE implementations and compatibility with OpenID Connect. In cases where public interoperability is not required, such as custom implementations meant for internal consumption, alternative secure transport mechanisms MAY be used.

When communicating with a bundle endpoint, it is critical to know the name of the trust domain that the endpoint represents. SPIFFE implementations MUST securely associate bundle endpoints with their respective trust domain, nominally through explicit configuration of a `<trust_domain, endpoint>` tuple.

### 5.1. Endpoint Stability
By utilizing [sequence number](#411-sequence-number) and [refresh hints](#412-refresh-hint), endpoint implementers have the option of publishing a trust bundle to a single, fixed endpoint URL; clients can utilize the sequence number to quickly determine when a new bundle has been retrieved and the refresh hint to determine how frequently to poll for updates. Whenever the contents of the trust bundle are updated (which includes the sequence number), the endpoint URL should remain unchanged so that clients can continue fetching updates from a stable endpoint without regard to the specific revision of the bundle available at the endpoint.

### 5.2. Authenticating the Bundle Endpoint
It is extremely important for remote bundle endpoints to be appropriately authenticated. If the bundle transmission is compromised, it will result in the attacker being able to assume arbitrary identities in the remote trust domain. We rely on TLS to give us some of these assurances, and this specification does not explicitly mandate support for a particular authentication strategy.

This section provides an overview of two recommended authentication mechanisms.

#### 5.2.1. Web PKI
Leveraging publicly trusted authorities provides a low-friction path to authenticating remote bundle endpoints. In this strategy, the bundle endpoint obtains a certificate from a public CA which is bound to its DNS name or IP address. To import the foreign bundle, operators configure their SPIFFE control plane with the URL of the bundle endpoint, as well as the trust domain that the bundle represents.

Taking this approach requires little-to-no manual intervention, since we rely on public trust in order to secure the connection. Please see the [Security Considerations](#6-security-considerations) section and the [SPIFFE Authentication](#522-spiffe-authentication) section for more information about the security implications of using Web PKI to protect a SPIFFE bundle endpoint.

#### 5.2.2. SPIFFE Authentication
By protecting the bundle endpoint with a SPIFFE identity (e.g. an [X509-SVID][8]), it is possible to mitigate certain person-in-the-middle attacks as well as avoid trusting public CAs. In this strategy, the bundle endpoint is served using an identity it has obtained from its own trust domain. To import the bundle, operators configure their SPIFFE control plane with the URL of the bundle endpoint, as well as the SPIFFE ID of the workload serving the bundle endpoint. The operator is additionally required to provide an initial up-to-date bundle from the remote trust domain, obtained through an offline exchange.

Taking this approach has the benefit of being more secure than the Web PKI approach, but comes at the cost of operator responsibility and additional complexity. The SPIFFE control plane authenticates the bundle endpoint using the manually-provided bundle, and subsequent updates can be delivered over the same channel, negating the need for further operator intervention when keys in the bundle rotate. The trust domain that the bundle represents can be derived directly from the operator-configured SPIFFE ID of the bundle endpoint.

## 6. Security Considerations
This section outlines security-related considerations that should be made while implementing and deploying a SPIFFE control plane.

### 6.1. Securing SPIFFE Bundle Transmission
When fetching a SPIFFE bundle from a bundle endpoint, the use of transport security is required in order to prevent its contents from being modified in flight. In addition to transport security however, it is necessary to securely bind the name of the trust domain to the identity of the workload serving the bundle.

The manner in which this is done is dependent upon the type of authentication and validation used. For instance, if using Web PKI, then an operator-supplied `<trust_domain, endpoint_address>` tuple is sufficient. The trust domain is explicitly bound to the endpoint address through the supplied tuple, and (per standard Web PKI secure naming) the endpoint address is equivalent to the identity of the serving workload. 

This can be contrasted to the use of SPIFFE authentication, where the identity of the workload is not the same as the endpoint address. In this case, a different parameter (the SPIFFE ID of the bundle endpoint) is required. The trust domain can be implicitly extracted from the provided SPIFFE ID. Concretely, this translates into an operator-supplied tuple of `<trust_domain, spiffe_id, endpoint_address>` or simply `<spiffe_id, endpoint_address>`.

Please see the [Authenticating the Bundle Endpoint](#52-authenticating-the-bundle-endpoint) section and the [Bundle Endpoint Authentication Examples](#appendix-b-bundle-endpoint-authentication-examples) appendix item for more information.

### 6.2. SPIFFE Bundle Refresh Hint
SPIFFE bundles include an optional `refresh_hint` field meant to indicate the frequency at which consumers should attempt to refresh their copy of the bundle. This value has a clear impact on how quickly keys can be rotated, but it also impacts how quickly keys can be redacted. Refresh hint values should be carefully chosen with this in mind.

Since this field is not mandatory, it is possible to encounter SPIFFE bundles that do not have a `refresh_hint` set. In this case, a client has the option of using a suitable interval by examining SVID validity periods. It should be acknowledged that omitting a `refresh_hint` will likely impact the ability of a trust domain to rapidly revoke compromised keys. Clients should default to a relatively low (e.g. five minutes) refresh interval to be able to retrieve updated trust bundles in a timely manner.

### 6.3. Using Web PKI on a SPIFFE Bundle Endpoint
Web PKI provides a convenient way to authenticate remote SPIFFE bundle endpoints as publicly trusted authorities can negate the need for an initial out-of-band bundle exchange (as is the case when using SPIFFE authentication). While largely reliable, there are some tradeoffs and drawbacks that should be considered before its use.

The first and most obvious is that you are assuming trust in the public certificate authorities and in their fulfillment procedures. Any public CA can sign a certificate for the domain name where your bundle endpoint is hosted that will appear valid. While this may be an unacceptable risk to some, most users are OK with it given the convenience it provides and the historical stability of the public CA infrastructure.

Second, more importantly, recently introduced automated fulfillment protocols like [ACME][9] make room for attacks that were not previously possible. ACME allows publicly trusted certificates to be issued without manual intervention by performing a challenge which allows a machine to assert that it is authorized by answering an HTTP request made to the DNS name of the certificate being issued. This is significant because it means that anyone that can intercept and answer the challenge is capable of receiving a valid publicly-trusted certificate. While the risk of interception across the open internet is decidedly low, risk of interception by a neighboring machine is high. Concretely, without adequate Layer 2 security controls, SPIFFE bundle endpoints using Web PKI may be subverted by malicious software with access to the same Layer 2 network as the bundle endpoint. Operators should be careful in ensuring that Layer 2 access to SPIFFE bundle endpoints protected by Web PKI is restricted.

### 6.4. Reusing Cryptographic Keys Across Trust Domains
This specification discourages sharing cryptographic keys across trust domains since the practice degrades trust domain isolation and introduces additional security challenges. When a root key is shared across multiple trust domains, it becomes critically important that authentication and authorization implementations carefully check the trust domain component of an identity and that the trust domain component be easily and habitually expressed in authorization policies.

Suppose that a naïve implementation imported (ie. fully trusted) a particular root key and that the authentication system were configured to authenticate the SPIFFE identity of any SVID which chained up to the trusted root key. If the naïve implementation is not configured to only trust a specific trust domain, then any identity issued in any trust domain could be authenticated (so long as the SVID chains up to the trusted root key). Successful authentication of an external trust domain is not a problem per se since the risk can be mitigated by a correctly implemented authorization system; however, this risk could alternatively be mitigated by simply not reusing root keys across trust domains.

Continuing the above example where a naïve implementation imports a particular CA certificate, suppose that the authentication did not disambiguate trust domains and that any SVID which chained up to a trusted root key were accepted by the authentication system. Then it would become incumbent on the authorization system to only authorize specific trust domains. In other words, authorization policies need to be explicitly configured to check the trust domain component of an SVID. The security concern here is that a naïve authorization implementation may blindly trust that the authentication system has filtered out untrusted trust domains.

In summary, a security-in-depth best practice is to maintain a one-to-one mapping between trust domain and root keys so as to reduce subtle (yet catastrophic) authentication and authorization implementation errors. Systems which do reuse root keys across trust domains should ensure that (a) the SVID-issuing system (eg. CA) correctly implements authorization checks prior to issuing SVIDs and (b) that relying parties (ie. systems consuming the SVIDs) correctly implement robust authentication and authorization systems capable of disambiguating multiple trust domains.

## Appendix A. SPIFFE Bundle Example
In the following example, we configure an initial SPIFFE bundle for the trust domain `example.com` and then demonstrate how the bundle is updated during root key rotation.

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
			"kty": "RSA"
			"use": "x509-svid",
			"x5c": ["<base64 DER encoding of Certificate #1>"]
			"n": "<base64urlUint-encoded value>"
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
			"kty": “RSA”
			"use": "x509-svid",
			"x5c": ["<base64 DER encoding of Certificate #1>"]
			"n": "<base64urlUint-encoded value>"
			"e": "AQAB"
		},
		{
			"kty": “RSA”
			"use": "x509-svid",
			"x5c": ["<base64 DER encoding of Certificate #2>"]
			"n": "<base64urlUint-encoded value>"
			"e": "AQAB"
		}
	]
}
```

In trust bundle #2, note that the `spiffe_sequence` parameter has been incremented and the second root certificate for `example.com` has been added. Once this new trust bundle is published to `example.com`’s bundle endpoint, validators will accept SVIDs signed by either the original or the replacement root certificate. By publishing the replacement certificate well ahead of the expiration of the original certificate, validators have ample opportunity to refresh the trust bundle of example.com and learn of the pending replacement certificate.

## Appendix B. Bundle Endpoint Authentication Examples
This section provides two worked examples of how to authenticate bundle endpoints, one for each of the recommended authentication methods described in this specification

### Appendix B.1. Web PKI-based Endpoint Authentication
Alice wants to federate with Bob using Web PKI so that she can authenticate identities residing in Bob’s trust domain. Alice is an administrator of the `alice.example` trust domain, and Bob is an administrator of the `bob.example` trust domain. To do so securely, the following steps are performed:

1. Bob provides Alice with his trust domain name (`bob.example`) and the HTTPS URL of his bundle endpoint (`https://bob.example.org/spiffe-bundle`)
1. Alice configures configures her control plane with the information received in the previous step - Bob's trust domain name and the HTTPS endpoint
1. Alice's control plane dials `bob.example.org`, and negotiates TLS using Web PKI, ensuring that it receives a server certificate for `bob.example.org`
1. Alice's control plane issues an HTTP GET request over the authenticated TLS connection for path `/spiffe-bundle`
1. Bob's control plane answers, transmitting the latest available copy of its SPIFFE bundle
1. Alice's control plane receives Bob's bundle and stores it, being careful to mark it as the SPIFFE bundle for trust domain `bob.example`
1. Systems in Alice's trust domain can now validate SVIDs from `bob.example` using the keys contained in the SPIFFE bundle received from Bob

Alice's control plane periodically repeats steps 3-6 to ensure that her copy of Bob's bundle is kept up-to-date as Bob rotates his keys 

### Appendix B.2. SPIFFE-based Endpoint Authentication
Alice wants to federate with Bob so that she can authenticate identities residing in Bob's trust domain, however she does not want to rely on Web PKI. Instead, Alice and Bob will use SPIFFE authentication. Alice is an administrator of the `alice.example` trust domain, and Bob is an administrator of the `bob.example` trust domain. To do this securely, the following steps are performed:

1. Bob provides Alice with the SPIFFE ID of his bundle endpoint service (`spiffe://bob.example/control-plane/bundle-endpoint`), and a URL that she can reach it at (`https://bob.example.org/spiffe-bundle`). He also provides an up-to-date copy of his SPIFFE bundle
1. Alice loads the SPIFFE bundle from the last step into her control plane, being careful to set it as the bundle for the `bob.example` trust domain
1. Alice configures her control plane with the SPIFFE ID and address that she received in step 1. Her control plane extracts the trust domain from the provided SPIFFE ID, and records this as the bundle endpoint configuration for trust domain `bob.example`
1. Alice's control plane dials `bob.example.org` and negotiates TLS using the X.509 CA certificates in the SPIFFE bundle stored for the `bob.example` trust domain. The server certificate is verified to have the SPIFFE ID configured in step 2
1. Alice's control plane issues an HTTP GET request over the authenticated TLS connection for `/spiffe-bundle`
1. Bob's control plane answers, transmitting the latest available copy of its SPIFFE bundle
1. Alice's control plane receives Bob's bundle and stores it, being careful to mark it as the SPIFFE bundle for trust domain `bob.example`

After step 2, systems in Alice’s trust domain can validate SVIDs from `bob.example` using the keys contained in the SPIFFE bundle received from Bob. Alice's control plane periodically repeats steps 4-7 to ensure that her copy of Bob's bundle is kept up-to-date as Bob rotates his keys.

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
