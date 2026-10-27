<#
.SYNOPSIS
    Kubernetes ~/.kube/config Context & Cluster Auditor (#045)
.DESCRIPTION
    Audits ~/.kube/config size, contexts, and kubectl client status.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [045] Kubernetes ~/.kube/config Context & Cluster Auditor ==="
$kubeConfig = Join-Path $env:USERPROFILE ".kube\config"
if (-not (Test-Path $kubeConfig)) {
    Write-Output "No ~/.kube/config file found on this workstation."
    return
}

$item = Get-Item $kubeConfig
Write-Output ("Found kubeconfig: {0} ({1} KB, LastModified: {2})" -f $item.FullName, [math]::Round($item.Length / 1KB, 1), $item.LastWriteTime)

if (Get-Command "kubectl" -ErrorAction SilentlyContinue) {
    & kubectl config get-contexts
}
