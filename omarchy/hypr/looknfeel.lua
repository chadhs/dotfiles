-- Change the default Omarchy look'n'feel.

-- Slightly rounded window corners (recommended by the Solarized themes).
hl.config({
  decoration = {
    rounding = 8,
  },
})

-- Thin border (recommended by the Solarized themes; colors come from the theme).
hl.config({
  general = {
    border_size = 1,
  },
})

-- Apps that must open on top of (and alongside) full-screen floating windows:
-- Hyprland always renders tiled windows below the floating layer, so a tiled
-- app launched while a floater covers the screen is invisible even when it
-- correctly holds keyboard focus. Floating these puts them in the floating
-- layer, newest on top. Get the class from `hyprctl activewindow`.
-- (Previously lived in a vendored hyprland.lua; that file is stock again.)
o.window("^(chatgpt)$", { float = true })
o.window("^(chatgpt)$", { center = true })
o.window("^(chatgpt)$", { size = { "(monitor_w*0.75)", "(monitor_h*0.85)" } })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })
