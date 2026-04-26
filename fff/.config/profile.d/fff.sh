#!/usr/bin/env bash
# fff extensions — sourced by ~/.bashrc via profile.d
# Dependencies: fff, fzf, fd, rg, bat, nvim, tmux, imv, zathura, trash-cli, xclip

# This file uses bash-specific syntax (bind -x, export -f, ${var,,}).
# Skip it when sourced from zsh so startup stays clean.
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

# ── Smart opener (used by FFF_OPENER and the o function) ───────────
fff_open() {
  case "${1,,}" in
    *.java|*.js|*.ts|*.jsx|*.tsx|*.py|*.go|*.rs|*.c|*.cpp|*.h| \
    *.sh|*.bash|*.zsh|*.yml|*.yaml|*.toml|*.json|*.xml|*.html| \
    *.css|*.md|*.txt|*.conf|*.cfg|*.ini|*.lua|*.vim|*.sql|*.gradle| \
    *.properties|*.env)
      nvim "$1" ;;
    *.png|*.jpg|*.jpeg|*.gif|*.bmp|*.webp|*.svg)
      imv "$1" ;;
    *.pdf|*.epub|*.djvu)
      zathura "$1" ;;
    *.mp4|*.mkv|*.avi|*.webm|*.mov)
      mpv "$1" 2>/dev/null || xdg-open "$1" ;;
    *.tar.*|*.zip|*.gz|*.bz2|*.xz|*.7z|*.rar)
      echo "Archive: $1"; file "$1"; echo "---"; tar tf "$1" 2>/dev/null || unzip -l "$1" 2>/dev/null ;;
    *)
      # Fallback: if it looks like text, open in nvim; otherwise xdg-open
      if file -b --mime-type "$1" | grep -q "^text/"; then
        nvim "$1"
      else
        xdg-open "$1"
      fi ;;
  esac
}
export -f fff_open
export FFF_OPENER=fff_open

# Shorthand for the opener
o() { fff_open "$1"; }

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
