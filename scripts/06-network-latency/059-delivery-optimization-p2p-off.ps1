<#
.SYNOPSIS
    Disable Windows Update P2P Upload Bandwidth Drain (#059)
.DESCRIPTION
    Sets DODownloadMode=0 (HTTP Only, no P2P peering) in HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [059] Disable Windows Update P2P Upload Bandwidth Drain ==="
$doKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"

if ($DryRun -or -not $PSCmdlet.ShouldProcess($doKey, "Set DODownloadMode = 0 (HTTP Only)")) {
    Write-Output "[DRY-RUN] Would set DODownloadMode=0 in $doKey to disable P2P background uploads."
    return
}

if (-not (Test-Path $doKey)) { New-Item -Path $doKey -Force | Out-Null }
Set-ItemProperty -Path $doKey -Name "DODownloadMode" -Value 0 -Type DWord
Write-Output "Delivery Optimization P2P upload peering disabled."
