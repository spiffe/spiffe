# Best Current Practice - Designing SPIFFE ID Paths

## Status of this Memo
This document provides guidance on designing the [path component](/standards/SPIFFE-ID.md#22-path) of SPIFFE IDs, in particular on choosing identity granularity, ordering path segments consistently, and identifying individual workloads. Distribution of this document is unlimited.

## Abstract
The SPIFFE ID specification defines the syntax of SPIFFE ID paths, but intentionally leaves their meaning to the administrator of each trust domain. Path conventions are hard to change once SPIFFE IDs are used in authorization policies, audit records, and federation agreements.

This document outlines the considerations to apply when designing a path convention: what an identity should represent, how to structure and order paths, how to handle optional and instance-level information, how relying parties should match paths, and how to bind paths to attested properties and change conventions over time.

## Table of Contents

1\. [Background](#1-background)  
2\. [Identity Granularity](#2-identity-granularity)  
2.1. [Service, Deployment, and Instance Identities](#21-service-deployment-and-instance-identities)  
2.2. [Costs of Instance Identities](#22-costs-of-instance-identities)  
3\. [Path Structure](#3-path-structure)  
3.1. [Opaque, Positional, and Labeled Paths](#31-opaque-positional-and-labeled-paths)  
3.2. [Ordering](#32-ordering)  
3.3. [Optional Levels](#33-optional-levels)  
3.4. [Segment Values](#34-segment-values)  
4\. [Uniqueness and Lifecycle](#4-uniqueness-and-lifecycle)  
4.1. [Scoping Values](#41-scoping-values)  
4.2. [Instance Identifiers](#42-instance-identifiers)  
5\. [Authorization](#5-authorization)  
5.1. [Exact and Prefix Matching](#51-exact-and-prefix-matching)  
5.2. [No Implied Inheritance](#52-no-implied-inheritance)  
6\. [Issuance](#6-issuance)  
7\. [Evolving a Convention](#7-evolving-a-convention)  
8\. [Heuristics](#8-heuristics)  
9\. [Appendix](#9-appendix)  

## 1. Background
The [SPIFFE ID specification](/standards/SPIFFE-ID.md#22-path) says that the path of a SPIFFE ID "allows for the unique identification of a given workload" and that "the meaning behind the path is left open-ended and is the responsibility of the administrator to define". It gives examples that identify services directly, that map identities from other platforms such as Kubernetes service accounts, and opaque identifiers whose meaning is kept in a separate system.

The syntax rules are short. Path segments contain only letters, numbers, dots, dashes, and underscores, segments may not be empty or relative path modifiers, the path may not end with `/` or contain percent-encoded characters, and the path is [case-sensitive](/standards/SPIFFE-ID.md#24-spiffe-id-parsing). The [whole SPIFFE ID](/standards/SPIFFE-ID.md#23-maximum-spiffe-id-length) should not exceed 2048 bytes.

Everything else is a choice made by the operator. This document does not define a universal naming scheme. Different runtimes and organizations need different information in their paths. It describes properties that make a convention unambiguous, safe to authorize against, and maintainable. It assumes that trust domain boundaries have already been chosen. See [Choosing Trust Domain Boundaries](Choosing_Trust_Domain_Boundaries.md) for that decision.

## 2. Identity Granularity

### 2.1 Service, Deployment, and Instance Identities
The first decision is what a single SPIFFE ID represents. Common choices are:

* **Service identity**: all replicas of a logical service, in all locations, share one SPIFFE ID, for example `spiffe://example.org/service/payments`.
* **Deployment identity**: each deployment of a service, for example per environment, region, or cluster, has its own SPIFFE ID, for example `spiffe://example.org/service/payments/region/eu-west`.
* **Instance identity**: each running instance has its own SPIFFE ID, for example `spiffe://example.org/service/payments/region/eu-west/instance/7f3c2a`.

The right granularity is the coarsest one at which relying parties need to make different decisions. If every authorization policy that refers to a service treats all of its replicas the same way, a service or deployment identity is sufficient. Finer granularity is useful when:

* Authorization differs between deployments, for example a regional data store that should only accept callers from the same region.
* Individual instances must be distinguished in an authorization decision, for example a leader that is allowed to perform operations that followers are not.
* Accountability requires that actions be attributed to an instance through the identity itself, rather than through other information such as logs or connection metadata.

Granularity can differ between services. A convention can give most workloads a deployment identity and only a few of them instance identities, as long as relying parties can tell from the path which kind of identity they are looking at (see [section 3](#3-path-structure)).

### 2.2 Costs of Instance Identities
Instance identities provide the most precise attribution, but they have costs that should be weighed explicitly:

* Authorization policies rarely want to list instances. They usually match on a service or deployment and ignore the instance part, which requires matching rules that relying parties must implement correctly (see [section 5](#5-authorization)).
* Identities change whenever instances are replaced. Anything that stores or caches SPIFFE IDs, such as audit pipelines, allow lists, and metrics labels, sees a constantly changing set of values.
* The issuing system has to register, track, and clean up many more identities.

If the goal is accountability rather than authorization, consider whether instance information can be recorded without making it part of the identity, for example by logging which instance obtained which SVID at issuance time, and keeping a service or deployment identity for authorization.

## 3. Path Structure

### 3.1 Opaque, Positional, and Labeled Paths
There are three broad styles of paths:

* **Opaque**: the path is a random or assigned identifier, such as `spiffe://example.org/9eebccd2-12bf-40a6-b262-65fe0487d453`, and its attributes are kept in a separate system. This avoids encoding information that may change and keeps identities stable, but every relying party that makes decisions based on attributes needs access to that system.
* **Positional**: the meaning of each segment is given by its position, for example `spiffe://example.org/payments/prod/eu-west`. This is compact, but becomes ambiguous as soon as a level is optional or a new level is added, because a reader can no longer tell which position a value is in.
* **Labeled**: each value is preceded by a label naming it, for example `spiffe://example.org/service/payments/env/prod/region/eu-west`. The common Kubernetes convention `spiffe://example.org/ns/<namespace>/sa/<service-account>` is an example of this style.

Labeled paths are recommended when paths carry information that relying parties use. They are longer, but they make each value self-describing, they allow optional levels without ambiguity, and they allow new labels to be introduced without changing the meaning of existing ones.

### 3.2 Ordering
Within a labeled convention, the labels should appear in a fixed order for all identities in the trust domain, so that each combination of values has exactly one SPIFFE ID. Two IDs that contain the same labels and values in different orders, such as `/env/prod/service/payments` and `/service/payments/env/prod`, are different SPIFFE IDs, and a convention that allows both creates two identities for the same principal.

A practical way to maintain a fixed order is to keep a registry of labels with their relative positions, and to leave gaps so that new labels can be inserted later. The order does not need to describe a strict containment hierarchy. It only needs to be canonical.

Which label comes first is a trade-off:

* **Service first**, such as `/service/payments/region/eu-west`: every identity of a service shares a common prefix, which suits policies that are mostly written per service.
* **Scope first**, such as `/region/eu-west/service/payments`: identities within a scope share a common prefix, which suits policies that are mostly written per environment, region, or tenant.

Choose the order that matches how most policies will be written, and apply it consistently. Prefix-based policies (see [section 5.1](#51-exact-and-prefix-matching)) can only match on the levels that come first.

### 3.3 Optional Levels
Different runtimes have different properties. A virtual machine has no Kubernetes namespace, and a serverless function may have no stable region. A convention should allow levels to be omitted, but omission must not create ambiguity or merge distinct principals:

* With labeled paths, omit both the label and the value, and keep the relative order of the remaining labels. An absent label then simply means the identity makes no assertion about that level.
* Do not use placeholder values such as `none` or `default` for an absent level, unless that value is reserved and can never be a real value of the level.
* Make sure that omitting a level cannot cause two different principals to receive the same SPIFFE ID. For example, if two services named `payments` run in different namespaces, the namespace must not be optional for them.

Relying parties should treat an absent level as "unspecified", not as a wildcard. A policy that requires `region/eu-west` should not accept an identity that has no region.

### 3.4 Segment Values
Path segments may only contain letters, numbers, dots, dashes, and underscores. Values taken from other systems, such as user names, email addresses, or resource names from other platforms, may contain other characters or may be longer than is practical. A convention should define how such values are mapped into segments, and the mapping should be injective, so that two different source values can never produce the same segment. If a value cannot be mapped safely, it should not be part of the path.

Because the path is case-sensitive, values from systems that are case-insensitive should be normalized to one case before they are placed in a path. Otherwise the same principal can end up with several SPIFFE IDs.

Avoid values that look like labels of the convention, or reserve the label names so that they cannot be used as values. In a labeled path, a value that equals a label name can make the path hard to read and easy to parse incorrectly.

## 4. Uniqueness and Lifecycle

### 4.1 Scoping Values
A consistent order does not make identities unique by itself. The values must also distinguish the principals they are meant to distinguish. Names of clusters, accounts, or namespaces are often only unique within some other scope. Two independently operated clusters may both be called `main`, and two cloud providers may both have an account called `prod`. If such names appear in paths, include the scope that makes them unique, or use identifiers that are globally unique within the trust domain.

### 4.2 Instance Identifiers
When instance identities are used, the instance identifier determines what "the same instance" means. Decide explicitly whether an identity should survive:

* a process restart on the same host,
* rescheduling to a different host,
* failover to a replacement, or
* re-creation of the instance under the same name, for example a Kubernetes pod in a StatefulSet.

Identifiers derived from platform names, such as a pod name, survive re-creation under the same name, so a replacement inherits its predecessor's identity. Identifiers assigned at creation, such as a platform UID, change on every re-creation. Neither is wrong, but the convention should state which one is intended, and policies and audit consumers should know which one they are dealing with.

Identifiers should not be reused for a different principal within the period in which old SVIDs or audit records referring to them may still be relevant.

## 5. Authorization

### 5.1 Exact and Prefix Matching
Relying parties should match SPIFFE IDs exactly where possible. When policies need to match a group of identities, for example all instances of a service, the match should be defined on whole path segments:

* A policy that allows `spiffe://example.org/service/payments` and everything below it must not match `spiffe://example.org/service/payments-admin`. A plain string prefix match on the URI would accept it, so match on whole segments instead.
* Match on the trust domain as well as the path. A path that is allowed in one trust domain must not be accepted from another trust domain just because the path is the same (see [section 4.1.2](/standards/SPIFFE-ID.md#412-scope-and-influence) of the SPIFFE ID specification).
* Compare paths case-sensitively, as the specification requires.

### 5.2 No Implied Inheritance
A longer path does not imply narrower privileges, and a shorter path does not imply broader ones. `spiffe://example.org/service/payments/instance/7f3c2a` is a different principal from `spiffe://example.org/service/payments`, and neither inherits permissions from the other unless a policy says so. Conventions and policy tooling should make such grants explicit rather than deriving them from the path hierarchy.

Similarly, the meaning of a path convention only extends to the trust domains that have agreed on it. Relying parties should not interpret the paths of a federated trust domain according to their own convention unless the two operators have agreed on it (see [section 4.1.3](/standards/SPIFFE-ID.md#413-interpretation) of the SPIFFE ID specification).

## 6. Issuance
A path is an assertion made by the issuing authority. Each value in it is only as trustworthy as the evidence the authority used to assign it. Path values should therefore be derived from properties the issuing system has attested, such as the namespace and service account of a Kubernetes pod or the instance metadata of a cloud VM, and not from information the workload provides about itself.

Prefer properties that remain true for the lifetime of the SVID. The [SPIFFE ID specification](/standards/SPIFFE-ID.md#411-temporal-accuracy) notes that an assertion true at issuance may no longer be true at the time of use. Values such as the node a workload runs on are usually stable for the lifetime of a workload, while values such as a deployment version or a feature flag may change while SVIDs are still valid.

If different issuers or registration paths can assign the same label, make sure they derive its value the same way. Otherwise the same principal can receive different SPIFFE IDs depending on how it was registered.

## 7. Evolving a Convention
Changing a path convention changes SPIFFE IDs, which affects every policy, audit query, and federation agreement that refers to them. To keep changes manageable:

* Add new labels in the positions reserved for them, and only to identities that need them. Identities that do not need a new label keep their existing SPIFFE ID.
* Avoid changing the order of existing labels or the meaning of existing values. If that is necessary, treat it as a migration.
* For a migration, update policies to accept both the old and the new SPIFFE ID of each affected principal, then switch issuance to the new SPIFFE IDs, and finally remove the old ones from policies once no valid SVIDs carry them.
* Document the convention, including the label registry, the order, the value mappings, and which properties each label is derived from, so that policy authors and federated partners can rely on it.

## 8. Heuristics
* Choose the coarsest granularity at which relying parties need to make different decisions. Use instance identities only where the identity itself must distinguish instances.
* Prefer labeled paths with a fixed, documented order of labels over positional paths.
* Omit absent levels entirely, keep the order of the remaining labels, and never let omission merge distinct principals.
* Map external values into segments with an injective mapping, and normalize case.
* Include the scope that makes a value unique, or use globally unique identifiers.
* Match SPIFFE IDs exactly or on whole segments, and always together with the trust domain.
* Do not derive permissions from the path hierarchy.
* Derive path values from attested properties that stay true for the lifetime of the SVID.
* Treat changes to the order or meaning of labels as migrations.

## 9. Appendix

* [The SPIFFE Identity and Verifiable Identity Document](/standards/SPIFFE-ID.md)
* [Choosing Trust Domain Boundaries](Choosing_Trust_Domain_Boundaries.md)
