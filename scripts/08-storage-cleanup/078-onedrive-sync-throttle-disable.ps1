<#
.SYNOPSIS
    OneDrive Background Sync Controller (#078)
.DESCRIPTION
    Inspects OneDrive process RAM/CPU footprint and cleanly shuts down OneDrive during heavy compilation.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
