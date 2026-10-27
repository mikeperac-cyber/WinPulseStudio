<#
.SYNOPSIS
    Ultra-Endurance On-The-Go Battery Profile (#012)
.DESCRIPTION
    Tunes DC (battery) processor state and switches to a battery-conserving power profile.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [ValidateRange(40, 100)]
    [int]$MaxCpuOnBatteryPercent = 70
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
