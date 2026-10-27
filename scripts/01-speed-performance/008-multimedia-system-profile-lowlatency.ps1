<#
.SYNOPSIS
    MMCSS Low-Latency System Responsiveness (#008)
.DESCRIPTION
    Tunes HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile for low-latency audio/video/network throughput.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$Revert
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [008] MMCSS Low-Latency System Responsiveness ==="
$mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
$current = Get-ItemProperty -Path $mmPath -ErrorAction SilentlyContinue
Write-Output ("Current SystemResponsiveness  : {0}" -f $current.SystemResponsiveness)
Write-Output ("Current NetworkThrottlingIndex: {0}" -f $current.NetworkThrottlingIndex)

$targetResp = if ($Revert) { 20 } else { 10 }
$targetNet  = if ($Revert) { 10 } else { 0xFFFFFFFF }

if ($DryRun -or -not $PSCmdlet.ShouldProcess($mmPath, "Set SystemResponsiveness=$targetResp")) {
    Write-Output "[DRY-RUN] Would set SystemResponsiveness=$targetResp and NetworkThrottlingIndex=$targetNet."
    return
}

Set-ItemProperty -Path $mmPath -Name "SystemResponsiveness" -Value $targetResp -Type DWord
Set-ItemProperty -Path $mmPath -Name "NetworkThrottlingIndex" -Value $targetNet -Type DWord
Write-Output "MMCSS SystemProfile tuned for low-latency operation."
