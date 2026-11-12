using System.IO;
using WinPulseStudio.Services;
using Xunit;

namespace WinPulseStudio.Tests;

public sealed class CommandReferenceTests
{
    private static string FindRepoRoot()
    {
        var dir = new DirectoryInfo(AppContext.BaseDirectory);
        while (dir != null)
        {
            if (File.Exists(Path.Combine(dir.FullName, "scripts", "manifest.json")))
            {
                return dir.FullName;
            }
            dir = dir.Parent;
        }

        throw new DirectoryNotFoundException("Could not locate the repository root.");
    }

    [Fact]
    public void LoadCommands_ReturnsAllThreeShells()
    {
        var workspace = new WorkspaceService(
            FindRepoRoot(),
            Path.Combine(Path.GetTempPath(), "winpulse-tests", $"commands-{Guid.NewGuid():N}"));

        var commands = workspace.LoadCommands();

        Assert.Equal(56, commands.Count);
        Assert.Contains(commands, c => c.Shell == "PowerShell");
        Assert.Contains(commands, c => c.Shell == "winget");
        Assert.Contains(commands, c => c.Shell == "cmd");
    }

    [Fact]
    public void LoadCommands_AllEntriesAreCompleteAndUnique()
    {
        var workspace = new WorkspaceService(
            FindRepoRoot(),
            Path.Combine(Path.GetTempPath(), "winpulse-tests", $"commands-fields-{Guid.NewGuid():N}"));

        var commands = workspace.LoadCommands();
        var validShells = new[] { "PowerShell", "winget", "cmd" };

        Assert.Equal(commands.Count, commands.Select(c => c.Id).Distinct(StringComparer.OrdinalIgnoreCase).Count());

        foreach (var command in commands)
        {
            Assert.False(string.IsNullOrWhiteSpace(command.Id));
            Assert.False(string.IsNullOrWhiteSpace(command.Title));
            Assert.False(string.IsNullOrWhiteSpace(command.Command));
            Assert.False(string.IsNullOrWhiteSpace(command.Description));
            Assert.Contains(command.Shell, validShells);
            Assert.False(string.IsNullOrWhiteSpace(command.Safety));
        }
    }

    [Fact]
    public void LoadCommands_MalformedJson_ReturnsEmptyList()
    {
        var root = Path.Combine(Path.GetTempPath(), "winpulse-tests", $"commands-bad-{Guid.NewGuid():N}");
        Directory.CreateDirectory(Path.Combine(root, "commands"));
        File.WriteAllText(Path.Combine(root, "commands", "commands.json"), "{ not json");

        var workspace = new WorkspaceService(root, Path.Combine(Path.GetTempPath(), "winpulse-tests", $"commands-bad-data-{Guid.NewGuid():N}"));

        Assert.Empty(workspace.LoadCommands());
    }
}