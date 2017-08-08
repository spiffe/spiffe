#==========================
#-------------------------- 
NAME = spiffe/gen/bash

VERSION = 0.1.1

MKDIR_P = mkdir -p 

MY_PWD = $(shell pwd)
SRC_CERTS_DIR = $(MY_PWD)/../.certs
SRC_CONF_DIR  = $(MY_PWD)/conf
SRC_TEMPLATES_DIR = $(MY_PWD)/templates

CERTS_DIR     = /spiffe/certs
CONF_DIR      = /spiffe/conf
TEMPLATES_DIR = /spiffe/templates
GEN_DIR       = /spiffe/svid/gen


.PHONY: all build

build:
	@echo "======================"
	@echo "Create Docker Image"
	@echo "----------------------"
	docker build -t $(NAME):$(VERSION) --rm  .


setup:
	@echo "======================"
	@echo "Setup directories"
	@echo "----------------------"
	$(MKDIR_P) $(SRC_CERTS_DIR)

clean:
	@echo "======================"
	@echo "Cleanup certs: $(SRC_CERTS_DIR)"
	@echo "----------------------"
	rm -Rf $(SRC_CERTS_DIR)/org/*


clean_exited:
	@echo "Cleanup all exited containers"
	docker rm -v $(shell docker ps -a -q -f ancestor=$(NAME):$(VERSION) -f status=exited)

tag_latest:
	docker tag -f $(NAME):$(VERSION) $(NAME):latest


generate:
	@echo "Generate ..."
	docker run -v $(SRC_CERTS_DIR):$(CERTS_DIR) \
	-v $(SRC_CONF_DIR):$(CONF_DIR) \
	-v $(SRC_TEMPLATES_DIR):$(TEMPLATES_DIR) \
	-it $(NAME):$(VERSION) $(GEN_DIR)/generate_ca.sh  $(CERTS_DIR) $(CONF_DIR) $(TEMPLATES_DIR)


run:
	@echo "Run container: $(NAME)"
	docker run -v $(SRC_CERTS_DIR):$(CERTS_DIR) \
	-v $(SRC_TEMPLATES_DIR):$(TEMPLATES_DIR) \
	-v $(SRC_CONF_DIR):$(CONF_DIR) -it $(NAME):$(VERSION) /bin/bash

last_build_date:
	docker inspect -f '{{ .Created }}' $(NAME):$(VERSION)
