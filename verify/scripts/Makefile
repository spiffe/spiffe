#==========================
#-------------------------- 
NAME = spiffe/verify/bash

VERSION = 0.1.1

MKDIR_P = mkdir -p
RMDIR   = rmdir -Rf 

MY_PWD = $(shell pwd)
SRC_CERTS_DIR = $(MY_PWD)/../../.certs
SRC_CONF_DIR  = $(MY_PWD)/../../conf
SRC_RESULTS_DIR = $(MY_PWD)/../../.results/bash/openssl

CERTS_DIR     = /spiffe/certs
CONF_DIR      = /spiffe/conf
VERIFY_DIR    = /spiffe/svid/verify
RESULTS_DIR   = /spiffe/results

ORG_NAME     ?= acme.com
SERVICE_NAME ?= blog

.PHONY: all build

build:
	@echo "======================"
	@echo "Create Docker Image"
	@echo "----------------------"
	docker build -t $(NAME):$(VERSION) --rm  .

setup:
	@echo "======================"
	@echo "Setup directory: $(SRC_RESULTS_DIR) "
	@echo "----------------------"
	$(MKDIR_P) $(SRC_RESULTS_DIR)

cleanup:
	@echo "======================"
	@echo "Cleaup results directory $(SRC_RESULTS_DIR)"
	@echo "----------------------"
	$(RMDIR) $(SRC_RESULTS_DIR)



clean_exited:
	@echo "Cleanup all exited containers"
	docker rm -v $(shell docker ps -a -q -f ancestor=$(NAME):$(VERSION) -f status=exited)

tag_latest:
	docker tag -f $(NAME):$(VERSION) $(NAME):latest


verify:
	@echo "Verify ..."
	docker run -v $(SRC_CERTS_DIR):$(CERTS_DIR) \
	-v $(SRC_CONF_DIR):$(CONF_DIR) \
	-v $(SRC_RESULTS_DIR):$(RESULTS_DIR) \
	-it $(NAME):$(VERSION) $(VERIFY_DIR)/verify_ca.sh  $(CERTS_DIR) $(CONF_DIR)  $(RESULTS_DIR) 

run:
	@echo "Run container: $(NAME)"
	docker run -v $(SRC_CERTS_DIR):$(CERTS_DIR) \
	-v $(SRC_CONF_DIR):$(CONF_DIR) \
	-v $(SRC_RESULTS_DIR):$(RESULTS_DIR) \
	-it $(NAME):$(VERSION) /bin/bash

last_build_date:
	docker inspect -f '{{ .Created }}' $(NAME):$(VERSION)
