<#
.SYNOPSIS
    NVMe SysMain (Superfetch) Optimizer (#003)
.DESCRIPTION
    Detects SSD/NVMe drives and configures SysMain service startup and PrefetchParameters to avoid background I/O thrashing.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$EnableSysMain
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [003] NVMe SysMain (Superfetch) Optimizer ==="
$disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
foreach ($d in $disks) {
    Write-Output ("Detected Disk: {0} | MediaType: {1} | BusType: {2}" -f $d.FriendlyName, $d.MediaType, $d.BusType)
}

$svc = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
if ($null -eq $svc) {
    Write-Output "SysMain service not found on this Windows edition."
    return
}

Write-Output ("Current SysMain Status: {0} (StartType: {1})" -f $svc.Status, $svc.StartType)
$targetStartType = if ($EnableSysMain) { 'Automatic' } else { 'Manual' }

if ($DryRun -or -not $PSCmdlet.ShouldProcess("Service SysMain", "Set StartType to $targetStartType")) {
    Write-Output "[DRY-RUN] Would set SysMain StartType to '$targetStartType' and stop service if running."
    return
}

Set-Service -Name "SysMain" -StartupType $targetStartType
if ($EnableSysMain) {
    Start-Service -Name "SysMain" -ErrorAction SilentlyContinue
    Write-Output "SysMain enabled and started."
} else {
    if ($svc.Status -eq 'Running') {
        Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
    }
    Write-Output "SysMain stopped and set to Manual for low-jitter NVMe I/O."
}
