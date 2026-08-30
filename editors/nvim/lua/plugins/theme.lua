-- Omarchy theme integration for this non-LazyVim (kickstart-derived) config.
--
-- Startup: applies the theme described by omarchy's state file when nvim
-- launches. See lua/lib/omarchy-theme.lua for the shared parsing.
-- Live reloads are handled by the spec below (see coverage notes there).
local lib = require('lib.omarchy-theme')

local colorscheme, lazyvim_opts, specs = lib.parse()
if not colorscheme then
  return {}
end

-- forward the LazyVim entry's remaining opts (e.g. everforest's
-- background="soft") to the colorscheme plugin spec so lazy's default
-- setup(opts) picks them up. We deliberately do NOT wrap config when the
-- module name resolves normally: overriding it would suppress lazy's
-- automatic setup(opts).
for _, s in ipairs(specs) do
  local pname = s.name or s[1]
  if type(pname) == 'string' and pname:find(colorscheme, 1, true) then
    local forwarded = nil
    if type(lazyvim_opts) == 'table' then
      forwarded = vim.tbl_deep_extend('force', {}, lazyvim_opts)
      forwarded.colorscheme = nil
      if next(forwarded) == nil then
        forwarded = nil
      end
    end
    if forwarded then
      s.opts = s.opts and vim.tbl_deep_extend('force', s.opts, forwarded) or forwarded
      -- Wrapping config is required when the repo's lua module name differs
      -- from the repo name (neanias/everforest-nvim -> "everforest"): lazy's
      -- default setup would try require("everforest-nvim") and error. We
      -- resolve the module ourselves; user-provided config still wins.
      local user_config = s.config
      s.config = function(_, opts)
        if type(user_config) == 'function' then
          user_config(_, opts)
        else
          local repo_mod = tostring(pname):match('([^/]+)$')
          for _, cand in ipairs({ repo_mod, colorscheme }) do
            local ok_mod, mod = pcall(require, cand)
            if ok_mod and type(mod) == 'table' and type(mod.setup) == 'function' then
              mod.setup(opts)
              break
            end
          end
        end
      end
    end
  end
end

-- Startup theme application plus live reload for non-aether themes, in a
-- single dir-based spec (lazy merges dir specs by directory, so a second
-- one would be silently dropped).
--
-- Live-reload coverage is split by active colorscheme:
--   - aether active: the watcher does nothing — aether's built-in hotreload
--     watcher (fs_event on the state file) owns reloads while it is loaded
--     and active. Skipping here is what prevents the two pipelines from
--     racing (the cause of stale "sometimes" reloads in earlier setups).
--   - aether NOT active (everforest, etc.): aether isn't loaded, so nothing
--     else watches the state file — an fs_poll on it applies the regenerated
--     spec. fs_poll re-stats by path every tick, so omarchy's rm -rf + mv of
--     the theme/ directory cannot strand it (unlike inode-bound fs_event).
--
-- Note: lazy's change detection can't drive reloads here — it stats spec
-- files, and this adapter is a regular file whose mtime never changes on a
-- theme switch (the stock symlink made the state file's mtime visible; a
-- checked-in adapter does not).
--
-- Mac-safe: without omarchy's state file this returns {} and nothing here
-- exists at all.
table.insert(specs, {
  name = 'omarchy-theme',
  dir = vim.fn.stdpath('config'),
  lazy = false,
  priority = 0,
  config = function()
    lib.apply()

    -- persist the handle so GC can't collect it and kill the poll
    local uv = vim.uv or vim.loop
    local poll = uv.new_fs_poll()
    _G.__omarchy_theme_poll = poll
    poll:start(lib.state_file(), 1000, function(err)
      if err or vim.g.colors_name == 'aether' then
        return
      end
      vim.schedule(function()
        require('lib.omarchy-theme').apply()
      end)
    end)
  end,
})

return specs
