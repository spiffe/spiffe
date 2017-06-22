#!/bin/bash

# The return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero status,
# or zero if all commands in the pipeline exit successfully:
set -o pipefail
set -e

BASH_XTRACEFD="5"
PS4='$LINENO: '

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

function usage  {
    esilent "Usage ./verify_ca.sh <service_name> <base_directory> <config_directory>"
    esilent "eg.   ./verify_ca.sh acme.com blogserver ./.certs/ ./conf"

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
    local service_name=${3}

    set +e
    ( exec openssl verify -CAfile ${dir_base_inter}/certs/ca-chain.cert.pem \
        ${dir_base_leaf}/certs/${service_name}.cert.pem )
    set -e

}

function clean_up {

    einfo "EXIT ==============="
}

#================================
# Check input parameters
#--------------------------------
if [ $# -ne 2 ]; then
  usage
  exit
fi

BASE=${1}
CONF_BASE=${2}

trap clean_up SIGHUP SIGINT SIGTERM


description


{
    read
    while IFS=, read col_org col_service; do

        dir_base_inter="${BASE}/org/${col_org}/intermediate"
        dir_base_leaf="${BASE}/org/${col_org}/leaf"

        einfo $col_org
        einfo $col_service

        verify ${dir_base_inter} ${dir_base_leaf} ${col_service}

    done

} < ${CONF_BASE}/cert_conf.csv