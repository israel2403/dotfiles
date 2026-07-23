# Interactive Git workflows. Private implementation helpers use the _git_ prefix.

# Return an error when the current directory is not part of a Git worktree.
_git_require_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    printf 'Error: this directory is not inside a Git repository.\n' >&2
    return 1
  }
}

# Verify that commands required by an interactive function are available.
_git_require_commands() {
  local command_name

  for command_name in "$@"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      printf 'Error: required command not found: %s\n' "$command_name" >&2
      return 1
    fi
  done
}

# Select one commit and return its complete object ID.
_git_pick_commit() {
  _git_require_repo || return
  _git_require_commands git fzf || return

  local prompt="${1:-Commit > }"

  git log \
    --color=always \
    --date=short \
    --format='%H%x09%C(yellow)%h%C(reset) %C(cyan)%ad%C(reset) %C(auto)%d%C(reset) %s %C(blue)<%an>%C(reset)' |
    fzf \
      --ansi \
      --delimiter=$'\t' \
      --with-nth=2.. \
      --no-sort \
      --layout=reverse \
      --border \
      --height=90% \
      --prompt="$prompt" \
      --header='Enter: select | Ctrl-U/Ctrl-D: scroll preview | Esc: cancel' \
      --preview='git --no-pager show --color=always --stat --patch {1}' \
      --preview-window='right,65%,wrap' |
    cut -f1
}

# Select a local or remote branch and return its full reference name. Symbolic
# remote HEAD refs are omitted for every remote, not only one named "origin".
_git_pick_branch() {
  _git_require_repo || return
  _git_require_commands git fzf || return

  git for-each-ref \
    --color=always \
    --sort=-committerdate \
    --format='%(if)%(symref)%(then)%(else)%(refname)%09%(color:yellow)%(refname:short)%(color:reset) %(color:cyan)%(committerdate:short)%(color:reset) %(subject)%(end)' \
    refs/heads refs/remotes |
    sed '/^$/d' |
    fzf \
      --ansi \
      --delimiter=$'\t' \
      --with-nth=2.. \
      --no-sort \
      --layout=reverse \
      --border \
      --height=90% \
      --prompt='Branch > ' \
      --header='Enter: select | Esc: cancel' \
      --preview='git --no-pager log --color=always --oneline --decorate -20 {1}' \
      --preview-window='right,60%,wrap' |
    cut -f1
}

# Display a commit selected interactively without changing HEAD or the worktree.
gfshow() {
  local commit

  commit=$(_git_pick_commit 'Show commit > ') || return
  [[ -n "$commit" ]] || return

  git show --color=always "$commit"
}

# The first selection is the base and the second is the target.
gfdiff() {
  local base_commit target_commit

  base_commit=$(_git_pick_commit 'Base commit > ') || return
  [[ -n "$base_commit" ]] || return

  target_commit=$(_git_pick_commit 'Target commit > ') || return
  [[ -n "$target_commit" ]] || return

  if [[ "$base_commit" == "$target_commit" ]]; then
    printf 'Nothing to compare: both selections refer to the same commit.\n' >&2
    return 1
  fi

  printf 'Comparing %s..%s\n' \
    "$(git rev-parse --short "$base_commit")" \
    "$(git rev-parse --short "$target_commit")"
  git diff --color=always "$base_commit" "$target_commit"
}

# Switch to a local branch or create a local tracking branch from a remote ref.
gfbranch() {
  local ref short_ref remote_name branch_name candidate

  ref=$(_git_pick_branch) || return
  [[ -n "$ref" ]] || return

  if [[ "$ref" == refs/heads/* ]]; then
    git switch "${ref#refs/heads/}"
    return
  fi

  if [[ "$ref" != refs/remotes/* ]]; then
    printf 'Error: unsupported branch reference: %s\n' "$ref" >&2
    return 1
  fi

  # Resolve the remote from configured names rather than assuming "origin".
  # Longest-prefix selection also handles remotes whose names share a prefix.
  for candidate in ${(f)"$(git remote)"}; do
    if [[ "$ref" == "refs/remotes/$candidate/"* ]] &&
       (( ${#candidate} > ${#remote_name} )); then
      remote_name=$candidate
    fi
  done

  if [[ -z "$remote_name" ]]; then
    printf 'Error: unable to determine the remote for reference: %s\n' "$ref" >&2
    return 1
  fi

  short_ref=${ref#refs/remotes/$remote_name/}
  branch_name=$short_ref
  if [[ -z "$branch_name" || "$branch_name" == "$ref" ]]; then
    printf 'Error: unable to determine the remote branch name.\n' >&2
    return 1
  fi

  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    git switch "$branch_name"
  else
    git switch --track -c "$branch_name" "$remote_name/$branch_name"
  fi
}

# Detached HEAD is intentional. Reject changes so history is never mixed with
# an existing working state.
gfdetach() {
  _git_require_repo || return

  if [[ -n "$(git status --porcelain)" ]]; then
    printf 'Error: the working tree is not clean.\n' >&2
    printf 'Commit, stash, or discard the changes before detaching HEAD.\n' >&2
    return 1
  fi

  local commit
  commit=$(_git_pick_commit 'Inspect commit > ') || return
  [[ -n "$commit" ]] || return

  git switch --detach "$commit" || return
  printf '\nYou are inspecting commit %s in detached HEAD state.\n' \
    "$(git rev-parse --short HEAD)"
  printf 'Run gfreturn to return to the previous branch.\n'
  printf 'Run gfnewbranch if you decide to continue working from this commit.\n'
}

# Return only from detached HEAD; this avoids making "git switch -" do
# something surprising when the command is invoked from a normal branch.
gfreturn() {
  _git_require_repo || return

  if git symbolic-ref -q HEAD >/dev/null; then
    printf 'Error: HEAD is already attached to a branch.\n' >&2
    return 1
  fi

  if [[ -n "$(git status --porcelain)" ]]; then
    printf 'Error: the working tree is not clean.\n' >&2
    printf 'Commit, stash, or discard the changes before switching back.\n' >&2
    return 1
  fi

  git switch -
}

gfnewbranch() {
  _git_require_repo || return

  local commit branch_name
  commit=$(_git_pick_commit 'Starting commit > ') || return
  [[ -n "$commit" ]] || return

  printf 'New branch name: '
  read -r branch_name

  if [[ -z "$branch_name" ]]; then
    printf 'Cancelled: a branch name is required.\n' >&2
    return 1
  fi
  if ! git check-ref-format --branch "$branch_name" >/dev/null 2>&1; then
    printf 'Error: invalid branch name: %s\n' "$branch_name" >&2
    return 1
  fi
  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    printf 'Error: local branch already exists: %s\n' "$branch_name" >&2
    return 1
  fi

  git switch -c "$branch_name" "$commit"
}

# Restore into the worktree only, after displaying the selected content and
# receiving explicit confirmation. The index remains unchanged.
gfrestorefile() {
  _git_require_repo || return
  _git_require_commands git fzf || return

  local commit selected_file confirmation
  commit=$(_git_pick_commit 'Source commit > ') || return
  [[ -n "$commit" ]] || return

  selected_file=$(
    git ls-tree -r --name-only "$commit" |
      fzf \
        --layout=reverse \
        --border \
        --height=90% \
        --prompt='Restore file > ' \
        --header='Enter: select | Esc: cancel' \
        --preview="git --no-pager show --color=always '${commit}:{}'" \
        --preview-window='right,65%,wrap'
  ) || return
  [[ -n "$selected_file" ]] || return

  printf 'Restore "%s" from commit %s? [y/N] ' \
    "$selected_file" "$(git rev-parse --short "$commit")"
  read -r confirmation

  case "$confirmation" in
    y|Y|yes|YES)
      git restore --source="$commit" --worktree -- "$selected_file" || return
      printf 'Restored into the working tree: %s\n' "$selected_file"
      printf 'Review the result with: git diff -- %q\n' "$selected_file"
      ;;
    *)
      printf 'Cancelled.\n'
      ;;
  esac
}

# Interactive staging remains available under the same unambiguous gf prefix.
gfstage() {
  _git_require_repo || return
  _git_require_commands git fzf || return

  local -a paths
  paths=("${(@0)$(
    { git diff --name-only -z; git ls-files --others --exclude-standard -z; } |
      fzf --read0 --print0 --multi --prompt='Stage > ' \
        --preview='git --no-pager diff --color=always -- {} 2>/dev/null || if command -v bat >/dev/null 2>&1; then bat --color=always --style=numbers -- {}; elif command -v batcat >/dev/null 2>&1; then batcat --color=always --style=numbers -- {}; else sed -n "1,200p" -- {}; fi'
  )}")
  paths=("${(@)paths:#}")
  (( ${#paths} )) || return 0

  git add -- "${paths[@]}" && git status --short
}
