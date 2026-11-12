using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Media;
using WinPulseStudio.Models;

namespace WinPulseStudio.Views;

public sealed class GuideStepVm : INotifyPropertyChanged
{
    private string _statusText = "Not previewed";
    private Brush _statusBackground = Freeze(0x1E, 0x29, 0x3B);
    private Brush _statusForeground = Freeze(0x94, 0xA3, 0xB8);
    private bool _isDetailsOpen;
    private bool _isOutputOpen;
    private string _outputText = string.Empty;
    private bool _isPreviewed;
    private bool _isApplied;

    public GuideStepVm(ScriptItem script)
    {
        Script = script;
    }

    public ScriptItem Script { get; }

    public string DisplayId => Script.DisplayId;
    public string Name => Script.Name;
    public string SummaryText => Script.SummaryText;
    public string MetaLine => $"{Script.Category}  •  {Script.Impact} impact  •  ~{Script.EstimatedSeconds}s";
    public string AdminBadgeText => Script.AdminBadgeText;
    public string ModeBadgeText => Script.ModeBadgeText;
    public string PrereqText => Script.PrerequisitesText;
    public string PrereqLine => $"Before you start: {Script.PrerequisitesText}";
    public Visibility PrereqVisibility => Script.HasPrerequisites ? Visibility.Visible : Visibility.Collapsed;
    public bool HasWhatChanges => Script.HasWhatChanges;
    public bool HasHowToRevert => Script.HasHowToRevert;
    public List<string> WhatChanges => Script.WhatChanges;
    public string HowToRevert => Script.HowToRevert;

    public string StatusText
    {
        get => _statusText;
        private set
        {
            if (_statusText != value)
            {
                _statusText = value;
                OnPropertyChanged();
            }
        }
    }

    public Brush StatusBackground
    {
        get => _statusBackground;
        private set
        {
            _statusBackground = value;
            OnPropertyChanged();
        }
    }

    public Brush StatusForeground
    {
        get => _statusForeground;
        private set
        {
            _statusForeground = value;
            OnPropertyChanged();
        }
    }

    public bool IsDetailsOpen
    {
        get => _isDetailsOpen;
        set
        {
            if (_isDetailsOpen != value)
            {
                _isDetailsOpen = value;
                OnPropertyChanged();
            }
        }
    }

    public bool IsOutputOpen
    {
        get => _isOutputOpen;
        set
        {
            if (_isOutputOpen != value)
            {
                _isOutputOpen = value;
                OnPropertyChanged();
            }
        }
    }

    public string OutputText
    {
        get => _outputText;
        private set
        {
            _outputText = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(HasOutput));
        }
    }

    public bool HasOutput => !string.IsNullOrWhiteSpace(_outputText);

    public bool IsPreviewed
    {
        get => _isPreviewed;
        set
        {
            if (_isPreviewed != value)
            {
                _isPreviewed = value;
                OnPropertyChanged();
            }
        }
    }

    public bool IsApplied
    {
        get => _isApplied;
        set
        {
            if (_isApplied != value)
            {
                _isApplied = value;
                OnPropertyChanged();
            }
        }
    }

    public void SetStatus(string text, Color background, Color foreground)
    {
        StatusText = text;
        StatusBackground = new SolidColorBrush(background);
        StatusForeground = new SolidColorBrush(foreground);
    }

    public void SetNeutralStatus(string text) =>
        SetStatus(text, Color.FromRgb(0x1E, 0x29, 0x3B), Color.FromRgb(0x94, 0xA3, 0xB8));

    public void SetWorkingStatus(string text) =>
        SetStatus(text, Color.FromRgb(0x78, 0x35, 0x0F), Color.FromRgb(0xFD, 0xE0, 0x47));

    public void SetSuccessStatus(string text) =>
        SetStatus(text, Color.FromRgb(0x06, 0x4E, 0x3B), Color.FromRgb(0x6E, 0xE7, 0xB7));

    public void SetFailureStatus(string text) =>
        SetStatus(text, Color.FromRgb(0x7F, 0x1D, 0x1D), Color.FromRgb(0xFC, 0xA5, 0xA5));

    public void AppendOutput(string text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return;
        }

        OutputText = string.IsNullOrEmpty(OutputText)
            ? text.Trim()
            : OutputText + Environment.NewLine + text.Trim();
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }

    private static Brush Freeze(byte r, byte g, byte b)
    {
        var brush = new SolidColorBrush(Color.FromRgb(r, g, b));
        brush.Freeze();
        return brush;
    }
}

public sealed class AppliedRevertVm
{
    public string Title { get; init; } = string.Empty;
    public string Revert { get; init; } = string.Empty;
}
