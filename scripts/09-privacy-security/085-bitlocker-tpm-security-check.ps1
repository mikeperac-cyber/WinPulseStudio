<#
.SYNOPSIS
    TPM 2.0, Secure Boot & BitLocker Encryption Inspector (#085)
.DESCRIPTION
    Audits Secure Boot, TPM 2.0 status, and BitLocker volume protection status.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [085] TPM 2.0, Secure Boot & BitLocker Encryption Inspector ==="
try {
    $sb = Confirm-SecureBootUEFI -ErrorAction Stop
    Write-Output "Secure Boot UEFI Enabled: $sb"
} catch {
    Write-Output "Secure Boot Status: Requires elevated privileges or Legacy BIOS."
}

$tpm = Get-Tpm -ErrorAction SilentlyContinue
if ($tpm) {
    Write-Output ("TPM Present: {0} | Ready: {1} | Enabled: {2}" -f $tpm.TpmPresent, $tpm.TpmReady, $tpm.TpmEnabled)
}

$bl = Get-BitLockerVolume -ErrorAction SilentlyContinue
if ($bl) {
    $bl | Select-Object MountPoint, VolumeStatus, ProtectionStatus, EncryptionPercentage | Format-Table -AutoSize | Out-String | Write-Output
}
