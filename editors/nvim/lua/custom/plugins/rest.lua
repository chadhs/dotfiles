-- REST client for .http files (Emacs restclient-mode parity)
return {
  {
    'mistweaverco/kulala.nvim',
    ft = { 'http', 'rest' },
    keys = {
      { '<leader>ef', function() require('kulala').run() end, desc = 'REST: send request', ft = { 'http', 'rest' } },
    },
    opts = {
      global_keymaps = false,
      kulala_keymaps = true,
    },
    config = function(_, opts)
      require('kulala').setup(opts)
      vim.filetype.add {
        extension = {
          http = 'http',
        },
      }
    end,
  },
}
