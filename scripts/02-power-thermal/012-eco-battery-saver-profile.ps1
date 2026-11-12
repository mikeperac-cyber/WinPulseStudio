<#
.SYNOPSIS
    Ultra-Endurance On-The-Go Battery Profile (#012)
.DESCRIPTION
    Tunes DC (battery) processor state and switches to a battery-conserving power profile.
.EXAMPLE
    .\012-eco-battery-saver-profile.ps1 -DryRun

    Simulates the change without modifying the system.

    .\012-eco-battery-saver-profile.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [ValidateRange(40, 100)]
    [int]$MaxCpuOnBatteryPercent = 70
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Fail fast with a structured error instead of a raw PowerShell dump, so the
# calling app can record exactly what went wrong.
trap {
    Write-Output ("[ERROR] Script failed: " + $_.Exception.Message)
    exit 1
}

Write-Output "=== [012] Ultra-Endurance On-The-Go Battery Profile ==="
$activeScheme = & powercfg.exe /getactivescheme
Write-Output "Current Active Scheme: $activeScheme"

if ($DryRun -or -not $PSCmdlet.ShouldProcess("Active Power Scheme", "Set DC Max CPU to $MaxCpuOnBatteryPercent%")) {
    Write-Output "[DRY-RUN] Would set PROCTHROTTLEMAX on DC power to $MaxCpuOnBatteryPercent% and DC display timeout to 3 minutes."
    return
}

& powercfg.exe /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX $MaxCpuOnBatteryPercent
& powercfg.exe /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5
& powercfg.exe /setdcvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 180
& powercfg.exe /setactive SCHEME_CURRENT
Write-Output "Configured Ultra-Endurance Battery profile (Max DC CPU: $MaxCpuOnBatteryPercent%)."
