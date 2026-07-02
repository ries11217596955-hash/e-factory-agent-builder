$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

$OfficialStepId = "PHASE111_BUILD_NEXT_ACTION_DECISION_KERNEL_V1"
$NextAllowed = "PHASE112_BUILD_DECISION_TO_ACTION_ENGINE_V1"

$EngineOutputPath = "self_build_batch/autonomy_trials/$OfficialStepId/SELF_NEED_DETECTION_ENGINE_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$OfficialStepId/${OfficialStepId}_RESULT.json"
$ReportPath = "reports/self_development/${OfficialStepId}_REPORT.json"
$ProofPath = "proofs/self_development/${OfficialStepId}.json"

foreach ($p in @(
  "modules/invoke_self_need_detection_engine.ps1",
  "orchestrator/run.ps1",
  $EngineOutputPath,
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
  $Engine = Get-Content $EngineOutputPath -Raw | ConvertFrom-Json
  Write-Output "ENGINE_STATUS=$($Engine.status)"
  Write-Output "ENGINE_DIAGNOSIS=$($Engine.diagnosis)"
  Write-Output "ENGINE_DETECTED_NEED=$($Engine.detected_need_id)"
  Write-Output "ENGINE_RECOMMENDED_NEXT_STEP=$($Engine.recommended_next_step)"

  if ($Engine.status -ne "PASS") { Mark-Fail "ENGINE_NOT_PASS" }
  if ($Engine.diagnosis -ne "MISSING_DECISION_TO_ACTION_CAPABILITY") { Mark-Fail "ENGINE_DIAGNOSIS_UNEXPECTED=$($Engine.diagnosis)" }
  if ($Engine.detected_need_id -ne "NEED_DECISION_TO_ACTION_ENGINE") { Mark-Fail "ENGINE_NEED_UNEXPECTED=$($Engine.detected_need_id)" }
  if ($Engine.recommended_next_step -ne $NextAllowed) { Mark-Fail "ENGINE_NEXT_STEP_UNEXPECTED=$($Engine.recommended_next_step)" }
} catch {
  Mark-Fail "ENGINE_OUTPUT_PARSE_FAIL=$($_.Exception.Message)"
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

if ($Ok -eq $true) {
  Write-Output "PHASE111_SELF_NEED_DETECTION_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE111_SELF_NEED_DETECTION_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE111 self-need detection validation failed."
}
