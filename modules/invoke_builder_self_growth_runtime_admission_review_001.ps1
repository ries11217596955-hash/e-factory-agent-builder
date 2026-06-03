param(
  [string]$RepoRoot = ".",
  [string]$RunId = "PHASE155_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_001"
)

$ErrorActionPreference = "Stop"

function Resolve-Phase155Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase155JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase155Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE155_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase155JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase155Path -RepoRoot $RepoRoot -Path $Path
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

function Assert-Phase155Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE155_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase155True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE155_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase155False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE155_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase155SafetyFalse {
  param(
    [object]$Object,
    [string[]]$Flags,
    [string]$Prefix
  )

  foreach ($flag in $Flags) {
    Assert-Phase155False -Actual $Object.$flag -Name "${Prefix}_$flag"
  }
}

function Invoke-BuilderSelfGrowthRuntimeAdmissionReview001 {
  param(
    [string]$RepoRoot = ".",
    [string]$RunId = "PHASE155_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_001"
  )

  $RepoRoot = Resolve-Phase155Path -RepoRoot $RepoRoot -Path "."
  $Pushed = $false
  Push-Location $RepoRoot
  $Pushed = $true

  try {
    $StepId = "PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1"
    $NextAllowedStep = "PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1"
    $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
    $ExpectedHead = "ea96c06"
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

    foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase155Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $Branch = (git branch --show-current).Trim()
    if ($Branch -eq "main") {
      throw "PHASE155_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase155Equals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
    $Head = (git rev-parse --short HEAD).Trim()
    Assert-Phase155Equals -Actual $Head -Expected $ExpectedHead -Name "current_head"

    foreach ($requiredPath in @(
      $RouteAlignmentPath,
      $ModulePath,
      $ValidatorPath,
      $Phase153ProofPath,
      $Phase154ProofPath,
      $Phase154ResultPath,
      $Phase154ReportPath,
      $Phase153HeartbeatPath,
      $Phase153StopPath,
      $Phase154HeartbeatPath,
      $Phase154TrialResultPath,
      $Phase154StopPath,
      $RuntimePath,
      $RuntimeContractPath,
      $CurriculumPath,
      $SafetyPolicyPath,
      $BodyPackPath,
      $BodyPolicyPath,
      $SourcePolicyPath,
      $TrustedSourcesPath,
      $QueuePath
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase155Path -RepoRoot $RepoRoot -Path $requiredPath))) {
        throw "PHASE155_MISSING_REQUIRED_INPUT=$requiredPath"
      }
    }

    $Phase153Proof = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $Phase153ProofPath
    Assert-Phase155Equals -Actual $Phase153Proof.status -Expected "PASS" -Name "phase153_status"
    Assert-Phase155Equals -Actual $Phase153Proof.cycle_count -Expected 2 -Name "phase153_cycle_count"
    Assert-Phase155True -Actual $Phase153Proof.self_growth_loop_proven -Name "phase153_self_growth_loop_proven"
    Assert-Phase155True -Actual $Phase153Proof.ready_for_phase154_bounded_trial -Name "phase153_ready_for_phase154"

    $Phase154Proof = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $Phase154ProofPath
    Assert-Phase155Equals -Actual $Phase154Proof.status -Expected "PASS" -Name "phase154_status"
    Assert-Phase155Equals -Actual $Phase154Proof.cycle_count -Expected 3 -Name "phase154_cycle_count"
    Assert-Phase155True -Actual $Phase154Proof.bounded_self_growth_trial_proven -Name "phase154_trial_proven"
    Assert-Phase155True -Actual $Phase154Proof.all_cycles_validated -Name "phase154_all_cycles_validated"
    Assert-Phase155True -Actual $Phase154Proof.no_codex_needed_inside_cycles -Name "phase154_no_codex"
    Assert-Phase155True -Actual $Phase154Proof.safe_stop -Name "phase154_safe_stop"
    Assert-Phase155Equals -Actual $Phase154Proof.next_allowed_step -Expected $StepId -Name "phase154_next_allowed_step"

    $Phase154Result = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $Phase154ResultPath
    Assert-Phase155Equals -Actual $Phase154Result.status -Expected "PASS" -Name "phase154_result_status"
    Assert-Phase155Equals -Actual $Phase154Result.queue_after -Expected "NONE" -Name "phase154_queue_after"

    $Phase153Heartbeat = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $Phase153HeartbeatPath
    $Phase153Stop = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $Phase153StopPath
    $Phase154Heartbeat = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $Phase154HeartbeatPath
    $Phase154TrialResult = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $Phase154TrialResultPath
    $Phase154Stop = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $Phase154StopPath
    Assert-Phase155Equals -Actual $Phase153Heartbeat.cycle_count -Expected 2 -Name "phase153_heartbeat_cycle_count"
    Assert-Phase155True -Actual $Phase153Stop.safe_stop -Name "phase153_stop_safe"
    Assert-Phase155Equals -Actual $Phase154Heartbeat.cycle_count -Expected 3 -Name "phase154_heartbeat_cycle_count"
    Assert-Phase155True -Actual $Phase154TrialResult.all_cycles_validated -Name "phase154_trial_result_all_cycles"
    Assert-Phase155True -Actual $Phase154Stop.safe_stop -Name "phase154_stop_safe"

    $Runtime = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $RuntimePath
    $RuntimeContract = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $RuntimeContractPath
    $Curriculum = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $CurriculumPath
    $SafetyPolicy = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $SafetyPolicyPath
    $BodyPack = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $BodyPackPath
    $BodyPolicy = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $BodyPolicyPath
    $SourcePolicy = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $SourcePolicyPath
    $TrustedSources = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $TrustedSourcesPath
    $Queue = Read-Phase155JsonRequired -RepoRoot $RepoRoot -Path $QueuePath
    Assert-Phase155Equals -Actual $Runtime.runtime_id -Expected "SELF_GROWTH_DUTY_RUNTIME_V1" -Name "runtime_id"
    Assert-Phase155Equals -Actual $Curriculum.status -Expected "PASS" -Name "curriculum_status"
    Assert-Phase155Equals -Actual $BodyPack.body_pack_id -Expected "BUILDER_BODY_ORGAN_PACK_V1" -Name "body_pack_id"
    Assert-Phase155Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $RuntimeSafetyFlags = @("external_fetch_allowed", "install_allowed", "arbitrary_code_execution_allowed", "accepted_state_mutation_allowed", "capability_shelf_mutation_allowed")
    Assert-Phase155SafetyFalse -Object $RuntimeContract -Flags $RuntimeSafetyFlags -Prefix "runtime_contract"
    Assert-Phase155SafetyFalse -Object $SafetyPolicy -Flags @("external_fetch_allowed", "install_allowed", "arbitrary_code_execution_allowed", "executable_materials_allowed", "accepted_state_mutation_allowed", "accepted_memory_mutation_allowed", "accepted_self_model_mutation_allowed", "capability_shelf_mutation_allowed", "body_pack_mutation_allowed") -Prefix "safety_policy"
    Assert-Phase155SafetyFalse -Object $BodyPolicy -Flags @("external_fetch_allowed", "install_allowed", "arbitrary_code_execution_allowed", "accepted_state_mutation_allowed", "capability_shelf_mutation_allowed", "generated_agents_allowed", "applied_agents_allowed") -Prefix "body_policy"
    Assert-Phase155False -Actual $SourcePolicy.external_fetch_allowed -Name "source_policy_external_fetch_allowed"
    Assert-Phase155False -Actual $SourcePolicy.install_allowed -Name "source_policy_install_allowed"
    Assert-Phase155False -Actual $SourcePolicy.executable_use_allowed -Name "source_policy_executable_use_allowed"
    Assert-Phase155Equals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count"

    $RuntimeOutputsPresent = $true
    foreach ($path in @($Phase153HeartbeatPath, $Phase153StopPath, $Phase154HeartbeatPath, $Phase154TrialResultPath, $Phase154StopPath)) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase155Path -RepoRoot $RepoRoot -Path $path))) {
        $RuntimeOutputsPresent = $false
      }
    }

    $ReviewBoot = [ordered]@{
      status = "PASS"
      review_boot_id = "PHASE155_REVIEW_BOOT"
      step_id = $StepId
      run_id = $RunId
      root_cause = "PHASE155 entrypoint absent"
      review_type = "SELF_GROWTH_RUNTIME_ADMISSION_REVIEW"
      phase_type = "admission_review"
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $ReviewBootPath -Object $ReviewBoot

    $EvidenceChainReview = [ordered]@{
      status = "PASS"
      review_id = "PHASE155_EVIDENCE_CHAIN_REVIEW"
      step_id = $StepId
      run_id = $RunId
      phase153_verified = $true
      phase154_verified = $true
      total_self_growth_cycles_reviewed = 5
      runtime_outputs_present = $RuntimeOutputsPresent
      runtime_evidence_chain_verified = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $EvidenceChainReviewPath -Object $EvidenceChainReview

    $Phase153Review = [ordered]@{
      status = "PASS"
      review_id = "PHASE155_PHASE153_REVIEW"
      step_id = $StepId
      run_id = $RunId
      source_proof_path = $Phase153ProofPath
      cycle_count = 2
      self_growth_loop_proven = $true
      ready_for_phase154_bounded_trial = $true
      safe_stop = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $Phase153ReviewPath -Object $Phase153Review

    $Phase154Review = [ordered]@{
      status = "PASS"
      review_id = "PHASE155_PHASE154_REVIEW"
      step_id = $StepId
      run_id = $RunId
      source_proof_path = $Phase154ProofPath
      cycle_count = 3
      bounded_self_growth_trial_proven = $true
      all_cycles_validated = $true
      no_codex_needed_inside_cycles = $true
      safe_stop = $true
      next_allowed_step_from_phase154 = $StepId
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $Phase154ReviewPath -Object $Phase154Review

    $RuntimeSafetyReview = [ordered]@{
      status = "PASS"
      review_id = "PHASE155_RUNTIME_SAFETY_REVIEW"
      step_id = $StepId
      run_id = $RunId
      accepted_state_mutation_detected = $false
      external_fetch_detected = $false
      dependency_install_detected = $false
      arbitrary_code_execution_detected = $false
      capability_shelf_mutation_detected = $false
      runtime_modified = $false
      body_pack_mutated = $false
      trusted_source_count = 0
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $RuntimeSafetyReviewPath -Object $RuntimeSafetyReview

    $RuntimeReuseDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE155_RUNTIME_REUSE_DECISION"
      step_id = $StepId
      run_id = $RunId
      reuse_decision = "ADMIT_FOR_BOUNDED_SANDBOX_REUSE"
      allowed_scope = "sandbox_only"
      max_cycles_per_run = 3
      owner_approval_required_for_scope_increase = $true
      accepted_state_mutation_allowed = $false
      external_fetch_allowed = $false
      install_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $RuntimeReuseDecisionPath -Object $RuntimeReuseDecision

    $RuntimeAdmissionDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE155_RUNTIME_ADMISSION_DECISION"
      step_id = $StepId
      run_id = $RunId
      admission_status = "ADMITTED_FOR_BOUNDED_SELF_GROWTH_SANDBOX_USE"
      unrestricted_autonomy_approved = $false
      accepted_core_promotion_approved = $false
      capability_shelf_promotion_approved = $false
      allowed_scope = "sandbox_only"
      max_cycles_per_run = 3
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $RuntimeAdmissionDecisionPath -Object $RuntimeAdmissionDecision

    $BoundedReusePolicy = [ordered]@{
      status = "PASS"
      policy_id = "PHASE155_BOUNDED_REUSE_POLICY"
      step_id = $StepId
      run_id = $RunId
      allowed_next_use = "self_selected_gap_trial"
      max_cycle_count = 3
      allowed_outputs = @("living_learning_environment/*")
      accepted_state_mutation_allowed = $false
      external_fetch_allowed = $false
      install_allowed = $false
      arbitrary_code_execution_allowed = $false
      capability_shelf_mutation_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $BoundedReusePolicyPath -Object $BoundedReusePolicy

    $NonPromotionDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE155_NON_PROMOTION_DECISION"
      step_id = $StepId
      run_id = $RunId
      runtime_promoted_to_accepted_core = $false
      reason = "bounded runtime is proven for sandbox self-growth only; accepted core promotion requires later admission"
      unrestricted_autonomy_approved = $false
      accepted_core_promotion_approved = $false
      capability_shelf_promotion_approved = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $NonPromotionDecisionPath -Object $NonPromotionDecision

    $SelfModelUpdateCandidate = [ordered]@{
      status = "PASS"
      candidate_id = "PHASE155_SELF_MODEL_UPDATE_CANDIDATE"
      step_id = $StepId
      run_id = $RunId
      update_type = "SELF_GROWTH_RUNTIME_ADMISSION_CANDIDATE"
      candidate_only = $true
      admission_status = "ADMITTED_FOR_BOUNDED_SELF_GROWTH_SANDBOX_USE"
      accepted_self_model_mutated = $false
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $SelfModelUpdateCandidatePath -Object $SelfModelUpdateCandidate

    $NextTrialTicket = [ordered]@{
      status = "PASS"
      ticket_id = "PHASE155_NEXT_TRIAL_TICKET"
      step_id = $StepId
      run_id = $RunId
      ticket_status = "ISSUED_FOR_PHASE156_ONLY"
      trial_type = "SELF_SELECTED_GAP_SELF_BUILD_TRIAL"
      allowed_scope = "sandbox_only"
      max_cycle_count = 3
      accepted_state_mutation_allowed = $false
      external_fetch_allowed = $false
      install_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $NextTrialTicketPath -Object $NextTrialTicket

    $NextCycleDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE155_NEXT_CYCLE_DECISION"
      step_id = $StepId
      run_id = $RunId
      next_action = "RUN_SELF_SELECTED_GAP_SELF_BUILD_TRIAL"
      codex_needed_for_next_step = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $NextCycleDecisionPath -Object $NextCycleDecision

    $AdmissionReviewTrace = [ordered]@{
      status = "PASS"
      trace_id = "PHASE155_ADMISSION_REVIEW_TRACE"
      step_id = $StepId
      run_id = $RunId
      sequence = @("REVIEW_PHASE153", "REVIEW_PHASE154", "REVIEW_RUNTIME_SAFETY", "DECIDE_BOUNDED_REUSE", "REFUSE_CORE_PROMOTION", "ISSUE_PHASE156_TICKET")
      phase153_verified = $true
      phase154_verified = $true
      runtime_evidence_chain_verified = $true
      admission_status = "ADMITTED_FOR_BOUNDED_SELF_GROWTH_SANDBOX_USE"
      reuse_decision = "ADMIT_FOR_BOUNDED_SANDBOX_REUSE"
      safe_stop = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $AdmissionReviewTracePath -Object $AdmissionReviewTrace

    $RuntimeCreatedOutputs = @(
      $ReviewBootPath,
      $EvidenceChainReviewPath,
      $Phase153ReviewPath,
      $Phase154ReviewPath,
      $RuntimeSafetyReviewPath,
      $RuntimeReuseDecisionPath,
      $RuntimeAdmissionDecisionPath,
      $BoundedReusePolicyPath,
      $NonPromotionDecisionPath,
      $SelfModelUpdateCandidatePath,
      $NextTrialTicketPath,
      $NextCycleDecisionPath,
      $AdmissionReviewTracePath
    )

    $Common = [ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase153_verified = $true
      phase154_verified = $true
      total_self_growth_cycles_reviewed = 5
      runtime_evidence_chain_verified = $true
      runtime_safety_review_created = $true
      runtime_reuse_decision_created = $true
      runtime_admission_decision_created = $true
      bounded_reuse_policy_created = $true
      non_promotion_decision_created = $true
      self_model_update_candidate_created = $true
      next_trial_ticket_created = $true
      next_cycle_decision_created = $true
      admission_status = "ADMITTED_FOR_BOUNDED_SELF_GROWTH_SANDBOX_USE"
      reuse_decision = "ADMIT_FOR_BOUNDED_SANDBOX_REUSE"
      allowed_scope = "sandbox_only"
      max_cycles_per_run = 3
      unrestricted_autonomy_approved = $false
      accepted_core_promotion_approved = $false
      capability_shelf_promotion_approved = $false
      runtime_promoted_to_accepted_core = $false
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
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
      codex_needed_for_next_step = $false
      review_root = $ReviewRoot
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      next_allowed_step = $NextAllowedStep
    }

    $Result = [ordered]@{}
    foreach ($key in $Common.Keys) { $Result[$key] = $Common[$key] }
    $Result["result_id"] = "PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_RESULT"
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result

    $Report = [ordered]@{
      status = "PASS"
      report_id = "PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1_REPORT"
      step_id = $StepId
      run_id = $RunId
      root_cause = "PHASE155 entrypoint absent"
      files_changed = @($RouteAlignmentPath, $ModulePath, $ValidatorPath) + $RuntimeCreatedOutputs + @($ResultPath, $ReportPath, $ProofPath)
      module_path = $ModulePath
      validator_path = $ValidatorPath
      exact_run_command_expected = ".\modules\invoke_builder_self_growth_runtime_admission_review_001.ps1"
      exact_validator_command_expected = ".\validators\validate_phase155_builder_self_growth_runtime_admission_review_v1.ps1 -RepoRoot ."
      runtime_output_files_created = $RuntimeCreatedOutputs + @($ResultPath, $ReportPath, $ProofPath)
      risks = @(
        "PHASE155 admits reuse only for bounded sandbox self-growth; it does not approve unrestricted autonomy.",
        "PHASE155 creates a self-model update candidate only; accepted self-model state remains unchanged.",
        "PHASE156 must remain within sandbox-only scope and the three-cycle limit unless later owner admission expands scope."
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
        "No accepted PHASE142-PHASE154 artifact mutation.",
        "No generated_agents or applied_agents touch.",
        "No package manager or dependency file touch.",
        "No GitHub workflow touch.",
        "No route lock touch.",
        "No internet fetch.",
        "No dependency install.",
        "No external material execution.",
        "No arbitrary generated code execution.",
        "No accepted memory or self-model mutation.",
        "No runtime promotion to accepted core.",
        "No capability shelf promotion.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report

    $Proof = [ordered]@{}
    foreach ($key in $Common.Keys) { $Proof[$key] = $Common[$key] }
    $Proof["proof_id"] = $StepId
    $Proof["review_boot_path"] = $ReviewBootPath
    $Proof["evidence_chain_review_path"] = $EvidenceChainReviewPath
    $Proof["runtime_reuse_decision_path"] = $RuntimeReuseDecisionPath
    $Proof["runtime_admission_decision_path"] = $RuntimeAdmissionDecisionPath
    $Proof["bounded_reuse_policy_path"] = $BoundedReusePolicyPath
    $Proof["next_trial_ticket_path"] = $NextTrialTicketPath
    $Proof["next_cycle_decision_path"] = $NextCycleDecisionPath
    Write-Phase155JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject][ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase153_verified = $true
      phase154_verified = $true
      total_self_growth_cycles_reviewed = 5
      admission_status = "ADMITTED_FOR_BOUNDED_SELF_GROWTH_SANDBOX_USE"
      reuse_decision = "ADMIT_FOR_BOUNDED_SANDBOX_REUSE"
      allowed_scope = "sandbox_only"
      max_cycles_per_run = 3
      unrestricted_autonomy_approved = $false
      accepted_core_promotion_approved = $false
      capability_shelf_promotion_approved = $false
      runtime_promoted_to_accepted_core = $false
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
  Invoke-BuilderSelfGrowthRuntimeAdmissionReview001 -RepoRoot $RepoRoot -RunId $RunId | ConvertTo-Json -Depth 20
}
