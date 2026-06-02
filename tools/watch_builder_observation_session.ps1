param(
  [string]$SessionId = "LIVE_AFTER_PHASE145_001",
  [int]$Iterations = 0,
  [int]$RefreshSeconds = 2,
  [int]$Tail = 5
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if ([string]::IsNullOrWhiteSpace($SessionId) -or $SessionId -match "[\\/:\*\?`"<>|]") {
  throw "INVALID_OBSERVATION_SESSION_ID=$SessionId"
}

$SessionRoot = Join-Path $RepoRoot "runtime_sessions/builder_life_loop/observations/$SessionId"
$Count = 0

while ($true) {
  $Count++
  Write-Host "BUILDER_OBSERVATION_SESSION_WATCH_TICK=$Count"
  Write-Host "OBSERVATION_SESSION_ID=$SessionId"
  Write-Host "OBSERVATION_SESSION_ROOT=$SessionRoot"

  foreach ($name in @("heartbeat.json", "life_loop_state.json", "learning_metrics.json", "session_summary.json")) {
    $path = Join-Path $SessionRoot $name
    if (Test-Path -LiteralPath $path) {
      Write-Host "READ=$name"
      Get-Content -LiteralPath $path -Raw
    } else {
      Write-Host "MISSING=$name"
    }
  }

  foreach ($name in @("observation_ledger.jsonl", "decision_trace.jsonl", "error_ledger.jsonl")) {
    $path = Join-Path $SessionRoot $name
    if (Test-Path -LiteralPath $path) {
      Write-Host "TAIL=$name"
      Get-Content -LiteralPath $path -Tail $Tail
    } else {
      Write-Host "MISSING=$name"
    }
  }

  if ($Iterations -gt 0 -and $Count -ge $Iterations) {
    break
  }

  Start-Sleep -Seconds $RefreshSeconds
}
