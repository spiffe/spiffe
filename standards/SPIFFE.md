# Secure Production Infrastructure Framework for Everyone (SPIFFE)

## Status of this Memo
This document specifies an experimental identity and identity issuance standard for the internet community, and requests discussion and suggestions for improvements. It is a work in progress. Distribution of this document is unlimited.

## Abstract
Distributed design patterns and practices such as microservices, container orchestrators, and cloud computing have led to production environments that are increasingly dynamic and heterogenous. Conventional security practices (such as network policies that only allow traffic between particular IP addresses) struggle to scale under this complexity. A first-class identity framework for workloads in an organization becomes necessary.

Further, modern developers are expected to understand and play a role in how applications are deployed and managed in production environments. Operations teams require deeper visibility into the applications they are managing. As we move to a more evolved security stance, we must offer better tools to both teams so they can play an active role in building secure, distributed applications.

The SPIFFE standard provides a specification for a framework capable of bootstrapping and issuing identity to services across heterogeneous environments and organizational boundaries.

## Table of Contents
1\. [Introduction](#1.-introduction)  
2\. [The SPIFFE ID](#2.-the-spiffe-id)  
3\. [The SPIFFE Verifiable Identity Document](#3.-the-spiffe-verifiable-identity-document)  
4\. [The Workload API](#4.-the-workload-api)  
5\. [Conclusion](#5.-conclusion)  
Appendix A. [List of SPIFFE Specifications](#appendix-a.-list-of-spiffe-specifications)  

## 1. Introduction
The SPIFFE standard comprises three major components - one which standardizes an identity namespace, one which dictates the manner in which an issued identity may be presented and verified, and another which specifies an API through which identity may be retrieved and/or issued. These components are known as the SPIFFE ID, the SPIFFE Verifiable Identity Document (SVID) and the Workload API, respectively.

While each of these components has a dedicated specification, the remainder of this document will explore them at a high level, and explain how they fit together.

## 2. The SPIFFE ID
A SPIFFE ID is a structured string (represented as a URI) which serves as the "name" of an entity. Although just a string, it is the component around which everything else is built. It is defined in the "SPIFFE Identity and Verifiable Identity Document" specification.

## 3. The SPIFFE Verifiable Identity Document
A SPIFFE Verifiable Identity Document (SVID) is a document which carries the SPIFFE ID itself. It is the functional equivalent of a passport - a document which is presented that carries the identity of the presenter. Of course, similar to passports, they must be resistant to forgery, and it must be obvious that the document belongs to the presenter. In order to achieve this, an SVID includes cryptographic properties which allow it to be 1) proven as authentic, and 2) proven to belong to the presenter.

An SVID itself is not a document type. Instead, we define 1) the properties required of an SVID, and 2) the method by which SVID information can be encoded and validated in various existing document types. Currently, the only supported document type is an X.509 certificate.

The SPIFFE SVID is defined in the "SPIFFE Identity and Verifiable Identity Document" specification.

## 4. The Workload API
The SPIFFE Workload API is the method through which workloads, or compute processes, obtain their SVID(s). It is typically exposed locally, and is unauthenticated. It is up to the implementor of the Workload API to authenticate the caller via an out-of-band method.

In addition to providing a workload with its necessary SVIDs, the Workload API delivers the CA bundles which the workload should outwardly trust. These bundles are associated with trust domains outside of the issued SVID, and are used for federation.

The Workload API is defined in the "SPIFFE Workload API" specification, please see that document for more information.

## 5. Conclusion
This document covered, at a high level, the various components that make up the SPIFFE specification as a whole. Together, these components solve many of the authentication and traffic security challenges presented in modern, heterogeneous environments, particularly those which are highly dynamic. For more detailed information, please see the specification(s) related to the component of interest.

## Appendix A. List of SPIFFE Specifications
* The SPIFFE Identity and Verifiable Identity Document
* The X.509 SPIFFE Verifiable Identity Document
* The SPIFFE Workload API