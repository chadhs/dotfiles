-- Resolve Ruby formatting and linting from the nearest project declaration.

local M = {}

M.command = vim.fs.normalize(vim.fn.expand '~/dotfiles/utils/project-ruby-exec')

local CONFIGS = {
  standardrb = '.standard.yml',
  rubocop = '.rubocop.yml',
}

local MANIFESTS = { 'Gemfile', 'gems.rb' }

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function start_dir(path)
  path = vim.fs.normalize(path)
  if vim.fn.isdirectory(path) == 1 then
    return path
  end
  return vim.fs.dirname(path)
end

local function search_boundary(dir)
  local git_entry = vim.fs.find('.git', { path = dir, upward = true })[1]
  if git_entry then
    return vim.fs.dirname(git_entry)
  end

  local home = vim.fs.normalize(vim.fn.expand '~')
  if dir == home or vim.startswith(dir, home .. '/') then
    return home
  end
  return '/'
end

local function ancestor_dirs(dir)
  local dirs = {}
  local boundary = search_boundary(dir)
  local current = vim.fs.normalize(dir)

  while current do
    table.insert(dirs, current)
    if current == boundary then
      break
    end
    local parent = vim.fs.dirname(current)
    if not parent or parent == current then
      break
    end
    current = parent
  end

  return dirs
end

local function nearest_manifest(dirs)
  for _, dir in ipairs(dirs) do
    for _, name in ipairs(MANIFESTS) do
      local path = vim.fs.joinpath(dir, name)
      if exists(path) then
        return path
      end
    end
  end
end

local function manifest_tools(path)
  local tools = {
    standardrb = false,
    rubocop = false,
    solargraph = false,
    ruby_lsp = false,
    reek = false,
  }
  if not path then
    return tools
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return tools
  end

  for _, line in ipairs(lines) do
    local gem_name = line:match '^%s*gem%s*%(?%s*["\']([^"\']+)["\']'
    if gem_name == 'standard' or vim.startswith(gem_name or '', 'standard-') then
      tools.standardrb = true
    elseif gem_name == 'rubocop' or vim.startswith(gem_name or '', 'rubocop-') then
      tools.rubocop = true
    elseif gem_name == 'solargraph' or vim.startswith(gem_name or '', 'solargraph-') then
      tools.solargraph = true
    elseif gem_name == 'ruby-lsp' or vim.startswith(gem_name or '', 'ruby-lsp-') then
      tools.ruby_lsp = true
    elseif gem_name == 'reek' then
      tools.reek = true
    end
  end

  return tools
end

local function nearest_file(dirs, name)
  for _, dir in ipairs(dirs) do
    local path = vim.fs.joinpath(dir, name)
    if exists(path) then
      return path
    end
  end
end

local function enrich(result, dirs, manifest, declared)
  local reek_config = nearest_file(dirs, '.reek.yml')
  result.reek = declared.reek or reek_config ~= nil
  result.reek_bundled = declared.reek
  result.reek_config = reek_config

  if declared.solargraph and declared.ruby_lsp then
    result.lsp_ambiguous = true
    result.lsp_message = 'both Solargraph and Ruby LSP are declared in ' .. manifest
  elseif declared.ruby_lsp then
    result.language_server = 'ruby_lsp'
    result.lsp_bundled = true
    result.lsp_source = 'manifest'
  elseif declared.solargraph then
    result.language_server = 'solargraph'
    result.lsp_bundled = true
    result.lsp_source = 'manifest'
  else
    result.language_server = 'solargraph'
    result.lsp_bundled = false
    result.lsp_source = 'fallback'
  end

  return result
end

local function ambiguous(message, root)
  return {
    ambiguous = true,
    message = message,
    root = root,
  }
end

function M.resolve_path(path)
  local dir = start_dir(path)
  local dirs = ancestor_dirs(dir)
  local manifest = nearest_manifest(dirs)
  local declared = manifest_tools(manifest)

  for _, candidate in ipairs(dirs) do
    local has_standard = exists(vim.fs.joinpath(candidate, CONFIGS.standardrb))
    local has_rubocop = exists(vim.fs.joinpath(candidate, CONFIGS.rubocop))

    if has_standard and has_rubocop then
      return enrich(ambiguous('both .standard.yml and .rubocop.yml exist in ' .. candidate, candidate), dirs, manifest, declared)
    elseif has_standard or has_rubocop then
      local tool = has_standard and 'standardrb' or 'rubocop'
      return enrich({
        tool = tool,
        bundled = manifest ~= nil,
        manifest = manifest,
        root = manifest and vim.fs.dirname(manifest) or candidate,
        source = 'config',
      }, dirs, manifest, declared)
    end
  end

  if declared.standardrb and declared.rubocop then
    return enrich(ambiguous('both StandardRB and RuboCop are declared in ' .. manifest, vim.fs.dirname(manifest)), dirs, manifest, declared)
  elseif declared.standardrb or declared.rubocop then
    return enrich({
      tool = declared.standardrb and 'standardrb' or 'rubocop',
      bundled = true,
      manifest = manifest,
      root = vim.fs.dirname(manifest),
      source = 'manifest',
    }, dirs, manifest, declared)
  end

  return enrich({
    tool = 'rubocop',
    bundled = false,
    manifest = manifest,
    root = manifest and vim.fs.dirname(manifest) or dir,
    source = 'fallback',
  }, dirs, manifest, declared)
end

function M.resolve(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then
    path = vim.uv.cwd()
  end
  return M.resolve_path(path)
end

local function warn(bufnr, result)
  if result.ambiguous then
    if vim.b[bufnr].ruby_tooling_warning ~= result.message then
      vim.b[bufnr].ruby_tooling_warning = result.message
      vim.schedule(function()
        vim.notify('Ruby tooling disabled: ' .. result.message, vim.log.levels.WARN)
      end)
    end
  else
    vim.b[bufnr].ruby_tooling_warning = nil
  end

  if result.lsp_ambiguous and vim.b[bufnr].ruby_lsp_warning ~= result.lsp_message then
    vim.b[bufnr].ruby_lsp_warning = result.lsp_message
    vim.schedule(function()
      vim.notify('Ruby LSP disabled: ' .. result.lsp_message, vim.log.levels.WARN)
    end)
  elseif not result.lsp_ambiguous then
    vim.b[bufnr].ruby_lsp_warning = nil
  end
end

function M.formatters(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local result = M.resolve(bufnr)
  warn(bufnr, result)
  if result.ambiguous then
    return {}
  end
  local suffix = result.bundled and '_bundle' or '_project'
  return { result.tool .. suffix }
end

function M.linter(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local result = M.resolve(bufnr)
  warn(bufnr, result)
  if result.ambiguous then
    return nil, result
  end
  local suffix = result.bundled and '_bundle' or '_project'
  return result.tool .. suffix, result
end

function M.linters(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local style, result = M.linter(bufnr)
  if not style then
    return {}, result
  end
  local names = { style }
  if result.reek then
    table.insert(names, result.reek_bundled and 'reek_bundle' or 'reek_project')
  end
  return names, result
end

function M.language_server(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local result = M.resolve(bufnr)
  warn(bufnr, result)
  if result.lsp_ambiguous then
    return nil, result
  end
  return result.language_server, result
end

function M.try_lint(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local names, result = M.linters(bufnr)
  if #names == 0 then
    return
  end
  require('lint').try_lint(names, { cwd = result.root })
end

return M
