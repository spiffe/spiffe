#==========================
#-------------------------- 
NAME = spiffe/verify/bash

VERSION = 0.1.1

MKDIR_P = mkdir -p
RMDIR   = rmdir -Rf 

MY_PWD = $(shell pwd)
SRC_CERTS_DIR = $(MY_PWD)/../../.certs/good

CERTS_DIR     = /certs

ORG_NAME     ?= acme.com
SERVICE_NAME ?= blog

.PHONY: all build

build:
	@echo "======================"
	@echo "Create Docker Image"
	@echo "----------------------"
	docker build -t $(NAME):$(VERSION) --rm  .

clean_exited:
	@echo "Cleanup all exited containers"
	docker rm -v $(shell docker ps -a -q -f ancestor=$(NAME):$(VERSION) -f status=exited)

verify:
	@echo "Verify ..."
	docker run -v $(SRC_CERTS_DIR):$(CERTS_DIR) \
	-it $(NAME):$(VERSION) $(CERTS_DIR)

last_build_date:
	docker inspect -f '{{ .Created }}' $(NAME):$(VERSION)
