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

### Brewfile location
the `Brewfile` lives at the **repo root** (not under `scripts/`). that matches Homebrew’s usual layout so `cd ~/dotfiles && brew bundle` works without extra flags, while `scripts/weekly-update.sh` still passes `--file` explicitly.

### keeping config changes in sync
the `deploy.sh` script is designed to setup base packages and symlinks; it is also called by the bootstrap script.

`sh deploy.sh` is idempotent and safe to re-run for symlink maintenance (prefer running it intentionally, not as a login hook).

### agent skills
shared skills live in `utils/agents/skills/`. after `deploy.sh`, Claude and Cursor load them via `~/.agents/skills` (Claude also via `~/.claude/skills`).

machine-only skills (e.g. company-specific) go in `~/.agents/skills-local/`. re-run `deploy.sh` after adding one so it is linked into the merge dir. a local skill with the same name as a shared skill wins on that machine. deploy also drops skill names from the merge dir that no longer exist in shared or local.

### keeping your mac packages up to date
`scripts/weekly-update.sh` is the single full maintenance entry point: brew upgrade, Brewfile reconcile, Mac App Store apps, and global npm/gem packages.

`sh scripts/weekly-update.sh` (safe to run from any cwd)

for ad-hoc brew/cask/mas updates from a shell, use the aliases: `brewup`, `caskup`, `masup` (npm/gem globals are handled by weekly-update)

### opening files from Finder with Neovim
MacVim is no longer installed. for occasional GUI/Finder opens, deploy links **Open in Neovim.app**, which launches the file in Ghostty running `nvim`.

after `sh deploy.sh`:
- Finder → right click file → **Open With** → **Open in Neovim**
- (optional) set as default for a file type via **Get Info** → Open with → Change All

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
