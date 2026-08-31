-- Omarchy theme cache warmer: pre-installs every colorscheme the omarchy
-- themes on this machine may reference, so the first hot-reload after a
-- theme switch renders correctly instead of falling back to tokyonight.
--
-- The list is generated dynamically from each theme's own neovim.lua in
-- ~/.config/omarchy/themes (custom) and /usr/share/omarchy/themes (stock),
-- so newly installed or updated themes are picked up with no edits here.
-- Specs are stripped down to repo/name/branch: warming must not carry any
-- theme's opts or config, and it must not force anything eager.
--
-- Themes without a neovim.lua are aether-template-based (every theme built
-- from a colors.toml, including repos installed via omarchy-theme-add) and
-- all resolve to the single hardcoded aether spec below. It must keep its
-- explicit name and branch: lazy merges specs by url and lets an explicit
-- name rename the merged plugin, so a bare "bjarneo/aether.nvim" builds the
-- cache into lazy/aether.nvim while every aether-themed install renames it
-- to lazy/aether at runtime -- a directory the package never shipped. That
-- mismatch cost a network clone on first launch and a tokyonight fallback
-- until nvim was restarted.
-- Mac-safe: no omarchy state file means no extra plugins get installed.
if vim.fn.filereadable(vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")) == 0 then
	return {}
end

local warmed = {
	-- Covers every theme that has no neovim.lua of its own (see above).
	{
		"bjarneo/aether.nvim",
		branch = "v3",
		name = "aether",
		lazy = true,
		priority = 1000,
	},
}

local function warm(file)
	local ok, themes = pcall(dofile, file)
	if not ok or type(themes) ~= "table" then
		return
	end

	for _, spec in ipairs(themes) do
		local repo = type(spec) == "table" and type(spec[1]) == "string" and spec[1] or nil
		-- The distro entry is never a plugin; it only carries opts to read.
		if repo and repo ~= "LazyVim/LazyVim" then
			warmed[spec.name or repo] = {
				repo,
				name = spec.name,
				branch = spec.branch,
				lazy = true,
				priority = 1000,
			}
		end
	end
end

local theme_dirs = {
	vim.fn.expand("~/.config/omarchy/themes"),
	(vim.env.OMARCHY_PATH or "/usr/share/omarchy") .. "/themes",
}

for _, dir in ipairs(theme_dirs) do
	for _, file in ipairs(vim.fn.glob(dir .. "/*/neovim.lua", false, true)) do
		warm(file)
	end
end

return vim.tbl_values(warmed)
