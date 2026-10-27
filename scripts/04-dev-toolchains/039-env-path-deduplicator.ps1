<#
.SYNOPSIS
    System & User PATH Deduplicator & Dead-Entry Cleaner (#039)
.DESCRIPTION
    Inspects User PATH for duplicates and missing folders, backs up to ~/.path-backup.txt, and writes deduplicated User PATH.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [039] System & User PATH Deduplicator & Dead-Entry Cleaner ==="
$userPathRaw = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $userPathRaw) {
    Write-Output "User PATH is empty."
    return
}

$entries = $userPathRaw -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
$seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$cleanEntries = [System.Collections.Generic.List[string]]::new()
$duplicates = 0
$missing = 0

foreach ($e in $entries) {
    $trimmed = $e.Trim().TrimEnd('\')
    if (-not (Test-Path $trimmed)) {
        Write-Output "  [DEAD PATH] $trimmed"
        $missing++
    }
    if ($seen.Add($trimmed)) {
        $cleanEntries.Add($e.Trim())
    } else {
        Write-Output "  [DUPLICATE] $trimmed"
        $duplicates++
    }
}

Write-Output ("Summary: {0} total entries | {1} duplicates | {2} dead directories" -f $entries.Count, $duplicates, $missing)
if ($DryRun -or ($duplicates -eq 0) -or -not $PSCmdlet.ShouldProcess("User PATH", "Deduplicate PATH entries")) {
    Write-Output "[DRY-RUN / OK] User PATH audit complete."
    return
}

$backupFile = Join-Path $env:USERPROFILE ".winpulse-path-backup.txt"
Set-Content -Path $backupFile -Value $userPathRaw -Encoding UTF8
[Environment]::SetEnvironmentVariable("Path", ($cleanEntries -join ';'), "User")
Write-Output "Deduplicated User PATH (Backup saved to $backupFile)."
