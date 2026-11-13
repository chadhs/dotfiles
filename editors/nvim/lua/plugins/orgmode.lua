-- Basic Org-mode support (agenda/capture are thinner than Emacs; see EMACS-PARITY.md)
return {
  {
    'nvim-orgmode/orgmode',
    ft = { 'org' },
    event = 'VeryLazy',
    config = function()
      local platform = require 'lib.platform'
      require('orgmode').setup {
        org_agenda_files = { platform.org .. '/**/*', platform.notes .. '/**/*.org' },
        org_default_notes_file = platform.org .. '/refile.org',
        org_startup_indented = true,
        mappings = {
          prefix = '<Leader>o',
        },
      }
    end,
  },
}
