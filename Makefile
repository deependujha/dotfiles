# Day-to-day commands for this repository. Run `make` to list them.
#
# From any directory, the `dots` shell function does the same:  dots update

SHELL := bash
.DEFAULT_GOAL := help

# Every top-level directory with a setup.sh is a component.
COMPONENTS := $(patsubst %/setup.sh,%,$(wildcard */setup.sh))

# Commit message for `make push`:  make push m="add zellij keybinds"
m ?= update

.PHONY: help update pull push status restore check $(COMPONENTS)

help:
	@echo "make update        apply everything in this repo to this machine"
	@echo "make <component>   apply one of: $(COMPONENTS)"
	@echo "make push          commit all changes and push   (make push m=\"message\")"
	@echo "make pull          pull from GitHub, then apply"
	@echo "make status        uncommitted changes, unpushed commits, the snapshot"
	@echo "make restore       put back what the last update replaced (from snapshot/)"
	@echo "make check         syntax-check the scripts (shellcheck too, if installed)"

update:
	@bash install.sh

$(COMPONENTS):
	@bash install.sh $@

pull:
	@git pull
	@bash install.sh

push: check
	@git add -A
	@git diff --cached --quiet || git commit -m "$(m)"
	@git push

status:
	@git status --short --branch
	@if ls snapshot/*/manifest >/dev/null 2>&1; then \
		echo; echo "snapshot ($$(cat snapshot/.run 2>/dev/null)):"; \
		cat snapshot/*/manifest | cut -f2 | sed 's/^/  /'; \
	else \
		echo; echo "no snapshot"; \
	fi

restore:
	@bash scripts/restore.sh

check:
	@for f in install.sh common/*.sh scripts/*.sh */setup.sh shell/*.sh shell/*.bash; do \
		bash -n "$$f" || exit 1; \
	done
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -x install.sh common/*.sh scripts/*.sh */setup.sh shell/*.sh shell/*.bash; \
	fi
	@echo "check: ok"
