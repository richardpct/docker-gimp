.PHONY: build run exec stop rm

.DEFAULT_GOAL := run
VPATH         := dockerfile
CONTAINER     := gimp
IMAGE         := richardpct/$(CONTAINER)
VOL_DOWNLOADS ?= $(HOME)/container/$(CONTAINER)
INTERFACE     ?= en4
DOCKER_EXISTS := $(shell which docker)

ifndef DOCKER_EXISTS
  $(error docker is not found)
endif

build: Dockerfile
ifneq "$(shell docker image inspect $(IMAGE) > /dev/null 2>&1 && echo exists)" "exists"
	cd dockerfile && \
	docker build -t $(IMAGE) .
endif

run: IP := $(shell ifconfig $(INTERFACE) | awk '/inet /{print $$2}')
run: build
ifeq "$(wildcard $(VOL_DOWNLOADS))" ""
	@mkdir -p $(VOL_DOWNLOADS)
endif

ifneq "$(shell docker container inspect $(CONTAINER) > /dev/null 2>&1 && echo exists)" "exists"
	xhost + $(IP) && \
	docker container run --rm -d \
	-e DISPLAY=$(IP):0 \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	-v $(VOL_DOWNLOADS):/root/Downloads \
	--name $(CONTAINER) \
	$(IMAGE)
endif

exec: run
	docker container exec -it $(CONTAINER) /bin/bash

stop:
ifeq "$(shell docker container inspect $(CONTAINER) > /dev/null 2>&1 && echo exists)" "exists"
	docker container stop $(CONTAINER)
endif

rm: stop
ifeq "$(shell docker image inspect $(IMAGE) > /dev/null 2>&1 && echo exists)" "exists"
	docker image rm $(IMAGE)
endif
