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

function As-Array {
  param([object]$Value)

  if ($null -eq $Value) {
    return @()
  }
  if ($Value -is [System.Array]) {
    return $Value
  }
  return @($Value)
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
    "external_fetch_performed",
    "dependency_install_performed",
    "executable_materials_used",
    "executable_used",
    "wrapper_created",
    "smoke_test_executed",
    "production_adoption_allowed",
    "trusted"
  )) {
    Assert-FalseProperty -Object $Object -PropertyName $propertyName -Context $Context
  }
}

function Assert-ContainsAll {
  param(
    [string[]]$Actual,
    [string[]]$Expected,
    [string]$Name
  )

  foreach ($ExpectedValue in $Expected) {
    if ($Actual -notcontains $ExpectedValue) {
      Mark-Fail "$Name`_MISSING=$ExpectedValue"
    }
  }
}

$StepId = "PHASE138A_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_V1"
$RunId = "PHASE138A_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_001"
$PreviousStepId = "PHASE137_BUILD_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_V1"
$ExpectedPreviousNextStep = "PHASE138_OWNER_DECISION_FOR_FIRST_MATERIAL_ADOPTION_V1"
$NextAllowed = "PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_V1"
$ExpectedKnownCandidateIds = @(
  "candidate_pester_powershell_test_framework",
  "candidate_psscriptanalyzer_static_checker",
  "candidate_syft_sbom_cli"
)

$PreviousProofPath = "proofs/self_development/${PreviousStepId}.json"
$DatasetPath = "materials/MATERIAL_DECISION_STRESS_DATASET_300.json"
$DecisionResultPath = "materials/AUTONOMOUS_MATERIAL_DECISION_RESULT.json"
$ErrorLedgerPath = "materials/AUTONOMOUS_MATERIAL_DECISION_ERROR_LEDGER.json"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$RuntimeLogPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RUNTIME_LOG.txt"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($p in @(
  "modules/invoke_autonomous_material_decision_stress_lab_001.ps1",
  "orchestrator/run.ps1",
  $PreviousProofPath,
  $DatasetPath,
  $DecisionResultPath,
  $ErrorLedgerPath,
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
$Dataset = Read-JsonOrFail -Path $DatasetPath
$DecisionResult = Read-JsonOrFail -Path $DecisionResultPath
$ErrorLedger = Read-JsonOrFail -Path $ErrorLedgerPath
$Output = Read-JsonOrFail -Path $OutputPath
$Result = Read-JsonOrFail -Path $ResultPath
$Report = Read-JsonOrFail -Path $ReportPath
$Proof = Read-JsonOrFail -Path $ProofPath
$Queue = Read-JsonOrFail -Path "TASK_QUEUE.json"

try {
  $RuntimeLog = Get-Content -LiteralPath $RuntimeLogPath -Raw
  foreach ($requiredSignal in @(
    "AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB=PHASE138A_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_001",
    "STRESS_DATASET_RECORD_COUNT=300",
    "AUTONOMOUS_SELECTED_COUNT=1",
    "OWNER_DELEGATED_SANDBOX_DECISION=True",
    "OWNER_MANUAL_PICK=False",
    "PRODUCTION_ADOPTION_ALLOWED=False",
    "MATERIAL_TRUSTED_COUNT=0",
    "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
    "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
    "MATERIAL_EXECUTABLE_USED=False",
    "MATERIAL_WRAPPER_CREATED=False",
    "MATERIAL_SMOKE_TEST_EXECUTED=False",
    "AUTONOMOUS_DECISION_NEXT_STEP=PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_V1",
    "STATUS=PASS_STOPPED_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_BUILT"
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
  Assert-Equals -Actual $PreviousProof.next_allowed_step -Expected $ExpectedPreviousNextStep -Name "PREVIOUS_PROOF_NEXT_ALLOWED_STEP"
  Assert-Equals -Actual $PreviousProof.evaluated_material_count -Expected 3 -Name "PREVIOUS_PROOF_EVALUATED_COUNT"
  Assert-Equals -Actual $PreviousProof.trusted_material_count -Expected 0 -Name "PREVIOUS_PROOF_TRUSTED_COUNT"
  Assert-FalseProperty -Object $PreviousProof -PropertyName "external_fetch_performed" -Context "PREVIOUS_PROOF"
  Assert-FalseProperty -Object $PreviousProof -PropertyName "dependency_install_performed" -Context "PREVIOUS_PROOF"
  Assert-FalseProperty -Object $PreviousProof -PropertyName "executable_materials_used" -Context "PREVIOUS_PROOF"
}

if ($null -ne $Dataset) {
  $Records = As-Array -Value $Dataset.records
  $RecordIds = @($Records | ForEach-Object { "$($_.material_id)" })
  $LowRisk = @($Records | Where-Object { $_.risk_level -eq "LOW" })
  $MediumRisk = @($Records | Where-Object { $_.risk_level -eq "MEDIUM" })
  $HighRisk = @($Records | Where-Object { $_.risk_level -eq "HIGH" })
  $Malformed = @($Records | Where-Object { $_.malformed_or_incomplete -eq $true })
  $DuplicateOrConflict = @($Records | Where-Object { $_.duplicate_or_conflict -eq $true })
  $KnownCandidates = @($Records | Where-Object { $_.known_phase137_candidate -eq $true })

  Write-Output "DATASET_RECORD_COUNT=$(@($Records).Count)"
  Write-Output "DATASET_LOW_RISK_COUNT=$(@($LowRisk).Count)"
  Write-Output "DATASET_MEDIUM_RISK_COUNT=$(@($MediumRisk).Count)"
  Write-Output "DATASET_HIGH_RISK_COUNT=$(@($HighRisk).Count)"
  Write-Output "DATASET_MALFORMED_COUNT=$(@($Malformed).Count)"
  Write-Output "DATASET_DUPLICATE_OR_CONFLICT_COUNT=$(@($DuplicateOrConflict).Count)"

  Assert-Equals -Actual @($Records).Count -Expected 300 -Name "DATASET_RECORD_COUNT"
  Assert-Equals -Actual $Dataset.record_count -Expected 300 -Name "DATASET_REPORTED_RECORD_COUNT"
  if (@($LowRisk).Count -lt 30) { Mark-Fail "LOW_RISK_COUNT_LT_30=$(@($LowRisk).Count)" }
  if (@($MediumRisk).Count -lt 30) { Mark-Fail "MEDIUM_RISK_COUNT_LT_30=$(@($MediumRisk).Count)" }
  if (@($HighRisk).Count -lt 30) { Mark-Fail "HIGH_RISK_COUNT_LT_30=$(@($HighRisk).Count)" }
  if (@($Malformed).Count -lt 20) { Mark-Fail "MALFORMED_COUNT_LT_20=$(@($Malformed).Count)" }
  if (@($DuplicateOrConflict).Count -lt 20) { Mark-Fail "DUPLICATE_OR_CONFLICT_COUNT_LT_20=$(@($DuplicateOrConflict).Count)" }
  if (@($KnownCandidates).Count -lt 3) { Mark-Fail "KNOWN_PHASE137_CANDIDATE_COUNT_LT_3=$(@($KnownCandidates).Count)" }
  Assert-ContainsAll -Actual $RecordIds -Expected $ExpectedKnownCandidateIds -Name "DATASET_KNOWN_CANDIDATE_IDS"
  Assert-FalseProperty -Object $Dataset -PropertyName "external_fetch_performed" -Context "DATASET"
  Assert-FalseProperty -Object $Dataset -PropertyName "dependency_install_performed" -Context "DATASET"
  Assert-FalseProperty -Object $Dataset -PropertyName "executable_materials_used" -Context "DATASET"
}

if ($null -ne $DecisionResult) {
  Write-Output "DECISION_STATUS=$($DecisionResult.status)"
  Write-Output "DECISION_SELECTED_COUNT=$($DecisionResult.selected_count)"
  Write-Output "DECISION_SELECTED_MATERIAL=$($DecisionResult.selected_material_id)"

  Assert-Equals -Actual $DecisionResult.status -Expected "PASS" -Name "DECISION_STATUS"
  Assert-Equals -Actual $DecisionResult.selected_count -Expected 1 -Name "DECISION_SELECTED_COUNT"
  Assert-Equals -Actual $DecisionResult.owner_delegated_sandbox_decision -Expected $true -Name "DECISION_OWNER_DELEGATED"
  Assert-Equals -Actual $DecisionResult.selected_by_builder -Expected $true -Name "DECISION_SELECTED_BY_BUILDER"
  Assert-Equals -Actual $DecisionResult.owner_manual_pick -Expected $false -Name "DECISION_OWNER_MANUAL_PICK"
  Assert-Equals -Actual $DecisionResult.adoption_scope -Expected "SANDBOX_DECISION_ONLY" -Name "DECISION_ADOPTION_SCOPE"
  Assert-Equals -Actual $DecisionResult.trusted_material_count -Expected 0 -Name "DECISION_TRUSTED_COUNT"
  Assert-Equals -Actual $DecisionResult.next_allowed_step -Expected $NextAllowed -Name "DECISION_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenRuntimeFlags -Object $DecisionResult -Context "DECISION"
}

if ($null -ne $ErrorLedger) {
  Write-Output "LEDGER_STATUS=$($ErrorLedger.status)"
  Write-Output "LEDGER_DATASET_RECORD_COUNT=$($ErrorLedger.dataset_record_count)"
  Write-Output "LEDGER_SELECTED_COUNT=$($ErrorLedger.selected_count)"

  Assert-Equals -Actual $ErrorLedger.status -Expected "PASS" -Name "LEDGER_STATUS"
  Assert-Equals -Actual $ErrorLedger.dataset_record_count -Expected 300 -Name "LEDGER_DATASET_RECORD_COUNT"
  Assert-Equals -Actual $ErrorLedger.selected_count -Expected 1 -Name "LEDGER_SELECTED_COUNT"
  if ($ErrorLedger.invalid_record_count -lt 20) { Mark-Fail "LEDGER_INVALID_RECORD_COUNT_LT_20=$($ErrorLedger.invalid_record_count)" }
  if ($ErrorLedger.duplicate_or_conflict_count -lt 20) { Mark-Fail "LEDGER_DUPLICATE_OR_CONFLICT_COUNT_LT_20=$($ErrorLedger.duplicate_or_conflict_count)" }
  if ($ErrorLedger.policy_violation_count -lt 1) { Mark-Fail "LEDGER_POLICY_VIOLATION_COUNT_LT_1=$($ErrorLedger.policy_violation_count)" }
  if ($ErrorLedger.false_trust_attempt_count -lt 1) { Mark-Fail "LEDGER_FALSE_TRUST_ATTEMPT_COUNT_LT_1=$($ErrorLedger.false_trust_attempt_count)" }
  if ($ErrorLedger.forbidden_fetch_attempt_count -lt 1) { Mark-Fail "LEDGER_FORBIDDEN_FETCH_ATTEMPT_COUNT_LT_1=$($ErrorLedger.forbidden_fetch_attempt_count)" }
  if ($ErrorLedger.forbidden_install_attempt_count -lt 1) { Mark-Fail "LEDGER_FORBIDDEN_INSTALL_ATTEMPT_COUNT_LT_1=$($ErrorLedger.forbidden_install_attempt_count)" }
  if ($ErrorLedger.forbidden_executable_attempt_count -lt 1) { Mark-Fail "LEDGER_FORBIDDEN_EXECUTABLE_ATTEMPT_COUNT_LT_1=$($ErrorLedger.forbidden_executable_attempt_count)" }
  if ($ErrorLedger.unknown_license_count -lt 1) { Mark-Fail "LEDGER_UNKNOWN_LICENSE_COUNT_LT_1=$($ErrorLedger.unknown_license_count)" }
  if ($ErrorLedger.missing_provenance_count -lt 1) { Mark-Fail "LEDGER_MISSING_PROVENANCE_COUNT_LT_1=$($ErrorLedger.missing_provenance_count)" }
  Assert-Equals -Actual $ErrorLedger.next_allowed_step -Expected $NextAllowed -Name "LEDGER_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenRuntimeFlags -Object $ErrorLedger -Context "LEDGER"
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

  if (Test-PropertyExists -Object $artifact -Name "stress_dataset_record_count") {
    Assert-Equals -Actual $artifact.stress_dataset_record_count -Expected 300 -Name "$artifactName`_STRESS_DATASET_RECORD_COUNT"
  }
  if (Test-PropertyExists -Object $artifact -Name "autonomous_selected_count") {
    Assert-Equals -Actual $artifact.autonomous_selected_count -Expected 1 -Name "$artifactName`_AUTONOMOUS_SELECTED_COUNT"
  }
  if (Test-PropertyExists -Object $artifact -Name "trusted_material_count") {
    Assert-Equals -Actual $artifact.trusted_material_count -Expected 0 -Name "$artifactName`_TRUSTED_MATERIAL_COUNT"
  }
}

if ($null -ne $Proof) {
  Assert-Equals -Actual $Proof.runtime_executed -Expected $true -Name "PROOF_RUNTIME_EXECUTED"
  Assert-Equals -Actual $Proof.builder_runtime_invoked -Expected $true -Name "PROOF_BUILDER_RUNTIME_INVOKED"
  Assert-Equals -Actual $Proof.owner_delegated_sandbox_decision -Expected $true -Name "PROOF_OWNER_DELEGATED"
  Assert-Equals -Actual $Proof.owner_manual_pick -Expected $false -Name "PROOF_OWNER_MANUAL_PICK"
  Assert-Equals -Actual $Proof.production_adoption_allowed -Expected $false -Name "PROOF_PRODUCTION_ADOPTION_ALLOWED"
  Assert-Equals -Actual $Proof.external_fetch_performed -Expected $false -Name "PROOF_EXTERNAL_FETCH_PERFORMED"
  Assert-Equals -Actual $Proof.dependency_install_performed -Expected $false -Name "PROOF_DEPENDENCY_INSTALL_PERFORMED"
  Assert-Equals -Actual $Proof.executable_materials_used -Expected $false -Name "PROOF_EXECUTABLE_MATERIALS_USED"
  Assert-Equals -Actual $Proof.wrapper_created -Expected $false -Name "PROOF_WRAPPER_CREATED"
  Assert-Equals -Actual $Proof.smoke_test_executed -Expected $false -Name "PROOF_SMOKE_TEST_EXECUTED"
  Assert-Equals -Actual $Proof.queue_after -Expected "NONE" -Name "PROOF_QUEUE_AFTER"
  Assert-Equals -Actual $Proof.codex_used -Expected $false -Name "PROOF_CODEX_USED"
  Assert-Equals -Actual $Proof.main_touched -Expected $false -Name "PROOF_MAIN_TOUCHED"
}

if ($null -ne $Queue) {
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"
  Assert-Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "TASK_QUEUE_ACTIVE_TASK_ID"
}

if ($Ok -eq $true) {
  Write-Output "PHASE138A_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE138A_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE138A validation failed."
}
