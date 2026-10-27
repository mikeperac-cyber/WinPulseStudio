<#
.SYNOPSIS
    Docker Engine & BuildKit Cache Deep Prune (#041)
.DESCRIPTION
    Runs docker system df and prunes dangling containers, networks, images, and BuildKit cache.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [041] Docker Engine & BuildKit Cache Deep Prune ==="
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Output "Docker CLI is not installed on this machine."
    return
}

$info = & docker system df 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Output "Docker daemon is not currently running."
    return
}
$info | ForEach-Object { Write-Output $_ }

if ($DryRun -or -not $PSCmdlet.ShouldProcess("Docker Daemon", "docker system prune -f & builder prune -f")) {
    Write-Output "[DRY-RUN] Would execute 'docker system prune -f' and 'docker builder prune -f'."
    return
}

& docker system prune -f
& docker builder prune -f
Write-Output "Docker dangling images, stopped containers, and build caches pruned."
