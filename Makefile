.DEFAULT_GOAL := help

ENV_PREFIX ?= .
ENV_FILE := $(wildcard $(ENV_PREFIX)/.env)

ifeq ($(strip $(ENV_FILE)),)
$(info $(ENV_PREFIX)/.env file not found, skipping inclusion)
else
include $(ENV_PREFIX)/.env
export
endif

GIT_SHA_SHORT = $(shell git rev-parse --short HEAD)
GIT_REF = $(shell git rev-parse --abbrev-ref HEAD)

#-------
##@ help
#-------

# based on "https://gist.github.com/prwhite/8168133?permalink_comment_id=4260260#gistcomment-4260260"
help: ## Display this help. (Default)
	@grep -hE '^(##@|[A-Za-z0-9_ \-]*?:.*##).*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; /^##@/ {print "\n" substr($$0, 5)} /^[A-Za-z0-9_ \-]*?:.*##/ {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

help-sort: ## Display alphabetized version of help (no section headings).
	@grep -hE '^[A-Za-z0-9_ \-]*?:.*##.*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; /^[A-Za-z0-9_ \-]*?:.*##/ {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

HELP_TARGETS_PATTERN ?= test
help-targets: ## Print commands for all targets matching a given pattern. eval "$(make help-targets HELP_TARGETS_PATTERN=render | sed 's/\x1b\[[0-9;]*m//g')"
	@make help-sort | awk '{print $$1}' | grep '$(HELP_TARGETS_PATTERN)' | xargs -I {} printf "printf '___\n\n{}:\n\n'\nmake -n {}\nprintf '\n'\n"

#-----------------
##@ CI tasks
#-----------------

.PHONY: install
install: ## Install package
	@echo "Installing package"
	julia -e '\
		using Pkg; \
		Pkg.activate("."); \
		Pkg.instantiate();'

.PHONY: lint
lint: ## Lint julia files
	@echo "Linting"
	julia -e '\
		using Pkg; \
		Pkg.activate("."); \
		Pkg.instantiate(); \
		using JuliaFormatter; \
		format("./src", verbose=true); \
		format("./test", verbose=true);'

.PHONY: test
test: ## Run tests
	@echo "Running tests"
	julia -e '\
		using Pkg; \
		Pkg.activate("."); \
		Pkg.instantiate(); \
		Pkg.test()'

.PHONY: docs
docs: ## Build documentation
	@echo "Building documentation"
	julia --project=docs --color=yes -e '\
		using Pkg; \
		Pkg.develop(PackageSpec(path=pwd())); \
		Pkg.instantiate(); \
		using Documenter: DocMeta, doctest; \
		using Fluxome; \
		DocMeta.setdocmeta!(Fluxome, :DocTestSetup, :(using Fluxome); recursive=true); \
		doctest(Fluxome)'

.PHONY: check
check: ## Run all checks
check: lint test docs


#-----------------
##@ GitHub
#-----------------

ghsecrets: ## Update github secrets for GH_REPO from ".env" file.
	@echo "secrets before updates:"
	@echo
	PAGER=cat gh secret list --repo=$(GH_REPO)
	@echo
	gh secret set CODECOV_TOKEN --repo="$(GH_REPO)" --body="$(CODECOV_TOKEN)"
	@echo
	@echo secrets after updates:
	@echo
	PAGER=cat gh secret list --repo=$(GH_REPO)

GHA_WORKFLOWS := \
	.github/workflows/CI.yml \
	.github/workflows/CompatHelper.yml \
	.github/workflows/TagBot.yml \
	.github/workflows/pr-check.yaml \
	.github/workflows/pr-merge.yaml \
	.github/workflows/labeler.yml

ratchet = docker run -it --rm -v "${PWD}:${PWD}" -w "${PWD}" ghcr.io/sethvargo/ratchet:0.9.2 $1

ratchet-pin: ## Pin all workflow versions to hash values. (requires docker).
	$(foreach workflow,$(GHA_WORKFLOWS),$(call ratchet,pin $(workflow));)

ratchet-unpin: ## Unpin hashed workflow versions to semantic values. (requires docker).
	$(foreach workflow,$(GHA_WORKFLOWS),$(call ratchet,unpin $(workflow));)

ratchet-update: ## Unpin hashed workflow versions to semantic values. (requires docker).
	$(foreach workflow,$(GHA_WORKFLOWS),$(call ratchet,update $(workflow));)

#------
##@ Nix
#------

meta: ## Generate nix flake metadata.
	nix flake metadata --impure --accept-flake-config
	nix flake show --impure --accept-flake-config

up: ## Update nix flake lock file.
	nix flake update --impure --accept-flake-config
	nix flake check --impure --accept-flake-config

dup: ## Debug update nix flake lock file.
	nix flake update --impure --accept-flake-config
	nix flake check --show-trace --print-build-logs --impure --accept-flake-config

nix-lint: ## Lint nix files.
	nix fmt

NIX_DERIVATION_PATH ?= $(shell which julia)

closure-size: ## Print nix closure size for a given path. make -n closure-size NIX_DERIVATION_PATH=$(which julia)
	nix path-info -Sh $(NIX_DERIVATION_PATH)

re: ## Reload direnv.
	direnv reload

al: ## Enable direnv.
	direnv allow

nix-default: ## Build default nix derivation.
	nix build .#default \
	--accept-flake-config \
	--impure \
	--fallback \
	--keep-going \
	--print-build-logs
