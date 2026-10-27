<#
.SYNOPSIS
    WSL2 Distro Inspector & LxssManager Cold Restart (#042)
.DESCRIPTION
    Audits wsl --list --verbose and performs a clean shutdown/restart of WSL2 services.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [042] WSL2 Distro Inspector & LxssManager Cold Restart ==="
if (-not (Get-Command "wsl" -ErrorAction SilentlyContinue)) {
    Write-Output "WSL is not installed."
    return
}

& wsl.exe --status
& wsl.exe --list --verbose

if ($DryRun -or -not $PSCmdlet.ShouldProcess("WSL2 VM & Service", "Shutdown and restart WSLService")) {
    Write-Output "[DRY-RUN] Would run 'wsl --shutdown' and restart WSLService."
    return
}

& wsl.exe --shutdown
$wslSvc = Get-Service -Name "WslService" -ErrorAction SilentlyContinue
if ($wslSvc) {
    Restart-Service -Name "WslService" -Force
}
Write-Output "WSL2 utility VM cleanly reset."
