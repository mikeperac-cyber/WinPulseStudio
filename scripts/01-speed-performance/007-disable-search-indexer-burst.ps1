<#
.SYNOPSIS
    Pause Windows Search Indexer (Build Mode) (#007)
.DESCRIPTION
    Pauses or resumes the WSearch service to prevent indexing storms during software compilation or branch switching.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$ResumeIndexer
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [007] Pause Windows Search Indexer (Build Mode) ==="
$svc = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
if (-not $svc) {
    Write-Output "Windows Search (WSearch) service is not installed."
    return
}

Write-Output ("WSearch Current Status: {0} (StartType: {1})" -f $svc.Status, $svc.StartType)

if ($DryRun -or -not $PSCmdlet.ShouldProcess("WSearch Service", $(if ($ResumeIndexer) { "Start" } else { "Stop" }))) {
    Write-Output ("[DRY-RUN] Would {0} WSearch service." -f $(if ($ResumeIndexer) { "start and enable" } else { "stop for build mode" }))
    return
}

if ($ResumeIndexer) {
    Set-Service -Name "WSearch" -StartupType DelayedStart -ErrorAction SilentlyContinue
    Start-Service -Name "WSearch"
    Write-Output "WSearch resumed."
} else {
    Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
    Write-Output "WSearch paused. Disk and CPU resources freed for builds."
}
