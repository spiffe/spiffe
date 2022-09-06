The SPIFFE Project succeeds because of an open, inclusive, and respectful community. Ideas and contributions are accepted based on their technical merit and alignment with project objectives, scope, and design principles. This document lists a non-exclusive set of guidelines to help ensure fairness and transparency in managing the SPIFFE Project.

## Code of Conduct

The SPIFFE community abides by the Cloud Native Computing Foundation's [code of conduct](/CODE-OF-CONDUCT.md). An excerpt follows:

> _As contributors and maintainers of this project, and in the interest of fostering an open and
> welcoming community, we pledge to respect all people who contribute through reporting issues,
> posting feature requests, updating documentation, submitting pull requests or patches, and other
> activities._

SPIFFE community members represent the project and their fellow contributors. We value our community tremendously, and we'd like to keep cultivating a friendly and collaborative environment for our contributors and users. We want everyone in the community to have positive experiences.

## Project Roles

### Users

These are individuals who 1) want to learn more about the SPIFFE Project; or 2) are existing users of SPIFFE and its tools who wish to follow the Project's progress. They may have questions, comments, or suggestions that can be communicated via Slack, GitHub, or during community calls and events. They can follow along as the Project's special interest groups (SIGs) do their work.

### Contributors

These are individuals who wish to contribute code or ideas to SPIFFE projects. Contributors submit code and ideas through GitHub or through participation in SPIFFE's community calls.

### Maintainers

These are individuals who can merge submitted PRs into the primary codebase (note: the Project requires PRs be approved by at least one (1) maintainer). Maintainers also adhere to the following:

* They are an active SPIFFE contributor. This includes, but is not limited to, regular attendance of SPIFFE community meetings and SIGs relevant to the components they maintain.
* They respond to PR review requests in a timely manner. Generally, a response is expected within 24 hours of the PR being submitted.
* They ensure that code changes they approve:
  * Meet the [coding conventions](/CONTRIBUTING.md) required by the Project. This includes ensuring the code is sufficiently well tested, follows the appropriate standards, and, of course - does not break the build.  
  * Is consistent with the goals and direction of the Project. This requires not just code and architectural correctness, but also ensuring that it does not introduce "scope creep," and does not unduly affect existing users.
* Once a PR has the requisite approvals, the last approving maintainer is responsible for merging the change (however, the PR's author must ensure the change is merge-ready).

Maintainers are documented in each repository's [CODEOWNERS](https://help.github.com/articles/about-codeowners/) file. To become a maintainer, one must:

* Work in a helpful and collaborative way with the community
* Have a track record of providing constructive feedback on others' PRs
* Have submitted at least 20 PRs themselves

The process for nominating and approving Maintainers is:

* Open a PR against the CODEOWNERS file that covers the parts of the project you wish to nominate someone (or yourself) for
* A consensus of existing Maintainers must approve your PR

### The SPIFFE Steering Committee (SSC)

The SPIFFE Project is governed by the [SSC](https://github.com/spiffe/spiffe/blob/master/ssc/README.md) that is exclusively responsible for SPIFFE's [standards](https://github.com/spiffe/spiffe/tree/master/standards) and the Project's strategic goals and direction. SSC members have final authority over:

* Technical direction of the Project.
* Project governance and process (this document).
* Contribution policy.

The SSC adheres to the following:

* The SSC meets the first Wednesday of each month ([Meeting Notes](https://docs.google.com/document/d/14YlmMTqwqNdx-CWapwwIBMaakH5Z2UnAvOBQBB8AwQM) | [Calendar ICS](https://calendar.google.com/calendar/ical/c_gck7v87m9obq6n3hpo01l7csus%40group.calendar.google.com/public/basic.ics))
* The SSC is comprised of at least five (5) members.
* No more than 2 SSC members may be affiliated with the same organization.
* At least 40% of the SSC must be represented by organizations that currently have a SPIFFE implementation deployed in production.
* Each SSC member's term is 24 months.
* There is no limit to the number of terms an SSC member can serve.
* SSC members may remove themselves voluntarily at any time.

For more information about the SSC, please refer to the [SSC Charter](ssc/CHARTER.md).

## Decision Making

Maintainer and SSC decisions are made by a [lazy consensus](http://rave.apache.org/docs/governance/lazyConsensus.html) approach. When formal voting is required, members may abstain. Negative votes must be accompanied by an explanation or alternative proposal.

## Change Review Process

**All changes must be submitted as a GitHub Pull Request (PR)**

The submitter of a PR is responsible for responding to feedback from reviewers and maintainers. While the PR remains open, they are also responsible for ensuring the change is always in a state where it can be merged. Guidelines for submitting a PR for approval can be found [here](/CONTRIBUTING.md).

**All minor changes must be approved by at least one other Maintainer**

Documentation changes, bugfixes, or other minor changes that do not significantly impact most users must be approved by at least one (1) maintainer.

**All major changes must be approved by at least two (2) other Maintainers**

New or changed functionality require two (2) maintainer approvals.

## Special Interest Groups (SIGs)

The SPIFFE Project has various SIGs that focus on specific parts or features. SIGs provide an avenue for face-to-face discussion of important design changes with key stakeholders. Each SIG is run by a *SIG Lead* who is responsible for the logistics of running the meeting, and for ensuring the group reaches consensus on any issues raised. Active SIGs, their leads, and meeting information are [listed here](/README.md#sigs).

### Responsibilities of the SIG Lead

* Organize regular meetings as necessary, ideally at least for 30 minutes every two weeks.
* Announce meeting agenda and minutes after each meeting on their SIG mailing list.
* Keep up-to-date meeting notes, linked from the SIG's page in the community repository.
* Record SIG meetings and make said recordings publicly available.
* Ensure the SIG's mailing list and Slack channel are archived.
* Report activity in the weekly community meeting at least once every four (4) weeks.
* Use the above forums as the primary means of working, communicating, and collaborating, as opposed to private e-mails and meetings.

To propose a new SIG on a particular topic, [please follow our guidelines](/community/sig-creation-procedure.md).

## License

All software is licensed under the [Apache License version 2.0](https://www.apache.org/licenses/LICENSE-2.0), and all documentation is licensed under the [Creative Commons License version 4.0](https://creativecommons.org/licenses/by/4.0/legalcode).
