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
    "merge_allowed_now",
    "production_adoption_allowed",
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

$StepId = "PHASE138C_SANDBOX_BRANCH_MERGE_DECISION_V1"
$RunId = "PHASE138C_SANDBOX_BRANCH_MERGE_DECISION_001"
$PreviousStepId = "PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_V1"
$NextAllowed = "PHASE138D_OWNER_APPROVED_SANDBOX_BRANCH_MERGE_V1"
$SourceBranch = "phase138a-autonomous-material-decision-stress-lab"
$TargetBranch = "phase110-idempotent-autonomy-trial-runtime"

$PreviousProofPath = "proofs/self_development/${PreviousStepId}.json"
$ReviewPath = "materials/AUTONOMOUS_MATERIAL_DECISION_REVIEW.json"
$DecisionPath = "self_control/SANDBOX_BRANCH_MERGE_DECISION.json"
$ReadinessPath = "self_control/SANDBOX_BRANCH_MERGE_READINESS_REPORT.json"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/SANDBOX_BRANCH_MERGE_DECISION_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$RuntimeLogPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RUNTIME_LOG.txt"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($p in @(
  "modules/invoke_sandbox_branch_merge_decision_001.ps1",
  "orchestrator/run.ps1",
  $PreviousProofPath,
  $ReviewPath,
  $DecisionPath,
  $ReadinessPath,
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
$Review = Read-JsonOrFail -Path $ReviewPath
$Decision = Read-JsonOrFail -Path $DecisionPath
$Readiness = Read-JsonOrFail -Path $ReadinessPath
$Output = Read-JsonOrFail -Path $OutputPath
$Result = Read-JsonOrFail -Path $ResultPath
$Report = Read-JsonOrFail -Path $ReportPath
$Proof = Read-JsonOrFail -Path $ProofPath
$Queue = Read-JsonOrFail -Path "TASK_QUEUE.json"

try {
  $RuntimeLog = Get-Content -LiteralPath $RuntimeLogPath -Raw
  foreach ($requiredSignal in @(
    "SANDBOX_BRANCH_MERGE_DECISION=PHASE138C_SANDBOX_BRANCH_MERGE_DECISION_001",
    "MERGE_DECISION_STATUS=PASS",
    "MERGE_SOURCE_BRANCH=phase138a-autonomous-material-decision-stress-lab",
    "MERGE_TARGET_BRANCH=phase110-idempotent-autonomy-trial-runtime",
    "MERGE_RECOMMENDATION=MERGE_AFTER_OWNER_APPROVAL",
    "MERGE_ALLOWED_NOW=False",
    "OWNER_APPROVAL_REQUIRED=True",
    "PRODUCTION_ADOPTION_ALLOWED=False",
    "MATERIAL_TRUSTED_COUNT=0",
    "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
    "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
    "MATERIAL_EXECUTABLE_USED=False",
    "MERGE_DECISION_NEXT_STEP=PHASE138D_OWNER_APPROVED_SANDBOX_BRANCH_MERGE_V1",
    "STATUS=PASS_STOPPED_SANDBOX_BRANCH_MERGE_DECISION_BUILT"
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
  Assert-Equals -Actual $Branch -Expected $SourceBranch -Name "GIT_BRANCH"
} catch {
  Mark-Fail "GIT_BRANCH_READ_FAIL=$($_.Exception.Message)"
}

if ($null -ne $PreviousProof) {
  Write-Output "PREVIOUS_PROOF_STATUS=$($PreviousProof.status)"
  Write-Output "PREVIOUS_PROOF_NEXT=$($PreviousProof.next_allowed_step)"
  Assert-Equals -Actual $PreviousProof.status -Expected "PASS" -Name "PREVIOUS_PROOF_STATUS"
  Assert-Equals -Actual $PreviousProof.next_allowed_step -Expected $StepId -Name "PREVIOUS_PROOF_NEXT_ALLOWED_STEP"
  Assert-Equals -Actual $PreviousProof.selected_material_id -Expected "candidate_pester_powershell_test_framework" -Name "PREVIOUS_PROOF_SELECTED_MATERIAL"
  Assert-Equals -Actual $PreviousProof.policy_violation_count -Expected 30 -Name "PREVIOUS_PROOF_POLICY_VIOLATION_COUNT"
  Assert-Equals -Actual $PreviousProof.violation_sum -Expected 30 -Name "PREVIOUS_PROOF_VIOLATION_SUM"
  Assert-Equals -Actual $PreviousProof.trusted_material_count -Expected 0 -Name "PREVIOUS_PROOF_TRUSTED_COUNT"
  Assert-NoForbiddenRuntimeFlags -Object $PreviousProof -Context "PREVIOUS_PROOF"
}

if ($null -ne $Review) {
  Assert-Equals -Actual $Review.status -Expected "PASS" -Name "REVIEW_STATUS"
  Assert-Equals -Actual $Review.selected_material_id -Expected "candidate_pester_powershell_test_framework" -Name "REVIEW_SELECTED_MATERIAL"
  Assert-Equals -Actual $Review.policy_violation_count -Expected 30 -Name "REVIEW_POLICY_VIOLATION_COUNT"
  Assert-Equals -Actual $Review.violation_sum -Expected 30 -Name "REVIEW_VIOLATION_SUM"
  Assert-Equals -Actual $Review.trusted_material_count -Expected 0 -Name "REVIEW_TRUSTED_COUNT"
  Assert-NoForbiddenRuntimeFlags -Object $Review -Context "REVIEW"
}

if ($null -ne $Decision) {
  Write-Output "DECISION_STATUS=$($Decision.status)"
  Write-Output "DECISION_RECOMMENDATION=$($Decision.merge_recommendation)"
  Write-Output "DECISION_MERGE_ALLOWED_NOW=$($Decision.merge_allowed_now)"

  Assert-Equals -Actual $Decision.status -Expected "PASS" -Name "DECISION_STATUS"
  Assert-Equals -Actual $Decision.decision_id -Expected "SANDBOX_BRANCH_MERGE_DECISION_001" -Name "DECISION_ID"
  Assert-Equals -Actual $Decision.source_branch -Expected $SourceBranch -Name "DECISION_SOURCE_BRANCH"
  Assert-Equals -Actual $Decision.target_branch -Expected $TargetBranch -Name "DECISION_TARGET_BRANCH"
  Assert-Equals -Actual $Decision.source_head -Expected "c2f8b56" -Name "DECISION_SOURCE_HEAD"
  Assert-Equals -Actual $Decision.target_base_head -Expected "6a958ed" -Name "DECISION_TARGET_BASE_HEAD"
  Assert-Equals -Actual $Decision.merge_recommendation -Expected "MERGE_AFTER_OWNER_APPROVAL" -Name "DECISION_MERGE_RECOMMENDATION"
  Assert-Equals -Actual $Decision.merge_allowed_now -Expected $false -Name "DECISION_MERGE_ALLOWED_NOW"
  Assert-Equals -Actual $Decision.owner_approval_required -Expected $true -Name "DECISION_OWNER_APPROVAL_REQUIRED"
  Assert-Equals -Actual $Decision.recommended_merge_mode -Expected "REVIEWED_PR_OR_MANUAL_MERGE" -Name "DECISION_RECOMMENDED_MERGE_MODE"
  Assert-Equals -Actual $Decision.trusted_material_count -Expected 0 -Name "DECISION_TRUSTED_COUNT"
  Assert-Equals -Actual $Decision.next_allowed_step -Expected $NextAllowed -Name "DECISION_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenRuntimeFlags -Object $Decision -Context "DECISION"
}

if ($null -ne $Readiness) {
  Write-Output "READINESS_STATUS=$($Readiness.status)"
  Write-Output "READINESS_BLOCKERS=$($Readiness.merge_blockers_count)"

  Assert-Equals -Actual $Readiness.status -Expected "PASS" -Name "READINESS_STATUS"
  Assert-Equals -Actual $Readiness.stress_dataset_record_count -Expected 300 -Name "READINESS_DATASET_RECORD_COUNT"
  Assert-Equals -Actual $Readiness.selected_material_id -Expected "candidate_pester_powershell_test_framework" -Name "READINESS_SELECTED_MATERIAL"
  Assert-Equals -Actual $Readiness.policy_violation_count -Expected 30 -Name "READINESS_POLICY_VIOLATION_COUNT"
  Assert-Equals -Actual $Readiness.merge_blockers_count -Expected 1 -Name "READINESS_MERGE_BLOCKERS_COUNT"
  if (@($Readiness.merge_blockers) -notcontains "OWNER_APPROVAL_REQUIRED_BEFORE_MERGE") {
    Mark-Fail "READINESS_OWNER_APPROVAL_BLOCKER_MISSING"
  }
  Assert-Equals -Actual $Readiness.no_runtime_forbidden_actions -Expected $true -Name "READINESS_NO_RUNTIME_FORBIDDEN_ACTIONS"
  Assert-Equals -Actual $Readiness.no_production_trust -Expected $true -Name "READINESS_NO_PRODUCTION_TRUST"
  Assert-Equals -Actual $Readiness.no_dependency_install -Expected $true -Name "READINESS_NO_DEPENDENCY_INSTALL"
  Assert-Equals -Actual $Readiness.no_external_fetch -Expected $true -Name "READINESS_NO_EXTERNAL_FETCH"
  Assert-Equals -Actual $Readiness.no_executable_use -Expected $true -Name "READINESS_NO_EXECUTABLE_USE"
  Assert-Equals -Actual $Readiness.trusted_material_count -Expected 0 -Name "READINESS_TRUSTED_COUNT"
  Assert-Equals -Actual $Readiness.next_allowed_step -Expected $NextAllowed -Name "READINESS_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenRuntimeFlags -Object $Readiness -Context "READINESS"
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

  if (Test-PropertyExists -Object $artifact -Name "merge_recommendation") {
    Assert-Equals -Actual $artifact.merge_recommendation -Expected "MERGE_AFTER_OWNER_APPROVAL" -Name "$artifactName`_MERGE_RECOMMENDATION"
  }
  if (Test-PropertyExists -Object $artifact -Name "merge_allowed_now") {
    Assert-Equals -Actual $artifact.merge_allowed_now -Expected $false -Name "$artifactName`_MERGE_ALLOWED_NOW"
  }
  if (Test-PropertyExists -Object $artifact -Name "owner_approval_required") {
    Assert-Equals -Actual $artifact.owner_approval_required -Expected $true -Name "$artifactName`_OWNER_APPROVAL_REQUIRED"
  }
  if (Test-PropertyExists -Object $artifact -Name "trusted_material_count") {
    Assert-Equals -Actual $artifact.trusted_material_count -Expected 0 -Name "$artifactName`_TRUSTED_COUNT"
  }
}

if ($null -ne $Proof) {
  Assert-Equals -Actual $Proof.runtime_executed -Expected $true -Name "PROOF_RUNTIME_EXECUTED"
  Assert-Equals -Actual $Proof.builder_runtime_invoked -Expected $true -Name "PROOF_BUILDER_RUNTIME_INVOKED"
  Assert-Equals -Actual $Proof.source_branch -Expected $SourceBranch -Name "PROOF_SOURCE_BRANCH"
  Assert-Equals -Actual $Proof.target_branch -Expected $TargetBranch -Name "PROOF_TARGET_BRANCH"
  Assert-Equals -Actual $Proof.queue_after -Expected "NONE" -Name "PROOF_QUEUE_AFTER"
  Assert-Equals -Actual $Proof.codex_used -Expected $false -Name "PROOF_CODEX_USED"
  Assert-Equals -Actual $Proof.main_touched -Expected $false -Name "PROOF_MAIN_TOUCHED"
}

if ($null -ne $Queue) {
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"
  Assert-Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "TASK_QUEUE_ACTIVE_TASK_ID"
}

if ($Ok -eq $true) {
  Write-Output "PHASE138C_SANDBOX_BRANCH_MERGE_DECISION_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE138C_SANDBOX_BRANCH_MERGE_DECISION_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE138C validation failed."
}
