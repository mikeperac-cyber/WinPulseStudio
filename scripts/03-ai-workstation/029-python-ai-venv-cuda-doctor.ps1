<#
.SYNOPSIS
    Python AI Toolchain, CUDA & ONNX Doctor (#029)
.DESCRIPTION
    Read-only diagnostic of Python, uv, CUDA toolkit environment variables, nvcc, and local LLM CLIs.
.EXAMPLE
    .\029-python-ai-venv-cuda-doctor.ps1 -DryRun

    Simulates the change without modifying the system.

    .\029-python-ai-venv-cuda-doctor.ps1

    Applies the change. Some scripts require Administrator; see the catalog prerequisites.

#>
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [029] Python AI Toolchain, CUDA & ONNX Doctor ==="
$tools = @('python', 'uv', 'pip', 'conda', 'nvcc', 'ollama', 'nvidia-smi')
foreach ($t in $tools) {
    $cmd = Get-Command $t -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Output ("[FOUND] {0,-12} -> {1}" -f $t, $cmd.Source)
    } else {
        Write-Output ("[MISS ] {0,-12} -> Not on PATH" -f $t)
    }
}

Write-Output "`n--- CUDA Environment Variables ---"
Get-ChildItem Env: | Where-Object { $_.Name -match '^CUDA|^CUDNN|^OLLAMA|^HF_' } | ForEach-Object {
    Write-Output ("  {0} = {1}" -f $_.Name, $_.Value)
}
