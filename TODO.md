# TODO

## Neovim: gaps vs retired Vim/MacVim setup

Tracked after removing classic Vim/Vundle/MacVim in favor of Kickstart-based Neovim.
Restored in `editors/nvim` to match old vimrc / IdeaVim muscle memory.

### High-value keybinds / workflows to restore

- [x] File/buffer pickers: old `,t` (CtrlP) / `,b` (CtrlPBuffer) → Telescope `git_files` / `buffers`
- [x] Project search: old `,gf` (Ack/`ag`) → Telescope live grep
- [x] File tree: old `,nt` (NERDTree) → neo-tree toggle on `,nt` (right side; `,Fd` netrw kept)
- [x] Buffer close keeping split: `:bd` → `Bclose` (Lua implementation in `keymaps.lua`)
- [x] Save/quit shortcuts: `,ww` / `,wq` / `,qq`
- [x] Edit/reload config: `,ev` / `,sv` for Neovim config
- [x] Undo tree UI: old `,gu` (Gundo) → undotree
- [x] EasyMotion-style jump: old `,jl` (vim-easymotion, matches IdeaVim)
- [x] Split resize: `,` + arrow keys
- [x] Toggle line numbers: `,nn`
- [x] cwd helpers: `,cd` (file’s dir) / `,cds` (`~/src`)
- [x] Marked 2 preview: `,m` (macOS `open -a 'Marked 2.app'`)
- [x] Wrap-aware motion: `j`/`k` as `gj`/`gk`
- [x] Fold toggle on `<space>` (treesitter folds, `foldenable` off like old vim)

### Plugins / behaviors to consider

- [x] **Surround** — `mini.surround` with vim-surround-compatible maps (`ys`/`ds`/`cs`/`S`) + **vim-repeat**
- [x] **Autopairs** — kickstart `autopairs` enabled; disabled for clojure/lisp (and scheme/racket)
- [x] **Rainbow parens** — `rainbow-delimiters.nvim` (treesitter)
- [x] Load **nvim-paredit** — required from `lazy-plugins.lua` for lisp-family filetypes
- [ ] Narrow region (NrrwRgn) — deferred; only if you still miss that workflow
- [x] visualstar — `*` / `#` over visual selection (Lua in `keymaps.lua`)
- [ ] Org/Markdown/Ansible-specific plugins — deferred; treesitter/LSP cover the common case

### Option / UX differences (optional)

- [x] Mouse: off (`mouse=`), matching old vimrc
- [x] Restore cursor position on file reopen (`BufReadPost`)
- [x] `hidden` / `autowrite` / fold defaults restored
- [x] Zoom: keep `<C-z>` and restore old `,zw` alias

### Already covered (no action)

Solarized (+ auto light/dark), leader `,`, `,cl` comments, tmux navigator, Telescope/LSP/completion (ahead of CtrlP/Ack/Syntastic/VCM), split zoom via `<C-z>`, EditorConfig-ish indent via guess-indent.
