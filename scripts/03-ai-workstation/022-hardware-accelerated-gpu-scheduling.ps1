<#
.SYNOPSIS
    Enable Hardware-Accelerated GPU Scheduling (HAGS) (#022)
.DESCRIPTION
    Configures HwSchMode=2 in HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers.
.EXAMPLE
    .\022-hardware-accelerated-gpu-scheduling.ps1 -DryRun

    Simulates the change without modifying the system.

    .\022-hardware-accelerated-gpu-scheduling.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$DisableHags
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Fail fast with a structured error instead of a raw PowerShell dump, so the
# calling app can record exactly what went wrong.
trap {
    Write-Output ("[ERROR] Script failed: " + $_.Exception.Message)
    exit 1
}

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
