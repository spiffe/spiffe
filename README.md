# SVID TEST 

## Requirements
1. Make
1. Docker
1. Python 2.7+
1. Virtualenv

## Running the tests
SPIFFE certificates can be generated and tested in a single step by simply calling Make, which will exit non-zero if unsuccessful. Relevant error messages will also be printed at that time.

## Adding new tests
SPIFFE validation tests are very straight-forward. Each language/library in the suite has a dedicated subdirectory which stores a Dockerfile and any other required files or config. The suite will build each docker container and execute its entrypoint. If the certificate validates successfully, the container should exit 0. Otherwise, print the error and exit non-zero.

Generated SPIFFE certificates will be mounted into the `/certs` directory. The CA chain is located at `/certs/ca-chain.cert.pem` and the leaf cert to validate is located at `/certs/leaf.cert.pem`. The rest is up to you.