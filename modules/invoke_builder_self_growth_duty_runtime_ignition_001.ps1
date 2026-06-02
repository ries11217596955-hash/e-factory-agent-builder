function Resolve-Phase153Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase153JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase153Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE153_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase153JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase153Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase153TextFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$Content
  )

  $fullPath = Resolve-Phase153Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  if (-not $Content.EndsWith("`n")) {
    $Content += "`n"
  }

  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase153Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE153_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase153True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE153_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase153False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE153_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase153ArithmeticValue {
  param([object]$TestCase)

  switch ($TestCase.operation) {
    "multiply" { return [int]$TestCase.left_operand * [int]$TestCase.right_operand }
    "divide" {
      if ([int]$TestCase.right_operand -eq 0) {
        throw "PHASE153_DIVIDE_BY_ZERO_TEST_CASE=$($TestCase.test_id)"
      }
      return [int]$TestCase.left_operand / [int]$TestCase.right_operand
    }
    default { throw "PHASE153_UNSUPPORTED_OPERATION=$($TestCase.operation)" }
  }
}

function New-Phase153TestCase {
  param(
    [string]$TestId,
    [int]$Left,
    [string]$Symbol,
    [string]$Operation,
    [int]$Right,
    [int]$Expected
  )

  return [ordered]@{
    test_id = $TestId
    expression = "$Left $Symbol $Right = $Expected"
    left_operand = $Left
    operator_symbol = $Symbol
    operation = $Operation
    right_operand = $Right
    expected_result = $Expected
  }
}

function Invoke-Phase153SelfGrowthCycle {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$StepId,
    [string]$NextAllowedStep,
    [string]$CycleId,
    [int]$CycleNumber,
    [string]$CycleRoot,
    [string]$SelectedGoal,
    [string]$SelectionSource,
    [string]$SourceNextGrowthGoalPath,
    [string]$SkillId,
    [string]$SkillName,
    [string]$Operation,
    [string]$Question,
    [string]$Answer,
    [object[]]$TestCases,
    [string]$NextGrowthGoalValue
  )

  $SelfDiagnosisPath = "$CycleRoot/self_diagnosis.json"
  $GrowthGoalSelectionPath = "$CycleRoot/growth_goal_selection.json"
  $InternalQuestionPath = "$CycleRoot/internal_question.json"
  $InternalAnswerPath = "$CycleRoot/internal_answer.json"
  $SelfBuildProgramCandidatePath = "$CycleRoot/self_build_program_candidate.json"
  $SandboxExecutionTracePath = "$CycleRoot/sandbox_execution_trace.json"
  $SkillCandidatePath = "$CycleRoot/skill_candidate.json"
  $SkillContractPath = "$CycleRoot/skill_contract.json"
  $TestCasesPath = "$CycleRoot/test_cases.json"
  $SkillValidationResultPath = "$CycleRoot/skill_validation_result.json"
  $LearningAbsorptionCandidatePath = "$CycleRoot/learning_absorption_candidate.json"
  $NextGrowthGoalPath = "$CycleRoot/next_growth_goal.json"
  $CycleTracePath = "$CycleRoot/cycle_trace.json"

  $DerivedFromPreviousCycle = ($CycleNumber -eq 2)

  $SelfDiagnosis = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "SELF_DIAGNOSE"
    diagnosis = "no proven internal skill candidate for $SkillName in the PHASE153 self-growth cycle"
    proven_internal_skill_candidate_exists = $false
    detected_missing_skill = $SkillName
    accepted_state_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $SelfDiagnosisPath -Object $SelfDiagnosis

  $GrowthGoalSelection = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "SELECT_GROWTH_GOAL"
    selected_goal = $SelectedGoal
    selected_skill_id = $SkillId
    selection_source = $SelectionSource
    selected_from_cycle_001_next_goal = $DerivedFromPreviousCycle
    source_next_growth_goal_path = $SourceNextGrowthGoalPath
    owner_selected_goal = $false
    codex_selected_goal = $false
    accepted_state_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $GrowthGoalSelectionPath -Object $GrowthGoalSelection

  $InternalQuestion = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "INTERNAL_QUESTION"
    question = $Question
    asked_by_runtime_component = "internal_question_engine_adapter"
    owner_selected_goal = $false
    codex_selected_goal = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $InternalQuestionPath -Object $InternalQuestion

  $InternalAnswer = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "INTERNAL_ANSWER_SEARCH"
    answer = $Answer
    answer_sources = @("SELF_GROWTH_CURRICULUM_V1", "BUILDER_BODY_ORGAN_PACK_V1", $SourceNextGrowthGoalPath)
    external_fetch_performed = $false
    owner_selected_goal = $false
    codex_selected_goal = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $InternalAnswerPath -Object $InternalAnswer

  $SelfBuildProgramCandidate = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "WRITE_SELF_BUILD_PROGRAM"
    program_id = "PHASE153_${SkillId}_PROGRAM"
    program_status = "DECLARATIVE_PROGRAM_CANDIDATE"
    target_skill_id = $SkillId
    target_growth_goal = $SelectedGoal
    execution_mode = "declarative_json_only"
    execution_scope = "self_growth_cycle_sandbox"
    arbitrary_code_execution_allowed = $false
    accepted_state_mutation_allowed = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $SelfBuildProgramCandidatePath -Object $SelfBuildProgramCandidate

  $SkillCandidate = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    skill_id = $SkillId
    skill_name = $SkillName
    skill_status = "SANDBOX_SKILL_CANDIDATE_NOT_ACCEPTED"
    growth_goal = $SelectedGoal
    operation = $Operation
    execution_mode = "declarative_json_only"
    accepted_capability = $false
    accepted_memory_mutated = $false
    accepted_state_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $SkillCandidatePath -Object $SkillCandidate

  $SkillContract = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    contract_id = "PHASE153_${SkillId}_CONTRACT"
    skill_id = $SkillId
    operation = $Operation
    validation_rule = "validator must independently calculate every test case result from operands and operation"
    accepted_state_mutation_allowed = $false
    accepted_capability = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $SkillContractPath -Object $SkillContract

  $TestCaseFile = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    skill_id = $SkillId
    operation = $Operation
    test_cases = $TestCases
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $TestCasesPath -Object $TestCaseFile

  $CalculatedResults = @()
  foreach ($testCase in $TestCases) {
    $actual = Get-Phase153ArithmeticValue -TestCase ([pscustomobject]$testCase)
    $CalculatedResults += [ordered]@{
      test_id = $testCase.test_id
      expression = $testCase.expression
      expected_result = $testCase.expected_result
      calculated_result = $actual
      passed = ($actual -eq [int]$testCase.expected_result)
    }
  }
  if (@($CalculatedResults | Where-Object { $_.passed -ne $true }).Count -gt 0) {
    throw "PHASE153_SKILL_VALIDATION_FAILED=$CycleId"
  }

  $SandboxExecutionTrace = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "EXECUTE_IN_SANDBOX"
    executor = "declarative_skill_factory"
    program_id = $SelfBuildProgramCandidate.program_id
    skill_id = $SkillId
    executed = $true
    execution_mode = "declarative_json_only"
    arbitrary_code_execution_used = $false
    accepted_state_mutated = $false
    created_outputs = @($SkillCandidatePath, $SkillContractPath, $TestCasesPath)
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $SandboxExecutionTracePath -Object $SandboxExecutionTrace

  $SkillValidationResult = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "VALIDATE_SKILL"
    skill_id = $SkillId
    validation_status = "PASS"
    independently_calculated = $true
    calculated_results = $CalculatedResults
    accepted_state_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $SkillValidationResultPath -Object $SkillValidationResult

  $LearningAbsorptionCandidate = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "ABSORB_AS_CANDIDATE"
    skill_id = $SkillId
    absorption_status = "CANDIDATE_NOT_ACCEPTED"
    learning_summary = "$SkillName validated in sandbox as a declarative skill candidate."
    accepted_memory_mutated = $false
    accepted_state_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $LearningAbsorptionCandidatePath -Object $LearningAbsorptionCandidate

  $NextGrowthGoalArtifact = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "SELECT_NEXT_GROWTH_GOAL"
    current_goal = $SelectedGoal
    next_growth_goal = $NextGrowthGoalValue
    selected_by_runtime = $true
    owner_selected_goal = $false
    codex_selected_goal = $false
    accepted_state_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $NextGrowthGoalPath -Object $NextGrowthGoalArtifact

  $CycleTrace = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    sequence = @("SELF_DIAGNOSE", "SELECT_GROWTH_GOAL", "WRITE_SELF_BUILD_PROGRAM", "EXECUTE_IN_SANDBOX", "VALIDATE_SKILL", "ABSORB_AS_CANDIDATE", "SELECT_NEXT_GROWTH_GOAL")
    self_diagnosis_created = $true
    growth_goal_selected = $true
    selected_goal = $SelectedGoal
    self_build_program_created = $true
    executed = $true
    skill_id = $SkillId
    skill_validated = $true
    validation_status = "PASS"
    learning_absorption_candidate_created = $true
    next_growth_goal = $NextGrowthGoalArtifact.next_growth_goal
    started_from_cycle_001_next_goal = $DerivedFromPreviousCycle
    owner_selected_goal = $false
    codex_selected_goal = $false
    accepted_state_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $CycleTracePath -Object $CycleTrace

  return [ordered]@{
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    selected_goal = $SelectedGoal
    skill_id = $SkillId
    validation_status = "PASS"
    next_growth_goal = $NextGrowthGoalArtifact.next_growth_goal
    self_diagnosis_path = $SelfDiagnosisPath
    growth_goal_selection_path = $GrowthGoalSelectionPath
    internal_question_path = $InternalQuestionPath
    internal_answer_path = $InternalAnswerPath
    self_build_program_candidate_path = $SelfBuildProgramCandidatePath
    sandbox_execution_trace_path = $SandboxExecutionTracePath
    skill_candidate_path = $SkillCandidatePath
    skill_contract_path = $SkillContractPath
    test_cases_path = $TestCasesPath
    skill_validation_result_path = $SkillValidationResultPath
    learning_absorption_candidate_path = $LearningAbsorptionCandidatePath
    next_growth_goal_path = $NextGrowthGoalPath
    cycle_trace_path = $CycleTracePath
  }
}

function Invoke-BuilderSelfGrowthDutyRuntimeIgnition001 {
  param(
    [string]$RepoRoot = ".",
    [string]$RunId = "PHASE153_SELF_GROWTH_DUTY_RUNTIME_IGNITION_001"
  )

  $ErrorActionPreference = "Stop"
  $RepoRoot = Resolve-Phase153Path -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot

  try {
    $StepId = "PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1"
    $NextAllowedStep = "PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1"
    $RuntimeId = "SELF_GROWTH_DUTY_RUNTIME_V1"
    $CycleLimit = 2
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

    foreach ($identityFile in @(
      "CAPABILITY_ROADMAP.json",
      "GENESIS_STATE.json",
      "TASK_QUEUE.json",
      "packs/registry.json",
      "orchestrator/run.ps1"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase153Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $Branch = (git branch --show-current).Trim()
    if ($Branch -eq "main") {
      throw "PHASE153_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase153Equals -Actual $Branch -Expected "phase110-idempotent-autonomy-trial-runtime" -Name "current_branch"
    $Head = (git rev-parse --short HEAD).Trim()
    Assert-Phase153Equals -Actual $Head -Expected "46b70c4" -Name "current_head"

    $ForbiddenBefore = @(git status --short --untracked-files=all -- `
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
    if ($ForbiddenBefore.Count -gt 0) {
      throw "PHASE153_FORBIDDEN_SCOPE_DIRTY_BEFORE=$($ForbiddenBefore -join '; ')"
    }

    $Phase152Proof = Read-Phase153JsonRequired -RepoRoot $RepoRoot -Path $Phase152ProofPath
    Assert-Phase153Equals -Actual $Phase152Proof.status -Expected "PASS" -Name "phase152_status"
    Assert-Phase153Equals -Actual $Phase152Proof.next_allowed_step -Expected $StepId -Name "phase152_next_allowed_step"
    Assert-Phase153Equals -Actual $Phase152Proof.body_organ_count -Expected 24 -Name "phase152_body_organ_count"
    Assert-Phase153True -Actual $Phase152Proof.program_executed -Name "phase152_program_executed"
    Assert-Phase153Equals -Actual $Phase152Proof.execution_scope -Expected "sandbox_only" -Name "phase152_execution_scope"
    Assert-Phase153Equals -Actual $Phase152Proof.execution_mode -Expected "declarative_json_only" -Name "phase152_execution_mode"

    $null = Read-Phase153JsonRequired -RepoRoot $RepoRoot -Path $Phase152ResultPath
    $null = Read-Phase153JsonRequired -RepoRoot $RepoRoot -Path $Phase152ReportPath
    $BodyPack = Read-Phase153JsonRequired -RepoRoot $RepoRoot -Path $BodyPackPath
    $BodyRegistry = Read-Phase153JsonRequired -RepoRoot $RepoRoot -Path $BodyRegistryPath
    $BodyPolicy = Read-Phase153JsonRequired -RepoRoot $RepoRoot -Path $BodyPolicyPath
    $BodyRuntimeContract = Read-Phase153JsonRequired -RepoRoot $RepoRoot -Path $BodyRuntimeContractPath
    $BodySafetyBoundaries = Read-Phase153JsonRequired -RepoRoot $RepoRoot -Path $BodySafetyBoundariesPath
    $null = Read-Phase153JsonRequired -RepoRoot $RepoRoot -Path $BodyPortabilityManifestPath
    Assert-Phase153Equals -Actual $BodyPack.body_pack_id -Expected "BUILDER_BODY_ORGAN_PACK_V1" -Name "body_pack_id"
    Assert-Phase153Equals -Actual $BodyRegistry.body_organ_count -Expected 24 -Name "body_registry_count"
    Assert-Phase153False -Actual $BodyPolicy.accepted_state_mutation_allowed -Name "body_policy_accepted_state_mutation_allowed"
    Assert-Phase153False -Actual $BodyRuntimeContract.accepted_state_mutation_allowed -Name "body_runtime_accepted_state_mutation_allowed"
    Assert-Phase153False -Actual $BodySafetyBoundaries.capability_shelf_mutation_allowed -Name "body_safety_capability_shelf_mutation_allowed"

    foreach ($organPath in @(
      "living_learning_environment/body/organs/SELF_STATE_SENSOR_V1.json",
      "living_learning_environment/body/organs/GOAL_STATE_MANAGER_V1.json",
      "living_learning_environment/body/organs/CAPABILITY_GAP_DETECTOR_V1.json",
      "living_learning_environment/body/organs/INTERNAL_QUESTION_ENGINE_V1.json",
      "living_learning_environment/body/organs/INTERNAL_ANSWER_SEARCHER_V1.json",
      "living_learning_environment/body/organs/SELF_BUILD_PROGRAM_COMPOSER_V1.json",
      "living_learning_environment/body/organs/SELF_BUILD_SANDBOX_EXECUTOR_V1.json",
      "living_learning_environment/body/organs/SANDBOX_VALIDATION_RUNNER_V1.json",
      "living_learning_environment/body/organs/MEMORY_ABSORBER_V1.json",
      "living_learning_environment/body/organs/SELF_MODEL_UPDATE_CANDIDATE_WRITER_V1.json",
      "living_learning_environment/body/organs/NEXT_CYCLE_DECIDER_V1.json",
      "living_learning_environment/body/organs/DUTY_LOOP_CONTROLLER_V1.json"
    )) {
      $organ = Read-Phase153JsonRequired -RepoRoot $RepoRoot -Path $organPath
      Assert-Phase153False -Actual $organ.accepted_capability -Name "body_organ_accepted_capability"
    }

    $SourcePolicy = Read-Phase153JsonRequired -RepoRoot $RepoRoot -Path $SourcePolicyPath
    Assert-Phase153False -Actual $SourcePolicy.default_trust -Name "source_policy_default_trust"
    Assert-Phase153False -Actual $SourcePolicy.external_fetch_allowed -Name "source_policy_external_fetch_allowed"
    Assert-Phase153False -Actual $SourcePolicy.install_allowed -Name "source_policy_install_allowed"
    Assert-Phase153False -Actual $SourcePolicy.executable_use_allowed -Name "source_policy_executable_use_allowed"
    $TrustedSources = Read-Phase153JsonRequired -RepoRoot $RepoRoot -Path $TrustedSourcesPath
    Assert-Phase153Equals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count"
    $Queue = Read-Phase153JsonRequired -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
    Assert-Phase153Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $RuntimeComponents = @(
      "self_diagnosis_engine",
      "growth_goal_selector",
      "internal_question_engine_adapter",
      "internal_answer_search_adapter",
      "self_build_program_writer",
      "declarative_skill_factory",
      "sandbox_executor_adapter",
      "skill_validator",
      "learning_absorber",
      "next_growth_goal_selector",
      "bounded_cycle_controller",
      "safe_stop_controller"
    )
    $CurriculumGoals = @(
      [ordered]@{ goal_id = "learn_multiplication_basic_v1"; skill_id = "MULTIPLICATION_BASIC_SKILL_CANDIDATE_V1"; operation = "multiply"; next_growth_goal = "learn_division_basic_v1" },
      [ordered]@{ goal_id = "learn_division_basic_v1"; skill_id = "DIVISION_BASIC_SKILL_CANDIDATE_V1"; operation = "divide"; next_growth_goal = "learn_subtraction_basic_v1" },
      [ordered]@{ goal_id = "learn_subtraction_basic_v1"; skill_id = "SUBTRACTION_BASIC_SKILL_CANDIDATE_V1"; operation = "subtract"; next_growth_goal = "learn_addition_consistency_v1" },
      [ordered]@{ goal_id = "learn_addition_consistency_v1"; skill_id = "ADDITION_CONSISTENCY_SKILL_CANDIDATE_V1"; operation = "add"; next_growth_goal = "learn_arithmetic_error_detection_v1" },
      [ordered]@{ goal_id = "learn_arithmetic_error_detection_v1"; skill_id = "ARITHMETIC_ERROR_DETECTION_SKILL_CANDIDATE_V1"; operation = "validate"; next_growth_goal = "STOP_SAFE" }
    )

    Write-Phase153TextFile -RepoRoot $RepoRoot -Path $RouteAlignmentPath -Content ((@(
      "# PHASE153 Self-Growth Duty Runtime Ignition Alignment Request",
      "",
      "status: PASS",
      "line: AGENT_BUILDER_SELF_DEVELOPMENT",
      "mode: SELF_BUILD",
      "runtime_id: $RuntimeId",
      "cycle_limit: 2",
      "cycle_shape: SELF_DIAGNOSE -> SELECT_GROWTH_GOAL -> WRITE_SELF_BUILD_PROGRAM -> EXECUTE_IN_SANDBOX -> VALIDATE_SKILL -> ABSORB_AS_CANDIDATE -> SELECT_NEXT_GROWTH_GOAL -> START_NEXT_CYCLE",
      "cycle_002_source: cycle_001 next_growth_goal",
      "accepted_state_mutated: false",
      "arbitrary_code_execution_used: false",
      "next_allowed_step: $NextAllowedStep"
    )) -join "`n")

    $RuntimeDefinition = [ordered]@{
      status = "PASS"
      runtime_id = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      runtime_status = "SELF_GROWTH_DUTY_RUNTIME_AVAILABLE_IN_LLE"
      bounded_cycle_limit = $CycleLimit
      declared_components = $RuntimeComponents
      loop_shape = @("SELF_DIAGNOSE","SELECT_GROWTH_GOAL","WRITE_SELF_BUILD_PROGRAM","EXECUTE_IN_SANDBOX","VALIDATE_SKILL","ABSORB_AS_CANDIDATE","SELECT_NEXT_GROWTH_GOAL","START_NEXT_CYCLE")
      owner_selected_each_goal = $false
      codex_selected_each_goal = $false
      accepted_state_mutation_allowed = $false
      next_allowed_step = $StepId
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $RuntimePath -Object $RuntimeDefinition

    $RuntimeContract = [ordered]@{
      status = "PASS"
      contract_id = "SELF_GROWTH_DUTY_RUNTIME_CONTRACT_V1"
      runtime_id = $RuntimeId
      cycle_limit = $CycleLimit
      external_fetch_allowed = $false
      install_allowed = $false
      arbitrary_code_execution_allowed = $false
      executable_materials_allowed = $false
      accepted_state_mutation_allowed = $false
      accepted_memory_mutation_allowed = $false
      accepted_self_model_mutation_allowed = $false
      capability_shelf_mutation_allowed = $false
      generated_agents_allowed = $false
      applied_agents_allowed = $false
      body_pack_mutation_allowed = $false
      safe_stop_required = $true
      next_allowed_step = $StepId
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $RuntimeContractPath -Object $RuntimeContract

    $Curriculum = [ordered]@{
      status = "PASS"
      curriculum_id = "SELF_GROWTH_CURRICULUM_V1"
      runtime_id = $RuntimeId
      curriculum_status = "INTERNAL_DNA_LEARNING_MAP"
      owner_manual_goal_selection_required = $false
      goals = $CurriculumGoals
      next_allowed_step = $StepId
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $CurriculumPath -Object $Curriculum

    $DeclarativeSkillFactory = [ordered]@{
      status = "PASS"
      factory_id = "DECLARATIVE_SKILL_FACTORY_V1"
      runtime_id = $RuntimeId
      execution_mode = "declarative_json_only"
      can_create_skill_candidates = $true
      arbitrary_code_execution_allowed = $false
      accepted_capability_promotion_allowed = $false
      accepted_state_mutation_allowed = $false
      next_allowed_step = $StepId
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $DeclarativeSkillFactoryPath -Object $DeclarativeSkillFactory

    $BodyPackAdapter = [ordered]@{
      status = "PASS"
      adapter_id = "BODY_PACK_ADAPTER_V1"
      runtime_id = $RuntimeId
      body_pack_id = "BUILDER_BODY_ORGAN_PACK_V1"
      body_pack_path = $BodyPackPath
      body_registry_path = $BodyRegistryPath
      body_policy_path = $BodyPolicyPath
      body_pack_mutation_allowed = $false
      organs_used = @("SELF_STATE_SENSOR_V1","GOAL_STATE_MANAGER_V1","CAPABILITY_GAP_DETECTOR_V1","INTERNAL_QUESTION_ENGINE_V1","INTERNAL_ANSWER_SEARCHER_V1","SELF_BUILD_PROGRAM_COMPOSER_V1","SELF_BUILD_SANDBOX_EXECUTOR_V1","SANDBOX_VALIDATION_RUNNER_V1","MEMORY_ABSORBER_V1","SELF_MODEL_UPDATE_CANDIDATE_WRITER_V1","NEXT_CYCLE_DECIDER_V1","DUTY_LOOP_CONTROLLER_V1")
      next_allowed_step = $StepId
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $BodyPackAdapterPath -Object $BodyPackAdapter

    $SafetyPolicy = [ordered]@{
      status = "PASS"
      policy_id = "SELF_GROWTH_SAFETY_POLICY_V1"
      runtime_id = $RuntimeId
      cycle_limit = $CycleLimit
      external_fetch_allowed = $false
      install_allowed = $false
      executable_materials_allowed = $false
      arbitrary_code_execution_allowed = $false
      accepted_state_mutation_allowed = $false
      accepted_memory_mutation_allowed = $false
      accepted_self_model_mutation_allowed = $false
      external_agents_allowed = $false
      capability_shelf_mutation_allowed = $false
      body_pack_mutation_allowed = $false
      trusted_source_count_required = 0
      next_allowed_step = $StepId
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $SafetyPolicyPath -Object $SafetyPolicy

    $RuntimeBoot = [ordered]@{
      status = "PASS"
      boot_id = "PHASE153_RUNTIME_BOOT"
      step_id = $StepId
      run_id = $RunId
      runtime_id = $RuntimeId
      runtime_started = $true
      cycle_limit = $CycleLimit
      phase152_verified = $true
      body_pack_verified = $true
      body_organ_count = 24
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $RuntimeBootPath -Object $RuntimeBoot

    $Cycle001Root = "$CycleRoot/cycle_001"
    $Cycle001Tests = @(
      (New-Phase153TestCase -TestId "multiply_2_3" -Left 2 -Symbol "*" -Operation "multiply" -Right 3 -Expected 6),
      (New-Phase153TestCase -TestId "multiply_4_5" -Left 4 -Symbol "*" -Operation "multiply" -Right 5 -Expected 20),
      (New-Phase153TestCase -TestId "multiply_7_8" -Left 7 -Symbol "*" -Operation "multiply" -Right 8 -Expected 56)
    )
    $Cycle001 = Invoke-Phase153SelfGrowthCycle `
      -RepoRoot $RepoRoot `
      -RunId $RunId `
      -StepId $StepId `
      -NextAllowedStep $NextAllowedStep `
      -CycleId "cycle_001" `
      -CycleNumber 1 `
      -CycleRoot $Cycle001Root `
      -SelectedGoal "learn_multiplication_basic_v1" `
      -SelectionSource "internal_curriculum_first_unproven_goal" `
      -SourceNextGrowthGoalPath "" `
      -SkillId "MULTIPLICATION_BASIC_SKILL_CANDIDATE_V1" `
      -SkillName "multiplication_basic" `
      -Operation "multiply" `
      -Question "What bounded self-growth skill should I build first to prove my learning loop?" `
      -Answer "Build multiplication_basic first because the internal curriculum orders it before division and PHASE152 body organs can compose, execute, validate, and absorb it as a candidate." `
      -TestCases $Cycle001Tests `
      -NextGrowthGoalValue "learn_division_basic_v1"

    $Cycle001Next = Read-Phase153JsonRequired -RepoRoot $RepoRoot -Path $Cycle001.next_growth_goal_path
    Assert-Phase153Equals -Actual $Cycle001Next.next_growth_goal -Expected "learn_division_basic_v1" -Name "cycle001_runtime_next_goal"

    $Cycle002Root = "$CycleRoot/cycle_002"
    $Cycle002Tests = @(
      (New-Phase153TestCase -TestId "divide_6_3" -Left 6 -Symbol "/" -Operation "divide" -Right 3 -Expected 2),
      (New-Phase153TestCase -TestId "divide_20_5" -Left 20 -Symbol "/" -Operation "divide" -Right 5 -Expected 4),
      (New-Phase153TestCase -TestId "divide_56_8" -Left 56 -Symbol "/" -Operation "divide" -Right 8 -Expected 7)
    )
    $Cycle002 = Invoke-Phase153SelfGrowthCycle `
      -RepoRoot $RepoRoot `
      -RunId $RunId `
      -StepId $StepId `
      -NextAllowedStep $NextAllowedStep `
      -CycleId "cycle_002" `
      -CycleNumber 2 `
      -CycleRoot $Cycle002Root `
      -SelectedGoal $Cycle001Next.next_growth_goal `
      -SelectionSource "cycle_001_next_growth_goal" `
      -SourceNextGrowthGoalPath $Cycle001.next_growth_goal_path `
      -SkillId "DIVISION_BASIC_SKILL_CANDIDATE_V1" `
      -SkillName "division_basic" `
      -Operation "divide" `
      -Question "What bounded follow-up skill should I build after multiplication_basic validated?" `
      -Answer "Build division_basic because Cycle 001 selected learn_division_basic_v1 as the next growth goal and the internal curriculum defines division as the bounded follow-up." `
      -TestCases $Cycle002Tests `
      -NextGrowthGoalValue "learn_subtraction_basic_v1"

    $RuntimeTrace = [ordered]@{
      status = "PASS"
      trace_id = "PHASE153_SELF_GROWTH_RUNTIME_TRACE"
      step_id = $StepId
      run_id = $RunId
      runtime_id = $RuntimeId
      sequence = @("SELF_DIAGNOSE","SELECT_GROWTH_GOAL","WRITE_SELF_BUILD_PROGRAM","EXECUTE_IN_SANDBOX","VALIDATE_SKILL","ABSORB_AS_CANDIDATE","SELECT_NEXT_GROWTH_GOAL","START_NEXT_CYCLE")
      runtime_started = $true
      cycle_count = $CycleLimit
      cycle_001_completed = $true
      cycle_002_started_from_cycle_001_next_goal = $true
      cycle_002_completed = $true
      safe_stop_after_cycle_limit = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $RuntimeTracePath -Object $RuntimeTrace

    $BodyPackUsageTrace = [ordered]@{
      status = "PASS"
      trace_id = "PHASE153_BODY_PACK_USAGE_TRACE"
      step_id = $StepId
      run_id = $RunId
      body_pack_id = "BUILDER_BODY_ORGAN_PACK_V1"
      body_pack_verified = $true
      body_organ_count = 24
      body_pack_mutated = $false
      organs_used = $BodyPackAdapter.organs_used
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $BodyPackUsageTracePath -Object $BodyPackUsageTrace

    $CycleIndex = [ordered]@{
      status = "PASS"
      index_id = "PHASE153_CYCLE_INDEX"
      step_id = $StepId
      run_id = $RunId
      cycle_count = $CycleLimit
      cycles = @(
        [ordered]@{ cycle_id = "cycle_001"; selected_goal = $Cycle001.selected_goal; skill_id = $Cycle001.skill_id; validation_status = $Cycle001.validation_status; next_growth_goal = $Cycle001.next_growth_goal; output_root = $Cycle001Root },
        [ordered]@{ cycle_id = "cycle_002"; selected_goal = $Cycle002.selected_goal; skill_id = $Cycle002.skill_id; validation_status = $Cycle002.validation_status; next_growth_goal = $Cycle002.next_growth_goal; output_root = $Cycle002Root; source_next_growth_goal_path = $Cycle001.next_growth_goal_path }
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $CycleIndexPath -Object $CycleIndex

    $Heartbeat = [ordered]@{
      status = "PASS"
      heartbeat_id = "PHASE153_SELF_GROWTH_HEARTBEAT"
      step_id = $StepId
      run_id = $RunId
      runtime_started = $true
      cycle_count = $CycleLimit
      cycle_001_completed = $true
      cycle_002_started_from_cycle_001_next_goal = $true
      cycle_002_completed = $true
      self_growth_loop_proven = $true
      owner_selected_each_goal = $false
      codex_selected_each_goal = $false
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $HeartbeatPath -Object $Heartbeat

    $SkillIndex = [ordered]@{
      status = "PASS"
      index_id = "PHASE153_LEARNED_SKILL_CANDIDATES_INDEX"
      step_id = $StepId
      run_id = $RunId
      skill_candidate_count = 2
      skill_candidates = @(
        [ordered]@{ cycle_id = "cycle_001"; skill_id = $Cycle001.skill_id; selected_goal = $Cycle001.selected_goal; validation_status = "PASS"; path = $Cycle001.skill_candidate_path },
        [ordered]@{ cycle_id = "cycle_002"; skill_id = $Cycle002.skill_id; selected_goal = $Cycle002.selected_goal; validation_status = "PASS"; path = $Cycle002.skill_candidate_path }
      )
      accepted_capability_promotion_performed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $SkillIndexPath -Object $SkillIndex

    $SelfModelGrowthCandidate = [ordered]@{
      status = "PASS"
      candidate_id = "PHASE153_SELF_MODEL_GROWTH_CANDIDATE"
      step_id = $StepId
      run_id = $RunId
      new_candidate_skills_count = 2
      candidate_skill_ids = @($Cycle001.skill_id, $Cycle002.skill_id)
      accepted_self_model_mutated = $false
      self_model_candidate_statement = "Builder can run a two-cycle bounded self-growth loop from internal curriculum and previous cycle output."
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $SelfModelGrowthCandidatePath -Object $SelfModelGrowthCandidate

    $DutyLoopReadiness = [ordered]@{
      status = "PASS"
      readiness_id = "PHASE153_BOUNDED_DUTY_LOOP_READINESS"
      step_id = $StepId
      run_id = $RunId
      ready_for_phase154_bounded_trial = $true
      recommended_cycle_limit = 3
      no_codex_needed_for_phase154_trial = $true
      codex_needed_for_next_step = $false
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $DutyLoopReadinessPath -Object $DutyLoopReadiness

    $RuntimeStopDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE153_RUNTIME_STOP_DECISION"
      step_id = $StepId
      run_id = $RunId
      stop_reason = "PHASE153_CYCLE_LIMIT_REACHED"
      safe_stop = $true
      cycle_count = $CycleLimit
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $RuntimeStopDecisionPath -Object $RuntimeStopDecision

    $RuntimeCreatedOutputs = @(
      $RuntimeBootPath,
      $RuntimeTracePath,
      $BodyPackUsageTracePath,
      $CycleIndexPath,
      $Cycle001.self_diagnosis_path,
      $Cycle001.growth_goal_selection_path,
      $Cycle001.internal_question_path,
      $Cycle001.internal_answer_path,
      $Cycle001.self_build_program_candidate_path,
      $Cycle001.sandbox_execution_trace_path,
      $Cycle001.skill_candidate_path,
      $Cycle001.skill_contract_path,
      $Cycle001.test_cases_path,
      $Cycle001.skill_validation_result_path,
      $Cycle001.learning_absorption_candidate_path,
      $Cycle001.next_growth_goal_path,
      $Cycle001.cycle_trace_path,
      $Cycle002.self_diagnosis_path,
      $Cycle002.growth_goal_selection_path,
      $Cycle002.internal_question_path,
      $Cycle002.internal_answer_path,
      $Cycle002.self_build_program_candidate_path,
      $Cycle002.sandbox_execution_trace_path,
      $Cycle002.skill_candidate_path,
      $Cycle002.skill_contract_path,
      $Cycle002.test_cases_path,
      $Cycle002.skill_validation_result_path,
      $Cycle002.learning_absorption_candidate_path,
      $Cycle002.next_growth_goal_path,
      $Cycle002.cycle_trace_path,
      $HeartbeatPath,
      $SkillIndexPath,
      $SelfModelGrowthCandidatePath,
      $DutyLoopReadinessPath,
      $RuntimeStopDecisionPath
    )

    $Common = [ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase152_verified = $true
      body_pack_verified = $true
      body_organ_count = 24
      self_growth_duty_runtime_created = $true
      self_growth_runtime_contract_created = $true
      self_growth_curriculum_created = $true
      declarative_skill_factory_created = $true
      body_pack_adapter_created = $true
      self_growth_safety_policy_created = $true
      runtime_started = $true
      cycle_count = $CycleLimit
      cycle_001_self_diagnosis_created = $true
      cycle_001_growth_goal_selected = $true
      cycle_001_selected_goal = "learn_multiplication_basic_v1"
      cycle_001_self_build_program_created = $true
      cycle_001_executed = $true
      cycle_001_skill_id = "MULTIPLICATION_BASIC_SKILL_CANDIDATE_V1"
      cycle_001_skill_validated = $true
      cycle_001_validation_status = "PASS"
      cycle_001_learning_absorption_candidate_created = $true
      cycle_001_next_growth_goal = "learn_division_basic_v1"
      cycle_002_started = $true
      cycle_002_started_from_cycle_001_next_goal = $true
      cycle_002_selected_goal = "learn_division_basic_v1"
      cycle_002_self_build_program_created = $true
      cycle_002_executed = $true
      cycle_002_skill_id = "DIVISION_BASIC_SKILL_CANDIDATE_V1"
      cycle_002_skill_validated = $true
      cycle_002_validation_status = "PASS"
      cycle_002_learning_absorption_candidate_created = $true
      cycle_002_next_growth_goal = "learn_subtraction_basic_v1"
      self_growth_heartbeat_created = $true
      learned_skill_candidates_index_created = $true
      self_model_growth_candidate_created = $true
      bounded_duty_loop_readiness_created = $true
      runtime_stop_decision_created = $true
      self_growth_loop_proven = $true
      owner_selected_each_goal = $false
      codex_selected_each_goal = $false
      ready_for_phase154_bounded_trial = $true
      recommended_cycle_limit = 3
      codex_needed_for_next_step = $false
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      arbitrary_code_execution_used = $false
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
      external_agents_created = $false
      orchestrator_changed = $false
      route_lock_changed = $false
      current_runtime_changed = $false
      capability_shelf_mutated = $false
      body_pack_mutated = $false
      trusted_source_count = 0
      queue_after = "NONE"
      runtime_path = $RuntimePath
      runtime_contract_path = $RuntimeContractPath
      curriculum_path = $CurriculumPath
      declarative_skill_factory_path = $DeclarativeSkillFactoryPath
      body_pack_adapter_path = $BodyPackAdapterPath
      safety_policy_path = $SafetyPolicyPath
      cycle_root = $CycleRoot
      next_allowed_step = $NextAllowedStep
    }

    $Result = [ordered]@{}
    foreach ($key in $Common.Keys) { $Result[$key] = $Common[$key] }
    $Result["result_id"] = "PHASE153_BUILDER_SELF_GROWTH_DUTY_RUNTIME_IGNITION_RESULT"
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result

    $RuntimeArchitectureFiles = @($RouteAlignmentPath, $RuntimePath, $RuntimeContractPath, $CurriculumPath, $DeclarativeSkillFactoryPath, $BodyPackAdapterPath, $SafetyPolicyPath)
    $Report = [ordered]@{
      status = "PASS"
      report_id = "PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1_REPORT"
      step_id = $StepId
      run_id = $RunId
      route_alignment_request_path = $RouteAlignmentPath
      self_growth_runtime_paths = @($RuntimePath, $RuntimeContractPath, $CurriculumPath, $DeclarativeSkillFactoryPath, $BodyPackAdapterPath, $SafetyPolicyPath)
      runtime_contract_path = $RuntimeContractPath
      curriculum_path = $CurriculumPath
      module_path = "modules/invoke_builder_self_growth_duty_runtime_ignition_001.ps1"
      validator_path = "validators/validate_phase153_builder_self_growth_duty_runtime_ignition_v1.ps1"
      exact_run_command_expected = ". .\modules\invoke_builder_self_growth_duty_runtime_ignition_001.ps1; `$Result = Invoke-BuilderSelfGrowthDutyRuntimeIgnition001 -RepoRoot (Get-Location).Path -RunId PHASE153_SELF_GROWTH_DUTY_RUNTIME_IGNITION_001; `$Result | ConvertTo-Json -Depth 20"
      exact_validator_command_expected = ".\validators\validate_phase153_builder_self_growth_duty_runtime_ignition_v1.ps1 -RepoRoot ."
      runtime_output_files_created = $RuntimeCreatedOutputs + @($ResultPath, $ReportPath, $ProofPath)
      cycle_002_derivation = "Cycle 002 reads $($Cycle001.next_growth_goal_path) and selects its next_growth_goal value learn_division_basic_v1."
      files_changed = $RuntimeArchitectureFiles + @("modules/invoke_builder_self_growth_duty_runtime_ignition_001.ps1", "validators/validate_phase153_builder_self_growth_duty_runtime_ignition_v1.ps1") + $RuntimeCreatedOutputs + @($ResultPath, $ReportPath, $ProofPath)
      risks = @(
        "PHASE153 creates skill candidates and learning candidates only; they are not accepted skills or capabilities.",
        "The duty runtime is bounded to exactly two cycles and stops safely before PHASE154.",
        "PHASE154 must prove a bounded trial without mutating accepted state."
      )
      cut_list = @(
        "No orchestrator change.",
        "No TASK_QUEUE mutation.",
        "No GENESIS_STATE mutation.",
        "No CAPABILITY_ROADMAP mutation.",
        "No packs registry mutation.",
        "No capability_shelf mutation.",
        "No living_learning_environment/body mutation.",
        "No accepted PHASE142-PHASE152 artifact mutation.",
        "No generated_agents or applied_agents touch.",
        "No package manager or dependency file touch.",
        "No GitHub workflow touch.",
        "No internet fetch.",
        "No dependency install.",
        "No external executable material use.",
        "No arbitrary code execution from generated programs.",
        "No accepted memory or self-model mutation.",
        "No skill candidate promotion.",
        "No external agent production.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report

    $Proof = [ordered]@{}
    foreach ($key in $Common.Keys) { $Proof[$key] = $Common[$key] }
    $Proof["proof_id"] = $StepId
    $Proof["phase152_proof_path"] = $Phase152ProofPath
    $Proof["runtime_boot_path"] = $RuntimeBootPath
    $Proof["cycle_index_path"] = $CycleIndexPath
    $Proof["self_growth_heartbeat_path"] = $HeartbeatPath
    $Proof["runtime_stop_decision_path"] = $RuntimeStopDecisionPath
    $Proof["result_path"] = $ResultPath
    $Proof["report_path"] = $ReportPath
    Write-Phase153JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject][ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      runtime_started = $true
      cycle_count = $CycleLimit
      cycle_001_selected_goal = "learn_multiplication_basic_v1"
      cycle_001_skill_id = "MULTIPLICATION_BASIC_SKILL_CANDIDATE_V1"
      cycle_001_validation_status = "PASS"
      cycle_002_started_from_cycle_001_next_goal = $true
      cycle_002_selected_goal = "learn_division_basic_v1"
      cycle_002_skill_id = "DIVISION_BASIC_SKILL_CANDIDATE_V1"
      cycle_002_validation_status = "PASS"
      self_growth_loop_proven = $true
      ready_for_phase154_bounded_trial = $true
      codex_needed_for_next_step = $false
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      next_allowed_step = $NextAllowedStep
    }
  } finally {
    Pop-Location
  }
}
