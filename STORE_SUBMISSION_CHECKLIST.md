# Store Submission Checklist — WinPulse Control Studio

Work top to bottom. `Test-StoreReadiness.ps1` automates the machine-checkable
items; the rest are human/Partner Center steps.

## A. Machine-checkable (run the gate)

```powershell
pwsh -File .\Test-StoreReadiness.ps1
```

It fails until all of these are true:

- [ ] `STORE_LISTING.md` contains no `example.com` placeholder URLs.
- [ ] Versions agree across `WinPulseStudio.csproj`, `scripts/manifest.json`,
      and `Package.appxmanifest` (`1.2.0` / `1.2.0.0`).
- [ ] `scripts/manifest.json` lists 100 scripts and 100 files exist on disk.
- [ ] `commands/commands.json` `totalCommands` matches the actual entry count.
- [ ] The MSIX exists at `package\output\WinPulseStudio_1.2.0.0_x64.msix`.
- [ ] The MSIX signature is `Valid` (trusted certificate chain), not
      `UnknownError` like the local self-signed build.
- [ ] The MSIX signature is timestamped.

## B. Identity and certificate (one-time)

- [ ] Reserve the app name in **Partner Center**.
- [ ] Update `Package.appxmanifest` `<Identity Name=... Publisher=...>` to the
      exact values Partner Center assigns. `Publisher` must match the subject
      of the signing certificate **character for character**.
- [ ] Obtain a code-signing certificate (Partner Center-issued or a public CA
      certificate), or use the certificate Partner Center provides.
- [ ] Replace the local self-signed cert in `Build-MSIX.ps1`:
      `-CertificateSubject 'CN=<your exact publisher CN>'` or sign manually.
- [ ] Confirm `signtool verify /pa /v package\output\*.msix` reports success.

## C. Content and policy

- [ ] Fill in the three URLs in `STORE_LISTING.md` (privacy, support, website).
- [ ] Publish the privacy policy page. It must state what the app reads
      (system info, process list, event logs) and that nothing leaves the PC.
- [ ] Capture 1–8 screenshots listed in `STORE_LISTING.md` at 1366×768 or larger.
- [ ] Confirm the age rating and category in Partner Center.
- [ ] Justify `runFullTrust` in the submission notes: the app is a desktop
      utility that runs local PowerShell and writes system settings.
- [ ] Review every built-in script's effect. Defender exclusions (`#031`),
      telemetry/hosts changes (`#081`, `#090`), and USB lockdown (`#086`) are
      high-impact; make sure the description is accurate and the Safety Lock
      default remains ON.

## D. Build and verify the submission package

```powershell
pwsh -File .\Build-MSIX.ps1
pwsh -File .\Install-MSIX.ps1      # end-to-end install + headless self-test
pwsh -File .\Test-StoreReadiness.ps1
```

- [ ] Install test passes (`==> SUCCESS: MSIX ... verified end to end`).
- [ ] `Get-AppxPackage MikePerac.WinPulseStudio` shows the expected version.
- [ ] Uninstall cleanly: `Remove-AppxPackage`.

## E. Submit

- [ ] Upload `package\output\WinPulseStudio_<version>_x64.msix`.
- [ ] Paste the listing text from `STORE_LISTING.md`.
- [ ] Upload screenshots, Store logo, and promotional images.
- [ ] Complete the age-rating questionnaire.
- [ ] Submit for certification and respond to any report.

## F. After release

- [ ] Bump `<Version>` / manifest version / `Package.appxmanifest` version
      together for every release.
- [ ] Keep the local `CN=WinPulse Studio` self-signed cert for development only;
      never ship it as the production signer.
- [ ] Re-run `Test-StoreReadiness.ps1` in CI before tagging a release.
