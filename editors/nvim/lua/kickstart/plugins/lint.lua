return {

  { -- Linting (Emacs flycheck parity — only enable tools we actually use)
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      local ruby_tooling = require 'custom.ruby_tooling'

      local function exe(name)
        return vim.fn.executable(name) == 1
      end

      -- Clear noisy defaults; opt into Emacs-parity linters when present on PATH.
      -- JS/TS linting is the eslint LSP (not nvim-lint) to avoid duplicate diagnostics.
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
      if available 'shellcheck' then
        lint.linters_by_ft.sh = { 'shellcheck' }
        lint.linters_by_ft.bash = { 'shellcheck' }
        lint.linters_by_ft.zsh = { 'shellcheck' }
      end
      if available 'cfn-lint' then
        lint.linters_by_ft.cfn = { 'cfn_lint' }
      end

      local function project_linter(parent, executable, bundled)
        return function()
          local linter = vim.deepcopy(lint.linters[parent])
          linter.cmd = ruby_tooling.command
          local prefix = bundled and { 'bundle', 'exec', executable } or { executable }
          linter.args = vim.list_extend(prefix, linter.args)
          linter.ignore_exitcode = true
          return linter
        end
      end

      local function reek_linter(bundled)
        local prefix = bundled and { 'bundle', 'exec', 'reek' } or { 'reek' }
        return {
          cmd = ruby_tooling.command,
          args = vim.list_extend(prefix, {
            '--format',
            'json',
            function()
              return vim.api.nvim_buf_get_name(0)
            end,
          }),
          stdin = false,
          ignore_exitcode = true,
          parser = function(output)
            if output == '' then
              return {}
            end
            local ok, smells = pcall(vim.json.decode, output)
            if not ok or type(smells) ~= 'table' then
              return {}
            end
            local diagnostics = {}
            for _, smell in ipairs(smells) do
              local lines = smell.lines or {}
              local message = smell.message or 'Code smell'
              if smell.context and smell.context ~= '' then
                message = smell.context .. ': ' .. message
              end
              table.insert(diagnostics, {
                source = 'reek',
                code = smell.smell_type,
                message = message,
                severity = vim.diagnostic.severity.WARN,
                lnum = math.max((lines[1] or 1) - 1, 0),
                col = 0,
              })
            end
            return diagnostics
          end,
        }
      end

      lint.linters.standardrb_bundle = project_linter('standardrb', 'standardrb', true)
      lint.linters.rubocop_bundle = project_linter('rubocop', 'rubocop', true)
      lint.linters.standardrb_project = project_linter('standardrb', 'standardrb', false)
      lint.linters.rubocop_project = project_linter('rubocop', 'rubocop', false)
      lint.linters.reek_bundle = function()
        return reek_linter(true)
      end
      lint.linters.reek_project = function()
        return reek_linter(false)
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
          if vim.bo.filetype == 'ruby' then
            pcall(ruby_tooling.try_lint)
          else
            pcall(lint.try_lint)
          end
        end,
      })
    end,
  },
}
