#!/bin/bash
#
# Usage: find_eligible_voters.sh [GH_ACCESS_TOKEN]
#

set -e

if [ $# -ne 1 ]; then
        echo "Usage: $0 [GH_ACCESS_TOKEN]"
        exit 1
fi

which -s jq
if [ $? -ne 0 ]; then
        echo "`jq` tool required"
fi

GHTOKEN=$1
ELIGIBLE_VOTERS=""
CURL="curl -H \"accept: application/vnd.github.v3+json\" -su username:$GHTOKEN https://api.github.com"
echo "SSC voter eligibility script running..."

#
# Collect all public SPIFFE repos
#
REPO_RESPONSE=`curl -su username:$GHTOKEN https://api.github.com/orgs/spiffe/repos`
REPOS=`echo "$REPO_RESPONSE" | jq  '.[] | {name: .name, private: .private}' | grep -B1 '"private": false' | grep '"name": ' | awk '{print $2}' | sed 's/^"//' | sed 's/",$//'`
NUM_REPOS=`echo "$REPOS" | wc -l`
echo "Found $NUM_REPOS SPIFFE repositories."
echo Names: $REPOS
echo

#
# Collect all issues and PR authors
# 
for REPO in $REPOS; do
        PAGE_SIZE=100
        REQUEST_CMD="$CURL/repos/spiffe/$REPO/issues?per_page=$PAGE_SIZE&state=all"

        FULL_RESP=""
        THIS_PAGE_SIZE=$PAGE_SIZE
        THIS_PAGE_NUM=1
        while [ $THIS_PAGE_SIZE -eq $PAGE_SIZE ]; do
                resp=`$REQUEST_CMD\&page\=$THIS_PAGE_NUM`
                THIS_PAGE_SIZE=`echo $resp | jq '.[] | {issue_number: .number}' | grep issue_number | wc -l`
                let "THIS_PAGE_NUM++"
                FULL_RESP+=$resp
        done

	# Only Issues/PRs from the last one year qualify
	RECENT_ISSUES=`echo $FULL_RESP | jq '.[] | select (.created_at | fromdateiso8601 > (now - 31536000)) | .'`
        NUM_RECENT_ISSUES=`echo $RECENT_ISSUES | jq '. | {issue_number: .number}' | grep issue_number | wc -l | tr -d '[:space:]'`

	UNIQUE_AUTHORS=`echo $RECENT_ISSUES | jq '. | {author: .user.login}' | grep '"author": ' | sort -u | awk '{print $2}' | sed 's/^"//' | sed 's/"$//'`
        NUM_UNIQUE_AUTHORS=`echo "$UNIQUE_AUTHORS" | wc -l | tr -d '[:space:]'`

	ELIGIBLE_VOTERS+="$UNIQUE_AUTHORS"
	if [ $NUM_UNIQUE_AUTHORS -gt 0 ]; then
		ELIGIBLE_VOTERS+=$'\n'
	fi

        echo "Found	$NUM_RECENT_ISSUES issues and PRs in repo $REPO	with $NUM_UNIQUE_AUTHORS unique authors"
done

ELIGIBLE_VOTERS=`echo "$ELIGIBLE_VOTERS" | sort -u`

echo
echo "Eligible voters:"
echo "$ELIGIBLE_VOTERS"
echo

NUM_ELIGIBLE_VOTERS=`echo "$ELIGIBLE_VOTERS" | wc -l | tr -d '[:space:]'`
echo "Total: $NUM_ELIGIBLE_VOTERS"

#
# Look up user data
#
INELIGIBLE_VOTERS=""
echo
echo
for VOTER in $ELIGIBLE_VOTERS; do
	if [ "$VOTER" == "dependabot[bot]" ] || [ "$VOTER" == "github-actions[bot]" ] || [ "$VOTER" == "chainguard-alerter" ] ; then
		continue
	fi

	USER_RESP=`$CURL/users/$VOTER`
	NAME=`echo "$USER_RESP" | jq '.name' | sed 's/^"//' | sed 's/"$//'`
	EMAIL=`echo "$USER_RESP" | jq '.email' | sed 's/^"//' | sed 's/"$//'`

	if [ "$EMAIL" == "null" ]; then
		INELIGIBLE_VOTERS+="- @$VOTER"
		INELIGIBLE_VOTERS+=$'\n'
		continue
	fi

	if [ "$NAME" == "null" ]; then
		NAME=
	fi

	echo "- $NAME (@$VOTER) <$EMAIL>"
done

echo
echo
echo "The following voters are ineligible due to missing email address:"
echo "$INELIGIBLE_VOTERS"
