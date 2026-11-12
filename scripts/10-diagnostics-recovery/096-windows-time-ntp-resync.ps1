<#
.SYNOPSIS
    Force High-Precision NTP Clock Resync (Fix OAuth/JWT Drift) (#096)
.DESCRIPTION
    Starts w32time and runs w32tm /resync /force to eliminate system clock drift.
.EXAMPLE
    .\096-windows-time-ntp-resync.ps1 -DryRun

    Simulates the change without modifying the system.

    .\096-windows-time-ntp-resync.ps1

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

Write-Output "=== [096] Force High-Precision NTP Clock Resync ==="
Write-Output ("Current Local Time: {0:yyyy-MM-dd HH:mm:ss.fff zzz}" -f (Get-Date))

if ($DryRun -or -not $PSCmdlet.ShouldProcess("w32time Service", "Start and w32tm /resync /force")) {
    Write-Output "[DRY-RUN] Would start w32time service and run w32tm /resync /force."
    return
}

Start-Service -Name "w32time" -ErrorAction SilentlyContinue
& w32tm.exe /resync /force
Write-Output ("Synced Time: {0:yyyy-MM-dd HH:mm:ss.fff zzz}" -f (Get-Date))
