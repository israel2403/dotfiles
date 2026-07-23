export NVM_DIR="$HOME/.nvm"

if command -v nvm >/dev/null 2>&1; then
  return 0 2>/dev/null || exit 0
fi

if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
elif [ -s "/usr/share/nvm/init-nvm.sh" ]; then
  . /usr/share/nvm/init-nvm.sh
fi

if [ -s "$NVM_DIR/bash_completion" ]; then
  . "$NVM_DIR/bash_completion"
elif [ -s "/usr/share/nvm/bash_completion" ]; then
  . /usr/share/nvm/bash_completion
fi
