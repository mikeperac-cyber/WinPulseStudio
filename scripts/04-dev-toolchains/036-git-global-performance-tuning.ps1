<#
.SYNOPSIS
    Git Monorepo & Filesystem Cache Turbo Config (#036)
.DESCRIPTION
    Configures git global settings optimized for Windows NTFS performance.
.EXAMPLE
    .\036-git-global-performance-tuning.ps1 -DryRun

    Simulates the change without modifying the system.

    .\036-git-global-performance-tuning.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Fail fast with a structured error instead of a raw PowerShell dump, so the
# calling app can record exactly what went wrong.
trap {
    Write-Output ("[ERROR] Script failed: " + $_.Exception.Message)
    exit 1
}

Write-Output "=== [036] Git Monorepo & Filesystem Cache Turbo Config ==="
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Output "Git is not installed or not on PATH."
    return
}

$gitTweaks = @{
    "core.fscache"       = "true"
    "core.preloadindex"  = "true"
    "core.untrackedCache"= "true"
    "feature.manyFiles"  = "true"
    "fetch.parallel"     = "0"
    "submodule.fetchJobs"= "0"
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess("~/.gitconfig", "Apply Git Windows performance flags")) {
    foreach ($kv in $gitTweaks.GetEnumerator()) {
        Write-Output ("[DRY-RUN] git config --global {0} {1}" -f $kv.Key, $kv.Value)
    }
    return
}

foreach ($kv in $gitTweaks.GetEnumerator()) {
    & git config --global $kv.Key $kv.Value
    Write-Output ("Applied: git config --global {0} = {1}" -f $kv.Key, $kv.Value)
}
