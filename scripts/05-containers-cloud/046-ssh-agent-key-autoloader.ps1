<#
.SYNOPSIS
    OpenSSH Agent Auto-Start & Key Permission Hardener (#046)
.DESCRIPTION
    Starts Windows ssh-agent service and verifies ~/.ssh key files.
.EXAMPLE
    .\046-ssh-agent-key-autoloader.ps1 -DryRun

    Simulates the change without modifying the system.

    .\046-ssh-agent-key-autoloader.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Fail fast with a structured error instead of a raw PowerShell dump, so the
# calling app can record exactly what went wrong.
trap {
    Write-Output ("[ERROR] Script failed: " + $_.Exception.Message)
    exit 1
}

Write-Output "=== [046] OpenSSH Agent Auto-Start & Key Permission Hardener ==="
$sshDir = Join-Path $env:USERPROFILE ".ssh"
if (Test-Path $sshDir) {
    $keys = Get-ChildItem -Path $sshDir -File | Where-Object { $_.Name -match '^id_' -and $_.Extension -ne '.pub' }
    Write-Output ("Found {0} SSH private key(s) in {1}" -f @($keys).Count, $sshDir)
}

$svc = Get-Service -Name "ssh-agent" -ErrorAction SilentlyContinue
if (-not $svc) {
    Write-Output "OpenSSH Authentication Agent service is not installed."
    return
}
Write-Output ("Current ssh-agent status: {0} (StartType: {1})" -f $svc.Status, $svc.StartType)

if ($DryRun -or -not $PSCmdlet.ShouldProcess("ssh-agent Service", "Set StartupType Automatic and Start")) {
    Write-Output "[DRY-RUN] Would set ssh-agent StartupType=Automatic and start the service."
    return
}

Set-Service -Name "ssh-agent" -StartupType Automatic
Start-Service -Name "ssh-agent"
Write-Output "OpenSSH Agent service started and set to Automatic."
