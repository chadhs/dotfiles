-- Emacs global-subword-mode parity: w/e/b stop on CamelCase and snake_case parts.
-- W/E/B stay Vim WORDs (whitespace-separated).
return {
  {
    'chrisgrieser/nvim-spider',
    keys = {
      {
        'w',
        function()
          require('spider').motion 'w'
        end,
        mode = { 'n', 'o', 'x' },
        desc = 'Subword forward',
      },
      {
        'e',
        function()
          require('spider').motion 'e'
        end,
        mode = { 'n', 'o', 'x' },
        desc = 'Subword end',
      },
      {
        'b',
        function()
          require('spider').motion 'b'
        end,
        mode = { 'n', 'o', 'x' },
        desc = 'Subword backward',
      },
      {
        'ge',
        function()
          require('spider').motion 'ge'
        end,
        mode = { 'n', 'o', 'x' },
        desc = 'Subword end backward',
      },
    },
  },
}
