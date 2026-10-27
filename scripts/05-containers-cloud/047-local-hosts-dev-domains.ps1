<#
.SYNOPSIS
    Hosts File Local Dev Domain & Docker Entry Auditor (#047)
.DESCRIPTION
    Reads and parses active non-comment entries in the Windows hosts file.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [047] Hosts File Local Dev Domain & Docker Entry Auditor ==="
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
if (-not (Test-Path $hostsPath)) {
    Write-Output "Hosts file not found at $hostsPath"
    return
}

$lines = Get-Content -Path $hostsPath | Where-Object { $_ -notmatch '^\s*#' -and -not [string]::IsNullOrWhiteSpace($_) }
Write-Output ("Active custom host mappings: {0}" -f @($lines).Count)
foreach ($line in $lines) {
    Write-Output ("  {0}" -f $line.Trim())
}
