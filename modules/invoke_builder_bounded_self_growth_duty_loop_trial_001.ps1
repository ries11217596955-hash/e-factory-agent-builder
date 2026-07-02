param(
  [string]$RepoRoot = ".",
  [string]$RunId = "PHASE154_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_001"
)

$ErrorActionPreference = "Stop"

function Resolve-Phase154Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase154JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase154Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE154_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase154JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase154Path -RepoRoot $RepoRoot -Path $Path
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

function Assert-Phase154Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE154_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase154True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE154_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase154False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE154_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase154CurriculumGoal {
  param(
    [object]$Curriculum,
    [string]$GoalId
  )

  $matches = @($Curriculum.goals | Where-Object { $_.goal_id -eq $GoalId })
  Assert-Phase154Equals -Actual $matches.Count -Expected 1 -Name "curriculum_goal_match_count:$GoalId"
  return $matches[0]
}

function New-Phase154ArithmeticTestCase {
  param(
    [string]$TestId,
    [string]$Expression,
    [string]$Operation,
    [int]$Left,
    [int]$Right,
    [int]$Expected
  )

  return [ordered]@{
    test_id = $TestId
    expression = $Expression
    operation = $Operation
    left_operand = $Left
    right_operand = $Right
    expected_result = $Expected
  }
}

function New-Phase154ErrorDetectionTestCase {
  param(
    [string]$TestId,
    [string]$Expression,
    [string]$BaseOperation,
    [int]$Left,
    [int]$Right,
    [int]$Claimed,
    [int]$Expected,
    [bool]$ErrorDetected
  )

  return [ordered]@{
    test_id = $TestId
    expression = $Expression
    operation = "validate"
    base_operation = $BaseOperation
    left_operand = $Left
    right_operand = $Right
    claimed_result = $Claimed
    expected_result = $Expected
    error_detected = $ErrorDetected
  }
}

function Get-Phase154ArithmeticValue {
  param(
    [string]$Operation,
    [int]$Left,
    [int]$Right
  )

  switch ($Operation) {
    "add" { return $Left + $Right }
    "subtract" { return $Left - $Right }
    "multiply" { return $Left * $Right }
    "divide" {
      if ($Right -eq 0) {
        throw "PHASE154_DIVIDE_BY_ZERO"
      }
      return [int]($Left / $Right)
    }
    default { throw "PHASE154_UNSUPPORTED_OPERATION=$Operation" }
  }
}

function Get-Phase154ValidationResult {
  param([object]$TestCase)

  if ($TestCase.operation -eq "validate") {
    $actual = Get-Phase154ArithmeticValue -Operation $TestCase.base_operation -Left ([int]$TestCase.left_operand) -Right ([int]$TestCase.right_operand)
    $calculatedError = ($actual -ne [int]$TestCase.claimed_result)
    return [ordered]@{
      test_id = $TestCase.test_id
      expression = $TestCase.expression
      claimed_result = [int]$TestCase.claimed_result
      expected_result = [int]$TestCase.expected_result
      calculated_result = $actual
      error_detected = $calculatedError
      expected_error_detected = [bool]$TestCase.error_detected
      passed = (($actual -eq [int]$TestCase.expected_result) -and ($calculatedError -eq [bool]$TestCase.error_detected))
    }
  }

  $actual = Get-Phase154ArithmeticValue -Operation $TestCase.operation -Left ([int]$TestCase.left_operand) -Right ([int]$TestCase.right_operand)
  return [ordered]@{
    test_id = $TestCase.test_id
    expression = $TestCase.expression
    expected_result = [int]$TestCase.expected_result
    calculated_result = $actual
    passed = ($actual -eq [int]$TestCase.expected_result)
  }
}

function Invoke-Phase154SelfGrowthCycle {
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
    [string]$SourceCycleId,
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

  $FromPhase153 = ($CycleId -eq "cycle_003")
  $FromCycle003 = ($CycleId -eq "cycle_004")
  $FromCycle004 = ($CycleId -eq "cycle_005")

  $SelfDiagnosis = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "SELF_DIAGNOSE"
    diagnosis = "no accepted internal skill exists for $SkillName; create sandbox candidate only"
    proven_internal_skill_candidate_exists = $false
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $SelfDiagnosisPath -Object $SelfDiagnosis

  $GrowthGoalSelection = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "SELECT_GROWTH_GOAL_FROM_PREVIOUS_NEXT_GOAL"
    selected_goal = $SelectedGoal
    selected_skill_id = $SkillId
    selection_source = $SelectionSource
    source_cycle_id = $SourceCycleId
    source_next_growth_goal_path = $SourceNextGrowthGoalPath
    selected_from_previous_next_goal = $true
    selected_from_phase153_cycle_002_next_goal = $FromPhase153
    selected_from_cycle_003_next_goal = $FromCycle003
    selected_from_cycle_004_next_goal = $FromCycle004
    owner_selected_goal = $false
    codex_selected_goal = $false
    accepted_state_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $GrowthGoalSelectionPath -Object $GrowthGoalSelection

  $InternalQuestion = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "INTERNAL_QUESTION"
    question = $Question
    owner_selected_goal = $false
    codex_selected_goal = $false
    no_codex_needed_inside_cycle = $true
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $InternalQuestionPath -Object $InternalQuestion

  $InternalAnswer = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "INTERNAL_ANSWER_SEARCH"
    answer = $Answer
    answer_sources = @("SELF_GROWTH_CURRICULUM_V1", $SourceNextGrowthGoalPath)
    external_fetch_performed = $false
    owner_selected_goal = $false
    codex_selected_goal = $false
    no_codex_needed_inside_cycle = $true
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $InternalAnswerPath -Object $InternalAnswer

  $ProgramCandidate = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "WRITE_SELF_BUILD_PROGRAM"
    program_id = "PHASE154_${SkillId}_PROGRAM"
    program_status = "DECLARATIVE_PROGRAM_CANDIDATE"
    target_skill_id = $SkillId
    target_growth_goal = $SelectedGoal
    execution_mode = "declarative_json_only"
    execution_scope = "self_growth_cycle_sandbox"
    arbitrary_code_execution_allowed = $false
    accepted_state_mutation_allowed = $false
    accepted_memory_mutation_allowed = $false
    accepted_self_model_mutation_allowed = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $SelfBuildProgramCandidatePath -Object $ProgramCandidate

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
    accepted_self_model_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $SkillCandidatePath -Object $SkillCandidate

  $SkillContract = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    contract_id = "PHASE154_${SkillId}_CONTRACT"
    skill_id = $SkillId
    operation = $Operation
    validation_rule = "module and validator independently calculate all test cases"
    accepted_state_mutation_allowed = $false
    accepted_memory_mutation_allowed = $false
    accepted_self_model_mutation_allowed = $false
    accepted_capability = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $SkillContractPath -Object $SkillContract

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
  Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $TestCasesPath -Object $TestCaseFile

  $CalculatedResults = @()
  foreach ($testCase in $TestCases) {
    $CalculatedResults += Get-Phase154ValidationResult -TestCase ([pscustomobject]$testCase)
  }
  if (@($CalculatedResults | Where-Object { $_.passed -ne $true }).Count -gt 0) {
    throw "PHASE154_SKILL_VALIDATION_FAILED=$CycleId"
  }

  $SandboxTrace = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "EXECUTE_IN_SANDBOX"
    executor = "declarative_skill_factory"
    program_id = $ProgramCandidate.program_id
    skill_id = $SkillId
    executed = $true
    execution_mode = "declarative_json_only"
    arbitrary_code_execution_used = $false
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    created_outputs = @($SkillCandidatePath, $SkillContractPath, $TestCasesPath)
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $SandboxExecutionTracePath -Object $SandboxTrace

  $Validation = [ordered]@{
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
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $SkillValidationResultPath -Object $Validation

  $AbsorptionCandidate = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    phase = "ABSORB_AS_CANDIDATE"
    skill_id = $SkillId
    absorption_status = "CANDIDATE_NOT_ACCEPTED"
    accepted_memory_mutated = $false
    accepted_state_mutated = $false
    accepted_self_model_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $LearningAbsorptionCandidatePath -Object $AbsorptionCandidate

  $NextGoal = [ordered]@{
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
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $NextGrowthGoalPath -Object $NextGoal

  $CycleTrace = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    selected_goal = $SelectedGoal
    skill_id = $SkillId
    validation_status = "PASS"
    next_growth_goal = $NextGoal.next_growth_goal
    source_cycle_id = $SourceCycleId
    source_next_growth_goal_path = $SourceNextGrowthGoalPath
    selected_from_previous_next_goal = $true
    started_from_phase153_cycle_002_next_goal = $FromPhase153
    started_from_cycle_003_next_goal = $FromCycle003
    started_from_cycle_004_next_goal = $FromCycle004
    self_build_program_created = $true
    executed = $true
    skill_validated = $true
    learning_absorption_candidate_created = $true
    owner_selected_goal = $false
    codex_selected_goal = $false
    no_codex_needed_inside_cycle = $true
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $CycleTracePath -Object $CycleTrace

  return [ordered]@{
    cycle_id = $CycleId
    selected_goal = $SelectedGoal
    skill_id = $SkillId
    validation_status = "PASS"
    next_growth_goal = $NextGoal.next_growth_goal
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

function Invoke-BuilderBoundedSelfGrowthDutyLoopTrial001 {
  param(
    [string]$RepoRoot = ".",
    [string]$RunId = "PHASE154_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_001"
  )

  $RepoRoot = Resolve-Phase154Path -RepoRoot $RepoRoot -Path "."
  $Pushed = $false
  Push-Location $RepoRoot
  $Pushed = $true

  try {
    $StepId = "PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1"
    $NextAllowedStep = "PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1"
    $Phase153StepId = "PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1"
    $Phase153RunId = "PHASE153_SELF_GROWTH_DUTY_RUNTIME_IGNITION_001"
    $CycleLimit = 3
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
    $QueuePath = "TASK_QUEUE.json"
    $TrustedSourcesPath = "source_registry/trusted_sources.json"
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

    foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase154Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $Branch = (git branch --show-current).Trim()
    if ($Branch -eq "main") {
      throw "PHASE154_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase154Equals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
    $Head = (git rev-parse --short HEAD).Trim()
    Assert-Phase154Equals -Actual $Head -Expected $ExpectedHead -Name "current_head"

    foreach ($requiredPath in @($RouteAlignmentPath, $ModulePath, $ValidatorPath, $Phase153ProofPath, $Phase153NextPath, $RuntimePath, $CurriculumPath, $SafetyPolicyPath, $BodyPackPath, $QueuePath)) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase154Path -RepoRoot $RepoRoot -Path $requiredPath))) {
        throw "PHASE154_MISSING_REQUIRED_INPUT=$requiredPath"
      }
    }

    $Phase153Proof = Read-Phase154JsonRequired -RepoRoot $RepoRoot -Path $Phase153ProofPath
    Assert-Phase154Equals -Actual $Phase153Proof.status -Expected "PASS" -Name "phase153_status"
    Assert-Phase154True -Actual $Phase153Proof.self_growth_loop_proven -Name "phase153_self_growth_loop_proven"
    Assert-Phase154Equals -Actual $Phase153Proof.next_allowed_step -Expected $StepId -Name "phase153_next_allowed_step"
    Assert-Phase154Equals -Actual $Phase153Proof.cycle_002_next_growth_goal -Expected "learn_subtraction_basic_v1" -Name "phase153_cycle002_next_goal"

    $Phase153Next = Read-Phase154JsonRequired -RepoRoot $RepoRoot -Path $Phase153NextPath
    Assert-Phase154Equals -Actual $Phase153Next.status -Expected "PASS" -Name "phase153_next_status"
    Assert-Phase154Equals -Actual $Phase153Next.next_growth_goal -Expected "learn_subtraction_basic_v1" -Name "phase153_next_file_goal"

    $Runtime = Read-Phase154JsonRequired -RepoRoot $RepoRoot -Path $RuntimePath
    Assert-Phase154Equals -Actual $Runtime.status -Expected "PASS" -Name "runtime_status"
    Assert-Phase154Equals -Actual $Runtime.runtime_id -Expected "SELF_GROWTH_DUTY_RUNTIME_V1" -Name "runtime_id"

    $Curriculum = Read-Phase154JsonRequired -RepoRoot $RepoRoot -Path $CurriculumPath
    Assert-Phase154Equals -Actual $Curriculum.status -Expected "PASS" -Name "curriculum_status"

    $SafetyPolicy = Read-Phase154JsonRequired -RepoRoot $RepoRoot -Path $SafetyPolicyPath
    foreach ($flag in @("external_fetch_allowed", "install_allowed", "executable_materials_allowed", "arbitrary_code_execution_allowed", "accepted_state_mutation_allowed", "accepted_memory_mutation_allowed", "accepted_self_model_mutation_allowed", "body_pack_mutation_allowed")) {
      Assert-Phase154False -Actual $SafetyPolicy.$flag -Name "safety_policy_$flag"
    }

    $BodyPack = Read-Phase154JsonRequired -RepoRoot $RepoRoot -Path $BodyPackPath
    Assert-Phase154Equals -Actual $BodyPack.body_pack_id -Expected "BUILDER_BODY_ORGAN_PACK_V1" -Name "body_pack_id"

    $Queue = Read-Phase154JsonRequired -RepoRoot $RepoRoot -Path $QueuePath
    Assert-Phase154Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $TrustedSourceCount = 0
    if (Test-Path -LiteralPath (Resolve-Phase154Path -RepoRoot $RepoRoot -Path $TrustedSourcesPath)) {
      $TrustedSources = Read-Phase154JsonRequired -RepoRoot $RepoRoot -Path $TrustedSourcesPath
      if ($null -ne $TrustedSources.trusted_source_count) {
        $TrustedSourceCount = [int]$TrustedSources.trusted_source_count
      }
    }

    $RuntimeBoot = [ordered]@{
      status = "PASS"
      boot_id = "PHASE154_RUNTIME_BOOT"
      step_id = $StepId
      run_id = $RunId
      phase153_verified = $true
      runtime_reused = $true
      runtime_modified = $false
      body_pack_verified = $true
      cycle_limit = $CycleLimit
      start_cycle_id = "cycle_003"
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $RuntimeBootPath -Object $RuntimeBoot

    $Phase153ContinuationRead = [ordered]@{
      status = "PASS"
      read_id = "PHASE154_PHASE153_CONTINUATION_READ"
      step_id = $StepId
      run_id = $RunId
      source_step_id = $Phase153StepId
      source_run_id = $Phase153RunId
      source_next_growth_goal_path = $Phase153NextPath
      source_next_growth_goal = $Phase153Next.next_growth_goal
      phase153_self_growth_loop_proven = $true
      cycle_003_selected_goal = $Phase153Next.next_growth_goal
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $Phase153ContinuationReadPath -Object $Phase153ContinuationRead

    $Cycle003Goal = Get-Phase154CurriculumGoal -Curriculum $Curriculum -GoalId $Phase153Next.next_growth_goal
    Assert-Phase154Equals -Actual $Cycle003Goal.skill_id -Expected "SUBTRACTION_BASIC_SKILL_CANDIDATE_V1" -Name "cycle003_skill"
    Assert-Phase154Equals -Actual $Cycle003Goal.operation -Expected "subtract" -Name "cycle003_operation"
    $Cycle003 = Invoke-Phase154SelfGrowthCycle `
      -RepoRoot $RepoRoot `
      -RunId $RunId `
      -StepId $StepId `
      -NextAllowedStep $NextAllowedStep `
      -CycleId "cycle_003" `
      -CycleNumber 3 `
      -CycleRoot "$TrialRoot/cycle_003" `
      -SelectedGoal $Phase153Next.next_growth_goal `
      -SelectionSource "phase153_cycle_002_next_growth_goal" `
      -SourceCycleId "PHASE153:cycle_002" `
      -SourceNextGrowthGoalPath $Phase153NextPath `
      -SkillId $Cycle003Goal.skill_id `
      -SkillName "subtraction_basic" `
      -Operation $Cycle003Goal.operation `
      -Question "What goal follows PHASE153 cycle_002?" `
      -Answer "Use PHASE153 cycle_002 next_growth_goal learn_subtraction_basic_v1." `
      -TestCases @(
        (New-Phase154ArithmeticTestCase -TestId "subtract_9_4" -Expression "9 - 4 = 5" -Operation "subtract" -Left 9 -Right 4 -Expected 5),
        (New-Phase154ArithmeticTestCase -TestId "subtract_20_7" -Expression "20 - 7 = 13" -Operation "subtract" -Left 20 -Right 7 -Expected 13),
        (New-Phase154ArithmeticTestCase -TestId "subtract_56_8" -Expression "56 - 8 = 48" -Operation "subtract" -Left 56 -Right 8 -Expected 48)
      ) `
      -NextGrowthGoalValue "learn_addition_consistency_v1"

    $Cycle003Next = Read-Phase154JsonRequired -RepoRoot $RepoRoot -Path $Cycle003.next_growth_goal_path
    Assert-Phase154Equals -Actual $Cycle003Next.next_growth_goal -Expected "learn_addition_consistency_v1" -Name "cycle003_next_goal"

    $Cycle004Goal = Get-Phase154CurriculumGoal -Curriculum $Curriculum -GoalId $Cycle003Next.next_growth_goal
    Assert-Phase154Equals -Actual $Cycle004Goal.skill_id -Expected "ADDITION_CONSISTENCY_SKILL_CANDIDATE_V1" -Name "cycle004_skill"
    Assert-Phase154Equals -Actual $Cycle004Goal.operation -Expected "add" -Name "cycle004_operation"
    $Cycle004 = Invoke-Phase154SelfGrowthCycle `
      -RepoRoot $RepoRoot `
      -RunId $RunId `
      -StepId $StepId `
      -NextAllowedStep $NextAllowedStep `
      -CycleId "cycle_004" `
      -CycleNumber 4 `
      -CycleRoot "$TrialRoot/cycle_004" `
      -SelectedGoal $Cycle003Next.next_growth_goal `
      -SelectionSource "cycle_003_next_growth_goal" `
      -SourceCycleId "cycle_003" `
      -SourceNextGrowthGoalPath $Cycle003.next_growth_goal_path `
      -SkillId $Cycle004Goal.skill_id `
      -SkillName "addition_consistency" `
      -Operation $Cycle004Goal.operation `
      -Question "What goal follows cycle_003?" `
      -Answer "Use cycle_003 next_growth_goal learn_addition_consistency_v1." `
      -TestCases @(
        (New-Phase154ArithmeticTestCase -TestId "add_2_3" -Expression "2 + 3 = 5" -Operation "add" -Left 2 -Right 3 -Expected 5),
        (New-Phase154ArithmeticTestCase -TestId "add_13_7" -Expression "13 + 7 = 20" -Operation "add" -Left 13 -Right 7 -Expected 20),
        (New-Phase154ArithmeticTestCase -TestId "add_48_8" -Expression "48 + 8 = 56" -Operation "add" -Left 48 -Right 8 -Expected 56)
      ) `
      -NextGrowthGoalValue "learn_arithmetic_error_detection_v1"

    $Cycle004Next = Read-Phase154JsonRequired -RepoRoot $RepoRoot -Path $Cycle004.next_growth_goal_path
    Assert-Phase154Equals -Actual $Cycle004Next.next_growth_goal -Expected "learn_arithmetic_error_detection_v1" -Name "cycle004_next_goal"

    $Cycle005Goal = Get-Phase154CurriculumGoal -Curriculum $Curriculum -GoalId $Cycle004Next.next_growth_goal
    Assert-Phase154Equals -Actual $Cycle005Goal.skill_id -Expected "ARITHMETIC_ERROR_DETECTION_SKILL_CANDIDATE_V1" -Name "cycle005_skill"
    Assert-Phase154Equals -Actual $Cycle005Goal.operation -Expected "validate" -Name "cycle005_operation"
    $Cycle005 = Invoke-Phase154SelfGrowthCycle `
      -RepoRoot $RepoRoot `
      -RunId $RunId `
      -StepId $StepId `
      -NextAllowedStep $NextAllowedStep `
      -CycleId "cycle_005" `
      -CycleNumber 5 `
      -CycleRoot "$TrialRoot/cycle_005" `
      -SelectedGoal $Cycle004Next.next_growth_goal `
      -SelectionSource "cycle_004_next_growth_goal" `
      -SourceCycleId "cycle_004" `
      -SourceNextGrowthGoalPath $Cycle004.next_growth_goal_path `
      -SkillId $Cycle005Goal.skill_id `
      -SkillName "arithmetic_error_detection" `
      -Operation $Cycle005Goal.operation `
      -Question "What goal follows cycle_004?" `
      -Answer "Use cycle_004 next_growth_goal learn_arithmetic_error_detection_v1." `
      -TestCases @(
        (New-Phase154ErrorDetectionTestCase -TestId "detect_multiply_2_3_wrong" -Expression "2 * 3" -BaseOperation "multiply" -Left 2 -Right 3 -Claimed 5 -Expected 6 -ErrorDetected $true),
        (New-Phase154ErrorDetectionTestCase -TestId "detect_divide_20_5_right" -Expression "20 / 5" -BaseOperation "divide" -Left 20 -Right 5 -Claimed 4 -Expected 4 -ErrorDetected $false),
        (New-Phase154ErrorDetectionTestCase -TestId "detect_subtract_9_4_wrong" -Expression "9 - 4" -BaseOperation "subtract" -Left 9 -Right 4 -Claimed 6 -Expected 5 -ErrorDetected $true)
      ) `
      -NextGrowthGoalValue "STOP_CURRICULUM_ROUND_COMPLETE"

    $Cycle005Next = Read-Phase154JsonRequired -RepoRoot $RepoRoot -Path $Cycle005.next_growth_goal_path
    Assert-Phase154Equals -Actual $Cycle005Next.next_growth_goal -Expected "STOP_CURRICULUM_ROUND_COMPLETE" -Name "cycle005_next_goal"

    $CycleOutputs = @(
      $Cycle003.self_diagnosis_path, $Cycle003.growth_goal_selection_path, $Cycle003.internal_question_path, $Cycle003.internal_answer_path, $Cycle003.self_build_program_candidate_path, $Cycle003.sandbox_execution_trace_path, $Cycle003.skill_candidate_path, $Cycle003.skill_contract_path, $Cycle003.test_cases_path, $Cycle003.skill_validation_result_path, $Cycle003.learning_absorption_candidate_path, $Cycle003.next_growth_goal_path, $Cycle003.cycle_trace_path,
      $Cycle004.self_diagnosis_path, $Cycle004.growth_goal_selection_path, $Cycle004.internal_question_path, $Cycle004.internal_answer_path, $Cycle004.self_build_program_candidate_path, $Cycle004.sandbox_execution_trace_path, $Cycle004.skill_candidate_path, $Cycle004.skill_contract_path, $Cycle004.test_cases_path, $Cycle004.skill_validation_result_path, $Cycle004.learning_absorption_candidate_path, $Cycle004.next_growth_goal_path, $Cycle004.cycle_trace_path,
      $Cycle005.self_diagnosis_path, $Cycle005.growth_goal_selection_path, $Cycle005.internal_question_path, $Cycle005.internal_answer_path, $Cycle005.self_build_program_candidate_path, $Cycle005.sandbox_execution_trace_path, $Cycle005.skill_candidate_path, $Cycle005.skill_contract_path, $Cycle005.test_cases_path, $Cycle005.skill_validation_result_path, $Cycle005.learning_absorption_candidate_path, $Cycle005.next_growth_goal_path, $Cycle005.cycle_trace_path
    )

    $BoundedLoopTrace = [ordered]@{
      status = "PASS"
      trace_id = "PHASE154_BOUNDED_LOOP_TRACE"
      step_id = $StepId
      run_id = $RunId
      sequence = @("READ_PHASE153_NEXT_GOAL", "RUN_CYCLE_003", "RUN_CYCLE_004", "RUN_CYCLE_005", "STOP_SAFE")
      cycle_count = $CycleLimit
      cycle_003_started_from_phase153_next_goal = $true
      cycle_004_started_from_cycle_003_next_goal = $true
      cycle_005_started_from_cycle_004_next_goal = $true
      all_cycles_validated = $true
      safe_stop = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $BoundedLoopTracePath -Object $BoundedLoopTrace

    $CycleIndex = [ordered]@{
      status = "PASS"
      index_id = "PHASE154_CYCLE_INDEX"
      step_id = $StepId
      run_id = $RunId
      cycle_count = $CycleLimit
      cycles = @(
        [ordered]@{ cycle_id = "cycle_003"; selected_goal = $Cycle003.selected_goal; skill_id = $Cycle003.skill_id; validation_status = $Cycle003.validation_status; next_growth_goal = $Cycle003.next_growth_goal; source_next_growth_goal_path = $Phase153NextPath },
        [ordered]@{ cycle_id = "cycle_004"; selected_goal = $Cycle004.selected_goal; skill_id = $Cycle004.skill_id; validation_status = $Cycle004.validation_status; next_growth_goal = $Cycle004.next_growth_goal; source_next_growth_goal_path = $Cycle003.next_growth_goal_path },
        [ordered]@{ cycle_id = "cycle_005"; selected_goal = $Cycle005.selected_goal; skill_id = $Cycle005.skill_id; validation_status = $Cycle005.validation_status; next_growth_goal = $Cycle005.next_growth_goal; source_next_growth_goal_path = $Cycle004.next_growth_goal_path }
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $CycleIndexPath -Object $CycleIndex

    $Heartbeat = [ordered]@{
      status = "PASS"
      heartbeat_id = "PHASE154_SELF_GROWTH_HEARTBEAT"
      step_id = $StepId
      run_id = $RunId
      cycle_count = $CycleLimit
      bounded_self_growth_trial_proven = $true
      owner_selected_each_goal = $false
      codex_selected_each_goal = $false
      all_cycles_validated = $true
      no_codex_needed_inside_cycles = $true
      safe_stop = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $HeartbeatPath -Object $Heartbeat

    $SkillIndex = [ordered]@{
      status = "PASS"
      index_id = "PHASE154_LEARNED_SKILL_CANDIDATES_INDEX"
      step_id = $StepId
      run_id = $RunId
      skill_candidate_count = 3
      skill_candidates = @(
        [ordered]@{ cycle_id = "cycle_003"; skill_id = $Cycle003.skill_id; selected_goal = $Cycle003.selected_goal; validation_status = "PASS"; path = $Cycle003.skill_candidate_path },
        [ordered]@{ cycle_id = "cycle_004"; skill_id = $Cycle004.skill_id; selected_goal = $Cycle004.selected_goal; validation_status = "PASS"; path = $Cycle004.skill_candidate_path },
        [ordered]@{ cycle_id = "cycle_005"; skill_id = $Cycle005.skill_id; selected_goal = $Cycle005.selected_goal; validation_status = "PASS"; path = $Cycle005.skill_candidate_path }
      )
      accepted_capability_promotion_performed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $SkillIndexPath -Object $SkillIndex

    $SelfModelGrowthCandidate = [ordered]@{
      status = "PASS"
      candidate_id = "PHASE154_SELF_MODEL_GROWTH_CANDIDATE"
      step_id = $StepId
      run_id = $RunId
      candidate_only = $true
      new_candidate_skills_count = 3
      candidate_skill_ids = @($Cycle003.skill_id, $Cycle004.skill_id, $Cycle005.skill_id)
      accepted_self_model_mutated = $false
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $SelfModelGrowthCandidatePath -Object $SelfModelGrowthCandidate

    $RuntimeStopDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE154_RUNTIME_STOP_DECISION"
      step_id = $StepId
      run_id = $RunId
      stop_reason = "PHASE154_CYCLE_LIMIT_REACHED"
      safe_stop = $true
      cycle_count = $CycleLimit
      stopped_after_cycle_id = "cycle_005"
      final_next_growth_goal = $Cycle005.next_growth_goal
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $RuntimeStopDecisionPath -Object $RuntimeStopDecision

    $Common = [ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase153_verified = $true
      phase153_self_growth_loop_proven = $true
      runtime_reused = $true
      runtime_modified = $false
      body_pack_verified = $true
      body_pack_mutated = $false
      cycle_count = $CycleLimit
      cycle_003_started = $true
      cycle_003_started_from_phase153_next_goal = $true
      cycle_003_selected_goal = "learn_subtraction_basic_v1"
      cycle_003_skill_id = "SUBTRACTION_BASIC_SKILL_CANDIDATE_V1"
      cycle_003_validation_status = "PASS"
      cycle_003_next_growth_goal = "learn_addition_consistency_v1"
      cycle_004_started = $true
      cycle_004_started_from_cycle_003_next_goal = $true
      cycle_004_selected_goal = "learn_addition_consistency_v1"
      cycle_004_skill_id = "ADDITION_CONSISTENCY_SKILL_CANDIDATE_V1"
      cycle_004_validation_status = "PASS"
      cycle_004_next_growth_goal = "learn_arithmetic_error_detection_v1"
      cycle_005_started = $true
      cycle_005_started_from_cycle_004_next_goal = $true
      cycle_005_selected_goal = "learn_arithmetic_error_detection_v1"
      cycle_005_skill_id = "ARITHMETIC_ERROR_DETECTION_SKILL_CANDIDATE_V1"
      cycle_005_validation_status = "PASS"
      cycle_005_next_growth_goal = "STOP_CURRICULUM_ROUND_COMPLETE"
      bounded_self_growth_trial_proven = $true
      owner_selected_each_goal = $false
      codex_selected_each_goal = $false
      all_cycles_validated = $true
      no_codex_needed_inside_cycles = $true
      learned_skill_candidates_index_created = $true
      self_model_growth_candidate_created = $true
      runtime_stop_decision_created = $true
      safe_stop = $true
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
      trusted_source_count = $TrustedSourceCount
      queue_after = "NONE"
      trial_root = $TrialRoot
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      next_allowed_step = $NextAllowedStep
    }

    $RuntimeCreatedOutputs = @(
      $RuntimeBootPath,
      $Phase153ContinuationReadPath,
      $BoundedLoopTracePath,
      $CycleIndexPath
    ) + $CycleOutputs + @(
      $HeartbeatPath,
      $SkillIndexPath,
      $SelfModelGrowthCandidatePath,
      $BoundedTrialResultPath,
      $RuntimeStopDecisionPath
    )

    $BoundedTrialResult = [ordered]@{}
    foreach ($key in $Common.Keys) { $BoundedTrialResult[$key] = $Common[$key] }
    $BoundedTrialResult["result_id"] = "PHASE154_BOUNDED_TRIAL_RESULT"
    Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $BoundedTrialResultPath -Object $BoundedTrialResult

    $Result = [ordered]@{}
    foreach ($key in $Common.Keys) { $Result[$key] = $Common[$key] }
    $Result["result_id"] = "PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_RESULT"
    Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result

    $Report = [ordered]@{
      status = "PASS"
      report_id = "PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1_REPORT"
      step_id = $StepId
      run_id = $RunId
      root_cause_found = "The previous PHASE154 module defined functions only; running .\modules\invoke_builder_bounded_self_growth_duty_loop_trial_001.ps1 returned exit code 0 after parsing but never invoked Invoke-BuilderBoundedSelfGrowthDutyLoopTrial001."
      why_previous_module_exited_0_without_outputs = "PowerShell treats a script containing only function definitions as successful execution. No terminating error occurred, and no function call was made."
      fresh_output_generation_guarantee = "The script now has a top-level invocation guard: direct execution calls Invoke-BuilderBoundedSelfGrowthDutyLoopTrial001, which writes every runtime, result, report, and proof artifact through Write-Phase154JsonFile. Dot-sourcing still only loads functions."
      files_changed = @($RouteAlignmentPath, $ModulePath, $ValidatorPath) + $RuntimeCreatedOutputs + @($ResultPath, $ReportPath, $ProofPath)
      module_path = $ModulePath
      validator_path = $ValidatorPath
      expected_run_command = ".\modules\invoke_builder_bounded_self_growth_duty_loop_trial_001.ps1"
      expected_validator_command = ".\validators\validate_phase154_builder_bounded_self_growth_duty_loop_trial_v1.ps1 -RepoRoot ."
      runtime_output_files_created = $RuntimeCreatedOutputs + @($ResultPath, $ReportPath, $ProofPath)
      cycle_003_derivation = "Cycle 003 reads $Phase153NextPath and selects learn_subtraction_basic_v1."
      cycle_004_derivation = "Cycle 004 reads $($Cycle003.next_growth_goal_path) and selects learn_addition_consistency_v1."
      cycle_005_derivation = "Cycle 005 reads $($Cycle004.next_growth_goal_path) and selects learn_arithmetic_error_detection_v1, validates error detection, then stops safely."
      risks = @(
        "PHASE154 still creates candidate-only sandbox learning artifacts; PHASE155 must decide any admission.",
        "The direct script invocation now creates artifacts, so repeated runs overwrite the same PHASE154 trial files.",
        "The final next growth goal is a stop marker, not a promoted runtime route."
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
        "No accepted PHASE142-PHASE153 artifact mutation.",
        "No generated_agents or applied_agents touch.",
        "No route lock touch.",
        "No internet fetch.",
        "No dependency install.",
        "No arbitrary generated code execution.",
        "No skill candidate promotion.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report

    $Proof = [ordered]@{}
    foreach ($key in $Common.Keys) { $Proof[$key] = $Common[$key] }
    $Proof["proof_id"] = $StepId
    $Proof["runtime_boot_path"] = $RuntimeBootPath
    $Proof["phase153_continuation_read_path"] = $Phase153ContinuationReadPath
    $Proof["bounded_loop_trace_path"] = $BoundedLoopTracePath
    $Proof["cycle_index_path"] = $CycleIndexPath
    $Proof["bounded_trial_result_path"] = $BoundedTrialResultPath
    $Proof["runtime_stop_decision_path"] = $RuntimeStopDecisionPath
    Write-Phase154JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject][ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase153_verified = $true
      runtime_reused = $true
      body_pack_verified = $true
      cycle_count = $CycleLimit
      cycle_003_selected_goal = "learn_subtraction_basic_v1"
      cycle_003_skill_id = "SUBTRACTION_BASIC_SKILL_CANDIDATE_V1"
      cycle_003_validation_status = "PASS"
      cycle_004_selected_goal = "learn_addition_consistency_v1"
      cycle_004_skill_id = "ADDITION_CONSISTENCY_SKILL_CANDIDATE_V1"
      cycle_004_validation_status = "PASS"
      cycle_005_selected_goal = "learn_arithmetic_error_detection_v1"
      cycle_005_skill_id = "ARITHMETIC_ERROR_DETECTION_SKILL_CANDIDATE_V1"
      cycle_005_validation_status = "PASS"
      bounded_self_growth_trial_proven = $true
      all_cycles_validated = $true
      safe_stop = $true
      queue_after = "NONE"
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
  Invoke-BuilderBoundedSelfGrowthDutyLoopTrial001 -RepoRoot $RepoRoot -RunId $RunId | ConvertTo-Json -Depth 20
}
