-- Load personal + friendly snippets (yasnippet-style parity without sharing Emacs dirs)
-- LuaSnip is also pulled in by blink.cmp; this spec owns snippet loading so it happens once.
return {
  {
    'L3MON4D3/LuaSnip',
    dependencies = { 'rafamadriz/friendly-snippets' },
    event = 'InsertEnter',
    config = function()
      require('luasnip.loaders.from_vscode').lazy_load()
      local personal = vim.fn.stdpath 'config' .. '/snippets'
      if vim.fn.isdirectory(personal) == 1 then
        require('luasnip.loaders.from_snipmate').lazy_load { paths = { personal } }
      end
    end,
  },
}
