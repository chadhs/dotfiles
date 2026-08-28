-- string-inflection parity (camelCase / kebab / snake cycling)
-- Uses text-case.nvim's conversion library with an in-buffer replace that works
-- from Lua keymaps (plugin's current_word() relies on feedkeys/operatorfunc).
local function cword_bounds()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  if line == '' then
    return nil
  end
  local c = col + 1 -- 1-based
  if c > #line then
    c = #line
  end
  -- Treat snake / kebab / alnum as one identifier (Emacs string-inflection style)
  local function is_ident(ch)
    return ch and ch:match '[%w_%-]' ~= nil
  end
  if not is_ident(line:sub(c, c)) then
    -- If cursor is on a boundary, prefer the identifier to the right, else left
    if is_ident(line:sub(c + 1, c + 1)) then
      c = c + 1
    elseif c > 1 and is_ident(line:sub(c - 1, c - 1)) then
      c = c - 1
    else
      return nil
    end
  end
  while c > 1 and is_ident(line:sub(c - 1, c - 1)) do
    c = c - 1
  end
  local s = c
  while c <= #line and is_ident(line:sub(c, c)) do
    c = c + 1
  end
  local word = line:sub(s, c - 1)
  if word == '' then
    return nil
  end
  return row - 1, s - 1, c - 1, word
end

local function apply_case(converter)
  local row, start_col, end_col, word = cword_bounds()
  if not word then
    return
  end
  local new_word = converter(word)
  if not new_word or new_word == word then
    return
  end
  vim.api.nvim_buf_set_text(0, row, start_col, row, end_col, { new_word })
end

return {
  {
    'johmsalas/text-case.nvim',
    keys = {
      {
        '<leader>sit',
        function()
          local row, start_col, end_col, word = cword_bounds()
          if not word then
            return
          end
          local api = require('textcase').api
          local next_word
          if word:find '_' then
            next_word = api.to_dash_case(word)
          elseif word:find '-' then
            next_word = api.to_camel_case(word)
          else
            next_word = api.to_snake_case(word)
          end
          vim.api.nvim_buf_set_text(0, row, start_col, row, end_col, { next_word })
        end,
        desc = 'Case: cycle snake/kebab/camel',
      },
      {
        '<leader>sic',
        function()
          apply_case(require('textcase').api.to_camel_case)
        end,
        desc = 'Case: lowerCamel',
      },
      {
        '<leader>sik',
        function()
          apply_case(require('textcase').api.to_dash_case)
        end,
        desc = 'Case: kebab',
      },
      {
        '<leader>sis',
        function()
          apply_case(require('textcase').api.to_snake_case)
        end,
        desc = 'Case: snake',
      },
    },
    config = function()
      require('textcase').setup {}
    end,
  },
}
