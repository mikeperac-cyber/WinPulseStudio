#Requires -Version 7.0
<#
.SYNOPSIS
    Builds a Store-style MSIX layout from the current source and packages it.

.DESCRIPTION
    Publishes a self-contained win-x64 build, copies the 100 built-in scripts,
    the validator, the package manifest, app manifest, and assets into a staging
    folder, then packages it with MakeAppx. When -SkipSigning is not specified,
    the package is signed with the local "CN=WinPulse Studio" certificate (created
    if needed).

    This produces a locally testable MSIX. Microsoft Store submission still
    requires a Store-issued signing certificate and Partner Center onboarding.
#>
[CmdletBinding()]
param(
    [string]$Configuration = "Release",
    [string]$CertificateSubject = "CN=WinPulse Studio",
    [switch]$SkipSigning
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$project = Join-Path $root "src\WinPulseStudio\WinPulseStudio.csproj"
$staging = Join-Path $root "package\staging"
$output = Join-Path $root "package\output"
$appxVersion = ([xml](Get-Content (Join-Path $root 'Package.appxmanifest') -Raw)).Package.Identity.Version
$msix = Join-Path $output "WinPulseStudio_${appxVersion}_x64.msix"

if (-not (Test-Path $project)) { throw "Project not found: $project" }

if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Force $staging, $output | Out-Null

Write-Host "==> Publishing self-contained win-x64 layout..." -ForegroundColor Cyan
dotnet publish $project `
    -c $Configuration `
    -r win-x64 `
    --self-contained true `
    -p:PublishSingleFile=false `
    -p:PublishTrimmed=false `
    -o $staging

# dotnet publish already copies scripts/ and tests/ via the project Content
# items. Copying the whole tree again is redundant and can stall on large
# staging folders, so only copy the package-only files here.
Copy-Item -Path (Join-Path $root "Package.appxmanifest") -Destination (Join-Path $staging "AppxManifest.xml") -Force
Copy-Item (Join-Path $root "app.manifest") $staging -Force

if (Test-Path (Join-Path $root "package\Assets")) {
    robocopy (Join-Path $root "package\Assets") (Join-Path $staging "Assets") /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed to copy Assets with exit code $LASTEXITCODE." }
}

if (-not (Test-Path (Join-Path $staging "scripts\manifest.json"))) { throw "scripts/manifest.json missing from staging." }
if (-not (Test-Path (Join-Path $staging "tests\Validate-AllScripts.ps1"))) { throw "tests/Validate-AllScripts.ps1 missing from staging." }
if (-not (Test-Path (Join-Path $staging "AppxManifest.xml"))) { throw "AppxManifest.xml missing from staging." }

$makeAppx = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" -Recurse -Filter makeappx.exe -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "\\x64\\" } |
    Sort-Object FullName -Descending |
    Select-Object -First 1
if (-not $makeAppx) { throw "MakeAppx.exe not found. Install the Windows 10/11 SDK." }

Write-Host "==> Packing MSIX..." -ForegroundColor Cyan
& $makeAppx.FullName pack /d $staging /p $msix /o /l
if ($LASTEXITCODE -ne 0) { throw "MakeAppx pack failed with exit code $LASTEXITCODE." }

if (-not $SkipSigning) {
    . (Join-Path $root 'tools\Invoke-WinPulseSigning.ps1')
    Invoke-WinPulseCodeSign -TargetPath $msix -CertificateSubject $CertificateSubject -ExportCertDir $output

    Write-Host "    Signature written. Trust the certificate before installing." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==> SUCCESS: $msix" -ForegroundColor Green
Write-Host "    Staging layout: $staging"
Write-Host "    Scripts included: $((Get-ChildItem (Join-Path $staging 'scripts') -Recurse -Filter *.ps1).Count) .ps1 files"
Write-Host "    MSIX size: $([math]::Round((Get-Item $msix).Length / 1MB, 1)) MB"
if ($SkipSigning) {
    Write-Host "    Signing skipped (-SkipSigning)." -ForegroundColor Yellow
}