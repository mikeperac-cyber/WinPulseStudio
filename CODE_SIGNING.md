# Code Signing Configuration for WinPulse Control Studio
#
# MSIX packages must be code-signed before Store submission.
#
# Option 1: Self-signed certificate (for sideloading/testing)
#   New-SelfSignedCertificate -Type Custom -Subject "CN=WinPulse Studio" `
#     -KeyUsage DigitalSignature -KeyExportPolicy Exportable `
#     -CertStoreLocation "Cert:\CurrentUser\My" `
#     -KeyAlgorithm RSA -KeyLength 2048
#
# Option 2: Purchase from a trusted CA (DigiCert, Sectigo, etc.) for Store publication
#
# Signing command (after building MSIX):
#   signtool sign /fd SHA256 /n "CN=WinPulse Studio" "WinPulseStudio_1.2.0.0_x64.msix"
#
# Verification:
#   signtool verify /pa "WinPulseStudio_1.2.0.0_x64.msix"

$signingConfig = @{
    PublisherName = "CN=WinPulse Studio"
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
Write-Host "  New-SelfSignedCertificate -Type Custom -Subject `"CN=WinPulse Studio`" `" -ForegroundColor Gray
Write-Host "    -KeyUsage DigitalSignature -KeyExportPolicy Exportable `" -ForegroundColor Gray
Write-Host "    -CertStoreLocation `"Cert:\CurrentUser\My`" -KeyAlgorithm RSA -KeyLength 2048" -ForegroundColor Gray
