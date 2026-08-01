-- autopairs
-- https://github.com/windwp/nvim-autopairs
-- Replaces old delimitMate (excluded for clojure/lisp)

return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  opts = {
    disable_filetype = { 'TelescopePrompt', 'clojure', 'lisp', 'scheme', 'racket' },
  },
}
