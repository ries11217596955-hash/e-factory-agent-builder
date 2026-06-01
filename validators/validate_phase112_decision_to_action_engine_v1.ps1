$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

$StepId = "PHASE112_BUILD_DECISION_TO_ACTION_ENGINE_V1"
$NextAllowed = "PHASE113_BUILD_DECISION_ACTION_ADMISSION_BRIDGE_V1"

$ActionOutputPath = "self_build_batch/autonomy_trials/$StepId/DECISION_TO_ACTION_ENGINE_OUTPUT.json"
$ActionRequestPath = "self_build_batch/autonomy_trials/$StepId/ACTION_REQUEST.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($p in @(
  "modules/invoke_decision_to_action_engine.ps1",
  "modules/invoke_self_need_detection_engine.ps1",
  "orchestrator/run.ps1",
  $ActionOutputPath,
  $ActionRequestPath,
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
  $Action = Get-Content $ActionOutputPath -Raw | ConvertFrom-Json
  $Request = Get-Content $ActionRequestPath -Raw | ConvertFrom-Json

  Write-Output "ACTION_ENGINE_STATUS=$($Action.status)"
  Write-Output "ACTION_ENGINE_DECISION_ID=$($Action.decision_id)"
  Write-Output "ACTION_ENGINE_NEXT=$($Action.proposed_next_step)"
  Write-Output "ACTION_REQUEST_STATUS=$($Request.status)"
  Write-Output "ACTION_REQUEST_KIND=$($Request.action_kind)"
  Write-Output "ACTION_REQUEST_TARGET=$($Request.target_capability)"

  if ($Action.status -ne "PASS") { Mark-Fail "ACTION_ENGINE_NOT_PASS" }
  if ($Action.proposed_next_step -ne $NextAllowed) { Mark-Fail "ACTION_ENGINE_NEXT_UNEXPECTED=$($Action.proposed_next_step)" }
  if ($Request.status -ne "PASS") { Mark-Fail "ACTION_REQUEST_NOT_PASS" }
  if ($Request.action_kind -ne "BUILD_NEXT_CAPABILITY") { Mark-Fail "ACTION_KIND_UNEXPECTED=$($Request.action_kind)" }
  if ($Request.target_capability -ne "DECISION_ACTION_ADMISSION_BRIDGE") { Mark-Fail "TARGET_CAPABILITY_UNEXPECTED=$($Request.target_capability)" }
  if ($Request.manual_active_task_seed -ne $false) { Mark-Fail "MANUAL_ACTIVE_TASK_SEED_NOT_FALSE" }
} catch {
  Mark-Fail "ACTION_OUTPUT_PARSE_FAIL=$($_.Exception.Message)"
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
  Write-Output "PHASE112_DECISION_TO_ACTION_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE112_DECISION_TO_ACTION_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE112 decision-to-action validation failed."
}
