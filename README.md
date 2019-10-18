![SPIFFE Logo](https://github.com/spiffe/spiffe/blob/master/community/logo/256x1024.png?raw=true)


The Secure Production Identity Framework For Everyone (SPIFFE) Project defines a framework and set of
standards for identifying and securing communications between web-based services. At its heart, SPIFFE is:

* A standard defining how services identify themselves to each other. These are called *SPIFFE IDs* and are implemented as [Uniform Resource Identifiers (URIs)](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier).

* A standard for encoding SPIFFE IDs in a cryptographically-verifiable document called a SPIFFE Verifiable Identity Document or *SVIDs*.

* An API specification for issuing and/or retrieving SVIDs. This is the *Workload API*.

The SPIFFE Project is also producing a reference implementation that, in addition to the above, will:

* Perform node and workload attestation.
* Implement a signing framework for securely issuing and renewing SVIDs.
* Provide an API for registering nodes and workloads, along with their designated SPIFFE IDs.

SPIFFE is hosted by the [Cloud Native Computing Foundation](https://cncf.io) (CNCF) as a sandbox level project. If you are an organization that wants to help shape the evolution of technologies that are container-packaged, dynamically-scheduled and microservices-oriented, consider joining the CNCF. For details read the CNCF [announcement](https://www.cncf.io/blog/2018/03/29/cncf-to-host-the-spiffe-project/).

## SPIFFE Standards

* [Secure Production Infrastructure Framework for Everyone (SPIFFE)](standards/SPIFFE.md)
* [The SPIFFE Identity and Verifiable Identity Document](standards/SPIFFE-ID.md)
* [The X.509 SPIFFE Verifiable Identity Document](standards/X509-SVID.md)
* [The JWT SPIFFE Verifiable Identity Document](standards/JWT-SVID.md)
* [The SPIFFE Trust Domain and Bundle](standards/SPIFFE_Trust_Domain_and_Bundle.md)
* [The SPIFFE Workload Endpoint](standards/SPIFFE_Workload_Endpoint.md)
* [The SPIFFE Workload API](standards/SPIFFE_Workload_API.md)

## Getting Started

* [spiffe](https://github.com/spiffe/spiffe): This repository includes the SPIFFE ID, SVID and Workload API specifications, example code, and tests, as well as project governance, policies, and processes.    
* [spire](https://github.com/spiffe/spire): This is a reference implementation of SPIFFE and the SPIFFE Workload API that can be run on and across varying hosting environments.
* [go-spiffe](https://github.com/spiffe/go-spiffe): Golang client libraries.

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

| Name | Leads | Group | Slack Channel | Meetings |
|:------:|:-------:|:-------:|:---------------:|:----------:|
| [Components](/community/sig-components/README.md) | [Oliver Liu](https://github.com/myidpt) (Google, Inc.)  | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-components) | [Here](https://spiffe.slack.com/messages/sig-components/) |[Notes](https://goo.gl/eCDKva) |
| [Integration: AWS](/community/sig-integration-aws/README.md) | [Jon Debonis](https://www.linkedin.com/in/jondb) (Blend, Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-integration-aws) | [Here](https://spiffe.slack.com/messages/sig-integration-aws/) | [Notes](https://docs.google.com/document/d/1-QPtuC1_JHNCu6zSrQhbpX_MmNZFXtbU4uNEB-UVH8k) |
| [Integration: gRPC](/community/sig-integration-grpc/README.md) | [Lizan Zhou](https://github.com/lizan) (Google, Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-integration-grpc) | [Here](https://spiffe.slack.com/messages/sig-integration-grpc/) | [Notes](https://docs.google.com/document/d/1wzW59UUn-7LJo-IGoo7es-I7bovmVC8sa0nGb1e8wLM) |
| [Integration: Kubernetes](/community/sig-integration-k8s/README.md) | [Vipin Jain](https://github.com/jainvipin) (Pensando, Inc.) & [Tao Li](https://github.com/wattli) (Google, Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-integration-k8s) | [Here](https://spiffe.slack.com/messages/sig-integration-k8s) | [Notes](https://docs.google.com/document/d/1Dq4kSlfOpewnisItipTWx3Q8qCelbNP85yjMnSrdomE) |
| [Specification](/community/sig-spec/README.md) | [Evan Gilman](https://github.com/evan2645) (Scytale, Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-specification) | [Here](https://spiffe.slack.com/messages/sig-spec) | [Notes](https://docs.google.com/document/d/1p2BbRWN_7z6nkBMj-h1mAJAJxxKqNeFiV4IplZ_wU4c) |

**Follow the SPIFFE Project** You can find us on [Github](https://github.com/spiffe/) and [Twitter](https://twitter.com/SPIFFEio).
