param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase154ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase154ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase154ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE154_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Assert-Phase154ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE154_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase154ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE154_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase154ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE154_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase154StatusPath {
  param([string]$StatusLine)

  if ($StatusLine -match '^.. (.+)$') {
    return ($Matches[1] -replace '\\', '/')
  }
  return ($StatusLine -replace '\\', '/')
}

function Get-Phase154ExpectedValue {
  param([object]$TestCase)

  switch ($TestCase.operation) {
    "add" { return [int]$TestCase.left_operand + [int]$TestCase.right_operand }
    "subtract" { return [int]$TestCase.left_operand - [int]$TestCase.right_operand }
    "validate" {
      switch ($TestCase.base_operation) {
        "multiply" { return [int]$TestCase.left_operand * [int]$TestCase.right_operand }
        "divide" {
          if ([int]$TestCase.right_operand -eq 0) {
            throw "PHASE154_VALIDATE_DIVIDE_BY_ZERO=$($TestCase.test_id)"
          }
          return [int]([int]$TestCase.left_operand / [int]$TestCase.right_operand)
        }
        "subtract" { return [int]$TestCase.left_operand - [int]$TestCase.right_operand }
        default { throw "PHASE154_VALIDATE_UNSUPPORTED_BASE_OPERATION=$($TestCase.base_operation)" }
      }
    }
    default { throw "PHASE154_VALIDATE_UNSUPPORTED_OPERATION=$($TestCase.operation)" }
  }
}

function Assert-Phase154Cycle {
  param(
    [string]$RepoRoot,
    [string]$TrialRoot,
    [string]$CycleId,
    [string]$ExpectedGoal,
    [string]$ExpectedSkillId,
    [string]$ExpectedOperation,
    [string[]]$ExpectedExpressions,
    [string]$ExpectedNextGoal,
    [string]$ExpectedSourcePath
  )

  $Growth = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/growth_goal_selection.json"
  Assert-Phase154ValidatorEquals -Actual $Growth.selected_goal -Expected $ExpectedGoal -Name "$CycleId:selected_goal"
  Assert-Phase154ValidatorEquals -Actual $Growth.selected_skill_id -Expected $ExpectedSkillId -Name "$CycleId:selected_skill"
  Assert-Phase154ValidatorEquals -Actual $Growth.source_next_growth_goal_path -Expected $ExpectedSourcePath -Name "$CycleId:source_path"
  Assert-Phase154ValidatorFalse -Actual $Growth.owner_selected_goal -Name "$CycleId:owner_selected_goal"
  Assert-Phase154ValidatorFalse -Actual $Growth.codex_selected_goal -Name "$CycleId:codex_selected_goal"

  $Program = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/self_build_program_candidate.json"
  Assert-Phase154ValidatorEquals -Actual $Program.target_skill_id -Expected $ExpectedSkillId -Name "$CycleId:program_skill"
  Assert-Phase154ValidatorFalse -Actual $Program.arbitrary_code_execution_allowed -Name "$CycleId:program_arbitrary"

  $Skill = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/skill_candidate.json"
  Assert-Phase154ValidatorEquals -Actual $Skill.skill_id -Expected $ExpectedSkillId -Name "$CycleId:skill_id"
  Assert-Phase154ValidatorFalse -Actual $Skill.accepted_capability -Name "$CycleId:accepted_capability"

  $Tests = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/test_cases.json"
  Assert-Phase154ValidatorEquals -Actual $Tests.operation -Expected $ExpectedOperation -Name "$CycleId:operation"
  Assert-Phase154ValidatorEquals -Actual @($Tests.test_cases).Count -Expected 3 -Name "$CycleId:test_count"
  foreach ($expression in $ExpectedExpressions) {
    if (-not (@($Tests.test_cases | ForEach-Object { $_.expression }) -contains $expression)) {
      throw "PHASE154_VALIDATE_TEST_EXPRESSION_MISSING=${CycleId}:$expression"
    }
  }

  $Validation = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/skill_validation_result.json"
  Assert-Phase154ValidatorEquals -Actual $Validation.validation_status -Expected "PASS" -Name "$CycleId:validation_status"
  Assert-Phase154ValidatorTrue -Actual $Validation.independently_calculated -Name "$CycleId:independently_calculated"

  foreach ($testCase in @($Tests.test_cases)) {
    $expectedValue = Get-Phase154ExpectedValue -TestCase $testCase
    $matching = @($Validation.calculated_results | Where-Object { $_.test_id -eq $testCase.test_id })
    Assert-Phase154ValidatorEquals -Actual $matching.Count -Expected 1 -Name "$CycleId:result_match:$($testCase.test_id)"
    Assert-Phase154ValidatorEquals -Actual $matching[0].calculated_result -Expected $expectedValue -Name "$CycleId:calculated_result:$($testCase.test_id)"
    if ($ExpectedOperation -eq "validate") {
      $expectedError = ($expectedValue -ne [int]$testCase.claimed_result)
      Assert-Phase154ValidatorEquals -Actual $matching[0].error_detected -Expected $expectedError -Name "$CycleId:error_detected:$($testCase.test_id)"
      Assert-Phase154ValidatorEquals -Actual $matching[0].expected_error_detected -Expected ([bool]$testCase.error_detected) -Name "$CycleId:expected_error_detected:$($testCase.test_id)"
    }
    Assert-Phase154ValidatorTrue -Actual $matching[0].passed -Name "$CycleId:case_passed:$($testCase.test_id)"
  }

  $Next = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/next_growth_goal.json"
  Assert-Phase154ValidatorEquals -Actual $Next.next_growth_goal -Expected $ExpectedNextGoal -Name "$CycleId:next_goal"

  $Trace = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/$CycleId/cycle_trace.json"
  Assert-Phase154ValidatorEquals -Actual $Trace.selected_goal -Expected $ExpectedGoal -Name "$CycleId:trace_goal"
  Assert-Phase154ValidatorEquals -Actual $Trace.skill_id -Expected $ExpectedSkillId -Name "$CycleId:trace_skill"
  Assert-Phase154ValidatorEquals -Actual $Trace.validation_status -Expected "PASS" -Name "$CycleId:trace_validation"
  Assert-Phase154ValidatorTrue -Actual $Trace.no_codex_needed_inside_cycle -Name "$CycleId:no_codex"
}

$Pushed = $false

try {
  $StepId = "PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1"
  $RunId = "PHASE154_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_001"
  $NextAllowedStep = "PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1"
  $Phase153RunId = "PHASE153_SELF_GROWTH_DUTY_RUNTIME_IGNITION_001"
  $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
  $ExpectedHead = "f55652d"
  $TrialRoot = "living_learning_environment/self_growth_cycles/$RunId"
  $RouteAlignmentPath = "route_change_requests/PHASE154_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_ALIGNMENT_REQUEST.md"
  $ModulePath = "modules/invoke_builder_bounded_self_growth_duty_loop_trial_001.ps1"
  $ValidatorPath = "validators/validate_phase154_builder_bounded_self_growth_duty_loop_trial_v1.ps1"
  $Phase153ProofPath = "proofs/self_development/PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1.json"
  $Phase153NextPath = "living_learning_environment/self_growth_cycles/$Phase153RunId/cycle_002/next_growth_goal.json"
  $RuntimePath = "living_learning_environment/self_growth_runtime/SELF_GROWTH_DUTY_RUNTIME_V1.json"
  $CurriculumPath = "living_learning_environment/self_growth_runtime/SELF_GROWTH_CURRICULUM_V1.json"
  $SafetyPolicyPath = "living_learning_environment/self_growth_runtime/SELF_GROWTH_SAFETY_POLICY_V1.json"
  $BodyPackPath = "living_learning_environment/body/BUILDER_BODY_ORGAN_PACK_V1.json"
  $RuntimeBootPath = "$TrialRoot/runtime_boot.json"
  $Phase153ContinuationReadPath = "$TrialRoot/phase153_continuation_read.json"
  $BoundedLoopTracePath = "$TrialRoot/bounded_loop_trace.json"
  $CycleIndexPath = "$TrialRoot/cycle_index.json"
  $HeartbeatPath = "$TrialRoot/self_growth_heartbeat.json"
  $SkillIndexPath = "$TrialRoot/learned_skill_candidates_index.json"
  $SelfModelGrowthCandidatePath = "$TrialRoot/self_model_growth_candidate.json"
  $BoundedTrialResultPath = "$TrialRoot/bounded_trial_result.json"
  $RuntimeStopDecisionPath = "$TrialRoot/runtime_stop_decision.json"
  $ResultPath = "self_control/BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_RESULT.json"
  $ReportPath = "reports/self_development/PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1_REPORT.json"
  $ProofPath = "proofs/self_development/PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1.json"
  $CycleOutputNames = @("self_diagnosis.json", "growth_goal_selection.json", "internal_question.json", "internal_answer.json", "self_build_program_candidate.json", "sandbox_execution_trace.json", "skill_candidate.json", "skill_contract.json", "test_cases.json", "skill_validation_result.json", "learning_absorption_candidate.json", "next_growth_goal.json", "cycle_trace.json")
  $Cycle003Paths = @($CycleOutputNames | ForEach-Object { "$TrialRoot/cycle_003/$_" })
  $Cycle004Paths = @($CycleOutputNames | ForEach-Object { "$TrialRoot/cycle_004/$_" })
  $Cycle005Paths = @($CycleOutputNames | ForEach-Object { "$TrialRoot/cycle_005/$_" })
  $RuntimeRootOutputs = @($RuntimeBootPath, $Phase153ContinuationReadPath, $BoundedLoopTracePath, $CycleIndexPath, $HeartbeatPath, $SkillIndexPath, $SelfModelGrowthCandidatePath, $BoundedTrialResultPath, $RuntimeStopDecisionPath)
  $AllowedExact = @($RouteAlignmentPath, $ModulePath, $ValidatorPath, $ResultPath, $ReportPath, $ProofPath) + $RuntimeRootOutputs + $Cycle003Paths + $Cycle004Paths + $Cycle005Paths

  $RepoRoot = Resolve-Phase154ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot
  $Pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase154ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE154_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }
  Assert-Phase154ValidatorEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  Assert-Phase154ValidatorEquals -Actual $Head -Expected $ExpectedHead -Name "current_head"

  foreach ($requiredPath in @($RouteAlignmentPath, $ModulePath, $ValidatorPath, $Phase153ProofPath, $Phase153NextPath, $RuntimePath, $CurriculumPath, $SafetyPolicyPath, $BodyPackPath, $ResultPath, $ReportPath, $ProofPath) + $RuntimeRootOutputs + $Cycle003Paths + $Cycle004Paths + $Cycle005Paths) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase154ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE154_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $StatusLines = @(git status --short --untracked-files=all)
  foreach ($line in $StatusLines) {
    $path = Get-Phase154StatusPath -StatusLine $line
    if (-not ($AllowedExact -contains $path)) {
      throw "PHASE154_VALIDATE_CHANGE_OUTSIDE_ALLOWED_SCOPE=$line"
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
    self_control/BUILDER_SELF_GROWTH_DUTY_RUNTIME_IGNITION_RESULT.json 2>$null)
  if ($ProtectedStatus.Count -gt 0) {
    throw "PHASE154_VALIDATE_PROTECTED_SCOPE_CHANGED=$($ProtectedStatus -join '; ')"
  }

  $Phase153Proof = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $Phase153ProofPath
  Assert-Phase154ValidatorEquals -Actual $Phase153Proof.status -Expected "PASS" -Name "phase153_status"
  Assert-Phase154ValidatorTrue -Actual $Phase153Proof.self_growth_loop_proven -Name "phase153_loop_proven"
  Assert-Phase154ValidatorEquals -Actual $Phase153Proof.next_allowed_step -Expected $StepId -Name "phase153_next_allowed_step"

  $Phase153Next = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $Phase153NextPath
  Assert-Phase154ValidatorEquals -Actual $Phase153Next.next_growth_goal -Expected "learn_subtraction_basic_v1" -Name "phase153_next_goal"

  $Runtime = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $RuntimePath
  Assert-Phase154ValidatorEquals -Actual $Runtime.runtime_id -Expected "SELF_GROWTH_DUTY_RUNTIME_V1" -Name "runtime_id"

  $SafetyPolicy = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $SafetyPolicyPath
  foreach ($flag in @("external_fetch_allowed", "install_allowed", "executable_materials_allowed", "arbitrary_code_execution_allowed", "accepted_state_mutation_allowed", "accepted_memory_mutation_allowed", "accepted_self_model_mutation_allowed", "body_pack_mutation_allowed")) {
    Assert-Phase154ValidatorFalse -Actual $SafetyPolicy.$flag -Name "safety_policy_$flag"
  }

  $BodyPack = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $BodyPackPath
  Assert-Phase154ValidatorEquals -Actual $BodyPack.body_pack_id -Expected "BUILDER_BODY_ORGAN_PACK_V1" -Name "body_pack_id"

  $RuntimeBoot = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $RuntimeBootPath
  Assert-Phase154ValidatorTrue -Actual $RuntimeBoot.runtime_reused -Name "runtime_boot_reused"
  Assert-Phase154ValidatorFalse -Actual $RuntimeBoot.runtime_modified -Name "runtime_boot_modified"

  $Continuation = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $Phase153ContinuationReadPath
  Assert-Phase154ValidatorEquals -Actual $Continuation.source_next_growth_goal -Expected "learn_subtraction_basic_v1" -Name "continuation_source_goal"
  Assert-Phase154ValidatorEquals -Actual $Continuation.cycle_003_selected_goal -Expected "learn_subtraction_basic_v1" -Name "continuation_cycle003_goal"

  Assert-Phase154Cycle -RepoRoot $RepoRoot -TrialRoot $TrialRoot -CycleId "cycle_003" -ExpectedGoal "learn_subtraction_basic_v1" -ExpectedSkillId "SUBTRACTION_BASIC_SKILL_CANDIDATE_V1" -ExpectedOperation "subtract" -ExpectedExpressions @("9 - 4 = 5", "20 - 7 = 13", "56 - 8 = 48") -ExpectedNextGoal "learn_addition_consistency_v1" -ExpectedSourcePath $Phase153NextPath
  Assert-Phase154Cycle -RepoRoot $RepoRoot -TrialRoot $TrialRoot -CycleId "cycle_004" -ExpectedGoal "learn_addition_consistency_v1" -ExpectedSkillId "ADDITION_CONSISTENCY_SKILL_CANDIDATE_V1" -ExpectedOperation "add" -ExpectedExpressions @("2 + 3 = 5", "13 + 7 = 20", "48 + 8 = 56") -ExpectedNextGoal "learn_arithmetic_error_detection_v1" -ExpectedSourcePath "$TrialRoot/cycle_003/next_growth_goal.json"
  Assert-Phase154Cycle -RepoRoot $RepoRoot -TrialRoot $TrialRoot -CycleId "cycle_005" -ExpectedGoal "learn_arithmetic_error_detection_v1" -ExpectedSkillId "ARITHMETIC_ERROR_DETECTION_SKILL_CANDIDATE_V1" -ExpectedOperation "validate" -ExpectedExpressions @("2 * 3", "20 / 5", "9 - 4") -ExpectedNextGoal "STOP_CURRICULUM_ROUND_COMPLETE" -ExpectedSourcePath "$TrialRoot/cycle_004/next_growth_goal.json"

  $BoundedLoopTrace = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $BoundedLoopTracePath
  Assert-Phase154ValidatorEquals -Actual $BoundedLoopTrace.cycle_count -Expected 3 -Name "loop_trace_cycle_count"
  Assert-Phase154ValidatorTrue -Actual $BoundedLoopTrace.all_cycles_validated -Name "loop_trace_all_cycles_validated"
  Assert-Phase154ValidatorTrue -Actual $BoundedLoopTrace.safe_stop -Name "loop_trace_safe_stop"

  $CycleIndex = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $CycleIndexPath
  Assert-Phase154ValidatorEquals -Actual @($CycleIndex.cycles).Count -Expected 3 -Name "cycle_index_count"

  $Heartbeat = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $HeartbeatPath
  Assert-Phase154ValidatorTrue -Actual $Heartbeat.bounded_self_growth_trial_proven -Name "heartbeat_trial_proven"
  Assert-Phase154ValidatorTrue -Actual $Heartbeat.all_cycles_validated -Name "heartbeat_all_cycles_validated"

  $SkillIndex = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $SkillIndexPath
  Assert-Phase154ValidatorEquals -Actual $SkillIndex.skill_candidate_count -Expected 3 -Name "skill_index_count"
  Assert-Phase154ValidatorFalse -Actual $SkillIndex.accepted_capability_promotion_performed -Name "skill_index_promotion"

  $SelfModelGrowthCandidate = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $SelfModelGrowthCandidatePath
  Assert-Phase154ValidatorTrue -Actual $SelfModelGrowthCandidate.candidate_only -Name "self_model_candidate_only"
  Assert-Phase154ValidatorFalse -Actual $SelfModelGrowthCandidate.accepted_self_model_mutated -Name "self_model_mutated"

  $RuntimeStopDecision = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $RuntimeStopDecisionPath
  Assert-Phase154ValidatorTrue -Actual $RuntimeStopDecision.safe_stop -Name "stop_safe"
  Assert-Phase154ValidatorEquals -Actual $RuntimeStopDecision.stopped_after_cycle_id -Expected "cycle_005" -Name "stop_after_cycle"

  $BoundedTrialResult = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $BoundedTrialResultPath
  $Result = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath

  foreach ($artifact in @($BoundedTrialResult, $Result, $Report, $Proof)) {
    Assert-Phase154ValidatorEquals -Actual $artifact.status -Expected "PASS" -Name "artifact_status"
    Assert-Phase154ValidatorEquals -Actual $artifact.step_id -Expected $StepId -Name "artifact_step_id"
    Assert-Phase154ValidatorEquals -Actual $artifact.run_id -Expected $RunId -Name "artifact_run_id"
    Assert-Phase154ValidatorEquals -Actual $artifact.next_allowed_step -Expected $NextAllowedStep -Name "artifact_next_allowed_step"
  }

  foreach ($artifact in @($BoundedTrialResult, $Result, $Proof)) {
    Assert-Phase154ValidatorTrue -Actual $artifact.phase153_verified -Name "artifact_phase153_verified"
    Assert-Phase154ValidatorTrue -Actual $artifact.phase153_self_growth_loop_proven -Name "artifact_phase153_loop"
    Assert-Phase154ValidatorTrue -Actual $artifact.runtime_reused -Name "artifact_runtime_reused"
    Assert-Phase154ValidatorFalse -Actual $artifact.runtime_modified -Name "artifact_runtime_modified"
    Assert-Phase154ValidatorTrue -Actual $artifact.body_pack_verified -Name "artifact_body_pack_verified"
    Assert-Phase154ValidatorFalse -Actual $artifact.body_pack_mutated -Name "artifact_body_pack_mutated"
    Assert-Phase154ValidatorEquals -Actual $artifact.cycle_count -Expected 3 -Name "artifact_cycle_count"
    Assert-Phase154ValidatorTrue -Actual $artifact.cycle_003_started -Name "artifact_cycle003_started"
    Assert-Phase154ValidatorTrue -Actual $artifact.cycle_003_started_from_phase153_next_goal -Name "artifact_cycle003_from_phase153"
    Assert-Phase154ValidatorEquals -Actual $artifact.cycle_003_selected_goal -Expected "learn_subtraction_basic_v1" -Name "artifact_cycle003_goal"
    Assert-Phase154ValidatorEquals -Actual $artifact.cycle_003_skill_id -Expected "SUBTRACTION_BASIC_SKILL_CANDIDATE_V1" -Name "artifact_cycle003_skill"
    Assert-Phase154ValidatorEquals -Actual $artifact.cycle_003_validation_status -Expected "PASS" -Name "artifact_cycle003_validation"
    Assert-Phase154ValidatorEquals -Actual $artifact.cycle_003_next_growth_goal -Expected "learn_addition_consistency_v1" -Name "artifact_cycle003_next"
    Assert-Phase154ValidatorTrue -Actual $artifact.cycle_004_started -Name "artifact_cycle004_started"
    Assert-Phase154ValidatorTrue -Actual $artifact.cycle_004_started_from_cycle_003_next_goal -Name "artifact_cycle004_from_cycle003"
    Assert-Phase154ValidatorEquals -Actual $artifact.cycle_004_selected_goal -Expected "learn_addition_consistency_v1" -Name "artifact_cycle004_goal"
    Assert-Phase154ValidatorEquals -Actual $artifact.cycle_004_skill_id -Expected "ADDITION_CONSISTENCY_SKILL_CANDIDATE_V1" -Name "artifact_cycle004_skill"
    Assert-Phase154ValidatorEquals -Actual $artifact.cycle_004_validation_status -Expected "PASS" -Name "artifact_cycle004_validation"
    Assert-Phase154ValidatorEquals -Actual $artifact.cycle_004_next_growth_goal -Expected "learn_arithmetic_error_detection_v1" -Name "artifact_cycle004_next"
    Assert-Phase154ValidatorTrue -Actual $artifact.cycle_005_started -Name "artifact_cycle005_started"
    Assert-Phase154ValidatorTrue -Actual $artifact.cycle_005_started_from_cycle_004_next_goal -Name "artifact_cycle005_from_cycle004"
    Assert-Phase154ValidatorEquals -Actual $artifact.cycle_005_selected_goal -Expected "learn_arithmetic_error_detection_v1" -Name "artifact_cycle005_goal"
    Assert-Phase154ValidatorEquals -Actual $artifact.cycle_005_skill_id -Expected "ARITHMETIC_ERROR_DETECTION_SKILL_CANDIDATE_V1" -Name "artifact_cycle005_skill"
    Assert-Phase154ValidatorEquals -Actual $artifact.cycle_005_validation_status -Expected "PASS" -Name "artifact_cycle005_validation"
    Assert-Phase154ValidatorTrue -Actual $artifact.bounded_self_growth_trial_proven -Name "artifact_trial_proven"
    Assert-Phase154ValidatorFalse -Actual $artifact.owner_selected_each_goal -Name "artifact_owner_selected"
    Assert-Phase154ValidatorFalse -Actual $artifact.codex_selected_each_goal -Name "artifact_codex_selected"
    Assert-Phase154ValidatorTrue -Actual $artifact.all_cycles_validated -Name "artifact_all_cycles_validated"
    Assert-Phase154ValidatorTrue -Actual $artifact.no_codex_needed_inside_cycles -Name "artifact_no_codex"
    Assert-Phase154ValidatorTrue -Actual $artifact.learned_skill_candidates_index_created -Name "artifact_skill_index_created"
    Assert-Phase154ValidatorTrue -Actual $artifact.self_model_growth_candidate_created -Name "artifact_self_model_created"
    Assert-Phase154ValidatorTrue -Actual $artifact.runtime_stop_decision_created -Name "artifact_stop_created"
    Assert-Phase154ValidatorTrue -Actual $artifact.safe_stop -Name "artifact_safe_stop"
    Assert-Phase154ValidatorFalse -Actual $artifact.codex_needed_for_next_step -Name "artifact_codex_needed_next"
    foreach ($flag in @("external_fetch_performed", "dependency_install_performed", "executable_materials_used", "arbitrary_code_execution_used", "accepted_state_mutated", "accepted_memory_mutated", "accepted_self_model_mutated", "external_agents_created", "orchestrator_changed", "route_lock_changed", "current_runtime_changed", "capability_shelf_mutated")) {
      Assert-Phase154ValidatorFalse -Actual $artifact.$flag -Name "artifact_$flag"
    }
    Assert-Phase154ValidatorEquals -Actual $artifact.trusted_source_count -Expected 0 -Name "artifact_trusted_source_count"
    Assert-Phase154ValidatorEquals -Actual $artifact.queue_after -Expected "NONE" -Name "artifact_queue_after"
  }

  Assert-Phase154ValidatorEquals -Actual $Report.root_cause_found -Expected "The previous PHASE154 module defined functions only; running .\modules\invoke_builder_bounded_self_growth_duty_loop_trial_001.ps1 returned exit code 0 after parsing but never invoked Invoke-BuilderBoundedSelfGrowthDutyLoopTrial001." -Name "report_root_cause"
  Assert-Phase154ValidatorEquals -Actual $Report.expected_run_command -Expected ".\modules\invoke_builder_bounded_self_growth_duty_loop_trial_001.ps1" -Name "report_run_command"
  Assert-Phase154ValidatorEquals -Actual $Report.expected_validator_command -Expected ".\validators\validate_phase154_builder_bounded_self_growth_duty_loop_trial_v1.ps1 -RepoRoot ." -Name "report_validator_command"
  foreach ($runtimePath in ($RuntimeRootOutputs + $Cycle003Paths + $Cycle004Paths + $Cycle005Paths + @($ResultPath, $ReportPath, $ProofPath))) {
    if (-not (@($Report.runtime_output_files_created) -contains $runtimePath)) {
      throw "PHASE154_VALIDATE_REPORT_RUNTIME_OUTPUT_MISSING=$runtimePath"
    }
  }

  $Queue = Read-Phase154ValidatorJson -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
  Assert-Phase154ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  Write-Host "PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_VALIDATE_RESULT=PASS"
  Write-Host "RUNTIME_OUTPUTS_CREATED_BY_MODULE=True"
  Write-Host "CYCLE_COUNT=3"
  Write-Host "CYCLE_003_STARTED_FROM_PHASE153_NEXT_GOAL=True"
  Write-Host "CYCLE_003_SELECTED_GOAL=learn_subtraction_basic_v1"
  Write-Host "CYCLE_003_SKILL_ID=SUBTRACTION_BASIC_SKILL_CANDIDATE_V1"
  Write-Host "CYCLE_003_VALIDATION_STATUS=PASS"
  Write-Host "CYCLE_003_NEXT_GROWTH_GOAL=learn_addition_consistency_v1"
  Write-Host "CYCLE_004_STARTED_FROM_CYCLE_003_NEXT_GOAL=True"
  Write-Host "CYCLE_004_SELECTED_GOAL=learn_addition_consistency_v1"
  Write-Host "CYCLE_004_SKILL_ID=ADDITION_CONSISTENCY_SKILL_CANDIDATE_V1"
  Write-Host "CYCLE_004_VALIDATION_STATUS=PASS"
  Write-Host "CYCLE_004_NEXT_GROWTH_GOAL=learn_arithmetic_error_detection_v1"
  Write-Host "CYCLE_005_STARTED_FROM_CYCLE_004_NEXT_GOAL=True"
  Write-Host "CYCLE_005_SELECTED_GOAL=learn_arithmetic_error_detection_v1"
  Write-Host "CYCLE_005_SKILL_ID=ARITHMETIC_ERROR_DETECTION_SKILL_CANDIDATE_V1"
  Write-Host "CYCLE_005_VALIDATION_STATUS=PASS"
  Write-Host "BOUNDED_SELF_GROWTH_TRIAL_PROVEN=True"
  Write-Host "ALL_CYCLES_VALIDATED=True"
  Write-Host "NO_CODEX_NEEDED_INSIDE_CYCLES=True"
  Write-Host "ACCEPTED_STATE_MUTATED=False"
  Write-Host "ACCEPTED_MEMORY_MUTATED=False"
  Write-Host "ACCEPTED_SELF_MODEL_MUTATED=False"
  Write-Host "EXTERNAL_FETCH_PERFORMED=False"
  Write-Host "DEPENDENCY_INSTALL_PERFORMED=False"
  Write-Host "ARBITRARY_CODE_EXECUTION_USED=False"
  Write-Host "SAFE_STOP=True"
  Write-Host "QUEUE_AFTER=NONE"
  Write-Host "NEXT_ALLOWED_STEP=PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1"
} catch {
  Write-Host "PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE154_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
