# qutebrowser

Stow package that manages the qutebrowser user configuration.

```bash
cd ~/dotfiles
stow qutebrowser      # links ~/.config/qutebrowser/config.py
```

## Managed

* `.config/qutebrowser/config.py` — manual configuration (keybindings,
  dark-mode tuning, TLS, session restore, Google sign-in UA fix, etc.)

## Google sign-in fix

Google blocks qutebrowser's default QtWebEngine user-agent on sign-in
pages with *"this browser or app may not be secure"* (affects Gmail,
Drive, YouTube login, OAuth "Sign in with Google" buttons, …).

`config.py` spoofs a Firefox UA on `accounts.google.com` and other
`*.google.com` domains, which is the upstream-recommended workaround
(see qutebrowser issues
[#5182](https://github.com/qutebrowser/qutebrowser/issues/5182) and
[#8492](https://github.com/qutebrowser/qutebrowser/issues/8492)).

Because `config.py` is stowed by `bootstrap-new-machine`, the fix is
applied automatically on every fresh install — no extra step needed.
If qutebrowser is already running, reload with `:config-source` or
restart to pick up changes.

## NOT managed (runtime / machine-local state)

Intentionally left outside the repo because they are machine-specific or
frequently rewritten by qutebrowser itself:

* `autoconfig.yml` — written by qutebrowser on every settings change
* `quickmarks`, `bookmarks/` — user-edited but also touched by the app
* `greasemonkey/`, `qsettings/` — runtime caches / persisted Qt settings

If you want bookmarks/quickmarks to travel too, move them into this package
manually and re-run `stow qutebrowser`.
