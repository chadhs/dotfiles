return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    -- main is required on Neovim 0.12+; master is frozen and crashes on markdown injections
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      -- [[ Configure Treesitter ]] See `:help nvim-treesitter-intro`
      -- Highlighting/folds/indent are Neovim builtins; this plugin only installs parsers + queries.
      local parsers = {
        'bash',
        'c',
        'clojure',
        'cpp',
        'css',
        'diff',
        'dockerfile',
        'elixir',
        'go',
        'graphql',
        'html',
        'java',
        'javascript',
        'json',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'ruby',
        'rust',
        'scss',
        'terraform',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
      }
      require('nvim-treesitter').install(parsers)

      -- Ruby indent is still more reliable with vim's regex indent (same as the old master config).
      local disable_indent = { ruby = true }

      ---@param buf integer
      ---@param language string
      local function treesitter_try_attach(buf, language)
        if not vim.treesitter.language.add(language) then
          return
        end
        vim.treesitter.start(buf, language)

        if disable_indent[language] then
          return
        end
        local ok, query = pcall(vim.treesitter.query.get, language, 'indents')
        if ok and query ~= nil then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('kickstart-treesitter', { clear = true }),
        callback = function(args)
          local buf, filetype = args.buf, args.match
          local language = vim.treesitter.language.get_lang(filetype)
          if not language then
            return
          end

          local installed_ok, installed = pcall(require('nvim-treesitter').get_installed, 'parsers')
          if installed_ok and vim.tbl_contains(installed, language) then
            treesitter_try_attach(buf, language)
            return
          end

          local available = require('nvim-treesitter').get_available()
          if vim.tbl_contains(available, language) then
            require('nvim-treesitter').install(language):await(function()
              treesitter_try_attach(buf, language)
            end)
          else
            treesitter_try_attach(buf, language)
          end
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
