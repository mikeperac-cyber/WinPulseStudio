<#
.SYNOPSIS
    Rescue Off-Screen Stranded Windows to Primary Display (#067)
.DESCRIPTION
    Finds visible main application windows and brings off-screen windows to (100, 100) on the primary screen via user32.dll SetWindowPos.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [067] Rescue Off-Screen Stranded Windows to Primary Display ==="
$windowProcs = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and -not [string]::IsNullOrWhiteSpace($_.MainWindowTitle) }
Write-Output ("Found {0} active top-level desktop windows:" -f @($windowProcs).Count)
foreach ($wp in $windowProcs) {
    Write-Output ("  [{0}] {1}" -f $wp.ProcessName, $wp.MainWindowTitle)
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess("Off-Screen Desktop Windows", "Cascade to Primary Monitor")) {
    Write-Output "[DRY-RUN] Would inspect window rectangles via user32.dll GetWindowRect and reposition off-screen windows."
    return
}

$win32 = @"
using System;
using System.Runtime.InteropServices;
public static class WinRescue {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
}
"@
if (-not ([System.Management.Automation.PSTypeName]'WinRescue').Type) {
    Add-Type -TypeDefinition $win32 -Language CSharp
}

$rescued = 0
foreach ($wp in $windowProcs) {
    $rect = New-Object WinRescue+RECT
    if ([WinRescue]::GetWindowRect($wp.MainWindowHandle, [ref]$rect)) {
        if ($rect.Left -lt -100 -or $rect.Top -lt -100) {
            [void][WinRescue]::SetWindowPos($wp.MainWindowHandle, [IntPtr]::Zero, 120, 120, 0, 0, 0x0001 -bor 0x0004)
            Write-Output "Rescued off-screen window: $($wp.MainWindowTitle)"
            $rescued++
        }
    }
}
Write-Output "Rescued $rescued off-screen window(s)."
