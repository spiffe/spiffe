# Use a specific version of Ubuntu

FROM ubuntu:latest
MAINTAINER Emiliano Berenbaum "emiliano@scytale.io"
LABEL Description="OpenSSL shell SVID generation"
LABEL vendor="Spiffe"

RUN apt-get -y update
RUN apt-get install -qy libssl-dev
RUN apt-get install -qy openssl

#
ADD ./bash /spiffe/svid/gen

WORKDIR /spiffe/svid/gen
