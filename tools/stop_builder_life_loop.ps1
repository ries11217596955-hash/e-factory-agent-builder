param()

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$SessionRoot = Join-Path $RepoRoot "runtime_sessions/builder_life_loop/current"
$StopPath = Join-Path $SessionRoot "STOP_REQUESTED"

New-Item -ItemType Directory -Force -Path $SessionRoot | Out-Null
Set-Content -LiteralPath $StopPath -Value "STOP_REQUESTED_AT=$((Get-Date).ToUniversalTime().ToString('o'))" -Encoding UTF8
Write-Host "BUILDER_LIFE_LOOP_STOP_REQUESTED=$StopPath"
