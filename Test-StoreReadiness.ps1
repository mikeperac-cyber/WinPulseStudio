#Requires -Version 7.0
<#
.SYNOPSIS
    Pre-flight gate for Microsoft Store submission.

.DESCRIPTION
    Checks the machine-verifiable parts of STORE_SUBMISSION_CHECKLIST.md and
    exits non-zero if anything blocks submission:

      * no example.com placeholder URLs in STORE_LISTING.md
      * version agreement across csproj, scripts manifest, and MSIX manifest
      * 100 scripts listed and present on disk
      * commands.json totalCommands matches the actual entry count
      * the MSIX exists, is timestamped, and is signed by a TRUSTED certificate

    Use -AllowSelfSigned for a local pre-flight run: the signature and URL
    checks then produce warnings instead of failures (they still block a real
    Store submission).

.PARAMETER AllowSelfSigned
    Treat the self-signed certificate and placeholder URLs as warnings.

.EXAMPLE
    pwsh -File .\Test-StoreReadiness.ps1 -AllowSelfSigned
#>
[CmdletBinding()]
param(
    [switch]$AllowSelfSigned
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string]$message) { $failures.Add($message) }
function Add-Warning([string]$message) { $warnings.Add($message) }

function To-VersionParts([string]$version) {
    if ($version -notmatch '^\d+\.\d+\.\d+(\.\d+)?$') { return $null }
    return ($version -split '\.')
}

# ---------------------------------------------------------------- URLs
$listingPath = Join-Path $root 'STORE_LISTING.md'
$placeholderUrls = @()
if (Test-Path $listingPath) {
    $placeholderUrls = @(Select-String -Path $listingPath -Pattern 'https://example\.com' |
        ForEach-Object { $_.Line.Trim() })
} else {
    Add-Failure 'STORE_LISTING.md is missing.'
}

if ($placeholderUrls.Count -gt 0) {
    $message = "STORE_LISTING.md still contains $($placeholderUrls.Count) example.com placeholder URL(s)."
    if ($AllowSelfSigned) { Add-Warning $message } else { Add-Failure $message }
}

# ------------------------------------------------------------- Versions
$csprojVersion = $null
$csprojPath = Join-Path $root 'src\WinPulseStudio\WinPulseStudio.csproj'
if (Test-Path $csprojPath) {
    $csprojVersion = ([xml](Get-Content $csprojPath -Raw)).Project.PropertyGroup |
        ForEach-Object { $_.Version } |
        Where-Object { $_ } |
        Select-Object -First 1
} else {
    Add-Failure 'src\WinPulseStudio\WinPulseStudio.csproj is missing.'
}

$manifestPath = Join-Path $root 'scripts\manifest.json'
$manifest = $null
if (Test-Path $manifestPath) {
    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
} else {
    Add-Failure 'scripts\manifest.json is missing.'
}

$appxPath = Join-Path $root 'Package.appxmanifest'
$appxVersion = $null
if (Test-Path $appxPath) {
    $identity = ([xml](Get-Content $appxPath -Raw)).Package.Identity
    $appxVersion = $identity.Version
} else {
    Add-Failure 'Package.appxmanifest is missing.'
}

if ($csprojVersion -and $manifest -and $appxVersion) {
    $appxParts = To-VersionParts $appxVersion
    $expectedAppx = if ($appxParts) { "$($appxParts[0]).$($appxParts[1]).$($appxParts[2])" } else { $null }
    if ($csprojVersion -ne $manifest.version) {
        Add-Failure "Version mismatch: csproj=$csprojVersion, manifest=$($manifest.version)."
    }
    if ($expectedAppx -ne $manifest.version) {
        Add-Failure "Version mismatch: Package.appxmanifest=$appxVersion, manifest=$($manifest.version)."
    }
}

# --------------------------------------------------------------- Catalog
if ($manifest) {
    $scripts = @($manifest.scripts)
    if ($scripts.Count -ne 100) {
        Add-Failure "scripts/manifest.json lists $($scripts.Count) scripts, expected 100."
    }
    $missing = @()
    foreach ($entry in $scripts) {
        $path = Join-Path $root ($entry.relativePath -replace '/', '\')
        if (-not (Test-Path $path)) { $missing += $entry.relativePath }
    }
    if ($missing.Count -gt 0) {
        Add-Failure "$($missing.Count) script file(s) listed in the manifest are missing, e.g. $($missing[0])."
    }
}

$commandsPath = Join-Path $root 'commands\commands.json'
if (Test-Path $commandsPath) {
    $commands = Get-Content $commandsPath -Raw | ConvertFrom-Json
    $actual = @($commands.commands).Count
    if ($commands.totalCommands -ne $actual) {
        Add-Failure "commands.json totalCommands=$($commands.totalCommands) but it contains $actual entries."
    }
} else {
    Add-Failure 'commands\commands.json is missing.'
}

# ----------------------------------------------------------------- MSIX
$msixVersion = if ($appxVersion) { $appxVersion } else { '1.2.0.0' }
$msixPath = Join-Path $root "package\output\WinPulseStudio_${msixVersion}_x64.msix"
if (-not (Test-Path $msixPath)) {
    Add-Failure "MSIX not found: package\output\WinPulseStudio_${msixVersion}_x64.msix (run Build-MSIX.ps1)."
} else {
    $signature = Get-AuthenticodeSignature $msixPath
    if ($signature.Status -ne 'Valid') {
        $message = "MSIX signature status is '$($signature.Status)' (expected 'Valid'). A Store build needs a trusted certificate chain."
        if ($AllowSelfSigned) { Add-Warning $message } else { Add-Failure $message }
    }
    if ($null -eq $signature.TimeStamperCertificate) {
        Add-Failure 'MSIX signature is not timestamped; it will expire with the certificate.'
    }
}

# ---------------------------------------------------------------- Report
Write-Host ''
Write-Host '=== WinPulse Store Readiness ===' -ForegroundColor Cyan

if ($warnings.Count -gt 0) {
    Write-Host ''
    Write-Host "Warnings ($($warnings.Count)):" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

if ($failures.Count -gt 0) {
    Write-Host ''
    Write-Host "FAILED ($($failures.Count)):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host ''
Write-Host 'PASS: machine-checkable Store readiness checks succeeded.' -ForegroundColor Green
if ($AllowSelfSigned -and $warnings.Count -gt 0) {
    Write-Host '      Local pre-flight only — resolve the warnings before a real submission.' -ForegroundColor Yellow
}
exit 0