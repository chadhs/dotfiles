# Solarized theme for T3 Code

A [Solarized](https://ethanschoonover.com/solarized/) theme for
[T3 Code](https://github.com/pingdotgg/t3code) that follows the app's system
light/dark switch: `solarized-theme.json` is a single dual-mode theme file
(Solarized Light as the base, Solarized Dark as the `dark` variant), so
picking it once covers both appearances.

## Install

1. Open T3 Code → Settings → **Themes**.
2. Click **Add theme**, then drop `solarized-theme.json` on the dialog (or
   pick it from the file browser).
3. Select **Solarized** as your theme. It'll follow your OS/app appearance
   mode automatically.

## How it's built

T3 Code themes are JSON files mapping ~57 UI roles (canvas, sidebar, toolbar,
status colors, terminal, etc. — see `packages/shared/src/themePalettes.ts` in
the T3 Code repo) to CSS colors, with an optional `variants.dark` block for
the other appearance.

Solarized only defines 16 swatches (8 monotones + 8 accents), far fewer than
the role list, so `generate_solarized_theme.py` derives the rest, following
[Schoonover's own reading pairs](https://ethanschoonover.com/solarized/)
rather than inventing a new hierarchy:

- **Text pairing**: Solarized tunes two foreground/background pairs per mode
  to carry identical contrast — `base3:base00` (light) / `base03:base0`
  (dark) for text on the plain canvas, and `base2:base01` (light) /
  `base02:base1` (dark) for text on a highlighted surface (sidebar, code
  blocks, secondary buttons). Each role here uses whichever pair matches the
  surface it actually renders on.
- **Muted text** (`textMuted`, `placeholder`, `iconMuted`, etc.) uses
  Solarized's own third tier, "comments / secondary content" — `base1`
  (light) / `base01` (dark) — exactly as documented. That's genuinely low
  contrast (~2.5:1), by design: it's meant to visually recede the way code
  comments do. This theme reproduces that rather than boosting it for WCAG AA.
- **Derived surfaces** (raised panels, hover/active/selected rows, status
  backgrounds): mixed between adjacent Solarized tones and the accent hue
  rather than invented from scratch, so they stay visually part of the
  palette.
- **Accents**: blue (`#268bd2`) for focus/accent/links, red (`#dc322f`) for
  errors, orange (`#cb4b16`) for warnings, violet (`#6c71c4`) for the
  "update available" indicator — all straight from Solarized's accent set.

Re-run `python3 generate_solarized_theme.py` after changing a design
decision in the script; it asserts the full 57-role list is covered and
prints the resulting contrast ratios for the key text pairs.
