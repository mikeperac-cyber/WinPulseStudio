<#
.SYNOPSIS
    AI Model Weights Cache Auditor (HF, Ollama, Torch) (#026)
.DESCRIPTION
    Audits disk footprint of local AI model directories and cleans incomplete/orphaned lock files.
.EXAMPLE
    .\026-huggingface-pytorch-cache-audit.ps1 -DryRun

    Simulates the change without modifying the system.

    .\026-huggingface-pytorch-cache-audit.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$CleanIncompleteDownloads
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Fail fast with a structured error instead of a raw PowerShell dump, so the
# calling app can record exactly what went wrong.
trap {
    Write-Output ("[ERROR] Script failed: " + $_.Exception.Message)
    exit 1
}

Write-Output "=== [026] AI Model Weights Cache Auditor ==="
$cacheLocations = @(
    @{ Name = "HuggingFace Hub"; Path = Join-Path $env:USERPROFILE ".cache\huggingface\hub" },
    @{ Name = "Ollama Models";   Path = Join-Path $env:USERPROFILE ".ollama\models" },
    @{ Name = "PyTorch Hub";     Path = Join-Path $env:USERPROFILE ".cache\torch" },
    @{ Name = "LM Studio";       Path = Join-Path $env:USERPROFILE ".cache\lm-studio\models" }
)

$totalBytes = 0L
foreach ($loc in $cacheLocations) {
    if (Test-Path $loc.Path) {
        $files = Get-ChildItem -Path $loc.Path -Recurse -File -ErrorAction SilentlyContinue
        $size = ($files | Measure-Object -Property Length -Sum).Sum
        if ($null -eq $size) { $size = 0L }
        $totalBytes += $size
        Write-Output ("[{0}] {1} GB ({2} files) -> {3}" -f $loc.Name, [math]::Round($size / 1GB, 2), @($files).Count, $loc.Path)

        $incomplete = @($files | Where-Object { $_.Extension -in @('.incomplete', '.lock', '.part') })
        if ($incomplete.Count -gt 0) {
            Write-Output ("  Found {0} incomplete/lock files in {1}" -f $incomplete.Count, $loc.Name)
            if (-not $DryRun -and $CleanIncompleteDownloads -and $PSCmdlet.ShouldProcess($loc.Path, "Remove incomplete files")) {
                $incomplete | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-Output "  Cleaned incomplete/lock files."
            }
        }
    } else {
        Write-Output ("[{0}] Not present ({1})" -f $loc.Name, $loc.Path)
    }
}
Write-Output ("Total AI Model Cache Footprint: {0} GB" -f [math]::Round($totalBytes / 1GB, 2))
