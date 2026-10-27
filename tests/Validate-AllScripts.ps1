<#
.SYNOPSIS
    Static AST, Cmdlet Resolution & Safety Verifier for all 100 WinPulse PowerShell Scripts.
.DESCRIPTION
    Uses [System.Management.Automation.Language.Parser]::ParseFile to statically verify
    syntax, tokens, CmdletBinding, -DryRun parameter, StrictMode, and command resolution
    across all 100 scripts WITHOUT executing any script.
#>
[CmdletBinding()]
param(
    [string]$WorkspaceRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$manifestPath = Join-Path $WorkspaceRoot "scripts\manifest.json"
if (-not (Test-Path $manifestPath)) {
    throw "Manifest not found at $manifestPath"
}

$manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
$scriptsList = @($manifest.scripts)

Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host " WinPulse Studio - Deep Static AST & Cmdlet Verifier (Zero Execution)   " -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host ("Total Scripts in Manifest: {0}" -f $scriptsList.Count)

$knownOptionalWindowsCmdlets = @(
    'Optimize-VHD',
    'Delete-DeliveryOptimizationCache',
    'Get-BitLockerVolume',
    'Confirm-SecureBootUEFI',
    'Get-Tpm',
    'Add-MpPreference',
    'Get-PnpDevice',
    'Get-NetTCPConnection',
    'Get-NetAdapter',
    'Get-NetRoute',
    'Get-NetIPInterface',
    'Get-NetFirewallProfile',
    'Get-NetFirewallRule',
    'Get-DnsClientServerAddress',
    'Set-DnsClientServerAddress',
    'Clear-DnsClientCache',
    'Get-SmbClientConfiguration',
    'Set-SmbClientConfiguration',
    'Get-Volume',
    'Optimize-Volume',
    'Get-PhysicalDisk',
    'Get-StorageReliabilityCounter',
    'Get-AppxPackage',
    'Remove-AppxPackage',
    'Enable-ComputerRestore',
    'Checkpoint-Computer',
    'Clear-RecycleBin'
)

$passed = 0
$failed = 0
$totalCommandsVerified = 0
$failures = [System.Collections.Generic.List[string]]::new()

foreach ($entry in $scriptsList) {
    $filePath = Join-Path $WorkspaceRoot ($entry.relativePath -replace '/', '\')
    if (-not (Test-Path $filePath)) {
        $failed++
        $failures.Add("[$($entry.id)] Missing file: $filePath")
        continue
    }

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $filePath,
        [ref]$tokens,
        [ref]$parseErrors
    )

    if ($parseErrors -and $parseErrors.Count -gt 0) {
        $failed++
        foreach ($err in $parseErrors) {
            $failures.Add("[$($entry.id)] Syntax Error at line $($err.Extent.StartLineNumber): $($err.Message)")
        }
        continue
    }

    # 1. Verify ParamBlock and -DryRun parameter
    if ($null -eq $ast.ParamBlock) {
        $failed++
        $failures.Add("[$($entry.id)] Missing ParamBlock in $filePath")
        continue
    }

    $hasDryRun = $false
    foreach ($p in $ast.ParamBlock.Parameters) {
        if ($p.Name.VariablePath.UserPath -eq 'DryRun') {
            $hasDryRun = $true
            break
        }
    }
    if (-not $hasDryRun) {
        $failed++
        $failures.Add("[$($entry.id)] Missing [switch]`$DryRun parameter in $filePath")
        continue
    }

    # 2. Verify CmdletBinding attribute
    $hasCmdletBinding = $false
    foreach ($attr in $ast.ParamBlock.Attributes) {
        if ($attr.TypeName.Name -eq 'CmdletBinding') {
            $hasCmdletBinding = $true
            break
        }
    }
    if (-not $hasCmdletBinding) {
        $failed++
        $failures.Add("[$($entry.id)] Missing [CmdletBinding()] attribute in $filePath")
        continue
    }

    # 3. Verify Set-StrictMode and Comment Help (.SYNOPSIS & .DESCRIPTION)
    $rawText = $ast.Extent.Text
    if ($rawText -notmatch '\.SYNOPSIS' -or $rawText -notmatch '\.DESCRIPTION') {
        $failed++
        $failures.Add("[$($entry.id)] Missing .SYNOPSIS or .DESCRIPTION help block")
        continue
    }
    if ($rawText -notmatch 'Set-StrictMode') {
        $failed++
        $failures.Add("[$($entry.id)] Missing Set-StrictMode declaration")
        continue
    }

    # 4. Verify all PowerShell Verb-Noun Cmdlets in AST exist or are known Windows OS module cmdlets
    $cmdAsts = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true)
    $cmdError = $false
    foreach ($cAst in $cmdAsts) {
        $cmdName = $cAst.GetCommandName()
        if ($cmdName -and $cmdName -match '^[A-Za-z]+-[A-Za-z0-9]+$') {
            $totalCommandsVerified++
            if ($cmdName -notin $knownOptionalWindowsCmdlets) {
                $resolved = Get-Command -Name $cmdName -ErrorAction SilentlyContinue
                if (-not $resolved) {
                    $cmdError = $true
                    $failures.Add("[$($entry.id)] Unrecognized PowerShell cmdlet: '$cmdName'")
                }
            }
        }
    }
    if ($cmdError) {
        $failed++
        continue
    }

    $passed++
}

Write-Host ("`nDeep AST Validation Complete: {0}/100 Scripts Passed | {1} Failed | {2} Cmdlet Invocations Verified" -f $passed, $failed, $totalCommandsVerified) -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

if ($failed -gt 0) {
    foreach ($f in $failures) {
        Write-Host "  FAIL: $f" -ForegroundColor Red
    }
    exit 1
}

Write-Host "All 100 PowerShell scripts passed deep AST syntax, Cmdlet resolution, and safety verification!" -ForegroundColor Green
exit 0
