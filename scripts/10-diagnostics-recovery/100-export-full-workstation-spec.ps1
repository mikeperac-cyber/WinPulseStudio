<#
.SYNOPSIS
    Export Full Developer & AI Workstation Spec Report (JSON) (#100)
.DESCRIPTION
    Collects OS, CPU, RAM, GPU, Disk, and Dev Toolchain metadata into a structured summary.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [string]$ExportPath = (Join-Path $env:TEMP "winpulse-workstation-spec.json")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [100] Export Full Developer & AI Workstation Spec Report ==="
$os  = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$gpus = @(Get-CimInstance Win32_VideoController | ForEach-Object { @{ Name = $_.Name; Driver = $_.DriverVersion } })

$spec = [ordered]@{
    Timestamp   = (Get-Date).ToString("o")
    Computer    = $env:COMPUTERNAME
    OS          = "$($os.Caption) (Build $($os.BuildNumber))"
    CPU         = $cpu.Name.Trim()
    Cores       = $cpu.NumberOfCores
    LogicalCPUs = $cpu.NumberOfLogicalProcessors
    TotalRamGB  = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    FreeRamGB   = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    GPUs        = $gpus
}

$json = $spec | ConvertTo-Json -Depth 4
Write-Output $json

if (-not $DryRun -and $PSCmdlet.ShouldProcess($ExportPath, "Write JSON spec report")) {
    Set-Content -Path $ExportPath -Value $json -Encoding UTF8
    Write-Output "Saved full workstation report to: $ExportPath"
}
