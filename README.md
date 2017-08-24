<img src="community/logo/64x256.png" width="256" height="64">

## About SPIFFE

The Secure Production Identity Framework For Everyone (SPIFFE) Project defines a framework and set of
standards for identifying and securing communications between web-based services. At its heart, SPIFFE is:

* A standard defining how services identify themselves to each other. These are called *SPIFFE IDs* and are implemented as [Uniform Resource Identifiers (URIs)](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier).

* A standard for encoding SPIFFE IDs in a cryptographically-verifiable document called a SPIFFE Verifiable Identity Document or *SVIDs*.

* An API specification for issuing and/or retrieving SVIDs. This is the *Workload API*.

The SPIFFE Project is also producing a reference implementation that, in addition to the above, will:

* Perform node and workload attestation.
* Implement a signing framework for securely issuing and renewing SVIDs.
* Provide an API for registering nodes and workloads, along with their designated SPIFFE IDs.

## SPIFFE Standards

* [Secure Production Infrastructure Framework for Everyone (SPIFFE)](standards/SPIFFE.md)
* [The SPIFFE Identity and Verifiable Identity Document](standards/SPIFFE-ID.md)
* [The X.509 SPIFFE Verifiable Identity Document](standards/X509-SVID.md)
* The Workload API (TBD)

## Getting Started

* [spiffe](https://github.com/spiffe/spiffe): This repository includes the SPIFFE ID, SVID and Workload API specifications, example code, and tests, as well as project governance, policies, and processes.    
* [sri](https://github.com/spiffe/sri): This details a reference implementation of the SPIFFE Workload API that can be run on and accross varying hosting environments.
* [spiffe-examples](https://github.com/spiffe/spiffe-examples): Examples and demonstrations.
* [go-spiffe](https://github.com/spiffe/go-spiffe): Golang client libraries.

### Communications

  * [Slack](https://spiffe.slack.com) (Join [here](https://slack.spiffe.io)).
  * <dev-discussion@spiffe.io> (View or join [here](https://groups.google.com/a/spiffe.io/forum/#!forum/dev-discussion)).
  * <user-discussion@spiffe.io> (View or join [here](https://groups.google.com/a/spiffe.io/forum/#!forum/user-discussion)).

### Contribute

* [CONTRIBUTING](/CONTRIBUTING.md)
* [GOVERNANCE](/GOVERNANCE.md)

### SIGs & Working Groups<a name="sigs"></a>

Most community activity is organized into Special Interest Groups (SIGs), time-bounded working groups, and our monthly community-wide meetings. SIGs follow these [guidelines](GOVERNANCE.md#sigs), although each may operate differently depending on their needs and workflows. Each group's material can be found in the [/sigs](/sigs) directory of this repository.

| Name | Leads | Group | Slack Channel | Meetings |
|:------:|:-------:|:-------:|:---------------:|:----------:|
| [Certificate Format](/community/sig-cert-format/README.md) | [Diogo Mónica](https://github.com/diogomonica) (Docker, Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-cert-format) | [Here](https://spiffe.slack.com/messages/sig-cert-format/) | [Notes](https://docs.google.com/document/d/1pSUGC4Ye0Mfq3sM7PTkVnLqzR8I671Na82LTDF_zLrU) |
| [Components](/community/sig-components/README.md) | [Oliver Liu](https://github.com/myidpt) (Google, Inc.)  | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-components) | [Here](https://spiffe.slack.com/messages/sig-components/) |[Notes](https://docs.google.com/document/d/1XXfXPYKw05LiXhM2Z-chT-NCet4hjiHg0jh872IPONE) |
| [Integration: AWS](/community/sig-integration-aws/README.md) | [Jon Debonis](https://www.linkedin.com/in/jondb) (Blend, Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-integration-aws) | [Here](https://spiffe.slack.com/messages/sig-integration-aws/) | [Notes](https://docs.google.com/document/d/1-QPtuC1_JHNCu6zSrQhbpX_MmNZFXtbU4uNEB-UVH8k) |
| [Integration: Docker Swarm](/community/sig-integration-swarm/README.md) | [Diogo Mónica](https://github.com/diogomonica) (Docker, Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-integration-swarm) | [Here](https://spiffe.slack.com/messages/sig-integration-swarm) | TBD by Leads |
| [Integration: gRPC](/community/sig-integration-grpc/README.md) | [Lizan Zhou](https://github.com/lizan) (Google, Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-integration-grpc) | [Here](https://spiffe.slack.com/messages/sig-integration-grpc/) | [Notes](https://docs.google.com/document/d/1wzW59UUn-7LJo-IGoo7es-I7bovmVC8sa0nGb1e8wLM) |
| [Integration: Kubernetes](/community/sig-integration-k8s/README.md) | [Vipin Jain](https://github.com/jainvipin) (Pensando, Inc.) & [Tao Li](https://github.com/wattli) (Google, Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-integration-k8s) | [Here](https://spiffe.slack.com/messages/sig-integration-k8s) | [Notes](https://docs.google.com/document/d/1Dq4kSlfOpewnisItipTWx3Q8qCelbNP85yjMnSrdomE) |

**Follow the SPIFFE Project** You can find us on [Github](https://github.com/spiffe/) and [Twitter](https://twitter.com/SPIFFEio).
