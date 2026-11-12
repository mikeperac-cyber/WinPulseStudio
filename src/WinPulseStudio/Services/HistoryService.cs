using System.IO;
using System.Text;
using System.Text.Json;
using WinPulseStudio.Models;

namespace WinPulseStudio.Services;

public sealed class HistoryService
{
    private const int MaxRecords = 500;
    private static readonly JsonSerializerOptions IndentedJsonOptions = new() { WriteIndented = true };
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
            var json = JsonSerializer.Serialize(_records, IndentedJsonOptions);
            var tempPath = HistoryPath + ".tmp";
            File.WriteAllText(tempPath, json, Encoding.UTF8);
            File.Move(tempPath, HistoryPath, overwrite: true);
        }
        catch
        {
            // History is best-effort; never block a run because logging failed.
        }
    }
}
