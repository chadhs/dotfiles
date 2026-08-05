-- Load project .envrc (Emacs envrc-mode parity)
-- Only enable when direnv is on PATH (Brewfile installs it on Mac).
return {
  {
    'direnv/direnv.vim',
    lazy = false,
    cond = function()
      return vim.fn.executable 'direnv' == 1
    end,
  },
}
