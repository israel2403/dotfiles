# Package manifests

Two flat lists used by `migrate-packages` to recreate this system on a new
machine (e.g. a fresh Omarchy install).

* `pacman.txt` — explicit packages from the official Arch repositories.
  `qutebrowser` is included intentionally.
* `aur.txt` — foreign / AUR packages.

## Regenerate (run on the source machine)

```bash
pacman -Qqen | sort -u > ~/dotfiles/packages/pacman.txt
pacman -Qqm  | sort -u > ~/dotfiles/packages/aur.txt
# keep qutebrowser pinned even if it's somehow uninstalled locally
grep -qx qutebrowser ~/dotfiles/packages/pacman.txt \
  || { echo qutebrowser >> ~/dotfiles/packages/pacman.txt; \
       sort -u -o ~/dotfiles/packages/pacman.txt ~/dotfiles/packages/pacman.txt; }
```

## Replay (run on the destination machine)

```bash
migrate-packages            # installs everything in both files
migrate-packages --dry-run  # preview only
```
