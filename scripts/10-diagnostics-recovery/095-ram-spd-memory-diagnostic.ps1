<#
.SYNOPSIS
    Physical RAM DIMM Slot, Speed & Dual-Channel Inspector (#095)
.DESCRIPTION
    Queries Win32_PhysicalMemory to verify DIMM population, capacity, and MT/s clock speed.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [095] Physical RAM DIMM Slot, Speed & Dual-Channel Inspector ==="
$dimms = Get-CimInstance -ClassName Win32_PhysicalMemory
foreach ($m in $dimms) {
    $capGB = [math]::Round($m.Capacity / 1GB, 1)
    Write-Output ("Slot [{0}]: {1} GB | Speed: {2} MT/s (Configured: {3} MT/s) | Manufacturer: {4} | Part: {5}" -f $m.DeviceLocator, $capGB, $m.Speed, $m.ConfiguredClockSpeed, $m.Manufacturer, ($m.PartNumber).Trim())
}
