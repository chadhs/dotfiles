-- Emacs-style named bookmarks (bookmark-set / bookmark-jump / bookmark-delete parity).
-- Named, persistent bookmarks stored in stdpath('data')/bookmarks.json, globally
-- scoped like Emacs's ~/.emacs.d/bookmarks. Files open at the bookmarked
-- position; directories open in netrw (Emacs dired parity), never a file tree.
-- Vim's native marks (m a, ' a, :delmarks) are unaffected.

local M = {}

local function bookmarks_file()
  return vim.fn.stdpath('data') .. '/bookmarks.json'
end

local function load()
  local f = io.open(bookmarks_file(), 'r')
  if not f then
    return {}
  end
  local content = f:read('*a')
  f:close()
  if not content or content:match '^%s*$' then
    return {}
  end
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= 'table' then
    return {}
  end
  return data
end

local function save(bookmarks)
  local f = io.open(bookmarks_file(), 'w')
  if f then
    f:write(vim.json.encode(bookmarks))
    f:close()
  end
end

local function trim(name)
  return (name or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

-- Bookmarkable target of the current buffer: a file path or a directory
-- (e.g. a netrw buffer). Returns nil for special buffers (neo-tree, etc.).
local function current_target()
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' then
    return nil
  end
  if vim.fn.isdirectory(path) == 1 or vim.fn.filereadable(path) == 1 then
    return path
  end
  return nil
end

function M.set(name)
  name = trim(name)
  if name == '' then
    return
  end
  local path = current_target()
  if not path then
    vim.notify('Nothing to bookmark in this buffer', vim.log.levels.WARN)
    return
  end
  local bookmarks = load()
  local existed = bookmarks[name] ~= nil
  local entry = { path = path }
  if vim.fn.isdirectory(path) == 0 then
    local cursor = vim.api.nvim_win_get_cursor(0)
    entry.line = math.max(cursor[1], 1)
    entry.col = cursor[2] + 1
  end
  bookmarks[name] = entry
  save(bookmarks)
  local where = vim.fn.fnamemodify(path, ':~')
  if vim.fn.isdirectory(path) == 1 then
    where = where .. '/'
  end
  vim.notify('Bookmark ' .. name .. (existed and ' (updated)' or ' set') .. ': ' .. where)
end

-- Prompt for a name (default: current file/dir name), like bookmark-set.
function M.prompt_set()
  local path = current_target()
  if not path then
    vim.notify('Nothing to bookmark in this buffer', vim.log.levels.WARN)
    return
  end
  local default = vim.fn.fnamemodify(path:gsub('/$', ''), ':t')
  vim.ui.input({ prompt = 'Set bookmark (name): ', default = default }, function(name)
    if name then
      M.set(name)
    end
  end)
end

function M.delete(name)
  local bookmarks = load()
  if bookmarks[name] then
    bookmarks[name] = nil
    save(bookmarks)
    vim.notify('Bookmark ' .. name .. ' deleted')
  else
    vim.notify('No bookmark named ' .. name, vim.log.levels.WARN)
  end
end

local function jump(bookmark)
  local path = bookmark.path
  if vim.fn.isdirectory(path) == 1 then
    -- Directories open in netrw (Emacs dired parity), never a file tree.
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
    return
  end
  if vim.fn.filereadable(path) == 0 then
    vim.notify('Bookmark target no longer exists: ' .. path, vim.log.levels.WARN)
    return
  end
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  local line = math.min(math.max(bookmark.line or 1, 1), vim.api.nvim_buf_line_count(0))
  local col = math.max((bookmark.col or 1) - 1, 0)
  pcall(vim.api.nvim_win_set_cursor, 0, { line, col })
end

-- Jump to a bookmark by name (Emacs bookmark-jump).
function M.jump(name)
  local bookmark = load()[trim(name)]
  if not bookmark then
    vim.notify('No bookmark named ' .. name, vim.log.levels.WARN)
    return
  end
  jump(bookmark)
end

local function display_path(b)
  local p = vim.fn.fnamemodify(b.path, ':~')
  if vim.fn.isdirectory(b.path) == 1 then
    return p .. '/'
  end
  return p .. ':' .. (b.line or 1)
end

-- Telescope picker over bookmarks; pass { delete = true } to delete instead of jump.
function M.list(opts)
  opts = opts or {}
  local bookmarks = load()
  local names = vim.tbl_keys(bookmarks)
  if #names == 0 then
    vim.notify('No bookmarks yet — set one with ,ms')
    return
  end
  table.sort(names)

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local entry_display = require('telescope.pickers.entry_display')

  local displayer = entry_display.create {
    separator = '  ',
    items = { { width = 32 }, { remaining = true } },
  }

  pickers
    .new(opts, {
      prompt_title = opts.delete and 'Delete bookmark' or 'Jump to bookmark',
      finder = finders.new_table {
        results = names,
        entry_maker = function(name)
          local b = bookmarks[name]
          return {
            value = name,
            ordinal = name .. ' ' .. b.path,
            display = function()
              return displayer { name, display_path(b) }
            end,
            path = b.path,
            lnum = b.line,
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      previewer = conf.qflist_previewer(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not entry then
            return
          end
          if opts.delete then
            M.delete(entry.value)
          else
            jump(bookmarks[entry.value])
          end
        end)
        return true
      end,
    })
    :find()
end

return M
