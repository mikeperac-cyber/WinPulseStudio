<#
.SYNOPSIS
    Toggle Windows 11 Full Classic Right-Click Context Menu (#065)
.DESCRIPTION
    Creates or removes HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$RestoreModernMenu
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [065] Toggle Windows 11 Full Classic Right-Click Context Menu ==="
$clsidPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
$isClassic = Test-Path $clsidPath
Write-Output ("Classic Context Menu Currently Active: {0}" -f $isClassic)

if ($DryRun -or -not $PSCmdlet.ShouldProcess($clsidPath, $(if ($RestoreModernMenu) { "Remove Classic Menu" } else { "Enable Classic Menu" }))) {
    Write-Output "[DRY-RUN] Would update CLSID {86ca1aa0-34aa-4e8b-a509-50c905bae2a2} InprocServer32."
    return
}

if ($RestoreModernMenu) {
    Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Output "Restored Windows 11 default compact context menu."
} else {
    New-Item -Path $clsidPath -Force | Out-Null
    Set-ItemProperty -Path $clsidPath -Name "(Default)" -Value "" -Type String
    Write-Output "Enabled full classic right-click context menu (restart Explorer to apply)."
}
