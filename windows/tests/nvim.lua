-- Run with nvim --headless -u NONE -l windows/tests/nvim.lua.
local root = vim.fs.normalize(vim.uv.cwd())
package.path = root .. '/editors/nvim/lua/?.lua;' .. package.path
vim.g.mapleader = ','
vim.g.maplocalleader = ','
local platform = require 'lib.platform'
assert(vim.fs.normalize(platform.repo):lower() == root:lower(), 'checkout discovery')
require 'options'
require 'keymaps'
require 'lib.root'
assert(vim.fn.isdirectory(vim.fs.joinpath(vim.fn.stdpath 'state', 'backup')) == 1, 'backup directory')
assert(vim.fn.maparg(',ev', 'n') ~= '', 'shared config edit binding')
assert(vim.fn.maparg(',sv', 'n') ~= '', 'shared config reload binding')
assert(vim.fn.maparg(',ww', 'n') ~= '', 'shared save binding')
local ruby = require 'lib.ruby_tooling'
local original = vim.fn.executable
vim.fn.executable = function(name)
  return name == ruby.command and 0 or original(name)
end
assert(#ruby.formatters(0) == 0, 'missing Ruby does not start a formatter')
assert(ruby.language_server(0) == nil, 'missing Ruby does not start a language server')
vim.fn.executable = original
local arguments = ruby.arguments { 'bundle', 'exec', 'rubocop' }
assert(arguments[#arguments] == 'rubocop', 'Ruby arguments keep the requested executable')
if vim.fn.has 'win32' == 1 then
  assert(arguments[1] == '-S', 'Windows Ruby finds gem launchers with -S')
  assert(platform.enabled_servers.ts_ls, 'Windows includes the shared JavaScript/TypeScript server')
end

for _, file in ipairs(vim.fn.glob(root .. '/editors/nvim/**/*.lua', false, true)) do
  assert(loadfile(file), file)
end
assert(loadfile(root .. '/windows/nvim/platform.lua'))
print 'PASS shared Neovim paths, options, keymaps, Ruby guard, and Lua syntax'
