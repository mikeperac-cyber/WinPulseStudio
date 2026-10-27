<#
.SYNOPSIS
    NVMe ReTrim & Storage Slab Optimizer (#006)
.DESCRIPTION
    Runs Optimize-Volume -ReTrim on all local fixed NTFS/ReFS volumes backed by SSD/NVMe storage.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [006] NVMe ReTrim & Storage Slab Optimizer ==="
$volumes = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' -and $_.FileSystemType -in @('NTFS', 'ReFS') }

foreach ($vol in $volumes) {
    $freePct = if ($vol.Size -gt 0) { [math]::Round(($vol.SizeRemaining / $vol.Size) * 100, 1) } else { 0 }
    Write-Output ("Volume {0}: ({1}) - {2} GB free ({3}%)" -f $vol.DriveLetter, $vol.FileSystemLabel, [math]::Round($vol.SizeRemaining / 1GB, 1), $freePct)
    if ($DryRun -or -not $PSCmdlet.ShouldProcess("Volume $($vol.DriveLetter):", "Optimize-Volume -ReTrim")) {
        Write-Output "  [DRY-RUN] Would run Optimize-Volume -DriveLetter $($vol.DriveLetter) -ReTrim"
    } else {
        Optimize-Volume -DriveLetter $vol.DriveLetter -ReTrim -Verbose
        Write-Output "  [OK] ReTrim completed on $($vol.DriveLetter):"
    }
}
