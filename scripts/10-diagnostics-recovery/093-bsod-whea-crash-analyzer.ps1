<#
.SYNOPSIS
    BSOD BugCheck & WHEA Hardware Error Event Analyzer (#093)
.DESCRIPTION
    Scans System Event Log for Event IDs 41 (Kernel-Power), 1001 (BugCheck), and WHEA-Logger hardware errors.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [int]$LookbackDays = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [093] BSOD BugCheck & WHEA Hardware Error Event Analyzer ==="
$startTime = (Get-Date).AddDays(-$LookbackDays)
$events = Get-WinEvent -FilterHashtable @{
    LogName   = 'System'
    Id        = @(41, 1001)
    StartTime = $startTime
} -MaxEvents 15 -ErrorAction SilentlyContinue

if (-not $events) {
    Write-Output "Zero BSOD BugCheck (1001) or unexpected Kernel-Power (41) events in the last $LookbackDays days."
    return
}

foreach ($ev in $events) {
    Write-Output ("[{0:yyyy-MM-dd HH:mm}] ID {1} ({2}): {3}" -f $ev.TimeCreated, $ev.Id, $ev.ProviderName, ($ev.Message -split "`r?`n")[0])
}
