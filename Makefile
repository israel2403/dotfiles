# ~/dotfiles/Makefile
# Convenience entrypoints. Run from anywhere inside ~/dotfiles:
#
#     make            # alias for `make sync`
#     make sync       # pull + restow + idempotent helpers (DAILY command)
#     make force-sync # like `sync` but DELETES divergent local files (no backup)
#     make bootstrap  # full new-machine bootstrap (FIRST-TIME ONLY)
#     make stow       # stow every package, no git pull, no helpers
#     make restow     # stow --restow every package (refresh links)
#     make unstow     # remove every symlink stow has created
#     make status     # show git status + which packages are stowed
#     make dry-run    # `make sync` but read-only (no writes)
#
# Implementation notes:
# * Every target shells out to a helper script in scripts/.local/bin/, which
#   means ~/dotfiles/Makefile is the user-facing surface and the scripts can
#   be called individually too (and from cron, hooks, etc.).
# * `sync` is idempotent on purpose: re-running it costs nothing if everything
#   is up to date.

SHELL := /bin/bash
DOTFILES := $(abspath $(CURDIR))
SCRIPTS  := $(DOTFILES)/scripts/.local/bin

PACKAGES := $(shell find $(DOTFILES) -mindepth 1 -maxdepth 1 -type d \
            ! -name '.git' ! -name 'packages' \
            -printf '%f ')

.DEFAULT_GOAL := sync
.PHONY: sync force-sync bootstrap stow restow unstow status dry-run help

help:
	@sed -n '2,18p' $(firstword $(MAKEFILE_LIST)) | sed 's/^# \{0,1\}//'

sync:
	@$(SCRIPTS)/dotfiles-sync

force-sync:
	@$(SCRIPTS)/dotfiles-sync --force

dry-run:
	@$(SCRIPTS)/dotfiles-sync --dry-run

bootstrap:
	@$(SCRIPTS)/bootstrap-new-machine

stow:
	@cd $(DOTFILES) && stow --target=$$HOME $(PACKAGES)

restow:
	@cd $(DOTFILES) && stow --restow --target=$$HOME $(PACKAGES)

unstow:
	@cd $(DOTFILES) && stow -D --target=$$HOME $(PACKAGES)

status:
	@echo "=== git status ==="
	@git -C $(DOTFILES) --no-pager status -sb
	@echo
	@echo "=== stow packages ==="
	@for p in $(PACKAGES); do printf '  %s\n' "$$p"; done
	@echo
	@echo "=== current symlinks into the repo ==="
	@find $$HOME -maxdepth 4 -type l -lname "*dotfiles*" 2>/dev/null \
	    | sed "s#^$$HOME/#~/#" | sort
