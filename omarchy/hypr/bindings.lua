-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Mac-style text editing shortcuts.
-- Same injection approach as Omarchy's built-in universal copy/paste
-- (default/hypr/bindings/clipboard.lua): send the real chord to the focused
-- surface via send_key_state. See https://github.com/hyprwm/Hyprland/discussions/14099
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

-- Lean on the terminal tag from default/hypr/apps/terminals.lua so there's one
-- definition of what counts as a terminal. Dynamic tags carry a trailing "*".
local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

local function unless_terminal(send)
  return function()
    if not active_window_is_terminal() then
      send()
    end
  end
end

-- Select all (mac Cmd+A).
o.bind("SUPER + A", "Universal select all", send_shortcut_once("CTRL", "A"))

-- Undo/redo (mac Cmd+Z / Cmd+Shift+Z). No-op in terminals so the injected
-- CTRL+Z can't suspend a running shell job.
o.bind("SUPER + Z", "Universal undo", unless_terminal(send_shortcut_once("CTRL", "Z")))
o.bind("SUPER + SHIFT + Z", "Universal redo", unless_terminal(send_shortcut_once("CTRL + SHIFT", "Z")))

-- Word movement (mac Option+Arrow -> CTRL+Arrow).
o.bind("ALT + LEFT", "Move cursor one word left", send_shortcut_once("CTRL", "LEFT"))
o.bind("ALT + RIGHT", "Move cursor one word right", send_shortcut_once("CTRL", "RIGHT"))

-- Word deletion (mac Option+Backspace -> CTRL+Backspace). In terminals,
-- replay the raw chord instead: readline's Meta-Backspace is
-- backward-kill-word, while CTRL+BACKSPACE only deletes one char there.
o.bind("ALT + BACKSPACE", "Delete previous word", function()
  if active_window_is_terminal() then
    send_shortcut_once("ALT", "BACKSPACE")()
  else
    send_shortcut_once("CTRL", "BACKSPACE")()
  end
end)

-- Delete next word (mac fn+Option+Delete -> CTRL+Delete). In terminals,
-- replay the raw chord (forward-kill-word is a readline M- binding).
o.bind("ALT + DELETE", "Delete next word", function()
  if active_window_is_terminal() then
    send_shortcut_once("ALT", "DELETE")()
  else
    send_shortcut_once("CTRL", "DELETE")()
  end
end)

-- Line/document navigation (mac Cmd+Arrow). Unbind Omarchy's window focus on
-- SUPER+Arrow first; focus moves to SUPER+ALT+Arrow below.
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")

o.bind("SUPER + LEFT", "Cursor to line start", send_shortcut_once("", "HOME"))
o.bind("SUPER + RIGHT", "Cursor to line end", send_shortcut_once("", "END"))
o.bind("SUPER + UP", "Cursor to document start", send_shortcut_once("CTRL", "HOME"))
o.bind("SUPER + DOWN", "Cursor to document end", send_shortcut_once("CTRL", "END"))

-- Window focus (relocated twice over: was SUPER+Arrow, then SUPER+ALT+Arrow —
-- SUPER+Arrow is now text nav and SUPER+ALT+Arrow is the Moom nudge below).
o.bind("CTRL + ALT + SHIFT + LEFT", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("CTRL + ALT + SHIFT + RIGHT", "Focus on right window", hl.dsp.focus({ direction = "r" }))
o.bind("CTRL + ALT + SHIFT + UP", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("CTRL + ALT + SHIFT + DOWN", "Focus on below window", hl.dsp.focus({ direction = "d" }))

-- Moom-style window management (see omarchy/docs/moom-omarchy-plan.md in the
-- dotfiles repo).
-- Fraction chords resize tiled splits; grid cells place floating windows.
local function moom(action)
  return "omarchy-moom " .. action
end

-- Cede these Omarchy chords to Moom muscle memory (features remain reachable
-- via the omarchy menu): reminders, show time, battery, weather, reset zoom,
-- and move-workspace-to-monitor (per-window monitor moves: CTRL+ALT+Arrows).
hl.unbind("SUPER + CTRL + ALT + R")
hl.unbind("SUPER + CTRL + ALT + T")
hl.unbind("SUPER + CTRL + ALT + B")
hl.unbind("SUPER + CTRL + ALT + W")
hl.unbind("SUPER + CTRL + ALT + Z")
hl.unbind("SUPER + SHIFT + ALT + LEFT")
hl.unbind("SUPER + SHIFT + ALT + RIGHT")

-- Fractions: tiled = exact split resize, float = cell placement.
o.bind("SUPER + CTRL + ALT + LEFT", "Moom: half width", moom("half-left"))
o.bind("SUPER + CTRL + ALT + RIGHT", "Moom: half width", moom("half-right"))
o.bind("SUPER + CTRL + ALT + UP", "Moom: top half", moom("half-top"))
o.bind("SUPER + CTRL + ALT + DOWN", "Moom: bottom half", moom("half-bottom"))
o.bind("SUPER + SHIFT + ALT + LEFT", "Moom: narrow left panel", moom("narrow-left"))
o.bind("SUPER + SHIFT + ALT + RIGHT", "Moom: narrow right panel", moom("narrow-right"))
o.bind("SUPER + SHIFT + CTRL + ALT + LEFT", "Moom: wide left panel", moom("wide-left"))
o.bind("SUPER + SHIFT + CTRL + ALT + RIGHT", "Moom: wide right panel", moom("wide-right"))
o.bind("SUPER + CTRL + ALT + M", "Moom: center two-thirds", moom("center"))
o.bind("SUPER + CTRL + ALT + B", "Moom: left three-quarters", moom("threequarter"))
o.bind("SUPER + CTRL + ALT + F", "Moom: fill", moom("fill"))

-- Placement keys (float-first on tiled windows).
o.bind("SUPER + ALT + Q", "Moom: corner top left", moom("corner-tl"))
o.bind("SUPER + ALT + W", "Moom: corner top right", moom("corner-tr"))
o.bind("SUPER + ALT + Z", "Moom: corner bottom left", moom("corner-bl"))
o.bind("SUPER + ALT + X", "Moom: corner bottom right", moom("corner-br"))
o.bind("SUPER + CTRL + ALT + Q", "Moom: quarter top left", moom("quarter-tl"))
o.bind("SUPER + CTRL + ALT + W", "Moom: quarter top right", moom("quarter-tr"))
o.bind("SUPER + CTRL + ALT + Z", "Moom: quarter bottom left", moom("quarter-bl"))
o.bind("SUPER + CTRL + ALT + X", "Moom: quarter bottom right", moom("quarter-br"))
o.bind("SUPER + CTRL + ALT + T", "Moom: task list cell", moom("task"))

-- Nudges (floating only, confined to display).
o.bind("SUPER + ALT + LEFT", "Moom: nudge left", moom("nudge-left"), { repeating = true })
o.bind("SUPER + ALT + RIGHT", "Moom: nudge right", moom("nudge-right"), { repeating = true })
o.bind("SUPER + ALT + UP", "Moom: nudge up", moom("nudge-up"), { repeating = true })
o.bind("SUPER + ALT + DOWN", "Moom: nudge down", moom("nudge-down"), { repeating = true })

-- Send focused window to prev/next monitor (wraps around).
o.bind("CTRL + ALT + LEFT", "Moom: previous display", moom("display-prev"))
o.bind("CTRL + ALT + RIGHT", "Moom: next display", moom("display-next"))

-- Revert last Moom action for the focused window.
o.bind("SUPER + CTRL + ALT + R", "Moom: revert", moom("revert"))

-- New tab (mac Cmd+T): terminals get CTRL+SHIFT+T (ghostty's new_tab),
-- GUI apps get CTRL+T (chromium etc.). Relocates Omarchy's toggle
-- floating/tiling, now on SUPER+ALT+T below.
hl.unbind("SUPER + T")
o.bind("SUPER + T", "New tab", function()
  if active_window_is_terminal() then
    send_shortcut_once("CTRL + SHIFT", "T")()
  else
    send_shortcut_once("CTRL", "T")()
  end
end)

-- Address/search bar (mac Cmd+L): inject CTRL+L, which Chromium and most
-- GUI apps handle. No-op in terminals so the injected CTRL+L can't clear
-- a running shell. Relocates Omarchy's workspace-layout toggle to
-- SUPER+ALT+L.
hl.unbind("SUPER + L")
o.bind("SUPER + L", "Address / search bar", unless_terminal(send_shortcut_once("CTRL", "L")))
o.bind("SUPER + ALT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

-- Tab navigation (mac Cmd+{ / Cmd+}): previous/next tab in chromium,
-- ghostty, and most GUI apps. Injects the universal ctrl+shift+tab /
-- ctrl+tab chords, which keep working directly too. Binds must use the
-- unshifted keysym (bracketleft, not braceleft): Hyprland resolves the
-- pressed key against a mod-free xkb state, so braceleft never matches.
hl.unbind("SUPER + SHIFT + BRACELEFT")
hl.unbind("SUPER + SHIFT + BRACERIGHT")
o.bind("SUPER + SHIFT + BRACKETLEFT", "Previous tab", send_shortcut_once("CTRL + SHIFT", "TAB"))
o.bind("SUPER + SHIFT + BRACKETRIGHT", "Next tab", send_shortcut_once("CTRL", "TAB"))

-- Toggle window floating/tiling (relocated from SUPER+T).
o.bind("SUPER + ALT + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))

-- Multi-tab apps where SUPER+W should close a tab, not the whole window with
-- all its tabs (mac Cmd+W semantics). Everything else gets a plain window
-- close, which works universally — including single-window apps like omacalc,
-- omawrite, claude, and localsend. JetBrains IDEs are deliberately excluded:
-- on Linux their CTRL+W is "extend selection".
local function active_window_is_multi_tab_app()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  local class = (window.class or ""):lower()
  for _, pattern in ipairs({
    "chrom", "brave", "edge", "vivaldi", "opera", "arc",
    "code", "zed", "nautilus", "dolphin", "thunar", "nemo", "pcmanfm",
  }) do
    if class:find(pattern, 1, true) then
      return true
    end
  end

  return false
end

-- Mac-style Cmd+W: close tab in multi-tab apps, close the window everywhere
-- else. In terminals always close the window so injected CTRL+W can't delete
-- a word.
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close tab / window", function()
  if active_window_is_terminal() or active_window_is_multi_tab_app() then
    send_shortcut_once("CTRL", "W")()
  else
    hl.dispatch(hl.dsp.window.close())
  end
end)

-- Mac-style Cmd+Q: quit the whole app by closing every window of its class.
-- Universal — no injected chords, so apps that ignore CTRL+Q (omawrite,
-- claude, omacalc) still quit. On a terminal this closes all terminal windows.
o.bind("SUPER + Q", "Quit app", "omarchy-quit-app")

-- Mac-style screenshot shortcut. `save` skips the annotation editor so the
-- capture lands straight in Pictures, like macOS. (An earlier SUPER+SHIFT+
-- 3/4/5/W set conflicted with other hotkeys, so only region select survives.)
-- Screenshot shortcuts (mac-ish chords). All three open the capture menu for
-- now; mode-specific binds kept tripping over capture quirks (silent exits
-- with stale slurp pickers, clipboard not landing). Revisit later.
o.bind("CTRL + SUPER + SHIFT + 3", "Screenshot: capture menu", "omarchy-menu toggle trigger.capture")
o.bind("CTRL + SUPER + SHIFT + 4", "Screenshot: capture menu", "omarchy-menu toggle trigger.capture")
o.bind("CTRL + SUPER + SHIFT + 5", "Screenshot: capture menu", "omarchy-menu toggle trigger.capture")

-- Clipboard history (same command as the default SUPER+CTRL+V bind).
o.bind("SUPER + ALT + C", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")

-- Switchboard: full-screen live window overview (also on 3-finger swipe up,
-- see input.lua). Bound by keycode (SUPER+SHIFT+backslash) per the plugin's
-- recommendation; unbound in stock Omarchy.
o.bind("SUPER + SHIFT + code:51", "Switchboard: window overview", "omarchy-shell -q switchboard toggle")

-- Switcharoo: MRU grid window switcher (io.github.gabrielvincent.switcharoo).
-- Replaces both Omarchy's stock workspace-local ALT+TAB cycling and the
-- retired altswitch fork (which previously held SUPER+TAB; still in git
-- history under omarchy/plugins/io.github.pablo-merino.altswitch/).
-- The plugin's release-watch and commit path are patched locally (see
-- omarchy/plugins/patches/switcharoo-local.patch): commit-on-release watches
-- the Super keys (without it SUPER+TAB would open the grid but never commit
-- on release), and commits run omarchy-window-raise-front so a committed
-- tiled window covered by a floater is floated in place and raised. Removal, if ever needed:
--   1. delete this block
--   2. omarchy plugin remove io.github.gabrielvincent.switcharoo --yes
-- The "Switcharoo switcher" description acts as a sentinel: the plugin checks
-- for it in `hyprctl binds` to detect that the binding is installed.
hl.unbind("ALT + TAB")
o.bind("ALT + TAB", "Switcharoo switcher", hl.dsp.global("omarchy-switcharoo:next"), { repeating = true })

hl.unbind("ALT + SHIFT + TAB")
o.bind("ALT + SHIFT + TAB", "Switcharoo switcher", hl.dsp.global("omarchy-switcharoo:previous"), { repeating = true })

hl.unbind("ALT + GRAVE")
o.bind("ALT + GRAVE", "Switcharoo switcher", hl.dsp.global("omarchy-switcharoo:previous"), { repeating = true })

hl.layer_rule({ match = { namespace = "omarchy-switcharoo" }, no_anim = true })

-- SUPER+TAB / SUPER+SHIFT+TAB (mac Cmd+Tab muscle memory) share ALT+TAB's
-- global shortcuts. These chords no longer switch workspaces: use SUPER+1..0,
-- scroll, or gestures.
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")
o.bind("SUPER + TAB", "Switcharoo switcher", hl.dsp.global("omarchy-switcharoo:next"), { repeating = true })
o.bind("SUPER + SHIFT + TAB", "Switcharoo switcher", hl.dsp.global("omarchy-switcharoo:previous"), { repeating = true })
