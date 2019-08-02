.DEFAULT_GOAL := help
AWK           := /usr/bin/awk
DOCKER        := /usr/local/bin/docker
VPATH         := dockerfile
BUILD         := .build
CONTAINER     := gimp
IMAGE         := richardpct/$(CONTAINER)
VOL_SHARE     ?= $(HOME)/container/$(CONTAINER)
INTERFACE     ?= en4

# If default DOCKER does not exist then looks for in PATH variable
ifeq "$(wildcard $(DOCKER))" ""
  DOCKER_FOUND := $(shell which docker)
  DOCKER = $(if $(DOCKER_FOUND),$(DOCKER_FOUND),$(error docker is not found))
endif

# $(call docker-image-rm)
define docker-image-rm
  if $(DOCKER) image inspect $(IMAGE) > /dev/null 2>&1 ; then \
    $(DOCKER) image rm $(IMAGE); \
    rm -f $(BUILD); \
  fi
endef

# $(call docker-container-stop)
define docker-container-stop
  if $(DOCKER) container inspect $(CONTAINER) > /dev/null 2>&1 ; then \
    $(DOCKER) container stop $(CONTAINER); \
  fi
endef

.PHONY: help
help: ## Show help
	@echo "Usage: make [VOL_SHARE=/tmp] TARGET\n"
	@echo "Targets:"
	@$(AWK) -F ":.* ##" '/.*:.*##/{ printf "%-13s%s\n", $$1, $$2 }' \
	$(MAKEFILE_LIST) \
	| grep -v AWK

.PHONY: build
build: $(BUILD) ## Build the image from the Dockerfile

.build: Dockerfile
	$(call docker-container-stop)
	$(call docker-image-rm)

	cd dockerfile && \
	$(DOCKER) build -t $(IMAGE) .
	@touch $@

.PHONY: run
run: IP := $(shell ifconfig $(INTERFACE) | awk '/inet /{print $$2}')
run: $(BUILD) ## Run the container
ifeq "$(wildcard $(VOL_SHARE))" ""
	@mkdir -p $(VOL_SHARE)
endif

	if ! $(DOCKER) container inspect $(CONTAINER) > /dev/null 2>&1 ; then \
	  xhost + $(IP); \
	  $(DOCKER) container run --rm -d \
	  -e DISPLAY=$(IP):0 \
	  -v /tmp/.X11-unix:/tmp/.X11-unix \
	  -v $(VOL_SHARE):/root/Share \
	  --name $(CONTAINER) \
	  $(IMAGE); \
	fi

.PHONY: shell
shell: run ## Get a shell into the container
	$(DOCKER) container exec -it $(CONTAINER) /bin/bash

.PHONY: stop
stop: ## Stop the container
	$(call docker-container-stop)

.PHONY: clean
clean: stop ## Delete the image
	$(call docker-image-rm)
