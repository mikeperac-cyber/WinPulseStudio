#Requires -Version 7.0
<#
.SYNOPSIS
    Builds WinPulse Control Studio as ONE downloadable, self-contained WinPulseStudio.exe.

.DESCRIPTION
    Produces dist\WinPulseStudio.exe containing the full .NET 10 WPF app, the
    .NET runtime (no install needed on the target PC), and all 100 built-in
    PowerShell scripts with the catalog manifest.

    The target PC still requires PowerShell 7 (pwsh) on PATH for script
    verification, preview, and apply operations.

.PARAMETER OutputDir
    Where to place the exe. Defaults to <repo>\dist.

.PARAMETER SkipSigning
    Do not sign the produced exe.

.EXAMPLE
    pwsh -File .\Build-SingleExe.ps1
#>
[CmdletBinding()]
param(
    [string]$OutputDir = (Join-Path $PSScriptRoot 'dist'),
    [string]$CertificateSubject = 'CN=WinPulse Studio',
    [switch]$SkipSigning
)

$ErrorActionPreference = 'Stop'

$project = Join-Path $PSScriptRoot 'src\WinPulseStudio\WinPulseStudio.csproj'
if (-not (Test-Path $project)) {
    throw "Project not found: $project"
}

Write-Host '==> Building single-file self-contained WinPulseStudio.exe ...' -ForegroundColor Cyan

$outDirFull = [System.IO.Path]::GetFullPath($OutputDir)
dotnet publish $project -c Release /p:PublishProfile=win-x64-single-exe /p:PublishDir="$outDirFull\" /nodeReuse:false
if ($LASTEXITCODE -ne 0) {
    throw "dotnet publish failed with exit code $LASTEXITCODE."
}

$publishedExe = Join-Path $outDirFull 'WinPulseStudio.exe'
if (-not (Test-Path $publishedExe)) {
    throw "Expected output exe was not produced: $publishedExe"
}

if (-not $SkipSigning) {
    $signTool = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin' -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\x64\\' } |
        Sort-Object FullName -Descending |
        Select-Object -First 1
    if (-not $signTool) {
        throw 'SignTool.exe not found. Install the Windows 10/11 SDK or pass -SkipSigning.'
    }

    $cert = Get-ChildItem Cert:\CurrentUser\My -ErrorAction SilentlyContinue |
        Where-Object { $_.Subject -eq $CertificateSubject } |
        Select-Object -First 1
    if (-not $cert) {
        Write-Host "==> Creating local signing certificate: $CertificateSubject" -ForegroundColor Yellow
        $cert = New-SelfSignedCertificate `
            -Subject $CertificateSubject `
            -Type Custom `
            -KeyUsage DigitalSignature `
            -KeyExportPolicy Exportable `
            -CertStoreLocation Cert:\CurrentUser\My `
            -KeyAlgorithm RSA `
            -KeyLength 2048 `
            -HashAlgorithm SHA256 `
            -NotAfter (Get-Date).AddYears(2)
    }

    Write-Host '==> Signing exe ...' -ForegroundColor Cyan
    # Timestamp the signature so it stays valid after the certificate expires.
    # Fall back to an untime-stamped signature if the server is unreachable.
    & $signTool.FullName sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /sha1 $cert.Thumbprint $publishedExe
    if ($LASTEXITCODE -ne 0) {
        Write-Host '    Timestamp server unreachable; signing without a timestamp.' -ForegroundColor Yellow
        & $signTool.FullName sign /fd SHA256 /sha1 $cert.Thumbprint $publishedExe
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Signing failed with exit code $LASTEXITCODE."
    }

    # Export the public certificate next to the exe so users can inspect or
    # trust it (needed to install the self-signed MSIX, for example).
    $cerPath = Join-Path $outDirFull 'WinPulseStudio.cer'
    Export-Certificate -Cert $cert -FilePath $cerPath -Type CERT | Out-Null
    Write-Host "    Certificate exported: $cerPath" -ForegroundColor Gray
}

$sizeMb = [math]::Round((Get-Item $publishedExe).Length / 1MB, 1)
Write-Host ''
Write-Host "==> SUCCESS: $publishedExe ($sizeMb MB)" -ForegroundColor Green
Write-Host '    Self-contained single file - no .NET runtime install required.' -ForegroundColor Gray
Write-Host '    All 100 built-in PowerShell scripts are bundled inside the exe.' -ForegroundColor Gray
Write-Host '    PowerShell 7 (pwsh) must be installed on the target PC.' -ForegroundColor Yellow
if ($SkipSigning) {
    Write-Host '    Signing skipped (-SkipSigning).' -ForegroundColor Yellow
}