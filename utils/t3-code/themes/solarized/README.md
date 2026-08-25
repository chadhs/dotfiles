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

Re-import the same file after you change it; T3 Code treats a matching `id`
as an update.

## How it's built

T3 Code themes map ~57 UI roles (canvas, sidebar, toolbar, status colors,
terminal, etc.) to CSS colors, with an optional `variants.dark` block for
the other appearance. The role list lives in
`apps/web/src/themePalette.ts` (`THEME_COLOR_ROLES`) in the T3 Code repo.

Solarized only defines 16 swatches (8 monotones + 8 accents). Roles here
follow [Schoonover's own reading pairs](https://ethanschoonover.com/solarized/)
rather than inventing a new hierarchy:

- **Text pairing**: two foreground/background pairs per mode carry the same
  contrast — `base3:base00` (light) / `base03:base0` (dark) for text on the
  plain canvas, and `base2:base01` (light) / `base02:base1` (dark) for text
  on a highlighted surface (sidebar, code blocks, secondary buttons). Each
  role uses whichever pair matches the surface it actually renders on.
- **Muted text** (`textMuted`, `placeholder`, `iconMuted`,
  `mutedForeground`, `sidebarMutedForeground`): Solarized's comment tier
  (`base1` light / `base01` dark) is ~2.5:1 by design and nearly disappears
  on these surfaces. Placeholders, timestamps, and sidebar counts need to
  stay readable, so that tier is nudged toward black/white to a ~3.6:1
  floor (still short of WCAG AA 4.5:1). The committed hexes are
  `#7a8282` / `#717979` (light, canvas vs highlighted) and `#727f86` /
  `#7c8990` (dark). Body text on canvas lands around 4.1:1 light / 4.8:1
  dark — Solarized's own designed contrast, not AA.
- **Derived surfaces** (raised panels, hover/active/selected rows, status
  backgrounds): mixed between adjacent Solarized tones and the accent hue
  so they stay visually part of the palette. Sidebar hover/active stays
  subtle on purpose; a wider contrast spread read heavier than Solarized.
- **Accents**: blue (`#268bd2`) for focus/accent/links, red (`#dc322f`) for
  errors, orange (`#cb4b16`) for warnings, violet (`#6c71c4`) for the
  "update available" indicator.

## Updating the theme

Edit hex values in `solarized-theme.json` directly. Keep every role in both
`colors` and `variants.dark` — T3 Code fills omitted keys from its default
pink/purple palette, which will look wrong next to Solarized.

If T3 Code adds roles, copy the new names from `THEME_COLOR_ROLES` and pick
the nearest existing pair (canvas vs highlighted surface, or the matching
status accent).
