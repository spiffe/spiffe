#==========================
#-------------------------- 

VENV=.venv
VDIR=$(PWD)/$(VENV)

NAME = spiffe/gen/python

VERSION = 0.1.0
SRC_CERTS_DIR = ${PWD}/../.certs
SRC_CONF_DIR  = ${PWD}/conf

CERTS_DIR = /spiffe/certs
CONF_DIR  = /spiffe/conf

GEN_DIR = /spiffe/svid/gen
INTERMEDIATE_DIR = $(CERTS_DIR)/org/acme.com/ca/intermediate
SECRET     ?= default 
PASSPHRASE ?= default

.PHONY: all build

build:
	@echo "======================"
	@echo "Create Docker Image"
	@echo "----------------------"
	docker build -t $(NAME):$(VERSION) --rm .


clean_exited:
	@echo "Cleanup all exited containers"
	docker rm -v $(shell docker ps -a -q -f ancestor=$(NAME):$(VERSION) -f status=exited)


tag_latest:
	docker tag -f $(NAME):$(VERSION) $(NAME):latest


run:
	@echo "Run container: $(NAME)"
	docker run -v $(SRC_CERTS_DIR):$(CERTS_DIR) -v $(SRC_CONF_DIR):$(CONF_DIR) -it $(NAME):$(VERSION) /bin/bash

generate:
	@echo "Run container: $(NAME)"
	docker run -v $(SRC_CERTS_DIR):$(CERTS_DIR) -v $(SRC_CONF_DIR):$(CONF_DIR) -it $(NAME):$(VERSION) python3 spiffe.py --path=$(INTERMEDIATE_DIR)/  --pass=$(PASSPHRASE) --secret=$(SECRET) --config=$(CONF_DIR)/sample_config.ini --target=$(CERTS_DIR)


last_build_date:
	docker inspect -f '{{ .Created }}' $(NAME):$(VERSION)
