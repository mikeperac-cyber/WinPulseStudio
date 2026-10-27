<#
.SYNOPSIS
    Startup App & Prelauncher Slimmer (#009)
.DESCRIPTION
    Audits startup entries across HKCU/HKLM Run keys and disables Edge background prelaunch to save boot time and idle RAM.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [009] Startup App & Prelauncher Slimmer ==="
$runPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
)

foreach ($rp in $runPaths) {
    if (Test-Path $rp) {
        Write-Output "--- $rp ---"
        $props = Get-ItemProperty -Path $rp
        foreach ($p in $props.PSObject.Properties) {
            if ($p.Name -notin @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')) {
                Write-Output ("  [Autorun] {0} => {1}" -f $p.Name, $p.Value)
            }
        }
    }
}

$edgePolicy = "HKCU:\Software\Policies\Microsoft\Edge"
if ($DryRun -or -not $PSCmdlet.ShouldProcess($edgePolicy, "Disable StartupBoostEnabled & BackgroundModeEnabled")) {
    Write-Output "[DRY-RUN] Would disable Edge StartupBoostEnabled and BackgroundModeEnabled in HKCU policies."
    return
}

if (-not (Test-Path $edgePolicy)) { New-Item -Path $edgePolicy -Force | Out-Null }
Set-ItemProperty -Path $edgePolicy -Name "StartupBoostEnabled" -Value 0 -Type DWord
Set-ItemProperty -Path $edgePolicy -Name "BackgroundModeEnabled" -Value 0 -Type DWord
Write-Output "Disabled Edge background prelaunch and startup boost."
