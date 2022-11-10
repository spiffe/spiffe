![SPIFFE Logo](https://github.com/spiffe/spiffe/blob/main/community/logo/256x1024.png?raw=true)




[![Production Phase](https://github.com/spiffe/spiffe/blob/main/.img/maturity/prod.svg)](https://github.com/spiffe/spiffe/blob/main/MATURITY.md#production)

The Secure Production Identity Framework For Everyone (SPIFFE) Project defines a framework and set of
standards for identifying and securing communications between application services. At its core, SPIFFE is:

* A standard defining how services identify themselves to each other. These are called *SPIFFE IDs* and are implemented as [Uniform Resource Identifiers (URIs)](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier).

* A standard for encoding SPIFFE IDs in a cryptographically-verifiable document called a SPIFFE Verifiable Identity Document or *SVIDs*.

* An API specification for issuing and/or retrieving SVIDs. This is the *Workload API*.

The SPIFFE Project has a reference implementation, the SPIRE (the SPIFFE Runtime Environment), that in addition to the above, it:

* Performs node and workload attestation.

* Implements a signing framework for securely issuing and renewing SVIDs.

* Provides an API for registering nodes and workloads, along with their designated SPIFFE IDs.

* Provides and manages the rotation of keys and certs for mutual authentication and encryption between workloads.

* Simplifies access from identified services to secret stores, databases, services meshes and cloud provider services.

* Interoperability and federation to SPIFFE compatible systems across heterogeneous environments and administrative trust boundaries.


SPIFFE is a [graduated](https://www.cncf.io/projects/spiffe/) project of the [Cloud Native Computing Foundation](https://cncf.io) (CNCF). If you are an organization that wants to help shape the evolution of technologies that are container-packaged, dynamically-scheduled and microservices-oriented, consider joining the CNCF.

## SPIFFE Standards

* [Secure Production Identity Framework for Everyone (SPIFFE)](standards/SPIFFE.md)
* [The SPIFFE Identity and Verifiable Identity Document](standards/SPIFFE-ID.md)
* [The X.509 SPIFFE Verifiable Identity Document](standards/X509-SVID.md)
* [The JWT SPIFFE Verifiable Identity Document](standards/JWT-SVID.md)
* [The SPIFFE Trust Domain and Bundle](standards/SPIFFE_Trust_Domain_and_Bundle.md)
* [The SPIFFE Workload Endpoint](standards/SPIFFE_Workload_Endpoint.md)
* [The SPIFFE Workload API](standards/SPIFFE_Workload_API.md)
* [SPIFFE Federation](standards/SPIFFE_Federation.md)

## Getting Started

* [spiffe](https://github.com/spiffe/spiffe): This repository includes the SPIFFE ID, SVID and Workload API specifications, example code, and tests, as well as project governance, policies, and processes.    
* [spire](https://github.com/spiffe/spire): This is a reference implementation of SPIFFE and the SPIFFE Workload API that can be run on and across varying hosting environments.
* [go-spiffe](https://github.com/spiffe/go-spiffe/tree/main/v2): Golang client libraries.
* [java-spiffe](https://github.com/spiffe/java-spiffe): Java client libraries

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
| [SIG-Community](/community/sig-community/README.md) | [Umair Khan](https://github.com/umairmkhan) (HPE) | [Here](https://groups.google.com/a/spiffe.io/g/sig-community) | [Here](https://spiffe.slack.com/messages/community) | [Notes](https://docs.google.com/document/d/1tb3lxubwr8IKRd6Smnl83ur14xkOQdjwQqla9OHjwZo) |
| [SIG-Spec](/community/sig-spec/README.md) | [Evan Gilman](https://github.com/evan2645) (VMware) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-specification) | [Here](https://spiffe.slack.com/messages/sig-spec) | [Notes](https://docs.google.com/document/d/1f64vbyn5sOb8Mr1H3mGGGul3vTKo4r6cTBcUV3N9OFo) |
| [SIG-SPIRE](/community/sig-spire/README.md) | [Daniel Feldman](https://github.com/dfeldman) (HPE) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-spire) | [Here](https://spiffe.slack.com/messages/spire) | [Notes](https://docs.google.com/document/d/1IgpCkvSRSoY9Xd16gFQJJ1KP8sLZ7EE39cEjBK_UIg4) |

**Follow the SPIFFE Project** You can find us on [Github](https://github.com/spiffe/) and [Twitter](https://twitter.com/SPIFFEio).

## SPIFFE SSC
The [SPIFFE Steering Committee](/GOVERNANCE.md#the-spiffe-steering-committee-ssc) meets on a regular cadence to review project progress, address maintainer needs, and provide feedback on strategic direction and industry trends. Community members interested in joining this call can find details below.

* Calendar: [iCal](https://calendar.google.com/calendar/ical/c_gck7v87m9obq6n3hpo01l7csus%40group.calendar.google.com/public/basic.ics) or [Browser-based](https://calendar.google.com/calendar/embed?src=c_gck7v87m9obq6n3hpo01l7csus%40group.calendar.google.com&ctz=America%2FChicago)
* Meeting Notes: [Google Doc](https://docs.google.com/document/d/14YlmMTqwqNdx-CWapwwIBMaakH5Z2UnAvOBQBB8AwQM)
* Call Details: [Zoom Link](https://zoom.us/j/95959131216?pwd=akw4RzlEUEVCTnFkWE5KdWFPZXpkdz09)

To contact the SSC privately, please send an email to [ssc@spiffe.io](mailto:ssc@spiffe.io).
