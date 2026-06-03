param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase157ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase157ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase157ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE157_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Assert-Phase157ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE157_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase157ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE157_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase157ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE157_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase157StatusPath {
  param([string]$StatusLine)

  if ($StatusLine -match '^.. (.+)$') {
    return ($Matches[1] -replace '\\', '/')
  }
  return ($StatusLine -replace '\\', '/')
}

function Assert-Phase157Phase156Proof {
  param([object]$Proof)

  Assert-Phase157ValidatorEquals -Actual $Proof.status -Expected "PASS" -Name "phase156_status"
  Assert-Phase157ValidatorEquals -Actual $Proof.next_allowed_step -Expected "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1" -Name "phase156_next_allowed_step"
  Assert-Phase157ValidatorTrue -Actual $Proof.self_selected_gap_trial_proven -Name "phase156_trial_proven"
  Assert-Phase157ValidatorTrue -Actual $Proof.all_cycles_validated -Name "phase156_all_cycles_validated"
  Assert-Phase157ValidatorTrue -Actual $Proof.no_codex_needed_inside_cycles -Name "phase156_no_codex_inside"
  Assert-Phase157ValidatorTrue -Actual $Proof.safe_stop -Name "phase156_safe_stop"
  Assert-Phase157ValidatorFalse -Actual $Proof.owner_selected_each_gap -Name "phase156_owner_selected"
  Assert-Phase157ValidatorFalse -Actual $Proof.codex_selected_each_gap -Name "phase156_codex_selected"
}

function Assert-Phase157CycleReview {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$CycleId,
    [string]$ExpectedGap,
    [string]$ExpectedSkillId,
    [string]$ExpectedNextGap
  )

  $Review = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $Path
  Assert-Phase157ValidatorEquals -Actual $Review.status -Expected "PASS" -Name "${CycleId}:status"
  Assert-Phase157ValidatorEquals -Actual $Review.cycle_id -Expected $CycleId -Name "${CycleId}:cycle_id"
  Assert-Phase157ValidatorEquals -Actual $Review.selected_gap -Expected $ExpectedGap -Name "${CycleId}:selected_gap"
  Assert-Phase157ValidatorEquals -Actual $Review.skill_id -Expected $ExpectedSkillId -Name "${CycleId}:skill_id"
  Assert-Phase157ValidatorEquals -Actual $Review.validation_status -Expected "PASS" -Name "${CycleId}:validation_status"
  Assert-Phase157ValidatorEquals -Actual $Review.review_status -Expected "VALIDATED_SANDBOX_CANDIDATE" -Name "${CycleId}:review_status"
  Assert-Phase157ValidatorEquals -Actual $Review.promotion_status -Expected "NOT_PROMOTED" -Name "${CycleId}:promotion_status"
  Assert-Phase157ValidatorFalse -Actual $Review.rollback_required -Name "${CycleId}:rollback_required"
  Assert-Phase157ValidatorFalse -Actual $Review.quarantine_required -Name "${CycleId}:quarantine_required"
  Assert-Phase157ValidatorFalse -Actual $Review.skill_candidates_promoted -Name "${CycleId}:skill_candidates_promoted"
  Assert-Phase157ValidatorFalse -Actual $Review.accepted_capability_created -Name "${CycleId}:accepted_capability_created"
  Assert-Phase157ValidatorFalse -Actual $Review.accepted_state_mutated -Name "${CycleId}:accepted_state_mutated"
  Assert-Phase157ValidatorEquals -Actual $Review.next_selected_gap -Expected $ExpectedNextGap -Name "${CycleId}:next_selected_gap"
}

function Assert-Phase157ProofFields {
  param(
    [object]$Artifact,
    [string]$Name
  )

  Assert-Phase157ValidatorEquals -Actual $Artifact.status -Expected "PASS" -Name "${Name}:status"
  Assert-Phase157ValidatorEquals -Actual $Artifact.step_id -Expected "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1" -Name "${Name}:step_id"
  Assert-Phase157ValidatorEquals -Actual $Artifact.run_id -Expected "PHASE157_SELF_SELECTED_GAP_TRIAL_REVIEW_001" -Name "${Name}:run_id"
  Assert-Phase157ValidatorTrue -Actual $Artifact.phase156_verified -Name "${Name}:phase156_verified"
  Assert-Phase157ValidatorTrue -Actual $Artifact.phase156_trial_reviewed -Name "${Name}:phase156_reviewed"
  Assert-Phase157ValidatorEquals -Actual $Artifact.cycle_count_reviewed -Expected 3 -Name "${Name}:cycle_count_reviewed"
  Assert-Phase157ValidatorTrue -Actual $Artifact.gap_chain_verified -Name "${Name}:gap_chain_verified"
  Assert-Phase157ValidatorTrue -Actual $Artifact.skill_candidates_reviewed -Name "${Name}:skill_candidates_reviewed"
  Assert-Phase157ValidatorEquals -Actual $Artifact.skill_candidate_count -Expected 3 -Name "${Name}:skill_candidate_count"
  Assert-Phase157ValidatorEquals -Actual $Artifact.cycle_006_review_status -Expected "VALIDATED_SANDBOX_CANDIDATE" -Name "${Name}:cycle006_review"
  Assert-Phase157ValidatorEquals -Actual $Artifact.cycle_007_review_status -Expected "VALIDATED_SANDBOX_CANDIDATE" -Name "${Name}:cycle007_review"
  Assert-Phase157ValidatorEquals -Actual $Artifact.cycle_008_review_status -Expected "VALIDATED_SANDBOX_CANDIDATE" -Name "${Name}:cycle008_review"
  Assert-Phase157ValidatorTrue -Actual $Artifact.sandbox_candidate_decision_created -Name "${Name}:sandbox_decision_created"
  Assert-Phase157ValidatorEquals -Actual $Artifact.sandbox_candidate_decision -Expected "KEEP_AS_VALIDATED_SANDBOX_CANDIDATES" -Name "${Name}:sandbox_decision"
  Assert-Phase157ValidatorFalse -Actual $Artifact.rollback_required -Name "${Name}:rollback_required"
  Assert-Phase157ValidatorFalse -Actual $Artifact.quarantine_required -Name "${Name}:quarantine_required"
  Assert-Phase157ValidatorTrue -Actual $Artifact.non_promotion_decision_created -Name "${Name}:non_promotion_created"
  Assert-Phase157ValidatorFalse -Actual $Artifact.skill_candidates_promoted -Name "${Name}:skill_candidates_promoted"
  Assert-Phase157ValidatorFalse -Actual $Artifact.accepted_capability_created -Name "${Name}:accepted_capability_created"
  Assert-Phase157ValidatorTrue -Actual $Artifact.bounded_reuse_decision_created -Name "${Name}:bounded_reuse_created"
  Assert-Phase157ValidatorEquals -Actual $Artifact.reuse_decision -Expected "ADMIT_PHASE156_CANDIDATES_FOR_BOUNDED_SANDBOX_REUSE" -Name "${Name}:reuse_decision"
  Assert-Phase157ValidatorEquals -Actual $Artifact.allowed_scope -Expected "sandbox_only" -Name "${Name}:allowed_scope"
  Assert-Phase157ValidatorTrue -Actual $Artifact.self_model_update_candidate_created -Name "${Name}:self_model_candidate_created"
  Assert-Phase157ValidatorTrue -Actual $Artifact.next_reuse_ticket_created -Name "${Name}:next_ticket_created"
  Assert-Phase157ValidatorTrue -Actual $Artifact.next_cycle_decision_created -Name "${Name}:next_cycle_decision_created"
  Assert-Phase157ValidatorFalse -Actual $Artifact.codex_needed_for_next_step -Name "${Name}:codex_needed_next"
  foreach ($flag in @("accepted_state_mutated", "accepted_memory_mutated", "accepted_self_model_mutated", "external_fetch_performed", "dependency_install_performed", "executable_materials_used", "arbitrary_code_execution_used", "external_agents_created", "orchestrator_changed", "route_lock_changed", "current_runtime_changed", "capability_shelf_mutated", "body_pack_mutated")) {
    Assert-Phase157ValidatorFalse -Actual $Artifact.$flag -Name "${Name}:$flag"
  }
  Assert-Phase157ValidatorEquals -Actual $Artifact.trusted_source_count -Expected 0 -Name "${Name}:trusted_source_count"
  Assert-Phase157ValidatorEquals -Actual $Artifact.queue_after -Expected "NONE" -Name "${Name}:queue_after"
  Assert-Phase157ValidatorEquals -Actual $Artifact.next_allowed_step -Expected "PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1" -Name "${Name}:next_allowed_step"
}

$Pushed = $false

try {
  $StepId = "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1"
  $RunId = "PHASE157_SELF_SELECTED_GAP_TRIAL_REVIEW_001"
  $NextAllowedStep = "PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1"
  $Phase156RunId = "PHASE156_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_001"
  $Phase156Root = "living_learning_environment/self_growth_cycles/$Phase156RunId"
  $ReviewRoot = "living_learning_environment/trial_reviews/$RunId"
  $RouteAlignmentPath = "route_change_requests/PHASE157_SELF_SELECTED_GAP_TRIAL_REVIEW_ALIGNMENT_REQUEST.md"
  $ModulePath = "modules/invoke_builder_self_selected_gap_trial_review_001.ps1"
  $ValidatorPath = "validators/validate_phase157_builder_self_selected_gap_trial_review_v1.ps1"
  $Phase156ProofPath = "proofs/self_development/PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1.json"
  $Phase156ResultPath = "self_control/BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_RESULT.json"
  $Phase156ReportPath = "reports/self_development/PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1_REPORT.json"
  $Phase156TrialResultPath = "$Phase156Root/self_selected_gap_trial_result.json"
  $Phase156SkillIndexPath = "$Phase156Root/built_skill_candidates_index.json"
  $Phase156StopPath = "$Phase156Root/runtime_stop_decision.json"
  $Phase155BoundedPolicyPath = "living_learning_environment/admission_reviews/PHASE155_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_001/bounded_reuse_policy.json"
  $SafetyPolicyPath = "living_learning_environment/self_growth_runtime/SELF_GROWTH_SAFETY_POLICY_V1.json"
  $BodyPackPath = "living_learning_environment/body/BUILDER_BODY_ORGAN_PACK_V1.json"
  $BodyPolicyPath = "living_learning_environment/body/body_policy.json"
  $SourcePolicyPath = "source_registry/source_policy.json"
  $TrustedSourcesPath = "source_registry/trusted_sources.json"
  $QueuePath = "TASK_QUEUE.json"
  $Cycle006GapSelectionPath = "$Phase156Root/cycle_006/gap_selection.json"
  $Cycle006SkillCandidatePath = "$Phase156Root/cycle_006/skill_candidate.json"
  $Cycle006ValidationPath = "$Phase156Root/cycle_006/skill_validation_result.json"
  $Cycle006NextPath = "$Phase156Root/cycle_006/next_selected_gap.json"
  $Cycle007GapSelectionPath = "$Phase156Root/cycle_007/gap_selection.json"
  $Cycle007SkillCandidatePath = "$Phase156Root/cycle_007/skill_candidate.json"
  $Cycle007ValidationPath = "$Phase156Root/cycle_007/skill_validation_result.json"
  $Cycle007NextPath = "$Phase156Root/cycle_007/next_selected_gap.json"
  $Cycle008GapSelectionPath = "$Phase156Root/cycle_008/gap_selection.json"
  $Cycle008SkillCandidatePath = "$Phase156Root/cycle_008/skill_candidate.json"
  $Cycle008ValidationPath = "$Phase156Root/cycle_008/skill_validation_result.json"
  $Cycle008NextPath = "$Phase156Root/cycle_008/next_selected_gap.json"
  $ReviewBootPath = "$ReviewRoot/review_boot.json"
  $EvidenceReadPath = "$ReviewRoot/phase156_evidence_read.json"
  $Cycle006ReviewPath = "$ReviewRoot/cycle_006_review.json"
  $Cycle007ReviewPath = "$ReviewRoot/cycle_007_review.json"
  $Cycle008ReviewPath = "$ReviewRoot/cycle_008_review.json"
  $GapChainReviewPath = "$ReviewRoot/gap_chain_review.json"
  $SkillQualityReviewPath = "$ReviewRoot/skill_candidate_quality_review.json"
  $SkillValidationReviewPath = "$ReviewRoot/skill_validation_review.json"
  $SandboxCandidateDecisionPath = "$ReviewRoot/sandbox_candidate_decision.json"
  $NonPromotionDecisionPath = "$ReviewRoot/non_promotion_decision.json"
  $BoundedReuseDecisionPath = "$ReviewRoot/bounded_reuse_decision.json"
  $SelfModelUpdateCandidatePath = "$ReviewRoot/self_model_update_candidate.json"
  $NextReuseTicketPath = "$ReviewRoot/next_reuse_ticket.json"
  $NextCycleDecisionPath = "$ReviewRoot/next_cycle_decision.json"
  $TrialReviewTracePath = "$ReviewRoot/trial_review_trace.json"
  $ResultPath = "self_control/BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_RESULT.json"
  $ReportPath = "reports/self_development/PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1_REPORT.json"
  $ProofPath = "proofs/self_development/PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1.json"
  $RuntimeOutputs = @($ReviewBootPath, $EvidenceReadPath, $Cycle006ReviewPath, $Cycle007ReviewPath, $Cycle008ReviewPath, $GapChainReviewPath, $SkillQualityReviewPath, $SkillValidationReviewPath, $SandboxCandidateDecisionPath, $NonPromotionDecisionPath, $BoundedReuseDecisionPath, $SelfModelUpdateCandidatePath, $NextReuseTicketPath, $NextCycleDecisionPath, $TrialReviewTracePath)
  $AllowedExact = @($RouteAlignmentPath, $ModulePath, $ValidatorPath, $ResultPath, $ReportPath, $ProofPath) + $RuntimeOutputs
  $AllowedCandidateIds = @("SELF_GAP_INVENTORY_SKILL_CANDIDATE_V1", "SELF_REPAIR_TASK_SPEC_WRITER_SKILL_CANDIDATE_V1", "SELF_PROOF_SUMMARY_SKILL_CANDIDATE_V1")

  $RepoRoot = Resolve-Phase157ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot
  $Pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase157ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE157_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }
  Assert-Phase157ValidatorEquals -Actual $Branch -Expected "phase110-idempotent-autonomy-trial-runtime" -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  Assert-Phase157ValidatorEquals -Actual $Head -Expected "86d848b" -Name "current_head"

  $RequiredPaths = @(
    $RouteAlignmentPath,
    $ModulePath,
    $ValidatorPath,
    $Phase156ProofPath,
    $Phase156ResultPath,
    $Phase156ReportPath,
    $Phase156TrialResultPath,
    $Phase156SkillIndexPath,
    $Phase156StopPath,
    $Cycle006GapSelectionPath,
    $Cycle006SkillCandidatePath,
    $Cycle006ValidationPath,
    $Cycle006NextPath,
    $Cycle007GapSelectionPath,
    $Cycle007SkillCandidatePath,
    $Cycle007ValidationPath,
    $Cycle007NextPath,
    $Cycle008GapSelectionPath,
    $Cycle008SkillCandidatePath,
    $Cycle008ValidationPath,
    $Cycle008NextPath,
    $Phase155BoundedPolicyPath,
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
    if (-not (Test-Path -LiteralPath (Resolve-Phase157ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE157_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $StatusLines = @(git status --short --untracked-files=all)
  foreach ($line in $StatusLines) {
    $path = Get-Phase157StatusPath -StatusLine $line
    if (-not ($AllowedExact -contains $path)) {
      throw "PHASE157_VALIDATE_CHANGE_OUTSIDE_ALLOWED_SCOPE=$line"
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
    self_control/BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_RESULT.json 2>$null)
  if ($ProtectedStatus.Count -gt 0) {
    throw "PHASE157_VALIDATE_PROTECTED_SCOPE_CHANGED=$($ProtectedStatus -join '; ')"
  }

  $Phase156Proof = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $Phase156ProofPath
  Assert-Phase157Phase156Proof -Proof $Phase156Proof

  $Phase156Result = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $Phase156ResultPath
  Assert-Phase157Phase156Proof -Proof $Phase156Result

  $Phase156TrialResult = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $Phase156TrialResultPath
  Assert-Phase157Phase156Proof -Proof $Phase156TrialResult

  $Phase156Stop = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $Phase156StopPath
  Assert-Phase157ValidatorTrue -Actual $Phase156Stop.safe_stop -Name "phase156_stop_safe"
  Assert-Phase157ValidatorEquals -Actual $Phase156Stop.stop_reason -Expected "PHASE156_CYCLE_LIMIT_REACHED" -Name "phase156_stop_reason"

  $SkillIndex = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $Phase156SkillIndexPath
  Assert-Phase157ValidatorEquals -Actual $SkillIndex.skill_candidate_count -Expected 3 -Name "phase156_skill_index_count"
  foreach ($skillId in $AllowedCandidateIds) {
    if (-not (@($SkillIndex.skill_candidates | ForEach-Object { $_.skill_id }) -contains $skillId)) {
      throw "PHASE157_VALIDATE_SKILL_INDEX_MISSING=$skillId"
    }
  }

  $Cycle006Gap = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $Cycle006GapSelectionPath
  $Cycle006Next = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $Cycle006NextPath
  $Cycle007Gap = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $Cycle007GapSelectionPath
  $Cycle007Next = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $Cycle007NextPath
  $Cycle008Gap = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $Cycle008GapSelectionPath
  $Cycle008Next = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $Cycle008NextPath
  Assert-Phase157ValidatorEquals -Actual $Cycle006Gap.selected_gap -Expected "SELF_GAP_INVENTORY_GAP" -Name "cycle006_selected_gap"
  Assert-Phase157ValidatorEquals -Actual $Cycle006Next.next_selected_gap -Expected "SELF_REPAIR_TASK_SPEC_WRITER_GAP" -Name "cycle006_next_gap"
  Assert-Phase157ValidatorEquals -Actual $Cycle007Gap.selected_gap -Expected "SELF_REPAIR_TASK_SPEC_WRITER_GAP" -Name "cycle007_selected_gap"
  Assert-Phase157ValidatorEquals -Actual $Cycle007Next.next_selected_gap -Expected "SELF_PROOF_SUMMARY_GAP" -Name "cycle007_next_gap"
  Assert-Phase157ValidatorEquals -Actual $Cycle008Gap.selected_gap -Expected "SELF_PROOF_SUMMARY_GAP" -Name "cycle008_selected_gap"
  Assert-Phase157ValidatorEquals -Actual $Cycle008Next.next_selected_gap -Expected "STOP_PHASE156_CYCLE_LIMIT_REACHED" -Name "cycle008_next_gap"

  Assert-Phase157CycleReview -RepoRoot $RepoRoot -Path $Cycle006ReviewPath -CycleId "cycle_006" -ExpectedGap "SELF_GAP_INVENTORY_GAP" -ExpectedSkillId "SELF_GAP_INVENTORY_SKILL_CANDIDATE_V1" -ExpectedNextGap "SELF_REPAIR_TASK_SPEC_WRITER_GAP"
  Assert-Phase157CycleReview -RepoRoot $RepoRoot -Path $Cycle007ReviewPath -CycleId "cycle_007" -ExpectedGap "SELF_REPAIR_TASK_SPEC_WRITER_GAP" -ExpectedSkillId "SELF_REPAIR_TASK_SPEC_WRITER_SKILL_CANDIDATE_V1" -ExpectedNextGap "SELF_PROOF_SUMMARY_GAP"
  Assert-Phase157CycleReview -RepoRoot $RepoRoot -Path $Cycle008ReviewPath -CycleId "cycle_008" -ExpectedGap "SELF_PROOF_SUMMARY_GAP" -ExpectedSkillId "SELF_PROOF_SUMMARY_SKILL_CANDIDATE_V1" -ExpectedNextGap "STOP_PHASE156_CYCLE_LIMIT_REACHED"

  $GapChainReview = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $GapChainReviewPath
  Assert-Phase157ValidatorTrue -Actual $GapChainReview.gap_chain_verified -Name "gap_chain_verified"
  Assert-Phase157ValidatorEquals -Actual $GapChainReview.cycle_count_reviewed -Expected 3 -Name "gap_chain_cycle_count"
  Assert-Phase157ValidatorEquals -Actual $GapChainReview.terminal_next_selected_gap -Expected "STOP_PHASE156_CYCLE_LIMIT_REACHED" -Name "gap_chain_terminal"

  $QualityReview = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $SkillQualityReviewPath
  Assert-Phase157ValidatorTrue -Actual $QualityReview.skill_candidates_reviewed -Name "quality_reviewed"
  Assert-Phase157ValidatorEquals -Actual $QualityReview.skill_candidate_count -Expected 3 -Name "quality_count"
  Assert-Phase157ValidatorTrue -Actual $QualityReview.all_candidates_sandbox_only -Name "quality_sandbox_only"
  Assert-Phase157ValidatorFalse -Actual $QualityReview.accepted_capability_created -Name "quality_accepted_capability"

  $ValidationReview = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $SkillValidationReviewPath
  Assert-Phase157ValidatorEquals -Actual $ValidationReview.validation_review_status -Expected "PASS" -Name "validation_review_status"
  Assert-Phase157ValidatorTrue -Actual $ValidationReview.all_validations_passed -Name "validation_all_passed"
  Assert-Phase157ValidatorEquals -Actual $ValidationReview.validation_count -Expected 3 -Name "validation_count"

  $SandboxDecision = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $SandboxCandidateDecisionPath
  Assert-Phase157ValidatorEquals -Actual $SandboxDecision.decision -Expected "KEEP_AS_VALIDATED_SANDBOX_CANDIDATES" -Name "sandbox_decision"
  Assert-Phase157ValidatorEquals -Actual $SandboxDecision.candidate_count -Expected 3 -Name "sandbox_candidate_count"
  Assert-Phase157ValidatorFalse -Actual $SandboxDecision.rollback_required -Name "sandbox_rollback"
  Assert-Phase157ValidatorFalse -Actual $SandboxDecision.quarantine_required -Name "sandbox_quarantine"
  Assert-Phase157ValidatorEquals -Actual $SandboxDecision.promotion_status -Expected "NOT_PROMOTED" -Name "sandbox_promotion"

  $NonPromotion = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $NonPromotionDecisionPath
  Assert-Phase157ValidatorFalse -Actual $NonPromotion.skill_candidates_promoted -Name "non_promotion_skill_promoted"
  Assert-Phase157ValidatorFalse -Actual $NonPromotion.accepted_capability_created -Name "non_promotion_accepted_capability"
  Assert-Phase157ValidatorEquals -Actual $NonPromotion.reason -Expected "PHASE156 candidates are validated sandbox candidates only; accepted promotion requires later admission." -Name "non_promotion_reason"

  $BoundedReuse = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $BoundedReuseDecisionPath
  Assert-Phase157ValidatorEquals -Actual $BoundedReuse.reuse_decision -Expected "ADMIT_PHASE156_CANDIDATES_FOR_BOUNDED_SANDBOX_REUSE" -Name "bounded_reuse_decision"
  Assert-Phase157ValidatorEquals -Actual $BoundedReuse.allowed_scope -Expected "sandbox_only" -Name "bounded_reuse_scope"
  Assert-Phase157ValidatorEquals -Actual $BoundedReuse.allowed_use -Expected "REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL" -Name "bounded_reuse_use"
  Assert-Phase157ValidatorEquals -Actual $BoundedReuse.max_cycles_per_run -Expected 3 -Name "bounded_reuse_max_cycles"

  $SelfModelCandidate = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $SelfModelUpdateCandidatePath
  Assert-Phase157ValidatorEquals -Actual $SelfModelCandidate.update_type -Expected "SELF_SELECTED_GAP_SKILLS_REVIEW_CANDIDATE" -Name "self_model_update_type"
  Assert-Phase157ValidatorFalse -Actual $SelfModelCandidate.accepted_self_model_mutated -Name "self_model_mutated"

  $NextTicket = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $NextReuseTicketPath
  Assert-Phase157ValidatorEquals -Actual $NextTicket.ticket_status -Expected "ISSUED_FOR_PHASE158_ONLY" -Name "ticket_status"
  Assert-Phase157ValidatorEquals -Actual $NextTicket.trial_type -Expected "REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL" -Name "ticket_trial_type"
  Assert-Phase157ValidatorEquals -Actual $NextTicket.allowed_scope -Expected "sandbox_only" -Name "ticket_scope"
  Assert-Phase157ValidatorEquals -Actual $NextTicket.max_cycle_count -Expected 3 -Name "ticket_max_cycle"
  foreach ($skillId in $AllowedCandidateIds) {
    if (-not (@($NextTicket.allowed_candidates) -contains $skillId)) {
      throw "PHASE157_VALIDATE_TICKET_CANDIDATE_MISSING=$skillId"
    }
  }

  $NextCycleDecision = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $NextCycleDecisionPath
  Assert-Phase157ValidatorEquals -Actual $NextCycleDecision.next_action -Expected "RUN_REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL" -Name "next_action"
  Assert-Phase157ValidatorFalse -Actual $NextCycleDecision.codex_needed_for_next_step -Name "next_codex_needed"
  Assert-Phase157ValidatorEquals -Actual $NextCycleDecision.next_allowed_step -Expected $NextAllowedStep -Name "next_allowed_step"

  $Result = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath
  Assert-Phase157ProofFields -Artifact $Result -Name "result"
  Assert-Phase157ProofFields -Artifact $Proof -Name "proof"

  Assert-Phase157ValidatorEquals -Actual $Report.root_cause -Expected "PHASE157 entrypoint absent" -Name "report_root_cause"
  Assert-Phase157ValidatorEquals -Actual $Report.module_path -Expected $ModulePath -Name "report_module_path"
  Assert-Phase157ValidatorEquals -Actual $Report.validator_path -Expected $ValidatorPath -Name "report_validator_path"
  Assert-Phase157ValidatorEquals -Actual $Report.exact_run_command_expected -Expected ".\modules\invoke_builder_self_selected_gap_trial_review_001.ps1" -Name "report_run_command"
  Assert-Phase157ValidatorEquals -Actual $Report.exact_validator_command_expected -Expected ".\validators\validate_phase157_builder_self_selected_gap_trial_review_v1.ps1 -RepoRoot ." -Name "report_validator_command"
  foreach ($runtimePath in ($RuntimeOutputs + @($ResultPath, $ReportPath, $ProofPath))) {
    if (-not (@($Report.runtime_output_files_created) -contains $runtimePath)) {
      throw "PHASE157_VALIDATE_REPORT_RUNTIME_OUTPUT_MISSING=$runtimePath"
    }
  }

  $Queue = Read-Phase157ValidatorJson -RepoRoot $RepoRoot -Path $QueuePath
  Assert-Phase157ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  Write-Host "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_VALIDATE_RESULT=PASS"
  Write-Host "PHASE156_VERIFIED=True"
  Write-Host "PHASE156_TRIAL_REVIEWED=True"
  Write-Host "CYCLE_COUNT_REVIEWED=3"
  Write-Host "GAP_CHAIN_VERIFIED=True"
  Write-Host "SKILL_CANDIDATES_REVIEWED=True"
  Write-Host "SKILL_CANDIDATE_COUNT=3"
  Write-Host "CYCLE_006_REVIEW_STATUS=VALIDATED_SANDBOX_CANDIDATE"
  Write-Host "CYCLE_007_REVIEW_STATUS=VALIDATED_SANDBOX_CANDIDATE"
  Write-Host "CYCLE_008_REVIEW_STATUS=VALIDATED_SANDBOX_CANDIDATE"
  Write-Host "SANDBOX_CANDIDATE_DECISION=KEEP_AS_VALIDATED_SANDBOX_CANDIDATES"
  Write-Host "ROLLBACK_REQUIRED=False"
  Write-Host "QUARANTINE_REQUIRED=False"
  Write-Host "SKILL_CANDIDATES_PROMOTED=False"
  Write-Host "ACCEPTED_CAPABILITY_CREATED=False"
  Write-Host "REUSE_DECISION=ADMIT_PHASE156_CANDIDATES_FOR_BOUNDED_SANDBOX_REUSE"
  Write-Host "ALLOWED_SCOPE=sandbox_only"
  Write-Host "CODEX_NEEDED_FOR_NEXT_STEP=False"
  Write-Host "QUEUE_AFTER=NONE"
  Write-Host "NEXT_ALLOWED_STEP=PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1"
} catch {
  Write-Host "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE157_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
