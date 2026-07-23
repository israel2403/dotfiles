#!/usr/bin/env bash
# Shared environment for fff. Zsh functions and bindings live in the zsh package.

[ -r "$HOME/.config/fff/fff.conf" ] && . "$HOME/.config/fff/fff.conf"

# Zsh loads its native integration explicitly from ~/.config/zsh.
[ -n "${ZSH_VERSION:-}" ] && return 0

# Retain the parent-shell directory change for interactive Bash users.
f3() {
  command fff "$@"
  local cd_file="${FFF_CD_FILE:-$HOME/.fff_d}" dir
  if [ -r "$cd_file" ]; then
    dir=$(<"$cd_file")
    rm -f -- "$cd_file"
    [ -d "$dir" ] && cd -- "$dir"
  fi
}

if [[ $- == *i* ]]; then
  bind -x '"\eOR":f3'
  bind -x '"\e[13~":f3'
fi
