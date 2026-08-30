# omarchy — owned omarchy customizations

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
| `ghostty/config` | `~/.config/ghostty/config` | linux terminal config (fork of omarchy's, with local font-size/padding tweaks; mac ghostty stays `utils/ghostty/config`) |
| `env/90-shell.conf` | `~/.config/environment.d/90-shell.conf` | session `SHELL` mirror (ghostty launches `$SHELL`; guards against systemd user-manager staleness after chsh) |
| `bin/` | `~/.local/bin/` | `omarchy-moom`, `omarchy-window-raise-front` |
| `plugins/io.github.pablo-merino.altswitch/` | `~/.config/omarchy/plugins/io.github.pablo-merino.altswitch/` | owned fork (see below) |
| `docs/moom-omarchy-plan.md` | — | design doc for `omarchy-moom` + the Moom chords in `bindings.lua` |

## Deliberately NOT included

- `~/.config/hypr/monitors.lua` — omarchy generates this per machine (display
  wiring, scale). Keep it machine-local.
- `~/.config/hypr/looknfeel.lua`, `autostart.lua`, `hyprland.lua`,
  `xdph.conf`, `hyprsunset.conf` — stock omarchy; let `omarchy` manage them.

## ghostty config caveat: the text-size slider

`omarchy display text size <px>` edits `~/.config/ghostty/config` with
`sed -i`, which **replaces the symlink with a regular file** — one slider
drag silently severs the repo link. Doctor flags it (FAIL: not a symlink);
heal with `sh deploy.sh`. Terminal font size changes are repo edits now:
change `font-size` in `omarchy/ghostty/config`, commit, and pull/deploy on
other machines.

## altswitch plugin — owned fork

This is our fork; we own the patched copy and treat it as authoritative.

- Upstream (attribution): https://github.com/Pablo-Merino/omarchy-altswitch
  (MIT, see bundled `LICENSE`)
- Base commit: `b99a58ca94e7ffcb6785d009a2e88f9e68599642`
  (merge of PR #2, 2026-08-28)
- Our patch: SUPER-chord support in `altswitch.lua` ("SUPER-CHORD PATCH"
  block; ownership header at the top of the file), used by the keymaps in
  `hypr/bindings.lua`
- **The directory name is load-bearing** — it must match the plugin `id` in
  `manifest.json` and the entry in `shell.json`, because omarchy's plugin
  loader resolves the id against the directory name under
  `~/.config/omarchy/plugins/`. Do not rename it.

### Refreshing the fork from upstream

`omarchy plugin update` no longer manages this plugin once it's a symlink into
the dotfiles repo. To pull upstream changes:

1. Clone the plugin somewhere temp:
   `git clone https://github.com/Pablo-Merino/omarchy-altswitch /tmp/opencode/altswitch-upstream`
2. Re-apply our patch to `altswitch.lua` (keep a copy of the diff before
   replacing the forked copy: `diff -u` upstream vs forked), including the
   ownership header at the top of the file.
3. Replace everything in `omarchy/plugins/io.github.pablo-merino.altswitch/`
   except keep the patched `altswitch.lua`, and ensure no `.git` dir is
   committed.
4. Update the base commit in this README and in the `altswitch.lua` header.
5. Run `deploy.sh` and reload the omarchy shell.

If the patch set grows, the cleaner long-term path is a GitHub fork of the
plugin that we track here.
