#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('nvim', 'emacs')][string[]] $Editor = @('nvim', 'emacs'),
    [switch] $BackupExisting,
    [switch] $InstallDependencies,
    [string] $NvimConfig,
    [string] $EmacsConfig,
    [string] $ToolsDirectory
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/common.ps1"
$context = Get-DotfilesContext -NvimConfig $NvimConfig -EmacsConfig $EmacsConfig -ToolsDirectory $ToolsDirectory
$manifest = Import-PowerShellDataFile "$PSScriptRoot/links.psd1"
$operations = @()
Assert-DotfilesToolPathsFile $context

# Validate the whole selection before installing anything or touching targets.
foreach ($entry in $manifest.Entries | Where-Object Editor -in $Editor) {
    $source = Join-Path $context.Repo $entry.Source
    if (-not (Test-Path -LiteralPath $source)) { throw "Missing configuration source: $source" }
    $target = $context.($entry.Target)
    if ($entry.Kind -eq 'EmacsInit') {
        Assert-DotfilesEmacsStartup $context
        $target = Join-Path $target 'init.el'
        $content = Get-DotfilesEmacsInit $context
        if ((Test-Path -LiteralPath $target -PathType Leaf) -and
            -not (Get-Item -LiteralPath $target -Force).LinkType -and
            [IO.File]::ReadAllText($target) -ceq $content) {
            Write-Host "OK    $target"
            continue
        }
    } elseif (Test-DotfilesJunction -Path $target -Source $source) {
        Write-Host "OK    $target"
        continue
    }
    $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
    if ($existing -and -not $BackupExisting) {
        throw "Existing configuration left untouched: $target. Review it, then rerun with -BackupExisting."
    }
    $operations += [pscustomobject]@{ Entry = $entry; Source = $source; Target = $target; Existing = $existing }
}

if ($InstallDependencies) {
    & "$PSScriptRoot/install.ps1" -Editor $Editor -ToolsDirectory $context.ToolsDirectory -WhatIf:$WhatIfPreference
}

Write-DotfilesToolPaths $context -WhatIf:$WhatIfPreference

foreach ($operation in $operations) {
    $target = $operation.Target
    if (-not $PSCmdlet.ShouldProcess($target, "Deploy $($operation.Entry.Kind) from $($operation.Source)")) { continue }
    if ($operation.Existing) {
        $backup = $target + '.bak-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fffffff')
        Move-Item -LiteralPath $target -Destination $backup
        Write-Host "BACKUP $backup"
    }
    $parent = Split-Path $target -Parent
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
    if ($operation.Entry.Kind -eq 'Junction') {
        New-Item -ItemType Junction -Path $target -Target $operation.Source | Out-Null
    } else {
        [IO.File]::WriteAllText($target, (Get-DotfilesEmacsInit $context), [Text.UTF8Encoding]::new($false))
    }
    Write-Host "READY $target"
}
