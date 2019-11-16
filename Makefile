.DEFAULT_GOAL := $(if ${CI},all,amd64-build-docker)
.RECIPEPREFIX +=
MAKEFLAGS=--warn-undefined-variables
SHELL := /bin/bash

# Official Docker Images do not use arm64 but instead arm64v8. We need to transalte this.
DOCKER_ARCH_amd64 ?= amd64
DOCKER_ARCH_arm64 ?= arm64v8
DOCKER_ARCH_armhf ?= arm32v7

ARCH ?= $(shell uname -m)
DIR ?= packages
PIP ?= -r https://github.com/healthchecks/healthchecks/raw/master/requirements.txt Kibitzr Red-DiscordBot -r https://github.com/HelloZeroNet/ZeroNet/raw/py3/requirements.txt
REPO := https://pypi.supersandro.de/
SUDO ?= $(shell if ! groups | grep -q docker; then echo "sudo"; fi)

%.Dockerfile: Dockerfile.j2
  (export arch=$(DOCKER_ARCH_$*) && j2 $< -o $@)

.PHONY: build-docker-%
build-docker-%: amd64.Dockerfile arm64.Dockerfile
  $(SUDO) docker build . -f $< -t pypi-builder-$*
  $(SUDO) docker run -it -v $$PWD/packages:/data/packages pypi-builder-$* make build

.PHONY: build-docker
build-docker: build-docker-amd64 build-docker-arm64
  docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

.PHONY: all-docker-amd64
all-docker-amd64: build-docker-amd64 upload

.PHONY: all-docker-arm64
all-docker-arm64: build-docker-arm64 upload

.PHONY: all-docker-native
all-docker-native: build-docker-$(ARCH) upload

.PHONY: all-docker
all-docker: build-docker upload

.PHONY: build
build:
  pip3 wheel --wheel-dir $(DIR)/ $(PIP)

.PHONY: upload
upload:
   find packages/ ! -name *none-any* -type f | xargs twine upload --repository-url $(REPO) --skip-existing

.PHONY: all
all: build upload
