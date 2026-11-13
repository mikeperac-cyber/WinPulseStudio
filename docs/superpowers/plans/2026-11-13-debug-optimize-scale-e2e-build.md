# Debug, Optimization, Scale & End-to-End Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix concurrency, persistence, and UI allocation bugs in `WinPulseStudio`, optimize package footprint and build script reuse, and execute the full end-to-end build, signing, local MSIX install, and headless verification pipeline.

**Architecture:** Harden `WorkspaceService`, `HistoryService`, `CollectionService`, and `MainWindow` for bounded memory, atomic file writes, and zero-allocation UI updates; deduplicate signing logic across `Build-SingleExe.ps1` and `Build-MSIX.ps1`; and run the complete local verification chain through `Install-MSIX.ps1` and `Test-StoreReadiness.ps1 -AllowSelfSigned`.

**Tech Stack:** .NET 10 (`net10.0-windows`, WPF, `win-x64`), xUnit (`tests/WinPulseStudio.Tests`), PowerShell 7 (`pwsh`), Windows 10/11 SDK (`makeappx.exe`, `signtool.exe`).

**Spec:** User request (`/writing-plans debug and build for optimization and scale` — full end-to-end build) grounded in `src/WinPulseStudio/WinPulseStudio.csproj`, `Build-SingleExe.ps1`, `Build-MSIX.ps1`, `Install-MSIX.ps1`, and `Test-StoreReadiness.ps1`.

## Global Constraints

- Target framework: `net10.0-windows`, `RuntimeIdentifier`: `win-x64`, `UseWPF`: `true`, `Nullable`: `enable`.
- Keep Safety Lock default ON (`SafetyLockEnabled = true`) and never bypass `RunService` safety checks.
- Keep `PublishTrimmed=false` for WPF reflection/XAML compatibility and preserve all 100 bundled `.ps1` scripts, `scripts/manifest.json`, `commands/commands.json`, and `tests/Validate-AllScripts.ps1`.
- Version `1.2.0` (`1.2.0.0` in `Package.appxmanifest`) must remain consistent across `WinPulseStudio.csproj`, `scripts/manifest.json`, and `Package.appxmanifest`.
- PowerShell scripts use `#Requires -Version 7.0`, `Set-StrictMode -Version Latest`, and `$ErrorActionPreference = 'Stop'`.

## Review Focus

- **Process stdout/stderr EOF race:** `Process.WaitForExitAsync` can complete before `OutputDataReceived` / `ErrorDataReceived` deliver their final `null` EOF sentinel, truncating trailing lines of script output.
- **Unbounded script output memory growth:** A noisy or runaway PowerShell script emitting tens of thousands of lines can exhaust memory in `RunProcessCaptureAsync` unless output capture is bounded.
- **Non-atomic JSON writes on crash:** `HistoryService.SaveUnsafe` and `CollectionService.SaveUnsafe` overwrite `history.json` / `collections.json` in place, risking partial-write corruption if the app exits mid-write.
- **Minimized-window timer & UI brush churn:** `MainWindow._telemetryTimer` ticks every 3 seconds even when minimized, and `UpdateSafetyLockUi` allocates new `SolidColorBrush` instances on every toggle.
- **Bloated satellite resource DLLs in MSIX/SingleExe:** Publishing without `<SatelliteResourceLanguages>en-US</SatelliteResourceLanguages>` ships 15+ unused localized WPF resource folders that mismatch `Package.appxmanifest` (`en-us`).

---

### Task 1: Fix `RunProcessCaptureAsync` Stream EOF Race and Bound Output Scale

**Files:**
- Modify: `src/WinPulseStudio/Services/WorkspaceService.cs:480-591`
- Create: `tests/WinPulseStudio.Tests/RunProcessCaptureScaleTests.cs`

**Interfaces:**
- Consumes: `WorkspaceService.ExecuteScriptAsync`, `WorkspaceService.ValidateSingleScriptAstAsync`, `RunOutcome`
- Produces: `WorkspaceService.RunProcessCaptureAsync` awaiting both stdout/stderr EOF `TaskCompletionSource<bool>` signals and capping retained output at `MaxCapturedChars = 262_144` (preserving tail notice when truncated).

- [ ] **Step 1: Write the failing test**

Create `tests/WinPulseStudio.Tests/RunProcessCaptureScaleTests.cs`:

```csharp
using System.IO;
using WinPulseStudio.Models;
using WinPulseStudio.Services;
using Xunit;

namespace WinPulseStudio.Tests;

public sealed class RunProcessCaptureScaleTests
{
    [Fact]
    public async Task ExecuteScriptAsync_FlushesTrailingLinesAndBoundsLargeOutput()
    {
        var tempRoot = Path.Combine(Path.GetTempPath(), "winpulse-scale-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(Path.Combine(tempRoot, "scripts"));
        try
        {
            var scriptPath = Path.Combine(tempRoot, "scripts", "noisy.ps1");
            await File.WriteAllTextAsync(scriptPath, """
                param([switch]$DryRun)
                1..6000 | ForEach-Object { Write-Output "line-$_-0123456789012345678901234567890123456789" }
                Write-Output "FINAL-SENTINEL-LINE"
                """);

            var ws = new WorkspaceService(tempRoot, tempRoot);
            var item = new ScriptItem
            {
                Id = "999",
                Name = "Noisy",
                RelativePath = "scripts/noisy.ps1",
                FullPath = scriptPath,
                BundledPath = scriptPath
            };

            var outcome = await ws.ExecuteScriptAsync(item, dryRun: true, safetyLockEnabled: false);

            Assert.True(outcome.Success);
            Assert.Contains("FINAL-SENTINEL-LINE", outcome.Output);
            Assert.True(outcome.Output.Length <= 270_000, $"Expected bounded output, got {outcome.Output.Length} chars.");
        }
        finally
        {
            Directory.Delete(tempRoot, recursive: true);
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dotnet test tests/WinPulseStudio.Tests/WinPulseStudio.Tests.csproj -c Release --filter "FullyQualifiedName~RunProcessCaptureScaleTests"`
Expected: FAIL (`outcome.Output.Length` exceeds `270_000` chars because `StringBuilder` is unbounded).

- [ ] **Step 3: Implement EOF awaiting and bounded capture in `WorkspaceService.RunProcessCaptureAsync`**

In `src/WinPulseStudio/Services/WorkspaceService.cs`:
1. Add `private const int MaxCapturedChars = 262_144;` and `private const string TruncationBanner = "[TRUNCATED] Earlier output omitted to bound memory; showing most recent output.\r\n";`.
2. Track `stdoutDone = new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously)` and `stderrDone = new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously)`. Set them when `e.Data == null` in `OutputDataReceived` / `ErrorDataReceived`.
3. In `Append(string line)`, under `lock (sb)`, append the line and if `sb.Length > MaxCapturedChars`, trim the front to keep the most recent `MaxCapturedChars - TruncationBanner.Length` characters prefixed with `TruncationBanner`.
4. After `await proc.WaitForExitAsync(timeoutCts.Token)`, await `Task.WhenAll(stdoutDone.Task, stderrDone.Task).WaitAsync(TimeSpan.FromSeconds(5))` (catching timeout so a hung child handle cannot deadlock).

- [ ] **Step 4: Run test to verify it passes**

Run: `dotnet test tests/WinPulseStudio.Tests/WinPulseStudio.Tests.csproj -c Release --filter "FullyQualifiedName~RunProcessCaptureScaleTests"`
Expected: PASS (1 passed, 0 failed).

- [ ] **Step 5: Commit**

```bash
git add src/WinPulseStudio/Services/WorkspaceService.cs tests/WinPulseStudio.Tests/RunProcessCaptureScaleTests.cs
git commit -m "fix: await stdout/stderr EOF and bound captured process output"
```

---

### Task 2: Atomic Persistence, Cached `JsonSerializerOptions`, and Bounded Sort in `HistoryService` & `CollectionService`

**Files:**
- Modify: `src/WinPulseStudio/Services/HistoryService.cs:8-87`
- Modify: `src/WinPulseStudio/Services/CollectionService.cs:8-86`
- Modify: `tests/WinPulseStudio.Tests/HistoryAndCollectionTests.cs`

**Interfaces:**
- Consumes: `HistoryService(string? storageDirectory)`, `CollectionService(string? storageDirectory)`
- Produces: Atomic temp-file + `File.Move(tempPath, path, overwrite: true)` writes, shared `static readonly JsonSerializerOptions IndentedJsonOptions`, and single-pass `HistoryService.Add` trimming without double-sorting.

- [ ] **Step 1: Write the failing test**

Add a test in `tests/WinPulseStudio.Tests/HistoryAndCollectionTests.cs` verifying that adding 550 records keeps the 500 newest records in descending order via `GetAll()` and leaves no `.tmp` files behind on disk:

```csharp
[Fact]
public void HistoryService_TrimAndAtomicSave_LeavesNoTempFilesAndKeepsNewest500()
{
    var dir = Path.Combine(Path.GetTempPath(), "winpulse-hist-" + Guid.NewGuid().ToString("N"));
    try
    {
        var svc = new HistoryService(dir);
        var baseTime = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);
        for (int i = 0; i < 550; i++)
        {
            svc.Add(new RunRecord { ScriptId = i.ToString("D3"), Timestamp = baseTime.AddSeconds(i) });
        }

        var all = svc.GetAll();
        Assert.Equal(500, all.Count);
        Assert.Equal("549", all[0].ScriptId);
        Assert.Equal("050", all[^1].ScriptId);
        Assert.Empty(Directory.GetFiles(dir, "*.tmp"));
    }
    finally
    {
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
    }
}
```

- [ ] **Step 2: Run test to verify it fails or establishes baseline**

Run: `dotnet test tests/WinPulseStudio.Tests/WinPulseStudio.Tests.csproj -c Release --filter "FullyQualifiedName~HistoryAndCollectionTests"`
Expected: Compiles and runs; check existing tests pass before refactoring `SaveUnsafe` and `Add`.

- [ ] **Step 3: Refactor `HistoryService` and `CollectionService`**

1. In both `HistoryService` and `CollectionService`, add `private static readonly JsonSerializerOptions IndentedJsonOptions = new() { WriteIndented = true };`.
2. Update `SaveUnsafe()` in both services to write `var tempPath = HistoryPath + ".tmp";` (or `CollectionsPath + ".tmp"`), `File.WriteAllText(tempPath, json, Encoding.UTF8);`, and `File.Move(tempPath, targetPath, overwrite: true);`.
3. In `HistoryService.Add(RunRecord record)`, when `_records.Count > MaxRecords`, sort descending once (`_records = _records.OrderByDescending(r => r.Timestamp).Take(MaxRecords).ToList();`) and keep `GetAll()` returning `_records.OrderByDescending(r => r.Timestamp).ToList()`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `dotnet test tests/WinPulseStudio.Tests/WinPulseStudio.Tests.csproj -c Release --filter "FullyQualifiedName~HistoryAndCollectionTests"`
Expected: PASS (all tests in `HistoryAndCollectionTests` pass).

- [ ] **Step 5: Commit**

```bash
git add src/WinPulseStudio/Services/HistoryService.cs src/WinPulseStudio/Services/CollectionService.cs tests/WinPulseStudio.Tests/HistoryAndCollectionTests.cs
git commit -m "perf: use atomic writes and cached JsonSerializerOptions in History/Collection services"
```

---

### Task 3: Eliminate `MainWindow` Brush/View Allocations and Pause Timer When Minimized

**Files:**
- Modify: `src/WinPulseStudio/MainWindow.xaml.cs:29-161`

**Interfaces:**
- Consumes: `INavigator`, `SessionContext`, `HomeView`
- Produces: Cached `_homeView` field, static frozen safety-lock brushes (`LockedFgBrush`, `LockedBgBrush`, `UnlockedFgBrush`, `UnlockedBgBrush`), one-time `TxtHostCpu` initialization, and `StateChanged` handler that stops/starts `_telemetryTimer` when `WindowState == WindowState.Minimized`.

- [ ] **Step 1: Inspect `MainWindow.xaml.cs` lines 144-161 to confirm exact unlocked brush RGB values**

Read `src/WinPulseStudio/MainWindow.xaml.cs` lines 140-161 before editing so exact colors are preserved.

- [ ] **Step 2: Apply optimizations in `src/WinPulseStudio/MainWindow.xaml.cs`**

1. Add `private HomeView? _homeView;` and reuse it in `ShowHome()` (`_homeView ??= new HomeView(_session, this); ContentHost.Content = _homeView;`).
2. Replace `new SolidColorBrush(...)` inside `UpdateSafetyLockUi()` with `private static readonly SolidColorBrush` fields initialized via `CreateFrozen(...)`.
3. Move `TxtHostCpu.Text = $"{Environment.MachineName} • {Environment.ProcessorCount} Logical Cores";` into `MainWindow_Loaded` so `UpdateTelemetryHeader()` only polls `WorkspaceService.GetMemoryTelemetry()`.
4. Subscribe `StateChanged += (_, _) => { if (WindowState == WindowState.Minimized) _telemetryTimer.Stop(); else if (!_telemetryTimer.IsEnabled) { UpdateTelemetryHeader(); _telemetryTimer.Start(); } };` and `Closed += (_, _) => _telemetryTimer.Stop();`.

- [ ] **Step 3: Build and run full test suite (including `CommandsViewInitializationTests`)**

Run: `dotnet test WinPulseStudio.slnx -c Release`
Expected: Build succeeds with 0 errors and all tests pass.

- [ ] **Step 4: Commit**

```bash
git add src/WinPulseStudio/MainWindow.xaml.cs
git commit -m "perf: cache HomeView, freeze safety-lock brushes, and pause telemetry when minimized"
```

---

### Task 4: Trim Unused Satellite Cultures and Deduplicate Build Signing Helper

**Files:**
- Modify: `src/WinPulseStudio/WinPulseStudio.csproj:3-16`
- Create: `scripts/Invoke-WinPulseSigning.ps1`
- Modify: `Build-SingleExe.ps1:50-93`
- Modify: `Build-MSIX.ps1:72-116`

**Interfaces:**
- Consumes: `Package.appxmanifest` (`en-us` resource), `WinPulseStudio.csproj`
- Produces: `<SatelliteResourceLanguages>en-US</SatelliteResourceLanguages>` in `WinPulseStudio.csproj`, and `scripts/Invoke-WinPulseSigning.ps1` exporting `Invoke-WinPulseCodeSign -TargetPath <string> -CertificateSubject <string> -ExportCertDir <string>`.

- [ ] **Step 1: Add `<SatelliteResourceLanguages>en-US</SatelliteResourceLanguages>` to `src/WinPulseStudio/WinPulseStudio.csproj`**

Insert `<SatelliteResourceLanguages>en-US</SatelliteResourceLanguages>` inside the first `<PropertyGroup>` of `src/WinPulseStudio/WinPulseStudio.csproj` to match `<Resource Language="en-us" />` in `Package.appxmanifest`.

- [ ] **Step 2: Create `scripts/Invoke-WinPulseSigning.ps1`**

Extract the shared `signtool.exe` discovery, `Cert:\CurrentUser\My` lookup/creation, timestamped signing with fallback (`http://timestamp.digicert.com`), and `WinPulseStudio.cer` export into `scripts/Invoke-WinPulseSigning.ps1`.

- [ ] **Step 3: Update `Build-SingleExe.ps1` and `Build-MSIX.ps1` to dot-source `scripts/Invoke-WinPulseSigning.ps1`**

Replace the duplicated signing blocks in both scripts with calls to `Invoke-WinPulseCodeSign`.

- [ ] **Step 4: Run script syntax/catalog validation**

Run: `pwsh -NoProfile -File .\tests\Validate-AllScripts.ps1`
Expected: Exits 0 with all 100 scripts valid.

- [ ] **Step 5: Commit**

```bash
git add src/WinPulseStudio/WinPulseStudio.csproj scripts/Invoke-WinPulseSigning.ps1 Build-SingleExe.ps1 Build-MSIX.ps1
git commit -m "build: trim non-en-US satellite resources and share code-signing helper"
```

---

### Task 5: Execute Full End-to-End Local Build, Packaging, Install & Headless Verification

**Files:**
- Outputs: `dist/WinPulseStudio.exe`, `package/output/WinPulseStudio_1.2.0.0_x64.msix`, `package/output/WinPulseStudio.cer`

- [ ] **Step 1: Run clean Release build and unit tests**

Run: `dotnet test WinPulseStudio.slnx -c Release`
Expected: `Passed! - Failed: 0, Skipped: 0`.

- [ ] **Step 2: Run static validation of all 100 PowerShell scripts**

Run: `pwsh -NoProfile -File .\tests\Validate-AllScripts.ps1`
Expected: Exits 0.

- [ ] **Step 3: Build & locally sign single-file executable**

Run: `pwsh -NoProfile -File .\Build-SingleExe.ps1`
Expected: `==> SUCCESS: ...\dist\WinPulseStudio.exe` and `WinPulseStudio.cer` created, with reduced size from satellite trimming.

- [ ] **Step 4: Build & locally sign MSIX package**

Run: `pwsh -NoProfile -File .\Build-MSIX.ps1`
Expected: `==> SUCCESS: ...\package\output\WinPulseStudio_1.2.0.0_x64.msix`.

- [ ] **Step 5: Run end-to-end MSIX install + `--verify-headless` + clean uninstall**

Run: `pwsh -NoProfile -File .\Install-MSIX.ps1`
Expected: `==> SUCCESS: MSIX (signed mode) installed and verified end to end.` (or `register mode` under Developer Mode) with `[WinPulseStudio UI + Headless Self-Test] Loaded 100 scripts...` and exit code 0.

- [ ] **Step 6: Run local pre-flight Store readiness gate**

Run: `pwsh -NoProfile -File .\Test-StoreReadiness.ps1 -AllowSelfSigned`
Expected: Exit code 0 (`PASS: machine-checkable Store readiness checks succeeded.`).
