<#
.SYNOPSIS
    UAC, SmartScreen & Exploit Guard Posture Auditor (#083)
.DESCRIPTION
    Reads HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System security posture values.
.EXAMPLE
    .\083-uac-smartscreen-security-audit.ps1 -DryRun

    Simulates the change without modifying the system.

    .\083-uac-smartscreen-security-audit.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Fail fast with a structured error instead of a raw PowerShell dump, so the
# calling app can record exactly what went wrong.
trap {
    Write-Output ("[ERROR] Script failed: " + $_.Exception.Message)
    exit 1
}

Write-Output "=== [083] UAC, SmartScreen & Exploit Guard Posture Auditor ==="
$sysPol = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$props = Get-ItemProperty -Path $sysPol -ErrorAction SilentlyContinue

Write-Output ("EnableLUA (UAC Active)          : {0}" -f ($props.EnableLUA -eq 1))
Write-Output ("ConsentPromptBehaviorAdmin      : {0} (2=Always Notify, 5=Default)" -f $props.ConsentPromptBehaviorAdmin)
Write-Output ("PromptOnSecureDesktop           : {0}" -f ($props.PromptOnSecureDesktop -eq 1))
