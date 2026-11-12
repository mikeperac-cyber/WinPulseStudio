<#
.SYNOPSIS
    VRAM Pre-Flight Cleaner for AI Inference (#024)
.DESCRIPTION
    Audits GPU VRAM consumers via nvidia-smi / Performance Counters and optionally closes non-essential background GPU apps.
.EXAMPLE
    .\024-vram-hog-process-reaper.ps1 -DryRun

    Simulates the change without modifying the system.

    .\024-vram-hog-process-reaper.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$CloseBackgroundGpuApps
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Fail fast with a structured error instead of a raw PowerShell dump, so the
# calling app can record exactly what went wrong.
trap {
    Write-Output ("[ERROR] Script failed: " + $_.Exception.Message)
    exit 1
}

Write-Output "=== [024] VRAM Pre-Flight Cleaner for AI Inference ==="
$nvidiaSmi = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
if ($nvidiaSmi) {
    Write-Output "--- NVIDIA GPU Memory Status ---"
    & nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free,utilization.gpu --format=csv
} else {
    $gpus = Get-CimInstance -ClassName Win32_VideoController
    foreach ($g in $gpus) {
        Write-Output ("GPU: {0} | AdapterRAM: {1} MB | Driver: {2}" -f $g.Name, [math]::Round($g.AdapterRAM / 1MB, 0), $g.DriverVersion)
    }
}

$vramHogs = @('steamwebhelper', 'EpicGamesLauncher', 'wallpaper32', 'wallpaper64', 'Discord', 'Overwolf', 'XboxPcApp')
$runningHogs = Get-Process | Where-Object { $_.ProcessName -in $vramHogs }

Write-Output ("Detected {0} background GPU-accelerated consumer apps." -f @($runningHogs).Count)
foreach ($p in $runningHogs) {
    Write-Output ("  -> {0} (PID {1}) - WorkingSet: {2} MB" -f $p.ProcessName, $p.Id, [math]::Round($p.WorkingSet64 / 1MB, 1))
}

if ($DryRun -or -not $CloseBackgroundGpuApps -or -not $PSCmdlet.ShouldProcess("Background GPU Apps", "Stop Processes")) {
    Write-Output "[DRY-RUN / AUDIT] Pass -CloseBackgroundGpuApps to terminate listed background VRAM consumers."
    return
}

foreach ($p in $runningHogs) {
    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    Write-Output "Stopped $($p.ProcessName) (PID $($p.Id))."
}
