param(
  [string]$SessionId = "LIVE_AFTER_PHASE145_001"
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if ([string]::IsNullOrWhiteSpace($SessionId) -or $SessionId -match "[\\/:\*\?`"<>|]") {
  throw "INVALID_OBSERVATION_SESSION_ID=$SessionId"
}

$SessionRoot = Join-Path $RepoRoot "runtime_sessions/builder_life_loop/observations/$SessionId"
if (-not (Test-Path -LiteralPath $SessionRoot)) {
  New-Item -ItemType Directory -Force -Path $SessionRoot | Out-Null
}

$StopPath = Join-Path $SessionRoot "STOP_REQUESTED"
$Content = "STOP_REQUESTED_AT=$((Get-Date).ToUniversalTime().ToString("o"))`nOBSERVATION_SESSION_ID=$SessionId`n"
[System.IO.File]::WriteAllText($StopPath, $Content, [System.Text.UTF8Encoding]::new($false))

Write-Host "BUILDER_OBSERVATION_STOP_REQUESTED=True"
Write-Host "OBSERVATION_SESSION_ID=$SessionId"
Write-Host "STOP_FILE=$StopPath"
