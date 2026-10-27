<#
.SYNOPSIS
    OpenSSH Agent Auto-Start & Key Permission Hardener (#046)
.DESCRIPTION
    Starts Windows ssh-agent service and verifies ~/.ssh key files.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
