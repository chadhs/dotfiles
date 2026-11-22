return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    -- main is required on Neovim 0.12+; master is frozen and crashes on markdown injections
    branch = 'main',
    lazy = false,
    -- Do not use build = ':TSUpdate'. That command is the old master installer and
    -- clones parsers into stdpath('data') (the gitignore mv error on :Lazy update).
    config = function()
      -- [[ Configure Treesitter ]] See `:help nvim-treesitter-intro`
      -- Highlighting/folds/indent are Neovim builtins; this plugin only installs parsers + queries.
      local ts = require 'nvim-treesitter'
      if type(ts.install) ~= 'function' then
        vim.notify(
          'nvim-treesitter is still on the old master API. In :Lazy, press x on nvim-treesitter, then S to reinstall from main, and restart.',
          vim.log.levels.ERROR
        )
        return
      end

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
      local wanted = {}
      parsers = require('lib.platform').parsers or parsers
      for _, lang in ipairs(parsers) do
        wanted[lang] = true
      end
      local can_install = vim.fn.executable 'tree-sitter' == 1
        and (vim.fn.executable 'cc' == 1 or vim.fn.executable 'gcc' == 1 or vim.fn.executable 'clang' == 1 or vim.fn.executable 'cl' == 1)
      if can_install then
        ts.install(parsers)
      end

      -- Ruby indent is still more reliable with vim's regex indent (same as the old master config).
      local disable_indent = { ruby = true }

      ---@param buf integer
      ---@param language string
      local function treesitter_try_attach(buf, language)
        local ok, added = pcall(vim.treesitter.language.add, language)
        if not ok or not added then
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
        group = vim.api.nvim_create_augroup('treesitter-highlight-activations', { clear = true }),
        callback = function(args)
          local buf, filetype = args.buf, args.match
          local language = vim.treesitter.language.get_lang(filetype)
          if not language then
            return
          end

          local installed_ok, installed = pcall(ts.get_installed, 'parsers')
          if installed_ok and vim.tbl_contains(installed, language) then
            treesitter_try_attach(buf, language)
            return
          end

          -- Only fetch parsers we opted into (not every filetype, e.g. gitignore).
          if wanted[language] and can_install then
            ts.install(language):await(function()
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
