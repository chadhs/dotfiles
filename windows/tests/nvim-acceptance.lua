-- Run after plugin, Mason, and parser installation with the deployed config.
local platform = require 'lib.platform'
local root = assert(vim.env.DOTFILES_TEST_ROOT, 'Set DOTFILES_TEST_ROOT to a disposable test directory')
root = vim.fs.normalize(root)
vim.fn.mkdir(root, 'p')

local function write(name, lines)
  local file = vim.fs.joinpath(root, name)
  vim.fn.writefile(lines, file)
  return file
end

local function check(condition, message)
  assert(condition, message)
  print('PASS ' .. message)
end

local function command(args)
  local result = vim.system(args, { cwd = root, text = true }):wait(30000)
  assert(result.code == 0, result.stderr)
  return result.stdout
end

local function edit(file)
  vim.cmd.edit(vim.fn.fnameescape(file))
  return vim.api.nvim_get_current_buf()
end

local function client_for(buf, name)
  check(
    vim.wait(60000, function()
      local clients = vim.lsp.get_clients { bufnr = buf, name = name }
      return #clients > 0 and clients[1].initialized
    end, 100),
    name .. ' attaches'
  )
  return vim.lsp.get_clients({ bufnr = buf, name = name })[1]
end

command { 'git', 'init', '--quiet', root }
write('package.json', { '{"private":true,"devDependencies":{"eslint":"*","prettier":"*"}}' })
write('tsconfig.json', { '{"compilerOptions":{"strict":true,"noEmit":true,"allowJs":true},"include":["*.ts","*.js"]}' })
write('.prettierrc.json', { '{"singleQuote":true}' })
write('eslint.config.cjs', {
  'module.exports = [{files: ["**/*.js"], rules: {"no-unused-vars": "error"}}];',
})
local ts = write('example.ts', {
  'export function greet(name: string): string { return `Hello ${name}`; }',
  'const message: string = greet("Windows");',
  'const broken: number = "wrong";',
})
local js = write('example.js', { 'const unused = 1;', 'console.log("Windows");' })
local lua = write('example.lua', { 'local result={value=42}', 'print(result.value)' })
local markdown = write('example.md', { '# Windows', '', 'Shared configuration acceptance test.' })
local org = write('example.org', { '* TODO Verify Windows editors', 'An Org heading.' })
command { 'git', 'add', '--', '.' }

check(vim.g.colors_name == 'solarized', 'shared Solarized theme')
for _, lang in ipairs(platform.parsers or {}) do
  check(vim.treesitter.language.add(lang), lang .. ' parser loads')
end
for _, tool in ipairs { 'node', 'git', 'rg', 'fd', 'prettier', 'typescript-language-server' } do
  check(vim.fn.executable(tool) == 1, tool .. ' is available to the editor')
end

local buf = edit(ts)
local client = client_for(buf, 'ts_ls')
check(
  vim.wait(30000, function()
    return #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR }) > 0
  end, 100),
  'TypeScript reports a type error'
)
local definition = client:request_sync('textDocument/definition', {
  textDocument = { uri = vim.uri_from_bufnr(buf) },
  position = { line = 1, character = 26 },
}, 30000, buf)
check(definition and definition.result and #definition.result > 0, 'TypeScript definition navigation')
local completion = client:request_sync('textDocument/completion', {
  textDocument = { uri = vim.uri_from_bufnr(buf) },
  position = { line = 1, character = 25 },
}, 30000, buf)
check(completion and completion.result ~= nil, 'TypeScript completion request')
check(vim.fn.maparg(',jd', 'n') ~= '', 'shared definition keybinding')
require('conform').format { bufnr = buf, async = false, timeout_ms = 10000, lsp_format = 'never' }
check(
  table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n'):find("greet('Windows')", 1, true),
  'Prettier formats TypeScript through the native npm launcher'
)
vim.cmd.write()

buf = edit(js)
client_for(buf, 'eslint')
check(
  vim.wait(30000, function()
    return vim.iter(vim.diagnostic.get(buf)):any(function(item)
      return item.message:find('unused', 1, true) ~= nil
    end)
  end, 100),
  'ESLint reports an unused JavaScript variable'
)

buf = edit(lua)
client_for(buf, 'lua_ls')
require('conform').format { bufnr = buf, async = false, timeout_ms = 10000, lsp_format = 'never' }
check(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]:find('local result = ', 1, true), 'StyLua formats Lua')
vim.cmd.write()

buf = edit(markdown)
check(vim.bo[buf].filetype == 'markdown', 'Markdown editing')
check(vim.treesitter.get_parser(buf):parse()[1] ~= nil, 'Markdown syntax parsing')
buf = edit(org)
check(vim.bo[buf].filetype == 'org', 'Org editing')
check(require 'orgmode' ~= nil, 'shared Org plugin loads')

local search = command { 'rg', '--line-number', '--fixed-strings', 'Windows', root }
check(search:find('example.md', 1, true), 'project search with ripgrep')
check(command({ 'fd', '--type', 'f', 'example', root }):find('example.ts', 1, true), 'file discovery with fd')
edit(ts)
check(vim.fs.normalize(require('lib.root').project()):lower() == root:lower(), 'project-root discovery with spaces in the path')
check(
  vim.wait(10000, function()
    return vim.b.gitsigns_status_dict ~= nil
  end, 100),
  'Git signs attach to a tracked file'
)
require('neogit').open { kind = 'replace' }
check(
  vim.wait(10000, function()
    return vim.bo.filetype == 'NeogitStatus'
  end, 100),
  'Neogit status opens'
)
require('neogit').close()

local shell = vim.fn.system 'echo DOTFILES_NATIVE_SHELL'
check(vim.v.shell_error == 0 and shell:find('DOTFILES_NATIVE_SHELL', 1, true), 'native shell command')
local saved = vim.fn.getreg('+', 1, true)
local saved_type = vim.fn.getregtype '+'
vim.fn.setreg('+', 'dotfiles Windows clipboard check')
local clipboard = vim.fn.getreg '+'
vim.fn.setreg('+', saved, saved_type)
check(clipboard == 'dotfiles Windows clipboard check', 'system clipboard round trip')
check(vim.v.errmsg == '', 'no Neovim startup or runtime error')
print 'PASS full native Neovim acceptance checks'
