-- Basic Org-mode support (agenda/capture are thinner than Emacs; see EMACS-PARITY.md)
return {
  {
    'nvim-orgmode/orgmode',
    ft = { 'org' },
    event = 'VeryLazy',
    config = function()
      require('orgmode').setup {
        org_agenda_files = { '~/org/**/*', '~/notes/**/*.org' },
        org_default_notes_file = '~/org/refile.org',
        org_startup_indented = true,
        mappings = {
          prefix = '<Leader>o',
        },
      }
    end,
  },
}
