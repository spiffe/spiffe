# SIG Integration AWS

A Special Interest Group (SIG) for running SPIFFE in AWS. We encourage attendees to show up in-person for these meetings, even though each meeting will have video conferencing (and be recorded).

### Meetings:
* Every other Thursday @ 2:00pm PDT
    * [Meetings Notes](https://goo.gl/xBfMQ8)
    * [Calendar ICS](https://calendar.google.com/calendar/ical/scytale.io_86ue2u4jf0v5cqt06gdfg7dotg%40group.calendar.google.com/public/basic.ics) (See this [Google support page](https://support.google.com/calendar/answer/37100?co=GENIE.Platform%3DDesktop&hl=en) to learn more about importing .ics files)

### Contact:
* [Slack Channel](https://spiffe.slack.com/messages/sig-integration-aws/)
* [Google Group](https://groups.google.com/a/spiffe.io/forum/#!forum/sig-integration-aws)

### Goals:
* Overall: establish trust of a system when it first boots. This is the first thing that must happen for a SIFFE aware deployment to exist.
* Sequence diagram (strawman)
* Protocol that authenticates an ec2 instance to the control plane when the instance first boots
* Support the following instance to SPIFFE ID mapping methods
  * Only the instance ID (map IID to SPIFFE ID)
  * AWS IAM roles (map IAM-ROLE to SPIFFEE ID)
  * AWS Tags (map a nonce in a tag to a SPIFFE ID)
  * Auto Scaling Groups (map an ASG/Security group to a SPIFFE ID)
  * Google Cloud Platform (TBD mapped to a SPIFFE ID)
* Determine how the control plane supports the registation methods to map to a set of SPIFFE IDs
* End to end POC

### Non Goals:
* TODO

### Leads:
* Jon Debonis ([GitHub](https://github.com/jondb) / [LinkedIn](https://www.linkedin.com/in/jondb/))
