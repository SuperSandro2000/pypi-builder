.DEFAULT_GOAL := $(if ${CI},all,all-docker-native)
MAKEFLAGS=--warn-undefined-variables
SHELL := /bin/bash

# `uname -m` does not use arm64 but instead aarch64. We need to translate this.
NATIVE_ARCH_x86_64 := amd64
NATIVE_ARCH_aarch64 := arm64
NATIVE_ARCH_amd64 := amd64
NATIVE_ARCH_arm64 := arm64
NATIVE_ARCH_armhf := armhf
NATIVE_ARCH_armv7l := armhf
# Official Docker Images do not use arm64 but instead arm64v8. We need to translate this.
DOCKER_ARCH_amd64 := amd64
DOCKER_ARCH_arm64 := arm64v8
DOCKER_ARCH_armhf := arm32v7

ARCH ?= $(shell uname -m)
CI ?=
DIR ?= packages
DIST ?= alpine # tested with alpine and buster
PY_VERSION ?= 3
PIP ?= Kibitzr psycopg2-binary Red-DiscordBot -r https://github.com/HelloZeroNet/ZeroNet/raw/py3/requirements.txt
REPO ?= https://pypi.supersandro.de/
SUDO ?= $(shell if ! groups | grep -q docker; then echo "sudo"; fi)

%.Dockerfile: Dockerfile.j2
	(export ARCH=$(DOCKER_ARCH_$*) DIST=$(DIST) PY_VERSION=$(PY_VERSION) PIP="$(PIP)" && j2 $< -o $@)

.PHONY: build
build:
	pip3 wheel --wheel-dir $(DIR)/ $(PIP)

.PHONY: build-docker-%
build-docker-%: %.Dockerfile
	$(SUDO) docker build . -f $< -t pypi-builder:$*
	$(SUDO) docker run -i$(if ${CI},,t) -v $$PWD/packages:/data/packages pypi-builder:$* make build PIP='$(PIP)'

.PHONY: build-docker
build-docker: build-docker-amd64 build-docker-arm64 build-docker-armhf

.PHONY: cross
cross:
	$(SUDO) docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

.PHONY: upload
upload:
	@find packages/ ! -name *none-any* -type f -print0 | \
	  while IFS= read -r -d '' line; do \
	    twine upload --repository-url $(REPO) --skip-existing $$line; \
	  $(if ${CI},sudo,) rm $$line; \
	done

.PHONY: all-docker-amd64
all-docker-amd64: build-docker-amd64 upload

.PHONY: all-docker-arm64
all-docker-arm64: build-docker-arm64 upload

.PHONY: all-docker-armhf
all-docker-armhf: cross build-docker-armhf upload

.PHONY: all-docker
all-docker: build-docker upload

.PHONY: all-docker-native
all-docker-native: build-docker-$(NATIVE_ARCH_$(ARCH)) upload

.PHONY: all
all: build upload

.PHONY: clean
clean:
	$(if ${CI},sudo,) rm -f packages/*
