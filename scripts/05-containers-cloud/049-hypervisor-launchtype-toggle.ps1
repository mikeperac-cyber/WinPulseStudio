<#
.SYNOPSIS
    Hyper-V Hypervisor LaunchType Switcher (Auto vs Off) (#049)
.DESCRIPTION
    Checks or toggles bcdedit /set hypervisorlaunchtype auto|off.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [ValidateSet("Auto", "Off")]
    [string]$LaunchType = "Auto"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [049] Hyper-V Hypervisor LaunchType Switcher ==="
$cs = Get-CimInstance -ClassName Win32_ComputerSystem
Write-Output ("HypervisorPresent currently: {0}" -f $cs.HypervisorPresent)

if ($DryRun -or -not $PSCmdlet.ShouldProcess("BCDEdit hypervisorlaunchtype", "Set to $LaunchType")) {
    Write-Output "[DRY-RUN] Would run: bcdedit /set hypervisorlaunchtype $($LaunchType.ToLower())"
    return
}

& bcdedit.exe /set hypervisorlaunchtype $LaunchType.ToLower()
Write-Output "Set hypervisorlaunchtype to $LaunchType. Reboot required to apply."
