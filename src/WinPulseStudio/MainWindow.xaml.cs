using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Threading;
using WinPulseStudio.Models;
using WinPulseStudio.Services;
using WinPulseStudio.Views;

namespace WinPulseStudio;

public partial class MainWindow : Window, INavigator
{
    // Cached, frozen brushes: the telemetry timer repaints every 3 seconds and
    // nav clicks re-style buttons — freezing avoids per-tick allocations and
    // makes the brushes safely shareable across elements.
    private static readonly SolidColorBrush AdminGreenBrush = CreateFrozen(Color.FromRgb(16, 185, 129));
    private static readonly SolidColorBrush StandardAmberBrush = CreateFrozen(Color.FromRgb(251, 191, 36));
    private static readonly SolidColorBrush NavActiveBgBrush = CreateFrozen(Color.FromRgb(3, 105, 161));
    private static readonly SolidColorBrush NavActiveBorderBrush = CreateFrozen(Color.FromRgb(56, 189, 248));
    private static readonly SolidColorBrush TransparentBrush = CreateFrozen(Colors.Transparent);
    private static readonly SolidColorBrush SafetyLockedFgBrush = CreateFrozen(Color.FromRgb(110, 231, 183));
    private static readonly SolidColorBrush SafetyLockedBgBrush = CreateFrozen(Color.FromRgb(6, 78, 59));
    private static readonly SolidColorBrush SafetyLockedBorderBrush = CreateFrozen(Color.FromRgb(16, 185, 129));
    private static readonly SolidColorBrush SafetyUnlockedFgBrush = CreateFrozen(Color.FromRgb(253, 224, 71));
    private static readonly SolidColorBrush SafetyUnlockedBgBrush = CreateFrozen(Color.FromRgb(120, 53, 15));
    private static readonly SolidColorBrush SafetyUnlockedBorderBrush = CreateFrozen(Color.FromRgb(245, 158, 11));

    private static SolidColorBrush CreateFrozen(Color color)
    {
        var brush = new SolidColorBrush(color);
        brush.Freeze();
        return brush;
    }

    private readonly SessionContext _session = new();
    private readonly DispatcherTimer _telemetryTimer = new();
    private HomeView? _homeView;
    private AdvancedView? _advancedView;
    private CommandsView? _commandsView;
    private HistoryView? _historyView;
    private Button? _activeNavButton;

    public MainWindow()
    {
        InitializeComponent();
        Loaded += MainWindow_Loaded;
    }

    private void MainWindow_Loaded(object sender, RoutedEventArgs e)
    {
        TxtWorkspacePath.Text = $"Workspace: {_session.Workspace.WorkspaceRoot}";
        TxtHostCpu.Text = $"{Environment.MachineName} • {Environment.ProcessorCount} Logical Cores";
        UpdateTelemetryHeader();
        UpdateSafetyLockUi();

        _telemetryTimer.Interval = TimeSpan.FromSeconds(3);
        _telemetryTimer.Tick += (_, _) => UpdateTelemetryHeader();
        _telemetryTimer.Start();

        StateChanged += (_, _) =>
        {
            if (WindowState == WindowState.Minimized)
            {
                _telemetryTimer.Stop();
            }
            else if (!_telemetryTimer.IsEnabled)
            {
                UpdateTelemetryHeader();
                _telemetryTimer.Start();
            }
        };
        Closed += (_, _) => _telemetryTimer.Stop();

        _session.StatusChanged += (_, message) => TxtFooterStatus.Text = message;
        _session.SafetyLockChanged += (_, _) => UpdateSafetyLockUi();

        ShowHome();

        if (!_session.PowerShellAvailable)
        {
            _session.SetStatus("PowerShell 7 (pwsh) was not found on PATH. Install it before running or verifying scripts.");
        }
    }

    private void UpdateTelemetryHeader()
    {
        var (usedGb, totalGb, loadPct) = WorkspaceService.GetMemoryTelemetry();
        TxtRamUsage.Text = $"{usedGb:0.0} / {totalGb:0.0} GB ({loadPct}%)";

        bool isAdmin = _session.IsAdministrator;
        TxtAdminStatus.Text = isAdmin ? "⚡ Administrator" : "👤 Standard User";
        TxtAdminStatus.Foreground = isAdmin ? AdminGreenBrush : StandardAmberBrush;
    }

    // ==================== NAVIGATION ====================

    public void ShowHome()
    {
        _homeView ??= new HomeView(_session, this);
        ContentHost.Content = _homeView;
        SetActiveNav(BtnNavHome);
        _session.SetStatus("Home • Choose a goal to see exactly what will change before anything runs.");
    }

    public void ShowAdvanced()
    {
        _advancedView ??= new AdvancedView(_session, this);
        ContentHost.Content = _advancedView;
        SetActiveNav(BtnNavAdvanced);
        _session.SetStatus("Advanced Mode • Full 100-script catalog, presets, filters and source editor.");
    }

    public void ShowCommands()
    {
        _commandsView ??= new CommandsView(_session, this);
        ContentHost.Content = _commandsView;
        SetActiveNav(BtnNavCommands);
        _session.SetStatus("Commands • Everyday PowerShell, winget, and cmd commands explained in plain language. Nothing runs from here.");
    }

    public void ShowHistory()
    {
        _historyView ??= new HistoryView(_session, this);
        _historyView.Refresh();
        ContentHost.Content = _historyView;
        SetActiveNav(BtnNavHistory);
        _session.SetStatus("History • Every verification, preview and applied change is recorded on this PC.");
    }

    public void ShowGuide(GoalContext goal)
    {
        ContentHost.Content = new GuideView(_session, this, goal);
        SetActiveNav(null);
        _session.SetStatus($"Guided mode • {goal.Title} — preview each step, then apply when ready.");
    }

    private void SetActiveNav(Button? active)
    {
        _activeNavButton = active;
        foreach (var button in new[] { BtnNavHome, BtnNavAdvanced, BtnNavCommands, BtnNavHistory })
        {
            bool isActive = ReferenceEquals(button, active);
            button.Background = isActive ? NavActiveBgBrush : TransparentBrush;
            button.BorderBrush = isActive ? NavActiveBorderBrush : TransparentBrush;
        }
    }

    private void BtnNavHome_Click(object sender, RoutedEventArgs e) => ShowHome();

    private void BtnNavAdvanced_Click(object sender, RoutedEventArgs e) => ShowAdvanced();

    private void BtnNavCommands_Click(object sender, RoutedEventArgs e) => ShowCommands();

    private void BtnNavHistory_Click(object sender, RoutedEventArgs e) => ShowHistory();

    // ==================== SAFETY LOCK ====================

    private void BtnSafetyLock_Click(object sender, RoutedEventArgs e)
    {
        _session.SetSafetyLock(!_session.SafetyLockEnabled);
        _session.SetStatus(_session.SafetyLockEnabled
            ? "Safety Lock is ON — live changes are blocked everywhere. Previews are always allowed."
            : "Safety Lock is OFF — live changes are allowed. The lock turns back on after a guided apply.");
    }

    private void UpdateSafetyLockUi()
    {
        if (_session.SafetyLockEnabled)
        {
            TxtSafetyLockLabel.Text = "🔒 Safety Lock: ON (Live changes blocked)";
            TxtSafetyLockLabel.Foreground = SafetyLockedFgBrush;
            BtnSafetyLock.Background = SafetyLockedBgBrush;
            BtnSafetyLock.BorderBrush = SafetyLockedBorderBrush;
        }
        else
        {
            TxtSafetyLockLabel.Text = "🔓 Safety Lock: OFF (Live changes allowed)";
            TxtSafetyLockLabel.Foreground = SafetyUnlockedFgBrush;
            BtnSafetyLock.Background = SafetyUnlockedBgBrush;
            BtnSafetyLock.BorderBrush = SafetyUnlockedBorderBrush;
        }
    }
}
