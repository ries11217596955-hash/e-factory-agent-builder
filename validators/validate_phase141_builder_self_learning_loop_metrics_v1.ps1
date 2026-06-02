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
    if (-not (Test-Path -LiteralPath $Path)) {
      Mark-Fail "MISSING=$Path"
      return $null
    }
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

  if ($null -eq $Object) { return $false }
  return $null -ne ($Object.PSObject.Properties | Where-Object { $_.Name -eq $Name } | Select-Object -First 1)
}

function Get-PropertyValue {
  param(
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object) { return $null }
  $property = $Object.PSObject.Properties | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
  if ($null -eq $property) { return $null }
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

function Assert-True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    Mark-Fail "$Name`_NOT_TRUE=$Actual"
  }
}

function Assert-False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    Mark-Fail "$Name`_NOT_FALSE=$Actual"
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

function Assert-ZeroProperty {
  param(
    [object]$Object,
    [string]$PropertyName,
    [string]$Context
  )

  if (Test-PropertyExists -Object $Object -Name $PropertyName) {
    $value = Get-PropertyValue -Object $Object -Name $PropertyName
    if ($value -ne 0) {
      Mark-Fail "$Context`_$PropertyName`_NOT_ZERO=$value"
    }
  }
}

function Assert-NoForbiddenFlags {
  param(
    [object]$Object,
    [string]$Context
  )

  foreach ($propertyName in @(
    "external_agent_production_allowed",
    "production_adoption_allowed",
    "external_fetch_performed",
    "dependency_install_performed",
    "executable_materials_used",
    "dependency_install_allowed",
    "external_fetch_allowed",
    "executable_use_allowed",
    "codex_authored",
    "codex_authored_generated_pack",
    "codex_authored_generated_packs",
    "external_agent_created"
  )) {
    Assert-FalseProperty -Object $Object -PropertyName $propertyName -Context $Context
  }

  Assert-ZeroProperty -Object $Object -PropertyName "trusted_material_count" -Context $Context
}

function Assert-TextContains {
  param(
    [string]$Text,
    [string]$Needle,
    [string]$Name
  )

  if ($Text -notmatch [regex]::Escape($Needle)) {
    Mark-Fail "$Name`_TEXT_MISSING=$Needle"
  }
}

$StepId = "PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_V1"
$RunId = "PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_001"
$PreviousStepId = "PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_V1"
$Phase139StepId = "PHASE139_BUILD_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_V1"
$NextAllowed = "PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1"
$ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"

$Phase140ProofPath = "proofs/self_development/${PreviousStepId}.json"
$Phase139ProofPath = "proofs/self_development/${Phase139StepId}.json"
$MetricsPath = "self_control/BUILDER_SELF_LEARNING_LOOP_METRICS.json"
$ErrorLedgerPath = "self_control/BUILDER_SELF_LEARNING_ERROR_LEDGER.json"
$NextGapSelectionPath = "self_control/BUILDER_NEXT_GAP_SELECTION.json"
$CurrentStatePath = "self_control/CURRENT_AGENT_BUILDER_STATE.json"
$NextActionPath = "self_control/NEXT_ACTION.json"
$ProofPointerPath = "self_control/LAST_ACCEPTED_PROOF_POINTER.json"
$RestoreToolPath = "tools/restore_agent_builder_state.ps1"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/BUILDER_SELF_LEARNING_LOOP_METRICS_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$RuntimeLogPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RUNTIME_LOG.txt"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($path in @(
  "modules/invoke_builder_self_learning_loop_metrics_001.ps1",
  "validators/validate_phase141_builder_self_learning_loop_metrics_v1.ps1",
  "orchestrator/run.ps1",
  $Phase140ProofPath,
  $MetricsPath,
  $ErrorLedgerPath,
  $NextGapSelectionPath,
  $CurrentStatePath,
  $NextActionPath,
  $ProofPointerPath,
  $RestoreToolPath,
  $OutputPath,
  $ResultPath,
  $RuntimeLogPath,
  $ReportPath,
  $ProofPath
)) {
  if (-not (Test-Path -LiteralPath $path)) {
    Mark-Fail "MISSING=$path"
  } else {
    Write-Output "EXISTS=$path"
  }
}

$Phase140Proof = Read-JsonOrFail -Path $Phase140ProofPath
$Phase139Proof = if (Test-Path -LiteralPath $Phase139ProofPath) { Read-JsonOrFail -Path $Phase139ProofPath } else { $null }
$Metrics = Read-JsonOrFail -Path $MetricsPath
$ErrorLedger = Read-JsonOrFail -Path $ErrorLedgerPath
$NextGapSelection = Read-JsonOrFail -Path $NextGapSelectionPath
$CurrentState = Read-JsonOrFail -Path $CurrentStatePath
$NextAction = Read-JsonOrFail -Path $NextActionPath
$ProofPointer = Read-JsonOrFail -Path $ProofPointerPath
$Output = Read-JsonOrFail -Path $OutputPath
$Result = Read-JsonOrFail -Path $ResultPath
$Report = Read-JsonOrFail -Path $ReportPath
$Proof = Read-JsonOrFail -Path $ProofPath
$Queue = Read-JsonOrFail -Path "TASK_QUEUE.json"

try {
  $OrchestratorText = Get-Content -LiteralPath "orchestrator/run.ps1" -Raw
  Assert-TextContains -Text $OrchestratorText -Needle "Invoke-BuilderSelfLearningLoopMetrics001" -Name "ORCHESTRATOR"
  Assert-TextContains -Text $OrchestratorText -Needle "BUILDER_SELF_LEARNING_LOOP_METRICS=PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_001" -Name "ORCHESTRATOR"
} catch {
  Mark-Fail "ORCHESTRATOR_READ_FAIL=$($_.Exception.Message)"
}

try {
  $RuntimeLog = Get-Content -LiteralPath $RuntimeLogPath -Raw
  foreach ($requiredSignal in @(
    "BUILDER_SELF_LEARNING_LOOP_METRICS=PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_001",
    "SELF_LEARNING_METRICS_STATUS=PASS",
    "MEASURED_PHASE_COUNT=2",
    "BUILDER_GENERATED_PACK_TOTAL=4",
    "GENERATED_PACK_ADMISSION_SUCCESS_COUNT=4",
    "GENERATED_PACK_EXECUTION_SUCCESS_COUNT=4",
    "GENERATED_PACK_FAILURE_COUNT=0",
    "CODEX_AUTHORED_GENERATED_PACK_COUNT=0",
    "EXTERNAL_AGENT_CREATED_COUNT=0",
    "REPO_STATE_SYNC_CAPSULE_AVAILABLE=True",
    "RESTORE_TOOL_AVAILABLE=True",
    "NEXT_GAP_SELECTED=BUILDER_NEXT_GAP_SELECTOR_RUNTIME",
    "EXTERNAL_AGENT_PRODUCTION_ALLOWED=False",
    "MATERIAL_TRUSTED_COUNT=0",
    "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
    "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
    "MATERIAL_EXECUTABLE_USED=False",
    "SELF_LEARNING_METRICS_NEXT_STEP=PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1",
    "STATUS=PASS_STOPPED_BUILDER_SELF_LEARNING_LOOP_METRICS_BUILT"
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
  $ExternalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
  if ($ExternalAgentStatus.Count -gt 0) {
    Mark-Fail "EXTERNAL_AGENT_FOLDER_CREATED_OR_TOUCHED=$($ExternalAgentStatus -join '; ')"
  } else {
    Write-Output "EXTERNAL_AGENT_SCOPE_STATUS=CLEAN"
  }
} catch {
  Mark-Fail "EXTERNAL_AGENT_SCOPE_STATUS_READ_FAIL=$($_.Exception.Message)"
}

try {
  $Phase141GeneratedPacks = @(Get-ChildItem -LiteralPath "self_build_programs/generated" -Filter "PHASE141*.json" -File -ErrorAction SilentlyContinue)
  if ($Phase141GeneratedPacks.Count -gt 0) {
    Mark-Fail "PHASE141_GENERATED_SELF_BUILD_PACK_CREATED=$($Phase141GeneratedPacks.Name -join ',')"
  } else {
    Write-Output "PHASE141_GENERATED_SELF_BUILD_PACK_CREATED=False"
  }
} catch {
  Mark-Fail "PHASE141_GENERATED_PACK_SCAN_FAIL=$($_.Exception.Message)"
}

if ($null -ne $Phase140Proof) {
  Assert-Equals -Actual $Phase140Proof.status -Expected "PASS" -Name "PHASE140_PROOF_STATUS"
  Assert-Equals -Actual $Phase140Proof.next_allowed_step -Expected $StepId -Name "PHASE140_PROOF_NEXT_ALLOWED_STEP"
  Assert-Equals -Actual $Phase140Proof.builder_generated_pack_count -Expected 3 -Name "PHASE140_BUILDER_GENERATED_PACK_COUNT"
  Assert-Equals -Actual $Phase140Proof.generated_packs_author -Expected "BUILDER_RUNTIME" -Name "PHASE140_GENERATED_PACKS_AUTHOR"
  Assert-False -Actual $Phase140Proof.codex_authored_generated_packs -Name "PHASE140_CODEX_AUTHORED_GENERATED_PACKS"
  Assert-True -Actual $Phase140Proof.generated_packs_admitted -Name "PHASE140_GENERATED_PACKS_ADMITTED"
  Assert-True -Actual $Phase140Proof.generated_packs_executed -Name "PHASE140_GENERATED_PACKS_EXECUTED"
  Assert-True -Actual $Phase140Proof.repo_state_sync_capsule_created -Name "PHASE140_REPO_STATE_SYNC_CAPSULE_CREATED"
  Assert-True -Actual $Phase140Proof.restore_tool_created -Name "PHASE140_RESTORE_TOOL_CREATED"
  Assert-NoForbiddenFlags -Object $Phase140Proof -Context "PHASE140_PROOF"
}

if ($null -ne $Phase139Proof) {
  Assert-Equals -Actual $Phase139Proof.status -Expected "PASS" -Name "PHASE139_PROOF_STATUS"
  Assert-Equals -Actual $Phase139Proof.builder_generated_pack_count -Expected 1 -Name "PHASE139_BUILDER_GENERATED_PACK_COUNT"
  Assert-Equals -Actual $Phase139Proof.generated_pack_author -Expected "BUILDER_RUNTIME" -Name "PHASE139_GENERATED_PACK_AUTHOR"
  Assert-False -Actual $Phase139Proof.codex_authored_generated_pack -Name "PHASE139_CODEX_AUTHORED_GENERATED_PACK"
  Assert-True -Actual $Phase139Proof.generated_pack_admitted -Name "PHASE139_GENERATED_PACK_ADMITTED"
  Assert-True -Actual $Phase139Proof.generated_pack_executed -Name "PHASE139_GENERATED_PACK_EXECUTED"
  Assert-NoForbiddenFlags -Object $Phase139Proof -Context "PHASE139_PROOF"
}

foreach ($artifactSpec in @(
  @{ Name = "METRICS"; Object = $Metrics },
  @{ Name = "ERROR_LEDGER"; Object = $ErrorLedger },
  @{ Name = "NEXT_GAP_SELECTION"; Object = $NextGapSelection },
  @{ Name = "OUTPUT"; Object = $Output },
  @{ Name = "RESULT"; Object = $Result },
  @{ Name = "REPORT"; Object = $Report },
  @{ Name = "PROOF"; Object = $Proof }
)) {
  $artifactName = $artifactSpec.Name
  $artifact = $artifactSpec.Object
  if ($null -eq $artifact) { continue }

  Write-Output "$artifactName`_STATUS=$($artifact.status)"
  Write-Output "$artifactName`_NEXT_ALLOWED_STEP=$($artifact.next_allowed_step)"
  Assert-Equals -Actual $artifact.status -Expected "PASS" -Name "$artifactName`_STATUS"
  Assert-Equals -Actual $artifact.next_allowed_step -Expected $NextAllowed -Name "$artifactName`_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenFlags -Object $artifact -Context $artifactName
}

if ($null -ne $Metrics) {
  Assert-Equals -Actual $Metrics.metrics_id -Expected $RunId -Name "METRICS_ID"
  Assert-Equals -Actual $Metrics.current_line -Expected "SELF_BUILD" -Name "METRICS_CURRENT_LINE"
  Assert-Equals -Actual (@($Metrics.measured_phases).Count) -Expected 2 -Name "METRICS_MEASURED_PHASES_COUNT"
  Assert-Equals -Actual $Metrics.measured_phase_count -Expected 2 -Name "METRICS_MEASURED_PHASE_COUNT"
  Assert-Equals -Actual $Metrics.builder_generated_pack_total -Expected 4 -Name "METRICS_BUILDER_GENERATED_PACK_TOTAL"
  Assert-Equals -Actual $Metrics.builder_generated_pack_total_breakdown.PHASE139_BUILD_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_V1 -Expected 1 -Name "METRICS_PHASE139_BREAKDOWN"
  Assert-Equals -Actual $Metrics.builder_generated_pack_total_breakdown.PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_V1 -Expected 3 -Name "METRICS_PHASE140_BREAKDOWN"
  Assert-Equals -Actual $Metrics.generated_pack_admission_success_count -Expected 4 -Name "METRICS_ADMISSION_SUCCESS_COUNT"
  Assert-Equals -Actual $Metrics.generated_pack_execution_success_count -Expected 4 -Name "METRICS_EXECUTION_SUCCESS_COUNT"
  Assert-Equals -Actual $Metrics.generated_pack_failure_count -Expected 0 -Name "METRICS_FAILURE_COUNT"
  Assert-Equals -Actual $Metrics.codex_bootstrap_phase_count -Expected 2 -Name "METRICS_CODEX_BOOTSTRAP_PHASE_COUNT"
  Assert-Equals -Actual $Metrics.codex_authored_generated_pack_count -Expected 0 -Name "METRICS_CODEX_AUTHORED_GENERATED_PACK_COUNT"
  Assert-Equals -Actual $Metrics.external_agent_created_count -Expected 0 -Name "METRICS_EXTERNAL_AGENT_CREATED_COUNT"
  Assert-Equals -Actual $Metrics.production_adoption_count -Expected 0 -Name "METRICS_PRODUCTION_ADOPTION_COUNT"
  Assert-Equals -Actual $Metrics.trusted_material_count -Expected 0 -Name "METRICS_TRUSTED_MATERIAL_COUNT"
  Assert-Equals -Actual $Metrics.external_fetch_count -Expected 0 -Name "METRICS_EXTERNAL_FETCH_COUNT"
  Assert-Equals -Actual $Metrics.dependency_install_count -Expected 0 -Name "METRICS_DEPENDENCY_INSTALL_COUNT"
  Assert-Equals -Actual $Metrics.executable_material_use_count -Expected 0 -Name "METRICS_EXECUTABLE_MATERIAL_USE_COUNT"
  Assert-True -Actual $Metrics.restore_tool_available -Name "METRICS_RESTORE_TOOL_AVAILABLE"
  Assert-True -Actual $Metrics.repo_state_sync_capsule_available -Name "METRICS_REPO_STATE_SYNC_CAPSULE_AVAILABLE"
}

if ($null -ne $ErrorLedger) {
  Assert-Equals -Actual $ErrorLedger.error_ledger_id -Expected "PHASE141_SELF_LEARNING_ERROR_LEDGER_001" -Name "ERROR_LEDGER_ID"
  Assert-Equals -Actual $ErrorLedger.false_autonomy_claim_count -Expected 0 -Name "ERROR_LEDGER_FALSE_AUTONOMY_CLAIM_COUNT"
  Assert-Equals -Actual $ErrorLedger.codex_authored_generated_pack_violation_count -Expected 0 -Name "ERROR_LEDGER_CODEX_AUTHORED_GENERATED_PACK_VIOLATION_COUNT"
  Assert-Equals -Actual $ErrorLedger.external_agent_scope_violation_count -Expected 0 -Name "ERROR_LEDGER_EXTERNAL_AGENT_SCOPE_VIOLATION_COUNT"
  Assert-Equals -Actual $ErrorLedger.trusted_material_violation_count -Expected 0 -Name "ERROR_LEDGER_TRUSTED_MATERIAL_VIOLATION_COUNT"
  Assert-Equals -Actual $ErrorLedger.external_fetch_violation_count -Expected 0 -Name "ERROR_LEDGER_EXTERNAL_FETCH_VIOLATION_COUNT"
  Assert-Equals -Actual $ErrorLedger.dependency_install_violation_count -Expected 0 -Name "ERROR_LEDGER_DEPENDENCY_INSTALL_VIOLATION_COUNT"
  Assert-Equals -Actual $ErrorLedger.executable_material_violation_count -Expected 0 -Name "ERROR_LEDGER_EXECUTABLE_MATERIAL_VIOLATION_COUNT"
  if ($ErrorLedger.unresolved_learning_risk_count -lt 1) {
    Mark-Fail "ERROR_LEDGER_UNRESOLVED_LEARNING_RISK_COUNT_TOO_LOW=$($ErrorLedger.unresolved_learning_risk_count)"
  }
  if (@($ErrorLedger.unresolved_learning_risks) -notcontains "METRICS_ARE_RETROSPECTIVE_NOT_YET_AUTONOMOUS_DECISION_QUALITY") {
    Mark-Fail "ERROR_LEDGER_REQUIRED_RISK_MISSING"
  }
}

if ($null -ne $NextGapSelection) {
  Assert-Equals -Actual $NextGapSelection.selected_next_gap -Expected "BUILDER_NEXT_GAP_SELECTOR_RUNTIME" -Name "NEXT_GAP_SELECTED_NEXT_GAP"
  Assert-Equals -Actual $NextGapSelection.selection_reason -Expected "Builder can generate and execute self-packs, but next it must select the next gap using metrics instead of owner/assistant direction" -Name "NEXT_GAP_SELECTION_REASON"
  Assert-Equals -Actual $NextGapSelection.selected_next_step -Expected $NextAllowed -Name "NEXT_GAP_SELECTED_NEXT_STEP"
  Assert-False -Actual $NextGapSelection.external_agent_production_allowed -Name "NEXT_GAP_EXTERNAL_AGENT_PRODUCTION_ALLOWED"
  Assert-False -Actual $NextGapSelection.owner_interactive_prompt_required -Name "NEXT_GAP_OWNER_INTERACTIVE_PROMPT_REQUIRED"
}

if ($null -ne $CurrentState) {
  Assert-Equals -Actual $CurrentState.status -Expected "PASS" -Name "CURRENT_STATE_STATUS"
  Assert-Equals -Actual $CurrentState.branch -Expected $ExpectedBranch -Name "CURRENT_STATE_BRANCH"
  Assert-Equals -Actual $CurrentState.accepted_head -Expected $Proof.source_head -Name "CURRENT_STATE_ACCEPTED_HEAD"
  Assert-Equals -Actual $CurrentState.last_accepted_phase -Expected $PreviousStepId -Name "CURRENT_STATE_LAST_ACCEPTED_PHASE"
  Assert-Equals -Actual $CurrentState.current_phase -Expected $StepId -Name "CURRENT_STATE_CURRENT_PHASE"
  Assert-Equals -Actual $CurrentState.current_line -Expected "SELF_BUILD" -Name "CURRENT_STATE_CURRENT_LINE"
  Assert-Equals -Actual $CurrentState.next_allowed_step -Expected $NextAllowed -Name "CURRENT_STATE_NEXT_ALLOWED_STEP"
}

if ($null -ne $NextAction) {
  Assert-Equals -Actual $NextAction.status -Expected "PASS" -Name "NEXT_ACTION_STATUS"
  Assert-Equals -Actual $NextAction.next_allowed_step -Expected $NextAllowed -Name "NEXT_ACTION_NEXT_ALLOWED_STEP"
  Assert-Equals -Actual $NextAction.next_action_type -Expected "SELF_BUILD" -Name "NEXT_ACTION_TYPE"
  Assert-False -Actual $NextAction.external_agent_production_allowed -Name "NEXT_ACTION_EXTERNAL_AGENT_PRODUCTION_ALLOWED"
  Assert-False -Actual $NextAction.owner_interactive_prompt_required -Name "NEXT_ACTION_OWNER_INTERACTIVE_PROMPT_REQUIRED"
}

if ($null -ne $ProofPointer) {
  Assert-Equals -Actual $ProofPointer.status -Expected "PASS" -Name "PROOF_POINTER_STATUS"
  Assert-Equals -Actual $ProofPointer.last_accepted_proof -Expected $Phase140ProofPath -Name "PROOF_POINTER_LAST_ACCEPTED_PROOF"
  Assert-Equals -Actual $ProofPointer.pending_current_proof -Expected $ProofPath -Name "PROOF_POINTER_PENDING_CURRENT_PROOF"
}

if ($null -ne $Proof) {
  Assert-True -Actual $Proof.runtime_executed -Name "PROOF_RUNTIME_EXECUTED"
  Assert-True -Actual $Proof.builder_runtime_invoked -Name "PROOF_BUILDER_RUNTIME_INVOKED"
  Assert-Equals -Actual $Proof.current_line -Expected "SELF_BUILD" -Name "PROOF_CURRENT_LINE"
  Assert-Equals -Actual $Proof.measured_phase_count -Expected 2 -Name "PROOF_MEASURED_PHASE_COUNT"
  Assert-Equals -Actual $Proof.builder_generated_pack_total -Expected 4 -Name "PROOF_BUILDER_GENERATED_PACK_TOTAL"
  Assert-Equals -Actual $Proof.generated_pack_admission_success_count -Expected 4 -Name "PROOF_ADMISSION_SUCCESS_COUNT"
  Assert-Equals -Actual $Proof.generated_pack_execution_success_count -Expected 4 -Name "PROOF_EXECUTION_SUCCESS_COUNT"
  Assert-Equals -Actual $Proof.generated_pack_failure_count -Expected 0 -Name "PROOF_FAILURE_COUNT"
  Assert-Equals -Actual $Proof.codex_authored_generated_pack_count -Expected 0 -Name "PROOF_CODEX_AUTHORED_GENERATED_PACK_COUNT"
  Assert-Equals -Actual $Proof.external_agent_created_count -Expected 0 -Name "PROOF_EXTERNAL_AGENT_CREATED_COUNT"
  Assert-True -Actual $Proof.repo_state_sync_capsule_available -Name "PROOF_REPO_STATE_SYNC_CAPSULE_AVAILABLE"
  Assert-True -Actual $Proof.restore_tool_available -Name "PROOF_RESTORE_TOOL_AVAILABLE"
  Assert-Equals -Actual $Proof.selected_next_gap -Expected "BUILDER_NEXT_GAP_SELECTOR_RUNTIME" -Name "PROOF_SELECTED_NEXT_GAP"
  Assert-False -Actual $Proof.external_agent_production_allowed -Name "PROOF_EXTERNAL_AGENT_PRODUCTION_ALLOWED"
  Assert-False -Actual $Proof.production_adoption_allowed -Name "PROOF_PRODUCTION_ADOPTION_ALLOWED"
  Assert-Equals -Actual $Proof.trusted_material_count -Expected 0 -Name "PROOF_TRUSTED_COUNT"
  Assert-False -Actual $Proof.external_fetch_performed -Name "PROOF_EXTERNAL_FETCH_PERFORMED"
  Assert-False -Actual $Proof.dependency_install_performed -Name "PROOF_DEPENDENCY_INSTALL_PERFORMED"
  Assert-False -Actual $Proof.executable_materials_used -Name "PROOF_EXECUTABLE_MATERIALS_USED"
  Assert-Equals -Actual $Proof.queue_after -Expected "NONE" -Name "PROOF_QUEUE_AFTER"
  Assert-False -Actual $Proof.main_touched -Name "PROOF_MAIN_TOUCHED"
  Assert-Equals -Actual $Proof.source_branch -Expected $ExpectedBranch -Name "PROOF_SOURCE_BRANCH"
  Assert-Equals -Actual $Proof.next_allowed_step -Expected $NextAllowed -Name "PROOF_NEXT_ALLOWED_STEP"
}

if ($null -ne $Queue) {
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"
  Assert-Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "TASK_QUEUE_ACTIVE_TASK_ID"
}

if ($Ok -eq $true) {
  Write-Output "PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE141 validation failed."
}
