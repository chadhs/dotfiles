#Requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet('nvim', 'emacs')][string[]] $Editor = @('nvim', 'emacs'),
    [string] $NvimConfig,
    [string] $EmacsConfig,
    [string] $ToolsDirectory
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/common.ps1"
$context = Get-DotfilesContext -NvimConfig $NvimConfig -EmacsConfig $EmacsConfig -ToolsDirectory $ToolsDirectory
$manifest = Import-PowerShellDataFile "$PSScriptRoot/links.psd1"
$packages = Import-PowerShellDataFile "$PSScriptRoot/packages.psd1"
Add-DotfilesToolPaths $context
$failures = 0
try {
    Assert-DotfilesToolPathsFile $context
    if (-not (Test-Path -LiteralPath $context.ToolPathsFile -PathType Leaf) -or
        [IO.File]::ReadAllText($context.ToolPathsFile).TrimEnd() -cne (Get-DotfilesToolPathsContent $context)) {
        throw 'Run windows/deploy.ps1 to refresh editor-local tool paths.'
    }
    Write-Host "PASS  $($context.ToolPathsFile)"
} catch { Write-Host "FAIL  $($_.Exception.Message)"; $failures++ }

foreach ($entry in $manifest.Entries | Where-Object Editor -in $Editor) {
    $source = Join-Path $context.Repo $entry.Source
    $target = $context.($entry.Target)
    $valid = $false
    if ($entry.Kind -eq 'Junction') {
        $valid = (Test-Path -LiteralPath $source -PathType Container) -and (Test-DotfilesJunction -Path $target -Source $source)
    } else {
        try { Assert-DotfilesEmacsStartup $context } catch { Write-Host "FAIL  $($_.Exception.Message)"; $failures++ }
        $target = Join-Path $target 'init.el'
        $valid = (Test-Path -LiteralPath $target -PathType Leaf) -and
            -not (Get-Item -LiteralPath $target -Force).LinkType -and
            [IO.File]::ReadAllText($target) -ceq (Get-DotfilesEmacsInit $context)
    }
    if ($valid) { Write-Host "PASS  $target" } else { Write-Host "FAIL  Missing or unmanaged configuration: $target"; $failures++ }
}

$required = @($packages.Required)
if ('nvim' -in $Editor) { $required += @('nvim', 'tree-sitter') }
if ('emacs' -in $Editor) { $required += @('emacs', 'gpg') }
foreach ($tool in $required) {
    $command = Get-Command $tool -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { Write-Host "PASS  $tool $($command.Source)" } else { Write-Host "FAIL  Missing tool: $tool"; $failures++ }
}
foreach ($tool in $packages.NpmCommands) {
    $command = Get-Command $tool -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { Write-Host "PASS  $tool $($command.Source)" } else { Write-Host "FAIL  Missing editor npm tool: $tool"; $failures++ }
}
$typescript = Join-Path $context.ToolsDirectory 'node/node_modules/typescript'
try {
    $version = (Get-Content -LiteralPath (Join-Path $typescript 'package.json') -Raw | ConvertFrom-Json).version
    if ([version]$version -ge [version]'7.0.0' -or -not (Test-Path -LiteralPath (Join-Path $typescript 'lib/tsserver.js') -PathType Leaf)) {
        throw 'typescript-language-server needs TypeScript below version 7 with lib/tsserver.js.'
    }
    Write-Host "PASS  Shared TypeScript $version includes tsserver.js"
} catch { Write-Host 'FAIL  Run windows/install.ps1 to install a compatible shared TypeScript library.'; $failures++ }
if ('emacs' -in $Editor) {
    $gpg = Get-Command gpg.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($gpg -and $gpg.Source -like '*\Git\usr\bin\*') {
        Write-Host 'FAIL  Git GPG does not accept native paths. Install GnuPG.GnuPG with windows/install.ps1.'
        $failures++
    }
}
if ('nvim' -in $Editor -and (Get-Command nvim.exe -ErrorAction SilentlyContinue)) {
    $version = & nvim.exe --version | Select-Object -First 1
    if ($version -match 'NVIM v(\d+\.\d+\.\d+)' -and [version]$Matches[1] -ge [version]'0.12.0') {
        Write-Host "PASS  $version"
    } else { Write-Host 'FAIL  Neovim 0.12 or newer is required.'; $failures++ }
}
if ('nvim' -in $Editor -and (Get-Command tree-sitter.exe -ErrorAction SilentlyContinue)) {
    $version = & tree-sitter.exe --version
    if ($version -match 'tree-sitter (\d+\.\d+\.\d+)' -and [version]$Matches[1] -ge [version]'0.26.1') {
        Write-Host "PASS  $version"
    } else { Write-Host 'FAIL  Tree-sitter CLI 0.26.1 or newer is required.'; $failures++ }
}
foreach ($tool in $packages.Optional) {
    if (-not (Get-Command $tool -CommandType Application -ErrorAction SilentlyContinue)) {
        Write-Host "INFO  Optional tool unavailable: $tool"
    }
}
Write-Host 'INFO  Package downloads and grammar builds run separately in each editor. See windows/README.md.'
if ($failures) { throw "$failures required Windows editor checks failed." }
Write-Host 'PASS  Required Windows editor deployment and dependency checks passed.'
