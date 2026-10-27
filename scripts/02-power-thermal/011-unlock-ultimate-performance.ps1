<#
.SYNOPSIS
    Unlock & Activate Ultimate Performance Plan (#011)
.DESCRIPTION
    Duplicates the Ultimate Performance GUID if not already present and sets it as the active Windows power scheme.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [011] Unlock & Activate Ultimate Performance Plan ==="
$ultimateGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
$schemes = & powercfg.exe /list
$schemes | ForEach-Object { Write-Output $_ }

if ($DryRun -or -not $PSCmdlet.ShouldProcess("PowerCfg", "Duplicate and activate Ultimate Performance ($ultimateGuid)")) {
    Write-Output "[DRY-RUN] Would run: powercfg -duplicatescheme $ultimateGuid and activate it."
    return
}

$dupOutput = & powercfg.exe -duplicatescheme $ultimateGuid 2>&1
Write-Output $dupOutput
if ($dupOutput -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
    $newGuid = $Matches[1]
    & powercfg.exe /setactive $newGuid
    Write-Output "Activated Ultimate Performance scheme: $newGuid"
}
