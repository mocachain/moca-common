SHELL := /bin/bash

GO_TOOLCHAIN ?= go1.23.11
GO := env GOTOOLCHAIN=$(GO_TOOLCHAIN) go

.PHONY: build

build:
	@echo "--> Building moca-common go modules"
	@cd go && $(GO) build ./...


