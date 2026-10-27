<#
.SYNOPSIS
    Faulty & Degraded PnP Device Driver Inspector (#099)
.DESCRIPTION
    Finds any PnP device where ConfigManagerErrorCode != 0.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [099] Faulty & Degraded PnP Device Driver Inspector ==="
$faulty = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }

if (-not $faulty) {
    Write-Output "All Plug-and-Play hardware devices report healthy status (ErrorCode = 0)."
    return
}

foreach ($dev in $faulty) {
    Write-Output ("[PROBLEM] {0} | ErrorCode: {1} | DeviceID: {2}" -f $dev.Name, $dev.ConfigManagerErrorCode, $dev.DeviceID)
}
