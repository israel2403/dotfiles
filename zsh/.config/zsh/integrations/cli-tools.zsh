# Optional CLI enhancements. Each block is conditional so shell startup still
# works on machines where the corresponding Homebrew formula is not installed.

if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza --long --all --group-directories-first --git --icons=auto'
  alias lt='eza --tree --level=2 --group-directories-first --icons=auto'
else
  alias ls='ls --color=auto'
  alias ll='ls -lah'
fi

if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi
