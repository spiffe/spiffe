# SIG Integration Swarm

A Special Interest Group for running SPIFFE-enabled workloads in a Docker Swarm environment.

### Meetings:
* Meetings: TBD
* [Meetings Notes](https://todo.com)
* [Calendar](https://calendar.google.com/calendar/todo)

### Contact:
* [Slack Channel (SPIFFE)](https://spiffe.slack.com/messages/sig-integration-swarm/)
* [Slack Channel (Docker)](https://dockercommunity.slack.com/messages/docker-security/)
* [Google Group](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-integration-swarm)

### Goals:
* Ability to easily create and manage distinct service-level PKIs in a Swarm.
* Automatic issuance of TLS certificates for running services in desired PKIs.
* Automatic rotation of TLS certificates that will expire using Swarm’s rolling deploys.
* Ability to manage the roots of trust for each Swarm service.
* Generation of a stable service ID scheme (based on SPIFFE) for services deployed through Swarm that can be used for service-to-service authentication.
* Integration with 3rd party certificate authorities.

### Non Goals:
* An ACL for granular service-to-service authorization.
* A higher-level framework that allows for complex authorization around which particular endpoints a remote peer is allowed to call.

### Current Design Documents & Background Reading:
* [Service Identities in Docker](https://docs.google.com/document/d/117lKj_VxYa2UvVhx_md51ldjziU_1J1gYKJlGc1Ncrg/edit)
* [Secure Secrets Delivery in Swarm](https://docs.docker.com/engine/swarm/secrets/)
* [Secure Swarm Lock/Unlock](https://docs.docker.com/engine/swarm/secrets/)

### Leads:
* Diogo Monica (diogo@docker.com)
* Nathan McCauley (nathan.mccauley@docker.com)
