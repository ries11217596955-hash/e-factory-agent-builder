function Resolve-Phase150Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase150JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase150Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE150_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase150JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase150Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase150TextFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$Content
  )

  $fullPath = Resolve-Phase150Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  if (-not $Content.EndsWith("`n")) {
    $Content += "`n"
  }

  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase150Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE150_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase150False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE150_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Invoke-BuilderReuseBasedMicroOrganTrial001 {
  param(
    [string]$RepoRoot,
    [string]$RunId = "PHASE150_SELF_BUILD_IGNITION_BRIDGE_001"
  )

  $ErrorActionPreference = "Stop"
  Push-Location $RepoRoot

  try {
    $StepId = "PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1"
    $NextAllowedStep = "PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1"
    $Phase149StepId = "PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1"
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

    foreach ($identityFile in @(
      "CAPABILITY_ROADMAP.json",
      "GENESIS_STATE.json",
      "TASK_QUEUE.json",
      "packs/registry.json",
      "orchestrator/run.ps1"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase150Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $Branch = (git branch --show-current).Trim()
    if ($Branch -eq "main") {
      throw "PHASE150_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase150Equals -Actual $Branch -Expected "phase110-idempotent-autonomy-trial-runtime" -Name "current_branch"
    $Head = (git rev-parse --short HEAD).Trim()
    Assert-Phase150Equals -Actual $Head -Expected "22a6fe6" -Name "current_head"

    $ForbiddenBefore = @(git status --short --untracked-files=all -- `
      orchestrator/run.ps1 `
      route_locks `
      capability_shelf `
      generated_agents `
      applied_agents `
      runtime_sessions/builder_life_loop/current `
      TASK_QUEUE.json `
      GENESIS_STATE.json `
      CAPABILITY_ROADMAP.json `
      packs/registry.json 2>$null)
    if ($ForbiddenBefore.Count -gt 0) {
      throw "PHASE150_FORBIDDEN_SCOPE_DIRTY_BEFORE=$($ForbiddenBefore -join '; ')"
    }

    $Phase149Proof = Read-Phase150JsonRequired -RepoRoot $RepoRoot -Path $Phase149ProofPath
    Assert-Phase150Equals -Actual $Phase149Proof.status -Expected "PASS" -Name "phase149_status"
    Assert-Phase150Equals -Actual $Phase149Proof.selected_capability_id -Expected $ReusedCapabilityId -Name "phase149_selected_capability_id"
    Assert-Phase150Equals -Actual $Phase149Proof.next_allowed_step -Expected $StepId -Name "phase149_next_allowed_step"

    $Phase149Proposal = Read-Phase150JsonRequired -RepoRoot $RepoRoot -Path $Phase149ProposalPath
    Assert-Phase150Equals -Actual $Phase149Proposal.status -Expected "PASS" -Name "phase149_proposal_status"
    Assert-Phase150Equals -Actual $Phase149Proposal.selected_capability_id -Expected $ReusedCapabilityId -Name "phase149_proposal_selected_capability_id"
    Assert-Phase150False -Actual $Phase149Proposal.accepted_state_change_requested -Name "phase149_proposal_accepted_state_change_requested"

    $Phase149LearningCard = Read-Phase150JsonRequired -RepoRoot $RepoRoot -Path $Phase149LearningCardPath
    Assert-Phase150Equals -Actual $Phase149LearningCard.status -Expected "PASS" -Name "phase149_learning_card_status"
    Assert-Phase150Equals -Actual $Phase149LearningCard.selected_capability_id -Expected $ReusedCapabilityId -Name "phase149_learning_card_selected_capability_id"

    $SourcePolicy = Read-Phase150JsonRequired -RepoRoot $RepoRoot -Path $SourcePolicyPath
    Assert-Phase150False -Actual $SourcePolicy.default_trust -Name "source_policy_default_trust"
    Assert-Phase150False -Actual $SourcePolicy.external_fetch_allowed -Name "source_policy_external_fetch_allowed"
    Assert-Phase150False -Actual $SourcePolicy.install_allowed -Name "source_policy_install_allowed"
    Assert-Phase150False -Actual $SourcePolicy.executable_use_allowed -Name "source_policy_executable_use_allowed"

    $TrustedSources = Read-Phase150JsonRequired -RepoRoot $RepoRoot -Path $TrustedSourcesPath
    Assert-Phase150Equals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count"
    Assert-Phase150Equals -Actual @($TrustedSources.trusted_sources).Count -Expected 0 -Name "trusted_sources_empty"

    $Capability = Read-Phase150JsonRequired -RepoRoot $RepoRoot -Path $CapabilityPath
    Assert-Phase150Equals -Actual $Capability.capability_id -Expected $ReusedCapabilityId -Name "capability_id"

    $Queue = Read-Phase150JsonRequired -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
    Assert-Phase150Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $InputSources = @(
      $Phase149ProofPath,
      $Phase149ProposalPath,
      $Phase149LearningCardPath,
      $SourcePolicyPath,
      $TrustedSourcesPath,
      $CapabilityPath
    )
    $PlannedOutputs = @(
      "knowledge_library/learning_cards/<future_advisor_recommendation>.json",
      "living_learning_environment/proposals/<future_reuse_advice>.json",
      "living_learning_environment/reading_sessions/<future_session>/reuse_advice.json"
    )
    $SafetyFlags = [ordered]@{
      sandbox_only = $true
      accepted_state_mutation_allowed = $false
      accepted_state_mutated = $false
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      external_agents_created = $false
      trusted_source_count = 0
      orchestrator_changed = $false
      route_lock_changed = $false
      current_runtime_changed = $false
      capability_shelf_mutated = $false
      production_adoption_allowed = $false
    }

    Write-Phase150TextFile -RepoRoot $RepoRoot -Path $RouteAlignmentPath -Content ((@(
      "# PHASE150 Self-Build Ignition Alignment Request",
      "",
      "status: PASS",
      "from: PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1 as a possible Codex-built organ",
      "to: PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1 as self-build ignition bridge",
      "reason: PHASE149 proved Builder can read and select reusable capability self_learning_memory. PHASE150 should use that reuse proposal to generate a sandbox-only self-build program candidate for the future learning_card_reuse_advisor micro-organ, not mutate accepted Builder state.",
      "sandbox_only: true",
      "promotion_status: NOT_PROMOTED",
      "next_allowed_step: $NextAllowedStep"
    )) -join "`n")

    $SelfBuildIntent = [ordered]@{
      status = "PASS"
      intent_id = "PHASE150_SELF_BUILD_INTENT"
      step_id = $StepId
      run_id = $RunId
      gap_detected = $true
      missing_capability = $MissingCapability
      reused_capability_id = $ReusedCapabilityId
      target_output = "self_build_program_candidate"
      accepted_state_mutation_allowed = $false
      sandbox_only = $true
      input_sources = $InputSources
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase150JsonFile -RepoRoot $RepoRoot -Path $SelfBuildIntentPath -Object $SelfBuildIntent

    $ProgramCandidate = [ordered]@{
      status = "PASS"
      program_id = $ProgramId
      step_id = $StepId
      run_id = $RunId
      program_status = "CANDIDATE_NOT_ADMITTED"
      generated_by_builder_runtime = $true
      target_micro_organ_id = $MissingCapability
      reused_capability_id = $ReusedCapabilityId
      input_sources = $InputSources
      planned_outputs = $PlannedOutputs
      safety_flags = $SafetyFlags
      validator_required = $true
      admission_required = $true
      admitted = $false
      promoted = $false
      trusted = $false
      executed = $false
      sandbox_path = $ProgramCandidatePath
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase150JsonFile -RepoRoot $RepoRoot -Path $ProgramCandidatePath -Object $ProgramCandidate

    $ProgramContract = [ordered]@{
      status = "PASS"
      contract_id = "PHASE150_LEARNING_CARD_REUSE_ADVISOR_PROGRAM_CONTRACT"
      step_id = $StepId
      run_id = $RunId
      target_micro_organ_id = $MissingCapability
      inputs = @(
        "knowledge_library/learning_cards/*.json",
        "capability_shelf/registry.json",
        "capability_shelf/capabilities/self_learning_memory.json",
        "source_registry/source_policy.json",
        "source_registry/trusted_sources.json"
      )
      outputs = $PlannedOutputs
      forbidden_actions = @(
        "modify accepted Builder state",
        "modify orchestrator/run.ps1",
        "modify route_locks",
        "modify capability_shelf accepted files",
        "create external agents",
        "fetch internet",
        "install dependencies",
        "execute external materials",
        "mark source trusted",
        "promote candidate without admission"
      )
      proof_requirements = @(
        "validator PASS",
        "sandbox execution evidence",
        "source policy safe fields",
        "trusted_source_count 0",
        "no forbidden flags true",
        "owner approval before promotion"
      )
      rollback_or_quarantine_rule = "If validation fails, keep candidate in living_learning_environment/sandbox and mark promotion candidate NOT_PROMOTED or QUARANTINED; do not apply to accepted Builder state."
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase150JsonFile -RepoRoot $RepoRoot -Path $ProgramContractPath -Object $ProgramContract

    $AdmissionChecklist = [ordered]@{
      status = "PASS"
      checklist_id = "PHASE150_SELF_BUILD_PROGRAM_ADMISSION_CHECKLIST"
      step_id = $StepId
      run_id = $RunId
      program_id = $ProgramId
      requires_owner_approval = $true
      requires_validator = $true
      requires_sandbox_execution = $true
      accepted_state_change_requested = $false
      requires_source_policy_safe = $true
      requires_trusted_source_count_zero = $true
      requires_no_fetch_install_execute = $true
      requires_not_promoted_before_admission = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase150JsonFile -RepoRoot $RepoRoot -Path $AdmissionChecklistPath -Object $AdmissionChecklist

    $FutureExecutionPlan = [ordered]@{
      status = "PASS"
      plan_id = "PHASE150_FUTURE_EXECUTION_PLAN"
      step_id = $StepId
      run_id = $RunId
      program_id = $ProgramId
      plan_for_future_phase = "PHASE152"
      plan_status = "FUTURE_NOT_EXECUTED"
      execution_now = $false
      sandbox_only = $true
      steps = @(
        "PHASE151 admits or rejects the candidate using validator and owner approval gates.",
        "PHASE152 may execute admitted candidate in sandbox only.",
        "Future promotion requires proof and explicit promotion gate."
      )
      forbidden_now = @("execute candidate","promote candidate","mutate accepted Builder state")
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase150JsonFile -RepoRoot $RepoRoot -Path $FutureExecutionPlanPath -Object $FutureExecutionPlan

    $TrialTrace = [ordered]@{
      status = "PASS"
      trace_id = "PHASE150_SELF_BUILD_IGNITION_BRIDGE_TRACE"
      step_id = $StepId
      run_id = $RunId
      reused_capability_id = $ReusedCapabilityId
      sandbox_only = $true
      accepted_state_mutated = $false
      self_build_program_candidate_created = $true
      gap_detected = $true
      missing_capability = $MissingCapability
      input_sources = $InputSources
      created_outputs = @(
        $SelfBuildIntentPath,
        $ProgramCandidatePath,
        $ProgramContractPath,
        $AdmissionChecklistPath,
        $FutureExecutionPlanPath
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase150JsonFile -RepoRoot $RepoRoot -Path $TrialTracePath -Object $TrialTrace

    $ModuleRequest = [ordered]@{
      status = "PASS"
      request_id = "PHASE150_SELF_BUILD_PROGRAM_GENERATOR_REQUEST"
      step_id = $StepId
      run_id = $RunId
      request_type = "SELF_BUILD_PROGRAM_GENERATOR_ADMISSION_REQUEST"
      missing_tool_or_defect = "Builder needs an admitted self-build program generator path for learning_card_reuse_advisor candidates."
      evidence_paths = @($ProgramCandidatePath, $ProgramContractPath, $AdmissionChecklistPath)
      codex_required_now = $false
      builder_generated_candidate_exists = $true
      accepted_state_change_requested = $false
      sandbox_only = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase150JsonFile -RepoRoot $RepoRoot -Path $ModuleRequestPath -Object $ModuleRequest

    $PromotionCandidate = [ordered]@{
      status = "PASS"
      promotion_candidate_id = "PHASE150_SELF_BUILD_PROGRAM_CANDIDATE_PROMOTION_CANDIDATE"
      step_id = $StepId
      run_id = $RunId
      program_id = $ProgramId
      candidate_path = $ProgramCandidatePath
      promotion_status = "NOT_PROMOTED"
      owner_approval_required = $true
      accepted_state_change_requested = $false
      validator_required_before_promotion = $true
      trusted = $false
      accepted = $false
      promoted = $false
      executed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase150JsonFile -RepoRoot $RepoRoot -Path $PromotionCandidatePath -Object $PromotionCandidate

    $Common = [ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase149_verified = $true
      reused_capability_id = $ReusedCapabilityId
      gap_detected = $true
      missing_capability = $MissingCapability
      self_build_intent_created = $true
      self_build_program_candidate_created = $true
      self_build_program_contract_created = $true
      admission_checklist_created = $true
      future_execution_plan_created = $true
      module_request_created = $true
      promotion_candidate_created = $true
      sandbox_only = $true
      promotion_status = "NOT_PROMOTED"
      owner_approval_required = $true
      accepted_state_change_requested = $false
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      accepted_state_mutated = $false
      external_agents_created = $false
      orchestrator_changed = $false
      route_lock_changed = $false
      current_runtime_changed = $false
      capability_shelf_mutated = $false
      trusted_source_count = 0
      queue_after = "NONE"
      selected_by = "BUILDER_RUNTIME"
      self_build_intent_path = $SelfBuildIntentPath
      self_build_program_candidate_path = $ProgramCandidatePath
      self_build_program_contract_path = $ProgramContractPath
      admission_checklist_path = $AdmissionChecklistPath
      future_execution_plan_path = $FutureExecutionPlanPath
      trial_trace_path = $TrialTracePath
      module_request_path = $ModuleRequestPath
      promotion_candidate_path = $PromotionCandidatePath
      next_allowed_step = $NextAllowedStep
    }

    $Result = [ordered]@{}
    foreach ($key in $Common.Keys) { $Result[$key] = $Common[$key] }
    $Result["result_id"] = "PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_RESULT"
    Write-Phase150JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result

    $Report = [ordered]@{
      status = "PASS"
      report_id = "PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1_REPORT"
      step_id = $StepId
      run_id = $RunId
      route_alignment_request_path = $RouteAlignmentPath
      files_changed = @(
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
      input_sources = $InputSources
      reused_capability_id = $ReusedCapabilityId
      missing_capability = $MissingCapability
      candidate_scope = "living_learning_environment/sandbox only"
      risks = @(
        "PHASE150 creates a candidate and future execution plan only; PHASE151 must admit or reject it before use.",
        "The candidate is not executed, trusted, admitted, promoted, or accepted.",
        "The future micro-organ may still need refinement after admission-gate review."
      )
      cut_list = @(
        "No orchestrator change.",
        "No route lock change.",
        "No accepted PHASE142-PHASE149 artifact change.",
        "No accepted capability_shelf mutation.",
        "No TASK_QUEUE mutation.",
        "No generated_agents or applied_agents touch.",
        "No internet fetch.",
        "No dependency install.",
        "No external executable material use.",
        "No trusted source creation.",
        "No external agent production.",
        "No accepted Builder state mutation.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase150JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report

    $Proof = [ordered]@{}
    foreach ($key in $Common.Keys) { $Proof[$key] = $Common[$key] }
    $Proof["proof_id"] = $StepId
    $Proof["phase149_proof_path"] = $Phase149ProofPath
    $Proof["phase149_reuse_proposal_path"] = $Phase149ProposalPath
    $Proof["phase149_learning_card_path"] = $Phase149LearningCardPath
    $Proof["source_policy_path"] = $SourcePolicyPath
    $Proof["trusted_sources_path"] = $TrustedSourcesPath
    $Proof["capability_path"] = $CapabilityPath
    $Proof["result_path"] = $ResultPath
    $Proof["report_path"] = $ReportPath
    Write-Phase150JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject][ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      reused_capability_id = $ReusedCapabilityId
      missing_capability = $MissingCapability
      self_build_program_candidate_path = $ProgramCandidatePath
      promotion_status = "NOT_PROMOTED"
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      next_allowed_step = $NextAllowedStep
    }
  } finally {
    Pop-Location
  }
}
