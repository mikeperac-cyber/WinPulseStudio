<#
.SYNOPSIS
    Virtualization-Based Security (VBS / Memory Integrity) Inspector (#089)
.DESCRIPTION
    Queries Win32_DeviceGuard in root\Microsoft\Windows\DeviceGuard.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [089] Virtualization-Based Security (VBS / Memory Integrity) Inspector ==="
$dg = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction SilentlyContinue
if (-not $dg) {
    Write-Output "Win32_DeviceGuard information unavailable."
    return
}

$vbsStatusMap = @{ 0 = "Not Enabled"; 1 = "Enabled (Not Running)"; 2 = "Enabled & Running" }
Write-Output ("VirtualizationBasedSecurityStatus: {0} ({1})" -f $dg.VirtualizationBasedSecurityStatus, $vbsStatusMap[[int]$dg.VirtualizationBasedSecurityStatus])
Write-Output ("SecurityServicesRunning          : {0}" -f ($dg.SecurityServicesRunning -join ', '))
