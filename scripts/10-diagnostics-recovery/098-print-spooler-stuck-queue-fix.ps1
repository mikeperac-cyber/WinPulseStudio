<#
.SYNOPSIS
    Flush Stuck Print Spooler & Virtual PDF Queue (#098)
.DESCRIPTION
    Stops Spooler service, clears C:\Windows\System32\spool\PRINTERS, and restarts Spooler.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [098] Flush Stuck Print Spooler & Virtual PDF Queue ==="
$spoolFolder = "$env:SystemRoot\System32\spool\PRINTERS"
if ($DryRun -or -not $PSCmdlet.ShouldProcess("Spooler Service & $spoolFolder", "Stop Spooler, clear stuck jobs, restart")) {
    Write-Output "[DRY-RUN] Would stop Spooler, clear files in $spoolFolder, and start Spooler."
    return
}

Stop-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
if (Test-Path $spoolFolder) {
    Get-ChildItem -Path $spoolFolder -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}
Start-Service -Name "Spooler"
Write-Output "Print Spooler queue flushed and service restarted."
