<#
.SYNOPSIS
    Faulty & Degraded PnP Device Driver Inspector (#099)
.DESCRIPTION
    Finds any PnP device where ConfigManagerErrorCode != 0.
.EXAMPLE
    .\099-driver-signature-problem-audit.ps1 -DryRun

    Simulates the change without modifying the system.

    .\099-driver-signature-problem-audit.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Fail fast with a structured error instead of a raw PowerShell dump, so the
# calling app can record exactly what went wrong.
trap {
    Write-Output ("[ERROR] Script failed: " + $_.Exception.Message)
    exit 1
}

Write-Output "=== [099] Faulty & Degraded PnP Device Driver Inspector ==="
$faulty = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }

if (-not $faulty) {
    Write-Output "All Plug-and-Play hardware devices report healthy status (ErrorCode = 0)."
    return
}

foreach ($dev in $faulty) {
    Write-Output ("[PROBLEM] {0} | ErrorCode: {1} | DeviceID: {2}" -f $dev.Name, $dev.ConfigManagerErrorCode, $dev.DeviceID)
}
