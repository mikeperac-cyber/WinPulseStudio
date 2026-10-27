<#
.SYNOPSIS
    Instant System & App Dark / Light Mode Switcher (#062)
.DESCRIPTION
    Toggles AppsUseLightTheme and SystemUsesLightTheme in HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [ValidateSet("Dark", "Light", "Toggle")]
    [string]$Theme = "Dark"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [062] Instant System & App Dark / Light Mode Switcher ==="
$themeKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$curLight = (Get-ItemProperty -Path $themeKey -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue).AppsUseLightTheme

$newVal = switch ($Theme) {
    "Dark"   { 0 }
    "Light"  { 1 }
    "Toggle" { if ($curLight -eq 1) { 0 } else { 1 } }
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess($themeKey, "Set LightTheme=$newVal")) {
    Write-Output ("[DRY-RUN] Would switch Windows System & App theme to: {0}" -f $(if ($newVal -eq 0) { "Dark Mode" } else { "Light Mode" }))
    return
}

Set-ItemProperty -Path $themeKey -Name "AppsUseLightTheme" -Value $newVal -Type DWord
Set-ItemProperty -Path $themeKey -Name "SystemUsesLightTheme" -Value $newVal -Type DWord
Write-Output ("Switched Windows theme to {0}." -f $(if ($newVal -eq 0) { "Dark Mode" } else { "Light Mode" }))
