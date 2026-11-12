<#
.SYNOPSIS
    Create Instant System Restore Checkpoint (#091)
.DESCRIPTION
    Uses Enable-ComputerRestore and Checkpoint-Computer to create a safe rollback point.
.EXAMPLE
    .\091-create-system-restore-point.ps1 -DryRun

    Simulates the change without modifying the system.

    .\091-create-system-restore-point.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [string]$Description = "WinPulse Studio Pre-Optimization Checkpoint"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Fail fast with a structured error instead of a raw PowerShell dump, so the
# calling app can record exactly what went wrong.
trap {
    Write-Output ("[ERROR] Script failed: " + $_.Exception.Message)
    exit 1
}

Write-Output "=== [091] Create Instant System Restore Checkpoint ==="
if ($DryRun -or -not $PSCmdlet.ShouldProcess("System Drive C:", "Checkpoint-Computer '$Description'")) {
    Write-Output "[DRY-RUN] Would enable System Restore on C:\ and create checkpoint: '$Description'."
    return
}

Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS"
Write-Output "Created System Restore Point: '$Description'"
