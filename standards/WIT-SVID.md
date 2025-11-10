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

### 2.1. Key ID - `kid`

The `kid` header is defined by [JSON Web Signature (JWS)][2]. 

For the WIT-SVID profile, this header is mandatory.

The precise structure of this header is unspecified, and, it MUST be treated by verifiers as a case-sensitive string.

The issuer MUST ensure that the value set within the `kid` header is unique to each issuing key-pair.

### 2.2. Additional Headers

It is permitted for an implementation to include additional headers not specified in this document or the upstream document.

### 3. Claims

TODO:

- `iss` claim. Do we wish to make this mandatory?

### 3.1. Subject - `sub`

TODO: Mandatory, and must be the SPIFFE ID of the workload.

### 3.2. Additional Claims

## 4. Token Signing and Validation

## 5. Token Transmission

## 6. Representation in the SPIFFE Bundle

## 7. Security Considerations

### 7.1 Proof of Possession

The WIT-SVID MUST NOT be used as a bearer token and MUST be presented with a 
proof of possession of the key-pair within the `cnf` claim. 

## Appendix A. Overview of Differences

JOSE Headers:

| Header  | WIT      | WIT-SVID  |
|---------|----------|-----------|
| `kid`   | Optional | Mandatory |

[1]: https://datatracker.ietf.org/doc/draft-ietf-wimse-workload-creds/
[2]: https://www.rfc-editor.org/rfc/rfc7515