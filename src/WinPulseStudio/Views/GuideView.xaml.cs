using System.Collections.ObjectModel;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using WinPulseStudio.Models;
using WinPulseStudio.Services;

namespace WinPulseStudio.Views;

public partial class GuideView : UserControl
{
    private readonly SessionContext _session;
    private readonly INavigator _navigator;
    private readonly GoalContext _goal;
    private readonly ObservableCollection<GuideStepVm> _steps = [];
    private readonly ObservableCollection<AppliedRevertVm> _reverts = [];
    private bool _busy;

    public GuideView(SessionContext session, INavigator navigator, GoalContext goal)
    {
        InitializeComponent();
        _session = session;
        _navigator = navigator;
        _goal = goal;

        TxtGoalTitle.Text = goal.Title;
        TxtGoalSubtitle.Text = goal.Subtitle;

        foreach (var script in goal.Scripts)
        {
            _steps.Add(new GuideStepVm(script));
        }

        LstSteps.ItemsSource = _steps;
        LstSummaryReverts.ItemsSource = _reverts;

        if (!goal.CanApply)
        {
            BtnApply.Visibility = Visibility.Collapsed;
            BtnRestorePoint.Visibility = Visibility.Collapsed;
            TxtApplyHint.Text = "These checks only read your system — nothing will be changed.";
        }
        else if (!session.IsAdministrator)
        {
            BtnRestorePoint.ToolTip = "Creating a restore point requires running WinPulse Studio as Administrator.";
        }

        UpdateProgress();
    }

    private void UpdateProgress()
    {
        int previewed = _steps.Count(s => s.IsPreviewed);
        TxtProgress.Text = $"{previewed} of {_steps.Count} previewed";
        PrgProgress.Maximum = Math.Max(1, _steps.Count);
        PrgProgress.Value = previewed;
    }

    private void SetBusy(bool busy)
    {
        _busy = busy;
        BtnPreviewAll.IsEnabled = !busy;
        BtnApply.IsEnabled = !busy;
        BtnRestorePoint.IsEnabled = !busy;
    }

    private void BtnBackHome_Click(object sender, RoutedEventArgs e) => _navigator.ShowHome();

    private async void BtnPreviewStep_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: GuideStepVm vm })
        {
            await PreviewOneAsync(vm);
        }
    }

    private async void BtnPreviewAll_Click(object sender, RoutedEventArgs e)
    {
        if (_busy)
        {
            return;
        }

        SetBusy(true);
        try
        {
            foreach (var step in _steps.Where(s => !s.IsPreviewed).ToList())
            {
                await PreviewCoreAsync(step);
            }
        }
        finally
        {
            SetBusy(false);
        }
        _session.SetStatus($"Previewed {_steps.Count(s => s.IsPreviewed)} of {_steps.Count} steps for '{_goal.Title}'.");
    }

    private async Task PreviewOneAsync(GuideStepVm vm)
    {
        if (_busy || vm.IsPreviewed)
        {
            return;
        }

        SetBusy(true);
        try
        {
            await PreviewCoreAsync(vm);
        }
        finally
        {
            SetBusy(false);
        }
    }

    private async Task PreviewCoreAsync(GuideStepVm vm)
    {
        vm.SetWorkingStatus("Verifying…");
        var verify = await _session.Runs.RunAsync(vm.Script, RunMode.Verify, _goal.ContextName);
        vm.AppendOutput(verify.Output);

        if (!verify.Success)
        {
            vm.SetFailureStatus("Verification failed");
            vm.IsDetailsOpen = true;
            vm.IsOutputOpen = true;
            _session.SetStatus($"{vm.DisplayId} failed verification — check the output for details.");
            return;
        }

        vm.SetWorkingStatus("Simulating…");
        var dryRun = await _session.Runs.RunAsync(vm.Script, RunMode.DryRun, _goal.ContextName);
        vm.AppendOutput(dryRun.Output);

        if (dryRun.Success)
        {
            vm.SetSuccessStatus($"Preview ready ({dryRun.Duration.TotalSeconds:0.0}s)");
            vm.IsPreviewed = true;
            _session.SetStatus($"{vm.DisplayId} preview completed — no changes were made.");
        }
        else
        {
            vm.SetFailureStatus($"Preview failed (exit {dryRun.ExitCode})");
            vm.IsDetailsOpen = true;
            vm.IsOutputOpen = true;
            _session.SetStatus($"{vm.DisplayId} preview reported a problem — check the output for details.");
        }

        UpdateProgress();
    }

    private async void BtnApply_Click(object sender, RoutedEventArgs e)
    {
        if (_busy)
        {
            return;
        }

        var pending = _steps.Where(s => !s.IsApplied).ToList();
        if (pending.Count == 0)
        {
            MessageBox.Show(Window.GetWindow(this), "Everything in this plan has already been applied.", "Nothing to apply", MessageBoxButton.OK, MessageBoxImage.Information);
            return;
        }

        var unpreviewed = pending.Count(s => !s.IsPreviewed);
        if (unpreviewed > 0)
        {
            MessageBox.Show(
                Window.GetWindow(this),
                $"{unpreviewed} step(s) have not been previewed yet.\n\nPreview every step before applying so you can see exactly what will change.",
                "Preview required",
                MessageBoxButton.OK,
                MessageBoxImage.Information);
            return;
        }

        var message = BuildApplyConfirmation(pending);
        var confirm = MessageBox.Show(
            Window.GetWindow(this),
            message,
            "Apply changes for real",
            MessageBoxButton.YesNo,
            MessageBoxImage.Warning,
            MessageBoxResult.No);

        if (confirm != MessageBoxResult.Yes)
        {
            return;
        }

        SetBusy(true);
        _session.SetSafetyLock(false);

        int succeeded = 0;
        int failed = 0;
        try
        {
            foreach (var step in pending)
            {
                step.SetWorkingStatus("Applying…");
                _session.SetStatus($"Applying {step.DisplayId} ({step.Name})...");

                var outcome = await _session.Runs.RunAsync(step.Script, RunMode.Live, _goal.ContextName);
                step.AppendOutput(outcome.Output);

                if (outcome.Success)
                {
                    succeeded++;
                    step.IsApplied = true;
                    step.IsPreviewed = true;
                    step.SetSuccessStatus($"Applied ✓ ({outcome.Duration.TotalSeconds:0.0}s)");
                }
                else
                {
                    failed++;
                    step.SetFailureStatus($"Failed (exit {outcome.ExitCode})");
                    step.IsOutputOpen = true;
                }
                UpdateProgress();
            }
        }
        finally
        {
            _session.SetSafetyLock(true);
            SetBusy(false);
        }

        ShowSummary(succeeded, failed);
        _session.SetStatus(failed == 0
            ? $"'{_goal.Title}' applied successfully: {succeeded} step(s) completed. A restore point can be created before your next apply."
            : $"'{_goal.Title}' finished with issues: {succeeded} succeeded, {failed} failed. Review the failed steps and the History screen.");
    }

    private string BuildApplyConfirmation(List<GuideStepVm> pending)
    {
        var sb = new StringBuilder();
        sb.AppendLine($"You are about to apply {pending.Count} change(s) to this PC:");
        sb.AppendLine();

        foreach (var step in pending)
        {
            sb.AppendLine($"• {step.DisplayId} {step.Name}");
            foreach (var change in step.Script.WhatChanges.Take(2))
            {
                sb.AppendLine($"     – {change}");
            }
        }

        int adminNeeded = pending.Count(s => s.Script.RequiresAdmin);
        if (adminNeeded > 0 && !_session.IsAdministrator)
        {
            sb.AppendLine();
            sb.AppendLine($"Warning: {adminNeeded} step(s) need Administrator rights and this session is not elevated.");
        }

        if (pending.Any(s => s.IsApplied == false))
        {
            sb.AppendLine();
            sb.AppendLine("Tip: use 'Create Restore Point' first if you have not already.");
        }

        sb.AppendLine();
        sb.AppendLine("The Safety Lock turns off while this batch runs, then turns back on when it finishes.");
        sb.AppendLine();
        sb.AppendLine("Continue?");
        return sb.ToString();
    }

    private void ShowSummary(int succeeded, int failed)
    {
        SummaryPanel.Visibility = Visibility.Visible;

        if (failed == 0)
        {
            TxtSummaryTitle.Text = "All done!";
            TxtSummaryTitle.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(0x6E, 0xE7, 0xB7));
            TxtSummaryDetail.Text = $"{succeeded} step(s) applied successfully. A full log of every action is on the History screen.";
        }
        else
        {
            TxtSummaryTitle.Text = "Finished with issues";
            TxtSummaryTitle.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(0xFC, 0xA5, 0xA5));
            TxtSummaryDetail.Text = $"{succeeded} step(s) applied, {failed} failed. Open the failed steps' output for details, then check the History screen.";
        }

        _reverts.Clear();
        foreach (var step in _steps.Where(s => s.IsApplied))
        {
            if (step.Script.HasHowToRevert)
            {
                _reverts.Add(new AppliedRevertVm
                {
                    Title = $"{step.DisplayId} {step.Name}",
                    Revert = step.Script.HowToRevert
                });
            }
        }

        TxtNoReverts.Visibility = _reverts.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
    }

    private async void BtnRestorePoint_Click(object sender, RoutedEventArgs e)
    {
        if (_busy)
        {
            return;
        }

        if (!_session.IsAdministrator)
        {
            MessageBox.Show(
                Window.GetWindow(this),
                "Creating a System Restore point needs Administrator rights.\n\nClose WinPulse Studio, right-click it and choose 'Run as administrator', then try again.",
                "Administrator required",
                MessageBoxButton.OK,
                MessageBoxImage.Information);
            return;
        }

        var confirm = MessageBox.Show(
            Window.GetWindow(this),
            "Create a Windows System Restore checkpoint now?\n\nThis can take a minute and creates a safe point you can return to.",
            "Create restore point",
            MessageBoxButton.YesNo,
            MessageBoxImage.Question,
            MessageBoxResult.Yes);

        if (confirm != MessageBoxResult.Yes)
        {
            return;
        }

        SetBusy(true);
        _session.SetSafetyLock(false);
        try
        {
            _session.SetStatus("Creating a System Restore point...");
            var restoreScript = _session.Scripts.FirstOrDefault(s => s.Id == "091");
            var outcome = await _session.Runs.RunRestorePointAsync(restoreScript);

            MessageBox.Show(
                Window.GetWindow(this),
                outcome.Success
                    ? "Restore point created successfully. You can now apply changes with confidence."
                    : $"The restore point could not be created (exit {outcome.ExitCode}).\n\nYou can still continue, but the changes will not have a checkpoint.",
                outcome.Success ? "Restore point created" : "Restore point failed",
                MessageBoxButton.OK,
                outcome.Success ? MessageBoxImage.Information : MessageBoxImage.Warning);

            _session.SetStatus(outcome.Success
                ? "Restore point created successfully."
                : "Restore point failed — see the History screen for the log.");
        }
        finally
        {
            _session.SetSafetyLock(true);
            SetBusy(false);
        }
    }

    private void BtnCopyReport_Click(object sender, RoutedEventArgs e)
    {
        var sb = new StringBuilder();
        sb.AppendLine($"WinPulse run report — {_goal.Title}");
        sb.AppendLine($"Generated: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
        sb.AppendLine(new string('-', 60));

        foreach (var step in _steps)
        {
            sb.AppendLine($"{step.DisplayId} {step.Name}");
            sb.AppendLine($"  Status  : {step.StatusText}");
            sb.AppendLine($"  Previewed: {(step.IsPreviewed ? "yes" : "no")}    Applied: {(step.IsApplied ? "yes" : "no")}");
            if (step.HasOutput)
            {
                var lines = step.OutputText.Replace("\r\n", "\n").Split('\n');
                var tail = lines.Length > 12 ? lines[^12..] : lines;
                foreach (var line in tail)
                {
                    sb.AppendLine($"    {line}");
                }
            }
            sb.AppendLine();
        }

        if (_reverts.Count > 0)
        {
            sb.AppendLine("HOW TO UNDO APPLIED CHANGES");
            foreach (var revert in _reverts)
            {
                sb.AppendLine($"{revert.Title}: {revert.Revert}");
            }
        }

        Clipboard.SetText(sb.ToString());
        _session.SetStatus("Copied the run report to clipboard.");
    }

    private void BtnViewHistory_Click(object sender, RoutedEventArgs e) => _navigator.ShowHistory();
}
