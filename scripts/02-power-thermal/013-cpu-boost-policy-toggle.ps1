<#
.SYNOPSIS
    CPU Turbo Boost Thermal & Fan Controller (#013)
.DESCRIPTION
    Unhides PERFBOOSTMODE (be337238-0d82-4146-a960-4f3749d470c7) and configures CPU Turbo Boost policy.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [ValidateSet("Disabled", "Enabled", "Aggressive", "EfficientEnabled", "EfficientAggressive")]
    [string]$BoostMode = "EfficientEnabled"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [013] CPU Turbo Boost Thermal & Fan Controller ==="
$boostGuid = "be337238-0d82-4146-a960-4f3749d470c7"
$modeMap = @{
    "Disabled"            = 0
    "Enabled"             = 1
    "Aggressive"          = 2
    "EfficientEnabled"    = 3
    "EfficientAggressive" = 4
}
$modeIndex = $modeMap[$BoostMode]

if ($DryRun -or -not $PSCmdlet.ShouldProcess("CPU Boost Policy", "Set PERFBOOSTMODE to $BoostMode ($modeIndex)")) {
    Write-Output "[DRY-RUN] Would unhide PERFBOOSTMODE ($boostGuid) and set AC/DC boost mode to '$BoostMode' ($modeIndex)."
    return
}

& powercfg.exe -attributes SUB_PROCESSOR $boostGuid -ATTRIB_HIDE
& powercfg.exe /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR $boostGuid $modeIndex
& powercfg.exe /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR $boostGuid 0
& powercfg.exe /setactive SCHEME_CURRENT
Write-Output "CPU Turbo Boost Mode set to '$BoostMode' on AC and 'Disabled' on Battery."
