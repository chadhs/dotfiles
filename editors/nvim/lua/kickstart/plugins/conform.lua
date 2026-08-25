local ruby_tooling = require 'custom.ruby_tooling'

local function ruby_project_root(_, ctx)
  return ruby_tooling.resolve(ctx.buf).root
end

local function format_options(bufnr, async)
  if vim.bo[bufnr].filetype == 'ruby' then
    if #ruby_tooling.formatters(bufnr) == 0 then
      return nil
    end
    return {
      async = async,
      timeout_ms = 5000,
      lsp_format = 'never',
    }
  end

  local disable_filetypes = { c = true, cpp = true }
  if disable_filetypes[vim.bo[bufnr].filetype] then
    return nil
  end
  return {
    async = async,
    timeout_ms = 1000,
    lsp_format = 'fallback',
  }
end

return {
  { -- Autoformat (Emacs prettier / goimports / project-aware Ruby / black parity)
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        -- Use ,fb so ,f* stays free for flycheck/find/format submaps (Emacs style)
        '<leader>fb',
        function()
          local opts = format_options(vim.api.nvim_get_current_buf(), true)
          if opts then
            require('conform').format(opts)
          end
        end,
        mode = '',
        desc = '[F]ormat [B]uffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        return format_options(bufnr, false)
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'isort', 'black' },
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        html = { 'prettierd', 'prettier', stop_after_first = true },
        css = { 'prettierd', 'prettier', stop_after_first = true },
        scss = { 'prettierd', 'prettier', stop_after_first = true },
        markdown = { 'prettierd', 'prettier', stop_after_first = true },
        yaml = { 'prettierd', 'prettier', stop_after_first = true },
        go = { 'goimports', 'gofmt' },
        ruby = function(bufnr)
          return ruby_tooling.formatters(bufnr)
        end,
        terraform = { 'terraform_fmt' },
      },
      formatters = {
        standardrb_bundle = {
          inherit = 'standardrb',
          command = ruby_tooling.command,
          prepend_args = { 'bundle', 'exec', 'standardrb' },
          cwd = ruby_project_root,
          require_cwd = true,
        },
        rubocop_bundle = {
          inherit = 'rubocop',
          command = ruby_tooling.command,
          prepend_args = { 'bundle', 'exec', 'rubocop' },
          cwd = ruby_project_root,
          require_cwd = true,
        },
        standardrb_project = {
          inherit = 'standardrb',
          command = ruby_tooling.command,
          prepend_args = { 'standardrb' },
          cwd = ruby_project_root,
          require_cwd = true,
        },
        rubocop_project = {
          inherit = 'rubocop',
          command = ruby_tooling.command,
          prepend_args = { 'rubocop' },
          cwd = ruby_project_root,
          require_cwd = true,
        },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
