SPIFFE as a project succeeds because of an open, inclusive and respectful community. Ideas and
contributions are accepted according to their technical merit and alignment with project
objectives, scope, and design principles.

This document lists a non-exclusive set of guidelines to help ensure fairness and transparency in
managing the SPIFFE project.

## Code of Conduct

The SPIFFE community abides by the CNCF [code of conduct](/CODE-OF-CONDUCT.md). Here is an excerpt:

> _As contributors and maintainers of this project, and in the interest of fostering an open and
> welcoming community, we pledge to respect all people who contribute through reporting issues,
> posting feature requests, updating documentation, submitting pull requests or patches, and other
> activities._

As a member of the SPIFFE project, you represent the project and your fellow contributors. We value
our community tremendously and we'd like to keep cultivating a friendly and collaborative
environment for our contributors and users. We want everyone in the community to have positive
experiences.

## Making changes to SPIFFE

SPIFFE's change management process is designed to be transparent, fair, and efficient. It applies to
all individuals and organizations involved in the project, irrespective of their role or employer.

Anyone may contribute to a projects in the SPIFFE repository that they have read access to,
provided they:

* Abide by the CNCF [code of conduct](/CODE-OF-CONDUCT.md)
* Have accepted the project's [Contributor License Agreement](/CLA.md).

The process is as follows:

**All changes must be submitted as a Github pull request**

The submitter of the pull request is responsible for responding to any feedback from reviewers and
maintainers, and, while the PR remains open, ensuring that the change is in a state where it can be
merged at all times. Guidelines for submitting a pull request for approval can be found in
[CONTRIBUTING](/CONTRIBUTING.md).

**All minor changes must be approved by at least one other Maintainer**

Documentation changes, bugfixes, or other minor changes that don't significantly impact most users
must be approved by one maintainer.

**All major changes must be approved by at least two other Maintainers**

New or changed functionality require two maintainer approvals.


## Maintainers

A SPIFFE Maintainer has a specific set of rights and responsibilities. Maintainers have the ability
to merge changes into the SPIFFE codebase, and at least one maintainer's approval is required on any
pull request for that change to be accepted.

Accordingly, a maintainer also has the following responsibilities:

* They must be an active contributor to the community. This includes, but is not limited to, regular
  attendance of SPIFFE community meetings and Special Interest Groups relevant to the components
  they are a maintainer of.
* They should respond to review requests in a timely manner. Generally, a response is expected
  within 24 hours of a review being submitted.
* They must ensure that any code changes they approve:
  * Meet the [coding conventions](/CONTRIBUTING.md) required by the project. This includes ensuring
    the code is sufficiently well tested, follows the appropriate standards, and of course - doesn't
    break the build.  
  * Is consistent with the goals and direction of the SPIFFE project. This requires not just code
    and architectural correctness, but also ensuring that it does not introduce unnecessary scope
    creep, and does not unduly affect existing users.    
* Once a PR has the relevant approvals, the last approving maintainer bears the responsibility
  of merging the change in (however the author of the PR is expected to ensure the change is
  merge-ready).

Maintainers are documents in each repository's
[CODEOWNERS](https://help.github.com/articles/about-codeowners/)file.

While a formal process for electing and removing maintainers has not yet been defined, in the
meantime reach out to the SPIFFE maintainers at <hello@spiffe.io> if you would like to nominate
yourself as a maintainer.

## Special Interest Groups (SIGs)<a name="sigs"></a>

The SPIFFE project has a number of special interest groups, which are sub-sections of the community
that focus on specific parts of SPIFFE (such as specific integrations).

SIGs provide an avenue for face-to-face discussion of important design changes with key
stakeholders. Each SIG is run by a *SIG Lead*, who is responsible for the logistics of running the
meeting, and for ensuring the group reaches consensus on any issues raised. Active SIGs, their
leads, and meeting information are [listed
here](/README.md#sigs).

#### Responsibilities of the SIG lead

* Organize regular meetings as necessary, ideally at least for 30 minutes every two weeks
* Announce meeting agenda and minutes after each meeting on their SIG mailing list.
* Keep up-to-date meeting notes, linked from the SIG's page in the community repo.
* Record SIG meeting and make it publicly available.
* Ensure the SIG's mailing list and Slack channel are archived.
* Report activity in the weekly community meeting at least once every four (4) weeks.
* Participate in release planning, retrospective, and burndown meetings, as needed.
* Ensure related work happens in a project-owned GitHub organization and repository, with code
  and tests explicitly owned and supported by the SIG, including issue triage, PR reviews,
  test-failure response, bug fixes, etc.
* Use the above forums as the primary means of working, communicating, and collaborating, as
  opposed to private e-mails and meetings.
* Represent the SIG for the PM group:
  * Identify all features in the current release from the SIG.
  * Track all features (in the repo with all the fields complete).
  * Attend your SIG meetings.
  * Attend the PM group meetings which occur 3-5 times per release (TODO: Determine cadence).
  * Identify the annual roadmap.
  * Advise their SIG as needed.

To propose a new SIG on a particular topic, [please follow our
guidelines](/community/sig-creation-procedure.md).

## License

All software should use the [Apache License version
2.0](https://www.apache.org/licenses/LICENSE-2.0), and all documentation should use the [Creative
Commons License version 4.0](https://creativecommons.org/licenses/by/4.0/legalcode)
