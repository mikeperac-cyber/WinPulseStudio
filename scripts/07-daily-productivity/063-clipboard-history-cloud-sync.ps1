<#
.SYNOPSIS
    Enable Win+V Multi-Slot Clipboard History & Sanitizer (#063)
.DESCRIPTION
    Enables EnableClipboardHistory=1 in HKCU:\Software\Microsoft\Clipboard.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$ClearCurrentClipboard
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [063] Enable Win+V Multi-Slot Clipboard History & Sanitizer ==="
$clipKey = "HKCU:\Software\Microsoft\Clipboard"
$enabled = (Get-ItemProperty -Path $clipKey -Name "EnableClipboardHistory" -ErrorAction SilentlyContinue).EnableClipboardHistory
Write-Output ("Clipboard History Currently Enabled: {0}" -f ($enabled -eq 1))

if ($DryRun -or -not $PSCmdlet.ShouldProcess($clipKey, "EnableClipboardHistory = 1")) {
    Write-Output "[DRY-RUN] Would set EnableClipboardHistory = 1 in $clipKey."
    return
}

if (-not (Test-Path $clipKey)) { New-Item -Path $clipKey -Force | Out-Null }
Set-ItemProperty -Path $clipKey -Name "EnableClipboardHistory" -Value 1 -Type DWord
if ($ClearCurrentClipboard) {
    Set-Clipboard -Value $null
    Write-Output "Cleared active clipboard content."
}
Write-Output "Win+V Multi-Slot Clipboard History enabled."
