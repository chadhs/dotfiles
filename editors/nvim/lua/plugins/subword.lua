-- Emacs global-subword-mode parity: w/e/b stop on CamelCase and snake_case parts.
-- Punctuation, spaces, and newlines are hard boundaries (not skipped).
-- W/E/B stay Vim WORDs (whitespace-separated).
return {
  {
    'chrisgrieser/nvim-spider',
    opts = {
      skipInsignificantPunctuation = false,
    },
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
      -- Spider does not special-case cw the way Vim does (cw == ce). Remap so
      -- change-word stops at the end of the current subword instead of eating
      -- the following space or newline.
      {
        'cw',
        'ce',
        mode = 'n',
        remap = true,
        desc = 'Change subword (to end)',
      },
    },
  },
}
