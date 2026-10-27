<#
.SYNOPSIS
    End-of-Day Uncommitted Git Audit & Workspace Wrap-Up (#069)
.DESCRIPTION
    Scans repositories under Documents / source\repos and reports any uncommitted working tree changes.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [string]$WorkspaceRoot = (Join-Path $env:USERPROFILE "Documents")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [069] End-of-Day Uncommitted Git Audit & Workspace Wrap-Up ==="
$gitDirs = Get-ChildItem -Path $WorkspaceRoot -Filter ".git" -Directory -Force -Recurse -Depth 3 -ErrorAction SilentlyContinue

if (-not $gitDirs) {
    Write-Output "No Git repositories discovered under $WorkspaceRoot (depth 3)."
    return
}

foreach ($gd in $gitDirs) {
    $repoPath = $gd.Parent.FullName
    $status = & git -C $repoPath status --porcelain 2>$null
    $branch = & git -C $repoPath rev-parse --abbrev-ref HEAD 2>$null
    if ($status) {
        Write-Output ("[DIRTY ] {0} (branch: {1}) -> {2} modified/untracked file(s)" -f $repoPath, $branch, @($status).Count)
    } else {
        Write-Output ("[CLEAN ] {0} (branch: {1})" -f $repoPath, $branch)
    }
}
