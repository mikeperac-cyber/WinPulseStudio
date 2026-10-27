<#
.SYNOPSIS
    NPU, GPU & DirectML Accelerator Inventory (#030)
.DESCRIPTION
    Queries Win32_VideoController and PnP ComputeAccelerator / Display devices to report AI compute capabilities.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [030] NPU, GPU & DirectML Accelerator Inventory ==="
$gpus = Get-CimInstance -ClassName Win32_VideoController
foreach ($g in $gpus) {
    Write-Output ("[GPU] {0} | Driver: {1} | Status: {2}" -f $g.Name, $g.DriverVersion, $g.Status)
}

$npus = Get-PnpDevice -Class "ComputeAccelerator" -ErrorAction SilentlyContinue
if ($npus) {
    foreach ($n in $npus) {
        Write-Output ("[NPU/ComputeAccelerator] {0} | Status: {1} | InstanceId: {2}" -f $n.FriendlyName, $n.Status, $n.InstanceId)
    }
} else {
    Write-Output "[NPU] No dedicated PnP ComputeAccelerator class device detected (using GPU DirectML/CUDA)."
}
