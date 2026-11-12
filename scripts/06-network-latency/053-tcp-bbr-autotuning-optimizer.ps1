<#
.SYNOPSIS
    TCP Stack, Receive Window Auto-Tuning & RSS Optimizer (#053)
.DESCRIPTION
    Audits and optimizes netsh int tcp global parameters for high-speed developer downloads and low latency.
.EXAMPLE
    .\053-tcp-bbr-autotuning-optimizer.ps1 -DryRun

    Simulates the change without modifying the system.

    .\053-tcp-bbr-autotuning-optimizer.ps1

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

Write-Output "=== [053] TCP Stack, Receive Window Auto-Tuning & RSS Optimizer ==="
& netsh.exe int tcp show global

if ($DryRun -or -not $PSCmdlet.ShouldProcess("netsh int tcp global", "Apply AutoTuning=normal & RSS=enabled")) {
    Write-Output "[DRY-RUN] Would run netsh int tcp set global autotuninglevel=normal rss=enabled."
    return
}

& netsh.exe int tcp set global autotuninglevel=normal | Out-Null
& netsh.exe int tcp set global rss=enabled | Out-Null
Write-Output "TCP Receive Window Auto-Tuning and RSS enabled."
