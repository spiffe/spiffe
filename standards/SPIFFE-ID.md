# The SPIFFE Identity and Verifiable Identity Document

## Status of this Memo
This document specifies an identity and identity issuance standard for the internet community, and requests discussion and suggestions for improvements. Distribution of this document is unlimited.

## Abstract
The SPIFFE standard provides a specification for a framework capable of bootstrapping and issuing identity to services across heterogeneous environments and organizational boundaries. It encompasses a variety of specifications, each defining the operation of a specific subset of the SPIFFE functionality.

This document, in particular, serves as the core specification for the SPIFFE standard. While there are other specifications falling under the SPIFFE umbrella, conformance with this document is sufficient for achieving SPIFFE compliance, and gaining the interoperability benefit of the SPIFFE standard itself.

For more general information about SPIFFE, please see the [Secure Production Identity Framework for Everyone (SPIFFE)](SPIFFE.md) standard.

## Table of Contents

1\. [Introduction](#1-introduction)  
2\. [SPIFFE Identity](#2-spiffe-identity)  
2.1. [Trust Domain](#21-trust-domain)  
2.1.1. [Trust Domain Name Collisions](#211-trust-domain-name-collisions)  
2.2. [Path](#22-path)  
2.3. [Maximum SPIFFE ID Length](#23-maximum-spiffe-id-length)  
3\. [SPIFFE Verifiable Identity Document](#3-spiffe-verifiable-identity-document)  
3.1. [SVID Trust](#31-svid-trust)  
3.2. [SVID Components](#32-svid-components)  
3.3. [SVID Format](#33-svid-format)  
4\. [Security Considerations](#4-security-considerations)  
4.1. [SVID Assertions](#41-svid-assertions)  
4.1.1. [Temporal Accuracy](#411-temporal-accuracy)  
4.1.2. [Scope and Influence](#412-scope-and-influence)  
4.1.3. [Interpretation](#413-interpretation)  
4.1.4. [Veracity](#414-veracity)  


## 1. Introduction
This document sets forth the official SPIFFE specification. It defines the two most fundamental components of the SPIFFE standard: the SPIFFE Identity and the SPIFFE Verifiable Identity document.

Section 2 outlines the SPIFFE Identity (SPIFFE ID) and its namespace. The SPIFFE ID is a structured string used to identify a resource or caller, and is the cornerstone of the SPIFFE standard. All other SPIFFE components focus on the issuance and verification of the SPIFFE IDs themselves.

Section 3 describes the SPIFFE Verifiable Identity Document (or SVID). An SVID is a mechanism through which a compute endpoint can present its SPIFFE ID in a way that can be cryptographically verified and deemed trustworthy. SVIDs, which may reference an associated asymmetric key pair, can additionally be used to form a secure communication channel.

Conformance with this document is sufficient for the purposes of SPIFFE compliance.

## 2. SPIFFE Identity
In order to communicate an identity, we must first define an identity namespace. A SPIFFE Identity (or SPIFFE ID) is defined as an [RFC 3986](https://tools.ietf.org/html/rfc3986) compliant URI comprising a “trust domain name” and an associated path. The trust domain name stands as the authority component of the URI, and serves to identify the system in which a given identity is issued. The following example demonstrates how a SPIFFE ID is constructed:

```spiffe://trust-domain-name/path```

Valid SPIFFE IDs MUST have the scheme set to `spiffe`, include a non-zero trust domain name, and MUST NOT include a query or fragment component. In other words, a SPIFFE ID is defined in its entirety by the `spiffe` scheme and a site-specific `hier-part` which includes an authority component and an optional path.

### 2.1. Trust Domain
The trust domain corresponds to the trust root of a system. A trust domain could represent an individual, organization, environment or department running their own independent SPIFFE infrastructure.

Trust domain names are nominally self-registered, unlike public DNS there is no delegating authority that acts to assert and register a base domain name to an actual legal real-world entity, or assert that legal entity has fair and due rights to any particular trust domain name.

The trust domain name is defined as the authority component of the URI with the following restrictions applied:
* The `host` part of the authority MUST NOT be empty.
* The `userinfo` and `port` parts of the authority component MUST be empty.
* The `host` part of the authority MUST be lowercase.
* The `host` part of the authority MUST contain only letters, numbers, dots, dashes, and underscores ([a-z0-9.-_]).
* The `host` part of the authority MUST NOT contain percent-encoded characters.

Please note that this definition does not exclude IPv4 addresses in dotted-quad notation, but does exclude IPv6 addresses. DNS names are a strict subset of valid trust domain names. Implementations MUST NOT process trust domain names differently whether or not they are valid IP addresses and/or valid DNS names.

#### 2.1.1. Trust Domain Name Collisions

Trust domain operators are free to choose any trust domain name they find suitable: there is no centralized authority for regulation or registration of trust domain names. Thus, there is no guarantee of global uniqueness nor is there any technical means for preventing distinct trust domains from using identical trust domain names.

To prevent accidental collisions (two trust domains select identical names), operators are advised to select trust domain names which are highly likely to be globally unique. Even though a trust domain name is not a DNS name, using a registered domain name as a suffix of a trust domain name, when available, will reduce chances of an accidental collision; for example, if a trust domain operator owns the domain name `example.com`, then using a trust domain name such as `trust_domain_name.example.com` would likely not produce a collision. When trust domain names are automatically generated without operator input, randomly generating a unique name (such as a UUID) is strongly advised.

When a collision does occur, those trust domains will continue to operate independently but will be unable to federate (connect to one another).  Because each trust domain uses unique cryptographic roots of trust, identity claims issued by one trust domain will fail validation in the other. Further details of SPIFFE authentication are covered in [Section 3.1](#31-svid-trust).


### 2.2. Path
The path component of a SPIFFE ID allows for the unique identification of a given workload. The meaning behind the path is left open-ended and is the responsibility of the administrator to define.

Valid SPIFFE ID path components adhere to the following rules:
* The path component MUST NOT include percent-encoded characters.
* The path component MUST NOT include segments that are empty or are relative path modifiers (i.e. `.`, `..`)
* The path component MUST NOT include a trailing `/`.
* Individual path segments MUST contain only letters, numbers, dots, dashes, and underscores ([a-zA-Z0-9.-_]).

Paths MAY be hierarchical - similar to filesystem paths. The specific meaning of paths is reserved as an exercise to the implementer and are outside the SVID specification. Some examples and conventions are expressed below.

* Identifying services directly

  Often it is valuable to identify services directly. For example, an administrator may decree that any process running on a particular set of nodes should be able to present itself as a particular identity. For example:

  ```spiffe://staging.example.com/payments/mysql```
  or
  ```spiffe://staging.example.com/payments/web-fe```

  The two SPIFFE IDs above refer to two different components - the mysql database service and a web front-end - of a payments service running in a staging environment. The meaning of ‘staging’ as an environment, ‘payments’ as a high level service collection is defined by the implementer.

* Identifying service owners

  Often higher level orchestrators and platforms may have their own identity concepts built in (such as Kubernetes service accounts, or AWS/GCP service accounts) and it is helpful to be able to directly map SPIFFE identities to those identities. For example:

  ```spiffe://k8s-west.example.com/ns/staging/sa/default```

  In this example, the administrator of example.com is running a Kubernetes cluster k8s-west.example.com, which has a ‘staging’ namespace, and within this a service account (sa) called ‘default’. These are conventions defined by the SPIFFE administrator, not assertions guaranteed by this specification.


* Opaque SPIFFE identity

  The above examples are illustrative and, in the most general case, the SPIFFE path may be left opaque, carrying no visible hierarchical information. Metadata, such as geographic location, logical system partitioning and/or service name, may be provided by a secondary system, where identities and their attributes are registered. That can be queried to retrieve any metadata associated with the SPIFFE identifier. For example:

  ```spiffe://example.com/9eebccd2-12bf-40a6-b262-65fe0487d453```

### 2.3. Maximum SPIFFE ID Length

URIs, as defined by [RFC 3986](https://tools.ietf.org/html/rfc3986), do not have a maximal length. As an interoperability consideration, SPIFFE implementations MUST support SPIFFE URIs up to 2048 bytes in length and SHOULD NOT generate URIs of length greater than 2048 bytes. [RFC 3986](https://tools.ietf.org/html/rfc3986) permits only ASCII characters, thus the recommended maximum length of a SPIFFE ID is 2048 bytes.

All URI components contribute to the URI length, including the "spiffe" scheme, "://" separator, trust domain name, and path component. Non-ASCII characters contribute to the URI length after they are percent encoded as ASCII characters. Note that [RFC 3986](https://tools.ietf.org/html/rfc3986) defines a maximum length of 255 characters for the "host" component of a URI; therefore a maximum length of a trust domain name is 255 bytes.

### 2.4. SPIFFE ID Parsing

SPIFFE IDs follow the URI specification as defined by [RFC 3986](https://tools.ietf.org/html/rfc3986). The scheme and trust domain name of the SPIFFE ID are case-insensitive. The path is case-sensitive.

## 3. SPIFFE Verifiable Identity Document
A SPIFFE Verifiable Identity Document (SVID) is the mechanism through which a workload communicates its identity to a resource or caller. An SVID is considered valid if it has been signed by an authority within the SPIFFE ID's trust domain.

### 3.1. SVID Trust
As covered in Section 2.1, SPIFFE trust is rooted in a given ID's trust domain. A signing authority MUST exist in each trust domain, and this signing authority MUST carry an SVID of its own. The SPIFFE ID of the signing authority SHOULD reside in the trust domain in which it is authoritative, and SHOULD NOT have a path component. The SVID of the signing authority then forms the basis of trust for a given trust domain.

Chaining of trust, if desired, can be achieved by signing the authority’s SVID with the private key of a foreign trust domain’s authority. In the event that trust is not being chained, then the authority’s SVID is self-signed.

### 3.2. SVID Components
An SVID is a fairly simple construct, and comprises three basic components:

* A SPIFFE ID
* A valid signature
* An optional public key

The SPIFFE ID and the public key (if present) MUST be included in a portion of the payload which is signed. If a public key is included, then the corresponding private key is retained by the entity to which the SVID has been issued, and is used to prove ownership of the SVID itself.

Individual SVID specifications MAY require or otherwise allow information to be included in an SVID beyond what is described here. The nature of the included information may or may not be strictly defined by the relevant SPIFFE specification - for example, the JWT-SVID specification allows users to include arbitrary information inside the SVID itself. In cases where this additional information is not explicitly specified by the relevant SVID specification, operators should exercise caution when using this information as input to a security decision, particularly if the SVID being validated belongs to a different trust domain. Please see the security considerations section for more information.

### 3.3. SVID Format
An SVID is not itself a document type. Many document formats exist already which fulfil the needs of a SPIFFE SVID, and we do not wish to re-invent those formats. Instead, we define a set of format-specific specifications which standardize the encoding of SVID information.

In order for an SVID to be considered valid, it MUST leverage a document type for which a corresponding specification has been defined. At the time of this writing, the only supported document types are X.509 and JWT. Note that format-specific SVID specifications may upgrade the requirements set forth in this document.

Please see the [X.509 SPIFFE Verifiable Identity Document](X509-SVID.md) or the [JWT SPIFFE Verifiable Identity Document](JWT-SVID.md) specification for more information.

## 4. Security Considerations
This section includes security considerations that implementers and users should take into account when using SPIFFE IDs and SVIDs.

### 4.1. SVID Assertions
SVIDs always carry within them a set of data - at the minimum, a SPIFFE ID. Sometimes, this data represents assertions made by the trust domain authority about the SVID's subject. When interpreting meaning from this data, care must be taken to ensure that all parties involved well understand the meaning and significance of the utilized information.

There are four major concerns when considering the relative safety of any given assertion. First is the temporal accuracy - SVIDs are good for some time before they expire, is the assertion in the SVID true over the entirety of the SVID lifetime? Second, there is the scope and influence of the assertion - under what context was the assertion originally made, and how far reaching should its influence be? Third is the issue of interpretation and meaning - does the assertion have the same meaning to the authority and consumer, or is there room for divergent interpretation? And finally, the veracity of the assertion itself may be called into question in some cases.

This section explores all four areas of concern, and provides guidelines by which operators may assess the relative safety of any given SVID assertion. Generally speaking, operators should err on the side of caution and only include assertions in which there is a very high degree of confidence in the safety of the assertion in question.

It should be noted that while assertions which are directly formalized by the SPIFFE specifications are not typically vulnerable to problems related to interpretation and meaning, they can still be vulnerable to problems related to veracity. However, due to the tightly scoped nature of SPIFFE defined assertions, veracity concerns in this regard indicate much larger concerns around the security posture of the trust domain in question, at which point operators should seriously question whether or not data should be exchanged with these systems in the first place.

#### 4.1.1. Temporal Accuracy
SVIDs are valid for a limited period of time, primarily for the purpose of mitigating the likelihood of a key compromise and the damage associated with it. While it is generally the case that assertions in SVIDs are true at the time of issuance, it does not necessarily mean that they are true at the time of use.

Certain kinds of assertions are more vulnerable to this problem than others. The name of a service owner, role or group membership, and access policies are all examples of assertions that are more likely to change between the time of SVID issuance and the time of validation or use. In contrast, natural properties of the workload and its runtime (e.g. the SPIFFE ID, or the region that the workload is running in) are generally bound to the lifetime of the workload and therefore unlikely to change, meaning they are less susceptible to problems with temporal accuracy.

When deciding whether or not a certain assertion should be included in an SVID, it is important to consider this point. Assertions made in an SVID will be considered valid for the lifetime of the SVID, and effecting a change to this assertion (or revoking it) on a live system will be protracted as all SVIDs with the old assertion must first expire. If the volatility of the assertion in question is not clear, operators should err on the side of caution and exclude it from the SVID.

#### 4.1.2. Scope and Influence
SVIDs are signed by an authority in the trust domain in which they reside. It is the responsibility of the signing authority to validate all information in the SVIDs it signs, and assertions included in an SVID are in fact assertions made by the signing authority.

The influence of this authority, and the scope of the assertions it makes, are naturally limited. The authority of one trust domain should not be making assertions about entities in other trust domains (i.e. the scope of its assertions are limited to entities under its control). Similarly, when consuming SVID data, the consumer should consider all assertions contained within it to be qualified by the trust domain that the SVID resides in.

Example: if trust domains A and B both use an attribute named “role”, then an entity with role “admin” in trust domain A is not assumed to be an “admin” in the context of trust domain B.

#### 4.1.3. Interpretation
For flexibility, most SVID specifications allow for the inclusion of arbitrary information, the behavior of which is undefined by SPIFFE or any of its underlying specifications. When included, different parties may interpret the semantics of this information differently. For this reason, the inclusion and consideration of arbitrary information in SVIDs is difficult to do safely, however it is possible with scrutiny and attention.

When arbitrary SVID information is consumed as part of a security decision (such as whether to allow a request or connection), it is critical that the authority issuing the SVID has the same meaning or interpretation of the information as the entity consuming the SVID.

It is a good idea to consider exactly who is operating the authority issuing the SVID. Through out-of-band coordination, trust domain operators may be able to agree on the meaning of a particular piece of information. For example, if an organization operates multiple trust domains for administrative reasons, it may be straightforward to agree on an interpretation of SVID information within that organization (even if the nature of the information is not publicly standardized). The operator should, however, limit processing of that data to only the trust domains with which the meaning has been agreed; agreements of meaning between two trust domain operators should not automatically extend to all trust domain operators.

Example: if trust domains A and B agree to the meaning of the "environment" attribute, that agreement of semantics does not extend to trust domain C which may also happen to include an attribute with the same name of "environment".

#### 4.1.4. Veracity
SVID consumers residing in the same trust domain as the SVID being consumed can generally assume that assertions in the SVID are true, as the consumer likely considers the authority that issued the SVID to be wholly trusted. It does not necessarily mean however, that assertions of similar form and nature can be assumed true when originating from a different trust domain.

Operators should carefully consider, on a case by case basis, whether or not a given foreign authority should be considered trustworthy in the context of a specific assertion.

For example, imagine that the operator of trust domain A and trust domain B have a shared customer and a business relationship. During normal operation in trust domain A, a specialized process authenticates the customer and the trust domain’s authority creates an SVID that embeds an assertion indicating the customer’s identity. The purpose of this process is to mitigate unauthorized access to customer data in the event that an intermediary service within the trust domain is compromised by proving that the customer was authenticated and did in fact make this request.

Now imagine that a request for the customer’s data is received by the storage service in trust domain A, except the caller presented an SVID from trust domain B. Even though the presented SVID may have the necessary assertion indicating that the shared customer was authenticated and authorized the request, it is a bad idea to blindly assume that trust domain B has indeed authenticated your customer. If trust domain B is compromised, or if it has a malicious internal actor, it could claim to have authenticated any user it wishes, thus creating the very circumstance that the measure was designed to mitigate in the first place.

