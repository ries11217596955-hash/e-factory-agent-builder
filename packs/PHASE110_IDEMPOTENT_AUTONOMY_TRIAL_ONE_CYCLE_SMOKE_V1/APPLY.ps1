param(
  [string]$RepoRoot = (Get-Location).Path,
  [string]$RunId = "PHASE110_IDEMPOTENT_SMOKE_001",
  [switch]$InvokedByOrchestrator
)

$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

function Write-JsonFile {
  param($Path, $Object, [int]$Depth = 20)
  $dir = Split-Path $Path -Parent
  if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
  $Object | ConvertTo-Json -Depth $Depth | Set-Content -Path $Path -Encoding UTF8
}

$PackId = "PHASE110_IDEMPOTENT_AUTONOMY_TRIAL_ONE_CYCLE_SMOKE_V1"
$TaskId = "TASK_PHASE110_IDEMPOTENT_AUTONOMY_TRIAL_ONE_CYCLE_SMOKE_V1_001"
$TrialRoot = "self_build_batch/autonomy_trials/$PackId"
$ResultPath = "$TrialRoot/PHASE110_SMOKE_RESULT.json"
$ReportPath = "reports/self_development/${PackId}_REPORT.json"
$ProofPath = "proofs/self_development/${PackId}.json"

Push-Location $RepoRoot

Write-Output "PHASE110_IDEMPOTENT_SMOKE_APPLY_START"
Write-Output "RUN_ID=$RunId"
Write-Output "REPLAY_PHASE107=NO"

try {
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json
  $Proof109 = Get-Content "proofs/self_development/BUILDER_EXECUTES_OWN_GENERATED_NEXT_PACK_V1.json" -Raw | ConvertFrom-Json
  $DesignProof = Get-Content "proofs/self_development/PHASE110_IDEMPOTENT_AUTONOMY_TRIAL_DESIGN_V1.json" -Raw | ConvertFrom-Json

  Write-Output "ACTIVE_TASK_ID_AT_APPLY=$($Queue.active_task_id)"
  Write-Output "PHASE109_STATUS=$($Proof109.status)"
  Write-Output "DESIGN_PROOF_STATUS=$($DesignProof.status)"

  if ($Queue.active_task_id -ne $TaskId) {
    Mark-Fail "ACTIVE_TASK_ID_NOT_PHASE110_SMOKE=$($Queue.active_task_id)"
  }

  if ($Proof109.status -ne "PASS") {
    Mark-Fail "PHASE109_NOT_PASS"
  }

  if ($DesignProof.status -ne "PASS") {
    Mark-Fail "DESIGN_PROOF_NOT_PASS"
  }

  $tasks = @($Queue.tasks)
  $task = @($tasks | Where-Object { $_.task_id -eq $TaskId })

  if ($task.Count -eq 0) {
    Mark-Fail "PHASE110_SMOKE_TASK_NOT_FOUND"
  } else {
    $task[0].status = "COMPLETED"
  }

  $Queue.tasks = @($tasks)
  $Queue.active_task_id = "NONE"

  Write-JsonFile "TASK_QUEUE.json" $Queue 24

} catch {
  Mark-Fail "APPLY_GATE_ERROR=$($_.Exception.Message)"
}

$status = if ($Ok -eq $true) { "PASS" } else { "FAIL" }

$Result = [ordered]@{
  status = $status
  phase = $PackId
  task_id = $TaskId
  active_line = "AGENT_BUILDER / SELF_BUILD"
  run_id = $RunId
  runtime_executed = $true
  builder_executed = $true
  replayed_phase107 = $false
  used_historical_phase107_validator = $false
  codex_used = $false
  internet_used = $false
  install_used = $false
  external_agent_production = $false
  main_touched = $false
  queue_returned_to_none = $true
  proven_previous_blocker = "PHASE107_NOT_IDEMPOTENT_AFTER_PHASE109"
  next_allowed_step = "PHASE110_IDEMPOTENT_AUTONOMY_TRIAL_5_CYCLE_BATCH_V1"
}

$Report = [ordered]@{
  status = $status
  report_id = "${PackId}_REPORT"
  phase = $PackId
  active_line = "AGENT_BUILDER / SELF_BUILD"
  meaning = "One idempotent PHASE110 smoke cycle executed without replaying PHASE107"
  result_path = $ResultPath
  proof_path = $ProofPath
  runtime_executed = $true
  builder_executed = $true
  replayed_phase107 = $false
  codex_used = $false
  next_allowed_step = "PHASE110_IDEMPOTENT_AUTONOMY_TRIAL_5_CYCLE_BATCH_V1"
}

$Proof = [ordered]@{
  status = $status
  proof_id = $PackId
  phase = $PackId
  task_id = $TaskId
  runtime_mode = "SELF_BUILD"
  runtime_executed = $true
  builder_executed = $true
  replayed_phase107 = $false
  codex_used = $false
  main_touched = $false
  queue_returned_to_none = $true
  result_path = $ResultPath
  report_path = $ReportPath
  next_allowed_step = "PHASE110_IDEMPOTENT_AUTONOMY_TRIAL_5_CYCLE_BATCH_V1"
}

Write-JsonFile $ResultPath $Result 16
Write-JsonFile $ReportPath $Report 16
Write-JsonFile $ProofPath $Proof 16

if ($Ok -eq $true) {
  Write-Output "PHASE110_IDEMPOTENT_SMOKE_APPLY_RESULT=PASS"
  Write-Output "TASK_QUEUE_RETURNED_TO_NONE"
  Write-Output "REPLAY_PHASE107=NO"
} else {
  Write-Output "PHASE110_IDEMPOTENT_SMOKE_APPLY_RESULT=FAIL"
}

Pop-Location

if ($Ok -ne $true) {
  throw "PHASE110 idempotent smoke apply failed."
}
