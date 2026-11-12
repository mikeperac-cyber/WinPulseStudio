using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using System.Text.Json;
using WinPulseStudio.Models;

namespace WinPulseStudio.Services;

public sealed class WorkspaceService
{
    public string WorkspaceRoot { get; }
    public string UserDataRoot { get; }
    public string UserScriptsRoot => Path.Combine(UserDataRoot, "scripts");
    public string ManifestPath => Path.Combine(WorkspaceRoot, "scripts", "manifest.json");
    public string ValidatorScriptPath => Path.Combine(WorkspaceRoot, "tests", "Validate-AllScripts.ps1");
    public string FavoritesPath => Path.Combine(UserDataRoot, "favorites.json");
    public bool PowerShellAvailable => IsPowerShellAvailable();

    private static bool? _powerShellAvailable;

    public WorkspaceService()
        : this(workspaceRoot: null, userDataRoot: null)
    {
    }

    public WorkspaceService(string? workspaceRoot, string? userDataRoot)
    {
        WorkspaceRoot = workspaceRoot ?? DiscoverWorkspaceRoot();
        UserDataRoot = userDataRoot ?? Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "WinPulseStudio");

        try
        {
            Directory.CreateDirectory(UserDataRoot);
        }
        catch
        {
            // The app can still browse; persistence is best-effort.
        }
    }

    private static string DiscoverWorkspaceRoot()
    {
        var candidates = new List<string>
        {
            Directory.GetCurrentDirectory(),
            AppContext.BaseDirectory
        };

        foreach (var start in candidates)
        {
            var dir = new DirectoryInfo(start);
            while (dir != null)
            {
                var testManifest = Path.Combine(dir.FullName, "scripts", "manifest.json");
                if (File.Exists(testManifest))
                {
                    return dir.FullName;
                }
                dir = dir.Parent;
            }
        }

        // No workspace folder found (e.g. a published install without bundled
        // scripts). Fall back to the current directory so the app still boots
        // and can surface a clear catalog error instead of hardcoding a
        // machine-specific path.
        return Directory.GetCurrentDirectory();
    }

    public ManifestRoot LoadManifest()
    {
        if (!File.Exists(ManifestPath))
        {
            return new ManifestRoot();
        }

        try
        {
            var json = File.ReadAllText(ManifestPath, Encoding.UTF8);
            var manifest = JsonSerializer.Deserialize<ManifestRoot>(json) ?? new ManifestRoot();
            var favIds = LoadFavoriteIds();

            foreach (var script in manifest.Scripts)
            {
                var normalizedRel = script.RelativePath.Replace('/', Path.DirectorySeparatorChar);
                script.BundledPath = Path.Combine(WorkspaceRoot, normalizedRel);
                var userOverride = Path.Combine(UserScriptsRoot, normalizedRel);
                script.FullPath = File.Exists(userOverride) ? userOverride : script.BundledPath;
                script.IsFavorite = favIds.Contains(script.Id);
            }

            return manifest;
        }
        catch (JsonException)
        {
            // A malformed catalog must not crash the UI. The empty catalog lets
            // the caller show a clear error instead of failing startup.
            return new ManifestRoot();
        }
    }

    public HashSet<string> LoadFavoriteIds()
    {
        try
        {
            if (File.Exists(FavoritesPath))
            {
                var json = File.ReadAllText(FavoritesPath, Encoding.UTF8);
                var list = JsonSerializer.Deserialize<List<string>>(json);
                if (list != null)
                {
                    return new HashSet<string>(list, StringComparer.OrdinalIgnoreCase);
                }
            }

            // Migrate the old workspace-root favorites file once, so upgrades do
            // not silently lose pinned scripts.
            var legacyPath = Path.Combine(WorkspaceRoot, ".winpulse-favorites.json");
            if (File.Exists(legacyPath))
            {
                var legacyJson = File.ReadAllText(legacyPath, Encoding.UTF8);
                var legacyList = JsonSerializer.Deserialize<List<string>>(legacyJson);
                if (legacyList != null)
                {
                    Directory.CreateDirectory(UserDataRoot);
                    File.WriteAllText(FavoritesPath, legacyJson, Encoding.UTF8);
                    return new HashSet<string>(legacyList, StringComparer.OrdinalIgnoreCase);
                }
            }
        }
        catch
        {
            // Ignore malformed/unreadable favorites file.
        }

        return new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "001", "011", "021", "023", "031", "061", "091"
        };
    }

    public bool SaveFavorites(IEnumerable<ScriptItem> scripts)
    {
        try
        {
            var favs = scripts.Where(s => s.IsFavorite).Select(s => s.Id).OrderBy(x => x).ToList();
            var json = JsonSerializer.Serialize(favs, new JsonSerializerOptions { WriteIndented = true });
            Directory.CreateDirectory(UserDataRoot);
            var tempPath = FavoritesPath + ".tmp";
            File.WriteAllText(tempPath, json, Encoding.UTF8);
            File.Move(tempPath, FavoritesPath, true);
            return true;
        }
        catch
        {
            return false;
        }
    }

    public string ReadScriptSource(ScriptItem script)
    {
        var path = File.Exists(script.FullPath) ? script.FullPath : script.BundledPath;
        if (File.Exists(path))
        {
            return File.ReadAllText(path, Encoding.UTF8);
        }
        return $"# Script file not found at: {path}";
    }

    /// <summary>
    /// Saves an edited script to a user-writable override under LocalAppData.
    /// The bundled script is never overwritten, which keeps MSIX installs and
    /// single-file extraction directories working.
    /// </summary>
    public bool SaveScriptSource(ScriptItem script, string newContent)
    {
        if (string.IsNullOrWhiteSpace(script.RelativePath))
        {
            return false;
        }

        try
        {
            var normalizedRel = script.RelativePath.Replace('/', Path.DirectorySeparatorChar);
            var userPath = Path.Combine(UserScriptsRoot, normalizedRel);
            Directory.CreateDirectory(Path.GetDirectoryName(userPath)!);
            var tempPath = userPath + ".tmp";
            File.WriteAllText(tempPath, newContent, Encoding.UTF8);
            File.Move(tempPath, userPath, true);
            script.FullPath = userPath;
            return true;
        }
        catch
        {
            return false;
        }
    }

    public static bool IsPowerShellAvailable()
    {
        if (_powerShellAvailable.HasValue)
        {
            return _powerShellAvailable.Value;
        }

        var pathValue = Environment.GetEnvironmentVariable("PATH") ?? string.Empty;
        foreach (var dir in pathValue.Split(Path.PathSeparator, StringSplitOptions.RemoveEmptyEntries))
        {
            try
            {
                if (File.Exists(Path.Combine(dir, "pwsh.exe")) || File.Exists(Path.Combine(dir, "pwsh")))
                {
                    _powerShellAvailable = true;
                    return true;
                }
            }
            catch
            {
                // Ignore inaccessible PATH entries.
            }
        }

        _powerShellAvailable = false;
        return false;
    }

    public static bool IsRunningAsAdministrator()
    {
        try
        {
            using var identity = WindowsIdentity.GetCurrent();
            var principal = new WindowsPrincipal(identity);
            return principal.IsInRole(WindowsBuiltInRole.Administrator);
        }
        catch
        {
            return false;
        }
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    private sealed class MEMORYSTATUSEX
    {
        public uint dwLength = (uint)Marshal.SizeOf<MEMORYSTATUSEX>();
        public uint dwMemoryLoad;
        public ulong ullTotalPhys;
        public ulong ullAvailPhys;
        public ulong ullTotalPageFile;
        public ulong ullAvailPageFile;
        public ulong ullTotalVirtual;
        public ulong ullAvailVirtual;
        public ulong ullAvailExtendedVirtual;
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GlobalMemoryStatusEx([In, Out] MEMORYSTATUSEX lpBuffer);

    public static (double UsedGb, double TotalGb, uint LoadPercent) GetMemoryTelemetry()
    {
        try
        {
            var mem = new MEMORYSTATUSEX();
            if (GlobalMemoryStatusEx(mem))
            {
                double totalGb = Math.Round(mem.ullTotalPhys / (1024.0 * 1024.0 * 1024.0), 1);
                double availGb = Math.Round(mem.ullAvailPhys / (1024.0 * 1024.0 * 1024.0), 1);
                double usedGb = Math.Round(totalGb - availGb, 1);
                return (usedGb, totalGb, mem.dwMemoryLoad);
            }
        }
        catch
        {
            // Fallback below.
        }
        return (0, 0, 0);
    }

    /// <summary>
    /// Statically validates a single script using PowerShell's AST Parser
    /// WITHOUT executing any optimization script.
    /// </summary>
    public async Task<RunOutcome> ValidateSingleScriptAstAsync(ScriptItem script)
    {
        var path = File.Exists(script.FullPath) ? script.FullPath : script.BundledPath;
        if (!File.Exists(path))
        {
            return new RunOutcome(false, 1, $"[FAIL] File not found: {path}", TimeSpan.Zero, RunMode.Verify);
        }

        string escapedPath = path.Replace("'", "''");
        string escapedName = script.Name.Replace("'", "''");
        string escapedId = script.Id.Replace("'", "''");
        string psAstCommand = $@"
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile('{escapedPath}', [ref]$tokens, [ref]$errors)
if ($errors.Count -gt 0) {{
    foreach ($e in $errors) {{ Write-Output ""[AST ERROR] Line $($e.Extent.StartLineNumber): $($e.Message)"" }}
    exit 1
}}
$cmds = @($ast.FindAll({{ param($n) $n -is [System.Management.Automation.Language.CommandAst] }}, $true))
$params = @($ast.ParamBlock.Parameters | ForEach-Object {{ $_.Name.VariablePath.UserPath }})
Write-Output ""[STATIC AST VERIFIED] #{escapedId} ({escapedName})""
Write-Output ""  File       : {escapedPath}""
Write-Output ""  Tokens     : $($tokens.Count) tokens parsed with 0 syntax errors""
Write-Output ""  Parameters : -$($params -join ', -')""
Write-Output ""  AST Nodes  : $($cmds.Count) command invocations verified""
Write-Output ""  Safety     : Non-execution static verification succeeded.""
";

        return await RunPwshCommandInternalAsync(psAstCommand);
    }

    public async Task<RunOutcome> ValidateAll100ScriptsAstAsync()
    {
        if (!File.Exists(ValidatorScriptPath))
        {
            return new RunOutcome(false, 1, $"Validator script missing at {ValidatorScriptPath}", TimeSpan.Zero, RunMode.Verify);
        }

        if (!PowerShellAvailable)
        {
            return new RunOutcome(
                false,
                -1,
                "[ERROR] PowerShell 7 (pwsh) was not found on PATH. Install PowerShell 7 and restart the app.",
                TimeSpan.Zero,
                RunMode.Verify);
        }

        string args = $"-NoProfile -ExecutionPolicy Bypass -File \"{ValidatorScriptPath}\"";
        return await RunProcessCaptureAsync(
            "pwsh",
            args,
            onLineReceived: null,
            modeOverride: RunMode.Verify,
            timeout: TimeSpan.FromMinutes(10));
    }

    /// <summary>
    /// Executes a script with or without -DryRun. Live execution is refused while the
    /// Safety Lock is on; instead the script is statically inspected. Preview (dry-run)
    /// is always allowed because -DryRun never changes the system.
    /// </summary>
    public async Task<RunOutcome> ExecuteScriptAsync(
        ScriptItem script,
        bool dryRun,
        bool safetyLockEnabled,
        Action<string>? onLineReceived = null)
    {
        if (!PowerShellAvailable)
        {
            var missing = BuildPowerShellMissingOutcome(RunMode.Verify);
            onLineReceived?.Invoke(missing.Output);
            return missing;
        }

        if (!dryRun && safetyLockEnabled)
        {
            var sb = new StringBuilder();
            sb.AppendLine("======================================================================");
            sb.AppendLine($" [SAFETY LOCK ACTIVE] #{script.Id} - {script.Name}");
            sb.AppendLine("======================================================================");
            sb.AppendLine("Mode           : Static Non-Execution Inspection (Safety Lock is ON)");
            sb.AppendLine($"Script Path    : {script.FullPath}");
            sb.AppendLine($"Category       : {script.Category} / {script.Subcategory}");
            sb.AppendLine($"Impact         : {script.Impact} | Requires Admin: {script.RequiresAdmin} | Reversible: {script.Reversible}");
            sb.AppendLine($"Summary        : {script.SummaryText}");
            sb.AppendLine();
            var astRes = await ValidateSingleScriptAstAsync(script);
            sb.AppendLine(astRes.Output.TrimEnd());
            sb.AppendLine();
            sb.AppendLine("[TIP] Safety Lock is ON: live changes are blocked. Use Preview (-DryRun) to simulate,");
            sb.AppendLine("      or turn the Safety Lock off in the top bar when you are ready to apply changes.");
            var text = sb.ToString();
            onLineReceived?.Invoke(text);
            return new RunOutcome(astRes.Success, astRes.Success ? 0 : 1, text, astRes.Duration, RunMode.Verify);
        }

        string dryFlag = dryRun ? " -DryRun" : string.Empty;
        string args = $"-NoProfile -ExecutionPolicy Bypass -File \"{script.FullPath}\"{dryFlag}";
        return await RunProcessCaptureAsync(
            "pwsh",
            args,
            onLineReceived,
            timeout: dryRun ? TimeSpan.FromMinutes(5) : TimeSpan.FromMinutes(30));
    }

    /// <summary>
    /// Runs a script with one of its built-in undo switches (for example -Revert or
    /// -RestoreNotifications). This is a live change; the caller must have the Safety
    /// Lock off, and this method re-checks it as defense in depth.
    /// </summary>
    public async Task<RunOutcome> ExecuteScriptWithSwitchAsync(
        ScriptItem script,
        string switchName,
        bool safetyLockEnabled,
        Action<string>? onLineReceived = null)
    {
        if (!PowerShellAvailable)
        {
            var missing = BuildPowerShellMissingOutcome(RunMode.Live);
            onLineReceived?.Invoke(missing.Output);
            return missing;
        }

        if (safetyLockEnabled)
        {
            var blocked = new RunOutcome(
                false,
                -1,
                $"[ERROR] Safety Lock is ON. Unlock it in the top bar before reverting #{script.Id} -{switchName}.",
                TimeSpan.Zero,
                RunMode.Live);
            onLineReceived?.Invoke(blocked.Output);
            return blocked;
        }

        string args = $"-NoProfile -ExecutionPolicy Bypass -File \"{script.FullPath}\" -{switchName}";
        return await RunProcessCaptureAsync("pwsh", args, onLineReceived, timeout: TimeSpan.FromMinutes(30));
    }

    private static RunOutcome BuildPowerShellMissingOutcome(RunMode mode)
    {
        return new RunOutcome(
            false,
            -1,
            "[ERROR] PowerShell 7 (pwsh) was not found on PATH. Install PowerShell 7 and restart the app.",
            TimeSpan.Zero,
            mode);
    }

    private async Task<RunOutcome> RunPwshCommandInternalAsync(string command)
    {
        if (!PowerShellAvailable)
        {
            return BuildPowerShellMissingOutcome(RunMode.Verify);
        }

        string bytesB64 = Convert.ToBase64String(Encoding.Unicode.GetBytes(command));
        string args = $"-NoProfile -NonInteractive -EncodedCommand {bytesB64}";
        return await RunProcessCaptureAsync(
            "pwsh",
            args,
            modeOverride: RunMode.Verify,
            timeout: TimeSpan.FromMinutes(2));
    }

    private static async Task<RunOutcome> RunProcessCaptureAsync(
        string fileName,
        string arguments,
        Action<string>? onLineReceived = null,
        RunMode? modeOverride = null,
        TimeSpan? timeout = null)
    {
        var sb = new StringBuilder();
        var stopwatch = Stopwatch.StartNew();
        var mode = modeOverride ?? (arguments.Contains("-DryRun", StringComparison.OrdinalIgnoreCase)
            ? RunMode.DryRun
            : RunMode.Live);

        using var timeoutCts = new CancellationTokenSource();
        if (timeout.HasValue)
        {
            timeoutCts.CancelAfter(timeout.Value);
        }

        using var proc = new Process
        {
            StartInfo = new ProcessStartInfo
            {
                FileName = fileName,
                Arguments = arguments,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
                StandardOutputEncoding = Encoding.UTF8,
                StandardErrorEncoding = Encoding.UTF8
            }
        };

        void Append(string line)
        {
            lock (sb)
            {
                sb.AppendLine(line);
            }

            try
            {
                onLineReceived?.Invoke(line);
            }
            catch
            {
                // A UI callback must not tear down the reader thread.
            }
        }

        try
        {
            proc.OutputDataReceived += (_, e) =>
            {
                if (e.Data != null)
                {
                    Append(e.Data);
                }
            };
            proc.ErrorDataReceived += (_, e) =>
            {
                if (e.Data != null)
                {
                    Append($"[STDERR] {e.Data}");
                }
            };

            proc.Start();
            proc.BeginOutputReadLine();
            proc.BeginErrorReadLine();
            await proc.WaitForExitAsync(timeoutCts.Token);
            stopwatch.Stop();

            lock (sb)
            {
                return new RunOutcome(proc.ExitCode == 0, proc.ExitCode, sb.ToString(), stopwatch.Elapsed, mode);
            }
        }
        catch (OperationCanceledException)
        {
            stopwatch.Stop();
            try
            {
                if (!proc.HasExited)
                {
                    proc.Kill(entireProcessTree: true);
                }
            }
            catch
            {
                // Process may have exited between the check and the kill.
            }

            string msg = $"[ERROR] {fileName} exceeded the {(timeout ?? TimeSpan.Zero).TotalMinutes:0} minute timeout and was terminated.";
            Append(msg);
            lock (sb)
            {
                return new RunOutcome(false, -1, sb.ToString(), stopwatch.Elapsed, mode);
            }
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            string msg = $"[ERROR] Failed to invoke {fileName}: {ex.Message}";
            Append(msg);
            lock (sb)
            {
                return new RunOutcome(false, -1, sb.ToString(), stopwatch.Elapsed, mode);
            }
        }
    }
}