![SPIFFE Logo](https://github.com/spiffe/spiffe/blob/master/community/logo/256x1024.png?raw=true)


The Secure Production Identity Framework For Everyone (SPIFFE) Project defines a framework and set of
standards for identifying and securing communications between application services. At its core, SPIFFE is:

* A standard defining how services identify themselves to each other. These are called *SPIFFE IDs* and are implemented as [Uniform Resource Identifiers (URIs)](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier).

* A standard for encoding SPIFFE IDs in a cryptographically-verifiable document called a SPIFFE Verifiable Identity Document or *SVIDs*.

* An API specification for issuing and/or retrieving SVIDs. This is the *Workload API*.

The SPIFFE Project has a reference implementation, the SPIRE (the SPIFFE Runtime Environment), that, in addition to the above, it:

* Performs node and workload attestation.
* Implements a signing framework for securely issuing and renewing SVIDs.
* Provides an API for registering nodes and workloads, along with their designated SPIFFE IDs.
* Provides and manages the rotation of keys and certs for mutual authentication and encryption between workloads.
* Simplifies access from identified services to secret stores, databases, services meshes and cloud provider services.
* Interoperability and federation to SPIFFE compatible systems across heterogeneous environments and administrative trust boundaries.

SPIFFE is hosted by the [Cloud Native Computing Foundation](https://cncf.io) (CNCF) as an incubation-level project. If you are an organization that wants to help shape the evolution of technologies that are container-packaged, dynamically-scheduled and microservices-oriented, consider joining the CNCF. For details read the CNCF [announcement](https://www.cncf.io/blog/2020/06/22/toc-approves-spiffe-and-spire-to-incubation/).

## SPIFFE Standards

* [Secure Production Identity Framework for Everyone (SPIFFE)](standards/SPIFFE.md)
* [The SPIFFE Identity and Verifiable Identity Document](standards/SPIFFE-ID.md)
* [The X.509 SPIFFE Verifiable Identity Document](standards/X509-SVID.md)
* [The JWT SPIFFE Verifiable Identity Document](standards/JWT-SVID.md)
* [The SPIFFE Trust Domain and Bundle](standards/SPIFFE_Trust_Domain_and_Bundle.md)
* [The SPIFFE Workload Endpoint](standards/SPIFFE_Workload_Endpoint.md)
* [The SPIFFE Workload API](standards/SPIFFE_Workload_API.md)

## Getting Started

* [spiffe](https://github.com/spiffe/spiffe): This repository includes the SPIFFE ID, SVID and Workload API specifications, example code, and tests, as well as project governance, policies, and processes.    
* [spire](https://github.com/spiffe/spire): This is a reference implementation of SPIFFE and the SPIFFE Workload API that can be run on and across varying hosting environments.
* [go-spiffe](https://github.com/spiffe/go-spiffe/tree/master/v2): Golang client libraries.
* [java-spiffe](https://github.com/spiffe/java-spiffe/tree/v2-api): Java client libraries

### Communications

  * [Slack](https://spiffe.slack.com) (Join [here](https://slack.spiffe.io)).
  * <announce@spiffe.io> (View or join [here](https://groups.google.com/a/spiffe.io/forum/#!forum/announce)).
  * <dev-discussion@spiffe.io> (View or join [here](https://groups.google.com/a/spiffe.io/forum/#!forum/dev-discussion)).
  * <user-discussion@spiffe.io> (View or join [here](https://groups.google.com/a/spiffe.io/forum/#!forum/user-discussion)).

### Contribute

* [CONTRIBUTING](/CONTRIBUTING.md)
* [GOVERNANCE](/GOVERNANCE.md)

### SIGs & Working Groups<a name="sigs"></a>

Most community activity is organized into Special Interest Groups (SIGs), time-bounded working groups, and our monthly community-wide meetings. SIGs follow these [guidelines](GOVERNANCE.md#special-interest-groups-sigs), although each may operate differently depending on their needs and workflows. Each group's material can be found in the [/community](/community) directory of this repository.

| Name | Lead | Group | Slack Channel | Meetings |
|:------:|:-------:|:-------:|:---------------:|:----------:|
| [Specification](/community/sig-spec/README.md) | [Evan Gilman](https://github.com/evan2645) (Scytale, Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-specification) | [Here](https://spiffe.slack.com/messages/sig-spec) | [Notes](https://docs.google.com/document/d/1p2BbRWN_7z6nkBMj-h1mAJAJxxKqNeFiV4IplZ_wU4c) |

**Follow the SPIFFE Project** You can find us on [Github](https://github.com/spiffe/) and [Twitter](https://twitter.com/SPIFFEio).
