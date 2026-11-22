@{
    # Only tools needed by the shared editors belong in this manifest.
    Winget = @(
        @{ Id = 'Git.Git'; Commands = @('git'); Editors = @('nvim', 'emacs') }
        @{ Id = 'Neovim.Neovim'; Commands = @('nvim'); Editors = @('nvim') }
        @{ Id = 'GNU.Emacs'; Commands = @('emacs'); Editors = @('emacs') }
        @{ Id = 'GnuPG.GnuPG'; Commands = @('gpg'); RejectPath = '*\Git\usr\bin\*'; Editors = @('emacs') }
        @{ Id = 'BurntSushi.ripgrep.MSVC'; Commands = @('rg'); Editors = @('nvim', 'emacs') }
        @{ Id = 'sharkdp.fd'; Commands = @('fd'); Editors = @('nvim', 'emacs') }
        @{ Id = 'tree-sitter.tree-sitter-cli'; Commands = @('tree-sitter'); Editors = @('nvim') }
        @{ Id = 'BrechtSanders.WinLibs.POSIX.UCRT'; Commands = @('gcc', 'g++'); Editors = @('nvim', 'emacs') }
        @{ Id = 'OpenJS.NodeJS.LTS'; Commands = @('node', 'npm.cmd'); Editors = @('nvim', 'emacs') }
    )
    # Install into the dotfiles tools directory, not a shell's global npm prefix.
    # typescript-language-server still needs the JavaScript tsserver shipped before v7.
    Npm = @('typescript@6', 'typescript-language-server', 'prettier', 'eslint', 'vscode-langservers-extracted')
    Required = @('git', 'rg', 'fd', 'gcc', 'g++', 'node', 'npm.cmd', 'diff')
    NpmCommands = @('typescript-language-server', 'prettier', 'eslint', 'vscode-eslint-language-server')
    Optional = @('ruby', 'python', 'go', 'cargo', 'java', 'elixir', 'direnv', 'aspell', 'markup-preview')
}
