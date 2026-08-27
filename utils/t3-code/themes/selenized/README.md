# Selenized theme for T3 Code

A [Selenized](https://github.com/jan-warchol/selenized) theme for
[T3 Code](https://github.com/pingdotgg/t3code) that follows the app's system
light/dark switch: `selenized-theme.json` is a single dual-mode theme file
(Selenized Light as the base, Selenized Dark as the `dark` variant), so
picking it once covers both appearances.

Selenized is Jan Warchoł's redesign of Solarized. Same two-background reading
model, higher contrast, and accent colors that actually tell apart on a
typical display. The black and white variants are a higher-contrast family
and are not in this file.

## Install

1. Open T3 Code → Settings → **Themes**.
2. Click **Add theme**, then drop `selenized-theme.json` on the dialog (or
   pick it from the file browser).
3. Select **Selenized** as your theme. It'll follow your OS/app appearance
   mode automatically.

Re-import the same file after you change it; T3 Code treats a matching `id`
as an update.

## How it's built

T3 Code themes map ~57 UI roles (canvas, sidebar, toolbar, status colors,
terminal, etc.) to CSS colors, with an optional `variants.dark` block for
the other appearance. The role list lives in
`apps/web/src/themePalette.ts` (`THEME_COLOR_ROLES`) in the T3 Code repo.

Selenized defines 3 background shades, 3 content shades, and 8 accents (each
with a bright version). Roles follow
[Warchoł's mapping](https://github.com/jan-warchol/selenized/blob/master/manual-installation.md)
and the same canvas vs highlighted split as the Solarized T3 theme. sRGB
values come from
[the-values.md](https://github.com/jan-warchol/selenized/blob/master/the-values.md).
LAB is canonical; we use the published sRGB column.

- **Text pairing**: `bg_0:fg_0` for text on the plain canvas, `bg_1:fg_1` for
  text on a highlighted surface (sidebar, code blocks, secondary buttons).
  Each role uses whichever pair matches the surface it actually renders on.
  Selenized's accents are *not* shared across modes the way Solarized's are;
  light blue is `#0072d4`, dark blue is `#4695f7`.
- **Muted text** (`textMuted`, `placeholder`, `iconMuted`,
  `mutedForeground`, `sidebarMutedForeground`): Selenized's dim tier
  (`dim_0`) is still ~2.6:1 light / ~3.2:1 dark on canvas, which is too faint
  for placeholders, timestamps, and sidebar counts. That tier is nudged
  toward black/white to a ~3.6:1 floor, same as the Solarized T3 theme. The
  committed hexes are `#79817e` / `#707673` (light, canvas vs highlighted)
  and `#7c9197` / `#8da0a4` (dark). Body text on canvas lands around 5.4:1
  light / 6.1:1 dark, which is Selenized's own designed contrast (WCAG AA).
- **Derived surfaces** (raised panels, hover/active/selected rows, status
  backgrounds): mixed between adjacent Selenized tones and the accent hue
  with the same mix ratios as the Solarized T3 theme. Sidebar hover/active
  stays subtle on purpose.
- **Accents**: blue for focus/accent/links, red for errors, orange for
  warnings, violet for the "update available" indicator.

## Updating the theme

Edit hex values in `selenized-theme.json` directly. Keep every role in both
`colors` and `variants.dark`. T3 Code fills omitted keys from its default
pink/purple palette, which will look wrong next to Selenized.

If T3 Code adds roles, copy the new names from `THEME_COLOR_ROLES` and pick
the nearest existing pair (canvas vs highlighted surface, or the matching
status accent).
