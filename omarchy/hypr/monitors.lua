-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- Versioned on purpose: this machine wants 1.6, not omarchy's per-machine
-- "auto" guess. If a second machine appears, fork this per machine or drop
-- the repo link for it (see omarchy/README.md "Deliberately NOT included").
local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 1.6

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- Separate Monitor Settings (specifically to set color profile)
hl.monitor({
  output = "DP-1",
  mode = "preferred",
  position = "0x0",
  scale = omarchy_monitor_scale,
  icc =
  "/home/chadhs/.local/share/DisplayCAL/storage/Monitor_1_#1_2026-09-04_10-44_180cdm²_D6500_2.2_F-S_XYZLUT+MTX/Monitor_1_#1_2026-09-04_10-44_180cdm²_D6500_2.2_F-S_XYZLUT+MTX.icc",
})

hl.monitor({
  output = "DP-2",
  mode = "preferred",
  position = "auto-right",
  scale = omarchy_monitor_scale,
  icc =
  "/home/chadhs/.local/share/DisplayCAL/storage/Monitor_2_#2_2026-09-04_11-25_180cdm²_D6500_2.2_F-S_XYZLUT+MTX/Monitor_2_#2_2026-09-04_11-25_180cdm²_D6500_2.2_F-S_XYZLUT+MTX.icc",
})
