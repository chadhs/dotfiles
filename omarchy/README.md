# omarchy — owned omarchy customizations

Machine-independent customizations for [Omarchy](https://omarchy.org) (Arch +
Hyprland) installs. `deploy.sh` links these into place on `linux`-scoped
entries in `scripts/links.conf`; see that file for the exact mapping.

## What's here

| path | deploys to | notes |
| --- | --- | --- |
| `hypr/bindings.lua` | `~/.config/hypr/bindings.lua` | mac-style text nav, Moom chords, switcher wiring |
| `hypr/input.lua` | `~/.config/hypr/input.lua` | no tap-to-click, natural scroll, per-device list |
| `hypr/hyprland.lua` | `~/.config/hypr/hyprland.lua` | vendored for the float-on-top window rules (see "focus on open" below) |
| `shell.json` | `~/.config/omarchy/shell.json` | transparent bar + altswitch plugin entry |
| `moom.conf` | `~/.config/omarchy/moom.conf` | `MOOM_MODE=planA` |
| `ghostty/config` | `~/.config/ghostty/config` | linux terminal config (fork of omarchy's, with local font-size/padding tweaks; mac ghostty stays `utils/ghostty/config`) |
| `env/90-shell.conf` | `~/.config/environment.d/90-shell.conf` | session `SHELL` mirror (ghostty launches `$SHELL`; guards against systemd user-manager staleness after chsh) |
| `bin/` | `~/.local/bin/` | `omarchy-moom`, `omarchy-window-raise-front`, `focus-new-windows` |
| `systemd/user/` | `~/.config/systemd/user/` | dotfiles-shipped user units, enabled by `deploy.sh` on arch |
| `plugins/io.github.pablo-merino.altswitch/` | `~/.config/omarchy/plugins/io.github.pablo-merino.altswitch/` | owned fork (see below) |
| `docs/moom-omarchy-plan.md` | — | design doc for `omarchy-moom` + the Moom chords in `bindings.lua` |

## focus on open: `focus-new-windows` + float-on-top rules

The problem: launching an app while a floating window has focus meant the
new app silently lost keyboard focus (Hyprland bounces focus back to the
floater after the new window maps), and — because Hyprland always renders
tiled windows below the floating layer — the app was also invisible behind
a full-screen floater.

The fix is two repo-owned pieces:

1. **`focus-new-windows`** (`omarchy/bin/`, run by
   `omarchy/systemd/user/focus-new-windows.service`): listens on Hyprland's
   event socket for `openwindow` events and re-focuses the new window
   ~0.15s after it maps, winning the focus-bounce race deterministically.
   Skips pinned overlays and windows opening on non-active workspaces.
   Gotchas baked in (cost real debugging time): event addresses have no
   `0x` prefix, the socket lives in `$XDG_RUNTIME_DIR/hypr/`, socat needs
   `-U` (socket→stdout) not `-u` when stdin is null, and window focus goes
   through `hyprctl eval 'hl.dsp.focus({ window = "0x..." })'` — the classic
   `hyprctl dispatch focuswindow address:` does not parse in 0.56's Lua
   dispatcher. Debug trail: `$XDG_RUNTIME_DIR/focus-new-windows.log`.
2. **Float-on-top window rules** (`omarchy/hypr/hyprland.lua`): no setting
   can raise a tiled window above floating windows, so apps that must be
   *seen* when a full-screen floater is up are floated via `o.window(...)`
   rules (ChatGPT today; add more with the class from `hyprctl activewindow`).

`hyprland.lua` was vendored for this (previously "stock omarchy"). It is
tiny and stable, but it is the file omarchy's update migrations may rewrite
— if an `omarchy update` changes Hyprland's config template, diff
`~/.config/hypr/hyprland.lua.bak-omarchy` against the repo copy and fold in
what's new. The unit is enabled by `deploy.sh` (`systemctl --user enable
--now`); an `autostart.lua` hook was rejected deliberately — that file
stays stock omarchy.

## Deliberately NOT included

- `~/.config/hypr/monitors.lua` — omarchy generates this per machine (display
  wiring, scale). Keep it machine-local.
- `~/.config/hypr/looknfeel.lua`, `autostart.lua`, `xdph.conf`,
  `hyprsunset.conf` — stock omarchy; let `omarchy` manage them.
  (`hyprland.lua` used to be on this list; it was vendored for the
  float-on-top rules above.)

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
