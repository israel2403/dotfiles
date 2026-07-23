# Package manifests

Flat package lists used by `migrate-packages` to recreate a machine.

* `apt.txt` — Ubuntu/Debian packages installed with `apt-get` when available.
  Packages missing from the configured Ubuntu repositories are skipped with a
  warning instead of aborting the whole bootstrap.
* `pacman.txt` — explicit packages from the official Arch repositories.
* `aur.txt` — foreign / AUR packages for Arch/Omarchy.

## Replay

```bash
migrate-packages            # installs the manifest for this OS
migrate-packages --dry-run  # preview only
```

## Regenerate Arch Lists

```bash
pacman -Qqen | sort -u > ~/dotfiles/packages/pacman.txt
pacman -Qqm  | sort -u > ~/dotfiles/packages/aur.txt
```

## Maintain Ubuntu List

Edit `packages/apt.txt` manually. Keep it focused on packages available from
Ubuntu repositories; use SDKMAN/NVM scripts for Java and Node.
