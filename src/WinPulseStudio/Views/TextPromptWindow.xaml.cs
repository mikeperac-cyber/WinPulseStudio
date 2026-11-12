using System.Windows;
using System.Windows.Input;

namespace WinPulseStudio.Views;

public partial class TextPromptWindow : Window
{
    public string ResponseText { get; private set; } = string.Empty;

    public TextPromptWindow(string title, string prompt, string initialValue = "")
    {
        InitializeComponent();
        Title = title;
        TxtPrompt.Text = prompt;
        TxtInput.Text = initialValue;
        Loaded += (_, _) =>
        {
            TxtInput.Focus();
            TxtInput.SelectAll();
        };
    }

    private void BtnOk_Click(object sender, RoutedEventArgs e)
    {
        ResponseText = TxtInput.Text;
        DialogResult = true;
    }

    private void BtnCancel_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
    }

    private void TxtInput_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Escape)
        {
            DialogResult = false;
        }
    }
}
