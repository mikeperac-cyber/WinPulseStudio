<#
.SYNOPSIS
    Deep Temp, DirectX & NVIDIA/AMD Shader Cache Purge (#071)
.DESCRIPTION
    Measures and cleans temporary folders and GPU shader caches without touching active locked files.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [071] Deep Temp, DirectX & NVIDIA/AMD Shader Cache Purge ==="
$targets = @(
    @{ Name = "User Temp";        Path = $env:TEMP },
    @{ Name = "DirectX Shaders";  Path = Join-Path $env:LOCALAPPDATA "D3DSCache" },
    @{ Name = "NVIDIA DXCache";   Path = Join-Path $env:LOCALAPPDATA "NVIDIA\DXCache" },
    @{ Name = "NVIDIA GLCache";   Path = Join-Path $env:LOCALAPPDATA "NVIDIA\GLCache" },
    @{ Name = "AMD DxCache";      Path = Join-Path $env:LOCALAPPDATA "AMD\DxCache" }
)

$totalBytes = 0L
foreach ($t in $targets) {
    if (Test-Path $t.Path) {
        $files = Get-ChildItem -Path $t.Path -Recurse -File -ErrorAction SilentlyContinue
        $bytes = ($files | Measure-Object -Property Length -Sum).Sum
        if ($bytes) { $totalBytes += $bytes }
        Write-Output ("[{0,-16}] {1,8} MB ({2} files)" -f $t.Name, [math]::Round(($bytes / 1MB), 1), @($files).Count)

        if (-not $DryRun -and $PSCmdlet.ShouldProcess($t.Path, "Purge unlocked temp/shader files")) {
            $files | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
}
Write-Output ("Total Scanned Temp & Shader Cache: {0} MB" -f [math]::Round($totalBytes / 1MB, 1))
