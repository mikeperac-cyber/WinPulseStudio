<#
.SYNOPSIS
    Workstation AC Processor State Tuner (#019)
.DESCRIPTION
    Sets PROCTHROTTLEMIN and PROCTHROTTLEMAX on AC power for the active power plan.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [ValidateRange(5, 100)]
    [int]$MinPercent = 10,
    [ValidateRange(50, 100)]
    [int]$MaxPercent = 100
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [019] Workstation AC Processor State Tuner ==="
if ($DryRun -or -not $PSCmdlet.ShouldProcess("AC Processor State", "Set Min=$MinPercent%, Max=$MaxPercent%")) {
    Write-Output "[DRY-RUN] Would set AC PROCTHROTTLEMIN=$MinPercent% and PROCTHROTTLEMAX=$MaxPercent%."
    return
}

& powercfg.exe /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN $MinPercent
& powercfg.exe /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX $MaxPercent
& powercfg.exe /setactive SCHEME_CURRENT
Write-Output "Configured AC Processor State: Min=$MinPercent%, Max=$MaxPercent%."
