using WinPulseStudio.Models;

namespace WinPulseStudio.Services;

public sealed class SessionContext
{
    public WorkspaceService Workspace { get; }
    public ManifestRoot Manifest { get; }
    public List<ScriptItem> Scripts { get; }
    public HistoryService History { get; }
    public CollectionService Collections { get; }
    public RunService Runs { get; }
    public bool IsAdministrator { get; }
    public bool PowerShellAvailable => Workspace.PowerShellAvailable;

    private bool _safetyLockEnabled = true;

    public bool SafetyLockEnabled => _safetyLockEnabled;

    public event EventHandler? SafetyLockChanged;
    public event EventHandler<string>? StatusChanged;

    public SessionContext()
    {
        Workspace = new WorkspaceService();
        Manifest = Workspace.LoadManifest();
        Scripts = Manifest.Scripts;
        History = new HistoryService();
        Collections = new CollectionService();
        Runs = new RunService(Workspace, History, () => _safetyLockEnabled);
        IsAdministrator = WorkspaceService.IsRunningAsAdministrator();
    }

    public void SetSafetyLock(bool enabled)
    {
        if (_safetyLockEnabled == enabled)
        {
            return;
        }

        _safetyLockEnabled = enabled;
        SafetyLockChanged?.Invoke(this, EventArgs.Empty);
    }

    public void SetStatus(string message)
    {
        StatusChanged?.Invoke(this, message);
    }
}
