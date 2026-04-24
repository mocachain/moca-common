SHELL := /bin/bash

GO_TOOLCHAIN ?= go1.23.11
GO ?= $(shell command -v go 2>/dev/null || echo go)
GO_LOCAL_ENV ?= env -u GOROOT GOTOOLCHAIN=$(GO_TOOLCHAIN)
GO_DIR ?= go
GO_GOPATH ?= $(shell $(GO_LOCAL_ENV) $(GO) env GOPATH 2>/dev/null)
GO_BIN ?= $(or $(GOBIN),$(if $(GO_GOPATH),$(GO_GOPATH)/bin,$(HOME)/go/bin))
LEFTHOOK ?= $(GO_BIN)/lefthook
LEFTHOOK_VERSION ?= v1.11.3
GOLANGCI_LINT ?= $(GO_BIN)/golangci-lint
GOLANGCI_LINT_VERSION ?= v1.64.8
LINT_TIMEOUT ?= 15m

.PHONY: build lint test lint-changed lint-staged test-changed test-staged pre-commit pre-commit-staged hooks install-lint check-lint check-go-env

build:
	@echo "--> Building moca-common go modules"
	@cd $(GO_DIR) && $(GO_LOCAL_ENV) $(GO) build ./...

check-go-env:
	@echo "--> Using Go binary: $(GO)"
	@$(GO_LOCAL_ENV) $(GO) version
	@echo "--> Repository toolchain: $(GO_TOOLCHAIN)"
	@echo "--> Ignoring external GOROOT for repository commands"

install-lint:
	@$(GO_LOCAL_ENV) GOBIN=$(GO_BIN) $(GO) install github.com/golangci/golangci-lint/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)

check-lint:
	@if [ ! -x "$(GOLANGCI_LINT)" ]; then \
		echo "golangci-lint not found at $(GOLANGCI_LINT)"; \
		echo "Run 'make install-lint' first."; \
		exit 1; \
	fi
	@echo "--> Using golangci-lint binary: $(GOLANGCI_LINT)"
	@$(GOLANGCI_LINT) version

hooks:
	@if [ ! -x "$(LEFTHOOK)" ]; then \
		echo "--> Installing lefthook $(LEFTHOOK_VERSION) into $(GO_BIN)"; \
		$(GO_LOCAL_ENV) GOBIN=$(GO_BIN) $(GO) install github.com/evilmartians/lefthook@$(LEFTHOOK_VERSION); \
	else \
		echo "--> Using lefthook binary: $(LEFTHOOK)"; \
	fi
	@$(LEFTHOOK) install

lint: check-go-env check-lint
	@echo "--> Running golangci-lint in $(GO_DIR)"
	@cd $(GO_DIR) && $(GO_LOCAL_ENV) $(GOLANGCI_LINT) run --timeout $(LINT_TIMEOUT)

test: check-go-env
	@echo "--> Running go test in $(GO_DIR)"
	@cd $(GO_DIR) && $(GO_LOCAL_ENV) $(GO) test ./...

lint-changed: check-go-env check-lint
	@changed_go_files="$$( { git diff --name-only --diff-filter=ACMR HEAD; git ls-files --others --exclude-standard; } | grep '^$(GO_DIR)/.*\.go$$' | sort -u || true )"; \
	if { git diff --name-only --diff-filter=ACMR HEAD; git ls-files --others --exclude-standard; } | grep -Eq '^$(GO_DIR)/(go\.mod|go\.sum)$$'; then \
		echo "--> $(GO_DIR)/go.mod or $(GO_DIR)/go.sum changed; running full golangci-lint..."; \
		cd $(GO_DIR) && $(GO_LOCAL_ENV) $(GOLANGCI_LINT) run --timeout $(LINT_TIMEOUT); \
	elif [ -z "$$changed_go_files" ]; then \
		echo "--> No local changed Go files under $(GO_DIR) to lint"; \
	else \
		changed_dirs="$$(printf '%s\n' "$$changed_go_files" | xargs -n1 dirname | sed 's#^$(GO_DIR)$$#./.#' | sed 's#^$(GO_DIR)/#./#' | sort -u)"; \
		echo "--> Running golangci-lint on local changed Go packages in $(GO_DIR)..."; \
		cd $(GO_DIR) && $(GO_LOCAL_ENV) $(GOLANGCI_LINT) run --timeout $(LINT_TIMEOUT) $$changed_dirs; \
	fi

lint-staged: check-go-env check-lint
	@staged_go_files="$$(git diff --cached --name-only --diff-filter=ACMR | grep '^$(GO_DIR)/.*\.go$$' | sort -u || true)"; \
	if git diff --cached --name-only --diff-filter=ACMR | grep -Eq '^$(GO_DIR)/(go\.mod|go\.sum)$$'; then \
		echo "--> $(GO_DIR)/go.mod or $(GO_DIR)/go.sum changed; running full golangci-lint..."; \
		cd $(GO_DIR) && $(GO_LOCAL_ENV) $(GOLANGCI_LINT) run --timeout $(LINT_TIMEOUT); \
	elif [ -z "$$staged_go_files" ]; then \
		echo "--> No staged Go files under $(GO_DIR) to lint"; \
	else \
		staged_dirs="$$(printf '%s\n' "$$staged_go_files" | xargs -n1 dirname | sed 's#^$(GO_DIR)$$#./.#' | sed 's#^$(GO_DIR)/#./#' | sort -u)"; \
		echo "--> Running golangci-lint on staged Go packages in $(GO_DIR)..."; \
		cd $(GO_DIR) && $(GO_LOCAL_ENV) $(GOLANGCI_LINT) run --timeout $(LINT_TIMEOUT) $$staged_dirs; \
	fi

test-changed: check-go-env
	@changed_go_files="$$( { git diff --name-only --diff-filter=ACMR HEAD; git ls-files --others --exclude-standard; } | grep '^$(GO_DIR)/.*\.go$$' | sort -u || true )"; \
	if { git diff --name-only --diff-filter=ACMR HEAD; git ls-files --others --exclude-standard; } | grep -Eq '^$(GO_DIR)/(go\.mod|go\.sum)$$'; then \
		echo "--> $(GO_DIR)/go.mod or $(GO_DIR)/go.sum changed; running full go test..."; \
		cd $(GO_DIR) && $(GO_LOCAL_ENV) $(GO) test ./...; \
	elif [ -z "$$changed_go_files" ]; then \
		echo "--> No local changed Go files under $(GO_DIR) to test"; \
	else \
		changed_dirs="$$(printf '%s\n' "$$changed_go_files" | xargs -n1 dirname | sed 's#^$(GO_DIR)$$#./.#' | sed 's#^$(GO_DIR)/#./#' | sort -u)"; \
		echo "--> Running go test on local changed Go packages in $(GO_DIR)..."; \
		cd $(GO_DIR) && $(GO_LOCAL_ENV) $(GO) test $$changed_dirs; \
	fi

test-staged: check-go-env
	@staged_go_files="$$(git diff --cached --name-only --diff-filter=ACMR | grep '^$(GO_DIR)/.*\.go$$' | sort -u || true)"; \
	if git diff --cached --name-only --diff-filter=ACMR | grep -Eq '^$(GO_DIR)/(go\.mod|go\.sum)$$'; then \
		echo "--> $(GO_DIR)/go.mod or $(GO_DIR)/go.sum changed; running full go test..."; \
		cd $(GO_DIR) && $(GO_LOCAL_ENV) $(GO) test ./...; \
	elif [ -z "$$staged_go_files" ]; then \
		echo "--> No staged Go files under $(GO_DIR) to test"; \
	else \
		staged_dirs="$$(printf '%s\n' "$$staged_go_files" | xargs -n1 dirname | sed 's#^$(GO_DIR)$$#./.#' | sed 's#^$(GO_DIR)/#./#' | sort -u)"; \
		echo "--> Running go test on staged Go packages in $(GO_DIR)..."; \
		cd $(GO_DIR) && $(GO_LOCAL_ENV) $(GO) test $$staged_dirs; \
	fi

pre-commit: lint-changed test-changed

pre-commit-staged: lint-staged test-staged
