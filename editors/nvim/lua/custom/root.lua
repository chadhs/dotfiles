-- Project root from the current buffer (Emacs projectile / default-directory).
-- Window-local lcd so :pwd, :e, ,t, and ,gf follow the file or netrw listing,
-- not nvim's launch directory.

local M = {}

local function home()
  return vim.fs.normalize(vim.fn.resolve(vim.fn.expand '~'))
end

function M.dir()
  local name = vim.api.nvim_buf_get_name(0)
  if name == '' then
    return vim.uv.cwd()
  end
  name = vim.fs.normalize(name)
  if vim.fn.isdirectory(name) == 1 then
    return name
  end
  local parent = vim.fn.fnamemodify(name, ':h')
  if parent ~= '' and vim.fn.isdirectory(parent) == 1 then
    return parent
  end
  return vim.uv.cwd()
end

function M.git_root()
  local git = vim.fn.finddir('.git', M.dir() .. ';')
  if git == '' then
    return nil
  end
  local path = vim.fs.normalize(vim.fn.fnamemodify(git, ':p'))
  path = path:gsub('/+$', '')
  if vim.fn.fnamemodify(path, ':t') == '.git' then
    path = vim.fn.fnamemodify(path, ':h')
  end
  return path
end

function M.project()
  return M.git_root() or M.dir()
end

local function should_skip(root)
  if vim.bo.buftype ~= '' then
    return true
  end
  if vim.api.nvim_buf_get_name(0) == '' then
    return true
  end
  if not root or root == '' then
    return true
  end
  if vim.fn.isdirectory(root) == 0 then
    return true
  end
  -- Emacs avoids treating HOME as a projectile project.
  return vim.fn.resolve(root) == vim.fn.resolve(home())
end

function M.lcd_to_project()
  local root = M.project()
  if should_skip(root) then
    return
  end
  if vim.fs.normalize(vim.fn.getcwd()) == root then
    return
  end
  pcall(vim.cmd, 'lcd ' .. vim.fn.fnameescape(root))
end

vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('custom-root-lcd', { clear = true }),
  desc = 'lcd to the current buffer git root (or directory)',
  callback = M.lcd_to_project,
})

return M
