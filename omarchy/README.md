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
| `bin/` | `~/.local/bin/` | `omarchy-moom`, `omarchy-quit-app`, `omarchy-agent-tools-update`, `omarchy-window-raise-front`, `focus-new-windows`, `trackpad-check`, `omarchy-scheduled-theme`, `omarchy-theme-toggle` |
| `systemd/user/` | `~/.config/systemd/user/` | dotfiles-shipped user units (`focus-new-windows.service`, `omarchy-scheduled-theme.{service,timer}`), enabled by `deploy.sh` on arch except the optional theme timer |
| `vicinae/` | `~/.config/vicinae/settings.json`, copy-once `~/.local/share/vicinae/shortcuts/shortcuts.json` | launcher config + `{query}` web-search shortcuts (see below) |
| `aur.packages` | — | AUR list `deploy.sh` installs (vicinae-bin + agent desktop apps); `omarchy-agent-tools-update` reads the same file. T3 Code OpenRouter setup: [utils/t3-code/README.md](../utils/t3-code/README.md) |
| `applications/nixfred.blip.desktop` | `~/.local/share/applications/nixfred.blip.desktop` | Blip Messages launcher for Omarchy and Vicinae; requires the Blip plugin |
| `plugins/patches/` | — | local patches for plugin-manager-managed plugins (see below) |
| `docs/moom-omarchy-plan.md` | — | design doc for `omarchy-moom` + the Moom chords in `bindings.lua` |
| `docs/display-profiles.md` | — | DisplayCAL / SpyderX ICC workflow and how Hyprland loads them |

## Omarchy 4.5 baseline

See [docs/omarchy-4.5-review.md](docs/omarchy-4.5-review.md) for the verified
stock replacements, retained behaviors, and rollback/acceptance checks.

The clock intentionally uses `ddd d MMM h:mm AP`: weekday, date, month,
and 12-hour time. Keep this live preference, not the older repo formatting
or the packaged weekday/24-hour default. The bar uses `background: "opaque"`.

`hypr/workspaces.lua` keeps the first five workspaces on each display
persistent using Omarchy's assigned blocks: DP-2 uses 1–5; DP-3 uses 11–15,
shown as 1–5 on that bar. If ports or monitor-block assignments change,
review this file against `~/.local/state/omarchy/monitor-workspaces`.
Deployment restores its loader via `scripts/ensure-omarchy-workspaces.py`.

## Scheduled Solarized themes

Solarized Dark is the default. Automatic switching is disabled; use the manual
Vicinae toggle below when you want Light. Omarchy saves the selected theme
across logins.

When explicitly enabled, `omarchy-scheduled-theme.timer` selects Solarized
Light at 10am and Solarized Dark at 7pm using the system timezone, including
daylight saving changes. Each scheduled run selects that theme's Ripples
background. An already-active theme is not reloaded; if only the background
differs, only the background is changed. Manual theme and background choices
stay until the next scheduled run.

The timer starts with the graphical session, or when enabled with `--now`, and
checks the appearance after five seconds. Persistent calendar triggers catch
up after a missed switch at login or resume, choosing the theme for the current
time. They do not wake the computer. There is no periodic enforcement between
these runs.

Install `solarized-light` and `solarized-dark` separately through Omarchy. Each
must include `backgrounds/1-ripples.png`. The script checks the selected theme
and image before making changes and logs an error if either is missing. Theme
assets, current-theme state, and systemd timer timestamps remain outside this
repo. The desktop session supplies Omarchy's PATH and graphical environment.

The scheduled-theme script and both units remain installed so the schedule can
be enabled again. `deploy.sh` links them and reloads systemd on Arch, but leaves
the timer's enabled state alone. Redeploying the dotfiles does not re-enable
a disabled schedule. The oneshot service is static and is activated only by
the timer or an explicit manual start.

```sh
# Inspect the next scheduled switch and recent results.
systemctl --user list-timers --all omarchy-scheduled-theme.timer
journalctl --user -u omarchy-scheduled-theme.service -n 30 --no-pager

# Apply the current time's theme and Ripples now, during a desktop session.
systemctl --user start omarchy-scheduled-theme.service

# Stop scheduled changes and prevent activation at the next login.
systemctl --user disable --now omarchy-scheduled-theme.timer

# Re-enable the schedule; apply the current time's theme after five seconds.
systemctl --user enable --now \
  "$HOME/dotfiles/omarchy/systemd/user/omarchy-scheduled-theme.timer"
```

The full unit path lets systemd recreate its link if disabling the timer
removed it.

## Manual light/dark toggle

Run `omarchy-theme-toggle` from a terminal or SUPER+SPACE → "Toggle Light/Dark Theme"
in Vicinae. Light switches to Dark and vice versa. Other themes switch to
Solarized Dark first. Like the scheduled script it applies the theme's Ripples
background, checks assets before touching anything, and the
result persists across logins until you change it again. If you explicitly
enable the optional schedule, the next scheduled run overrides manual choices.

One repo file (`omarchy/bin/omarchy-theme-toggle`) is linked twice by
`links.conf`: to `~/.local/bin/` for terminal use and into
`~/.local/share/vicinae/scripts/` so Vicinae indexes it as a script command.
The `@vicinae.*` directives are comments, so the same file serves both entry
points; `vicinae script check` validates them. After changing the directives,
reload with the "Reload Script Directories" command in Vicinae. Vicinae's
silent mode needs layer-shell, which the launcher already uses.

```sh
# Validate the Vicinae directives after editing.
vicinae script check omarchy/bin/omarchy-theme-toggle
```

## Thunderbird

`deploy.sh` installs Thunderbird from the Arch repository. The Thunderbird
block in `hypr/bindings.lua` adds Super+E for archive and Ctrl+Super+M for the
folder picker, scoped to Thunderbird. These require tbkeys-lite and Quick
Folder Move with the settings documented in
[utils/thunderbird](../utils/thunderbird/README.md).
Thunderbird is in the multi-tab Super+W set, which forwards Ctrl+W and follows
Thunderbird's native tab and last-tab behavior.

That directory owns the adaptive Solarized theme manifest, its packaging
script, the UI refinement stylesheet and installer, and the portable preference
reference. Follow its one-time setup
steps for the theme, extensions, iCloud folder discovery, and validation.
Mail profiles and credentials remain machine-local; deployment does not
rewrite them.

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
from `default/hypr/` regardless) and the entrypoint remains machine-local. It currently loads our workspace
and DisplayCAL modules and contains game-specific fullscreen rules. Do not
reset it to stock without preserving those additions. Deployment restores the
workspace loader without replacing the entrypoint. The unit is enabled by `deploy.sh`
(`systemctl --user enable --now`); an `autostart.lua` hook was rejected
deliberately — that file stays stock omarchy.

## AI usage: stock Omarchy 4.5 collectors

Omarchy now owns Cursor, OpenCode (including Go), and Codex collection. The
old custom collectors, record writers, Codex limits patch, and eight systemd
units were retired after verifying the packaged replacements on 2026-11-07.
No dotfiles service writes to the agents panel's records anymore.

The stock OpenCode record is `opencode.json`, replacing `opencode-go.json`.
It reads both OpenCode database formats and counts typed prompts instead of
assistant steps, so the prompt total differs from the old collector. Token
coverage and all three Go limit windows were verified. Codex returned fresh
weekly limits and reset times without the patch. Cursor remains disabled;
its stock record correctly reports paused limits rather than contacting the
provider. Claude remains disabled too.

Use `omarchy agent usage-update codex opencode` for an explicit refresh.
The panel manages ordinary refreshes. Do not reinstall the retired timers or
path watchers. `scripts/omarchy-retire-usage.sh` removes only known dotfiles
links and units on older installations; deploy invokes it after confirming
that the packaged collectors exist. Old Go records move outside the panel's
watch directory into the local backup directory.

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

`omarchy bar set` treats a dotted key literally, so pass the complete
`providers` object when changing visibility. Preserve both disabled entries
for Claude and Cursor. GUI writers can replace the shell config symlink;
reconcile the live file into the repo before restoring the link.

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
Omarchy menu (including Appearance and Trigger), replacing 4.5's Apps-grid shortcut. SUPER+ESCAPE, the bar menu button,
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
the ghostty text-size slider. Doctor flags it (FAIL: not a symlink). First preserve the live settings in
the repo, then restore the link; blind redeployment would lose live edits. Prefer editing
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
drag silently severs the repo link. Doctor flags it (FAIL: not a symlink). Preserve any desired live changes
in the repo before restoring the link. Terminal font size changes are repo edits now:
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

- `switcharoo-local.patch`, local patches (see the patch README for the full current list):
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
