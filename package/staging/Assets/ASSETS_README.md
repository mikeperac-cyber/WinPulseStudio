# WinPulse Studio - Store Asset Configuration
# Required assets for Microsoft Store submission
#
# Asset specifications:
# - Square44x44Logo.png    : 44x44 px, app tile
# - Square150x150Logo.png  : 150x150 px, app tile  
# - Wide310x150Logo.png    : 310x150 px, wide tile
# - Square310x310Logo.png  : 310x310 px, large tile
# - StoreLogo.png          : 50x50 px, store listing
# - SplashScreen.png       : 620x300 px, app splash
# - Screenshot1.png        : 1920x1080 px minimum, store screenshots
# - Screenshot2.png        : 1920x1080 px minimum
# - Screenshot3.png        : 1920x1080 px minimum
#
# All images: PNG format, sRGB color space
# Background color: #0078D4 (Microsoft Blue)

$assets = @(
    @{Name="Square44x44Logo.png"; Size="44x44"; Description="App tile small"},
    @{Name="Square150x150Logo.png"; Size="150x150"; Description="App tile medium"},
    @{Name="Wide310x150Logo.png"; Size="310x150"; Description="App tile wide"},
    @{Name="Square310x310Logo.png"; Size="310x310"; Description="App tile large"},
    @{Name="StoreLogo.png"; Size="50x50"; Description="Store listing icon"},
    @{Name="SplashScreen.png"; Size="620x300"; Description="App splash screen"}
)

Write-Host "Store Asset Configuration:" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Gray
$assets | ForEach-Object {
    $path = Join-Path "C:\Users\MIKE\Documents\pwsh\Assets" $_.Name
    $exists = Test-Path $path
    $status = if ($exists) { "PRESENT" } else { "MISSING - create placeholder" }
    Write-Host "  $($_.Name) ($($_.Size)) - $status" -ForegroundColor (if ($exists) { "Green" } else { "Yellow" })
}

Write-Host "`nTo generate placeholder assets:" -ForegroundColor Cyan
Write-Host "  1. Open Paint or any image editor" -ForegroundColor Gray
Write-Host "  2. Create PNG files at the specified sizes" -ForegroundColor Gray
Write-Host "  3. Place them in the Assets/ folder" -ForegroundColor Gray
Write-Host "  4. Use #0078D4 background with white WinPulse logo" -ForegroundColor Gray