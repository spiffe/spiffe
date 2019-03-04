### SIG creation procedure

### Prerequisites

* Purpose the new SIG publicly include a brief mission statement, by emailing
  spiffe-dev@googlegroups.com and spiffe-users@googlegroups.com, then wait a couple of days for
  feedback  
* Ask a repo maintainer to create a github label, if one doesn't already exist: sig/foo
* Request a new [spiffe.slack.com](http://spiffe.slack.com) channel (#sig-foo). New users can join
  at [slack.spiffe.io]
* Slack activity is archived at [spiffe.slackarchive.io](http://spiffe.slackarchive.io). To start
  archiving a new channel invite slackarchive bot to the channel via '/invite @slackarchive'
* Organization video meetings as needed.  No need to wait for the [Weekly Community Video
  Conference](community/README.md) to discuss.  Please report summary of SIG activities there.
* Add the meeting to the community meeting calendar by inviting {TODO}@group.calendar.google.com.  
* Announce new SIG on spiffe-dev@googlegroups.com
* Submit a PR to add a row for the SIG to the table in the [README](../README.md) file, to create a
  spiffe/community directory, and to add any SIG-related docs, schedules, roadmaps, etc. to your
  new spiffe/community/SIG-foo directory.

### Creating service account for the SIG

With a purpose to distribute the channels of notification and discussion of the various topics,
every SIG has to use multiple accounts to GitHub mentioning and notifications. Below the procedure
is explained step-by-step

### Google Groups creation

Create Google Groups at
[https://groups.google.com/forum/#!creategroup](https://groups.google.com/forum/#!creategroup),
following the procedure:

* Each SIG should have one discussion groups
* Create groups using the name conventions below
* Groups should be created as e-mail lists with at least three owners
* To add the owners, visit the Group Settings (drop-down menu on the right side), select Direct
  Add Members on the left side and add (2 default owners TODO)
* Set "View topics", "Post" "Join the Groups" permissions to be "Public"

For now we will use one group per SIG. Later on the SIGs can be sub divided into more granular
groupings.

Name convention example:

* spiffe-sig-cert-format (the discussion group)

#### GitHub users creation

Create the GitHub users at [https://github.com/join](https://github.com/join), using the name
convention below.

As an e-mail address, please, use the Google Group e-mail address of the respective Google Group,
created before. After creating the GitHub users, please add these users to the Spiffe organization.  

Name convention:

* spiffe-mirror-foo

Example:
* spiffe-mirror-cert-format

NOTE: Github's notification autocompletion finds the users before the corresponding teams.
This is the reason we recommend naming the users `spiffe-mirror-foo-*` instead of `spiffe-sig-foo-*`.


#### Create the GitHub teams

Create the GitHub teams using the name conventions below. Please, add the GitHub users (created
before) to the GitHub teams respectively.

For now we will create one GitHub team per SIG. Later on we will subdivide SIG teams  into more
granular groupings.

* sig-foo-misc

Example

* sig-cert-format
* sig-cert-format
