# dotfiles

configs and systems preferences for all the machines i frequent now and in the future.

obviously you **want to read** the best part... [emacs-config.org](editors/emacs-config.org) — and its nvim counterpart: [editors/nvim/README.md](editors/nvim/README.md) with the [emacs parity keymap doc](editors/nvim/EMACS-PARITY.md).

## what's in here

| dir | contents |
| --- | --- |
| `editors/` | emacs config ([emacs-config.org](editors/emacs-config.org)), neovim config ([editors/nvim](editors/nvim/README.md)), `ideavimrc`, `editorconfig`, jetbrains plugins |
| `shells/` | zsh + bash profiles/rc files, `inputrc`, the `digitalnomad` zsh theme |
| `utils/` | `gitconfig`, `tmux.conf`, ghostty + karabiner + espanso config, `ssh_config`, agent skills, misc tool config and scripts (`project-ruby-exec`, `autogit.sh`, ...) |
| `scripts/` | `bootstrap-mac.sh`, `deploy.sh`, `doctor.sh`, `weekly-update.sh`, `macos-defaults.sh`, `links.conf`, npm/gem package lists |
| `.github/` | CI: shellcheck, `links.conf` lint, and syntax checks run on push/PR |

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

all managed symlinks and copy-once baseline files are defined in **`scripts/links.conf`** — the single source of truth shared by `deploy.sh` (applies them) and `scripts/doctor.sh` (verifies them). to manage a new config file, add a line there rather than editing the scripts. run with `DOTFILES_LINKS_ONLY=1 sh deploy.sh` to apply links without the repo update or package installs.

### agent skills
shared skills live in `utils/agents/skills/`. after `deploy.sh`, Claude and Cursor load them via `~/.agents/skills` (Claude also via `~/.claude/skills`).

machine-only skills (e.g. company-specific) go in `~/.agents/skills-local/`. re-run `deploy.sh` after adding one so it is linked into the merge dir. a local skill with the same name as a shared skill wins on that machine. deploy also drops skill names from the merge dir that no longer exist in shared or local.

### keeping your mac packages up to date
`scripts/weekly-update.sh` is the single full maintenance entry point: brew upgrade, Brewfile reconcile, Mac App Store apps, and global npm/gem packages.

`sh scripts/weekly-update.sh` (safe to run from any cwd)

for ad-hoc brew/cask/mas updates from a shell, use the aliases: `brewup`, `caskup`, `masup` (npm/gem globals are handled by weekly-update)

### checking machine health
`sh scripts/doctor.sh` verifies this machine still matches what `deploy.sh` sets up: symlinks intact and pointing at the repo, copy-once baseline files present (warns on drift from the repo version), git identity configured, toolchain present, Brewfile packages installed, and agent skills linked. FAILs mean broken setup (usually re-run `deploy.sh`); WARNs are informational. safe to run anytime, from any cwd.

the same lint/syntax checks (shellcheck, `links.conf` validation) also run remotely on every push/PR via [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

### manual steps after bootstrap
things that can't be automated from the shell, in rough order:

1. **1Password SSH agent** — System Settings → 1Password → enable SSH agent (then set `IdentityFile`/`IdentityAgent` in `~/.ssh/config.d/ssh_config`). this replaces fetching keys from the vault by hand.
2. **sign into 1Password, iCloud, and the App Store** — `mas` and `scripts/weekly-update.sh` need a signed-in App Store.
3. **Karabiner-Elements permissions** — grant the system extension and Input Monitoring when macOS prompts (System Settings → Privacy & Security).
4. **espanso** — grant Accessibility permission, then enable it as a login item.
5. **Emacs.app first launch** — if Gatekeeper complains, right-click → Open (cask builds are signed but not always notarized).
6. **PopClip / Moom / other cask apps** — grant Accessibility permissions as prompted on first launch.

`sh scripts/doctor.sh` after finishing to confirm everything landed.

### GUI neovim (neovide)
MacVim is no longer installed. for occasional GUI/Finder opens, use **Neovide** (installed via the Brewfile); it shares this repo's `init.lua`, so colors and plugins match terminal nvim.

- Finder → right click file → **Open With** → **Neovide**
- (optional) set as default for a file type via **Get Info** → Open with → Change All

## more info

this repo also contains other utility scripts, editor settings, etc...  feel free to use anything you find useful. ^_^

### lang version philosophy

where possible run the latest stable version via homebrew as a base version.  if you need a specific version for development use a version manager or docker.

#### current exceptions

- node@24
- corretto21 (amazon jdk)
- postgresql@17 (lives commented-out in the [Brewfile](Brewfile); uncomment it on a machine when you actually need it)

(node@24 and corretto21 are pinned in the [Brewfile](Brewfile); keep this list in sync with it.)

### fun options

create a `~/.box-name` to override the host name that is used for display purposes in zsh
