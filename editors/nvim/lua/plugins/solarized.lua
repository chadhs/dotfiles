return {
  -- Solarized uses the OS light/dark preference on every platform.
  {
    'maxmx03/solarized.nvim',
    lazy = false,
    priority = 1000, -- load before UI plugins so they get correct colors
    opts = {},
    config = function(_, opts)
      vim.o.termguicolors = true
      require('solarized').setup(opts)
      vim.cmd.colorscheme 'solarized'
    end,
  },

  -- Cross-platform auto light/dark switching
  {
    'f-person/auto-dark-mode.nvim',
    lazy = false,
    priority = 999, -- after the colorscheme is available
    config = function()
      -- setup() already starts the watcher; do not call init() again.
      require('auto-dark-mode').setup {
        update_interval = 1000, -- checks once per second (safe and light)
        set_dark_mode = function()
          vim.o.background = 'dark'
          vim.cmd.colorscheme 'solarized'
        end,
        set_light_mode = function()
          vim.o.background = 'light'
          vim.cmd.colorscheme 'solarized'
        end,
      }
    end,
  },
}
