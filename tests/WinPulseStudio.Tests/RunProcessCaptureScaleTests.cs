using System.IO;
using WinPulseStudio.Models;
using WinPulseStudio.Services;
using Xunit;

namespace WinPulseStudio.Tests;

public sealed class RunProcessCaptureScaleTests
{
    [Fact]
    public async Task ExecuteScriptAsync_FlushesTrailingLinesAndBoundsLargeOutput()
    {
        var tempRoot = Path.Combine(Path.GetTempPath(), "winpulse-scale-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(Path.Combine(tempRoot, "scripts"));
        try
        {
            var scriptPath = Path.Combine(tempRoot, "scripts", "noisy.ps1");
            await File.WriteAllTextAsync(scriptPath, """
                param([switch]$DryRun)
                1..6000 | ForEach-Object { Write-Output "line-$_-0123456789012345678901234567890123456789" }
                Write-Output "FINAL-SENTINEL-LINE"
                """);

            var ws = new WorkspaceService(tempRoot, tempRoot);
            var item = new ScriptItem
            {
                Id = "999",
                Name = "Noisy",
                RelativePath = "scripts/noisy.ps1",
                FullPath = scriptPath,
                BundledPath = scriptPath
            };

            var outcome = await ws.ExecuteScriptAsync(item, dryRun: true, safetyLockEnabled: false);

            Assert.True(outcome.Success);
            Assert.Contains("FINAL-SENTINEL-LINE", outcome.Output);
            Assert.True(outcome.Output.Length <= 270_000, $"Expected bounded output, got {outcome.Output.Length} chars.");
        }
        finally
        {
            Directory.Delete(tempRoot, recursive: true);
        }
    }
}
