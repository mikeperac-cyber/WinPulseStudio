<#
.SYNOPSIS
    AppData Top Space Consumers & Orphaned Folder Auditor (#080)
.DESCRIPTION
    Audits top-level directories in %APPDATA% and reports their LastWriteTime and file counts.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [080] AppData Top Space Consumers & Orphaned Folder Auditor ==="
$dirs = Get-ChildItem -Path $env:APPDATA -Directory -ErrorAction SilentlyContinue
$summary = foreach ($d in $dirs) {
    $files = Get-ChildItem -Path $d.FullName -Recurse -File -Depth 2 -ErrorAction SilentlyContinue
    $sum = ($files | Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{
        Folder        = $d.Name
        SizeMB        = [math]::Round(($sum / 1MB), 1)
        LastModified  = $d.LastWriteTime.ToString("yyyy-MM-dd")
    }
}

$summary | Sort-Object SizeMB -Descending | Select-Object -First 15 | Format-Table -AutoSize | Out-String | Write-Output
