<#
.SYNOPSIS
    Enable Developer Mode, Sudo & Win32 Long Paths (#032)
.DESCRIPTION
    Sets LongPathsEnabled=1 in FileSystem and AllowDevelopmentWithoutDevLicense=1 in AppModelUnlock.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [032] Enable Developer Mode, Sudo & Win32 Long Paths ==="
$fsKey = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
$devKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"

$longPaths = (Get-ItemProperty -Path $fsKey -Name "LongPathsEnabled" -ErrorAction SilentlyContinue).LongPathsEnabled
Write-Output ("Current LongPathsEnabled: {0}" -f $longPaths)

if ($DryRun -or -not $PSCmdlet.ShouldProcess("HKLM FileSystem & AppModelUnlock", "Enable LongPaths & Developer Mode")) {
    Write-Output "[DRY-RUN] Would set LongPathsEnabled=1 and AllowDevelopmentWithoutDevLicense=1."
    return
}

Set-ItemProperty -Path $fsKey -Name "LongPathsEnabled" -Value 1 -Type DWord
if (-not (Test-Path $devKey)) { New-Item -Path $devKey -Force | Out-Null }
Set-ItemProperty -Path $devKey -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord
Set-ItemProperty -Path $devKey -Name "AllowAllTrustedApps" -Value 1 -Type DWord

Write-Output "Win32 Long Paths (>260 chars) and Developer Mode symlinks enabled."
