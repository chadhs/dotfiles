# Neovim Configuration

```
███╗   ██╗ ███████╗  ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗
████╗  ██║ ██╔════╝ ██╔═══██╗ ██║   ██║ ██║ ████╗ ████║
██╔██╗ ██║ █████╗   ██║   ██║ ██║   ██║ ██║ ██╔████╔██║
██║╚██╗██║ ██╔══╝   ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║
██║ ╚████║ ███████╗ ╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║
╚═╝  ╚═══╝ ╚══════╝  ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝

=====================================================================
===============   READ THIS BEFORE EDITING (OR NOT)   ===============
=====================================================================

      .---.                .---. .---. .---. .---.
      | , |  is the leader | : | | w | | q | | ↩ |  writes and quits
      '---'                '---' '---' '---' '---'

             hjkl required  ·  no mouse  ·  :Tutor first

=====================================================================
```

Personal Neovim configuration, deployed as `~/.config/nvim` via a symlink from
the [dotfiles](../../README.md) repo (`deploy.sh`). Derived from
[kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) (MIT); see
[LICENSE.md](./LICENSE.md).

See [EMACS-PARITY.md](./EMACS-PARITY.md) for the keybind and language tooling
map against `editors/emacs-config.org`. This is intentionally **not** a full
Emacs reimplementation — Org agenda depth, multi-term shell visor, and
perspectives are thinner or deferred in favor of tmux + Neovim-native tools.

## Layout

| Path | Purpose |
| --- | --- |
| `init.lua` | entry point: leader, requires, lazy.nvim bootstrap + `setup('plugins')` |
| `lua/options.lua` | editor options |
| `lua/keymaps.lua` | base keymaps + autocmds |
| `lua/lib/` | own modules: `root.lua` (buffer/git-root cwd), `ruby_tooling.lua` (project-aware Ruby tooling), `health.lua` |
| `lua/plugins/` | one lazy.nvim spec per plugin — auto-imported, drop a file and it loads |

## Adding a plugin

Create `lua/plugins/<name>.lua` returning a lazy.nvim spec table. No require
list to update; lazy picks it up on next start.

## Updating plugins

```sh
:Lazy update   # then commit the updated lazy-lock.json… or don't (it's gitignored here)
```

## Quick verification

```sh
export XDG_CONFIG_HOME=/path/to/dotfiles/editors
export XDG_DATA_HOME=/tmp/nvim-test/share
export XDG_STATE_HOME=/tmp/nvim-test/state
export XDG_CACHE_HOME=/tmp/nvim-test/cache
nvim --headless "+Lazy! sync" "+qa"
nvim  # then try ,gst ,jd ,fu ,t ,gf ,nt
```
