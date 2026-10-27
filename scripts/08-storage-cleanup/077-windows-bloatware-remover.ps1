<#
.SYNOPSIS
    Consumer Appx Bloatware Auditor & Debloater (#077)
.DESCRIPTION
    Scans for non-essential consumer Appx packages and removes them on request.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [077] Consumer Appx Bloatware Auditor & Debloater ==="
$bloatPatterns = @(
    "*BingNews*",
    "*BingWeather*",
    "*MicrosoftSolitaireCollection*",
    "*WindowsFeedbackHub*",
    "*Microsoft.GetHelp*",
    "*Microsoft.Getstarted*",
    "*Microsoft.People*",
    "*Microsoft.MixedReality.Portal*",
    "*Clipchamp.Clipchamp*"
)

$foundPackages = foreach ($pat in $bloatPatterns) {
    Get-AppxPackage -Name $pat -ErrorAction SilentlyContinue
}

Write-Output ("Detected {0} removable consumer Appx packages:" -f @($foundPackages).Count)
foreach ($pkg in $foundPackages) {
    Write-Output ("  -> {0} ({1})" -f $pkg.Name, $pkg.Version)
    if (-not $DryRun -and $PSCmdlet.ShouldProcess($pkg.Name, "Remove-AppxPackage")) {
        Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction SilentlyContinue
        Write-Output "     Removed $($pkg.Name)"
    }
}
