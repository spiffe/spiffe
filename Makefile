NAME = spiffe/svid-test

VERSION = 0.2.1

.PHONY: all generate verify

default: all

all: generate verify

generate:
	make -C generate setup build generate clean_exited

verify:
	make -C verify/scripts setup build verify clean_exited
