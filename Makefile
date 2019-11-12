.DEFAULT_GOAL := all
.RECIPEPREFIX +=
MAKEFLAGS=--warn-undefined-variables
SHELL := /bin/bash

SUDO ?= $(shell if ! groups | grep -q docker; then echo "sudo"; fi)
DIR ?= packages
PIP ?= Red-DiscordBot
REPO := https://pypi.supersandro.de/

.PHONY: build
build:
  pip3 wheel --wheel-dir $(DIR)/ $(PIP)

.PHONY: upload
upload:
   find packages/ ! -name *none-any* -type f | xargs twine upload --repository-url $(REPO) --skip-existing

.PHONY: all
all: build upload
