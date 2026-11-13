#Requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-WinPulseCodeSign {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TargetPath,
        [Parameter(Mandatory)]
        [string]$CertificateSubject,
        [Parameter(Mandatory)]
        [string]$ExportCertDir
    )

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

    Write-Host "==> Signing $(Split-Path $TargetPath -Leaf)..." -ForegroundColor Cyan
    & $signTool.FullName sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /sha1 $cert.Thumbprint $TargetPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host '    Timestamp server unreachable; signing without a timestamp.' -ForegroundColor Yellow
        & $signTool.FullName sign /fd SHA256 /sha1 $cert.Thumbprint $TargetPath
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Signing failed with exit code $LASTEXITCODE."
    }

    $cerPath = Join-Path $ExportCertDir 'WinPulseStudio.cer'
    Export-Certificate -Cert $cert -FilePath $cerPath -Type CERT | Out-Null
    Write-Host "    Certificate exported: $cerPath" -ForegroundColor Gray
}
