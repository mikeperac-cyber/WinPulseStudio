using System.IO;
using WinPulseStudio.Models;
using WinPulseStudio.Services;
using Xunit;

namespace WinPulseStudio.Tests;

public sealed class HistoryAndCollectionTests
{
    private static string TempDir(string name)
    {
        var path = Path.Combine(Path.GetTempPath(), "winpulse-tests", $"{name}-{Guid.NewGuid():N}");
        Directory.CreateDirectory(path);
        return path;
    }

    [Fact]
    public void History_Add_TrimsToMaxRecordsAndPersists()
    {
        var dir = TempDir("history");
        var history = new HistoryService(dir);

        for (int i = 0; i < 505; i++)
        {
            history.Add(new RunRecord { ScriptId = i.ToString(), ScriptName = $"Script {i}", Context = "test" });
        }

        Assert.Equal(500, history.GetAll().Count);
        Assert.True(File.Exists(Path.Combine(dir, "history.json")));
        Assert.Equal(500, new HistoryService(dir).GetAll().Count);
    }

    [Fact]
    public void Collections_AddRemove_Persist()
    {
        var dir = TempDir("collections");
        var collections = new CollectionService(dir);
        var collection = collections.Add("Test collection", "test", ["001", "002"]);

        var loaded = new CollectionService(dir).GetAll();
        Assert.Single(loaded);
        Assert.Equal("Test collection", loaded[0].Name);

        collections.Remove(collection.Id);
        Assert.Empty(new CollectionService(dir).GetAll());
    }
}