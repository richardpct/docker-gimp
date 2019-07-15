.PHONY: build run exec stop rm

.DEFAULT_GOAL := run
VPATH         := dockerfile
BUILD         := .build
CONTAINER     := gimp
IMAGE         := richardpct/$(CONTAINER)
VOL_DOWNLOADS ?= $(HOME)/container/$(CONTAINER)
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

build: $(BUILD)

.build: Dockerfile
	$(call docker-container-stop)
	$(call docker-image-rm)

	cd dockerfile && \
	docker build -t $(IMAGE) .
	@touch $@

run: IP := $(shell ifconfig $(INTERFACE) | awk '/inet /{print $$2}')
run: $(BUILD)
ifeq "$(wildcard $(VOL_DOWNLOADS))" ""
	@mkdir -p $(VOL_DOWNLOADS)
endif

	if ! docker container inspect $(CONTAINER) > /dev/null 2>&1 ; then \
	  xhost + $(IP); \
	  docker container run --rm -d \
	  -e DISPLAY=$(IP):0 \
	  -v /tmp/.X11-unix:/tmp/.X11-unix \
	  -v $(VOL_DOWNLOADS):/root/Downloads \
	  --name $(CONTAINER) \
	  $(IMAGE); \
	fi

exec: run
	docker container exec -it $(CONTAINER) /bin/bash

stop:
	$(call docker-container-stop)

rm: stop
	$(call docker-image-rm)
