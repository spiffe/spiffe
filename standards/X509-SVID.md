# The X.509 SPIFFE Verifiable Identity Document

## Status of this Memo
This document specifies an experimental identity document standard for the internet community, and requests discussion and suggestions for improvements. It is a work in progress. Distribution of this document is unlimited.

## Abstract
The SPIFFE standard provides a specification for a framework capable of bootstrapping and issuing identity to services across heterogeneous environments and organizational boundaries. It defines an identity document known as the SPIFFE Verifiable Identity Document (SVID).

An SVID on its own does not represent a new document type. Rather, we set forth a specification which defines how SVID information may be encoded into existing document types.

This document defines a standard in which an X.509 certificate is used as an SVID. Basic understanding of X.509 is assumed. Please reference [RFC 5280][1] for information specific to X.509.

## Table of Contents
1\. [Introduction](#1.-introduction)  
2\. [SPIFFE ID](#2.-spiffe-id)  
3\. [Hierarchy](#3.-hierarchy)  
3.1. [Leaf Certificates](#3.1.-leaf-certificates)  
3.2. [Signing Certificates](#3.2.-signing-certificates)  
4\. [Constraints and Usage](#4.-constraints-and-usage)  
4.1. [Basic Constraints](#4.1.-basic-constraints)  
4.2. [Name Constraints](#4.2.-name-constraints)  
4.3. [Key Usage](#4.3.-key-usage)  
4.4. [Extended Key Usage](#4.4.-extended-key-usage)  
5\. [Validation](#5.-validation)  
5.1. [Path Validation](#5.1.-path-validation)  
5.2. [Leaf Validation](#5.2.-leaf-validation)  
6\. [Conclusion](#6.-conclusion)  
Appendix A. [X.509 Field Reference](#appendix-a.-x.509-field-reference)  

## 1. Introduction
Perhaps the most important function of SPIFFE is to secure process to process communication. The core standard allows for authentication, however leveraging cryptographic identity to build a secure communication channel is also highly desirable. With TLS being widely adopted, and implemented using X.509-based authentication, the use of X.509 as a SPIFFE SVID is clearly advantageous.

This specification addresses the encoding of SVID information into an X.509 certificate, the constraints which must be set, as well as how to validate X.509 SVIDs.

## 2. SPIFFE ID
In an X.509 SVID, the corresponding SPIFFE ID is set as a URI type in the Subject Alternative Name extension (SAN extension, see [RFC 5280 section 4.2.16][2]). An X.509 SVID MUST NOT contain more than one URI SAN. It MAY contain any number of other SAN fields, including DNS SANs.

## 3. Hierarchy
This section discusses the relationship between leaf, root, and intermediate certificates, as well as the requirements placed upon each.

### 3.1. Leaf Certificates
A leaf certificate is an SVID which serves to identify a caller or resource. They are signed by the signing authority of the trust domain in which they reside, and are suitable for use in authentication processes. A leaf certificate (as opposed to a signing certificate, [section 3.2](#3.2.-signing-certificates)) is the only type which may serve to identify a resource or caller.

Leaf certificate SPIFFE IDs MUST have a non-root path component. See [section 4.1](#4.1.-basic-constraints) for information on X.509-specific properties which distinguish a leaf certificate from a signing certificate.

### 3.2. Signing Certificates
An X.509 SVID signing certificate is one which has set `keyCertSign` in the key usage extension. It additionally has the `CA` flag set to `true` in the basic constraints extension (see [section 4.1](#4.1.-basic-constraints)). That is to say, it is a CA certificate.

A signing certificate is itself an SVID. The SPIFFE ID of a signing certificate MUST NOT have a path component, and MUST reside in the trust domain of any leaf SVIDs it issues. A signing certificate MAY be used to issue further signing certificates in the same or different trust domains.

Signing certificates MUST NOT be used for authentication purposes. They serve as validation material only, and may be chained together in typical X.509 fashion, as described in [RFC 5280][1]. Please see [section 4.3](#4.3.-key-usage) and [section 4.4](#4.4-extended-key-usage) for further information regarding X.509-specific restrictions on signing certificates.

## 4. Constraints and Usage
Leaf and signing certificates carry different X.509 properties - some for security purposes, and some to support their specialized functions. This section describes the constraints and key usage configuration for X.509 SVIDs of both types.

### 4.1. Basic Constraints
The basic constraints X.509 extension identifies whether the certificate is a signing certificate, as well as the maximum depth of valid certification paths that include this certificate. It is defined in [RFC 5280, section 4.2.1.9][3].

Valid X.509 SVIDs (both leaf and signing certificates) MUST NOT set the `pathLenConstraint` field. Signing certificates MUST set the `CA` field to `true`, and leaf certificates MUST set the `CA` field to `false`.

### 4.2. Name Constraints
Name constraints indicate a namespace within which all SPIFFE IDs in subsequent certificates in a certification path MUST be located. They are used to limit the blast radius of a compromised signing certificate to the named trust domain(s), and are defined in [RFC 5280, section 4.2.1.10][4]. This section applies to signing certificates only.

Name constraints are typed in the same way that Subject Alternative Names are. Since the only name an SVID is concerned about is the SPIFFE ID, and the SPIFFE ID is defined as SAN type URI, we will define the semantics of URI typed name constraints only.

There is a distinct lack of support for URI type name constraints in the wild. Libraries which don’t support them will reject such certificates, preventing path validation from occurring successfully. While name constraints are an X.509 feature that SPIFFE wishes to use, the authors recognize that the lack of widespread support may inflict significant implementation and/or deployment pain. Therefore, X.509 SVID signing certificates MAY apply URI name constraints as the implementor sees fit, though caution is urged in this area. The SPIFFE community is working to enable support for URI name constraints across a variety of platforms, and it should be expected that the requirements defined in this section will become more stringent in future versions as wider support is achieved.

### 4.3. Key Usage
The key usage extension defines the purpose of the key contained in the certificate. The usage restriction might be employed when a key that could be used for more than one operation is to be restricted. The key usage extension is defined in [RFC 5280, section 4.2.1.3][5].

The key usage extension MUST be set on all SVIDs, and MUST be marked critical.

SVID signing certificates MUST set `keyCertSign` and `cRLSign`. They MUST NOT set `keyEncipherment` or `keyAgreement`. This helps ensure that they cannot be used for authentication purposes.

Leaf SVIDs MUST set `keyEncipherment`, `keyAgreement`, and `digitalSignature`. They MUST NOT set `keyCertSign` or `cRLSign`.

### 4.4. Extended Key Usage
This extension indicates one or more purposes for which the key contained in the certificate may be used, in addition to or in place of the basic purposes indicated in the key usage extension. It is defined in [RFC 5280, section 4.2.1.2][6].

The extended key usage extension applies to leaf certificates only. Leaf SVIDs SHOULD include this extension, and it MAY be marked as critical. When included, fields `id-kp-serverAuth` and `id-kp-clientAuth` MUST be set, and all other fields MUST NOT be set.

Signing certificates MUST NOT include an Extended Key Usage extension.

## 5. Validation
This section describes how an X.509 SVID is validated. The procedure uses standard X.509 validation, in addition to a small set of SPIFFE-specific validation steps.

### 5.1. Path Validation
The validation of trust in a given SVID is based on standard X.509 path validation, and MUST follow [RFC 5280][1] path validation semantics.

In order to perform path validation, it is necessary to possess the public portion of at least one signing certificate. The set of signing certificates required for validation is known as the CA bundle. The mechanism through which an entity can retrieve the relevant CA bundle(s) is out of scope for this document, and is instead defined in the SPIFFE Workload API specification.

### 5.2. Leaf Validation
When authenticating a resource or caller, it is necessary to perform validation beyond what is covered by the X.509 standard. Namely, we must ensure that 1) the certificate is a leaf certificate, and 2) the signing authority was authorized to issue it, and 3) all signatures use secure algorithms.

When validating an X.509 SVID for authentication purposes, the validator MUST ensure that the `CA` field in the basic constraints extension is set to `false`, and that `keyCertSign` and `cRLSign` are not set in the key usage extension. The validator must also ensure that the scheme of the SPIFFE ID is set to `spiffe://`.

It is the responsibility of the validator to ensure that the certificate used to sign the leaf is in fact an authority for the trust domain that the leaf resides in. Specifically, the SPIFFE ID of the signing certificate MUST be equal to the leaf certificate’s SPIFFE trust domain. In the context of X.509, the leaf’s signing certificate is the one with a Subject Key Identifier (SKID) equal to the Authority Key Identifier (AKID) set on the leaf certificate. This validation step is only performed between the leaf and its immediate signing certificate. That is to say, it does not proceeed all the way up the trust chain.

Validation of the signing authority in this manner is necessary due to lack of widespread support for X.509 URI name constraints (see [section 4.2](#4.2.-name-constraints)). As support for URI name constraints becomes more widespread, future versions this document may update the requirements set forth in this section in order to better leverage name constraint validation.

When verifying signatures (e.g. when verifying the signature of a certificate using its issuer's public key, and when verifying a signature in a TLS handshake using the leaf certificate's public key) the validator MUST ensure that the signature uses a secure signature algorithm. In particular, all signatures MUST use one of the following signature algorithms:

* ECDSA using the P-256 curve and using SHA-256 as the digest algorithm.
* ECDSA using the P-384 curve and using SHA-384 as the digest algorithm.
* RSA using PSS (not PKCS#1), with an RSA public key having a modulus of at least 2047 bits and at most 8192 bits, and an odd public exponent of at least 65537, and using one of SHA-256, SHA-384, or SHA-512 as the digest algorithm.
* Ed25519 (using SHA-512) as specified in https://tools.ietf.org/html/draft-ietf-curdle-pkix-05.

In particular, validators MUST NOT accept signatures with weak keys (e.g. RSA keys smaller than 2047 bits or a public exponent of 3) and validators MUST NOT accept signatures using weak digest algorithms (e.g. MD5 or SHA-1).

## 6. Conclusion
This document set forth conventions and standards for the issuance and validation of X.509-based SPIFFE Verifiable Identity Documents. It forms the basis for real world SPIFFE service authentication and SVID validation. By conforming to the X.509 SVID standard, it is possible to build an identity and authentication system which is interoperable and platform agnostic.

## Appendix A. X.509 Field Reference
Extension | Field | Description
----------|-------|------------
Subject Alternate Name | uniformResourceIdentifier | This field is set equal to the SPIFFE ID. Only one instance of this field is permitted.
Basic Constraints | CA | This field must be set to `true` if and only if the SVID is a signing certificate.
Basic Constraints | pathLenConstraint | This field must not be set.
Name Constraints | permittedSubtrees | This field may be set if the implementor wishes to use URI name constraints. It will be required in a future version of this document.
Key Usage | keyCertSign | This field must be set if and only if the SVID is a signing certificate.
Key Usage | cRLSign | This field must be set if and only if the SVID is a signing certificate.
Key Usage | keyAgreement | This field must be set if and only if the SVID is a leaf certificate.
Key Usage | keyEncipherment | This field must be set if and only if the SVID is a leaf certificate.
Key Usage | digitalSignature | This field must be set if and only if the SVID is a leaf certificate.
Extended Key Usage | id-kp-serverAuth | This field may be set if and only if the SVID is a leaf certificate.
Extended Key Usage | id-kp-clientAuth | This field may be set if and only if the SVID is a leaf certificate.

[1]: https://tools.ietf.org/html/rfc5280
[2]: https://tools.ietf.org/html/rfc5280#section-4.2.1.6
[3]: https://tools.ietf.org/html/rfc5280#section-4.2.1.9
[4]: https://tools.ietf.org/html/rfc5280#section-4.2.1.10
[5]: https://tools.ietf.org/html/rfc5280#section-4.2.1.3
[6]: https://tools.ietf.org/html/rfc5280#section-4.2.1.2
