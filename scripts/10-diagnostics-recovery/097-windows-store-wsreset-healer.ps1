<#
.SYNOPSIS
    Microsoft Store & App Installer Cache Healer (#097)
.DESCRIPTION
    Clears Microsoft.WindowsStore LocalCache directory and verifies DesktopAppInstaller package status.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [097] Microsoft Store & App Installer Cache Healer ==="
$storePkg = Get-AppxPackage -Name "*WindowsStore*" -ErrorAction SilentlyContinue
$installerPkg = Get-AppxPackage -Name "*DesktopAppInstaller*" -ErrorAction SilentlyContinue

if ($storePkg) { Write-Output ("Windows Store Version     : {0}" -f $storePkg.Version) }
if ($installerPkg) { Write-Output ("App Installer (winget) Ver: {0}" -f $installerPkg.Version) }

$storeCache = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalCache"
if ($DryRun -or -not $PSCmdlet.ShouldProcess($storeCache, "Clear Windows Store LocalCache")) {
    Write-Output "[DRY-RUN] Would clear cached files in $storeCache."
    return
}

if (Test-Path $storeCache) {
    Get-ChildItem -Path $storeCache -Recurse -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Output "Microsoft Store LocalCache cleared."
}
