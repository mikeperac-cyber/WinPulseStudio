<#
.SYNOPSIS
    Toggle Fast Startup & Hibernation Space Saver (#016)
.DESCRIPTION
    Controls HiberbootEnabled and hiberfil.sys type (Reduced / Full / Off).
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [ValidateSet("ReducedForFastStartupOnly", "DisableHibernationReclaimDisk", "FullHibernation")]
    [string]$Mode = "ReducedForFastStartupOnly"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [016] Toggle Fast Startup & Hibernation Space Saver ==="
$hiberFile = "C:\hiberfil.sys"
if (Test-Path -LiteralPath $hiberFile) {
    $item = Get-Item -LiteralPath $hiberFile -Force
    Write-Output ("Current hiberfil.sys size: {0} GB" -f [math]::Round($item.Length / 1GB, 2))
} else {
    Write-Output "hiberfil.sys is currently not present."
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess("PowerCfg Hibernation", "Apply mode $Mode")) {
    Write-Output "[DRY-RUN] Would configure hibernation mode: $Mode."
    return
}

switch ($Mode) {
    "ReducedForFastStartupOnly" {
        & powercfg.exe /hibernate on
        & powercfg.exe /h /type reduced
        Write-Output "Hibernation set to Reduced (~50% smaller hiberfil.sys)."
    }
    "DisableHibernationReclaimDisk" {
        & powercfg.exe /hibernate off
        Write-Output "Hibernation and Fast Startup disabled; hiberfil.sys space reclaimed."
    }
    "FullHibernation" {
        & powercfg.exe /hibernate on
        & powercfg.exe /h /type full
        Write-Output "Full hibernation enabled."
    }
}
