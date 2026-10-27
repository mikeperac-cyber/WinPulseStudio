<#
.SYNOPSIS
    Multi-Browser Media & Code Cache Vacuum (#076)
.DESCRIPTION
    Scans and purges Chromium Cache_Data, Code Cache, and GPUCache without touching cookies or sessions.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [076] Multi-Browser Media & Code Cache Vacuum ==="
$browsers = @(
    @{ Name = "Microsoft Edge"; Base = Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Default" },
    @{ Name = "Google Chrome";  Base = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default" },
    @{ Name = "Brave Browser";  Base = Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser\User Data\Default" }
)
$cacheSubDirs = @("Cache\Cache_Data", "Code Cache", "GPUCache")

$totalMB = 0.0
foreach ($b in $browsers) {
    if (Test-Path $b.Base) {
        foreach ($sub in $cacheSubDirs) {
            $p = Join-Path $b.Base $sub
            if (Test-Path $p) {
                $files = Get-ChildItem -Path $p -Recurse -File -ErrorAction SilentlyContinue
                $mb = [math]::Round((($files | Measure-Object -Property Length -Sum).Sum / 1MB), 1)
                $totalMB += $mb
                Write-Output ("[{0} - {1}] {2} MB" -f $b.Name, $sub, $mb)
                if (-not $DryRun -and $PSCmdlet.ShouldProcess($p, "Clear Browser Cache")) {
                    $files | Remove-Item -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
Write-Output ("Total Browser Cache Reclaimable: {0} MB" -f $totalMB)
