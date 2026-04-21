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

### qutebrowser

- `.config/qutebrowser/config.py` — manual qutebrowser config (keybindings, dark mode, TLS, session restore). See `qutebrowser/README.md` for what is intentionally left out.

### scripts

Bootstrap and setup scripts installed to `~/.local/bin/`.

- `bootstrap-dev` — Full dev environment setup (runs all others)
- `bootstrap-system` — Core packages via pacman (+ `stow`, `openssh`, `rsync`, enables `sshd`)
- `bootstrap-docker` — Docker service and group setup
- `bootstrap-git` — Git identity and project directories
- `bootstrap-new-machine` — One-shot clone of this environment onto a fresh Omarchy install
- `migrate-packages` — Replay `packages/{pacman,aur}.txt` on the current machine
- `sync-projects` — `rsync` over SSH to push/pull `~/projects/` between machines
- `setup-java` — Java 21 Temurin via SDKMAN
- `setup-node` — Node.js LTS via NVM
- `setup-angular` — Angular CLI via npm
- `doctor-dev-env` — Verify all installed tool versions

### packages

Version-controlled package inventory. See `packages/README.md`.

- `packages/pacman.txt` — explicit packages from the official repos (includes `qutebrowser`).
- `packages/aur.txt` — foreign / AUR packages.

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

## Clone this whole environment onto a fresh Omarchy install

**Scope guarantee.** The migration only carries **your env/shell files** and
**`~/projects/`**. It intentionally never touches Omarchy- or machine-specific
configuration such as `~/.config/hypr/monitors.conf`, waybar, mako, walker,
alacritty, ghostty, kitty, sddm, or anything under `~/.config/omarchy/`. These
paths are listed in `.stow-global-ignore` at the repo root, and
`bootstrap-new-machine` runs a `stow -n` dry-run first and aborts if any
proposed symlink would land in one of them.

High-level flow (detailed steps in `scripts/.local/bin/bootstrap-new-machine`):

```bash
# -- ON THE NEW MACHINE --
sudo pacman -S --needed git stow openssh rsync
sudo systemctl enable --now sshd
git clone https://github.com/israel2403/dotfiles.git ~/dotfiles
cd ~/dotfiles && stow scripts   # so the helpers are on PATH
bootstrap-new-machine           # stows the rest + runs migrate-packages

# -- ON THE OLD MACHINE --
sync-projects push <user>@<new-machine-ip>
```

`bootstrap-new-machine` will also generate an SSH key if one doesn't exist
yet and print the public key so you can paste it into GitHub (and into
`~/.ssh/authorized_keys` on the old machine if pulling).

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
├── packages/
│   ├── pacman.txt
│   └── aur.txt
├── qutebrowser/
│   └── .config/qutebrowser/config.py
├── scripts/
│   └── .local/bin/
│       ├── bootstrap-dev
│       ├── bootstrap-docker
│       ├── bootstrap-git
│       ├── bootstrap-new-machine
│       ├── bootstrap-system
│       ├── doctor-dev-env
│       ├── migrate-packages
│       ├── setup-angular
│       ├── setup-java
│       ├── setup-node
│       └── sync-projects
├── sdkman/
│   └── .config/profile.d/sdkman.sh
└── zsh/
    └── .zshrc
```
