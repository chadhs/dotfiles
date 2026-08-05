return {

  { -- Linting (Emacs flycheck parity — only enable tools we actually use)
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      -- Clear noisy defaults; opt into Emacs-parity linters explicitly
      lint.linters_by_ft = {
        clojure = { 'clj-kondo' },
        clojurescript = { 'clj-kondo' },
        javascript = { 'eslint_d' },
        javascriptreact = { 'eslint_d' },
        typescript = { 'eslint_d' },
        typescriptreact = { 'eslint_d' },
        sh = { 'shellcheck' },
        bash = { 'shellcheck' },
        zsh = { 'shellcheck' },
        ruby = { 'rubocop' },
        -- CloudFormation (cfn-lint from Brewfile); filetype set via autocmd below
        cfn = { 'cfn_lint' },
      }

      -- Detect CloudFormation templates (Emacs cfn-yaml-mode / cfn-json-mode)
      vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
        pattern = { '*.yaml', '*.yml', '*.json' },
        callback = function(args)
          local path = args.file
          if path == '' then
            return
          end
          local ok, lines = pcall(vim.fn.readfile, path, '', 20)
          if not ok then
            return
          end
          local head = table.concat(lines, '\n')
          if head:find 'AWSTemplateFormatVersion' then
            vim.bo[args.buf].filetype = 'cfn'
          end
        end,
      })

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          if vim.bo.modifiable then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
