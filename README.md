![SPIFFE Logo](https://github.com/spiffe/spiffe/blob/main/community/logo/256x1024.png?raw=true)




[![Production Phase](https://img.shields.io/badge/SPIFFE-Prod-green.svg?logoWidth=18&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHJvbGU9ImltZyIgdmlld0JveD0iMC4xMSAxLjg2IDM1OC4yOCAzNTguMjgiPjxzdHlsZT5zdmcge2VuYWJsZS1iYWNrZ3JvdW5kOm5ldyAwIDAgMzYwIDM2MH08L3N0eWxlPjxzdHlsZT4uc3QyLC5zdDN7ZmlsbC1ydWxlOmV2ZW5vZGQ7Y2xpcC1ydWxlOmV2ZW5vZGQ7ZmlsbDojYmNkOTE4fS5zdDN7ZmlsbDojMDRiZGQ5fTwvc3R5bGU+PGcgaWQ9IkxPR08iPjxwYXRoIGQ9Ik0xMi4xIDguOWgyOC4zYzIuNyAwIDUgMi4yIDUgNXYyOC4zYzAgMi43LTIuMiA1LTUgNUgxMi4xYy0yLjcgMC01LTIuMi01LTVWMTMuOWMuMS0yLjcgMi4zLTUgNS01eiIgY2xhc3M9InN0MiIvPjxwYXRoIGQ9Ik04OC43IDguOWgyNThjMi43IDAgNSAyLjIgNSA1djI4LjNjMCAyLjctMi4yIDUtNSA1aC0yNThjLTIuNyAwLTUtMi4yLTUtNVYxMy45YzAtMi43IDIuMi01IDUtNXoiIGNsYXNzPSJzdDMiLz48cGF0aCBkPSJNMzQ2LjcgODUuNWgtMjguM2MtMi43IDAtNSAyLjItNSA1djI4LjNjMCAyLjggMi4yIDUgNSA1aDI4LjNjMi43IDAgNS0yLjIgNS01VjkwLjVjMC0yLjgtMi4zLTUtNS01eiIgY2xhc3M9InN0MiIvPjxwYXRoIGQ9Ik0xOTMuNiA4NS41SDEyLjFjLTIuNyAwLTUgMi4zLTUgNXYyOC4zYzAgMi43IDIuMiA1IDUgNWgxODEuNWMyLjcgMCA1LTIuMiA1LTVWOTAuNWMwLTIuOC0yLjItNS01LTV6IiBjbGFzcz0ic3QzIi8+PHBhdGggZD0iTTI3MC4yIDg1LjVoLTI4LjNjLTIuNyAwLTUgMi4yLTUgNXYyOC4zYzAgMi44IDIuMiA1IDUgNWgyOC4zYzIuNyAwIDUtMi4yIDUtNVY5MC41Yy0uMS0yLjgtMi4zLTUtNS01eiIgY2xhc3M9InN0MiIvPjxwYXRoIGQ9Ik0yNzAuMiAxNjJIODguN2MtMi43IDAtNSAyLjItNSA1djI4LjNjMCAyLjcgMi4yIDUgNSA1aDE4MS41YzIuNyAwIDUtMi4yIDUtNVYxNjdjLS4xLTIuOC0yLjMtNS01LTV6IiBjbGFzcz0ic3QzIi8+PHBhdGggZD0iTTM0Ni43IDE2MmgtMjguM2MtMi43IDAtNSAyLjItNSA1djI4LjNjMCAyLjggMi4yIDUgNSA1aDI4LjNjMi43IDAgNS0yLjIgNS01VjE2N2MwLTIuOC0yLjMtNS01LTV6bS0zMDYuMyAwSDEyLjFjLTIuNyAwLTUgMi4yLTUgNXYyOC4zYzAgMi44IDIuMiA1IDUgNWgyOC4zYzIuNyAwIDUtMi4yIDUtNVYxNjdjMC0yLjgtMi4yLTUtNS01em0tMjguMyA3Ni41aDI4LjNjMi43IDAgNSAyLjIgNSA1djI4LjNjMCAyLjctMi4yIDUtNSA1SDEyLjFjLTIuNyAwLTUtMi4yLTUtNXYtMjguM2MuMS0yLjcgMi4zLTUgNS01eiIgY2xhc3M9InN0MiIvPjxwYXRoIGQ9Ik0xNjUuMiAyMzguNWgxODEuNWMyLjcgMCA1IDIuMiA1IDV2MjguM2MwIDIuNy0yLjIgNS01IDVIMTY1LjJjLTIuNyAwLTUtMi4yLTUtNXYtMjguM2MwLTIuNyAyLjItNSA1LTV6IiBjbGFzcz0ic3QzIi8+PHBhdGggZD0iTTg4LjcgMjM4LjVIMTE3YzIuNyAwIDUgMi4yIDUgNXYyOC4zYzAgMi43LTIuMiA1LTUgNUg4OC43Yy0yLjcgMC01LTIuMi01LTV2LTI4LjNjMC0yLjcgMi4yLTUgNS01em0yNTggNzYuN2gtMjguM2MtMi43IDAtNSAyLjItNSA1djI4LjNjMCAyLjggMi4yIDUgNSA1aDI4LjNjMi43IDAgNS0yLjIgNS01di0yOC4zYzAtMi44LTIuMy01LTUtNXoiIGNsYXNzPSJzdDIiLz48cGF0aCBkPSJNMjcwLjIgMzE1LjJoLTI1OGMtMi43IDAtNSAyLjItNSA1djI4LjNjMCAyLjcgMi4yIDUgNSA1aDI1OGMyLjcgMCA1LTIuMiA1LTV2LTI4LjNjLS4xLTIuOC0yLjMtNS01LTV6IiBjbGFzcz0ic3QzIi8+PC9nPjwvc3ZnPg==)](https://github.com/spiffe/spiffe/blob/main/MATURITY.md#production)


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

SPIFFE is hosted by the [Cloud Native Computing Foundation](https://cncf.io) (CNCF) as an incubation-level project. If you are an organization that wants to help shape the evolution of technologies that are container-packaged, dynamically-scheduled and microservices-oriented, consider joining the CNCF. For details read the CNCF [announcement](https://www.cncf.io/blog/2020/06/22/toc-approves-spiffe-and-spire-to-incubation/).

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
| [SIG-Spec](/community/sig-spec/README.md) | [Evan Gilman](https://github.com/evan2645) (VMware) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-specification) | [Here](https://spiffe.slack.com/messages/sig-spec) | [Notes](https://docs.google.com/document/d/1p2BbRWN_7z6nkBMj-h1mAJAJxxKqNeFiV4IplZ_wU4c) |
| [SIG-SPIRE](/community/sig-spire/README.md) | [Daniel Feldman](https://github.com/dfeldman) (HPE) | [Here](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-spire) | [Here](https://spiffe.slack.com/messages/spire) | [Notes](https://docs.google.com/document/d/1IgpCkvSRSoY9Xd16gFQJJ1KP8sLZ7EE39cEjBK_UIg4) |

**Follow the SPIFFE Project** You can find us on [Github](https://github.com/spiffe/) and [Twitter](https://twitter.com/SPIFFEio).

## SPIFFE SSC
The [SPIFFE Steering Committee](/GOVERNANCE.md#the-spiffe-steering-committee-ssc) meets on a regular cadence to review project progress, address maintainer needs, and provide feedback on strategic direction and industry trends. Community members interested in joining this call can find details below.

* Calendar: [iCal](https://calendar.google.com/calendar/ical/c_gck7v87m9obq6n3hpo01l7csus%40group.calendar.google.com/public/basic.ics) or [Browser-based](https://calendar.google.com/calendar/embed?src=c_gck7v87m9obq6n3hpo01l7csus%40group.calendar.google.com&ctz=America%2FChicago)
* Meeting Notes: [Google Doc](https://docs.google.com/document/d/14YlmMTqwqNdx-CWapwwIBMaakH5Z2UnAvOBQBB8AwQM)
* Call Details: [Zoom Link](https://zoom.us/j/95959131216?pwd=akw4RzlEUEVCTnFkWE5KdWFPZXpkdz09)

To contact the SSC privately, please send an email to [ssc@spiffe.io](mailto:ssc@spiffe.io).
