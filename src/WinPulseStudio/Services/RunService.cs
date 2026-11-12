using WinPulseStudio.Models;

namespace WinPulseStudio.Services;

public sealed class RunService
{
    private readonly WorkspaceService _workspace;
    private readonly HistoryService _history;
    private readonly Func<bool> _safetyLockProvider;

    public event Action<RunRecord>? RecordAdded;

    public RunService(WorkspaceService workspace, HistoryService history, Func<bool>? safetyLockProvider = null)
    {
        _workspace = workspace;
        _history = history;
        _safetyLockProvider = safetyLockProvider ?? (() => true);
    }

    public async Task<RunOutcome> RunAsync(
        ScriptItem script,
        RunMode mode,
        string context,
        Action<string>? onLineReceived = null)
    {
        if (!_workspace.PowerShellAvailable)
        {
            return RecordBlocked(script, "PowerShell 7 (pwsh) was not found on PATH.", mode, context, onLineReceived);
        }

        if (mode == RunMode.Live && _safetyLockProvider())
        {
            return RecordBlocked(
                script,
                $"Safety Lock is ON. Unlock it in the top bar before applying #{script.Id}.",
                mode,
                context,
                onLineReceived);
        }

        RunOutcome outcome = mode switch
        {
            RunMode.Verify => await _workspace.ValidateSingleScriptAstAsync(script),
            RunMode.DryRun => await _workspace.ExecuteScriptAsync(script, dryRun: true, safetyLockEnabled: false, onLineReceived),
            _ => await _workspace.ExecuteScriptAsync(script, dryRun: false, safetyLockEnabled: _safetyLockProvider(), onLineReceived)
        };

        Record(script, outcome, context);
        return outcome;
    }

    public async Task<RunOutcome> VerifyAllAsync(string context, Action<string>? onLineReceived = null)
    {
        var outcome = await _workspace.ValidateAll100ScriptsAstAsync();
        var record = BuildRecord("*", "All 100 scripts (AST verification)", outcome, context);
        _history.Add(record);
        RecordAdded?.Invoke(record);
        return outcome;
    }

    public async Task<RunOutcome> RunRestorePointAsync(ScriptItem? restoreScript, Action<string>? onLineReceived = null)
    {
        if (restoreScript == null)
        {
            var missing = new RunOutcome(
                false,
                1,
                "[ERROR] Restore point script #091 was not found in the manifest.",
                TimeSpan.Zero,
                RunMode.Live);
            var missingRecord = BuildRecord("091", "Create System Restore Point", missing, "Restore point");
            _history.Add(missingRecord);
            RecordAdded?.Invoke(missingRecord);
            return missing;
        }

        return await RunAsync(restoreScript, RunMode.Live, "Restore point", onLineReceived);
    }

    public async Task<RunOutcome> RunRevertAsync(ScriptItem script, string switchName, Action<string>? onLineReceived = null)
    {
        if (!_workspace.PowerShellAvailable)
        {
            return RecordBlocked(
                script,
                "PowerShell 7 (pwsh) was not found on PATH.",
                RunMode.Live,
                $"Revert (-{switchName})",
                onLineReceived);
        }

        if (_safetyLockProvider())
        {
            return RecordBlocked(
                script,
                $"Safety Lock is ON. Unlock it in the top bar before reverting #{script.Id} -{switchName}.",
                RunMode.Live,
                $"Revert (-{switchName})",
                onLineReceived);
        }

        var outcome = await _workspace.ExecuteScriptWithSwitchAsync(script, switchName, safetyLockEnabled: false, onLineReceived);
        var record = BuildRecord(script.Id, script.Name, outcome, $"Revert (-{switchName})");
        _history.Add(record);
        RecordAdded?.Invoke(record);
        return outcome;
    }

    private RunOutcome RecordBlocked(
        ScriptItem script,
        string message,
        RunMode mode,
        string context,
        Action<string>? onLineReceived)
    {
        var outcome = new RunOutcome(false, -1, $"[ERROR] {message}", TimeSpan.Zero, mode);
        onLineReceived?.Invoke(outcome.Output);
        Record(script, outcome, context);
        return outcome;
    }

    private void Record(ScriptItem script, RunOutcome outcome, string context)
    {
        var record = BuildRecord(script.Id, script.Name, outcome, context);
        _history.Add(record);
        RecordAdded?.Invoke(record);
    }

    private static RunRecord BuildRecord(string id, string name, RunOutcome outcome, string context)
    {
        return new RunRecord
        {
            Timestamp = DateTime.Now,
            ScriptId = id,
            ScriptName = name,
            Mode = outcome.Mode.ToString(),
            Success = outcome.Success,
            ExitCode = outcome.ExitCode,
            DurationSeconds = Math.Round(outcome.Duration.TotalSeconds, 2),
            Context = context,
            OutputSnippet = BuildSnippet(outcome.Output)
        };
    }

    private static string BuildSnippet(string output)
    {
        if (string.IsNullOrWhiteSpace(output))
        {
            return string.Empty;
        }

        var lines = output.Replace("\r\n", "\n").Split('\n');
        var tail = lines.Length > 40 ? lines[^40..] : lines;
        string snippet = string.Join(Environment.NewLine, tail).Trim();
        return snippet.Length > 4000 ? snippet[^4000..] : snippet;
    }
}