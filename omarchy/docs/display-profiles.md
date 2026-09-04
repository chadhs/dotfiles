# Display ICC profiles

Hyprland loads one ICC per output via `icc =` on `hl.monitor` in
[`hypr/monitors.lua`](../hypr/monitors.lua). That is the color path on this
machine. Do not enable `displaycal-apply-profiles`, colord, or `dispwin`.
Omarchy does not see these displays through colord anyway.

The profiles themselves stay out of git. They are large, they are this
desk, and a second machine should measure its own panels.

## Current files

SpyderX, DisplayCAL 3.9.17, XYZLUT+MTX, D65, gamma 2.2, about 150 cd/m².

| output | profile dir under `~/.local/share/DisplayCAL/storage/` |
| --- | --- |
| DP-1 | `Monitor_1_#1_2026-09-04_14-40_150cdm²_D6500_2.2_F-S_XYZLUT+MTX/` |
| DP-2 | `Monitor_2_#2_2026-09-04_15-18_150cdm²_D6500_2.2_F-S_XYZLUT+MTX/` |

Point `icc` at the `.icc` inside that directory. Keep the DP-1 `hl.monitor`
block first so `position = "auto-right"` on DP-2 still lands to the right of
`0x0`. Scale is `1.6` here (`GDK_SCALE=2`). Do not hardcode `2400x0`.

`hyprctl monitors` does not print the ICC path. After a reload, empty
`hyprctl configerrors` is the parser check. Look at the screens.

Hyprland `icc` forces SDR EOTF to sRGB. It does not mix with HDR. Turn night
light off when you are judging the profile.

## Load a different profile

1. Edit `icc =` in `omarchy/hypr/monitors.lua` (the live file is a symlink).
2. `hyprctl reload` and `hyprctl configerrors`.
3. Leave the monitor OSD brightness where DisplayCAL left it. A big backlight
   change makes the ICC describe the wrong display. Theme swap is the
   day/night change, not the brightness slider.

Older 180-nit runs are still in `storage/` if you need to compare. DP-2 never
hit 180 last time (~172). The 150-nit pair is the one that actually matches.

## Make new profiles

Need a SpyderX and the Arch `displaycal` package (pulls ArgyllCMS).

Warm the panels about 30 minutes. Same picture mode on both. No vivid or
dynamic processing.

In DisplayCAL:

1. Display & instrument. Pick the output (Monitor 1 / DP-1, then Monitor 2 /
   DP-2). Instrument is the SpyderX. Display type Rec. 709 / native, whatever
   you used last time (`-yb` in the logs).
2. Calibration. White 150 cd/m², D65, gamma 2.2. Interactive adjustment:
   set **white level with the monitor backlight only**. Then white point with
   RGB gains if needed. DisplayCAL will sometimes scale 150 down a couple of
   nits "to fit within gamut". That is fine.
3. Profiling. XYZLUT+MTX, default 175-patch chart, quality as before.
4. Calibrate & profile. One output at a time.

Set `profile.create_gamut_views = 0` in `~/.config/DisplayCAL/DisplayCAL.ini`.
Default is 1. On Python 3.14 the post-ICC gamut-view step hangs (idle CPU, no
`colprof`, a pile of forkservers). The stock `demjson_compat.py` also dies on
`encoding=` in `JSONEncoder`. Package updates overwrite a local patch.

After the 175 patches, DisplayCAL often hangs on "Create profile" even with
gamut views off. The ICC is already in `/tmp/DisplayCAL-*/` next to the
`.ti3`. Copy it into the matching folder under
`~/.local/share/DisplayCAL/storage/` or you will only have `.cal` / `.ti3`
and think the run failed. Reboot wipes `/tmp`.

Then point `monitors.lua` at the new `.icc` and reload.

Kill a stuck DisplayCAL with `fix-displaycal` (function in `~/.user-env`).
That is `pkill -f '^/usr/bin/python /usr/bin/displaycal'` plus the
forkservers and `rm ~/.config/DisplayCAL/DisplayCAL.lock`. Do not
`pkill -f displaycal`. It matches random shell lines.

A stale `DisplayCAL.lock` is why a second launch says the app is already
running.

## Window rules (local)

Tiling Hyprland puts DisplayCAL prompts on top of the measurement patch.
`~/.config/hypr/displaycal.lua` (required from `hyprland.lua`) floats the
app, keeps the patch centered and opaque, parks the main UI top-left under
the bar, and puts dialogs to the right of that window on the **same**
monitor the session opened on.

This file is not in the repo. `hyprland.lua` stays stock Omarchy. If you
rebuild the machine, copy `displaycal.lua` back or the prompts cover the
patch again.

Do not tag DisplayCAL as `floating-window`. That tag also centers and
resizes to 875x600.

## Did the profile fit?

Argyll, no extra measurements:

```sh
profcheck -v -k \
  "….ti3" \
  "….icc"
```

Look for `Profile check complete, errors(CIEDE2000)`. Avg well under 1 and
a peak of a couple of ΔE on near-black greys is normal for this SpyderX.
The 150-nit pair was about 0.08 avg / 1.4 peak. The 180-nit pair was a bit
tighter (0.04 avg) because the meter has more light to work with in the
darks. Still use the 150-nit files if the OSD is at 150.

That check is closed-loop. Same instrument, same session. It does not prove
absolute accuracy and it does not re-test Hyprland's `icc=` path.
