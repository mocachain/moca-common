SHELL := /bin/bash

.PHONY: build

build:
	@echo "--> Building moca-common go modules"
	@cd go && go build ./...


