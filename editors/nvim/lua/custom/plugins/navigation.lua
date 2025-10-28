-- Navigation plugins for seamless tmux and Neovim integration

return {
  -- Seamless navigation between tmux and (Neo)vim splits
  'christoomey/vim-tmux-navigator',
  init = function()
    -- Disable default mappings before plugin loads
    vim.g.tmux_navigator_no_mappings = 1
  end,
  config = function()
    -- Set up our own navigation mappings (excluding C-\)
    vim.keymap.set('n', '<C-h>', ':<C-U>TmuxNavigateLeft<CR>', { desc = 'Navigate left' })
    vim.keymap.set('n', '<C-j>', ':<C-U>TmuxNavigateDown<CR>', { desc = 'Navigate down' })
    vim.keymap.set('n', '<C-k>', ':<C-U>TmuxNavigateUp<CR>', { desc = 'Navigate up' })
    vim.keymap.set('n', '<C-l>', ':<C-U>TmuxNavigateRight<CR>', { desc = 'Navigate right' })
    vim.keymap.set('n', '<C-p>', ':<C-U>TmuxNavigatePrevious<CR>', { desc = 'Navigate to previous pane' })
  end,
}