#!/usr/bin/env bash
# fff extensions — sourced by ~/.bashrc via profile.d
# Dependencies: fff, fzf, fd, rg, bat, nvim, tmux, imv, zathura, trash-cli, xclip

# ── Shell-portable helpers ─────────────────────────────────────────────
# Defined BEFORE the zsh-guard so these work both in your interactive zsh
# AND in the bash subshell that fff spawns when you press '!'.
#
#   nv [PATH]   — open PATH (default: $PWD) in nvim. If invoked from inside
#                 the temporary shell that fff spawns on '!' (FFF_LEVEL > 0),
#                 the shell auto-exits when nvim quits so you land back in
#                 fff at the same directory. Outside fff it's just `nvim .`
#                 and your shell stays alive.
#
#   fnv [...]   — run fff (passing through any args), then open whatever dir
#                 fff cd'd into with nvim. Useful from the regular shell
#                 when you want to navigate-then-edit in one command.
#
# Workflow inside fff to open ~/projects/school/master/tech-web in nvim:
#   1. Launch fff (F3 or `f3`).
#   2. Navigate into the directory (use l / arrows).
#   3. Press `!` — fff drops you into a shell at that directory.
#   4. Type `nv` <Enter> — nvim opens with that directory as its argument.
#   5. Edit, then `:q` / `:qa` — the spawned shell auto-exits and you are
#      back inside fff at the same directory.
nv() {
  nvim "${1:-$PWD}"
  # Only auto-exit when invoked from fff's own subshell, never from a
  # top-level shell -- otherwise quitting nvim would close the user's
  # actual terminal session.
  if [[ -n "${FFF_LEVEL:-}" && "${FFF_LEVEL:-0}" -gt 0 ]]; then
    exit
  fi
}

fnv() {
  fff "$@"
  local dir
  if [[ -r "${FFF_CD_FILE:-$HOME/.fff_d}" ]]; then
    dir=$(< "${FFF_CD_FILE:-$HOME/.fff_d}")
    rm -f "${FFF_CD_FILE:-$HOME/.fff_d}"
  fi
  [[ -z "$dir" ]] && dir="$PWD"
  if [[ -d "$dir" ]]; then
    cd "$dir" || return
    nvim "$dir"
  else
    echo "fnv: '$dir' is not a directory" >&2
    return 1
  fi
}

# This file uses bash-specific syntax below (bind -x, export -f, ${var,,}).
# Skip the rest when sourced from zsh so startup stays clean.
if [ -n "${ZSH_VERSION:-}" ]; then
  return 0
fi

# ── Source fff config ──────────────────────────────────────────────
[ -f ~/.config/fff/fff.conf ] && source ~/.config/fff/fff.conf

# ── fff wrapper (cd on exit) ───────────────────────────────────────
f3() {
  fff "$@"
  if [ -f "$FFF_CD_FILE" ]; then
    local dir
    dir=$(cat "$FFF_CD_FILE")
    [ -d "$dir" ] && cd "$dir" || true
    rm -f "$FFF_CD_FILE"
  fi
}

# Bind F3 key to launch f3 (so you can just press F3 instead of typing f3)
bind -x '"\eOR":f3'      # F3 in some terminals
bind -x '"\e[13~":f3'    # F3 in other terminals

# ── Smart opener ───────────────────────────────────────────────────────────────
# fff is itself a bash script that's launched from your interactive zsh.
# zsh does NOT export bash functions to subprocesses, so a fff_open shell
# function defined here would be invisible to fff. The opener now lives as a
# standalone executable at ~/.local/bin/fff-open (stowed via the `scripts`
# package), so it's resolvable via PATH from any shell -- including the bash
# subprocess that fff itself runs in. PDFs route through zathura there.
export FFF_OPENER=fff-open

# Shorthand for the opener (works in both zsh and bash).
o() { fff-open "$1"; }

# ── Fuzzy file finder (IntelliJ-style Ctrl+Shift+N) ───────────────
f() {
  local file
  file=$(fd --type f --hidden --exclude .git | fzf \
    --preview 'bat --style=numbers --color=always --line-range=:200 {}' \
    --preview-window=right:60%:wrap \
    --height=80% \
    --bind 'ctrl-/:toggle-preview')
  [ -n "$file" ] && nvim "$file"
}

# ── Ripgrep + fzf (IntelliJ-style Ctrl+Shift+F) ──────────────────
# Named rgg to avoid conflict with omarchy's `r` alias (rails)
rgg() {
  local result file line
  result=$(rg --line-number --no-heading --color=always --smart-case "${1:-.}" |
    fzf --ansi \
      --delimiter ':' \
      --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
      --preview-window=right:60%:wrap:+{2}-10 \
      --height=80% \
      --bind 'ctrl-/:toggle-preview')
  file=$(echo "$result" | cut -d: -f1)
  line=$(echo "$result" | cut -d: -f2)
  [ -n "$file" ] && nvim +"$line" "$file"
}

# ── Preview (standalone bat preview) ──────────────────────────────
preview() {
  if [ -z "$1" ]; then
    echo "Usage: preview <file>"
    return 1
  fi
  bat --style=numbers,header,grid --color=always "$1"
}

# ── IDE-like split: fff left, preview right (tmux) ────────────────
ide() {
  if [ -z "$TMUX" ]; then
    echo "Start tmux first: tmux"
    return 1
  fi
  # Open fff in current pane, preview in right split
  tmux split-window -h -l 60% "bash -c '
    while true; do
      clear
      if [ -f /tmp/.fff_preview ]; then
        file=\$(cat /tmp/.fff_preview)
        if [ -f \"\$file\" ]; then
          bat --style=numbers --color=always \"\$file\" 2>/dev/null || file \"\$file\"
        fi
      fi
      sleep 1
    done
  '"
  f3 "$@"
}

# ── File operations ───────────────────────────────────────────────
# Copy to a staging area
yy() {
  if [ -z "$1" ]; then
    echo "Usage: yy <file/dir>"
    return 1
  fi
  mkdir -p ~/tmp
  cp -r "$1" ~/tmp/
  echo "Copied to ~/tmp/$(basename "$1")"
}

# Move file
mm() {
  if [ $# -lt 2 ]; then
    echo "Usage: mm <source> <destination>"
    return 1
  fi
  mv "$1" "$2"
}

# Safe delete (uses trash)
dd_() {
  if [ -z "$1" ]; then
    echo "Usage: dd_ <file/dir>"
    return 1
  fi
  trash-put "$1" && echo "Trashed: $1"
}

# Quick create
nf() { touch "$1" && echo "Created file: $1"; }
nd() { mkdir -p "$1" && echo "Created dir: $1"; }

# Copy file path to clipboard
yp() {
  local abs
  abs=$(realpath "${1:-.}")
  echo -n "$abs" | xclip -selection clipboard
  echo "Copied path: $abs"
}

# ── Git shortcuts ─────────────────────────────────────────────────
# gs, ga, gc, gp already in .bashrc — add the missing ones
gl() { git pull; }

gd() { git --no-pager diff "$@"; }

glog() {
  git --no-pager log --oneline --graph --decorate -20 "$@"
}

# Interactive git add with fzf
gaf() {
  local files
  files=$(git --no-pager diff --name-only | fzf --multi \
    --preview 'git --no-pager diff --color=always {}' \
    --preview-window=right:60%:wrap \
    --height=80%)
  [ -n "$files" ] && echo "$files" | xargs git add && git status --short
}

# ── Java / Maven shortcuts ────────────────────────────────────────
run_java()  { mvn spring-boot:run "$@"; }
test_java() { mvn test "$@"; }
mvnc()      { mvn clean install -DskipTests "$@"; }
mvn_new() {
  if [ -z "$1" ]; then
    echo "Usage: mvn_new <artifactId> [groupId]"
    return 1
  fi

  local artifactId="$1"
  local groupId="${2:-com.huerta}"

  mvn archetype:generate \
    -DgroupId="$groupId" \
    -DartifactId="$artifactId" \
    -DarchetypeArtifactId=maven-archetype-quickstart \
    -DinteractiveMode=false

  cd "$artifactId" || return

  # Remove default junk
  rm -rf src/test/java/*

  # Create modern structure
  mkdir -p src/main/java src/main/resources src/test/java

  echo "package $groupId;" > src/main/java/App.java

  cat > src/main/java/App.java <<EOF
package $groupId;

public class App {
    public static void main(String[] args) {
        System.out.println("Hello from $artifactId");
    }
}
EOF

  echo "✅ Clean Maven project ready"
}
# ── Project launcher ──────────────────────────────────────────────
proj() {
  local dir
  dir=$(fd --type d --hidden --max-depth 4 '\.git$' ~/projects 2>/dev/null |
    sed 's|/\.git/$||' |
    fzf --preview 'ls --color=always {}' \
        --preview-window=right:40% \
        --height=60% \
        --header="Select a project")
  if [ -n "$dir" ]; then
    cd "$dir" || return
    echo "📂 $(basename "$dir")"
    git --no-pager log --oneline -5 2>/dev/null
    f3
  fi
}
