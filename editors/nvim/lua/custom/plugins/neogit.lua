-- Magit-style Git UI (Neogit) with Emacs evil-leader keybinds
return {
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim',
      'nvim-telescope/telescope.nvim',
    },
    cmd = 'Neogit',
    keys = {
      {
        '<leader>gst',
        function()
          require('neogit').open()
        end,
        desc = 'Git status (Magit)',
      },
      {
        '<leader>gg',
        function()
          require('neogit').open { kind = 'floating' }
        end,
        desc = 'Git dispatch (Neogit)',
      },
      {
        '<leader>gd',
        function()
          vim.cmd 'DiffviewOpen'
        end,
        desc = 'Git diff working tree',
      },
      {
        '<leader>gco',
        function()
          require('telescope.builtin').git_branches()
        end,
        desc = 'Git checkout branch',
      },
      {
        '<leader>gcm',
        function()
          require('telescope.builtin').git_branches()
        end,
        desc = 'Git checkout branch',
      },
      {
        '<leader>gcb',
        function()
          vim.ui.input({ prompt = 'New branch: ' }, function(name)
            if name and name ~= '' then
              vim.fn.system { 'git', 'checkout', '-b', name }
              require('neogit').open()
            end
          end)
        end,
        desc = 'Git create and checkout branch',
      },
      {
        '<leader>gl',
        function()
          vim.cmd 'Git pull'
        end,
        desc = 'Git pull upstream',
      },
      {
        '<leader>gaa',
        function()
          vim.cmd 'Git add -u'
          vim.notify('Staged modified files', vim.log.levels.INFO)
        end,
        desc = 'Git stage modified',
      },
      {
        '<leader>grh',
        function()
          vim.cmd 'Git reset HEAD'
        end,
        desc = 'Git reset HEAD',
      },
      {
        '<leader>gca',
        function()
          require('neogit').open { 'commit' }
        end,
        desc = 'Git commit',
      },
      {
        '<leader>gpu',
        function()
          vim.cmd 'Git push -u'
        end,
        desc = 'Git push upstream',
      },
      {
        '<leader>gpp',
        function()
          vim.cmd 'Git push'
        end,
        desc = 'Git push remote',
      },
      {
        '<leader>gt',
        function()
          vim.ui.input({ prompt = 'Tag name: ' }, function(name)
            if name and name ~= '' then
              vim.fn.system { 'git', 'tag', name }
              vim.notify('Created tag ' .. name, vim.log.levels.INFO)
            end
          end)
        end,
        desc = 'Git tag',
      },
      {
        '<leader>gpt',
        function()
          vim.cmd 'Git push --tags'
        end,
        desc = 'Git push tags',
      },
    },
    opts = {
      integrations = {
        telescope = true,
        diffview = true,
      },
    },
  },
  {
    -- Fugitive provides :Git used by Magit-parity keybinds above
    'tpope/vim-fugitive',
    cmd = { 'Git', 'G', 'Gdiffsplit', 'Gread', 'Gwrite', 'Ggrep', 'GMove', 'GDelete' },
  },
}
