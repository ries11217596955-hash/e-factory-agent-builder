$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

$StepId = "PHASE124_BUILD_SELF_MODEL_FIRST_RUNTIME_ENTRYPOINT_V1"
$NextAllowed = "PHASE125_RUN_SELF_MODEL_FIRST_CONTROLLER_GOVERNED_TRIAL_V1"

$OutputPath = "self_build_batch/autonomy_trials/$StepId/SELF_MODEL_FIRST_RUNTIME_ENTRYPOINT_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($p in @(
  "modules/invoke_self_model_first_runtime_entrypoint.ps1",
  "orchestrator/run.ps1",
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
  $Output = Get-Content $OutputPath -Raw | ConvertFrom-Json
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json

  Write-Output "ENTRY_STATUS=$($Output.status)"
  Write-Output "ENTRY_MODE=$($Output.entry_mode)"
  Write-Output "ENTRY_CURRENT_NEED=$($Output.current_need)"
  Write-Output "ENTRY_NEXT=$($Output.proposed_next_step)"
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"

  if ($Output.status -ne "PASS") { Mark-Fail "ENTRY_NOT_PASS" }
  if ($Output.used_self_model_first -ne $true) { Mark-Fail "ENTRY_DID_NOT_USE_SELF_MODEL_FIRST" }
  if ($Output.current_need -ne "NEED_CONTROLLER_GOVERNED_SELF_BUILD_TRIAL") { Mark-Fail "ENTRY_NEED_UNEXPECTED=$($Output.current_need)" }
  if ($Output.proposed_next_step -ne $NextAllowed) { Mark-Fail "ENTRY_NEXT_UNEXPECTED=$($Output.proposed_next_step)" }
  if ($Output.replayed_controller_build_path -ne $false) { Mark-Fail "ENTRY_REPLAYED_CONTROLLER_BUILD_PATH" }
  if ($Queue.active_task_id -ne "NONE") { Mark-Fail "QUEUE_NOT_NONE=$($Queue.active_task_id)" }
} catch {
  Mark-Fail "ENTRY_VALIDATE_PARSE_FAIL=$($_.Exception.Message)"
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
  Write-Output "PHASE124_SELF_MODEL_FIRST_ENTRYPOINT_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE124_SELF_MODEL_FIRST_ENTRYPOINT_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE124 validation failed."
}
