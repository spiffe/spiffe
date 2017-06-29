# Use a specific version of Ubuntu

FROM alpine:latest

MAINTAINER Emiliano Berenbaum "emiliano@scytale.io"
LABEL Description="OpenSSL SVID test"
LABEL vendor="SPIFFE"

# install openssl
RUN apk add --update openssl && \
    rm -rf /var/cache/apk/*

RUN apk update && apk upgrade && \
    apk add --no-cache bash

ADD ./verify_ca.sh /

WORKDIR /

ENTRYPOINT [ "/verify_ca.sh" ]
