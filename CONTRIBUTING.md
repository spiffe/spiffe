# Contributing

## Adding Test Modules
Each test module has a dedicated subdirectory which stores a Dockerfile and any other required files or config. The suite will build each docker container and execute its entrypoint, passing the SPIFFE ID as the only argument.

The CA chain is located at `/certs/ca-chain.cert.pem` and the leaf cert to validate is located at `/certs/leaf.cert.pem`. If the certificate validates successfully against the trust chain and ID argument, the container should exit 0. Otherwise, print the error and exit non-zero.

## Submit a Pull Request
1. Fork this repo
1. Make your changes in a feature branch
1. Ensure all tests are passing (Make from the project root)
1. Submit a pull request against the Master branch of this repo

This repository follows strict code review guidelines. Pull Requests must receive at least two approvals before they can be merged.

For more information about how to add tests to the suite, please see README.md
