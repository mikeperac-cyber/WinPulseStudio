<#
.SYNOPSIS
    NVIDIA GPU Compute Power & Clock Tuner (#027)
.DESCRIPTION
    Uses nvidia-smi to inspect GPU thermals, power draw, P-State, and configure compute modes.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [int]$PowerLimitWatts = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [027] NVIDIA GPU Compute Power & Clock Tuner ==="
$smi = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
if (-not $smi) {
    Write-Output "nvidia-smi not found on PATH. Checking WMI VideoController fallback..."
    Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion, VideoProcessor | Format-Table -AutoSize | Out-String | Write-Output
    return
}

& nvidia-smi --query-gpu=index,name,pstate,temperature.gpu,power.draw,power.default_limit,clocks.gr,clocks.mem --format=csv
if ($DryRun -or $PowerLimitWatts -le 0 -or -not $PSCmdlet.ShouldProcess("NVIDIA GPU", "Set Power Limit to ${PowerLimitWatts}W")) {
    Write-Output "[DRY-RUN / INFO] Pass -PowerLimitWatts <W> as Administrator to lock custom GPU power envelope."
    return
}

& nvidia-smi -pl $PowerLimitWatts
Write-Output "Applied NVIDIA GPU power limit: ${PowerLimitWatts}W"
