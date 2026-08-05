# Emacs → Neovim feature parity

Goal: open Neovim and operate with the same muscle memory as `editors/emacs-config.org` (`,` leader, language tooling, git, navigation).

This is intentionally **not** a full Emacs reimplementation. Org agenda depth, multi-term shell visor, and perspectives are thinner or deferred in favor of tmux + Neovim-native tools.

## Shared muscle memory

| Emacs (evil-leader `,`) | Neovim | Notes |
| --- | --- | --- |
| `,t` project file | `,t` Telescope git files | |
| `,b` buffer switch | `,b` Telescope buffers | |
| `,gf` project grep | `,gf` Telescope live_grep | |
| `,Ff` find file | `,Ff` Telescope find_files | |
| `,Fd` dired here | `,Fd` netrw (`:Ex`) | |
| `,nt` neotree | `,nt` neo-tree | |
| `,ww` / `,wq` / `,qq` | same | |
| `,/` clear search hl | same | |
| `,nn` toggle line numbers | same | |
| `,wc` / `,wm` window close/main | same | |
| `,jl` avy line | EasyMotion `,jl` | also `,jw` / `,jc` |
| `,cl` comment lines | Comment.nvim | |
| `,m` Marked preview | same (macOS) | |
| `,ev` / `,sv` | edit / reload nvim options+keymaps | Emacs uses `,ee` / `,se` for emacs |
| `,jd` lsp definition | same | also kickstart `grd` |
| `,fu` lsp references | same | also kickstart `grr` |
| `,gst` magit status | Neogit | |
| `,gg` magit dispatch | Neogit floating | |
| `,gca` / `,gaa` / `,gpu`… | Magit-shaped git maps | uses Neogit + Fugitive `:Git` |
| `,fcn` / `,fcp` / `,fcl` / `,fcb` | diagnostic next/prev/list/refresh | |
| `,dw` delete trailing ws | same | |
| `,lt` truncate-lines toggle | `wrap!` | |
| `,kb` kill buffer | `Bclose` | keeps split |
| `,kr` kill-ring / yank history | Telescope `registers` | |
| `,ml` / `,ms` / `,md` bookmarks | Telescope marks + `:mark` / `:delmarks` | |
| `,Pl` package list | `:Lazy` | |
| `,nc` / `,np` / `,nw` deft notes | Telescope in `~/notes/{common,personal,work}` | |
| `,fb` format buffer | Conform | was bare `,f` in stock Kickstart |
| `,sit` / `,sic` / `,sik` / `,sis` | text-case.nvim | |
| `,dd` dash-at-point | Dash.app (macOS) | |
| CIDER `,eb` / `,ef` / `,ri`… | Conjure (clojure ft) | |
| restclient `,ef` | kulala on `.http` | |

## Language / tooling map

| Emacs | Neovim |
| --- | --- |
| lsp-mode + company | mason + lspconfig + blink.cmp |
| flycheck | nvim-lint + vim.diagnostic |
| prettier / eslint / black / rubocop / goimports | Conform + eslint LSP + mason tools |
| CIDER | Conjure |
| projectile + ivy/counsel | Telescope (+ git root) |
| envrc | direnv.vim |
| editorconfig | Neovim built-in (`vim.g.editorconfig`) |
| yasnippet | LuaSnip + friendly-snippets (+ Emacs snipmate dirs if present) |
| solarized + auto-dark | solarized.nvim + auto-dark-mode.nvim |
| org-mode | nvim-orgmode (basic) |
| deft | Telescope notes dirs |
| magit + diff-hl | Neogit + gitsigns |
| paredit / rainbow | nvim-paredit + rainbow-delimiters |

### LSP servers enabled

`clangd`, `gopls`, `pyright`, `rust_analyzer`, `ts_ls`, `bashls`, `html`, `cssls`, `jsonls`, `yamlls`, `dockerls`, `eslint`, `lua_ls`, `ruby_lsp`, `clojure_lsp`, `jdtls`, `elixirls`, `terraformls`, `graphql`

### Linters (nvim-lint)

`eslint_d` (js/ts), `clj-kondo`, `shellcheck`, `cfn_lint`, `rubocop` — tools installed via Mason where available; `cfn-lint` / `clj-kondo` also come from the Brewfile on macOS.

## Known gaps (intentionally thinner)

- **Perspectives** (`persp-*`): use tmux sessions/windows or Neovim tab pages for now
- **multi-term shell visor** (`,sv` in Emacs): keep using tmux; Neovim `,sv` reloads config
- **Full Org** agenda / pomodoro / Mac Mail links / HTML agenda export
- **Atomic Chrome**, **Dash** depth beyond macOS URL handler
- **aggressive-indent**, **column-enforce**, **typo-mode**
- **CIDER** test runners / clj-refactor — Conjure covers eval/doc; jack-in UX differs
- **lsp-java** project import polish — `jdtls` via Mason is the stand-in

## Quick verification

```sh
export XDG_CONFIG_HOME=/path/to/dotfiles/editors
export XDG_DATA_HOME=/tmp/nvim-test/share
export XDG_STATE_HOME=/tmp/nvim-test/state
export XDG_CACHE_HOME=/tmp/nvim-test/cache
nvim --headless "+Lazy! sync" "+qa"
nvim  # then try ,gst ,jd ,fu ,t ,gf ,nt
```
