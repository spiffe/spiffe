# Use a specific version of Ubuntu


FROM python:3.6

MAINTAINER Emiliano Berenbaum "emiliano@scytale.io"
LABEL Description="Python shell SVID testing"
LABEL vendor="Spiffe"

RUN apt-get install -qy libssl-dev

#
ADD  ./spiffe  /spiffe/svid/gen

WORKDIR /spiffe/svid/gen

RUN pip3 install --upgrade pip
RUN pip3 install -r requirements/dev.txt
