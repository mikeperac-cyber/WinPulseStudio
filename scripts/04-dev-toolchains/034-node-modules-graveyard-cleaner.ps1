<#
.SYNOPSIS
    Stale node_modules & Build Artifact Pruner (#034)
.DESCRIPTION
    Finds node_modules, .next, and target directories older than $StaleDays and reports or removes them.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [string]$SearchRoot = (Join-Path $env:USERPROFILE "Documents"),
    [int]$StaleDays = 30,
    [switch]$DeleteStale
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [034] Stale node_modules & Build Artifact Pruner ==="
Write-Output "Scanning root: $SearchRoot (Threshold: >$StaleDays days inactive)"
$cutoff = (Get-Date).AddDays(-$StaleDays)

$dirs = Get-ChildItem -Path $SearchRoot -Directory -Recurse -Depth 3 -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -in @('node_modules', '.next', 'target', '.turbo') -and $_.LastWriteTime -lt $cutoff }

if (-not $dirs) {
    Write-Output "No stale build artifact directories found in $SearchRoot."
    return
}

foreach ($d in $dirs) {
    Write-Output ("Found Stale Dir: {0} (Last modified: {1:yyyy-MM-dd})" -f $d.FullName, $d.LastWriteTime)
    if (-not $DryRun -and $DeleteStale -and $PSCmdlet.ShouldProcess($d.FullName, "Remove stale artifact folder")) {
        Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "  [REMOVED] $($d.FullName)"
    }
}
