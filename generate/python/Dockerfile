
# Use a specific version of Ubuntu

FROM ubuntu:latest
MAINTAINER Emiliano Berenbaum "emiliano@scytale.io"

RUN apt-get -y update
RUN apt-get install -qy libssl-dev
RUN apt-get install -qy python3
RUN apt-get install -qy python3-pip

#
ADD . /svid_gen_leaf

WORKDIR /svid_gen_leaf

RUN pip3 install --upgrade pip
RUN pip3 install -r spiffe/requirements/dev.txt
