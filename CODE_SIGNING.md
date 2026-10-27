# Code Signing Configuration for Microsoft Store
#
# MSIX packages must be code-signed before Store submission.
#
# Option 1: Self-signed certificate (for sideloading/testing)
#   New-SelfSignedCertificate -Type Custom -Subject "CN=Microsoft WinPulse Studio" `
#     -KeyUsage DigitalSignature -KeyExportPolicy Exportable `
#     -CertStoreLocation "Cert:\CurrentUser\My" `
#     -KeyAlgorithm RSA -KeyLength 2048
#
# Option 2: Purchase from trusted CA (DigiCert, Sectigo, etc.) for Store publication
#
# Signing command (after building MSIX):
#   signtool sign /a /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com `
#     /n "Microsoft WinPulse Studio" "WinPulseStudio_1.0.0.0_x64.msix"
#
# Verification:
#   signtool verify /a "WinPulseStudio_1.0.0.0_x64.msix"

$signingConfig = @{
    PublisherName = "CN=Microsoft Corporation"
    KeyAlgorithm  = "RSA"
    KeyLength     = 2048
    HashAlgorithm = "SHA256"
    TimestampUrl  = "http://timestamp.digicert.com"
    CertStore     = "Cert:\CurrentUser\My"
}

Write-Host "Code Signing Configuration:" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Gray
$signingConfig.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "To create a self-signed cert for testing:" -ForegroundColor Cyan
Write-Host "  New-SelfSignedCertificate -Type Custom -Subject `"CN=Microsoft WinPulse Studio`" `" -ForegroundColor Gray
Write-Host "    -KeyUsage DigitalSignature -KeyExportPolicy Exportable `" -ForegroundColor Gray
Write-Host "    -CertStoreLocation `"Cert:\CurrentUser\My`" -KeyAlgorithm RSA -KeyLength 2048" -ForegroundColor Gray