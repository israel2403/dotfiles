# Generic file helpers for interactive Zsh.

preview() {
  (( $# == 1 )) || { print -u2 'usage: preview <file>'; return 2; }
  if (( $+commands[bat] )); then
    bat --style=numbers,header,grid --color=always -- "$1"
  elif (( $+commands[batcat] )); then
    batcat --style=numbers,header,grid --color=always -- "$1"
  else
    sed -n '1,200p' -- "$1"
  fi
}

yy() {
  (( $# == 1 )) || { print -u2 'usage: yy <file-or-directory>'; return 2; }
  mkdir -p -- "$HOME/tmp" || return
  cp -R -- "$1" "$HOME/tmp/" || return
  print -r -- "Copied to $HOME/tmp/${1:t}"
}

mm() {
  (( $# == 2 )) || { print -u2 'usage: mm <source> <destination>'; return 2; }
  mv -- "$1" "$2"
}

# Deletion is intentionally recoverable; trash-put never bypasses the trash.
dd_() {
  (( $# > 0 )) || { print -u2 'usage: dd_ <path> [...]'; return 2; }
  trash-put -- "$@"
}

nf() {
  (( $# == 1 )) || { print -u2 'usage: nf <file>'; return 2; }
  touch -- "$1" && print -r -- "Created file: $1"
}

nd() {
  (( $# == 1 )) || { print -u2 'usage: nd <directory>'; return 2; }
  mkdir -p -- "$1" && print -r -- "Created directory: $1"
}

yp() {
  (( $# <= 1 )) || { print -u2 'usage: yp [path]'; return 2; }
  local absolute=${${1:-.}:A}
  print -rn -- "$absolute" | xclip -selection clipboard || return
  print -r -- "Copied path: $absolute"
}
