# ~/.zshrc — managed by the zsh GNU Stow package.

# Powerlevel10k instant prompt must precede initialization that may print.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Initialize Homebrew before loading modules that detect optional formulae.
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME='powerlevel10k/powerlevel10k'
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13
CASE_SENSITIVE=false
HYPHEN_INSENSITIVE=true
HIST_STAMPS='yyyy-mm-dd'

plugins=(
  git docker docker-compose sudo history command-not-found npm node nvm
  colored-man-pages extract systemd dirhistory fzf zsh-completions
  zsh-autosuggestions zsh-syntax-highlighting
)
fpath+=("$ZSH/custom/plugins/zsh-completions/src")
source "$ZSH/oh-my-zsh.sh"

zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" 'ma=1;30;48;5;46'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS \
  INC_APPEND_HISTORY EXTENDED_HISTORY

# Tool profiles remain shared with Bash. SDKMAN is loaded last below because
# its initializer can alter variables established by earlier startup code.
for profile in "$HOME/.config/profile.d"/*.sh(N); do
  [[ ${profile:t} == sdkman.sh ]] || source "$profile"
done

# The package owns every referenced file, so direct sourcing makes missing or
# broken modules visible immediately instead of silently skipping them.
source "$HOME/.config/zsh/functions/files.zsh"
source "$HOME/.config/zsh/functions/navigation.zsh"
source "$HOME/.config/zsh/functions/java.zsh"
source "$HOME/.config/zsh/functions/php.zsh"
source "$HOME/.config/zsh/functions/php-server.zsh"
source "$HOME/.config/zsh/functions/tomee.zsh"
source "$HOME/.config/zsh/functions/git.zsh"

source "$HOME/.config/zsh/integrations/fzf.zsh"
source "$HOME/.config/zsh/integrations/fff.zsh"
source "$HOME/.config/zsh/integrations/cli-tools.zsh"

# Bindings load last because they invoke functions defined above.
source "$HOME/.config/zsh/keybindings.zsh"
unset profile

# OMZ's Git plugin already supplies common aliases; these are intentional local
# names that do not collide with its gst/gaa/gc/gp set.
alias gs='git status'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias grep='grep --color=auto'

[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
