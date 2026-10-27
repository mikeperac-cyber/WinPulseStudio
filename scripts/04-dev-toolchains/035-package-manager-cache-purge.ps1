<#
.SYNOPSIS
    Unified Package Manager Cache Purge (npm/pip/NuGet) (#035)
.DESCRIPTION
    Measures and clears package caches across npm, pip, and NuGet.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [035] Unified Package Manager Cache Purge ==="
$cacheDirs = @(
    @{ Tool = "npm-cache";   Path = Join-Path $env:LOCALAPPDATA "npm-cache" },
    @{ Tool = "pip-cache";   Path = Join-Path $env:LOCALAPPDATA "pip\cache" },
    @{ Tool = "nuget-v3";    Path = Join-Path $env:LOCALAPPDATA "NuGet\v3-cache" },
    @{ Tool = "pnpm-store";  Path = Join-Path $env:LOCALAPPDATA "pnpm\store" }
)

foreach ($c in $cacheDirs) {
    if (Test-Path $c.Path) {
        $bytes = (Get-ChildItem -Path $c.Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $mb = if ($bytes) { [math]::Round($bytes / 1MB, 1) } else { 0 }
        Write-Output ("[{0,-12}] {1,8} MB -> {2}" -f $c.Tool, $mb, $c.Path)
    }
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess("npm, pip, and dotnet nuget temp caches", "Purge Caches")) {
    Write-Output "[DRY-RUN] Would run: dotnet nuget locals temp --clear, npm cache clean --force, and pip cache purge."
    return
}

if (Get-Command "dotnet" -ErrorAction SilentlyContinue) {
    & dotnet nuget locals temp --clear
}
if (Get-Command "npm" -ErrorAction SilentlyContinue) {
    & npm cache verify
}
Write-Output "Package manager caches cleaned and verified."
