param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase156ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase156ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase156ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE156_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Assert-Phase156ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE156_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase156ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE156_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase156ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE156_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase156StatusPath {
  param([string]$StatusLine)

  if ($StatusLine -match '^.. (.+)$') {
    return ($Matches[1] -replace '\\', '/')
  }
  return ($StatusLine -replace '\\', '/')
}

function Get-Phase156ExpectedResult {
  param([object]$TestCase)

  switch ($TestCase.operation) {
    "classify_gap_inventory" {
      $map = @{
        missing_entrypoint = "entrypoint_missing"
        missing_validator = "validator_missing"
        missing_runtime_output = "runtime_output_missing"
      }
      return $map[[string]$TestCase.input_kind]
    }
    "write_repair_task_spec" {
      $map = @{
        entrypoint_missing = "build_entrypoint_task"
        validator_missing = "build_validator_task"
        runtime_output_missing = "repair_runtime_output_generation_task"
      }
      return $map[[string]$TestCase.input_kind]
    }
    "summarize_proof_state" {
      return [ordered]@{
        accepted = ([string]$TestCase.proof_status -eq "PASS")
        next_step = [string]$TestCase.next_allowed_step
        codex_needed = [bool]$TestCase.codex_needed_for_next_step
      }
    }
    default {
      throw "PHASE156_VALIDATE_UNSUPPORTED_OPERATION=$($TestCase.operation)"
    }
  }
}

function Assert-Phase156Cycle {
  param(
    [string]$RepoRoot,
    [string]$TrialRoot,
    [string]$CycleId,
    [string]$ExpectedGap,
    [string]$ExpectedSkillId,
    [string]$ExpectedNextGap,
    [string]$ExpectedQuestion,
    [string]$ExpectedSourcePath
  )

  $Diagnosis = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/self_diagnosis.json"
  Assert-Phase156ValidatorEquals -Actual $Diagnosis.detected_missing_sandbox_candidate_skill -Expected $ExpectedSkillId -Name "$CycleId:diagnosis_skill"

  $Selection = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/gap_selection.json"
  Assert-Phase156ValidatorEquals -Actual $Selection.selected_gap -Expected $ExpectedGap -Name "$CycleId:selected_gap"
  Assert-Phase156ValidatorEquals -Actual $Selection.selected_skill_id -Expected $ExpectedSkillId -Name "$CycleId:selected_skill"
  Assert-Phase156ValidatorEquals -Actual $Selection.selector_type -Expected "deterministic_internal_policy" -Name "$CycleId:selector"
  Assert-Phase156ValidatorFalse -Actual $Selection.owner_selected_gap -Name "$CycleId:owner_selected"
  Assert-Phase156ValidatorFalse -Actual $Selection.codex_selected_gap -Name "$CycleId:codex_selected"
  if ($ExpectedSourcePath -ne "") {
    Assert-Phase156ValidatorEquals -Actual $Selection.source_next_selected_gap_path -Expected $ExpectedSourcePath -Name "$CycleId:source_path"
    Assert-Phase156ValidatorTrue -Actual $Selection.selected_from_previous_cycle_next_gap -Name "$CycleId:from_previous"
  }

  $Question = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/internal_question.json"
  Assert-Phase156ValidatorEquals -Actual $Question.question -Expected $ExpectedQuestion -Name "$CycleId:question"

  $Program = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/self_build_program_candidate.json"
  Assert-Phase156ValidatorEquals -Actual $Program.target_skill_id -Expected $ExpectedSkillId -Name "$CycleId:program_skill"
  Assert-Phase156ValidatorEquals -Actual $Program.execution_scope -Expected "sandbox_only" -Name "$CycleId:program_scope"
  Assert-Phase156ValidatorFalse -Actual $Program.arbitrary_code_execution_allowed -Name "$CycleId:program_arbitrary"

  $Skill = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/skill_candidate.json"
  Assert-Phase156ValidatorEquals -Actual $Skill.skill_id -Expected $ExpectedSkillId -Name "$CycleId:skill_id"
  Assert-Phase156ValidatorFalse -Actual $Skill.accepted_capability -Name "$CycleId:accepted_capability"

  $Tests = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/test_cases.json"
  Assert-Phase156ValidatorEquals -Actual @($Tests.test_cases).Count -Expected 3 -Name "$CycleId:test_count"

  $Validation = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/skill_validation_result.json"
  Assert-Phase156ValidatorEquals -Actual $Validation.validation_status -Expected "PASS" -Name "$CycleId:validation_status"
  Assert-Phase156ValidatorTrue -Actual $Validation.independently_calculated -Name "$CycleId:independent"

  foreach ($testCase in @($Tests.test_cases)) {
    $expected = Get-Phase156ExpectedResult -TestCase $testCase
    $matching = @($Validation.calculated_results | Where-Object { $_.test_id -eq $testCase.test_id })
    Assert-Phase156ValidatorEquals -Actual $matching.Count -Expected 1 -Name "$CycleId:result_match:$($testCase.test_id)"
    if ($testCase.operation -eq "summarize_proof_state") {
      Assert-Phase156ValidatorEquals -Actual $matching[0].calculated_summary.accepted -Expected $expected.accepted -Name "$CycleId:summary_accepted:$($testCase.test_id)"
      Assert-Phase156ValidatorEquals -Actual $matching[0].calculated_summary.next_step -Expected $expected.next_step -Name "$CycleId:summary_next:$($testCase.test_id)"
      Assert-Phase156ValidatorEquals -Actual $matching[0].calculated_summary.codex_needed -Expected $expected.codex_needed -Name "$CycleId:summary_codex:$($testCase.test_id)"
    } else {
      Assert-Phase156ValidatorEquals -Actual $matching[0].calculated_output -Expected $expected -Name "$CycleId:calculated_output:$($testCase.test_id)"
    }
    Assert-Phase156ValidatorTrue -Actual $matching[0].passed -Name "$CycleId:case_passed:$($testCase.test_id)"
  }

  $Next = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/next_selected_gap.json"
  Assert-Phase156ValidatorEquals -Actual $Next.next_selected_gap -Expected $ExpectedNextGap -Name "$CycleId:next_gap"

  $Trace = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/cycle_trace.json"
  Assert-Phase156ValidatorEquals -Actual $Trace.selected_gap -Expected $ExpectedGap -Name "$CycleId:trace_gap"
  Assert-Phase156ValidatorEquals -Actual $Trace.validation_status -Expected "PASS" -Name "$CycleId:trace_validation"
  Assert-Phase156ValidatorTrue -Actual $Trace.no_codex_needed_inside_cycle -Name "$CycleId:no_codex"
}

function Assert-Phase156ProofFields {
  param(
    [object]$Artifact,
    [string]$Name
  )

  Assert-Phase156ValidatorEquals -Actual $Artifact.status -Expected "PASS" -Name "${Name}:status"
  Assert-Phase156ValidatorEquals -Actual $Artifact.step_id -Expected "PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1" -Name "${Name}:step_id"
  Assert-Phase156ValidatorEquals -Actual $Artifact.run_id -Expected "PHASE156_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_001" -Name "${Name}:run_id"
  Assert-Phase156ValidatorTrue -Actual $Artifact.phase155_verified -Name "${Name}:phase155_verified"
  Assert-Phase156ValidatorTrue -Actual $Artifact.admission_status_verified -Name "${Name}:admission_status_verified"
  Assert-Phase156ValidatorTrue -Actual $Artifact.ticket_verified -Name "${Name}:ticket_verified"
  Assert-Phase156ValidatorTrue -Actual $Artifact.bounded_reuse_policy_verified -Name "${Name}:bounded_policy"
  Assert-Phase156ValidatorTrue -Actual $Artifact.runtime_reused -Name "${Name}:runtime_reused"
  Assert-Phase156ValidatorFalse -Actual $Artifact.runtime_modified -Name "${Name}:runtime_modified"
  Assert-Phase156ValidatorTrue -Actual $Artifact.body_pack_verified -Name "${Name}:body_pack_verified"
  Assert-Phase156ValidatorFalse -Actual $Artifact.body_pack_mutated -Name "${Name}:body_pack_mutated"
  Assert-Phase156ValidatorEquals -Actual $Artifact.cycle_count -Expected 3 -Name "${Name}:cycle_count"
  Assert-Phase156ValidatorTrue -Actual $Artifact.cycle_006_started -Name "${Name}:cycle006_started"
  Assert-Phase156ValidatorEquals -Actual $Artifact.cycle_006_selected_gap -Expected "SELF_GAP_INVENTORY_GAP" -Name "${Name}:cycle006_gap"
  Assert-Phase156ValidatorEquals -Actual $Artifact.cycle_006_skill_id -Expected "SELF_GAP_INVENTORY_SKILL_CANDIDATE_V1" -Name "${Name}:cycle006_skill"
  Assert-Phase156ValidatorEquals -Actual $Artifact.cycle_006_validation_status -Expected "PASS" -Name "${Name}:cycle006_validation"
  Assert-Phase156ValidatorEquals -Actual $Artifact.cycle_006_next_selected_gap -Expected "SELF_REPAIR_TASK_SPEC_WRITER_GAP" -Name "${Name}:cycle006_next"
  Assert-Phase156ValidatorTrue -Actual $Artifact.cycle_007_started -Name "${Name}:cycle007_started"
  Assert-Phase156ValidatorTrue -Actual $Artifact.cycle_007_started_from_cycle_006_next_gap -Name "${Name}:cycle007_from_cycle006"
  Assert-Phase156ValidatorEquals -Actual $Artifact.cycle_007_selected_gap -Expected "SELF_REPAIR_TASK_SPEC_WRITER_GAP" -Name "${Name}:cycle007_gap"
  Assert-Phase156ValidatorEquals -Actual $Artifact.cycle_007_skill_id -Expected "SELF_REPAIR_TASK_SPEC_WRITER_SKILL_CANDIDATE_V1" -Name "${Name}:cycle007_skill"
  Assert-Phase156ValidatorEquals -Actual $Artifact.cycle_007_validation_status -Expected "PASS" -Name "${Name}:cycle007_validation"
  Assert-Phase156ValidatorEquals -Actual $Artifact.cycle_007_next_selected_gap -Expected "SELF_PROOF_SUMMARY_GAP" -Name "${Name}:cycle007_next"
  Assert-Phase156ValidatorTrue -Actual $Artifact.cycle_008_started -Name "${Name}:cycle008_started"
  Assert-Phase156ValidatorTrue -Actual $Artifact.cycle_008_started_from_cycle_007_next_gap -Name "${Name}:cycle008_from_cycle007"
  Assert-Phase156ValidatorEquals -Actual $Artifact.cycle_008_selected_gap -Expected "SELF_PROOF_SUMMARY_GAP" -Name "${Name}:cycle008_gap"
  Assert-Phase156ValidatorEquals -Actual $Artifact.cycle_008_skill_id -Expected "SELF_PROOF_SUMMARY_SKILL_CANDIDATE_V1" -Name "${Name}:cycle008_skill"
  Assert-Phase156ValidatorEquals -Actual $Artifact.cycle_008_validation_status -Expected "PASS" -Name "${Name}:cycle008_validation"
  Assert-Phase156ValidatorEquals -Actual $Artifact.cycle_008_next_selected_gap -Expected "STOP_PHASE156_CYCLE_LIMIT_REACHED" -Name "${Name}:cycle008_next"
  Assert-Phase156ValidatorTrue -Actual $Artifact.self_selected_gap_trial_proven -Name "${Name}:trial_proven"
  Assert-Phase156ValidatorTrue -Actual $Artifact.all_cycles_validated -Name "${Name}:all_cycles_validated"
  Assert-Phase156ValidatorFalse -Actual $Artifact.owner_selected_each_gap -Name "${Name}:owner_selected"
  Assert-Phase156ValidatorFalse -Actual $Artifact.codex_selected_each_gap -Name "${Name}:codex_selected"
  Assert-Phase156ValidatorTrue -Actual $Artifact.no_codex_needed_inside_cycles -Name "${Name}:no_codex_inside"
  Assert-Phase156ValidatorTrue -Actual $Artifact.built_skill_candidates_index_created -Name "${Name}:skill_index_created"
  Assert-Phase156ValidatorTrue -Actual $Artifact.self_model_growth_candidate_created -Name "${Name}:self_model_candidate"
  Assert-Phase156ValidatorTrue -Actual $Artifact.runtime_stop_decision_created -Name "${Name}:stop_created"
  Assert-Phase156ValidatorTrue -Actual $Artifact.safe_stop -Name "${Name}:safe_stop"
  Assert-Phase156ValidatorFalse -Actual $Artifact.codex_needed_for_next_step -Name "${Name}:codex_needed_next"
  foreach ($flag in @("external_fetch_performed", "dependency_install_performed", "executable_materials_used", "arbitrary_code_execution_used", "accepted_state_mutated", "accepted_memory_mutated", "accepted_self_model_mutated", "external_agents_created", "orchestrator_changed", "route_lock_changed", "current_runtime_changed", "capability_shelf_mutated")) {
    Assert-Phase156ValidatorFalse -Actual $Artifact.$flag -Name "${Name}:$flag"
  }
  Assert-Phase156ValidatorEquals -Actual $Artifact.trusted_source_count -Expected 0 -Name "${Name}:trusted_source_count"
  Assert-Phase156ValidatorEquals -Actual $Artifact.queue_after -Expected "NONE" -Name "${Name}:queue_after"
  Assert-Phase156ValidatorEquals -Actual $Artifact.next_allowed_step -Expected "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1" -Name "${Name}:next_allowed_step"
}

$Pushed = $false

try {
  $StepId = "PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1"
  $RunId = "PHASE156_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_001"
  $NextAllowedStep = "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1"
  $TrialRoot = "living_learning_environment/self_growth_cycles/$RunId"
  $RouteAlignmentPath = "route_change_requests/PHASE156_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_ALIGNMENT_REQUEST.md"
  $ModulePath = "modules/invoke_builder_self_selected_gap_self_build_trial_001.ps1"
  $ValidatorPath = "validators/validate_phase156_builder_self_selected_gap_self_build_trial_v1.ps1"
  $Phase155ProofPath = "proofs/self_development/PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1.json"
  $Phase155TicketPath = "living_learning_environment/admission_reviews/PHASE155_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_001/next_trial_ticket.json"
  $Phase155NextDecisionPath = "living_learning_environment/admission_reviews/PHASE155_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_001/next_cycle_decision.json"
  $Phase155BoundedPolicyPath = "living_learning_environment/admission_reviews/PHASE155_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_001/bounded_reuse_policy.json"
  $RuntimePath = "living_learning_environment/self_growth_runtime/SELF_GROWTH_DUTY_RUNTIME_V1.json"
  $CurriculumPath = "living_learning_environment/self_growth_runtime/SELF_GROWTH_CURRICULUM_V1.json"
  $SafetyPolicyPath = "living_learning_environment/self_growth_runtime/SELF_GROWTH_SAFETY_POLICY_V1.json"
  $BodyPackPath = "living_learning_environment/body/BUILDER_BODY_ORGAN_PACK_V1.json"
  $BodyPolicyPath = "living_learning_environment/body/body_policy.json"
  $SourcePolicyPath = "source_registry/source_policy.json"
  $TrustedSourcesPath = "source_registry/trusted_sources.json"
  $QueuePath = "TASK_QUEUE.json"
  $TrialBootPath = "$TrialRoot/trial_boot.json"
  $Phase155TicketReadPath = "$TrialRoot/phase155_ticket_read.json"
  $SelfGapDiscoveryPath = "$TrialRoot/self_gap_discovery.json"
  $SelfSelectedGapPolicyPath = "$TrialRoot/self_selected_gap_policy.json"
  $SelfSelectedGapTracePath = "$TrialRoot/self_selected_gap_trace.json"
  $CycleIndexPath = "$TrialRoot/cycle_index.json"
  $TrialResultPath = "$TrialRoot/self_selected_gap_trial_result.json"
  $SkillIndexPath = "$TrialRoot/built_skill_candidates_index.json"
  $SelfModelGrowthCandidatePath = "$TrialRoot/self_model_growth_candidate.json"
  $RuntimeStopDecisionPath = "$TrialRoot/runtime_stop_decision.json"
  $ResultPath = "self_control/BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_RESULT.json"
  $ReportPath = "reports/self_development/PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1_REPORT.json"
  $ProofPath = "proofs/self_development/PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1.json"
  $CycleOutputNames = @("self_diagnosis.json", "gap_selection.json", "internal_question.json", "internal_answer.json", "self_build_program_candidate.json", "sandbox_execution_trace.json", "skill_candidate.json", "skill_contract.json", "test_cases.json", "skill_validation_result.json", "learning_absorption_candidate.json", "next_selected_gap.json", "cycle_trace.json")
  $Cycle006Paths = @($CycleOutputNames | ForEach-Object { "$TrialRoot/cycle_006/$_" })
  $Cycle007Paths = @($CycleOutputNames | ForEach-Object { "$TrialRoot/cycle_007/$_" })
  $Cycle008Paths = @($CycleOutputNames | ForEach-Object { "$TrialRoot/cycle_008/$_" })
  $RuntimeOutputs = @($TrialBootPath, $Phase155TicketReadPath, $SelfGapDiscoveryPath, $SelfSelectedGapPolicyPath, $SelfSelectedGapTracePath, $CycleIndexPath) + $Cycle006Paths + $Cycle007Paths + $Cycle008Paths + @($TrialResultPath, $SkillIndexPath, $SelfModelGrowthCandidatePath, $RuntimeStopDecisionPath)
  $AllowedExact = @($RouteAlignmentPath, $ModulePath, $ValidatorPath, $ResultPath, $ReportPath, $ProofPath) + $RuntimeOutputs

  $RepoRoot = Resolve-Phase156ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot
  $Pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase156ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE156_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }
  Assert-Phase156ValidatorEquals -Actual $Branch -Expected "phase110-idempotent-autonomy-trial-runtime" -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  Assert-Phase156ValidatorEquals -Actual $Head -Expected "b6cb28c" -Name "current_head"

  foreach ($requiredPath in @($RouteAlignmentPath, $ModulePath, $ValidatorPath, $Phase155ProofPath, $Phase155TicketPath, $Phase155NextDecisionPath, $Phase155BoundedPolicyPath, $RuntimePath, $CurriculumPath, $SafetyPolicyPath, $BodyPackPath, $BodyPolicyPath, $SourcePolicyPath, $TrustedSourcesPath, $QueuePath, $ResultPath, $ReportPath, $ProofPath) + $RuntimeOutputs) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase156ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE156_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $StatusLines = @(git status --short --untracked-files=all)
  foreach ($line in $StatusLines) {
    $path = Get-Phase156StatusPath -StatusLine $line
    if (-not ($AllowedExact -contains $path)) {
      throw "PHASE156_VALIDATE_CHANGE_OUTSIDE_ALLOWED_SCOPE=$line"
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
    self_control/BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_RESULT.json 2>$null)
  if ($ProtectedStatus.Count -gt 0) {
    throw "PHASE156_VALIDATE_PROTECTED_SCOPE_CHANGED=$($ProtectedStatus -join '; ')"
  }

  $Phase155Proof = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path $Phase155ProofPath
  Assert-Phase156ValidatorEquals -Actual $Phase155Proof.status -Expected "PASS" -Name "phase155_status"
  Assert-Phase156ValidatorEquals -Actual $Phase155Proof.next_allowed_step -Expected $StepId -Name "phase155_next_allowed_step"
  Assert-Phase156ValidatorEquals -Actual $Phase155Proof.admission_status -Expected "ADMITTED_FOR_BOUNDED_SELF_GROWTH_SANDBOX_USE" -Name "phase155_admission"
  Assert-Phase156ValidatorEquals -Actual $Phase155Proof.max_cycles_per_run -Expected 3 -Name "phase155_max_cycles"

  $Ticket = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path $Phase155TicketPath
  Assert-Phase156ValidatorEquals -Actual $Ticket.ticket_status -Expected "ISSUED_FOR_PHASE156_ONLY" -Name "ticket_status"
  Assert-Phase156ValidatorEquals -Actual $Ticket.trial_type -Expected "SELF_SELECTED_GAP_SELF_BUILD_TRIAL" -Name "ticket_trial_type"

  $Policy = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path $SelfSelectedGapPolicyPath
  Assert-Phase156ValidatorEquals -Actual $Policy.selector_type -Expected "deterministic_internal_policy" -Name "policy_selector"
  Assert-Phase156ValidatorFalse -Actual $Policy.owner_selected_each_gap -Name "policy_owner_selected"
  Assert-Phase156ValidatorFalse -Actual $Policy.codex_selected_each_gap -Name "policy_codex_selected"
  Assert-Phase156ValidatorEquals -Actual $Policy.max_cycles -Expected 3 -Name "policy_max_cycles"
  Assert-Phase156ValidatorEquals -Actual $Policy.allowed_scope -Expected "sandbox_only" -Name "policy_scope"

  Assert-Phase156Cycle -RepoRoot $RepoRoot -TrialRoot $TrialRoot -CycleId "cycle_006" -ExpectedGap "SELF_GAP_INVENTORY_GAP" -ExpectedSkillId "SELF_GAP_INVENTORY_SKILL_CANDIDATE_V1" -ExpectedNextGap "SELF_REPAIR_TASK_SPEC_WRITER_GAP" -ExpectedQuestion "What internal skill helps me identify my own next missing capability?" -ExpectedSourcePath ""
  Assert-Phase156Cycle -RepoRoot $RepoRoot -TrialRoot $TrialRoot -CycleId "cycle_007" -ExpectedGap "SELF_REPAIR_TASK_SPEC_WRITER_GAP" -ExpectedSkillId "SELF_REPAIR_TASK_SPEC_WRITER_SKILL_CANDIDATE_V1" -ExpectedNextGap "SELF_PROOF_SUMMARY_GAP" -ExpectedQuestion "What internal skill helps me turn a detected gap into a repair/build task spec?" -ExpectedSourcePath "$TrialRoot/cycle_006/next_selected_gap.json"
  Assert-Phase156Cycle -RepoRoot $RepoRoot -TrialRoot $TrialRoot -CycleId "cycle_008" -ExpectedGap "SELF_PROOF_SUMMARY_GAP" -ExpectedSkillId "SELF_PROOF_SUMMARY_SKILL_CANDIDATE_V1" -ExpectedNextGap "STOP_PHASE156_CYCLE_LIMIT_REACHED" -ExpectedQuestion "What internal skill helps me summarize proof state and next allowed step?" -ExpectedSourcePath "$TrialRoot/cycle_007/next_selected_gap.json"

  $Cycle007Selection = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/cycle_007/gap_selection.json"
  Assert-Phase156ValidatorTrue -Actual $Cycle007Selection.selected_from_cycle_006_next_gap -Name "cycle007_from_cycle006"
  $Cycle008Selection = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/cycle_008/gap_selection.json"
  Assert-Phase156ValidatorTrue -Actual $Cycle008Selection.selected_from_cycle_007_next_gap -Name "cycle008_from_cycle007"

  $TrialResult = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path $TrialResultPath
  Assert-Phase156ValidatorEquals -Actual $TrialResult.cycle_count -Expected 3 -Name "trial_result_cycle_count"
  Assert-Phase156ValidatorTrue -Actual $TrialResult.all_cycles_validated -Name "trial_result_all_cycles"
  Assert-Phase156ValidatorTrue -Actual $TrialResult.self_selected_gap_trial_proven -Name "trial_result_proven"
  Assert-Phase156ValidatorFalse -Actual $TrialResult.owner_selected_each_gap -Name "trial_result_owner_selected"
  Assert-Phase156ValidatorFalse -Actual $TrialResult.codex_selected_each_gap -Name "trial_result_codex_selected"
  Assert-Phase156ValidatorTrue -Actual $TrialResult.no_codex_needed_inside_cycles -Name "trial_result_no_codex"

  $SkillIndex = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path $SkillIndexPath
  foreach ($skillId in @("SELF_GAP_INVENTORY_SKILL_CANDIDATE_V1", "SELF_REPAIR_TASK_SPEC_WRITER_SKILL_CANDIDATE_V1", "SELF_PROOF_SUMMARY_SKILL_CANDIDATE_V1")) {
    if (-not (@($SkillIndex.skill_candidates | ForEach-Object { $_.skill_id }) -contains $skillId)) {
      throw "PHASE156_VALIDATE_SKILL_INDEX_MISSING=$skillId"
    }
  }

  $RuntimeStop = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path $RuntimeStopDecisionPath
  Assert-Phase156ValidatorEquals -Actual $RuntimeStop.stop_reason -Expected "PHASE156_CYCLE_LIMIT_REACHED" -Name "stop_reason"
  Assert-Phase156ValidatorTrue -Actual $RuntimeStop.safe_stop -Name "stop_safe"
  Assert-Phase156ValidatorEquals -Actual $RuntimeStop.next_allowed_step -Expected $NextAllowedStep -Name "stop_next_allowed"

  $Result = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath
  Assert-Phase156ProofFields -Artifact $Result -Name "result"
  Assert-Phase156ProofFields -Artifact $Proof -Name "proof"

  Assert-Phase156ValidatorEquals -Actual $Report.root_cause -Expected "PHASE156 entrypoint absent" -Name "report_root_cause"
  Assert-Phase156ValidatorEquals -Actual $Report.module_path -Expected $ModulePath -Name "report_module_path"
  Assert-Phase156ValidatorEquals -Actual $Report.validator_path -Expected $ValidatorPath -Name "report_validator_path"
  Assert-Phase156ValidatorEquals -Actual $Report.exact_run_command_expected -Expected ".\modules\invoke_builder_self_selected_gap_self_build_trial_001.ps1" -Name "report_run_command"
  Assert-Phase156ValidatorEquals -Actual $Report.exact_validator_command_expected -Expected ".\validators\validate_phase156_builder_self_selected_gap_self_build_trial_v1.ps1 -RepoRoot ." -Name "report_validator_command"
  foreach ($runtimePath in ($RuntimeOutputs + @($ResultPath, $ReportPath, $ProofPath))) {
    if (-not (@($Report.runtime_output_files_created) -contains $runtimePath)) {
      throw "PHASE156_VALIDATE_REPORT_RUNTIME_OUTPUT_MISSING=$runtimePath"
    }
  }

  $Queue = Read-Phase156ValidatorJson -RepoRoot $RepoRoot -Path $QueuePath
  Assert-Phase156ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  Write-Host "PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_VALIDATE_RESULT=PASS"
  Write-Host "PHASE155_VERIFIED=True"
  Write-Host "TICKET_VERIFIED=True"
  Write-Host "CYCLE_COUNT=3"
  Write-Host "CYCLE_006_SELECTED_GAP=SELF_GAP_INVENTORY_GAP"
  Write-Host "CYCLE_006_VALIDATION_STATUS=PASS"
  Write-Host "CYCLE_007_STARTED_FROM_CYCLE_006_NEXT_GAP=True"
  Write-Host "CYCLE_007_SELECTED_GAP=SELF_REPAIR_TASK_SPEC_WRITER_GAP"
  Write-Host "CYCLE_007_VALIDATION_STATUS=PASS"
  Write-Host "CYCLE_008_STARTED_FROM_CYCLE_007_NEXT_GAP=True"
  Write-Host "CYCLE_008_SELECTED_GAP=SELF_PROOF_SUMMARY_GAP"
  Write-Host "CYCLE_008_VALIDATION_STATUS=PASS"
  Write-Host "SELF_SELECTED_GAP_TRIAL_PROVEN=True"
  Write-Host "ALL_CYCLES_VALIDATED=True"
  Write-Host "OWNER_SELECTED_EACH_GAP=False"
  Write-Host "CODEX_SELECTED_EACH_GAP=False"
  Write-Host "NO_CODEX_NEEDED_INSIDE_CYCLES=True"
  Write-Host "SAFE_STOP=True"
  Write-Host "CODEX_NEEDED_FOR_NEXT_STEP=False"
  Write-Host "QUEUE_AFTER=NONE"
  Write-Host "NEXT_ALLOWED_STEP=PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1"
} catch {
  Write-Host "PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE156_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
