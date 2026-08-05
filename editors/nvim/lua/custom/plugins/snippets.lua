-- Load personal + friendly snippets (yasnippet-style parity without sharing Emacs dirs)
-- LuaSnip itself is also pulled in by blink.cmp in auto-complete.lua; this adds snippet sources.
return {
  {
    'rafamadriz/friendly-snippets',
    lazy = true,
    config = function()
      -- Loaded once LuaSnip is available (blink pulls it in on InsertEnter)
      local ok, loader = pcall(require, 'luasnip.loaders.from_vscode')
      if ok then
        loader.lazy_load()
      end
      local snipmate_ok, snipmate = pcall(require, 'luasnip.loaders.from_snipmate')
      if not snipmate_ok then
        return
      end
      -- Optional Neovim-local snippets only (not ~/.emacs.d/snippets)
      local personal = vim.fn.stdpath 'config' .. '/snippets'
      if vim.fn.isdirectory(personal) == 1 then
        snipmate.lazy_load { paths = { personal } }
      end
    end,
  },
  {
    -- Ensure LuaSnip loads friendly-snippets when completion starts
    'L3MON4D3/LuaSnip',
    dependencies = { 'rafamadriz/friendly-snippets' },
    event = 'InsertEnter',
    config = function()
      require('luasnip.loaders.from_vscode').lazy_load()
      local snipmate = require 'luasnip.loaders.from_snipmate'
      local personal = vim.fn.stdpath 'config' .. '/snippets'
      if vim.fn.isdirectory(personal) == 1 then
        snipmate.lazy_load { paths = { personal } }
      end
    end,
  },
}
