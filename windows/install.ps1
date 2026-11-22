#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('nvim', 'emacs')][string[]] $Editor = @('nvim', 'emacs'),
    [string] $ToolsDirectory
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/common.ps1"
$context = Get-DotfilesContext -ToolsDirectory $ToolsDirectory
$packages = Import-PowerShellDataFile "$PSScriptRoot/packages.psd1"
Assert-DotfilesToolPathsFile $context
Add-DotfilesToolPaths $context

foreach ($package in $packages.Winget | Where-Object { @($_.Editors | Where-Object { $_ -in $Editor }).Count }) {
    $missing = @($package.Commands | Where-Object {
        $command = Get-Command $_ -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        -not $command -or ($package.ContainsKey('RejectPath') -and $command.Source -like $package.RejectPath)
    })
    if (-not $missing.Count) { Write-Host "OK    $($package.Id)"; continue }
    if ($PSCmdlet.ShouldProcess($package.Id, 'Install editor dependency with WinGet')) {
        if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) { throw 'Install Microsoft App Installer to get WinGet.' }
        & winget.exe install --id $package.Id --exact --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
        if ($LASTEXITCODE -ne 0) { throw "WinGet failed for $($package.Id), exit code $LASTEXITCODE" }
        Add-DotfilesToolPaths $context
    }
}

$nodeDirectory = Join-Path $context.ToolsDirectory 'node'
if ($PSCmdlet.ShouldProcess($nodeDirectory, "Install shared editor npm tools: $($packages.Npm -join ', ')")) {
    if (-not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) { throw 'Node/npm is unavailable. Reopen PowerShell after installing Node, then rerun.' }
    & npm.cmd install --prefix $nodeDirectory --no-audit --no-fund @($packages.Npm)
    if ($LASTEXITCODE -ne 0) { throw "npm failed, exit code $LASTEXITCODE" }
}
Write-DotfilesToolPaths $context -WhatIf:$WhatIfPreference
