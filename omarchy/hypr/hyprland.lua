-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Apps that must open on top of (and alongside) full-screen floating
-- windows: Hyprland always renders tiled windows below the floating layer,
-- so a tiled app launched while a floater covers the screen is invisible
-- even when it correctly holds keyboard focus. Floating these puts them in
-- the floating layer, newest on top. Get the class from `hyprctl activewindow`.
o.window("^(chatgpt)$", { float = true })
o.window("^(chatgpt)$", { center = true })
o.window("^(chatgpt)$", { size = { "(monitor_w*0.75)", "(monitor_h*0.85)" } })
