#Requires -Version 7.0
<#
.SYNOPSIS
    Installs the locally built WinPulse Studio MSIX and verifies it end to end.

.DESCRIPTION
    Performs the full local installation test:
      1. Installs the signed MSIX with Add-AppxPackage.
      2. If the self-signed certificate is not trusted (0x800B0109 — the root
         cannot be trusted without an elevated one-time import), falls back to
         Developer Mode loose-file registration (Add-AppxPackage -Register),
         which still gives the app a real package identity.
      3. Runs the INSTALLED/REGISTERED app with --verify-headless and checks
         the exit code (100 scripts, 5 presets, 56 command entries, pwsh).
      4. Unless -Keep is passed, removes the package again to leave the
         machine clean.

    To enable the fully signed install path, run once from an elevated
    PowerShell:
        Import-Certificate -FilePath package\output\WinPulseStudio.cer `
            -CertStoreLocation Cert:\LocalMachine\TrustedPeople

.PARAMETER Keep
    Keep the package installed after the test instead of removing it.

.EXAMPLE
    pwsh -File .\Install-MSIX.ps1
#>
[CmdletBinding()]
param(
    [switch]$Keep
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$appxVersion = ([xml](Get-Content (Join-Path $root 'Package.appxmanifest') -Raw)).Package.Identity.Version
$msix = Join-Path $root "package\output\WinPulseStudio_${appxVersion}_x64.msix"
$stagingManifest = Join-Path $root 'package\staging\AppxManifest.xml'
$packageName = 'WinPulse.Studio'

if (-not (Test-Path $msix)) { throw "MSIX not found: $msix (run Build-MSIX.ps1 first)" }
if (-not (Test-Path $stagingManifest)) { throw "Staging manifest not found: $stagingManifest (run Build-MSIX.ps1 first)" }

Write-Host '==> Step 1/3: Installing the package...' -ForegroundColor Cyan

# Remove a stale copy first so the test always exercises a fresh install.
$stale = Get-AppxPackage -Name $packageName -ErrorAction SilentlyContinue
if ($stale) {
    Remove-AppxPackage -Package $stale.PackageFullName
    Write-Host '    Removed previous installation.' -ForegroundColor Gray
}

$mode = $null
try {
    Add-AppxPackage -Path $msix -ErrorAction Stop
    $mode = 'signed'
    Write-Host '    Installed the signed MSIX (certificate is trusted on this machine).' -ForegroundColor Gray
} catch {
    if ($_.Exception.Message -match '0x800B0109') {
        $devMode = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
        if (-not $devMode) {
            throw "The self-signed root is not trusted and Developer Mode is off. Enable Developer Mode (Settings > System > For developers) or import package\output\WinPulseStudio.cer into LocalMachine\TrustedPeople from an elevated shell."
        }
        Write-Host '    Signed install blocked: the self-signed root is not trusted.' -ForegroundColor Yellow
        Write-Host '    Falling back to Developer Mode registration from the staging layout.' -ForegroundColor Yellow
        Add-AppxPackage -Register $stagingManifest -ErrorAction Stop
        $mode = 'register'
        Write-Host '    Registered via Developer Mode (real package identity, loose files).' -ForegroundColor Gray
    } else {
        throw
    }
}

$package = Get-AppxPackage -Name $packageName
if (-not $package) { throw 'Installation reported success but the package was not found.' }
$installLocation = $package.InstallLocation
Write-Host "    Mode     : $mode" -ForegroundColor Gray
Write-Host "    Package  : $($package.PackageFullName)" -ForegroundColor Gray
Write-Host "    Location : $installLocation" -ForegroundColor Gray

Write-Host '==> Step 2/3: Running the installed app headless...' -ForegroundColor Cyan
$installedExe = Join-Path $installLocation 'WinPulseStudio.exe'
if (-not (Test-Path $installedExe)) { throw "Installed exe not found: $installedExe" }

$out = Join-Path $env:TEMP "winpulse-msix-test-$([guid]::NewGuid().ToString('N')).txt"
$proc = Start-Process -FilePath $installedExe -ArgumentList '--verify-headless' -Wait -PassThru -RedirectStandardOutput $out
$output = Get-Content $out -ErrorAction SilentlyContinue
Remove-Item $out -Force -ErrorAction SilentlyContinue

Write-Host "    Exit code: $($proc.ExitCode)" -ForegroundColor Gray
if ($output) { $output | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray } }

if ($proc.ExitCode -ne 0) {
    throw "Installed app failed the headless self-test (exit $($proc.ExitCode))."
}

Write-Host '==> Step 3/3: Cleaning up...' -ForegroundColor Cyan
if ($Keep) {
    Write-Host '    -Keep passed; leaving the package installed.' -ForegroundColor Yellow
} else {
    Remove-AppxPackage -Package $package.PackageFullName
    Write-Host '    Package removed.' -ForegroundColor Gray
}

Write-Host ''
Write-Host "==> SUCCESS: MSIX ($mode mode) installed and verified end to end." -ForegroundColor Green