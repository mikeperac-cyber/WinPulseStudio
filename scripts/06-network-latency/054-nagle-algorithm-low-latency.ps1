<#
.SYNOPSIS
    Disable Nagle's Algorithm (TcpAckFrequency & TCPNoDelay) (#054)
.DESCRIPTION
    Configures TcpAckFrequency=1 and TCPNoDelay=1 on active IPv4 Tcpip\Parameters\Interfaces keys.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$Revert
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [054] Disable Nagle's Algorithm (TcpAckFrequency & TCPNoDelay) ==="
$upNics = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
foreach ($nic in $upNics) {
    $ifGuid = $nic.InterfaceGuid
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$ifGuid"
    Write-Output ("Active NIC: {0} ({1})" -f $nic.Name, $ifGuid)
    if (-not $DryRun -and (Test-Path $regPath) -and $PSCmdlet.ShouldProcess($regPath, "Configure TCPNoDelay")) {
        if ($Revert) {
            Remove-ItemProperty -Path $regPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $regPath -Name "TCPNoDelay" -ErrorAction SilentlyContinue
            Write-Output "  Reverted Nagle settings on $($nic.Name)"
        } else {
            Set-ItemProperty -Path $regPath -Name "TcpAckFrequency" -Value 1 -Type DWord
            Set-ItemProperty -Path $regPath -Name "TCPNoDelay" -Value 1 -Type DWord
            Write-Output "  Enabled TCPNoDelay=1 & TcpAckFrequency=1 on $($nic.Name)"
        }
    }
}

if ($DryRun) {
    Write-Output "[DRY-RUN] Would set TcpAckFrequency=1 and TCPNoDelay=1 on $($upNics.Count) active interface(s)."
}
