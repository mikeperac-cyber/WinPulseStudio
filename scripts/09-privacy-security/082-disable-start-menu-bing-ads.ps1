<#
.SYNOPSIS
    Disable Start Menu Bing Web Search & Suggested Ads (#082)
.DESCRIPTION
    Sets DisableSearchBoxSuggestions=1 and disables ContentDeliveryManager silent app installs.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$RestoreBingSearch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [082] Disable Start Menu Bing Web Search & Suggested Ads ==="
$explorerPolicy = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
$cdmKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$disableVal = if ($RestoreBingSearch) { 0 } else { 1 }

if ($DryRun -or -not $PSCmdlet.ShouldProcess($explorerPolicy, "Set DisableSearchBoxSuggestions=$disableVal")) {
    Write-Output "[DRY-RUN] Would set DisableSearchBoxSuggestions=$disableVal and disable ContentDeliveryManager SilentInstalledAppsEnabled."
    return
}

if (-not (Test-Path $explorerPolicy)) { New-Item -Path $explorerPolicy -Force | Out-Null }
Set-ItemProperty -Path $explorerPolicy -Name "DisableSearchBoxSuggestions" -Value $disableVal -Type DWord

if (Test-Path $cdmKey) {
    Set-ItemProperty -Path $cdmKey -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord
    Set-ItemProperty -Path $cdmKey -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord
    Set-ItemProperty -Path $cdmKey -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord
}
Write-Output "Start Menu Bing web search and suggested ads disabled. Local search is now strictly local and instant."
