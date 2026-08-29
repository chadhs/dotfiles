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

-- Cmd+Tab-style app switcher: omarchy-altswitch plugin, patched for SUPER
-- chords (see the fork at ~/.config/omarchy/plugins/io.github.pablo-merino.altswitch/).
-- Overlay stays open while SUPER is held; release commits, SUPER+ESC cancels.
-- (An earlier standalone omarchy-appswitch script was retired in favor of the
-- plugin.) These chords no longer switch workspaces: use SUPER+1..0, scroll,
-- or gestures.
dofile(os.getenv("HOME") .. "/.config/omarchy/plugins/io.github.pablo-merino.altswitch/altswitch.lua")

-- Mac-style Cmd+W / Cmd+Q. In terminals fall back to closing the window so
-- injected CTRL+W can't delete a word and CTRL+Q can't hit flow control.
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close tab / window", function()
  if active_window_is_terminal() then
    hl.dispatch(hl.dsp.window.close())
  else
    send_shortcut_once("CTRL", "W")()
  end
end)

-- Chromium on Linux has no quit accelerator (mac Cmd+Q is menu-level), so
-- quit it by closing the window; closing the last window quits the app.
local function active_window_is_chromium()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  local class = (window.class or ""):lower()
  for _, pattern in ipairs({ "chrom", "brave", "edge", "vivaldi", "opera", "arc" }) do
    if class:find(pattern, 1, true) then
      return true
    end
  end

  return false
end

o.bind("SUPER + Q", "Quit app", function()
  if active_window_is_terminal() or active_window_is_chromium() then
    hl.dispatch(hl.dsp.window.close())
  else
    send_shortcut_once("CTRL", "Q")()
  end
end)
