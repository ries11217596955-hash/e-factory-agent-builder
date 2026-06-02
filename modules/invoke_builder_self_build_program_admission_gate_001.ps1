function Resolve-Phase151Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase151JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase151Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE151_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase151JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase151Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase151TextFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$Content
  )

  $fullPath = Resolve-Phase151Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  if (-not $Content.EndsWith("`n")) {
    $Content += "`n"
  }

  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase151Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE151_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase151True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE151_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase151False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE151_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Invoke-BuilderSelfBuildProgramAdmissionGate001 {
  param(
    [string]$RepoRoot = ".",
    [string]$RunId = "PHASE151_BRAIN_CELL_INNER_LOOP_IGNITION_001"
  )

  $ErrorActionPreference = "Stop"
  $RepoRoot = Resolve-Phase151Path -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot

  try {
    $StepId = "PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1"
    $NextAllowedStep = "PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1"
    $Phase150RunId = "PHASE150_SELF_BUILD_IGNITION_BRIDGE_001"
    $ProgramId = "PHASE150_LEARNING_CARD_REUSE_ADVISOR_SELF_BUILD_PROGRAM_CANDIDATE"
    $TargetMicroOrganId = "learning_card_reuse_advisor"
    $DetectedBlocker = "program_not_admitted"
    $AdmissionStatus = "ADMITTED_FOR_SANDBOX_EXECUTION_ONLY"
    $ExecutionScope = "sandbox_only"
    $AllowedExecutionRoot = "living_learning_environment/sandbox/PHASE152_EXECUTE_ADMITTED_SELF_BUILD_PROGRAM_001"
    $InnerLoopRoot = "living_learning_environment/inner_loop/$RunId"
    $RouteAlignmentPath = "route_change_requests/PHASE151_BRAIN_CELL_INNER_LOOP_IGNITION_ALIGNMENT_REQUEST.md"
    $Phase150ProofPath = "proofs/self_development/PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1.json"
    $ProgramCandidatePath = "living_learning_environment/sandbox/PHASE150_SELF_BUILD_IGNITION_BRIDGE_001/self_build_program_candidate.json"
    $ProgramContractPath = "living_learning_environment/sandbox/PHASE150_SELF_BUILD_IGNITION_BRIDGE_001/self_build_program_contract.json"
    $AdmissionChecklistPath = "living_learning_environment/sandbox/PHASE150_SELF_BUILD_IGNITION_BRIDGE_001/admission_checklist.json"
    $SourcePolicyPath = "source_registry/source_policy.json"
    $TrustedSourcesPath = "source_registry/trusted_sources.json"
    $InternalQuestionPath = "$InnerLoopRoot/internal_question.json"
    $InternalAnswerSearchPath = "$InnerLoopRoot/internal_answer_search.json"
    $AdmissionDecisionPath = "$InnerLoopRoot/admission_decision.json"
    $RiskAssessmentPath = "$InnerLoopRoot/risk_assessment.json"
    $SandboxExecutionTicketPath = "$InnerLoopRoot/sandbox_execution_ticket.json"
    $ExecutionIntentionPath = "$InnerLoopRoot/execution_intention.json"
    $NextCycleDecisionPath = "$InnerLoopRoot/next_cycle_decision.json"
    $InnerLoopTracePath = "$InnerLoopRoot/inner_loop_trace.json"
    $ResultPath = "self_control/BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_RESULT.json"
    $ReportPath = "reports/self_development/PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1_REPORT.json"
    $ProofPath = "proofs/self_development/PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1.json"

    foreach ($identityFile in @(
      "CAPABILITY_ROADMAP.json",
      "GENESIS_STATE.json",
      "TASK_QUEUE.json",
      "packs/registry.json",
      "orchestrator/run.ps1"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase151Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $Branch = (git branch --show-current).Trim()
    if ($Branch -eq "main") {
      throw "PHASE151_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase151Equals -Actual $Branch -Expected "phase110-idempotent-autonomy-trial-runtime" -Name "current_branch"
    $Head = (git rev-parse --short HEAD).Trim()
    Assert-Phase151Equals -Actual $Head -Expected "38ae2e2" -Name "current_head"

    $ForbiddenBefore = @(git status --short --untracked-files=all -- `
      orchestrator/run.ps1 `
      TASK_QUEUE.json `
      GENESIS_STATE.json `
      CAPABILITY_ROADMAP.json `
      packs/registry.json `
      capability_shelf `
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
      reports/self_development/PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1_REPORT.json `
      reports/self_development/PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1_REPORT.json `
      reports/self_development/PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1_REPORT.json `
      reports/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1_REPORT.json `
      reports/self_development/PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1_REPORT.json `
      reports/self_development/PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1_REPORT.json `
      reports/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1_REPORT.json `
      reports/self_development/PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1_REPORT.json `
      reports/self_development/PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1_REPORT.json 2>$null)
    if ($ForbiddenBefore.Count -gt 0) {
      throw "PHASE151_FORBIDDEN_SCOPE_DIRTY_BEFORE=$($ForbiddenBefore -join '; ')"
    }

    $Phase150Proof = Read-Phase151JsonRequired -RepoRoot $RepoRoot -Path $Phase150ProofPath
    Assert-Phase151Equals -Actual $Phase150Proof.status -Expected "PASS" -Name "phase150_status"
    Assert-Phase151Equals -Actual $Phase150Proof.run_id -Expected $Phase150RunId -Name "phase150_run_id"
    Assert-Phase151True -Actual $Phase150Proof.self_build_program_candidate_created -Name "phase150_candidate_created"
    Assert-Phase151Equals -Actual $Phase150Proof.next_allowed_step -Expected $StepId -Name "phase150_next_allowed_step"

    $ProgramCandidate = Read-Phase151JsonRequired -RepoRoot $RepoRoot -Path $ProgramCandidatePath
    Assert-Phase151Equals -Actual $ProgramCandidate.status -Expected "PASS" -Name "candidate_status"
    Assert-Phase151Equals -Actual $ProgramCandidate.program_id -Expected $ProgramId -Name "candidate_program_id"
    Assert-Phase151Equals -Actual $ProgramCandidate.program_status -Expected "CANDIDATE_NOT_ADMITTED" -Name "candidate_program_status"
    Assert-Phase151Equals -Actual $ProgramCandidate.target_micro_organ_id -Expected $TargetMicroOrganId -Name "candidate_target_micro_organ"
    Assert-Phase151True -Actual $ProgramCandidate.validator_required -Name "candidate_validator_required"
    Assert-Phase151True -Actual $ProgramCandidate.admission_required -Name "candidate_admission_required"
    foreach ($field in @("admitted","promoted","trusted","executed")) {
      Assert-Phase151False -Actual $ProgramCandidate.$field -Name "candidate_$field"
    }

    $ProgramContract = Read-Phase151JsonRequired -RepoRoot $RepoRoot -Path $ProgramContractPath
    Assert-Phase151Equals -Actual $ProgramContract.status -Expected "PASS" -Name "contract_status"
    Assert-Phase151Equals -Actual $ProgramContract.target_micro_organ_id -Expected $TargetMicroOrganId -Name "contract_target_micro_organ"

    $AdmissionChecklist = Read-Phase151JsonRequired -RepoRoot $RepoRoot -Path $AdmissionChecklistPath
    Assert-Phase151Equals -Actual $AdmissionChecklist.status -Expected "PASS" -Name "admission_checklist_status"
    Assert-Phase151Equals -Actual $AdmissionChecklist.program_id -Expected $ProgramId -Name "admission_checklist_program_id"
    Assert-Phase151True -Actual $AdmissionChecklist.requires_validator -Name "admission_requires_validator"
    Assert-Phase151True -Actual $AdmissionChecklist.requires_sandbox_execution -Name "admission_requires_sandbox_execution"
    Assert-Phase151False -Actual $AdmissionChecklist.accepted_state_change_requested -Name "admission_accepted_state_change_requested"

    $SourcePolicy = Read-Phase151JsonRequired -RepoRoot $RepoRoot -Path $SourcePolicyPath
    Assert-Phase151False -Actual $SourcePolicy.default_trust -Name "source_policy_default_trust"
    Assert-Phase151False -Actual $SourcePolicy.external_fetch_allowed -Name "source_policy_external_fetch_allowed"
    Assert-Phase151False -Actual $SourcePolicy.install_allowed -Name "source_policy_install_allowed"
    Assert-Phase151False -Actual $SourcePolicy.executable_use_allowed -Name "source_policy_executable_use_allowed"

    $TrustedSources = Read-Phase151JsonRequired -RepoRoot $RepoRoot -Path $TrustedSourcesPath
    Assert-Phase151Equals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count"
    Assert-Phase151Equals -Actual @($TrustedSources.trusted_sources).Count -Expected 0 -Name "trusted_sources_empty"

    $Queue = Read-Phase151JsonRequired -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
    Assert-Phase151Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $InputSources = @(
      $Phase150ProofPath,
      $ProgramCandidatePath,
      $ProgramContractPath,
      $AdmissionChecklistPath,
      $SourcePolicyPath,
      $TrustedSourcesPath
    )
    $Question = "What is required before executing this self-build program candidate?"
    $Answer = "admit for sandbox execution only, do not mutate accepted state"

    Write-Phase151TextFile -RepoRoot $RepoRoot -Path $RouteAlignmentPath -Content ((@(
      "# PHASE151 Brain-Cell Inner-Loop Ignition Alignment Request",
      "",
      "status: PASS",
      "line: AGENT_BUILDER_SELF_DEVELOPMENT",
      "mode: SELF_BUILD",
      "from: paper-only admission gate",
      "to: bounded inner-loop admission decision",
      "reason: PHASE150 produced a sandbox-only self-build program candidate that cannot run until admitted. PHASE151 asks and answers the execution-blocker question from internal repo sources only, admits sandbox execution for PHASE152, and executes nothing now.",
      "admission_status: $AdmissionStatus",
      "execution_scope: $ExecutionScope",
      "program_executed: false",
      "accepted_state_mutated: false",
      "next_allowed_step: $NextAllowedStep"
    )) -join "`n")

    $InternalQuestion = [ordered]@{
      status = "PASS"
      question_id = "PHASE151_INTERNAL_EXECUTION_BLOCKER_QUESTION"
      step_id = $StepId
      run_id = $RunId
      question_type = "EXECUTION_BLOCKER"
      question = $Question
      detected_blocker = $DetectedBlocker
      asked_by_builder_inner_loop = $true
      observed_program_id = $ProgramId
      observed_program_status = "CANDIDATE_NOT_ADMITTED"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase151JsonFile -RepoRoot $RepoRoot -Path $InternalQuestionPath -Object $InternalQuestion

    $InternalAnswerSearch = [ordered]@{
      status = "PASS"
      search_id = "PHASE151_INTERNAL_ANSWER_SEARCH"
      step_id = $StepId
      run_id = $RunId
      search_scope = "internal_repo_only"
      sources_read = $InputSources
      external_fetch_performed = $false
      answer_found = $true
      answer = $Answer
      accepted_state_mutation_allowed = $false
      trusted_source_count = 0
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase151JsonFile -RepoRoot $RepoRoot -Path $InternalAnswerSearchPath -Object $InternalAnswerSearch

    $AdmissionDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE151_SANDBOX_ONLY_ADMISSION_DECISION"
      step_id = $StepId
      run_id = $RunId
      admission_status = $AdmissionStatus
      program_id = $ProgramId
      target_micro_organ_id = $TargetMicroOrganId
      accepted_state_change_approved = $false
      execution_allowed = $true
      execution_scope = $ExecutionScope
      program_executed = $false
      decision_basis = $Answer
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase151JsonFile -RepoRoot $RepoRoot -Path $AdmissionDecisionPath -Object $AdmissionDecision

    $RiskAssessment = [ordered]@{
      status = "PASS"
      assessment_id = "PHASE151_SANDBOX_ADMISSION_RISK_ASSESSMENT"
      step_id = $StepId
      run_id = $RunId
      risk_level = "LOW_BOUNDED_SANDBOX"
      external_fetch_allowed = $false
      install_allowed = $false
      executable_use_allowed = $false
      accepted_state_mutation_allowed = $false
      capability_shelf_mutation_allowed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      external_agents_created = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase151JsonFile -RepoRoot $RepoRoot -Path $RiskAssessmentPath -Object $RiskAssessment

    $SandboxExecutionTicket = [ordered]@{
      status = "PASS"
      ticket_id = "PHASE151_SANDBOX_EXECUTION_TICKET"
      step_id = $StepId
      run_id = $RunId
      ticket_status = "ISSUED_FOR_PHASE152_ONLY"
      execution_target = $ProgramId
      allowed_execution_root = $AllowedExecutionRoot
      owner_approval_required = $false
      accepted_state_mutation_allowed = $false
      execution_scope = $ExecutionScope
      program_executed = $false
      valid_for_step = $NextAllowedStep
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase151JsonFile -RepoRoot $RepoRoot -Path $SandboxExecutionTicketPath -Object $SandboxExecutionTicket

    $ExecutionIntention = [ordered]@{
      status = "PASS"
      intention_id = "PHASE151_EXECUTION_INTENTION"
      step_id = $StepId
      run_id = $RunId
      intention_type = "EXECUTE_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX"
      intended_next_step = $NextAllowedStep
      program_id = $ProgramId
      program_executed_now = $false
      reason = "admission completed; execution belongs to PHASE152"
      execution_scope = $ExecutionScope
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase151JsonFile -RepoRoot $RepoRoot -Path $ExecutionIntentionPath -Object $ExecutionIntention

    $NextCycleDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE151_NEXT_CYCLE_DECISION"
      step_id = $StepId
      run_id = $RunId
      current_cycle_result = "ADMISSION_READY"
      next_action = "EXECUTE_IN_SANDBOX"
      next_allowed_step = $NextAllowedStep
      codex_needed_for_next_step = $false
      program_executed = $false
    }
    Write-Phase151JsonFile -RepoRoot $RepoRoot -Path $NextCycleDecisionPath -Object $NextCycleDecision

    $InnerLoopTrace = [ordered]@{
      status = "PASS"
      trace_id = "PHASE151_BRAIN_CELL_INNER_LOOP_TRACE"
      step_id = $StepId
      run_id = $RunId
      inner_loop_sequence = @("need","blocked","question","internal_answer_search","bounded_decision","sandbox_execution_intention","next_cycle_decision")
      observe_state = $true
      blocker_detected = $true
      internal_question_generated = $true
      internal_answer_found = $true
      bounded_decision_created = $true
      sandbox_execution_ticket_created = $true
      execution_intention_created = $true
      next_cycle_decision_created = $true
      detected_blocker = $DetectedBlocker
      admission_status = $AdmissionStatus
      execution_scope = $ExecutionScope
      program_executed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase151JsonFile -RepoRoot $RepoRoot -Path $InnerLoopTracePath -Object $InnerLoopTrace

    $Common = [ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase150_verified = $true
      program_candidate_verified = $true
      contract_verified = $true
      admission_checklist_verified = $true
      internal_question_created = $true
      internal_answer_search_created = $true
      internal_answer_found = $true
      blocker_detected = $true
      detected_blocker = $DetectedBlocker
      admission_decision_created = $true
      risk_assessment_created = $true
      sandbox_execution_ticket_created = $true
      execution_intention_created = $true
      next_cycle_decision_created = $true
      inner_loop_trace_created = $true
      admission_status = $AdmissionStatus
      execution_allowed = $true
      execution_scope = $ExecutionScope
      program_executed = $false
      accepted_state_change_approved = $false
      codex_needed_for_next_step = $false
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
      program_id = $ProgramId
      target_micro_organ_id = $TargetMicroOrganId
      internal_question_path = $InternalQuestionPath
      internal_answer_search_path = $InternalAnswerSearchPath
      admission_decision_path = $AdmissionDecisionPath
      risk_assessment_path = $RiskAssessmentPath
      sandbox_execution_ticket_path = $SandboxExecutionTicketPath
      execution_intention_path = $ExecutionIntentionPath
      next_cycle_decision_path = $NextCycleDecisionPath
      inner_loop_trace_path = $InnerLoopTracePath
      next_allowed_step = $NextAllowedStep
    }

    $Result = [ordered]@{}
    foreach ($key in $Common.Keys) { $Result[$key] = $Common[$key] }
    $Result["result_id"] = "PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_RESULT"
    Write-Phase151JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result

    $Report = [ordered]@{
      status = "PASS"
      report_id = "PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1_REPORT"
      step_id = $StepId
      run_id = $RunId
      route_alignment_request_path = $RouteAlignmentPath
      module_path = "modules/invoke_builder_self_build_program_admission_gate_001.ps1"
      validator_path = "validators/validate_phase151_builder_self_build_program_admission_gate_v1.ps1"
      exact_run_command_expected = ". .\modules\invoke_builder_self_build_program_admission_gate_001.ps1; `$Result = Invoke-BuilderSelfBuildProgramAdmissionGate001 -RepoRoot (Get-Location).Path -RunId PHASE151_BRAIN_CELL_INNER_LOOP_IGNITION_001; `$Result | ConvertTo-Json -Depth 20"
      exact_validator_command_expected = ".\validators\validate_phase151_builder_self_build_program_admission_gate_v1.ps1 -RepoRoot ."
      files_changed = @(
        $RouteAlignmentPath,
        "modules/invoke_builder_self_build_program_admission_gate_001.ps1",
        "validators/validate_phase151_builder_self_build_program_admission_gate_v1.ps1",
        $InternalQuestionPath,
        $InternalAnswerSearchPath,
        $AdmissionDecisionPath,
        $RiskAssessmentPath,
        $SandboxExecutionTicketPath,
        $ExecutionIntentionPath,
        $NextCycleDecisionPath,
        $InnerLoopTracePath,
        $ResultPath,
        $ReportPath,
        $ProofPath
      )
      input_sources = $InputSources
      output_files_runtime_created = @(
        $InternalQuestionPath,
        $InternalAnswerSearchPath,
        $AdmissionDecisionPath,
        $RiskAssessmentPath,
        $SandboxExecutionTicketPath,
        $ExecutionIntentionPath,
        $NextCycleDecisionPath,
        $InnerLoopTracePath,
        $ResultPath,
        $ReportPath,
        $ProofPath
      )
      risks = @(
        "PHASE151 admits sandbox execution only; PHASE152 must perform any execution in the declared sandbox root.",
        "The PHASE150 self-build program candidate remains unchanged and unexecuted.",
        "No accepted Builder state is mutated by this admission gate."
      )
      cut_list = @(
        "No orchestrator change.",
        "No route lock change.",
        "No accepted PHASE142-PHASE150 proof or report change.",
        "No accepted capability_shelf mutation.",
        "No TASK_QUEUE mutation.",
        "No generated_agents or applied_agents touch.",
        "No package manager or dependency file touch.",
        "No GitHub workflow touch.",
        "No internet fetch.",
        "No dependency install.",
        "No external executable material use.",
        "No trusted source creation.",
        "No external agent production.",
        "No accepted Builder state mutation.",
        "No PHASE150 self-build program execution.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase151JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report

    $Proof = [ordered]@{}
    foreach ($key in $Common.Keys) { $Proof[$key] = $Common[$key] }
    $Proof["proof_id"] = $StepId
    $Proof["phase150_proof_path"] = $Phase150ProofPath
    $Proof["program_candidate_path"] = $ProgramCandidatePath
    $Proof["program_contract_path"] = $ProgramContractPath
    $Proof["admission_checklist_path"] = $AdmissionChecklistPath
    $Proof["source_policy_path"] = $SourcePolicyPath
    $Proof["trusted_sources_path"] = $TrustedSourcesPath
    $Proof["result_path"] = $ResultPath
    $Proof["report_path"] = $ReportPath
    Write-Phase151JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject][ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase150_verified = $true
      admission_status = $AdmissionStatus
      execution_allowed = $true
      execution_scope = $ExecutionScope
      program_executed = $false
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
