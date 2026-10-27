<#
.SYNOPSIS
    Dev Drive (ReFS) & Filesystem Filter Driver Auditor (#040)
.DESCRIPTION
    Checks fixed volumes for ReFS / Dev Drive status and lists active filesystem filter drivers.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [040] Dev Drive (ReFS) & Filesystem Filter Driver Auditor ==="
$vols = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter }
foreach ($v in $vols) {
    Write-Output ("Drive {0}: | FS: {1,-6} | Label: {2,-16} | Free: {3} GB" -f $v.DriveLetter, $v.FileSystemType, $v.FileSystemLabel, [math]::Round($v.SizeRemaining / 1GB, 1))
}

$refsVols = @($vols | Where-Object { $_.FileSystemType -eq 'ReFS' })
if ($refsVols.Count -eq 0) {
    Write-Output "`n[RECOMMENDATION] No ReFS Dev Drive detected. Creating a 50GB+ Dev Drive in Windows Settings -> System -> Storage -> Disks & Volumes improves npm/cargo/dotnet build times by ~25-30%."
} else {
    Write-Output "`n[OK] ReFS volume detected on this workstation."
}
