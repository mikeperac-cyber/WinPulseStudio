namespace WinPulseStudio.Services;

public static class RevertCatalog
{
    private static readonly Dictionary<string, string> Switches = new(StringComparer.OrdinalIgnoreCase)
    {
        ["002"] = "Revert",
        ["003"] = "EnableSysMain",
        ["007"] = "ResumeIndexer",
        ["008"] = "Revert",
        ["010"] = "EnableCapture",
        ["021"] = "RevertDefault",
        ["022"] = "DisableHags",
        ["028"] = "EnableWindowsAI",
        ["050"] = "ResetAllProxies",
        ["054"] = "Revert",
        ["061"] = "RestoreNotifications",
        ["065"] = "RestoreModernMenu",
        ["082"] = "RestoreBingSearch",
        ["086"] = "AllowUsbWrites",
        ["090"] = "RemoveShield"
    };

    public static string? GetRevertSwitch(string scriptId) =>
        Switches.TryGetValue(scriptId, out var name) ? name : null;
}
