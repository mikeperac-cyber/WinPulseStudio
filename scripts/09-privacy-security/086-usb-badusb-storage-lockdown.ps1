<#
.SYNOPSIS
    USB Mass Storage Write-Protect / Read-Only Shield (#086)
.DESCRIPTION
    Configures HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies\WriteProtect.
.EXAMPLE
    .\086-usb-badusb-storage-lockdown.ps1 -DryRun

    Simulates the change without modifying the system.

    .\086-usb-badusb-storage-lockdown.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$AllowUsbWrites
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Fail fast with a structured error instead of a raw PowerShell dump, so the
# calling app can record exactly what went wrong.
trap {
    Write-Output ("[ERROR] Script failed: " + $_.Exception.Message)
    exit 1
}

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
