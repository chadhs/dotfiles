# Plugin patches

Local patches applied to plugin-manager-managed plugins under
`~/.config/omarchy/plugins/` (gitignored, so `omarchy plugin update` can
clobber them). After any `omarchy plugin update` or `omarchy update`, run
`sh scripts/omarchy-post-update.sh` — it re-applies this patch
automatically when the clone is clean and verifies the rest of the setup.
To apply by hand:

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

Local delta against upstream `main`, applied across `Switcher.qml`,
`WindowModel.js`, the plugin README, and its tests:

1. **release-modifiers config** (`Switcher.qml` + `WindowModel.js`) — adds a
   `releaseModifiers` setting (default `["alt"]`, alias `release_modifiers`)
   so commit-on-release watches configurable modifiers instead of hardcoded
   Alt. `shell.json` sets `["alt", "super"]` for the mac Cmd+Tab
   SUPER+TAB bindings. This is also the pending upstream PR — when it
   merges, this part of the patch is dropped and the config alone carries
   the behavior.
2. **raise-front** (`Switcher.qml`, marked `LOCAL PATCH`) — after the focus
   dispatch in `activateSelected()`, runs the repo-owned
   `omarchy-window-raise-front <address>` helper so a committed tiled window
   overlapped by a floater is floated in place and raised (Hyprland renders
   all floats above all tiles; plain focus would leave it invisible).

The patch source of truth is the `local-patch` branch of the fork at
`~/src/chadhs/omarchy-switcharoo` (`git diff upstream/main local-patch`);
the PR branch is `release-modifiers-config` (everything above minus the
local-only raise-front commit). Both are required by the bindings in
`omarchy/hypr/bindings.lua` (switcharoo section).

## TODO: when upstream merges the releaseModifiers PR

(https://github.com/gabrielvincent/omarchy-switcharoo/pull/1 — draft as of
2026-08-31; flip this section into done notes when it lands.)

1. `omarchy plugin update` — upstream code now carries releaseModifiers
   natively; the live clone needs no patch for it
2. Shrink `switcharoo-local.patch` to the raise-front hunk only
   (`git diff upstream/main <raise-front-only-ref>` from the fork), re-apply,
   `sh scripts/omarchy-post-update.sh` must be 10/10
3. `omarchy/shell.json` keeps `"releaseModifiers": ["alt", "super"]` — now
   consumed by upstream code instead of the patch; no change needed
4. Extend `PATCH_SENTINELS` in `scripts/omarchy-post-update.sh` back to just
   `omarchy-window-raise-front`
5. Update this README (patch covers only Switcher.qml again); delete the
   fork if desired — the dotfiles repo has no other dependency on it
