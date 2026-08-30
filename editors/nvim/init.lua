-- Personal Neovim configuration (chadhs)
--
-- Derived from kickstart.nvim (MIT) — see LICENSE.md and README.md.
--
-- Layout:
--   lua/options.lua      editor options
--   lua/keymaps.lua      base keymaps + autocmds
--   lua/lib/             own library modules (project root, Ruby tooling, health)
--   lua/plugins/*.lua    one lazy.nvim spec per plugin (auto-imported)
--   editors/nvim/EMACS-PARITY.md   keybind/tooling map vs the Emacs config

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false

-- [[ Setting options ]]
require 'options'

-- [[ Basic Keymaps + autocmds ]]
require 'keymaps'

-- [[ Buffer/netrw directory (lcd for :e; ,t / ,gf use git project) ]]
require 'lib.root'

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end
---@type vim.Option
vim.opt.rtp:prepend(lazypath)

-- [[ Load plugins ]]
-- `setup('plugins')` auto-imports every spec in lua/plugins/*.lua —
-- drop a file there and it loads. See `:help lazy.nvim-🔌-plugin-spec`
require('lazy').setup('plugins', {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
  change_detection = {
    -- omarchy theme switches rewrite the state file aether's hotreload
    -- watcher watches, and aether's reload path re-runs lazy's reloader,
    -- which would pop this notification on every theme change; theme
    -- reloads are handled silently by plugins/theme.lua + aether
    notify = false,
  },
})

-- vim: ts=2 sts=2 sw=2 et
