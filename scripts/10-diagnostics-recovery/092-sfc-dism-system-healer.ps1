<#
.SYNOPSIS
    DISM Image Health & SFC Integrity Verifier (#092)
.DESCRIPTION
    Runs DISM /Online /Cleanup-Image /CheckHealth to verify Windows component store integrity.
.EXAMPLE
    .\092-sfc-dism-system-healer.ps1 -DryRun

    Simulates the change without modifying the system.

    .\092-sfc-dism-system-healer.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [092] DISM Image Health & SFC Integrity Verifier ==="
if ($DryRun -or -not $PSCmdlet.ShouldProcess("Windows Component Store", "DISM /CheckHealth")) {
    Write-Output "[DRY-RUN] Would execute: Dism.exe /Online /Cleanup-Image /CheckHealth"
    return
}

& Dism.exe /Online /Cleanup-Image /CheckHealth
