# Static Verifier for WinPulseStudio Scripts
# Validates all PowerShell scripts across all category directories

param (
    [string]$ScriptsPath = "$PSScriptRoot",
    [switch]$CheckSyntax = $true
)

$ErrorActionPreference = 'Continue'

Write-Host "Starting static verification of WinPulseStudio scripts..." -ForegroundColor Cyan

if (-not (Test-Path $ScriptsPath)) {
    Write-Error "Scripts directory not found: $ScriptsPath"
    exit 1
}

# Check PowerShell execution policy
$policy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned') {
    Write-Warning "PowerShell execution policy is '$policy'. Scripts may not run without policy change."
}

# Discover all script directories (01 through 10)
$categories = Get-ChildItem -LiteralPath $ScriptsPath -Directory | Sort-Object Name
$totalScripts = 0
$failedScripts = @()

foreach ($category in $categories) {
    $scripts = Get-ChildItem -LiteralPath $category.FullName -Filter "*.ps1" | Sort-Object Name
    
    foreach ($script in $scripts) {
        $totalScripts++
        Write-Host "  Validating: $($script.Name) [$($category.Name)]" -ForegroundColor Gray
        
        $issues = @()
        
        try {
            $content = Get-Content -LiteralPath $script.FullName -Raw -ErrorAction Stop
            if (-not $content -or $content.Trim() -eq '') {
                $issues += "Empty file"
            }
            
            # Syntax validation using PowerShell parser
            if ($CheckSyntax) {
                $errors = $null
                $nullTokens = $null
                [System.Management.Automation.Language.Parser]::ParseFile(
                    $script.FullName, 
                    [ref]$nullTokens, 
                    [ref]$errors
                ) | Out-Null
                
                if ($errors -and $errors.Count -gt 0) {
                    foreach ($err in $errors) {
                        $issues += "Line $($err.Extent.StartLineNumber): $($err.Message)"
                    }
                }
            }
        }
        catch {
            $issues += "READ ERROR: $($_.Exception.Message)"
        }
        
        if ($issues.Count -gt 0) {
            $failedScripts += [PSCustomObject]@{
                Name = $script.Name
                Category = $category.Name
                Issues = $issues
            }
            foreach ($issue in $issues) {
                Write-Warning "  [ISSUE] $($script.Name): $issue"
            }
        }
    }
}

Write-Host "`nVerification complete." -ForegroundColor Cyan
Write-Host "Total scripts scanned: $totalScripts" -ForegroundColor Gray

if ($failedScripts.Count -eq 0) {
    Write-Host "All scripts passed validation." -ForegroundColor Green
    exit 0
} else {
    Write-Warning "$($failedScripts.Count) script(s) had issues."
    $failedScripts | ForEach-Object { 
        Write-Host "  - $($_.Name) [$($_.Category)]" -ForegroundColor Red
        $_.Issues | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
    }
    exit 1
}