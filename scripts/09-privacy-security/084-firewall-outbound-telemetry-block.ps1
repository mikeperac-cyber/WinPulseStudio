<#
.SYNOPSIS
    Windows Firewall Public Profile Inbound Exposure Auditor (#084)
.DESCRIPTION
    Checks Get-NetFirewallProfile status and lists active inbound Allow rules on the Public profile.
.EXAMPLE
    .\084-firewall-outbound-telemetry-block.ps1 -DryRun

    Simulates the change without modifying the system.

    .\084-firewall-outbound-telemetry-block.ps1

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

Write-Output "=== [084] Windows Firewall Public Profile Inbound Exposure Auditor ==="
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction |
    Format-Table -AutoSize | Out-String | Write-Output

$publicRules = Get-NetFirewallRule -Direction Inbound -Enabled True -Action Allow -ErrorAction SilentlyContinue |
    Where-Object { $_.Profile -match 'Public|Any' } | Select-Object -First 15 DisplayName, Profile, Owner

Write-Output "Top Active Inbound Allow Rules on Public/Any Profile:"
$publicRules | Format-Table -AutoSize | Out-String | Write-Output
