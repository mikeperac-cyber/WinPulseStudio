<#
.SYNOPSIS
    Windows Copilot & Recall Resource Controller (#028)
.DESCRIPTION
    Configures TurnOffWindowsCopilot and DisableAIDataAnalysis policies to manage background Windows AI resource usage.
.EXAMPLE
    .\028-windows-copilot-recall-control.ps1 -DryRun

    Simulates the change without modifying the system.

    .\028-windows-copilot-recall-control.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$EnableWindowsAI
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Fail fast with a structured error instead of a raw PowerShell dump, so the
# calling app can record exactly what went wrong.
trap {
    Write-Output ("[ERROR] Script failed: " + $_.Exception.Message)
    exit 1
}

Write-Output "=== [028] Windows Copilot & Recall Resource Controller ==="
$copilotUserKey = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
$aiMachineKey   = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
$disableVal = if ($EnableWindowsAI) { 0 } else { 1 }

if ($DryRun -or -not $PSCmdlet.ShouldProcess("WindowsCopilot & WindowsAI Policies", "Set Disable=$disableVal")) {
    Write-Output ("[DRY-RUN] Would set TurnOffWindowsCopilot={0} and DisableAIDataAnalysis={0}." -f $disableVal)
    return
}

if (-not (Test-Path $copilotUserKey)) { New-Item -Path $copilotUserKey -Force | Out-Null }
Set-ItemProperty -Path $copilotUserKey -Name "TurnOffWindowsCopilot" -Value $disableVal -Type DWord

if (-not (Test-Path $aiMachineKey)) { New-Item -Path $aiMachineKey -Force | Out-Null }
Set-ItemProperty -Path $aiMachineKey -Name "DisableAIDataAnalysis" -Value $disableVal -Type DWord

Write-Output ("Windows Copilot & Recall background analysis set to: {0}" -f $(if ($EnableWindowsAI) { "Enabled" } else { "Disabled (Resources Freed)" }))
