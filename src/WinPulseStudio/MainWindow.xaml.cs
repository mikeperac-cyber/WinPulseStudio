using System.Diagnostics;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Threading;
using WinPulseStudio.Models;
using WinPulseStudio.Services;

namespace WinPulseStudio;

public partial class MainWindow : Window
{
    private readonly WorkspaceService _workspace = new();
    private readonly DispatcherTimer _telemetryTimer = new();
    private ManifestRoot _manifest = new();
    private List<ScriptItem> _allScripts = [];
    private ScriptItem? _selectedScript;
    private string _activeCategoryId = "ALL";
    private PresetProfile? _activePreset;
    private bool _safetyLockEnabled = true;
    private bool _suppressSelectionEvents;

    public MainWindow()
    {
        InitializeComponent();
        Loaded += MainWindow_Loaded;
    }

    private void MainWindow_Loaded(object sender, RoutedEventArgs e)
    {
        TxtWorkspacePath.Text = $"Workspace: {_workspace.WorkspaceRoot}";
        UpdateTelemetryHeader();

        _telemetryTimer.Interval = TimeSpan.FromSeconds(3);
        _telemetryTimer.Tick += (_, _) => UpdateTelemetryHeader();
        _telemetryTimer.Start();

        LoadCatalog();
        AppendConsole("=========================================================================");
        AppendConsole(" Microsoft WinPulse Control Studio v1.1 Initialized");
        AppendConsole($" Loaded {_allScripts.Count} built-in PowerShell scripts across 10 categories.");
        AppendConsole(" Safety Lock is ON (No-Run Mode): scripts are inspected & AST-verified");
        AppendConsole(" without executing system changes unless you unlock Safety Lock.");
        AppendConsole("=========================================================================");
    }

    private void UpdateTelemetryHeader()
    {
        TxtHostCpu.Text = $"{Environment.MachineName} • {Environment.ProcessorCount} Logical Cores";
        var (usedGb, totalGb, loadPct) = WorkspaceService.GetMemoryTelemetry();
        TxtRamUsage.Text = $"{usedGb:0.0} / {totalGb:0.0} GB ({loadPct}%)";

        bool isAdmin = WorkspaceService.IsRunningAsAdministrator();
        TxtAdminStatus.Text = isAdmin ? "⚡ Administrator" : "👤 Standard User";
        TxtAdminStatus.Foreground = new SolidColorBrush(isAdmin
            ? Color.FromRgb(16, 185, 129)
            : Color.FromRgb(251, 191, 36));
    }

    private void LoadCatalog()
    {
        _manifest = _workspace.LoadManifest();
        _allScripts = _manifest.Scripts;

        BuildCategoryList();
        LstPresets.ItemsSource = _manifest.Presets;

        ApplyFilters();
        if (LstScripts.Items.Count > 0)
        {
            LstScripts.SelectedIndex = 0;
        }
    }

    private void BuildCategoryList()
    {
        var icons = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["01-speed-performance"] = "🚀",
            ["02-power-thermal"] = "🔋",
            ["03-ai-workstation"] = "🧠",
            ["04-dev-toolchains"] = "🛠",
            ["05-containers-cloud"] = "🐳",
            ["06-network-latency"] = "🌐",
            ["07-daily-productivity"] = "🎯",
            ["08-storage-cleanup"] = "🧹",
            ["09-privacy-security"] = "🛡",
            ["10-diagnostics-recovery"] = "🩺"
        };

        var categories = new List<CategoryFilterItem>
        {
            new()
            {
                CategoryId = "ALL",
                Name = "All Built-In Scripts",
                IconGlyph = "📦",
                Count = _allScripts.Count
            },
            new()
            {
                CategoryId = "FAVORITES",
                Name = "Pinned Favorites",
                IconGlyph = "★",
                Count = _allScripts.Count(s => s.IsFavorite)
            }
        };

        var grouped = _allScripts
            .GroupBy(s => new { s.CategoryId, s.Category })
            .OrderBy(g => g.Key.CategoryId);

        foreach (var g in grouped)
        {
            string icon = icons.TryGetValue(g.Key.CategoryId, out var glyph) ? glyph : "•";
            categories.Add(new CategoryFilterItem
            {
                CategoryId = g.Key.CategoryId,
                Name = g.Key.Category,
                IconGlyph = icon,
                Count = g.Count()
            });
        }

        _suppressSelectionEvents = true;
        LstCategories.ItemsSource = categories;
        var selectedCat = categories.FirstOrDefault(c => c.CategoryId == _activeCategoryId) ?? categories[0];
        LstCategories.SelectedItem = selectedCat;
        _suppressSelectionEvents = false;
    }

    private void ApplyFilters()
    {
        if (_allScripts.Count == 0)
        {
            return;
        }

        IEnumerable<ScriptItem> query = _allScripts;

        if (_activePreset != null)
        {
            var presetSet = new HashSet<string>(_activePreset.ScriptIds, StringComparer.OrdinalIgnoreCase);
            query = query.Where(s => presetSet.Contains(s.Id));
        }
        else if (_activeCategoryId == "FAVORITES")
        {
            query = query.Where(s => s.IsFavorite);
        }
        else if (_activeCategoryId != "ALL")
        {
            query = query.Where(s => string.Equals(s.CategoryId, _activeCategoryId, StringComparison.OrdinalIgnoreCase));
        }

        if (ChkHighImpact.IsChecked == true)
        {
            query = query.Where(s => string.Equals(s.Impact, "High", StringComparison.OrdinalIgnoreCase));
        }

        if (ChkNoAdmin.IsChecked == true)
        {
            query = query.Where(s => !s.RequiresAdmin);
        }

        if (ChkSafeReadOnly.IsChecked == true)
        {
            query = query.Where(s => s.SafeReadOnly);
        }

        if (ChkReversible.IsChecked == true)
        {
            query = query.Where(s => s.Reversible);
        }

        string search = TxtSearch.Text.Trim();
        if (!string.IsNullOrEmpty(search))
        {
            query = query.Where(s =>
                s.Id.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                s.DisplayId.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                s.Name.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                s.Category.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                s.Subcategory.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                s.Description.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                s.Slug.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                s.Tags.Any(t => t.Contains(search, StringComparison.OrdinalIgnoreCase)));
        }

        var filtered = query.ToList();
        LstScripts.ItemsSource = filtered;

        string filterContext = _activePreset != null
            ? $"Preset '{_activePreset.Name}': {filtered.Count} scripts"
            : $"Showing {filtered.Count} of {_allScripts.Count} scripts";
        TxtResultCount.Text = filterContext;

        if (filtered.Count > 0 && (_selectedScript == null || !filtered.Contains(_selectedScript)))
        {
            LstScripts.SelectedIndex = 0;
        }
    }

    private void LstCategories_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_suppressSelectionEvents)
        {
            return;
        }

        if (LstCategories.SelectedItem is CategoryFilterItem cat)
        {
            _suppressSelectionEvents = true;
            LstPresets.SelectedItem = null;
            _activePreset = null;
            _suppressSelectionEvents = false;

            _activeCategoryId = cat.CategoryId;
            ApplyFilters();
        }
    }

    private void LstPresets_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_suppressSelectionEvents)
        {
            return;
        }

        if (LstPresets.SelectedItem is PresetProfile preset)
        {
            _suppressSelectionEvents = true;
            LstCategories.SelectedItem = null;
            _suppressSelectionEvents = false;

            _activePreset = preset;
            ApplyFilters();
            AppendConsole($"[PRESET SELECTED] {preset.Name} ({preset.ScriptIds.Count} scripts: #{string.Join(", #", preset.ScriptIds)})");
        }
    }

    private async void BtnBatchPreset_Click(object sender, RoutedEventArgs e)
    {
        var preset = _activePreset ?? _manifest.Presets.FirstOrDefault();
        if (preset == null)
        {
            return;
        }

        if (_activePreset == null)
        {
            LstPresets.SelectedItem = preset;
        }

        BtnBatchPreset.IsEnabled = false;
        var targetScripts = _allScripts.Where(s => preset.ScriptIds.Contains(s.Id, StringComparer.OrdinalIgnoreCase)).ToList();
        AppendConsole($"\n======================================================================");
        AppendConsole($" [BATCH PRESET] {preset.Name} ({targetScripts.Count} scripts)");
        AppendConsole($"======================================================================");

        int okCount = 0;
        foreach (var script in targetScripts)
        {
            TxtFooterStatus.Text = $"Batch processing {script.DisplayId} ({script.Name})...";
            var (success, output) = await _workspace.ExecuteScriptAsync(
                script,
                dryRun: true,
                safetyLockEnabled: _safetyLockEnabled);

            AppendConsole(output.TrimEnd());
            if (success)
            {
                okCount++;
            }
            script.StatusText = _safetyLockEnabled ? "Preset Verified ✓" : "Simulated ✓";
        }

        TxtFooterStatus.Text = $"Preset '{preset.Name}' complete: {okCount}/{targetScripts.Count} scripts verified.";
        BtnBatchPreset.IsEnabled = true;
    }

    private void TxtSearch_TextChanged(object sender, TextChangedEventArgs e)
    {
        ApplyFilters();
    }

    private void FilterCheckbox_Changed(object sender, RoutedEventArgs e)
    {
        ApplyFilters();
    }

    private void BtnResetFilters_Click(object sender, RoutedEventArgs e)
    {
        _suppressSelectionEvents = true;
        TxtSearch.Text = string.Empty;
        ChkHighImpact.IsChecked = false;
        ChkNoAdmin.IsChecked = false;
        ChkSafeReadOnly.IsChecked = false;
        ChkReversible.IsChecked = false;
        _activePreset = null;
        _activeCategoryId = "ALL";
        LstPresets.SelectedItem = null;
        if (LstCategories.Items.Count > 0)
        {
            LstCategories.SelectedIndex = 0;
        }
        _suppressSelectionEvents = false;

        ApplyFilters();
    }

    private void LstScripts_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (LstScripts.SelectedItem is ScriptItem script)
        {
            _selectedScript = script;
            TxtSelectedId.Text = script.DisplayId;
            TxtSelectedTitle.Text = script.Name;
            TxtSelectedMeta.Text = $"{script.Category} • {script.Subcategory} • {script.Impact} Impact • {(script.RequiresAdmin ? "Requires Admin" : "Standard User")} • ~{script.EstimatedSeconds}s";
            TxtSelectedDesc.Text = script.Description;
            TxtScriptPathShort.Text = script.RelativePath;
            TxtCodeEditor.Text = _workspace.ReadScriptSource(script);
        }
    }

    private void BtnToggleFavorite_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: ScriptItem script })
        {
            script.IsFavorite = !script.IsFavorite;
            _workspace.SaveFavorites(_allScripts);
            BuildCategoryList();
            if (_activeCategoryId == "FAVORITES")
            {
                ApplyFilters();
            }
        }
    }

    private void BtnSafetyLock_Click(object sender, RoutedEventArgs e)
    {
        _safetyLockEnabled = !_safetyLockEnabled;
        if (_safetyLockEnabled)
        {
            TxtSafetyLockLabel.Text = "🔒 Safety Lock: ON (No-Run Mode)";
            TxtSafetyLockLabel.Foreground = new SolidColorBrush(Color.FromRgb(110, 231, 183));
            BtnSafetyLock.Background = new SolidColorBrush(Color.FromRgb(6, 78, 59));
            BtnSafetyLock.BorderBrush = new SolidColorBrush(Color.FromRgb(16, 185, 129));
            AppendConsole("[SAFETY LOCK ENABLED] Scripts will only be statically AST-verified and never executed.");
        }
        else
        {
            TxtSafetyLockLabel.Text = "🔓 Safety Lock: UNLOCKED (Live/DryRun Enabled)";
            TxtSafetyLockLabel.Foreground = new SolidColorBrush(Color.FromRgb(253, 224, 71));
            BtnSafetyLock.Background = new SolidColorBrush(Color.FromRgb(120, 53, 15));
            BtnSafetyLock.BorderBrush = new SolidColorBrush(Color.FromRgb(245, 158, 11));
            AppendConsole("[SAFETY LOCK UNLOCKED] You can now run scripts in -DryRun simulation mode or live execution mode.");
        }
    }

    private async void BtnVerifyAll_Click(object sender, RoutedEventArgs e)
    {
        BtnVerifyAll.IsEnabled = false;
        TxtFooterStatus.Text = "Running deep PowerShell AST & Cmdlet static verification across all 100 scripts...";
        AppendConsole("\n>>> Running Deep Static AST & Cmdlet Verifier across all 100 scripts (Zero Execution)...");

        var (success, output) = await _workspace.ValidateAll100ScriptsAstAsync();
        AppendConsole(output.TrimEnd());

        foreach (var s in _allScripts)
        {
            s.StatusText = success ? "AST Verified ✓" : "Check AST";
        }

        TxtFooterStatus.Text = success
            ? "Verified: All 100 PowerShell scripts passed static AST syntax & cmdlet checks!"
            : "AST verification reported issues. Check the integrated console.";
        BtnVerifyAll.IsEnabled = true;
    }

    private async void BtnVerifySingle_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedScript == null)
        {
            return;
        }

        BtnVerifySingle.IsEnabled = false;
        TxtFooterStatus.Text = $"Verifying AST for {_selectedScript.DisplayId} {_selectedScript.Name}...";
        var (success, output) = await _workspace.ValidateSingleScriptAstAsync(_selectedScript);
        AppendConsole(output.TrimEnd());
        _selectedScript.StatusText = success ? "AST Verified ✓" : "Syntax Error";
        TxtFooterStatus.Text = success
            ? $"{_selectedScript.DisplayId} passed static PowerShell AST verification."
            : $"{_selectedScript.DisplayId} failed AST verification.";
        BtnVerifySingle.IsEnabled = true;
    }

    private async void BtnDryRunSingle_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedScript == null)
        {
            return;
        }

        BtnDryRunSingle.IsEnabled = false;
        TxtFooterStatus.Text = $"Simulating {_selectedScript.DisplayId} ({_selectedScript.Name})...";
        AppendConsole($"\n>>> [{DateTime.Now:HH:mm:ss}] Simulating {_selectedScript.DisplayId} - {_selectedScript.Name} (-DryRun)");

        var (success, _) = await _workspace.ExecuteScriptAsync(
            _selectedScript,
            dryRun: true,
            safetyLockEnabled: _safetyLockEnabled,
            onLineReceived: line => Dispatcher.Invoke(() => AppendConsole(line)));

        _selectedScript.StatusText = _safetyLockEnabled ? "Inspect OK ✓" : (success ? "Dry-Run OK ✓" : "Exit != 0");
        TxtFooterStatus.Text = $"Completed simulation of {_selectedScript.DisplayId}.";
        BtnDryRunSingle.IsEnabled = true;
    }

    private async void BtnExecuteSingle_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedScript == null)
        {
            return;
        }

        BtnExecuteSingle.IsEnabled = false;
        TxtFooterStatus.Text = _safetyLockEnabled
            ? $"Inspecting {_selectedScript.DisplayId} (Safety Lock ON)..."
            : $"Executing {_selectedScript.DisplayId} ({_selectedScript.Name})...";

        var (success, _) = await _workspace.ExecuteScriptAsync(
            _selectedScript,
            dryRun: false,
            safetyLockEnabled: _safetyLockEnabled,
            onLineReceived: line => Dispatcher.Invoke(() => AppendConsole(line)));

        _selectedScript.StatusText = _safetyLockEnabled ? "Safety Locked 🔒" : (success ? "Executed ✓" : "Failed");
        TxtFooterStatus.Text = _safetyLockEnabled
            ? $"{_selectedScript.DisplayId} inspected safely (Safety Lock prevented execution)."
            : $"Finished executing {_selectedScript.DisplayId}.";
        BtnExecuteSingle.IsEnabled = true;
    }

    private void BtnCopyCode_Click(object sender, RoutedEventArgs e)
    {
        if (!string.IsNullOrEmpty(TxtCodeEditor.Text))
        {
            Clipboard.SetText(TxtCodeEditor.Text);
            TxtFooterStatus.Text = $"Copied PowerShell code for {_selectedScript?.DisplayId} to clipboard.";
        }
    }

    private void BtnSaveCode_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedScript == null)
        {
            return;
        }

        _workspace.SaveScriptSource(_selectedScript, TxtCodeEditor.Text);
        AppendConsole($"[SAVED] Updated script file: {_selectedScript.FullPath}");
        TxtFooterStatus.Text = $"Saved changes to {_selectedScript.RelativePath}.";
    }

    private void BtnRevealFile_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedScript != null && File.Exists(_selectedScript.FullPath))
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = "explorer.exe",
                Arguments = $"/select,\"{_selectedScript.FullPath}\"",
                UseShellExecute = true
            });
        }
    }

    private void BtnCopyConsole_Click(object sender, RoutedEventArgs e)
    {
        if (!string.IsNullOrEmpty(TxtConsole.Text))
        {
            Clipboard.SetText(TxtConsole.Text);
            TxtFooterStatus.Text = "Copied console output log to clipboard.";
        }
    }

    private void BtnClearConsole_Click(object sender, RoutedEventArgs e)
    {
        TxtConsole.Clear();
    }

    private void AppendConsole(string message)
    {
        if (string.IsNullOrEmpty(TxtConsole.Text))
        {
            TxtConsole.Text = message;
        }
        else
        {
            TxtConsole.AppendText(Environment.NewLine + message);
        }
        TxtConsole.ScrollToEnd();
    }
}
