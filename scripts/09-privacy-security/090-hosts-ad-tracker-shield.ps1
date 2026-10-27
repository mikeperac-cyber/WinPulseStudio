<#
.SYNOPSIS
    Telemetry & Ad-Tracker Hosts Blocklist Manager (#090)
.DESCRIPTION
    Adds or removes a managed telemetry sinkhole block in C:\Windows\System32\drivers\etc\hosts.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$RemoveShield
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [090] Telemetry & Ad-Tracker Hosts Blocklist Manager ==="
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
$blockDomains = @(
    "0.0.0.0 vortex.data.microsoft.com",
    "0.0.0.0 settings-win.data.microsoft.com",
    "0.0.0.0 telemetry.microsoft.com",
    "0.0.0.0 watson.telemetry.microsoft.com"
)

if ($DryRun -or -not $PSCmdlet.ShouldProcess($hostsFile, "Update WinPulse-Shield section")) {
    Write-Output "[DRY-RUN] Would manage $($blockDomains.Count) telemetry domains in $hostsFile."
    return
}

$raw = Get-Content -Path $hostsFile -Raw
$cleaned = $raw -replace '(?s)# \[WinPulse-Shield-Start\].*?# \[WinPulse-Shield-End\]\r?\n?', ''
if ($RemoveShield) {
    Set-Content -Path $hostsFile -Value $cleaned.TrimEnd() -Encoding Ascii
    Write-Output "Removed WinPulse-Shield blocklist from hosts file."
} else {
    $blockText = "`r`n# [WinPulse-Shield-Start]`r`n" + ($blockDomains -join "`r`n") + "`r`n# [WinPulse-Shield-End]`r`n"
    Set-Content -Path $hostsFile -Value ($cleaned.TrimEnd() + $blockText) -Encoding Ascii
    Write-Output "Applied WinPulse-Shield telemetry sinkhole to hosts file."
}
