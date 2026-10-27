<#
.SYNOPSIS
    Restart Windows Audio Stack & Bluetooth Headset Recovery (#066)
.DESCRIPTION
    Lists active audio devices and restarts AudioEndpointBuilder and Audiosrv services.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [066] Restart Windows Audio Stack & Bluetooth Headset Recovery ==="
Get-CimInstance -ClassName Win32_SoundDevice -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Output ("Audio Device: {0} | Status: {1}" -f $_.Name, $_.Status)
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess("Audiosrv & AudioEndpointBuilder", "Restart-Service")) {
    Write-Output "[DRY-RUN] Would restart AudioEndpointBuilder and Audiosrv services."
    return
}

Restart-Service -Name "AudioEndpointBuilder" -Force
Restart-Service -Name "Audiosrv" -Force
Write-Output "Windows Audio services restarted cleanly."
