-- Native Windows integration. Editing behavior remains under editors/nvim.
return function(platform)
  platform.home = vim.env.USERPROFILE or platform.home
  platform.src = vim.env.DOTFILES_SRC or 'C:/src'
  platform.font = 'Cascadia Mono:h12'
  -- Ruby uses the active native runtime. Do not invoke the Unix chruby launcher.
  platform.ruby_command = 'ruby'
  platform.ruby_args = { '-S' }

  local local_appdata = assert(vim.env.LOCALAPPDATA, 'LOCALAPPDATA is required on Windows')
  local tools = vim.env.DOTFILES_TOOLS or vim.fs.joinpath(local_appdata, 'dotfiles/tools')
  local path_file = vim.fs.joinpath(tools, 'paths.json')
  if vim.fn.filereadable(path_file) == 1 then
    local paths = vim.json.decode(table.concat(vim.fn.readfile(path_file), '\n'))
    assert(paths.ManagedBy == 'chadhs/dotfiles/windows' and paths.Version == 1, 'Run windows/deploy.ps1 to refresh tool paths')
    vim.env.PATH = table.concat(paths.Paths, ';') .. ';' .. vim.env.PATH .. ';' .. table.concat(paths.FallbackPaths, ';')
  end
  -- Node searches project-local modules before these editor-local fallbacks.
  local modules = vim.fs.joinpath(tools, 'node/node_modules')
  if vim.fn.isdirectory(modules) == 1 then
    vim.env.NODE_PATH = vim.env.NODE_PATH and (vim.env.NODE_PATH .. ';' .. modules) or modules
  end
  -- The MSVC Tree-sitter CLI defaults to cl.exe even when GCC is on PATH.
  if not vim.env.CC and vim.fn.executable 'gcc' == 1 then
    vim.env.CC = 'gcc'
  end

  -- Mason needs only Lua's native tools here. JS/TS tools are shared with Emacs.
  platform.mason_tools = { 'lua_ls', 'stylua' }
  platform.enabled_servers = { lua_ls = true, ts_ls = true, eslint = true, html = true, cssls = true, jsonls = true }
  -- Start with the acceptance languages. Other parsers remain available via :TSInstall.
  platform.parsers =
    { 'c', 'lua', 'luadoc', 'vim', 'vimdoc', 'query', 'diff', 'markdown', 'markdown_inline', 'javascript', 'typescript', 'tsx', 'json', 'css', 'html' }
end
