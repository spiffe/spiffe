#!/bin/bash

# Go to the script's directory
cd "$(dirname "$0")"

# The return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero status,
# or zero if all commands in the pipeline exit successfully:
set -o pipefail
set -e

# Set this var to enable debug logging
DEBUG=

MO=./.lib/mo/mo

function elog() {
    datestring=`date +"%Y-%m-%d %H:%M:%S"`
    echo -e "${datestring} - $@"
}

function edebug_log() {
    if [[ $DEBUG ]]; then
        datestring=`date +"%Y-%m-%d %H:%M:%S"`
        echo -e "${datestring} - $@"
    fi
}

function edebug_exec() {
    if [[ $DEBUG ]]; then
        datestring=`date +"%Y-%m-%d %H:%M:%S"`
        echo -n "${datestring} - "
        set -x; "$@"; set +x
    else
        "$@" >/dev/null 2>&1
        echo -n '.'
    fi
}

function pushd () {
    command pushd "$@" > /dev/null
}

function popd () {
    command popd "$@" > /dev/null
}

function usage  {
   echo "Usage ./generate_ca.sh <org_domain> <service_name> <base_directory> <config_directory>"
   echo "eg. ./generate_ca.sh acme.com blogserver ./.certs/ ./templates"

}

function description {

   echo "================================================================"
   echo "This script will lead you through the generation of a root "
   echo "certificate keypair, intermediate cert keypair, and a final"
   echo "SPIFFE certificate suitable for use in mTLS"
   echo "  BASE:        ${BASE}"
   echo "  CONF_BASE: ${CONF_BASE}"
   echo "  TEMPLATES BASE: ${TEMPLATES_BASE} "
   echo "----------------------------------------------------------------"
}

function setup_confs_templates {

    local base_ca=${1}
    local base_inter=${2}
    local templates_source=${3}
    local ns_root=${4}
    local ns_inter=${5}
    local spiffe_id=${6}
    local san=${7}

    edebug_log "Setting up OpenSSL configuration files"

    if [ ! -e "${base_ca}/openssl.templates" ]; then
        # Namespace are delimited with |
        export SPIFFE_ROOT_NS="${ns_root/|/,}"
        export SPIFFE_INTER_NS="${ns_inter/|/,}"

        cat ${templates_source}/root_openssl.conf.mo | $MO > ${base_ca}/openssl.conf
    fi

    if [ ! -e "${base_inter}/openssl.templates" ]; then
        export SPIFFE_ID=${spiffe_id}

        cat ${templates_source}/intermediate_openssl.conf.mo | $MO > ${base_inter}/openssl.conf
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
    local base_dir=${1}
    _setup_dirs  ${base_dir} serial
}

function setup_intermediate_dirs {
   local base_dir=${1}

   _setup_dirs ${base_dir} crlnumber

   if [ ! -e "${base_dir}/serial" ]; then
       pushd ${base_dir}
          mkdir csr
          echo 1000 > serial
       popd
  fi
}

function setup_leaf_dirs {
    local base_dir=${1}

    _setup_dirs ${base_dir} crlnumber
    if [ ! -e "${base_dir}/serial" ]; then
        pushd ${base_dir}
            mkdir csr
            echo 1000 > serial
        popd
    fi
}

function create_trust_root {

    # build root CA
    local dir_base_ca=${1}
    local passphrase=${2}
    local org_name=${3}

    export HOME_CA=${dir_base_ca}

    if [ -e "${dir_base_ca}/certs/ca.cert.pem" ]; then
        exit 0
    fi

    edebug_log "Ceating root CA cert"

    pushd ${dir_base_ca}
        edebug_exec openssl genrsa \
           -aes256 \
           -out private/ca.key.pem \
           -passout pass:${passphrase} \
           4096

        chmod 700 private/ca.key.pem

        edebug_exec openssl req \
          -config openssl.conf \
          -key private/ca.key.pem \
          -new \
          -x509 \
          -days 365 \
          -sha256 \
          -passin pass:${passphrase} \
          -extensions v3_ca \
          -out certs/ca.cert.pem \
          -subj "/C=US/O=${org_name}/CN=RootCA"

        chmod 744 certs/ca.cert.pem
    popd
}

function create_intermediate {

    local dir_base_ca=${1}
    local dir_base_inter=${2}
    local root_passphrase=${3}
    local inter_passphrase=${4}
    local org_name=${5}

    export HOME_CA=${dir_base_ca}
    export HOME_INTER=${dir_base_inter}

    if [ ! -e "${dir_base_inter}/certs/ca-chain.cert.pem" ]; then

        pushd ${dir_base_inter}
            edebug_log "Creating intermediate CA cert"

            edebug_exec openssl genrsa \
                -aes256 \
                -out private/intermediate.key.pem \
                -passout pass:${inter_passphrase} \
                4096

            chmod 700 private/intermediate.key.pem

            edebug_exec openssl req \
                -config openssl.conf \
                -new \
                -sha256 \
                -key private/intermediate.key.pem \
                -passin pass:${inter_passphrase}\
                -out csr/intermediate.csr.pem \
                -subj "/C=US/O=${org_name}/CN=IntermediaetCA" \

            # sign the intermediate with the root
            edebug_exec openssl ca \
            -batch \
            -config ${dir_base_ca}/openssl.conf \
            -extensions v3_intermediate_ca \
            -passin pass:${root_passphrase} \
            -days 100 \
            -notext \
            -md sha256 \
            -in csr/intermediate.csr.pem \
            -out certs/intermediate.cert.pem

            chmod 744 certs/intermediate.cert.pem

            # create the ca cert chain
            cat certs/intermediate.cert.pem  \
                ${dir_base_ca}/certs/ca.cert.pem > certs/ca-chain.cert.pem

            chmod 744 certs/ca-chain.cert.pem
        popd
    fi


}

function create_leaf {

    local dir_base_inter=${1}
    local dir_base_leaf=${2}
    local inter_passphrase=${3}
    local leaf_passphrase=${4}
    local org_name=${5}
    local service_name=${6}

    export HOME_INTER=${dir_base_inter}

    edebug_log "Creating leaf cert"

    if [ ! -e "${dir_base_leaf}/certs/${service_name}.pem" ]; then
        pushd ${dir_base_leaf}
            edebug_exec openssl genrsa \
                -out private/leaf.key.pem \
                -passout pass:${leaf_passphrase} \
                2048

            chmod 700 private/leaf.key.pem

            edebug_exec openssl req \
                -config ${dir_base_inter}/openssl.conf \
                -passin pass:${leaf_passphrase} \
                -key private/leaf.key.pem \
                -new \
                -sha256 \
                -out csr/leaf.csr.pem \
                -subj "/C=US/O=${org_name}/CN=${service_name}"

            # CA sign the csr and return a certificate
            edebug_exec openssl ca \
                -batch \
                -config ${dir_base_inter}/openssl.conf \
                -extensions server_cert \
                -days 10 \
                -notext \
                -md sha256 \
                -passin pass:${inter_passphrase} \
                -in csr/leaf.csr.pem \
                -out certs/leaf.cert.pem \
                -subj "/C=US/O=${org_name}/CN=${service_name}"
        popd
    fi

}

# Copy instead of link just in case link poses portability problems
function copy_certs_to_root {

    local org_base=${1}

    cp ${org_base}/intermediate/certs/ca-chain.cert.pem ${org_base}
    cp ${org_base}/leaf/certs/leaf.cert.pem ${org_base}
}

#================================
# Check input parameters
#--------------------------------
if [ $# -ne 3 ]; then
  usage
  exit
fi

#================================
# Assign input parameters
#--------------------------------
BASE=${1}
CONF_BASE=${2}
TEMPLATES_BASE=${3}

# TODO Hardcoded pass phrases for testing
ROOT_PASS=blah
INTER_PASS=blah
LEAF_PASS=blah


description

{
    # Get rid of the first line, Header file in the CSV file
    read
    # while IFS= read -r line; do
    while IFS=, read col_org col_service_name col_root_ns col_inter_ns col_spiffe_id col_expected_result; do
        echo
        elog "Processing certs for org ${col_org}"

        if [ ${col_expected_result} == "PASS" ]; then
            dir_base="${BASE}/good/${col_org}"
        else
            dir_base="${BASE}/bad/${col_org}"
        fi

        dir_base_ca=${dir_base}/ca
        dir_base_inter=${dir_base}/intermediate
        dir_base_leaf=${dir_base}/leaf

        edebug_log "============================"
        edebug_log "org -       " $col_org
        edebug_log "service_name - " $col_service_name
        edebug_log "ns root -   "  $col_root_ns
        edebug_log "ns inter -  " $col_inter_ns
        edebug_log "spiffe_id - " $col_spiffe_id
        edebug_log "dir ca -    " ${dir_base_ca}
        edebug_log "dir inter - " ${dir_base_inter}
        edebug_log "dir leaf -  " ${dir_base_leaf}
        edebug_log "----------------------------"

        setup_root_dirs ${dir_base_ca}
        setup_intermediate_dirs ${dir_base_inter}
        setup_leaf_dirs ${dir_base_leaf}

        setup_confs_templates ${dir_base_ca} ${dir_base_inter} ${TEMPLATES_BASE} "${col_root_ns}" "${col_inter_ns}" ${col_spiffe_id} ${col_san}

        create_trust_root ${dir_base_ca} ${ROOT_PASS} ${col_org}

        create_intermediate ${dir_base_ca} ${dir_base_inter} ${ROOT_PASS} ${INTER_PASS} ${col_org}

        create_leaf ${dir_base_inter} ${dir_base_leaf} ${INTER_PASS} ${LEAF_PASS} ${col_org} ${col_service_name}

        copy_certs_to_root ${dir_base}

        echo -n ${col_spiffe_id} > "${dir_base}/spiffe-id.txt"

    done
} < ${CONF_BASE}/cert_conf.csv
