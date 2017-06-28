# SVID TEST 

## Requirements
1. Docker
1. Python 2.7+
1. Virtualenv

## Running the tests
SPIFFE certificates can be generated and tested in a single step by simply calling Make, which will exit non-zero if unsuccessful. Relevant error messages will also be printed at that time.

## Adding new tests
SPIFFE validation tests are very straight-forward. Each language/library in the suite has a dedicated subdirectory which stores a Dockerfile and any other required files or config. The suite will build each docker container and execute its entrypoint. If all certificates validate successfully, the container should exit 0. Otherwise, print the error and exit non-zero.

A subset of the generated certificates are designed to fail validation. In these cases, failure detection needs to be inverted. The test suite will pass `--bad-certs` as an argument to the entrypoint when testing such certificates. Ensure that this flag inverts the behavior, as specified.

Generated SPIFFE certificates will be mounted into the `/certs` directory. The rest is up to you.