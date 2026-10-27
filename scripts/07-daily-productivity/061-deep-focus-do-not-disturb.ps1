<#
.SYNOPSIS
    Deep Focus Coding Mode (Mute Toasts & Distractions) (#061)
.DESCRIPTION
    Toggles Windows Toast notifications in HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$RestoreNotifications
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [061] Deep Focus Coding Mode ==="
$pushKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"
$cur = (Get-ItemProperty -Path $pushKey -Name "ToastEnabled" -ErrorAction SilentlyContinue).ToastEnabled
Write-Output ("Current ToastEnabled: {0}" -f $cur)

$target = if ($RestoreNotifications) { 1 } else { 0 }
if ($DryRun -or -not $PSCmdlet.ShouldProcess($pushKey, "Set ToastEnabled=$target")) {
    Write-Output ("[DRY-RUN] Would set ToastEnabled={0} ({1})." -f $target, $(if ($RestoreNotifications) { "Notifications Restored" } else { "Deep Focus Quiet Mode" }))
    return
}

if (-not (Test-Path $pushKey)) { New-Item -Path $pushKey -Force | Out-Null }
Set-ItemProperty -Path $pushKey -Name "ToastEnabled" -Value $target -Type DWord
Write-Output ("Deep Focus Mode: ToastEnabled set to {0}." -f $target)
