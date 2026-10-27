<#
.SYNOPSIS
    Generate Isolated Windows Sandbox (.wsb) Profile (#044)
.DESCRIPTION
    Creates a disposable DevSandbox.wsb file with vGPU enabled and a read-only mapped host folder.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [string]$OutputPath = (Join-Path $env:USERPROFILE "Desktop\WinPulse-DevSandbox.wsb")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [044] Generate Isolated Windows Sandbox (.wsb) Profile ==="
$wsbXml = @"
<Configuration>
  <VGpu>Enable</VGpu>
  <Networking>Enable</Networking>
  <MemoryInMB>8192</MemoryInMB>
  <ClipboardRedirection>Enable</ClipboardRedirection>
  <MappedFolders>
    <MappedFolder>
      <HostFolder>$PSScriptRoot</HostFolder>
      <SandboxFolder>C:\Users\WDAGUtilityAccount\Desktop\SharedScripts</SandboxFolder>
      <ReadOnly>true</ReadOnly>
    </MappedFolder>
  </MappedFolders>
</Configuration>
"@

if ($DryRun -or -not $PSCmdlet.ShouldProcess($OutputPath, "Write .wsb Sandbox profile")) {
    Write-Output "[DRY-RUN] Would create Windows Sandbox profile at: $OutputPath"
    return
}

Set-Content -Path $OutputPath -Value $wsbXml -Encoding UTF8
Write-Output "Created Windows Sandbox configuration: $OutputPath"
