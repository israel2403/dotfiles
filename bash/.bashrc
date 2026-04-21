# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# Prevent stale aliases from breaking omarchy function definitions on re-source
unalias ga gd gs 2>/dev/null

# All the default Omarchy aliases and functions
source ~/.local/share/omarchy/default/bash/rc

# ~/.local/bin on PATH
export PATH="$HOME/.local/bin:$PATH"

# Aliases – Git (ga/gd reserved by omarchy worktrees)
alias gst='git status'
alias gaa='git add'
alias gc='git commit'
alias gp='git push'

# Source all tool initializations from ~/.config/profile.d/
if [ -d "$HOME/.config/profile.d" ]; then
  for f in "$HOME/.config/profile.d"/*.sh; do
    [ -f "$f" ] && . "$f"
  done
fi

# Aliases – Docker
alias dcu='docker compose up -d'
alias dcd='docker compose down'

# Re-enable command hashing (omarchy disables it for mise init, not needed after)
set -h
