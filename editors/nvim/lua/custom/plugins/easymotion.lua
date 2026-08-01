-- EasyMotion-style line jump (matches IdeaVim `,jl` and old vimrc)
return {
  {
    'easymotion/vim-easymotion',
    keys = {
      -- remap=true required so <Plug> maps resolve
      { '<leader>jl', '<Plug>(easymotion-bd-jk)', desc = 'EasyMotion jump to line', mode = { 'n', 'x', 'o' }, remap = true },
    },
    init = function()
      -- Disable default EasyMotion mappings; we only want `,jl`
      vim.g.EasyMotion_do_mapping = 0
    end,
  },
}
