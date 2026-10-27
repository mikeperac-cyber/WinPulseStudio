<#
.SYNOPSIS
    UAC, SmartScreen & Exploit Guard Posture Auditor (#083)
.DESCRIPTION
    Reads HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System security posture values.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [083] UAC, SmartScreen & Exploit Guard Posture Auditor ==="
$sysPol = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$props = Get-ItemProperty -Path $sysPol -ErrorAction SilentlyContinue

Write-Output ("EnableLUA (UAC Active)          : {0}" -f ($props.EnableLUA -eq 1))
Write-Output ("ConsentPromptBehaviorAdmin      : {0} (2=Always Notify, 5=Default)" -f $props.ConsentPromptBehaviorAdmin)
Write-Output ("PromptOnSecureDesktop           : {0}" -f ($props.PromptOnSecureDesktop -eq 1))
