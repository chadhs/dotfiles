# omarchy — owned omarchy customizations

Machine-independent customizations for [Omarchy](https://omarchy.org) (Arch +
Hyprland) installs. `deploy.sh` links these into place on `linux`-scoped
entries in `scripts/links.conf`; see that file for the exact mapping.

## What's here

| path | deploys to | notes |
| --- | --- | --- |
| `hypr/bindings.lua` | `~/.config/hypr/bindings.lua` | mac-style text nav, Moom chords, switcher wiring, Vicinae on SUPER+SPACE |
| `hypr/input.lua` | `~/.config/hypr/input.lua` | no tap-to-click, natural scroll, per-device list |
| `hypr/looknfeel.lua` | `~/.config/hypr/looknfeel.lua` | rounding/border tweaks + float-on-top window rules (see "focus on open" below) |
| `hypr/monitors.lua` | `~/.config/hypr/monitors.lua` | versioned for the 1.6 scale this machine wants (omarchy's default is `"auto"`) |
| `shell.json` | `~/.config/omarchy/shell.json` | opaque bar + switchboard/switcharoo plugin entries |
| `moom.conf` | `~/.config/omarchy/moom.conf` | `MOOM_MODE=planA` |
| `ghostty/config` | `~/.config/ghostty/config` | linux terminal config (fork of omarchy's, with local font-size/padding tweaks; mac ghostty stays `utils/ghostty/config`) |
| `env/90-shell.conf` | `~/.config/environment.d/90-shell.conf` | session `SHELL` mirror (ghostty launches `$SHELL`; guards against systemd user-manager staleness after chsh) |
| `bin/` | `~/.local/bin/` | `omarchy-moom`, `omarchy-quit-app`, `omarchy-agent-tools-update`, `omarchy-window-raise-front`, `focus-new-windows` |
| `systemd/user/` | `~/.config/systemd/user/` | dotfiles-shipped user units, enabled by `deploy.sh` on arch |
| `vicinae/` | `~/.config/vicinae/settings.json`, copy-once `~/.local/share/vicinae/shortcuts/shortcuts.json` | launcher config + `{query}` web-search shortcuts (see below) |
| `aur.packages` | — | AUR list `deploy.sh` installs (vicinae-bin + agent desktop apps); `omarchy-agent-tools-update` reads the same file |
| `plugins/patches/` | — | local patches for plugin-manager-managed plugins (see below) |
| `docs/moom-omarchy-plan.md` | — | design doc for `omarchy-moom` + the Moom chords in `bindings.lua` |

## focus on open: `focus-new-windows` + float-on-top rules

The problem: launching an app while a floating window has focus meant the
new app silently lost keyboard focus (Hyprland bounces focus back to the
floater after the new window maps), and — because Hyprland always renders
tiled windows below the floating layer — the app was also invisible behind
a full-screen floater.

The fix is three repo-owned pieces:

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
2. **Raise-front on open** (also `focus-new-windows`, added after the
   switcharoo migration exposed the gap): focus alone cannot lift a tiled
   window above the floating layer, so after refocusing, the window goes
   through `omarchy-window-raise-front` — raised, and floated in place
   (tiled geometry preserved) only when a floater actually covers it.
   Newly launched apps always surface, tiled or floated. Trade-off: such
   windows stay floating until re-tiled (SUPER+ALT+T).
3. **Float-on-top window rules** (`omarchy/hypr/looknfeel.lua`): no setting
   can raise a tiled window above floating windows, so apps that must be
   *seen* when a full-screen floater is up are floated via `o.window(...)`
   rules (ChatGPT today; add more with the class from `hyprctl activewindow`).

`hyprland.lua` used to be vendored to carry those rules, which was fragile —
it is omarchy's config *entrypoint* template, so an upstream change to its
require list would silently never load. The rules now live in
`looknfeel.lua` (safe to own: stock is comments/examples, real defaults load
from `default/hypr/` regardless) and `hyprland.lua` is stock omarchy again —
if it ever needs reverting to stock after an update:
`omarchy refresh config hypr/hyprland.lua`. The unit is enabled by `deploy.sh`
(`systemctl --user enable --now`); an `autostart.lua` hook was rejected
deliberately — that file stays stock omarchy.

## Vicinae (SUPER+SPACE)

Omarchy's native menu searches apps and nested commands. It does not do
home-directory file search or `{query}` web searches, so SUPER+SPACE opens
[Vicinae](https://docs.vicinae.com/) instead. SUPER+ALT+SPACE is the full
Omarchy menu (Install / Style / Trigger). SUPER+ESCAPE, the bar menu button,
and the clipboard overlays stay stock.

`vicinae-bin` is in [`aur.packages`](aur.packages). `sh deploy.sh` installs
it with the other AUR apps (yay will prompt for sudo), links the settings,
copies the shortcuts baseline if missing, then enables the packaged
`vicinae.service` (the package owns that unit; we do not vendor a copy).
Doctor FAILs if the package or unit is missing.

Web search is five `{query}` shortcuts in `vicinae/shortcuts.json` (Google,
DuckDuckGo, Wikipedia, YouTube, GitHub). They are fallbacks: type anything
that is not an app, highlight Search Google, Enter. Files stay out of the
root box; use the Search Files command (also a fallback).

`app` must be `"default"` (Vicinae's sentinel for the xdg default browser).
An empty string looks up an app id that does not exist and toasts
`No app with id`. Do not pin `chromium` here; the next machine may use
Firefox.

`shortcuts.json` is copy-once because Vicinae writes visit counts there.
Doctor reports that drift as INFO. `deploy.sh` still seeds any repo ids
the live file is missing, so an empty file Vicinae created before the
first deploy does not strand the fallbacks. To reset the engines, delete
the live file and re-run deploy.

**Settings GUI caveat:** Vicinae writes `~/.config/vicinae/settings.json`
and can replace the symlink with a regular file — same class of problem as
the ghostty text-size slider. Doctor flags it (FAIL: not a symlink); heal
with `DOTFILES_LINKS_ONLY=1 sh deploy.sh`. Prefer editing
`omarchy/vicinae/settings.json` in the repo.

## Deliberately NOT included

- `~/.config/hypr/autostart.lua`, `xdph.conf`, `hyprsunset.conf` — stock
  omarchy; let `omarchy` manage them.
- `monitors.lua` and `looknfeel.lua` used to be on this list (omarchy
  generates monitors per machine; looknfeel was stock). Both are repo-owned
  now: `monitors.lua` for the 1.6 scale (a rebuild silently reset it to
  `"auto"` — one machine, so versioned; fork it per machine if a second
  appears), `looknfeel.lua` as the safe home for the float-on-top rules.

## ghostty config caveat: the text-size slider

`omarchy display text size <px>` edits `~/.config/ghostty/config` with
`sed -i`, which **replaces the symlink with a regular file** — one slider
drag silently severs the repo link. Doctor flags it (FAIL: not a symlink);
heal with `sh deploy.sh`. Terminal font size changes are repo edits now:
change `font-size` in `omarchy/ghostty/config`, commit, and pull/deploy on
other machines.

## switcharoo plugin — local patch snapshot

The window switcher (`io.github.gabrielvincent.switcharoo`, installed via
`omarchy plugin add`) is **not vendored** — the plugin manager owns its clone
under `~/.config/omarchy/plugins/` and `omarchy plugin update` refreshes it.
That means local patches would be lost on update, so they are snapshotted in
`plugins/patches/` (see that README for re-apply instructions):

- `switcharoo-local.patch`, two `Switcher.qml` patches:
  - **super-release**: commit-on-release watches the Super keys, not just
    Alt. Required by the SUPER+TAB / SUPER+SHIFT+TAB bindings in
    `hypr/bindings.lua`; without it the grid opens but never commits.
  - **raise-front**: commits run `omarchy-window-raise-front` so a committed
    tiled window overlapped by a floater is floated in place and raised
    (Hyprland renders all floats above all tiles).

The retired altswitch fork previously lived vendored here
(`omarchy/plugins/io.github.pablo-merino.altswitch/`, with SUPER-chord support
in `altswitch.lua`); switcharoo superseded it and the vendored copy was
removed — recover it from git history if ever needed.
