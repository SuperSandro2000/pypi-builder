.DEFAULT_GOAL := $(if ${CI},all,docker-native)
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
DIST ?= buster # tested with alpine and buster
PY_VERSION ?= 3.8
PIP ?= cryptography Kibitzr gevent lxml psycopg2-binary Twisted -r https://github.com/HelloZeroNet/ZeroNet/raw/py3/requirements.txt
REPO ?= https://pypi.supersandro.de/
SUDO ?= $(shell if ! groups 2&>/dev/null | grep -q docker; then echo sudo --preserve-env=DOCKER_BUILDKIT,DOCKER_CLI_EXPERIMENTAL,COMPOSE_DOCKER_CLI_BUILD,HOME,PWD; fi)

%.Dockerfile: Dockerfile.j2
	(export ARCH=$(DOCKER_ARCH_$*) DIST=$(DIST) PY_VERSION=$(PY_VERSION) PIP="$(PIP)" && j2 $< -o $@)

.PHONY: build
build:
	pip3 wheel --wheel-dir $(DIR)/ $(PIP)

.PHONY: docker-build-%
docker-build-%: %.Dockerfile
	$(SUDO) docker build . --pull -f $< -t pypi-builder:$*
	$(SUDO) docker run --init --rm -i$(if ${CI},,t) -v $$PWD/packages:/data/packages pypi-builder:$* make build PIP='$(PIP)'

.PHONY: docker-build
docker-build: docker-build-amd64 docker-build-arm64 docker-build-armhf

.PHONY: cross
cross:
	$(SUDO) docker run --init --privileged --rm multiarch/qemu-user-static --reset -p yes

.PHONY: upload
upload:
	@find packages/ ! -name *none-any* -type f -print0 | \
	  while IFS= read -r -d '' line; do \
            if [[ $$line =~ ".dev0-" ]]; then continue; fi; \
	    twine upload --repository-url $(REPO) --skip-existing $$line; \
	done

.PHONY: docker-amd64
docker-amd64: docker-build-amd64 upload

.PHONY: docker-arm64
docker-arm64: cross docker-build-arm64 upload

.PHONY: docker-armhf
docker-armhf: cross docker-build-armhf upload

.PHONY: docker
docker: docker-build upload

.PHONY: docker-native
docker-native: docker-build-$(NATIVE_ARCH_$(ARCH)) upload

.PHONY: all
all: build upload

.PHONY: clean
clean:
	rm -f *.Dockerfile
	$(if ${CI},sudo,) rm -f packages/*
