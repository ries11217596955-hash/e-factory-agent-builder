$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

$StepId = "PHASE127_BUILD_SELF_BUILD_OPERATION_CONTRACT_V1"
$NextAllowed = "PHASE128_RUN_SELF_BUILD_OPERATION_CONTRACT_SMOKE_V1"

$ContractPath = "self_control/SELF_BUILD_OPERATION_CONTRACT.json"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/SELF_BUILD_OPERATION_CONTRACT_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($p in @(
  "modules/invoke_self_model_first_runtime_entrypoint.ps1",
  "modules/invoke_self_build_operation_contract.ps1",
  "orchestrator/run.ps1",
  $ContractPath,
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
  $Contract = Get-Content $ContractPath -Raw | ConvertFrom-Json
  $Output = Get-Content $OutputPath -Raw | ConvertFrom-Json
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json

  Write-Output "CONTRACT_STATUS=$($Contract.status)"
  Write-Output "CONTRACT_ID=$($Contract.contract_id)"
  Write-Output "OUTPUT_STATUS=$($Output.status)"
  Write-Output "OUTPUT_CONTRACT_CREATED=$($Output.contract_created)"
  Write-Output "OUTPUT_NEXT=$($Output.proposed_next_step)"
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"

  if ($Contract.status -ne "PASS") { Mark-Fail "CONTRACT_NOT_PASS" }
  if ($Contract.contract_id -ne "SELF_BUILD_OPERATION_CONTRACT_V1") { Mark-Fail "CONTRACT_ID_UNEXPECTED=$($Contract.contract_id)" }
  if ($Contract.require_proof_before_next_phase -eq $false) { Mark-Fail "CONTRACT_PROOF_GATE_FALSE" }
  if ($Output.status -ne "PASS") { Mark-Fail "OUTPUT_NOT_PASS" }
  if ($Output.contract_created -ne $true) { Mark-Fail "OUTPUT_CONTRACT_CREATED_NOT_TRUE" }
  if ($Output.proposed_next_step -ne $NextAllowed) { Mark-Fail "OUTPUT_NEXT_UNEXPECTED=$($Output.proposed_next_step)" }
  if ($Queue.active_task_id -ne "NONE") { Mark-Fail "QUEUE_NOT_NONE=$($Queue.active_task_id)" }
} catch {
  Mark-Fail "CONTRACT_VALIDATE_PARSE_FAIL=$($_.Exception.Message)"
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
  Write-Output "PHASE127_SELF_BUILD_OPERATION_CONTRACT_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE127_SELF_BUILD_OPERATION_CONTRACT_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE127 validation failed."
}
