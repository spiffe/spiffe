# Use a specific version of Ubuntu

FROM alpine:latest

MAINTAINER Emiliano Berenbaum "emiliano@scytale.io"
LABEL Description="OpenSSL shell SVID generation"
LABEL vendor="Spiffe"

# install openssl
RUN apk add --update openssl && \
    rm -rf /var/cache/apk/*


#
ADD ./bash /spiffe/svid/verify

WORKDIR /spiffe/svid/verify

ENTRYPOINT [ "/spiffe/svid/verify/verify_ca.sh" ]
