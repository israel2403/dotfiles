# ~/dotfiles/Makefile
# Convenience entrypoints. Run from anywhere inside ~/dotfiles:
#
#     make            # detect Ubuntu/Omarchy and stow the matching profile
#     make setup      # detect Ubuntu/Omarchy and stow the matching profile
#     make setup-dry-run # preview the detected profile without changing links
#     make ubuntu     # explicitly select Ubuntu and run its dev bootstrap
#     make sync       # pull + restow + idempotent helpers (DAILY command)
#     make force-sync # like `sync` but DELETES divergent local files (no backup)
#     make bootstrap  # full new-machine Omarchy bootstrap (FIRST-TIME ONLY)
#     make stow       # stow every package, no git pull, no helpers
#     make restow     # stow --restow every package (refresh links)
#     make unstow     # remove every symlink stow has created
#     make status     # show git status + which packages are stowed
#     make dry-run    # `make sync` but read-only (no writes)

SHELL := /bin/bash
DOTFILES := $(abspath $(CURDIR))
SCRIPTS  := $(DOTFILES)/scripts/.local/bin

PACKAGES := $(shell find $(DOTFILES) -mindepth 1 -maxdepth 1 -type d \
            ! -name '.git' ! -name 'packages' \
            -printf '%f ')

PROFILE := $(SCRIPTS)/stow-profile

.DEFAULT_GOAL := setup
.PHONY: setup setup-dry-run sync force-sync bootstrap ubuntu ubuntu-stow omarchy-stow stow restow unstow status dry-run help

help:
	@sed -n '2,15p' $(firstword $(MAKEFILE_LIST)) | sed 's/^# \{0,1\}//'

sync:
	@$(SCRIPTS)/dotfiles-sync

force-sync:
	@$(SCRIPTS)/dotfiles-sync --force

dry-run:
	@$(SCRIPTS)/dotfiles-sync --dry-run

bootstrap:
	@$(SCRIPTS)/bootstrap-new-machine

setup:
	@DOTFILES=$(DOTFILES) $(PROFILE)

setup-dry-run:
	@DOTFILES=$(DOTFILES) $(PROFILE) --dry-run

ubuntu: ubuntu-stow
	@$(SCRIPTS)/bootstrap-dev

ubuntu-stow:
	@DOTFILES=$(DOTFILES) $(PROFILE) --profile ubuntu

omarchy-stow:
	@DOTFILES=$(DOTFILES) $(PROFILE) --profile omarchy

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
