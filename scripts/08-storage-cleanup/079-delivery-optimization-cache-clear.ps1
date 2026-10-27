<#
.SYNOPSIS
    Purge Windows Delivery Optimization Peer Cache (#079)
.DESCRIPTION
    Clears the Windows Update Delivery Optimization cache via Delete-DeliveryOptimizationCache.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [079] Purge Windows Delivery Optimization Peer Cache ==="
if ($DryRun -or -not $PSCmdlet.ShouldProcess("DeliveryOptimizationCache", "Delete-DeliveryOptimizationCache")) {
    Write-Output "[DRY-RUN] Would execute Delete-DeliveryOptimizationCache -Force."
    return
}

if (Get-Command "Delete-DeliveryOptimizationCache" -ErrorAction SilentlyContinue) {
    Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue
    Write-Output "Delivery Optimization cache cleared."
} else {
    Write-Output "Delete-DeliveryOptimizationCache cmdlet not available on this OS build."
}
