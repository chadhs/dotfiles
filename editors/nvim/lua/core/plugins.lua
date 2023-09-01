local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  "folke/which-key.nvim",
  "ishan9299/nvim-solarized-lua",
  {
    "nvim-telescope/telescope.nvim", tag = "0.1.2",
    dependencies = { {"nvim-lua/plenary.nvim"} },
  },
  {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
  {
    "julienvincent/nvim-paredit",
    config = function()
      require("nvim-paredit").setup()
    end
  },
  {
    'numToStr/Comment.nvim',
    opts = {},
    lazy = false,
  },
  { 'echasnovski/mini.nvim', version = false },
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v2.x',
    dependencies = {
      -- LSP Support
      {'neovim/nvim-lspconfig'},             -- Required
      {'williamboman/mason.nvim'},           -- Optional
      {'williamboman/mason-lspconfig.nvim'}, -- Optional

      -- Autocompletion
      {'hrsh7th/nvim-cmp'},     -- Required
      {'hrsh7th/cmp-nvim-lsp'}, -- Required
      {'L3MON4D3/LuaSnip'},     -- Required
    }
  },
}

local opts = {}

require("lazy").setup(plugins, opts)
