<#
.SYNOPSIS
    NVMe / SSD SMART Health, Temp & Wear Level Monitor (#094)
.DESCRIPTION
    Reads PhysicalDisk status and StorageReliabilityCounter telemetry.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [094] NVMe / SSD SMART Health, Temp & Wear Level Monitor ==="
$disks = Get-PhysicalDisk
foreach ($d in $disks) {
    Write-Output ("Disk [{0}]: {1} | Media: {2} | Health: {3} | Size: {4} GB" -f $d.DeviceId, $d.FriendlyName, $d.MediaType, $d.HealthStatus, [math]::Round($d.Size / 1GB, 0))
    $rel = Get-StorageReliabilityCounter -PhysicalDisk $d -ErrorAction SilentlyContinue
    if ($rel) {
        Write-Output ("  -> Temp: {0} C | Wear: {1}% | ReadErrors: {2} | WriteErrors: {3}" -f $rel.Temperature, $rel.Wear, $rel.ReadErrorsTotal, $rel.WriteErrorsTotal)
    }
}
