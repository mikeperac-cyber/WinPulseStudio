<#
.SYNOPSIS
    Windows Firewall Public Profile Inbound Exposure Auditor (#084)
.DESCRIPTION
    Checks Get-NetFirewallProfile status and lists active inbound Allow rules on the Public profile.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [084] Windows Firewall Public Profile Inbound Exposure Auditor ==="
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction |
    Format-Table -AutoSize | Out-String | Write-Output

$publicRules = Get-NetFirewallRule -Direction Inbound -Enabled True -Action Allow -ErrorAction SilentlyContinue |
    Where-Object { $_.Profile -match 'Public|Any' } | Select-Object -First 15 DisplayName, Profile, Owner

Write-Output "Top Active Inbound Allow Rules on Public/Any Profile:"
$publicRules | Format-Table -AutoSize | Out-String | Write-Output
