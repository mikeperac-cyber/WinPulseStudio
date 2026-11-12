<#
.SYNOPSIS
    LAN SMB3 Multichannel & NAS Transfer Optimizer (#057)
.DESCRIPTION
    Checks Get-SmbClientConfiguration and enables MultiChannel and LargeMtu for maximum LAN throughput.
.EXAMPLE
    .\057-smb-signing-lan-transfer-boost.ps1 -DryRun

    Simulates the change without modifying the system.

    .\057-smb-signing-lan-transfer-boost.ps1

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

Write-Output "=== [057] LAN SMB3 Multichannel & NAS Transfer Optimizer ==="
$smb = Get-SmbClientConfiguration
Write-Output ("EnableMultiChannel          : {0}" -f $smb.EnableMultiChannel)
Write-Output ("EnableLargeMtu              : {0}" -f $smb.EnableLargeMtu)
Write-Output ("EnableBandwidthThrottling   : {0}" -f $smb.EnableBandwidthThrottling)

if ($DryRun -or -not $PSCmdlet.ShouldProcess("SmbClientConfiguration", "Enable MultiChannel & LargeMtu")) {
    Write-Output "[DRY-RUN] Would run Set-SmbClientConfiguration -EnableMultiChannel `$true -EnableLargeMtu `$true -Force"
    return
}

Set-SmbClientConfiguration -EnableMultiChannel $true -EnableLargeMtu $true -EnableBandwidthThrottling $false -Force
Write-Output "SMB3 Multichannel and Large MTU enabled."
