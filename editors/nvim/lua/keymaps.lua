-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
-- vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps live under ,fc* (Emacs flycheck parity) so ,qq can quit immediately.

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
-- NOTE: Commented out explicit <C-h/j/k/l> window navigation mappings.
-- vim-tmux-navigator now owns these to enable seamless tmux/Nvim navigation.
-- vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
-- vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
-- vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
-- vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Split creation keybinds
vim.keymap.set('n', '<C-\\>', '<cmd>vsplit<CR>', { desc = 'Create vertical split' })
vim.keymap.set('n', '<C-->', '<cmd>split<CR>', { desc = 'Create horizontal split' })
vim.keymap.set('n', '<C-_>', '<cmd>split<CR>', { desc = 'Create horizontal split (underscore alias)' })

-- Zoom current split (toggle) - built-in Neovim
local zoomed = false
local function toggle_zoom()
  if zoomed then
    vim.cmd 'wincmd ='
    zoomed = false
  else
    vim.cmd 'wincmd |'
    vim.cmd 'wincmd _'
    zoomed = true
  end
end
vim.keymap.set('n', '<C-z>', toggle_zoom, { desc = 'Zoom current split (toggle)' })

-- Window management
vim.keymap.set('n', '<leader>wc', '<cmd>close<CR>', { desc = '[W]indow [C]lose' })
vim.keymap.set('n', '<leader>wm', '<cmd>only<CR>', { desc = '[W]indow [M]ake main (close others)' })

-- Alternative built-in zoom options
-- vim.keymap.set('n', '<C-x>', '<C-w>|', { desc = 'Zoom current split (maximize width)' })
-- vim.keymap.set('n', '<leader>uz', '<C-w>=', { desc = 'Unzoom (restore equal splits)' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Restore cursor position when reopening a file
vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Restore last cursor position',
  group = vim.api.nvim_create_augroup('custom-restore-cursor', { clear = true }),
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et

------------
-- CUSTOM --
------------
vim.keymap.set('n', '<leader>Fd', vim.cmd.Ex, { desc = 'Open netrw file explorer' })
vim.keymap.set('n', '<leader>/', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })

-- Save / quit shortcuts (old vimrc muscle memory)
vim.keymap.set('n', '<leader>ww', '<cmd>write<CR>', { desc = 'Write file' })
vim.keymap.set('n', '<leader>wq', '<cmd>wq<CR>', { desc = 'Write and quit' })
vim.keymap.set('n', '<leader>qq', '<cmd>quit<CR>', { desc = 'Quit' })

-- Edit / reload Neovim config
vim.keymap.set('n', '<leader>ev', function()
  vim.cmd.edit(vim.fn.stdpath 'config' .. '/init.lua')
end, { desc = 'Edit Neovim config' })
-- Reload options/keymaps only. Re-sourcing init.lua would re-run lazy.setup and break.
vim.keymap.set('n', '<leader>sv', function()
  local config = vim.fn.stdpath 'config'
  package.loaded['options'] = nil
  package.loaded['keymaps'] = nil
  dofile(config .. '/lua/options.lua')
  dofile(config .. '/lua/keymaps.lua')
  vim.notify('Reloaded options.lua + keymaps.lua (restart for plugin changes)', vim.log.levels.INFO)
end, { desc = 'Reload Neovim options/keymaps' })

-- Toggle line numbers
vim.keymap.set('n', '<leader>nn', '<cmd>set invnumber<CR>', { desc = 'Toggle line numbers' })

-- Zoom alias matching old ZoomWin binding (also available via <C-z>)
vim.keymap.set('n', '<leader>zw', toggle_zoom, { desc = 'Zoom current split (toggle)' })

-- Resize splits with leader + arrows
vim.keymap.set('n', '<leader><Up>', '<cmd>resize +5<CR>', { desc = 'Increase split height' })
vim.keymap.set('n', '<leader><Down>', '<cmd>resize -5<CR>', { desc = 'Decrease split height' })
vim.keymap.set('n', '<leader><Left>', '<cmd>vertical resize +5<CR>', { desc = 'Increase split width' })
vim.keymap.set('n', '<leader><Right>', '<cmd>vertical resize -5<CR>', { desc = 'Decrease split width' })

-- cwd helpers
vim.keymap.set('n', '<leader>cd', '<cmd>cd %:p:h<CR><cmd>pwd<CR>', { desc = "cd to current file's directory" })
vim.keymap.set('n', '<leader>cS', '<cmd>cd ~/src<CR><cmd>pwd<CR>', { desc = 'cd to ~/src' })

-- Preview current file in Marked 2 (macOS only) — Emacs markdown ,Mp
vim.keymap.set('n', '<leader>Mp', function()
  if vim.fn.has 'mac' == 0 and vim.fn.has 'macunix' == 0 then
    vim.notify('Marked 2 preview is only available on macOS', vim.log.levels.WARN)
    return
  end
  local path = vim.fn.expand '%:p'
  vim.fn.jobstart({ 'open', '-a', 'Marked 2.app', path }, { detach = true })
end, { desc = 'Preview in Marked 2' })

-- Display-line motion (Emacs visual-line-mode / evil-next-visual-line).
-- gj/gk walk screen lines, so j/k move through wraps instead of skipping them.
vim.keymap.set({ 'n', 'x', 'o' }, 'j', 'gj', { silent = true, desc = 'Down (display line)' })
vim.keymap.set({ 'n', 'x', 'o' }, 'k', 'gk', { silent = true, desc = 'Up (display line)' })
vim.keymap.set({ 'n', 'x', 'o' }, '<Down>', 'gj', { silent = true, desc = 'Down (display line)' })
vim.keymap.set({ 'n', 'x', 'o' }, '<Up>', 'gk', { silent = true, desc = 'Up (display line)' })

-- Fold toggle (matches old vim <space> za)
vim.keymap.set('n', '<Space>', function()
  local line = vim.fn.line '.'
  if vim.fn.foldlevel(line) == 0 then
    return
  end
  if vim.fn.foldclosed(line) == -1 then
    vim.cmd 'normal! zc'
  else
    vim.cmd 'normal! zo'
  end
end, { desc = 'Toggle fold', silent = true })

-- visualstar: * / # over a visual selection (old thinca/vim-visualstar)
local function visual_star(forward)
  local start_pos = vim.fn.getpos 'v'
  local end_pos = vim.fn.getpos '.'
  local start_row, start_col = start_pos[2], start_pos[3]
  local end_row, end_col = end_pos[2], end_pos[3]
  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  local lines = vim.api.nvim_buf_get_text(0, start_row - 1, start_col - 1, end_row - 1, end_col, {})
  local selected = table.concat(lines, '\n')
  if selected == '' then
    return
  end

  local pattern = '\\V' .. vim.fn.escape(selected, '\\'):gsub('\n', '\\n')
  vim.fn.setreg('/', pattern)
  vim.opt.hlsearch = true

  -- Exit visual mode, then jump to the next/previous match from the selection end.
  local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'nx', false)
  local flags = forward and 'W' or 'bW'
  if vim.fn.search(pattern, flags) == 0 then
    -- Wrap like normal n/N when wrapscan is set
    vim.fn.search(pattern, forward and 'w' or 'bw')
  end
end
vim.keymap.set('x', '*', function()
  visual_star(true)
end, { desc = 'Search forward for visual selection' })
vim.keymap.set('x', '#', function()
  visual_star(false)
end, { desc = 'Search backward for visual selection' })

-- Bclose: close buffer without destroying the split (old bclose.vim)
vim.api.nvim_create_user_command('Bclose', function()
  local current_buf = vim.api.nvim_get_current_buf()
  local alternate_buf = vim.fn.bufnr '#'

  if vim.fn.buflisted(alternate_buf) == 1 then
    vim.cmd 'buffer #'
  else
    vim.cmd 'bnext'
  end

  if vim.api.nvim_get_current_buf() == current_buf then
    vim.cmd 'enew'
  end

  if vim.fn.buflisted(current_buf) == 1 then
    vim.cmd('bdelete! ' .. current_buf)
  end
end, { desc = 'Close buffer without closing split' })

-- Make :bd use Bclose (keeps the split layout)
vim.cmd [[cnoreabbrev <expr> bd (getcmdtype() ==# ':' && getcmdline() ==# 'bd') ? 'Bclose' : 'bd']]

------------
-- EMACS PARITY KEYBINDS
-- Matching evil-leader maps from editors/emacs-config.org
------------

-- (k)ill (b)uffer without destroying the split
vim.keymap.set('n', '<leader>kb', '<cmd>Bclose<CR>', { desc = 'Kill buffer (keep split)' })

-- (d)elete trailing (w)hitespace
vim.keymap.set('n', '<leader>dw', function()
  local view = vim.fn.winsaveview()
  vim.cmd [[keeppatterns %s/\s\+$//e]]
  vim.fn.winrestview(view)
end, { desc = 'Delete trailing whitespace' })

-- (l)ine (t)runcate toggle (Emacs truncate-lines ↔ wrap)
vim.keymap.set('n', '<leader>lt', '<cmd>setlocal wrap!<CR>', { desc = 'Toggle line wrap/truncate' })

-- (k)ill-(r)ing / yank history
vim.keymap.set('n', '<leader>kr', function()
  require('telescope.builtin').registers()
end, { desc = 'Yank / register history' })

-- Bookmarks (Emacs bookmark-set / bookmark-jump / bookmark-delete parity).
-- Named, persistent bookmarks via custom.bookmarks; vim's native marks
-- (m a, ' a) are untouched and still work out of the box.
vim.keymap.set('n', '<leader>ms', function()
  require('custom.bookmarks').prompt_set()
end, { desc = 'Bookmark set' })
vim.keymap.set('n', '<leader>ml', function()
  require('custom.bookmarks').list()
end, { desc = 'Bookmark jump (list)' })
vim.keymap.set('n', '<leader>mj', function()
  require('custom.bookmarks').list()
end, { desc = 'Bookmark jump' })
vim.keymap.set('n', '<leader>md', function()
  require('custom.bookmarks').list { delete = true }
end, { desc = 'Bookmark delete' })

-- (P)ackage (l)ist → Lazy
vim.keymap.set('n', '<leader>Pl', '<cmd>Lazy<CR>', { desc = 'Package list (Lazy)' })
vim.keymap.set('n', '<leader>Pu', '<cmd>Lazy sync<CR>', { desc = 'Package update (Lazy sync)' })
vim.keymap.set('n', '<leader>Pi', '<cmd>Lazy install<CR>', { desc = 'Package install' })

-- Flycheck-shaped diagnostic maps
vim.keymap.set('n', '<leader>fcn', function()
  vim.diagnostic.jump { count = 1, float = true }
end, { desc = 'Diagnostic next' })
vim.keymap.set('n', '<leader>fcp', function()
  vim.diagnostic.jump { count = -1, float = true }
end, { desc = 'Diagnostic previous' })
vim.keymap.set('n', '<leader>fcl', vim.diagnostic.setloclist, { desc = 'Diagnostic list' })
vim.keymap.set('n', '<leader>fcb', function()
  vim.diagnostic.reset()
  if package.loaded['lint'] then
    require('lint').try_lint()
  end
  vim.cmd 'edit' -- nudge LSP refresh
  vim.notify('Diagnostics refreshed', vim.log.levels.INFO)
end, { desc = 'Diagnostic refresh buffer' })

-- Deft-shaped notes roots
local function notes_telescope(subdir)
  local root = vim.fn.expand('~/notes/' .. subdir)
  if vim.fn.isdirectory(root) == 0 then
    vim.notify('Notes dir missing: ' .. root, vim.log.levels.WARN)
    return
  end
  require('telescope.builtin').find_files { cwd = root, prompt_title = 'Notes: ' .. subdir }
end
vim.keymap.set('n', '<leader>nc', function()
  notes_telescope 'common'
end, { desc = 'Notes: common' })
vim.keymap.set('n', '<leader>np', function()
  notes_telescope 'personal'
end, { desc = 'Notes: personal' })
vim.keymap.set('n', '<leader>nw', function()
  notes_telescope 'work'
end, { desc = 'Notes: work' })
vim.keymap.set('n', '<leader>nf', function()
  local roots = {
    vim.fn.expand '~/notes/common',
    vim.fn.expand '~/notes/personal',
    vim.fn.expand '~/notes/work',
  }
  require('telescope.builtin').find_files {
    search_dirs = roots,
    prompt_title = 'Notes: all',
  }
end, { desc = 'Notes: find file' })

-- (d)ash (d)oc — macOS Dash.app
vim.keymap.set('n', '<leader>dd', function()
  if vim.fn.has 'mac' == 0 and vim.fn.has 'macunix' == 0 then
    vim.notify('Dash is only available on macOS', vim.log.levels.WARN)
    return
  end
  local word = vim.fn.expand '<cword>'
  if word == '' then
    return
  end
  vim.fn.jobstart({ 'open', 'dash://' .. word }, { detach = true })
end, { desc = 'Dash documentation' })

-- (d)escribe (v)ariable — Lua/help stand-in for Emacs describe-variable
vim.keymap.set('n', '<leader>dv', function()
  require('telescope.builtin').help_tags()
end, { desc = 'Describe / help tags' })

-- Comment line / selection / paragraph (evil-nerd-commenter ,cl / ,cb / ,cp)
-- Neovim 0.10+ built-in commenting (`gcc` / `gc` / `gb`); Comment.nvim is archived.
vim.keymap.set('n', '<leader>cl', 'gcc', { remap = true, silent = true, desc = 'Comment line' })
vim.keymap.set('x', '<leader>cl', 'gc', { remap = true, silent = true, desc = 'Comment selection' })
vim.keymap.set('n', '<leader>cb', 'gbc', { remap = true, silent = true, desc = 'Comment block' })
vim.keymap.set('x', '<leader>cb', 'gb', { remap = true, silent = true, desc = 'Comment block' })
vim.keymap.set('n', '<leader>cp', 'vipgc', {
  remap = true,
  silent = true,
  desc = 'Comment paragraph',
})

-- Clear / recenter screen (Emacs ,cs)
vim.keymap.set('n', '<leader>cs', 'zz', { desc = 'Clear / recenter screen' })

-- EditorConfig is built into Neovim 0.9+; ensure enabled
vim.g.editorconfig = true

-- Netrw: make ^ behave like 'u' (parent directory)
-- Some setups see netrw re-apply its own mappings after FileType runs.
-- To ensure our override sticks, (re)apply it on FileType and on BufWinEnter.
local netrw_group = vim.api.nvim_create_augroup('custom-netrw-keys', { clear = true })

local function set_netrw_parent_map(buf)
  -- Remove any existing mapping for ^ in this buffer, then map to 'u'
  pcall(vim.keymap.del, 'n', '^', { buffer = buf })
  vim.keymap.set('n', '^', '-', {
    buffer = buf,
    remap = true, -- leverage netrw's own mapping for '-' (parent dir)
    silent = true,
    desc = 'Netrw: go up one directory',
  })
end

-- When the netrw filetype is set, schedule our mapping so it runs after netrw's mappings
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Netrw: remap ^ to u (parent directory)',
  group = netrw_group,
  pattern = 'netrw',
  callback = function(args)
    vim.schedule(function()
      set_netrw_parent_map(args.buf)
    end)
  end,
})

-- Also re-apply when (re)entering a netrw window to beat late remaps
vim.api.nvim_create_autocmd('BufWinEnter', {
  group = netrw_group,
  callback = function(args)
    if vim.bo[args.buf].filetype == 'netrw' then
      set_netrw_parent_map(args.buf)
    end
  end,
})
