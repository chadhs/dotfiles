-- Structural editing for Lisp/Clojure (nvim-paredit)
return {
  {
    'julienvincent/nvim-paredit',
    ft = { 'clojure', 'lisp', 'scheme', 'racket', 'fennel' },
    config = function()
      require('nvim-paredit').setup()
    end,
  },
}
