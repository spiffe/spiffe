# SPIFFE Specification Stability

## Table of Contents
1\. [What this is](#1-what-this-is)  
2\. [Stability levels](#2-stability-levels)  
2.1. [Proposed](#21-proposed)  
2.2. [Incubating](#22-incubating)  
2.3. [Stable](#23-stable)  
3\. [Marking stability](#3-marking-stability)  
3.1. [Marking part of a specification](#31-marking-part-of-a-specification)  

## 1. What this is

This document defines stability levels for SPIFFE *specifications* and the
process for moving a specification between them.

This is distinct from [MATURITY.md](/MATURITY.md), which describes the maturity
of SPIFFE *software projects* (e.g. SPIRE). A specification's stability and an
implementation's maturity are separate axes - a Stable specification may have
implementations at any maturity, and vice versa.

## 2. Stability levels

- **Proposed**
  - *Breaking-change contract:* anything may change or be removed at any time, without notice.
  - *Where it lives:* an open PR or proposal. Not merged into the `main` branch.
  - *Audience:* discussion in SIG-Spec and proof of concept implementations.
- **Incubating**
  - *Breaking-change contract:* breaking changes are avoided, but may be made in response to real-world implementation experience.
  - *Where it lives:* merged into the `main` branch, marked Incubating.
  - *Audience:* implementers willing to track changes and provide feedback. Features relying on an Incubating specification are typically gated behind a feature flag.
- **Stable**
  - *Breaking-change contract:* breaking changes are severely avoided and reserved for resolving critical security issues.
  - *Where it lives:* merged into the `main` branch, marked Stable.
  - *Audience:* anyone, including production-critical use.

### 2.1. Proposed

A specification is **Proposed** by default whilst it lives in an open pull
request or proposal. It has not yet been merged into the `main` branch. SIG-Spec
may still be debating its shape, and any part of it may change or be dropped
entirely.

Because Proposed specifications live in PRs rather than in `main`, they require
no in-document stability marking - the fact that a specification is unmerged
indicates that it is Proposed.

### 2.2. Incubating

A specification is promoted from Proposed to **Incubating** by a pull request
that merges it into the `main` branch with an Incubating banner, approved by two
code owners. The criterion for promotion is SIG-Spec consensus that its design
is sound and ready for trial implementation.

When implementing an Incubating specification, it is recommended that adopters
record the revision of the specification that they have implemented. A permalink
to the document on GitHub or the commit hash is sufficient for this purpose.

Adopters implementing an Incubating specification are encouraged to discuss
their experience and raise feedback with SIG-Spec, so that any rough edges can
be ironed out before it is promoted to Stable.

We avoid making breaking changes to Incubating specifications. However, the
purpose of the Incubating phase is to gather experience from real
implementations, and that experience may occasionally force a breaking change.

Where breaking changes must be made, the change should be clearly communicated
along with advice on adjusting implementations. This should be included within
the document itself within an appendix.

Due to the potential for breaking changes, we typically expect implementations
of an Incubating specification to gate it behind a feature flag (or equivalent
opt-in), rather than enabling it by default. This makes it clear to operators
that they are relying on functionality that may still change, and keeps an
Incubating feature from becoming a de-facto stable one purely by virtue of being
widely deployed.

### 2.3. Stable

A specification is promoted from Incubating to **Stable** by a pull request that
updates its banner, approved by two code owners. The criterion for promotion is
that at least two independent, interoperable implementations exist and no
further breaking changes are anticipated.

Breaking changes to a Stable specification are severely avoided and reserved for
resolving critical security issues. A Stable specification cannot be demoted
back to Incubating, but may be extended in a non-breaking way with new sections
or profiles marked Incubating.

## 3. Marking stability

A specification declares its level with a banner immediately beneath the title,
above the existing "Status of this Memo" section. Use the variant matching the
level:

> **Stability: Incubating** - see [STABILITY.md](STABILITY.md).

> **Stability: Stable** - see [STABILITY.md](STABILITY.md).

### 3.1. Marking part of a specification

A section inherits the stability of the document it sits in unless it carries
its own marker. This lets a mature specification grow a less-baked addition
without dragging the whole document down a level. For example, an otherwise
Stable specification may define a specific profile, or a set of RPCs, at a lower
stability whilst that part is still being proven.

An override is declared inline at the head of the section:

> **Stability: Incubating** (this section only - the remainder of this document
> is Stable.)
