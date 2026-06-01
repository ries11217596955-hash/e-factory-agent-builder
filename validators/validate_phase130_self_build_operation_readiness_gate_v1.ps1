$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

$StepId = "PHASE130_BUILD_SELF_BUILD_OPERATION_READINESS_GATE_V1"
$NextAllowed = "PHASE131_RUN_CONTRACT_GOVERNED_SELF_BUILD_OPERATION_TRIAL_V1"

$GatePath = "self_control/SELF_BUILD_OPERATION_READINESS_GATE.json"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/SELF_BUILD_OPERATION_READINESS_GATE_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($p in @(
  "modules/invoke_self_model_first_runtime_entrypoint.ps1",
  "modules/invoke_self_build_operation_readiness_gate.ps1",
  "orchestrator/run.ps1",
  $GatePath,
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
  $Gate = Get-Content $GatePath -Raw | ConvertFrom-Json
  $Output = Get-Content $OutputPath -Raw | ConvertFrom-Json
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json

  Write-Output "GATE_STATUS=$($Gate.status)"
  Write-Output "GATE_ID=$($Gate.gate_id)"
  Write-Output "GATE_DECISION=$($Gate.decision)"
  Write-Output "GATE_NEXT=$($Gate.allowed_next_step)"
  Write-Output "OUTPUT_STATUS=$($Output.status)"
  Write-Output "OUTPUT_DECISION=$($Output.decision)"
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"

  if ($Gate.status -ne "PASS") { Mark-Fail "GATE_NOT_PASS" }
  if ($Gate.gate_id -ne "SELF_BUILD_OPERATION_READINESS_GATE_V1") { Mark-Fail "GATE_ID_UNEXPECTED=$($Gate.gate_id)" }
  if ($Gate.decision -ne "READY_FOR_CONTRACT_GOVERNED_SELF_BUILD_OPERATION_TRIAL") { Mark-Fail "GATE_DECISION_UNEXPECTED=$($Gate.decision)" }
  if ($Gate.allowed_next_step -ne $NextAllowed) { Mark-Fail "GATE_NEXT_UNEXPECTED=$($Gate.allowed_next_step)" }
  if ($Output.status -ne "PASS") { Mark-Fail "OUTPUT_NOT_PASS" }
  if ($Output.gate_created -ne $true) { Mark-Fail "OUTPUT_GATE_CREATED_NOT_TRUE" }
  if ($Output.proposed_next_step -ne $NextAllowed) { Mark-Fail "OUTPUT_NEXT_UNEXPECTED=$($Output.proposed_next_step)" }
  if ($Queue.active_task_id -ne "NONE") { Mark-Fail "QUEUE_NOT_NONE=$($Queue.active_task_id)" }
} catch {
  Mark-Fail "READINESS_GATE_VALIDATE_PARSE_FAIL=$($_.Exception.Message)"
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
  Write-Output "PHASE130_SELF_BUILD_OPERATION_READINESS_GATE_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE130_SELF_BUILD_OPERATION_READINESS_GATE_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE130 validation failed."
}
