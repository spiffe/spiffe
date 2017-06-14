#!/bin/bash

# Go to the script's directory
cd "$(dirname "$0")"


# The return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero status,
# or zero if all commands in the pipeline exit successfully:
set -o pipefail
set -e

BASH_XTRACEFD="5"
PS4='$LINENO: '

MO=./.lib/mo/mo

# set -x

VERBOSITY=4

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


function esilent () { verb_lvl=$silent_lvl elog_plain "$@" ;}
function enotify () { verb_lvl=$ntf_lvl elog "$@" ;}
function eok ()    { verb_lvl=$ntf_lvl elog "SUCCESS - $@" ;}
function ewarn ()  { verb_lvl=$wrn_lvl elog "${colylw}WARNING${colrst} - $@" ;}
function einfo ()  { verb_lvl=$inf_lvl elog "${colwht}INFO${colrst} ---- $@" ;}
function edebug () { verb_lvl=$dbg_lvl elog "${colgrn}DEBUG${colrst} --- $@" ;}
function eerror () { verb_lvl=$err_lvl elog "${colred}ERROR${colrst} --- $@" ;}
function ecrit ()  { verb_lvl=$crt_lvl elog "${colpur}FATAL${colrst} --- $@" ;}
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

function einfo_exec() {
    if [ ${VERBOSITY} -ge ${inf_lvl} ]; then
        set -x;
        "$@"
        set +x;
    fi

}

function esilent_exec() {

    "$@" 2>/dev/null
}



function usage  {
   esilent "Usage ./generate_ca.sh <org_domain> <service_name> <base_directory> <config_directory>"
   esilent "eg. ./generate_ca.sh acme.com blogserver ./.certs/ ./conf}"

}

function description {

   esilent "================================================================"
   esilent "This script will lead you through the generation of a root "
   esilent "certificate keypair, intermediate cert keypair, and a final"
   esilent "SPIFFEdf certificate suitable for use in mTLS"
   esilent "  ORG:         ${SPIFFE_CERT_ORG_NAME}"
   esilent "  SERVICE ID:  ${SPIFFE_CERT_SERVICE_NAME}"
   esilent "  BASE:        ${BASE}"
   esilent "  SPIFFE_BASE: ${SPIFFE_BASE}"
   esilent "  SPIFFE_ID:   ${SPIFFE_ID}"
   esilent "----------------------------------------------------------------"
}

function setup_confs {

   local base=${1}
   local conf_source=${2}

   einfo "Setup OpenSSL configuration files."

   if [ ! -e "${base}/openssl.conf" ]; then
      cp ${conf_source}/root_openssl.conf ${base}/openssl.conf
   fi

   if [ ! -e "${base}/intermediate/openssl.conf" ]; then
      cp ${conf_source}/intermediate_openssl.conf ${base}/intermediate/openssl.conf
   fi
}


function _setup_dirs {

  local base_dir=${1}
  local verify_file=${2}

  if [ ! -e "${base_dir}/${verify_file}" ]; then

    # generate CA directories
    mkdir -p ${base_dir}
    pushd ${base_dir}
      mkdir certs crl newcerts private
      chmod 700 private
      touch index.txt
      echo 1000 > ${verify_file}
    popd
  fi
}

function setup_root_dirs {
    einfo "========================="
    einfo "Building Root CA"
    einfo "-------------------------"

    local base_dir=${1}
    _setup_dirs  ${base_dir} serial

}

function setup_intermediate_dirs {

    einfo "========================"
    einfo "Building Intermediate CA"
    einfo "------------------------"

   local base_dir=${1}

   _setup_dirs ${base_dir}/intermediate crlnumber

   if [ ! -e "${base_dir}/intermediate/serial" ]; then
      pushd ${base_dir}/intermediate
          mkdir csr
          echo 1000 > serial
      popd
  fi
}

function setup_leaf_dirs {

    einfo "========================"
    einfo "Building Leaf key and cert"
    einfo "------------------------"

    local base_dir=${1}

    _setup_dirs ${base_dir}/leaf crlnumber
}


function create_trust_root {

    # build root CA
    if [ -e "${SPIFFE_BASE}/certs/ca.cert.pem" ]; then
        exit 0
    fi

    local passphrase=${1}

    einfo "==============================="
    einfo "Create ROOT of trust"
    einfo "-------------------------------"

    pushd ${SPIFFE_BASE}
        esilent_exec openssl genrsa \
           -aes256 \
           -out private/ca.key.pem \
           -passout pass:${passphrase} \
           4096

        chmod 700 private/ca.key.pem

        esilent_exec openssl req \
          -config openssl.conf \
          -key private/ca.key.pem \
          -new \
          -x509 \
          -days 365 \
          -sha256 \
          -passin pass:${passphrase} \
          -extensions v3_ca \
          -out certs/ca.cert.pem \
          -subj "/C=US/O=${SPIFFE_CERT_ORG_NAME}/CN=RootCA"

        chmod 744 certs/ca.cert.pem

        einfo_exec openssl x509 -noout -text -in certs/ca.cert.pem
    popd

}


function create_intermediate {

    local root_passphrase=${1}
    local inter_passphrase=${2}

    if [ ! -e "${SPIFFE_BASE}/intermediate/certs/ca-chain.cert.pem" ]; then

      pushd ${SPIFFE_BASE}
        einfo "==============================="
        einfo "Create intermediate keypair..."
        einfo "-------------------------------"

        esilent_exec openssl genrsa \
            -aes256 \
            -out intermediate/private/intermediate.key.pem \
            -passout pass:${inter_passphrase} \
            4096


        chmod 700 intermediate/private/intermediate.key.pem

        esilent_exec openssl req \
            -config intermediate/openssl.conf \
            -new \
            -sha256 \
            -key intermediate/private/intermediate.key.pem \
            -passin pass:${inter_passphrase}\
            -out intermediate/csr/intermediate.csr.pem \
            -subj "/C=US/O=${SPIFFE_CERT_ORG_NAME}/CN=IntermediaetCA" \

        # sign the intermediate with the root
        esilent_exec openssl ca \
            -batch \
            -config openssl.conf \
            -extensions v3_intermediate_ca \
            -passin pass:${root_passphrase} \
            -days 100 \
            -notext \
            -md sha256 \
            -in intermediate/csr/intermediate.csr.pem \
            -out intermediate/certs/intermediate.cert.pem

        chmod 444 intermediate/certs/intermediate.cert.pem

        einfo_exec openssl x509 -noout -text \
                -in intermediate/certs/intermediate.cert.pem

        # create the ca cert chain
        cat intermediate/certs/intermediate.cert.pem \
          certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem

        chmod 744 intermediate/certs/ca-chain.cert.pem
      popd
    fi


}

function create_leaf {

    local inter_passphrase=${1}
    local leaf_passphrase=${2}

    einfo "==============================="
    einfo "Building Server and Client example certificates"
    einfo "-------------------------------"

    if [ ! -e "${SPIFFE_BASE}/intermediate/certs/${SPIFFE_CERT_SERVICE_NAME}.pem" ]; then
      pushd ${SPIFFE_BASE}
        # create server and client certificate
        einfo "Create service ${SPIFFE_CERT_SERVICE_NAME} keypair..."

        esilent_exec openssl genrsa \
           -out intermediate/private/${SPIFFE_CERT_SERVICE_NAME}.key.pem \
           -passout pass:${leaf_passphrase} \
           2048

        chmod 700 intermediate/private/${SPIFFE_CERT_SERVICE_NAME}.key.pem

        esilent_exec openssl req \
          -config intermediate/openssl.conf \
          -passin pass:${leaf_passphrase} \
          -key intermediate/private/${SPIFFE_CERT_SERVICE_NAME}.key.pem \
          -new \
          -sha256 \
          -out intermediate/csr/${SPIFFE_CERT_SERVICE_NAME}.csr.pem \
          -subj "/C=US/O=${SPIFFE_CERT_ORG_NAME}/CN=${SPIFFE_CERT_SERVICE_NAME}"

        # CA sign the csr and return a certificate
        esilent_exec openssl ca \
          -batch \
          -config intermediate/openssl.conf \
          -extensions server_cert \
          -days 10 \
          -notext \
          -md sha256 \
          -passin pass:${inter_passphrase} \
          -in intermediate/csr/${SPIFFE_CERT_SERVICE_NAME}.csr.pem \
          -out intermediate/certs/${SPIFFE_CERT_SERVICE_NAME}.cert.pem \
          -subj "/C=US/O=${SPIFFE_CERT_ORG_NAME}/CN=${SPIFFE_CERT_SERVICE_NAME}"

        einfo_exec openssl x509 -noout -text \
            -in intermediate/certs/${SPIFFE_CERT_SERVICE_NAME}.cert.pem
      popd
    fi

}


#================================
# Check input parameters
#--------------------------------
if [ $# -ne 4 ]; then
  usage
  exit
fi

#================================
# Assign input parameters
#--------------------------------
SPIFFE_CERT_ORG_NAME=${1}
SPIFFE_CERT_SERVICE_NAME=${2}

BASE=${3}

# Set global variables
SPIFFE_BASE="${BASE}/org/${SPIFFE_CERT_ORG_NAME}/ca/"
CONF_BASE=${4}

ROOT_PASS=blah
INTER_PASS=blah
LEAF_PASS=blah

# TODO: would need a more detailed Domain name and path for Service name
export SPIFFE_ID="spiffe://${SPIFFE_CERT_ORG_NAME}/${SPIFFE_CERT_SERVICE_NAME}"

description

setup_root_dirs ${SPIFFE_BASE}
setup_intermediate_dirs ${SPIFFE_BASE}
setup_leaf_dirs ${SPIFFE_BASE}

setup_confs ${SPIFFE_BASE} ${CONF_BASE}

create_trust_root ${ROOT_PASS}

create_intermediate ${ROOT_PASS} ${INTER_PASS}

create_leaf ${INTER_PASS} ${LEAF_PASS}

