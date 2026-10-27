<#
.SYNOPSIS
    Zombie Localhost Dev Port Reaper (#033)
.DESCRIPTION
    Finds TCP listeners on common dev server ports (3000, 5173, 8000, 8080, etc.) and optionally terminates orphaned processes.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [int[]]$Ports = @(3000, 3001, 4200, 5000, 5001, 5173, 5174, 8000, 8080, 8888),
    [switch]$KillListeners
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [033] Zombie Localhost Dev Port Reaper ==="
$listeners = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in $Ports }

if (-not $listeners) {
    Write-Output ("No processes are currently holding dev ports: {0}" -f ($Ports -join ', '))
    return
}

foreach ($conn in $listeners) {
    $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
    $pName = if ($proc) { $proc.ProcessName } else { "Unknown" }
    Write-Output ("Port {0,-5} -> PID {1,-6} ({2})" -f $conn.LocalPort, $conn.OwningProcess, $pName)

    if (-not $DryRun -and $KillListeners -and $PSCmdlet.ShouldProcess("PID $($conn.OwningProcess) ($pName) on port $($conn.LocalPort)", "Stop-Process")) {
        Stop-Process -Id $conn.OwningProcess -Force
        Write-Output "  [KILLED] Terminated PID $($conn.OwningProcess) ($pName) freeing port $($conn.LocalPort)."
    }
}

if ($DryRun -or -not $KillListeners) {
    Write-Output "[DRY-RUN / SCAN] Pass -KillListeners to terminate the processes above."
}
