<#
.SYNOPSIS
    VPN Interface Metric & Orphaned Route Doctor (#058)
.DESCRIPTION
    Displays IPv4 default routes (0.0.0.0/0) and VPN adapter interface metrics to diagnose split-tunnel conflicts.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [058] VPN Interface Metric & Orphaned Route Doctor ==="
Write-Output "--- Active Default Routes (0.0.0.0/0) ---"
Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
    Select-Object ifIndex, InterfaceAlias, NextHop, RouteMetric, InterfaceMetric |
    Sort-Object { $_.RouteMetric + $_.InterfaceMetric } |
    Format-Table -AutoSize | Out-String | Write-Output

Write-Output "--- Virtual / VPN Interfaces ---"
Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.ConnectionState -eq 'Connected' } |
    Select-Object ifIndex, InterfaceAlias, InterfaceMetric, NlMtu |
    Sort-Object InterfaceMetric | Format-Table -AutoSize | Out-String | Write-Output
