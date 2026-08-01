-- Undo tree UI (replaces old Gundo `,gu`)
return {
  {
    'mbbill/undotree',
    keys = {
      { '<leader>gu', '<cmd>UndotreeToggle<CR>', desc = 'Toggle undo tree', silent = true },
    },
    config = function()
      vim.g.undotree_SetFocusWhenToggle = 1
      vim.g.undotree_WindowLayout = 2
    end,
  },
}
