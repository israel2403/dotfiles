# ~/.zshrc — managed via ~/dotfiles (GNU stow)
# ---------------------------------------------------------------------------

# Powerlevel10k instant prompt. Must stay near the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go ABOVE this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ---------------------------------------------------------------------------
# Oh My Zsh
# ---------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"

# Theme: Powerlevel10k (run `p10k configure` after first launch to customize)
ZSH_THEME="powerlevel10k/powerlevel10k"

# Auto-update OMZ on a schedule instead of prompting
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

# Case-insensitive completion (macOS-style)
CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"

# Fancy timestamp in `history`
HIST_STAMPS="yyyy-mm-dd"

# Plugins — productivity-focused set.
# NOTE: zsh-syntax-highlighting MUST be last.
plugins=(
  git
  docker
  docker-compose
  sudo                    # ESC ESC to prefix/unprefix sudo
  history
  command-not-found
  archlinux               # pacman / yay aliases
  npm
  node
  nvm
  colored-man-pages
  extract                 # `x <archive>` unpacks anything
  systemd                 # sc-start/stop/status shortcuts
  dirhistory              # Alt+←/→/↑/↓ to navigate directories
  fzf
  zsh-completions
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# zsh-completions requires rebuilding fpath BEFORE compinit runs in OMZ
fpath+=("$ZSH/custom/plugins/zsh-completions/src")

source "$ZSH/oh-my-zsh.sh"

# ---------------------------------------------------------------------------
# Completion tweaks — macOS-style grid menu
# ---------------------------------------------------------------------------
zmodload zsh/complist
zstyle ':completion:*' menu select                               # grid w/ selection
# Colorize entries from $LS_COLORS, and force the *highlighted* match (`ma=`)
# to bold black text on a bright-green background so directory names remain
# readable when the menu-select cursor lands on them.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" 'ma=1;30;48;5;46'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' \
                                     'r:|[._-]=* r:|=*' \
                                     'l:|=* r:|=*'               # fuzzy + smart-case
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''

# Shift-Tab to cycle backwards through the menu
bindkey -M menuselect '^[[Z' reverse-menu-complete

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE \
       HIST_REDUCE_BLANKS INC_APPEND_HISTORY EXTENDED_HISTORY

# ---------------------------------------------------------------------------
# PATH & tool initializations
# ---------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"

# Source all tool initializations from ~/.config/profile.d/ (nvm, sdkman, mise, …)
if [ -d "$HOME/.config/profile.d" ]; then
  for f in "$HOME/.config/profile.d"/*.sh(N); do
    [ -f "$f" ] && . "$f"
  done
fi

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
# Git (OMZ git plugin already provides gst/gaa/gc/gp/etc., keep a few overrides)
alias gs='git status'

# Docker
alias dcu='docker compose up -d'
alias dcd='docker compose down'

# Safety / niceties
alias ls='ls --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'

# ---------------------------------------------------------------------------
# Powerlevel10k user config
# ---------------------------------------------------------------------------
# To customize the prompt, run `p10k configure` — it writes ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ---------------------------------------------------------------------------
# SDKMAN — MUST be at the very end of the file
# ---------------------------------------------------------------------------
export SDKMAN_DIR="/home/isra/.sdkman"
[[ -s "/home/isra/.sdkman/bin/sdkman-init.sh" ]] && source "/home/isra/.sdkman/bin/sdkman-init.sh"
