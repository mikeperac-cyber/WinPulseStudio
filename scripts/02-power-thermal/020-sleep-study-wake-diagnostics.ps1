<#
.SYNOPSIS
    Modern Standby & Phantom Wake Auditor (#020)
.DESCRIPTION
    Audits powercfg /lastwake, /waketimers, /devicequery wake_armed, and /requests.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [020] Modern Standby & Phantom Wake Auditor ==="
Write-Output "--- Last Wake Source ---"
& powercfg.exe /lastwake

Write-Output "`n--- Wake-Armed Hardware Devices ---"
& powercfg.exe /devicequery wake_armed

Write-Output "`n--- Active Wake Timers ---"
& powercfg.exe /waketimers

if (-not $DryRun) {
    Write-Output "`n--- Active Power Requests ---"
    & powercfg.exe /requests
}
