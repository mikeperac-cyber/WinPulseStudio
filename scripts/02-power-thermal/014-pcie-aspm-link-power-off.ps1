<#
.SYNOPSIS
    Disable PCIe Link State Power Management (ASPM) (#014)
.DESCRIPTION
    Configures SUB_PCIEXPRESS ASPM to 0 (Off) on AC power and 1 (Moderate Power Savings) on DC power.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [014] Disable PCIe Link State Power Management (ASPM) ==="
if ($DryRun -or -not $PSCmdlet.ShouldProcess("SCHEME_CURRENT SUB_PCIEXPRESS", "Disable ASPM on AC")) {
    Write-Output "[DRY-RUN] Would run powercfg /setacvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 0."
    return
}

& powercfg.exe /setacvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 0
& powercfg.exe /setdcvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 1
& powercfg.exe /setactive SCHEME_CURRENT
Write-Output "PCIe Link State Power Management disabled on AC power for zero wake latency."
