<#
.SYNOPSIS
    Disable GameDVR Background Frame Capture (#010)
.DESCRIPTION
    Disables background DVR capture hooks in HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR and System\GameConfigStore.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$EnableCapture
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [010] Disable GameDVR Background Frame Capture ==="
$dvrPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
$gcsPath = "HKCU:\System\GameConfigStore"
$val = if ($EnableCapture) { 1 } else { 0 }

if ($DryRun -or -not $PSCmdlet.ShouldProcess($dvrPath, "Set AppCaptureEnabled=$val")) {
    Write-Output "[DRY-RUN] Would set AppCaptureEnabled=$val and GameDVR_Enabled=$val."
    return
}

if (-not (Test-Path $dvrPath)) { New-Item -Path $dvrPath -Force | Out-Null }
Set-ItemProperty -Path $dvrPath -Name "AppCaptureEnabled" -Value $val -Type DWord
if (Test-Path $gcsPath) {
    Set-ItemProperty -Path $gcsPath -Name "GameDVR_Enabled" -Value $val -Type DWord
}
Write-Output ("GameDVR Background Capture set to {0}." -f $(if ($EnableCapture) { "Enabled" } else { "Disabled" }))
