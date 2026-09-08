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
| `hypr/monitors.lua` | `~/.config/hypr/monitors.lua` | 1.6 scale (omarchy default is `"auto"`) plus per-output `icc =` paths. Profiles: [docs/display-profiles.md](docs/display-profiles.md) |
| `shell.json` | `~/.config/omarchy/shell.json` | opaque bar + switchboard/switcharoo plugin entries |
| `moom.conf` | `~/.config/omarchy/moom.conf` | `MOOM_MODE=planA` |
| `ghostty/config` | `~/.config/ghostty/config` | linux terminal config (fork of omarchy's, with local font-size/padding tweaks; mac ghostty stays `utils/ghostty/config`) |
| `env/90-shell.conf` | `~/.config/environment.d/90-shell.conf` | session `SHELL` mirror (ghostty launches `$SHELL`; guards against systemd user-manager staleness after chsh) |
| `bin/` | `~/.local/bin/` | `omarchy-moom`, `omarchy-quit-app`, `omarchy-agent-tools-update`, `omarchy-agent-usage-opencode-go`, `omarchy-opencode-go-record`, `omarchy-agent-usage-cursor`, `omarchy-cursor-record`, `omarchy-window-raise-front`, `focus-new-windows`, `trackpad-check`, `omarchy-scheduled-theme` |
| `systemd/user/` | `~/.config/systemd/user/` | dotfiles-shipped user units (`focus-new-windows.service`, `omarchy-opencode-go-record.{service,path,timer}`, `omarchy-cursor-record.{service,path,timer}`, `omarchy-scheduled-theme.{service,timer}`), enabled by `deploy.sh` on arch |
| `vicinae/` | `~/.config/vicinae/settings.json`, copy-once `~/.local/share/vicinae/shortcuts/shortcuts.json` | launcher config + `{query}` web-search shortcuts (see below) |
| `aur.packages` | — | AUR list `deploy.sh` installs (vicinae-bin + agent desktop apps); `omarchy-agent-tools-update` reads the same file. T3 Code OpenRouter setup: [utils/t3-code/README.md](../utils/t3-code/README.md) |
| `applications/nixfred.blip.desktop` | `~/.local/share/applications/nixfred.blip.desktop` | Blip Messages launcher for Omarchy and Vicinae; requires the Blip plugin |
| `plugins/patches/` | — | local patches for plugin-manager-managed plugins (see below) |
| `docs/moom-omarchy-plan.md` | — | design doc for `omarchy-moom` + the Moom chords in `bindings.lua` |
| `docs/display-profiles.md` | — | DisplayCAL / SpyderX ICC workflow and how Hyprland loads them |

## Scheduled Solarized themes

`omarchy-scheduled-theme.timer` selects Solarized Light at 10am and Solarized
Dark at 7pm using the system timezone, including daylight saving changes.
Each scheduled run selects that theme's Ripples background. An already-active
theme is not reloaded; if only the background differs, only the background is
changed. Manual theme and background choices stay until the next scheduled run.

The timer starts with the graphical session and checks the appearance after
five seconds. Persistent calendar triggers catch up after a missed switch at
login or resume, choosing the theme for the current time. They do not wake the
computer. There is no periodic enforcement between these runs.

Install `solarized-light` and `solarized-dark` separately through Omarchy. Each
must include `backgrounds/1-ripples.png`. The script checks the selected theme
and image before making changes and logs an error if either is missing. Theme
assets, current-theme state, and systemd timer timestamps remain outside this
repo. The desktop session supplies Omarchy's PATH and graphical environment.

`deploy.sh` links the script and units, reloads systemd, and enables the timer
on Arch. The oneshot service is static and is activated only by the timer or
an explicit manual start. Deploying the dotfiles enables the timer again if
it was previously disabled.

```sh
# Inspect the next scheduled switch and recent results.
systemctl --user list-timers --all omarchy-scheduled-theme.timer
journalctl --user -u omarchy-scheduled-theme.service -n 30 --no-pager

# Apply the current time's theme and Ripples now, during a desktop session.
systemctl --user start omarchy-scheduled-theme.service

# Stop scheduled changes and prevent activation at the next login.
systemctl --user disable --now omarchy-scheduled-theme.timer

# Re-enable the schedule during a desktop session.
systemctl --user enable --now omarchy-scheduled-theme.timer
```

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

## OpenCode Go tab in the agents panel

The stock `omarchy.agents` bar panel only ships collectors for Claude, Codex
and Fireworks, and its claude/codex collectors fold in opencode sessions only
when they ran on an `anthropic`/`openai` provider — so usage on the
`opencode-go` provider (GLM etc.) never showed up. `omarchy/systemd/user/`
plus `omarchy/bin/` add a fourth tab for it:

- `omarchy-agent-usage-opencode-go` (collector): local token stats from
  opencode's SQLite db (assistant messages with `providerID = "opencode-go"`)
  plus rolling 5h/weekly/monthly limit meters from the official
  `https://opencode.ai/zen/go/v1/usage` endpoint, Bearer-authed with the key
  opencode already stores in `~/.local/share/opencode/auth.json`. Falls back
  to a cached copy on 429/network blips.
- `omarchy-opencode-go-record` (wrapper): runs the collector and atomically
  writes `~/.local/state/omarchy/agents/usage/opencode-go.json` — the record
  file the panel watches. Needed because the packaged
  `omarchy-agent-usage-update` only runs collectors in `/usr/share/omarchy/bin/`.
- `omarchy-opencode-go-record.path`: watches `claude.json` + `codex.json` in
  the usage dir. The packaged updater rewrites every record on each panel
  refresh (open the panel, press `r`, or its own 15-min timer), so the Go tab
  regenerates at exactly the same moments as the packaged agents — lockstep
  freshness with zero extra endpoint traffic. Writes go to `opencode-go.json`,
  so there is no trigger loop.
- `omarchy-opencode-go-record.timer`: 15-min fallback in case the watched
  records stop changing.
- `omarchy-opencode-go-record.service`: the oneshot both triggers run.

The collector is vendored from upstream omarchy PR #7157 (still open at time
of writing). Once a released `omarchy update` ships its own
`omarchy-agent-usage-opencode-go`: delete the two `omarchy/bin/` scripts and
the three units here, drop the `links.conf` entries, and
`systemctl --user disable --now` the path + timer units. The packaged
updater will then regenerate the record itself on every panel refresh.

## Cursor tab in the agents panel

Same shape as the OpenCode Go tab, different data plumbing. Cursor publishes
no per-user usage API (Admin/Analytics are Enterprise-only), but its web
dashboard reads live numbers, so the collector authenticates as the
dashboard does: the WorkOS session token `cursor-agent login` already stored
in `~/.config/cursor/auth.json`, sent as
`WorkosCursorSessionToken=<sub>::<jwt>` (sub comes from decoding the token
itself). `$CURSOR_SESSION_TOKEN` overrides, and the editor's
`~/.config/Cursor/User/globalStorage/state.vscdb` (`cursorAuth/accessToken`)
is the fallback. Only cursor.com sees the token.

- `omarchy-agent-usage-cursor` (collector): limits from `GET
  /api/usage-summary` (Cursor-models pool, other-models pool, total, cycle
  end) and token stats from the dashboard event log (`POST
  /api/dashboard/get-filtered-usage-events`, paginate, cap 5 pages). Note
  event `inputTokens` includes cache traffic; the collector subtracts cache
  before recording so the panel's per-model sum stays honest.
- `omarchy-cursor-record` (wrapper): runs the collector, writes
  `~/.local/state/omarchy/agents/usage/cursor.json` atomically.
- `omarchy-cursor-record.path` / `.timer` / `.service`: identical lockstep
  pattern to the opencode-go units, plus a 15-min fallback timer.

These are undocumented dashboard endpoints (reverse-engineered by the
community, see gist `dmwyatt/1e9359b1862e7cbfe1e754fe4c8db764`); POSTs need
an `Origin: https://cursor.com` header or they 403. If Cursor changes its
dashboard protocol the tab goes stale with a "Cursor limits stale" note and
the cached meters; re-run `omarchy-cursor-record` by hand to re-check.

## Showing and hiding agents in the panel

The `omarchy.agents` panel takes per-agent `providers` settings under its bar
entry. `enabled` defaults to true for every agent that has a record, and a
disabled agent drops its tab and stops its collector from running on refresh:

```sh
omarchy bar set omarchy.agents providers '{"claude": {"enabled": false}}' --json
```

Bring an agent back the same way with `"enabled": true`. The setting lives in
`omarchy/shell.json`, and the live file symlinks here, so `omarchy bar set`
edits the repo copy directly; no deploy step needed. The shell hot-reloads
the change.

Two things to know. `set` writes the key literally rather than walking a
dotted path, so pass the whole `providers` object with every agent you are
overriding, not just the one changing. And numbers need `--json` or they
land in `shell.json` as strings.

Claude is disabled in the committed `shell.json` right now since it is not in
use. That does not break the opencode-go lockstep trigger: the `.path` unit
also watches `codex.json`, and the 15-min timer covers everything else.

## Color profiles

Each monitor gets an ICC from DisplayCAL (SpyderX). Hyprland loads it with
`icc =` on the `hl.monitor` blocks in `hypr/monitors.lua`. The `.icc` files
live under `~/.local/share/DisplayCAL/storage/`, not in this repo.

How to measure a new pair, what to do when DisplayCAL hangs after the
patches, and how to `profcheck` the result: [docs/display-profiles.md](docs/display-profiles.md).

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
- `~/.config/hypr/displaycal.lua` — local window rules so DisplayCAL prompts
  stay off the measurement patch. Required from `hyprland.lua`. See
  [docs/display-profiles.md](docs/display-profiles.md).
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

## Blip messaging

The bar layout includes `nixfred.blip` after the tray. **Blip Messages** in
Omarchy’s app launcher or Vicinae opens or focuses its full window through:

```sh
qs -p /usr/share/omarchy/shell ipc call nixfred.blip app
```

The launcher is repo-owned; the plugin itself stays under the Omarchy plugin
manager. Install [Blip](https://github.com/nixfred/blip) separately and run its
bundled setup wizard against your Mac. The initial setup used revision
`438f5c06769b2982d7b90b54cb8a00adba6135ba`, version 2.3.3. Keep SIP, Gatekeeper,
and FileVault enabled. Blip requires Full Disk Access and Messages Automation
for SSH on the Mac; the dedicated restricted key does not narrow those grants
for other unrestricted SSH logins.

The Mac address, bridge settings, keys, and caches stay machine-local. The
wizard saves the address in `~/.config/blip/bridge.conf`; a `blip_mac` shell
variable is only shorthand for setup and maintenance. Keep Mac-specific SSH
Host blocks in `~/.ssh/config.d/`, which both OS configs already include.
If the wizard appends a block to the linked `~/.ssh/config`, move just that
new block into a local include before committing dotfiles.

Use a command-scoped setup agent so it does not change the terminal’s Git
identity environment:

```sh
ssh-agent bash -c '
  ssh-add "$HOME/.ssh/id_ed25519" &&
  exec "$HOME/.config/omarchy/plugins/nixfred.blip/scripts/blip-setup" "$1"
' blip-setup you@your-mac
```

For manual release updates, select a published tag, rerun that wizard to
update the Mac bridge too, and run `omarchy restart shell`. Omarchy 4.0.2’s
`omarchy plugin update nixfred.blip` follows default-branch HEAD and can
advance even a detached checkout; it is not a release-only updater.

To pause the client, use `omarchy plugin disable nixfred.blip` and restart
the shell. Full removal also needs key revocation and permission cleanup on
the Mac; removing the widget alone does not remove access. Preserve retained
sent attachments in `~/.blip/sent` and `~/Pictures/.blip-outbox` until any
needed originals are saved. If permanently removing Blip from dotfiles,
remove its bar entry, launcher, and `links.conf` mapping together so a later
deploy does not recreate the shortcut.

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
