# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
source ~/.local/share/omarchy/default/bash/rc

# ~/.local/bin on PATH
export PATH="$HOME/.local/bin:$PATH"

# Source all tool initializations from ~/.config/profile.d/
if [ -d "$HOME/.config/profile.d" ]; then
  for f in "$HOME/.config/profile.d"/*.sh; do
    [ -f "$f" ] && . "$f"
  done
fi

# Aliases – Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

# Aliases – Docker
alias dcu='docker compose up -d'
alias dcd='docker compose down'
