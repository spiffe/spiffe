#!/bin/bash

set -o pipefail
set -e

BASH_XTRACEFD="5"
PS4='$LINENO: '
set -x

function usage  {
  echo "Usage ./verify_ca.sh <service_name> <base_directory> <config_directory>"
  echo "eg. ./verify_ca.sh acme.com blogserver ${PWD}/../../.certs/ ${PWD/conf}"

}

function description {

  echo "################################################################"
  echo "### This script will lead you through the generation of a root "
  echo "### certificate keypair, intermediate cert keypair, and a final"
  echo "### SPIFFEdf certificate suitable for use in mTLS"
  echo "###   SERVICE ID:  ${SPIFFE_CERT_SERVICE_NAME}"
  echo "###   BASE:        ${BASE}"
  echo "###   SPIFFE_BASE: ${SPIFFE_BASE}"
  echo "----------------------------------------------------------------"

}


function verify {
    openssl verify -CAfile ${SPIFFE_BASE}/intermediate/certs/ca-chain.cert.pem \
        ${SPIFFE_BASE}/intermediate/certs/${SPIFFE_CERT_SERVICE_NAME}.cert.pem

}


#=================================
#---------------------------------
#================================
# Check input parameters
#--------------------------------
if [ $# -ne 3 ]; then
  usage
  exit
fi


SPIFFE_CERT_SERVICE_NAME=${1}
BASE=${2}

# Set global variables
SPIFFE_BASE="${BASE}/org/${SPIFFE_CERT_ORG_NAME}/ca/"
CONF_BASE=${3}



verify