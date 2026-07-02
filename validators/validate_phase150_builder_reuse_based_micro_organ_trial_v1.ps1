param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase150ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase150ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase150ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE150_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Assert-Phase150ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE150_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase150ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE150_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase150ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE150_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase150StatusPath {
  param([string]$StatusLine)

  if ($StatusLine -match '^.. (.+)$') {
    return ($Matches[1] -replace '\\', '/')
  }
  return ($StatusLine -replace '\\', '/')
}

try {
  $StepId = "PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1"
  $RunId = "PHASE150_SELF_BUILD_IGNITION_BRIDGE_001"
  $NextAllowedStep = "PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1"
  $ReusedCapabilityId = "self_learning_memory"
  $MissingCapability = "learning_card_reuse_advisor"
  $ProgramId = "PHASE150_LEARNING_CARD_REUSE_ADVISOR_SELF_BUILD_PROGRAM_CANDIDATE"
  $SandboxRoot = "living_learning_environment/sandbox/$RunId"
  $RouteAlignmentPath = "route_change_requests/PHASE150_SELF_BUILD_IGNITION_ALIGNMENT_REQUEST.md"
  $Phase149ProofPath = "proofs/self_development/PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1.json"
  $Phase149ProposalPath = "living_learning_environment/proposals/PHASE149_REUSE_PROPOSAL.json"
  $Phase149LearningCardPath = "knowledge_library/learning_cards/PHASE149_CAPABILITY_REUSE_LEARNING_CARD.json"
  $SourcePolicyPath = "source_registry/source_policy.json"
  $TrustedSourcesPath = "source_registry/trusted_sources.json"
  $CapabilityPath = "capability_shelf/capabilities/self_learning_memory.json"
  $SelfBuildIntentPath = "$SandboxRoot/self_build_intent.json"
  $ProgramCandidatePath = "$SandboxRoot/self_build_program_candidate.json"
  $ProgramContractPath = "$SandboxRoot/self_build_program_contract.json"
  $AdmissionChecklistPath = "$SandboxRoot/admission_checklist.json"
  $FutureExecutionPlanPath = "$SandboxRoot/future_execution_plan.json"
  $TrialTracePath = "$SandboxRoot/trial_trace.json"
  $ModuleRequestPath = "living_learning_environment/module_requests/PHASE150_SELF_BUILD_PROGRAM_GENERATOR_REQUEST.json"
  $PromotionCandidatePath = "living_learning_environment/promotion_candidates/PHASE150_SELF_BUILD_PROGRAM_CANDIDATE_PROMOTION_CANDIDATE.json"
  $ResultPath = "self_control/BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_RESULT.json"
  $ReportPath = "reports/self_development/PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1_REPORT.json"
  $ProofPath = "proofs/self_development/PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1.json"

  $RepoRoot = Resolve-Phase150ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot

  foreach ($identityFile in @(
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1"
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase150ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE150_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }

  foreach ($requiredPath in @(
    $RouteAlignmentPath,
    "modules/invoke_builder_reuse_based_micro_organ_trial_001.ps1",
    "validators/validate_phase150_builder_reuse_based_micro_organ_trial_v1.ps1",
    $Phase149ProofPath,
    $Phase149ProposalPath,
    $Phase149LearningCardPath,
    $SourcePolicyPath,
    $TrustedSourcesPath,
    $CapabilityPath,
    $SelfBuildIntentPath,
    $ProgramCandidatePath,
    $ProgramContractPath,
    $AdmissionChecklistPath,
    $FutureExecutionPlanPath,
    $TrialTracePath,
    $ModuleRequestPath,
    $PromotionCandidatePath,
    $ResultPath,
    $ReportPath,
    $ProofPath
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase150ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE150_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $AllowedExact = @(
    $RouteAlignmentPath,
    "modules/invoke_builder_reuse_based_micro_organ_trial_001.ps1",
    "validators/validate_phase150_builder_reuse_based_micro_organ_trial_v1.ps1",
    $SelfBuildIntentPath,
    $ProgramCandidatePath,
    $ProgramContractPath,
    $AdmissionChecklistPath,
    $FutureExecutionPlanPath,
    $TrialTracePath,
    $ModuleRequestPath,
    $PromotionCandidatePath,
    $ResultPath,
    $ReportPath,
    $ProofPath
  )
  $StatusLines = @(git status --short --untracked-files=all)
  foreach ($line in $StatusLines) {
    $path = Get-Phase150StatusPath -StatusLine $line
    if (-not ($AllowedExact -contains $path)) {
      throw "PHASE150_VALIDATE_CHANGE_OUTSIDE_ALLOWED_SCOPE=$line"
    }
  }

  $ProtectedStatus = @(git status --short --untracked-files=all -- `
    orchestrator/run.ps1 `
    TASK_QUEUE.json `
    GENESIS_STATE.json `
    CAPABILITY_ROADMAP.json `
    packs/registry.json `
    capability_shelf `
    route_locks `
    runtime_sessions/builder_life_loop/current `
    generated_agents `
    applied_agents `
    proofs/self_development/PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1.json `
    proofs/self_development/PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1.json `
    proofs/self_development/PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1.json `
    proofs/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1.json `
    proofs/self_development/PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1.json `
    proofs/self_development/PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1.json `
    proofs/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1.json `
    proofs/self_development/PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1.json `
    reports/self_development/PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1_REPORT.json `
    reports/self_development/PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1_REPORT.json `
    reports/self_development/PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1_REPORT.json `
    reports/self_development/PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1_REPORT.json 2>$null)
  if ($ProtectedStatus.Count -gt 0) {
    throw "PHASE150_VALIDATE_PROTECTED_SCOPE_CHANGED=$($ProtectedStatus -join '; ')"
  }

  $Phase149Proof = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $Phase149ProofPath
  Assert-Phase150ValidatorEquals -Actual $Phase149Proof.status -Expected "PASS" -Name "phase149_status"
  Assert-Phase150ValidatorEquals -Actual $Phase149Proof.selected_capability_id -Expected $ReusedCapabilityId -Name "phase149_selected_capability_id"
  Assert-Phase150ValidatorEquals -Actual $Phase149Proof.next_allowed_step -Expected $StepId -Name "phase149_next_allowed_step"

  $Phase149Proposal = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $Phase149ProposalPath
  $Phase149LearningCard = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $Phase149LearningCardPath
  Assert-Phase150ValidatorEquals -Actual $Phase149Proposal.status -Expected "PASS" -Name "phase149_proposal_status"
  Assert-Phase150ValidatorEquals -Actual $Phase149LearningCard.status -Expected "PASS" -Name "phase149_learning_card_status"

  $SourcePolicy = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $SourcePolicyPath
  foreach ($field in @("default_trust","external_fetch_allowed","install_allowed","executable_use_allowed")) {
    if (-not ($SourcePolicy.PSObject.Properties.Name -contains $field)) {
      throw "PHASE150_VALIDATE_SOURCE_POLICY_FIELD_MISSING=$field"
    }
  }
  Assert-Phase150ValidatorFalse -Actual $SourcePolicy.default_trust -Name "source_policy_default_trust"
  Assert-Phase150ValidatorFalse -Actual $SourcePolicy.external_fetch_allowed -Name "source_policy_external_fetch_allowed"
  Assert-Phase150ValidatorFalse -Actual $SourcePolicy.install_allowed -Name "source_policy_install_allowed"
  Assert-Phase150ValidatorFalse -Actual $SourcePolicy.executable_use_allowed -Name "source_policy_executable_use_allowed"

  $TrustedSources = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $TrustedSourcesPath
  Assert-Phase150ValidatorEquals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count"
  Assert-Phase150ValidatorEquals -Actual @($TrustedSources.trusted_sources).Count -Expected 0 -Name "trusted_sources_empty"

  $Capability = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $CapabilityPath
  Assert-Phase150ValidatorEquals -Actual $Capability.capability_id -Expected $ReusedCapabilityId -Name "capability_id"

  if (-not $ProgramCandidatePath.StartsWith("living_learning_environment/sandbox/", [System.StringComparison]::Ordinal)) {
    throw "PHASE150_VALIDATE_PROGRAM_CANDIDATE_OUTSIDE_SANDBOX=$ProgramCandidatePath"
  }

  $SelfBuildIntent = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $SelfBuildIntentPath
  $ProgramCandidate = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $ProgramCandidatePath
  $ProgramContract = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $ProgramContractPath
  $AdmissionChecklist = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $AdmissionChecklistPath
  $FutureExecutionPlan = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $FutureExecutionPlanPath
  $TrialTrace = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $TrialTracePath
  $ModuleRequest = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $ModuleRequestPath
  $PromotionCandidate = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $PromotionCandidatePath
  $Result = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath

  foreach ($artifact in @($SelfBuildIntent, $ProgramCandidate, $ProgramContract, $AdmissionChecklist, $FutureExecutionPlan, $TrialTrace, $ModuleRequest, $PromotionCandidate, $Result, $Report, $Proof)) {
    Assert-Phase150ValidatorEquals -Actual $artifact.status -Expected "PASS" -Name "artifact_status"
    Assert-Phase150ValidatorEquals -Actual $artifact.next_allowed_step -Expected $NextAllowedStep -Name "artifact_next_allowed_step"
  }

  Assert-Phase150ValidatorTrue -Actual $SelfBuildIntent.gap_detected -Name "intent_gap_detected"
  Assert-Phase150ValidatorEquals -Actual $SelfBuildIntent.missing_capability -Expected $MissingCapability -Name "intent_missing_capability"
  Assert-Phase150ValidatorEquals -Actual $SelfBuildIntent.reused_capability_id -Expected $ReusedCapabilityId -Name "intent_reused_capability"
  Assert-Phase150ValidatorEquals -Actual $SelfBuildIntent.target_output -Expected "self_build_program_candidate" -Name "intent_target_output"
  Assert-Phase150ValidatorFalse -Actual $SelfBuildIntent.accepted_state_mutation_allowed -Name "intent_accepted_state_mutation_allowed"
  Assert-Phase150ValidatorTrue -Actual $SelfBuildIntent.sandbox_only -Name "intent_sandbox_only"

  Assert-Phase150ValidatorEquals -Actual $ProgramCandidate.program_id -Expected $ProgramId -Name "candidate_program_id"
  Assert-Phase150ValidatorEquals -Actual $ProgramCandidate.program_status -Expected "CANDIDATE_NOT_ADMITTED" -Name "candidate_program_status"
  Assert-Phase150ValidatorTrue -Actual $ProgramCandidate.generated_by_builder_runtime -Name "candidate_generated_by_builder_runtime"
  Assert-Phase150ValidatorEquals -Actual $ProgramCandidate.target_micro_organ_id -Expected $MissingCapability -Name "candidate_target_micro_organ"
  Assert-Phase150ValidatorTrue -Actual $ProgramCandidate.validator_required -Name "candidate_validator_required"
  Assert-Phase150ValidatorTrue -Actual $ProgramCandidate.admission_required -Name "candidate_admission_required"
  foreach ($field in @("admitted","promoted","trusted","executed")) {
    Assert-Phase150ValidatorFalse -Actual $ProgramCandidate.$field -Name "candidate_$field"
  }

  foreach ($flag in @("external_fetch_performed","dependency_install_performed","executable_materials_used","accepted_state_mutated","external_agents_created","orchestrator_changed","route_lock_changed","current_runtime_changed","capability_shelf_mutated","production_adoption_allowed")) {
    Assert-Phase150ValidatorFalse -Actual $ProgramCandidate.safety_flags.$flag -Name "candidate_safety_$flag"
  }
  Assert-Phase150ValidatorTrue -Actual $ProgramCandidate.safety_flags.sandbox_only -Name "candidate_safety_sandbox_only"
  Assert-Phase150ValidatorEquals -Actual $ProgramCandidate.safety_flags.trusted_source_count -Expected 0 -Name "candidate_safety_trusted_source_count"

  Assert-Phase150ValidatorEquals -Actual $ProgramContract.target_micro_organ_id -Expected $MissingCapability -Name "contract_target_micro_organ"
  if (@($ProgramContract.forbidden_actions).Count -lt 5) {
    throw "PHASE150_VALIDATE_CONTRACT_FORBIDDEN_ACTIONS_TOO_SHORT"
  }
  if (@($ProgramContract.proof_requirements).Count -lt 5) {
    throw "PHASE150_VALIDATE_CONTRACT_PROOF_REQUIREMENTS_TOO_SHORT"
  }

  Assert-Phase150ValidatorTrue -Actual $AdmissionChecklist.requires_owner_approval -Name "admission_requires_owner_approval"
  Assert-Phase150ValidatorTrue -Actual $AdmissionChecklist.requires_validator -Name "admission_requires_validator"
  Assert-Phase150ValidatorTrue -Actual $AdmissionChecklist.requires_sandbox_execution -Name "admission_requires_sandbox_execution"
  Assert-Phase150ValidatorFalse -Actual $AdmissionChecklist.accepted_state_change_requested -Name "admission_accepted_state_change_requested"

  Assert-Phase150ValidatorEquals -Actual $FutureExecutionPlan.plan_for_future_phase -Expected "PHASE152" -Name "future_plan_phase"
  Assert-Phase150ValidatorEquals -Actual $FutureExecutionPlan.plan_status -Expected "FUTURE_NOT_EXECUTED" -Name "future_plan_status"
  Assert-Phase150ValidatorFalse -Actual $FutureExecutionPlan.execution_now -Name "future_plan_execution_now"
  Assert-Phase150ValidatorTrue -Actual $FutureExecutionPlan.sandbox_only -Name "future_plan_sandbox_only"

  Assert-Phase150ValidatorEquals -Actual $TrialTrace.reused_capability_id -Expected $ReusedCapabilityId -Name "trial_trace_reused_capability"
  Assert-Phase150ValidatorTrue -Actual $TrialTrace.sandbox_only -Name "trial_trace_sandbox_only"
  Assert-Phase150ValidatorFalse -Actual $TrialTrace.accepted_state_mutated -Name "trial_trace_accepted_state_mutated"
  Assert-Phase150ValidatorTrue -Actual $TrialTrace.self_build_program_candidate_created -Name "trial_trace_candidate_created"

  Assert-Phase150ValidatorFalse -Actual $ModuleRequest.codex_required_now -Name "module_request_codex_required_now"
  Assert-Phase150ValidatorTrue -Actual $ModuleRequest.builder_generated_candidate_exists -Name "module_request_builder_candidate_exists"
  Assert-Phase150ValidatorFalse -Actual $ModuleRequest.accepted_state_change_requested -Name "module_request_accepted_state_change_requested"
  Assert-Phase150ValidatorTrue -Actual $ModuleRequest.sandbox_only -Name "module_request_sandbox_only"

  Assert-Phase150ValidatorEquals -Actual $PromotionCandidate.promotion_status -Expected "NOT_PROMOTED" -Name "promotion_status"
  Assert-Phase150ValidatorTrue -Actual $PromotionCandidate.owner_approval_required -Name "promotion_owner_approval_required"
  Assert-Phase150ValidatorFalse -Actual $PromotionCandidate.accepted_state_change_requested -Name "promotion_accepted_state_change_requested"
  Assert-Phase150ValidatorTrue -Actual $PromotionCandidate.validator_required_before_promotion -Name "promotion_validator_required_before_promotion"
  foreach ($field in @("trusted","accepted","promoted","executed")) {
    Assert-Phase150ValidatorFalse -Actual $PromotionCandidate.$field -Name "promotion_$field"
  }

  foreach ($artifact in @($Result, $Proof)) {
    Assert-Phase150ValidatorTrue -Actual $artifact.phase149_verified -Name "phase149_verified"
    Assert-Phase150ValidatorEquals -Actual $artifact.reused_capability_id -Expected $ReusedCapabilityId -Name "reused_capability_id"
    Assert-Phase150ValidatorTrue -Actual $artifact.gap_detected -Name "gap_detected"
    Assert-Phase150ValidatorEquals -Actual $artifact.missing_capability -Expected $MissingCapability -Name "missing_capability"
    Assert-Phase150ValidatorTrue -Actual $artifact.self_build_intent_created -Name "self_build_intent_created"
    Assert-Phase150ValidatorTrue -Actual $artifact.self_build_program_candidate_created -Name "self_build_program_candidate_created"
    Assert-Phase150ValidatorTrue -Actual $artifact.self_build_program_contract_created -Name "self_build_program_contract_created"
    Assert-Phase150ValidatorTrue -Actual $artifact.admission_checklist_created -Name "admission_checklist_created"
    Assert-Phase150ValidatorTrue -Actual $artifact.future_execution_plan_created -Name "future_execution_plan_created"
    Assert-Phase150ValidatorTrue -Actual $artifact.module_request_created -Name "module_request_created"
    Assert-Phase150ValidatorTrue -Actual $artifact.promotion_candidate_created -Name "promotion_candidate_created"
    Assert-Phase150ValidatorTrue -Actual $artifact.sandbox_only -Name "sandbox_only"
    Assert-Phase150ValidatorEquals -Actual $artifact.promotion_status -Expected "NOT_PROMOTED" -Name "artifact_promotion_status"
    Assert-Phase150ValidatorTrue -Actual $artifact.owner_approval_required -Name "owner_approval_required"
    Assert-Phase150ValidatorFalse -Actual $artifact.accepted_state_change_requested -Name "accepted_state_change_requested"
    foreach ($flag in @("external_fetch_performed","dependency_install_performed","executable_materials_used","accepted_state_mutated","external_agents_created","orchestrator_changed","route_lock_changed","current_runtime_changed","capability_shelf_mutated")) {
      Assert-Phase150ValidatorFalse -Actual $artifact.$flag -Name $flag
    }
    Assert-Phase150ValidatorEquals -Actual $artifact.trusted_source_count -Expected 0 -Name "trusted_source_count"
    Assert-Phase150ValidatorEquals -Actual $artifact.queue_after -Expected "NONE" -Name "queue_after"
  }

  Assert-Phase150ValidatorEquals -Actual $Proof.step_id -Expected $StepId -Name "proof_step_id"
  Assert-Phase150ValidatorEquals -Actual $Proof.run_id -Expected $RunId -Name "proof_run_id"

  $Queue = Read-Phase150ValidatorJson -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
  Assert-Phase150ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  Write-Host "PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_VALIDATE_RESULT=PASS"
  Write-Host "REUSED_CAPABILITY_ID=$ReusedCapabilityId"
  Write-Host "MISSING_CAPABILITY=$MissingCapability"
  Write-Host "SELF_BUILD_PROGRAM_CANDIDATE_CREATED=True"
  Write-Host "PROMOTION_STATUS=NOT_PROMOTED"
  Write-Host "OWNER_APPROVAL_REQUIRED=True"
  Write-Host "ACCEPTED_STATE_CHANGE_REQUESTED=False"
  Write-Host "EXTERNAL_FETCH_PERFORMED=False"
  Write-Host "DEPENDENCY_INSTALL_PERFORMED=False"
  Write-Host "EXECUTABLE_MATERIALS_USED=False"
  Write-Host "ACCEPTED_STATE_MUTATED=False"
  Write-Host "EXTERNAL_AGENTS_CREATED=False"
  Write-Host "ORCHESTRATOR_CHANGED=False"
  Write-Host "ROUTE_LOCK_CHANGED=False"
  Write-Host "CURRENT_RUNTIME_CHANGED=False"
  Write-Host "CAPABILITY_SHELF_MUTATED=False"
  Write-Host "TRUSTED_SOURCE_COUNT=0"
  Write-Host "QUEUE_AFTER=NONE"
  Write-Host "NEXT_ALLOWED_STEP=PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1"
} catch {
  Write-Host "PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE150_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  Pop-Location
}
