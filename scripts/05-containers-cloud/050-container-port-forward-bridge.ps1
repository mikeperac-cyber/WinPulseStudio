<#
.SYNOPSIS
    WSL2 / Container to LAN Port Proxy Manager (#050)
.DESCRIPTION
    Lists active netsh portproxy rules and optionally adds or resets a v4tov4 port bridge.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [int]$ListenPort = 0,
    [string]$ConnectAddress = "127.0.0.1",
    [int]$ConnectPort = 0,
    [switch]$ResetAllProxies
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [050] WSL2 / Container to LAN Port Proxy Manager ==="
& netsh.exe interface portproxy show all

if ($DryRun) {
    Write-Output "[DRY-RUN] Inspected netsh interface portproxy table."
    return
}

if ($ResetAllProxies -and $PSCmdlet.ShouldProcess("netsh portproxy", "Reset all rules")) {
    & netsh.exe interface portproxy reset
    Write-Output "All portproxy rules cleared."
} elseif ($ListenPort -gt 0 -and $ConnectPort -gt 0 -and $PSCmdlet.ShouldProcess("Port $ListenPort -> ${ConnectAddress}:${ConnectPort}", "Add v4tov4 proxy")) {
    & netsh.exe interface portproxy add v4tov4 listenport=$ListenPort listenaddress=0.0.0.0 connectport=$ConnectPort connectaddress=$ConnectAddress
    Write-Output "Added port proxy: 0.0.0.0:$ListenPort -> ${ConnectAddress}:${ConnectPort}"
}
