# Microsoft Store Publishing Build Plan (Stop at Store Gate)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a clean, optimized, Store-compliant unsigned MSIX package and stop at the exact Microsoft Store / Partner Center handoff boundary where Partner Center identity, real public URLs, and Store/trusted-CA signing must take over.

**Architecture:** Run all automated code, test, script-catalog, manifest, and asset-layout checks; build an **unsigned** MSIX (`Build-MSIX.ps1 -SkipSigning`) so Microsoft Store certification can sign it with the Store-issued certificate (never shipping the local self-signed `CN=WinPulse Studio` cert); then run `Test-StoreReadiness.ps1` in strict mode to verify zero code/catalog/version defects and halt cleanly at the Partner Center submission gate.

**Tech Stack:** .NET 10 (`net10.0-windows`, WPF, `win-x64`), PowerShell 7 (`pwsh`), Windows 10/11 SDK (`makeappx.exe`), Microsoft Partner Center.

**Spec:** `STORE_SUBMISSION_CHECKLIST.md`, `STORE_LISTING.md`, `Package.appxmanifest`, `Build-MSIX.ps1`, and `Test-StoreReadiness.ps1`.

## Global Constraints

- **Stop boundary:** Do NOT self-sign the Store submission MSIX, do NOT run `Install-MSIX.ps1` with a self-signed cert as a Store sign-off, and do NOT invent or fabricate Partner Center `Identity Name`, `Publisher` CN, or live `STORE_LISTING.md` URLs.
- Keep `PublishTrimmed=false` and `PublishSingleFile=false` in `Build-MSIX.ps1` (required for WPF and MSIX loose-layout packaging).
- Keep `<rescap:Capability Name="runFullTrust" />` in `Package.appxmanifest` and `SafetyLockEnabled = true` default ON (Store policy requirement for high-impact system scripts).
- Versions must match across `src/WinPulseStudio/WinPulseStudio.csproj` (`1.2.0`), `scripts/manifest.json` (`1.2.0`), and `Package.appxmanifest` (`1.2.0.0`).

## Review Focus

- **Self-signed certificate leakage:** Shipping an MSIX signed with `CN=WinPulse Studio` or committing a `.pfx`/`.cer` fails Store/CA expectations; Store builds must use `-SkipSigning` until Partner Center/trusted CA signing is configured.
- **Identity/Publisher mismatch:** `Package.appxmanifest` `<Identity Name="WinPulse.Studio" Publisher="CN=WinPulse Studio" />` uses development placeholders that must be replaced with Partner Center's assigned `Name` and `Publisher` before final Store upload.
- **Placeholder URLs in `STORE_LISTING.md`:** `https://example.com/winpulse/*` (3 URLs) will fail `Test-StoreReadiness.ps1` strict mode and Partner Center certification until replaced with live HTTPS pages.
- **Unused satellite cultures bloating MSIX:** Without `<SatelliteResourceLanguages>en-US</SatelliteResourceLanguages>` in `WinPulseStudio.csproj`, `MakeAppx` packs 15+ unused culture folders that conflict with `<Resource Language="en-us" />` in `Package.appxmanifest`.
- **Missing Store visual assets:** `Package.appxmanifest` references `Assets\StoreLogo.png`, `Square150x150Logo.png`, `Square44x44Logo.png`, `Wide310x150Logo.png`, `Square310x310Logo.png`, and `SplashScreen.png`; all must exist in `package\staging\Assets\` before `MakeAppx` packs.

---

### Task 1: Verify Optimization & Scale Prerequisites Are Applied

**Files:**
- Check: `src/WinPulseStudio/WinPulseStudio.csproj`
- Check: `src/WinPulseStudio/Services/WorkspaceService.cs`
- Check: `src/WinPulseStudio/Services/HistoryService.cs`
- Check: `src/WinPulseStudio/Services/CollectionService.cs`

- [ ] **Step 1: Confirm `<SatelliteResourceLanguages>en-US</SatelliteResourceLanguages>` is present in `WinPulseStudio.csproj`**

Run: `Select-String -Path src\WinPulseStudio\WinPulseStudio.csproj -Pattern 'SatelliteResourceLanguages'`
Expected: Match found (`<SatelliteResourceLanguages>en-US</SatelliteResourceLanguages>`). If missing, apply Tasks 1–4 of `2026-11-13-debug-optimize-scale-e2e-build.md` first.

- [ ] **Step 2: Run Release build and full xUnit test suite**

Run: `dotnet test WinPulseStudio.slnx -c Release`
Expected: `Passed! - Failed: 0, Skipped: 0`.

- [ ] **Step 3: Run static AST & catalog validation across all 100 scripts**

Run: `pwsh -NoProfile -File .\tests\Validate-AllScripts.ps1`
Expected: Exits 0 with 100/100 scripts validated.

---

### Task 2: Verify Store Manifest, Asset Integrity & Version Alignment

**Files:**
- Read/Check: `Package.appxmanifest`
- Read/Check: `scripts/manifest.json`
- Read/Check: `commands/commands.json`
- Check: `package/Assets/`

- [ ] **Step 1: Verify all 6 visual assets referenced by `Package.appxmanifest` exist in `package/Assets/`**

Run:
```powershell
$assets = @('StoreLogo.png','Square150x150Logo.png','Square44x44Logo.png','Wide310x150Logo.png','Square310x310Logo.png','SplashScreen.png')
$missing = $assets | Where-Object { -not (Test-Path (Join-Path 'package\Assets' $_)) }
if ($missing) { throw "Missing Store assets: $($missing -join ', ')" }
Write-Host "All 6 Store assets present."
```
Expected: `All 6 Store assets present.`

- [ ] **Step 2: Verify `Package.appxmanifest` declares `runFullTrust`, `Windows.Desktop`, and `en-us` resource**

Run:
```powershell
$xml = [xml](Get-Content Package.appxmanifest -Raw)
Write-Host "Identity: Name=$($xml.Package.Identity.Name) Publisher=$($xml.Package.Identity.Publisher) Version=$($xml.Package.Identity.Version)"
```
Expected: Prints `Identity: Name=WinPulse.Studio Publisher=CN=WinPulse Studio Version=1.2.0.0` (or updated Partner Center values if already provisioned).

---

### Task 3: Build Unsigned Store-Layout MSIX (Stop Before Self-Signing)

**Files:**
- Run: `Build-MSIX.ps1`
- Output: `package/output/WinPulseStudio_1.2.0.0_x64.msix` (unsigned)
- Output: `package/staging/` (inspected layout)

- [ ] **Step 1: Remove any prior self-signed `.cer` or `.msix` from `package/output/`**

Run:
```powershell
Remove-Item -Path 'package\output\*.msix', 'package\output\*.cer' -Force -ErrorAction SilentlyContinue
```
Expected: Clean `package\output\` directory with no leftover dev-signed artifacts.

- [ ] **Step 2: Build the unsigned MSIX layout**

Run: `pwsh -NoProfile -File .\Build-MSIX.ps1 -SkipSigning`
Expected:
- `==> SUCCESS: ...\package\output\WinPulseStudio_1.2.0.0_x64.msix`
- `Signing skipped (-SkipSigning).`
- `Scripts included: 100 .ps1 files`

- [ ] **Step 3: Verify no non-`en-US` satellite resource folders were staged**

Run:
```powershell
$langs = Get-ChildItem package\staging -Directory | Where-Object { $_.Name -match '^(cs|de|es|fr|it|ja|ko|pl|pt-BR|ru|tr|zh-Hans|zh-Hant)$' }
if ($langs) { throw "Unexpected satellite folders: $($langs.Name -join ', ')" }
Write-Host "Staging layout clean: no unused satellite culture folders."
```
Expected: `Staging layout clean: no unused satellite culture folders.`

---

### Task 4: Run Strict Store Readiness Gate & Stop at Partner Center Boundary

**Files:**
- Run: `Test-StoreReadiness.ps1` (strict mode — NO `-AllowSelfSigned`)
- Reference: `STORE_SUBMISSION_CHECKLIST.md`

- [ ] **Step 1: Run strict `Test-StoreReadiness.ps1` to confirm exact remaining Store blockers**

Run: `pwsh -NoProfile -File .\Test-StoreReadiness.ps1`
Expected:
- Code, version, 100-script catalog, and `commands.json` checks all PASS.
- Fails **only** on the external Partner Center / Store blockers:
  1. `STORE_LISTING.md still contains 3 example.com placeholder URL(s).`
  2. `MSIX signature status is 'NotSigned' (expected 'Valid').`
  3. `MSIX signature is not timestamped; it will expire with the certificate.`

- [ ] **Step 2: STOP HERE — Hand off to Partner Center / Human Operator**

Do **not** proceed further in automated builds until the human operator completes:
1. **Partner Center Identity (`STORE_SUBMISSION_CHECKLIST.md` §B):** Reserve app name, update `Package.appxmanifest` `<Identity Name=... Publisher=...>` to Partner Center's assigned values, and rebuild with `pwsh -NoProfile -File .\Build-MSIX.ps1 -SkipSigning` (if Store-signed on upload) or `-CertificateSubject 'CN=<Partner Center CN>'` (if CA-signed).
2. **Public URLs (`STORE_LISTING.md`):** Replace the 3 `https://example.com/winpulse/*` URLs with live HTTPS privacy, support, and product URLs.
3. **Screenshots & Submission (`STORE_SUBMISSION_CHECKLIST.md` §C, §E):** Capture 1–8 screenshots (1366×768+), complete age-rating & `runFullTrust` justification, and upload `package\output\WinPulseStudio_<version>_x64.msix` to Partner Center.
