<#
.SYNOPSIS
    Wi-Fi 6/6E/7 Link Quality & Power-Save Optimizer (#055)
.DESCRIPTION
    Displays detailed Wi-Fi radio telemetry and sets wireless adapter power mode to Maximum Performance on AC.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [055] Wi-Fi 6/6E/7 Link Quality & Power-Save Optimizer ==="
& netsh.exe wlan show interfaces

$wifiSubGuid = "19cbb8fa-5279-450e-9fac-8a3d5fedd0c1"
$wifiPwrGuid = "12bbebe6-58d6-4636-95bb-3217ef867c1a"

if ($DryRun -or -not $PSCmdlet.ShouldProcess("Wireless Adapter Power Policy", "Set Maximum Performance (0) on AC")) {
    Write-Output "[DRY-RUN] Would set Wireless Adapter Power Saving Mode to Maximum Performance (0) on AC power."
    return
}

& powercfg.exe /setacvalueindex SCHEME_CURRENT $wifiSubGuid $wifiPwrGuid 0
& powercfg.exe /setactive SCHEME_CURRENT
Write-Output "Configured Wireless Adapter for Maximum Performance on AC power."
