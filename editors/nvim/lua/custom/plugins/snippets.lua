-- Load personal + friendly snippets (Emacs yasnippet parity)
-- LuaSnip itself is owned by blink.cmp in auto-complete.lua; this only adds snippet sources.
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
      local personal = vim.fn.stdpath 'config' .. '/snippets'
      if vim.fn.isdirectory(personal) == 1 then
        snipmate.lazy_load { paths = { personal } }
      end
      local emacs_snip = vim.fn.expand '~/.emacs.d/snippets'
      if vim.fn.isdirectory(emacs_snip) == 1 then
        snipmate.lazy_load { paths = { emacs_snip } }
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
      local emacs_snip = vim.fn.expand '~/.emacs.d/snippets'
      if vim.fn.isdirectory(emacs_snip) == 1 then
        snipmate.lazy_load { paths = { emacs_snip } }
      end
    end,
  },
}
