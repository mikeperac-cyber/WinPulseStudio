<#
.SYNOPSIS
    Defender Real-Time Build & Compiler Exclusions (#031)
.DESCRIPTION
    Uses Add-MpPreference to exclude trusted compiler processes and workspace directories from synchronous file scanning.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [string[]]$WorkspacePaths = @(
        (Join-Path $env:USERPROFILE "source\repos"),
        (Join-Path $env:USERPROFILE "Documents\pwsh"),
        (Join-Path $env:USERPROFILE ".cargo"),
        (Join-Path $env:USERPROFILE ".nuget")
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [031] Defender Real-Time Build & Compiler Exclusions ==="
$devProcesses = @('dotnet.exe', 'msbuild.exe', 'VBCSCompiler.exe', 'devenv.exe', 'code.exe', 'node.exe', 'cargo.exe', 'rustc.exe', 'git.exe')

if ($DryRun -or -not $PSCmdlet.ShouldProcess("Windows Defender MpPreference", "Add Compiler & Workspace Exclusions")) {
    Write-Output "[DRY-RUN] Would exclude processes: $($devProcesses -join ', ')"
    Write-Output "[DRY-RUN] Would exclude paths: $($WorkspacePaths -join ', ')"
    return
}

foreach ($proc in $devProcesses) {
    Add-MpPreference -ExclusionProcess $proc -ErrorAction SilentlyContinue
}
foreach ($path in $WorkspacePaths) {
    if (Test-Path $path) {
        Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
        Write-Output "Added Defender Path Exclusion: $path"
    }
}
Write-Output "Configured Defender exclusions for $($devProcesses.Count) developer processes."
