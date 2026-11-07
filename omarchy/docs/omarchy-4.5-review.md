# Omarchy 4.5 review and retained behavior

Verified on 2026-11-07 with Omarchy 4.5.0-3, Hyprland 0.56.2-4, and
Quickshell 0.3.2.r7.g2b4501a-1. Prefer packaged implementations while preserving
Mac muscle memory. Custom behavior is required; custom code is replaceable.

## Stock implementations adopted

- Select-all uses stock Super+A. Custom quit-app, window swaps, and Moom fill
  explicitly replace new conflicting stock bindings. The live binding audit
  has no duplicate named chords. Modifier order in `o.rebind` must match the
  stock spelling on this installed Hyprland version.
- Packaged Codex and OpenCode collectors returned fresh limits and reset times.
  OpenCode includes Go's rolling, weekly, and monthly meters and reads both
  message stores. Its lower prompt count reflects user turns rather than the
  old collector's assistant-step count; token coverage increased. Cursor is
  intentionally disabled and correctly reports paused limits. Its active
  authenticated collection was not tested because it is not in use.
- Removed six custom usage scripts and eight user units, their live links,
  and deployment entries. The old Go record is archived outside the panel's
  watch directory. The panel's packaged updater is now the only record writer.
- Bar background uses the current `background: "opaque"` setting. Dock settings
  are intentionally omitted so they inherit packaged defaults.

## Intentional preferences retained

- Clock: `ddd d MMM h:mm AP`, with the existing alternate and vertical formats.
  This is the current date-inclusive display, not the packaged 24-hour format.
- Five persistent workspaces on each monitor, using 4.5's monitor blocks.
  Three-finger horizontal swipes and window-to-workspace shortcuts stay intact.
- Moom Plan A literal placement, nudges, revert, and monitor transfers; Mac
  editing, close-tab/quit-app, and switcher shortcuts; Switchboard swipe-up.
- Vicinae app/file/web search, favorites, and aliases; current world-clock
  choices; disabled Claude and Cursor panel entries; Blip and Dropbox widgets.
- 1.6 display scale and ICC profiles, natural scrolling and physical clicks,
  Solarized appearance/manual toggle, Ghostty sizing, Thunderbird behavior,
  OBS setup, and game-specific fullscreen/runner fixes.

The live shell and Vicinae files had replaced repo symlinks. Their current
content was reconciled before restoring the links. If a GUI breaks a link
again, compare and preserve live changes before redeploying.

## Floating-workspace trial and remaining helpers

Used disposable Foot windows on an empty workspace with the focus helper
temporarily stopped. Native floating mode gave new windows focus and floated
them on launch. Moom halves, fractions, quarters, corners, task placement,
50-pixel nudge/revert, and transfer to the other display and back worked.
Native-created windows returned to tiling when the workspace did.

The mixed-layout regression remains: on a tiled workspace with a large
Moom-positioned floater, a new window stayed tiled beneath the floating layer.
Focus alone does not fix stacking. Keep `omarchy-window-raise-front`, the
focus-new-windows service, ChatGPT float rules, and the Switcharoo patches.
Do not retire them based only on success on an entirely floating workspace.

The trial restored both monitors' previous workspaces, focused window, saved
layout, Moom undo state, and the focus helper. No trial windows remain.
User confirmed on 2026-11-07 that all tested binding behavior works after
the cleanup, in response to the Moom fill, relocated window-swap, Cmd/Super+Tab,
and disposable-app quit checklist. Automated tests separately exercised
dispatchers and geometry.

## Deployment and maintenance

`scripts/ensure-omarchy-workspaces.py` adds the workspace require after the
monitor require only when absent, making a backup first. It leaves DisplayCAL
and game rules alone and refuses unknown entrypoint shapes. Deploy invokes it
on Arch. The entrypoint is machine-local, not an untouched stock template.

`scripts/omarchy-retire-usage.sh` removes only known dotfiles-owned usage
links/units, after checking packaged collectors exist. It does not remove
unrelated files. Deploy invokes it to avoid leaving old services on machines
upgrading these dotfiles.

Run `sh scripts/omarchy-post-update.sh` for a read-only audit. Explicit plugin
repair is `sh scripts/omarchy-repair-switcharoo.sh`; it refuses dirty plugin
trees, checks the patch, then applies it and restarts the shell. The audit
never applies patches, restarts services, or sends notifications.

After future releases, review overrides against installed source, test a
stock replacement, and remove the obsolete code only after its original
failure cases pass. Keep per-provider visibility and current live preferences.

## Validation and rollback

Validate with `hyprctl reload`, `hyprctl configerrors`, the read-only audit,
and `sh scripts/doctor.sh`. Check both monitors' persistent workspaces and
test Mac editing, Moom fill/nudge/revert, swaps, Cmd+Tab release-to-commit,
and quit-app using disposable windows. Use `omarchy agent usage-update codex
opencode` to verify packaged refreshes without custom writers.

Pre-change backup on this machine:
`~/.local/state/omarchy/backups/stock-4.5-20261107-090821/`.
It includes the pre-existing uncommitted repo state, live configs, usage
records, and systemd unit states. Collector comparisons and floating-trial
results also live there. Restore only the affected subsystem; do not overwrite
subsequent unrelated work or roll back the entire repo. Restore retired unit
files and links before re-enabling units if a collector rollback is required.

Two pre-existing doctor failures are outside this cleanup: the undeployed
`evolve-companion-obs.desktop` entry and the expected but absent
`t3code-nightly-bin` package. Do not install or overwrite either merely to
make the audit green.
