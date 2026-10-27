<#
.SYNOPSIS
    Enable Hardware-Accelerated GPU Scheduling (HAGS) (#022)
.DESCRIPTION
    Configures HwSchMode=2 in HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$DisableHags
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [022] Enable Hardware-Accelerated GPU Scheduling (HAGS) ==="
$gfxPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
$curMode = (Get-ItemProperty -Path $gfxPath -Name "HwSchMode" -ErrorAction SilentlyContinue).HwSchMode
Write-Output ("Current HwSchMode: {0} (2=Enabled, 1=Disabled)" -f $curMode)

$target = if ($DisableHags) { 1 } else { 2 }
if ($DryRun -or -not $PSCmdlet.ShouldProcess($gfxPath, "Set HwSchMode=$target")) {
    Write-Output "[DRY-RUN] Would set HwSchMode=$target in $gfxPath."
    return
}

Set-ItemProperty -Path $gfxPath -Name "HwSchMode" -Value $target -Type DWord
Write-Output ("HwSchMode set to {0}. Restart Windows to apply changes." -f $target)
