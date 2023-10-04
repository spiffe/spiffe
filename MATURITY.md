# SPIFFE Project Maturity Phases
SPIFFE comprises a handful of software projects, all of which share a common governance structure. As these projects may vary in their respective levels of maturity, it is important for SPIFFE/SPIRE users to have a strong sense of what to expect prior to adopting or deploying them.

This document provides detailed information about the maturity phases of the various projects that are part of the overarching [SPIFFE project](https://github.com/spiffe).

To be considered as a new SPIFFE project, see instructions at [NEW_PROJECTS](/NEW_PROJECTS.md).

The SPIFFE project maintains three phases of maturity which indicate the level of reliability and scale at which a particular project or sub-project is known to support:
- **Development**: The software is still under active development, and many efforts are exploratory. APIs and interfaces may change rapidly and without warning. Use this software for development and proof of concept purposes, but stability and longevity is not guaranteed.
- **Pre-Production**: The software is relatively stable and being used to solve real problems. APIs and interfaces may change, but effort will be made to consider compatibility. Use this software for integration investigation and technology evaluation. Some early adopters may choose to run this software in production, however it is not recommended. Deprecation of this software is unlikely.
- **Production**: The software is stable and being used in production at scale. APIs and interfaces have compatibility guarantees. Use of this software is safe for mission critical purposes. Deprecation of this software will be performed on a years-long time scale.
- **Deprecated**: The software is no longer maintained, and may or may not continue to fill its intended purpose. While API stability is assumed due to lack of development, compatibility with other components is not guaranteed and likely to break in due time. Use of this software is not recommended.

## Changing the Maturity of a SPIFFE Project
When a project is ready to change its maturity level, one of its maintainers raises a PR against it to update the documented level and/or maturity badge. This PR must tag the SSC and remain open for a minimum of two weeks, during which time anyone is welcome to ask questions or object. Any difficult questions or objections are raised to the next regularly scheduled SSC call for discussion.

To merge the PR and effect the change of maturity level, the PR must be approved by at least two active SSC members.

---

## Development [![Development Phase](https://github.com/spiffe/spiffe/blob/main/.img/maturity/dev.svg)](https://github.com/spiffe/spiffe/blob/main/MATURITY.md#development)

### Description
Software in the **Development** phase is being actively developed by the SPIFFE community, and is still in its infancy. The primary audience of this software is developers and technology enthusiasts.

### Characteristics
Characteristics of software in the Development phase:

- Apache 2 licensed
- Rapidly evolving (days-to-weeks)
- No compatibility guarantee (or by extension, upgrade guarantee)
- Supported by developers actively working on the software
- Basic documentation (e.g. a README.md file) has been written, and includes:
  - A clear indication that it is in the **Development** phase
  - Description of its covered use cases
  - Supported versions of relevant components (e.g. supported SPIRE versions, etc)
  - Known limitations

## Pre-Production [![Pre-Production Phase](https://github.com/spiffe/spiffe/blob/main/.img/maturity/pre-prod.svg)](https://github.com/spiffe/spiffe/blob/main/MATURITY.md#pre-production)

### Description
Software in the **Pre-Production** phase is still under active development by the SPIFFE community, but is relatively stable and has entered into a more mature phase than software still in the **Development** phase.

### Characteristics
Characteristics of software in the **Pre-Production** phase:

- Apache 2 licensed
- Moderate velocity (weeks-to-month)
- Best effort compatibility guarantee
- A comprehensive set of examples is available
- Automated test suites are exercised regularly
- Pre-built artifacts are published and made publicly available
- Supported by both developers and early adopter community
- A security policy is clearly defined (i.e. SECURITY.md)
  - A security contact must be specified
  - A response time must be specified
- Software has been fully documented and includes:
  - A clear indication that it is in the **Pre-Production** phase
  - Supported versions of relevant components (e.g. supported SPIRE versions, etc)
  - Known limitations
  - Basic troubleshooting
  - API documentation

## Production [![Production Phase](https://github.com/spiffe/spiffe/blob/main/.img/maturity/prod.svg)](https://github.com/spiffe/spiffe/blob/main/MATURITY.md#production)

### Description
Software in the **Production** phase is stable and actively maintained. It can be relied upon to operate in production and at scale.

### Characteristics
Characteristics of software in the **Production** phase:

- Apache 2 licensed
- Moderate to low velocity (month-to-months)
- Well tested via unit, functional, and integration test suites on multiple platforms (when applicable)
- Strict compatibility guarantees are in place and upgrade/compatibility guidance is published
- Pre-built artifacts are published by an automated system for multiple platforms (when applicable)
- Supported by maintainers and a broad community of adopters
- A security policy and response process is clearly defined and includes:
  - Acknowledgement time of less than seven days
- ADOPTERS.md file is present
- Software documentation is complete and includes:
  - A clear indication that it is in the **Production** phase
  - Working examples exercised by automated test suites
  - Known bugs
  - Comprehensive troubleshooting guide(s)
  - Complete API documentation
  - Architecture and deployment guidelines

## Deprecated [![Deprecated Phase](https://github.com/spiffe/spiffe/blob/main/.img/maturity/deprecated.svg)](https://github.com/spiffe/spiffe/blob/main/MATURITY.md#deprecated)

### Description
Software in the **Deprecated** phase is no longer actively developed. Emergency releases may occur in response to security issues on a case-by-case basis, however such maintenance should not be expected. Do not adopt this software.

### Characteristics
Characteristics of software in the **Deprecated** phase:

- A clear indication in the documentation that it is in the **Deprecated** phase
- Apache 2 licensed
- Zero velocity
- Not tested or exercised in any official capacity
- Likely to be removed from GitHub in the near future
