$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

$StepId = "PHASE132_BUILD_OPERATION_TRIAL_AWARE_SELF_MODEL_ADVANCE_V1"
$NextAllowed = "PHASE133_BUILD_SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_V1"

$SelfModelPath = "self_model/BUILDER_SELF_MODEL.json"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/OPERATION_TRIAL_AWARE_SELF_MODEL_ADVANCE_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($p in @(
  "modules/invoke_operation_trial_aware_self_model_advance.ps1",
  "orchestrator/run.ps1",
  $SelfModelPath,
  $OutputPath,
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
  $SelfModel = Get-Content $SelfModelPath -Raw | ConvertFrom-Json
  $Output = Get-Content $OutputPath -Raw | ConvertFrom-Json
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json
  $closed = @($SelfModel.closed_needs)

  Write-Output "SELF_MODEL_STATUS=$($SelfModel.status)"
  Write-Output "SELF_MODEL_ID=$($SelfModel.self_model_id)"
  Write-Output "SELF_MODEL_CURRENT_NEED=$($SelfModel.current_detected_need)"
  Write-Output "SELF_MODEL_NEXT=$($SelfModel.recommended_next_step)"
  Write-Output "OUTPUT_STATUS=$($Output.status)"
  Write-Output "OUTPUT_CLOSED_NEED=$($Output.closed_need)"
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"

  if ($SelfModel.status -ne "PASS") { Mark-Fail "SELF_MODEL_NOT_PASS" }
  if ($SelfModel.operation_trial_aware -ne $true) { Mark-Fail "SELF_MODEL_NOT_OPERATION_TRIAL_AWARE" }
  if ($closed -notcontains "NEED_SELF_BUILD_OPERATION_READINESS_GATE") { Mark-Fail "CLOSED_NEED_MISSING_NEED_SELF_BUILD_OPERATION_READINESS_GATE" }
  if ($SelfModel.current_detected_need -ne "NEED_SELF_BUILD_OPERATION_CAPABILITY_SELECTOR") { Mark-Fail "SELF_MODEL_NEED_UNEXPECTED=$($SelfModel.current_detected_need)" }
  if ($SelfModel.recommended_next_step -ne $NextAllowed) { Mark-Fail "SELF_MODEL_NEXT_UNEXPECTED=$($SelfModel.recommended_next_step)" }
  if ($Output.status -ne "PASS") { Mark-Fail "OUTPUT_NOT_PASS" }
  if ($Output.closed_need -ne "NEED_SELF_BUILD_OPERATION_READINESS_GATE") { Mark-Fail "OUTPUT_CLOSED_NEED_UNEXPECTED=$($Output.closed_need)" }
  if ($Output.proposed_next_step -ne $NextAllowed) { Mark-Fail "OUTPUT_NEXT_UNEXPECTED=$($Output.proposed_next_step)" }
  if ($Queue.active_task_id -ne "NONE") { Mark-Fail "QUEUE_NOT_NONE=$($Queue.active_task_id)" }
} catch {
  Mark-Fail "OPERATION_TRIAL_AWARE_VALIDATE_PARSE_FAIL=$($_.Exception.Message)"
}

foreach ($p in @($ResultPath,$ReportPath,$ProofPath)) {
  try {
    $obj = Get-Content $p -Raw | ConvertFrom-Json
    Write-Output "JSON_PARSE_PASS=$p"
    Write-Output "STATUS=$($obj.status)"
    Write-Output "NEXT_ALLOWED_STEP=$($obj.next_allowed_step)"

    if ($obj.status -ne "PASS") { Mark-Fail "OUTPUT_ARTIFACT_NOT_PASS=$p" }
    if ($obj.next_allowed_step -ne $NextAllowed) { Mark-Fail "OUTPUT_ARTIFACT_NEXT_UNEXPECTED=$p :: $($obj.next_allowed_step)" }
  } catch {
    Mark-Fail "JSON_PARSE_FAIL=$p :: $($_.Exception.Message)"
  }
}

if ($Ok -eq $true) {
  Write-Output "PHASE132_OPERATION_TRIAL_AWARE_SELF_MODEL_ADVANCE_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE132_OPERATION_TRIAL_AWARE_SELF_MODEL_ADVANCE_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE132 validation failed."
}
