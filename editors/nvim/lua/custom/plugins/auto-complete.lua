-- Company-TNG style completion configuration
return {
   {
      'saghen/blink.cmp',
      event = { 'InsertEnter' },
      version = '1.*',
      dependencies = {
	 'L3MON4D3/LuaSnip',
	 'folke/lazydev.nvim',
      },
      opts = {
	 keymap = {
	    preset = 'super-tab', -- Use super-tab as base

	    -- Override Tab for Company-TNG behavior
	    ["<Tab>"] = { "show_and_insert", "select_next" },

	    -- Shift-Tab: cycle backward
	    ["<S-Tab>"] = { "show", "select_prev" },

	    -- Enter: accept completion or fallback to newline
	    ["<CR>"] = { "accept", "fallback" },

	    -- Escape: hide completion menu
	    ["<Esc>"] = { "hide", "fallback" },

	    -- Ctrl-Space: show completion menu manually
	    ["<C-Space>"] = { "show", "fallback" },

	    -- Ctrl-N/P: navigate completion items
	    ["<C-N>"] = { "select_next" },
	    ["<C-P>"] = { "select_prev" },

	    -- Ctrl-E: hide menu
	    ["<C-E>"] = { "hide" },

	    -- Ctrl-K: toggle signature help
	    ["<C-K>"] = { "show_signature", "hide_signature", "fallback" },
	 },

	 completion = {
	    -- Company-TNG style: no preselect, but enable auto_insert for show_and_insert
	    list = {
	       selection = {
		  preselect = false,
		  auto_insert = true,  -- Required for show_and_insert to work
	       },
	    },
	    ghost_text = {
	       enabled = false,  -- Company-TNG doesn't show ghost text
	    },
	    -- Show completion menu automatically
	    trigger = {
	       show_on_trigger_character = true,
	       show_on_insert_enter = true,
	    },
	    documentation = { auto_show = false },
	 },

	 sources = {
	    default = { 'lsp', 'path', 'snippets', 'lazydev' },
	    providers = {
	       lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
	    },
	 },

	 snippets = { preset = 'luasnip' },
	 fuzzy = { implementation = 'lua' },
	 signature = { enabled = true },
      },
   },
}
