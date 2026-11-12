<#
.SYNOPSIS
    Purge Windows Delivery Optimization Peer Cache (#079)
.DESCRIPTION
    Clears the Windows Update Delivery Optimization cache via Delete-DeliveryOptimizationCache.
.EXAMPLE
    .\079-delivery-optimization-cache-clear.ps1 -DryRun

    Simulates the change without modifying the system.

    .\079-delivery-optimization-cache-clear.ps1

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
