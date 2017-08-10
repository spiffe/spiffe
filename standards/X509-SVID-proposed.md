# The X.509 SPIFFE Verifiable Identity Document

## Status of this Memo
This document specifies an experimental identity document standard for the internet community, and requests discussion and suggestions for improvements. It is a work in progress. Distribution of this document is unlimited.

## Abstract
The SPIFFE standard provides a specification for a framework capable of bootstrapping and issuing identity to services across heterogeneous environments and organizational boundaries. It defines an identity document known as the SPIFFE Verifiable Identity Document (SVID).

An SVID on its own does not represent a new document type. Rather, we set forth a specification which defines how SVID information may be encoded into existing document types.

This document defines a standard in which an X.509 certificate is used as an SVID. Basic understanding of X.509 is assumed. Please reference RFC 5280 for information specific to X.509.

## Table of Contents
TODO

## 1. Introduction
Perhaps the most important function of SPIFFE is to secure process to process communication. The core standard allows for authentication, however leveraging cryptographic identity to build a secure communication channel is also highly desirable. With TLS being widely adopted, and implemented using X.509-based authentication, the use of X.509 as a SPIFFE SVID is clearly advantageous.

This specification addresses the encoding of SVID information into an X.509 certificate, the constraints which must be set, as well as how to validate X.509 SVIDs.

## 2. SPIFFE ID
In an X.509 SVID, the corresponding SPIFFE ID is set as a URI type in the Subject Alternative Name extension (SAN extension, see RFC 5280). An X.509 SVID MUST NOT contain more than one URI SAN.

## 3. Hierarchy
This section discusses the relationship between root, intermediate, and leaf certificates, as well as the requirements placed upon each.

### 3.1. Leaf Certificates
A leaf certificate is an SVID which serves to identify a caller or resource. They are signed by the signing authority of the trust domain in which they reside, and are suitable for use in authentication processes. A leaf certificate (as opposed to a signing certificate, section 3.2) is the only type considered to correspond to an actual SPIFFE service.

Leaf certificate SPIFFE IDs MUST have a non-root path component. See section 4.1 for information on X.509-specific properties which distinguish a leaf certificate from a signing certificate.

### 3.2. Signing Certificates
An X.509 SVID signing certificate is one which has set `keyCertSign` in the key usage extension. It additionally has the `CA` flag set to `true` in the basic constraints extension (see section 5.1). That is to say, it is a CA certificate.

A signing certificate is itself an SVID. The SPIFFE ID of a signing certificate MUST NOT have a path component, and MUST reside in the trust domain of any leaf SVIDs it issues. A signing certificate MAY be used to issue further signing certificates in the same or different trust domains.

Signing certificates MUST NOT be used for authentication purposes. They serve as validation material only, and may be chained together in typical X.509 fashion, as described in RFC 5280.

## 4. Constraints and Usage
Leaf and signing certificates carry different X.509 properties - some for security purposes, and some to support their specialized functions. This section describes the constraints and key usage configuration for X.509 SVIDs of both types.

### 4.1. Basic Constraints
The basic constraints X.509 extension identifies whether the certificate is a signing certificate, as well as the maximum depth of valid certification paths that include this certificate. It is defined in RFC 5280, section 4.2.1.9.

Valid X.509 SVIDs (both leaf and signing certificates) MUST NOT set the `pathLenConstraint` field. Signing certificates MUST set the `CA` field to `true`, and leaf certificates MUST set the `CA` field to `false`.

### 4.2. Name Constraints
Name constraints indicate a namespace within which all SPIFFE IDs in subsequent certificates in a certification path MUST be located. They are used to limit the blast radius of a compromised signing certificate, and are defined in RFC 5280, section 4.2.1.10. This section applies to signing certificates only.

Name constraints are typed in the same way that Subject Alternative Names are. Since the only name an SVID is concerned about is the SPIFFE ID, and the SPIFFE ID is defined as SAN type URI, we will define the semantics of URI typed name constraints only.

There is a distinct lack of support for URI type name constraints in the wild. Libraries which don’t support them will reject such certificates, preventing path validation from occurring successfully. While name constraints are an X.509 feature that SPIFFE wishes to use, the authors recognize that the lack of widespread support may inflict significant implementation and/or deployment pain. Therefore, X.509 SVID signing certificates MAY apply URI name constraints as the implementor sees fit, though caution is urged in this area. The SPIFFE community is working to enable support for URI name constraints across a variety of platforms, and it should be expected that the requirements defined in this section will become more stringent in future versions as wider support is achieved.

### 4.3. Key Usage
The key usage extension defines the purpose of the key contained in the certificate. The usage restriction might be employed when a key that could be used for more than one operation is to be restricted. The key usage extension is defined in RFC 5280, section 4.2.1.3.

The key usage extension MUST be set on all SVIDs, and MUST be marked critical.

SVID signing certificates MUST set `keyCertSign` and `cRLSign`. They MUST NOT set `keyEncipherment` or `keyAgreement`. This helps ensure that they cannot be used for authentication purposes.

Leaf SVIDs MUST set `keyEncipherment`, `keyAgreement`, and `digitalSignature`. They MUST NOT set `keyCertSign` or `cRLSign`.

### 4.4. Extended Key Usage
This extension indicates one or more purposes for which the key contained in the certificate may be used, in addition to or in place of the basic purposes indicated in the key usage extension. It is defined in RFC 5280, section 4.2.12.

The extended key usage extension applies to leaf certificates only. Leaf SVIDs SHOULD include this extension, and it MAY be marked as critical. When included, fields `id-kp-serverAuth` and `id-kp-clientAuth` MUST be set, and all other fields MUST NOT be set.

## 5. Validation
This section describes how an X.509 SVID is validated. The procedure uses standard X.509 validation, in addition to a small set of SPIFFE-specific validation steps.

### 5.1. Path Validation
The validation of trust in a given SVID is based on standard X.509 path validation, and MUST follow RFC 5280 path validation semantics.

In order to perform path validation, it is necessary to possess the public portion of at least one signing certificate. The set of signing certificates required for validation is known as the CA bundle. The mechanism through which an entity can retrieve the relevant CA bundle(s) is out of scope for this document, and is instead defined in the SPIFFE Workload API specification.

### 5.2. Leaf Validation
When authenticating a resource or caller, it is necessary to perform validation beyond what is covered by the X.509 standard. Namely, we must ensure that 1) the certificate is a leaf certificate, and 2) that the signing authority was authorized to issue it.

When validating an X.509 SVID for authentication purposes, the validator MUST ensure that the `CA` field in the basic constraints extension is set to `false`, and that `keyCertSign` and `cRLSign` are not set in the key usage extension.

It is also the responsibility of the validator to ensure that the certificate used to sign the leaf is in fact an authority for the trust domain that the leaf resides in. Specifically, the SPIFFE ID of the signing certificate MUST be equal to the leaf certificate’s SPIFFE trust domain. In the context of X.509, the leaf’s signing certificate is the one with a Subject Key Identifier (SKID) equal to the Authority Key Identifier (AKID) set on the leaf certificate.

Validation of the signing authority is necessary due to lack of widespread support for X.509 URI name constraints (see section 4.2). As support for URI name constraints becomes more widespread, future versions this document may loosen the requirements set forth in this section in favor of name constraints.

## 6. Conclusion
This document set forth conventions and standards for the issuance and validation of X.509-based SPIFFE Verifiable Identity Documents. It forms the basis for real world SPIFFE service authentication and SVID validation. By conforming to the X.509 SVID standard, it is possible to build an identity and authentication system which is interoperable and platform agnostic.