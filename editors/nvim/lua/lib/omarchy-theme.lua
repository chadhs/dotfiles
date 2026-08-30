-- Omarchy theme integration, shared by the startup adapter and live-reload
-- watcher in plugins/theme.lua.
--
-- omarchy's theme engine regenerates a lazy spec at
-- ~/.local/state/omarchy/current/theme/neovim.lua on every `omarchy theme
-- set`. That file is written for LazyVim: the colorscheme colors live in a
-- plain spec, and the "LazyVim/LazyVim" entry exists only so LazyVim's
-- config applies the colorscheme. This module reads that file, strips the
-- distro entry, and exposes the result. Mac-safe: the state file never
-- exists on darwin.
local M = {}

M.state_file = function()
  return vim.fn.expand('~/.local/state/omarchy/current/theme/neovim.lua')
end

--- Parse the omarchy-generated spec.
--- @return string|nil colorscheme intended colorscheme name
--- @return table|nil lazyvim_opts the full LazyVim entry opts (may carry
---   theme config like everforest's background="soft")
--- @return table|nil specs remaining plugin specs, LazyVim entry removed
--- @return table|nil omarchy_spec the raw parsed file (nil when unreadable)
M.parse = function()
  local state_file = M.state_file()
  if vim.fn.filereadable(state_file) == 0 then
    return nil, nil, nil, nil
  end

  local ok, omarchy_spec = pcall(dofile, state_file)
  if not ok or type(omarchy_spec) ~= 'table' then
    return nil, nil, nil, nil
  end

  local colorscheme, lazyvim_opts, specs = nil, nil, {}
  for _, s in ipairs(omarchy_spec) do
    if s[1] == 'LazyVim/LazyVim' then
      -- distro entry: never install it, just read its opts
      if type(s.opts) == 'table' then
        colorscheme = s.opts.colorscheme
        lazyvim_opts = s.opts
      end
    else
      table.insert(specs, s)
    end
  end

  return colorscheme, lazyvim_opts, specs, omarchy_spec
end

--- Apply the theme described by the current state file. Lazy-aware: loads
--- the colorscheme plugin first if it is lazy=true (all-themes.lua warmer),
--- then runs :colorscheme. Returns the applied name, or nil when nothing
--- was applied.
--- @return string|nil
M.apply = function()
  local colorscheme, lazyvim_opts = M.parse()
  if not colorscheme then
    return nil
  end

  local bg = type(lazyvim_opts) == 'table' and lazyvim_opts.background or nil
  if bg == 'dark' or bg == 'light' then
    pcall(function() vim.o.background = bg end)
  end

  pcall(function()
    require('lazy.core.loader').colorscheme(colorscheme)
  end)
  pcall(vim.cmd.colorscheme, colorscheme)
  return vim.g.colors_name == colorscheme and colorscheme or nil
end

return M
