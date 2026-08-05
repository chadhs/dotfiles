-- Clojure/Lisp REPL — Conjure as CIDER stand-in
-- Localleader is `,` (same as Emacs evil-leader), so Conjure maps stay familiar.
return {
  {
    'Olical/conjure',
    ft = { 'clojure', 'fennel', 'janet', 'racket', 'scheme', 'lisp', 'hy' },
    init = function()
      -- Keep Conjure on localleader (`,`) like Emacs CIDER leader maps
      vim.g['conjure#mapping#prefix'] = ','
      -- Prefer HUD + log without stealing focus on connect
      vim.g['conjure#log#hud#enabled'] = true
      vim.g['conjure#log#wrap'] = true
      -- Clojure: jack-in helpers via vim-jack-in / fireplace are optional;
      -- document `,ri` style binds via which-key aliases below.
    end,
    config = function()
      -- Emacs CIDER-shaped aliases (buffer-local when Conjure attaches)
      local group = vim.api.nvim_create_augroup('emacs-parity-conjure', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = { 'clojure', 'fennel', 'janet', 'racket', 'scheme', 'lisp', 'hy' },
        callback = function(args)
          local opts = { buffer = args.buf, silent = true }
          -- (r)epl (i)nit / connect — Conjure auto-connects; this focuses log
          vim.keymap.set('n', '<leader>ri', '<cmd>ConjureLogVSplit<CR>', vim.tbl_extend('force', opts, { desc = 'REPL: open log' }))
          vim.keymap.set('n', '<leader>rq', '<cmd>ConjureClientStateReset<CR>', vim.tbl_extend('force', opts, { desc = 'REPL: reset client' }))
          -- Eval aliases matching CIDER
          vim.keymap.set('n', '<leader>eb', '<cmd>ConjureEvalBuf<CR>', vim.tbl_extend('force', opts, { desc = 'Eval buffer' }))
          vim.keymap.set('n', '<leader>ef', '<cmd>ConjureEvalCurrentForm<CR>', vim.tbl_extend('force', opts, { desc = 'Eval form' }))
          vim.keymap.set('n', '<leader>es', '<cmd>ConjureEvalCurrentForm<CR>', vim.tbl_extend('force', opts, { desc = 'Eval sexp' }))
          vim.keymap.set('n', '<leader>rb', '<cmd>ConjureLogVSplit<CR>', vim.tbl_extend('force', opts, { desc = 'REPL buffer' }))
          vim.keymap.set('n', '<leader>ds', '<cmd>ConjureDocWord<CR>', vim.tbl_extend('force', opts, { desc = 'Doc under cursor' }))
        end,
      })
    end,
  },
}
