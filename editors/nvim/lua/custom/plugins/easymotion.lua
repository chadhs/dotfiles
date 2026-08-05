-- EasyMotion jumps matching Emacs avy maps (,jl / ,jw / ,jc)
return {
  {
    'easymotion/vim-easymotion',
    keys = {
      -- remap=true required so <Plug> maps resolve
      { '<leader>jl', '<Plug>(easymotion-bd-jk)', desc = 'EasyMotion jump to line', mode = { 'n', 'x', 'o' }, remap = true },
      { '<leader>jw', '<Plug>(easymotion-bd-w)', desc = 'EasyMotion jump to word', mode = { 'n', 'x', 'o' }, remap = true },
      { '<leader>jc', '<Plug>(easymotion-bd-f)', desc = 'EasyMotion jump to char', mode = { 'n', 'x', 'o' }, remap = true },
    },
    init = function()
      -- Disable default EasyMotion mappings; we only want explicit leader maps
      vim.g.EasyMotion_do_mapping = 0
    end,
  },
}
