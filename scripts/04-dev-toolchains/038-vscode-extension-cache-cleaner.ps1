<#
.SYNOPSIS
    VS Code / Cursor Cached VSIX & Crashpad Cleaner (#038)
.DESCRIPTION
    Purges CachedExtensionVSIXs, Crashpad\reports, and old logs in %APPDATA%\Code and %APPDATA%\Cursor.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [038] VS Code / Cursor Cached VSIX & Crashpad Cleaner ==="
$ideRoots = @(
    (Join-Path $env:APPDATA "Code"),
    (Join-Path $env:APPDATA "Code - Insiders"),
    (Join-Path $env:APPDATA "Cursor")
)
$subFolders = @("CachedExtensionVSIXs", "CachedData", "Crashpad\reports", "logs")

$totalReclaimBytes = 0L
foreach ($root in $ideRoots) {
    if (Test-Path $root) {
        foreach ($sub in $subFolders) {
            $target = Join-Path $root $sub
            if (Test-Path $target) {
                $files = Get-ChildItem -Path $target -Recurse -File -ErrorAction SilentlyContinue
                $sum = ($files | Measure-Object -Property Length -Sum).Sum
                if ($sum) { $totalReclaimBytes += $sum }
                Write-Output ("Found {0} MB in {1}" -f [math]::Round(($sum / 1MB), 1), $target)
                if (-not $DryRun -and $PSCmdlet.ShouldProcess($target, "Clear IDE cache subfolder")) {
                    Get-ChildItem -Path $target -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
Write-Output ("Total IDE Cache Reclaimable/Cleaned: {0} MB" -f [math]::Round($totalReclaimBytes / 1MB, 1))
