<#
.SYNOPSIS
    Hyper-V Hypervisor LaunchType Switcher (Auto vs Off) (#049)
.DESCRIPTION
    Checks or toggles bcdedit /set hypervisorlaunchtype auto|off.
.EXAMPLE
    .\049-hypervisor-launchtype-toggle.ps1 -DryRun

    Simulates the change without modifying the system.

    .\049-hypervisor-launchtype-toggle.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [ValidateSet("Auto", "Off")]
    [string]$LaunchType = "Auto"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Fail fast with a structured error instead of a raw PowerShell dump, so the
# calling app can record exactly what went wrong.
trap {
    Write-Output ("[ERROR] Script failed: " + $_.Exception.Message)
    exit 1
}

Write-Output "=== [049] Hyper-V Hypervisor LaunchType Switcher ==="
$cs = Get-CimInstance -ClassName Win32_ComputerSystem
Write-Output ("HypervisorPresent currently: {0}" -f $cs.HypervisorPresent)

if ($DryRun -or -not $PSCmdlet.ShouldProcess("BCDEdit hypervisorlaunchtype", "Set to $LaunchType")) {
    Write-Output "[DRY-RUN] Would run: bcdedit /set hypervisorlaunchtype $($LaunchType.ToLower())"
    return
}

& bcdedit.exe /set hypervisorlaunchtype $LaunchType.ToLower()
Write-Output "Set hypervisorlaunchtype to $LaunchType. Reboot required to apply."
