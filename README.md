# dotfiles

configs and systems preferences for all the machines i frequent now and in the future.

obviously you **want to read** the best part... [emacs-config.org](editors/emacs-config.org)

## scripts
### setting up a new mac
the `bootstrap-mac.sh` script is designed to be run once for initial setup, although it should remain safe to re-run if interrupted.

```sh
git clone https://github.com/chadhs/dotfiles.git ~/dotfiles
cd ~/dotfiles
sh scripts/bootstrap-mac.sh
```

it will:
- wait for Xcode Command Line Tools
- install Homebrew if needed
- install packages from the root `Brewfile` (`brew bundle`)
- apply macOS defaults (`scripts/macos-defaults.sh`)
- run `deploy.sh` for symlinks / shell setup
- optionally switch your login shell to Homebrew zsh

### keeping config changes in sync
the `deploy.sh` script is designed to setup base packages and symlinks; it is also called by the bootstrap script.

`sh deploy.sh` is idempotent and safe to re-run for symlink maintenance (prefer running it intentionally, not as a login hook).

### keeping your mac packages up to date
the `weekly-update.sh` script updates brew (via `Brewfile` + `brew upgrade`), Mac App Store apps, and global npm/gem packages.

`sh scripts/weekly-update.sh` (safe to run from any cwd)

## more info

this repo also contains other utility scripts, editor settings, etc...  feel free to use anything you find useful. ^_^

### lang version philosophy

where possible run the lastest stable version via homebrew as a base version.  if you need a specific version for development use a version manager or docker.

#### current exceptions

- node@22
- corretto21 (amazon jdk)
- postgresql@17

### fun options

create a `~/.box-name` to override the host name that is used for display purposes in zsh
