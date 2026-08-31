-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
  input = {
    -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt.
    -- kb_layout = "us,dk,eu",
    -- kb_options = "compose:caps,shift:both_capslock_cancel,grp:alts_toggle",

    -- Use a specific keyboard variant if needed (e.g. intl for international keyboards).
    -- kb_variant = "intl",

    -- Change speed of keyboard repeat.
    -- repeat_rate = 40,
    -- repeat_delay = 250,

    -- Start with numlock on by default.
    -- numlock_by_default = true,

    -- Increase sensitivity for mouse/trackpad (default: 0).
    -- sensitivity = 0.35,

    -- Turn off mouse acceleration (default: adaptive).
    -- accel_profile = "flat",

    touchpad = {
      -- Require a physical click; no tap-to-click.
      tap_to_click = false,

      -- Use natural (inverse) scrolling.
      natural_scroll = true,

      -- Use two-finger clicks for right-click instead of lower-right corner.
      clickfinger_behavior = true,

      -- Control the speed of your scrolling.
      -- scroll_factor = 0.4,

      -- Enable the touchpad while typing.
      -- disable_while_typing = false,

      -- Left-click-and-drag with three fingers.
      -- drag_3fg = 1,
    },
  },
})

-- Natural (inverse) scrolling for mouse-type devices. Hyprland's touchpad
-- setting above doesn't cover devices exposed as mice (e.g. the Magic
-- Trackpad or external receivers). Names must match `hyprctl devices`.
hl.device({ name = "compx-2.4g-wireless-receiver", natural_scroll = true })
hl.device({ name = "compx-2.4g-wireless-receiver-keyboard-1", natural_scroll = true })
hl.device({ name = "apple-inc.-magic-trackpad", natural_scroll = true })
hl.device({ name = "apple-inc.-magic-trackpad-1", natural_scroll = true })
hl.device({ name = "dpb-ferris-sweep-mouse", natural_scroll = true })
hl.device({ name = "dpb-ferris-sweep-consumer-control-1", natural_scroll = true })
hl.device({ name = "asix-electronics-ax68004-1", natural_scroll = true })
hl.device({ name = "asix-electronics-ax68004-consumer-control-1", natural_scroll = true })
hl.device({ name = "asix-electronics-ax68004-2", natural_scroll = true })

-- App-specific touchpad scroll speeds.
-- o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
-- o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Enable touchpad gestures for changing workspaces.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- 3-finger swipe up opens Switchboard: a full-screen live overview of every
-- window on every workspace (macOS Mission Control style). Filter by typing,
-- digits 1-9 jump, Esc dismisses. Keyboard access is SUPER+SHIFT+backslash
-- (see bindings.lua).
hl.gesture({
  fingers = 3,
  direction = "up",
  action = function() hl.exec_cmd("omarchy-shell -q switchboard toggle") end,
})

-- Enable touchpad gestures for moving focus (helpful on scrolling layout).
-- hl.gesture({ fingers = 3, direction = "left", action = function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end })
-- hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end })
