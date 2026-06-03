param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase155ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase155ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase155ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE155_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Assert-Phase155ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE155_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase155ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE155_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase155ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE155_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase155StatusPath {
  param([string]$StatusLine)

  if ($StatusLine -match '^.. (.+)$') {
    return ($Matches[1] -replace '\\', '/')
  }
  return ($StatusLine -replace '\\', '/')
}

function Assert-Phase155ProofFields {
  param(
    [object]$Artifact,
    [string]$Name
  )

  Assert-Phase155ValidatorEquals -Actual $Artifact.status -Expected "PASS" -Name "${Name}:status"
  Assert-Phase155ValidatorEquals -Actual $Artifact.step_id -Expected "PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1" -Name "${Name}:step_id"
  Assert-Phase155ValidatorEquals -Actual $Artifact.run_id -Expected "PHASE155_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_001" -Name "${Name}:run_id"
  Assert-Phase155ValidatorTrue -Actual $Artifact.phase153_verified -Name "${Name}:phase153_verified"
  Assert-Phase155ValidatorTrue -Actual $Artifact.phase154_verified -Name "${Name}:phase154_verified"
  Assert-Phase155ValidatorEquals -Actual $Artifact.total_self_growth_cycles_reviewed -Expected 5 -Name "${Name}:total_cycles"
  Assert-Phase155ValidatorTrue -Actual $Artifact.runtime_evidence_chain_verified -Name "${Name}:evidence_chain"
  foreach ($field in @("runtime_safety_review_created", "runtime_reuse_decision_created", "runtime_admission_decision_created", "bounded_reuse_policy_created", "non_promotion_decision_created", "self_model_update_candidate_created", "next_trial_ticket_created", "next_cycle_decision_created")) {
    Assert-Phase155ValidatorTrue -Actual $Artifact.$field -Name "${Name}:$field"
  }
  Assert-Phase155ValidatorEquals -Actual $Artifact.admission_status -Expected "ADMITTED_FOR_BOUNDED_SELF_GROWTH_SANDBOX_USE" -Name "${Name}:admission_status"
  Assert-Phase155ValidatorEquals -Actual $Artifact.reuse_decision -Expected "ADMIT_FOR_BOUNDED_SANDBOX_REUSE" -Name "${Name}:reuse_decision"
  Assert-Phase155ValidatorEquals -Actual $Artifact.allowed_scope -Expected "sandbox_only" -Name "${Name}:allowed_scope"
  Assert-Phase155ValidatorEquals -Actual $Artifact.max_cycles_per_run -Expected 3 -Name "${Name}:max_cycles"
  Assert-Phase155ValidatorFalse -Actual $Artifact.unrestricted_autonomy_approved -Name "${Name}:unrestricted_autonomy"
  Assert-Phase155ValidatorFalse -Actual $Artifact.accepted_core_promotion_approved -Name "${Name}:accepted_core_promotion"
  Assert-Phase155ValidatorFalse -Actual $Artifact.capability_shelf_promotion_approved -Name "${Name}:capability_shelf_promotion"
  Assert-Phase155ValidatorFalse -Actual $Artifact.runtime_promoted_to_accepted_core -Name "${Name}:runtime_promoted"
  foreach ($flag in @("accepted_state_mutated", "accepted_memory_mutated", "accepted_self_model_mutated", "external_fetch_performed", "dependency_install_performed", "executable_materials_used", "arbitrary_code_execution_used", "external_agents_created", "orchestrator_changed", "route_lock_changed", "current_runtime_changed", "capability_shelf_mutated", "body_pack_mutated")) {
    Assert-Phase155ValidatorFalse -Actual $Artifact.$flag -Name "${Name}:$flag"
  }
  Assert-Phase155ValidatorEquals -Actual $Artifact.trusted_source_count -Expected 0 -Name "${Name}:trusted_source_count"
  Assert-Phase155ValidatorEquals -Actual $Artifact.queue_after -Expected "NONE" -Name "${Name}:queue_after"
  Assert-Phase155ValidatorFalse -Actual $Artifact.codex_needed_for_next_step -Name "${Name}:codex_needed"
  Assert-Phase155ValidatorEquals -Actual $Artifact.next_allowed_step -Expected "PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1" -Name "${Name}:next_allowed_step"
}

$Pushed = $false

try {
  $StepId = "PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1"
  $RunId = "PHASE155_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_001"
  $NextAllowedStep = "PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1"
  $ReviewRoot = "living_learning_environment/admission_reviews/$RunId"
  $RouteAlignmentPath = "route_change_requests/PHASE155_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_ALIGNMENT_REQUEST.md"
  $ModulePath = "modules/invoke_builder_self_growth_runtime_admission_review_001.ps1"
  $ValidatorPath = "validators/validate_phase155_builder_self_growth_runtime_admission_review_v1.ps1"
  $Phase153ProofPath = "proofs/self_development/PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1.json"
  $Phase154ProofPath = "proofs/self_development/PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1.json"
  $Phase154ResultPath = "self_control/BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_RESULT.json"
  $Phase154ReportPath = "reports/self_development/PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1_REPORT.json"
  $Phase153HeartbeatPath = "living_learning_environment/self_growth_cycles/PHASE153_SELF_GROWTH_DUTY_RUNTIME_IGNITION_001/self_growth_heartbeat.json"
  $Phase153StopPath = "living_learning_environment/self_growth_cycles/PHASE153_SELF_GROWTH_DUTY_RUNTIME_IGNITION_001/runtime_stop_decision.json"
  $Phase154HeartbeatPath = "living_learning_environment/self_growth_cycles/PHASE154_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_001/self_growth_heartbeat.json"
  $Phase154TrialResultPath = "living_learning_environment/self_growth_cycles/PHASE154_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_001/bounded_trial_result.json"
  $Phase154StopPath = "living_learning_environment/self_growth_cycles/PHASE154_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_001/runtime_stop_decision.json"
  $RuntimePath = "living_learning_environment/self_growth_runtime/SELF_GROWTH_DUTY_RUNTIME_V1.json"
  $RuntimeContractPath = "living_learning_environment/self_growth_runtime/SELF_GROWTH_DUTY_RUNTIME_CONTRACT_V1.json"
  $CurriculumPath = "living_learning_environment/self_growth_runtime/SELF_GROWTH_CURRICULUM_V1.json"
  $SafetyPolicyPath = "living_learning_environment/self_growth_runtime/SELF_GROWTH_SAFETY_POLICY_V1.json"
  $BodyPackPath = "living_learning_environment/body/BUILDER_BODY_ORGAN_PACK_V1.json"
  $BodyPolicyPath = "living_learning_environment/body/body_policy.json"
  $SourcePolicyPath = "source_registry/source_policy.json"
  $TrustedSourcesPath = "source_registry/trusted_sources.json"
  $QueuePath = "TASK_QUEUE.json"
  $ReviewBootPath = "$ReviewRoot/review_boot.json"
  $EvidenceChainReviewPath = "$ReviewRoot/evidence_chain_review.json"
  $Phase153ReviewPath = "$ReviewRoot/phase153_review.json"
  $Phase154ReviewPath = "$ReviewRoot/phase154_review.json"
  $RuntimeSafetyReviewPath = "$ReviewRoot/runtime_safety_review.json"
  $RuntimeReuseDecisionPath = "$ReviewRoot/runtime_reuse_decision.json"
  $RuntimeAdmissionDecisionPath = "$ReviewRoot/runtime_admission_decision.json"
  $BoundedReusePolicyPath = "$ReviewRoot/bounded_reuse_policy.json"
  $NonPromotionDecisionPath = "$ReviewRoot/non_promotion_decision.json"
  $SelfModelUpdateCandidatePath = "$ReviewRoot/self_model_update_candidate.json"
  $NextTrialTicketPath = "$ReviewRoot/next_trial_ticket.json"
  $NextCycleDecisionPath = "$ReviewRoot/next_cycle_decision.json"
  $AdmissionReviewTracePath = "$ReviewRoot/admission_review_trace.json"
  $ResultPath = "self_control/BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_RESULT.json"
  $ReportPath = "reports/self_development/PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1_REPORT.json"
  $ProofPath = "proofs/self_development/PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1.json"
  $RuntimeOutputs = @($ReviewBootPath, $EvidenceChainReviewPath, $Phase153ReviewPath, $Phase154ReviewPath, $RuntimeSafetyReviewPath, $RuntimeReuseDecisionPath, $RuntimeAdmissionDecisionPath, $BoundedReusePolicyPath, $NonPromotionDecisionPath, $SelfModelUpdateCandidatePath, $NextTrialTicketPath, $NextCycleDecisionPath, $AdmissionReviewTracePath)
  $AllowedExact = @($RouteAlignmentPath, $ModulePath, $ValidatorPath, $ResultPath, $ReportPath, $ProofPath) + $RuntimeOutputs

  $RepoRoot = Resolve-Phase155ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot
  $Pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase155ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE155_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }
  Assert-Phase155ValidatorEquals -Actual $Branch -Expected "phase110-idempotent-autonomy-trial-runtime" -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  Assert-Phase155ValidatorEquals -Actual $Head -Expected "ea96c06" -Name "current_head"

  foreach ($requiredPath in @($RouteAlignmentPath, $ModulePath, $ValidatorPath, $Phase153ProofPath, $Phase154ProofPath, $Phase154ResultPath, $Phase154ReportPath, $Phase153HeartbeatPath, $Phase153StopPath, $Phase154HeartbeatPath, $Phase154TrialResultPath, $Phase154StopPath, $RuntimePath, $RuntimeContractPath, $CurriculumPath, $SafetyPolicyPath, $BodyPackPath, $BodyPolicyPath, $SourcePolicyPath, $TrustedSourcesPath, $QueuePath, $ResultPath, $ReportPath, $ProofPath) + $RuntimeOutputs) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase155ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE155_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $StatusLines = @(git status --short --untracked-files=all)
  foreach ($line in $StatusLines) {
    $path = Get-Phase155StatusPath -StatusLine $line
    if (-not ($AllowedExact -contains $path)) {
      throw "PHASE155_VALIDATE_CHANGE_OUTSIDE_ALLOWED_SCOPE=$line"
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
    self_control/BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_RESULT.json 2>$null)
  if ($ProtectedStatus.Count -gt 0) {
    throw "PHASE155_VALIDATE_PROTECTED_SCOPE_CHANGED=$($ProtectedStatus -join '; ')"
  }

  $Phase153Proof = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $Phase153ProofPath
  Assert-Phase155ValidatorEquals -Actual $Phase153Proof.status -Expected "PASS" -Name "phase153_status"
  Assert-Phase155ValidatorEquals -Actual $Phase153Proof.cycle_count -Expected 2 -Name "phase153_cycle_count"
  Assert-Phase155ValidatorTrue -Actual $Phase153Proof.self_growth_loop_proven -Name "phase153_loop_proven"
  Assert-Phase155ValidatorTrue -Actual $Phase153Proof.ready_for_phase154_bounded_trial -Name "phase153_ready_phase154"

  $Phase154Proof = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $Phase154ProofPath
  Assert-Phase155ValidatorEquals -Actual $Phase154Proof.status -Expected "PASS" -Name "phase154_status"
  Assert-Phase155ValidatorEquals -Actual $Phase154Proof.cycle_count -Expected 3 -Name "phase154_cycle_count"
  Assert-Phase155ValidatorTrue -Actual $Phase154Proof.bounded_self_growth_trial_proven -Name "phase154_trial_proven"
  Assert-Phase155ValidatorTrue -Actual $Phase154Proof.all_cycles_validated -Name "phase154_all_cycles"
  Assert-Phase155ValidatorTrue -Actual $Phase154Proof.no_codex_needed_inside_cycles -Name "phase154_no_codex"
  Assert-Phase155ValidatorTrue -Actual $Phase154Proof.safe_stop -Name "phase154_safe_stop"
  Assert-Phase155ValidatorEquals -Actual $Phase154Proof.next_allowed_step -Expected $StepId -Name "phase154_next_allowed_step"

  $EvidenceChainReview = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $EvidenceChainReviewPath
  Assert-Phase155ValidatorTrue -Actual $EvidenceChainReview.phase153_verified -Name "evidence_phase153"
  Assert-Phase155ValidatorTrue -Actual $EvidenceChainReview.phase154_verified -Name "evidence_phase154"
  Assert-Phase155ValidatorEquals -Actual $EvidenceChainReview.total_self_growth_cycles_reviewed -Expected 5 -Name "evidence_cycle_count"
  Assert-Phase155ValidatorTrue -Actual $EvidenceChainReview.runtime_outputs_present -Name "evidence_outputs_present"

  $RuntimeSafetyReview = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $RuntimeSafetyReviewPath
  foreach ($flag in @("accepted_state_mutation_detected", "external_fetch_detected", "dependency_install_detected", "arbitrary_code_execution_detected", "capability_shelf_mutation_detected", "runtime_modified", "body_pack_mutated")) {
    Assert-Phase155ValidatorFalse -Actual $RuntimeSafetyReview.$flag -Name "runtime_safety_$flag"
  }

  $RuntimeReuseDecision = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $RuntimeReuseDecisionPath
  Assert-Phase155ValidatorEquals -Actual $RuntimeReuseDecision.reuse_decision -Expected "ADMIT_FOR_BOUNDED_SANDBOX_REUSE" -Name "reuse_decision"
  Assert-Phase155ValidatorEquals -Actual $RuntimeReuseDecision.allowed_scope -Expected "sandbox_only" -Name "reuse_allowed_scope"
  Assert-Phase155ValidatorEquals -Actual $RuntimeReuseDecision.max_cycles_per_run -Expected 3 -Name "reuse_max_cycles"
  Assert-Phase155ValidatorTrue -Actual $RuntimeReuseDecision.owner_approval_required_for_scope_increase -Name "reuse_owner_scope_increase"

  $RuntimeAdmissionDecision = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $RuntimeAdmissionDecisionPath
  Assert-Phase155ValidatorEquals -Actual $RuntimeAdmissionDecision.admission_status -Expected "ADMITTED_FOR_BOUNDED_SELF_GROWTH_SANDBOX_USE" -Name "admission_status"
  Assert-Phase155ValidatorFalse -Actual $RuntimeAdmissionDecision.unrestricted_autonomy_approved -Name "admission_unrestricted"
  Assert-Phase155ValidatorFalse -Actual $RuntimeAdmissionDecision.accepted_core_promotion_approved -Name "admission_core_promotion"
  Assert-Phase155ValidatorFalse -Actual $RuntimeAdmissionDecision.capability_shelf_promotion_approved -Name "admission_shelf_promotion"

  $BoundedReusePolicy = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $BoundedReusePolicyPath
  Assert-Phase155ValidatorEquals -Actual $BoundedReusePolicy.allowed_next_use -Expected "self_selected_gap_trial" -Name "policy_allowed_next_use"
  Assert-Phase155ValidatorEquals -Actual $BoundedReusePolicy.max_cycle_count -Expected 3 -Name "policy_max_cycle_count"
  Assert-Phase155ValidatorFalse -Actual $BoundedReusePolicy.accepted_state_mutation_allowed -Name "policy_state_mutation_allowed"
  Assert-Phase155ValidatorFalse -Actual $BoundedReusePolicy.external_fetch_allowed -Name "policy_fetch_allowed"
  Assert-Phase155ValidatorFalse -Actual $BoundedReusePolicy.install_allowed -Name "policy_install_allowed"

  $NonPromotionDecision = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $NonPromotionDecisionPath
  Assert-Phase155ValidatorFalse -Actual $NonPromotionDecision.runtime_promoted_to_accepted_core -Name "non_promotion_runtime_promoted"
  Assert-Phase155ValidatorEquals -Actual $NonPromotionDecision.reason -Expected "bounded runtime is proven for sandbox self-growth only; accepted core promotion requires later admission" -Name "non_promotion_reason"

  $SelfModelUpdateCandidate = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $SelfModelUpdateCandidatePath
  Assert-Phase155ValidatorEquals -Actual $SelfModelUpdateCandidate.update_type -Expected "SELF_GROWTH_RUNTIME_ADMISSION_CANDIDATE" -Name "self_model_update_type"
  Assert-Phase155ValidatorFalse -Actual $SelfModelUpdateCandidate.accepted_self_model_mutated -Name "self_model_mutated"

  $NextTrialTicket = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $NextTrialTicketPath
  Assert-Phase155ValidatorEquals -Actual $NextTrialTicket.ticket_status -Expected "ISSUED_FOR_PHASE156_ONLY" -Name "ticket_status"
  Assert-Phase155ValidatorEquals -Actual $NextTrialTicket.trial_type -Expected "SELF_SELECTED_GAP_SELF_BUILD_TRIAL" -Name "ticket_trial_type"
  Assert-Phase155ValidatorEquals -Actual $NextTrialTicket.allowed_scope -Expected "sandbox_only" -Name "ticket_allowed_scope"
  Assert-Phase155ValidatorEquals -Actual $NextTrialTicket.max_cycle_count -Expected 3 -Name "ticket_max_cycle_count"
  Assert-Phase155ValidatorFalse -Actual $NextTrialTicket.accepted_state_mutation_allowed -Name "ticket_state_mutation"

  $NextCycleDecision = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $NextCycleDecisionPath
  Assert-Phase155ValidatorEquals -Actual $NextCycleDecision.next_action -Expected "RUN_SELF_SELECTED_GAP_SELF_BUILD_TRIAL" -Name "next_cycle_action"
  Assert-Phase155ValidatorFalse -Actual $NextCycleDecision.codex_needed_for_next_step -Name "next_cycle_codex_needed"
  Assert-Phase155ValidatorEquals -Actual $NextCycleDecision.next_allowed_step -Expected $NextAllowedStep -Name "next_cycle_next_allowed_step"

  $Result = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath
  Assert-Phase155ProofFields -Artifact $Result -Name "result"
  Assert-Phase155ProofFields -Artifact $Proof -Name "proof"

  Assert-Phase155ValidatorEquals -Actual $Report.root_cause -Expected "PHASE155 entrypoint absent" -Name "report_root_cause"
  Assert-Phase155ValidatorEquals -Actual $Report.module_path -Expected $ModulePath -Name "report_module_path"
  Assert-Phase155ValidatorEquals -Actual $Report.validator_path -Expected $ValidatorPath -Name "report_validator_path"
  Assert-Phase155ValidatorEquals -Actual $Report.exact_run_command_expected -Expected ".\modules\invoke_builder_self_growth_runtime_admission_review_001.ps1" -Name "report_run_command"
  Assert-Phase155ValidatorEquals -Actual $Report.exact_validator_command_expected -Expected ".\validators\validate_phase155_builder_self_growth_runtime_admission_review_v1.ps1 -RepoRoot ." -Name "report_validator_command"
  foreach ($runtimePath in ($RuntimeOutputs + @($ResultPath, $ReportPath, $ProofPath))) {
    if (-not (@($Report.runtime_output_files_created) -contains $runtimePath)) {
      throw "PHASE155_VALIDATE_REPORT_RUNTIME_OUTPUT_MISSING=$runtimePath"
    }
  }

  $Queue = Read-Phase155ValidatorJson -RepoRoot $RepoRoot -Path $QueuePath
  Assert-Phase155ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  Write-Host "PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_VALIDATE_RESULT=PASS"
  Write-Host "PHASE153_VERIFIED=True"
  Write-Host "PHASE154_VERIFIED=True"
  Write-Host "TOTAL_SELF_GROWTH_CYCLES_REVIEWED=5"
  Write-Host "RUNTIME_EVIDENCE_CHAIN_VERIFIED=True"
  Write-Host "ADMISSION_STATUS=ADMITTED_FOR_BOUNDED_SELF_GROWTH_SANDBOX_USE"
  Write-Host "REUSE_DECISION=ADMIT_FOR_BOUNDED_SANDBOX_REUSE"
  Write-Host "ALLOWED_SCOPE=sandbox_only"
  Write-Host "MAX_CYCLES_PER_RUN=3"
  Write-Host "UNRESTRICTED_AUTONOMY_APPROVED=False"
  Write-Host "ACCEPTED_CORE_PROMOTION_APPROVED=False"
  Write-Host "CAPABILITY_SHELF_PROMOTION_APPROVED=False"
  Write-Host "RUNTIME_PROMOTED_TO_ACCEPTED_CORE=False"
  Write-Host "ACCEPTED_STATE_MUTATED=False"
  Write-Host "ACCEPTED_MEMORY_MUTATED=False"
  Write-Host "ACCEPTED_SELF_MODEL_MUTATED=False"
  Write-Host "EXTERNAL_FETCH_PERFORMED=False"
  Write-Host "DEPENDENCY_INSTALL_PERFORMED=False"
  Write-Host "ARBITRARY_CODE_EXECUTION_USED=False"
  Write-Host "QUEUE_AFTER=NONE"
  Write-Host "CODEX_NEEDED_FOR_NEXT_STEP=False"
  Write-Host "NEXT_ALLOWED_STEP=PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1"
} catch {
  Write-Host "PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE155_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
