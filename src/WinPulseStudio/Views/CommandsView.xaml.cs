using System.IO;
using System.Windows;
using System.Windows.Controls;
using WinPulseStudio.Models;
using WinPulseStudio.Services;

namespace WinPulseStudio.Views;

public partial class CommandsView : UserControl
{
    private readonly SessionContext _session;
    private List<CommandItem> _allCommands = [];
    private CommandItem? _selectedCommand;

    public CommandsView(SessionContext session, INavigator navigator)
    {
        _session = session;
        InitializeComponent();
        LoadCommands();
    }

    private void LoadCommands()
    {
        _allCommands = _session.Workspace.LoadCommands();
        ApplyFilters();

        if (_allCommands.Count == 0)
        {
            TxtEmptyCommands.Text = "The command reference could not be loaded. Reinstall the app or restore the commands folder.";
            _session.SetStatus("Command reference unavailable — commands/commands.json is missing or unreadable.");
            return;
        }

        _session.SetStatus($"Commands • {_allCommands.Count} basic PowerShell, winget, and cmd commands with plain-English explanations.");
    }

    private void ApplyFilters()
    {
        string query = TxtCommandSearch.Text.Trim();
        string shell = (CmbShell.SelectedItem as ComboBoxItem)?.Content?.ToString() ?? "All shells";

        IEnumerable<CommandItem> filtered = _allCommands;

        if (!string.IsNullOrEmpty(query))
        {
            filtered = filtered.Where(c => c.SearchText.Contains(query, StringComparison.OrdinalIgnoreCase));
        }

        if (!string.Equals(shell, "All shells", StringComparison.OrdinalIgnoreCase))
        {
            filtered = filtered.Where(c => string.Equals(c.Shell, shell, StringComparison.OrdinalIgnoreCase));
        }

        var visible = filtered.ToList();
        LstCommands.ItemsSource = visible;
        TxtEmptyCommands.Visibility = visible.Count == 0 && _allCommands.Count > 0
            ? Visibility.Visible
            : Visibility.Collapsed;

        if (LstCommands.Items.Count > 0)
        {
            LstCommands.SelectedIndex = 0;
        }
        else
        {
            _selectedCommand = null;
            ShowEmptySelection();
        }
    }

    private void TxtCommandSearch_TextChanged(object sender, TextChangedEventArgs e) => ApplyFilters();

    private void CmbShell_SelectionChanged(object sender, SelectionChangedEventArgs e) => ApplyFilters();

    private void LstCommands_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (LstCommands.SelectedItem is CommandItem command)
        {
            _selectedCommand = command;
            ShowCommand(command);
        }
    }

    private void ShowEmptySelection()
    {
        TxtDetailTitle.Text = "Select a command";
        TxtDetailMeta.Text = "What it does and how to use it appears here.";
        TxtDetailDescription.Text = string.Empty;
        TxtDetailCommand.Text = string.Empty;
        TxtDetailExample.Text = string.Empty;
        TxtExampleLabel.Visibility = Visibility.Collapsed;
        ExampleBorder.Visibility = Visibility.Collapsed;
        BtnCopyCommand.IsEnabled = false;
    }

    private void ShowCommand(CommandItem command)
    {
        TxtDetailTitle.Text = $"{command.ShellGlyph}  {command.Title}";
        TxtDetailMeta.Text = $"{command.Shell} • {command.Safety} • {(command.RequiresAdmin ? "Needs Administrator" : "Works as a normal user")}";
        TxtDetailDescription.Text = command.Description;

        TxtDetailCommand.Text = command.Command;

        bool hasExample = !string.IsNullOrWhiteSpace(command.Example)
            && !string.Equals(command.Example, command.Command, StringComparison.Ordinal);
        TxtDetailExample.Text = hasExample ? command.Example : string.Empty;
        TxtExampleLabel.Visibility = hasExample ? Visibility.Visible : Visibility.Collapsed;
        ExampleBorder.Visibility = hasExample ? Visibility.Visible : Visibility.Collapsed;

        BtnCopyCommand.IsEnabled = true;
    }

    private void BtnCopyCommand_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedCommand != null && !string.IsNullOrEmpty(_selectedCommand.Command))
        {
            Clipboard.SetText(_selectedCommand.Command);
            _session.SetStatus($"Copied '{_selectedCommand.Title}' command to clipboard. Paste it into PowerShell, winget, or cmd.");
        }
    }

    private void BtnCopyHelpTip_Click(object sender, RoutedEventArgs e)
    {
        if (_selectedCommand is { Shell: "PowerShell" } powerShellCommand)
        {
            Clipboard.SetText($"Get-Help {powerShellCommand.Title.Split(' ')[0]} -Examples");
            _session.SetStatus("Copied a Get-Help command — paste it into PowerShell to read the full manual page.");
            return;
        }

        Clipboard.SetText("winget --help");
        _session.SetStatus("Copied 'winget --help' — paste it into a terminal to see everything winget can do.");
    }
}