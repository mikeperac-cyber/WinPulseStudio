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
    . (Join-Path $PSScriptRoot 'tools\Invoke-WinPulseSigning.ps1')
    Invoke-WinPulseCodeSign -TargetPath $publishedExe -CertificateSubject $CertificateSubject -ExportCertDir $outDirFull
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