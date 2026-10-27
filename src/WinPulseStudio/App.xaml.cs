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

                // Also instantiate MainWindow to verify XAML parsing & UI initialization
                var win = new MainWindow();
                win.ShowActivated = false;
                win.WindowState = WindowState.Minimized;
                win.Show();
                win.Close();

                Console.WriteLine($"[WinPulseStudio UI + Headless Self-Test] Loaded {manifest.Scripts.Count} scripts, {manifest.Presets.Count} presets, {existingFiles}/100 .ps1 files, and verified MainWindow XAML.");
                Shutdown(existingFiles == 100 && manifest.Scripts.Count == 100 ? 0 : 1);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"[ERROR] {ex}");
                Shutdown(2);
            }
            return;
        }

        base.OnStartup(e);
    }
}
