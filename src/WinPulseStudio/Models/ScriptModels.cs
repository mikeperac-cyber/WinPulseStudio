using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Text.Json.Serialization;

namespace WinPulseStudio.Models;

public sealed class ManifestRoot
{
    [JsonPropertyName("appTitle")]
    public string AppTitle { get; set; } = "Microsoft WinPulse Control Studio";

    [JsonPropertyName("version")]
    public string Version { get; set; } = "1.0.0";

    [JsonPropertyName("totalScripts")]
    public int TotalScripts { get; set; }

    [JsonPropertyName("presets")]
    public List<PresetProfile> Presets { get; set; } = [];

    [JsonPropertyName("scripts")]
    public List<ScriptItem> Scripts { get; set; } = [];
}

public sealed class PresetProfile
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("icon")]
    public string Icon { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("scriptIds")]
    public List<string> ScriptIds { get; set; } = [];

    [JsonIgnore]
    public string CountLabel => $"{ScriptIds.Count} scripts";
}

public sealed class CategoryFilterItem
{
    public string CategoryId { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string IconGlyph { get; init; } = "•";
    public int Count { get; init; }
    public string DisplayLabel => $"{IconGlyph}  {Name}";
}

public sealed class ScriptItem : INotifyPropertyChanged
{
    private bool _isFavorite;
    private string _statusText = "AST Verified ✓";

    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("slug")]
    public string Slug { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("category")]
    public string Category { get; set; } = string.Empty;

    [JsonPropertyName("categoryId")]
    public string CategoryId { get; set; } = string.Empty;

    [JsonPropertyName("subcategory")]
    public string Subcategory { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("impact")]
    public string Impact { get; set; } = "Medium";

    [JsonPropertyName("requiresAdmin")]
    public bool RequiresAdmin { get; set; }

    [JsonPropertyName("reversible")]
    public bool Reversible { get; set; }

    [JsonPropertyName("safeReadOnly")]
    public bool SafeReadOnly { get; set; }

    [JsonPropertyName("tags")]
    public List<string> Tags { get; set; } = [];

    [JsonPropertyName("estimatedSeconds")]
    public int EstimatedSeconds { get; set; } = 2;

    [JsonPropertyName("relativePath")]
    public string RelativePath { get; set; } = string.Empty;

    [JsonIgnore]
    public string FullPath { get; set; } = string.Empty;

    [JsonIgnore]
    public string DisplayId => $"#{Id}";

    [JsonIgnore]
    public string CategorySubLabel => $"{Category}  •  {Subcategory}";

    [JsonIgnore]
    public string AdminBadgeText => RequiresAdmin ? "⚡ Admin" : "👤 User";

    [JsonIgnore]
    public string ModeBadgeText => SafeReadOnly ? "🟢 Read-Only Audit" : (Reversible ? "↺ Reversible" : "⚠ One-Way");

    [JsonIgnore]
    public string ImpactBadgeText => $"{Impact} Impact";

    [JsonIgnore]
    public string TagsFormatted => string.Join("   ", Tags.Select(t => $"#{t}"));

    [JsonIgnore]
    public string StarGlyph => IsFavorite ? "★" : "☆";

    [JsonIgnore]
    public bool IsFavorite
    {
        get => _isFavorite;
        set
        {
            if (_isFavorite != value)
            {
                _isFavorite = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(StarGlyph));
            }
        }
    }

    [JsonIgnore]
    public string StatusText
    {
        get => _statusText;
        set
        {
            if (_statusText != value)
            {
                _statusText = value;
                OnPropertyChanged();
            }
        }
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}
