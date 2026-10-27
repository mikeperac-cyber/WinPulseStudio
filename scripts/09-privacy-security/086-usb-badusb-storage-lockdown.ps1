<#
.SYNOPSIS
    USB Mass Storage Write-Protect / Read-Only Shield (#086)
.DESCRIPTION
    Configures HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies\WriteProtect.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$AllowUsbWrites
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [086] USB Mass Storage Write-Protect / Read-Only Shield ==="
$polKey = "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies"
$val = if ($AllowUsbWrites) { 0 } else { 1 }

if ($DryRun -or -not $PSCmdlet.ShouldProcess($polKey, "Set WriteProtect=$val")) {
    Write-Output ("[DRY-RUN] Would set USB WriteProtect={0} in {1}." -f $val, $polKey)
    return
}

if (-not (Test-Path $polKey)) { New-Item -Path $polKey -Force | Out-Null }
Set-ItemProperty -Path $polKey -Name "WriteProtect" -Value $val -Type DWord
Write-Output ("USB Mass Storage WriteProtect set to {0}." -f $(if ($val -eq 1) { "Read-Only" } else { "Read/Write" }))
