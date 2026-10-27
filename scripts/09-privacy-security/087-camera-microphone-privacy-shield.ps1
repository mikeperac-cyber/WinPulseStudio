<#
.SYNOPSIS
    Camera & Microphone Hardware Consent Auditor (#087)
.DESCRIPTION
    Lists applications in HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam and microphone.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [087] Camera & Microphone Hardware Consent Auditor ==="
foreach ($cap in @("webcam", "microphone")) {
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\$cap\NonPackaged"
    Write-Output "--- Desktop Apps with $cap History ---"
    if (Test-Path $path) {
        Get-ChildItem -Path $path | ForEach-Object {
            $appName = $_.PSChildName -replace '#', '\'
            $lastStop = (Get-ItemProperty -Path $_.PSPath -Name "LastUsedTimeStop" -ErrorAction SilentlyContinue).LastUsedTimeStop
            $status = if ($lastStop -eq 0) { "[CURRENTLY IN USE!]" } else { "Idle" }
            Write-Output ("  {0,-18} -> {1}" -f $status, $appName)
        }
    }
}
