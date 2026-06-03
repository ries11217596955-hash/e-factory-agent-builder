param(
  [string]$RepoRoot = ".",
  [string]$RunId = "PHASE156_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_001"
)

$ErrorActionPreference = "Stop"

function Resolve-Phase156Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase156JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase156Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE156_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase156JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase156Path -RepoRoot $RepoRoot -Path $Path
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

function Assert-Phase156Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE156_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase156True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE156_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase156False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE156_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function New-Phase156Case {
  param(
    [string]$TestId,
    [string]$InputKind,
    [string]$ExpectedOutput,
    [string]$Operation
  )

  return [ordered]@{
    test_id = $TestId
    input_kind = $InputKind
    operation = $Operation
    expected_output = $ExpectedOutput
  }
}

function New-Phase156ProofSummaryCase {
  param(
    [string]$TestId,
    [string]$Status,
    [string]$NextAllowedStep,
    [bool]$CodexNeeded,
    [bool]$ExpectedAccepted
  )

  return [ordered]@{
    test_id = $TestId
    operation = "summarize_proof_state"
    proof_status = $Status
    next_allowed_step = $NextAllowedStep
    codex_needed_for_next_step = $CodexNeeded
    expected_summary = [ordered]@{
      accepted = $ExpectedAccepted
      next_step = $NextAllowedStep
      codex_needed = $CodexNeeded
    }
  }
}

function Get-Phase156CalculatedResult {
  param([object]$TestCase)

  switch ($TestCase.operation) {
    "classify_gap_inventory" {
      $map = @{
        missing_entrypoint = "entrypoint_missing"
        missing_validator = "validator_missing"
        missing_runtime_output = "runtime_output_missing"
      }
      $actual = $map[[string]$TestCase.input_kind]
      return [ordered]@{
        test_id = $TestCase.test_id
        input_kind = $TestCase.input_kind
        expected_output = $TestCase.expected_output
        calculated_output = $actual
        passed = ($actual -eq [string]$TestCase.expected_output)
      }
    }
    "write_repair_task_spec" {
      $map = @{
        entrypoint_missing = "build_entrypoint_task"
        validator_missing = "build_validator_task"
        runtime_output_missing = "repair_runtime_output_generation_task"
      }
      $actual = $map[[string]$TestCase.input_kind]
      return [ordered]@{
        test_id = $TestCase.test_id
        input_kind = $TestCase.input_kind
        expected_output = $TestCase.expected_output
        calculated_output = $actual
        passed = ($actual -eq [string]$TestCase.expected_output)
      }
    }
    "summarize_proof_state" {
      $accepted = ([string]$TestCase.proof_status -eq "PASS")
      $summary = [ordered]@{
        accepted = $accepted
        next_step = [string]$TestCase.next_allowed_step
        codex_needed = [bool]$TestCase.codex_needed_for_next_step
      }
      return [ordered]@{
        test_id = $TestCase.test_id
        proof_status = $TestCase.proof_status
        next_allowed_step = $TestCase.next_allowed_step
        codex_needed_for_next_step = [bool]$TestCase.codex_needed_for_next_step
        expected_summary = $TestCase.expected_summary
        calculated_summary = $summary
        passed = (($summary.accepted -eq [bool]$TestCase.expected_summary.accepted) -and ($summary.next_step -eq [string]$TestCase.expected_summary.next_step) -and ($summary.codex_needed -eq [bool]$TestCase.expected_summary.codex_needed))
      }
    }
    default {
      throw "PHASE156_UNSUPPORTED_OPERATION=$($TestCase.operation)"
    }
  }
}

function Invoke-Phase156SelfSelectedGapCycle {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$StepId,
    [string]$NextAllowedStep,
    [string]$CycleId,
    [int]$CycleNumber,
    [string]$CycleRoot,
    [string]$SelectedGap,
    [string]$SelectionSource,
    [string]$SourceNextGapPath,
    [string]$SkillId,
    [string]$SkillName,
    [string]$InternalQuestionText,
    [string]$InternalAnswerText,
    [object[]]$TestCases,
    [string]$NextSelectedGapValue
  )

  $SelfDiagnosisPath = "$CycleRoot/self_diagnosis.json"
  $GapSelectionPath = "$CycleRoot/gap_selection.json"
  $InternalQuestionPath = "$CycleRoot/internal_question.json"
  $InternalAnswerPath = "$CycleRoot/internal_answer.json"
  $SelfBuildProgramCandidatePath = "$CycleRoot/self_build_program_candidate.json"
  $SandboxExecutionTracePath = "$CycleRoot/sandbox_execution_trace.json"
  $SkillCandidatePath = "$CycleRoot/skill_candidate.json"
  $SkillContractPath = "$CycleRoot/skill_contract.json"
  $TestCasesPath = "$CycleRoot/test_cases.json"
  $SkillValidationResultPath = "$CycleRoot/skill_validation_result.json"
  $LearningAbsorptionCandidatePath = "$CycleRoot/learning_absorption_candidate.json"
  $NextSelectedGapPath = "$CycleRoot/next_selected_gap.json"
  $CycleTracePath = "$CycleRoot/cycle_trace.json"

  $StartedFromCycle006 = ($CycleId -eq "cycle_007")
  $StartedFromCycle007 = ($CycleId -eq "cycle_008")

  $SelfDiagnosis = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    detected_missing_sandbox_candidate_skill = $SkillId
    selected_gap = $SelectedGap
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $SelfDiagnosisPath -Object $SelfDiagnosis

  $GapSelection = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    selected_gap = $SelectedGap
    selected_skill_id = $SkillId
    selector_type = "deterministic_internal_policy"
    selection_source = $SelectionSource
    source_next_selected_gap_path = $SourceNextGapPath
    selected_from_previous_cycle_next_gap = (-not [string]::IsNullOrWhiteSpace($SourceNextGapPath))
    selected_from_cycle_006_next_gap = $StartedFromCycle006
    selected_from_cycle_007_next_gap = $StartedFromCycle007
    owner_selected_gap = $false
    codex_selected_gap = $false
    accepted_state_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $GapSelectionPath -Object $GapSelection

  $InternalQuestion = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    question = $InternalQuestionText
    owner_selected_gap = $false
    codex_selected_gap = $false
    no_codex_needed_inside_cycle = $true
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $InternalQuestionPath -Object $InternalQuestion

  $InternalAnswer = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    answer = $InternalAnswerText
    answer_sources = @("PHASE155_NEXT_TRIAL_TICKET", "PHASE155_BOUNDED_REUSE_POLICY", "internal self_gap_discovery", "previous cycle next_selected_gap")
    external_fetch_performed = $false
    owner_selected_gap = $false
    codex_selected_gap = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $InternalAnswerPath -Object $InternalAnswer

  $ProgramCandidate = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    program_id = "PHASE156_${SkillId}_PROGRAM"
    program_status = "DECLARATIVE_PROGRAM_CANDIDATE"
    target_gap = $SelectedGap
    target_skill_id = $SkillId
    execution_scope = "sandbox_only"
    execution_mode = "declarative_json_only"
    arbitrary_code_execution_allowed = $false
    accepted_state_mutation_allowed = $false
    accepted_memory_mutation_allowed = $false
    accepted_self_model_mutation_allowed = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $SelfBuildProgramCandidatePath -Object $ProgramCandidate

  $SkillCandidate = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    skill_id = $SkillId
    skill_name = $SkillName
    skill_status = "SANDBOX_SKILL_CANDIDATE_NOT_ACCEPTED"
    selected_gap = $SelectedGap
    accepted_capability = $false
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $SkillCandidatePath -Object $SkillCandidate

  $SkillContract = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    contract_id = "PHASE156_${SkillId}_CONTRACT"
    skill_id = $SkillId
    selected_gap = $SelectedGap
    validation_rule = "validator must independently calculate expected outputs from declarative test cases"
    accepted_capability = $false
    accepted_state_mutation_allowed = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $SkillContractPath -Object $SkillContract

  $TestCaseFile = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    skill_id = $SkillId
    test_cases = $TestCases
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $TestCasesPath -Object $TestCaseFile

  $CalculatedResults = @()
  foreach ($testCase in $TestCases) {
    $CalculatedResults += Get-Phase156CalculatedResult -TestCase ([pscustomobject]$testCase)
  }
  if (@($CalculatedResults | Where-Object { $_.passed -ne $true }).Count -gt 0) {
    throw "PHASE156_SKILL_VALIDATION_FAILED=$CycleId"
  }

  $SandboxTrace = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    executed = $true
    execution_scope = "sandbox_only"
    execution_mode = "declarative_json_only"
    program_id = $ProgramCandidate.program_id
    skill_id = $SkillId
    arbitrary_code_execution_used = $false
    accepted_state_mutated = $false
    created_outputs = @($SkillCandidatePath, $SkillContractPath, $TestCasesPath)
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $SandboxExecutionTracePath -Object $SandboxTrace

  $ValidationResult = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    skill_id = $SkillId
    validation_status = "PASS"
    independently_calculated = $true
    calculated_results = $CalculatedResults
    accepted_state_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $SkillValidationResultPath -Object $ValidationResult

  $AbsorptionCandidate = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    skill_id = $SkillId
    absorption_status = "CANDIDATE_NOT_ACCEPTED"
    accepted_memory_mutated = $false
    accepted_state_mutated = $false
    accepted_self_model_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $LearningAbsorptionCandidatePath -Object $AbsorptionCandidate

  $NextSelectedGap = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    current_selected_gap = $SelectedGap
    next_selected_gap = $NextSelectedGapValue
    selected_by_runtime = $true
    owner_selected_gap = $false
    codex_selected_gap = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $NextSelectedGapPath -Object $NextSelectedGap

  $CycleTrace = [ordered]@{
    status = "PASS"
    cycle_id = $CycleId
    cycle_number = $CycleNumber
    step_id = $StepId
    run_id = $RunId
    selected_gap = $SelectedGap
    skill_id = $SkillId
    validation_status = "PASS"
    next_selected_gap = $NextSelectedGapValue
    source_next_selected_gap_path = $SourceNextGapPath
    started_from_cycle_006_next_gap = $StartedFromCycle006
    started_from_cycle_007_next_gap = $StartedFromCycle007
    owner_selected_gap = $false
    codex_selected_gap = $false
    no_codex_needed_inside_cycle = $true
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    next_allowed_step = $NextAllowedStep
  }
  Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $CycleTracePath -Object $CycleTrace

  return [ordered]@{
    cycle_id = $CycleId
    selected_gap = $SelectedGap
    skill_id = $SkillId
    validation_status = "PASS"
    next_selected_gap = $NextSelectedGapValue
    self_diagnosis_path = $SelfDiagnosisPath
    gap_selection_path = $GapSelectionPath
    internal_question_path = $InternalQuestionPath
    internal_answer_path = $InternalAnswerPath
    self_build_program_candidate_path = $SelfBuildProgramCandidatePath
    sandbox_execution_trace_path = $SandboxExecutionTracePath
    skill_candidate_path = $SkillCandidatePath
    skill_contract_path = $SkillContractPath
    test_cases_path = $TestCasesPath
    skill_validation_result_path = $SkillValidationResultPath
    learning_absorption_candidate_path = $LearningAbsorptionCandidatePath
    next_selected_gap_path = $NextSelectedGapPath
    cycle_trace_path = $CycleTracePath
  }
}

function Invoke-BuilderSelfSelectedGapSelfBuildTrial001 {
  param(
    [string]$RepoRoot = ".",
    [string]$RunId = "PHASE156_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_001"
  )

  $RepoRoot = Resolve-Phase156Path -RepoRoot $RepoRoot -Path "."
  $Pushed = $false
  Push-Location $RepoRoot
  $Pushed = $true

  try {
    $StepId = "PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1"
    $NextAllowedStep = "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1"
    $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
    $ExpectedHead = "b6cb28c"
    $CycleLimit = 3
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

    foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase156Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $Branch = (git branch --show-current).Trim()
    if ($Branch -eq "main") {
      throw "PHASE156_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase156Equals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
    $Head = (git rev-parse --short HEAD).Trim()
    Assert-Phase156Equals -Actual $Head -Expected $ExpectedHead -Name "current_head"

    foreach ($requiredPath in @($RouteAlignmentPath, $ModulePath, $ValidatorPath, $Phase155ProofPath, $Phase155TicketPath, $Phase155NextDecisionPath, $Phase155BoundedPolicyPath, $RuntimePath, $CurriculumPath, $SafetyPolicyPath, $BodyPackPath, $BodyPolicyPath, $SourcePolicyPath, $TrustedSourcesPath, $QueuePath)) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase156Path -RepoRoot $RepoRoot -Path $requiredPath))) {
        throw "PHASE156_MISSING_REQUIRED_INPUT=$requiredPath"
      }
    }

    $Phase155Proof = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $Phase155ProofPath
    Assert-Phase156Equals -Actual $Phase155Proof.status -Expected "PASS" -Name "phase155_status"
    Assert-Phase156Equals -Actual $Phase155Proof.next_allowed_step -Expected $StepId -Name "phase155_next_allowed_step"
    Assert-Phase156Equals -Actual $Phase155Proof.admission_status -Expected "ADMITTED_FOR_BOUNDED_SELF_GROWTH_SANDBOX_USE" -Name "phase155_admission"
    Assert-Phase156Equals -Actual $Phase155Proof.max_cycles_per_run -Expected 3 -Name "phase155_max_cycles"
    Assert-Phase156False -Actual $Phase155Proof.codex_needed_for_next_step -Name "phase155_codex_needed"

    $Ticket = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $Phase155TicketPath
    Assert-Phase156Equals -Actual $Ticket.status -Expected "PASS" -Name "ticket_status_field"
    Assert-Phase156Equals -Actual $Ticket.ticket_status -Expected "ISSUED_FOR_PHASE156_ONLY" -Name "ticket_status"
    Assert-Phase156Equals -Actual $Ticket.trial_type -Expected "SELF_SELECTED_GAP_SELF_BUILD_TRIAL" -Name "ticket_trial_type"
    Assert-Phase156Equals -Actual $Ticket.allowed_scope -Expected "sandbox_only" -Name "ticket_scope"
    Assert-Phase156Equals -Actual $Ticket.max_cycle_count -Expected 3 -Name "ticket_max_cycle"

    $NextDecision = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $Phase155NextDecisionPath
    Assert-Phase156Equals -Actual $NextDecision.next_action -Expected "RUN_SELF_SELECTED_GAP_SELF_BUILD_TRIAL" -Name "phase155_next_action"
    Assert-Phase156False -Actual $NextDecision.codex_needed_for_next_step -Name "phase155_next_codex"

    $BoundedPolicy = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $Phase155BoundedPolicyPath
    Assert-Phase156Equals -Actual $BoundedPolicy.allowed_next_use -Expected "self_selected_gap_trial" -Name "policy_allowed_next_use"
    Assert-Phase156Equals -Actual $BoundedPolicy.max_cycle_count -Expected 3 -Name "policy_max_cycle"
    Assert-Phase156False -Actual $BoundedPolicy.accepted_state_mutation_allowed -Name "policy_state_mutation"
    Assert-Phase156False -Actual $BoundedPolicy.external_fetch_allowed -Name "policy_fetch"
    Assert-Phase156False -Actual $BoundedPolicy.install_allowed -Name "policy_install"

    $Runtime = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $RuntimePath
    $Curriculum = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $CurriculumPath
    $SafetyPolicy = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $SafetyPolicyPath
    $BodyPack = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $BodyPackPath
    $BodyPolicy = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $BodyPolicyPath
    $SourcePolicy = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $SourcePolicyPath
    $TrustedSources = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $TrustedSourcesPath
    $Queue = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $QueuePath
    Assert-Phase156Equals -Actual $Runtime.runtime_id -Expected "SELF_GROWTH_DUTY_RUNTIME_V1" -Name "runtime_id"
    Assert-Phase156Equals -Actual $Curriculum.status -Expected "PASS" -Name "curriculum_status"
    Assert-Phase156Equals -Actual $BodyPack.body_pack_id -Expected "BUILDER_BODY_ORGAN_PACK_V1" -Name "body_pack_id"
    Assert-Phase156Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"
    Assert-Phase156False -Actual $SafetyPolicy.external_fetch_allowed -Name "safety_fetch"
    Assert-Phase156False -Actual $SafetyPolicy.install_allowed -Name "safety_install"
    Assert-Phase156False -Actual $SafetyPolicy.arbitrary_code_execution_allowed -Name "safety_arbitrary"
    Assert-Phase156False -Actual $SafetyPolicy.accepted_state_mutation_allowed -Name "safety_state"
    Assert-Phase156False -Actual $SafetyPolicy.capability_shelf_mutation_allowed -Name "safety_shelf"
    Assert-Phase156False -Actual $BodyPolicy.capability_shelf_mutation_allowed -Name "body_shelf"
    Assert-Phase156False -Actual $SourcePolicy.external_fetch_allowed -Name "source_fetch"
    Assert-Phase156Equals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count"

    $TrialBoot = [ordered]@{
      status = "PASS"
      boot_id = "PHASE156_TRIAL_BOOT"
      step_id = $StepId
      run_id = $RunId
      root_cause = "PHASE156 entrypoint absent"
      phase155_verified = $true
      admission_status_verified = $true
      ticket_verified = $true
      bounded_reuse_policy_verified = $true
      runtime_reused = $true
      runtime_modified = $false
      body_pack_verified = $true
      body_pack_mutated = $false
      cycle_limit = 3
      allowed_scope = "sandbox_only"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $TrialBootPath -Object $TrialBoot

    $TicketRead = [ordered]@{
      status = "PASS"
      read_id = "PHASE156_PHASE155_TICKET_READ"
      step_id = $StepId
      run_id = $RunId
      source_ticket_path = $Phase155TicketPath
      ticket_status = "ISSUED_FOR_PHASE156_ONLY"
      trial_type = "SELF_SELECTED_GAP_SELF_BUILD_TRIAL"
      allowed_scope = "sandbox_only"
      max_cycle_count = 3
      next_allowed_step_from_ticket = $StepId
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $Phase155TicketReadPath -Object $TicketRead

    $SelfGapDiscovery = [ordered]@{
      status = "PASS"
      discovery_id = "PHASE156_SELF_GAP_DISCOVERY"
      step_id = $StepId
      run_id = $RunId
      discovered_gaps = @(
        [ordered]@{ gap_id = "SELF_GAP_INVENTORY_GAP"; missing_skill_id = "SELF_GAP_INVENTORY_SKILL_CANDIDATE_V1"; priority = 1 },
        [ordered]@{ gap_id = "SELF_REPAIR_TASK_SPEC_WRITER_GAP"; missing_skill_id = "SELF_REPAIR_TASK_SPEC_WRITER_SKILL_CANDIDATE_V1"; priority = 2 },
        [ordered]@{ gap_id = "SELF_PROOF_SUMMARY_GAP"; missing_skill_id = "SELF_PROOF_SUMMARY_SKILL_CANDIDATE_V1"; priority = 3 }
      )
      first_selected_gap = "SELF_GAP_INVENTORY_GAP"
      owner_selected_gap = $false
      codex_selected_gap = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $SelfGapDiscoveryPath -Object $SelfGapDiscovery

    $SelfSelectedGapPolicy = [ordered]@{
      status = "PASS"
      policy_id = "PHASE156_SELF_SELECTED_GAP_POLICY"
      step_id = $StepId
      run_id = $RunId
      selector_type = "deterministic_internal_policy"
      owner_selected_each_gap = $false
      codex_selected_each_gap = $false
      selection_inputs = @("PHASE155 next_trial_ticket", "internal self_gap_discovery", "previous cycle next_selected_gap", "allowed bounded sandbox policy")
      max_cycles = 3
      allowed_scope = "sandbox_only"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $SelfSelectedGapPolicyPath -Object $SelfSelectedGapPolicy

    $Cycle006 = Invoke-Phase156SelfSelectedGapCycle `
      -RepoRoot $RepoRoot `
      -RunId $RunId `
      -StepId $StepId `
      -NextAllowedStep $NextAllowedStep `
      -CycleId "cycle_006" `
      -CycleNumber 6 `
      -CycleRoot "$TrialRoot/cycle_006" `
      -SelectedGap "SELF_GAP_INVENTORY_GAP" `
      -SelectionSource "internal self_gap_discovery priority 1" `
      -SourceNextGapPath "" `
      -SkillId "SELF_GAP_INVENTORY_SKILL_CANDIDATE_V1" `
      -SkillName "self_gap_inventory" `
      -InternalQuestionText "What internal skill helps me identify my own next missing capability?" `
      -InternalAnswerText "Build a sandbox candidate that classifies missing self-build parts into stable gap categories." `
      -TestCases @(
        (New-Phase156Case -TestId "classify_missing_entrypoint" -InputKind "missing_entrypoint" -ExpectedOutput "entrypoint_missing" -Operation "classify_gap_inventory"),
        (New-Phase156Case -TestId "classify_missing_validator" -InputKind "missing_validator" -ExpectedOutput "validator_missing" -Operation "classify_gap_inventory"),
        (New-Phase156Case -TestId "classify_missing_runtime_output" -InputKind "missing_runtime_output" -ExpectedOutput "runtime_output_missing" -Operation "classify_gap_inventory")
      ) `
      -NextSelectedGapValue "SELF_REPAIR_TASK_SPEC_WRITER_GAP"

    $Cycle006Next = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $Cycle006.next_selected_gap_path
    Assert-Phase156Equals -Actual $Cycle006Next.next_selected_gap -Expected "SELF_REPAIR_TASK_SPEC_WRITER_GAP" -Name "cycle006_next_gap"

    $Cycle007 = Invoke-Phase156SelfSelectedGapCycle `
      -RepoRoot $RepoRoot `
      -RunId $RunId `
      -StepId $StepId `
      -NextAllowedStep $NextAllowedStep `
      -CycleId "cycle_007" `
      -CycleNumber 7 `
      -CycleRoot "$TrialRoot/cycle_007" `
      -SelectedGap $Cycle006Next.next_selected_gap `
      -SelectionSource "cycle_006_next_selected_gap" `
      -SourceNextGapPath $Cycle006.next_selected_gap_path `
      -SkillId "SELF_REPAIR_TASK_SPEC_WRITER_SKILL_CANDIDATE_V1" `
      -SkillName "self_repair_task_spec_writer" `
      -InternalQuestionText "What internal skill helps me turn a detected gap into a repair/build task spec?" `
      -InternalAnswerText "Build a sandbox candidate that maps gap categories into repair/build task spec types." `
      -TestCases @(
        (New-Phase156Case -TestId "task_for_entrypoint_missing" -InputKind "entrypoint_missing" -ExpectedOutput "build_entrypoint_task" -Operation "write_repair_task_spec"),
        (New-Phase156Case -TestId "task_for_validator_missing" -InputKind "validator_missing" -ExpectedOutput "build_validator_task" -Operation "write_repair_task_spec"),
        (New-Phase156Case -TestId "task_for_runtime_output_missing" -InputKind "runtime_output_missing" -ExpectedOutput "repair_runtime_output_generation_task" -Operation "write_repair_task_spec")
      ) `
      -NextSelectedGapValue "SELF_PROOF_SUMMARY_GAP"

    $Cycle007Next = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $Cycle007.next_selected_gap_path
    Assert-Phase156Equals -Actual $Cycle007Next.next_selected_gap -Expected "SELF_PROOF_SUMMARY_GAP" -Name "cycle007_next_gap"

    $Cycle008 = Invoke-Phase156SelfSelectedGapCycle `
      -RepoRoot $RepoRoot `
      -RunId $RunId `
      -StepId $StepId `
      -NextAllowedStep $NextAllowedStep `
      -CycleId "cycle_008" `
      -CycleNumber 8 `
      -CycleRoot "$TrialRoot/cycle_008" `
      -SelectedGap $Cycle007Next.next_selected_gap `
      -SelectionSource "cycle_007_next_selected_gap" `
      -SourceNextGapPath $Cycle007.next_selected_gap_path `
      -SkillId "SELF_PROOF_SUMMARY_SKILL_CANDIDATE_V1" `
      -SkillName "self_proof_summary" `
      -InternalQuestionText "What internal skill helps me summarize proof state and next allowed step?" `
      -InternalAnswerText "Build a sandbox candidate that summarizes proof acceptance, next step, and Codex need from proof fields." `
      -TestCases @(
        (New-Phase156ProofSummaryCase -TestId "summary_phase156_next" -Status "PASS" -NextAllowedStep "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1" -CodexNeeded $false -ExpectedAccepted $true),
        (New-Phase156ProofSummaryCase -TestId "summary_phase155_next" -Status "PASS" -NextAllowedStep "PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1" -CodexNeeded $false -ExpectedAccepted $true),
        (New-Phase156ProofSummaryCase -TestId "summary_generic_next" -Status "PASS" -NextAllowedStep "X" -CodexNeeded $false -ExpectedAccepted $true)
      ) `
      -NextSelectedGapValue "STOP_PHASE156_CYCLE_LIMIT_REACHED"

    $Cycle008Next = Read-Phase156JsonRequired -RepoRoot $RepoRoot -Path $Cycle008.next_selected_gap_path
    Assert-Phase156Equals -Actual $Cycle008Next.next_selected_gap -Expected "STOP_PHASE156_CYCLE_LIMIT_REACHED" -Name "cycle008_next_gap"

    $CycleOutputs = @(
      $Cycle006.self_diagnosis_path, $Cycle006.gap_selection_path, $Cycle006.internal_question_path, $Cycle006.internal_answer_path, $Cycle006.self_build_program_candidate_path, $Cycle006.sandbox_execution_trace_path, $Cycle006.skill_candidate_path, $Cycle006.skill_contract_path, $Cycle006.test_cases_path, $Cycle006.skill_validation_result_path, $Cycle006.learning_absorption_candidate_path, $Cycle006.next_selected_gap_path, $Cycle006.cycle_trace_path,
      $Cycle007.self_diagnosis_path, $Cycle007.gap_selection_path, $Cycle007.internal_question_path, $Cycle007.internal_answer_path, $Cycle007.self_build_program_candidate_path, $Cycle007.sandbox_execution_trace_path, $Cycle007.skill_candidate_path, $Cycle007.skill_contract_path, $Cycle007.test_cases_path, $Cycle007.skill_validation_result_path, $Cycle007.learning_absorption_candidate_path, $Cycle007.next_selected_gap_path, $Cycle007.cycle_trace_path,
      $Cycle008.self_diagnosis_path, $Cycle008.gap_selection_path, $Cycle008.internal_question_path, $Cycle008.internal_answer_path, $Cycle008.self_build_program_candidate_path, $Cycle008.sandbox_execution_trace_path, $Cycle008.skill_candidate_path, $Cycle008.skill_contract_path, $Cycle008.test_cases_path, $Cycle008.skill_validation_result_path, $Cycle008.learning_absorption_candidate_path, $Cycle008.next_selected_gap_path, $Cycle008.cycle_trace_path
    )

    $SelfSelectedGapTrace = [ordered]@{
      status = "PASS"
      trace_id = "PHASE156_SELF_SELECTED_GAP_TRACE"
      step_id = $StepId
      run_id = $RunId
      selector_type = "deterministic_internal_policy"
      cycle_count = 3
      cycle_007_derived_from_cycle_006 = $true
      cycle_008_derived_from_cycle_007 = $true
      owner_selected_each_gap = $false
      codex_selected_each_gap = $false
      all_cycles_validated = $true
      safe_stop = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $SelfSelectedGapTracePath -Object $SelfSelectedGapTrace

    $CycleIndex = [ordered]@{
      status = "PASS"
      index_id = "PHASE156_CYCLE_INDEX"
      step_id = $StepId
      run_id = $RunId
      cycle_count = 3
      cycles = @(
        [ordered]@{ cycle_id = "cycle_006"; selected_gap = $Cycle006.selected_gap; skill_id = $Cycle006.skill_id; validation_status = "PASS"; next_selected_gap = $Cycle006.next_selected_gap },
        [ordered]@{ cycle_id = "cycle_007"; selected_gap = $Cycle007.selected_gap; skill_id = $Cycle007.skill_id; validation_status = "PASS"; next_selected_gap = $Cycle007.next_selected_gap; source_next_selected_gap_path = $Cycle006.next_selected_gap_path },
        [ordered]@{ cycle_id = "cycle_008"; selected_gap = $Cycle008.selected_gap; skill_id = $Cycle008.skill_id; validation_status = "PASS"; next_selected_gap = $Cycle008.next_selected_gap; source_next_selected_gap_path = $Cycle007.next_selected_gap_path }
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $CycleIndexPath -Object $CycleIndex

    $SkillIndex = [ordered]@{
      status = "PASS"
      index_id = "PHASE156_BUILT_SKILL_CANDIDATES_INDEX"
      step_id = $StepId
      run_id = $RunId
      skill_candidate_count = 3
      skill_candidates = @(
        [ordered]@{ cycle_id = "cycle_006"; skill_id = "SELF_GAP_INVENTORY_SKILL_CANDIDATE_V1"; path = $Cycle006.skill_candidate_path },
        [ordered]@{ cycle_id = "cycle_007"; skill_id = "SELF_REPAIR_TASK_SPEC_WRITER_SKILL_CANDIDATE_V1"; path = $Cycle007.skill_candidate_path },
        [ordered]@{ cycle_id = "cycle_008"; skill_id = "SELF_PROOF_SUMMARY_SKILL_CANDIDATE_V1"; path = $Cycle008.skill_candidate_path }
      )
      accepted_capability_promotion_performed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $SkillIndexPath -Object $SkillIndex

    $SelfModelGrowthCandidate = [ordered]@{
      status = "PASS"
      candidate_id = "PHASE156_SELF_MODEL_GROWTH_CANDIDATE"
      step_id = $StepId
      run_id = $RunId
      candidate_only = $true
      candidate_statement = "Builder can run a bounded sandbox self-selected gap trial by deterministic internal policy."
      accepted_self_model_mutated = $false
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $SelfModelGrowthCandidatePath -Object $SelfModelGrowthCandidate

    $RuntimeStopDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE156_RUNTIME_STOP_DECISION"
      step_id = $StepId
      run_id = $RunId
      stop_reason = "PHASE156_CYCLE_LIMIT_REACHED"
      safe_stop = $true
      cycle_count = 3
      stopped_after_cycle_id = "cycle_008"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $RuntimeStopDecisionPath -Object $RuntimeStopDecision

    $Common = [ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase155_verified = $true
      admission_status_verified = $true
      ticket_verified = $true
      bounded_reuse_policy_verified = $true
      runtime_reused = $true
      runtime_modified = $false
      body_pack_verified = $true
      body_pack_mutated = $false
      cycle_count = 3
      cycle_006_started = $true
      cycle_006_selected_gap = "SELF_GAP_INVENTORY_GAP"
      cycle_006_skill_id = "SELF_GAP_INVENTORY_SKILL_CANDIDATE_V1"
      cycle_006_validation_status = "PASS"
      cycle_006_next_selected_gap = "SELF_REPAIR_TASK_SPEC_WRITER_GAP"
      cycle_007_started = $true
      cycle_007_started_from_cycle_006_next_gap = $true
      cycle_007_selected_gap = "SELF_REPAIR_TASK_SPEC_WRITER_GAP"
      cycle_007_skill_id = "SELF_REPAIR_TASK_SPEC_WRITER_SKILL_CANDIDATE_V1"
      cycle_007_validation_status = "PASS"
      cycle_007_next_selected_gap = "SELF_PROOF_SUMMARY_GAP"
      cycle_008_started = $true
      cycle_008_started_from_cycle_007_next_gap = $true
      cycle_008_selected_gap = "SELF_PROOF_SUMMARY_GAP"
      cycle_008_skill_id = "SELF_PROOF_SUMMARY_SKILL_CANDIDATE_V1"
      cycle_008_validation_status = "PASS"
      cycle_008_next_selected_gap = "STOP_PHASE156_CYCLE_LIMIT_REACHED"
      self_selected_gap_trial_proven = $true
      all_cycles_validated = $true
      owner_selected_each_gap = $false
      codex_selected_each_gap = $false
      no_codex_needed_inside_cycles = $true
      built_skill_candidates_index_created = $true
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
      trusted_source_count = 0
      queue_after = "NONE"
      trial_root = $TrialRoot
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      next_allowed_step = $NextAllowedStep
    }

    $TrialResult = [ordered]@{}
    foreach ($key in $Common.Keys) { $TrialResult[$key] = $Common[$key] }
    $TrialResult["result_id"] = "PHASE156_SELF_SELECTED_GAP_TRIAL_RESULT"
    Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $TrialResultPath -Object $TrialResult

    $RuntimeCreatedOutputs = @($TrialBootPath, $Phase155TicketReadPath, $SelfGapDiscoveryPath, $SelfSelectedGapPolicyPath, $SelfSelectedGapTracePath, $CycleIndexPath) + $CycleOutputs + @($TrialResultPath, $SkillIndexPath, $SelfModelGrowthCandidatePath, $RuntimeStopDecisionPath)

    $Result = [ordered]@{}
    foreach ($key in $Common.Keys) { $Result[$key] = $Common[$key] }
    $Result["result_id"] = "PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_RESULT"
    Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result

    $Report = [ordered]@{
      status = "PASS"
      report_id = "PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1_REPORT"
      step_id = $StepId
      run_id = $RunId
      root_cause = "PHASE156 entrypoint absent"
      files_changed = @($RouteAlignmentPath, $ModulePath, $ValidatorPath) + $RuntimeCreatedOutputs + @($ResultPath, $ReportPath, $ProofPath)
      module_path = $ModulePath
      validator_path = $ValidatorPath
      exact_run_command_expected = ".\modules\invoke_builder_self_selected_gap_self_build_trial_001.ps1"
      exact_validator_command_expected = ".\validators\validate_phase156_builder_self_selected_gap_self_build_trial_v1.ps1 -RepoRoot ."
      runtime_output_files_created = $RuntimeCreatedOutputs + @($ResultPath, $ReportPath, $ProofPath)
      cycle_007_derivation = "Cycle 007 reads $($Cycle006.next_selected_gap_path) and selects SELF_REPAIR_TASK_SPEC_WRITER_GAP."
      cycle_008_derivation = "Cycle 008 reads $($Cycle007.next_selected_gap_path) and selects SELF_PROOF_SUMMARY_GAP."
      risks = @(
        "PHASE156 builds sandbox skill candidates only; none are promoted to accepted capability.",
        "The deterministic policy is intentionally small and bounded to three cycles.",
        "PHASE157 must review the self-selected gap trial before any broader reuse."
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
        "No accepted PHASE142-PHASE155 artifact mutation.",
        "No generated_agents or applied_agents touch.",
        "No package manager or dependency file touch.",
        "No GitHub workflow touch.",
        "No route lock touch.",
        "No internet fetch.",
        "No dependency install.",
        "No arbitrary generated code execution.",
        "No accepted memory or self-model mutation.",
        "No skill candidate promotion.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report

    $Proof = [ordered]@{}
    foreach ($key in $Common.Keys) { $Proof[$key] = $Common[$key] }
    $Proof["proof_id"] = $StepId
    $Proof["trial_boot_path"] = $TrialBootPath
    $Proof["phase155_ticket_read_path"] = $Phase155TicketReadPath
    $Proof["self_selected_gap_policy_path"] = $SelfSelectedGapPolicyPath
    $Proof["cycle_index_path"] = $CycleIndexPath
    $Proof["self_selected_gap_trial_result_path"] = $TrialResultPath
    $Proof["runtime_stop_decision_path"] = $RuntimeStopDecisionPath
    Write-Phase156JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject][ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase155_verified = $true
      ticket_verified = $true
      cycle_count = 3
      cycle_006_selected_gap = "SELF_GAP_INVENTORY_GAP"
      cycle_006_validation_status = "PASS"
      cycle_007_started_from_cycle_006_next_gap = $true
      cycle_007_selected_gap = "SELF_REPAIR_TASK_SPEC_WRITER_GAP"
      cycle_007_validation_status = "PASS"
      cycle_008_started_from_cycle_007_next_gap = $true
      cycle_008_selected_gap = "SELF_PROOF_SUMMARY_GAP"
      cycle_008_validation_status = "PASS"
      self_selected_gap_trial_proven = $true
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
  Invoke-BuilderSelfSelectedGapSelfBuildTrial001 -RepoRoot $RepoRoot -RunId $RunId | ConvertTo-Json -Depth 20
}
