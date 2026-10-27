<#
.SYNOPSIS
    Developer Snappy UI Visual Effects (#002)
.DESCRIPTION
    Configures Explorer VisualEffects and Desktop WindowMetrics for zero-latency window transitions while keeping ClearType and thumbnails enabled.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$Revert
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [002] Developer Snappy UI Visual Effects ==="
$vfxPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
$advPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$metricsPath = "HKCU:\Control Panel\Desktop\WindowMetrics"
$desktopPath = "HKCU:\Control Panel\Desktop"

$settings = if ($Revert) {
    @{
        VisualFXSetting = 0
        TaskbarAnimations = 1
        ListviewAlphaSelect = 1
        MinAnimate = "1"
        MenuShowDelay = "400"
    }
} else {
    @{
        VisualFXSetting = 3
        TaskbarAnimations = 0
        ListviewAlphaSelect = 1
        MinAnimate = "0"
        MenuShowDelay = "20"
    }
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess("HKCU VisualEffects & Desktop Metrics", "Apply Snappy UI Profile")) {
    Write-Output "[DRY-RUN] Would apply Snappy UI settings (VisualFXSetting=$($settings.VisualFXSetting), MinAnimate=$($settings.MinAnimate), MenuShowDelay=$($settings.MenuShowDelay)ms)."
    return
}

if (-not (Test-Path $vfxPath)) { New-Item -Path $vfxPath -Force | Out-Null }
Set-ItemProperty -Path $vfxPath -Name "VisualFXSetting" -Value $settings.VisualFXSetting -Type DWord
Set-ItemProperty -Path $advPath -Name "TaskbarAnimations" -Value $settings.TaskbarAnimations -Type DWord
Set-ItemProperty -Path $advPath -Name "ListviewAlphaSelect" -Value $settings.ListviewAlphaSelect -Type DWord
Set-ItemProperty -Path $metricsPath -Name "MinAnimate" -Value $settings.MinAnimate -Type String
Set-ItemProperty -Path $desktopPath -Name "MenuShowDelay" -Value $settings.MenuShowDelay -Type String
Set-ItemProperty -Path $desktopPath -Name "FontSmoothing" -Value "2" -Type String
Set-ItemProperty -Path $desktopPath -Name "FontSmoothingType" -Value 2 -Type DWord

Write-Output "Applied Developer Snappy UI profile. ClearType font smoothing remains active."
