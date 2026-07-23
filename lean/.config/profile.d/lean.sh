# Lean 4 toolchain managed by elan.
export ELAN_HOME="${ELAN_HOME:-$HOME/.elan}"
if [ -d "$ELAN_HOME/bin" ]; then
  case ":$PATH:" in
    *":$ELAN_HOME/bin:"*) ;;
    *) export PATH="$ELAN_HOME/bin:$PATH" ;;
  esac
fi
