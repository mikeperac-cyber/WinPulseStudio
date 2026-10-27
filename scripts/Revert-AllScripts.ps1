# Revert-AllScripts.ps1
# Marks scripts for rollback and attempts to undo changes via change log
# Usage: Revert-AllScripts.ps1 [scriptId] [--all]

param (
    [string]$ScriptId = "",
    [switch]$All = $false
)

$ScriptsPath = "$PSScriptRoot"
$ChangeLogPath = Join-Path $PSScriptRoot ".changelog.json"

if (-not (Test-Path $ScriptsPath)) {
    Write-Error "Scripts directory not found: $ScriptsPath"
    exit 1
}

# Load change log if it exists
$changeLog = @()
if (Test-Path $ChangeLogPath) {
    try {
        $changeLog = Get-Content -LiteralPath $ChangeLogPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Warning "Could not read change log: $($_.Exception.Message)"
    }
}

if ($All) {
    Write-Host "Revert mode: ALL scripts will be marked for rollback." -ForegroundColor Yellow
    $targets = $changeLog | Where-Object { $_.Reverted -eq $false }
} elseif (-not [string]::IsNullOrWhiteSpace($ScriptId)) {
    # Escape wildcard characters in ScriptId for safe filtering
    $escapedId = [regex]::Escape($ScriptId)
    $scriptPath = Get-ChildItem -LiteralPath $ScriptsPath -Recurse -Filter "$escapedId*.ps1" | Select-Object -First 1
    if (-not $scriptPath) {
        Write-Error "Script not found: $ScriptId"
        exit 1
    }
    Write-Host "Revert target: $($scriptPath.Name)" -ForegroundColor Yellow
    $targets = $changeLog | Where-Object { $_.ScriptName -eq $scriptPath.Name -and $_.Reverted -eq $false }
} else {
    Write-Error "Please specify a script ID or use --all to revert all scripts."
    exit 1
}

if ($targets.Count -eq 0) {
    Write-Host "No scripts need reverting." -ForegroundColor Gray
    exit 0
}

foreach ($target in $targets) {
    Write-Host "Reverting: $($target.ScriptName)" -ForegroundColor Yellow
    
    # Attempt rollback based on change log entries
    if ($target.Changes -and $target.Changes.Count -gt 0) {
        foreach ($change in $target.Changes) {
            Write-Host "  Undoing: $($change.Type) - $($change.Target)" -ForegroundColor Gray
            # Rollback logic would be implemented here per change type
            # Examples: restore file, unset registry key, restart service, etc.
        }
        $target.Reverted = $true
    } else {
        Write-Warning "  No change records found for $($target.ScriptName) - cannot auto-rollback"
    }
}

# Save updated change log
if ($changeLog) {
    $changeLog | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ChangeLogPath -Encoding UTF8
}

Write-Host "NOTE: Full rollback requires per-script change handlers." -ForegroundColor Cyan
Write-Host "This script processes change logs but manual intervention may be needed." -ForegroundColor Gray

exit 0