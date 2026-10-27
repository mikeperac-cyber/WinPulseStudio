<#
.SYNOPSIS
    Ollama Local LLM Flash-Attention & KV-Cache Tuner (#023)
.DESCRIPTION
    Sets user environment variables for Ollama to enable Flash Attention and Q8_0 KV cache quantization for longer context windows in less VRAM.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [ValidateSet("f16", "q8_0", "q4_0")]
    [string]$KvCacheType = "q8_0",
    [int]$NumParallel = 2,
    [string]$KeepAlive = "15m"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=== [023] Ollama Local LLM Flash-Attention & KV-Cache Tuner ==="
$ollamaVars = @{
    "OLLAMA_FLASH_ATTENTION" = "1"
    "OLLAMA_KV_CACHE_TYPE"   = $KvCacheType
    "OLLAMA_NUM_PARALLEL"    = "$NumParallel"
    "OLLAMA_KEEP_ALIVE"      = $KeepAlive
}

foreach ($kv in $ollamaVars.GetEnumerator()) {
    $existing = [Environment]::GetEnvironmentVariable($kv.Key, "User")
    Write-Output ("{0}: Current='{1}' -> Target='{2}'" -f $kv.Key, $existing, $kv.Value)
}

if ($DryRun -or -not $PSCmdlet.ShouldProcess("User Environment Variables", "Configure Ollama Flash Attention & KV Cache")) {
    Write-Output "[DRY-RUN] Would update User environment variables for Ollama and restart ollama process if running."
    return
}

foreach ($kv in $ollamaVars.GetEnumerator()) {
    [Environment]::SetEnvironmentVariable($kv.Key, $kv.Value, "User")
    Set-Item -Path "Env:\$($kv.Key)" -Value $kv.Value
}

Write-Output "Configured Ollama environment variables successfully."
