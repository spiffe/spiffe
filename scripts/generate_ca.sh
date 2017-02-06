#!/bin/bash

set -o pipefail
set -e

echo "### This script will lead you through the generation of a root "
echo "### cerfiicate keypair, intermediate cert keypair, and a final"
echo "### SPIFFE certificate suitable for use in mTLS"
echo "################################################################"

SPIFFE_CERT_ORG_NAME="acme.com"
SPIFFE_CERT_SERVICE_NAME="www.example.com"

echo "### Building Root CA"
if [ ! -e "root/ca/serial" ]; then
  # generate root CA directories
  mkdir -p root/ca
  pushd root/ca
    mkdir certs crl newcerts private
    chmod 700 private
    touch index.txt
    echo 1000 > serial
  popd
fi

if [ ! -e "root/ca/openssl.conf" ]; then
  cp root_openssl.conf root/ca/openssl.conf
fi

if [ ! -e "root/ca/certs/ca.cert.pem" ]; then
  # build root CA
  pushd root/ca
    openssl genrsa -aes256 -out private/ca.key.pem 4096
    chmod 400 private/ca.key.pem
    openssl req -config openssl.conf -key private/ca.key.pem -new -x509 -days 7300 -sha256 -extensions v3_ca -out certs/ca.cert.pem -subj "/O=$SPIFFE_CERT_ORG_NAME/CN=Root"
    chmod 444 certs/ca.cert.pem
    openssl x509 -noout -text -in certs/ca.cert.pem
  popd
fi

echo "#### Building Intermediate CA"
if [ ! -e "root/ca/intermediate/crlnumber" ]; then
  # build intermediate Certs
  mkdir -p root/ca/intermediate
  pushd root/ca/intermediate
    mkdir certs crl csr newcerts private
    chmod 700 private
    touch index.txt
    echo 1000 > serial
    echo 1000 > crlnumber
  popd
fi

if [ ! -e "root/ca/intermediate/openssl.conf" ]; then
  cp intermediate_openssl.conf root/ca/intermediate/openssl.conf
fi

if [ ! -e "root/ca/intermediate/certs/ca-chain.cert.pem" ]; then
  pushd root/ca
    openssl genrsa -aes256 -out intermediate/private/intermediate.key.pem 4096
    chmod 700 intermediate/private/intermediate.key.pem
    openssl req -config intermediate/openssl.conf -new -sha256  \
        -key intermediate/private/intermediate.key.pem \
        -out intermediate/csr/intermediate.csr.pem \
        -subj "/O=$SPIFFE_CERT_ORG_NAME/CN=Intermediate"

    #sign the intermediate with the root
    openssl ca -config openssl.conf -extensions v3_intermediate_ca \
        -days 3650 -notext -md sha256 \
        -in intermediate/csr/intermediate.csr.pem \
        -out intermediate/certs/intermediate.cert.pem

    chmod 444 intermediate/certs/intermediate.cert.pem
    openssl x509 -noout -text \
            -in intermediate/certs/intermediate.cert.pem

    cat intermediate/certs/intermediate.cert.pem \
      certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem
    chmod 444 intermediate/certs/ca-chain.cert.pem
  popd
fi

echo "#### Building Server and Client example certificates"
if [ ! -e "root/ca/intermediate/certs/$SPIFFE_CERT_SERVICE_NAME.pem" ]; then
  # create server and client certificates
  pushd root/ca
    openssl genrsa -out intermediate/private/$SPIFFE_CERT_SERVICE_NAME.key.pem 2048
    chmod 700 intermediate/private/$SPIFFE_CERT_SERVICE_NAME.key.pem

    openssl req -config intermediate/openssl.conf \
        -key intermediate/private/$SPIFFE_CERT_SERVICE_NAME.key.pem \
        -new -sha256 -out intermediate/csr/$SPIFFE_CERT_SERVICE_NAME.csr.pem \
        -subj "/C=US/O=$SPIFFE_CERT_ORG_NAME/CN=$SPIFFE_CERT_SERVICE_NAME"

    # CA sign the csr and return a certificate
    openssl ca -config intermediate/openssl.conf -extensions server_cert -days 375 -notext -md sha256 -in intermediate/csr/www.example.com.csr.pem -out intermediate/certs/www.example.com.cert.pem -subj "/O=$SPIFFE_CERT_ORG_NAME/CN=$SPIFFE_CERT_SERVICE_NAME"

    openssl x509 -noout -text \
        -in intermediate/certs/$SPIFFE_CERT_SERVICE_NAME.cert.pem

    openssl verify -CAfile intermediate/certs/ca-chain.cert.pem \
        intermediate/certs/$SPIFFE_CERT_SERVICE_NAME.cert.pem
  popd
fi
