<#
.SYNOPSIS
    WinSxS Component Store & Update Cache Slimmer (#072)
.DESCRIPTION
    Checks SoftwareDistribution\Download size and runs DISM StartComponentCleanup.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [072] WinSxS Component Store & Update Cache Slimmer ==="
$wuDownload = "$env:SystemRoot\SoftwareDistribution\Download"
if (Test-Path $wuDownload) {
    $files = Get-ChildItem -Path $wuDownload -Recurse -File -ErrorAction SilentlyContinue
    $mb = [math]::Round((($files | Measure-Object -Property Length -Sum).Sum / 1MB), 1)
    Write-Output ("Windows Update Download Cache: {0} MB ({1} files)" -f $mb, @($files).Count)
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess("WinSxS Component Store", "DISM /StartComponentCleanup")) {
    Write-Output "[DRY-RUN] Would run: Dism.exe /Online /Cleanup-Image /StartComponentCleanup"
    return
}

& Dism.exe /Online /Cleanup-Image /StartComponentCleanup
