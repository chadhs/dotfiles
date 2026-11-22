# Plugin patches

Local patches applied to plugin-manager-managed plugins under
`~/.config/omarchy/plugins/` (outside the dotfiles repo). Local edits can block a plugin fast-forward;
updates and validation rollback still require checking the applied patches. After any `omarchy plugin update` or `omarchy update`, run
`sh scripts/omarchy-post-update.sh` for a read-only audit. If patches are
missing, explicitly run `sh scripts/omarchy-repair-switcharoo.sh`; it applies
the snapshot only to a clean clone and restarts the shell. The audit never
changes files, restarts services, or sends notifications.
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
3. **config-fallback** (`Switcher.qml`, marked `LOCAL PATCH`) — the current
   omarchy shell's `PluginShellApi` no longer exposes `shellConfig`, so the
   plugin silently ignored every `shell.json` setting and fell back to
   defaults. Symptom as of 2026-10-01: SUPER+TAB committed ~100 ms after
   opening (release-watch saw Alt only, `false` while Super was held), so
   the grid flashed and never let you hold-tab; ALT+TAB still worked since
   it matches the default. `shellEntry()` now falls back to reading
   `~/.config/omarchy/shell.json` directly (2 s cache, `FileView`-based, so
   tab autorepeat does not reparse the file). Drop this once the shell
   exposes per-plugin entry config again.

The patch source of truth is the `local-patch` branch of the fork at
`~/src/chadhs/omarchy-switcharoo` (`git diff upstream/main local-patch`);
the PR branch is `release-modifiers-config` (everything above minus the
local-only raise-front commit). Both are required by the bindings in
`omarchy/hypr/bindings.lua` (switcharoo section).

## Retiring a patch after an upstream update

Review each installed upstream implementation before removing its local hunk.
Release-modifier support, config loading, and raise-front behavior are separate
requirements; adoption of one does not establish that the others are fixed.
Regenerate the snapshot for the remaining hunks, adjust audit sentinels to
match what must still exist in the installed plugin, and verify Alt/Super
release-to-commit plus visibility behind overlapping floating windows.
Run `sh scripts/omarchy-post-update.sh`; all applicable checks should pass.
