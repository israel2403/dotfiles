# ~/.local/bin on PATH
export PATH="$HOME/.local/bin:$PATH"

# Source all tool initializations from ~/.config/profile.d/
if [ -d "$HOME/.config/profile.d" ]; then
  for f in "$HOME/.config/profile.d"/*.sh(N); do
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