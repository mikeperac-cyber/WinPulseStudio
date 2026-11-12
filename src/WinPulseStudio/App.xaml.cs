using System.IO;
using System.Windows;
using WinPulseStudio.Services;

namespace WinPulseStudio;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        if (e.Args.Contains("--verify-headless", StringComparer.OrdinalIgnoreCase))
        {
            try
            {
                var ws = new WorkspaceService();
                var manifest = ws.LoadManifest();
                int existingFiles = manifest.Scripts.Count(s => File.Exists(s.FullPath) && ws.ReadScriptSource(s).Length > 100);
                bool pwshAvailable = WorkspaceService.IsPowerShellAvailable();

                // Also instantiate MainWindow to verify XAML parsing & UI initialization
                var win = new MainWindow();
                win.ShowActivated = false;
                win.WindowState = WindowState.Minimized;
                win.Show();
                win.Close();

                Console.WriteLine($"[WinPulseStudio UI + Headless Self-Test] Loaded {manifest.Scripts.Count} scripts, {manifest.Presets.Count} presets, {existingFiles}/100 .ps1 files, pwsh={(pwshAvailable ? "available" : "MISSING")}, and verified MainWindow XAML.");
                Shutdown(existingFiles == 100 && manifest.Scripts.Count == 100 && pwshAvailable ? 0 : 1);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"[ERROR] {ex}");
                Shutdown(2);
            }
            return;
        }

        if (!WorkspaceService.IsPowerShellAvailable())
        {
            MessageBox.Show(
                "WinPulse Studio requires PowerShell 7 (pwsh) on PATH to run, preview, and verify scripts.\n\nInstall PowerShell 7 from https://aka.ms/powershell, then restart the app.",
                "PowerShell 7 required",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
        }

        base.OnStartup(e);
    }
}
