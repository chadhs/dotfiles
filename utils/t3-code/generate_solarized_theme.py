#!/usr/bin/env python3
"""Regenerates solarized-theme.json from the canonical Solarized palette.

T3 Code (https://github.com/pingdotgg/t3code) theme files map 57 UI roles to
colors, with an optional `variants.dark` block for the other appearance. This
script derives both from Ethan Schoonover's 16 Solarized swatches, mixing and
contrast-solving the roles the base palette doesn't define directly (raised
surfaces, hover states, status backgrounds), so the JSON only needs
regenerating if the role list or a design decision changes.
"""

import json
from pathlib import Path

OUTPUT = Path(__file__).parent / "solarized-theme.json"

ROLES = [
    "canvas", "chrome", "toolbar", "toolbarForeground", "toolbarBorder", "toolbarControl",
    "toolbarControlForeground", "toolbarControlHover", "surface", "surfaceRaised", "surfaceOverlay",
    "text", "textMuted", "border", "input", "focus", "accent", "accentForeground", "secondary",
    "secondaryForeground", "muted", "mutedForeground", "placeholder", "secondaryLabel", "iconMuted",
    "error", "errorForeground", "errorSurface", "warning", "warningForeground", "warningSurface",
    "update", "updateForeground", "updateSurface", "accentSurface", "accentSurfaceForeground",
    "messageSurface", "messageForeground", "messageAction", "messageActionForeground", "messageActionHover",
    "codeBackground", "codeForeground", "sidebar", "sidebarForeground", "sidebarMutedForeground",
    "sidebarControlSurface", "sidebarRowHover", "sidebarRowActive", "sidebarRowSelected", "sidebarBorder",
    "terminalBackground", "terminalForeground", "terminalCursor", "terminalSelection", "terminalScrollbar",
    "terminalScrollbarHover",
]


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return "#" + "".join(f"{max(0, min(255, round(c))):02x}" for c in rgb)


def mix(a, b, t):
    ar, ag, ab = hex_to_rgb(a)
    br, bg, bb = hex_to_rgb(b)
    return rgb_to_hex((ar + (br - ar) * t, ag + (bg - ag) * t, ab + (bb - ab) * t))


def srgb_channel_to_linear(c):
    c = c / 255
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(hexcol):
    r, g, b = hex_to_rgb(hexcol)
    return 0.2126 * srgb_channel_to_linear(r) + 0.7152 * srgb_channel_to_linear(g) + 0.0722 * srgb_channel_to_linear(b)


def contrast(a, b):
    la, lb = relative_luminance(a), relative_luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def contrast_solved(fg, bg, target, toward, step=0.01):
    """Mix `fg` toward `toward` (black/white) until it clears `target` contrast
    against `bg`. Used to nudge Solarized's low-contrast "comments" tone up to
    a legible floor for muted UI text, without changing its hue."""
    c = fg
    for _ in range(200):
        if contrast(c, bg) >= target:
            return c
        c = mix(c, toward, step)
    return c


# The 16 canonical Solarized swatches (https://ethanschoonover.com/solarized/).
base03, base02, base01, base00 = "#002b36", "#073642", "#586e75", "#657b83"
base0, base1, base2, base3 = "#839496", "#93a1a1", "#eee8d5", "#fdf6e3"
yellow, orange, red, magenta = "#b58900", "#cb4b16", "#dc322f", "#d33682"
violet, blue, cyan, green = "#6c71c4", "#268bd2", "#2aa198", "#859900"

# Official Solarized reading pairs (ethanschoonover.com/solarized): Schoonover
# tuned two foreground/background pairs per mode to carry identical L*a*b
# contrast, so text reads the same whether it sits on the plain background or
# a highlighted one.
#   light:  base3:base00 (canvas)  <->  base2:base01 (highlighted surface)
#   dark:   base03:base0 (canvas)  <->  base02:base1 (highlighted surface)
# Content roles below pick a member of the matching pair by which surface they
# actually render on. "Comments/secondary content" is Solarized's own third
# tier (base1 light / base01 dark), used for textMuted and friends -- but
# Solarized designed that tone to nearly disappear next to syntax-highlighted
# code (~2.5:1), and this role also carries placeholder text, timestamps, and
# sidebar counts, which people actually need to read. So it's nudged up to a
# 3.6:1 floor here (still short of AA's 4.5:1, but no longer near-invisible)
# rather than used at its literal, near-invisible value. Solved separately per
# background since the role renders on both the canvas and the sidebar/muted
# surface, which need slightly different amounts of nudging.
MUTED_TARGET = 3.6
light_muted_on_canvas = contrast_solved(base1, base3, MUTED_TARGET, "#000000")
light_muted_on_surface = contrast_solved(base1, base2, MUTED_TARGET, "#000000")
dark_muted_on_canvas = contrast_solved(base01, base03, MUTED_TARGET, "#ffffff")
dark_muted_on_surface = contrast_solved(base01, base02, MUTED_TARGET, "#ffffff")

light = {
    "canvas": base3, "chrome": base3, "toolbar": base3,
    "toolbarForeground": base00, "toolbarBorder": mix(base2, base1, 0.35),
    "toolbarControl": base2, "toolbarControlForeground": base01,
    "toolbarControlHover": mix(base2, base1, 0.3),
    "surface": base3, "surfaceRaised": mix(base3, "#ffffff", 0.6), "surfaceOverlay": "#fffefa",
    "text": base00, "textMuted": light_muted_on_canvas,
    "border": mix(base2, base1, 0.35), "input": mix(base2, base1, 0.55),
    "focus": blue, "accent": blue, "accentForeground": "#ffffff",
    "secondary": base2, "secondaryForeground": base01,
    "muted": base2, "mutedForeground": light_muted_on_surface,
    "placeholder": light_muted_on_canvas, "secondaryLabel": light_muted_on_canvas,
    "iconMuted": light_muted_on_canvas,
    "error": red, "errorForeground": "#d02f2c", "errorSurface": mix(base3, red, 0.13),
    "warning": orange, "warningForeground": "#bf4816", "warningSurface": mix(base3, orange, 0.15),
    "update": violet, "updateForeground": "#6469b4", "updateSurface": mix(base3, violet, 0.15),
    "accentSurface": mix(base3, blue, 0.14), "accentSurfaceForeground": base01,
    "messageSurface": mix(base3, blue, 0.18), "messageForeground": base01,
    "messageAction": blue, "messageActionForeground": "#ffffff", "messageActionHover": mix(blue, "#000000", 0.12),
    "codeBackground": base2, "codeForeground": base01,
    "sidebar": base2, "sidebarForeground": base01, "sidebarMutedForeground": light_muted_on_surface,
    # A wider hover/active/selected spread (~1.6-1.8:1 vs sidebar, up from
    # ~1.1-1.4:1) was tried and measurably clears more contrast, but it reads
    # heavier than Solarized's quiet, low-saturation character -- kept at the
    # original subtler mix by preference.
    "sidebarControlSurface": mix(base2, base1, 0.18),
    "sidebarRowHover": mix(base2, base1, 0.22), "sidebarRowActive": mix(base2, base1, 0.38),
    "sidebarRowSelected": mix(base2, blue, 0.18), "sidebarBorder": mix(base2, base1, 0.45),
    "terminalBackground": base3, "terminalForeground": base00, "terminalCursor": blue,
    "terminalSelection": mix(base3, blue, 0.22), "terminalScrollbar": mix(base3, base1, 0.45),
    "terminalScrollbarHover": mix(base3, base1, 0.6),
}

dark = {
    "canvas": base03, "chrome": base03, "toolbar": base03,
    "toolbarForeground": base0, "toolbarBorder": mix(base02, base01, 0.35),
    "toolbarControl": base02, "toolbarControlForeground": base1,
    "toolbarControlHover": mix(base02, base01, 0.35),
    "surface": base03, "surfaceRaised": mix(base03, base02, 0.6), "surfaceOverlay": mix(base02, "#000000", 0.15),
    "text": base0, "textMuted": dark_muted_on_canvas,
    "border": mix(base02, base01, 0.35), "input": mix(base02, base01, 0.55),
    "focus": blue, "accent": blue, "accentForeground": "#ffffff",
    "secondary": base02, "secondaryForeground": base1,
    "muted": base02, "mutedForeground": dark_muted_on_surface,
    "placeholder": dark_muted_on_canvas, "secondaryLabel": dark_muted_on_canvas,
    "iconMuted": dark_muted_on_canvas,
    "error": red, "errorForeground": "#e66765", "errorSurface": mix(base03, red, 0.22),
    "warning": orange, "warningForeground": "#d8744c", "warningSurface": mix(base03, orange, 0.24),
    "update": violet, "updateForeground": "#8689cd", "updateSurface": mix(base03, violet, 0.24),
    "accentSurface": mix(base03, blue, 0.22), "accentSurfaceForeground": base1,
    "messageSurface": mix(base03, blue, 0.28), "messageForeground": base1,
    "messageAction": blue, "messageActionForeground": "#ffffff", "messageActionHover": mix(blue, "#ffffff", 0.14),
    "codeBackground": base02, "codeForeground": base1,
    "sidebar": base02, "sidebarForeground": base1, "sidebarMutedForeground": dark_muted_on_surface,
    "sidebarControlSurface": mix(base02, base01, 0.2),
    "sidebarRowHover": mix(base02, base01, 0.25), "sidebarRowActive": mix(base02, base01, 0.4),
    "sidebarRowSelected": mix(base02, blue, 0.28), "sidebarBorder": mix(base02, base01, 0.5),
    "terminalBackground": base03, "terminalForeground": base0, "terminalCursor": blue,
    "terminalSelection": mix(base03, blue, 0.32), "terminalScrollbar": mix(base03, base01, 0.55),
    "terminalScrollbarHover": mix(base03, base01, 0.7),
}


def check_missing(name, colors):
    missing = set(ROLES) - set(colors)
    extra = set(colors) - set(ROLES)
    if missing:
        raise SystemExit(f"{name} is missing roles: {sorted(missing)}")
    if extra:
        raise SystemExit(f"{name} has unknown roles: {sorted(extra)}")


def report_contrast():
    # These are informational, not a pass/fail gate: the point of this theme
    # is to reproduce Schoonover's own designed contrast levels, not to hit
    # WCAG AA. text/textMuted intentionally land where Solarized's spec puts
    # them -- textMuted (the "comments" tier) is ~2.5:1 by design.
    pairs = [
        ("light text/canvas", light["text"], light["canvas"]),
        ("light textMuted/canvas", light["textMuted"], light["canvas"]),
        ("light mutedForeground/muted", light["mutedForeground"], light["muted"]),
        ("light sidebarForeground/sidebar", light["sidebarForeground"], light["sidebar"]),
        ("light sidebarMutedForeground/sidebar", light["sidebarMutedForeground"], light["sidebar"]),
        ("dark text/canvas", dark["text"], dark["canvas"]),
        ("dark textMuted/canvas", dark["textMuted"], dark["canvas"]),
        ("dark mutedForeground/muted", dark["mutedForeground"], dark["muted"]),
        ("dark sidebarForeground/sidebar", dark["sidebarForeground"], dark["sidebar"]),
        ("dark sidebarMutedForeground/sidebar", dark["sidebarMutedForeground"], dark["sidebar"]),
    ]
    for label, fg, bg in pairs:
        print(f"  {label}: {contrast(fg, bg):.2f}:1")


check_missing("light", light)
check_missing("dark", dark)
report_contrast()

theme_file = {
    "version": 1,
    "id": "solarized",
    "name": "Solarized",
    "appearance": "light",
    "colors": {role: light[role] for role in ROLES},
    "variants": {"dark": {role: dark[role] for role in ROLES}},
}

OUTPUT.write_text(json.dumps(theme_file, indent=2) + "\n")
print(f"wrote {OUTPUT}")
