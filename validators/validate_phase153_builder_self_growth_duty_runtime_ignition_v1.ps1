param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase153ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase153ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase153ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE153_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Assert-Phase153ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE153_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase153ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE153_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase153ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE153_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase153StatusPath {
  param([string]$StatusLine)

  if ($StatusLine -match '^.. (.+)$') {
    return ($Matches[1] -replace '\\', '/')
  }
  return ($StatusLine -replace '\\', '/')
}

function Get-Phase153ArithmeticResult {
  param([object]$TestCase)

  switch ($TestCase.operation) {
    "multiply" { return [int]$TestCase.left_operand * [int]$TestCase.right_operand }
    "divide" {
      if ([int]$TestCase.right_operand -eq 0) {
        throw "PHASE153_VALIDATE_DIVIDE_BY_ZERO=$($TestCase.test_id)"
      }
      return [int]$TestCase.left_operand / [int]$TestCase.right_operand
    }
    default { throw "PHASE153_VALIDATE_UNSUPPORTED_OPERATION=$($TestCase.operation)" }
  }
}

function Assert-Phase153ArithmeticCases {
  param(
    [object]$TestCaseFile,
    [object]$ValidationFile,
    [string]$ExpectedOperation,
    [string[]]$ExpectedExpressions,
    [string]$Name
  )

  Assert-Phase153ValidatorEquals -Actual $TestCaseFile.status -Expected "PASS" -Name "${Name}:test_cases_status"
  Assert-Phase153ValidatorEquals -Actual $TestCaseFile.operation -Expected $ExpectedOperation -Name "${Name}:test_cases_operation"
  Assert-Phase153ValidatorEquals -Actual @($TestCaseFile.test_cases).Count -Expected 3 -Name "${Name}:test_case_count"
  foreach ($expectedExpression in $ExpectedExpressions) {
    if (-not (@($TestCaseFile.test_cases | ForEach-Object { $_.expression }) -contains $expectedExpression)) {
      throw "PHASE153_VALIDATE_TEST_EXPRESSION_MISSING=${Name}:$expectedExpression"
    }
  }

  $calculated = @()
  foreach ($testCase in @($TestCaseFile.test_cases)) {
    $actual = Get-Phase153ArithmeticResult -TestCase $testCase
    if ($actual -ne [int]$testCase.expected_result) {
      throw "PHASE153_VALIDATE_ARITHMETIC_FAIL=${Name}:$($testCase.expression):actual=$actual"
    }
    $calculated += [ordered]@{
      test_id = $testCase.test_id
      calculated_result = $actual
    }
  }

  Assert-Phase153ValidatorEquals -Actual $ValidationFile.status -Expected "PASS" -Name "${Name}:validation_file_status"
  Assert-Phase153ValidatorEquals -Actual $ValidationFile.validation_status -Expected "PASS" -Name "${Name}:validation_status"
  Assert-Phase153ValidatorTrue -Actual $ValidationFile.independently_calculated -Name "${Name}:independently_calculated"
  foreach ($item in $calculated) {
    $matching = @($ValidationFile.calculated_results | Where-Object { $_.test_id -eq $item.test_id })
    Assert-Phase153ValidatorEquals -Actual $matching.Count -Expected 1 -Name "${Name}:validation_result_match_count"
    Assert-Phase153ValidatorEquals -Actual $matching[0].calculated_result -Expected $item.calculated_result -Name "${Name}:validation_calculated_result"
    Assert-Phase153ValidatorTrue -Actual $matching[0].passed -Name "${Name}:validation_result_passed"
  }
}

try {
  $StepId = "PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1"
  $RunId = "PHASE153_SELF_GROWTH_DUTY_RUNTIME_IGNITION_001"
  $NextAllowedStep = "PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1"
  $RuntimeRoot = "living_learning_environment/self_growth_runtime"
  $CycleRoot = "living_learning_environment/self_growth_cycles/$RunId"
  $RouteAlignmentPath = "route_change_requests/PHASE153_SELF_GROWTH_DUTY_RUNTIME_IGNITION_ALIGNMENT_REQUEST.md"
  $RuntimePath = "$RuntimeRoot/SELF_GROWTH_DUTY_RUNTIME_V1.json"
  $RuntimeContractPath = "$RuntimeRoot/SELF_GROWTH_DUTY_RUNTIME_CONTRACT_V1.json"
  $CurriculumPath = "$RuntimeRoot/SELF_GROWTH_CURRICULUM_V1.json"
  $DeclarativeSkillFactoryPath = "$RuntimeRoot/DECLARATIVE_SKILL_FACTORY_V1.json"
  $BodyPackAdapterPath = "$RuntimeRoot/BODY_PACK_ADAPTER_V1.json"
  $SafetyPolicyPath = "$RuntimeRoot/SELF_GROWTH_SAFETY_POLICY_V1.json"
  $Phase152ProofPath = "proofs/self_development/PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1.json"
  $Phase152ResultPath = "self_control/BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_RESULT.json"
  $Phase152ReportPath = "reports/self_development/PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1_REPORT.json"
  $BodyPackPath = "living_learning_environment/body/BUILDER_BODY_ORGAN_PACK_V1.json"
  $BodyRegistryPath = "living_learning_environment/body/body_registry.json"
  $BodyPolicyPath = "living_learning_environment/body/body_policy.json"
  $BodyRuntimeContractPath = "living_learning_environment/body/body_runtime_contract.json"
  $BodySafetyBoundariesPath = "living_learning_environment/body/body_safety_boundaries.json"
  $BodyPortabilityManifestPath = "living_learning_environment/body/body_portability_manifest.json"
  $SourcePolicyPath = "source_registry/source_policy.json"
  $TrustedSourcesPath = "source_registry/trusted_sources.json"
  $RuntimeBootPath = "$CycleRoot/runtime_boot.json"
  $RuntimeTracePath = "$CycleRoot/self_growth_runtime_trace.json"
  $BodyPackUsageTracePath = "$CycleRoot/body_pack_usage_trace.json"
  $CycleIndexPath = "$CycleRoot/cycle_index.json"
  $HeartbeatPath = "$CycleRoot/self_growth_heartbeat.json"
  $SkillIndexPath = "$CycleRoot/learned_skill_candidates_index.json"
  $SelfModelGrowthCandidatePath = "$CycleRoot/self_model_growth_candidate.json"
  $DutyLoopReadinessPath = "$CycleRoot/bounded_duty_loop_readiness.json"
  $RuntimeStopDecisionPath = "$CycleRoot/runtime_stop_decision.json"
  $ResultPath = "self_control/BUILDER_SELF_GROWTH_DUTY_RUNTIME_IGNITION_RESULT.json"
  $ReportPath = "reports/self_development/PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1_REPORT.json"
  $ProofPath = "proofs/self_development/PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1.json"

  $RuntimeArchitecturePaths = @($RouteAlignmentPath, $RuntimePath, $RuntimeContractPath, $CurriculumPath, $DeclarativeSkillFactoryPath, $BodyPackAdapterPath, $SafetyPolicyPath)
  $CycleRootOutputs = @($RuntimeBootPath, $RuntimeTracePath, $BodyPackUsageTracePath, $CycleIndexPath, $HeartbeatPath, $SkillIndexPath, $SelfModelGrowthCandidatePath, $DutyLoopReadinessPath, $RuntimeStopDecisionPath)
  $CycleOutputNames = @("self_diagnosis.json","growth_goal_selection.json","internal_question.json","internal_answer.json","self_build_program_candidate.json","sandbox_execution_trace.json","skill_candidate.json","skill_contract.json","test_cases.json","skill_validation_result.json","learning_absorption_candidate.json","next_growth_goal.json","cycle_trace.json")
  $Cycle001Paths = @($CycleOutputNames | ForEach-Object { "$CycleRoot/cycle_001/$_" })
  $Cycle002Paths = @($CycleOutputNames | ForEach-Object { "$CycleRoot/cycle_002/$_" })
  $AllowedExact = $RuntimeArchitecturePaths + @(
    "modules/invoke_builder_self_growth_duty_runtime_ignition_001.ps1",
    "validators/validate_phase153_builder_self_growth_duty_runtime_ignition_v1.ps1",
    $ResultPath,
    $ReportPath,
    $ProofPath
  ) + $CycleRootOutputs + $Cycle001Paths + $Cycle002Paths

  $RepoRoot = Resolve-Phase153ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot

  foreach ($identityFile in @(
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1"
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase153ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE153_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }

  foreach ($requiredPath in @(
    $Phase152ProofPath,
    $Phase152ResultPath,
    $Phase152ReportPath,
    $BodyPackPath,
    $BodyRegistryPath,
    $BodyPolicyPath,
    $BodyRuntimeContractPath,
    $BodySafetyBoundariesPath,
    $BodyPortabilityManifestPath,
    $SourcePolicyPath,
    $TrustedSourcesPath,
    $ResultPath,
    $ReportPath,
    $ProofPath
  ) + $AllowedExact) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase153ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE153_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $StatusLines = @(git status --short --untracked-files=all)
  foreach ($line in $StatusLines) {
    $path = Get-Phase153StatusPath -StatusLine $line
    if (-not ($AllowedExact -contains $path)) {
      throw "PHASE153_VALIDATE_CHANGE_OUTSIDE_ALLOWED_SCOPE=$line"
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
    proofs/self_development/PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1.json `
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
    self_control/BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_RESULT.json 2>$null)
  if ($ProtectedStatus.Count -gt 0) {
    throw "PHASE153_VALIDATE_PROTECTED_SCOPE_CHANGED=$($ProtectedStatus -join '; ')"
  }

  $Phase152Proof = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $Phase152ProofPath
  Assert-Phase153ValidatorEquals -Actual $Phase152Proof.status -Expected "PASS" -Name "phase152_status"
  Assert-Phase153ValidatorEquals -Actual $Phase152Proof.next_allowed_step -Expected $StepId -Name "phase152_next_allowed_step"
  Assert-Phase153ValidatorEquals -Actual $Phase152Proof.body_organ_count -Expected 24 -Name "phase152_body_organ_count"

  $BodyRegistry = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $BodyRegistryPath
  Assert-Phase153ValidatorEquals -Actual $BodyRegistry.body_organ_count -Expected 24 -Name "body_registry_count"
  $BodyPack = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $BodyPackPath
  Assert-Phase153ValidatorEquals -Actual $BodyPack.body_pack_id -Expected "BUILDER_BODY_ORGAN_PACK_V1" -Name "body_pack_id"

  $Runtime = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $RuntimePath
  Assert-Phase153ValidatorEquals -Actual $Runtime.status -Expected "PASS" -Name "runtime_status"
  Assert-Phase153ValidatorEquals -Actual $Runtime.runtime_id -Expected "SELF_GROWTH_DUTY_RUNTIME_V1" -Name "runtime_id"
  Assert-Phase153ValidatorEquals -Actual $Runtime.bounded_cycle_limit -Expected 2 -Name "runtime_cycle_limit"
  foreach ($component in @("self_diagnosis_engine","growth_goal_selector","internal_question_engine_adapter","internal_answer_search_adapter","self_build_program_writer","declarative_skill_factory","sandbox_executor_adapter","skill_validator","learning_absorber","next_growth_goal_selector","bounded_cycle_controller","safe_stop_controller")) {
    if (-not (@($Runtime.declared_components) -contains $component)) {
      throw "PHASE153_VALIDATE_RUNTIME_COMPONENT_MISSING=$component"
    }
  }

  $RuntimeContract = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $RuntimeContractPath
  Assert-Phase153ValidatorEquals -Actual $RuntimeContract.cycle_limit -Expected 2 -Name "runtime_contract_cycle_limit"
  foreach ($flag in @("external_fetch_allowed","install_allowed","arbitrary_code_execution_allowed","executable_materials_allowed","accepted_state_mutation_allowed","accepted_memory_mutation_allowed","accepted_self_model_mutation_allowed","capability_shelf_mutation_allowed","generated_agents_allowed","applied_agents_allowed","body_pack_mutation_allowed")) {
    Assert-Phase153ValidatorFalse -Actual $RuntimeContract.$flag -Name "runtime_contract_$flag"
  }

  $Curriculum = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $CurriculumPath
  Assert-Phase153ValidatorEquals -Actual @($Curriculum.goals).Count -Expected 5 -Name "curriculum_goal_count"
  foreach ($goalId in @("learn_multiplication_basic_v1","learn_division_basic_v1","learn_subtraction_basic_v1","learn_addition_consistency_v1","learn_arithmetic_error_detection_v1")) {
    if (-not (@($Curriculum.goals | ForEach-Object { $_.goal_id }) -contains $goalId)) {
      throw "PHASE153_VALIDATE_CURRICULUM_GOAL_MISSING=$goalId"
    }
  }

  $Factory = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $DeclarativeSkillFactoryPath
  Assert-Phase153ValidatorEquals -Actual $Factory.execution_mode -Expected "declarative_json_only" -Name "factory_execution_mode"
  Assert-Phase153ValidatorFalse -Actual $Factory.arbitrary_code_execution_allowed -Name "factory_arbitrary_code_execution_allowed"

  $Adapter = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $BodyPackAdapterPath
  Assert-Phase153ValidatorEquals -Actual $Adapter.body_pack_id -Expected "BUILDER_BODY_ORGAN_PACK_V1" -Name "adapter_body_pack_id"
  Assert-Phase153ValidatorFalse -Actual $Adapter.body_pack_mutation_allowed -Name "adapter_body_pack_mutation_allowed"

  $SafetyPolicy = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $SafetyPolicyPath
  foreach ($flag in @("external_fetch_allowed","install_allowed","executable_materials_allowed","arbitrary_code_execution_allowed","accepted_state_mutation_allowed","accepted_memory_mutation_allowed","accepted_self_model_mutation_allowed","external_agents_allowed","capability_shelf_mutation_allowed","body_pack_mutation_allowed")) {
    Assert-Phase153ValidatorFalse -Actual $SafetyPolicy.$flag -Name "safety_policy_$flag"
  }
  Assert-Phase153ValidatorEquals -Actual $SafetyPolicy.trusted_source_count_required -Expected 0 -Name "safety_policy_trusted_source_count_required"

  $RuntimeBoot = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $RuntimeBootPath
  Assert-Phase153ValidatorTrue -Actual $RuntimeBoot.runtime_started -Name "runtime_boot_started"
  Assert-Phase153ValidatorEquals -Actual $RuntimeBoot.cycle_limit -Expected 2 -Name "runtime_boot_cycle_limit"

  $RuntimeTrace = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $RuntimeTracePath
  Assert-Phase153ValidatorTrue -Actual $RuntimeTrace.runtime_started -Name "runtime_trace_started"
  Assert-Phase153ValidatorEquals -Actual $RuntimeTrace.cycle_count -Expected 2 -Name "runtime_trace_cycle_count"
  Assert-Phase153ValidatorTrue -Actual $RuntimeTrace.cycle_002_started_from_cycle_001_next_goal -Name "runtime_trace_cycle2_from_cycle1"

  $BodyPackUsageTrace = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $BodyPackUsageTracePath
  Assert-Phase153ValidatorTrue -Actual $BodyPackUsageTrace.body_pack_verified -Name "body_pack_usage_verified"
  Assert-Phase153ValidatorFalse -Actual $BodyPackUsageTrace.body_pack_mutated -Name "body_pack_usage_mutated"

  $CycleIndex = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $CycleIndexPath
  Assert-Phase153ValidatorEquals -Actual $CycleIndex.cycle_count -Expected 2 -Name "cycle_index_count"

  $Cycle001GrowthGoal = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_001/growth_goal_selection.json"
  Assert-Phase153ValidatorEquals -Actual $Cycle001GrowthGoal.selected_goal -Expected "learn_multiplication_basic_v1" -Name "cycle001_selected_goal"
  Assert-Phase153ValidatorFalse -Actual $Cycle001GrowthGoal.owner_selected_goal -Name "cycle001_owner_selected_goal"
  Assert-Phase153ValidatorFalse -Actual $Cycle001GrowthGoal.codex_selected_goal -Name "cycle001_codex_selected_goal"

  $Cycle001Question = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_001/internal_question.json"
  Assert-Phase153ValidatorEquals -Actual $Cycle001Question.question -Expected "What bounded self-growth skill should I build first to prove my learning loop?" -Name "cycle001_question"

  $Cycle001Program = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_001/self_build_program_candidate.json"
  Assert-Phase153ValidatorEquals -Actual $Cycle001Program.target_skill_id -Expected "MULTIPLICATION_BASIC_SKILL_CANDIDATE_V1" -Name "cycle001_program_skill"

  $Cycle001Skill = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_001/skill_candidate.json"
  Assert-Phase153ValidatorEquals -Actual $Cycle001Skill.skill_id -Expected "MULTIPLICATION_BASIC_SKILL_CANDIDATE_V1" -Name "cycle001_skill_id"
  Assert-Phase153ValidatorFalse -Actual $Cycle001Skill.accepted_capability -Name "cycle001_skill_accepted_capability"

  $Cycle001Tests = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_001/test_cases.json"
  $Cycle001Validation = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_001/skill_validation_result.json"
  Assert-Phase153ArithmeticCases -TestCaseFile $Cycle001Tests -ValidationFile $Cycle001Validation -ExpectedOperation "multiply" -ExpectedExpressions @("2 * 3 = 6","4 * 5 = 20","7 * 8 = 56") -Name "cycle001"

  $Cycle001Absorption = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_001/learning_absorption_candidate.json"
  Assert-Phase153ValidatorEquals -Actual $Cycle001Absorption.absorption_status -Expected "CANDIDATE_NOT_ACCEPTED" -Name "cycle001_absorption_status"

  $Cycle001NextGoal = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_001/next_growth_goal.json"
  Assert-Phase153ValidatorEquals -Actual $Cycle001NextGoal.next_growth_goal -Expected "learn_division_basic_v1" -Name "cycle001_next_growth_goal"

  $Cycle001Trace = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_001/cycle_trace.json"
  Assert-Phase153ValidatorTrue -Actual $Cycle001Trace.executed -Name "cycle001_trace_executed"
  Assert-Phase153ValidatorEquals -Actual $Cycle001Trace.validation_status -Expected "PASS" -Name "cycle001_trace_validation_status"

  $Cycle002GrowthGoal = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_002/growth_goal_selection.json"
  Assert-Phase153ValidatorTrue -Actual $Cycle002GrowthGoal.selected_from_cycle_001_next_goal -Name "cycle002_selected_from_cycle001"
  Assert-Phase153ValidatorEquals -Actual $Cycle002GrowthGoal.source_next_growth_goal_path -Expected "$CycleRoot/cycle_001/next_growth_goal.json" -Name "cycle002_source_next_goal_path"
  Assert-Phase153ValidatorEquals -Actual $Cycle002GrowthGoal.selected_goal -Expected $Cycle001NextGoal.next_growth_goal -Name "cycle002_selected_goal_from_cycle001"
  Assert-Phase153ValidatorEquals -Actual $Cycle002GrowthGoal.selected_goal -Expected "learn_division_basic_v1" -Name "cycle002_selected_goal"
  Assert-Phase153ValidatorFalse -Actual $Cycle002GrowthGoal.owner_selected_goal -Name "cycle002_owner_selected_goal"
  Assert-Phase153ValidatorFalse -Actual $Cycle002GrowthGoal.codex_selected_goal -Name "cycle002_codex_selected_goal"

  $Cycle002Question = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_002/internal_question.json"
  Assert-Phase153ValidatorEquals -Actual $Cycle002Question.question -Expected "What bounded follow-up skill should I build after multiplication_basic validated?" -Name "cycle002_question"

  $Cycle002Program = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_002/self_build_program_candidate.json"
  Assert-Phase153ValidatorEquals -Actual $Cycle002Program.target_skill_id -Expected "DIVISION_BASIC_SKILL_CANDIDATE_V1" -Name "cycle002_program_skill"

  $Cycle002Skill = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_002/skill_candidate.json"
  Assert-Phase153ValidatorEquals -Actual $Cycle002Skill.skill_id -Expected "DIVISION_BASIC_SKILL_CANDIDATE_V1" -Name "cycle002_skill_id"
  Assert-Phase153ValidatorFalse -Actual $Cycle002Skill.accepted_capability -Name "cycle002_skill_accepted_capability"

  $Cycle002Tests = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_002/test_cases.json"
  $Cycle002Validation = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_002/skill_validation_result.json"
  Assert-Phase153ArithmeticCases -TestCaseFile $Cycle002Tests -ValidationFile $Cycle002Validation -ExpectedOperation "divide" -ExpectedExpressions @("6 / 3 = 2","20 / 5 = 4","56 / 8 = 7") -Name "cycle002"

  $Cycle002Absorption = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_002/learning_absorption_candidate.json"
  Assert-Phase153ValidatorEquals -Actual $Cycle002Absorption.absorption_status -Expected "CANDIDATE_NOT_ACCEPTED" -Name "cycle002_absorption_status"

  $Cycle002NextGoal = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_002/next_growth_goal.json"
  Assert-Phase153ValidatorEquals -Actual $Cycle002NextGoal.next_growth_goal -Expected "learn_subtraction_basic_v1" -Name "cycle002_next_growth_goal"

  $Cycle002Trace = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "$CycleRoot/cycle_002/cycle_trace.json"
  Assert-Phase153ValidatorTrue -Actual $Cycle002Trace.started_from_cycle_001_next_goal -Name "cycle002_trace_started_from_cycle001"
  Assert-Phase153ValidatorTrue -Actual $Cycle002Trace.executed -Name "cycle002_trace_executed"
  Assert-Phase153ValidatorEquals -Actual $Cycle002Trace.validation_status -Expected "PASS" -Name "cycle002_trace_validation_status"

  $Heartbeat = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $HeartbeatPath
  Assert-Phase153ValidatorTrue -Actual $Heartbeat.runtime_started -Name "heartbeat_runtime_started"
  Assert-Phase153ValidatorEquals -Actual $Heartbeat.cycle_count -Expected 2 -Name "heartbeat_cycle_count"
  Assert-Phase153ValidatorTrue -Actual $Heartbeat.cycle_001_completed -Name "heartbeat_cycle001_completed"
  Assert-Phase153ValidatorTrue -Actual $Heartbeat.cycle_002_started_from_cycle_001_next_goal -Name "heartbeat_cycle002_from_cycle001"
  Assert-Phase153ValidatorTrue -Actual $Heartbeat.cycle_002_completed -Name "heartbeat_cycle002_completed"
  Assert-Phase153ValidatorTrue -Actual $Heartbeat.self_growth_loop_proven -Name "heartbeat_loop_proven"
  Assert-Phase153ValidatorFalse -Actual $Heartbeat.owner_selected_each_goal -Name "heartbeat_owner_selected_each_goal"
  Assert-Phase153ValidatorFalse -Actual $Heartbeat.codex_selected_each_goal -Name "heartbeat_codex_selected_each_goal"
  Assert-Phase153ValidatorFalse -Actual $Heartbeat.accepted_state_mutated -Name "heartbeat_accepted_state_mutated"

  $SkillIndex = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $SkillIndexPath
  Assert-Phase153ValidatorEquals -Actual $SkillIndex.skill_candidate_count -Expected 2 -Name "skill_index_count"
  if (-not (@($SkillIndex.skill_candidates | ForEach-Object { $_.skill_id }) -contains "MULTIPLICATION_BASIC_SKILL_CANDIDATE_V1")) {
    throw "PHASE153_VALIDATE_SKILL_INDEX_MISSING_MULTIPLICATION"
  }
  if (-not (@($SkillIndex.skill_candidates | ForEach-Object { $_.skill_id }) -contains "DIVISION_BASIC_SKILL_CANDIDATE_V1")) {
    throw "PHASE153_VALIDATE_SKILL_INDEX_MISSING_DIVISION"
  }
  Assert-Phase153ValidatorFalse -Actual $SkillIndex.accepted_capability_promotion_performed -Name "skill_index_accepted_promotion"

  $SelfModelGrowthCandidate = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $SelfModelGrowthCandidatePath
  Assert-Phase153ValidatorEquals -Actual $SelfModelGrowthCandidate.new_candidate_skills_count -Expected 2 -Name "self_model_candidate_skill_count"
  Assert-Phase153ValidatorFalse -Actual $SelfModelGrowthCandidate.accepted_self_model_mutated -Name "self_model_accepted_mutated"

  $DutyLoopReadiness = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $DutyLoopReadinessPath
  Assert-Phase153ValidatorTrue -Actual $DutyLoopReadiness.ready_for_phase154_bounded_trial -Name "duty_loop_ready_phase154"
  Assert-Phase153ValidatorEquals -Actual $DutyLoopReadiness.recommended_cycle_limit -Expected 3 -Name "duty_loop_recommended_cycle_limit"
  Assert-Phase153ValidatorTrue -Actual $DutyLoopReadiness.no_codex_needed_for_phase154_trial -Name "duty_loop_no_codex_phase154"
  Assert-Phase153ValidatorFalse -Actual $DutyLoopReadiness.codex_needed_for_next_step -Name "duty_loop_codex_needed_next"

  $RuntimeStopDecision = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $RuntimeStopDecisionPath
  Assert-Phase153ValidatorEquals -Actual $RuntimeStopDecision.stop_reason -Expected "PHASE153_CYCLE_LIMIT_REACHED" -Name "stop_reason"
  Assert-Phase153ValidatorTrue -Actual $RuntimeStopDecision.safe_stop -Name "safe_stop"
  Assert-Phase153ValidatorEquals -Actual $RuntimeStopDecision.next_allowed_step -Expected $NextAllowedStep -Name "stop_next_allowed_step"

  $Result = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath
  foreach ($artifact in @($Result, $Report, $Proof)) {
    Assert-Phase153ValidatorEquals -Actual $artifact.status -Expected "PASS" -Name "artifact_status"
    Assert-Phase153ValidatorEquals -Actual $artifact.step_id -Expected $StepId -Name "artifact_step_id"
    Assert-Phase153ValidatorEquals -Actual $artifact.run_id -Expected $RunId -Name "artifact_run_id"
    Assert-Phase153ValidatorEquals -Actual $artifact.next_allowed_step -Expected $NextAllowedStep -Name "artifact_next_allowed_step"
  }

  foreach ($artifact in @($Result, $Proof)) {
    Assert-Phase153ValidatorTrue -Actual $artifact.phase152_verified -Name "phase152_verified"
    Assert-Phase153ValidatorTrue -Actual $artifact.body_pack_verified -Name "body_pack_verified"
    Assert-Phase153ValidatorEquals -Actual $artifact.body_organ_count -Expected 24 -Name "body_organ_count"
    foreach ($field in @(
      "self_growth_duty_runtime_created",
      "self_growth_runtime_contract_created",
      "self_growth_curriculum_created",
      "declarative_skill_factory_created",
      "body_pack_adapter_created",
      "self_growth_safety_policy_created",
      "runtime_started",
      "cycle_001_self_diagnosis_created",
      "cycle_001_growth_goal_selected",
      "cycle_001_self_build_program_created",
      "cycle_001_executed",
      "cycle_001_skill_validated",
      "cycle_001_learning_absorption_candidate_created",
      "cycle_002_started",
      "cycle_002_started_from_cycle_001_next_goal",
      "cycle_002_self_build_program_created",
      "cycle_002_executed",
      "cycle_002_skill_validated",
      "cycle_002_learning_absorption_candidate_created",
      "self_growth_heartbeat_created",
      "learned_skill_candidates_index_created",
      "self_model_growth_candidate_created",
      "bounded_duty_loop_readiness_created",
      "runtime_stop_decision_created",
      "self_growth_loop_proven",
      "ready_for_phase154_bounded_trial"
    )) {
      Assert-Phase153ValidatorTrue -Actual $artifact.$field -Name $field
    }
    Assert-Phase153ValidatorEquals -Actual $artifact.cycle_count -Expected 2 -Name "artifact_cycle_count"
    Assert-Phase153ValidatorEquals -Actual $artifact.cycle_001_selected_goal -Expected "learn_multiplication_basic_v1" -Name "artifact_cycle001_selected_goal"
    Assert-Phase153ValidatorEquals -Actual $artifact.cycle_001_skill_id -Expected "MULTIPLICATION_BASIC_SKILL_CANDIDATE_V1" -Name "artifact_cycle001_skill_id"
    Assert-Phase153ValidatorEquals -Actual $artifact.cycle_001_validation_status -Expected "PASS" -Name "artifact_cycle001_validation_status"
    Assert-Phase153ValidatorEquals -Actual $artifact.cycle_001_next_growth_goal -Expected "learn_division_basic_v1" -Name "artifact_cycle001_next_goal"
    Assert-Phase153ValidatorEquals -Actual $artifact.cycle_002_selected_goal -Expected "learn_division_basic_v1" -Name "artifact_cycle002_selected_goal"
    Assert-Phase153ValidatorEquals -Actual $artifact.cycle_002_skill_id -Expected "DIVISION_BASIC_SKILL_CANDIDATE_V1" -Name "artifact_cycle002_skill_id"
    Assert-Phase153ValidatorEquals -Actual $artifact.cycle_002_validation_status -Expected "PASS" -Name "artifact_cycle002_validation_status"
    Assert-Phase153ValidatorEquals -Actual $artifact.cycle_002_next_growth_goal -Expected "learn_subtraction_basic_v1" -Name "artifact_cycle002_next_goal"
    Assert-Phase153ValidatorFalse -Actual $artifact.owner_selected_each_goal -Name "owner_selected_each_goal"
    Assert-Phase153ValidatorFalse -Actual $artifact.codex_selected_each_goal -Name "codex_selected_each_goal"
    Assert-Phase153ValidatorEquals -Actual $artifact.recommended_cycle_limit -Expected 3 -Name "recommended_cycle_limit"
    Assert-Phase153ValidatorFalse -Actual $artifact.codex_needed_for_next_step -Name "codex_needed_for_next_step"
    foreach ($flag in @("external_fetch_performed","dependency_install_performed","executable_materials_used","arbitrary_code_execution_used","accepted_state_mutated","accepted_memory_mutated","accepted_self_model_mutated","external_agents_created","orchestrator_changed","route_lock_changed","current_runtime_changed","capability_shelf_mutated","body_pack_mutated")) {
      Assert-Phase153ValidatorFalse -Actual $artifact.$flag -Name $flag
    }
    Assert-Phase153ValidatorEquals -Actual $artifact.trusted_source_count -Expected 0 -Name "trusted_source_count"
    Assert-Phase153ValidatorEquals -Actual $artifact.queue_after -Expected "NONE" -Name "queue_after"
  }

  $SourcePolicy = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $SourcePolicyPath
  Assert-Phase153ValidatorFalse -Actual $SourcePolicy.default_trust -Name "source_policy_default_trust"
  Assert-Phase153ValidatorFalse -Actual $SourcePolicy.external_fetch_allowed -Name "source_policy_external_fetch_allowed"
  Assert-Phase153ValidatorFalse -Actual $SourcePolicy.install_allowed -Name "source_policy_install_allowed"
  Assert-Phase153ValidatorFalse -Actual $SourcePolicy.executable_use_allowed -Name "source_policy_executable_use_allowed"
  $TrustedSources = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path $TrustedSourcesPath
  Assert-Phase153ValidatorEquals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count_final"

  $Queue = Read-Phase153ValidatorJson -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
  Assert-Phase153ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  Write-Host "PHASE153_BUILDER_SELF_GROWTH_DUTY_RUNTIME_IGNITION_VALIDATE_RESULT=PASS"
  Write-Host "PHASE152_VERIFIED=True"
  Write-Host "BODY_PACK_VERIFIED=True"
  Write-Host "BODY_ORGAN_COUNT=24"
  Write-Host "SELF_GROWTH_DUTY_RUNTIME_CREATED=True"
  Write-Host "RUNTIME_STARTED=True"
  Write-Host "CYCLE_COUNT=2"
  Write-Host "CYCLE_001_SELECTED_GOAL=learn_multiplication_basic_v1"
  Write-Host "CYCLE_001_SKILL_ID=MULTIPLICATION_BASIC_SKILL_CANDIDATE_V1"
  Write-Host "CYCLE_001_VALIDATION_STATUS=PASS"
  Write-Host "CYCLE_001_NEXT_GROWTH_GOAL=learn_division_basic_v1"
  Write-Host "CYCLE_002_STARTED_FROM_CYCLE_001_NEXT_GOAL=True"
  Write-Host "CYCLE_002_SELECTED_GOAL=learn_division_basic_v1"
  Write-Host "CYCLE_002_SKILL_ID=DIVISION_BASIC_SKILL_CANDIDATE_V1"
  Write-Host "CYCLE_002_VALIDATION_STATUS=PASS"
  Write-Host "CYCLE_002_NEXT_GROWTH_GOAL=learn_subtraction_basic_v1"
  Write-Host "SELF_GROWTH_LOOP_PROVEN=True"
  Write-Host "OWNER_SELECTED_EACH_GOAL=False"
  Write-Host "CODEX_SELECTED_EACH_GOAL=False"
  Write-Host "READY_FOR_PHASE154_BOUNDED_TRIAL=True"
  Write-Host "RECOMMENDED_CYCLE_LIMIT=3"
  Write-Host "CODEX_NEEDED_FOR_NEXT_STEP=False"
  Write-Host "EXTERNAL_FETCH_PERFORMED=False"
  Write-Host "DEPENDENCY_INSTALL_PERFORMED=False"
  Write-Host "EXECUTABLE_MATERIALS_USED=False"
  Write-Host "ARBITRARY_CODE_EXECUTION_USED=False"
  Write-Host "ACCEPTED_STATE_MUTATED=False"
  Write-Host "ACCEPTED_MEMORY_MUTATED=False"
  Write-Host "ACCEPTED_SELF_MODEL_MUTATED=False"
  Write-Host "EXTERNAL_AGENTS_CREATED=False"
  Write-Host "ORCHESTRATOR_CHANGED=False"
  Write-Host "ROUTE_LOCK_CHANGED=False"
  Write-Host "CURRENT_RUNTIME_CHANGED=False"
  Write-Host "CAPABILITY_SHELF_MUTATED=False"
  Write-Host "BODY_PACK_MUTATED=False"
  Write-Host "TRUSTED_SOURCE_COUNT=0"
  Write-Host "QUEUE_AFTER=NONE"
  Write-Host "NEXT_ALLOWED_STEP=PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1"
} catch {
  Write-Host "PHASE153_BUILDER_SELF_GROWTH_DUTY_RUNTIME_IGNITION_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE153_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  Pop-Location
}
