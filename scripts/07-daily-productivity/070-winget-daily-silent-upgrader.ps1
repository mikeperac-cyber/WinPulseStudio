<#
.SYNOPSIS
    WinGet Outdated App Scanner & Silent Upgrader (#070)
.DESCRIPTION
    Lists available package upgrades via winget and optionally upgrades all packages silently.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$UpgradeAll
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [070] WinGet Outdated App Scanner & Silent Upgrader ==="
if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Output "winget is not installed on PATH."
    return
}

& winget.exe upgrade --accept-source-agreements

if ($DryRun -or -not $UpgradeAll -or -not $PSCmdlet.ShouldProcess("WinGet Packages", "winget upgrade --all --silent")) {
    Write-Output "`n[DRY-RUN / AUDIT] Pass -UpgradeAll to silently upgrade all listed packages."
    return
}

& winget.exe upgrade --all --silent --accept-package-agreements --accept-source-agreements
