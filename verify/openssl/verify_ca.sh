#!/bin/bash

# The return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero status,
# or zero if all commands in the pipeline exit successfully:
set -o pipefail
set -e

OPENSSL_RC=0

function esilent_exec() {
    EXEC_MSG=$( "$@" 2>/dev/null )
}

function usage  {
    echo "Usage ./verify_ca.sh"
}

function verify {
    set +e
    esilent_exec openssl verify -CAfile /certs/ca-chain.cert.pem \
           /certs/leaf.cert.pem
    OPENSSL_RC=$?
    set -e
}

#================================
# Check input parameters
#--------------------------------
if [ $# -gt 1 ] ; then
    usage
    exit 1
fi

OPENSSL_VERSION=$(openssl version)

verify

if [ $OPENSSL_RC -ne 0 ]; then
    echo "Failed ${OPENSSL_VERSION} with ${EXEC_MSG}"
    exit 1
fi
