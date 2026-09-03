# Emacs → Neovim feature parity

Goal: open Neovim and operate with the same muscle memory as `editors/emacs-config.org` (`,` leader, language tooling, git, navigation).

This is intentionally **not** a full Emacs reimplementation. Org agenda depth, multi-term shell visor, and perspectives are thinner or deferred in favor of tmux + Neovim-native tools.

## Shared muscle memory

| Emacs (evil-leader `,`) | Neovim | Notes |
| --- | --- | --- |
| `,t` project file | `,t` Telescope git files | git project of the current buffer (`use_file_path`); window cwd is the file/netrw directory so `:e` is relative there |
| `,b` buffer switch | `,b` Telescope buffers | |
| `,gf` project grep | `,gf` Telescope live_grep | same git project as `,t` |
| `,Ff` find file | `,Ff` Telescope find_files | |
| `,Fd` dired here | `,Fd` netrw (`:Ex`) | |
| `,nt` neotree | `,nt` neo-tree | |
| `,ww` / `,wq` / `,qq` | same | |
| `,/` clear search hl | same | |
| `,nn` toggle line numbers | same | |
| `,wc` / `,wm` window close/main | same | |
| `,jl` avy line | EasyMotion `,jl` | also `,jw` / `,jc` |
| `,cl` comment lines | built-in `gcc`/`gc` | also `,cb` / `,cp` |
| `,Mp` Markdown Preview | same (macOS) | bookmarks stay on `,ml` / `,ms` / `,md` |
| `,ev` / `,sv` | edit / reload nvim options+keymaps | Emacs uses `,ee` / `,se` for emacs |
| `,jd` lsp definition | same | also default `grd` |
| `,fu` lsp references | same | also default `grr` |
| `,gst` magit status | Neogit | |
| `,gg` magit dispatch | Neogit floating | |
| `,gca` / `,gaa` / `,gpu`… | Magit-shaped git maps | uses Neogit + Fugitive `:Git` |
| `,fcn` / `,fcp` / `,fcl` / `,fcb` | diagnostic next/prev/list/refresh | |
| `,dw` delete trailing ws | same | |
| `,lt` truncate-lines toggle | `wrap!` | |
| `,kb` kill buffer | `Bclose` | keeps split |
| `,kr` kill-ring / yank history | Telescope `registers` | |
| `,ml` / `,ms` / `,md` bookmarks | named persistent bookmarks ([emacs-bookmarks.nvim](https://github.com/chadhs/emacs-bookmarks.nvim)) | `,mj` also jumps; stored in `stdpath('data')/bookmarks.json`; files open at position, dirs open netrw (`hijack_netrw_behavior = disabled`); native vim marks untouched |
| `,Pl` package list | `:Lazy` | |
| `,nc` / `,np` / `,nw` deft notes | Telescope in `~/notes/{common,personal,work}` | |
| `,fb` format buffer | Conform | was bare `,f` in the original kickstart base |
| `,sit` / `,sic` / `,sik` / `,sis` | text-case.nvim | |
| `,dd` dash-at-point | Dash.app (macOS) | |
| CIDER `,eb` / `,ef` / `,ri`… | Conjure (clojure ft) | |
| restclient `,ef` | kulala on `.http` | |

## Language / tooling map

| Emacs | Neovim |
| --- | --- |
| lsp-mode + company | mason + lspconfig + blink.cmp |
| flycheck | nvim-lint + vim.diagnostic |
| prettier / eslint / black / project-aware StandardRB or RuboCop / goimports | Conform + eslint LSP + mason tools |
| CIDER | Conjure |
| projectile + ivy/counsel | Telescope (`custom.root`: lcd to buffer/netrw dir; `,t` / `,gf` use git project) |
| envrc | direnv.vim |
| editorconfig | Neovim built-in (`vim.g.editorconfig`) |
| yasnippet | LuaSnip + friendly-snippets (+ optional `stdpath('config')/snippets`) |
| solarized + auto-dark | solarized.nvim + auto-dark-mode.nvim |
| org-mode | nvim-orgmode (basic) |
| deft | Telescope notes dirs |
| magit + diff-hl | Neogit + gitsigns |
| paredit / rainbow | nvim-paredit + rainbow-delimiters |
| `global-subword-mode` | nvim-spider (`w`/`e`/`b`/`ge`; `W`/`E`/`B` stay WORDs) |

### LSP servers enabled

`clangd`, `gopls`, `pyright`, `rust_analyzer`, `ts_ls`, `bashls`, `html`, `cssls`, `jsonls`, `yamlls`, `dockerls`, `eslint`, `lua_ls`, project-aware `solargraph` / `ruby_lsp`, `clojure_lsp`, `jdtls`, `elixirls`, `terraformls`, `graphql`

### Linters (nvim-lint)

`clj-kondo`, `shellcheck`, `cfn_lint`, and project-aware `standardrb` / `rubocop` — tools installed via Mason or the current Ruby bundle where available; `cfn-lint` / `clj-kondo` also come from the Brewfile on macOS. JS/TS diagnostics come from the eslint LSP (not nvim-lint).

### Ruby formatter and linter selection

Emacs and Neovim use the same project-aware rule for Ruby buffers. Starting at the buffer's directory and stopping at the Git root, the nearest `.standard.yml` or `.rubocop.yml` wins. Without either config, a direct `standard*` or `rubocop*` declaration in the nearest `Gemfile` / `gems.rb` selects the tool. Silent projects fall back to RuboCop. Bundled declarations run through `bundle exec`.

Formatting and diagnostics are disabled for a buffer when one directory contains both conventional config files or one manifest directly declares both formatter families. Files with other names, such as a command-specific `.rubocop_beep.yml`, do not select RuboCop.

Ruby language servers follow direct bundle declarations: `solargraph*` selects bundled Solargraph and `ruby-lsp*` selects bundled Ruby LSP. A project declaring neither uses global Solargraph under its `.ruby-version`; declaring both disables LSP for that buffer. Every Ruby subprocess runs through `utils/project-ruby-exec`, so Mason's Homebrew Ruby cannot write native extensions into another Ruby's gem home.

Reek is opt-in. It runs only when the nearest project directly declares the `reek` gem or contains `.reek.yml`; transitive installation alone does not enable it.

## Known gaps (intentionally thinner)

- **Perspectives** (`persp-*`): use tmux sessions/windows or Neovim tab pages for now
- **multi-term shell visor** (`,sv` in Emacs): keep using tmux; Neovim `,sv` reloads config
- **Full Org** agenda / pomodoro / Mac Mail links / HTML agenda export
- **Atomic Chrome**, **Dash** depth beyond macOS URL handler
- **aggressive-indent**, **column-enforce**, **typo-mode**
- **CIDER** test runners / clj-refactor — Conjure covers eval/doc; jack-in UX differs
- **lsp-java** project import polish — `jdtls` via Mason is the stand-in

## Optional trims (if you want a thinner config)

Everything below works and is tested; pull out only if you prefer less surface area:

| Piece | Why you might drop it |
| --- | --- |
| `orgmode` | Emacs remains the better Org daily driver; nvim-orgmode is basic |
| `kulala` | Only needed if you edit `.http` restclient files in nvim |
| `jdtls` / `elixirls` Mason servers | Heavy first-time installs if you rarely touch Java/Elixir in nvim |
| `text-case` (`,si*`) | Convenience; not needed for core edit/LSP/git flow |

## Quick verification

```sh
export XDG_CONFIG_HOME=/path/to/dotfiles/editors
export XDG_DATA_HOME=/tmp/nvim-test/share
export XDG_STATE_HOME=/tmp/nvim-test/state
export XDG_CACHE_HOME=/tmp/nvim-test/cache
nvim --headless "+Lazy! sync" "+qa"
nvim  # then try ,gst ,jd ,fu ,t ,gf ,nt
```
