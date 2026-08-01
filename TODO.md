# TODO

## Neovim: gaps vs retired Vim/MacVim setup

Tracked after removing classic Vim/Vundle/MacVim in favor of Kickstart-based Neovim.
No changes required immediately; pursue as muscle memory or workflows demand.

### High-value keybinds / workflows to restore

- [ ] File/buffer pickers: old `,t` (CtrlP) / `,b` (CtrlPBuffer) → Telescope equivalents on `,` leader
- [ ] Project search: old `,gf` (Ack/`ag`) → Telescope live grep (familiar binding)
- [ ] File tree: old `,nt` (NERDTree) → enable neo-tree (already in kickstart, commented out) or keep `,Fd` netrw and document it
- [ ] Buffer close keeping split: old `bd` → `Bclose` behavior
- [ ] Save/quit shortcuts: `,ww` / `,wq` / `,qq`
- [ ] Edit/reload config: `,ev` / `,sv` for Neovim config
- [ ] Undo tree UI: old `,gu` (Gundo)
- [ ] EasyMotion-style jump: old `,jl` (still in IdeaVim)
- [ ] Split resize: `,` + arrow keys
- [ ] Toggle line numbers: `,nn`
- [ ] cwd helpers: `,cd` (file’s dir) / `,cds` (`~/src`)
- [ ] Marked 2 preview: `,m` (if still using Marked)
- [ ] Wrap-aware motion: `j`/`k` as `gj`/`gk`
- [ ] Fold toggle on `<space>` (vim used syntax folds, started collapsed)

### Plugins / behaviors to consider

- [ ] **vim-surround** (and ideally **vim-repeat**) — daily driver in old vimrc; confirm whether `mini` covers enough
- [ ] **Autopairs** — kickstart `autopairs` is commented out (old delimitMate; excluded clojure/lisp)
- [ ] **Rainbow parens** — used heavily for Lisp/Clojure
- [ ] Load **nvim-paredit** — `lua/custom/plugins/paredit.lua` exists but is not required from `lazy-plugins.lua`
- [ ] Narrow region (NrrwRgn) — only if you still miss that workflow
- [ ] visualstar — `*` over visual selection
- [ ] Org/Markdown/Ansible-specific plugins — only if treesitter/LSP feel thin vs old vim-orgmode / vim-markdown / ansible-vim

### Option / UX differences (optional)

- [ ] Mouse: old vim had mouse off; nvim enables `mouse=a` — decide intentional or not
- [ ] Restore cursor position on file reopen (vim `BufReadPost` jumplist autocmd)
- [ ] `hidden` / `autowrite` / fold defaults if you notice behavioral differences
- [ ] Align zoom key with old `,zw` vs current `<C-z>` if preferred

### Already covered (no action)

Solarized (+ auto light/dark), leader `,`, `,cl` comments, tmux navigator, Telescope/LSP/completion (ahead of CtrlP/Ack/Syntastic/VCM), split zoom via `<C-z>`, EditorConfig-ish indent via guess-indent.
