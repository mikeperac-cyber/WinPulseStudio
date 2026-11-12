using System.Text.Json.Serialization;

namespace WinPulseStudio.Models;

public sealed class CommandReferenceRoot
{
    [JsonPropertyName("version")]
    public string Version { get; set; } = "1.2.0";

    [JsonPropertyName("totalCommands")]
    public int TotalCommands { get; set; }

    [JsonPropertyName("commands")]
    public List<CommandItem> Commands { get; set; } = [];
}

public sealed class CommandItem
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("shell")]
    public string Shell { get; set; } = string.Empty;

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("command")]
    public string Command { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("example")]
    public string Example { get; set; } = string.Empty;

    [JsonPropertyName("requiresAdmin")]
    public bool RequiresAdmin { get; set; }

    [JsonPropertyName("safety")]
    public string Safety { get; set; } = "Read-only";

    [JsonIgnore]
    public string ShellGlyph => Shell switch
    {
        "PowerShell" => "⚡",
        "winget" => "📦",
        "cmd" => "🖥",
        _ => "❯"
    };

    [JsonIgnore]
    public string AdminBadgeText => RequiresAdmin ? "⚡ Admin" : "👤 User";

    [JsonIgnore]
    public string ListSubtitle => $"{Shell} • {Safety}";

    [JsonIgnore]
    public string SearchText => $"{Id} {Shell} {Title} {Command} {Description} {Safety}";
}