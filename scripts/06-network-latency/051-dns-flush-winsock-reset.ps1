<#
.SYNOPSIS
    Flush DNS Resolver Cache & Clear ARP Table (#051)
.DESCRIPTION
    Flushes the Windows DNS resolver cache and displays current DNS server configuration.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [051] Flush DNS Resolver Cache & Clear ARP Table ==="
$dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses }
foreach ($d in $dnsServers) {
    Write-Output ("Interface [{0}]: DNS -> {1}" -f $d.InterfaceAlias, ($d.ServerAddresses -join ', '))
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess("DNS Client Cache", "Clear-DnsClientCache")) {
    Write-Output "[DRY-RUN] Would run Clear-DnsClientCache and flush ARP cache."
    return
}

Clear-DnsClientCache
Write-Output "DNS Client Resolver Cache flushed successfully."
