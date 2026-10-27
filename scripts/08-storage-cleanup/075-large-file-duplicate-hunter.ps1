<#
.SYNOPSIS
    Top 25 Largest Files & Forgotten ISO/ZIP Hunter (#075)
.DESCRIPTION
    Read-only scan of Downloads and Documents for files > 50MB sorted by size descending.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [string[]]$ScanPaths = @(
        (Join-Path $env:USERPROFILE "Downloads"),
        (Join-Path $env:USERPROFILE "Desktop")
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [075] Top 25 Largest Files & Forgotten ISO/ZIP Hunter ==="
$largeFiles = foreach ($sp in $ScanPaths) {
    if (Test-Path $sp) {
        Get-ChildItem -Path $sp -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 25MB }
    }
}

$top25 = $largeFiles | Sort-Object Length -Descending | Select-Object -First 25
if (-not $top25) {
    Write-Output "No files larger than 25 MB found in scanned directories."
    return
}

foreach ($f in $top25) {
    Write-Output ("{0,8} MB | {1:yyyy-MM-dd} | {2}" -f [math]::Round($f.Length / 1MB, 1), $f.LastWriteTime, $f.FullName)
}
