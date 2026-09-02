# Locating the SPIFFE Endpoint

> **Stability: Experimental** - see [STABILITY.md](STABILITY.md).

## Status of this Memo

This document specifies an identity endpoint standard for the internet community, and requests discussion and suggestions for improvements. Distribution of this document is unlimited.

## Abstract

SPIFFE clients must be able to discover where, and by what means, they can obtain their SPIFFE identity. This document defines the `SPIFFE_ENDPOINT` environment variable as the standard, portable mechanism for that discovery. `SPIFFE_ENDPOINT` supersedes the `SPIFFE_ENDPOINT_SOCKET` variable defined by the [SPIFFE Workload Endpoint](SPIFFE_Workload_Endpoint.md) specification.

This specification is deliberately narrow. It standardizes only the variable, the structure of its value, and how a client selects among the options it offers. It does *not* define what any particular delivery mechanism does; the meaning of each URI scheme is owned by a separate specification. This keeps the mechanism extensible: new delivery mechanisms are introduced by publishing new specifications, without any change to this document.

## Table of Contents

1\. [Introduction](#1-introduction)
2\. [The SPIFFE_ENDPOINT Environment Variable](#2-the-spiffe_endpoint-environment-variable)
2.1. [Value Format](#21-value-format)
2.2. [Scheme Registry](#22-scheme-registry)
3\. [Client Behavior and Precedence](#3-client-behavior-and-precedence)
4\. [Deprecation of SPIFFE_ENDPOINT_SOCKET](#4-deprecation-of-spiffe_endpoint_socket)
5\. [Relationship to Other Specifications](#5-relationship-to-other-specifications)

## 1. Introduction

A workload, or any SPIFFE client, needs to know where to go to obtain its SPIFFE identity before it can participate in a SPIFFE-based system. Historically this location was communicated through the `SPIFFE_ENDPOINT_SOCKET` environment variable, which pointed at a [SPIFFE Workload Endpoint](SPIFFE_Workload_Endpoint.md) served over a Unix Domain Socket or a TCP listen socket.

As SPIFFE has grown, so have the ways in which identity may be made available to a client. In addition to a live API endpoint, identity material may be delivered directly via the filesystem. Rather than overloading `SPIFFE_ENDPOINT_SOCKET` — whose name and history tie it to socket transports — this specification defines a single, general-purpose variable, `SPIFFE_ENDPOINT`, that can express any delivery mechanism.

The scope of this document is limited to *discovery and selection*: the `SPIFFE_ENDPOINT` variable, the structure of its value, and the rules a client follows to pick an option it supports. The behavior of each mechanism — its transport, protocol, wire format, on-disk layout, authentication, and so on — is defined by the specification that owns the corresponding URI scheme, not here. This separation is intentional and load-bearing: it allows new delivery mechanisms to be added to SPIFFE simply by publishing a new specification that claims a scheme, with no amendment to this document.

## 2. The SPIFFE_ENDPOINT Environment Variable

Clients may be explicitly configured with an endpoint location, or may utilize the well-known environment variable `SPIFFE_ENDPOINT`. If not explicitly configured, conforming clients MUST fall back to the environment variable. See [Client Behavior and Precedence](#3-client-behavior-and-precedence) for the full precedence rules, including the deprecated `SPIFFE_ENDPOINT_SOCKET` fallback.

### 2.1. Value Format

The value of the `SPIFFE_ENDPOINT` environment variable is one or more [RFC 3986](https://www.ietf.org/rfc/rfc3986.txt) URIs. Multiple URIs MAY be provided as an ordered list separated by commas (`,`). Whitespace surrounding an individual URI is not significant; clients MUST trim leading and trailing whitespace from each list entry before interpreting it.

Each URI's scheme identifies the delivery mechanism. When a list is provided, it expresses an ordered preference: clients MUST select and use the first entry whose scheme they support, and MUST ignore entries whose scheme they do not support. This allows a producer to offer several mechanisms and let each client choose the first one it understands.

A client that supports none of the schemes present in the value MUST treat the situation as if no endpoint were configured.

The interpretation of the components of a URI other than the scheme (authority, path, query, and so on) is defined by the specification that owns that scheme, and is out of scope for this document.

### 2.2. Scheme Registry

The following table maps URI schemes to the specifications that define their meaning. This registry is informative and non-exhaustive: additional schemes MAY be introduced by other specifications without amending this document.

| Scheme | Meaning defined by |
| ------ | ------------------ |
| `unix` | [The SPIFFE Workload Endpoint](SPIFFE_Workload_Endpoint.md) (and [The SPIFFE Broker Endpoint](SPIFFE_Broker_Endpoint.md) for broker clients) |
| `tcp`  | [The SPIFFE Workload Endpoint](SPIFFE_Workload_Endpoint.md) (and [The SPIFFE Broker Endpoint](SPIFFE_Broker_Endpoint.md) for broker clients) |
| `file` | The SPIFFE Filesystem Delivery specification (in development) |

For the `unix` and `tcp` schemes, the value carries the same meaning it does for `SPIFFE_ENDPOINT_SOCKET`, as defined in [Section 4 of the SPIFFE Workload Endpoint](SPIFFE_Workload_Endpoint.md#4-locating-the-endpoint) specification.

## 3. Client Behavior and Precedence

A conforming client resolves its endpoint location in the following order of precedence:

1. Explicit configuration. A client MAY be explicitly configured with an endpoint location by other means (e.g. a command-line flag or configuration file). When present, this takes precedence over the environment.
2. `SPIFFE_ENDPOINT`. If not explicitly configured, the client MUST use the `SPIFFE_ENDPOINT` environment variable, interpreted as described in [Section 2](#2-the-spiffe_endpoint-environment-variable).
3. `SPIFFE_ENDPOINT_SOCKET`. If `SPIFFE_ENDPOINT` is unset or empty, the client MUST fall back to the deprecated `SPIFFE_ENDPOINT_SOCKET` variable, whose value and permitted schemes are defined by the [SPIFFE Workload Endpoint](SPIFFE_Workload_Endpoint.md) specification.

If both `SPIFFE_ENDPOINT` and `SPIFFE_ENDPOINT_SOCKET` are set, `SPIFFE_ENDPOINT` MUST take precedence and `SPIFFE_ENDPOINT_SOCKET` MUST be ignored.

## 4. Deprecation of SPIFFE_ENDPOINT_SOCKET

The `SPIFFE_ENDPOINT_SOCKET` environment variable is deprecated in favor of `SPIFFE_ENDPOINT`.

Producers of the environment (such as SPIFFE agents, launchers, and orchestrators) SHOULD set `SPIFFE_ENDPOINT`. To preserve interoperability with clients that predate this specification, producers MAY continue to set `SPIFFE_ENDPOINT_SOCKET` in parallel where its schemes are sufficient to express the intended endpoint.

Clients MUST continue to honor `SPIFFE_ENDPOINT_SOCKET` as described in [Section 3](#3-client-behavior-and-precedence) for backward compatibility if they support the SPIFFE Workload API. `SPIFFE_ENDPOINT_SOCKET` is limited to the schemes defined for it by the SPIFFE Workload Endpoint specification and cannot express mechanisms introduced through the extensible scheme registry of `SPIFFE_ENDPOINT`.

## 5. Relationship to Other Specifications

This document defines only how a client discovers and selects an endpoint. It does not define what any mechanism does once selected.

