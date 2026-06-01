$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

function Read-JsonOrFail {
  param([string]$Path)

  try {
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  } catch {
    Mark-Fail "JSON_PARSE_FAIL=$Path :: $($_.Exception.Message)"
    return $null
  }
}

function Test-PropertyExists {
  param(
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object) {
    return $false
  }

  return $null -ne ($Object.PSObject.Properties | Where-Object { $_.Name -eq $Name } | Select-Object -First 1)
}

function Get-PropertyValue {
  param(
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object) {
    return $null
  }

  $property = $Object.PSObject.Properties | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
  if ($null -eq $property) {
    return $null
  }

  return $property.Value
}

function Assert-Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    Mark-Fail "$Name`_UNEXPECTED=$Actual EXPECTED=$Expected"
  }
}

function Assert-FalseProperty {
  param(
    [object]$Object,
    [string]$PropertyName,
    [string]$Context
  )

  if (Test-PropertyExists -Object $Object -Name $PropertyName) {
    $value = Get-PropertyValue -Object $Object -Name $PropertyName
    if ($value -ne $false) {
      Mark-Fail "$Context`_$PropertyName`_NOT_FALSE=$value"
    }
  }
}

function Assert-NoForbiddenRuntimeFlags {
  param(
    [object]$Object,
    [string]$Context
  )

  foreach ($propertyName in @(
    "production_adoption_allowed",
    "trusted",
    "external_fetch_performed",
    "dependency_install_performed",
    "executable_materials_used",
    "executable_used",
    "wrapper_created",
    "smoke_test_executed"
  )) {
    Assert-FalseProperty -Object $Object -PropertyName $propertyName -Context $Context
  }
}

$StepId = "PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_V1"
$RunId = "PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_001"
$PreviousStepId = "PHASE138A_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_V1"
$NextAllowed = "PHASE138C_SANDBOX_BRANCH_MERGE_DECISION_V1"
$ExpectedSelectedMaterialId = "candidate_pester_powershell_test_framework"

$PreviousProofPath = "proofs/self_development/${PreviousStepId}.json"
$DecisionResultPath = "materials/AUTONOMOUS_MATERIAL_DECISION_RESULT.json"
$ErrorLedgerPath = "materials/AUTONOMOUS_MATERIAL_DECISION_ERROR_LEDGER.json"
$ReviewPath = "materials/AUTONOMOUS_MATERIAL_DECISION_REVIEW.json"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/AUTONOMOUS_MATERIAL_DECISION_REVIEW_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$RuntimeLogPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RUNTIME_LOG.txt"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($p in @(
  "modules/invoke_review_autonomous_material_decision_stress_results_001.ps1",
  "orchestrator/run.ps1",
  $PreviousProofPath,
  $DecisionResultPath,
  $ErrorLedgerPath,
  $ReviewPath,
  $OutputPath,
  $ResultPath,
  $RuntimeLogPath,
  $ReportPath,
  $ProofPath
)) {
  if (-not (Test-Path -LiteralPath $p)) {
    Mark-Fail "MISSING=$p"
  } else {
    Write-Output "EXISTS=$p"
  }
}

$PreviousProof = Read-JsonOrFail -Path $PreviousProofPath
$DecisionResult = Read-JsonOrFail -Path $DecisionResultPath
$ErrorLedger = Read-JsonOrFail -Path $ErrorLedgerPath
$Review = Read-JsonOrFail -Path $ReviewPath
$Output = Read-JsonOrFail -Path $OutputPath
$Result = Read-JsonOrFail -Path $ResultPath
$Report = Read-JsonOrFail -Path $ReportPath
$Proof = Read-JsonOrFail -Path $ProofPath
$Queue = Read-JsonOrFail -Path "TASK_QUEUE.json"

try {
  $RuntimeLog = Get-Content -LiteralPath $RuntimeLogPath -Raw
  foreach ($requiredSignal in @(
    "AUTONOMOUS_MATERIAL_DECISION_REVIEW=PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_001",
    "REVIEW_STATUS=PASS",
    "REVIEW_SELECTED_MATERIAL=candidate_pester_powershell_test_framework",
    "REVIEW_DATASET_RECORD_COUNT=300",
    "REVIEW_POLICY_VIOLATION_COUNT=30",
    "REVIEW_VIOLATION_SUM=30",
    "REVIEW_PRODUCTION_ADOPTION_ALLOWED=False",
    "REVIEW_TRUSTED=False",
    "REVIEW_EXTERNAL_FETCH_PERFORMED=False",
    "REVIEW_DEPENDENCY_INSTALL_PERFORMED=False",
    "REVIEW_EXECUTABLE_USED=False",
    "REVIEW_NEXT_STEP=PHASE138C_SANDBOX_BRANCH_MERGE_DECISION_V1",
    "STATUS=PASS_STOPPED_AUTONOMOUS_MATERIAL_DECISION_REVIEW_BUILT"
  )) {
    if ($RuntimeLog -notmatch [regex]::Escape($requiredSignal)) {
      Mark-Fail "RUNTIME_LOG_SIGNAL_MISSING=$requiredSignal"
    } else {
      Write-Output "RUNTIME_LOG_SIGNAL_PRESENT=$requiredSignal"
    }
  }
} catch {
  Mark-Fail "RUNTIME_LOG_READ_FAIL=$($_.Exception.Message)"
}

try {
  $Branch = (git rev-parse --abbrev-ref HEAD).Trim()
  Write-Output "GIT_BRANCH=$Branch"
  if ($Branch -eq "main") {
    Mark-Fail "MAIN_BRANCH_ACTIVE"
  }
} catch {
  Mark-Fail "GIT_BRANCH_READ_FAIL=$($_.Exception.Message)"
}

if ($null -ne $PreviousProof) {
  Write-Output "PREVIOUS_PROOF_STATUS=$($PreviousProof.status)"
  Write-Output "PREVIOUS_PROOF_NEXT=$($PreviousProof.next_allowed_step)"
  Assert-Equals -Actual $PreviousProof.status -Expected "PASS" -Name "PREVIOUS_PROOF_STATUS"
  Assert-Equals -Actual $PreviousProof.next_allowed_step -Expected $StepId -Name "PREVIOUS_PROOF_NEXT_ALLOWED_STEP"
  Assert-Equals -Actual $PreviousProof.stress_dataset_record_count -Expected 300 -Name "PREVIOUS_PROOF_DATASET_COUNT"
  Assert-Equals -Actual $PreviousProof.autonomous_selected_count -Expected 1 -Name "PREVIOUS_PROOF_SELECTED_COUNT"
  Assert-Equals -Actual $PreviousProof.trusted_material_count -Expected 0 -Name "PREVIOUS_PROOF_TRUSTED_COUNT"
  Assert-NoForbiddenRuntimeFlags -Object $PreviousProof -Context "PREVIOUS_PROOF"
}

if ($null -ne $DecisionResult) {
  Write-Output "DECISION_STATUS=$($DecisionResult.status)"
  Write-Output "DECISION_SELECTED_MATERIAL=$($DecisionResult.selected_material_id)"
  Assert-Equals -Actual $DecisionResult.status -Expected "PASS" -Name "DECISION_STATUS"
  Assert-Equals -Actual $DecisionResult.selected_material_id -Expected $ExpectedSelectedMaterialId -Name "DECISION_SELECTED_MATERIAL"
  Assert-Equals -Actual $DecisionResult.selected_count -Expected 1 -Name "DECISION_SELECTED_COUNT"
  Assert-Equals -Actual $DecisionResult.policy_violation_count -Expected 30 -Name "DECISION_POLICY_VIOLATION_COUNT"
  Assert-Equals -Actual $DecisionResult.trusted_material_count -Expected 0 -Name "DECISION_TRUSTED_COUNT"
  Assert-NoForbiddenRuntimeFlags -Object $DecisionResult -Context "DECISION"
}

if ($null -ne $ErrorLedger) {
  Write-Output "LEDGER_STATUS=$($ErrorLedger.status)"
  Write-Output "LEDGER_POLICY_VIOLATION_COUNT=$($ErrorLedger.policy_violation_count)"
  Assert-Equals -Actual $ErrorLedger.status -Expected "PASS" -Name "LEDGER_STATUS"
  Assert-Equals -Actual $ErrorLedger.dataset_record_count -Expected 300 -Name "LEDGER_DATASET_RECORD_COUNT"
  Assert-Equals -Actual $ErrorLedger.selected_count -Expected 1 -Name "LEDGER_SELECTED_COUNT"
  Assert-Equals -Actual $ErrorLedger.policy_violation_count -Expected 30 -Name "LEDGER_POLICY_VIOLATION_COUNT"
  Assert-NoForbiddenRuntimeFlags -Object $ErrorLedger -Context "LEDGER"
}

if ($null -ne $Review) {
  Write-Output "REVIEW_STATUS=$($Review.status)"
  Write-Output "REVIEW_SELECTED_MATERIAL=$($Review.selected_material_id)"
  Write-Output "REVIEW_VIOLATION_SUM=$($Review.violation_sum)"

  Assert-Equals -Actual $Review.status -Expected "PASS" -Name "REVIEW_STATUS"
  Assert-Equals -Actual $Review.selected_material_id -Expected $ExpectedSelectedMaterialId -Name "REVIEW_SELECTED_MATERIAL"
  Assert-Equals -Actual $Review.selected_material_accepted_for_sandbox_review -Expected $true -Name "REVIEW_ACCEPTED_FOR_SANDBOX"
  Assert-Equals -Actual $Review.stress_dataset_record_count -Expected 300 -Name "REVIEW_DATASET_COUNT"
  Assert-Equals -Actual $Review.selected_count -Expected 1 -Name "REVIEW_SELECTED_COUNT"
  Assert-Equals -Actual $Review.policy_violation_count -Expected 30 -Name "REVIEW_POLICY_VIOLATION_COUNT"
  Assert-Equals -Actual $Review.violation_sum -Expected 30 -Name "REVIEW_VIOLATION_SUM"
  Assert-Equals -Actual $Review.trusted_material_count -Expected 0 -Name "REVIEW_TRUSTED_COUNT"
  Assert-Equals -Actual $Review.next_allowed_step -Expected $NextAllowed -Name "REVIEW_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenRuntimeFlags -Object $Review -Context "REVIEW"

  foreach ($className in @(
    "malformed_or_incomplete_records",
    "duplicate_or_conflict_records",
    "false_trust_attempts_detected",
    "forbidden_fetch_attempts_detected",
    "forbidden_install_attempts_detected",
    "forbidden_executable_attempts_detected"
  )) {
    if (-not (Test-PropertyExists -Object $Review.error_classes -Name $className)) {
      Mark-Fail "REVIEW_ERROR_CLASS_MISSING=$className"
    }
  }
}

foreach ($artifactSpec in @(
  @{ Name = "OUTPUT"; Object = $Output },
  @{ Name = "RESULT"; Object = $Result },
  @{ Name = "REPORT"; Object = $Report },
  @{ Name = "PROOF"; Object = $Proof }
)) {
  $artifactName = $artifactSpec.Name
  $artifact = $artifactSpec.Object
  if ($null -eq $artifact) {
    continue
  }

  Write-Output "$artifactName`_STATUS=$($artifact.status)"
  Write-Output "$artifactName`_NEXT_ALLOWED_STEP=$($artifact.next_allowed_step)"
  Assert-Equals -Actual $artifact.status -Expected "PASS" -Name "$artifactName`_STATUS"
  Assert-Equals -Actual $artifact.next_allowed_step -Expected $NextAllowed -Name "$artifactName`_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenRuntimeFlags -Object $artifact -Context $artifactName

  if (Test-PropertyExists -Object $artifact -Name "selected_material_id") {
    Assert-Equals -Actual $artifact.selected_material_id -Expected $ExpectedSelectedMaterialId -Name "$artifactName`_SELECTED_MATERIAL"
  }
  if (Test-PropertyExists -Object $artifact -Name "stress_dataset_record_count") {
    Assert-Equals -Actual $artifact.stress_dataset_record_count -Expected 300 -Name "$artifactName`_DATASET_COUNT"
  }
  if (Test-PropertyExists -Object $artifact -Name "selected_count") {
    Assert-Equals -Actual $artifact.selected_count -Expected 1 -Name "$artifactName`_SELECTED_COUNT"
  }
  if (Test-PropertyExists -Object $artifact -Name "policy_violation_count") {
    Assert-Equals -Actual $artifact.policy_violation_count -Expected 30 -Name "$artifactName`_POLICY_VIOLATION_COUNT"
  }
  if (Test-PropertyExists -Object $artifact -Name "violation_sum") {
    Assert-Equals -Actual $artifact.violation_sum -Expected 30 -Name "$artifactName`_VIOLATION_SUM"
  }
  if (Test-PropertyExists -Object $artifact -Name "trusted_material_count") {
    Assert-Equals -Actual $artifact.trusted_material_count -Expected 0 -Name "$artifactName`_TRUSTED_COUNT"
  }
}

if ($null -ne $Proof) {
  Assert-Equals -Actual $Proof.runtime_executed -Expected $true -Name "PROOF_RUNTIME_EXECUTED"
  Assert-Equals -Actual $Proof.builder_runtime_invoked -Expected $true -Name "PROOF_BUILDER_RUNTIME_INVOKED"
  Assert-Equals -Actual $Proof.reviewed_previous_phase -Expected $PreviousStepId -Name "PROOF_REVIEWED_PREVIOUS_PHASE"
  Assert-Equals -Actual $Proof.queue_after -Expected "NONE" -Name "PROOF_QUEUE_AFTER"
  Assert-Equals -Actual $Proof.codex_used -Expected $false -Name "PROOF_CODEX_USED"
  Assert-Equals -Actual $Proof.main_touched -Expected $false -Name "PROOF_MAIN_TOUCHED"
}

if ($null -ne $Queue) {
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"
  Assert-Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "TASK_QUEUE_ACTIVE_TASK_ID"
}

if ($Ok -eq $true) {
  Write-Output "PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE138B validation failed."
}
