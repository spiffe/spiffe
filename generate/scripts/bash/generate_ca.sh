#!/bin/bash

set -o pipefail
set -e

BASH_XTRACEFD="5"
PS4='$LINENO: '
set -x

if [ -z "$1" -o -z "$2" ]; then
  echo "Usage ./generate_ca.sh <org_domain> <service_name> <base_directory>"
  echo "eg. ./generate_ca.sh acme.com blogserver ${PWD}/../../.certs/"
  exit
fi

SPIFFE_CERT_ORG_NAME=${1}
SPIFFE_CERT_SERVICE_NAME=${2}
BASE=${3}

# Set global variables
SPIFFE_BASE="${BASE}/org/${SPIFFE_CERT_ORG_NAME}/ca/"
CONF_BASE=/spiffe/conf

echo "### This script will lead you through the generation of a root "
echo "### certificate keypair, intermediate cert keypair, and a final"
echo "### SPIFFEdf certificate suitable for use in mTLS"
echo "###   ORG:         ${SPIFFE_CERT_ORG_NAME}"
echo "###   SERVICE ID:  ${SPIFFE_CERT_SERVICE_NAME}"
echo "###   BASE:        ${BASE}"
echo "###   SPIFFE_BASE: ${SPIFFE_BASE}"
echo "################################################################"


echo "### Building Root CA"
if [ ! -e "${SPIFFE_BASE}/serial" ]; then

  # generate root CA directories
  mkdir -p ${SPIFFE_BASE}
  pushd ${SPIFFE_BASE}
    mkdir certs crl newcerts private
    chmod 700 private
    touch index.txt
    echo 1000 > serial
  popd
fi

if [ ! -e "${SPIFFE_BASE}/openssl.conf" ]; then
  cp ${CONF_BASE}/root_openssl.conf ${SPIFFE_BASE}/openssl.conf
fi

if [ ! -e "${SPIFFE_BASE}/certs/ca.cert.pem" ]; then

  # build root CA
  pushd ${SPIFFE_BASE}
    openssl genrsa -aes256 -out private/ca.key.pem 4096
    chmod 700 private/ca.key.pem
    openssl req \
      -config openssl.conf \
      -key private/ca.key.pem \
      -new \
      -x509 \
      -days 7300 \
      -sha256 \
      -extensions v3_ca \
      -out certs/ca.cert.pem \
      -subj "/O=${SPIFFE_CERT_ORG_NAME}/CN=${SPIFFE_CERT_ORG_NAME} Root CA"
    chmod 744 certs/ca.cert.pem
    openssl x509 -noout -text -in certs/ca.cert.pem
  popd
fi

echo "#### Building Intermediate CA"
if [ ! -e "${SPIFFE_BASE}/intermediate/crlnumber" ]; then
  # build intermediate Certs
  mkdir -p ${SPIFFE_BASE}/intermediate
  pushd ${SPIFFE_BASE}/intermediate
    mkdir certs crl csr newcerts private
    chmod 700 private
    touch index.txt
    echo 1000 > serial
    echo 1000 > crlnumber
  popd
fi

if [ ! -e "${SPIFFE_BASE}/intermediate/openssl.conf" ]; then
  cp ${CONF_BASE}/intermediate_openssl.conf ${SPIFFE_BASE}/intermediate/openssl.conf
fi

if [ ! -e "${SPIFFE_BASE}/intermediate/certs/ca-chain.cert.pem" ]; then
  pushd ${SPIFFE_BASE}

    echo "Create intermediate keypair..."
    openssl genrsa -aes256 -out intermediate/private/intermediate.key.pem 4096
    chmod 700 intermediate/private/intermediate.key.pem
    openssl req \
        -config intermediate/openssl.conf \
        -new \
        -sha256 \
        -key intermediate/private/intermediate.key.pem \
        -out intermediate/csr/intermediate.csr.pem \
        -subj "/O=${SPIFFE_CERT_ORG_NAME}/CN=$SPIFFE_CERT_ORG_NAME Intermediate CA" \

    # sign the intermediate with the root
    openssl ca -config openssl.conf -extensions v3_intermediate_ca \
        -days 3650 -notext -md sha256 \
        -in intermediate/csr/intermediate.csr.pem \
        -out intermediate/certs/intermediate.cert.pem

    chmod 444 intermediate/certs/intermediate.cert.pem
    openssl x509 -noout -text \
            -in intermediate/certs/intermediate.cert.pem

    cat intermediate/certs/intermediate.cert.pem \
      certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem
    chmod 744 intermediate/certs/ca-chain.cert.pem
  popd
fi

echo "#### Building Server and Client example certificates"
if [ ! -e "${SPIFFE_BASE}/intermediate/certs/${SPIFFE_CERT_SERVICE_NAME}.pem" ]; then
  pushd ${SPIFFE_BASE}
    # create server and client certificate
    echo "Create service ${SPIFFE_CERT_SERVICE_NAME} keypair..."
    openssl genrsa -out intermediate/private/${SPIFFE_CERT_SERVICE_NAME}.key.pem 2048
    chmod 700 intermediate/private/${SPIFFE_CERT_SERVICE_NAME}.key.pem

    openssl req -config intermediate/openssl.conf \
      -key intermediate/private/${SPIFFE_CERT_SERVICE_NAME}.key.pem \
      -new \
      -sha256 \
      -out intermediate/csr/${SPIFFE_CERT_SERVICE_NAME}.csr.pem \
      -subj "/C=US/O=${SPIFFE_CERT_ORG_NAME}/CN=spiffe:${SPIFFE_CERT_ORG_NAME}:${SPIFFE_CERT_SERVICE_NAME}"

    # CA sign the csr and return a certificate
    openssl ca -config intermediate/openssl.conf \
      -extensions server_cert \
      -days 375 \
      -notext \
      -md sha256 \
      -in intermediate/csr/${SPIFFE_CERT_SERVICE_NAME}.csr.pem \
      -out intermediate/certs/${SPIFFE_CERT_SERVICE_NAME}.cert.pem \
      -subj "/C=US/O=${SPIFFE_CERT_ORG_NAME}/CN=spiffe:${SPIFFE_CERT_ORG_NAME}:${SPIFFE_CERT_SERVICE_NAME}"

    openssl x509 -noout -text \
        -in intermediate/certs/${SPIFFE_CERT_SERVICE_NAME}.cert.pem
  popd
fi

openssl verify -CAfile ${SPIFFE_BASE}/intermediate/certs/ca-chain.cert.pem \
    ${SPIFFE_BASE}/intermediate/certs/${SPIFFE_CERT_SERVICE_NAME}.cert.pem
