using System.IO;
using System.Text;
using System.Text.Json;
using WinPulseStudio.Models;

namespace WinPulseStudio.Services;

public sealed class HistoryService
{
    private const int MaxRecords = 500;
    private readonly object _sync = new();
    private List<RunRecord> _records = [];

    public string HistoryPath { get; }

    public HistoryService(string? storageDirectory = null)
    {
        string dir = storageDirectory ?? Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "WinPulseStudio");
        Directory.CreateDirectory(dir);
        HistoryPath = Path.Combine(dir, "history.json");
        Load();
    }

    private void Load()
    {
        try
        {
            if (File.Exists(HistoryPath))
            {
                var json = File.ReadAllText(HistoryPath, Encoding.UTF8);
                _records = JsonSerializer.Deserialize<List<RunRecord>>(json) ?? [];
            }
        }
        catch
        {
            _records = [];
        }
    }

    public IReadOnlyList<RunRecord> GetAll()
    {
        lock (_sync)
        {
            return _records.OrderByDescending(r => r.Timestamp).ToList();
        }
    }

    public void Add(RunRecord record)
    {
        lock (_sync)
        {
            _records.Add(record);
            if (_records.Count > MaxRecords)
            {
                _records = _records
                    .OrderByDescending(r => r.Timestamp)
                    .Take(MaxRecords)
                    .OrderBy(r => r.Timestamp)
                    .ToList();
            }
            SaveUnsafe();
        }
    }

    public void Clear()
    {
        lock (_sync)
        {
            _records = [];
            SaveUnsafe();
        }
    }

    private void SaveUnsafe()
    {
        try
        {
            var json = JsonSerializer.Serialize(_records, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(HistoryPath, json, Encoding.UTF8);
        }
        catch
        {
            // History is best-effort; never block a run because logging failed.
        }
    }
}
