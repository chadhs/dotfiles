-- On omarchy, the theme adapter (theme.lua, which loads the spec omarchy
-- regenerates in its state dir) owns the colorscheme and hot-reload; this
-- file stays mac-only. The state file never exists on darwin, so behavior
-- there is unchanged.
if vim.fn.filereadable(vim.fn.expand('~/.local/state/omarchy/current/theme/neovim.lua')) == 1 then
  return {}
end

return {
  -- 1) Solarized (one name: "solarized", switches with :set background=light/dark)

  -- -- option 1 for solarized
  --  {
  --    "ishan9299/nvim-solarized-lua",
  --    lazy = false,
  --    priority = 1000, -- load before UI plugins so they get correct colors
  --  },

  -- -- option 2 for solarized
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

  -- 2) Cross-platform auto light/dark switching
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
