using System.Threading;
using WinPulseStudio.Services;
using WinPulseStudio.Views;
using Xunit;

namespace WinPulseStudio.Tests;

[Collection("WpfUi")]
public sealed class CommandsViewInitializationTests
{
    [Fact]
    public void CommandsView_CanBeConstructed()
    {
        Exception? captured = null;

        var thread = new Thread(() =>
        {
            try
            {
                // App loads App.xaml resources (brushes/styles used by the view).
                // The generated App class only loads them in Main(), so call
                // InitializeComponent explicitly in this test host.
                if (System.Windows.Application.Current == null)
                {
                    var app = new App();
                    app.InitializeComponent();
                }
                var session = new SessionContext();
                _ = new CommandsView(session, null!);
            }
            catch (Exception ex)
            {
                captured = ex;
            }
        });

        thread.SetApartmentState(ApartmentState.STA);
        thread.Start();
        thread.Join();

        Assert.Null(captured);
    }
}