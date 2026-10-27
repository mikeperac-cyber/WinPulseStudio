<#
.SYNOPSIS
    Disable Windows Activity History & Purge Recent Jump Lists (#088)
.DESCRIPTION
    Disables PublishUserActivities and UploadUserActivities in HKLM:\SOFTWARE\Policies\Microsoft\Windows\System.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [088] Disable Windows Activity History & Purge Recent Jump Lists ==="
$sysPol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"

if ($DryRun -or -not $PSCmdlet.ShouldProcess($sysPol, "Disable PublishUserActivities & UploadUserActivities")) {
    Write-Output "[DRY-RUN] Would set EnableActivityFeed=0, PublishUserActivities=0, UploadUserActivities=0."
    return
}

if (-not (Test-Path $sysPol)) { New-Item -Path $sysPol -Force | Out-Null }
Set-ItemProperty -Path $sysPol -Name "EnableActivityFeed" -Value 0 -Type DWord
Set-ItemProperty -Path $sysPol -Name "PublishUserActivities" -Value 0 -Type DWord
Set-ItemProperty -Path $sysPol -Name "UploadUserActivities" -Value 0 -Type DWord
Write-Output "Windows Activity History tracking and cloud upload disabled."
