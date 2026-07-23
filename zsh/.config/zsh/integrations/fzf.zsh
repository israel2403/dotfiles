# Ubuntu packages these tools as fdfind/batcat. Neither is required: find and
# sed keep selection and previews useful on a minimal installation.
if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
elif (( $+commands[fdfind] )); then
  export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --exclude .git'
else
  export FZF_DEFAULT_COMMAND="find . -type f -not -path '*/.git/*'"
fi

if (( $+commands[bat] )); then
  export FZF_FILE_PREVIEW_COMMAND='bat --style=numbers --color=always --line-range=:200 --'
elif (( $+commands[batcat] )); then
  export FZF_FILE_PREVIEW_COMMAND='batcat --style=numbers --color=always --line-range=:200 --'
else
  export FZF_FILE_PREVIEW_COMMAND="sed -n '1,200p' --"
fi

# Shared fzf behavior and selectors that are not tied to another application.
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--height=80% --layout=reverse --border"

f() {
  local file
  (( $+commands[fzf] && $+commands[nvim] )) || {
    print -u2 'f: requires fzf and nvim'
    return 1
  }
  file=$(eval "$FZF_DEFAULT_COMMAND" |
    fzf --preview='$FZF_FILE_PREVIEW_COMMAND {}' \
      --preview-window='right:60%:wrap' --bind='ctrl-/:toggle-preview') || return
  [[ -n $file ]] && nvim -- "$file"
}

rgg() {
  (( $# )) || { print -u2 'usage: rgg <pattern> [path ...]'; return 2; }
  (( $+commands[rg] && $+commands[fzf] && $+commands[nvim] )) || {
    print -u2 'rgg: requires rg, fzf, and nvim'
    return 1
  }
  local result file line
  result=$(rg --line-number --no-heading --color=always --smart-case -- "$@" |
    fzf --ansi --delimiter=: \
      --preview='$FZF_FILE_PREVIEW_COMMAND {1}' \
      --preview-window='right:60%:wrap:+{2}-10' \
      --bind='ctrl-/:toggle-preview') || return
  file=${result%%:*}
  line=${${result#*:}%%:*}
  [[ -n $file ]] && nvim "+$line" -- "$file"
}
