return {
   -- 1) Solarized (one name: "solarized", switches with :set background=light/dark)

   -- -- option 1 for solarized
   --  {
   --    "ishan9299/nvim-solarized-lua",
   --    lazy = false,
   --    priority = 1000, -- load before UI plugins so they get correct colors
   --  },

   -- -- option 2 for solarized
   {
      "maxmx03/solarized.nvim",
      lazy = false,
      priority = 1000, -- load before UI plugins so they get correct colors
   },

   -- 2) Cross-platform auto light/dark switching
   {
      "f-person/auto-dark-mode.nvim",
      lazy = false,
      priority = 999, -- after the colorscheme is available
      config = function()
	 local auto_dark_mode = require("auto-dark-mode")
	 auto_dark_mode.setup({
	       update_interval = 1000, -- checks once per second (safe and light)
	       set_dark_mode = function()
		  vim.o.background = "dark"
		  vim.cmd.colorscheme("solarized")
	       end,
	       set_light_mode = function()
		  vim.o.background = "light"
		  vim.cmd.colorscheme("solarized")
	       end,
	 })
	 auto_dark_mode.init()

	 -- Optional: small toast whenever it flips
	 -- vim.api.nvim_create_autocmd("User", {
	 --   pattern = "AutoDarkModeChanged",
	 --   callback = function()
	 --     vim.notify("Theme ⇒ " .. vim.o.background)
	 --   end,
	 -- })
      end,
   },
}
