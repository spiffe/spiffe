#!/bin/bash

set -o pipefail
set -e

# generate root CA directories
echo "### Building Root CA"
mkdir -p root/ca
pushd root/ca
  mkdir certs crl newcerts private
  chmod 700 private
  touch index.txt
  echo 1000 > serial
popd

cp root_openssl.conf root/ca/openssl.conf

# build root CA
pushd root/ca
  openssl genrsa -aes256 -out private/ca.key.pem 4096
  chmod 400 private/ca.key.pem
  openssl req -config openssl.conf -key private/ca.key.pem -new -x509 -days 7300 -sha256 -extensions v3_ca -out certs/ca.cert.pem
  chmod 444 certs/ca.cert.pem
  openssl x509 -noout -text -in certs/ca.cert.pem
popd

# build intermediate Certs
echo "#### Building Intermediate CA"
mkdir -p root/ca/intermediate
pushd root/ca/intermediate
  mkdir certs crl csr newcerts private
  chmod 700 private
  touch index.txt
  echo 1000 > serial
  echo 1000 > crlnumber
popd

cp intermediate_openssl.conf root/ca/intermediate/openssl.conf

pushd root/ca
  openssl genrsa -aes256 -out intermediate/private/intermediate.key.pem 4096
  chmod 400 intermediate/private/intermediate.key.pem
  openssl req -config intermediate/openssl.conf -new -sha256  -key intermediate/private/intermediate.key.pem -out intermediate/csr/intermediate.csr.pem

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


# create server and client certificates

echo "#### Building Server and Client example certificated"
pushd root/ca
  openssl genrsa -out intermediate/private/www.example.com.key.pem 2048
  chmod 400 intermediate/private/www.example.com.key.pem

  openssl req -config intermediate/openssl.conf \
      -key intermediate/private/www.example.com.key.pem \
      -new -sha256 -out intermediate/csr/www.example.com.csr.pem

  # CA sign the csr and return a certificate
  openssl ca -config intermediate/openssl.conf -extensions server_cert -days 375 -notext -md sha256 -in intermediate/csr/www.example.com.csr.pem -out intermediate/certs/www.example.com.cert.pem

  openssl x509 -noout -text \
      -in intermediate/certs/www.example.com.cert.pem

  openssl verify -CAfile intermediate/certs/ca-chain.cert.pem \
      intermediate/certs/www.example.com.cert.pem
popd
