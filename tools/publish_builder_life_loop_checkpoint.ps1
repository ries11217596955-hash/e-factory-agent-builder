param(
  [int]$Cycle = 5,
  [switch]$Commit
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$SessionRoot = Join-Path $RepoRoot "runtime_sessions/builder_life_loop/current"
$CheckpointRoot = Join-Path $SessionRoot "checkpoints"
$CheckpointName = "checkpoint_{0:D3}.json" -f $Cycle
$CheckpointPath = Join-Path $CheckpointRoot $CheckpointName

Set-Location $RepoRoot
New-Item -ItemType Directory -Force -Path $CheckpointRoot | Out-Null

$SummaryPath = Join-Path $SessionRoot "session_summary.json"
$HeartbeatPath = Join-Path $SessionRoot "heartbeat.json"
$StatePath = Join-Path $SessionRoot "life_loop_state.json"

$Checkpoint = [ordered]@{
  status = "PASS"
  checkpoint_id = [System.IO.Path]::GetFileNameWithoutExtension($CheckpointName)
  cycle = $Cycle
  heartbeat_path = "runtime_sessions/builder_life_loop/current/heartbeat.json"
  life_loop_state_path = "runtime_sessions/builder_life_loop/current/life_loop_state.json"
  session_summary_path = "runtime_sessions/builder_life_loop/current/session_summary.json"
  heartbeat_exists = (Test-Path -LiteralPath $HeartbeatPath)
  life_loop_state_exists = (Test-Path -LiteralPath $StatePath)
  session_summary_exists = (Test-Path -LiteralPath $SummaryPath)
  published_at = (Get-Date).ToUniversalTime().ToString("o")
}

$json = ($Checkpoint | ConvertTo-Json -Depth 50) -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($CheckpointPath, "$json`n", [System.Text.UTF8Encoding]::new($false))

Write-Host "BUILDER_LIFE_LOOP_CHECKPOINT_PUBLISHED=$CheckpointPath"

if ($Commit) {
  git add -- $CheckpointPath
  git commit -m "Publish builder life loop checkpoint $Cycle"
}
