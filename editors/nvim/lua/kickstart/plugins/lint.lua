return {

  { -- Linting (Emacs flycheck parity — only enable tools we actually use)
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      local function exe(name)
        return vim.fn.executable(name) == 1
      end

      -- Clear noisy defaults; opt into Emacs-parity linters when present on PATH
      -- (Mason may install eslint_d/shellcheck/etc. later under stdpath data).
      local function mason_bin(name)
        return vim.fn.stdpath 'data' .. '/mason/bin/' .. name
      end
      local function available(name)
        return exe(name) or exe(mason_bin(name))
      end

      lint.linters_by_ft = {}

      if available 'clj-kondo' then
        lint.linters_by_ft.clojure = { 'clj-kondo' }
        lint.linters_by_ft.clojurescript = { 'clj-kondo' }
      end
      if available 'eslint_d' or available 'eslint' then
        local eslint = available 'eslint_d' and 'eslint_d' or 'eslint'
        lint.linters_by_ft.javascript = { eslint }
        lint.linters_by_ft.javascriptreact = { eslint }
        lint.linters_by_ft.typescript = { eslint }
        lint.linters_by_ft.typescriptreact = { eslint }
      end
      if available 'shellcheck' then
        lint.linters_by_ft.sh = { 'shellcheck' }
        lint.linters_by_ft.bash = { 'shellcheck' }
        lint.linters_by_ft.zsh = { 'shellcheck' }
      end
      if available 'rubocop' then
        lint.linters_by_ft.ruby = { 'rubocop' }
      end
      if available 'cfn-lint' then
        lint.linters_by_ft.cfn = { 'cfn_lint' }
      end

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
          if not vim.bo.modifiable then
            return
          end
          -- Never let a missing linter binary abort the autocmd chain
          pcall(lint.try_lint)
        end,
      })
    end,
  },
}
