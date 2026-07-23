# Zsh integration for fff. Generic fuzzy selectors live in fzf.zsh.
[[ -r $HOME/.config/fff/fff.conf ]] && source "$HOME/.config/fff/fff.conf"

f3() {
  command fff "$@"
  local cd_file=${FFF_CD_FILE:-$HOME/.fff_d} dir
  if [[ -r $cd_file ]]; then
    dir=$(<$cd_file)
    rm -f -- "$cd_file"
    [[ -d $dir ]] && cd -- "$dir"
  fi
}

nv() {
  nvim -- "${1:-$PWD}"
  # Only leave the temporary shell created by fff, never the user's terminal.
  (( ${FFF_LEVEL:-0} > 0 )) && exit
}

fnv() {
  f3 "$@" || return
  nvim -- "$PWD"
}

o() {
  (( $# == 1 )) || { print -u2 'usage: o <file>'; return 2; }
  fff-open "$1"
}

# These bindings belong with fff because both terminal escape sequences invoke
# its launcher; unrelated ZLE bindings remain in keybindings.zsh.
bindkey -s '\eOR' 'f3\n'
bindkey -s '\e[13~' 'f3\n'
