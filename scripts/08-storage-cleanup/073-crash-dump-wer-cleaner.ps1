<#
.SYNOPSIS
    Purge Memory Dumps, Minidumps & WER Crash Queues (#073)
.DESCRIPTION
    Scans and removes application crash dumps and Windows Error Reporting archives.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [073] Purge Memory Dumps, Minidumps & WER Crash Queues ==="
$dumpPaths = @(
    (Join-Path $env:LOCALAPPDATA "CrashDumps"),
    (Join-Path $env:LOCALAPPDATA "Microsoft\Windows\WER\ReportArchive"),
    (Join-Path $env:LOCALAPPDATA "Microsoft\Windows\WER\ReportQueue"),
    "C:\ProgramData\Microsoft\Windows\WER\ReportArchive",
    "C:\ProgramData\Microsoft\Windows\WER\ReportQueue"
)

$totalMB = 0.0
foreach ($dp in $dumpPaths) {
    if (Test-Path $dp) {
        $files = Get-ChildItem -Path $dp -Recurse -File -ErrorAction SilentlyContinue
        $mb = [math]::Round((($files | Measure-Object -Property Length -Sum).Sum / 1MB), 2)
        $totalMB += $mb
        Write-Output ("[{0}] -> {1} MB ({2} files)" -f $dp, $mb, @($files).Count)
        if (-not $DryRun -and $PSCmdlet.ShouldProcess($dp, "Delete crash dump files")) {
            $files | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
}
Write-Output ("Total Crash Dump & WER Space Found: {0} MB" -f $totalMB)
