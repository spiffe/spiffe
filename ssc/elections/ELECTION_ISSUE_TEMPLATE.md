# YYYY [H1,H2] SSC Election
This is the official tracking issue for the YYYY [H1,H2] SSC election. The timeline for this election is as follows:
* IMMEDIATELY: Nominations open
* MONTH DAY, YEAR: Nominations close
* MONTH DAY, YEAR: Polls open
* MONTH DAY, YEAR: Polls close
* MONTH DAY, YEAR: Results announced

There is/are X seats available.

## How to Participate
All SPIFFE community members and contributors demonstrating active engagement in the project(s) are invited to both nominate and vote on new SSC members.
An initial batch of eligible participants discovered via automation is listed below.

For more information about the definition of active engagement, and how this list was compiled, please see the Election and Term Mechanics section of the [SSC Charter](https://github.com/spiffe/spiffe/blob/master/ssc/CHARTER.md#election-and-term-mechanics).

If you feel that you are an active SPIFFE community member or contributor but are not included in the list below, please contact the SSC at ssc-elections@spiffe.io and we will be happy to include you.
Even if you do not interact with GitHub normally, to be an election candidate a GitHub account is required as this is how SSC members gain administrative rights on the SPIFFE projects.

### Nominating an SSC Member
Eligible participants may nominate up to two candidates per available SSC seat during the nomination period. They may nominate themselves or someone else.

If you'd like to nominate an SSC member for this election cycle, please follow these steps:
1. Verify that your GitHub handle is included in the list of eligible participants below
1. Verify that, in your best judgement, the nominee meets the criteria specified in the Nominee Qualifications section of the [SSC Charter](https://github.com/spiffe/spiffe/blob/master/ssc/CHARTER.md#nominee-qualification)
1. Fork this repository
1. Copy `ssc/elections/NOMINEE_TEMPLATE.md` into the appropriate subdirectory, and name it after the person to be nominated
	1. For example, from the root directory:  
	```
	$ cp ssc/elections/NOMINEE_TEMPLATE.md ssc/elections/2021H1/JANE_DOE.md
	```  
1. Fill in all fields in the copied template as completely as possible
1. Open a GitHub Pull Request back to this repository to add the new nominee
	1. Create a new commit with the name of the election and nominee
		1. For example, `Nominate Jane Doe for 2021H1 SSC Election`
	1. Open a new GitHub Pull Request against https://github.com/spiffe/spiffe
		1. Give the Pull Request the same name as the commit it includes
1. An SSC member will review the nomination and merge it when ready

### Electing an SSC Member
The SPIFFE project uses the [CIVS](https://civs.cs.cornell.edu/) tool to conduct its elections. Once the polls open, all eligible participants will receive an email from this tool. The email includes a link which can be used to vote. Do not share this link, as it is private.

If you are in the list of eligible participants, and you don't receive a link on the day the polls open, please contact the SSC at ssc-elections@spiffe.io.

Each participant casts a single ranked vote. If more than one SSC seat is available, the top N nominees will be selected.

## Eligible Participants
This section lists everyone eligible to participate in this SSC election cycle. If you believe you were omitted in error, please contact the SSC at ssc-elections@spiffe.io. If you have an `**` next to your username, we do not have a known email address to contact you at for sending a voting link. Please publish an email address to your GitHub profile and contact the SSC at ssc-elections@spiffe.io.

* LAST\_NAME, FIRST\_NAME (@GITHUB\_HANDLE) \<EMAIL\_ADDRESS\>
* ...

