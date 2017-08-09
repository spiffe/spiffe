# What is SPIFFE?

The Secure Production Identity Framework For Everyone (SPIFFE) is a new set of protocols and
conventions for identifying and securing communications between services. At its heart, SPIFFE is:

* An standard for how services identify themselves to each other. These are called *SPIFFE IDs* and
  are implemented as URIs.

* An standard for encoding SPIFFE IDs in the Subject Alternative Name (SAN) field of x.509
  certificates. These certificates are called SPIFFE Verifiable Service Identity Documents or
  *SVIDs*

* An API specification for signing SVIDs. This is the *Workload API*

In addition, the SPIFFE project is producing a reference implementation that, in addition to the
above, will securely issue and frequently renew SVIDs.

# The Project

## The Design

* The SVID specification
* The workload API


## Explore

* [spiffe](https://github.com/spiffe/spiffe) - This repository includes the SPIFFE, SVID, and
  Workload API specification, example code, and tests as well as project governance, policies, and
  processes    
* [spiffe-ri](https://github.com/spiffe/spiffe-ri) - The SPIFFE Reference Implementation
* [spiffe-examples](https://github.com/spiffe/spiffe-examples) - Examples and demonstrations
* [go-spiffe](https://github.com/spiffe/go-spiffe) - Golang client libraries


## Communicate

  * [Slack](https://spiffe.slack.com) (Join [here](https://slack.spiffe.io))
  * <dev-discussion@spiffe.io> (View or join
    [here](https://groups.google.com/a/spiffe.io/forum/#!forum/dev-discussion)).
  * <user-discussion@spiffe.io> (View or join
    [here](https://groups.google.com/a/spiffe.io/forum/#!forum/user-discussion)).


## Contribute

* [CONTRIBUTING](/CONTRIBUTING.md)
* [GOVERNANCE](/GOVERNANCE.md)


#### SIGs & Working Groups<a name="sigs"></a>

Most community activity is organized into Special Interest Groups (SIGs), time-bounded Working
Groups, and the community meeting. SIGs follow these [guidelines](GOVERNANCE.md#sigs), although each
may operate differently depending on their needs and workflows. Each group's material can be found
in the [/sigs](/sigs) directory of this repository.

| Name | Leads | Group | Slack Channel | Meetings |
|:------:|:-------:|:-------:|:---------------:|:----------:|
| [Certificate Format](/community/sig-cert-format/README.md) | [Diogo Mónica](https://github.com/diogomonica) (Docker Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-cert-format) | [Here](https://spiffe.slack.com/messages/sig-cert-format/) | [Agenda](https://docs.google.com/document/d/1pSUGC4Ye0Mfq3sM7PTkVnLqzR8I671Na82LTDF_zLrU/edit) |
| [Components](/community/sig-components/README.md) | [Oliver Liu](https://github.com/myidpt) (Google Inc.)  | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-components) | [Here](https://spiffe.slack.com/messages/sig-components/) |[Agenda](https://docs.google.com/document/d/1XXfXPYKw05LiXhM2Z-chT-NCet4hjiHg0jh872IPONE/edit) |
| [Integration: AWS](/community/sig-integration-aws/README.md) | [Jon Debonis](https://www.linkedin.com/in/jondb) (Blend Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-integration-aws) | [Here](https://spiffe.slack.com/messages/sig-integration-aws/) | TBD by Leads |
| [Integration: Docker Swarm](/community/sig-integration-swarm/README.md) | [Diogo Mónica](https://github.com/diogomonica) (Docker Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-integration-swarm) | [Here](https://spiffe.slack.com/messages/sig-integration-swarm) | TBD by Leads |
| [Integration: gRPC](/community/sig-integration-grpc/README.md) | [Lizan Zhou](https://github.com/lizan) (Google Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-integration-grpc) | [Here](https://spiffe.slack.com/messages/sig-integration-grpc/) | TBD by Leads |
| [Integration: Kubernetes](/community/sig-integration-k8s/README.md) | [Vipin Jain](https://github.com/jainvipin) (Independent), [Tao Li](https://github.com/wattli) (Google Inc.) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-integration-k8s) | [Here](https://spiffe.slack.com/messages/sig-integration-k8s) | [Agenda](https://docs.google.com/document/d/1Dq4kSlfOpewnisItipTWx3Q8qCelbNP85yjMnSrdomE/edit) |


**Follow SPIFFE** You can find us on [Github](https://github.com/spiffe/) and
  [Twitter](https://twitter.com/SPIFFEio)
