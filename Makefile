NAME = spiffe/svid-test
VERSION = 0.2.1

.PHONY: all generate verify

default: all

all: .venv generate verify

.venv:
	virtualenv .venv
	.venv/bin/pip install pytest
	.venv/bin/pip install docker

generate:
	make -C generate setup build generate clean_exited

verify: .venv
	make -C verify/openssl build verify clean_exited
