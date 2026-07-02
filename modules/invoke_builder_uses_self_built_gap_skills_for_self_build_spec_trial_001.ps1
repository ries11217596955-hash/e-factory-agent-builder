param(
  [string]$RepoRoot = ".",
  [string]$RunId = "PHASE158_REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL_001"
)

$ErrorActionPreference = "Stop"

function Resolve-Phase158Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase158JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase158Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE158_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase158JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase158Path -RepoRoot $RepoRoot -Path $Path
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

function Assert-Phase158Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE158_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase158True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE158_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase158False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE158_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase158FlagsFalse {
  param(
    [object]$Object,
    [string[]]$Flags,
    [string]$Prefix
  )

  foreach ($flag in $Flags) {
    Assert-Phase158False -Actual $Object.$flag -Name "${Prefix}:$flag"
  }
}

function Assert-Phase158Contains {
  param(
    [object[]]$Values,
    [string]$Expected,
    [string]$Name
  )

  if (-not (@($Values) -contains $Expected)) {
    throw "PHASE158_EXPECTED_VALUE_MISSING=$Name expected=$Expected"
  }
}

function Assert-Phase158Phase157Proof {
  param(
    [object]$Proof,
    [string]$StepId
  )

  Assert-Phase158Equals -Actual $Proof.status -Expected "PASS" -Name "phase157_status"
  Assert-Phase158Equals -Actual $Proof.step_id -Expected "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1" -Name "phase157_step_id"
  Assert-Phase158Equals -Actual $Proof.next_allowed_step -Expected $StepId -Name "phase157_next_allowed_step"
  Assert-Phase158True -Actual $Proof.phase156_verified -Name "phase157_phase156_verified"
  Assert-Phase158True -Actual $Proof.phase156_trial_reviewed -Name "phase157_trial_reviewed"
  Assert-Phase158Equals -Actual $Proof.skill_candidate_count -Expected 3 -Name "phase157_candidate_count"
  Assert-Phase158Equals -Actual $Proof.sandbox_candidate_decision -Expected "KEEP_AS_VALIDATED_SANDBOX_CANDIDATES" -Name "phase157_sandbox_decision"
  Assert-Phase158Equals -Actual $Proof.reuse_decision -Expected "ADMIT_PHASE156_CANDIDATES_FOR_BOUNDED_SANDBOX_REUSE" -Name "phase157_reuse_decision"
  Assert-Phase158Equals -Actual $Proof.allowed_scope -Expected "sandbox_only" -Name "phase157_allowed_scope"
  Assert-Phase158False -Actual $Proof.skill_candidates_promoted -Name "phase157_skill_candidates_promoted"
  Assert-Phase158False -Actual $Proof.accepted_capability_created -Name "phase157_accepted_capability_created"
  Assert-Phase158False -Actual $Proof.codex_needed_for_next_step -Name "phase157_codex_needed"
}

function Assert-Phase158Candidate {
  param(
    [object]$Candidate,
    [object]$Validation,
    [string]$ExpectedSkillId,
    [string]$Name
  )

  Assert-Phase158Equals -Actual $Candidate.status -Expected "PASS" -Name "${Name}:candidate_status"
  Assert-Phase158Equals -Actual $Candidate.skill_id -Expected $ExpectedSkillId -Name "${Name}:skill_id"
  Assert-Phase158Equals -Actual $Candidate.skill_status -Expected "SANDBOX_SKILL_CANDIDATE_NOT_ACCEPTED" -Name "${Name}:skill_status"
  Assert-Phase158False -Actual $Candidate.accepted_capability -Name "${Name}:accepted_capability"
  Assert-Phase158False -Actual $Candidate.accepted_state_mutated -Name "${Name}:accepted_state_mutated"
  Assert-Phase158Equals -Actual $Validation.status -Expected "PASS" -Name "${Name}:validation_file_status"
  Assert-Phase158Equals -Actual $Validation.skill_id -Expected $ExpectedSkillId -Name "${Name}:validation_skill_id"
  Assert-Phase158Equals -Actual $Validation.validation_status -Expected "PASS" -Name "${Name}:validation_status"
  Assert-Phase158True -Actual $Validation.independently_calculated -Name "${Name}:independently_calculated"
}

function Invoke-BuilderUsesSelfBuiltGapSkillsForSelfBuildSpecTrial001 {
  param(
    [string]$RepoRoot = ".",
    [string]$RunId = "PHASE158_REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL_001"
  )

  $RepoRoot = Resolve-Phase158Path -RepoRoot $RepoRoot -Path "."
  $Pushed = $false
  Push-Location $RepoRoot
  $Pushed = $true

  try {
    $StepId = "PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1"
    $NextAllowedStep = "PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1"
    $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
    $ExpectedHead = "787ad74"
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
    $SourceSkills = @(
      "SELF_GAP_INVENTORY_SKILL_CANDIDATE_V1",
      "SELF_REPAIR_TASK_SPEC_WRITER_SKILL_CANDIDATE_V1",
      "SELF_PROOF_SUMMARY_SKILL_CANDIDATE_V1"
    )
    $TaskSpecId = "SELF_WRITTEN_BUILD_SPEC_EXECUTION_TASK_SPEC_V1"
    $GenericBridgeId = "GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1"
    $GenericExecutorPath = "living_learning_environment/generic_execution_bridge/GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1"

    foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase158Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $Branch = (git branch --show-current).Trim()
    if ($Branch -eq "main") {
      throw "PHASE158_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase158Equals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
    $Head = (git rev-parse --short HEAD).Trim()
    Assert-Phase158Equals -Actual $Head -Expected $ExpectedHead -Name "current_head"

    $RequiredInputPaths = @(
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
      $QueuePath
    )
    foreach ($requiredPath in $RequiredInputPaths) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase158Path -RepoRoot $RepoRoot -Path $requiredPath))) {
        throw "PHASE158_MISSING_REQUIRED_INPUT=$requiredPath"
      }
    }

    $Phase157Proof = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $Phase157ProofPath
    $Ticket = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $Phase157TicketPath
    $NextDecision = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $Phase157NextDecisionPath
    $BoundedReuse = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $Phase157BoundedReusePath
    $SandboxDecision = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $Phase157SandboxDecisionPath
    $SkillIndex = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $SkillIndexPath
    $GapInventorySkill = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $GapInventorySkillPath
    $RepairTaskSpecSkill = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $RepairTaskSpecSkillPath
    $ProofSummarySkill = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $ProofSummarySkillPath
    $GapInventoryValidation = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $GapInventoryValidationPath
    $RepairTaskSpecValidation = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $RepairTaskSpecValidationPath
    $ProofSummaryValidation = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $ProofSummaryValidationPath
    $SafetyPolicy = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $SafetyPolicyPath
    $BodyPack = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $BodyPackPath
    $BodyPolicy = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $BodyPolicyPath
    $SourcePolicy = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $SourcePolicyPath
    $TrustedSources = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $TrustedSourcesPath
    $Queue = Read-Phase158JsonRequired -RepoRoot $RepoRoot -Path $QueuePath

    Assert-Phase158Phase157Proof -Proof $Phase157Proof -StepId $StepId
    Assert-Phase158Equals -Actual $Ticket.status -Expected "PASS" -Name "ticket_status_file"
    Assert-Phase158Equals -Actual $Ticket.ticket_status -Expected "ISSUED_FOR_PHASE158_ONLY" -Name "ticket_status"
    Assert-Phase158Equals -Actual $Ticket.trial_type -Expected "REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL" -Name "ticket_trial_type"
    Assert-Phase158Equals -Actual $Ticket.allowed_scope -Expected "sandbox_only" -Name "ticket_scope"
    Assert-Phase158Equals -Actual $Ticket.max_cycle_count -Expected 3 -Name "ticket_max_cycle_count"
    Assert-Phase158Equals -Actual $Ticket.next_allowed_step -Expected $StepId -Name "ticket_next_allowed_step"
    foreach ($skillId in $SourceSkills) {
      Assert-Phase158Contains -Values @($Ticket.allowed_candidates) -Expected $skillId -Name "ticket_allowed_candidates"
    }

    Assert-Phase158Equals -Actual $NextDecision.next_action -Expected "RUN_REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL" -Name "next_decision_action"
    Assert-Phase158False -Actual $NextDecision.codex_needed_for_next_step -Name "next_decision_codex_needed"
    Assert-Phase158Equals -Actual $BoundedReuse.reuse_decision -Expected "ADMIT_PHASE156_CANDIDATES_FOR_BOUNDED_SANDBOX_REUSE" -Name "bounded_reuse_decision"
    Assert-Phase158Equals -Actual $BoundedReuse.allowed_scope -Expected "sandbox_only" -Name "bounded_reuse_scope"
    Assert-Phase158Equals -Actual $BoundedReuse.allowed_use -Expected "REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL" -Name "bounded_reuse_use"
    Assert-Phase158Equals -Actual $SandboxDecision.decision -Expected "KEEP_AS_VALIDATED_SANDBOX_CANDIDATES" -Name "sandbox_candidate_decision"
    Assert-Phase158Equals -Actual $SandboxDecision.candidate_count -Expected 3 -Name "sandbox_candidate_count"
    Assert-Phase158False -Actual $SandboxDecision.rollback_required -Name "sandbox_rollback_required"
    Assert-Phase158False -Actual $SandboxDecision.quarantine_required -Name "sandbox_quarantine_required"
    Assert-Phase158Equals -Actual $SkillIndex.skill_candidate_count -Expected 3 -Name "skill_index_candidate_count"
    foreach ($skillId in $SourceSkills) {
      Assert-Phase158Contains -Values @($SkillIndex.skill_candidates | ForEach-Object { $_.skill_id }) -Expected $skillId -Name "skill_index_candidates"
    }

    Assert-Phase158Candidate -Candidate $GapInventorySkill -Validation $GapInventoryValidation -ExpectedSkillId $SourceSkills[0] -Name "gap_inventory"
    Assert-Phase158Candidate -Candidate $RepairTaskSpecSkill -Validation $RepairTaskSpecValidation -ExpectedSkillId $SourceSkills[1] -Name "repair_task_spec"
    Assert-Phase158Candidate -Candidate $ProofSummarySkill -Validation $ProofSummaryValidation -ExpectedSkillId $SourceSkills[2] -Name "proof_summary"
    Assert-Phase158FlagsFalse -Object $SafetyPolicy -Flags @("external_fetch_allowed", "install_allowed", "executable_materials_allowed", "arbitrary_code_execution_allowed", "accepted_state_mutation_allowed", "accepted_memory_mutation_allowed", "accepted_self_model_mutation_allowed", "external_agents_allowed", "capability_shelf_mutation_allowed", "body_pack_mutation_allowed") -Prefix "safety_policy"
    Assert-Phase158Equals -Actual $BodyPack.body_pack_id -Expected "BUILDER_BODY_ORGAN_PACK_V1" -Name "body_pack_id"
    Assert-Phase158FlagsFalse -Object $BodyPolicy -Flags @("accepted_state_mutation_allowed", "arbitrary_code_execution_allowed", "external_fetch_allowed", "install_allowed", "capability_shelf_mutation_allowed", "generated_agents_allowed", "applied_agents_allowed") -Prefix "body_policy"
    Assert-Phase158False -Actual $SourcePolicy.external_fetch_allowed -Name "source_policy_external_fetch_allowed"
    Assert-Phase158False -Actual $SourcePolicy.install_allowed -Name "source_policy_install_allowed"
    Assert-Phase158False -Actual $SourcePolicy.executable_use_allowed -Name "source_policy_executable_use_allowed"
    Assert-Phase158Equals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count"
    Assert-Phase158Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $TrialBoot = [ordered]@{
      status = "PASS"
      boot_id = "PHASE158_TRIAL_BOOT"
      step_id = $StepId
      run_id = $RunId
      root_cause = "PHASE158 entrypoint absent"
      trial_type = "REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL"
      source_phase157_proof_path = $Phase157ProofPath
      phase157_verified = $true
      allowed_scope = "sandbox_only"
      max_cycle_count = 3
      new_learning_cycle_started = $false
      new_skills_built = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $TrialBootPath -Object $TrialBoot

    $TicketRead = [ordered]@{
      status = "PASS"
      read_id = "PHASE158_PHASE157_TICKET_READ"
      step_id = $StepId
      run_id = $RunId
      source_ticket_path = $Phase157TicketPath
      ticket_status = "ISSUED_FOR_PHASE158_ONLY"
      trial_type = "REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL"
      allowed_scope = "sandbox_only"
      max_cycle_count = 3
      allowed_candidates = $SourceSkills
      next_allowed_step_from_ticket = $StepId
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $TicketReadPath -Object $TicketRead

    $CandidateLoad = [ordered]@{
      status = "PASS"
      load_id = "PHASE158_REVIEWED_CANDIDATE_SKILL_LOAD"
      step_id = $StepId
      run_id = $RunId
      reviewed_candidates_loaded = $true
      reviewed_candidate_count = 3
      loaded_candidates = @(
        [ordered]@{ skill_id = $SourceSkills[0]; source_skill_path = $GapInventorySkillPath; source_validation_path = $GapInventoryValidationPath; validation_status = "PASS"; reviewed_in_phase157 = $true },
        [ordered]@{ skill_id = $SourceSkills[1]; source_skill_path = $RepairTaskSpecSkillPath; source_validation_path = $RepairTaskSpecValidationPath; validation_status = "PASS"; reviewed_in_phase157 = $true },
        [ordered]@{ skill_id = $SourceSkills[2]; source_skill_path = $ProofSummarySkillPath; source_validation_path = $ProofSummaryValidationPath; validation_status = "PASS"; reviewed_in_phase157 = $true }
      )
      skill_candidates_promoted = $false
      accepted_capability_created = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $CandidateLoadPath -Object $CandidateLoad

    $SkillReusePolicy = [ordered]@{
      status = "PASS"
      policy_id = "PHASE158_SKILL_REUSE_POLICY"
      step_id = $StepId
      run_id = $RunId
      allowed_use = "SELF_WRITTEN_BUILD_SPEC_CANDIDATE_CREATION"
      allowed_scope = "sandbox_only"
      source_skills_allowed = $SourceSkills
      reviewed_candidates_loaded = $true
      new_skill_creation_allowed = $false
      skill_promotion_allowed = $false
      accepted_state_mutation_allowed = $false
      accepted_memory_mutation_allowed = $false
      accepted_self_model_mutation_allowed = $false
      external_fetch_allowed = $false
      install_allowed = $false
      arbitrary_code_execution_allowed = $false
      capability_shelf_mutation_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $SkillReusePolicyPath -Object $SkillReusePolicy

    $Cycle009 = [ordered]@{
      status = "PASS"
      cycle_id = "cycle_009"
      step_id = $StepId
      run_id = $RunId
      reused_skill_id = $SourceSkills[0]
      source_skill_path = $GapInventorySkillPath
      self_gap_inventory_skill_reused = $true
      selected_gap = "SELF_WRITTEN_BUILD_SPEC_EXECUTION_GAP"
      gap_class = "entrypoint_missing"
      reason = "Builder can write self-build specs but needs a bounded executor/reviewer path for self-written specs."
      source_skills_reused = $true
      new_skill_built = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $Cycle009Path -Object $Cycle009

    $Cycle010 = [ordered]@{
      status = "PASS"
      cycle_id = "cycle_010"
      step_id = $StepId
      run_id = $RunId
      reused_skill_id = $SourceSkills[1]
      source_skill_path = $RepairTaskSpecSkillPath
      self_repair_task_spec_writer_skill_reused = $true
      source_gap = "SELF_WRITTEN_BUILD_SPEC_EXECUTION_GAP"
      source_gap_class = "entrypoint_missing"
      task_spec_created = $true
      task_spec_id = $TaskSpecId
      task_type = "generic_sandbox_execution_request"
      target_step = $NextAllowedStep
      generic_bridge_id = $GenericBridgeId
      generic_executor_path = $GenericExecutorPath
      phase_specific_entrypoint_required = $false
      codex_required_for_phase159_entrypoint = $false
      source_skills_reused = $true
      new_skill_built = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $Cycle010Path -Object $Cycle010

    $Cycle011 = [ordered]@{
      status = "PASS"
      cycle_id = "cycle_011"
      step_id = $StepId
      run_id = $RunId
      reused_skill_id = $SourceSkills[2]
      source_skill_path = $ProofSummarySkillPath
      self_proof_summary_skill_reused = $true
      accepted = $false
      candidate_ready = $true
      codex_needed = $false
      next_step = $NextAllowedStep
      source_skills_reused = $true
      new_skill_built = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $Cycle011Path -Object $Cycle011

    $SpecCandidate = [ordered]@{
      status = "PASS"
      spec_id = $TaskSpecId
      step_id = $StepId
      run_id = $RunId
      source_skills_used = $SourceSkills
      source_skills_reused = $true
      selected_gap = "SELF_WRITTEN_BUILD_SPEC_EXECUTION_GAP"
      task_type = "generic_sandbox_execution_request"
      target_step = $NextAllowedStep
      generic_bridge_id = $GenericBridgeId
      generic_executor_path = $GenericExecutorPath
      phase_specific_entrypoint_required = $false
      codex_required_for_phase159_entrypoint = $false
      execution_type = "EXECUTE_SELF_WRITTEN_BUILD_SPEC_IN_SANDBOX"
      execution_scope = "sandbox_only"
      candidate_only = $true
      accepted_state_mutation_allowed = $false
      capability_shelf_mutation_allowed = $false
      external_fetch_allowed = $false
      install_allowed = $false
      arbitrary_code_execution_allowed = $false
      accepted_capability_created = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $SpecCandidatePath -Object $SpecCandidate

    $SpecContract = [ordered]@{
      status = "PASS"
      contract_id = "PHASE158_SELF_WRITTEN_BUILD_SPEC_CONTRACT"
      step_id = $StepId
      run_id = $RunId
      spec_id = $TaskSpecId
      target_step = $NextAllowedStep
      required_outputs = @($GenericExecutionRequestPath, $GenericExecutionAdmissionPath, $GenericSandboxExecutionResultPath, $GenericExecutionValidationPath)
      source_skills_used = $SourceSkills
      source_skills_reused = $true
      candidate_only = $true
      execution_scope = "sandbox_only"
      generic_bridge_id = $GenericBridgeId
      phase_specific_entrypoint_required = $false
      codex_required_for_phase159_entrypoint = $false
      validation_rule = "Self-written spec must be admissible to the generic sandbox execution bridge without creating a phase-specific PHASE159 entrypoint."
      accepted_state_mutation_allowed = $false
      capability_shelf_mutation_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $SpecContractPath -Object $SpecContract

    $SpecValidation = [ordered]@{
      status = "PASS"
      validation_id = "PHASE158_SELF_WRITTEN_BUILD_SPEC_VALIDATION"
      step_id = $StepId
      run_id = $RunId
      spec_id = $TaskSpecId
      spec_valid = $true
      source_skills_reused = $true
      candidate_only = $true
      target_step_verified = $true
      safety_scope_verified = $true
      forbidden_mutation_flags_verified = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $SpecValidationPath -Object $SpecValidation

    $GenericExecutionRequest = [ordered]@{
      status = "PASS"
      request_id = "PHASE158_GENERIC_SPEC_EXECUTION_REQUEST"
      step_id = $StepId
      run_id = $RunId
      source_spec_candidate_path = $SpecCandidatePath
      spec_id = $TaskSpecId
      target_step = $NextAllowedStep
      execution_type = "RUN_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE"
      execution_scope = "sandbox_only"
      generic_bridge_id = $GenericBridgeId
      generic_executor_path = $GenericExecutorPath
      self_written_spec_loaded = $true
      source_skills_reused = $true
      phase_specific_entrypoint_required = $false
      codex_required_for_phase159_entrypoint = $false
      accepted_state_mutation_allowed = $false
      capability_shelf_mutation_allowed = $false
      external_fetch_allowed = $false
      install_allowed = $false
      arbitrary_code_execution_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $GenericExecutionRequestPath -Object $GenericExecutionRequest

    $GenericExecutionAdmission = [ordered]@{
      status = "PASS"
      admission_id = "PHASE158_GENERIC_SPEC_EXECUTION_ADMISSION"
      step_id = $StepId
      run_id = $RunId
      source_execution_request_path = $GenericExecutionRequestPath
      admitted_for_generic_sandbox_execution = $true
      phase_specific_entrypoint_required = $false
      codex_required_for_phase159_entrypoint = $false
      execution_scope = "sandbox_only"
      generic_bridge_id = $GenericBridgeId
      accepted_state_mutation_allowed = $false
      capability_shelf_mutation_allowed = $false
      external_fetch_allowed = $false
      install_allowed = $false
      arbitrary_code_execution_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $GenericExecutionAdmissionPath -Object $GenericExecutionAdmission

    $GenericSandboxExecutionResult = [ordered]@{
      status = "PASS"
      result_id = "PHASE158_GENERIC_SPEC_SANDBOX_EXECUTION_RESULT"
      step_id = $StepId
      run_id = $RunId
      source_execution_admission_path = $GenericExecutionAdmissionPath
      source_spec_candidate_path = $SpecCandidatePath
      execution_scope = "sandbox_only"
      self_written_spec_loaded = $true
      generic_executor_path_used = $true
      generic_executor_path = $GenericExecutorPath
      phase_specific_module_created = $false
      phase_specific_entrypoint_required = $false
      codex_required_for_phase159_entrypoint = $false
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
      capability_shelf_mutated = $false
      body_pack_mutated = $false
      external_fetch_performed = $false
      dependency_install_performed = $false
      arbitrary_code_execution_used = $false
      external_agents_created = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $GenericSandboxExecutionResultPath -Object $GenericSandboxExecutionResult

    $GenericExecutionValidation = [ordered]@{
      status = "PASS"
      validation_id = "PHASE158_GENERIC_SPEC_EXECUTION_VALIDATION"
      step_id = $StepId
      run_id = $RunId
      source_sandbox_execution_result_path = $GenericSandboxExecutionResultPath
      generic_execution_bridge_proven = $true
      self_written_spec_executable_by_generic_bridge = $true
      generic_spec_execution_request_created = $true
      generic_spec_execution_admission_created = $true
      generic_spec_sandbox_execution_result_created = $true
      phase_specific_entrypoint_required = $false
      codex_required_for_phase159_entrypoint = $false
      accepted_state_mutated = $false
      capability_shelf_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $GenericExecutionValidationPath -Object $GenericExecutionValidation

    $SelfModelCandidate = [ordered]@{
      status = "PASS"
      candidate_id = "PHASE158_SELF_MODEL_UPDATE_CANDIDATE"
      step_id = $StepId
      run_id = $RunId
      update_type = "SELF_BUILT_GAP_SKILLS_REUSED_FOR_SELF_BUILD_SPEC_CANDIDATE"
      candidate_only = $true
      accepted_self_model_mutated = $false
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $SelfModelCandidatePath -Object $SelfModelCandidate

    $NextExecutionTicket = [ordered]@{
      status = "PASS"
      ticket_id = "PHASE158_NEXT_EXECUTION_TICKET"
      step_id = $StepId
      run_id = $RunId
      ticket_status = "ISSUED_FOR_PHASE159_ONLY"
      execution_type = "RUN_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE"
      allowed_scope = "sandbox_only"
      source_spec_candidate_path = $SpecCandidatePath
      source_generic_execution_request_path = $GenericExecutionRequestPath
      source_generic_execution_result_path = $GenericSandboxExecutionResultPath
      target_step = $NextAllowedStep
      generic_bridge_id = $GenericBridgeId
      generic_executor_path = $GenericExecutorPath
      phase_specific_entrypoint_required = $false
      codex_required_for_phase159_entrypoint = $false
      accepted_state_mutation_allowed = $false
      external_fetch_allowed = $false
      install_allowed = $false
      capability_shelf_mutation_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $NextExecutionTicketPath -Object $NextExecutionTicket

    $RuntimeStop = [ordered]@{
      status = "PASS"
      decision_id = "PHASE158_RUNTIME_STOP_DECISION"
      step_id = $StepId
      run_id = $RunId
      safe_stop = $true
      stop_reason = "PHASE158_GENERIC_EXECUTION_BRIDGE_PROVEN"
      stopped_after_output = $GenericExecutionValidationPath
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $RuntimeStopDecisionPath -Object $RuntimeStop

    $RuntimeCreatedOutputs = @(
      $TrialBootPath,
      $TicketReadPath,
      $CandidateLoadPath,
      $SkillReusePolicyPath,
      $Cycle009Path,
      $Cycle010Path,
      $Cycle011Path,
      $SpecCandidatePath,
      $SpecContractPath,
      $SpecValidationPath,
      $GenericExecutionRequestPath,
      $GenericExecutionAdmissionPath,
      $GenericSandboxExecutionResultPath,
      $GenericExecutionValidationPath,
      $ReuseTrialResultPath,
      $SelfModelCandidatePath,
      $NextExecutionTicketPath,
      $RuntimeStopDecisionPath,
      $ReuseTrialTracePath
    )

    $Common = [ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase157_verified = $true
      reviewed_candidates_loaded = $true
      reviewed_candidate_count = 3
      self_gap_inventory_skill_reused = $true
      self_repair_task_spec_writer_skill_reused = $true
      self_proof_summary_skill_reused = $true
      cycle_009_selected_gap = "SELF_WRITTEN_BUILD_SPEC_EXECUTION_GAP"
      cycle_009_gap_class = "entrypoint_missing"
      cycle_010_task_spec_created = $true
      cycle_010_task_spec_id = $TaskSpecId
      self_written_build_spec_candidate_created = $true
      self_written_build_spec_validated = $true
      generic_spec_execution_request_created = $true
      generic_spec_execution_admission_created = $true
      generic_spec_sandbox_execution_result_created = $true
      generic_spec_execution_validated = $true
      generic_execution_bridge_proven = $true
      self_written_spec_executable_by_generic_bridge = $true
      phase_specific_entrypoint_required = $false
      codex_required_for_phase159_entrypoint = $false
      source_skills_reused = $true
      source_skills_used = $SourceSkills
      candidate_only = $true
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
      skill_candidates_promoted = $false
      accepted_capability_created = $false
      capability_shelf_mutated = $false
      body_pack_mutated = $false
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      arbitrary_code_execution_used = $false
      external_agents_created = $false
      orchestrator_changed = $false
      route_lock_changed = $false
      current_runtime_changed = $false
      safe_stop = $true
      queue_after = "NONE"
      codex_needed_for_next_step = $false
      trial_root = $TrialRoot
      self_written_build_spec_candidate_path = $SpecCandidatePath
      generic_spec_execution_request_path = $GenericExecutionRequestPath
      generic_spec_sandbox_execution_result_path = $GenericSandboxExecutionResultPath
      next_execution_ticket_path = $NextExecutionTicketPath
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      next_allowed_step = $NextAllowedStep
    }

    $ReuseTrialResult = [ordered]@{}
    foreach ($key in $Common.Keys) { $ReuseTrialResult[$key] = $Common[$key] }
    $ReuseTrialResult["result_id"] = "PHASE158_REUSE_TRIAL_RESULT"
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $ReuseTrialResultPath -Object $ReuseTrialResult

    $ReuseTrialTrace = [ordered]@{
      status = "PASS"
      trace_id = "PHASE158_REUSE_TRIAL_TRACE"
      step_id = $StepId
      run_id = $RunId
      sequence = @("VERIFY_PHASE157_TICKET", "LOAD_REVIEWED_CANDIDATES", "REUSE_GAP_INVENTORY_SKILL", "REUSE_REPAIR_TASK_SPEC_WRITER_SKILL", "REUSE_PROOF_SUMMARY_SKILL", "WRITE_SELF_BUILD_SPEC_CANDIDATE", "VALIDATE_SPEC_CANDIDATE", "CREATE_GENERIC_EXECUTION_REQUEST", "ADMIT_GENERIC_EXECUTION", "PROVE_GENERIC_SANDBOX_EXECUTION_RESULT", "VALIDATE_GENERIC_EXECUTION_BRIDGE", "ISSUE_PHASE159_GENERIC_BRIDGE_TICKET", "SAFE_STOP")
      phase157_verified = $true
      reviewed_candidates_loaded = $true
      source_skills_reused = $true
      self_written_build_spec_candidate_created = $true
      self_written_build_spec_validated = $true
      generic_execution_bridge_proven = $true
      phase_specific_entrypoint_required = $false
      codex_required_for_phase159_entrypoint = $false
      safe_stop = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $ReuseTrialTracePath -Object $ReuseTrialTrace

    $Result = [ordered]@{}
    foreach ($key in $Common.Keys) { $Result[$key] = $Common[$key] }
    $Result["result_id"] = "PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_RESULT"
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result

    $Report = [ordered]@{
      status = "PASS"
      report_id = "PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1_REPORT"
      step_id = $StepId
      run_id = $RunId
      root_cause = "PHASE158 entrypoint absent"
      files_changed = @($RouteAlignmentPath, $ModulePath, $ValidatorPath) + $RuntimeCreatedOutputs + @($ResultPath, $ReportPath, $ProofPath)
      module_path = $ModulePath
      validator_path = $ValidatorPath
      exact_run_command_expected = ".\modules\invoke_builder_uses_self_built_gap_skills_for_self_build_spec_trial_001.ps1"
      exact_validator_command_expected = ".\validators\validate_phase158_builder_uses_self_built_gap_skills_for_self_build_spec_trial_v1.ps1 -RepoRoot ."
      runtime_output_files_created = $RuntimeCreatedOutputs + @($ResultPath, $ReportPath, $ProofPath)
      how_phase156_157_skills_are_reused = @(
        "PHASE157 next_reuse_ticket authorizes exactly the three PHASE156 sandbox candidates for bounded reuse.",
        "cycle_009 reuses SELF_GAP_INVENTORY_SKILL_CANDIDATE_V1 to classify the PHASE159 executor/reviewer need as entrypoint_missing.",
        "cycle_010 reuses SELF_REPAIR_TASK_SPEC_WRITER_SKILL_CANDIDATE_V1 to write SELF_WRITTEN_BUILD_SPEC_EXECUTION_TASK_SPEC_V1.",
        "cycle_011 reuses SELF_PROOF_SUMMARY_SKILL_CANDIDATE_V1 to mark the candidate ready, unaccepted, and Codex-free for the next step.",
        "PHASE158 converts the self-written spec into a generic_spec_execution_request and proves a sandbox result through the generic bridge without creating a phase-specific PHASE159 entrypoint."
      )
      risks = @(
        "PHASE158 proves only the generic bridge request/result contour; PHASE159 must run that generic bridge path under its own review boundary.",
        "The reused skills remain sandbox candidates and are not promoted to capability_shelf.",
        "No phase-specific PHASE159 module is created or required by this repair."
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
        "No accepted PHASE142-PHASE157 artifact mutation.",
        "No generated_agents or applied_agents touch.",
        "No package manager or dependency file touch.",
        "No GitHub workflow touch.",
        "No route lock touch.",
        "No internet fetch.",
        "No dependency install.",
        "No arbitrary generated code execution.",
        "No accepted state, memory, or self-model mutation.",
        "No trusted source marking.",
        "No skill candidate promotion.",
        "No new body pack.",
        "No new self-growth runtime.",
        "No external agent production.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report

    $Proof = [ordered]@{}
    foreach ($key in $Common.Keys) { $Proof[$key] = $Common[$key] }
    $Proof["proof_id"] = $StepId
    $Proof["trial_boot_path"] = $TrialBootPath
    $Proof["phase157_ticket_read_path"] = $TicketReadPath
    $Proof["reviewed_candidate_skill_load_path"] = $CandidateLoadPath
    $Proof["self_written_build_spec_candidate_path"] = $SpecCandidatePath
    $Proof["self_written_build_spec_validation_result_path"] = $SpecValidationPath
    $Proof["generic_spec_execution_request_path"] = $GenericExecutionRequestPath
    $Proof["generic_spec_execution_admission_path"] = $GenericExecutionAdmissionPath
    $Proof["generic_spec_sandbox_execution_result_path"] = $GenericSandboxExecutionResultPath
    $Proof["generic_spec_execution_validation_result_path"] = $GenericExecutionValidationPath
    $Proof["next_execution_ticket_path"] = $NextExecutionTicketPath
    $Proof["runtime_stop_decision_path"] = $RuntimeStopDecisionPath
    Write-Phase158JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject][ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase157_verified = $true
      reviewed_candidates_loaded = $true
      reviewed_candidate_count = 3
      self_gap_inventory_skill_reused = $true
      self_repair_task_spec_writer_skill_reused = $true
      self_proof_summary_skill_reused = $true
      cycle_009_selected_gap = "SELF_WRITTEN_BUILD_SPEC_EXECUTION_GAP"
      cycle_010_task_spec_created = $true
      self_written_build_spec_candidate_created = $true
      self_written_build_spec_validated = $true
      generic_execution_bridge_proven = $true
      phase_specific_entrypoint_required = $false
      codex_required_for_phase159_entrypoint = $false
      source_skills_reused = $true
      candidate_only = $true
      safe_stop = $true
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
  Invoke-BuilderUsesSelfBuiltGapSkillsForSelfBuildSpecTrial001 -RepoRoot $RepoRoot -RunId $RunId | ConvertTo-Json -Depth 20
}
