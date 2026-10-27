<#
.SYNOPSIS
    Multi-Target Ping, Jitter & Edge Latency Benchmark (#060)
.DESCRIPTION
    Measures RTT latency and jitter across key network hops.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [060] Multi-Target Ping, Jitter & Edge Latency Benchmark ==="
$targets = @("1.1.1.1", "8.8.8.8", "github.com")

foreach ($t in $targets) {
    $samples = @()
    for ($i = 0; $i -lt 3; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $ok = Test-Connection -ComputerName $t -Count 1 -Quiet -ErrorAction SilentlyContinue
        $sw.Stop()
        if ($ok) { $samples += $sw.ElapsedMilliseconds }
    }
    if ($samples.Count -gt 0) {
        $avg = [math]::Round(($samples | Measure-Object -Average).Average, 1)
        $min = ($samples | Measure-Object -Minimum).Minimum
        $max = ($samples | Measure-Object -Maximum).Maximum
        $jitter = $max - $min
        Write-Output ("Target {0,-15} -> Avg: {1,5} ms | Min: {2,4} ms | Max: {3,4} ms | Jitter: {4} ms" -f $t, $avg, $min, $max, $jitter)
    } else {
        Write-Output ("Target {0,-15} -> Unreachable" -f $t)
    }
}
