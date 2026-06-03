param(
  [string]$RepoRoot = ".",
  [string]$RunId = "PHASE157_SELF_SELECTED_GAP_TRIAL_REVIEW_001"
)

$ErrorActionPreference = "Stop"

function Resolve-Phase157Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase157JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase157Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE157_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase157JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase157Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $json = ($Object | ConvertTo-Json -Depth $Depth) -replace "`r`n", "`n"
  if (-not $json.EndsWith("`n")) {
    $json += "`n"
  }

  [System.IO.File]::WriteAllText($fullPath, $json, [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase157Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE157_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase157True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE157_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase157False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE157_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase157FlagsFalse {
  param(
    [object]$Object,
    [string[]]$Flags,
    [string]$Prefix
  )

  foreach ($flag in $Flags) {
    Assert-Phase157False -Actual $Object.$flag -Name "${Prefix}:$flag"
  }
}

function Assert-Phase157SkillIndexContains {
  param(
    [object]$SkillIndex,
    [string]$SkillId
  )

  $skillIds = @($SkillIndex.skill_candidates | ForEach-Object { $_.skill_id })
  if (-not ($skillIds -contains $SkillId)) {
    throw "PHASE157_SKILL_INDEX_MISSING=$SkillId"
  }
}

function Assert-Phase157Phase156Proof {
  param([object]$Proof)

  Assert-Phase157Equals -Actual $Proof.status -Expected "PASS" -Name "phase156_status"
  Assert-Phase157Equals -Actual $Proof.step_id -Expected "PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1" -Name "phase156_step_id"
  Assert-Phase157Equals -Actual $Proof.run_id -Expected "PHASE156_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_001" -Name "phase156_run_id"
  Assert-Phase157Equals -Actual $Proof.next_allowed_step -Expected "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1" -Name "phase156_next_allowed_step"
  Assert-Phase157Equals -Actual $Proof.cycle_count -Expected 3 -Name "phase156_cycle_count"
  Assert-Phase157True -Actual $Proof.self_selected_gap_trial_proven -Name "phase156_trial_proven"
  Assert-Phase157True -Actual $Proof.all_cycles_validated -Name "phase156_all_cycles_validated"
  Assert-Phase157False -Actual $Proof.owner_selected_each_gap -Name "phase156_owner_selected"
  Assert-Phase157False -Actual $Proof.codex_selected_each_gap -Name "phase156_codex_selected"
  Assert-Phase157True -Actual $Proof.no_codex_needed_inside_cycles -Name "phase156_no_codex_inside"
  Assert-Phase157True -Actual $Proof.safe_stop -Name "phase156_safe_stop"
  Assert-Phase157Equals -Actual $Proof.queue_after -Expected "NONE" -Name "phase156_queue_after"
  Assert-Phase157FlagsFalse -Object $Proof -Flags @("accepted_state_mutated", "accepted_memory_mutated", "accepted_self_model_mutated", "external_fetch_performed", "dependency_install_performed", "executable_materials_used", "arbitrary_code_execution_used", "external_agents_created", "orchestrator_changed", "route_lock_changed", "current_runtime_changed", "capability_shelf_mutated", "body_pack_mutated") -Prefix "phase156_proof"
}

function New-Phase157CycleReview {
  param(
    [string]$RepoRoot,
    [string]$StepId,
    [string]$RunId,
    [string]$NextAllowedStep,
    [string]$ReviewPath,
    [string]$CycleId,
    [string]$ExpectedGap,
    [string]$ExpectedSkillId,
    [string]$ExpectedNextGap,
    [string]$GapSelectionPath,
    [string]$SkillCandidatePath,
    [string]$ValidationResultPath,
    [string]$NextSelectedGapPath
  )

  $GapSelection = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $GapSelectionPath
  $SkillCandidate = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $SkillCandidatePath
  $ValidationResult = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $ValidationResultPath
  $NextSelectedGap = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $NextSelectedGapPath

  Assert-Phase157Equals -Actual $GapSelection.selected_gap -Expected $ExpectedGap -Name "${CycleId}:selected_gap"
  Assert-Phase157Equals -Actual $GapSelection.selected_skill_id -Expected $ExpectedSkillId -Name "${CycleId}:selected_skill"
  Assert-Phase157Equals -Actual $SkillCandidate.skill_id -Expected $ExpectedSkillId -Name "${CycleId}:skill_id"
  Assert-Phase157False -Actual $SkillCandidate.accepted_capability -Name "${CycleId}:accepted_capability"
  Assert-Phase157Equals -Actual $ValidationResult.validation_status -Expected "PASS" -Name "${CycleId}:validation_status"
  Assert-Phase157True -Actual $ValidationResult.independently_calculated -Name "${CycleId}:independently_calculated"
  Assert-Phase157Equals -Actual $NextSelectedGap.next_selected_gap -Expected $ExpectedNextGap -Name "${CycleId}:next_selected_gap"

  $Review = [ordered]@{
    status = "PASS"
    review_id = "PHASE157_${CycleId}_REVIEW"
    step_id = $StepId
    run_id = $RunId
    cycle_id = $CycleId
    source_gap_selection_path = $GapSelectionPath
    source_skill_candidate_path = $SkillCandidatePath
    source_validation_result_path = $ValidationResultPath
    source_next_selected_gap_path = $NextSelectedGapPath
    selected_gap = $ExpectedGap
    skill_id = $ExpectedSkillId
    validation_status = "PASS"
    review_status = "VALIDATED_SANDBOX_CANDIDATE"
    promotion_status = "NOT_PROMOTED"
    rollback_required = $false
    quarantine_required = $false
    skill_candidates_promoted = $false
    accepted_capability_created = $false
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    next_selected_gap = $ExpectedNextGap
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $ReviewPath -Object $Review

  return [ordered]@{
    cycle_id = $CycleId
    path = $ReviewPath
    selected_gap = $ExpectedGap
    skill_id = $ExpectedSkillId
    validation_status = "PASS"
    review_status = "VALIDATED_SANDBOX_CANDIDATE"
    promotion_status = "NOT_PROMOTED"
    rollback_required = $false
    quarantine_required = $false
    next_selected_gap = $ExpectedNextGap
  }
}

function Invoke-BuilderSelfSelectedGapTrialReview001 {
  param(
    [string]$RepoRoot = ".",
    [string]$RunId = "PHASE157_SELF_SELECTED_GAP_TRIAL_REVIEW_001"
  )

  $RepoRoot = Resolve-Phase157Path -RepoRoot $RepoRoot -Path "."
  $Pushed = $false
  Push-Location $RepoRoot
  $Pushed = $true

  try {
    $StepId = "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1"
    $NextAllowedStep = "PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1"
    $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
    $ExpectedHead = "86d848b"
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
    $AllowedCandidateIds = @(
      "SELF_GAP_INVENTORY_SKILL_CANDIDATE_V1",
      "SELF_REPAIR_TASK_SPEC_WRITER_SKILL_CANDIDATE_V1",
      "SELF_PROOF_SUMMARY_SKILL_CANDIDATE_V1"
    )

    foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase157Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $Branch = (git branch --show-current).Trim()
    if ($Branch -eq "main") {
      throw "PHASE157_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase157Equals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
    $Head = (git rev-parse --short HEAD).Trim()
    Assert-Phase157Equals -Actual $Head -Expected $ExpectedHead -Name "current_head"

    $InputPaths = @(
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
      $QueuePath
    )
    foreach ($requiredPath in $InputPaths) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase157Path -RepoRoot $RepoRoot -Path $requiredPath))) {
        throw "PHASE157_MISSING_REQUIRED_INPUT=$requiredPath"
      }
    }

    $Phase156Proof = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $Phase156ProofPath
    $Phase156Result = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $Phase156ResultPath
    $Phase156Report = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $Phase156ReportPath
    $Phase156TrialResult = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $Phase156TrialResultPath
    $SkillIndex = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $Phase156SkillIndexPath
    $RuntimeStop = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $Phase156StopPath
    $BoundedPolicy = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $Phase155BoundedPolicyPath
    $SafetyPolicy = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $SafetyPolicyPath
    $BodyPack = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $BodyPackPath
    $BodyPolicy = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $BodyPolicyPath
    $SourcePolicy = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $SourcePolicyPath
    $TrustedSources = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $TrustedSourcesPath
    $Queue = Read-Phase157JsonRequired -RepoRoot $RepoRoot -Path $QueuePath

    Assert-Phase157Phase156Proof -Proof $Phase156Proof
    Assert-Phase157Phase156Proof -Proof $Phase156Result
    Assert-Phase157Phase156Proof -Proof $Phase156TrialResult
    Assert-Phase157Equals -Actual $Phase156Report.status -Expected "PASS" -Name "phase156_report_status"
    Assert-Phase157Equals -Actual $RuntimeStop.stop_reason -Expected "PHASE156_CYCLE_LIMIT_REACHED" -Name "phase156_stop_reason"
    Assert-Phase157True -Actual $RuntimeStop.safe_stop -Name "phase156_runtime_stop_safe"
    Assert-Phase157Equals -Actual $SkillIndex.skill_candidate_count -Expected 3 -Name "phase156_skill_candidate_count"
    foreach ($skillId in $AllowedCandidateIds) {
      Assert-Phase157SkillIndexContains -SkillIndex $SkillIndex -SkillId $skillId
    }

    Assert-Phase157Equals -Actual $BoundedPolicy.allowed_next_use -Expected "self_selected_gap_trial" -Name "phase155_policy_allowed_next_use"
    Assert-Phase157Equals -Actual $BoundedPolicy.max_cycle_count -Expected 3 -Name "phase155_policy_max_cycle_count"
    Assert-Phase157FlagsFalse -Object $BoundedPolicy -Flags @("accepted_state_mutation_allowed", "external_fetch_allowed", "install_allowed", "arbitrary_code_execution_allowed", "capability_shelf_mutation_allowed") -Prefix "phase155_bounded_policy"
    Assert-Phase157FlagsFalse -Object $SafetyPolicy -Flags @("external_fetch_allowed", "install_allowed", "executable_materials_allowed", "arbitrary_code_execution_allowed", "accepted_state_mutation_allowed", "accepted_memory_mutation_allowed", "accepted_self_model_mutation_allowed", "external_agents_allowed", "capability_shelf_mutation_allowed", "body_pack_mutation_allowed") -Prefix "safety_policy"
    Assert-Phase157Equals -Actual $BodyPack.body_pack_id -Expected "BUILDER_BODY_ORGAN_PACK_V1" -Name "body_pack_id"
    Assert-Phase157True -Actual $BodyPack.body_is_not_accepted_core -Name "body_not_accepted_core"
    Assert-Phase157FlagsFalse -Object $BodyPolicy -Flags @("accepted_state_mutation_allowed", "arbitrary_code_execution_allowed", "external_fetch_allowed", "install_allowed", "capability_shelf_mutation_allowed", "generated_agents_allowed", "applied_agents_allowed") -Prefix "body_policy"
    Assert-Phase157False -Actual $SourcePolicy.external_fetch_allowed -Name "source_policy_external_fetch_allowed"
    Assert-Phase157False -Actual $SourcePolicy.install_allowed -Name "source_policy_install_allowed"
    Assert-Phase157False -Actual $SourcePolicy.executable_use_allowed -Name "source_policy_executable_use_allowed"
    Assert-Phase157Equals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count"
    Assert-Phase157Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $ReviewBoot = [ordered]@{
      status = "PASS"
      review_boot_id = "PHASE157_REVIEW_BOOT"
      step_id = $StepId
      run_id = $RunId
      root_cause = "PHASE157 entrypoint absent"
      review_type = "SELF_SELECTED_GAP_TRIAL_REVIEW"
      source_phase156_proof_path = $Phase156ProofPath
      phase156_verified = $true
      phase156_trial_reviewed = $true
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $ReviewBootPath -Object $ReviewBoot

    $EvidenceRead = [ordered]@{
      status = "PASS"
      evidence_read_id = "PHASE157_PHASE156_EVIDENCE_READ"
      step_id = $StepId
      run_id = $RunId
      phase156_proof_path = $Phase156ProofPath
      phase156_result_path = $Phase156ResultPath
      phase156_report_path = $Phase156ReportPath
      phase156_trial_result_path = $Phase156TrialResultPath
      skill_index_path = $Phase156SkillIndexPath
      runtime_stop_decision_path = $Phase156StopPath
      phase156_verified = $true
      phase156_trial_reviewed = $true
      cycle_count_reviewed = 3
      skill_candidate_count = 3
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $EvidenceReadPath -Object $EvidenceRead

    $Cycle006Review = New-Phase157CycleReview -RepoRoot $RepoRoot -StepId $StepId -RunId $RunId -NextAllowedStep $NextAllowedStep -ReviewPath $Cycle006ReviewPath -CycleId "cycle_006" -ExpectedGap "SELF_GAP_INVENTORY_GAP" -ExpectedSkillId "SELF_GAP_INVENTORY_SKILL_CANDIDATE_V1" -ExpectedNextGap "SELF_REPAIR_TASK_SPEC_WRITER_GAP" -GapSelectionPath $Cycle006GapSelectionPath -SkillCandidatePath $Cycle006SkillCandidatePath -ValidationResultPath $Cycle006ValidationPath -NextSelectedGapPath $Cycle006NextPath
    $Cycle007Review = New-Phase157CycleReview -RepoRoot $RepoRoot -StepId $StepId -RunId $RunId -NextAllowedStep $NextAllowedStep -ReviewPath $Cycle007ReviewPath -CycleId "cycle_007" -ExpectedGap "SELF_REPAIR_TASK_SPEC_WRITER_GAP" -ExpectedSkillId "SELF_REPAIR_TASK_SPEC_WRITER_SKILL_CANDIDATE_V1" -ExpectedNextGap "SELF_PROOF_SUMMARY_GAP" -GapSelectionPath $Cycle007GapSelectionPath -SkillCandidatePath $Cycle007SkillCandidatePath -ValidationResultPath $Cycle007ValidationPath -NextSelectedGapPath $Cycle007NextPath
    $Cycle008Review = New-Phase157CycleReview -RepoRoot $RepoRoot -StepId $StepId -RunId $RunId -NextAllowedStep $NextAllowedStep -ReviewPath $Cycle008ReviewPath -CycleId "cycle_008" -ExpectedGap "SELF_PROOF_SUMMARY_GAP" -ExpectedSkillId "SELF_PROOF_SUMMARY_SKILL_CANDIDATE_V1" -ExpectedNextGap "STOP_PHASE156_CYCLE_LIMIT_REACHED" -GapSelectionPath $Cycle008GapSelectionPath -SkillCandidatePath $Cycle008SkillCandidatePath -ValidationResultPath $Cycle008ValidationPath -NextSelectedGapPath $Cycle008NextPath
    $CycleReviews = @($Cycle006Review, $Cycle007Review, $Cycle008Review)

    $GapChainReview = [ordered]@{
      status = "PASS"
      review_id = "PHASE157_GAP_CHAIN_REVIEW"
      step_id = $StepId
      run_id = $RunId
      gap_chain_verified = $true
      cycle_count_reviewed = 3
      chain = @(
        [ordered]@{ cycle_id = "cycle_006"; selected_gap = "SELF_GAP_INVENTORY_GAP"; next_selected_gap = "SELF_REPAIR_TASK_SPEC_WRITER_GAP" },
        [ordered]@{ cycle_id = "cycle_007"; selected_gap = "SELF_REPAIR_TASK_SPEC_WRITER_GAP"; next_selected_gap = "SELF_PROOF_SUMMARY_GAP"; derived_from = $Cycle006NextPath },
        [ordered]@{ cycle_id = "cycle_008"; selected_gap = "SELF_PROOF_SUMMARY_GAP"; next_selected_gap = "STOP_PHASE156_CYCLE_LIMIT_REACHED"; derived_from = $Cycle007NextPath }
      )
      terminal_next_selected_gap = "STOP_PHASE156_CYCLE_LIMIT_REACHED"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $GapChainReviewPath -Object $GapChainReview

    $SkillCandidateQualityReview = [ordered]@{
      status = "PASS"
      review_id = "PHASE157_SKILL_CANDIDATE_QUALITY_REVIEW"
      step_id = $StepId
      run_id = $RunId
      skill_candidates_reviewed = $true
      skill_candidate_count = 3
      reviewed_candidates = @($CycleReviews | ForEach-Object { [ordered]@{ cycle_id = $_.cycle_id; skill_id = $_.skill_id; review_status = $_.review_status; promotion_status = $_.promotion_status } })
      all_candidates_sandbox_only = $true
      accepted_capability_created = $false
      promotion_status = "NOT_PROMOTED"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $SkillQualityReviewPath -Object $SkillCandidateQualityReview

    $SkillValidationReview = [ordered]@{
      status = "PASS"
      review_id = "PHASE157_SKILL_VALIDATION_REVIEW"
      step_id = $StepId
      run_id = $RunId
      validation_review_status = "PASS"
      all_validations_passed = $true
      validation_count = 3
      reviewed_validations = @($CycleReviews | ForEach-Object { [ordered]@{ cycle_id = $_.cycle_id; skill_id = $_.skill_id; validation_status = $_.validation_status } })
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $SkillValidationReviewPath -Object $SkillValidationReview

    $SandboxCandidateDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE157_SANDBOX_CANDIDATE_DECISION"
      step_id = $StepId
      run_id = $RunId
      decision = "KEEP_AS_VALIDATED_SANDBOX_CANDIDATES"
      candidate_count = 3
      allowed_candidates = $AllowedCandidateIds
      rollback_required = $false
      quarantine_required = $false
      promotion_status = "NOT_PROMOTED"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $SandboxCandidateDecisionPath -Object $SandboxCandidateDecision

    $NonPromotionDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE157_NON_PROMOTION_DECISION"
      step_id = $StepId
      run_id = $RunId
      skill_candidates_promoted = $false
      accepted_capability_created = $false
      reason = "PHASE156 candidates are validated sandbox candidates only; accepted promotion requires later admission."
      promotion_status = "NOT_PROMOTED"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $NonPromotionDecisionPath -Object $NonPromotionDecision

    $BoundedReuseDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE157_BOUNDED_REUSE_DECISION"
      step_id = $StepId
      run_id = $RunId
      reuse_decision = "ADMIT_PHASE156_CANDIDATES_FOR_BOUNDED_SANDBOX_REUSE"
      allowed_scope = "sandbox_only"
      allowed_use = "REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL"
      max_cycles_per_run = 3
      accepted_state_mutation_allowed = $false
      external_fetch_allowed = $false
      install_allowed = $false
      arbitrary_code_execution_allowed = $false
      capability_shelf_mutation_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $BoundedReuseDecisionPath -Object $BoundedReuseDecision

    $SelfModelUpdateCandidate = [ordered]@{
      status = "PASS"
      candidate_id = "PHASE157_SELF_MODEL_UPDATE_CANDIDATE"
      step_id = $StepId
      run_id = $RunId
      update_type = "SELF_SELECTED_GAP_SKILLS_REVIEW_CANDIDATE"
      candidate_only = $true
      accepted_self_model_mutated = $false
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $SelfModelUpdateCandidatePath -Object $SelfModelUpdateCandidate

    $NextReuseTicket = [ordered]@{
      status = "PASS"
      ticket_id = "PHASE157_NEXT_REUSE_TICKET"
      step_id = $StepId
      run_id = $RunId
      ticket_status = "ISSUED_FOR_PHASE158_ONLY"
      trial_type = "REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL"
      allowed_scope = "sandbox_only"
      max_cycle_count = 3
      allowed_candidates = $AllowedCandidateIds
      accepted_state_mutation_allowed = $false
      external_fetch_allowed = $false
      install_allowed = $false
      arbitrary_code_execution_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $NextReuseTicketPath -Object $NextReuseTicket

    $NextCycleDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE157_NEXT_CYCLE_DECISION"
      step_id = $StepId
      run_id = $RunId
      next_action = "RUN_REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL"
      codex_needed_for_next_step = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $NextCycleDecisionPath -Object $NextCycleDecision

    $TrialReviewTrace = [ordered]@{
      status = "PASS"
      trace_id = "PHASE157_TRIAL_REVIEW_TRACE"
      step_id = $StepId
      run_id = $RunId
      sequence = @("READ_PHASE156_EVIDENCE", "VERIFY_GAP_CHAIN", "REVIEW_SKILL_CANDIDATES", "KEEP_SANDBOX_CANDIDATES", "REFUSE_PROMOTION", "ADMIT_BOUNDED_REUSE", "ISSUE_PHASE158_TICKET")
      phase156_verified = $true
      phase156_trial_reviewed = $true
      cycle_count_reviewed = 3
      gap_chain_verified = $true
      skill_candidates_reviewed = $true
      sandbox_candidate_decision = "KEEP_AS_VALIDATED_SANDBOX_CANDIDATES"
      reuse_decision = "ADMIT_PHASE156_CANDIDATES_FOR_BOUNDED_SANDBOX_REUSE"
      safe_stop = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $TrialReviewTracePath -Object $TrialReviewTrace

    $RuntimeCreatedOutputs = @(
      $ReviewBootPath,
      $EvidenceReadPath,
      $Cycle006ReviewPath,
      $Cycle007ReviewPath,
      $Cycle008ReviewPath,
      $GapChainReviewPath,
      $SkillQualityReviewPath,
      $SkillValidationReviewPath,
      $SandboxCandidateDecisionPath,
      $NonPromotionDecisionPath,
      $BoundedReuseDecisionPath,
      $SelfModelUpdateCandidatePath,
      $NextReuseTicketPath,
      $NextCycleDecisionPath,
      $TrialReviewTracePath
    )

    $Common = [ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase156_verified = $true
      phase156_trial_reviewed = $true
      cycle_count_reviewed = 3
      gap_chain_verified = $true
      skill_candidates_reviewed = $true
      skill_candidate_count = 3
      cycle_006_review_status = "VALIDATED_SANDBOX_CANDIDATE"
      cycle_007_review_status = "VALIDATED_SANDBOX_CANDIDATE"
      cycle_008_review_status = "VALIDATED_SANDBOX_CANDIDATE"
      sandbox_candidate_decision_created = $true
      sandbox_candidate_decision = "KEEP_AS_VALIDATED_SANDBOX_CANDIDATES"
      rollback_required = $false
      quarantine_required = $false
      non_promotion_decision_created = $true
      skill_candidates_promoted = $false
      accepted_capability_created = $false
      bounded_reuse_decision_created = $true
      reuse_decision = "ADMIT_PHASE156_CANDIDATES_FOR_BOUNDED_SANDBOX_REUSE"
      allowed_scope = "sandbox_only"
      allowed_use = "REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL"
      max_cycles_per_run = 3
      self_model_update_candidate_created = $true
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
      next_reuse_ticket_created = $true
      next_cycle_decision_created = $true
      codex_needed_for_next_step = $false
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      arbitrary_code_execution_used = $false
      external_agents_created = $false
      orchestrator_changed = $false
      route_lock_changed = $false
      current_runtime_changed = $false
      capability_shelf_mutated = $false
      body_pack_mutated = $false
      trusted_source_count = 0
      queue_after = "NONE"
      review_root = $ReviewRoot
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      next_allowed_step = $NextAllowedStep
    }

    $Result = [ordered]@{}
    foreach ($key in $Common.Keys) { $Result[$key] = $Common[$key] }
    $Result["result_id"] = "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_RESULT"
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result

    $Report = [ordered]@{
      status = "PASS"
      report_id = "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1_REPORT"
      step_id = $StepId
      run_id = $RunId
      root_cause = "PHASE157 entrypoint absent"
      files_changed = @($RouteAlignmentPath, $ModulePath, $ValidatorPath) + $RuntimeCreatedOutputs + @($ResultPath, $ReportPath, $ProofPath)
      module_path = $ModulePath
      validator_path = $ValidatorPath
      exact_run_command_expected = ".\modules\invoke_builder_self_selected_gap_trial_review_001.ps1"
      exact_validator_command_expected = ".\validators\validate_phase157_builder_self_selected_gap_trial_review_v1.ps1 -RepoRoot ."
      runtime_output_files_created = $RuntimeCreatedOutputs + @($ResultPath, $ReportPath, $ProofPath)
      risks = @(
        "PHASE157 keeps PHASE156 skills as sandbox candidates only; accepted promotion remains blocked until a later admission.",
        "PHASE157 does not run a new learning cycle, so PHASE158 must prove bounded reuse separately.",
        "The next ticket is scoped to REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL with a three-cycle cap."
      )
      cut_list = @(
        "No orchestrator change.",
        "No TASK_QUEUE mutation.",
        "No GENESIS_STATE mutation.",
        "No CAPABILITY_ROADMAP mutation.",
        "No packs registry mutation.",
        "No capability_shelf mutation.",
        "No living_learning_environment/body mutation.",
        "No living_learning_environment/self_growth_runtime mutation.",
        "No accepted PHASE142-PHASE156 artifact mutation.",
        "No generated_agents or applied_agents touch.",
        "No package manager or dependency file touch.",
        "No GitHub workflow touch.",
        "No route lock touch.",
        "No internet fetch.",
        "No dependency install.",
        "No external material execution.",
        "No arbitrary generated code execution.",
        "No accepted state, memory, or self-model mutation.",
        "No trusted source marking.",
        "No skill candidate promotion.",
        "No new self-growth cycle.",
        "No external agent production.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report

    $Proof = [ordered]@{}
    foreach ($key in $Common.Keys) { $Proof[$key] = $Common[$key] }
    $Proof["proof_id"] = $StepId
    $Proof["review_boot_path"] = $ReviewBootPath
    $Proof["phase156_evidence_read_path"] = $EvidenceReadPath
    $Proof["gap_chain_review_path"] = $GapChainReviewPath
    $Proof["sandbox_candidate_decision_path"] = $SandboxCandidateDecisionPath
    $Proof["bounded_reuse_decision_path"] = $BoundedReuseDecisionPath
    $Proof["next_reuse_ticket_path"] = $NextReuseTicketPath
    $Proof["next_cycle_decision_path"] = $NextCycleDecisionPath
    Write-Phase157JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject][ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase156_verified = $true
      phase156_trial_reviewed = $true
      cycle_count_reviewed = 3
      gap_chain_verified = $true
      skill_candidates_reviewed = $true
      skill_candidate_count = 3
      sandbox_candidate_decision = "KEEP_AS_VALIDATED_SANDBOX_CANDIDATES"
      rollback_required = $false
      quarantine_required = $false
      skill_candidates_promoted = $false
      accepted_capability_created = $false
      reuse_decision = "ADMIT_PHASE156_CANDIDATES_FOR_BOUNDED_SANDBOX_REUSE"
      allowed_scope = "sandbox_only"
      queue_after = "NONE"
      codex_needed_for_next_step = $false
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      next_allowed_step = $NextAllowedStep
    }
  } finally {
    if ($Pushed) {
      Pop-Location
    }
  }
}

if ($MyInvocation.InvocationName -ne ".") {
  Invoke-BuilderSelfSelectedGapTrialReview001 -RepoRoot $RepoRoot -RunId $RunId | ConvertTo-Json -Depth 20
}
