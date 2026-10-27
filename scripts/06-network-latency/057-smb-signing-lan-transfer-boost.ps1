<#
.SYNOPSIS
    LAN SMB3 Multichannel & NAS Transfer Optimizer (#057)
.DESCRIPTION
    Checks Get-SmbClientConfiguration and enables MultiChannel and LargeMtu for maximum LAN throughput.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
