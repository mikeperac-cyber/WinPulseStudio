using System.IO;
using System.Text;
using System.Text.Json;
using WinPulseStudio.Models;

namespace WinPulseStudio.Services;

public sealed class CollectionService
{
    private static readonly JsonSerializerOptions IndentedJsonOptions = new() { WriteIndented = true };
    private readonly object _sync = new();
    private List<CustomCollection> _collections = [];

    public string CollectionsPath { get; }

    public CollectionService(string? storageDirectory = null)
    {
        string dir = storageDirectory ?? Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "WinPulseStudio");
        Directory.CreateDirectory(dir);
        CollectionsPath = Path.Combine(dir, "collections.json");
        Load();
    }

    private void Load()
    {
        try
        {
            if (File.Exists(CollectionsPath))
            {
                var json = File.ReadAllText(CollectionsPath, Encoding.UTF8);
                _collections = JsonSerializer.Deserialize<List<CustomCollection>>(json) ?? [];
            }
        }
        catch
        {
            _collections = [];
        }
    }

    public IReadOnlyList<CustomCollection> GetAll()
    {
        lock (_sync)
        {
            return _collections.OrderBy(c => c.CreatedAt).ToList();
        }
    }

    public CustomCollection Add(string name, string description, IEnumerable<string> scriptIds)
    {
        var collection = new CustomCollection
        {
            Name = name.Trim(),
            Description = description.Trim(),
            ScriptIds = scriptIds.Distinct(StringComparer.OrdinalIgnoreCase).ToList()
        };

        lock (_sync)
        {
            _collections.Add(collection);
            SaveUnsafe();
        }
        return collection;
    }

    public void Remove(string id)
    {
        lock (_sync)
        {
            _collections.RemoveAll(c => string.Equals(c.Id, id, StringComparison.OrdinalIgnoreCase));
            SaveUnsafe();
        }
    }

    private void SaveUnsafe()
    {
        try
        {
            var json = JsonSerializer.Serialize(_collections, IndentedJsonOptions);
            var tempPath = CollectionsPath + ".tmp";
            File.WriteAllText(tempPath, json, Encoding.UTF8);
            File.Move(tempPath, CollectionsPath, overwrite: true);
        }
        catch
        {
            // Best-effort persistence.
        }
    }
}
