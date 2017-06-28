#!/bin/bash

# The return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero status,
# or zero if all commands in the pipeline exit successfully:
set -o pipefail
set -e

PS4='$LINENO: '
EXEC_MSG="------------ NONE --------------"
OPENSSL_RC=0
_RESULT_FILE="openssl.csv"

VERBOSITY=8

colblk='\033[0;30m' # Black - Regular
colred='\033[0;31m' # Red
colgrn='\033[0;32m' # Green
colylw='\033[0;33m' # Yellow
colpur='\033[0;35m' # Purple
colrst='\033[0m'    # Text Reset

# Verbosity levels
silent_lvl=0
crt_lvl=1
err_lvl=2
wrn_lvl=3
ntf_lvl=4
inf_lvl=5
dbg_lvl=6


function esilent ()  { verb_lvl=$silent_lvl elog_plain "$@" ;}
function enotify ()  { verb_lvl=$ntf_lvl elog "$@" ;}
function eok ()      { verb_lvl=$ntf_lvl elog "SUCCESS - $@" ;}
function ewarn ()    { verb_lvl=$wrn_lvl elog "${colylw}WARNING${colrst} - $@" ;}
function einfo ()    { verb_lvl=$inf_lvl elog "${colwht}INFO${colrst} ---- $@" ;}
function edebug ()   { verb_lvl=$dbg_lvl elog "${colgrn}DEBUG${colrst} --- $@" ;}
function eerror ()   { verb_lvl=$err_lvl elog "${colred}ERROR${colrst} --- $@" ;}
function ecrit ()    { verb_lvl=$crt_lvl elog "${colpur}FATAL${colrst} --- $@" ;}
function edumpvar () { for var in $@ ; do edebug "$var=${!var}" ; done }

function elog() {
        if [ ${VERBOSITY} -ge ${verb_lvl} ]; then
                datestring=`date +"%Y-%m-%d %H:%M:%S"`
                echo -e "${datestring} - $@"
        fi
}

function elog_plain() {
    if [ ${VERBOSITY} -ge ${verb_lvl} ]; then
        echo -e "$@"
    fi
}

function esilent_exec() {
    EXEC_MSG=$( "$@" 2>/dev/null )
}

function usage  {
    esilent "Usage ./verify_ca.sh <certs_directory> [--bad-certs]"
    esilent "eg.   ./verify_ca.sh ./.certs/"

}

function description {

    esilent "################################################################"
    esilent "This script will lead you through the generation of a root "
    esilent "certificate keypair, intermediate cert keypair, and a final"
    esilent " SPIFFE certificate suitable for use in mTLS"
    esilent " BASE:      ${BASE}"
    esilent " CONF_BASE: ${CONF_BASE}"
    esilent "----------------------------------------------------------------"

}


function verify {
    local dir_base_inter=${1}
    local dir_base_leaf=${2}

    set +e
    esilent_exec openssl verify -CAfile ${dir_base_inter}/certs/ca-chain.cert.pem \
           ${dir_base_leaf}/certs/leaf.cert.pem
    OPENSSL_RC=$?
    set -e
}

#================================
# Check input parameters
#--------------------------------
if [ $# -lt 1 ] ; then
    usage
    exit
fi

CERTS_BASE=${1}
BAD_FLAG=false
OPENSSL_VERSION=$(openssl version)

if [ "${2}" == "--bad-certs" ]; then
    BAD_FLAG=true
fi

trap clean_up SIGHUP SIGINT SIGTERM

description

orgs="${CERTS_BASE}/*"
for org in $orgs; do
    dir_base_inter="${org}/intermediate"
    dir_base_leaf="${org}/leaf"

    verify ${dir_base_inter} ${dir_base_leaf}

    # Cert valid, no "bad" flag
    if [ "${OPENSSL_RC}" -eq 0 ] && ! $BAD_FLAG; then
        einfo "passed ${org}"
    # Cert invalid, but "bad" flag set
    elif [ "${OPENSSL_RC}" -ne 0 ] && $BAD_FLAG; then
        einfo "passed ${org}"
    # Cert valid even though "bad" flag set
    elif [ "${OPENSSL_RC}" -eq 0 ] && $BAD_FLAG; then
        eerror "failed ${org} - cert is valid but not supposed to be!"
        exit 1
    else
        eerror "failed ${org} with ${EXEC_MSG}"
        exit 1
    fi
done
