param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase152ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase152ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase152ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE152_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Assert-Phase152ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE152_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase152ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE152_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase152ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE152_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase152StatusPath {
  param([string]$StatusLine)

  if ($StatusLine -match '^.. (.+)$') {
    return ($Matches[1] -replace '\\', '/')
  }
  return ($StatusLine -replace '\\', '/')
}

try {
  $StepId = "PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1"
  $RunId = "PHASE152_MAXIMAL_BODY_ORGAN_PACK_AND_SANDBOX_EXECUTION_001"
  $NextAllowedStep = "PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1"
  $ProgramId = "PHASE150_LEARNING_CARD_REUSE_ADVISOR_SELF_BUILD_PROGRAM_CANDIDATE"
  $TargetMicroOrganId = "learning_card_reuse_advisor"
  $ExecutionMode = "declarative_json_only"
  $ExecutionScope = "sandbox_only"
  $BodyPackId = "BUILDER_BODY_ORGAN_PACK_V1"
  $BodyPackStatus = "BODY_ORGAN_PACK_AVAILABLE_IN_LLE"
  $BodyRoot = "living_learning_environment/body"
  $OrganRoot = "$BodyRoot/organs"
  $ContractRoot = "$BodyRoot/contracts"
  $SandboxRoot = "living_learning_environment/sandbox/$RunId"
  $RouteAlignmentPath = "route_change_requests/PHASE152_MAXIMAL_BODY_ORGAN_PACK_ALIGNMENT_REQUEST.md"
  $BodyPackPath = "$BodyRoot/BUILDER_BODY_ORGAN_PACK_V1.json"
  $BodyRegistryPath = "$BodyRoot/body_registry.json"
  $BodyPolicyPath = "$BodyRoot/body_policy.json"
  $BodyRuntimeContractPath = "$BodyRoot/body_runtime_contract.json"
  $BodySafetyBoundariesPath = "$BodyRoot/body_safety_boundaries.json"
  $BodyPortabilityManifestPath = "$BodyRoot/body_portability_manifest.json"
  $BodyOrganContractPath = "$ContractRoot/BODY_ORGAN_CONTRACT_V1.json"
  $ExecutorContractPath = "$ContractRoot/SELF_BUILD_SANDBOX_EXECUTOR_CONTRACT_V1.json"
  $DutyLoopContractPath = "$ContractRoot/DUTY_LOOP_CONTROLLER_CONTRACT_V1.json"
  $FailureRecoveryContractPath = "$ContractRoot/FAILURE_RECOVERY_CONTRACT_V1.json"
  $MemoryAbsorptionContractPath = "$ContractRoot/MEMORY_ABSORPTION_CONTRACT_V1.json"
  $PortabilityContractPath = "$ContractRoot/PORTABILITY_CONTRACT_V1.json"

  $Phase151ProofPath = "proofs/self_development/PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1.json"
  $Phase151TicketPath = "living_learning_environment/inner_loop/PHASE151_BRAIN_CELL_INNER_LOOP_IGNITION_001/sandbox_execution_ticket.json"
  $Phase151AdmissionDecisionPath = "living_learning_environment/inner_loop/PHASE151_BRAIN_CELL_INNER_LOOP_IGNITION_001/admission_decision.json"
  $Phase151ExecutionIntentionPath = "living_learning_environment/inner_loop/PHASE151_BRAIN_CELL_INNER_LOOP_IGNITION_001/execution_intention.json"
  $Phase151NextCyclePath = "living_learning_environment/inner_loop/PHASE151_BRAIN_CELL_INNER_LOOP_IGNITION_001/next_cycle_decision.json"
  $Phase150CandidatePath = "living_learning_environment/sandbox/PHASE150_SELF_BUILD_IGNITION_BRIDGE_001/self_build_program_candidate.json"
  $Phase150ContractPath = "living_learning_environment/sandbox/PHASE150_SELF_BUILD_IGNITION_BRIDGE_001/self_build_program_contract.json"
  $SourcePolicyPath = "source_registry/source_policy.json"
  $TrustedSourcesPath = "source_registry/trusted_sources.json"
  $CapabilityShelfRegistryPath = "capability_shelf/registry.json"
  $LearningCardPath = "knowledge_library/learning_cards/PHASE149_CAPABILITY_REUSE_LEARNING_CARD.json"
  $ReuseProposalPath = "living_learning_environment/proposals/PHASE149_REUSE_PROPOSAL.json"

  $RuntimeOutputs = @(
    "$SandboxRoot/body_activation_trace.json",
    "$SandboxRoot/self_state_observation.json",
    "$SandboxRoot/repo_observation.json",
    "$SandboxRoot/proof_memory_observation.json",
    "$SandboxRoot/task_intake_observation.json",
    "$SandboxRoot/goal_state_snapshot.json",
    "$SandboxRoot/gap_detection.json",
    "$SandboxRoot/failure_classification.json",
    "$SandboxRoot/internal_question.json",
    "$SandboxRoot/internal_answer_search.json",
    "$SandboxRoot/internal_answer.json",
    "$SandboxRoot/source_policy_guard_result.json",
    "$SandboxRoot/capability_shelf_read_result.json",
    "$SandboxRoot/execution_trace.json",
    "$SandboxRoot/self_build_program_execution_result.json",
    "$SandboxRoot/micro_organ_candidate.json",
    "$SandboxRoot/micro_organ_contract.json",
    "$SandboxRoot/input_example.json",
    "$SandboxRoot/output_example.json",
    "$SandboxRoot/validator_spec.json",
    "$SandboxRoot/sandbox_validation_result.json",
    "$SandboxRoot/rollback_plan.json",
    "$SandboxRoot/quarantine_plan.json",
    "$SandboxRoot/memory_absorption_candidate.json",
    "$SandboxRoot/self_model_update_candidate.json",
    "$SandboxRoot/next_cycle_decision.json",
    "$SandboxRoot/duty_loop_readiness.json",
    "$SandboxRoot/portability_readiness_note.json"
  )
  $ResultPath = "self_control/BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_RESULT.json"
  $ReportPath = "reports/self_development/PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1_REPORT.json"
  $ProofPath = "proofs/self_development/PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1.json"

  $OrganIds = @(
    "SELF_STATE_SENSOR_V1",
    "REPO_OBSERVATION_SENSOR_V1",
    "PROOF_MEMORY_SENSOR_V1",
    "TASK_INTAKE_SENSOR_V1",
    "GOAL_STATE_MANAGER_V1",
    "CAPABILITY_GAP_DETECTOR_V1",
    "FAILURE_CLASSIFIER_V1",
    "INTERNAL_QUESTION_ENGINE_V1",
    "INTERNAL_ANSWER_SEARCHER_V1",
    "KNOWLEDGE_MEMORY_READER_V1",
    "CAPABILITY_SHELF_READER_V1",
    "SOURCE_POLICY_GUARD_V1",
    "ORGAN_COMPOSER_V1",
    "SELF_BUILD_PROGRAM_COMPOSER_V1",
    "SELF_BUILD_SANDBOX_EXECUTOR_V1",
    "SANDBOX_VALIDATION_RUNNER_V1",
    "SANDBOX_ROLLBACK_MANAGER_V1",
    "QUARANTINE_MANAGER_V1",
    "MEMORY_ABSORBER_V1",
    "SELF_MODEL_UPDATE_CANDIDATE_WRITER_V1",
    "NEXT_CYCLE_DECIDER_V1",
    "DUTY_LOOP_CONTROLLER_V1",
    "OWNER_ESCALATION_GATE_V1",
    "MIGRATION_PORTABILITY_PREPARER_V1"
  )
  $OrganPaths = @($OrganIds | ForEach-Object { "$OrganRoot/$_.json" })
  $BodyArchitecturePaths = @($BodyPackPath, $BodyRegistryPath, $BodyPolicyPath, $BodyRuntimeContractPath, $BodySafetyBoundariesPath, $BodyPortabilityManifestPath)
  $BodyContractPaths = @($BodyOrganContractPath, $ExecutorContractPath, $DutyLoopContractPath, $FailureRecoveryContractPath, $MemoryAbsorptionContractPath, $PortabilityContractPath)

  $RepoRoot = Resolve-Phase152ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot

  foreach ($identityFile in @(
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1"
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase152ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE152_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }

  foreach ($requiredPath in @(
    $RouteAlignmentPath,
    "modules/invoke_builder_executes_admitted_self_build_program_in_sandbox_001.ps1",
    "validators/validate_phase152_builder_executes_admitted_self_build_program_in_sandbox_v1.ps1",
    $Phase151ProofPath,
    $Phase151TicketPath,
    $Phase151AdmissionDecisionPath,
    $Phase151ExecutionIntentionPath,
    $Phase151NextCyclePath,
    $Phase150CandidatePath,
    $Phase150ContractPath,
    $SourcePolicyPath,
    $TrustedSourcesPath,
    $CapabilityShelfRegistryPath,
    $LearningCardPath,
    $ReuseProposalPath,
    $ResultPath,
    $ReportPath,
    $ProofPath
  ) + $BodyArchitecturePaths + $BodyContractPaths + $OrganPaths + $RuntimeOutputs) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase152ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE152_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  foreach ($path in $RuntimeOutputs) {
    if (-not $path.StartsWith("$SandboxRoot/", [System.StringComparison]::Ordinal)) {
      throw "PHASE152_VALIDATE_RUNTIME_OUTPUT_OUTSIDE_SANDBOX=$path"
    }
  }

  $AllowedExact = @(
    $RouteAlignmentPath,
    "modules/invoke_builder_executes_admitted_self_build_program_in_sandbox_001.ps1",
    "validators/validate_phase152_builder_executes_admitted_self_build_program_in_sandbox_v1.ps1",
    $ResultPath,
    $ReportPath,
    $ProofPath
  ) + $BodyArchitecturePaths + $BodyContractPaths + $OrganPaths + $RuntimeOutputs
  $StatusLines = @(git status --short --untracked-files=all)
  foreach ($line in $StatusLines) {
    $path = Get-Phase152StatusPath -StatusLine $line
    if (-not ($AllowedExact -contains $path)) {
      throw "PHASE152_VALIDATE_CHANGE_OUTSIDE_ALLOWED_SCOPE=$line"
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
    .github/workflows `
    package.json `
    package-lock.json `
    pnpm-lock.yaml `
    yarn.lock `
    requirements.txt `
    pyproject.toml `
    poetry.lock `
    proofs/self_development/PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1.json `
    proofs/self_development/PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1.json `
    proofs/self_development/PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1.json `
    proofs/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1.json `
    proofs/self_development/PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1.json `
    proofs/self_development/PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1.json `
    proofs/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1.json `
    proofs/self_development/PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1.json `
    proofs/self_development/PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1.json `
    proofs/self_development/PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1.json `
    reports/self_development/PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1_REPORT.json `
    reports/self_development/PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1_REPORT.json `
    reports/self_development/PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1_REPORT.json `
    reports/self_development/PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1_REPORT.json `
    reports/self_development/PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1_REPORT.json 2>$null)
  if ($ProtectedStatus.Count -gt 0) {
    throw "PHASE152_VALIDATE_PROTECTED_SCOPE_CHANGED=$($ProtectedStatus -join '; ')"
  }

  $Phase151Proof = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $Phase151ProofPath
  Assert-Phase152ValidatorEquals -Actual $Phase151Proof.status -Expected "PASS" -Name "phase151_status"
  Assert-Phase152ValidatorEquals -Actual $Phase151Proof.next_allowed_step -Expected $StepId -Name "phase151_next_allowed_step"
  Assert-Phase152ValidatorEquals -Actual $Phase151Proof.admission_status -Expected "ADMITTED_FOR_SANDBOX_EXECUTION_ONLY" -Name "phase151_admission_status"
  Assert-Phase152ValidatorTrue -Actual $Phase151Proof.execution_allowed -Name "phase151_execution_allowed"
  Assert-Phase152ValidatorEquals -Actual $Phase151Proof.execution_scope -Expected $ExecutionScope -Name "phase151_execution_scope"
  Assert-Phase152ValidatorFalse -Actual $Phase151Proof.codex_needed_for_next_step -Name "phase151_codex_needed_for_next_step"

  $Ticket = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $Phase151TicketPath
  Assert-Phase152ValidatorEquals -Actual $Ticket.ticket_status -Expected "ISSUED_FOR_PHASE152_ONLY" -Name "ticket_status"
  Assert-Phase152ValidatorEquals -Actual $Ticket.execution_target -Expected $ProgramId -Name "ticket_execution_target"
  Assert-Phase152ValidatorEquals -Actual $Ticket.execution_scope -Expected $ExecutionScope -Name "ticket_execution_scope"
  Assert-Phase152ValidatorEquals -Actual $Ticket.valid_for_step -Expected $StepId -Name "ticket_valid_for_step"

  $AdmissionDecision = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $Phase151AdmissionDecisionPath
  Assert-Phase152ValidatorEquals -Actual $AdmissionDecision.admission_status -Expected "ADMITTED_FOR_SANDBOX_EXECUTION_ONLY" -Name "admission_status"
  Assert-Phase152ValidatorTrue -Actual $AdmissionDecision.execution_allowed -Name "admission_execution_allowed"
  Assert-Phase152ValidatorEquals -Actual $AdmissionDecision.execution_scope -Expected $ExecutionScope -Name "admission_execution_scope"

  $ExecutionIntention = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $Phase151ExecutionIntentionPath
  Assert-Phase152ValidatorEquals -Actual $ExecutionIntention.intention_type -Expected "EXECUTE_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX" -Name "execution_intention_type"
  Assert-Phase152ValidatorEquals -Actual $ExecutionIntention.intended_next_step -Expected $StepId -Name "execution_intention_next_step"

  $Phase151NextCycle = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $Phase151NextCyclePath
  Assert-Phase152ValidatorEquals -Actual $Phase151NextCycle.next_action -Expected "EXECUTE_IN_SANDBOX" -Name "phase151_next_action"

  $Phase150Candidate = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $Phase150CandidatePath
  Assert-Phase152ValidatorEquals -Actual $Phase150Candidate.program_status -Expected "CANDIDATE_NOT_ADMITTED" -Name "phase150_candidate_program_status"
  Assert-Phase152ValidatorEquals -Actual $Phase150Candidate.target_micro_organ_id -Expected $TargetMicroOrganId -Name "phase150_candidate_target_micro_organ"

  $SourcePolicy = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $SourcePolicyPath
  Assert-Phase152ValidatorFalse -Actual $SourcePolicy.default_trust -Name "source_policy_default_trust"
  Assert-Phase152ValidatorFalse -Actual $SourcePolicy.external_fetch_allowed -Name "source_policy_external_fetch_allowed"
  Assert-Phase152ValidatorFalse -Actual $SourcePolicy.install_allowed -Name "source_policy_install_allowed"
  Assert-Phase152ValidatorFalse -Actual $SourcePolicy.executable_use_allowed -Name "source_policy_executable_use_allowed"

  $TrustedSources = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $TrustedSourcesPath
  Assert-Phase152ValidatorEquals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count"
  Assert-Phase152ValidatorEquals -Actual @($TrustedSources.trusted_sources).Count -Expected 0 -Name "trusted_sources_empty"

  $BodyPack = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $BodyPackPath
  Assert-Phase152ValidatorEquals -Actual $BodyPack.body_pack_id -Expected $BodyPackId -Name "body_pack_id"
  Assert-Phase152ValidatorEquals -Actual $BodyPack.body_pack_status -Expected $BodyPackStatus -Name "body_pack_status"
  Assert-Phase152ValidatorEquals -Actual $BodyPack.body_organ_count -Expected 24 -Name "body_pack_organ_count"
  Assert-Phase152ValidatorFalse -Actual $BodyPack.accepted_capability -Name "body_pack_accepted_capability"

  $BodyRegistry = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $BodyRegistryPath
  Assert-Phase152ValidatorEquals -Actual $BodyRegistry.body_pack_id -Expected $BodyPackId -Name "body_registry_pack_id"
  Assert-Phase152ValidatorEquals -Actual $BodyRegistry.body_pack_status -Expected $BodyPackStatus -Name "body_registry_status"
  Assert-Phase152ValidatorEquals -Actual $BodyRegistry.body_organ_count -Expected 24 -Name "body_registry_count"
  Assert-Phase152ValidatorEquals -Actual @($BodyRegistry.organs).Count -Expected 24 -Name "body_registry_organs_count"
  foreach ($organ in @($BodyRegistry.organs)) {
    foreach ($field in @("organ_id","organ_type","purpose","allowed_inputs","allowed_outputs","forbidden_actions","status","accepted_capability")) {
      if (-not ($organ.PSObject.Properties.Name -contains $field)) {
        throw "PHASE152_VALIDATE_BODY_REGISTRY_ORGAN_FIELD_MISSING=$($organ.organ_id):$field"
      }
    }
    if (-not ($OrganIds -contains $organ.organ_id)) {
      throw "PHASE152_VALIDATE_UNEXPECTED_BODY_ORGAN=$($organ.organ_id)"
    }
    Assert-Phase152ValidatorEquals -Actual $organ.status -Expected "BODY_ORGAN_AVAILABLE_IN_LLE" -Name "registry_organ_status"
    Assert-Phase152ValidatorFalse -Actual $organ.accepted_capability -Name "registry_organ_accepted_capability"
  }

  foreach ($organId in $OrganIds) {
    $organ = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path "$OrganRoot/$organId.json"
    Assert-Phase152ValidatorEquals -Actual $organ.status -Expected "PASS" -Name "organ_file_status"
    Assert-Phase152ValidatorEquals -Actual $organ.organ_id -Expected $organId -Name "organ_file_id"
    Assert-Phase152ValidatorEquals -Actual $organ.organ_status -Expected "BODY_ORGAN_AVAILABLE_IN_LLE" -Name "organ_file_organ_status"
    Assert-Phase152ValidatorFalse -Actual $organ.accepted_capability -Name "organ_file_accepted_capability"
  }

  $BodyPolicy = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $BodyPolicyPath
  Assert-Phase152ValidatorTrue -Actual $BodyPolicy.body_is_not_accepted_core -Name "body_is_not_accepted_core"
  Assert-Phase152ValidatorTrue -Actual $BodyPolicy.body_organs_are_lle_organs -Name "body_organs_are_lle_organs"
  foreach ($flag in @("accepted_state_mutation_allowed","arbitrary_code_execution_allowed","external_fetch_allowed","install_allowed","capability_shelf_mutation_allowed","generated_agents_allowed","applied_agents_allowed")) {
    Assert-Phase152ValidatorFalse -Actual $BodyPolicy.$flag -Name "body_policy_$flag"
  }
  Assert-Phase152ValidatorTrue -Actual $BodyPolicy.owner_approval_required_for_promotion -Name "body_policy_owner_approval_required_for_promotion"

  $BodyRuntimeContract = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $BodyRuntimeContractPath
  Assert-Phase152ValidatorEquals -Actual $BodyRuntimeContract.allowed_execution_mode -Expected $ExecutionMode -Name "body_runtime_execution_mode"
  Assert-Phase152ValidatorEquals -Actual $BodyRuntimeContract.allowed_scope -Expected $ExecutionScope -Name "body_runtime_allowed_scope"
  Assert-Phase152ValidatorFalse -Actual $BodyRuntimeContract.accepted_state_mutation_allowed -Name "body_runtime_accepted_state_mutation_allowed"

  $BodySafetyBoundaries = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $BodySafetyBoundariesPath
  foreach ($flag in @("accepted_state_mutation_allowed","arbitrary_code_execution_allowed","external_fetch_allowed","install_allowed","executable_materials_allowed","capability_shelf_mutation_allowed","generated_agents_allowed","applied_agents_allowed","route_lock_mutation_allowed","orchestrator_mutation_allowed","migration_allowed_now")) {
    Assert-Phase152ValidatorFalse -Actual $BodySafetyBoundaries.$flag -Name "body_safety_$flag"
  }

  $BodyPortabilityManifest = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $BodyPortabilityManifestPath
  Assert-Phase152ValidatorTrue -Actual $BodyPortabilityManifest.portability_prepared -Name "portability_prepared"
  Assert-Phase152ValidatorFalse -Actual $BodyPortabilityManifest.migration_performed -Name "portability_migration_performed"

  foreach ($contractPath in $BodyContractPaths) {
    $contract = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $contractPath
    Assert-Phase152ValidatorEquals -Actual $contract.status -Expected "PASS" -Name "body_contract_status"
  }

  $ExecutorContract = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $ExecutorContractPath
  Assert-Phase152ValidatorEquals -Actual $ExecutorContract.executor_id -Expected "SELF_BUILD_SANDBOX_EXECUTOR_V1" -Name "executor_contract_executor_id"
  Assert-Phase152ValidatorEquals -Actual $ExecutorContract.execution_mode -Expected $ExecutionMode -Name "executor_contract_execution_mode"
  Assert-Phase152ValidatorEquals -Actual $ExecutorContract.allowed_scope -Expected $ExecutionScope -Name "executor_contract_allowed_scope"
  foreach ($flag in @("arbitrary_code_execution_allowed","external_fetch_allowed","install_allowed","accepted_state_mutation_allowed","capability_shelf_mutation_allowed","generated_agents_allowed","applied_agents_allowed")) {
    Assert-Phase152ValidatorFalse -Actual $ExecutorContract.$flag -Name "executor_contract_$flag"
  }

  $BodyActivationTrace = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path "$SandboxRoot/body_activation_trace.json"
  Assert-Phase152ValidatorEquals -Actual $BodyActivationTrace.body_organ_count -Expected 24 -Name "activation_trace_organ_count"
  Assert-Phase152ValidatorEquals -Actual @($BodyActivationTrace.activated_organs).Count -Expected 24 -Name "activation_trace_organs_count"

  $ExecutionTrace = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path "$SandboxRoot/execution_trace.json"
  Assert-Phase152ValidatorEquals -Actual $ExecutionTrace.executor_id -Expected "SELF_BUILD_SANDBOX_EXECUTOR_V1" -Name "execution_trace_executor"
  Assert-Phase152ValidatorEquals -Actual $ExecutionTrace.execution_mode -Expected $ExecutionMode -Name "execution_trace_mode"
  Assert-Phase152ValidatorEquals -Actual $ExecutionTrace.execution_scope -Expected $ExecutionScope -Name "execution_trace_scope"
  Assert-Phase152ValidatorTrue -Actual $ExecutionTrace.program_executed -Name "execution_trace_program_executed"
  Assert-Phase152ValidatorFalse -Actual $ExecutionTrace.arbitrary_code_execution_used -Name "execution_trace_arbitrary_code_execution_used"

  $ExecutionResult = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path "$SandboxRoot/self_build_program_execution_result.json"
  Assert-Phase152ValidatorTrue -Actual $ExecutionResult.program_executed -Name "execution_result_program_executed"
  Assert-Phase152ValidatorEquals -Actual $ExecutionResult.execution_mode -Expected $ExecutionMode -Name "execution_result_mode"
  Assert-Phase152ValidatorEquals -Actual $ExecutionResult.target_micro_organ_id -Expected $TargetMicroOrganId -Name "execution_result_target"

  $MicroOrganCandidate = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path "$SandboxRoot/micro_organ_candidate.json"
  Assert-Phase152ValidatorEquals -Actual $MicroOrganCandidate.target_micro_organ_id -Expected $TargetMicroOrganId -Name "micro_organ_target"
  Assert-Phase152ValidatorEquals -Actual $MicroOrganCandidate.execution_mode -Expected $ExecutionMode -Name "micro_organ_execution_mode"
  Assert-Phase152ValidatorFalse -Actual $MicroOrganCandidate.accepted_capability -Name "micro_organ_accepted_capability"

  $SandboxValidationResult = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path "$SandboxRoot/sandbox_validation_result.json"
  Assert-Phase152ValidatorEquals -Actual $SandboxValidationResult.status -Expected "PASS" -Name "sandbox_validation_status"
  Assert-Phase152ValidatorEquals -Actual $SandboxValidationResult.validation_result -Expected "PASS" -Name "sandbox_validation_result"
  Assert-Phase152ValidatorEquals -Actual $SandboxValidationResult.target_micro_organ_id -Expected $TargetMicroOrganId -Name "sandbox_validation_target"

  $RollbackPlan = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path "$SandboxRoot/rollback_plan.json"
  Assert-Phase152ValidatorEquals -Actual $RollbackPlan.status -Expected "PASS" -Name "rollback_plan_status"
  Assert-Phase152ValidatorFalse -Actual $RollbackPlan.accepted_state_delete_allowed -Name "rollback_accepted_state_delete_allowed"

  $QuarantinePlan = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path "$SandboxRoot/quarantine_plan.json"
  Assert-Phase152ValidatorEquals -Actual $QuarantinePlan.status -Expected "PASS" -Name "quarantine_plan_status"
  Assert-Phase152ValidatorFalse -Actual $QuarantinePlan.accepted_state_mutated -Name "quarantine_accepted_state_mutated"

  $MemoryAbsorptionCandidate = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path "$SandboxRoot/memory_absorption_candidate.json"
  Assert-Phase152ValidatorEquals -Actual $MemoryAbsorptionCandidate.status -Expected "PASS" -Name "memory_absorption_status"
  Assert-Phase152ValidatorFalse -Actual $MemoryAbsorptionCandidate.accepted_memory_mutation_allowed_now -Name "memory_absorption_acceptance_now"

  $SelfModelUpdateCandidate = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path "$SandboxRoot/self_model_update_candidate.json"
  Assert-Phase152ValidatorEquals -Actual $SelfModelUpdateCandidate.status -Expected "PASS" -Name "self_model_update_status"
  Assert-Phase152ValidatorFalse -Actual $SelfModelUpdateCandidate.accepted_self_model_mutation_allowed_now -Name "self_model_update_acceptance_now"

  $NextCycleDecision = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path "$SandboxRoot/next_cycle_decision.json"
  Assert-Phase152ValidatorEquals -Actual $NextCycleDecision.next_action -Expected "VALIDATE_AND_LEARN" -Name "next_cycle_action"
  Assert-Phase152ValidatorEquals -Actual $NextCycleDecision.next_allowed_step -Expected $NextAllowedStep -Name "next_cycle_next_allowed_step"
  Assert-Phase152ValidatorFalse -Actual $NextCycleDecision.codex_needed_for_next_step -Name "next_cycle_codex_needed"
  Assert-Phase152ValidatorFalse -Actual $NextCycleDecision.duty_loop_ready_for_bounded_trial -Name "next_cycle_duty_loop_ready"

  $DutyLoopReadiness = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path "$SandboxRoot/duty_loop_readiness.json"
  Assert-Phase152ValidatorFalse -Actual $DutyLoopReadiness.duty_loop_ready_for_bounded_trial -Name "duty_loop_ready_for_bounded_trial"

  $PortabilityReadinessNote = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path "$SandboxRoot/portability_readiness_note.json"
  Assert-Phase152ValidatorTrue -Actual $PortabilityReadinessNote.portability_prepared -Name "portability_note_prepared"
  Assert-Phase152ValidatorFalse -Actual $PortabilityReadinessNote.migration_performed -Name "portability_note_migration_performed"

  foreach ($path in @("$SandboxRoot/micro_organ_contract.json","$SandboxRoot/input_example.json","$SandboxRoot/output_example.json","$SandboxRoot/validator_spec.json","$SandboxRoot/source_policy_guard_result.json","$SandboxRoot/capability_shelf_read_result.json","$SandboxRoot/internal_answer.json","$SandboxRoot/internal_answer_search.json","$SandboxRoot/internal_question.json","$SandboxRoot/failure_classification.json","$SandboxRoot/gap_detection.json","$SandboxRoot/goal_state_snapshot.json","$SandboxRoot/task_intake_observation.json","$SandboxRoot/proof_memory_observation.json","$SandboxRoot/repo_observation.json","$SandboxRoot/self_state_observation.json")) {
    $artifact = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $path
    Assert-Phase152ValidatorEquals -Actual $artifact.status -Expected "PASS" -Name "runtime_artifact_status"
  }

  $Result = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath
  foreach ($artifact in @($Result, $Report, $Proof)) {
    Assert-Phase152ValidatorEquals -Actual $artifact.status -Expected "PASS" -Name "artifact_status"
    Assert-Phase152ValidatorEquals -Actual $artifact.step_id -Expected $StepId -Name "artifact_step_id"
    Assert-Phase152ValidatorEquals -Actual $artifact.run_id -Expected $RunId -Name "artifact_run_id"
    Assert-Phase152ValidatorEquals -Actual $artifact.next_allowed_step -Expected $NextAllowedStep -Name "artifact_next_allowed_step"
  }

  foreach ($artifact in @($Result, $Proof)) {
    Assert-Phase152ValidatorTrue -Actual $artifact.phase151_verified -Name "phase151_verified"
    Assert-Phase152ValidatorTrue -Actual $artifact.admission_ticket_verified -Name "admission_ticket_verified"
    Assert-Phase152ValidatorTrue -Actual $artifact.execution_intention_verified -Name "execution_intention_verified"
    Assert-Phase152ValidatorTrue -Actual $artifact.maximal_foundational_body_pack_created -Name "maximal_foundational_body_pack_created"
    Assert-Phase152ValidatorTrue -Actual $artifact.body_organ_pack_created -Name "body_organ_pack_created"
    Assert-Phase152ValidatorEquals -Actual $artifact.body_organ_count -Expected 24 -Name "artifact_body_organ_count"
    foreach ($field in @(
      "body_registry_created",
      "body_policy_created",
      "body_runtime_contract_created",
      "body_safety_boundaries_created",
      "body_portability_manifest_created",
      "self_state_sensor_created",
      "repo_observation_sensor_created",
      "proof_memory_sensor_created",
      "task_intake_sensor_created",
      "goal_state_manager_created",
      "gap_detector_created",
      "failure_classifier_created",
      "internal_question_engine_created",
      "internal_answer_searcher_created",
      "knowledge_memory_reader_created",
      "capability_shelf_reader_created",
      "source_policy_guard_created",
      "organ_composer_created",
      "self_build_program_composer_created",
      "sandbox_executor_created",
      "validation_runner_created",
      "sandbox_rollback_manager_created",
      "quarantine_manager_created",
      "memory_absorber_created",
      "self_model_update_candidate_writer_created",
      "next_cycle_decider_created",
      "duty_loop_controller_created",
      "owner_escalation_gate_created",
      "migration_portability_preparer_created",
      "body_activation_trace_created",
      "self_state_observation_created",
      "repo_observation_created",
      "proof_memory_observation_created",
      "task_intake_observation_created",
      "goal_state_snapshot_created",
      "gap_detection_created",
      "failure_classification_created",
      "internal_question_created",
      "internal_answer_search_created",
      "internal_answer_created",
      "source_policy_guard_result_created",
      "capability_shelf_read_result_created",
      "micro_organ_candidate_created",
      "micro_organ_contract_created",
      "input_example_created",
      "output_example_created",
      "validator_spec_created",
      "sandbox_validation_result_created",
      "rollback_plan_created",
      "quarantine_plan_created",
      "memory_absorption_candidate_created",
      "self_model_update_candidate_created",
      "next_cycle_decision_created",
      "duty_loop_readiness_created",
      "portability_readiness_note_created"
    )) {
      Assert-Phase152ValidatorTrue -Actual $artifact.$field -Name $field
    }
    Assert-Phase152ValidatorTrue -Actual $artifact.program_executed -Name "program_executed"
    Assert-Phase152ValidatorEquals -Actual $artifact.execution_scope -Expected $ExecutionScope -Name "execution_scope"
    Assert-Phase152ValidatorEquals -Actual $artifact.execution_mode -Expected $ExecutionMode -Name "execution_mode"
    Assert-Phase152ValidatorEquals -Actual $artifact.target_micro_organ_id -Expected $TargetMicroOrganId -Name "target_micro_organ_id"
    Assert-Phase152ValidatorEquals -Actual $artifact.next_cycle_action -Expected "VALIDATE_AND_LEARN" -Name "next_cycle_action"
    Assert-Phase152ValidatorFalse -Actual $artifact.duty_loop_ready_for_bounded_trial -Name "duty_loop_ready_for_bounded_trial"
    Assert-Phase152ValidatorFalse -Actual $artifact.codex_needed_for_next_step -Name "codex_needed_for_next_step"
    foreach ($flag in @("arbitrary_code_execution_used","external_fetch_performed","dependency_install_performed","executable_materials_used","accepted_state_mutated","external_agents_created","orchestrator_changed","route_lock_changed","current_runtime_changed","capability_shelf_mutated")) {
      Assert-Phase152ValidatorFalse -Actual $artifact.$flag -Name $flag
    }
    Assert-Phase152ValidatorEquals -Actual $artifact.trusted_source_count -Expected 0 -Name "trusted_source_count"
    Assert-Phase152ValidatorEquals -Actual $artifact.queue_after -Expected "NONE" -Name "queue_after"
  }

  $Queue = Read-Phase152ValidatorJson -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
  Assert-Phase152ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  Write-Host "PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_VALIDATE_RESULT=PASS"
  Write-Host "PHASE151_VERIFIED=True"
  Write-Host "ADMISSION_TICKET_VERIFIED=True"
  Write-Host "EXECUTION_INTENTION_VERIFIED=True"
  Write-Host "MAXIMAL_FOUNDATIONAL_BODY_PACK_CREATED=True"
  Write-Host "BODY_ORGAN_PACK_CREATED=True"
  Write-Host "BODY_ORGAN_COUNT=24"
  Write-Host "BODY_POLICY_SAFE=True"
  Write-Host "EXECUTOR_CONTRACT_SAFE=True"
  Write-Host "PROGRAM_EXECUTED=True"
  Write-Host "EXECUTION_SCOPE=sandbox_only"
  Write-Host "EXECUTION_MODE=declarative_json_only"
  Write-Host "TARGET_MICRO_ORGAN_ID=learning_card_reuse_advisor"
  Write-Host "SANDBOX_VALIDATION_RESULT=PASS"
  Write-Host "NEXT_CYCLE_ACTION=VALIDATE_AND_LEARN"
  Write-Host "DUTY_LOOP_READY_FOR_BOUNDED_TRIAL=False"
  Write-Host "CODEX_NEEDED_FOR_NEXT_STEP=False"
  Write-Host "ARBITRARY_CODE_EXECUTION_USED=False"
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
  Write-Host "NEXT_ALLOWED_STEP=PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1"
} catch {
  Write-Host "PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE152_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  Pop-Location
}
