<#
.SYNOPSIS
    Camera & Microphone Hardware Consent Auditor (#087)
.DESCRIPTION
    Lists applications in HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam and microphone.
.EXAMPLE
    .\087-camera-microphone-privacy-shield.ps1 -DryRun

    Simulates the change without modifying the system.

    .\087-camera-microphone-privacy-shield.ps1

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
