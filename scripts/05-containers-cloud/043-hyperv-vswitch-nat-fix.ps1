<#
.SYNOPSIS
    Repair WSL2 / Hyper-V Host Network Service (HNS) (#043)
.DESCRIPTION
    Audits Host Network Service (hns) and virtual network adapters, restarting HNS if virtual NAT routing is wedged.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [043] Repair WSL2 / Hyper-V Host Network Service (HNS) ==="
$vAdapters = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match 'Hyper-V|WSL' }
foreach ($va in $vAdapters) {
    Write-Output ("vNIC: {0} | Status: {1} |Desc: {2}" -f $va.Name, $va.Status, $va.InterfaceDescription)
}

$hns = Get-Service -Name "hns" -ErrorAction SilentlyContinue
if ($hns) {
    Write-Output ("Host Network Service (hns) Status: {0}" -f $hns.Status)
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess("Host Network Service (hns)", "Restart-Service")) {
    Write-Output "[DRY-RUN] Would restart 'hns' service to rebuild WSL2/Docker virtual NAT tables."
    return
}

if ($hns) {
    Restart-Service -Name "hns" -Force
    Write-Output "Host Network Service (hns) restarted successfully."
}
