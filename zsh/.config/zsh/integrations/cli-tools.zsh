# Optional CLI enhancements. Each block is conditional so shell startup still
# works on machines where the corresponding Homebrew formula is not installed.

if (( $+commands[eza] )); then
  # Keep the short views fast; reserve Git metadata and hidden files for the
  # explicit long aliases where that extra information is useful.
  alias ls='eza --group-directories-first --icons=auto'
  alias l='eza --group-directories-first --icons=auto'
  alias ll='eza --long --header --git --group-directories-first --icons=auto'
  alias la='eza --long --all --header --git --group-directories-first --icons=auto'
  alias ld='eza --only-dirs --group-directories-first --icons=auto'
  alias lt="eza --tree --level=2 --group-directories-first --icons=auto --ignore-glob='.git|node_modules|target|.gradle|.idea'"
else
  alias ls='ls --color=auto'
  alias l='ls --color=auto'
  alias ll='ls -lah'
  alias la='ls -lah'
  alias ld='ls -d -- */'
  alias lt='find . -maxdepth 2 -print'
fi

if (( $+commands[zoxide] )); then
  # Show the chosen destination before jumping, and give `zi` the same compact
  # fuzzy-selector presentation used elsewhere. Existing user values win.
  export _ZO_ECHO=${_ZO_ECHO:-1}
  export _ZO_FZF_OPTS=${_ZO_FZF_OPTS:---height=60% --layout=reverse --border --scheme=path}

  # Keep normal `cd` semantics; zoxide remains explicit through `z` and `zi`.
  eval "$(zoxide init zsh --hook=pwd)"
fi

# Ubuntu installs bat as `batcat`. Provide the upstream name and a safe
# interactive cat replacement: plain styling and automatic colors preserve
# clean output when redirected, while terminals still receive highlighting.
if (( $+commands[bat] || $+commands[batcat] )); then
  typeset _bat_command=${commands[bat]:-${commands[batcat]}}

  if ! (( $+commands[bat] )); then
    alias bat="${(q)_bat_command}"
  fi

  alias cat="${(q)_bat_command} --paging=never --style=plain --color=auto"
  alias bcat="${(q)_bat_command} --paging=auto --style=numbers,changes,header,grid --color=always"

  unset _bat_command
fi
