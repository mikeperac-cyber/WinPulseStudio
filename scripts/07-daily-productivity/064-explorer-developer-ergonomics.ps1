<#
.SYNOPSIS
    File Explorer Developer Ergonomics (#064)
.DESCRIPTION
    Sets HideFileExt=0, Hidden=1, LaunchTo=1 (This PC), and UseCompactMode=1 in HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [064] File Explorer Developer Ergonomics ==="
$advKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$cur = Get-ItemProperty -Path $advKey -ErrorAction SilentlyContinue
Write-Output ("Current HideFileExt : {0} (0 = Show Extensions)" -f $cur.HideFileExt)
Write-Output ("Current Hidden      : {0} (1 = Show Hidden Files)" -f $cur.Hidden)

if ($DryRun -or -not $PSCmdlet.ShouldProcess($advKey, "Configure Developer Explorer View")) {
    Write-Output "[DRY-RUN] Would set HideFileExt=0, Hidden=1, LaunchTo=1, UseCompactMode=1."
    return
}

Set-ItemProperty -Path $advKey -Name "HideFileExt" -Value 0 -Type DWord
Set-ItemProperty -Path $advKey -Name "Hidden" -Value 1 -Type DWord
Set-ItemProperty -Path $advKey -Name "LaunchTo" -Value 1 -Type DWord
Set-ItemProperty -Path $advKey -Name "UseCompactMode" -Value 1 -Type DWord
Write-Output "File Explorer configured for developers (File extensions, dotfiles, and Compact Mode enabled)."
