<#
.SYNOPSIS
    Exempt Compilers & IDEs from EcoQoS Throttling (#018)
.DESCRIPTION
    Disables Windows power throttling for discovered developer binaries so builds stay on Performance cores (P-cores).
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [018] Exempt Compilers & IDEs from EcoQoS Throttling ==="
$binaries = @('code', 'devenv', 'dotnet', 'node', 'python', 'cargo', 'rustc', 'go', 'pwsh')
$resolvedPaths = @()

foreach ($bin in $binaries) {
    $cmd = Get-Command $bin -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) {
        $resolvedPaths += $cmd.Source
        Write-Output ("Found toolchain binary: {0}" -f $cmd.Source)
    }
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess("PowerThrottling", "Exempt $($resolvedPaths.Count) binaries")) {
    Write-Output "[DRY-RUN] Would run 'powercfg /powerthrottling disable /path <exe>' for $($resolvedPaths.Count) binaries."
    return
}

foreach ($exePath in $resolvedPaths) {
    & powercfg.exe /powerthrottling disable /path "$exePath" | Out-Null
    Write-Output "Exempted from EcoQoS throttling: $exePath"
}
