# Project and directory navigation helpers.

proj() {
  local git_dir dir
  (( $+commands[fzf] )) || { print -u2 'proj: requires fzf'; return 1; }
  local finder
  if (( $+commands[fd] )); then
    finder='fd --type d --hidden --max-depth 4 --glob .git'
  elif (( $+commands[fdfind] )); then
    finder='fdfind --type d --hidden --max-depth 4 --glob .git'
  else
    finder='find . -maxdepth 4 -type d -name .git -prune'
  fi
  git_dir=$(cd -- "$HOME/projects" && eval "$finder" 2>/dev/null |
    fzf --prompt='project> ' --preview='git -C {//} log --color=always --oneline -10' \
      --preview-window='right:50%') || return
  [[ $git_dir == /* ]] || git_dir="$HOME/projects/${git_dir#./}"
  dir=${git_dir%/.git/}
  dir=${dir%/.git}
  [[ -d $dir ]] || return 1
  cd -- "$dir" || return
  print -r -- "Project: ${dir:t}"
  git --no-pager log --oneline -5
}

# Fuzzy-jump through zoxide's ranked directory history. Optional arguments
# narrow the zoxide results before fzf opens: `zj java project`.
zj() {
  (( $+commands[zoxide] && $+commands[fzf] )) || {
    print -u2 'zj: requires zoxide and fzf'
    return 1
  }

  local directory
  directory=$(
    zoxide query --list -- "$@" 2>/dev/null |
      fzf \
        --scheme=path \
        --prompt='jump> ' \
        --header='Enter: jump | Esc: cancel | Ctrl-/: toggle preview' \
        --preview='if command -v eza >/dev/null 2>&1; then eza --all --long --group-directories-first --icons=auto -- {}; else ls -la -- {}; fi' \
        --preview-window='right:55%:wrap' \
        --bind='ctrl-/:toggle-preview'
  ) || return

  [[ -n $directory && -d $directory ]] || return 1
  cd -- "$directory" || return
  print -r -- "Directory: $directory"
}
