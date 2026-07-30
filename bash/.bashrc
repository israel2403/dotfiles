# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# Prevent stale aliases from breaking omarchy function definitions on re-source
unalias ga gd gs 2>/dev/null

# All the default Omarchy aliases and functions
if [ -f "$HOME/.local/share/omarchy/default/bash/rc" ]; then
  source "$HOME/.local/share/omarchy/default/bash/rc"
fi

# ~/.local/bin on PATH
export PATH="$HOME/.local/bin:$PATH"

# Aliases – Git (ga/gd reserved by omarchy worktrees)
alias gst='git status'
alias gaa='git add'
alias gc='git commit'
alias gp='git push'

# Re-enable command hashing after Omarchy's mise initialization. Some tools
# loaded below (notably NVM) call `hash -r`.
set -h

# Source all tool initializations from ~/.config/profile.d/
if [ -d "$HOME/.config/profile.d" ]; then
  for f in "$HOME/.config/profile.d"/*.sh; do
    [ -f "$f" ] && . "$f"
  done
fi

# Aliases – Docker
alias dcu='docker compose up -d'
alias dcd='docker compose down'

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"


# Load optional tool integrations only when they are installed.
if command -v ng >/dev/null 2>&1; then
  source <(ng completion script)
fi

[[ -r "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
