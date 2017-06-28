FROM alpine:latest

MAINTAINER Emiliano Berenbaum "emiliano@scytale.io"
LABEL Description="OpenSSL shell SVID generation"
LABEL vendor="Spiffe"

# install openssl
RUN apk add --update openssl && \
    rm -rf /var/cache/apk/*

RUN apk update && apk upgrade && \
    apk add --no-cache bash git


ADD ./generate_ca.sh /spiffe/svid/gen/generate_ca.sh

WORKDIR /spiffe/svid/gen

# Copy Library repos
RUN git clone https://github.com/tests-always-included/mo.git  ./.lib/mo
RUN git clone https://github.com/geoffroy-aubry/awk-csv-parser.git ./.lib/awk-csv-parser


# TODO: Setup entry point to simplify the Makefile
# ENTRYPOINT [ "/spiffe/svid/gen/generate_ca.sh"]