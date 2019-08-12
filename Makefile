.DEFAULT_GOAL := help
AWK           := awk
DOCKER        := /usr/local/docker
VPATH         := dockerfile
BUILD         := .build
CONTAINER     := gimp
IMAGE         := richardpct/$(CONTAINER)
VOL_SHARE     ?= $(HOME)/container/$(CONTAINER)

# If DOCKER does not exist then looks for in the PATH variable
ifeq "$(wildcard $(DOCKER))" ""
  DOCKER_FOUND := $(shell which docker)
  DOCKER = $(if $(DOCKER_FOUND),$(DOCKER_FOUND),$(error docker is not found))
endif

# Retrieve your private IP whether the target is run or shell
ifeq "$(MAKECMDGOALS)" "$(filter $(MAKECMDGOALS), run shell)"
  IP := $(shell ifconfig | $(AWK) '/inet 192\.168\./{print $$2}' 2>/dev/null | head -n 1)
  ifndef IP
    $(error Your private IP is not found)
  endif
endif

# $(call docker-image-rm)
define docker-image-rm
  if $(DOCKER) image inspect $(IMAGE) > /dev/null 2>&1; then \
    $(DOCKER) image rm $(IMAGE); \
    rm -f $(BUILD); \
  fi
endef

# $(call docker-container-stop)
define docker-container-stop
  if $(DOCKER) container inspect $(CONTAINER) > /dev/null 2>&1; then \
    $(DOCKER) container stop $(CONTAINER); \
  fi
endef

.PHONY: help
help: ## Show help
	@echo "Usage: make [VOL_SHARE=/tmp] TARGET\n"
	@echo "Targets:"
	@$(AWK) -F ":.* ##" '/.*:.*##/{printf "%-13s%s\n", $$1, $$2}' \
	$(MAKEFILE_LIST) \
	| grep -v AWK

$(VOL_SHARE):
	@mkdir -p $@

.PHONY: build
build: $(BUILD) ## Build the image from the Dockerfile

$(BUILD): Dockerfile
	$(call docker-container-stop)
	$(call docker-image-rm)

	cd dockerfile && \
	$(DOCKER) build -t $(IMAGE) .
	@touch $@

.PHONY: shell
shell: run ## Get a shell into the container
	$(DOCKER) container exec -it $(CONTAINER) /bin/bash

.PHONY: run
run: $(VOL_SHARE) $(BUILD) ## Run the container
	if ! $(DOCKER) container inspect $(CONTAINER) > /dev/null 2>&1 ;then \
	  xhost + $(IP); \
	  $(DOCKER) container run --rm -d \
	  -e DISPLAY=$(IP):0 \
	  -v /tmp/.X11-unix:/tmp/.X11-unix \
	  -v $(VOL_SHARE):/root/Share \
	  --name $(CONTAINER) \
	  $(IMAGE); \
	fi

.PHONY: clean
clean: stop ## Delete the image
	$(call docker-image-rm)

.PHONY: stop
stop: ## Stop the container
	$(call docker-container-stop)
