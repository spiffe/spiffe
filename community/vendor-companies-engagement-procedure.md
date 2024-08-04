## Procedure for Engaging With Vendor Companies

### Summary

This document outlines the procedure for engaging with vendor companies, and
how vendor companies can represent themselves and their interests in the SPIFFE
community.

The goal is to provide a clear and consistent process for engaging with 
vendor companies that are included but not limited to those that use SPIFFE and 
SPIRE, provide a proprietary SPIFFE-compatible service, or are interested in 
contributing to the SPIFFE project.

More specifically, this document includes guidelines for communication, 
technical contact designation, and handling potential disruptive participants.

### Contacts

#### Objective

To ensure effective communication and support for vendor’s product or service
consumers using the SPIFFE specification by designating responsible technical 
contacts.

#### Guidelines

##### Designation of Contacts

* Each vendor company that directs their customers to the SPIFFE Slack channel 
  must designate two contacts. At least one of these contacts are encouraged
  (*but not required*) to be a technical contact. See the definition of roles
  and responsibilities of technical and community contacts in the subsequent
  **Kinds of Contacts** subsection.
* These contacts will serve as the primary point of contact for addressing 
  queries and facilitating communication between the customers and the SPIFFE 
  community and provide a mechanism for the SPIFFE community to communicate
  with the company.

##### Kinds of Contacts

Companies should designate two types of contacts: **technical** and 
**community**.

Companies are *strongly encouraged* to designate at least one technical contact.

A designated contact can serve as both a technical and community contact.

**Technical Contacts** are individuals with extensive knowledge of the vendor's 
SPIFFE product implementation. They will serve as the primary point of contact 
for SPIFFE contributors who have questions about the specifics of a vendor's 
implementation and for handling technical queries.

**Community Contacts** are individuals responsible for developer relations, 
developer experience, or other community engagement functions for the vendor. 
Their role includes engaging with and moderating the community associated with 
the vendor and the SPIFFE project. They will be the primary contact for 
discussions that benefit both the vendor and the SPIFFE project. This includes 
creating and sharing content such as case studies, use case statements, 
blog posts, screencasts, podcasts, tutorials, interviews, and other forms of 
media.

##### Documentation of Contacts

A dedicated folder for each company will be created in the SPIFFE repository
under the `./community/vendor-technical-contacts` directory.

The folder will contain:

* Names and contact information of the designated technical contacts. This can 
  include specific contact details for individuals or a group email that 
  directs to the appropriate contacts.
* Company-specific guidelines for interaction and support procedures, 
  such as how to submit tickets, expected response times, and preferred 
  communication channels.
* Any relevant documentation provided by the company.

### Interaction Protocols

#### Objective

To establish clear protocols for interactions between the vendor’s product or 
service consumers and the SPIFFE community to ensure a productive and respectful 
environment.

#### Guidelines

##### Communication Etiquette

* All interactions must be professional, respectful, and focused on technical 
  issues. [Refer to the **SPIFFE Code of Conduct** for details][coc].
* Technical contacts are responsible for ensuring that their customers, and 
  anyone who joins the community through their reference adhere to the community 
  guidelines and maintain a positive environment.

[coc]: ../CODE-OF-CONDUCT.md "SPIFFE Code of Conduct"

##### Issue Resolution

* Technical contacts should facilitate the resolution of technical issues by 
  providing detailed information and context.
* For complex issues, technical contacts should coordinate with SPIFFE 
  maintainers and contributors to find solutions.

##### Feedback Mechanism

SPIFFE Steering Committee encourages vendor to provide feedback on their 
experience with the SPIFFE specification and the support received.

SPIFFE Steering Committee will use this feedback to improve documentation, 
support processes, and community guidelines.

### Managing Disruptive Participants

#### Objective

To identify and manage participants who disrupt the community, ensuring that 
the SPIFFE Slack channel remains a productive and positive space.

#### Guidelines

##### Identification of Disruptive Behavior

* Disruptive behavior includes, but is not limited to, spamming, harassment, and 
  consistently off-topic discussions.
* Technical contacts must monitor interactions and identify any disruptive 
  behavior from their customers.

##### Actions to Take Upon Identifying Disruptive Behavior

* If a technical contact identifies disruptive behavior, they should first 
  determine if this behavior breaches the conduct guidelines.
* Upon confirming a breach, the technical contact should reach out directly to 
  the customer to deliver a warning and outline the expected conduct.
* If the behavior persists after the warning, escalate the issue to the 
  SPIFFE Steering Committee (SSC).

##### Initial Warning

* If a participant is identified as disruptive, a warning should be issued 
  outlining the behavior and the consequences of continued disruption.
* Technical contacts are responsible for communicating the warning to the 
  participant.

##### Escalation Process

* If the disruptive behavior continues, escalate the issue to the 
  SPIFFE Steering Committee (SSC).
* The SSC will evaluate the situation and decide on appropriate actions, which 
  may include temporary or permanent removal from the Slack channel. 
* If a company's customers frequently exhibit disruptive behavior or other 
  issues, the company will be removed from the channels and the list of 
  community partners.

##### Channel Removal Process

If a specific vendor's channel consistently experiences disruptive behavior or 
other persistent issues despite warnings and interventions:

* The SSC will conduct a thorough review of the channel's activity and impact 
  on the community.
* If the SSC determines that the channel is detrimental to the community's 
  well-being or productivity, they will initiate a formal discussion about 
  potential channel removal.
* The SSC will notify the vendor's technical and community contacts about the 
  concerns and the potential for channel removal.
* The vendor will be given a specified timeframe (e.g., 30 days) to address the 
  issues and demonstrate improvement.
* If no significant improvement is observed, the SSC will vote on removing the 
  channel.
* A majority vote from the SSC is required to remove a channel.
* If the vote passes, the channel will be archived, and the vendor will be 
  notified of the decision and the reasons behind it.
* The vendor may appeal the decision or request reinstatement after a specified 
  period (e.g., 6 months), demonstrating how they have addressed the previous 
  issues.
* The timelines for removal, appeal, and reinstatement are subject to change 
  based on the SSC's discretion.

##### Documentation and Reporting

* SSC will document all incidents of disruptive behavior, including the 
  participant's actions, warnings issued, and any subsequent actions taken.
* SSC will maintain a private report of these incidents to ensure confidentiality 
  and privacy.
