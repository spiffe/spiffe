# Best Current Practice - Choosing Trust Domain Boundaries

## Status of this Memo
This document provides guidance on deciding which workloads should share a [trust domain](/standards/SPIFFE-ID.md#21-trust-domain) and when workloads should be placed in separate trust domains. Distribution of this document is unlimited.

## Abstract
A SPIFFE trust domain is an identity namespace backed by an issuing authority. The SPIFFE specifications describe trust domains as delineating administrative and/or security boundaries, but leave it to operators to decide where those boundaries are drawn.

This document outlines the criteria to consider when drawing trust domain boundaries, explains which requirements can be met inside a single trust domain and which need separate issuing authorities, and describes common designs and their trade-offs.

## Table of Contents

1\. [Background](#1-background)  
2\. [What a Trust Domain Boundary Provides](#2-what-a-trust-domain-boundary-provides)  
2.1. [Issuer Isolation](#21-issuer-isolation)  
2.2. [What Stays the Same Across a Boundary](#22-what-stays-the-same-across-a-boundary)  
3\. [Criteria for Separate Trust Domains](#3-criteria-for-separate-trust-domains)  
3.1. [Administrative Authority](#31-administrative-authority)  
3.2. [Key Custody and Jurisdiction](#32-key-custody-and-jurisdiction)  
3.3. [Security Posture and Assurance](#33-security-posture-and-assurance)  
3.4. [Compromise Containment](#34-compromise-containment)  
4\. [Deployment Topology](#4-deployment-topology)  
4.1. [One Trust Domain Across Many Locations](#41-one-trust-domain-across-many-locations)  
4.2. [Locations That Warrant Separate Trust Domains](#42-locations-that-warrant-separate-trust-domains)  
5\. [Authorization Versus Issuer Isolation](#5-authorization-versus-issuer-isolation)  
6\. [Federation](#6-federation)  
7\. [Common Designs](#7-common-designs)  
7.1. [One Trust Domain per Organization](#71-one-trust-domain-per-organization)  
7.2. [One Trust Domain per Environment](#72-one-trust-domain-per-environment)  
7.3. [One Trust Domain per Regulated Zone or Jurisdiction](#73-one-trust-domain-per-regulated-zone-or-jurisdiction)  
7.4. [Trust Domains Across Organizations](#74-trust-domains-across-organizations)  
8\. [Evolving Boundaries](#8-evolving-boundaries)  
9\. [Heuristics](#9-heuristics)  
10\. [Appendix](#10-appendix)  

## 1. Background
The [SPIFFE ID specification](/standards/SPIFFE-ID.md#21-trust-domain) says a trust domain "corresponds to the trust root of a system" and could represent "an individual, organization, environment or department running their own independent SPIFFE infrastructure". The [Trust Domain and Bundle specification](/standards/SPIFFE_Trust_Domain_and_Bundle.md#2-trust-domains) defines a trust domain as "an identity namespace which is backed by an issuing authority with a set of cryptographic keys", and the [SPIFFE Federation specification](/standards/SPIFFE_Federation.md#1-background) notes that trust domains "delineate administrative and/or security domains".

These definitions tell operators what a trust domain is, but not how many they need. In practice the question comes up early in any SPIFFE adoption, and it is hard to change later because the trust domain name is part of every SPIFFE ID issued in it. Separating too little leaves workloads with very different trust requirements under one authority. Separating too much adds federation, bundle distribution, and policy configuration without a matching security benefit.

This document does not define new requirements. It collects the considerations that the SPIFFE specifications imply and describes how they are commonly applied.

## 2. What a Trust Domain Boundary Provides

### 2.1 Issuer Isolation
The property that only a trust domain boundary provides is issuer isolation. Every SVID is signed by an authority of the trust domain it belongs to, and the [SPIFFE ID specification](/standards/SPIFFE-ID.md#412-scope-and-influence) states that the authority of one trust domain should not be making assertions about entities in other trust domains. A relying party that validates an SVID against the bundle of trust domain A will not accept an SVID issued by the authority of trust domain B, unless it has been explicitly given B's bundle.

Within a single trust domain there is no equivalent boundary. SPIFFE does not define a way to limit an issuer to part of a trust domain's namespace. Any authority that can sign SVIDs for a trust domain can sign an SVID with any SPIFFE ID in it. [X.509 name constraints](/standards/X509-SVID.md#42-name-constraints) can limit a signing certificate to one or more trust domains where they are supported, but they cannot limit it to a path within a trust domain. This also applies to intermediate issuers that an implementation runs inside one trust domain, for example to scale out issuance to several locations: each of them can issue any identity in the trust domain.

As a consequence, the trust domain is the unit of compromise. If an issuing key of a trust domain is compromised, every identity in that trust domain must be considered compromised until the key has been removed from the trust domain's bundle and the bundle has been redistributed.

### 2.2 What Stays the Same Across a Boundary
A trust domain boundary does not by itself grant or deny access to anything. Whether workload A may call workload B is an authorization decision. Splitting workloads into different trust domains changes which authority vouches for their identities, and requires relying parties to hold the bundles of the trust domains they accept, but it does not replace authorization policy. Conversely, two workloads in the same trust domain can be fully denied access to each other by policy.

Operators should therefore separate two questions:

* Which authority do I trust to assert this identity? This is answered by trust domain boundaries and federation.
* What may this identity do? This is answered by authorization policy, typically expressed in terms of SPIFFE IDs.

## 3. Criteria for Separate Trust Domains
This section lists the criteria that most often justify separate trust domains. In each case the question to ask is whether the workloads involved require independent issuing authorities, not whether they need to be told apart. Telling workloads apart only requires distinct SPIFFE IDs (see [section 5](#5-authorization-versus-issuer-isolation)).

### 3.1 Administrative Authority
If different groups are responsible for operating the issuing infrastructure, including who may register workloads, change attestation policy, or access signing keys, those groups should usually operate separate trust domains. Sharing a trust domain means each group can issue identities that the other group's relying parties accept, so a mistake or misuse by one group affects the other.

Different teams consuming identities from a centrally operated SPIFFE deployment do not by themselves need separate trust domains. What matters is who controls issuance.

### 3.2 Key Custody and Jurisdiction
Regulatory or sovereignty requirements may require that identity issuance for some workloads is controlled within a given jurisdiction, that signing keys are held in specific hardware or by a specific legal entity, or that the issuing infrastructure is operated by specific personnel. If two sets of workloads have requirements of this kind that cannot both be met by one issuing authority, they need separate trust domains.

Because the requirement applies to the authority, it can justify separate trust domains even when the workloads run on similar or shared infrastructure.

### 3.3 Security Posture and Assurance
Environments that operate under different security controls, such as production and development, or cardholder data environments and the rest of an organization, are common candidates for separate trust domains. The [SPIFFE Federation specification](/standards/SPIFFE_Federation.md#3-targeted-use-cases) lists staging versus production and PCI versus non-PCI as typical examples.

The reasoning is that an authority is only as trustworthy as the least protected part of the infrastructure that can cause it to issue SVIDs. If development clusters can register workloads or reach the issuing infrastructure with weaker controls than production, a shared trust domain lets a compromise of the development environment produce identities that production relying parties accept.

The [Trust Domain and Bundle specification](/standards/SPIFFE_Trust_Domain_and_Bundle.md#62-reusing-cryptographic-keys-across-trust-domains) also discourages reusing keys across trust domains for the same reason. Separate trust domains only provide isolation if they are backed by separate keys.

### 3.4 Compromise Containment
Since the trust domain is the unit of compromise (see [section 2.1](#21-issuer-isolation)), operators can ask which workloads they would accept losing trust in together. A key compromise in a trust domain requires rotating its keys, redistributing its bundle to every relying party and federated trust domain, and reissuing every SVID in it. If the operational cost or impact of that event is unacceptable for a given set of workloads, placing them in a separate trust domain limits the scope.

This criterion should be weighed against the cost of federation (see [section 6](#6-federation)). Splitting purely to reduce blast radius, without one of the criteria above, often produces many trust domains that share an operator and the same security controls, and therefore tend to fail together anyway.

## 4. Deployment Topology

### 4.1 One Trust Domain Across Many Locations
Workloads running in several regions, data centers, clusters, or cloud accounts do not need separate trust domains just because they run in different places. If the same administrative authority operates issuance for all locations under the same security controls, a single trust domain is usually the simpler choice. Location can be expressed in SPIFFE ID paths where authorization needs it.

Implementations may run issuing infrastructure in each location within one trust domain, for example to keep issuance available when a location is cut off from the others, or to reduce latency. Operators should keep in mind that, as described in [section 2.1](#21-issuer-isolation), each of these issuers can issue any identity in the trust domain. Distributing issuance improves availability, not isolation.

### 4.2 Locations That Warrant Separate Trust Domains
Separate trust domains per location are appropriate when a criterion from [section 3](#3-criteria-for-separate-trust-domains) differs between locations, for example when locations are operated by different organizations, fall under different jurisdictions with key custody requirements, or run under different security controls. They may also be appropriate when locations need to operate fully independently for long periods, so that a shared issuing authority is not practical.

Trust domain names should not be derived from details that are likely to change, such as the name of a specific cluster, unless the trust domain is genuinely tied to that cluster's lifetime. Replacing a cluster should not require renaming a trust domain and changing every SPIFFE ID and policy that refers to it.

## 5. Authorization Versus Issuer Isolation
Many requirements that are first approached with separate trust domains can be met within one trust domain through SPIFFE ID paths and authorization policy. The following table summarizes which mechanism a requirement needs.

| Requirement | Can be met with paths and authorization policy in one trust domain | Needs separate trust domains |
|---|---|---|
| Distinguish services, environments, regions, or tenants in access decisions | Yes | No |
| Deny workloads in one environment access to workloads in another | Yes | No |
| Give different teams self-service over the identities they consume | Usually, if the implementation can delegate registration with sufficient controls | Only if the teams must control issuance themselves |
| Prevent an operator or issuer of one group from issuing identities accepted by another group's relying parties | No | Yes |
| Hold signing keys under different custody or in different jurisdictions | No | Yes |
| Limit the impact of an issuing key compromise to a subset of workloads | No | Yes |
| Revoke trust in a whole group of workloads at once by removing a bundle | No | Yes |

Path-based authorization only holds as long as the issuing authority issues each SPIFFE ID solely to the workloads it is meant for. It relies on the authority. Separate trust domains do not.

## 6. Federation
Separate trust domains that need to communicate do so through [SPIFFE Federation](/standards/SPIFFE_Federation.md), which requires each side to serve a bundle endpoint, configure the endpoint parameters of the other side, refresh bundles regularly, and distribute the resulting bundles to relying parties. Each additional trust domain that participates in a federation relationship adds this work, and a mesh of N trust domains that all federate with each other has on the order of N² relationships to manage.

When federating, operators should keep authentication trust separate from authorization:

* Federating with a trust domain means relying parties will authenticate its SVIDs. It should not mean they are authorized to do anything. Authorization policies should name the trust domain explicitly, as the [SPIFFE ID specification](/standards/SPIFFE-ID.md#412-scope-and-influence) notes that assertions in an SVID are qualified by the trust domain it resides in.
* Only distribute a federated bundle to the workloads that need to authenticate that trust domain, rather than to every workload in the local trust domain.
* Do not assume that path conventions mean the same thing in a federated trust domain, unless this has been agreed with its operator (see [section 4.1.3](/standards/SPIFFE-ID.md#413-interpretation) of the SPIFFE ID specification).

If two trust domains federate with each other for most of their workloads, and share an operator and the same security controls, that is a sign they may not need to be separate.

## 7. Common Designs
This section describes designs that are often used in practice. They can be combined, for example one trust domain per environment within each regulated zone.

### 7.1 One Trust Domain per Organization
All workloads of an organization share one trust domain, and environments, regions, and services are distinguished by SPIFFE ID paths.

* Benefits: no federation inside the organization, one bundle to distribute, and authorization policies can refer to any workload directly.
* Trade-offs: everything shares one issuing authority, so the least protected environment that can obtain SVIDs determines the trust in all of them, and a key compromise affects the whole organization.
* Fits: smaller organizations, or organizations where one platform team operates identity issuance under uniform controls.

### 7.2 One Trust Domain per Environment
Each environment, such as production, staging, and development, has its own trust domain, for example `prod.example.com` and `dev.example.com`.

* Benefits: development and staging cannot issue identities that production accepts, and keys and access to issuance can be protected according to each environment's needs.
* Trade-offs: workloads that legitimately cross environments, such as shared tooling, need federation or separate identities per environment. Paths and policies are often duplicated across environments.
* Fits: most organizations with environments under different security controls. This is the most common split.

### 7.3 One Trust Domain per Regulated Zone or Jurisdiction
Workloads that fall under specific regulatory or sovereignty requirements, such as a cardholder data environment or workloads that must be controlled within a given country, get their own trust domain, while other workloads share another.

* Benefits: the issuing authority, its keys, and its operators can be scoped and audited to meet the requirement, independently of the rest of the organization.
* Trade-offs: federation is needed for every flow between the regulated zone and other workloads, and should be limited to the workloads that need it.
* Fits: organizations with regulatory or sovereignty requirements that apply to identity issuance itself.

### 7.4 Trust Domains Across Organizations
Each organization operates its own trust domains, and they federate for the workloads that need to communicate. A hosted service may also authenticate its customers' workloads by consuming their bundles, as described in the [SPIFFE Federation specification](/standards/SPIFFE_Federation.md#3-targeted-use-cases).

* Benefits: neither organization trusts the other's issuing authority for its own identities.
* Trade-offs: path conventions, naming, and implementation details cannot be assumed to match, and coordination is generally limited to what the federation protocol exchanges.
* Fits: any communication across organizations. Separate organizations should not share a trust domain.

## 8. Evolving Boundaries
Trust domain boundaries are expensive to change, because the trust domain name is part of every SPIFFE ID issued in it. Splitting or merging trust domains changes SPIFFE IDs, which in turn affects authorization policies, audit records, and any system that stores or matches SPIFFE IDs.

When boundaries need to change, the following approach reduces disruption:

* Stand up the new trust domain alongside the existing one and federate the two for the duration of the migration, so that workloads in either can authenticate each other.
* Update authorization policies to accept both the old and the new SPIFFE ID of a migrating workload before moving it, and remove the old ID once the migration is complete.
* Move workloads incrementally and remove the federation relationship and the old bundle only once nothing depends on them.

Merging trust domains also merges their issuing authorities, so the criteria in [section 3](#3-criteria-for-separate-trust-domains) should be re-evaluated first. A merge removes isolation that may have been relied on implicitly.

To keep future changes manageable, choose trust domain names that describe the boundary they represent (an organization, environment, or zone) rather than the infrastructure that currently implements it, and follow the collision guidance in [section 2.1.1](/standards/SPIFFE-ID.md#211-trust-domain-name-collisions) of the SPIFFE ID specification.

## 9. Heuristics
* Use separate trust domains when workloads need independent issuing authorities: different operators of issuance, different key custody or jurisdiction requirements, or different security controls.
* Use one trust domain when workloads only need to be told apart. Express service, environment, region, and tenant in SPIFFE ID paths and enforce access with authorization policy.
* Do not create a trust domain per cluster or region by default. Running issuance in several locations within one trust domain improves availability, not isolation.
* Treat the trust domain as the unit of compromise and size it according to which workloads you would accept rotating and reissuing together.
* Back each trust domain with its own keys.
* When federating, keep authentication separate from authorization and only distribute federated bundles to the workloads that need them.
* Choose trust domain names that will outlive the infrastructure they run on.

## 10. Appendix

* [The SPIFFE Identity and Verifiable Identity Document](/standards/SPIFFE-ID.md)
* [The SPIFFE Trust Domain and Bundle](/standards/SPIFFE_Trust_Domain_and_Bundle.md)
* [SPIFFE Federation](/standards/SPIFFE_Federation.md)
* [The X.509 SPIFFE Verifiable Identity Document](/standards/X509-SVID.md)
