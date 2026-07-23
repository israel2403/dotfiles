# Dotfiles

Personal dotfiles managed with GNU Stow. This repo supports two flows:

* Ubuntu 24 laptops: shell, Git, Neovim, Lean 4, Java, Node/npm, Docker,
  qutebrowser, fff, Ghostty config, and common CLI tools.
* Arch/Omarchy machines: existing Omarchy bootstrap and package migration.

## Ubuntu 24 Quick Start

```bash
sudo apt update
sudo apt install -y git stow curl

git clone https://github.com/israel2403/dotfiles.git ~/dotfiles
cd ~/dotfiles

make ubuntu
```

`make ubuntu` stows only the Ubuntu-safe packages:

```bash
bash git nvim lazygit sdkman nvm lean scripts zsh qutebrowser fff ghostty
```

Then it runs:

```bash
bootstrap-system   # apt packages: git, stow, nvim, docker, qutebrowser, fonts, etc.
bootstrap-docker   # enable Docker and add your user to the docker group
bootstrap-git      # project directories and global Git defaults
setup-lazygit      # lazygit from apt when available, otherwise GitHub release
setup-java         # SDKMAN + Java 21 + Maven + Gradle
setup-node         # NVM + latest Node LTS + npm
setup-angular      # Angular CLI through npm
setup-lean         # Lean 4 toolchain through elan
setup-glow         # terminal Markdown renderer for Ghostty/Zellij
setup-ghostty      # Ghostty package when available + stowed config
bootstrap-zsh      # Oh My Zsh + Powerlevel10k + zsh plugins
```

After it finishes, log out and back in so the Docker group and login shell
changes apply.

If you want to stow manually on Ubuntu:

```bash
cd ~/dotfiles
stow --target="$HOME" bash git nvim lazygit sdkman nvm lean scripts zsh qutebrowser fff ghostty
bootstrap-dev
```

## Arch / Omarchy Quick Start

```bash
sudo pacman -S --needed git stow

git clone https://github.com/israel2403/dotfiles.git ~/dotfiles
cd ~/dotfiles
make bootstrap
```

`make bootstrap` intentionally remains the Omarchy/new-machine flow. Do not use
it on Ubuntu.

## Common Commands

```bash
make ubuntu-stow  # stow only the Ubuntu-safe package set
make stow         # stow every package in the repo
make restow       # restow every package
make unstow       # unstow every package
make status       # show repo status and symlinks into ~/dotfiles
```

On Ubuntu, prefer `make ubuntu` or `make ubuntu-stow`; `make stow` includes all
packages and can include desktop-specific configs.

## Packages

### Shells

* `bash/.bashrc` sources every `*.sh` file under `~/.config/profile.d/`.
* `zsh/.zshrc` initializes Oh My Zsh and explicitly loads focused modules from
  `~/.config/zsh/functions`, `~/.config/zsh/integrations`, and
  `~/.config/zsh/keybindings.zsh`.
* `fff/.config/profile.d/fff.sh` keeps the shared FFF environment available to
  Bash; native Zsh wrappers live in `integrations/fff.zsh`.

Zsh sources each module explicitly in responsibility order: general functions,
tool integrations, then keybindings. Because all module files belong to the
`zsh` Stow package, a missing file is treated as a startup error rather than
being silently ignored.

### Git Workflow

Interactive Git workflows use the `gf` prefix to avoid common alias collisions:

| Command | Purpose |
| --- | --- |
| `gfshow` | Inspect a historical commit |
| `gfdiff` | Compare a base commit with a target commit |
| `gfbranch` | Select and switch branches |
| `gfdetach` | Temporarily inspect an old project version |
| `gfreturn` | Return to the previous branch |
| `gfnewbranch` | Start a new branch from an old commit |
| `gfrestorefile` | Restore one file from a historical commit |

Recommended workflow for course exercises:

1. Complete one meaningful version of an exercise.
2. Commit it with a descriptive message.
3. Modify the code to implement the next version.
4. Commit the next version.
5. Use `gfshow` to inspect an implementation.
6. Use `gfdiff` to compare implementations.
7. Use `gfdetach` only for temporary read-only inspection.
8. Use `gfnewbranch` when experimentation should continue from an old version.
9. Use `gfreturn` to leave detached HEAD safely.

For example:

```text
java/loops: implement while-loop version
java/loops: replace with do-while version
java/loops: refactor using for-loop
java/loops: extract validation method
```

This preserves each meaningful implementation in Git history instead of keeping
obsolete code commented out.

The selectors return complete object IDs and full refs, so display formatting
never becomes command input. Remote branch selection excludes symbolic `HEAD`
refs for every remote and resolves the configured remote name from the full ref
instead of assuming it is named `origin`. Detached-HEAD transitions require a
clean worktree, and `gfreturn` refuses to run unless HEAD is actually detached.

Optional Homebrew tools are initialized by `integrations/cli-tools.zsh` when
installed. `eza` provides interactive `ls`, `ll`, and `lt` aliases, while
`zoxide` provides its `z` and `zi` navigation commands. Git uses `delta` as its
global pager; fzf previews explicitly use `git --no-pager` so they remain
non-blocking regardless of pager configuration.

### Development

* `nvim` contains the LazyVim-based Neovim config.
* `lean` adds `~/.elan/bin` to your shell PATH after `setup-lean` installs elan.
* `sdkman` initializes SDKMAN from `~/.config/profile.d/sdkman.sh`.
* `nvm` initializes NVM from either Ubuntu's `~/.nvm/nvm.sh` or Arch's
  `/usr/share/nvm/init-nvm.sh`.
* `scripts` installs bootstrap helpers into `~/.local/bin`.

### Terminal Markdown Preview

Browser preview remains available from Neovim, but `md-preview` gives you a
terminal-rendered view for Ghostty and Zellij.

Install Glow:

```bash
setup-glow
```

Use it in another Zellij pane beside Neovim:

```bash
md-preview --watch notes/discrete-math.md
```

For a one-shot rendered pager:

```bash
md-preview notes/discrete-math.md
```

### Lean 4 Proof Workflow

The Neovim config includes Lean 4 editing through `lean.nvim`, Lean LSP,
Tree-sitter highlighting, Telescope integration, and Markdown preview for notes.

Install or refresh the toolchain:

```bash
setup-lean
```

Create a mathlib-backed proof sandbox for discrete mathematics:

```bash
mkdir -p ~/projects/proofs
cd ~/projects/proofs
lake new discrete_math math
cd discrete_math
lake update
lake exe cache get
nvim DiscreteMath/Basic.lean
```

Useful Neovim mappings inside `.lean` files:

```text
<leader>lg  show current proof goal
<leader>li  toggle Lean infoview
<leader>lt  show term goal
<leader>ld  jump to definition
<leader>lh  hover
<leader>la  code action
```

### Apps

* `qutebrowser` stows `~/.config/qutebrowser/config.py`.
* `fff` stows `~/.config/fff`.
* `ghostty` stows `~/.config/ghostty/config` with your Tokyo Night terminal
  setup.

## Package Manifests

* `packages/apt.txt` is used on Ubuntu/Debian.
* `packages/pacman.txt` and `packages/aur.txt` are used on Arch/Omarchy.

Run:

```bash
migrate-packages --dry-run
```

to preview what will be installed for the current OS.
