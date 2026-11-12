using System.IO;
using System.Threading;
using System.Windows;
using WinPulseStudio.Services;
using WinPulseStudio.Views;
using Xunit;

namespace WinPulseStudio.Tests;

[Collection("WpfUi")]
public sealed class HomeViewRefreshTests
{
    [Fact]
    public void RefreshCollections_UpdatesItemsSourceAfterCollectionAdded()
    {
        Exception? captured = null;
        int countAfterRefresh = 0;

        var thread = new Thread(() =>
        {
            var tempDir = Path.Combine(Path.GetTempPath(), "winpulse-home-refresh-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(tempDir);
            try
            {
                if (Application.Current == null)
                {
                    var app = new App();
                    app.InitializeComponent();
                }

                var session = new SessionContext();
                var home = new HomeView(session, null!);
                int initialCount = home.CollectionCount;

                var added = session.Collections.Add("Reviewer Test Collection", "temp", ["001"]);
                try
                {
                    home.RefreshCollections();
                    countAfterRefresh = home.CollectionCount;
                    Assert.Equal(initialCount + 1, countAfterRefresh);
                }
                finally
                {
                    session.Collections.Remove(added.Id);
                }
            }
            catch (Exception ex)
            {
                captured = ex;
            }
            finally
            {
                if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
            }
        });

        thread.SetApartmentState(ApartmentState.STA);
        thread.Start();
        thread.Join();

        Assert.Null(captured);
        Assert.True(countAfterRefresh >= 1);
    }
}
