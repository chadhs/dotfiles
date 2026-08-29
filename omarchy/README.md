# omarchy — vendored omarchy customizations

Machine-independent customizations for [Omarchy](https://omarchy.org) (Arch +
Hyprland) installs. `deploy.sh` links these into place on `linux`-scoped
entries in `scripts/links.conf`; see that file for the exact mapping.

## What's here

| path | deploys to | notes |
| --- | --- | --- |
| `hypr/bindings.lua` | `~/.config/hypr/bindings.lua` | mac-style text nav, Moom chords, switcher wiring |
| `hypr/input.lua` | `~/.config/hypr/input.lua` | no tap-to-click, natural scroll, per-device list |
| `shell.json` | `~/.config/omarchy/shell.json` | transparent bar + altswitch plugin entry |
| `moom.conf` | `~/.config/omarchy/moom.conf` | `MOOM_MODE=planA` |
| `bin/` | `~/.local/bin/` | `omarchy-moom`, `omarchy-appswitch`, `omarchy-window-raise-front` |
| `plugins/io.github.pablo-merino.altswitch/` | `~/.config/omarchy/plugins/io.github.pablo-merino.altswitch/` | vendored plugin (no `.git`) |

## Deliberately NOT vendored

- `~/.config/hypr/monitors.lua` — omarchy generates this per machine (display
  wiring, scale). Keep it machine-local.
- `~/.config/hypr/looknfeel.lua`, `autostart.lua`, `hyprland.lua`,
  `xdph.conf`, `hyprsunset.conf` — stock omarchy; let `omarchy` manage them.

## altswitch plugin provenance

- Upstream: https://github.com/Pablo-Merino/omarchy-altswitch
- Base commit: `b99a58ca94e7ffcb6785d009a2e88f9e68599642`
  (merge of PR #2, 2026-08-28)
- Local patch: modifications to `altswitch.lua` adding SUPER-chord support
  (used by the Moom/switcher keymaps in `hypr/bindings.lua`)

### Refreshing the vendored plugin

`omarchy plugin update` no longer manages this plugin once it's a symlink into
the dotfiles repo. To pull upstream changes:

1. Clone the plugin somewhere temp:
   `git clone https://github.com/Pablo-Merino/omarchy-altswitch /tmp/opencode/altswitch-upstream`
2. Re-apply the local patch to `altswitch.lua` (keep a copy of the diff before
   replacing the vendored copy: `diff -u` upstream vs vendored).
3. Replace everything in `omarchy/plugins/io.github.pablo-merino.altswitch/`
   except keep the patched `altswitch.lua`, and ensure no `.git` dir is
   committed.
4. Update the base commit + provenance in this README.
5. Run `deploy.sh` (force-link refreshes the symlink target; the files here
   are what changes) and reload the omarchy shell.

If the patch set grows, consider forking the plugin on GitHub and vendoring
that fork instead — cleaner long-term than patch-on-refresh.
