-- Source paths and defaults shared by terminal and GUI launches.
local M = {}
local source = vim.uv.fs_realpath(debug.getinfo(1, 'S').source:sub(2))
M.config = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(source)))
M.repo = vim.fs.dirname(vim.fs.dirname(M.config))
M.home = vim.fn.expand '~'
M.font = vim.uv.os_uname().sysname == 'Darwin' and 'Menlo:h14' or 'JetBrainsMono Nerd Font:h14'
M.ruby_command = vim.fs.joinpath(M.repo, 'utils/project-ruby-exec')
M.ruby_args = {}

if vim.fn.has 'win32' == 1 then
  dofile(vim.fs.joinpath(M.repo, 'windows/nvim/platform.lua'))(M)
end

M.src = vim.env.DOTFILES_SRC or M.src or vim.fs.joinpath(M.home, 'src')
M.notes = vim.env.DOTFILES_NOTES or vim.fs.joinpath(M.home, 'notes')
M.org = vim.env.DOTFILES_ORG or vim.fs.joinpath(M.home, 'org')

local local_config = vim.fs.joinpath(vim.fn.stdpath 'config', 'local.lua')
if vim.fn.filereadable(local_config) == 1 then
  M = vim.tbl_extend('force', M, dofile(local_config) or {})
end

return M
