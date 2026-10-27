<#
.SYNOPSIS
    Force High-Precision NTP Clock Resync (Fix OAuth/JWT Drift) (#096)
.DESCRIPTION
    Starts w32time and runs w32tm /resync /force to eliminate system clock drift.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [096] Force High-Precision NTP Clock Resync ==="
Write-Output ("Current Local Time: {0:yyyy-MM-dd HH:mm:ss.fff zzz}" -f (Get-Date))

if ($DryRun -or -not $PSCmdlet.ShouldProcess("w32time Service", "Start and w32tm /resync /force")) {
    Write-Output "[DRY-RUN] Would start w32time service and run w32tm /resync /force."
    return
}

Start-Service -Name "w32time" -ErrorAction SilentlyContinue
& w32tm.exe /resync /force
Write-Output ("Synced Time: {0:yyyy-MM-dd HH:mm:ss.fff zzz}" -f (Get-Date))
