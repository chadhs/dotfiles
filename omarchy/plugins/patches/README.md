# Plugin patches

Local patches applied to plugin-manager-managed plugins under
`~/.config/omarchy/plugins/` (gitignored, so `omarchy plugin update` can
clobber them). Re-apply after updates:

```sh
git -C ~/.config/omarchy/plugins/io.github.gabrielvincent.switcharoo apply \
  ~/dotfiles/omarchy/plugins/patches/switcharoo-super-release.patch
```

## switcharoo-super-release.patch

`Switcher.qml` — extends `isReleaseModifier` / `modifierKeyExpr` to watch the
Super keys alongside Alt, so SUPER+TAB / SUPER+SHIFT+TAB bindings commit on
modifier release (mac Cmd+Tab semantics) the same way ALT+TAB does. Referenced
from `omarchy/hypr/bindings.lua` (switcharoo section).
