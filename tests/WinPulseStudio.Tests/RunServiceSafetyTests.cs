using System.IO;
using WinPulseStudio.Models;
using WinPulseStudio.Services;
using Xunit;

namespace WinPulseStudio.Tests;

public sealed class RunServiceSafetyTests
{
    [Fact]
    public async Task LiveRun_IsBlocked_WhenSafetyLockIsOn()
    {
        var root = Path.Combine(Path.GetTempPath(), "winpulse-tests", $"run-{Guid.NewGuid():N}");
        var data = Path.Combine(Path.GetTempPath(), "winpulse-tests", $"run-data-{Guid.NewGuid():N}");
        Directory.CreateDirectory(root);
        Directory.CreateDirectory(data);

        var workspace = new WorkspaceService(root, data);
        var history = new HistoryService(data);
        var runs = new RunService(workspace, history, () => true);
        var script = new ScriptItem
        {
            Id = "999",
            Name = "Safety lock test",
            RelativePath = "999.ps1",
            FullPath = Path.Combine(root, "999.ps1")
        };

        if (!workspace.PowerShellAvailable)
        {
            return;
        }

        var outcome = await runs.RunAsync(script, RunMode.Live, "test");

        Assert.False(outcome.Success);
        Assert.Equal(-1, outcome.ExitCode);
        Assert.Contains("Safety Lock", outcome.Output, StringComparison.OrdinalIgnoreCase);
        Assert.Single(history.GetAll());
        Assert.False(history.GetAll()[0].Success);
    }
}