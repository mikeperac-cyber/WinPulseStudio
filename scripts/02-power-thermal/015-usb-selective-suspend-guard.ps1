<#
.SYNOPSIS
    USB Selective Suspend Guard for Dev Hardware (#015)
.DESCRIPTION
    Disables USB selective suspend setting (2a737441-1930-4402-8d77-b2bebba308a3 / 48e6b7a6-50f5-4782-a5d4-53bb8f07e226) on AC power.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [015] USB Selective Suspend Guard for Dev Hardware ==="
$usbSubGuid = "2a737441-1930-4402-8d77-b2bebba308a3"
$usbSuspendGuid = "48e6b7a6-50f5-4782-a5d4-53bb8f07e226"

if ($DryRun -or -not $PSCmdlet.ShouldProcess("USB Selective Suspend", "Disable on AC power")) {
    Write-Output "[DRY-RUN] Would disable USB Selective Suspend ($usbSuspendGuid) on AC power."
    return
}

& powercfg.exe /setacvalueindex SCHEME_CURRENT $usbSubGuid $usbSuspendGuid 0
& powercfg.exe /setactive SCHEME_CURRENT
Write-Output "USB Selective Suspend disabled on AC power. Connected debuggers and DACs will remain awake."
