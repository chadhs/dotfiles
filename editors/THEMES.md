# Editor themes

Neovim and Emacs always use their own Solarized themes. They follow the OS
light/dark preference, including when Omarchy changes it. Switching desktop
palettes keeps Solarized active in the editors.

## Current setup

- Neovim uses `maxmx03/solarized.nvim` with its default options and true color,
  plus `f-person/auto-dark-mode.nvim`. The callbacks set `background` and apply
  `solarized`. The configured polling interval is one second; the installed
  plugin can use desktop notifications instead when supported.
- Emacs uses `solarized-theme` and `auto-dark` in graphical, terminal, and
  daemon sessions. Both Solarized variants load before auto-switching starts.
  Terminal Emacs no longer uses Ample. Themes apply across frames in one Emacs
  process, including frames opened through `emacsclient`.
- macOS retains Neovim's native detection and Emacs's `osascript` backend.
  On Linux both packages read the desktop portal's appearance setting over
  D-Bus. Omarchy already publishes its light/dark preference through the
  desktop settings. No editor reads Omarchy's generated palettes or watches
  its theme files.

The settings live in `nvim/lua/plugins/solarized.lua` and the themes sections
of `emacs-config.org`. The Emacs `lisp/.keep` directory and its deployment
symlink remain available for future custom Lisp code.

Restart editor processes after this migration. Reloading the edited config
does not stop watchers already created by the removed Omarchy integration.
Save work and restart any Emacs daemon as well as its clients. Emacs's normal
bootstrap regenerates the tangled configuration from the updated Org source.

## Troubleshooting

On Linux, inspect the same desktop appearance signal the editors use:

```sh
gdbus call --session --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop \
  --method org.freedesktop.portal.Settings.Read \
  org.freedesktop.appearance color-scheme
```

The value is `1` for dark, `2` for light, and `0` for no preference. The
currently installed packages treat `0` as light. Run editors in the desktop
user's D-Bus session. Neovim needs `dbus-send`; `dbus-monitor` enables its
signal listener. Emacs needs a build with D-Bus support and the desktop portal
service. Remote sessions follow the environment where the editor runs.

In Neovim, check `:set background?`, `:echo g:colors_name`, and `:Lazy`.
The colorscheme should be `solarized`. In Emacs, use `M-:`, then inspect
`custom-enabled-themes`, `auto-dark-mode`, and `auto-dark-detection-method`.
The Linux backend should be `dbus`; macOS should use `osascript`.

When appearance detection is unavailable, the packages retain their own
fallback behavior. There is no custom Omarchy fallback. For terminal color
problems, check the terminal's color support and `TERM` before changing the
theme. No package upgrades are required by this config change.

## Restoring full Omarchy palette following

Git preserves the implementation:

- `cf7f45a8437ba8c8affc6ad819ab48e2d64d7dbb` is the baseline before integration.
- `934d5f7f666cfaffe87d0a04427a9d448696b5ec` introduced theme following.
- `18936064549d85ff9da0364e356842e951cc962a` is the complete pre-cleanup revision,
  including later refinements. Use this revision to recover the removed code.

From the repository root, restore the four dedicated integration files:

```sh
git restore --source=18936064549d85ff9da0364e356842e951cc962a -- \
  editors/nvim/lua/plugins/theme.lua \
  editors/nvim/lua/plugins/all-themes.lua \
  editors/nvim/lua/lib/omarchy-theme.lua \
  editors/emacs.d/lisp/omarchy-theme.el
```

Inspect the original wiring and its pre-cleanup state:

```sh
git show 934d5f7 -- editors/nvim/init.lua \
  editors/nvim/lua/plugins/solarized.lua editors/emacs-config.org
git show 18936064549d85ff9da0364e356842e951cc962a:editors/emacs-config.org
```

Reintroduce only the relevant integration blocks in the shared files:

1. In Neovim's Solarized spec, restore the early return when
   `~/.local/state/omarchy/current/theme/neovim.lua` exists. This disables both
   Solarized and its auto-switcher while the Omarchy adapter is active.
   Restore the Lazy `change_detection.notify = false` setting from the
   integration commit if Omarchy reload notifications recur.
2. In Emacs, restore the `omarchy theme` section before the Solarized sections.
   Gate both Solarized and `auto-dark` with `:if (not omarchy-theme-active)`.
   Keep the newer cross-platform detection and terminal Solarized behavior
   outside Omarchy. Ample and the old graphical-only guards are unnecessary.
3. Verify `~/.emacs.d/lisp` still points to `editors/emacs.d/lisp` in this
   checkout. Its entry remains in `scripts/links.conf`. The restored Emacs
   integration adds it to `custom-theme-load-path`.
4. On Omarchy, install missing theme plugins with `:Lazy install`, then restart
   Neovim. The cache warmer discovers stock and user theme specs, including
   Aether's explicit name and `v3` branch. Installing before testing avoids a
   failed first switch to an uncached colorscheme.

Do not restore entire shared config files or reverse later unrelated commits.
For example, the Emacs Markdown preview changes should survive restoration.

### Dependencies and reload behavior

The recovered implementation expects generated files under
`~/.local/state/omarchy/current/`: `theme/neovim.lua` for Neovim,
`theme/omarchy-colors.el` for Emacs, and `theme.name` for Emacs reloads.
Verify these paths and formats against the installed Omarchy version before
restoring the integration. Omarchy owns their generation.

The Neovim adapter reads the generated LazyVim-style spec, strips the LazyVim
distro entry, forwards theme options, and applies the colorscheme. Its
filesystem poll handles reloads while Aether is inactive; Aether owns reloads
while active. Preserve that guard to avoid competing reloads. The poll stats
the file by path because Omarchy replaces the theme directory.

Emacs reloads generated palette variables, clears old theme faces, and enables
the vendored theme. Its watcher targets the sibling `theme.name`, written
after the theme directory is replaced. Watching the replaced directory itself
can strand the watcher. The vendored theme also uses the legacy `light.mode`
marker when the Omarchy light-theme helper is unavailable; verify that light
themes still provide a compatible signal, or update that detection.

Restart editor processes after restoration. Test startup, repeated dark/light
switches, and transitions between Aether and a non-Aether theme with both
editors open. Check that Solarized auto-switchers stay disabled while Omarchy
owns the theme, and still work on macOS or when Omarchy state is absent.
