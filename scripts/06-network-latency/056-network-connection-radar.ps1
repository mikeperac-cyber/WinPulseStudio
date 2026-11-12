<#
.SYNOPSIS
    Live External TCP Connection & Process Radar (#056)
.DESCRIPTION
    Lists all Established non-loopback TCP connections grouped by process name.
.EXAMPLE
    .\056-network-connection-radar.ps1 -DryRun

    Simulates the change without modifying the system.

    .\056-network-connection-radar.ps1

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

Write-Output "=== [056] Live External TCP Connection & Process Radar ==="
$conns = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue |
    Where-Object { $_.RemoteAddress -notin @('127.0.0.1', '::1') }

$report = foreach ($c in $conns) {
    $p = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        ProcessName   = if ($p) { $p.ProcessName } else { "PID-$($c.OwningProcess)" }
        PID           = $c.OwningProcess
        LocalPort     = $c.LocalPort
        RemoteAddress = $c.RemoteAddress
        RemotePort    = $c.RemotePort
    }
}

$report | Sort-Object ProcessName | Format-Table -AutoSize | Out-String | Write-Output
Write-Output ("Total Active External Connections: {0}" -f @($report).Count)
