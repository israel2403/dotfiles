# qutebrowser

Stow package that manages the qutebrowser user configuration.

```bash
cd ~/dotfiles
stow qutebrowser      # links ~/.config/qutebrowser/config.py
```

## Managed

* `.config/qutebrowser/config.py` — manual configuration (keybindings,
  dark-mode tuning, TLS, session restore, etc.)

## NOT managed (runtime / machine-local state)

Intentionally left outside the repo because they are machine-specific or
frequently rewritten by qutebrowser itself:

* `autoconfig.yml` — written by qutebrowser on every settings change
* `quickmarks`, `bookmarks/` — user-edited but also touched by the app
* `greasemonkey/`, `qsettings/` — runtime caches / persisted Qt settings

If you want bookmarks/quickmarks to travel too, move them into this package
manually and re-run `stow qutebrowser`.
