# AGENTS.md

## Cursor Cloud specific instructions

This repo is a personal **dotfiles** collection: setup/bootstrap shell scripts plus
editor/shell configuration. There is **no server application, build step, or automated
test suite** — the "product" is the deploy/bootstrap tooling and the config files it symlinks.

### Toolchain
- **Lint:** `shellcheck` is the shell linter (declared in `Brewfile`; scripts contain
  `# shellcheck disable=...` directives). Lint everything with:
  `shellcheck $(find . -name '*.sh' -not -path './.git/*')`
- The zsh-shebang scripts (`scripts/weekly-update.sh`, `scripts/brew-update.sh`,
  `scripts/mas-update.sh`, `scripts/npm-update.sh`, `utils/autogit.sh`) report
  `SC1071` ("ShellCheck only supports sh/bash/dash/ksh") — this is expected, not a real
  failure. There are also pre-existing style/info findings; do not treat them as new breakage.

### Running the product
- `scripts/bootstrap-mac.sh` is **macOS-only** (uses `xcode-select`, Homebrew, `chsh`,
  `defaults`) and cannot run on the Linux cloud VM.
- `deploy.sh` is the cross-platform core; it detects Ubuntu/Debian and takes a Linux path.
  It uses `sudo apt-get install` and network (installs oh-my-zsh via curl, clones Vundle),
  so it needs sudo + egress (both available on the cloud VM). It has no `set -e`, so
  individual step failures are non-fatal and it still prints `setup complete!`.

### Non-obvious gotchas when running `deploy.sh`
- It runs against `$HOME` directly and would modify the VM's real home. To exercise it
  safely/repeatably, run it under a throwaway `HOME` with a repo copy at `$HOME/dotfiles`,
  e.g. `HOME=/tmp/demo sh /tmp/demo/dotfiles/deploy.sh`.
- `update_repo()` does `cd ~/dotfiles && git pull` — it requires `~/dotfiles` to exist;
  a missing upstream just prints a warning and is ignored.
- It only creates `~/.config/nvim` if `~/.config` already exists; a bare sandbox HOME
  triggers a harmless `ln: ... No such file or directory` for that one symlink.
- `shells/zshrc`: for **non-root interactive Linux** shells it auto-attaches/creates tmux
  and `exit 0`s. When scripting a demo, set `TMUX=<anything>` (or run inside tmux) to keep
  the shell in the foreground so it does not get hijacked.

### Verifying the deployed shell
After `deploy.sh`, launching `zsh -i` from the deployed `$HOME` loads oh-my-zsh with the
custom `digitalnomad` theme (two-line `╭…`/`╰±` prompt), the Linux plugin set
`git tmux vi-mode`, and aliases from `shells/sh_aliases` (e.g. `ll`).
