-- Buffer/netrw directory as window cwd (Emacs default-directory).
-- :e is relative to that folder. ,t / ,gf still use project() (git root).

local M = {}

local function home()
  return vim.fs.normalize(vim.fn.resolve(vim.fn.expand '~'))
end

function M.dir()
  if vim.bo.filetype == 'netrw' then
    local cur = vim.b.netrw_curdir
    if type(cur) == 'string' and cur ~= '' and vim.fn.isdirectory(cur) == 1 then
      return vim.fs.normalize(cur)
    end
  end

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
  -- vim.fs.root matches .git whether it is a directory (repo) or a file (worktree/submodule)
  return vim.fs.root(M.dir(), '.git')
end

function M.project()
  return M.git_root() or M.dir()
end

local function should_skip(root)
  -- Netrw is sometimes 'nofile'; still lcd so :e follows the listing.
  if vim.bo.buftype ~= '' and vim.bo.filetype ~= 'netrw' then
    return true
  end
  if vim.api.nvim_buf_get_name(0) == '' and vim.bo.filetype ~= 'netrw' then
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

function M.lcd_to_dir()
  local root = M.dir()
  if should_skip(root) then
    return
  end
  if vim.fs.normalize(vim.fn.getcwd()) == root then
    return
  end
  pcall(vim.cmd, 'lcd ' .. vim.fn.fnameescape(root))
end

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufReadPost', 'FileType' }, {
  group = vim.api.nvim_create_augroup('custom-root-lcd', { clear = true }),
  desc = 'lcd to the current buffer or netrw directory',
  callback = function(args)
    if args.event == 'FileType' and args.match ~= 'netrw' then
      return
    end
    M.lcd_to_dir()
  end,
})

return M
