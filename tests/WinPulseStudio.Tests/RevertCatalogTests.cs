using System.IO;
using WinPulseStudio.Models;
using WinPulseStudio.Services;
using Xunit;

namespace WinPulseStudio.Tests;

public sealed class RevertCatalogTests
{
    [Fact]
    public void EveryCatalogedRevertSwitch_ExistsInItsScript()
    {
        var root = FindRepoRoot();
        var workspace = new WorkspaceService(root, Path.Combine(Path.GetTempPath(), "winpulse-tests", $"revert-{Guid.NewGuid():N}"));
        var manifest = workspace.LoadManifest();
        var cataloged = manifest.Scripts.Where(s => RevertCatalog.GetRevertSwitch(s.Id) != null).ToList();

        Assert.NotEmpty(cataloged);
        foreach (var script in cataloged)
        {
            var switchName = RevertCatalog.GetRevertSwitch(script.Id);
            Assert.NotNull(switchName);
            var text = File.ReadAllText(script.BundledPath);
            Assert.Contains($"${switchName}", text, StringComparison.Ordinal);
        }
    }

    [Fact]
    public void UnknownScript_HasNoRevertSwitch()
    {
        Assert.Null(RevertCatalog.GetRevertSwitch("999"));
    }

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
}