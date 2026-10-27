<#
.SYNOPSIS
    Win32PrioritySeparation Foreground Boost (#005)
.DESCRIPTION
    Tunes HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl\Win32PrioritySeparation to 0x26 (38 decimal) for optimal foreground responsiveness.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [ValidateSet("ResponsiveForeground", "BalancedDefault", "BackgroundServices")]
    [string]$Profile = "ResponsiveForeground"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [005] Win32PrioritySeparation Foreground Boost ==="
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
$currentVal = (Get-ItemProperty -Path $regPath -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue).Win32PrioritySeparation
Write-Output ("Current Win32PrioritySeparation: 0x{0:X2} ({0})" -f $currentVal)

$targetVal = switch ($Profile) {
    "ResponsiveForeground" { 0x26 } # Short, Variable, 3:1 foreground boost
    "BalancedDefault"      { 0x02 } # Windows default
    "BackgroundServices"   { 0x18 } # Long, Fixed, Equal quantum
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess($regPath, "Set Win32PrioritySeparation to 0x$($targetVal.ToString('X2'))")) {
    Write-Output ("[DRY-RUN] Would update Win32PrioritySeparation to 0x{0:X2} ({1})." -f $targetVal, $Profile)
    return
}

Set-ItemProperty -Path $regPath -Name "Win32PrioritySeparation" -Value $targetVal -Type DWord
Write-Output ("Updated Win32PrioritySeparation to 0x{0:X2} ({1})." -f $targetVal, $Profile)
