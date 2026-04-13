SHELL := /bin/bash

GO_TOOLCHAIN ?= go1.23.11
GO := env GOTOOLCHAIN=$(GO_TOOLCHAIN) go

.PHONY: all test

test:
	$(GO) test ./...
