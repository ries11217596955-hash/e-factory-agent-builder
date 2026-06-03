param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase158ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase158ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase158ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE158_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Assert-Phase158ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE158_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase158ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE158_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase158ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE158_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase158StatusPath {
  param([string]$StatusLine)

  if ($StatusLine -match '^.. (.+)$') {
    return ($Matches[1] -replace '\\', '/')
  }
  return ($StatusLine -replace '\\', '/')
}

function Assert-Phase158Contains {
  param(
    [object[]]$Values,
    [string]$Expected,
    [string]$Name
  )

  if (-not (@($Values) -contains $Expected)) {
    throw "PHASE158_VALIDATE_EXPECTED_VALUE_MISSING=$Name expected=$Expected"
  }
}

function Assert-Phase158NoPhaseSpecificEntrypointRequirement {
  param(
    [object]$Artifact,
    [string]$Name
  )

  foreach ($propertyName in @("required_module", "required_validator")) {
    if ($Artifact.PSObject.Properties.Name -contains $propertyName) {
      $value = [string]$Artifact.$propertyName
      if ($value -match "phase159|PHASE159|self_written_build_spec_in_sandbox|invoke_builder_executes_self_written_build_spec") {
        throw "PHASE158_VALIDATE_PHASE_SPECIFIC_ENTRYPOINT_REQUIRED=$Name.$propertyName value=$value"
      }
    }
  }
  if ($Artifact.PSObject.Properties.Name -contains "phase_specific_entrypoint_required") {
    Assert-Phase158ValidatorFalse -Actual $Artifact.phase_specific_entrypoint_required -Name "${Name}:phase_specific_entrypoint_required"
  }
  if ($Artifact.PSObject.Properties.Name -contains "codex_required_for_phase159_entrypoint") {
    Assert-Phase158ValidatorFalse -Actual $Artifact.codex_required_for_phase159_entrypoint -Name "${Name}:codex_required_for_phase159_entrypoint"
  }
}

function Assert-Phase158Phase157Proof {
  param(
    [object]$Proof,
    [string]$StepId
  )

  Assert-Phase158ValidatorEquals -Actual $Proof.status -Expected "PASS" -Name "phase157_status"
  Assert-Phase158ValidatorEquals -Actual $Proof.next_allowed_step -Expected $StepId -Name "phase157_next_allowed_step"
  Assert-Phase158ValidatorEquals -Actual $Proof.sandbox_candidate_decision -Expected "KEEP_AS_VALIDATED_SANDBOX_CANDIDATES" -Name "phase157_sandbox_decision"
  Assert-Phase158ValidatorEquals -Actual $Proof.reuse_decision -Expected "ADMIT_PHASE156_CANDIDATES_FOR_BOUNDED_SANDBOX_REUSE" -Name "phase157_reuse_decision"
  Assert-Phase158ValidatorEquals -Actual $Proof.allowed_scope -Expected "sandbox_only" -Name "phase157_allowed_scope"
  Assert-Phase158ValidatorEquals -Actual $Proof.skill_candidate_count -Expected 3 -Name "phase157_skill_candidate_count"
  Assert-Phase158ValidatorFalse -Actual $Proof.skill_candidates_promoted -Name "phase157_skill_candidates_promoted"
  Assert-Phase158ValidatorFalse -Actual $Proof.accepted_capability_created -Name "phase157_accepted_capability_created"
}

function Assert-Phase158ProofFields {
  param(
    [object]$Artifact,
    [string]$Name
  )

  Assert-Phase158ValidatorEquals -Actual $Artifact.status -Expected "PASS" -Name "${Name}:status"
  Assert-Phase158ValidatorEquals -Actual $Artifact.step_id -Expected "PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1" -Name "${Name}:step_id"
  Assert-Phase158ValidatorEquals -Actual $Artifact.run_id -Expected "PHASE158_REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL_001" -Name "${Name}:run_id"
  Assert-Phase158ValidatorTrue -Actual $Artifact.phase157_verified -Name "${Name}:phase157_verified"
  Assert-Phase158ValidatorTrue -Actual $Artifact.reviewed_candidates_loaded -Name "${Name}:reviewed_candidates_loaded"
  Assert-Phase158ValidatorEquals -Actual $Artifact.reviewed_candidate_count -Expected 3 -Name "${Name}:reviewed_candidate_count"
  Assert-Phase158ValidatorTrue -Actual $Artifact.self_gap_inventory_skill_reused -Name "${Name}:gap_inventory_reused"
  Assert-Phase158ValidatorTrue -Actual $Artifact.self_repair_task_spec_writer_skill_reused -Name "${Name}:repair_task_spec_reused"
  Assert-Phase158ValidatorTrue -Actual $Artifact.self_proof_summary_skill_reused -Name "${Name}:proof_summary_reused"
  Assert-Phase158ValidatorEquals -Actual $Artifact.cycle_009_selected_gap -Expected "SELF_WRITTEN_BUILD_SPEC_EXECUTION_GAP" -Name "${Name}:cycle009_gap"
  Assert-Phase158ValidatorTrue -Actual $Artifact.cycle_010_task_spec_created -Name "${Name}:cycle010_task_spec"
  Assert-Phase158ValidatorTrue -Actual $Artifact.self_written_build_spec_candidate_created -Name "${Name}:spec_candidate_created"
  Assert-Phase158ValidatorTrue -Actual $Artifact.self_written_build_spec_validated -Name "${Name}:spec_validated"
  Assert-Phase158ValidatorTrue -Actual $Artifact.generic_spec_execution_request_created -Name "${Name}:generic_request_created"
  Assert-Phase158ValidatorTrue -Actual $Artifact.generic_spec_execution_admission_created -Name "${Name}:generic_admission_created"
  Assert-Phase158ValidatorTrue -Actual $Artifact.generic_spec_sandbox_execution_result_created -Name "${Name}:generic_result_created"
  Assert-Phase158ValidatorTrue -Actual $Artifact.generic_spec_execution_validated -Name "${Name}:generic_execution_validated"
  Assert-Phase158ValidatorTrue -Actual $Artifact.generic_execution_bridge_proven -Name "${Name}:generic_bridge_proven"
  Assert-Phase158ValidatorTrue -Actual $Artifact.self_written_spec_executable_by_generic_bridge -Name "${Name}:spec_executable_by_generic_bridge"
  Assert-Phase158ValidatorFalse -Actual $Artifact.phase_specific_entrypoint_required -Name "${Name}:phase_specific_entrypoint_required"
  Assert-Phase158ValidatorFalse -Actual $Artifact.codex_required_for_phase159_entrypoint -Name "${Name}:codex_required_for_phase159_entrypoint"
  Assert-Phase158ValidatorTrue -Actual $Artifact.source_skills_reused -Name "${Name}:source_skills_reused"
  Assert-Phase158ValidatorTrue -Actual $Artifact.candidate_only -Name "${Name}:candidate_only"
  foreach ($flag in @("accepted_state_mutated", "accepted_memory_mutated", "accepted_self_model_mutated", "skill_candidates_promoted", "accepted_capability_created", "capability_shelf_mutated", "body_pack_mutated", "external_fetch_performed", "dependency_install_performed", "executable_materials_used", "arbitrary_code_execution_used", "external_agents_created", "orchestrator_changed", "route_lock_changed", "current_runtime_changed")) {
    Assert-Phase158ValidatorFalse -Actual $Artifact.$flag -Name "${Name}:$flag"
  }
  Assert-Phase158ValidatorEquals -Actual $Artifact.queue_after -Expected "NONE" -Name "${Name}:queue_after"
  Assert-Phase158ValidatorFalse -Actual $Artifact.codex_needed_for_next_step -Name "${Name}:codex_needed"
  Assert-Phase158ValidatorEquals -Actual $Artifact.next_allowed_step -Expected "PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1" -Name "${Name}:next_allowed_step"
}

$Pushed = $false

try {
  $StepId = "PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1"
  $RunId = "PHASE158_REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL_001"
  $NextAllowedStep = "PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1"
  $Phase157RunId = "PHASE157_SELF_SELECTED_GAP_TRIAL_REVIEW_001"
  $Phase156RunId = "PHASE156_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_001"
  $Phase157Root = "living_learning_environment/trial_reviews/$Phase157RunId"
  $Phase156Root = "living_learning_environment/self_growth_cycles/$Phase156RunId"
  $TrialRoot = "living_learning_environment/reuse_trials/$RunId"
  $RouteAlignmentPath = "route_change_requests/PHASE158_REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL_ALIGNMENT_REQUEST.md"
  $ModulePath = "modules/invoke_builder_uses_self_built_gap_skills_for_self_build_spec_trial_001.ps1"
  $ValidatorPath = "validators/validate_phase158_builder_uses_self_built_gap_skills_for_self_build_spec_trial_v1.ps1"
  $Phase157ProofPath = "proofs/self_development/PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1.json"
  $Phase157TicketPath = "$Phase157Root/next_reuse_ticket.json"
  $Phase157NextDecisionPath = "$Phase157Root/next_cycle_decision.json"
  $Phase157BoundedReusePath = "$Phase157Root/bounded_reuse_decision.json"
  $Phase157SandboxDecisionPath = "$Phase157Root/sandbox_candidate_decision.json"
  $SkillIndexPath = "$Phase156Root/built_skill_candidates_index.json"
  $GapInventorySkillPath = "$Phase156Root/cycle_006/skill_candidate.json"
  $RepairTaskSpecSkillPath = "$Phase156Root/cycle_007/skill_candidate.json"
  $ProofSummarySkillPath = "$Phase156Root/cycle_008/skill_candidate.json"
  $GapInventoryValidationPath = "$Phase156Root/cycle_006/skill_validation_result.json"
  $RepairTaskSpecValidationPath = "$Phase156Root/cycle_007/skill_validation_result.json"
  $ProofSummaryValidationPath = "$Phase156Root/cycle_008/skill_validation_result.json"
  $SafetyPolicyPath = "living_learning_environment/self_growth_runtime/SELF_GROWTH_SAFETY_POLICY_V1.json"
  $BodyPackPath = "living_learning_environment/body/BUILDER_BODY_ORGAN_PACK_V1.json"
  $BodyPolicyPath = "living_learning_environment/body/body_policy.json"
  $SourcePolicyPath = "source_registry/source_policy.json"
  $TrustedSourcesPath = "source_registry/trusted_sources.json"
  $QueuePath = "TASK_QUEUE.json"
  $TrialBootPath = "$TrialRoot/trial_boot.json"
  $TicketReadPath = "$TrialRoot/phase157_ticket_read.json"
  $CandidateLoadPath = "$TrialRoot/reviewed_candidate_skill_load.json"
  $SkillReusePolicyPath = "$TrialRoot/skill_reuse_policy.json"
  $Cycle009Path = "$TrialRoot/cycle_009_gap_inventory_reuse.json"
  $Cycle010Path = "$TrialRoot/cycle_010_repair_task_spec_reuse.json"
  $Cycle011Path = "$TrialRoot/cycle_011_proof_summary_reuse.json"
  $SpecCandidatePath = "$TrialRoot/self_written_build_spec_candidate.json"
  $SpecContractPath = "$TrialRoot/self_written_build_spec_contract.json"
  $SpecValidationPath = "$TrialRoot/self_written_build_spec_validation_result.json"
  $GenericExecutionRequestPath = "$TrialRoot/generic_spec_execution_request.json"
  $GenericExecutionAdmissionPath = "$TrialRoot/generic_spec_execution_admission.json"
  $GenericSandboxExecutionResultPath = "$TrialRoot/generic_spec_sandbox_execution_result.json"
  $GenericExecutionValidationPath = "$TrialRoot/generic_spec_execution_validation_result.json"
  $ReuseTrialResultPath = "$TrialRoot/reuse_trial_result.json"
  $SelfModelCandidatePath = "$TrialRoot/self_model_update_candidate.json"
  $NextExecutionTicketPath = "$TrialRoot/next_execution_ticket.json"
  $RuntimeStopDecisionPath = "$TrialRoot/runtime_stop_decision.json"
  $ReuseTrialTracePath = "$TrialRoot/reuse_trial_trace.json"
  $ResultPath = "self_control/BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_RESULT.json"
  $ReportPath = "reports/self_development/PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1_REPORT.json"
  $ProofPath = "proofs/self_development/PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1.json"
  $RuntimeOutputs = @($TrialBootPath, $TicketReadPath, $CandidateLoadPath, $SkillReusePolicyPath, $Cycle009Path, $Cycle010Path, $Cycle011Path, $SpecCandidatePath, $SpecContractPath, $SpecValidationPath, $GenericExecutionRequestPath, $GenericExecutionAdmissionPath, $GenericSandboxExecutionResultPath, $GenericExecutionValidationPath, $ReuseTrialResultPath, $SelfModelCandidatePath, $NextExecutionTicketPath, $RuntimeStopDecisionPath, $ReuseTrialTracePath)
  $AllowedExact = @($RouteAlignmentPath, $ModulePath, $ValidatorPath, $ResultPath, $ReportPath, $ProofPath) + $RuntimeOutputs
  $SourceSkills = @("SELF_GAP_INVENTORY_SKILL_CANDIDATE_V1", "SELF_REPAIR_TASK_SPEC_WRITER_SKILL_CANDIDATE_V1", "SELF_PROOF_SUMMARY_SKILL_CANDIDATE_V1")

  $RepoRoot = Resolve-Phase158ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot
  $Pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase158ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE158_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }
  Assert-Phase158ValidatorEquals -Actual $Branch -Expected "phase110-idempotent-autonomy-trial-runtime" -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  Assert-Phase158ValidatorEquals -Actual $Head -Expected "787ad74" -Name "current_head"

  $RequiredPaths = @(
    $RouteAlignmentPath,
    $ModulePath,
    $ValidatorPath,
    $Phase157ProofPath,
    $Phase157TicketPath,
    $Phase157NextDecisionPath,
    $Phase157BoundedReusePath,
    $Phase157SandboxDecisionPath,
    $SkillIndexPath,
    $GapInventorySkillPath,
    $RepairTaskSpecSkillPath,
    $ProofSummarySkillPath,
    $GapInventoryValidationPath,
    $RepairTaskSpecValidationPath,
    $ProofSummaryValidationPath,
    $SafetyPolicyPath,
    $BodyPackPath,
    $BodyPolicyPath,
    $SourcePolicyPath,
    $TrustedSourcesPath,
    $QueuePath,
    $ResultPath,
    $ReportPath,
    $ProofPath
  ) + $RuntimeOutputs
  foreach ($requiredPath in $RequiredPaths) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase158ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE158_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $StatusLines = @(git status --short --untracked-files=all)
  foreach ($line in $StatusLines) {
    $path = Get-Phase158StatusPath -StatusLine $line
    if (-not ($AllowedExact -contains $path)) {
      throw "PHASE158_VALIDATE_CHANGE_OUTSIDE_ALLOWED_SCOPE=$line"
    }
  }

  $ProtectedStatus = @(git status --short --untracked-files=all -- `
    orchestrator/run.ps1 `
    TASK_QUEUE.json `
    GENESIS_STATE.json `
    CAPABILITY_ROADMAP.json `
    packs/registry.json `
    capability_shelf `
    living_learning_environment/body `
    living_learning_environment/self_growth_runtime `
    route_locks `
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
    proofs/self_development/PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1.json `
    proofs/self_development/PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1.json `
    proofs/self_development/PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1.json `
    proofs/self_development/PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1.json `
    proofs/self_development/PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1.json `
    proofs/self_development/PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1.json `
    reports/self_development/PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1_REPORT.json `
    reports/self_development/PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1_REPORT.json `
    reports/self_development/PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1_REPORT.json `
    reports/self_development/PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1_REPORT.json `
    reports/self_development/PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1_REPORT.json `
    reports/self_development/PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1_REPORT.json `
    reports/self_development/PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1_REPORT.json `
    reports/self_development/PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1_REPORT.json `
    reports/self_development/PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1_REPORT.json `
    self_control/BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_RESULT.json 2>$null)
  if ($ProtectedStatus.Count -gt 0) {
    throw "PHASE158_VALIDATE_PROTECTED_SCOPE_CHANGED=$($ProtectedStatus -join '; ')"
  }

  $Phase157Proof = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $Phase157ProofPath
  Assert-Phase158Phase157Proof -Proof $Phase157Proof -StepId $StepId

  $Ticket = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $Phase157TicketPath
  Assert-Phase158ValidatorEquals -Actual $Ticket.ticket_status -Expected "ISSUED_FOR_PHASE158_ONLY" -Name "ticket_status"
  Assert-Phase158ValidatorEquals -Actual $Ticket.trial_type -Expected "REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL" -Name "ticket_trial_type"
  Assert-Phase158ValidatorEquals -Actual @($Ticket.allowed_candidates).Count -Expected 3 -Name "ticket_candidate_count"
  foreach ($skillId in $SourceSkills) {
    Assert-Phase158Contains -Values @($Ticket.allowed_candidates) -Expected $skillId -Name "ticket_allowed_candidates"
  }

  $SkillIndex = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $SkillIndexPath
  Assert-Phase158ValidatorEquals -Actual $SkillIndex.skill_candidate_count -Expected 3 -Name "skill_index_count"
  foreach ($skillId in $SourceSkills) {
    Assert-Phase158Contains -Values @($SkillIndex.skill_candidates | ForEach-Object { $_.skill_id }) -Expected $skillId -Name "skill_index_candidates"
  }

  foreach ($candidatePath in @($GapInventorySkillPath, $RepairTaskSpecSkillPath, $ProofSummarySkillPath)) {
    $Candidate = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $candidatePath
    Assert-Phase158Contains -Values $SourceSkills -Expected $Candidate.skill_id -Name "candidate_skill_id"
    Assert-Phase158ValidatorFalse -Actual $Candidate.accepted_capability -Name "candidate_accepted_capability"
  }
  foreach ($validationPath in @($GapInventoryValidationPath, $RepairTaskSpecValidationPath, $ProofSummaryValidationPath)) {
    $Validation = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $validationPath
    Assert-Phase158ValidatorEquals -Actual $Validation.validation_status -Expected "PASS" -Name "source_validation_status"
    Assert-Phase158ValidatorTrue -Actual $Validation.independently_calculated -Name "source_validation_independent"
  }

  $CandidateLoad = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $CandidateLoadPath
  Assert-Phase158ValidatorTrue -Actual $CandidateLoad.reviewed_candidates_loaded -Name "candidate_load_flag"
  Assert-Phase158ValidatorEquals -Actual $CandidateLoad.reviewed_candidate_count -Expected 3 -Name "candidate_load_count"

  $Policy = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $SkillReusePolicyPath
  Assert-Phase158ValidatorEquals -Actual $Policy.allowed_scope -Expected "sandbox_only" -Name "policy_scope"
  Assert-Phase158ValidatorFalse -Actual $Policy.new_skill_creation_allowed -Name "policy_new_skill_creation"
  Assert-Phase158ValidatorFalse -Actual $Policy.skill_promotion_allowed -Name "policy_skill_promotion"

  $Cycle009 = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $Cycle009Path
  Assert-Phase158ValidatorTrue -Actual $Cycle009.self_gap_inventory_skill_reused -Name "cycle009_skill_reused"
  Assert-Phase158ValidatorEquals -Actual $Cycle009.selected_gap -Expected "SELF_WRITTEN_BUILD_SPEC_EXECUTION_GAP" -Name "cycle009_gap"
  Assert-Phase158ValidatorEquals -Actual $Cycle009.gap_class -Expected "entrypoint_missing" -Name "cycle009_gap_class"
  Assert-Phase158ValidatorEquals -Actual $Cycle009.reason -Expected "Builder can write self-build specs but needs a bounded executor/reviewer path for self-written specs." -Name "cycle009_reason"

  $Cycle010 = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $Cycle010Path
  Assert-Phase158ValidatorTrue -Actual $Cycle010.self_repair_task_spec_writer_skill_reused -Name "cycle010_skill_reused"
  Assert-Phase158ValidatorTrue -Actual $Cycle010.task_spec_created -Name "cycle010_task_spec_created"
  Assert-Phase158ValidatorEquals -Actual $Cycle010.task_spec_id -Expected "SELF_WRITTEN_BUILD_SPEC_EXECUTION_TASK_SPEC_V1" -Name "cycle010_spec_id"
  Assert-Phase158ValidatorEquals -Actual $Cycle010.task_type -Expected "generic_sandbox_execution_request" -Name "cycle010_task_type"
  Assert-Phase158ValidatorEquals -Actual $Cycle010.target_step -Expected $NextAllowedStep -Name "cycle010_target_step"
  Assert-Phase158ValidatorEquals -Actual $Cycle010.generic_bridge_id -Expected "GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1" -Name "cycle010_generic_bridge"
  Assert-Phase158NoPhaseSpecificEntrypointRequirement -Artifact $Cycle010 -Name "cycle010"

  $Cycle011 = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $Cycle011Path
  Assert-Phase158ValidatorTrue -Actual $Cycle011.self_proof_summary_skill_reused -Name "cycle011_skill_reused"
  Assert-Phase158ValidatorFalse -Actual $Cycle011.accepted -Name "cycle011_accepted"
  Assert-Phase158ValidatorTrue -Actual $Cycle011.candidate_ready -Name "cycle011_candidate_ready"
  Assert-Phase158ValidatorFalse -Actual $Cycle011.codex_needed -Name "cycle011_codex_needed"
  Assert-Phase158ValidatorEquals -Actual $Cycle011.next_step -Expected $NextAllowedStep -Name "cycle011_next_step"

  $SpecCandidate = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $SpecCandidatePath
  Assert-Phase158ValidatorEquals -Actual $SpecCandidate.status -Expected "PASS" -Name "spec_status"
  Assert-Phase158ValidatorEquals -Actual $SpecCandidate.spec_id -Expected "SELF_WRITTEN_BUILD_SPEC_EXECUTION_TASK_SPEC_V1" -Name "spec_id"
  Assert-Phase158ValidatorEquals -Actual @($SpecCandidate.source_skills_used).Count -Expected 3 -Name "spec_source_skill_count"
  for ($i = 0; $i -lt $SourceSkills.Count; $i++) {
    Assert-Phase158ValidatorEquals -Actual @($SpecCandidate.source_skills_used)[$i] -Expected $SourceSkills[$i] -Name "spec_source_skill_$i"
  }
  Assert-Phase158ValidatorEquals -Actual $SpecCandidate.target_step -Expected $NextAllowedStep -Name "spec_target_step"
  Assert-Phase158ValidatorEquals -Actual $SpecCandidate.execution_scope -Expected "sandbox_only" -Name "spec_scope"
  Assert-Phase158ValidatorEquals -Actual $SpecCandidate.generic_bridge_id -Expected "GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1" -Name "spec_generic_bridge"
  Assert-Phase158NoPhaseSpecificEntrypointRequirement -Artifact $SpecCandidate -Name "spec_candidate"
  Assert-Phase158ValidatorFalse -Actual $SpecCandidate.accepted_state_mutation_allowed -Name "spec_state_mutation"
  Assert-Phase158ValidatorFalse -Actual $SpecCandidate.capability_shelf_mutation_allowed -Name "spec_shelf_mutation"
  Assert-Phase158ValidatorFalse -Actual $SpecCandidate.external_fetch_allowed -Name "spec_fetch"
  Assert-Phase158ValidatorFalse -Actual $SpecCandidate.install_allowed -Name "spec_install"

  $SpecValidation = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $SpecValidationPath
  Assert-Phase158ValidatorEquals -Actual $SpecValidation.status -Expected "PASS" -Name "spec_validation_status"
  Assert-Phase158ValidatorTrue -Actual $SpecValidation.spec_valid -Name "spec_valid"
  Assert-Phase158ValidatorTrue -Actual $SpecValidation.source_skills_reused -Name "spec_validation_source_skills"
  Assert-Phase158ValidatorTrue -Actual $SpecValidation.candidate_only -Name "spec_validation_candidate_only"

  $GenericRequest = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $GenericExecutionRequestPath
  Assert-Phase158ValidatorEquals -Actual $GenericRequest.status -Expected "PASS" -Name "generic_request_status"
  Assert-Phase158ValidatorEquals -Actual $GenericRequest.source_spec_candidate_path -Expected $SpecCandidatePath -Name "generic_request_source_spec"
  Assert-Phase158ValidatorEquals -Actual $GenericRequest.execution_scope -Expected "sandbox_only" -Name "generic_request_scope"
  Assert-Phase158ValidatorTrue -Actual $GenericRequest.self_written_spec_loaded -Name "generic_request_spec_loaded"
  Assert-Phase158ValidatorEquals -Actual $GenericRequest.generic_bridge_id -Expected "GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1" -Name "generic_request_bridge"
  Assert-Phase158NoPhaseSpecificEntrypointRequirement -Artifact $GenericRequest -Name "generic_request"

  $GenericAdmission = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $GenericExecutionAdmissionPath
  Assert-Phase158ValidatorEquals -Actual $GenericAdmission.status -Expected "PASS" -Name "generic_admission_status"
  Assert-Phase158ValidatorTrue -Actual $GenericAdmission.admitted_for_generic_sandbox_execution -Name "generic_admission_admitted"
  Assert-Phase158ValidatorFalse -Actual $GenericAdmission.phase_specific_entrypoint_required -Name "generic_admission_phase_specific"
  Assert-Phase158ValidatorFalse -Actual $GenericAdmission.codex_required_for_phase159_entrypoint -Name "generic_admission_codex"
  Assert-Phase158ValidatorEquals -Actual $GenericAdmission.execution_scope -Expected "sandbox_only" -Name "generic_admission_scope"

  $GenericResult = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $GenericSandboxExecutionResultPath
  Assert-Phase158ValidatorEquals -Actual $GenericResult.status -Expected "PASS" -Name "generic_result_status"
  Assert-Phase158ValidatorEquals -Actual $GenericResult.execution_scope -Expected "sandbox_only" -Name "generic_result_scope"
  Assert-Phase158ValidatorTrue -Actual $GenericResult.self_written_spec_loaded -Name "generic_result_spec_loaded"
  Assert-Phase158ValidatorTrue -Actual $GenericResult.generic_executor_path_used -Name "generic_result_executor_used"
  Assert-Phase158ValidatorFalse -Actual $GenericResult.phase_specific_module_created -Name "generic_result_phase_module"
  Assert-Phase158ValidatorFalse -Actual $GenericResult.phase_specific_entrypoint_required -Name "generic_result_phase_specific"
  Assert-Phase158ValidatorFalse -Actual $GenericResult.codex_required_for_phase159_entrypoint -Name "generic_result_codex"
  foreach ($flag in @("accepted_state_mutated", "accepted_memory_mutated", "accepted_self_model_mutated", "capability_shelf_mutated", "body_pack_mutated", "external_fetch_performed", "dependency_install_performed", "arbitrary_code_execution_used", "external_agents_created")) {
    Assert-Phase158ValidatorFalse -Actual $GenericResult.$flag -Name "generic_result_$flag"
  }

  $GenericValidation = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $GenericExecutionValidationPath
  Assert-Phase158ValidatorEquals -Actual $GenericValidation.status -Expected "PASS" -Name "generic_validation_status"
  Assert-Phase158ValidatorTrue -Actual $GenericValidation.generic_execution_bridge_proven -Name "generic_bridge_proven"
  Assert-Phase158ValidatorTrue -Actual $GenericValidation.self_written_spec_executable_by_generic_bridge -Name "generic_spec_executable"
  Assert-Phase158ValidatorFalse -Actual $GenericValidation.phase_specific_entrypoint_required -Name "generic_validation_phase_specific"
  Assert-Phase158ValidatorFalse -Actual $GenericValidation.codex_required_for_phase159_entrypoint -Name "generic_validation_codex"

  $NextTicket = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $NextExecutionTicketPath
  Assert-Phase158ValidatorEquals -Actual $NextTicket.status -Expected "PASS" -Name "next_ticket_status_file"
  Assert-Phase158ValidatorEquals -Actual $NextTicket.ticket_status -Expected "ISSUED_FOR_PHASE159_ONLY" -Name "next_ticket_status"
  Assert-Phase158ValidatorEquals -Actual $NextTicket.execution_type -Expected "RUN_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE" -Name "next_ticket_execution_type"
  Assert-Phase158ValidatorEquals -Actual $NextTicket.allowed_scope -Expected "sandbox_only" -Name "next_ticket_scope"
  Assert-Phase158NoPhaseSpecificEntrypointRequirement -Artifact $NextTicket -Name "next_ticket"

  $Stop = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $RuntimeStopDecisionPath
  Assert-Phase158ValidatorEquals -Actual $Stop.status -Expected "PASS" -Name "stop_status"
  Assert-Phase158ValidatorTrue -Actual $Stop.safe_stop -Name "stop_safe"
  Assert-Phase158ValidatorEquals -Actual $Stop.stop_reason -Expected "PHASE158_GENERIC_EXECUTION_BRIDGE_PROVEN" -Name "stop_reason"
  Assert-Phase158ValidatorEquals -Actual $Stop.next_allowed_step -Expected $NextAllowedStep -Name "stop_next_allowed"

  $Result = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath
  Assert-Phase158ProofFields -Artifact $Result -Name "result"
  Assert-Phase158ProofFields -Artifact $Proof -Name "proof"

  Assert-Phase158ValidatorEquals -Actual $Report.root_cause -Expected "PHASE158 entrypoint absent" -Name "report_root_cause"
  Assert-Phase158ValidatorEquals -Actual $Report.module_path -Expected $ModulePath -Name "report_module_path"
  Assert-Phase158ValidatorEquals -Actual $Report.validator_path -Expected $ValidatorPath -Name "report_validator_path"
  Assert-Phase158ValidatorEquals -Actual $Report.exact_run_command_expected -Expected ".\modules\invoke_builder_uses_self_built_gap_skills_for_self_build_spec_trial_001.ps1" -Name "report_run_command"
  Assert-Phase158ValidatorEquals -Actual $Report.exact_validator_command_expected -Expected ".\validators\validate_phase158_builder_uses_self_built_gap_skills_for_self_build_spec_trial_v1.ps1 -RepoRoot ." -Name "report_validator_command"
  foreach ($runtimePath in ($RuntimeOutputs + @($ResultPath, $ReportPath, $ProofPath))) {
    if (-not (@($Report.runtime_output_files_created) -contains $runtimePath)) {
      throw "PHASE158_VALIDATE_REPORT_RUNTIME_OUTPUT_MISSING=$runtimePath"
    }
  }

  $Queue = Read-Phase158ValidatorJson -RepoRoot $RepoRoot -Path $QueuePath
  Assert-Phase158ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  Write-Host "PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_VALIDATE_RESULT=PASS"
  Write-Host "PHASE157_VERIFIED=True"
  Write-Host "REVIEWED_CANDIDATES_LOADED=True"
  Write-Host "REVIEWED_CANDIDATE_COUNT=3"
  Write-Host "SELF_GAP_INVENTORY_SKILL_REUSED=True"
  Write-Host "SELF_REPAIR_TASK_SPEC_WRITER_SKILL_REUSED=True"
  Write-Host "SELF_PROOF_SUMMARY_SKILL_REUSED=True"
  Write-Host "CYCLE_009_SELECTED_GAP=SELF_WRITTEN_BUILD_SPEC_EXECUTION_GAP"
  Write-Host "CYCLE_010_TASK_SPEC_CREATED=True"
  Write-Host "SELF_WRITTEN_BUILD_SPEC_CANDIDATE_CREATED=True"
  Write-Host "SELF_WRITTEN_BUILD_SPEC_VALIDATED=True"
  Write-Host "GENERIC_SPEC_EXECUTION_REQUEST_CREATED=True"
  Write-Host "GENERIC_SPEC_EXECUTION_ADMISSION_CREATED=True"
  Write-Host "GENERIC_SPEC_SANDBOX_EXECUTION_RESULT_CREATED=True"
  Write-Host "GENERIC_SPEC_EXECUTION_VALIDATED=True"
  Write-Host "GENERIC_EXECUTION_BRIDGE_PROVEN=True"
  Write-Host "PHASE_SPECIFIC_ENTRYPOINT_REQUIRED=False"
  Write-Host "CODEX_REQUIRED_FOR_PHASE159_ENTRYPOINT=False"
  Write-Host "SOURCE_SKILLS_REUSED=True"
  Write-Host "CANDIDATE_ONLY=True"
  Write-Host "SKILL_CANDIDATES_PROMOTED=False"
  Write-Host "ACCEPTED_CAPABILITY_CREATED=False"
  Write-Host "CAPABILITY_SHELF_MUTATED=False"
  Write-Host "QUEUE_AFTER=NONE"
  Write-Host "CODEX_NEEDED_FOR_NEXT_STEP=False"
  Write-Host "NEXT_ALLOWED_STEP=PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1"
} catch {
  Write-Host "PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE158_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
