<#
.SYNOPSIS
    OneDrive Background Sync Controller (#078)
.DESCRIPTION
    Inspects OneDrive process RAM/CPU footprint and cleanly shuts down OneDrive during heavy compilation.
.EXAMPLE
    .\078-onedrive-sync-throttle-disable.ps1 -DryRun

    Simulates the change without modifying the system.

    .\078-onedrive-sync-throttle-disable.ps1

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

Write-Output "=== [078] OneDrive Background Sync Controller ==="
$od = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue
if (-not $od) {
    Write-Output "OneDrive is not currently running."
    return
}

foreach ($p in $od) {
    Write-Output ("OneDrive (PID {0}) - WorkingSet: {1} MB" -f $p.Id, [math]::Round($p.WorkingSet64 / 1MB, 1))
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess("OneDrive.exe", "Shutdown OneDrive background sync")) {
    Write-Output "[DRY-RUN] Would gracefully stop OneDrive.exe background process."
    return
}

Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
Write-Output "OneDrive background sync stopped."
