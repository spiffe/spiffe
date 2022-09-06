# SPIFFE Federation

## Status of this Memo
This document specifies an identity API standard for the internet community, and requests discussion and suggestions for improvements. Distribution of this document is unlimited.

## Table of Contents
1\. [Background](#1-background)  
2\. [Introduction](#2-introduction)  
3\. [Targeted Use Cases](#3-targeted-use-cases)  
4\. [SPIFFE Bundle Endpoint](#4-spiffe-bundle-endpoint)  
4.1. [Adding and Removing Keys](#41-adding-and-removing-keys)  
4.2. [Managing Fetched Bundles](#42-managing-fetched-bundles)  
4.3. [Endpoint Address Stability](#43-endpoint-address-stability)  
5\. [Serving and Consuming a SPIFFE Bundle Endpoint](#5-serving-and-consuming-a-spiffe-bundle-endpoint)  
5.1. [Endpoint Parameters](#51-endpoint-parameters)  
5.2. [Endpoint Profiles](#52-endpoint-profiles)  
5.2.1. [Web PKI (`https_web`)](#521-web-pki-https_web)  
5.2.1.1. [Endpoint URL Requirements](#5211-endpoint-url-requirements)  
5.2.1.2. [Endpoint Parameters](#5212-endpoint-parameters)  
5.2.1.3. [Serving a Bundle Endpoint](#5213-serving-a-bundle-endpoint)  
5.2.1.4. [Consuming a Bundle Endpoint](#5214-consuming-a-bundle-endpoint)  
5.2.2. [SPIFFE Authentication (`https_spiffe`)](#522-spiffe-authentication-https_spiffe)  
5.2.2.1. [Endpoint URL Requirements](#5221-endpoint-url-requirements)  
5.2.2.2. [Endpoint Parameters](#5222-endpoint-parameters)  
5.2.2.3. [Serving a Bundle Endpoint](#5223-serving-a-bundle-endpoint)  
5.2.2.4. [Consuming a Bundle Endpoint](#5224-consuming-a-bundle-endpoint)  
6\. [Relationship Lifecycle](#6-relationship-lifecycle)  
6.1. [Establishing a Relationship](#61-establishing-a-relationship)  
6.2. [Maintaining a Relationship](#62-maintaining-a-relationship)  
6.3. [Terminating a Relationship](#63-terminating-a-relationship)  
6.4. [Lifecycle Diagram](#64-lifecycle-diagram)  
7\. [Security Considerations](#7-security-considerations)  
7.1. [Distribution of Endpoint Parameters](#71-distribution-of-endpoint-parameters)  
7.2. [Explicitly-defined Endpoint Parameters](#72-explicitly-defined-endpoint-parameters)  
7.3. [Preserving the `<Trust Domain, Bundle>` Binding](#73-preserving-the-trust-domain-bundle-binding)  
7.4. [Trustworthiness of the Bundle Endpoint Server](#74-trustworthiness-of-the-bundle-endpoint-server)  
7.5. [Authenticity of the Bundle Endpoint](#75-authenticity-of-the-bundle-endpoint)  
7.5.1. [Bundle Endpoint URL Redirection](#751-bundle-endpoint-url-redirection)  
7.5.2. [Network Traffic Interception](#752-network-traffic-interception)  
7.5.3. [Endpoint Parameters](#753-endpoint-parameters)  
7.6. [Chaining Trust with `https_spiffe`](#76-chaining-trust-with-https_spiffe)  

## 1. Background
The SPIFFE specifications define the documents and interfaces necessary for establishing a platform-agnostic workload identity framework that is capable of bridging systems in different domains without the need for implementing identity translation or credential exchange logic. They define a “[trust domain][1]”, which serves as an identity namespace.

SPIFFE is decentralized by nature. Each trust domain acts in its own capacity, under its own authority, and is administratively isolated from systems residing in other trust domains. Although trust domains delineate administrative and/or security domains, a core SPIFFE use case is enabling communication across these same boundaries where needed. Therefore, it is necessary to define a mechanism by which an entity may be introduced to a foreign trust domain, allowing it to authenticate credentials issued by “other” SPIFFE authorities and allowing workloads in one trust domain to securely authenticate workloads in a foreign trust domain.

A [SPIFFE bundle][2] is a resource that contains the public key material needed to authenticate credentials from a particular trust domain. This document introduces a specification by which SPIFFE bundles can be securely fetched for the purpose of authenticating identities issued by external authorities. Included is information on how to serve a SPIFFE bundle, how to retrieve a SPIFFE bundle, and how to authenticate the endpoints that serve them.

## 2. Introduction
SPIFFE Federation enables the authentication of identity credentials (SVIDs) across trust domains. Specifically, it is the act of obtaining the necessary SPIFFE bundle(s) to authenticate SVIDs issued by a different trust domain, and providing said bundles to the workloads performing the authentication.

Possession of a trust domain's bundle is required in order to validate SVIDs from it. Therefore, achieving SPIFFE Federation necessitates the exchange of SPIFFE bundles between trust domains. This exchange should occur on a regular basis, allowing the contents of a trust domain's bundle to change over time.

To achieve this, SPIFFE Federation defines a "bundle endpoint", which is a URL that serves up a SPIFFE bundle for a particular trust domain. Also defined are a set of "endpoint profiles", which specify the protocol and authentication semantics used between bundle endpoint servers and clients. Finally, this document further specifies the behavior of bundle endpoint clients and servers, and the management of federation relationships and the resulting bundle data.

## 3. Targeted Use Cases
Ultimately, SPIFFE Federation enables workloads to authenticate peers that reside in other trust domains. This functionality is necessary to support a wide range of use cases, however we wish to focus on three core use cases.

SPIFFE Trust Domains are frequently used to segment environments with differing levels of trust within the same company or organization. Examples of this can be between staging and production, or between PCI and non-PCI environments. In these cases, the SPIFFE deployments used in each domain share a common administrative body and are likely backed by the same implementation. This is an important distinction, as it implies that the disparate deployments have the ability to agree on certain things (e.g. naming schemes), and that the security posture of each deployment can be known and well-understood by the others. 

Second, SPIFFE Federation is also used between trust domains residing in different companies or organizations. This case is similar to the first in that we are federating between SPIFFE deployments, however due to potential differences in implementation and administration, coordination is generally limited to the data exchanged in the SPIFFE Federation protocol described herein.

Finally, SPIFFE Federation can also enable use cases for consumers that don't yet have a mature SPIFFE control plane deployed. For example, a hosted product may wish to authenticate its customers using their SPIFFE identities without having to internally implement or deploy SPIFFE. This can be accomplished by allowing a workload to directly fetch the customer's trust domain bundle in order to authenticate their callers, obviating the need to commit to a full-blown SPIFFE deployment.

## 4. SPIFFE Bundle Endpoint
A SPIFFE bundle endpoint is a resource (represented by a URL) that serves a copy of a SPIFFE bundle for a trust domain. SPIFFE control planes may both expose and consume these endpoints in order to transfer bundles between themselves, thereby achieving federation.

The semantics of the SPIFFE bundle endpoint are similar to the `jwks_uri` mechanism defined in the OpenID Connect specification in that the bundle contains one or more public cryptographic keys used by a trust domain (for certifying identities within the trust domain). The bundle endpoint is an HTTPS URL that responds to an HTTP GET with a SPIFFE bundle. For more information about SPIFFE bundles and how they are encoded, please see the [SPIFFE Trust Domain and Bundle][3] specification.

### 4.1. Adding and Removing Keys
Operators of a trust domain MAY introduce or remove keys used to issue SVIDs within the trust domain as needed (e.g. as part of an internal key rotation process). When adding new keys, an updated trust bundle containing the keys SHOULD be published at the bundle endpoint sufficiently in advance that foreign trust domains have an opportunity to retrieve and internally disseminate the new bundle contents; the recommended advance time is 3-5 times the bundle’s `spiffe_refresh_hint`. At a minimum, new keys MUST be published at the bundle endpoint prior to the keys being used to issue SVIDs. 

Deprecated keys SHOULD be removed from the trust bundle after a trust domain no longer has any active, valid SVIDs issued from those keys. Failure to follow these recommendations as keys are added to and removed from the bundle could result in transient cross-domain authentication failures.

Requirements for updating the trust bundle do not apply to keys used to issue SVIDs for internal use only.

Clients SHOULD periodically poll the endpoint for updates because the contents are expected to [change over time][4] - key validity periods on the order of weeks or even days is commonplace. Clients SHOULD poll at a frequency equal to the value of the bundle’s `spiffe_refresh_hint`, in seconds. If not set, a reasonably low default value should apply - five minutes is recommended.

### 4.2. Managing Fetched Bundles
Clients of the bundle endpoint SHOULD store the latest SPIFFE bundle each time it is retrieved. The sequence number field of the trust bundle SHOULD be used when comparing the freshness or ordering of two trust bundles. If the trust bundle omits the sequence number, operators SHOULD consider the most recently retrieved bundle to be up-to-date.

Operators MAY locally update the SPIFFE bundle of a foreign trust domain at any time. In this case, the locally updated version of the bundle is considered the latest until replaced by a subsequent refresh.

Bundle contents from different trust domains MUST NOT be merged into a single, larger bundle. Doing so would enable one trust domain to forge identities belonging to another trust domain in the eyes of the validator with the unified bundle. As such, it is very important to ensure that bundles received from foreign trust domains be kept distinct, and clearly reflect the trust domain name to which they belong. Please see the [Security Considerations](#7-security-considerations) section for more information.

### 4.3. Endpoint Address Stability
Once foreign trust domains begin relying on a specific endpoint URL, it is a delicate and error-prone procedure to migrate all clients of the endpoint to a replacement endpoint URL. Therefore, the safest course of action is to prefer a stable endpoint URL.

## 5. Serving and Consuming a SPIFFE Bundle Endpoint
This specification defines two supported profiles for SPIFFE bundle endpoint servers, both of which are based on HTTPS. One relies on the use of Web PKI to authenticate the endpoint and the other leverages SPIFFE authentication. SPIFFE bundle endpoint clients MUST support both of these profiles while SPIFFE bundle endpoint servers MUST support at least one.

Bundle endpoint servers that support TLS-based profiles (e.g. `https_web` or `https_spiffe`) MUST adhere to the [Mozilla intermediate compatibility][5] requirements unless otherwise stated by the profile in use.

### 5.1. Endpoint Parameters
Prior to retrieving a bundle from a SPIFFE bundle endpoint, clients MUST be configured with the following three parameters: (1) the URL of the SPIFFE bundle endpoint, (2) the endpoint profile type, and (3) the trust domain name to associate with the bundle endpoint. The first two parameters indicate the location of the bundle endpoint and how to authenticate it. Since trust bundles do not contain a trust domain name, clients use the third parameter to associate a downloaded bundle with a specific trust domain name. Specific [endpoint profiles](#52-endpoint-profiles) (such as `https_spiffe`, as described below) MAY define additional mandatory configuration parameters.

```
Bundle Endpoint URL:		"https://example.com/production/bundle.json"
Bundle Endpoint Profile:	"https_web"
Trust Domain:			"prod.example.com"
```  
*Figure 1: Example SPIFFE bundle endpoint configuration for trust domain prod.example.com. Administrators configure SPIFFE control planes to retrieve foreign trust bundles through a bundle endpoint configuration.*

When a control plane internally distributes trust bundles to workloads, the association between trust domain name and trust bundle MUST be communicated. Please see the [Security Considerations](#7-security-considerations) section for more information about the sensitivity of these parameters.

![SPIFFE bundle distribution](https://raw.githubusercontent.com/evan2645/spiffe/ecb9fb894e1a13fae821c370f7b5ddeee634d1c8/standards/img/spiffe_bundle_distribution.png)  
*Figure 2: After retrieving a foreign SPIFFE trust bundle, control planes distribute both the trust domain name and the corresponding bundle to internal workloads. Workloads use this configuration to validate identities in the foreign trust domain. For details about the trust bundle contents, refer to The [SPIFFE Trust Domain and Bundle][3], specifically the [SPIFFE Bundle Format][6] and [SPIFFE Bundle Example][4] sections.*

The requirements in this section apply to all SPIFFE bundle endpoint servers and clients. Individual SPIFFE bundle endpoint profiles MAY add further requirements.

### 5.2. Endpoint Profiles
An endpoint profile describes both the transport protocol and authentication method that should be used when serving or consuming a bundle endpoint.

The following sections describe the supported bundle endpoint profiles.

#### 5.2.1. Web PKI (`https_web`)
The `https_web` profile leverages publicly trusted certificate authorities to provide a low-friction path for configuring SPIFFE Federation. It behaves identically to the "https" URLs that most people are familiar with when accessing web pages in their browsers. In this profile, the bundle endpoint server uses a certificate issued by a public CA, obviating the need for additional client configuration; endpoints using the `https_web` profile type are authenticated using the same public CA certificates commonly installed in modern operating systems.

Please see the [Security Considerations](#7-security-considerations) section for more information about the use of public certificate authorities.

##### 5.2.1.1. Endpoint URL Requirements
Bundle endpoint URLs utilizing `https_web` MUST have the scheme set to `https` and MUST NOT include userinfo in the authority component. Other components of the URL (as defined by [RFC 3986 section 3][7]) are not constrained by this specification.

For example, the URL `https://host.example.com/trust_domain` is a valid SPIFFE bundle endpoint URL for the `https_web` profile type.

##### 5.2.1.2. Endpoint Parameters
The `https_web` profile MUST NOT require any additional parameters beyond those required for every profile (namely the trust domain name, profile type, and endpoint URL) in order to function.

##### 5.2.1.3. Serving a Bundle Endpoint
SPIFFE bundle endpoint servers supporting the `https_web` transport type utilize standard TLS-protected HTTP (i.e. HTTPS). The server certificate used SHOULD be issued by a public certificate authority (as defined by the membership list of the CA/Browser forum), and MUST include the DNS name or IP address of the endpoint as an X.509 Subject Alternative Name (or Common Name). 

As an interoperability concern, servers MUST NOT require client authentication to access the bundle endpoint; this includes both transport layer (e.g. client certificates) and HTTP-layer (e.g. Authentication headers) authentication schemes.

Upon receiving an HTTP GET request for the correct path, the bundle endpoint server MUST respond with the most up-to-date version of the SPIFFE bundle available. The response MUST be encoded as UTF-8 and SHOULD set the `Content-Type` header to `application/json` on the response. The path from which the SPIFFE bundle is served is not constrained by this specification.

Bundle endpoint servers MAY respond with HTTP redirect (as defined by [RFC 7231 section 6.4][8]) if the authority for serving the requested bundle has moved.  The target URL of the redirect MUST also be a [valid bundle endpoint URL](#5211-endpoint-url-requirements) as defined in this profile. Servers SHOULD use a temporary redirect; support for redirection is intended for operational considerations (e.g. serving a bundle via a CDN) and not as a means to permanently migrate the bundle endpoint URL. See the [Security Considerations](#7-security-considerations) for more information.

##### 5.2.1.4. Consuming a Bundle Endpoint
SPIFFE bundle endpoint clients utilize standard TLS-protected HTTP (i.e. HTTPS) when interacting with an `https_web` bundle endpoint. When connecting to the endpoint, the server certificate MUST be validated in accordance with [RFC 6125][11]. To summarize that document, the server certificate MUST be issued by a certificate authority which is locally trusted and it MUST contain an X.509 Subject Alternative Name (or Common Name) that matches the host component of the configured endpoint URL.

After establishing a TLS connection to the bundle endpoint and authenticating the presented server certificate, clients issue an HTTP GET for the path specified by the endpoint URL. The body of the response is a SPIFFE bundle. Clients MUST know the name of the trust domain that the endpoint URL represents prior to retrieving the trust bundle, ideally via explicit configuration; please see the [Security Considerations](#7-security-considerations) section for more information.

Bundle endpoint servers MAY respond with HTTP redirect (as defined by [RFC 7231 section 6.4][8]).  Bundle endpoint clients SHOULD follow the redirect if the URL meets all the requirements of a valid bundle endpoint URL.  When connecting to the new URL, the same TLS considerations MUST be applied as connecting to the original URL.  Bundle endpoint clients SHOULD use the configured endpoint URL for each bundle refresh and SHOULD NOT permanently store the location for future fetches. See the [Security Considerations](#7-security-considerations) for more information. 

#### 5.2.2. SPIFFE Authentication (`https_spiffe`)
The `https_spiffe` profile uses an X509-SVID issued by a SPIFFE trust domain (as opposed to a certificate issued by public certificate authorities). This profile allows bundle endpoints to avoid the use of network locators as a form of server identity and additionally supports automated root CA rotation and revocation via standard SPIFFE mechanisms.

In addition to the endpoint parameters required of all profiles, the `https_spiffe` profile requires additional endpoint client parameters as described in Endpoint Parameters below.

##### 5.2.2.1. Endpoint URL Requirements
Bundle endpoint URLs utilizing `https_spiffe` MUST have the scheme set to `https` and MUST NOT include userinfo in the authority component.  Other components of the URL (as defined by [RFC 3986 section 3][7]) are not constrained by this specification. 

For example, the URL `https://host.example.com/trust_domain` is a valid SPIFFE bundle endpoint URL for the `https_spiffe` profile type.

##### 5.2.2.2. Endpoint Parameters
Bundle endpoint clients using the `https_spiffe` profile MUST be configured with the SPIFFE ID of the bundle endpoint server as well as a secure method for obtaining the trust bundle of the endpoint server's trust domain. A **self-serving bundle** endpoint is one in which the bundle endpoint server’s SPIFFE ID resides in the same trust domain as the bundle being fetched. Configured bundle endpoints may or may not be self-serving.
* If the endpoint is self-serving, clients need to be configured with a single up-to-date bundle in order to bootstrap the federation relationship.  Clients MUST support specifying the bundle in [SPIFFE Bundle Format][12] and MAY support other formats (e.g. PEM) provided they provide the necessary root certificate(s) to validate the connection.  Clients rely on this configured bundle for the first retrieval, but then store the retrieved bundle to validate later connections. See [Consuming a Bundle Endpoint](#5224-consuming-a-bundle-endpoint) below for more information.
* If the endpoint is not self-serving, clients MUST be separately configured for the endpoint server’s trust domain.  The endpoint server's trust domain and bundle may be configured in any of the following ways:
  * Endpoint parameters for the trust domain, which configures clients to fetch the bundle using the endpoint profiles as described in this document.  Note that clients MAY use any available profile and are not restricted to `https_spiffe`.
  * A process, automatic or static, to fetch or otherwise configure the bundle, that is not defined by and outside the scope of this document. Please see the [Security Considerations](#7-security-considerations) section for guidance in securing this approach.

```
Bundle Endpoint URL:		"https://example.com/global/bundle.json"
Bundle Endpoint Profile:	"https_spiffe"
Trust Domain:			"example.com"
Endpoint SPIFFE ID:		"spiffe://example.com/spiffe-bundle-server"
Endpoint Trust Bundle:		{example.com bundle contents omitted}
```  
*Figure 3: Example SPIFFE bundle endpoint configuration for trust domain `example.com` using SPIFFE authentication. In this example, the bundle endpoint is self-serving and the configuration includes the SPIFFE ID of the bundle endpoint and the trust bundle for `example.com`, the trust domain of this SPIFFE ID. This initial bundle is used to authenticate the first connection to the bundle endpoint and validate its SVID. Subsequent connections to this bundle endpoint are authenticated using the most recently fetched copy.*

```
Bundle Endpoint URL:		"https://example.com/production/bundle.json"
Bundle Endpoint Profile:	"https_spiffe"
Trust Domain:			"prod.example.com"
Endpoint SPIFFE ID:		"spiffe://example.com/spiffe-bundle-server"
```  
*Figure 4: Example SPIFFE bundle endpoint configuration for trust domain `prod.example.com` using SPIFFE authentication. In this example, the bundle endpoint is not self-serving: the trust bundle for `prod.example.com` is available from `example.com` with SPIFFE ID `spiffe://example.com/spiffe-bundle-server`. The trust bundle needed to authenticate example.com has been previously obtained through the federation example above.*

##### 5.2.2.3. Serving a Bundle Endpoint
SPIFFE bundle endpoint servers supporting the `https_spiffe` transport type utilize standard TLS-protected HTTP (i.e. HTTPS). The server certificate MUST be a valid X509-SVID.

As an interoperability concern, servers MUST NOT require client authentication to access the bundle endpoint; this includes both transport layer (e.g. client certificates) and HTTP-layer (e.g. Authentication headers) authentication schemes.

Upon receiving an HTTP GET request for the correct path, the bundle endpoint server MUST respond with the most up-to-date version of the SPIFFE bundle available. The exact path value may be chosen by the operator, and appears as part of the bundle endpoint URL.  The bundle endpoint server MUST transmit the bundle encoded as UTF-8 and SHOULD set the `Content-Type` header to `application/json` on the response.

Bundle endpoint servers MAY respond with HTTP redirect (as defined by [RFC 7231 section 6.4][8]) if the authority for serving the requested bundle has moved.  The target URL of the redirect MUST also be a [valid bundle endpoint URL](#5221-endpoint-url-requirements) as defined in this profile, and the server certificate presented by the new target must be a valid X509-SVID with the same SPIFFE ID as the original endpoint. Servers SHOULD use a temporary redirect; support for redirection is intended for operational considerations (e.g. serving a bundle via a CDN) and not as a means to permanently migrate the bundle endpoint URL. See the [Security Considerations](#7-security-considerations) for more information.

##### 5.2.2.4. Consuming a Bundle Endpoint
SPIFFE bundle endpoint clients utilize standard TLS-protected HTTP (i.e. HTTPS) when interacting with an `https_spiffe` bundle endpoint. When connecting to the endpoint, it MUST be validated that the server certificate is a valid X509-SVID for the bundle endpoint SPIFFE ID that was provided as a bundle endpoint parameter. See the [SPIFFE X509-SVID][9] specification for information on validating X509-SVIDs.

A self-serving bundle endpoint is one in which the bundle endpoint server’s SPIFFE ID resides in the same trust domain as the bundle being fetched. Upon the first connection to a self-serving bundle endpoint, clients use the operator-supplied SPIFFE bundle (via a bundle endpoint parameter) to validate the server certificate. The latest available bundle MUST be used to validate any subsequent connections. This allows the foreign trust domain to rotate keys without interrupting the federation relationship.

A non-self-serving bundle endpoint is one in which the bundle endpoint server’s SPIFFE ID does not reside in the same trust domain as the bundle being fetched. When connecting to a non-self-serving endpoint, clients use the latest available SPIFFE bundle corresponding to the trust domain of the endpoint’s SPIFFE ID, which might be directly configured or obtained through another federation relationship.

After establishing a TLS connection to the bundle endpoint and authenticating the presented server certificate, clients issue an HTTP GET for the path specified by the endpoint URL. The body of the response is a SPIFFE bundle. Clients MUST know the name of the trust domain that the endpoint URL represents prior to retrieving the trust bundle, ideally via explicit configuration; please see the [Security Considerations](#7-security-considerations) section for more information.

Bundle endpoint servers MAY respond with HTTP redirect (as defined by [RFC 7231 section 6.4][8]).  Bundle endpoint clients SHOULD follow the redirect if the URL meets all the requirements of a valid bundle endpoint URL.  When connecting to the new URL, the same TLS considerations MUST be applied as connecting to the original URL. In particular, it MUST present a valid X509-SVID for the same SPIFFE ID as originally configured.  Bundle endpoint clients SHOULD use the configured endpoint URL for each bundle refresh and SHOULD NOT permanently store the location for future fetches. See the [Security Considerations](#7-security-considerations) for more information. 

## 6. Relationship Lifecycle
This section describes the lifecycle of a federation "relationship", including the establishment of the first connection, ongoing maintenance, and termination.

Federation relationships are one-way. In other words, Alice could have a relationship with Bob but not vice versa. In this case, Alice would be able to validate identities issued by Bob, but Bob would not know how to validate an identity issued by Alice.

To achieve mutual authentication, two relationships are formed - one in each direction.

### 6.1. Establishing a Relationship
As described in the Endpoint Parameters section, all bundle endpoint clients need at least three pieces of information in order to be correctly configured: the foreign trust domain name, its bundle endpoint URL, and the endpoint profile.

The bundle endpoint URL provides the address at which a bundle for the foreign trust domain can be found, and the profile tells clients which protocol should be used when calling it. A profile may require additional profile-specific parameters. Please see the relevant Endpoint Profiles subsection for more information about exactly how to connect to and authenticate a bundle endpoint.

Once the connection has been successfully established, and a copy of the bundle has been received, it is stored along with the name of the trust domain it belongs to. The contents of the bundle (e.g. CA certificates, JWT signing keys, etc) can now be distributed for the purposes of validating SVIDs originating from the foreign trust domain.

The exact nature and mechanism by which this distribution occurs is an implementation detail, and is out of scope for this document. For more information on how SPIFFE-aware workloads can receive bundle updates, please see the [SPIFFE Workload API][10] specification.

### 6.2. Maintaining a Relationship
SPIFFE bundle endpoint clients SHOULD poll the bundle endpoint periodically for updates. When an update is detected, the stored bundle representing the endpoint's foreign trust domain is updated to match. The updated content is then distributed so that validators can add new keys and drop revoked keys as necessary. Again, the exact method(s) for distributing this update to validators is out of scope for this document.

If attempts to poll the bundle endpoint fail, bundle endpoint clients SHOULD retry at the next polling interval, rather than immediately or aggressively retrying, as this can overwhelm the bundle endpoint server. As discussed in the [Adding and Removing Keys](#41-adding-and-removing-keys) section, new keys should be published sufficiently in advance of their use such that missing one or two polls does not result in cross-domain authentication failures.

### 6.3. Terminating a Relationship
Terminating a federation relationship is as simple as deleting the local copy of the foreign trust domain's bundle, and ceasing to poll its bundle endpoint. Of course, this must also be propagated to validators so that they drop the bundle for that foreign trust domain and cease to successfully validate SVIDs presented from it.

In the event that the relationship needs to be re-established, this lifecycle is started over.

### 6.4. Lifecycle Diagram
![The lifecycle of a SPIFFE Federation relationship](https://raw.githubusercontent.com/evan2645/spiffe/2c6d5bd6c9b7e8aafc01ec577e7be53242e18e06/standards/img/spiffe_federation_lifecycle.png)

## 7. Security Considerations
This section contains security-related information and observations related to this specification. It is important that implementers and users alike be familiar with this information.

### 7.1. Distribution of Endpoint Parameters
The configuration parameters for a federation relationship including trust domain name, endpoint URL, and profile are themselves highly sensitive to tampering. Compromise of the configuration of a federation relationship can weaken or completely break security guarantees implied by an uncompromised SPIFFE implementation.

Some examples:
* tampering with the trust domain name allows the party that controls the corresponding bundle endpoint to impersonate arbitrary trust domains
* tampering with the endpoint URL, especially when used in conjunction with the `https_web` profile allows an attacker to issue fraudulent keys and impersonate any identity in the corresponding trust domain
* tampering with the endpoint profile can alter the security guarantees of the federation, for example substituting `https_spiffe` with `https_web`. If your threat model includes compromise of Web PKI (please additionally see the [Network Traffic Interception](#752-network-traffic-interception) section below), this could be considered a significant downgrade in security posture

Therefore, control plane administrators must take care to source these parameters securely and input them securely. Bundle endpoint configurations can be sourced using a wide variety of methods, including, but not limited to, email, an HTTPS-protected website, a company-internal wiki, etc. Regardless of the specific method used for initial distribution of the endpoint configuration, the distribution method needs to be resistant to in-flight tampering, unauthorized modification at-rest, and malicious impersonation. For example, email is generally not resilient to tampering nor to impersonation (i.e. "spoofed" email).

### 7.2. Explicitly-defined Endpoint Parameters
Each SPIFFE Federation relationship is configured with the following parameters at minimum:
* Trust domain name
* Endpoint URL
* Endpoint Profile

It is important that these three parameters are configured explicitly, the values cannot be securely inferred from each other.

For example, one might be tempted to infer the SPIFFE trust domain name from the host portion of the Endpoint URL. This is dangerous because it could allow anyone who can get a file served from a particular DNS name to assert trust roots for the SPIFFE trust domain of the same name.

Imagine a web hosting company called MyPage (`mypage.example.com`), that allows a customer, Alice, to serve web content at URLs like `https://mypage.example.com/alice/<filename>`, and further, that MyPage operates an API secured by SPIFFE Federation with the SPIFFE trust domain name `mypage.example.com`.  Imagine Alice sets up SPIFFE Federation with Bob, who is also a customer of MyPage, and Alice chooses to serve her trust bundle from `https://mypage.example.com/alice/spiffe-bundle`.

![A diagram illustrating the relationships between Alice, Bob, and MyPage](https://raw.githubusercontent.com/evan2645/spiffe/83985c0e18cad3b3b866e97341b8664b95bb0621/standards/img/spiffe_federation_mypage_example.png)  
*Figure 5: A diagram illustrating the relationships between Alice, Bob, and MyPage.*

If Bob’s control plane implicitly gets the trust domain name from the URL, this would then allow Alice to impersonate the trust domain `mypage.example.com`! It is also worth emphasizing that a SPIFFE trust domain name need not be a registered DNS name, which often makes this assumption incorrect to begin with. In this example, Alice's trust domain name is simply `alice`.

Endpoint Profile cannot be safely inferred from the URL either.  Both `https_web` and `https_spiffe` use normal HTTPS URLs with the same requirements. There is no secure method to distinguish them.  It is also insufficient to attempt `https_web` and fall back to `https_spiffe`, or vice versa, for similar reasons as outlined above: the ability to host a file with Web PKI at a particular HTTPS endpoint is not equivalent from a security perspective to the ability to host it with a valid SPIFFE SVID.

### 7.3. Preserving the `<Trust Domain, Bundle>` Binding
When authenticating an SVID, the verifier must use only the bundle for the trust domain the SPIFFE ID resides in. If we simply pooled all the bundles and accepted an SVID as long as it validates against some bundle, then trust domains could easily impersonate each other’s identities.  Another way to say this is that bundles are scoped to a particular trust domain.

Since bundles are not self-describing in terms of trust domain and are also self-issued, it is critical that the binding between trust domain name and bundle endpoint, configured as part of a SPIFFE Federation relationship, is then translated to a binding between trust domain name and bundle when bundles are stored and disseminated. This requirement is unlike traditional Web PKI where a single root certificate store is used to validate all certificates, regardless of which CA system actually issued the certificate being validated.

### 7.4. Trustworthiness of the Bundle Endpoint Server
The trustworthiness and integrity of a bundle endpoint server is essential in ensuring the security of the trust domain that the bundle represents. This includes not just the bundle endpoint server itself, but also the platform on which it runs, as well as any entity with administrative control over it or its platform.

While this fact may appear self evident, there are situations in which it may be less obvious. For example, in the case of a non-self-serving bundle endpoint wherein trust domain A serves a bundle for trust domain B, trust domain B is implicitly trusting trust domain A and its administrators to serve the correct bundle contents. Similarly, if serving a bundle from a hosting platform such as AWS S3, operators of the trust domain that the bundle in question represents are implicitly trusting AWS to serve the correct bundle contents.

When choosing a location from which a SPIFFE bundle will be served, it is important to consider the trustworthiness of the parties involved.

### 7.5. Authenticity of the Bundle Endpoint
Ensuring the authenticity of the bundle endpoint is of paramount importance. This cannot be stated strongly enough. This section explores a number of considerations that should be made in ensuring the authenticity of bundle endpoints.

#### 7.5.1. Bundle Endpoint URL Redirection
URL redirection comes in two variants: temporary and permanent. This specification recommends (via SHOULD directives) that servers only send temporary redirects and that clients treat all redirects as temporary, even if marked as permanent by servers.

A permanent redirect, if honored by clients, represents an in-band, automated rewrite of the bundle endpoint URL configuration parameter. This leads to two related security hazards.

Firstly, a trust domain operator might be tempted to use a permanent redirect as a method to migrate the bundle endpoint URL. However, there is no reliable means to ensure that all clients have processed the redirect and no means to ensure they will permanently honor it (e.g. through restarts, upgrades, redeployments, etc.). If a bundle endpoint URL transfers ownership and clients continue to fetch bundles from the original endpoint URL, those clients could retrieve a bundle controlled by an unexpected owner. This is of particular concern when using schemes based on Web PKI such as `https_web`, since the new domain owner is rightfully entitled to publicly trusted certificates against it.  Thus the safest course of action is to choose a Bundle Endpoint URL with long term stability in mind.  If a URL migration is absolutely required it is best handled using the out-of-band method used to obtain the bundle endpoint configuration in the first place, with a long, well publicized migration window.

Secondly, it is possible for permanent redirects to be abused as a mechanism to upgrade a transient compromise to a more permanent one.  Since the redirect is automatic, it can easily go unnoticed by bundle endpoint client operators.

Temporary redirects are often used by web hosts for operational purposes: for example to allow a globally stable URL to be served by a node located close to the recipient.  Banning the use of redirects for SPIFFE Federation would remove a useful tool from operators’ toolkit. However, temporary redirects do have security considerations. Not all web hosts are equivalent in terms of their security posture, meaning that operators might not be getting the security guarantees they are expecting if redirects occur. The advice in this specification that clients “SHOULD” follow redirects is to be interpreted as a recommended default: a balance between the operational value and security value.  Bundle endpoint client operators that do some due diligence investigating the security postures of bundle endpoints they rely on for federation may wish to consider disabling redirects so there are no surprises.

#### 7.5.2. Network Traffic Interception
While all SPIFFE bundle endpoint profiles leverage protocols which are largely impervious to the risks posed by the interception and manipulation of network traffic, it is important to note that this does not necessarily mean that the schemes by which the protocol's credentials are obtained are also impervious. If SPIFFE is being deployed as part of a "zero trust" solution, or if the operator's threat model otherwise includes network compromise, then special attention must be paid to the mechanisms used to issue bundle endpoint server credentials.

A common method of server credential issuance is through the use of challenge-response mechanisms, wherein requests for credentials are authorized based on the requestors ability to answer a challenge sent to a particular network address or DNS name. The ACME protocol is one example of this, and thought should be given to compensating controls if the use of public certificate authorities is desired. Of particular note is the security of the layer two network that a bundle endpoint server resides in.

Finally, it should be stated that ACME and the public certificate authority infrastructure has historically been stable and sound. The concern described in this section is decades-old, however it is prudent to highlight the behavior as operators adopting SPIFFE as a way to mitigate trust in the network or in DNS may find it surprising.

#### 7.5.3. Endpoint Parameters
One way to subvert a bundle endpoint is to tamper with the endpoint parameters, either in flight or at rest, as consumed by the endpoint’s clients. Modifying otherwise authentic endpoint parameters can lead to a downgraded security posture, or even lead clients to communicate with a different endpoint entirely. Please see the [Distribution of Endpoint Parameters](#71-distribution-of-endpoint-parameters) section for more information.

### 7.6. Chaining Trust with `https_spiffe`
When using SPIFFE Authentication, the authenticity of the trust bundle server is established by validating the presented X509-SVID using a trust bundle clients might obtain through various means.  For example, the bundle for trust domain A might be served by an endpoint in trust domain B, and the bundle for trust domain B might be served by an endpoint in trust domain C, and so on. 

In this way, the fetched bundle is trusted via a chain of relationships between the serving trust domain and the trust domain the bundle is for.  The chain of relationships eventually terminates in one of the following:
* via a federation relationship to a self-serving trust domain 
* via a federation relationship to a bundle endpoint served by Web PKI
* in a long-lived, statically configured trust bundle
* in some process outside the scope of this document

As described in the [Trustworthiness of the Bundle Endpoint Server](#74-trustworthiness-of-the-bundle-endpoint-server) section, it is important to understand that the security of this scheme depends on each trust domain in the chain succeeding in living up to its security guarantees. The compromise of a trust domain or bundle endpoint server in the chain would result in the compromise of the "next" trust domain. It may be possible for a sufficiently-powerful attacker with network interception capabilities to escalate this attack in such a way that trust domains further down the chain may be compromised. As such, forming long chains in this way is generally discouraged. If required, administrators should take the time to analyze these chains to ensure that all participating trust domains meet their desired criteria.

Finally, it should be noted that the "links" in this chain are formed by individual HTTPS request operations (against the various bundle endpoint servers in the chain), and these operations are likely occurring at different times. SPIFFE bundle endpoint clients should be logging these HTTPS request operations, and administrators should take care to preserve these logs for future forensic analysis if necessary.

[1]: https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE-ID.md#21-trust-domain
[2]: https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE_Trust_Domain_and_Bundle.md#3-spiffe-bundles
[3]: https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE_Trust_Domain_and_Bundle.md
[4]: https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE_Trust_Domain_and_Bundle.md#appendix-a-spiffe-bundle-example
[5]: https://wiki.mozilla.org/Security/Server_Side_TLS#Intermediate_compatibility_.28recommended.29
[6]: https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE_Trust_Domain_and_Bundle.md#4-spiffe-bundle-format
[7]: https://tools.ietf.org/html/rfc3986#section-3
[8]: https://tools.ietf.org/html/rfc7231#section-6.4
[9]: https://github.com/spiffe/spiffe/blob/master/standards/X509-SVID.md#5-validation
[10]: https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE_Workload_API.md
[11]: https://tools.ietf.org/html/rfc6125
[12]: https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE_Trust_Domain_and_Bundle.md#4-spiffe-bundle-format
