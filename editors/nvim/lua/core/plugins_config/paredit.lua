-- require("nvim-paredit").setup({
--   -- should plugin use default keybindings? (default = true)
--   use_default_keys = true,
--   -- sometimes user wants to restrict plugin to certain file types only
--   -- defaults to all supported file types including custom lang
--   -- extensions (see next section)
--   filetypes = { "clojure" },
--   cursor_behaviour = "auto", -- remain, follow, auto
--   -- list of default keybindings
--   keys = {
--     ["><"] = { paredit.api.slurp_forwards, "Slurp forwards" },
--     ["<>"] = { paredit.api.slurp_backwards, "Slurp backwards" },
--
--     [">>"] = { paredit.api.barf_forwards, "Barf forwards" },
--     ["<<"] = { paredit.api.barf_backwards, "Barf backwards" },
--
--     [">e"] = { paredit.api.drag_element_forwards, "Drag element right" },
--     ["<e"] = { paredit.api.drag_element_backwards, "Drag element left" },
--
--     [">f"] = { paredit.api.drag_form_forwards, "Drag form right" },
--     ["<f"] = { paredit.api.drag_form_backwards, "Drag form left" },
--
--     ["<localleader>o"] = { paredit.api.raise_form, "Raise form" },
--     ["<localleader>O"] = { paredit.api.raise_element, "Raise element" },
--
--     ["E"] = {
--       paredit.api.move_to_next_element,
--       "Jump to next element tail",
--       -- by default all keybindings are dot repeatable
--       repeatable = false,
--       mode = { "n", "x", "o", "v" },
--     },
--     ["B"] = {
--       paredit.api.move_to_prev_element,
--       "Jump to previous element head",
--       repeatable = false,
--       mode = { "n", "x", "o", "v" },
--     },
--
--     -- These are text object selection keybindings which can used with standard `d, y, c`, `v`
--     ["af"] = {
--       api.select_around_form,
--       "Around form",
--       repeatable = false,
--       mode = { "o", "v" }
--     },
--     ["if"] = {
--       api.select_in_form,
--       "In form",
--       repeatable = false,
--       mode = { "o", "v" }
--     },
--     ["ae"] = {
--       api.select_element,
--       "Around element",
--       repeatable = false,
--       mode = { "o", "v" },
--     },
--     ["ie"] = {
--       api.select_element,
--       "Element",
--       repeatable = false,
--       mode = { "o", "v" },
--     },
--   }
-- })
