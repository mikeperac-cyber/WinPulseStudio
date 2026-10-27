<#
.SYNOPSIS
    Extend GPU TDR Timeout for Local LLM / CUDA Kernels (#021)
.DESCRIPTION
    Sets TdrDelay and TdrDdiDelay in HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers to prevent premature GPU resets during long compute kernels.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [int]$TimeoutSeconds = 60,
    [switch]$RevertDefault
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [021] Extend GPU TDR Timeout for Local LLM / CUDA Kernels ==="
$gfxPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
$cur = Get-ItemProperty -Path $gfxPath -ErrorAction SilentlyContinue
Write-Output ("Current TdrDelay   : {0}" -f $(if ($null -ne $cur.TdrDelay) { "$($cur.TdrDelay)s" } else { "2s (Windows Default)" }))

$target = if ($RevertDefault) { 2 } else { $TimeoutSeconds }
if ($DryRun -or -not $PSCmdlet.ShouldProcess($gfxPath, "Set TdrDelay=$target seconds")) {
    Write-Output "[DRY-RUN] Would set TdrDelay=$target and TdrDdiDelay=$target in $gfxPath."
    return
}

Set-ItemProperty -Path $gfxPath -Name "TdrDelay" -Value $target -Type DWord
Set-ItemProperty -Path $gfxPath -Name "TdrDdiDelay" -Value $target -Type DWord
Write-Output "GPU TDR timeout set to ${target}s. Reboot required to take full effect."
