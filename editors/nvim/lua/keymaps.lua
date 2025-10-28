-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
-- vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

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
vim.keymap.set('n', '<C-z>', function()
  if zoomed then
    vim.cmd('wincmd =')
    zoomed = false
  else
    vim.cmd('wincmd |')
    vim.cmd('wincmd _')
    zoomed = true
  end
end, { desc = 'Zoom current split (toggle)' })

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

-- vim: ts=2 sts=2 sw=2 et

------------
-- CUSTOM --
------------
vim.keymap.set("n", "<leader>Fd", vim.cmd.Ex)
vim.keymap.set("n", "<leader>/", vim.cmd.nohlsearch)

-- Netrw: make ^ behave like 'u' (parent directory)
-- Some setups see netrw re-apply its own mappings after FileType runs.
-- To ensure our override sticks, (re)apply it on FileType and on BufWinEnter.
local netrw_group = vim.api.nvim_create_augroup("custom-netrw-keys", { clear = true })

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
  desc = "Netrw: remap ^ to u (parent directory)",
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

-- vimrc keybind to explore
--
-- vim.keymap.set("n", "<leader>nn" :set invnumber<CR>)
-- vim.keymap.set("n, <leader>gu :GundoToggle<CR>)
-- vim.keymap.set(", <leader>nt :NERDTreeToggle<CR>)
-- vim.keymap.set("n, <leader>zw :ZoomWin<CR>)
-- vim.keymap.set("n, <leader><UP> :resize +5<CR>)
-- vim.keymap.set("n, <leader><DOWN> :resize -5<CR>)
-- vim.keymap.set("n, <leader><LEFT> :vertical resize +5<CR>)
-- vim.keymap.set("n, <leader><RIGHT> :vertical resize -5<CR>)
