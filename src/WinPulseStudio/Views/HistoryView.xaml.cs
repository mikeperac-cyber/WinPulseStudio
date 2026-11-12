using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using WinPulseStudio.Models;
using WinPulseStudio.Services;

namespace WinPulseStudio.Views;

public partial class HistoryView : UserControl
{
    private readonly SessionContext _session;
    private readonly INavigator _navigator;

    public HistoryView(SessionContext session, INavigator navigator)
    {
        InitializeComponent();
        _session = session;
        _navigator = navigator;
        Refresh();
    }

    public void Refresh()
    {
        ApplyFilter();
    }

    private void TxtHistorySearch_TextChanged(object sender, TextChangedEventArgs e)
    {
        if (IsInitialized)
        {
            ApplyFilter();
        }
    }

    private void FilterCombo_Changed(object sender, SelectionChangedEventArgs e)
    {
        if (IsInitialized && CmbStatus != null)
        {
            ApplyFilter();
        }
    }

    private void ApplyFilter()
    {
        IEnumerable<RunRecord> query = _session.History.GetAll();

        string search = TxtHistorySearch.Text.Trim();
        if (!string.IsNullOrEmpty(search))
        {
            query = query.Where(r =>
                r.ScriptId.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                r.ScriptName.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                r.Context.Contains(search, StringComparison.OrdinalIgnoreCase));
        }

        string? mode = GetComboText(CmbMode);
        if (mode != null)
        {
            query = query.Where(r => string.Equals(r.ModeLabel, mode, StringComparison.OrdinalIgnoreCase));
        }

        string? status = GetComboText(CmbStatus);
        if (status != null)
        {
            query = query.Where(r => string.Equals(r.StatusLabel, status, StringComparison.OrdinalIgnoreCase));
        }

        var records = query.ToList();
        LstHistory.ItemsSource = records;
        TxtEmptyHistory.Visibility = records.Count == 0 ? Visibility.Visible : Visibility.Collapsed;

        if (records.Count > 0)
        {
            LstHistory.SelectedIndex = 0;
        }
        else
        {
            ShowDetail(null);
        }
    }

    private static string? GetComboText(ComboBox combo)
    {
        if (combo.SelectedIndex <= 0 || combo.SelectedItem is not ComboBoxItem item)
        {
            return null;
        }
        return item.Content?.ToString();
    }

    private void LstHistory_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        ShowDetail(LstHistory.SelectedItem as RunRecord);
    }

    private void ShowDetail(RunRecord? record)
    {
        if (record == null)
        {
            TxtDetailTitle.Text = "Select a run";
            TxtDetailMeta.Text = "Details, exit code and output appear here.";
            TxtDetailSummary.Text = string.Empty;
            TxtDetailOutput.Text = string.Empty;
            BtnRunAgain.IsEnabled = false;
            return;
        }

        TxtDetailTitle.Text = $"{record.DisplayId} {record.ScriptName}";
        TxtDetailMeta.Text = $"{record.TimestampText}  •  {record.ModeLabel}  •  {record.Context}";
        TxtDetailSummary.Text = $"{record.StatusLabel}  •  exit code {record.ExitCode}  •  {record.DurationSeconds:0.0}s";
        TxtDetailSummary.Foreground = new SolidColorBrush(record.Success
            ? Color.FromRgb(0x6E, 0xE7, 0xB7)
            : Color.FromRgb(0xFC, 0xA5, 0xA5));
        TxtDetailOutput.Text = string.IsNullOrWhiteSpace(record.OutputSnippet)
            ? "(no output captured)"
            : record.OutputSnippet;

        BtnRunAgain.IsEnabled = FindScript(record.ScriptId) != null;
    }

    private ScriptItem? FindScript(string id) =>
        _session.Scripts.FirstOrDefault(s => string.Equals(s.Id, id, StringComparison.OrdinalIgnoreCase));

    private void BtnRunAgain_Click(object sender, RoutedEventArgs e)
    {
        if (LstHistory.SelectedItem is not RunRecord record)
        {
            return;
        }

        var script = FindScript(record.ScriptId);
        if (script == null)
        {
            MessageBox.Show(Window.GetWindow(this), "That script is no longer available in the catalog.", "Script missing", MessageBoxButton.OK, MessageBoxImage.Information);
            return;
        }

        _navigator.ShowGuide(new GoalContext
        {
            Title = $"Re-run {record.DisplayId} — {record.ScriptName}",
            Subtitle = $"Re-run from history. Original run: {record.TimestampText} ({record.ModeLabel}).",
            ContextName = $"History re-run ({record.TimestampText})",
            Kind = GoalKind.Collection,
            Scripts = [script]
        });
    }

    private void BtnCopyDetail_Click(object sender, RoutedEventArgs e)
    {
        if (LstHistory.SelectedItem is not RunRecord record)
        {
            return;
        }

        string report =
            $"WinPulse run — {record.DisplayId} {record.ScriptName}{Environment.NewLine}" +
            $"When     : {record.TimestampText}{Environment.NewLine}" +
            $"Mode     : {record.ModeLabel}{Environment.NewLine}" +
            $"Context  : {record.Context}{Environment.NewLine}" +
            $"Result   : {record.StatusLabel} (exit code {record.ExitCode}) in {record.DurationSeconds:0.0}s{Environment.NewLine}" +
            $"{new string('-', 60)}{Environment.NewLine}" +
            record.OutputSnippet;

        Clipboard.SetText(report);
        _session.SetStatus("Copied the run report to clipboard.");
    }

    private void BtnClearHistory_Click(object sender, RoutedEventArgs e)
    {
        var confirm = MessageBox.Show(
            Window.GetWindow(this),
            "Clear the entire run history on this PC?\n\nThis only deletes the log; it does not undo any changes.",
            "Clear history",
            MessageBoxButton.YesNo,
            MessageBoxImage.Question,
            MessageBoxResult.No);

        if (confirm != MessageBoxResult.Yes)
        {
            return;
        }

        _session.History.Clear();
        Refresh();
        _session.SetStatus("Run history cleared.");
    }
}
