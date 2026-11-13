#Requires -Version 7.0
# No external test framework or package installation is needed.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../common.ps1"
$temp = if ($env:DOTFILES_TEST_TEMP) { $env:DOTFILES_TEST_TEMP } else { [IO.Path]::GetTempPath() }
$root = Join-Path $temp ('dotfiles deployment ' + [guid]::NewGuid().ToString('N'))
$nvim = Join-Path $root 'native nvim'
$emacs = Join-Path $root 'emacs state'
$tools = Join-Path $root 'editor tools'
$deploy = Join-Path $PSScriptRoot '../deploy.ps1'
$context = Get-DotfilesContext -NvimConfig $nvim -EmacsConfig $emacs -ToolsDirectory $tools
$targets = @{ NvimConfig = $nvim; EmacsConfig = $emacs; ToolsDirectory = $tools }
$count = 0

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
    $script:count++
    Write-Host "PASS  $Message"
}

function Assert-Throws {
    param([scriptblock] $Action, [string] $Message)
    $failed = $false
    try { & $Action } catch { $failed = $true }
    Assert-True $failed $Message
}

try {
    & $deploy @targets -InstallDependencies -WhatIf
    Assert-True (-not (Test-Path -LiteralPath $root)) '-WhatIf creates no directories or files'

    $gitRoot = Join-Path $root 'Git discovery'
    $gitBin = Join-Path $gitRoot 'Git/usr/bin'
    New-Item -ItemType Directory -Path $gitBin, (Join-Path $gitRoot 'Git/cmd') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $gitRoot 'Git/cmd/git.exe'), '')
    $savedPath = $env:PATH
    $savedProgramFiles = $env:ProgramFiles
    $savedLocalAppData = $env:LOCALAPPDATA
    try {
        $env:PATH = "$env:SystemRoot\System32;$env:SystemRoot"
        $env:ProgramFiles = $gitRoot
        $env:LOCALAPPDATA = $gitRoot
        Assert-True ((Get-DotfilesFallbackPaths) -eq $gitBin) 'Git fallback discovery works without Git on the inherited PATH'
    } finally {
        $env:PATH = $savedPath
        $env:ProgramFiles = $savedProgramFiles
        $env:LOCALAPPDATA = $savedLocalAppData
    }

    & $deploy @targets
    Assert-True (Test-DotfilesJunction $nvim (Join-Path $context.Repo 'editors/nvim')) 'Neovim junction points to shared config'
    $init = Join-Path $emacs 'init.el'
    Assert-True ([IO.File]::ReadAllText($init) -ceq (Get-DotfilesEmacsInit $context)) 'Emacs redirector loads this checkout'
    Assert-True (-not (Get-Item -LiteralPath $emacs).LinkType) 'Emacs state is not a repository junction'
    $paths = Get-Content -LiteralPath $context.ToolPathsFile -Raw | ConvertFrom-Json
    Assert-True ($paths.ManagedBy -ceq 'chadhs/dotfiles/windows' -and $paths.Version -eq 1) 'Generated tool paths have a versioned ownership marker'
    Assert-True (@($paths.Paths | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Container) }).Count -eq 0) 'Generated tool paths contain only existing directories'
    $written = (Get-Item -LiteralPath $init).LastWriteTimeUtc
    $pathsWritten = (Get-Item -LiteralPath $context.ToolPathsFile).LastWriteTimeUtc
    & $deploy @targets
    Assert-True ((Get-Item -LiteralPath $init).LastWriteTimeUtc -eq $written) 'Safe rerun does not rewrite the init file'
    Assert-True ((Get-Item -LiteralPath $context.ToolPathsFile).LastWriteTimeUtc -eq $pathsWritten) 'Safe rerun does not rewrite tool paths'

    [IO.File]::WriteAllText($context.ToolPathsFile, '{"user":"preserve me"}')
    Assert-Throws { & $deploy @targets -BackupExisting } 'Unmanaged tool paths block deployment even with backup requested'
    Assert-True ([IO.File]::ReadAllText($context.ToolPathsFile) -ceq '{"user":"preserve me"}') 'Blocked deployment preserves unmanaged tool paths'
    Remove-Item -LiteralPath $context.ToolPathsFile
    New-Item -ItemType Junction -Path $context.ToolPathsFile -Target $emacs | Out-Null
    Assert-Throws { & $deploy @targets } 'Tool metadata cannot redirect through a junction'
    Remove-Item -LiteralPath $context.ToolPathsFile -Force
    & $deploy @targets

    Remove-Item -LiteralPath $nvim -Force
    New-Item -ItemType Directory -Path $nvim | Out-Null
    [IO.File]::WriteAllText((Join-Path $nvim 'user.txt'), 'preserve me')
    Assert-Throws { & $deploy @targets } 'Unfamiliar Neovim configuration blocks deployment'
    Assert-True ([IO.File]::ReadAllText((Join-Path $nvim 'user.txt')) -eq 'preserve me') 'Blocked deployment preserves user files'
    & $deploy @targets -Editor nvim -BackupExisting -WhatIf
    Assert-True (-not (Get-Item -LiteralPath $nvim).LinkType) 'Backup preview does not replace a directory'
    & $deploy @targets -Editor nvim -BackupExisting
    $backup = Get-ChildItem -LiteralPath $root -Filter 'native nvim.bak-*' | Select-Object -First 1
    Assert-True ($backup -and [IO.File]::ReadAllText((Join-Path $backup.FullName 'user.txt')) -eq 'preserve me') 'Explicit backup preserves old Neovim config'

    [IO.File]::WriteAllText($init, '(message "existing user init")')
    Assert-Throws { & $deploy @targets } 'Unfamiliar Emacs init blocks deployment'
    Assert-True ([IO.File]::ReadAllText($init) -eq '(message "existing user init")') 'Blocked deployment preserves Emacs init'
    & $deploy @targets -Editor emacs -BackupExisting
    Assert-True (@(Get-ChildItem -LiteralPath $emacs -Filter 'init.el.bak-*').Count -eq 1) 'Explicit Emacs backup remains beside the redirector'

    foreach ($name in @('init.elc', 'early-init.el', 'early-init.elc')) {
        $file = Join-Path $emacs $name
        [IO.File]::WriteAllText($file, '; needs review')
        Assert-Throws { & $deploy @targets -Editor emacs -BackupExisting } "$name cannot silently override the redirector"
        Remove-Item -LiteralPath $file
    }
    $legacy = Join-Path $root '_emacs'
    [IO.File]::WriteAllText($legacy, '; legacy init')
    Assert-Throws { & $deploy @targets -Editor emacs } 'Legacy init takes precedence and requires manual review'
    Remove-Item -LiteralPath $legacy

    $selected = Join-Path $root 'selection only'
    & $deploy -Editor nvim -NvimConfig $nvim -EmacsConfig $selected -ToolsDirectory $tools
    Assert-True (-not (Test-Path -LiteralPath $selected)) 'Selecting Neovim does not deploy Emacs'

    $quoted = ConvertTo-EmacsString 'C:\src\space and "quote"\dotfiles'
    Assert-True ($quoted -ceq '"C:/src/space and \"quote\"/dotfiles"') 'Generated Lisp quotes paths with spaces and quotes'
    Write-Host "PASS  $count deployment assertions"
} finally {
    # Remove the junction itself before removing only this test's temporary tree.
    if ((Get-Item -LiteralPath $nvim -Force -ErrorAction SilentlyContinue).LinkType) {
        Remove-Item -LiteralPath $nvim -Force
    }
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
