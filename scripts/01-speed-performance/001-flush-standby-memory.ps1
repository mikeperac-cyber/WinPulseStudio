<#
.SYNOPSIS
    Purge Standby & Working Set RAM (#001)
.DESCRIPTION
    Uses Win32 EmptyWorkingSet API to trim idle pages from background processes and reports memory freed.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [001] Purge Standby & Working Set RAM ==="
$osBefore = Get-CimInstance -ClassName Win32_OperatingSystem
$freeBeforeMB = [math]::Round($osBefore.FreePhysicalMemory / 1024, 1)
$totalMB = [math]::Round($osBefore.TotalVisibleMemorySize / 1024, 1)
Write-Output ("Memory Before : {0} MB free / {1} MB total" -f $freeBeforeMB, $totalMB)

$processes = Get-Process | Where-Object { $_.WorkingSet64 -gt 20MB -and $_.Id -ne $PID -and $_.ProcessName -notin @('Idle', 'System', 'Memory Compression') }
Write-Output ("Target Processes (>20MB WS): {0}" -f $processes.Count)

if ($DryRun -or -not $PSCmdlet.ShouldProcess("System Processes", "EmptyWorkingSet")) {
    Write-Output "[DRY-RUN] Would invoke psapi.dll::EmptyWorkingSet on $($processes.Count) processes."
    $top5 = $processes | Sort-Object WorkingSet64 -Descending | Select-Object -First 5
    foreach ($p in $top5) {
        Write-Output ("  -> {0} (PID {1}): {2} MB" -f $p.ProcessName, $p.Id, [math]::Round($p.WorkingSet64 / 1MB, 1))
    }
    return
}

$signature = @"
using System;
using System.Runtime.InteropServices;
public static class MemoryTrimmer {
    [DllImport("psapi.dll", SetLastError = true)]
    public static extern bool EmptyWorkingSet(IntPtr hProcess);
}
"@
if (-not ([System.Management.Automation.PSTypeName]'MemoryTrimmer').Type) {
    Add-Type -TypeDefinition $signature -Language CSharp
}

$trimmedCount = 0
foreach ($proc in $processes) {
    try {
        if ($proc.Handle) {
            [void][MemoryTrimmer]::EmptyWorkingSet($proc.Handle)
            $trimmedCount++
        }
    } catch {
        # Ignore protected system processes
    }
}

[System.GC]::Collect()
Start-Sleep -Milliseconds 600
$osAfter = Get-CimInstance -ClassName Win32_OperatingSystem
$freeAfterMB = [math]::Round($osAfter.FreePhysicalMemory / 1024, 1)
$deltaMB = [math]::Round($freeAfterMB - $freeBeforeMB, 1)
Write-Output ("Trimmed {0} processes. Memory After: {1} MB free (Reclaimed: {2} MB)" -f $trimmedCount, $freeAfterMB, $deltaMB)
