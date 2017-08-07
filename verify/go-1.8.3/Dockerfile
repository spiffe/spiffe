FROM golang:1.8.3-alpine

MAINTAINER SPIFFE Developers "hello@spiffe.io"

ADD test_spiffe.go /

ENTRYPOINT ["go", "run", "/test_spiffe.go"]
