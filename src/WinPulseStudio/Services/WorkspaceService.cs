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
    public string ManifestPath => Path.Combine(WorkspaceRoot, "scripts", "manifest.json");
    public string ValidatorScriptPath => Path.Combine(WorkspaceRoot, "tests", "Validate-AllScripts.ps1");
    public string FavoritesPath => Path.Combine(WorkspaceRoot, ".winpulse-favorites.json");

    public WorkspaceService()
    {
        WorkspaceRoot = DiscoverWorkspaceRoot();
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

        const string fallback = @"c:\Users\MIKE\Documents\pwsh";
        return Directory.Exists(fallback) ? fallback : Directory.GetCurrentDirectory();
    }

    public ManifestRoot LoadManifest()
    {
        if (!File.Exists(ManifestPath))
        {
            return new ManifestRoot();
        }

        var json = File.ReadAllText(ManifestPath, Encoding.UTF8);
        var manifest = JsonSerializer.Deserialize<ManifestRoot>(json) ?? new ManifestRoot();
        var favIds = LoadFavoriteIds();

        foreach (var script in manifest.Scripts)
        {
            var normalizedRel = script.RelativePath.Replace('/', Path.DirectorySeparatorChar);
            script.FullPath = Path.Combine(WorkspaceRoot, normalizedRel);
            script.IsFavorite = favIds.Contains(script.Id);
        }

        return manifest;
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
        }
        catch
        {
            // Ignore malformed favorites file
        }
        return new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "001", "011", "021", "023", "031", "061", "091" };
    }

    public void SaveFavorites(IEnumerable<ScriptItem> scripts)
    {
        try
        {
            var favs = scripts.Where(s => s.IsFavorite).Select(s => s.Id).OrderBy(x => x).ToList();
            var json = JsonSerializer.Serialize(favs, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(FavoritesPath, json, Encoding.UTF8);
        }
        catch
        {
            // Ignore write errors
        }
    }

    public string ReadScriptSource(ScriptItem script)
    {
        if (File.Exists(script.FullPath))
        {
            return File.ReadAllText(script.FullPath, Encoding.UTF8);
        }
        return $"# Script file not found at: {script.FullPath}";
    }

    public void SaveScriptSource(ScriptItem script, string newContent)
    {
        if (!string.IsNullOrWhiteSpace(script.FullPath))
        {
            File.WriteAllText(script.FullPath, newContent, Encoding.UTF8);
        }
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
            // Fallback
        }
        return (0, 0, 0);
    }

    /// <summary>
    /// Statically validates a single script or all 100 scripts using PowerShell's AST Parser
    /// WITHOUT executing any optimization script.
    /// </summary>
    public async Task<(bool Success, string Output)> ValidateSingleScriptAstAsync(ScriptItem script)
    {
        if (!File.Exists(script.FullPath))
        {
            return (false, $"[FAIL] File not found: {script.FullPath}");
        }

        string escapedPath = script.FullPath.Replace("'", "''");
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
Write-Output ""[STATIC AST VERIFIED] #{script.Id} ({script.Name})""
Write-Output ""  File       : {escapedPath}""
Write-Output ""  Tokens     : $($tokens.Count) tokens parsed with 0 syntax errors""
Write-Output ""  Parameters : -$($params -join ', -')""
Write-Output ""  AST Nodes  : $($cmds.Count) command invocations verified""
Write-Output ""  Safety     : Non-execution static verification succeeded.""
";

        return await RunPwshCommandInternalAsync(psAstCommand);
    }

    public async Task<(bool Success, string Output)> ValidateAll100ScriptsAstAsync()
    {
        if (!File.Exists(ValidatorScriptPath))
        {
            return (false, $"Validator script missing at {ValidatorScriptPath}");
        }

        string args = $"-NoProfile -ExecutionPolicy Bypass -File \"{ValidatorScriptPath}\"";
        return await RunProcessCaptureAsync("pwsh", args);
    }

    public async Task<(bool Success, string Output)> ExecuteScriptAsync(
        ScriptItem script,
        bool dryRun,
        bool safetyLockEnabled,
        Action<string>? onLineReceived = null)
    {
        if (safetyLockEnabled)
        {
            var sb = new StringBuilder();
            sb.AppendLine($"======================================================================");
            sb.AppendLine($" [SAFETY LOCK ACTIVE] #{script.Id} - {script.Name}");
            sb.AppendLine($"======================================================================");
            sb.AppendLine($"Mode           : Static Non-Execution Inspection (Safety Lock is ON)");
            sb.AppendLine($"Script Path    : {script.FullPath}");
            sb.AppendLine($"Category       : {script.Category} / {script.Subcategory}");
            sb.AppendLine($"Impact         : {script.Impact} | Requires Admin: {script.RequiresAdmin} | Reversible: {script.Reversible}");
            sb.AppendLine($"Summary        : {script.Description}");
            sb.AppendLine();
            var astRes = await ValidateSingleScriptAstAsync(script);
            sb.AppendLine(astRes.Output.TrimEnd());
            sb.AppendLine();
            sb.AppendLine($"[TIP] Toggle 'Safety Lock: UNLOCKED' in the top bar if you want to execute this script live or with -DryRun.");
            var text = sb.ToString();
            onLineReceived?.Invoke(text);
            return (astRes.Success, text);
        }

        string dryFlag = dryRun ? " -DryRun" : string.Empty;
        string args = $"-NoProfile -ExecutionPolicy Bypass -File \"{script.FullPath}\"{dryFlag}";
        return await RunProcessCaptureAsync("pwsh", args, onLineReceived);
    }

    private static async Task<(bool Success, string Output)> RunPwshCommandInternalAsync(string command)
    {
        string bytesB64 = Convert.ToBase64String(Encoding.Unicode.GetBytes(command));
        string args = $"-NoProfile -NonInteractive -EncodedCommand {bytesB64}";
        return await RunProcessCaptureAsync("pwsh", args);
    }

    private static async Task<(bool Success, string Output)> RunProcessCaptureAsync(
        string fileName,
        string arguments,
        Action<string>? onLineReceived = null)
    {
        var sb = new StringBuilder();
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = fileName,
                Arguments = arguments,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
                StandardOutputEncoding = Encoding.UTF8,
                StandardErrorEncoding = Encoding.UTF8
            };

            using var proc = new Process { StartInfo = psi };
            proc.OutputDataReceived += (_, e) =>
            {
                if (e.Data != null)
                {
                    sb.AppendLine(e.Data);
                    onLineReceived?.Invoke(e.Data);
                }
            };
            proc.ErrorDataReceived += (_, e) =>
            {
                if (e.Data != null)
                {
                    string errLine = $"[STDERR] {e.Data}";
                    sb.AppendLine(errLine);
                    onLineReceived?.Invoke(errLine);
                }
            };

            proc.Start();
            proc.BeginOutputReadLine();
            proc.BeginErrorReadLine();
            await proc.WaitForExitAsync();

            return (proc.ExitCode == 0, sb.ToString());
        }
        catch (Exception ex)
        {
            string msg = $"[ERROR] Failed to invoke {fileName}: {ex.Message}";
            sb.AppendLine(msg);
            onLineReceived?.Invoke(msg);
            return (false, sb.ToString());
        }
    }
}
