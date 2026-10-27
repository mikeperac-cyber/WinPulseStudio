<#
.SYNOPSIS
    Create Instant System Restore Checkpoint (#091)
.DESCRIPTION
    Uses Enable-ComputerRestore and Checkpoint-Computer to create a safe rollback point.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [string]$Description = "WinPulse Studio Pre-Optimization Checkpoint"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [091] Create Instant System Restore Checkpoint ==="
if ($DryRun -or -not $PSCmdlet.ShouldProcess("System Drive C:", "Checkpoint-Computer '$Description'")) {
    Write-Output "[DRY-RUN] Would enable System Restore on C:\ and create checkpoint: '$Description'."
    return
}

Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS"
Write-Output "Created System Restore Point: '$Description'"
