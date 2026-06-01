$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

$StepId = "PHASE133_BUILD_SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_V1"
$NextAllowed = "PHASE134_BUILD_MATERIAL_ACQUISITION_BOOTSTRAP_V1"

$SelectorPath = "self_control/SELF_BUILD_OPERATION_CAPABILITY_SELECTOR.json"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($p in @(
  "modules/invoke_self_model_first_runtime_entrypoint.ps1",
  "modules/invoke_self_build_operation_capability_selector.ps1",
  "orchestrator/run.ps1",
  $SelectorPath,
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
  $Selector = Get-Content $SelectorPath -Raw | ConvertFrom-Json
  $Output = Get-Content $OutputPath -Raw | ConvertFrom-Json
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json

  Write-Output "SELECTOR_STATUS=$($Selector.status)"
  Write-Output "SELECTOR_ID=$($Selector.selector_id)"
  Write-Output "SELECTED_NEED=$($Selector.selected_need_id)"
  Write-Output "SELECTED_CAPABILITY=$($Selector.selected_capability_id)"
  Write-Output "SELECTED_NEXT=$($Selector.selected_next_step)"
  Write-Output "OUTPUT_STATUS=$($Output.status)"
  Write-Output "OUTPUT_NEXT=$($Output.proposed_next_step)"
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"

  if ($Selector.status -ne "PASS") { Mark-Fail "SELECTOR_NOT_PASS" }
  if ($Selector.selector_id -ne "SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_V1") { Mark-Fail "SELECTOR_ID_UNEXPECTED=$($Selector.selector_id)" }
  if ($Selector.selected_need_id -ne "NEED_MATERIAL_ACQUISITION_BOOTSTRAP") { Mark-Fail "SELECTOR_NEED_UNEXPECTED=$($Selector.selected_need_id)" }
  if ($Selector.selected_capability_id -ne "MATERIAL_ACQUISITION_BOOTSTRAP") { Mark-Fail "SELECTOR_CAPABILITY_UNEXPECTED=$($Selector.selected_capability_id)" }
  if ($Selector.selected_next_step -ne $NextAllowed) { Mark-Fail "SELECTOR_NEXT_UNEXPECTED=$($Selector.selected_next_step)" }
  if ($Output.status -ne "PASS") { Mark-Fail "OUTPUT_NOT_PASS" }
  if ($Output.selector_created -ne $true) { Mark-Fail "OUTPUT_SELECTOR_CREATED_NOT_TRUE" }
  if ($Output.proposed_next_step -ne $NextAllowed) { Mark-Fail "OUTPUT_NEXT_UNEXPECTED=$($Output.proposed_next_step)" }
  if ($Queue.active_task_id -ne "NONE") { Mark-Fail "QUEUE_NOT_NONE=$($Queue.active_task_id)" }
} catch {
  Mark-Fail "CAPABILITY_SELECTOR_VALIDATE_PARSE_FAIL=$($_.Exception.Message)"
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
  Write-Output "PHASE133_SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE133_SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE133 validation failed."
}
