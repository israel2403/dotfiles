# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) on Arch Linux.

## Prerequisites

```bash
sudo pacman -S --needed git stow
```

## Installation

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
```

### Stow individual packages

```bash
stow bash      # → ~/.bashrc
stow zsh       # → ~/.zshrc
stow git       # → ~/.gitconfig, ~/.gitconfig-personal, ~/.gitconfig-school
stow nvm       # → ~/.config/profile.d/nvm.sh
stow sdkman    # → ~/.config/profile.d/sdkman.sh
stow scripts   # → ~/.local/bin/bootstrap-*, setup-*, doctor-*
```

### Stow all packages at once

```bash
stow */
```

### Unstow a package

```bash
stow -D <package>
```

### Preview changes (dry run)

```bash
stow -n -v <package>
```

## Packages

### bash

- `.bashrc` — PATH, dynamic `~/.config/profile.d/` sourcing, and aliases

### zsh

- `.zshrc` — Same as bash, with zsh-compatible glob handling `(N)`

### git

Git configuration with conditional includes per project directory.

- `.gitconfig` — Global settings (editor, push, pull)
- `.gitconfig-personal` — Identity for `~/projects/personal/`
- `.gitconfig-school` — Identity for `~/projects/school/`

### nvm

- `.config/profile.d/nvm.sh` — NVM initialization (auto-sourced by shell rc)

### sdkman

- `.config/profile.d/sdkman.sh` — SDKMAN initialization (auto-sourced by shell rc)

### scripts

Bootstrap and setup scripts installed to `~/.local/bin/`.

- `bootstrap-dev` — Full dev environment setup (runs all others)
- `bootstrap-system` — Core packages via pacman
- `bootstrap-docker` — Docker service and group setup
- `bootstrap-git` — Git identity and project directories
- `setup-java` — Java 21 Temurin via SDKMAN
- `setup-node` — Node.js LTS via NVM
- `setup-angular` — Angular CLI via npm
- `doctor-dev-env` — Verify all installed tool versions

## Adding a New Tool

The shell rc files automatically source every `*.sh` file in `~/.config/profile.d/`.
To integrate a new tool (e.g. Rust):

```bash
mkdir -p ~/dotfiles/rust/.config/profile.d
# create rust/.config/profile.d/rust.sh with your init logic
cd ~/dotfiles && stow rust
```

No need to edit `.bashrc` or `.zshrc`.

## Quick Start (new machine)

```bash
# 1. Install prerequisites
sudo pacman -S --needed git stow

# 2. Clone and enter the repo
git clone https://github.com/<your-username>/dotfiles ~/dotfiles
cd ~/dotfiles

# 3. Stow everything (--adopt handles existing files like .bashrc)
stow --adopt */
git checkout .

# 4. Bootstrap the full dev environment
bootstrap-dev
```

## Directory Structure

```
dotfiles/
├── bash/
│   └── .bashrc
├── git/
│   ├── .gitconfig
│   ├── .gitconfig-personal
│   └── .gitconfig-school
├── nvm/
│   └── .config/profile.d/nvm.sh
├── scripts/
│   └── .local/bin/
│       ├── bootstrap-dev
│       ├── bootstrap-docker
│       ├── bootstrap-git
│       ├── bootstrap-system
│       ├── doctor-dev-env
│       ├── setup-angular
│       ├── setup-java
│       └── setup-node
├── sdkman/
│   └── .config/profile.d/sdkman.sh
└── zsh/
    └── .zshrc
```
