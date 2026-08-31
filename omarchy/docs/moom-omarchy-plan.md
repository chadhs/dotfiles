# Moom → Omarchy Recreation Plan

Migration of macOS Moom window-management muscle memory to Omarchy (Hyprland).
Implemented as **Plan A** mode (1:1 literal recreation) — `MOOM_MODE=planA` in
`~/.config/omarchy/moom.conf` is the active default; **Plan B** (tiling-embracing
hybrid) remains available as an opt-in alternative.

## Decoded Moom config (source of truth)

All fractions are cells on Moom's 12×8 grid. Column ranges are 1-indexed.

| Moom action | Mac keys | Grid |
|---|---|---|
| Move & Resize: left half | `^⌥⌘←` | cols 1–6, full height |
| Move & Resize: right half | `^⌥⌘→` | cols 7–12, full height |
| Move & Resize: top half | `^⌥⌘↑` | rows 1–4, full width |
| Move & Resize: bottom half | `^⌥⌘↓` | rows 5–8, full width |
| Move & Resize: narrow left | `⌥⇧⌘←` | cols 1–5, full height (5/12) |
| Move & Resize: narrow right | `⌥⇧⌘→` | cols 8–12, full height (5/12) |
| Move & Resize: wide left | `^⌥⇧⌘←` | cols 1–7, full height (7/12) |
| Move & Resize: wide right | `^⌥⇧⌘→` | cols 6–12, full height (7/12) |
| Move & Resize: center block | `^⌥⌘M` | cols 3–10, full height (2/3) |
| Move & Resize: left 3/4 | `^⌥⌘B` | cols 1–9, full height |
| Move & Resize: fill screen | `^⌥⌘F` | entire grid |
| Move & Resize: task list | `^⌥⌘T` | cols 9–12, rows 5–8 (4×4 cells) |
| Move to corner TL/TR/BL/BR | `⌥⌘Q/W/Z/X` | keep size, clamp to display |
| Quarters TL/TR/BL/BR | `^⌥⌘Q/W/Z/X` | 6×4 cells |
| Move 50pt L/R/U/D, confine | `⌥⌘←→↑↓` | floating nudge |
| Move to Display R/L, loop | `^⌥→/←` | next/prev monitor, wraps |
| Revert | `^⌥⌘R` | undo last Moom action |

## Mode handling — one chord set, two behaviors

Mode is set by `MOOM_MODE` in `~/.config/omarchy/moom.conf` (`planA` default,
`planB` optional).

**Plan A mode (active)**: every Moom chord floats the window if needed and
places it at the literal grid cell — identical behavior regardless of tiling
layout, no swaps, no split resizes. `fill` = fill the screen area (Moom-style,
not Hyprland fullscreen). New windows still tile and auto-arrange; SUPER+ALT+T
re-tiles any placed window; all tiling keys remain available. Flipping
`MOOM_MODE=planB` restores the tiling-aware chords.

**Plan B mode** (kept for reference / opt-in):

| Chord | Tiled window (dwindle) | Floating window |
|---|---|---|
| `^⌥⌘←→` | swap toward left/right (guarded), then width → 6/12 | left/right half cell |
| `^⌥⌘↑↓` | swap toward top/bottom, then height → 4/8 (half) | top/bottom half cell |
| `⌥⇧⌘←→` | swap toward left/right, then width → 5/12 | narrow side panel |
| `^⌥⇧⌘←→` | swap toward left/right, then width → 7/12 | wide side panel |
| `^⌥⌘M` | width → 8/12 (2/3) | center block |
| `^⌥⌘B` | width → 9/12 (3/4) | left 3/4 block |
| `^⌥⌘F` | fullscreen toggle | fill screen |
| `⌥⌘Q/W/Z/X` | float, then corner | corner, keep size |
| `^⌥⌘Q/W/Z/X` | float, then quarter | quarter cell |
| `^⌥⌘T` | float, then 4×4 cell | task-list cell |
| `⌥⌘←→↑↓` | no-op (tiler owns position) | ±50pt nudge, confined |
| `^⌥←→` | send window to prev/next monitor (wraps) — works on any window | same |
| `^⌥⌘R` | restore last Moom-resized geometry (not the swap) | revert last placement |

Directional fraction chords are *swap-then-resize*: mac "put this window on the
left/right/top/bottom half" semantics. The swap is guarded — it only fires when
a tiled sibling on the **same workspace** actually sits toward that direction,
so chords never fling windows to another monitor/workspace (a real quirk on
scrolling layouts, where the strip swap crosses monitors at the ends). A solo
tiled window (no split) no-ops: nothing to swap, nothing to resize.

## Cmd+Tab app switcher (omarchy-switcharoo plugin)

`SUPER+TAB` / `SUPER+SHIFT+TAB` (and `ALT+TAB` / `ALT+SHIFT+TAB` / `ALT+```)
run the **omarchy-switcharoo** plugin (community, installed via
`omarchy plugin add`): a visual MRU grid lists every window on every
workspace; TAB / SHIFT+TAB (or holding the modifier and tapping again) move
the highlight, and **releasing SUPER or ALT commits** to the highlighted
window (ESC cancels; Enter/click also commits). Selection is virtual — focus
moves once, on commit, so the view does not flit across workspaces mid-cycle.

Local patches to the plugin clone (upstream commits on ALT release only),
snapshotted at `plugins/patches/switcharoo-local.patch` — re-apply after
`omarchy plugin update`:
- Commit-on-release also watches the Super keys
- Commits run `~/.local/bin/omarchy-window-raise-front` (the repo-owned
  helper carried over from the altswitch fork): it raises the committed
  window, and — because Hyprland always renders floats above tiles — if the
  window is tiled and a floating window actually overlaps it, it is floated
  in place (tiled geometry preserved) and then raised, so nothing can cover it

These chords no longer switch workspaces; workspaces remain on `SUPER+1..0`,
`SUPER+CTRL+TAB` (former workspace), bar scroll, and gestures. The earlier
`omarchy-appswitch` script (spatial-order cycler) was retired and removed from
the repo once the plugin took over.

### Free with tiling (stock Omarchy bindings)

- Send window to workspace 1–10: `SUPER+SHIFT+1..0`; silently: `SUPER+SHIFT+ALT+1..0`
- Swap windows: `SUPER+SHIFT+Arrows`; scratchpad, groups, tab/window cycling: stock

### Ceded Omarchy bindings (Moom muscle memory wins; still in omarchy menu)

- `^⌥⌘R/T/B/W/Z`: reminders / time / battery / weather / reset zoom notifications
- `⌥⇧⌘←→` (SUPER+SHIFT+ALT+Arrows): move-workspace-to-monitor (per-window monitor
  moves remain via `^⌥←→`; move whole workspace via omarchy menu binding)
- `SUPER+ALT+Arrows`: window focus (relocated to `CTRL+ALT+SHIFT+Arrows` —
  SUPER+Arrow is text nav, SUPER+ALT+Arrow is now the Moom nudge)

### Engine

`~/.local/bin/omarchy-moom <action>` — reads active window + monitor geometry
from `hyprctl -j` (logical units; monitor pixels ÷ scale; reserved bars
respected), snapshots geometry to `~/.local/state/omarchy/moom/last.json`
before every action, applies placement via Hyprland dispatchers
(`hl.dsp.window.resize` for split deltas; `movewindowpixel`/`resizewindowpixel`
exact for floats). Gap-aware: uses `general:gaps_out` as outer padding for
float placement and the workspace-usable area as the fraction denominator.

Actions: `half-left half-right half-top half-bottom narrow-left narrow-right
wide-left wide-right center threequarter fill corner-tl corner-tr corner-bl
corner-br quarter-tl quarter-tr quarter-bl quarter-br task nudge-left
nudge-right nudge-up nudge-down display-prev display-next revert`

### Known limitations

- Nudge bindings repeat while held only via Hyprland's `repeating` flag (slower
  than macOS key-repeat)
- Revert only tracks omarchy-moom actions, not manual drags (same as Moom)
- Tiled fraction resizes are clamped by dwindle when a neighbor hits min size
- Fraction chords resize width/height, not side — dwindle decides orientation

## Plan A — implemented (1:1 Moom recreation)

Implemented as `MOOM_MODE=planA` (the `moom.conf` default): every chord binds
to the fixed action name (e.g. `omarchy-moom corner-tl` regardless of window
state) and the engine floats managed windows as needed. No manual rebinding
required — flipping `MOOM_MODE` in `~/.config/omarchy/moom.conf` switches
behavior.

If Omarchy's tiling ever chafes further: set `omarchy_default_bindings = false`
in `~/.config/hypr/hyprland.lua`, bind the full Moom table, and float everything —
the full decode table above is the spec.
