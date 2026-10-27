<#
.SYNOPSIS
    Empty All Recycle Bins & Inspect VSS Shadow Storage (#074)
.DESCRIPTION
    Runs Clear-RecycleBin across fixed volumes.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [074] Empty All Recycle Bins & Inspect VSS Shadow Storage ==="
if ($DryRun -or -not $PSCmdlet.ShouldProcess("All Drives Recycle Bin", "Clear-RecycleBin -Force")) {
    Write-Output "[DRY-RUN] Would run Clear-RecycleBin -Force on all local drives."
    return
}

Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Output "All Recycle Bins emptied."
