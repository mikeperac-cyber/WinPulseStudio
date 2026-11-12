using System.Windows;
using System.Windows.Controls;
using WinPulseStudio.Models;
using WinPulseStudio.Services;

namespace WinPulseStudio.Views;

public sealed class HomeGoalVm
{
    public string Title { get; init; } = string.Empty;
    public string Subtitle { get; init; } = string.Empty;
    public string Icon { get; init; } = "✨";
    public string Meta { get; init; } = string.Empty;
    public GoalContext Goal { get; init; } = new();
}

public sealed class HomeCollectionVm
{
    public string Title { get; init; } = string.Empty;
    public string Subtitle { get; init; } = string.Empty;
    public string Meta { get; init; } = string.Empty;
    public GoalContext Goal { get; init; } = new();
}

public partial class HomeView : UserControl
{
    private static readonly Dictionary<string, (string Title, string Subtitle, string Icon)> PresetCopy = new(StringComparer.OrdinalIgnoreCase)
    {
        ["preset-ai-inference"] = (
            "Run local AI models faster",
            "Free standby memory and tune your GPU, Ollama and WSL2 for token generation.",
            "🧠"),
        ["preset-dev-compile"] = (
            "Speed up builds and coding",
            "Defender exclusions, NTFS tuning and Git performance for faster compiles.",
            "🚀"),
        ["preset-daily-focus"] = (
            "Set up a distraction-free workspace",
            "Silence notifications, speed up Explorer and enable clipboard history.",
            "🎯"),
        ["preset-battery-travel"] = (
            "Make my battery last longer",
            "Power-saving profile, CPU boost limits and less background sync.",
            "🔋"),
        ["preset-clean-privacy"] = (
            "Clean up space and improve privacy",
            "A restore point first, then cache cleanup, telemetry and activity history.",
            "🧹")
    };

    private static readonly string[] DiagnosticsScriptIds = ["093", "094", "095", "099", "017", "085"];

    private readonly SessionContext _session;
    private readonly INavigator _navigator;
    private readonly Dictionary<string, ScriptItem> _scriptsById;

    public HomeView(SessionContext session, INavigator navigator)
    {
        InitializeComponent();
        _session = session;
        _navigator = navigator;
        _scriptsById = session.Scripts.ToDictionary(s => s.Id, StringComparer.OrdinalIgnoreCase);

        LstGoals.ItemsSource = BuildGoals();
        var collections = BuildCollections();
        LstCollections.ItemsSource = collections;
        TxtEmptyCollections.Visibility = collections.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
    }

    private List<HomeGoalVm> BuildGoals()
    {
        var goals = new List<HomeGoalVm>();

        foreach (var preset in _session.Manifest.Presets)
        {
            var scripts = ResolveScripts(preset.ScriptIds);
            if (scripts.Count == 0)
            {
                continue;
            }

            var copy = PresetCopy.TryGetValue(preset.Id, out var mapped)
                ? mapped
                : (preset.Name, preset.Description, "✨");

            goals.Add(new HomeGoalVm
            {
                Title = copy.Item1,
                Subtitle = copy.Item2,
                Icon = copy.Item3,
                Meta = BuildMeta(scripts),
                Goal = new GoalContext
                {
                    Title = copy.Item1,
                    Subtitle = copy.Item2,
                    ContextName = preset.Name,
                    Kind = GoalKind.Preset,
                    Scripts = scripts
                }
            });
        }

        var diagnostics = ResolveScripts(DiagnosticsScriptIds);
        if (diagnostics.Count > 0)
        {
            goals.Add(new HomeGoalVm
            {
                Title = "Something feels wrong — check my PC",
                Subtitle = "Read-only health checks: crashes, disk health, RAM, drivers, battery and security.",
                Icon = "🩺",
                Meta = BuildMeta(diagnostics, readOnly: diagnostics.All(s => s.SafeReadOnly)),
                Goal = new GoalContext
                {
                    Title = "Something feels wrong — check my PC",
                    Subtitle = "These checks only read your system. Nothing is changed.",
                    ContextName = "PC health check",
                    Kind = GoalKind.Diagnostics,
                    Scripts = diagnostics
                }
            });
        }

        return goals;
    }

    private List<HomeCollectionVm> BuildCollections()
    {
        var items = new List<HomeCollectionVm>();
        foreach (var collection in _session.Collections.GetAll())
        {
            var scripts = ResolveScripts(collection.ScriptIds);
            if (scripts.Count == 0)
            {
                continue;
            }

            items.Add(new HomeCollectionVm
            {
                Title = collection.Name,
                Subtitle = string.IsNullOrWhiteSpace(collection.Description) ? "Saved collection" : collection.Description,
                Meta = $"{scripts.Count} steps • saved {collection.CreatedAt:MMM d}",
                Goal = new GoalContext
                {
                    Title = collection.Name,
                    Subtitle = collection.Description,
                    ContextName = collection.Name,
                    Kind = GoalKind.Collection,
                    Scripts = scripts
                }
            });
        }
        return items;
    }

    private List<ScriptItem> ResolveScripts(IEnumerable<string> ids)
    {
        var result = new List<ScriptItem>();
        foreach (var id in ids)
        {
            if (_scriptsById.TryGetValue(id, out var script) && result.All(s => s.Id != script.Id))
            {
                result.Add(script);
            }
        }
        return result;
    }

    private static string BuildMeta(List<ScriptItem> scripts, bool readOnly = false)
    {
        int seconds = scripts.Sum(s => s.EstimatedSeconds);
        int admin = scripts.Count(s => s.RequiresAdmin);
        string mode = readOnly || scripts.All(s => s.SafeReadOnly) ? "read-only" : $"{admin} need admin";
        return $"{scripts.Count} steps • ~{seconds}s • {mode}";
    }

    private void GoalCard_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: HomeGoalVm vm })
        {
            _navigator.ShowGuide(vm.Goal);
        }
    }

    private void CollectionCard_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: HomeCollectionVm vm })
        {
            _navigator.ShowGuide(vm.Goal);
        }
    }
}
