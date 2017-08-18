The SPIFFE Project succeeds because of an open, inclusive and respectful community. Ideas and
contributions are accepted according to their technical merit and alignment with project objectives,
scope, and design principles.

This document lists a non-exclusive set of guidelines to help ensure fairness and transparency in
managing the SPIFFE Project.

# Code of Conduct

The SPIFFE community abides by the CNCF [code of conduct](/CODE-OF-CONDUCT.md). An excerpt:

> _As contributors and maintainers of this project, and in the interest of fostering an open and
> welcoming community, we pledge to respect all people who contribute through reporting issues,
> posting feature requests, updating documentation, submitting pull requests or patches, and other
> activities._

As a member of the SPIFFE Project, you represent the project and your fellow contributors. We value
our community tremendously and we'd like to keep cultivating a friendly and collaborative
environment for our contributors and users. We want everyone in the community to have positive
experiences.

# Project Roles

## Users

These are individuals who have heard about the SPIFFE Project and are interested in learning more,
or existing users of SPIFFE and its tools who wish to follow the progress of the project. They may
have questions, comments, or suggestions which can be communicated via e-mail, Slack, or GitHub
comments. They can follow along as the SIGs do their work.

## Contributors

Contributors are those who wish to contribute code or ideas to the SPIFFE projects. Contributors
submit code and ideas through GitHub pull requests (PRs) and Issues. To contribute code for
consideration for inclusion in the project, they or their organization must have a signed Contributor
License Agreement on file.

## Maintainers

A SPIFFE Maintainer has a specific set of rights and responsibilities. Maintainers have the ability
to merge changes into the project codebases and at least one maintainer's approval is required on
any PR for that change to be accepted.

Accordingly, a maintainer also has the following responsibilities:

* They must be an active contributor to the community. This includes, but is not limited to, regular
  attendance of SPIFFE community meetings and Special Interest Groups relevant to the components
  they are a maintainer of.
* They should respond to review requests in a timely manner. Generally, a response is expected
  within 24 hours of a review being requested.
* They must ensure that any code changes they approve:
  * Meet the [coding conventions](/CONTRIBUTING.md) required by the project. This includes ensuring
    the code is sufficiently well tested, follows the appropriate standards, and of course - doesn't
    break the build.  
  * Is consistent with the goals and direction of the SPIFFE Project. This requires not just code
    and architectural correctness, but also ensuring that it does not introduce unnecessary scope
    creep, and does not unduly affect existing users.    
* Once a PR has the relevant approvals, the last approving maintainer bears the responsibility
  of merging the change in (however the author of the PR is expected to ensure the change is
  merge-ready).

Although maintainers can authorize merges to a codebase directly, any chances a maintainer proposes
must be submitted as a PR, and approved by at least one _other_ maintainer.

A list of maintainers is documented in each repository's
[CODEOWNERS](https://help.github.com/articles/about-codeowners/) file.

Maintainers may reject a PR if they don't feel it is consistent with the project's architecture,
the goals of the project, or meets the project's standards for code quality. If this happens,
the maintainer should clearly and concisely explain the reasoning behind the rejection. 

In rare cases where maintainers formally disagree (that is, where at least one maintainer
_rejects_ a PR, and at least one maintainer _approves_ the same PR), and the disagreement
can't be worked out, a member of the Technical Steering Committee should be solicited for a tie
breaking decision.

To become a maintainer, one must:

* Work in a helpful and collaborative way with the community
* Have a track record of providing constructive feedback on other's PRs
* Have submitted a minimum of 50 PRs themselves

You may nominate yourself as a maintainer for all or part of a repository by:

* Nominating yourself by submitting a PR against the `CODEOWNERS` file that covers the parts of the
  project you wish to nominate yourself for
* By having at least one existing Maintainer, _and_ a member of the Technical Steering Committee
  approve the PR. 

Similarly, a Maintainer may be removed from a repository by:

* Submitting a PR to the `CODEOWNERS` file.
* Except in cases where the removal is voluntary, both an existing maintainer
  and a member of the TSC must approve the change.

## Technical Steering Committee (TSC)

The SPIFFE Project is governed by a Technical Steering Committee (TSC) which is exclusively
responsible for the SPIFFE Standards (https://github.com/spiffe/spiffe/tree/master/standards) as
well as  the high-level direction of the project.

In addition to the rights and privileges of Maintainers, the TSC has final authority over
this project including:

* Technical direction, including the proposal and revision of any standards proposed by 
  the SPIFFE project
* Project governance and process (described in the contents of this repository)
* Arbitrating concerns that cannot be resolved by the project maintainers
* Approving nominations and removals of maintainers to SPIFFE projects

A list of maintainers is documented in this repository's
[CODEOWNERS](CODEOWNERS) file.

A TSC member may propose a change to the governance charter of the SPIFFE project, 
a revision to any proposed standards, and any of it's policies, by submitting a pull 
request to this repository. If the change is non-trivial (that is, changes or extends
the the interpretation of any of the above), then it must be approved by a majority
of the TSC.

Neither the size of the TSC nor length of terms are limited. An user may nominate 
themselves as a TSC member by submitting a pull request that adds their Github user
ID to the `CODEOWNERS` file of this repository. 

Similarly, a TSC member may propose to remove themselves or another  TSC member by 
submitting a pull request that removes their ID from the `CODEOWNERS` file of this
repository.

With the exception of voluntary resignations, all proposed changes to TSC membership must
be expressly approved by an absolute majority of the existing TSC membership, excluding 
the nominee under consideration.

No more than 2 TSC members may be affiliated with the same employer.

# Change review process

**All changes must be submitted as a Github Pull Request (PR)**

The submitter of the PR is responsible for responding to any feedback from reviewers and
maintainers, and, while the PR remains open, ensuring that the change is in a state where it can be
merged at all times. Guidelines for submitting a PR for approval can be found in
[CONTRIBUTING](/CONTRIBUTING.md).

**All minor changes must be approved by at least one other Maintainer**

Documentation changes, bugfixes, or other minor changes that don't significantly impact most users
must be approved by one maintainer.

**All major changes must be approved by at least two other Maintainers**

New or changed functionality require two maintainer approvals. It is the first reviewer's
responsibility to determine if a second reviewer is required.

# Special Interest Groups (SIGs)<a name="sigs"></a>

The SPIFFE Project has a number of special interest groups which focus on specific parts or
features. SIGs provide an avenue for face-to-face discussion of important design changes with key
stakeholders.

Each SIG is run by a *SIG Lead*, who is responsible for the logistics of running the meeting, and
for ensuring the group reaches consensus on any issues raised. Active SIGs, their leads, and meeting
information are [listed here](/README.md#sigs).

#### Responsibilities of the SIG lead

* Organize regular meetings as necessary, ideally at least for 30 minutes every two weeks
* Announce meeting agenda and minutes after each meeting on their SIG mailing list.
* Keep up-to-date meeting notes, linked from the SIG's page in the community repo.
* Record SIG meeting and make it publicly available.
* Ensure the SIG's mailing list and Slack channel are archived.
* Report activity in the weekly community meeting at least once every four (4) weeks.
* Use the above forums as the primary means of working, communicating, and collaborating, as
  opposed to private e-mails and meetings.

To propose a new SIG on a particular topic, [please follow our
guidelines](/community/sig-creation-procedure.md).

# License

All software is licensed under the [Apache License version
2.0](https://www.apache.org/licenses/LICENSE-2.0), and all documentation is licensed under the
[Creative Commons License version 4.0](https://creativecommons.org/licenses/by/4.0/legalcode)
