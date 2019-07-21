.DEFAULT_GOAL := run
VPATH         := dockerfile
BUILD         := .build
CONTAINER     := gimp
IMAGE         := richardpct/$(CONTAINER)
VOL_SHARE     ?= $(HOME)/container/$(CONTAINER)
INTERFACE     ?= en4
DOCKER_EXISTS := $(shell which docker)

ifndef DOCKER_EXISTS
  $(error docker is not found)
endif

# $(call docker-image-rm)
define docker-image-rm
  if docker image inspect $(IMAGE) > /dev/null 2>&1 ; then \
    docker image rm $(IMAGE); \
    rm -f $(BUILD); \
  fi
endef

# $(call docker-container-stop)
define docker-container-stop
  if docker container inspect $(CONTAINER) > /dev/null 2>&1 ; then \
    docker container stop $(CONTAINER); \
  fi
endef

.PHONY: build
build: $(BUILD)

.build: Dockerfile
	$(call docker-container-stop)
	$(call docker-image-rm)

	cd dockerfile && \
	docker build -t $(IMAGE) .
	@touch $@

.PHONY: run
run: IP := $(shell ifconfig $(INTERFACE) | awk '/inet /{print $$2}')
run: $(BUILD)
ifeq "$(wildcard $(VOL_SHARE))" ""
	@mkdir -p $(VOL_SHARE)
endif

	if ! docker container inspect $(CONTAINER) > /dev/null 2>&1 ; then \
	  xhost + $(IP); \
	  docker container run --rm -d \
	  -e DISPLAY=$(IP):0 \
	  -v /tmp/.X11-unix:/tmp/.X11-unix \
	  -v $(VOL_SHARE):/root/Share \
	  --name $(CONTAINER) \
	  $(IMAGE); \
	fi

.PHONY: exec
exec: run
	docker container exec -it $(CONTAINER) /bin/bash

.PHONY: stop
stop:
	$(call docker-container-stop)

.PHONY: rm
rm: stop
	$(call docker-image-rm)
