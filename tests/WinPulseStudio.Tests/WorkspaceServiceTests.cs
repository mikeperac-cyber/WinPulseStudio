using System.IO;
using System.Text;
using WinPulseStudio.Models;
using WinPulseStudio.Services;
using Xunit;

namespace WinPulseStudio.Tests;

public sealed class WorkspaceServiceTests
{
    private static string RepoRoot()
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

        throw new DirectoryNotFoundException("Could not locate the repository root from the test host.");
    }

    private static string TempDir(string name)
    {
        var path = Path.Combine(Path.GetTempPath(), "winpulse-tests", $"{name}-{Guid.NewGuid():N}");
        Directory.CreateDirectory(path);
        return path;
    }

    [Fact]
    public void LoadManifest_LoadsAllScriptsAndPresets()
    {
        var workspace = new WorkspaceService(RepoRoot(), TempDir("manifest"));
        var manifest = workspace.LoadManifest();

        Assert.Equal(100, manifest.Scripts.Count);
        Assert.Equal(100, manifest.Scripts.Count(s => File.Exists(s.FullPath)));
        Assert.Equal(5, manifest.Presets.Count);

        foreach (var preset in manifest.Presets)
        {
            Assert.NotEmpty(preset.ScriptIds);
            foreach (var id in preset.ScriptIds)
            {
                Assert.Contains(manifest.Scripts, s => s.Id == id);
            }
        }
    }

    [Fact]
    public void LoadManifest_MalformedJson_ReturnsEmptyCatalog()
    {
        var root = TempDir("malformed");
        Directory.CreateDirectory(Path.Combine(root, "scripts"));
        File.WriteAllText(Path.Combine(root, "scripts", "manifest.json"), "{ not json");

        var workspace = new WorkspaceService(root, TempDir("malformed-data"));
        var manifest = workspace.LoadManifest();

        Assert.Empty(manifest.Scripts);
    }

    [Fact]
    public void SaveScriptSource_WritesUserOverrideAndKeepsBundledFile()
    {
        var root = TempDir("override");
        Directory.CreateDirectory(Path.Combine(root, "scripts"));
        var bundled = Path.Combine(root, "scripts", "demo.ps1");
        File.WriteAllText(bundled, "Write-Output 'bundled'", Encoding.UTF8);

        var workspace = new WorkspaceService(root, TempDir("override-data"));
        var script = new ScriptItem { Id = "900", RelativePath = "scripts/demo.ps1", BundledPath = bundled, FullPath = bundled };

        Assert.True(workspace.SaveScriptSource(script, "Write-Output 'edited'"));
        Assert.Equal("Write-Output 'edited'", workspace.ReadScriptSource(script));
        Assert.Equal("Write-Output 'bundled'", File.ReadAllText(bundled, Encoding.UTF8));
        Assert.StartsWith(workspace.UserScriptsRoot, script.FullPath, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void LoadFavoriteIds_MigratesLegacyWorkspaceFile()
    {
        var root = TempDir("favorites");
        var data = TempDir("favorites-data");
        File.WriteAllText(Path.Combine(root, ".winpulse-favorites.json"), "[\"001\",\"077\"]", Encoding.UTF8);

        var workspace = new WorkspaceService(root, data);
        var ids = workspace.LoadFavoriteIds();

        Assert.Contains("001", ids);
        Assert.Contains("077", ids);
        Assert.True(File.Exists(workspace.FavoritesPath));
    }

    [Fact]
    public void SaveFavorites_WritesToUserDataRoot()
    {
        var workspace = new WorkspaceService(RepoRoot(), TempDir("favorites-save"));
        var script = new ScriptItem { Id = "001", IsFavorite = true };
        var other = new ScriptItem { Id = "002", IsFavorite = false };

        Assert.True(workspace.SaveFavorites([script, other]));
        Assert.True(File.Exists(workspace.FavoritesPath));
        Assert.Contains("001", File.ReadAllText(workspace.FavoritesPath, Encoding.UTF8));
    }
}