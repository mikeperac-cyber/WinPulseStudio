using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;
using WinPulseStudio.Models;
using WinPulseStudio.Services;

namespace WinPulseStudio.Views;

public partial class AdvancedView : UserControl
{
    private readonly SessionContext _session;
    private readonly INavigator _navigator;
    private readonly WorkspaceService _workspace;
    private readonly ObservableCollection<RunRecord> _results = [];
    private List<ScriptItem> _allScripts = [];
    private List<ScriptItem> _filteredScripts = [];
    private ScriptItem? _selectedScript;
    private string _activeCategoryId = "ALL";
    private PresetProfile? _activePreset;
    private bool _suppressSelectionEvents;
    private bool _initialized;

    /// <summary>
    /// Debounces the search box so filtering runs once typing pauses instead of
    /// on every keystroke.
    /// </summary>
    private readonly DispatcherTimer _searchDebounce = new() { Interval = TimeSpan.FromMilliseconds(250) };

    public AdvancedView(SessionContext session, INavigator navigator)
    {
        InitializeComponent();
        _session = session;
        _navigator = navigator;
        _workspace = session.Workspace;
        _allScripts = session.Scripts;
        LstResults.ItemsSource = _results;
        _session.Runs.RecordAdded += OnRecordAdded;
        _searchDebounce.Tick += (_, _) =>
        {
            _searchDebounce.Stop();
            ApplyFilters();
        };
        Loaded += AdvancedView_Loaded;
    }

    private void OnRecordAdded(RunRecord record)
    {
        Dispatcher.Invoke(() => _results.Insert(0, record));
    }

    private void AdvancedView_Loaded(object sender, RoutedEventArgs e)
    {
        if (_initialized)
        {
            return;
        }
        _initialized = true;

        BuildCategoryList();
        LstPresets.ItemsSource = _session.Manifest.Presets;
        ApplyFilters();
        if (LstScripts.Items.Count > 0)
        {
            LstScripts.SelectedIndex = 0;
        }

        AppendConsole("=========================================================================");
        AppendConsole($" Advanced Mode • {_allScripts.Count} built-in PowerShell scripts across 10 categories.");
        AppendConsole($" Safety Lock is {(_session.SafetyLockEnabled ? "ON" : "OFF")}: live changes are blocked while ON; previews are always safe.");
        AppendConsole("=========================================================================");

        // Catalog integrity: surface manifest/disk mismatches immediately so the
        // user knows exactly how many of the 100 tools are actually available.
        int missingOnDisk = _allScripts.Count(s => !File.Exists(s.FullPath));
        if (missingOnDisk > 0)
        {
            AppendConsole($"[WARN] {missingOnDisk} of {_allScripts.Count} scripts listed in manifest.json are missing on disk — restore the scripts folder or re-publish the app.");
        }
        if (_session.Manifest.TotalScripts != _allScripts.Count)
        {
            AppendConsole($"[WARN] manifest.json totalScripts ({_session.Manifest.TotalScripts}) does not match the catalog count ({_allScripts.Count}).");
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
                s.PlainSummary.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                s.Slug.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                s.Tags.Any(t => t.Contains(search, StringComparison.OrdinalIgnoreCase)));
        }

        _filteredScripts = query.ToList();
        LstScripts.ItemsSource = _filteredScripts;

        string filterContext = _activePreset != null
            ? $"Preset '{_activePreset.Name}': {_filteredScripts.Count} scripts"
            : $"Showing {_filteredScripts.Count} of {_allScripts.Count} scripts";
        TxtResultCount.Text = filterContext;

        if (_filteredScripts.Count > 0 && (_selectedScript == null || !_filteredScripts.Contains(_selectedScript)))
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
        var preset = _activePreset ?? _session.Manifest.Presets.FirstOrDefault();
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
        AppendConsole($" [BATCH PREVIEW] {preset.Name} ({targetScripts.Count} scripts)");
        AppendConsole($"======================================================================");

        int okCount = 0;
        foreach (var script in targetScripts)
        {
            _session.SetStatus($"Previewing {script.DisplayId} ({script.Name})...");
            var outcome = await _session.Runs.RunAsync(
                script,
                RunMode.DryRun,
                preset.Name,
                line => Dispatcher.Invoke(() => AppendConsole(line)));

            if (!string.IsNullOrWhiteSpace(outcome.Output))
            {
                AppendConsole(outcome.Output.TrimEnd());
            }
            if (outcome.Success)
            {
                okCount++;
            }
            script.StatusText = outcome.Success ? "Preview OK ✓" : $"Preview failed ({outcome.ExitCode})";
        }

        _session.SetStatus($"Preset '{preset.Name}' preview complete: {okCount}/{targetScripts.Count} scripts simulated.");
        BtnBatchPreset.IsEnabled = true;
    }

    private void TxtSearch_TextChanged(object sender, TextChangedEventArgs e)
    {
        // Restart the debounce window; filtering fires ~250ms after typing pauses.
        _searchDebounce.Stop();
        _searchDebounce.Start();
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

    private void BtnSaveCollection_Click(object sender, RoutedEventArgs e)
    {
        if (_filteredScripts.Count == 0)
        {
            MessageBox.Show(Window.GetWindow(this), "There are no scripts in the current view to save.", "Nothing to save", MessageBoxButton.OK, MessageBoxImage.Information);
            return;
        }

        var dialog = new TextPromptWindow(
            "Save as collection",
            $"Name this collection of {_filteredScripts.Count} script(s). It will appear on the Home screen.",
            $"My collection ({_filteredScripts.Count} scripts)")
        {
            Owner = Window.GetWindow(this)
        };

        if (dialog.ShowDialog() != true || string.IsNullOrWhiteSpace(dialog.ResponseText))
        {
            return;
        }

        var collection = _session.Collections.Add(
            dialog.ResponseText,
            $"Created from Advanced Mode — {_filteredScripts.Count} scripts",
            _filteredScripts.Select(s => s.Id));
        _session.SetStatus($"Saved collection '{collection.Name}' ({collection.CountLabel}). Find it on the Home screen.");
    }

    private void LstScripts_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (LstScripts.SelectedItem is not ScriptItem script)
        {
            return;
        }

        _selectedScript = script;
        TxtSelectedId.Text = script.DisplayId;
        TxtSelectedTitle.Text = script.Name;
        TxtSelectedMeta.Text = $"{script.Category} • {script.Subcategory} • {script.Impact} Impact • {(script.RequiresAdmin ? "Requires Admin" : "Standard User")} • ~{script.EstimatedSeconds}s";
        TxtSelectedDesc.Text = script.SummaryText;
        TxtScriptPathShort.Text = script.RelativePath;
        TxtCodeEditor.Text = _workspace.ReadScriptSource(script);

        LstChanges.ItemsSource = script.WhatChanges;
        TxtHowToRevert.Text = script.HowToRevert;
        TxtPrereq.Text = script.PrerequisitesText;

        ExpWhatChanges.Visibility = script.HasWhatChanges ? Visibility.Visible : Visibility.Collapsed;
        ExpHowToRevert.Visibility = script.HasHowToRevert ? Visibility.Visible : Visibility.Collapsed;
        ExpPrereq.Visibility = script.HasPrerequisites ? Visibility.Visible : Visibility.Collapsed;
        ExpWhatChanges.IsExpanded = false;
        ExpHowToRevert.IsExpanded = false;
        ExpPrereq.IsExpanded = false;

        var revertSwitch = RevertCatalog.GetRevertSwitch(script.Id);
        BtnRevertScript.Visibility = revertSwitch != null ? Visibility.Visible : Visibility.Collapsed;
        BtnRevertScript.ToolTip = revertSwitch != null
            ? $"Undo this change by running the script with -{revertSwitch}. Requires Safety Lock off."
            : string.Empty;
    }

    private void BtnToggleFavorite_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: ScriptItem script })
        {
            script.IsFavorite = !script.IsFavorite;
            if (!_workspace.SaveFavorites(_allScripts))
            {
                _session.SetStatus($"Could not save favorites to {_workspace.FavoritesPath}.");
            }
            BuildCategoryList();
            if (_activeCategoryId == "FAVORITES")
            {
                ApplyFilters();
            }
        }
    }

    private async void BtnVerifyAll_Click(object sender, RoutedEventArgs e)
    {
        BtnVerifyAll.IsEnabled = false;
        _session.SetStatus("Running deep PowerShell AST & Cmdlet static verification across all 100 scripts...");
        AppendConsole("\n>>> Running Deep Static AST & Cmdlet Verifier across all 100 scripts (Zero Execution)...");

        var outcome = await _session.Runs.VerifyAllAsync("Advanced Mode");
        AppendConsole(outcome.Output.TrimEnd());

        foreach (var s in _allScripts)
        {
            s.StatusText = outcome.Success ? "AST Verified ✓" : "Check AST";
        }

        _session.SetStatus(outcome.Success
            ? "Verified: All 100 PowerShell scripts passed static AST syntax & cmdlet checks!"
            : "AST verification reported issues. Check the Results or Raw Log tab.");
        BtnVerifyAll.IsEnabled = true;
    }

    private async void BtnVerifySingle_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedScript == null)
        {
            return;
        }

        BtnVerifySingle.IsEnabled = false;
        _session.SetStatus($"Verifying AST for {_selectedScript.DisplayId} {_selectedScript.Name}...");
        var outcome = await _session.Runs.RunAsync(_selectedScript, RunMode.Verify, "Advanced Mode");
        AppendConsole(outcome.Output.TrimEnd());
        _selectedScript.StatusText = outcome.Success ? "AST Verified ✓" : "Syntax Error";
        _session.SetStatus(outcome.Success
            ? $"{_selectedScript.DisplayId} passed static PowerShell AST verification."
            : $"{_selectedScript.DisplayId} failed AST verification.");
        BtnVerifySingle.IsEnabled = true;
    }

    private async void BtnDryRunSingle_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedScript == null)
        {
            return;
        }

        BtnDryRunSingle.IsEnabled = false;
        _session.SetStatus($"Previewing {_selectedScript.DisplayId} ({_selectedScript.Name})...");
        AppendConsole($"\n>>> [{DateTime.Now:HH:mm:ss}] Previewing {_selectedScript.DisplayId} - {_selectedScript.Name} (-DryRun)");

        var outcome = await _session.Runs.RunAsync(
            _selectedScript,
            RunMode.DryRun,
            "Advanced Mode",
            line => Dispatcher.Invoke(() => AppendConsole(line)));

        if (!string.IsNullOrWhiteSpace(outcome.Output))
        {
            AppendConsole(outcome.Output.TrimEnd());
        }
        _selectedScript.StatusText = outcome.Success ? "Preview OK ✓" : $"Preview failed ({outcome.ExitCode})";
        _session.SetStatus($"Completed preview of {_selectedScript.DisplayId}.");
        BtnDryRunSingle.IsEnabled = true;
    }

    private async void BtnExecuteSingle_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedScript == null)
        {
            return;
        }

        if (_session.SafetyLockEnabled)
        {
            BtnExecuteSingle.IsEnabled = false;
            _session.SetStatus($"Safety Lock is ON — inspecting {_selectedScript.DisplayId} instead of applying it.");
            var inspection = await _session.Runs.RunAsync(_selectedScript, RunMode.Verify, "Advanced Mode");
            AppendConsole(inspection.Output.TrimEnd());
            _selectedScript.StatusText = "Safety Locked 🔒";
            _session.SetStatus($"{_selectedScript.DisplayId} inspected safely. Turn Safety Lock off to apply changes.");
            BtnExecuteSingle.IsEnabled = true;
            return;
        }

        var confirm = MessageBox.Show(
            Window.GetWindow(this),
            BuildLiveConfirmation(_selectedScript),
            "Apply live change",
            MessageBoxButton.YesNo,
            MessageBoxImage.Warning,
            MessageBoxResult.No);
        if (confirm != MessageBoxResult.Yes)
        {
            _session.SetStatus($"Apply cancelled for {_selectedScript.DisplayId}.");
            return;
        }

        BtnExecuteSingle.IsEnabled = false;
        _session.SetStatus($"Applying {_selectedScript.DisplayId} ({_selectedScript.Name})...");
        var outcome = await _session.Runs.RunAsync(
            _selectedScript,
            RunMode.Live,
            "Advanced Mode",
            line => Dispatcher.Invoke(() => AppendConsole(line)));

        if (!string.IsNullOrWhiteSpace(outcome.Output))
        {
            AppendConsole(outcome.Output.TrimEnd());
        }
        _selectedScript.StatusText = outcome.Success ? "Applied ✓" : $"Failed ({outcome.ExitCode})";
        _session.SetStatus(outcome.Success
            ? $"Finished applying {_selectedScript.DisplayId}."
            : $"{_selectedScript.DisplayId} failed with exit code {outcome.ExitCode}. See Results for details.");
        BtnExecuteSingle.IsEnabled = true;
    }

    private string BuildLiveConfirmation(ScriptItem script)
    {
        var sb = new StringBuilder();
        sb.AppendLine($"Apply #{script.Id} {script.Name} for real?");
        sb.AppendLine();
        sb.AppendLine($"Category: {script.Category} / {script.Subcategory}");
        sb.AppendLine($"Impact: {script.Impact} | Requires Admin: {script.RequiresAdmin} | Reversible: {script.Reversible}");
        sb.AppendLine();
        sb.AppendLine("What will change:");
        foreach (var change in script.WhatChanges.Take(3))
        {
            sb.AppendLine($"  - {change}");
        }

        if (!script.RequiresAdmin && script.Impact.Equals("High", StringComparison.OrdinalIgnoreCase))
        {
            sb.AppendLine();
            sb.AppendLine("High-impact change without an admin flag. Review the script before continuing.");
        }

        if (!_session.IsAdministrator && script.RequiresAdmin)
        {
            sb.AppendLine();
            sb.AppendLine("This session is not elevated. The script may fail or make only part of the change.");
        }

        sb.AppendLine();
        sb.AppendLine("The Safety Lock is already off for this session. Continue?");
        return sb.ToString();
    }

    private async void BtnRevertScript_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedScript == null)
        {
            return;
        }

        var revertSwitch = RevertCatalog.GetRevertSwitch(_selectedScript.Id);
        if (revertSwitch == null)
        {
            return;
        }

        if (_session.SafetyLockEnabled)
        {
            MessageBox.Show(
                Window.GetWindow(this),
                "Reverting applies a live change, so the Safety Lock must be off.\n\nTurn off Safety Lock in the top bar, then try again.",
                "Safety Lock is ON",
                MessageBoxButton.OK,
                MessageBoxImage.Information);
            return;
        }

        var confirm = MessageBox.Show(
            Window.GetWindow(this),
            $"Undo #{_selectedScript.Id} {_selectedScript.Name}?\n\nThis runs the script with -{revertSwitch} and reverses the change it made.",
            "Revert change",
            MessageBoxButton.YesNo,
            MessageBoxImage.Question,
            MessageBoxResult.No);

        if (confirm != MessageBoxResult.Yes)
        {
            return;
        }

        BtnRevertScript.IsEnabled = false;
        _session.SetStatus($"Reverting {_selectedScript.DisplayId} (-{revertSwitch})...");
        var outcome = await _session.Runs.RunRevertAsync(
            _selectedScript,
            revertSwitch,
            line => Dispatcher.Invoke(() => AppendConsole(line)));

        if (!string.IsNullOrWhiteSpace(outcome.Output))
        {
            AppendConsole(outcome.Output.TrimEnd());
        }

        _selectedScript.StatusText = outcome.Success ? "Reverted ✓" : $"Revert failed ({outcome.ExitCode})";
        _session.SetStatus(outcome.Success
            ? $"Reverted {_selectedScript.DisplayId} using -{revertSwitch}."
            : $"Revert of {_selectedScript.DisplayId} failed with exit code {outcome.ExitCode}.");
        BtnRevertScript.IsEnabled = true;
    }

    private void BtnCopyCode_Click(object sender, RoutedEventArgs e)
    {
        if (!string.IsNullOrEmpty(TxtCodeEditor.Text))
        {
            Clipboard.SetText(TxtCodeEditor.Text);
            _session.SetStatus($"Copied PowerShell code for {_selectedScript?.DisplayId} to clipboard.");
        }
    }

    private void BtnSaveCode_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedScript == null)
        {
            return;
        }

        try
        {
            if (_workspace.SaveScriptSource(_selectedScript, TxtCodeEditor.Text))
            {
                AppendConsole($"[SAVED] User override written: {_selectedScript.FullPath}");
                _session.SetStatus($"Saved changes to {_selectedScript.RelativePath} (user override).");
            }
            else
            {
                AppendConsole($"[ERROR] Could not save {_selectedScript.RelativePath}.");
                _session.SetStatus($"Could not save {_selectedScript.RelativePath}.");
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show(Window.GetWindow(this), ex.Message, "Save failed", MessageBoxButton.OK, MessageBoxImage.Error);
        }
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
            _session.SetStatus("Copied raw console output to clipboard.");
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
