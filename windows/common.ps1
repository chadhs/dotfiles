# Shared by deployment, dependency installation, diagnostics, and their tests.
Set-StrictMode -Version Latest

function Get-DotfilesContext {
    param(
        [string] $NvimConfig,
        [string] $EmacsConfig,
        [string] $ToolsDirectory
    )

    if (-not $IsWindows) { throw 'These scripts require PowerShell 7 on native Windows.' }
    $repo = Split-Path $PSScriptRoot -Parent
    if (-not $NvimConfig) {
        $configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { $env:LOCALAPPDATA }
        $appName = if ($env:NVIM_APPNAME) { $env:NVIM_APPNAME } else { 'nvim' }
        $NvimConfig = Join-Path $configHome $appName
    }
    if (-not $EmacsConfig) {
        # Ask Emacs so HOME, its registry setting, and XDG follow its own rules.
        $emacs = Find-DotfilesEmacs
        if ($emacs) {
            $output = & $emacs --batch -Q --eval '(princ (expand-file-name user-emacs-directory))'
            if ($LASTEXITCODE -ne 0) { throw 'Emacs could not resolve its configuration directory.' }
            $EmacsConfig = ($output -join "`n").Trim()
        } else {
            $emacsHome = if ($env:HOME) { $env:HOME } else { $env:APPDATA }
            $EmacsConfig = Join-Path $emacsHome '.emacs.d'
        }
    }
    if (-not $ToolsDirectory) {
        $ToolsDirectory = if ($env:DOTFILES_TOOLS) { $env:DOTFILES_TOOLS } else { Join-Path $env:LOCALAPPDATA 'dotfiles/tools' }
    }
    [pscustomobject]@{
        Repo = [IO.Path]::GetFullPath($repo)
        NvimConfig = [IO.Path]::GetFullPath($NvimConfig)
        EmacsConfig = [IO.Path]::GetFullPath($EmacsConfig)
        ToolsDirectory = [IO.Path]::GetFullPath($ToolsDirectory)
        ToolPathsFile = Join-Path ([IO.Path]::GetFullPath($ToolsDirectory)) 'paths.json'
    }
}

function Find-DotfilesEmacs {
    $command = Get-Command emacs.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Source }
    $candidates = @(
        "$env:ProgramFiles/Emacs/emacs-*/bin/emacs.exe"
        "$env:LOCALAPPDATA/Programs/Emacs/emacs-*/bin/emacs.exe"
    )
    Get-Item -Path $candidates -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
}

function Get-DotfilesToolPaths {
    param([Parameter(Mandatory)] $Context)

    $paths = [Collections.Generic.List[string]]::new()
    $paths.Add((Join-Path $Context.ToolsDirectory 'node/node_modules/.bin'))
    $fnmRoot = if ($env:FNM_DIR) { $env:FNM_DIR } else { Join-Path $env:APPDATA 'fnm' }
    $paths.Add((Join-Path $fnmRoot 'aliases/default'))
    $paths.Add((Join-Path $env:ProgramFiles 'nodejs'))
    $paths.Add((Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Links'))
    $emacs = Find-DotfilesEmacs
    if ($emacs) { $paths.Add((Split-Path $emacs -Parent)) }
    $paths.Add((Join-Path $env:ProgramFiles 'Neovim/bin'))
    $paths.Add((Join-Path $env:ProgramFiles 'PowerShell/7'))
    $paths.Add((Join-Path $env:LOCALAPPDATA 'Programs/Git/cmd'))
    $paths.Add((Join-Path $env:ProgramFiles 'Git/cmd'))
    $paths.Add((Join-Path $env:ProgramFiles '7-Zip'))
    $paths.Add((Join-Path $env:LOCALAPPDATA 'Programs/GnuPG/bin'))
    $paths.Add((Join-Path $env:ProgramFiles 'GnuPG/bin'))
    if (${env:ProgramFiles(x86)}) { $paths.Add((Join-Path ${env:ProgramFiles(x86)} 'GnuPG/bin')) }

    # WinGet's portable compiler has DLLs beside gcc. Include that real bin dir.
    $compilerPaths = @(
        "$env:LOCALAPPDATA/Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_*/mingw64/bin"
        "$env:ProgramFiles/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_*/mingw64/bin"
    )
    foreach ($item in Get-Item -Path $compilerPaths -ErrorAction SilentlyContinue | Sort-Object FullName) {
        $paths.Add($item.FullName)
    }
    foreach ($root in @("$env:LOCALAPPDATA/Microsoft", $env:ProgramFiles)) {
        foreach ($pattern in @('BurntSushi.ripgrep.MSVC_*/*/rg.exe', 'sharkdp.fd_*/*/fd.exe', 'tree-sitter.tree-sitter-cli_*/tree-sitter.exe')) {
            foreach ($item in Get-Item -Path "$root/WinGet/Packages/$pattern" -ErrorAction SilentlyContinue) {
                $paths.Add($item.DirectoryName)
            }
        }
    }
    $paths | Where-Object { Test-Path -LiteralPath $_ -PathType Container } | Select-Object -Unique
}

function Get-DotfilesFallbackPaths {
    $git = Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $gitPath = if ($git) {
        $git.Source
    } else {
        Get-Item -Path "$env:LOCALAPPDATA/Programs/Git/cmd/git.exe", "$env:ProgramFiles/Git/cmd/git.exe" -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
    }
    if ($gitPath) {
        $root = Split-Path (Split-Path $gitPath -Parent) -Parent
        $bin = Join-Path $root 'usr/bin'
        if (Test-Path -LiteralPath $bin -PathType Container) { $bin }
    }
}

function Add-DotfilesToolPaths {
    param([Parameter(Mandatory)] $Context)
    $paths = @(Get-DotfilesToolPaths $Context)
    # Native Windows tools take precedence over Git's Unix compatibility tools.
    $env:PATH = (@($paths) + @($env:PATH -split ';') + @(Get-DotfilesFallbackPaths) | Select-Object -Unique) -join ';'
}

function Assert-DotfilesToolPathsFile {
    param([Parameter(Mandatory)] $Context)
    if (Get-Item -LiteralPath $Context.ToolPathsFile -Force -ErrorAction SilentlyContinue) {
        try {
            $item = Get-Item -LiteralPath $Context.ToolPathsFile -Force
            if ($item.LinkType -or $item.PSIsContainer) { throw 'Tool paths must be a regular file' }
            $data = Get-Content -LiteralPath $Context.ToolPathsFile -Raw | ConvertFrom-Json
            if ($data.ManagedBy -cne 'chadhs/dotfiles/windows' -or $data.Version -ne 1) { throw 'Unmanaged paths file' }
        } catch { throw "Existing tool paths file needs manual review: $($Context.ToolPathsFile)" }
    }
}

function Get-DotfilesToolPathsContent {
    param([Parameter(Mandatory)] $Context)
    [ordered]@{
        ManagedBy = 'chadhs/dotfiles/windows'
        Version = 1
        Paths = @(Get-DotfilesToolPaths $Context)
        FallbackPaths = @(Get-DotfilesFallbackPaths)
    } | ConvertTo-Json
}

function Write-DotfilesToolPaths {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)] $Context)
    Assert-DotfilesToolPathsFile $Context
    $content = (Get-DotfilesToolPathsContent $Context) + "`n"
    if ((Test-Path -LiteralPath $Context.ToolPathsFile -PathType Leaf) -and
        [IO.File]::ReadAllText($Context.ToolPathsFile) -ceq $content) { return }
    if ($PSCmdlet.ShouldProcess($Context.ToolPathsFile, 'Write editor-local tool paths')) {
        New-Item -ItemType Directory -Path $Context.ToolsDirectory -Force | Out-Null
        [IO.File]::WriteAllText($Context.ToolPathsFile, $content, [Text.UTF8Encoding]::new($false))
        Write-Host "READY $($Context.ToolPathsFile)"
    }
}

function ConvertTo-EmacsString {
    param([Parameter(Mandatory)][string] $Value)
    # Forward slashes avoid Windows backslash escapes in generated Lisp strings.
    '"' + $Value.Replace('\', '/').Replace('"', '\"') + '"'
}

function Get-DotfilesEmacsInit {
    param([Parameter(Mandatory)] $Context)
    $root = ConvertTo-EmacsString ($Context.Repo + '/')
    $tools = ConvertTo-EmacsString $Context.ToolsDirectory
    @"
;;; dotfiles-windows-init v1 -*- lexical-binding: t -*-
;; Generated by windows/deploy.ps1. Editor settings live in the checkout.
(defvar cs/dotfiles-root $root)
(defvar cs/tools-directory $tools)
(load (expand-file-name "editors/emacs.el" cs/dotfiles-root) nil nil t)
"@ + "`n"
}

function Test-DotfilesJunction {
    param([string] $Path, [string] $Source)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if (-not $item -or $item.LinkType -ne 'Junction') { return $false }
    [string]::Equals([IO.Path]::GetFullPath($item.Target).TrimEnd('\', '/'),
        [IO.Path]::GetFullPath($Source).TrimEnd('\', '/'), [StringComparison]::OrdinalIgnoreCase)
}

function Assert-DotfilesEmacsStartup {
    param([Parameter(Mandatory)] $Context)
    $directory = $Context.EmacsConfig
    if (Test-Path -LiteralPath $directory) {
        $item = Get-Item -LiteralPath $directory -Force
        if (-not $item.PSIsContainer -or $item.LinkType) {
            throw "Emacs state must be a local directory, not a file or link: $directory"
        }
    }
    # An earlier init or compiled init would silently hide our redirector.
    $homeDirectory = Split-Path $directory -Parent
    $conflicts = @('.emacs', '.emacs.el', '.emacs.elc', '_emacs', '_emacs.el', '_emacs.elc') |
        ForEach-Object { Join-Path $homeDirectory $_ }
    $conflicts += @('init.elc', 'early-init.el', 'early-init.elc') |
        ForEach-Object { Join-Path $directory $_ }
    foreach ($path in $conflicts) {
        if (Test-Path -LiteralPath $path) { throw "Existing Emacs startup file needs manual review: $path" }
    }
}
