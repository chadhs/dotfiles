-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim
-- Replaces old NERDTree (`,nt`)

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '<leader>nt', '<cmd>Neotree toggle<CR>', desc = 'Toggle neo-tree', silent = true },
    { '\\', '<cmd>Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    filesystem = {
      window = {
        position = 'right', -- match old NERDTreeWinPos = "right"
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
}
