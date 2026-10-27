<#
.SYNOPSIS
    Benchmark & Switch to Fastest Public DNS (#052)
.DESCRIPTION
    Measures response time to Cloudflare (1.1.1.1), Google (8.8.8.8), and Quad9 (9.9.9.9) and optionally applies the winner.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [ValidateSet("AutoFastest", "Cloudflare", "Google", "Quad9", "ResetDHCP")]
    [string]$Provider = "AutoFastest"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [052] Benchmark & Switch to Fastest Public DNS ==="
$providers = @(
    @{ Name = "Cloudflare"; Primary = "1.1.1.1"; Secondary = "1.0.0.1" },
    @{ Name = "Google";     Primary = "8.8.8.8"; Secondary = "8.8.4.4" },
    @{ Name = "Quad9";      Primary = "9.9.9.9"; Secondary = "149.112.112.112" }
)

$results = foreach ($p in $providers) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $ok = Test-Connection -ComputerName $p.Primary -Count 1 -Quiet -ErrorAction SilentlyContinue
    $sw.Stop()
    $ms = if ($ok) { $sw.ElapsedMilliseconds } else { 9999 }
    Write-Output ("  {0,-12} ({1}) -> {2} ms" -f $p.Name, $p.Primary, $ms)
    [PSCustomObject]@{ Name = $p.Name; Primary = $p.Primary; Secondary = $p.Secondary; LatencyMs = $ms }
}

$winner = $results | Sort-Object LatencyMs | Select-Object -First 1
Write-Output ("Fastest Resolver: {0} ({1} ms)" -f $winner.Name, $winner.LatencyMs)

if ($DryRun -or -not $PSCmdlet.ShouldProcess("Active NetAdapter DNS", "Apply $Provider DNS")) {
    Write-Output "[DRY-RUN] Would set active adapter DNS to $($winner.Primary), $($winner.Secondary)."
    return
}

$activeAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.Virtual -eq $false }
foreach ($nic in $activeAdapters) {
    if ($Provider -eq "ResetDHCP") {
        Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ResetServerAddresses
        Write-Output "Reset DNS to DHCP on $($nic.Name)"
    } else {
        Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses @($winner.Primary, $winner.Secondary)
        Write-Output "Configured $($winner.Name) DNS ($($winner.Primary)) on $($nic.Name)"
    }
}
