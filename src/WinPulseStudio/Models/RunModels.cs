using System.Text.Json.Serialization;

namespace WinPulseStudio.Models;

public enum RunMode
{
    Verify,
    DryRun,
    Live
}

public readonly record struct RunOutcome(
    bool Success,
    int ExitCode,
    string Output,
    TimeSpan Duration,
    RunMode Mode);

public sealed class RunRecord
{
    [JsonPropertyName("timestamp")]
    public DateTime Timestamp { get; set; } = DateTime.Now;

    [JsonPropertyName("scriptId")]
    public string ScriptId { get; set; } = string.Empty;

    [JsonPropertyName("scriptName")]
    public string ScriptName { get; set; } = string.Empty;

    [JsonPropertyName("mode")]
    public string Mode { get; set; } = "Verify";

    [JsonPropertyName("success")]
    public bool Success { get; set; }

    [JsonPropertyName("exitCode")]
    public int ExitCode { get; set; }

    [JsonPropertyName("durationSeconds")]
    public double DurationSeconds { get; set; }

    [JsonPropertyName("context")]
    public string Context { get; set; } = string.Empty;

    [JsonPropertyName("outputSnippet")]
    public string OutputSnippet { get; set; } = string.Empty;

    [JsonIgnore]
    public string DisplayId => ScriptId == "*" ? "ALL" : $"#{ScriptId}";

    [JsonIgnore]
    public string TimestampText => Timestamp.ToString("yyyy-MM-dd HH:mm:ss");

    [JsonIgnore]
    public string ModeLabel => Mode switch
    {
        "Live" => "Applied",
        "DryRun" => "Preview",
        _ => "Verify"
    };

    [JsonIgnore]
    public string StatusLabel => Success ? "OK" : "Failed";

    [JsonIgnore]
    public string SummaryLine => $"{TimestampText}  •  {DisplayId}  •  {ModeLabel}  •  {StatusLabel}  •  {DurationSeconds:0.0}s";
}

public sealed class CustomCollection
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString("N");

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("scriptIds")]
    public List<string> ScriptIds { get; set; } = [];

    [JsonPropertyName("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    [JsonIgnore]
    public string CountLabel => $"{ScriptIds.Count} scripts";
}

public enum GoalKind
{
    Preset,
    Diagnostics,
    Collection
}

public sealed class GoalContext
{
    public string Title { get; init; } = string.Empty;
    public string Subtitle { get; init; } = string.Empty;
    public string ContextName { get; init; } = string.Empty;
    public GoalKind Kind { get; init; } = GoalKind.Preset;
    public List<ScriptItem> Scripts { get; init; } = [];

    public bool IsReadOnlyOnly => Scripts.Count > 0 && Scripts.All(s => s.SafeReadOnly);
    public bool CanApply => !IsReadOnlyOnly;
}
