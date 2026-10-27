# Revert-SpecificScript.ps1
# Marks a specific script for rollback of changes via change log
# Usage: Revert-SpecificScript.ps1 -ScriptId "001"

param (
    [Parameter(Mandatory = $true)]
    [string]$ScriptId
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

# Escape wildcard characters in ScriptId for safe filtering
$escapedId = [regex]::Escape($ScriptId)

# Find the script by ID prefix across all category directories
$matchingScripts = Get-ChildItem -LiteralPath $ScriptsPath -Recurse -Filter "$escapedId*.ps1"

if (-not $matchingScripts) {
    Write-Error "Script not found: $ScriptId"
    exit 1
}

# Warn if multiple scripts match the same ID prefix
if ($matchingScripts.Count -gt 1) {
    Write-Warning "Multiple scripts match ID '$ScriptId':"
    $matchingScripts | ForEach-Object { Write-Host "  - $($_.Name) [$($_.Directory.Name)]" -ForegroundColor Gray }
    $scriptPath = $matchingScripts | Select-Object -First 1
    Write-Warning "Using first match: $($scriptPath.Name)"
} else {
    $scriptPath = $matchingScripts | Select-Object -First 1
}

Write-Host "Revert target: $($scriptPath.Name) [$($scriptPath.Directory.Name)]" -ForegroundColor Yellow

# Find matching change log entries
$targets = $changeLog | Where-Object { $_.ScriptName -eq $scriptPath.Name -and $_.Reverted -eq $false }

if (-not $targets) {
    Write-Host "No change records found for $($scriptPath.Name). Nothing to revert." -ForegroundColor Gray
    exit 0
}

foreach ($target in $targets) {
    if ($target.Changes -and $target.Changes.Count -gt 0) {
        foreach ($change in $target.Changes) {
            Write-Host "  Undoing: $($change.Type) - $($change.Target)" -ForegroundColor Gray
        }
        $target.Reverted = $true
    } else {
        Write-Warning "  No change records found - cannot auto-rollback"
    }
}

# Save updated change log
if ($changeLog) {
    $changeLog | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ChangeLogPath -Encoding UTF8
}

Write-Host "NOTE: Full rollback requires per-script change handlers." -ForegroundColor Cyan
Write-Host "This script processes change logs but manual intervention may be needed." -ForegroundColor Gray

exit 0