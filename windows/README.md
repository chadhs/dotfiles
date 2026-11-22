# Native Windows editors

Run `windows/deploy.ps1` in PowerShell 7 to use the shared Neovim and Emacs
configuration on Windows 11. WSL is not required.

Editor settings, packages, language configuration, keybindings, and Solarized
themes remain under `editors/`. The small adapters in `windows/nvim/` and
`windows/emacs/` supply native paths, fonts, executable discovery, and shells.
This directory can hold other Windows applications later. The current setup
manages only these editors and their required tools.

## Setup

Start with Git, Microsoft App Installer for `winget`, and PowerShell 7. Install
PowerShell with `winget install --id Microsoft.PowerShell --exact` if needed,
then open `pwsh`. Use a normal user session. A package installer may request
elevation, but junction deployment does not require administrator access or
Windows Developer Mode.

1. Clone the repository into a stable local path, such as
   `C:\src\chadhs\dotfiles`, and open PowerShell 7 there.
2. Preview deployment. This does not install packages or write files.

   ```powershell
   .\windows\deploy.ps1 -WhatIf
   ```

3. Install the editor dependencies and deploy their configuration.

   ```powershell
   .\windows\deploy.ps1 -InstallDependencies
   ```

4. Run diagnostics.

   ```powershell
   .\windows\doctor.ps1
   ```

5. Open each editor and finish its package setup as described below. Allow about
   10 minutes for the first Emacs package download. Later starts on the verified
   machine take about 1.3 seconds in batch mode and 1.7 seconds in the GUI, before
   opening a project.

To select one editor, add `-Editor nvim` or `-Editor emacs` to deployment,
installation, and diagnostics. Running deployment again leaves matching targets
unchanged. To install or refresh dependencies separately, run
`windows/install.ps1`. It also accepts `-WhatIf`.

### Existing configuration and backups

Deployment refuses to replace an unfamiliar Neovim configuration or Emacs
`init.el`. Inspect the reported path first. To preserve it beside the new
configuration, rerun with `-BackupExisting`. Backups use a unique
`.bak-<timestamp>` suffix. `-BackupExisting -WhatIf` previews this operation.

An older Emacs startup file, compiled init, or early init can override the
redirector. Deployment stops when it finds one. Move that file aside yourself
after reviewing it. The backup flag does not bypass these conflicts.

The scripts also refuse an unrecognized `paths.json`. They do not overwrite it,
even when backups are requested.

For rollback, close the editor and restore the reported backup to its original
path. Remove only the Neovim junction itself, not its contents. Emacs rollback
replaces only the generated `init.el`; its package and state directories remain
local. The scripts do not uninstall applications.

## What deployment changes

| Location | Purpose |
| --- | --- |
| `%LOCALAPPDATA%\nvim` | Directory junction to `editors/nvim` |
| Emacs's `user-emacs-directory\init.el` | Generated redirector to `editors/emacs.el` |
| Emacs's `user-emacs-directory` | Local packages, generated Lisp, grammars, backups, and other state |
| `%LOCALAPPDATA%\dotfiles\tools\paths.json` | Generated, versioned executable paths for both editors |
| `%LOCALAPPDATA%\dotfiles\tools\node` | Shared editor npm tools and their libraries |

Neovim honors `XDG_CONFIG_HOME` and `NVIM_APPNAME`. Emacs chooses its own home
and init directory. Deployment asks the installed Emacs for
`user-emacs-directory` instead of assuming that it is `%USERPROFILE%\.emacs.d`.
With an unmodified native Emacs home, it is usually `%APPDATA%\.emacs.d`.

Neovim keeps plugins, Mason tools, parsers, and recovery files in its native
`stdpath` data and state directories. Emacs tangles `emacs-config.org` into
`user-emacs-directory/generated/emacs-config.el`, not into the checkout.

Deployment does not edit Git or SSH configuration, PowerShell profiles, the
system PATH, or `HOME`. WinGet packages can make their normal installer changes.
Editor adapters modify only the editor process's PATH, `exec-path`, and
`NODE_PATH`. Start-menu launches therefore do not depend on a terminal's fnm or
shell initialization.

### Required tools

`packages.psd1` is the dependency manifest. `links.psd1` is the deployment
manifest. Deployment and the read-only doctor use the same definitions.

The installer reuses tools it can find. Otherwise it installs Git, the selected
editors, ripgrep, fd, GCC/G++, and Node LTS through WinGet. Neovim also needs the
Tree-sitter CLI. Emacs needs native GnuPG for signed package archives. Git's
bundled GPG does not accept the same native paths and is not used for that job.

Use Neovim 0.12 or newer, Tree-sitter CLI 0.26.1 or newer, and Emacs 30.2 or
newer with Tree-sitter support. Native verification used Neovim 0.12.6 and
Emacs 31.1. The CI matrix uses Ubuntu and Windows with Emacs 30.2 for the
package-free shared regression tests. Full package and GUI checks run separately.

The shared npm prefix contains TypeScript 6, `typescript-language-server`,
Prettier, ESLint, and `vscode-langservers-extracted`. TypeScript 7 no longer
ships the JavaScript `tsserver.js` needed by this language server. Keep the
`typescript@6` constraint until the server supports its replacement.

Project-local packages take precedence. `NODE_PATH` supplies the shared
libraries only as a fallback. An existing fnm default alias can supply Node to
desktop launches. Rerun deployment after moving tools or changing their install
locations so it refreshes `paths.json`.

## First editor launch

### Neovim

Open `nvim` and allow Lazy to install the shared plugins. Use `:Lazy sync` if the
initial download was interrupted. Mason installs the Windows Lua language
server and StyLua. The JavaScript and TypeScript servers use the shared npm
prefix instead of another Mason installation.

The adapter selects an initial parser set for Lua, JavaScript, TypeScript, TSX,
JSON, HTML, CSS, Markdown, and supporting editor languages. GCC builds native
parser DLLs. Check `:checkhealth nvim-treesitter` and `:Mason` after installation.
Other configured parsers remain available through `:TSInstall`.

The shared comma-leader bindings remain unchanged. See
[`editors/nvim/EMACS-PARITY.md`](../editors/nvim/EMACS-PARITY.md).

### Emacs

Open the installed native Emacs. The first launch downloads the shared packages
from GNU ELPA and MELPA. Archive signatures remain enabled. Native GnuPG and the
compiler must be discoverable before package and grammar installation.

Emojify asks whether to download its optional emoji images during the first GUI
launch. Answer the prompt to finish startup. Declining leaves editing available;
`M-x emojify-download-emoji` can install the images later. Images stay under
`user-emacs-directory/emojis/`.

Run `M-x cs/ensure-grammars` after package setup to build the configured native
grammars. This is an explicit setup action on Windows. File opening does not
trigger grammar installation. JavaScript, TypeScript, and TSX use a fallback
mode if their primary grammar is missing. Reopen the file after installing its
grammar. Emacs 31 also uses the configured JSDoc grammar for JavaScript comments.

Both editors keep their Solarized themes and follow Windows light/dark
appearance. Emacs reads the Windows registry through auto-dark. Emacs uses a
native PowerShell buffer for `,sv` and `,sn`. Batch tools keep `cmdproxy` so npm
`.cmd` launchers work. Dired uses `ls-lisp` instead of requiring a Unix `ls`.

## Machine-local settings

Set `DOTFILES_SRC`, `DOTFILES_NOTES`, or `DOTFILES_ORG` before launching an editor
to override its source, notes, or Org directory. Windows defaults are `C:\src`,
`%USERPROFILE%\notes`, and `%USERPROFILE%\org`. No directory is moved for you.

For Neovim, create `local.lua` in its config directory. It is ignored by Git and
returns overrides for the shared platform settings.

```lua
return {
  src = 'D:/src',
  notes = 'D:/notes',
  font = 'Cascadia Mono:h14',
}
```

For Emacs, create `local.el` in `user-emacs-directory`. It loads before the
shared configuration consumes the platform settings.

```elisp
(setq cs/source-directory "D:/src"
      cs/notes-directory "D:/notes"
      cs/default-font "Cascadia Mono"
      cs/default-font-height 140)
```

`DOTFILES_TOOLS` overrides the shared tools directory. Set it for both editor
launches and script invocations. Passing `-ToolsDirectory` to a script alone
does not change Neovim's environment. `-NvimConfig` and `-EmacsConfig` select
deployment targets for tests or alternate launches; they do not change where an
unmodified editor looks for its init file.

## Acceptance coverage and optional tools

The full acceptance tests exercise TypeScript diagnostics, completion and
definition requests, project-aware Prettier, JavaScript ESLint, Markdown and Org,
project search, Git status, and native shells. Neovim also checks Lua LSP and
StyLua. A separate Emacs GUI test checks normal redirected startup, isolated
packages and generated state, Flycheck, Solarized, Windows appearance detection,
TypeScript, indentation guides, and clipboard copy and paste through an external
PowerShell process. Clipboard checks require a desktop session. Run the editor
acceptance tests sequentially because they share the system clipboard. Tests use
paths with spaces and can run with only Windows system directories on the
inherited PATH.

Ruby, Python, Go, Rust, Java, Clojure, and Elixir remain configured in the shared
editors. This Windows setup does not install or certify their runtimes or
language-specific tools. Missing Ruby does not start a formatter or language
server. When a native Ruby is available, the adapter uses `ruby -S` instead of
the Unix chruby launcher. Install project gems separately.

Treemacs works without Python, but reports that its advanced Git integration
and directory flattening are unavailable. Spelling and external Markdown/Org
preview commands also need their own optional programs. The doctor reports
missing optional tools without failing setup.

Emacs 31 and the current YASnippet packages can print `Inconsistent hierarchy`
when TypeScript snippet parents load. Inherited TypeScript snippet expansion
passes despite that warning. The GUI can also report that `text-scale-increase`
was redefined. Neither warning prevented the verified editing checks. The first
package installation reported an upstream `org-pomodoro-pidgin.el` compilation
error. Subsequent shared-config startup and acceptance checks passed; the Pidgin
integration is not verified.

## Tests

Run the package-free regression tests from the repository root.

```powershell
.\windows\tests\deploy.Tests.ps1
nvim --headless -u NONE -i NONE -n -l windows/tests/nvim.lua
emacs --batch -Q -l windows/tests/emacs-tests.el -f ert-run-tests-batch-and-exit
```

`deploy.Tests.ps1` uses disposable targets, checks refusal and backup behavior,
and removes only its own temporary directory. It does not install packages.

For Neovim's full acceptance test, finish plugin, parser, and Mason installation
first. Set `DOTFILES_TEST_ROOT` to a disposable directory; the test writes files
and initializes a Git repository there.

```powershell
$env:DOTFILES_TEST_ROOT = Join-Path $env:TEMP 'dotfiles nvim acceptance'
nvim --headless -i NONE -n '+lua local ok,err=pcall(dofile,"windows/tests/nvim-acceptance.lua"); if not ok then print(err); vim.cmd("cquit 1") end' '+qa!'
```

For Emacs's full acceptance test, use a separate test root. First deploy only its
redirector into isolated state and launch that init directory. This keeps package
installation out of the normal Emacs configuration without changing `HOME`.

```powershell
$env:DOTFILES_TEST_ROOT = Join-Path $env:TEMP 'dotfiles emacs acceptance'
$init = Join-Path $env:DOTFILES_TEST_ROOT 'emacs'
.\windows\deploy.ps1 -Editor emacs -EmacsConfig $init
emacs --init-directory="$init"
```

Finish package installation, answer the optional emoji-image prompt, and run
`M-x cs/ensure-grammars` in that isolated Emacs. Close it before running the batch
test. The batch test loads the shared configuration with packages and grammars
under `DOTFILES_TEST_ROOT/emacs/` and creates its sample project there.

```powershell
emacs --batch -Q -l windows/tests/emacs-acceptance.el
```

For the separate GUI test, use the same test root after the batch test. Install
the optional emoji images in that isolated init directory first so an unanswered
first-launch prompt cannot block automation. This command starts a real frame,
checks copy and paste, writes `emacs-gui-result.txt` under the test root, and
exits. It restores the previous clipboard text, not non-text clipboard formats.

```powershell
emacs --no-site-file --no-site-lisp --no-splash --init-directory="$init" -l windows/tests/emacs-gui.el
Get-Content (Join-Path $env:DOTFILES_TEST_ROOT 'emacs-gui-result.txt')
```

These full tests need network access during initial editor setup and are not
part of the package-free CI jobs.
