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

$StepId = "PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_V1"
$RunId = "PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_001"
$PreviousStepId = "PHASE139_BUILD_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_V1"
$NextAllowed = "PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_V1"
$ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"

$GeneratedPackStepIds = @(
  "PHASE140A_BUILDER_GENERATED_STATE_SYNC_CAPSULE_SEED_V1",
  "PHASE140B_BUILDER_GENERATED_SELF_LEARNING_METRIC_SEED_V1",
  "PHASE140C_BUILDER_GENERATED_NEXT_GAP_SELECTOR_SEED_V1"
)

$PreviousProofPath = "proofs/self_development/${PreviousStepId}.json"
$AdmissionBatchPath = "self_control/BUILDER_GENERATED_SELF_BUILD_PACKS_ADMISSION_BATCH.json"
$ScaleTrialResultPath = "self_control/BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_RESULT.json"
$CurrentStatePath = "self_control/CURRENT_AGENT_BUILDER_STATE.json"
$NextActionPath = "self_control/NEXT_ACTION.json"
$ProofPointerPath = "self_control/LAST_ACCEPTED_PROOF_POINTER.json"
$RestoreToolPath = "tools/restore_agent_builder_state.ps1"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$RuntimeLogPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RUNTIME_LOG.txt"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($path in @(
  "modules/invoke_builder_self_pack_author_scale_trial_001.ps1",
  "validators/validate_phase140_builder_self_pack_author_scale_trial_v1.ps1",
  "orchestrator/run.ps1",
  $PreviousProofPath,
  $AdmissionBatchPath,
  $ScaleTrialResultPath,
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

foreach ($generatedStepId in $GeneratedPackStepIds) {
  foreach ($path in @(
    "self_build_programs/generated/${generatedStepId}.json",
    "self_build_batch/autonomy_trials/$generatedStepId/${generatedStepId}_RESULT.json",
    "self_build_batch/autonomy_trials/$generatedStepId/${generatedStepId}_RUNTIME_LOG.txt"
  )) {
    if (-not (Test-Path -LiteralPath $path)) {
      Mark-Fail "MISSING=$path"
    } else {
      Write-Output "EXISTS=$path"
    }
  }
}

$PreviousProof = Read-JsonOrFail -Path $PreviousProofPath
$AdmissionBatch = Read-JsonOrFail -Path $AdmissionBatchPath
$ScaleTrialResult = Read-JsonOrFail -Path $ScaleTrialResultPath
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
  Assert-TextContains -Text $OrchestratorText -Needle "Invoke-BuilderSelfPackAuthorScaleTrial001" -Name "ORCHESTRATOR"
  Assert-TextContains -Text $OrchestratorText -Needle "BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL=PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_001" -Name "ORCHESTRATOR"
} catch {
  Mark-Fail "ORCHESTRATOR_READ_FAIL=$($_.Exception.Message)"
}

try {
  $RuntimeLog = Get-Content -LiteralPath $RuntimeLogPath -Raw
  foreach ($requiredSignal in @(
    "BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL=PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_001",
    "SELF_PACK_AUTHOR_SCALE_STATUS=PASS",
    "BUILDER_GENERATED_PACK_COUNT=3",
    "GENERATED_PACKS_AUTHOR=BUILDER_RUNTIME",
    "CODEX_AUTHORED_GENERATED_PACKS=False",
    "CODEX_BOOTSTRAP_USED=True",
    "GENERATED_PACKS_ADMITTED=True",
    "GENERATED_PACKS_EXECUTED=True",
    "REPO_STATE_SYNC_CAPSULE_CREATED=True",
    "RESTORE_TOOL_CREATED=True",
    "EXTERNAL_AGENT_PRODUCTION_ALLOWED=False",
    "MATERIAL_TRUSTED_COUNT=0",
    "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
    "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
    "MATERIAL_EXECUTABLE_USED=False",
    "SELF_PACK_AUTHOR_SCALE_NEXT_STEP=PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_V1",
    "STATUS=PASS_STOPPED_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_BUILT"
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
  $RestoreToolText = Get-Content -LiteralPath $RestoreToolPath -Raw
  foreach ($needle in @(
    '$env:USERPROFILE',
    'git fetch origin',
    'git switch $Branch',
    'git pull --ff-only origin $Branch',
    'NEXT_ALLOWED_STEP=$($NextAction.next_allowed_step)'
  )) {
    Assert-TextContains -Text $RestoreToolText -Needle $needle -Name "RESTORE_TOOL"
  }
  foreach ($forbidden in @(
    'git push',
    'git commit',
    'Set-Content',
    'Add-Content',
    'Out-File'
  )) {
    if ($RestoreToolText -match [regex]::Escape($forbidden)) {
      Mark-Fail "RESTORE_TOOL_FORBIDDEN_TEXT=$forbidden"
    }
  }
} catch {
  Mark-Fail "RESTORE_TOOL_READ_FAIL=$($_.Exception.Message)"
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

if ($null -ne $PreviousProof) {
  Assert-Equals -Actual $PreviousProof.status -Expected "PASS" -Name "PREVIOUS_PROOF_STATUS"
  Assert-Equals -Actual $PreviousProof.next_allowed_step -Expected $StepId -Name "PREVIOUS_PROOF_NEXT_ALLOWED_STEP"
  Assert-Equals -Actual $PreviousProof.builder_generated_pack_count -Expected 1 -Name "PREVIOUS_PROOF_BUILDER_GENERATED_PACK_COUNT"
  Assert-Equals -Actual $PreviousProof.generated_pack_author -Expected "BUILDER_RUNTIME" -Name "PREVIOUS_PROOF_GENERATED_PACK_AUTHOR"
  Assert-False -Actual $PreviousProof.codex_authored_generated_pack -Name "PREVIOUS_PROOF_CODEX_AUTHORED_GENERATED_PACK"
  Assert-True -Actual $PreviousProof.generated_pack_admitted -Name "PREVIOUS_PROOF_GENERATED_PACK_ADMITTED"
  Assert-True -Actual $PreviousProof.generated_pack_executed -Name "PREVIOUS_PROOF_GENERATED_PACK_EXECUTED"
  Assert-False -Actual $PreviousProof.external_agent_production_allowed -Name "PREVIOUS_PROOF_EXTERNAL_AGENT_PRODUCTION_ALLOWED"
  Assert-Equals -Actual $PreviousProof.trusted_material_count -Expected 0 -Name "PREVIOUS_PROOF_TRUSTED_COUNT"
  Assert-False -Actual $PreviousProof.external_fetch_performed -Name "PREVIOUS_PROOF_EXTERNAL_FETCH_PERFORMED"
  Assert-False -Actual $PreviousProof.dependency_install_performed -Name "PREVIOUS_PROOF_DEPENDENCY_INSTALL_PERFORMED"
  Assert-False -Actual $PreviousProof.executable_materials_used -Name "PREVIOUS_PROOF_EXECUTABLE_MATERIALS_USED"
}

foreach ($artifactSpec in @(
  @{ Name = "ADMISSION_BATCH"; Object = $AdmissionBatch },
  @{ Name = "SCALE_TRIAL_RESULT"; Object = $ScaleTrialResult },
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
  Assert-NoForbiddenFlags -Object $artifact -Context $artifactName
}

if ($null -ne $AdmissionBatch) {
  Assert-Equals -Actual $AdmissionBatch.admission_mode -Expected "ONE_BATCH" -Name "ADMISSION_BATCH_MODE"
  Assert-Equals -Actual $AdmissionBatch.admitted_by -Expected "BUILDER_RUNTIME" -Name "ADMISSION_BATCH_ADMITTED_BY"
  Assert-Equals -Actual $AdmissionBatch.admitted_pack_count -Expected 3 -Name "ADMISSION_BATCH_ADMITTED_PACK_COUNT"
  Assert-Equals -Actual (@($AdmissionBatch.admitted_packs).Count) -Expected 3 -Name "ADMISSION_BATCH_ADMITTED_PACKS_ARRAY_COUNT"
  Assert-Equals -Actual $AdmissionBatch.generated_packs_author -Expected "BUILDER_RUNTIME" -Name "ADMISSION_BATCH_GENERATED_PACKS_AUTHOR"
  Assert-False -Actual $AdmissionBatch.codex_authored_generated_packs -Name "ADMISSION_BATCH_CODEX_AUTHORED_GENERATED_PACKS"
  Assert-True -Actual $AdmissionBatch.generated_packs_admitted -Name "ADMISSION_BATCH_GENERATED_PACKS_ADMITTED"
}

foreach ($generatedStepId in $GeneratedPackStepIds) {
  $generatedPackPath = "self_build_programs/generated/${generatedStepId}.json"
  $generatedResultPath = "self_build_batch/autonomy_trials/$generatedStepId/${generatedStepId}_RESULT.json"
  $generatedRuntimeLogPath = "self_build_batch/autonomy_trials/$generatedStepId/${generatedStepId}_RUNTIME_LOG.txt"

  $GeneratedPack = Read-JsonOrFail -Path $generatedPackPath
  $GeneratedResult = Read-JsonOrFail -Path $generatedResultPath

  if ($null -ne $GeneratedPack) {
    Assert-Equals -Actual $GeneratedPack.status -Expected "BUILDER_RUNTIME_AUTHORED" -Name "$generatedStepId`_GENERATED_PACK_STATUS"
    Assert-Equals -Actual $GeneratedPack.step_id -Expected $generatedStepId -Name "$generatedStepId`_GENERATED_PACK_STEP_ID"
    Assert-Equals -Actual $GeneratedPack.author -Expected "BUILDER_RUNTIME" -Name "$generatedStepId`_GENERATED_PACK_AUTHOR"
    Assert-False -Actual $GeneratedPack.codex_authored -Name "$generatedStepId`_GENERATED_PACK_CODEX_AUTHORED"
    Assert-Equals -Actual $GeneratedPack.line -Expected "SELF_BUILD" -Name "$generatedStepId`_GENERATED_PACK_LINE"
    Assert-False -Actual $GeneratedPack.external_agent_production_allowed -Name "$generatedStepId`_GENERATED_PACK_EXTERNAL_AGENT_PRODUCTION_ALLOWED"
    Assert-False -Actual $GeneratedPack.dependency_install_allowed -Name "$generatedStepId`_GENERATED_PACK_DEPENDENCY_INSTALL_ALLOWED"
    Assert-False -Actual $GeneratedPack.external_fetch_allowed -Name "$generatedStepId`_GENERATED_PACK_EXTERNAL_FETCH_ALLOWED"
    Assert-False -Actual $GeneratedPack.executable_use_allowed -Name "$generatedStepId`_GENERATED_PACK_EXECUTABLE_USE_ALLOWED"
    if ([string]::IsNullOrWhiteSpace($GeneratedPack.purpose)) {
      Mark-Fail "$generatedStepId`_GENERATED_PACK_PURPOSE_MISSING"
    }
    if (@($GeneratedPack.expected_outputs).Count -lt 2) {
      Mark-Fail "$generatedStepId`_GENERATED_PACK_EXPECTED_OUTPUTS_TOO_SMALL=$(@($GeneratedPack.expected_outputs).Count)"
    }
    if ($null -eq $GeneratedPack.validator_contract) {
      Mark-Fail "$generatedStepId`_GENERATED_PACK_VALIDATOR_CONTRACT_MISSING"
    }
    if ($null -eq $GeneratedPack.proof_contract) {
      Mark-Fail "$generatedStepId`_GENERATED_PACK_PROOF_CONTRACT_MISSING"
    }
  }

  if ($null -ne $GeneratedResult) {
    Assert-Equals -Actual $GeneratedResult.status -Expected "PASS" -Name "$generatedStepId`_RESULT_STATUS"
    Assert-Equals -Actual $GeneratedResult.step_id -Expected $generatedStepId -Name "$generatedStepId`_RESULT_STEP_ID"
    Assert-Equals -Actual $GeneratedResult.executed_by -Expected "BUILDER_RUNTIME" -Name "$generatedStepId`_RESULT_EXECUTED_BY"
    Assert-True -Actual $GeneratedResult.bounded_mode -Name "$generatedStepId`_RESULT_BOUNDED_MODE"
    Assert-True -Actual $GeneratedResult.generated_pack_executed -Name "$generatedStepId`_RESULT_GENERATED_PACK_EXECUTED"
    Assert-Equals -Actual $GeneratedResult.next_allowed_step -Expected $NextAllowed -Name "$generatedStepId`_RESULT_NEXT_ALLOWED_STEP"
    Assert-NoForbiddenFlags -Object $GeneratedResult -Context "$generatedStepId`_RESULT"
  }

  try {
    $GeneratedRuntimeLog = Get-Content -LiteralPath $generatedRuntimeLogPath -Raw
    foreach ($requiredSignal in @(
      "GENERATED_SELF_BUILD_PACK=$generatedStepId",
      "GENERATED_PACK_EXECUTION_STATUS=PASS",
      "EXECUTED_BY=BUILDER_RUNTIME",
      "BOUNDED_MODE=True",
      "GENERATED_PACK_EXECUTED=True",
      "EXTERNAL_AGENT_CREATED=False",
      "GENERATED_PACK_NEXT_STEP=$NextAllowed"
    )) {
      if ($GeneratedRuntimeLog -notmatch [regex]::Escape($requiredSignal)) {
        Mark-Fail "$generatedStepId`_RUNTIME_LOG_SIGNAL_MISSING=$requiredSignal"
      }
    }
  } catch {
    Mark-Fail "$generatedStepId`_RUNTIME_LOG_READ_FAIL=$($_.Exception.Message)"
  }
}

if ($null -ne $ScaleTrialResult) {
  Assert-Equals -Actual $ScaleTrialResult.builder_generated_pack_count -Expected 3 -Name "SCALE_TRIAL_GENERATED_PACK_COUNT"
  Assert-Equals -Actual (@($ScaleTrialResult.generated_pack_ids).Count) -Expected 3 -Name "SCALE_TRIAL_GENERATED_PACK_IDS_COUNT"
  Assert-Equals -Actual $ScaleTrialResult.generated_packs_author -Expected "BUILDER_RUNTIME" -Name "SCALE_TRIAL_GENERATED_PACKS_AUTHOR"
  Assert-False -Actual $ScaleTrialResult.codex_authored_generated_packs -Name "SCALE_TRIAL_CODEX_AUTHORED_GENERATED_PACKS"
  Assert-True -Actual $ScaleTrialResult.generated_packs_admitted -Name "SCALE_TRIAL_GENERATED_PACKS_ADMITTED"
  Assert-True -Actual $ScaleTrialResult.generated_packs_executed -Name "SCALE_TRIAL_GENERATED_PACKS_EXECUTED"
  Assert-True -Actual $ScaleTrialResult.repo_state_sync_capsule_created -Name "SCALE_TRIAL_REPO_STATE_SYNC_CAPSULE_CREATED"
  Assert-True -Actual $ScaleTrialResult.restore_tool_created -Name "SCALE_TRIAL_RESTORE_TOOL_CREATED"
}

if ($null -ne $CurrentState) {
  Assert-Equals -Actual $CurrentState.status -Expected "PASS" -Name "CURRENT_STATE_STATUS"
  Assert-Equals -Actual $CurrentState.branch -Expected $ExpectedBranch -Name "CURRENT_STATE_BRANCH"
  Assert-Equals -Actual $CurrentState.accepted_head -Expected $Proof.source_head -Name "CURRENT_STATE_ACCEPTED_HEAD"
  Assert-Equals -Actual $CurrentState.last_accepted_phase -Expected $PreviousStepId -Name "CURRENT_STATE_LAST_ACCEPTED_PHASE"
  Assert-Equals -Actual $CurrentState.current_phase -Expected $StepId -Name "CURRENT_STATE_CURRENT_PHASE"
  Assert-Equals -Actual $CurrentState.current_line -Expected "SELF_BUILD" -Name "CURRENT_STATE_CURRENT_LINE"
  Assert-Equals -Actual $CurrentState.active_route_lock -Expected "AGENT_BUILDER_NEXT_15_STEPS_LOCK_V3_SELF_PACK_AUTHOR" -Name "CURRENT_STATE_ACTIVE_ROUTE_LOCK"
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
  Assert-Equals -Actual $ProofPointer.last_accepted_proof -Expected $PreviousProofPath -Name "PROOF_POINTER_LAST_ACCEPTED_PROOF"
  Assert-Equals -Actual $ProofPointer.pending_current_proof -Expected $ProofPath -Name "PROOF_POINTER_PENDING_CURRENT_PROOF"
}

if ($null -ne $Proof) {
  Assert-True -Actual $Proof.runtime_executed -Name "PROOF_RUNTIME_EXECUTED"
  Assert-True -Actual $Proof.builder_runtime_invoked -Name "PROOF_BUILDER_RUNTIME_INVOKED"
  Assert-Equals -Actual $Proof.builder_generated_pack_count -Expected 3 -Name "PROOF_BUILDER_GENERATED_PACK_COUNT"
  Assert-Equals -Actual (@($Proof.generated_pack_ids).Count) -Expected 3 -Name "PROOF_GENERATED_PACK_IDS_COUNT"
  Assert-Equals -Actual $Proof.generated_packs_author -Expected "BUILDER_RUNTIME" -Name "PROOF_GENERATED_PACKS_AUTHOR"
  Assert-False -Actual $Proof.codex_authored_generated_packs -Name "PROOF_CODEX_AUTHORED_GENERATED_PACKS"
  Assert-True -Actual $Proof.codex_bootstrap_used -Name "PROOF_CODEX_BOOTSTRAP_USED"
  Assert-True -Actual $Proof.generated_packs_admitted -Name "PROOF_GENERATED_PACKS_ADMITTED"
  Assert-True -Actual $Proof.generated_packs_executed -Name "PROOF_GENERATED_PACKS_EXECUTED"
  Assert-True -Actual $Proof.repo_state_sync_capsule_created -Name "PROOF_REPO_STATE_SYNC_CAPSULE_CREATED"
  Assert-True -Actual $Proof.restore_tool_created -Name "PROOF_RESTORE_TOOL_CREATED"
  Assert-Equals -Actual $Proof.current_line -Expected "SELF_BUILD" -Name "PROOF_CURRENT_LINE"
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
  Write-Output "PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE140 validation failed."
}
