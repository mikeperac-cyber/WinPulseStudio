<#
.SYNOPSIS
    Cloud CLI Log & Token Cache Cleaner (AWS/Azure/GCP) (#048)
.DESCRIPTION
    Cleans stale CLI log files in ~/.azure/logs, ~/.azure/telemetry, and %APPDATA%\gcloud\logs.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [048] Cloud CLI Log & Token Cache Cleaner ==="
$logDirs = @(
    (Join-Path $env:USERPROFILE ".azure\logs"),
    (Join-Path $env:USERPROFILE ".azure\telemetry"),
    (Join-Path $env:APPDATA "gcloud\logs")
)

foreach ($dir in $logDirs) {
    if (Test-Path $dir) {
        $files = Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue
        $mb = [math]::Round((($files | Measure-Object -Property Length -Sum).Sum / 1MB), 2)
        Write-Output ("Found {0} MB ({1} log files) in {2}" -f $mb, @($files).Count, $dir)
        if (-not $DryRun -and $PSCmdlet.ShouldProcess($dir, "Purge Cloud CLI logs")) {
            $files | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Output "  Cleaned logs in $dir"
        }
    } else {
        Write-Output ("Directory not present: {0}" -f $dir)
    }
}
