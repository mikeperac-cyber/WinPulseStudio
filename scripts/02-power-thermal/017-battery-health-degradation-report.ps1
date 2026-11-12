<#
.SYNOPSIS
    Battery Wear Level & Cycle Count Inspector (#017)
.DESCRIPTION
    Generates powercfg batteryreport XML and computes battery health percentage (FullChargeCapacity / DesignCapacity).
.EXAMPLE
    .\017-battery-health-degradation-report.ps1 -DryRun

    Simulates the change without modifying the system.

    .\017-battery-health-degradation-report.ps1

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

Write-Output "=== [017] Battery Wear Level & Cycle Count Inspector ==="
$bat = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
if (-not $bat) {
    Write-Output "No battery detected (Desktop workstation on AC power)."
    return
}

foreach ($b in $bat) {
    Write-Output ("Battery: {0} | Charge: {1}% | Status: {2}" -f $b.Name, $b.EstimatedChargeRemaining, $b.Status)
}

if ($DryRun) {
    Write-Output "[DRY-RUN] Would run powercfg /batteryreport /xml to compute exact mWh wear level."
    return
}

$xmlPath = Join-Path $env:TEMP "winpulse-battery-report.xml"
& powercfg.exe /batteryreport /xml /output $xmlPath | Out-Null
if (Test-Path $xmlPath) {
    [xml]$report = Get-Content $xmlPath
    $batteries = $report.BatteryReport.Batteries.Battery
    foreach ($item in $batteries) {
        $design = [double]$item.DesignCapacity
        $full   = [double]$item.FullChargeCapacity
        $health = if ($design -gt 0) { [math]::Round(($full / $design) * 100, 1) } else { 0 }
        Write-Output ("Model: {0} | Design: {1} mWh | Full Charge: {2} mWh | Health: {3}% | Cycles: {4}" -f $item.Id, $design, $full, $health, $item.CycleCount)
    }
}
