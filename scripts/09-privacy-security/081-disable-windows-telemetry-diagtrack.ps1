<#
.SYNOPSIS
    Minimize Windows Telemetry & DiagTrack Service (#081)
.DESCRIPTION
    Configures HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry=0 and stops DiagTrack.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [081] Minimize Windows Telemetry & DiagTrack Service ==="
$dcKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
$svc = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
if ($svc) {
    Write-Output ("DiagTrack Service Status: {0} (StartType: {1})" -f $svc.Status, $svc.StartType)
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess("DataCollection & DiagTrack", "Set AllowTelemetry=0 and disable DiagTrack")) {
    Write-Output "[DRY-RUN] Would set AllowTelemetry=0 in $dcKey and stop/disable DiagTrack."
    return
}

if (-not (Test-Path $dcKey)) { New-Item -Path $dcKey -Force | Out-Null }
Set-ItemProperty -Path $dcKey -Name "AllowTelemetry" -Value 0 -Type DWord
if ($svc) {
    Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "DiagTrack" -StartupType Disabled
}
Write-Output "Telemetry minimized and DiagTrack disabled."
