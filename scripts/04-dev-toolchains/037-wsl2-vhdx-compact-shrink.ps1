<#
.SYNOPSIS
    WSL2 & Docker Virtual Disk (ext4.vhdx) Compactor (#037)
.DESCRIPTION
    Finds ext4.vhdx files under %LOCALAPPDATA%\Packages and %LOCALAPPDATA%\Docker and reports or compacts them.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [037] WSL2 & Docker Virtual Disk (ext4.vhdx) Compactor ==="
$searchPaths = @(
    (Join-Path $env:LOCALAPPDATA "Packages"),
    (Join-Path $env:LOCALAPPDATA "Docker\wsl")
)

$vhdxFiles = @()
foreach ($sp in $searchPaths) {
    if (Test-Path $sp) {
        $vhdxFiles += Get-ChildItem -Path $sp -Filter "*.vhdx" -Recurse -File -ErrorAction SilentlyContinue
    }
}

if ($vhdxFiles.Count -eq 0) {
    Write-Output "No WSL2 or Docker .vhdx virtual disks found."
    return
}

foreach ($vhd in $vhdxFiles) {
    Write-Output ("Found VHDX: {0} ({1} GB)" -f $vhd.FullName, [math]::Round($vhd.Length / 1GB, 2))
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess("WSL2 VHDX Files", "Shutdown WSL and compact VHDX")) {
    Write-Output "[DRY-RUN] Would run 'wsl --shutdown' and compact $($vhdxFiles.Count) VHDX file(s) via Optimize-VHD / diskpart."
    return
}

& wsl.exe --shutdown
foreach ($vhd in $vhdxFiles) {
    if (Get-Command "Optimize-VHD" -ErrorAction SilentlyContinue) {
        Optimize-VHD -Path $vhd.FullName -Mode Full
        Write-Output "Compacted: $($vhd.FullName)"
    }
}
