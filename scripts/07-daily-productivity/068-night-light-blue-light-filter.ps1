<#
.SYNOPSIS
    Late-Night Coding Display Brightness & Eye-Care Controller (#068)
.DESCRIPTION
    Uses WmiMonitorBrightnessMethods in root\wmi to inspect and adjust internal display brightness.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [ValidateRange(10, 100)]
    [int]$TargetBrightness = 45
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [068] Late-Night Coding Display Brightness & Eye-Care Controller ==="
$mon = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBrightness -ErrorAction SilentlyContinue
if (-not $mon) {
    Write-Output "External desktop monitor detected (WMI internal panel brightness control not applicable)."
    return
}

Write-Output ("Current Panel Brightness: {0}%" -f $mon.CurrentBrightness)
if ($DryRun -or -not $PSCmdlet.ShouldProcess("Display Panel", "Set Brightness to $TargetBrightness%")) {
    Write-Output "[DRY-RUN] Would set panel brightness to $TargetBrightness%."
    return
}

$methods = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBrightnessMethods
Invoke-CimMethod -InputObject $methods -MethodName WmiSetBrightness -Arguments @{ Timeout = 1; Brightness = [byte]$TargetBrightness } | Out-Null
Write-Output "Display brightness set to $TargetBrightness%."
