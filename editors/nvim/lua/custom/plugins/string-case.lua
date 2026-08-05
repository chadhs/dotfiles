-- string-inflection parity (camelCase / kebab / snake cycling)
return {
  {
    'johmsalas/text-case.nvim',
    keys = {
      {
        '<leader>sit',
        function()
          -- Cycle snake → kebab → camel → snake (closest to string-inflection-all-cycle)
          local word = vim.fn.expand '<cword>'
          if word == '' then
            return
          end
          local textcase = require 'textcase'
          if word:find '_' then
            textcase.current_word 'to_dash_case'
          elseif word:find '-' then
            textcase.current_word 'to_camel_case'
          else
            textcase.current_word 'to_snake_case'
          end
        end,
        desc = 'Case: cycle snake/kebab/camel',
      },
      {
        '<leader>sic',
        function()
          require('textcase').current_word 'to_camel_case'
        end,
        desc = 'Case: lowerCamel',
      },
      {
        '<leader>sik',
        function()
          require('textcase').current_word 'to_dash_case'
        end,
        desc = 'Case: kebab',
      },
      {
        '<leader>sis',
        function()
          require('textcase').current_word 'to_snake_case'
        end,
        desc = 'Case: snake',
      },
    },
    config = function()
      require('textcase').setup {}
    end,
  },
}
