# Use a specific version of Ubuntu

FROM alpine:latest

MAINTAINER Emiliano Berenbaum "emiliano@scytale.io"
LABEL Description="OpenSSL shell SVID generation"
LABEL vendor="Spiffe"

# install openssl
RUN apk add --update openssl && \
    rm -rf /var/cache/apk/*

RUN apk update && apk upgrade && \
    apk add --no-cache bash

ADD ./verify_ca.sh /

WORKDIR /

ENTRYPOINT [ "/verify_ca.sh" ]
