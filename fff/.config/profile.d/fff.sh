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

# ── Java / Maven helpers (portable: defined ABOVE the zsh-guard) ──────────────
# Available in both zsh and bash. Previously these lived in the bash-only
# section, so 'mvn_new not found' was reported from zsh.
run_java()  { mvn spring-boot:run "$@"; }
test_java() { mvn test "$@"; }
mvnc()      { mvn clean install -DskipTests "$@"; }

# Resolve a Java version request (major like '21', SDKMAN id like '21.0.10-tem',
# or empty) into the best matching SDKMAN identifier installed on this box.
# Echoes the identifier on success; echoes the original argument on miss so the
# caller can still write something sensible into .sdkmanrc.
_mvn_new_resolve_sdkman_java() {
  local want=$1
  local sdk_dir="${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java"
  [ -d "$sdk_dir" ] || { printf '%s\n' "$want"; return 1; }

  # Specific SDKMAN id passed and installed.
  if [ -n "$want" ] && [ -d "$sdk_dir/$want" ]; then
    printf '%s\n' "$want"
    return 0
  fi

  # Major-only -> newest installed entry whose major matches.
  if [ -n "$want" ] && printf '%s' "$want" | grep -qE '^[0-9]+$'; then
    local cand
    cand=$(ls -1 "$sdk_dir" 2>/dev/null \
      | grep -E "^${want}([.-]|$)" \
      | sort -V \
      | tail -1)
    if [ -n "$cand" ]; then
      printf '%s\n' "$cand"
      return 0
    fi
    printf '%s\n' "$want"
    return 2  # major requested but no installed match
  fi

  # No version requested -> use the current SDKMAN java if any.
  if [ -L "$sdk_dir/current" ]; then
    basename "$(readlink "$sdk_dir/current")"
    return 0
  fi
  return 1
}

# mvn_new -- scaffold a clean Maven quickstart project pinned to a chosen
# Java release. Java version is flexible:
#   * --java N            explicit major (21, 25, …) or SDKMAN id (21.0.10-tem)
#   * \$MVN_NEW_JAVA       env var fallback
#   * SDKMAN current java if neither set
#   * 21 as final fallback
# Group id is configurable the same way (--group / \$MVN_NEW_GROUP, default
# com.huerta).
#
# Project changes vs. the upstream archetype:
#   * Pins maven-archetype-quickstart:1.5 (the first version that supports a
#     modern Java release out of the box).
#   * Rewrites pom.xml to set maven.compiler.source/target/release to the
#     selected major (release is the canonical Java >=9 property).
#   * Writes a .sdkmanrc so 'cd <project>' in an SDKMAN-aware shell switches
#     to the chosen JDK automatically.
#
# Usage:
#   mvn_new my-app                       # current/default Java
#   mvn_new --java 21 my-app             # pin to Java 21
#   mvn_new --java 25 --group com.acme my-app
#   MVN_NEW_JAVA=25 mvn_new my-app       # via env var
mvn_new() {
  local java_version="${MVN_NEW_JAVA:-}"
  local group="${MVN_NEW_GROUP:-com.huerta}"
  local artifact=""
  local archetype_version="1.5"

  while [ $# -gt 0 ]; do
    case "$1" in
      -j|--java)
        java_version=$2
        shift 2 || return 2
        ;;
      -g|--group)
        group=$2
        shift 2 || return 2
        ;;
      --archetype-version)
        archetype_version=$2
        shift 2 || return 2
        ;;
      -h|--help)
        cat <<'EOF'
mvn_new -- scaffold a Maven quickstart project pinned to a chosen Java release.

Usage:
  mvn_new [-j|--java VERSION] [-g|--group GROUP_ID] [--archetype-version VER] <artifactId>

Options:
  -j, --java VERSION         major (e.g. 21, 25) or full SDKMAN id (e.g. 21.0.10-tem).
                             Defaults to \$MVN_NEW_JAVA, then SDKMAN current java, then 21.
  -g, --group GROUP_ID       Maven groupId. Defaults to \$MVN_NEW_GROUP, then com.huerta.
      --archetype-version V  Override maven-archetype-quickstart version (default 1.5).

Examples:
  mvn_new my-app
  mvn_new --java 21 --group com.acme certification-prep
  MVN_NEW_JAVA=25 mvn_new future-app
EOF
        return 0
        ;;
      --)
        shift; break
        ;;
      -*)
        echo "mvn_new: unknown option '$1' (try --help)" >&2
        return 2
        ;;
      *)
        if [ -z "$artifact" ]; then
          artifact=$1
          shift
        else
          echo "mvn_new: unexpected argument '$1'" >&2
          return 2
        fi
        ;;
    esac
  done

  if [ -z "$artifact" ]; then
    echo "mvn_new: missing <artifactId>. Try: mvn_new --help" >&2
    return 1
  fi

  # Resolve SDKMAN id (may rewrite a bare major like '21' to e.g. '21.0.10-tem').
  local sdk_id
  sdk_id=$(_mvn_new_resolve_sdkman_java "$java_version")
  local resolve_rc=$?

  # If the resolver couldn't find anything and the user didn't supply a value,
  # default to Java 21.
  if [ -z "$java_version" ] && [ -z "$sdk_id" ]; then
    sdk_id="21"
    java_version="21"
  fi
  [ -z "$java_version" ] && java_version="$sdk_id"

  # Major number used for maven.compiler.{source,target,release}.
  local java_major
  java_major=$(printf '%s' "$java_version" | sed -E 's/^([0-9]+).*/\1/')
  if ! printf '%s' "$java_major" | grep -qE '^[0-9]+$'; then
    echo "mvn_new: could not derive a numeric Java major from '$java_version'" >&2
    return 2
  fi

  echo ">>> mvn_new: artifact=$artifact  group=$group  java=$java_major  sdkman=$sdk_id  archetype=$archetype_version"
  if [ "$resolve_rc" = "2" ]; then
    echo "    note: SDKMAN has no installed Java with major '$java_major'."
    echo "          .sdkmanrc will be written with '$sdk_id'; run 'sdk install java $sdk_id' to populate."
  fi

  mvn archetype:generate \
    -DgroupId="$group" \
    -DartifactId="$artifact" \
    -DarchetypeGroupId=org.apache.maven.archetypes \
    -DarchetypeArtifactId=maven-archetype-quickstart \
    -DarchetypeVersion="$archetype_version" \
    -DjavaCompilerVersion="$java_major" \
    -DinteractiveMode=false || return $?

  cd "$artifact" || return

  # Standard layout (the archetype already creates most of this).
  mkdir -p src/main/java src/main/resources src/test/java

  # Rewrite pom.xml to pin source/target/release to the chosen Java major.
  # release is the canonical property for Java 9+ and supersedes source/target.
  if [ -f pom.xml ]; then
    sed -i \
      -e "s|<maven\.compiler\.source>[^<]*</maven\.compiler\.source>|<maven.compiler.source>${java_major}</maven.compiler.source>|" \
      -e "s|<maven\.compiler\.target>[^<]*</maven\.compiler\.target>|<maven.compiler.target>${java_major}</maven.compiler.target>|" \
      pom.xml
    if ! grep -q '<maven\.compiler\.release>' pom.xml; then
      sed -i \
        "s|<maven\.compiler\.target>${java_major}</maven\.compiler\.target>|<maven.compiler.target>${java_major}</maven.compiler.target>\n    <maven.compiler.release>${java_major}</maven.compiler.release>|" \
        pom.xml
    fi
  fi

  # .sdkmanrc -- 'cd' into the project auto-switches the JDK if you've
  # enabled sdkman_auto_env in ~/.sdkman/etc/config.
  printf 'java=%s\n' "$sdk_id" > .sdkmanrc

  echo "✅ Clean Maven project ready  (Java release=$java_major, .sdkmanrc=java=$sdk_id)"
}

# ── Source fff config (BOTH shells) ────────────────────────────────────
# fff itself reads FFF_FAV1..FFF_FAV9, FFF_OPENER, etc. from its environment.
# fff.conf is plain `export` statements (portable). Sourcing it in BOTH zsh
# and bash is what makes the favorites jumps (digit keys 1-9 inside fff) work
# regardless of which shell you launched fff from.
[ -f ~/.config/fff/fff.conf ] && . ~/.config/fff/fff.conf

# ── f3 wrapper (portable across zsh and bash) ───────────────────────────
# Runs fff and, on exit, cd's the parent shell into wherever fff was. The
# function must be defined ABOVE the zsh-guard or zsh will print
# "command not found: f3" when you try to call it.
f3() {
  fff "$@"
  if [ -f "${FFF_CD_FILE:-$HOME/.fff_d}" ]; then
    local dir
    dir=$(cat "${FFF_CD_FILE:-$HOME/.fff_d}")
    [ -d "$dir" ] && cd "$dir"
    rm -f "${FFF_CD_FILE:-$HOME/.fff_d}"
  fi
}

# ── F3 key -> f3 (per-shell binding) ─────────────────────────────────
# zsh: bindkey -s injects the literal keys 'f3<CR>' into the line editor,
#       which is the simplest way to launch a TUI command from a key.
# bash: bind -x runs the function directly; defined inside the bash-only block
#       below so it doesn't error in zsh.
if [ -n "${ZSH_VERSION:-}" ]; then
  bindkey -s '\eOR'   'f3\n'   # F3 in some terminals
  bindkey -s '\e[13~' 'f3\n'   # F3 in other terminals
fi

# This file uses bash-specific syntax below (bind -x, export -f, ${var,,}).
# Skip the rest when sourced from zsh so startup stays clean.
if [ -n "${ZSH_VERSION:-}" ]; then
  return 0
fi

# Bind F3 in interactive bash to call the function directly.
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

# (Java/Maven helpers are defined above the zsh-guard so zsh sees them too.)
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
