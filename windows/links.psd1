@{
    Entries = @(
        @{ Editor = 'nvim'; Kind = 'Junction'; Source = 'editors/nvim'; Target = 'NvimConfig' }
        @{ Editor = 'emacs'; Kind = 'EmacsInit'; Source = 'editors/emacs.el'; Target = 'EmacsConfig' }
    )
}
