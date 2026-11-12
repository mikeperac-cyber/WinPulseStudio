<#
.SYNOPSIS
    WinSxS Component Store & Update Cache Slimmer (#072)
.DESCRIPTION
    Checks SoftwareDistribution\Download size and runs DISM StartComponentCleanup.
.EXAMPLE
    .\072-windows-update-dism-cleanup.ps1 -DryRun

    Simulates the change without modifying the system.

    .\072-windows-update-dism-cleanup.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Fail fast with a structured error instead of a raw PowerShell dump, so the
# calling app can record exactly what went wrong.
trap {
    Write-Output ("[ERROR] Script failed: " + $_.Exception.Message)
    exit 1
}

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
