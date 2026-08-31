# Plugin patches

Local patches applied to plugin-manager-managed plugins under
`~/.config/omarchy/plugins/` (gitignored, so `omarchy plugin update` can
clobber them). Re-apply after updates:

```sh
git -C ~/.config/omarchy/plugins/io.github.gabrielvincent.switcharoo apply \
  ~/dotfiles/omarchy/plugins/patches/switcharoo-local.patch
```

If an update changed `Switcher.qml` enough that the patch no longer applies
cleanly, regenerate it after re-porting by hand:

```sh
git -C ~/.config/omarchy/plugins/io.github.gabrielvincent.switcharoo diff \
  > ~/dotfiles/omarchy/plugins/patches/switcharoo-local.patch
```

## switcharoo-local.patch

Local patches to `Switcher.qml` (both marked `LOCAL PATCH` in the source):

1. **super-release** — extends `isReleaseModifier` / `modifierKeyExpr` to
   watch the Super keys alongside Alt, so SUPER+TAB / SUPER+SHIFT+TAB
   bindings commit on modifier release (mac Cmd+Tab semantics) the same way
   ALT+TAB does.
2. **raise-front** — after the focus dispatch in `activateSelected()`, runs
   the repo-owned `omarchy-window-raise-front <address>` helper so a committed
   tiled window overlapped by a floater is floated in place and raised
   (Hyprland renders all floats above all tiles; plain focus would leave it
   invisible).

Both are required by the bindings in `omarchy/hypr/bindings.lua`
(switcharoo section).
