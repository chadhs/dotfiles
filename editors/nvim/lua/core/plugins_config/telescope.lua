local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>Ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>t', builtin.git_files, {})
vim.keymap.set('n', '<leader>gf', builtin.live_grep, {})
