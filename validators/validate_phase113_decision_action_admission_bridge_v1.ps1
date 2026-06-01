$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

$StepId = "PHASE113_BUILD_DECISION_ACTION_ADMISSION_BRIDGE_V1"
$NextAllowed = "PHASE114_BUILD_ADMITTED_ACTION_EXECUTION_ENGINE_V1"

$AdmissionOutputPath = "self_build_batch/autonomy_trials/$StepId/DECISION_ACTION_ADMISSION_BRIDGE_OUTPUT.json"
$AdmissionRecordPath = "self_build_batch/autonomy_trials/$StepId/ACTION_ADMISSION_RECORD.json"
$AdmittedActionPath = "self_build_batch/autonomy_trials/$StepId/ADMITTED_ACTION.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($p in @(
  "modules/invoke_decision_action_admission_bridge.ps1",
  "modules/invoke_decision_to_action_engine.ps1",
  "modules/invoke_self_need_detection_engine.ps1",
  "orchestrator/run.ps1",
  $AdmissionOutputPath,
  $AdmissionRecordPath,
  $AdmittedActionPath,
  $ResultPath,
  $ReportPath,
  $ProofPath
)) {
  if (-not (Test-Path $p)) {
    Mark-Fail "MISSING=$p"
  } else {
    Write-Output "EXISTS=$p"
  }
}

try {
  $Output = Get-Content $AdmissionOutputPath -Raw | ConvertFrom-Json
  $Record = Get-Content $AdmissionRecordPath -Raw | ConvertFrom-Json
  $Action = Get-Content $AdmittedActionPath -Raw | ConvertFrom-Json

  Write-Output "ADMISSION_STATUS=$($Output.status)"
  Write-Output "ADMISSION_ID=$($Output.admission_id)"
  Write-Output "ADMITTED_ACTION_ID=$($Output.admitted_action_id)"
  Write-Output "ADMISSION_NEXT=$($Output.proposed_next_step)"
  Write-Output "ADMISSION_EXECUTED=$($Output.executed)"
  Write-Output "ADMISSION_QUEUE_MUTATED=$($Output.queue_mutated)"
  Write-Output "ADMITTED_ACTION_TARGET=$($Action.target_capability)"

  if ($Output.status -ne "PASS") { Mark-Fail "ADMISSION_OUTPUT_NOT_PASS" }
  if ($Output.admitted -ne $true) { Mark-Fail "ADMISSION_NOT_TRUE" }
  if ($Output.executed -ne $false) { Mark-Fail "ADMISSION_EXECUTED_NOT_FALSE" }
  if ($Output.queue_mutated -ne $false) { Mark-Fail "ADMISSION_QUEUE_MUTATED_NOT_FALSE" }
  if ($Output.proposed_next_step -ne $NextAllowed) { Mark-Fail "ADMISSION_NEXT_UNEXPECTED=$($Output.proposed_next_step)" }
  if ($Record.status -ne "PASS") { Mark-Fail "ADMISSION_RECORD_NOT_PASS" }
  if ($Action.status -ne "PASS") { Mark-Fail "ADMITTED_ACTION_NOT_PASS" }
  if ($Action.target_capability -ne "ADMITTED_ACTION_EXECUTION_ENGINE") { Mark-Fail "ADMITTED_ACTION_TARGET_UNEXPECTED=$($Action.target_capability)" }
} catch {
  Mark-Fail "ADMISSION_PARSE_FAIL=$($_.Exception.Message)"
}

foreach ($p in @($ResultPath, $ReportPath, $ProofPath)) {
  try {
    $obj = Get-Content $p -Raw | ConvertFrom-Json
    Write-Output "JSON_PARSE_PASS=$p"
    Write-Output "STATUS=$($obj.status)"
    Write-Output "NEXT_ALLOWED_STEP=$($obj.next_allowed_step)"

    if ($obj.status -ne "PASS") { Mark-Fail "OUTPUT_NOT_PASS=$p" }
    if ($obj.next_allowed_step -ne $NextAllowed) { Mark-Fail "OUTPUT_NEXT_STEP_UNEXPECTED=$p :: $($obj.next_allowed_step)" }
  } catch {
    Mark-Fail "JSON_PARSE_FAIL=$p :: $($_.Exception.Message)"
  }
}

try {
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"
  if ($Queue.active_task_id -ne "NONE") { Mark-Fail "QUEUE_NOT_NONE=$($Queue.active_task_id)" }
} catch {
  Mark-Fail "QUEUE_PARSE_FAIL=$($_.Exception.Message)"
}

if ($Ok -eq $true) {
  Write-Output "PHASE113_ADMISSION_BRIDGE_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE113_ADMISSION_BRIDGE_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE113 admission bridge validation failed."
}
