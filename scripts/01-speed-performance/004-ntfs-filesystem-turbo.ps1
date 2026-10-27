<#
.SYNOPSIS
    NTFS Small-File & Monorepo I/O Boost (#004)
.DESCRIPTION
    Configures NTFS parameters via HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem for high-throughput small file workloads.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [004] NTFS Small-File & Monorepo I/O Boost ==="
$fsReg = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
$current = Get-ItemProperty -Path $fsReg -ErrorAction SilentlyContinue

Write-Output ("Current NtfsDisableLastAccessUpdate : {0}" -f $current.NtfsDisableLastAccessUpdate)
Write-Output ("Current NtfsDisable8dot3NameCreation: {0}" -f $current.NtfsDisable8dot3NameCreation)
Write-Output ("Current NtfsMemoryUsage             : {0}" -f $current.NtfsMemoryUsage)

if ($DryRun -or -not $PSCmdlet.ShouldProcess($fsReg, "Apply NTFS Monorepo I/O Tweaks")) {
    Write-Output "[DRY-RUN] Would set NtfsDisable8dot3NameCreation=1, NtfsMemoryUsage=2, and NtfsDisableLastAccessUpdate=0x80000003."
    return
}

& fsutil.exe behavior set disable8dot3 1 | Out-Null
& fsutil.exe behavior set memoryusage 2 | Out-Null
& fsutil.exe behavior set disablelastaccess 1 | Out-Null

Write-Output "NTFS filesystem parameters tuned for high-speed small-file operations."
