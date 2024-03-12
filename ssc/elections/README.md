# SSC Elections
Welcome to the SSC elections. Here you will find information about how SSC elections are conducted, as well as past and current SSC elections.

For information about a specific election, please see the relevant subdirectory.

## SSC Election Process
Current membership and term dates can be seen [here](../README.md). Multiple seats may be open in a single election.

Each SSC election has a dedicated subdirectory and tracking issue in this repository. The tracking issue can be subscribed to by interested parties, and will be updated as the election progresses.

All nominees are proposed via GitHub Pull Request, and each nominee gets a dedicated file in the relevant subdirectory (e.g. `2021H1` for the first election of 2021). A list of eligible participants, as well as detailed instructions on how to participate in the election process, are documented in the subdirectory's README.

The rest of this section captures the exact steps necessary to begin and complete an SSC election. These steps are to be performed by an SSC member, or appointed party.

Eligible participants are initially found via a GitHub search, since all other discovery processes would be manual. This is not intended as an exclusion of community members who are not active in GitHub but otherwise do participate in SPIFFE workstreams.
However, for candidates a GitHub account is required as this is how SSC members gain administrative rights on the SPIFFE projects.

### Term Start-84 Days: Preparation, Nominations Open
1. Identify initial batch of eligible participants using the `script` subfolder.
	1. Automation of finding eligible participants requires a public email address on participant GitHub profiles
1. Open GitHub issue to track election
	1. The title should be `YYYY [H1,H2] SSC Election`
	1. Use the text in `ELECTION_ISSUE_TEMPLATE.md` as the issue body, filling in the details as needed
1. Create the election directory (e.g. `ssc/elections/2021H1`)
	1. Copy in `ELECTION_README_TEMPLATE.md`, renaming to `README.md`
		1. Fill in details, as appropriate
	1. Send a PR titled `Open Nominations for YYYY [H1,H2] SSC Election` to add the new directory and README
1. All nomination PRs are to be left OPEN during the nomination period
	1. GH reactions and comments are welcome
1. Announce the start of nominations
	1. Slack #announcements channel
	1. SIG mailing lists

### T-56 Days: Nomination Closes
1. Comment on tracking issue that nominations are now closed
1. SSC members perform due diligence on all nominations
	1. Each SSC member to take a portion of the nominations
	1. SSC members to initiate nominee-specific private SSC discussion if concern about qualification arises
	1. For every qualified nominee, SSC member performing due diligence to merge nomination PR

### T-49 Days: Polling Opens
1. One SSC member to volunteer as election supervisor
	1. Election supervisor opens poll on [CIVS](https://civs.cs.cornell.edu/)
1. Comment on tracking issue that polls are now open
	1. All eligible participants should have received an email
1. Announce that the polls are now open
	1. Slack #announcements channel
	1. SIG mailing lists

### T-21 Days: Polling Closes and Results Announced
1. Election supervisor closes [CIVS](https://civs.cs.cornell.edu/) poll
1. Comment on tracking issue that polls are now closed
1. Share full poll results privately with SSC
	1. Check for signs of abuse
1. Share result with winner(s) privately and re-confirm commitment (see [Charter](../CHARTER.md)).
1. Send a PR to add results to the election's README
	1. Only the new seats are to be named in the results section
1. Comment on tracking issue with the results
	1. Link to PR
1. Announce results
	1. Slack #announcements channel
	1. SIG mailing lists

### T-0 Days: New Term Starts
1. Send a PR adjusting the membership list.
	1. Tracking issue to be closed once PR is merged.
1. Any outgoing member(s) term is officially over, incoming member(s) term has now started.

