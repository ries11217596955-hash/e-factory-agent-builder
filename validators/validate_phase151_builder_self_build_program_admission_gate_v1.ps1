param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase151ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase151ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase151ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE151_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Assert-Phase151ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE151_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase151ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE151_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase151ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE151_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase151StatusPath {
  param([string]$StatusLine)

  if ($StatusLine -match '^.. (.+)$') {
    return ($Matches[1] -replace '\\', '/')
  }
  return ($StatusLine -replace '\\', '/')
}

try {
  $StepId = "PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1"
  $RunId = "PHASE151_BRAIN_CELL_INNER_LOOP_IGNITION_001"
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

  $RepoRoot = Resolve-Phase151ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot

  foreach ($identityFile in @(
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1"
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase151ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE151_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }

  foreach ($requiredPath in @(
    $RouteAlignmentPath,
    "modules/invoke_builder_self_build_program_admission_gate_001.ps1",
    "validators/validate_phase151_builder_self_build_program_admission_gate_v1.ps1",
    $Phase150ProofPath,
    $ProgramCandidatePath,
    $ProgramContractPath,
    $AdmissionChecklistPath,
    $SourcePolicyPath,
    $TrustedSourcesPath,
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
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase151ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE151_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $AllowedExact = @(
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
  $StatusLines = @(git status --short --untracked-files=all)
  foreach ($line in $StatusLines) {
    $path = Get-Phase151StatusPath -StatusLine $line
    if (-not ($AllowedExact -contains $path)) {
      throw "PHASE151_VALIDATE_CHANGE_OUTSIDE_ALLOWED_SCOPE=$line"
    }
  }

  $ProtectedStatus = @(git status --short --untracked-files=all -- `
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
  if ($ProtectedStatus.Count -gt 0) {
    throw "PHASE151_VALIDATE_PROTECTED_SCOPE_CHANGED=$($ProtectedStatus -join '; ')"
  }

  $Phase150Proof = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $Phase150ProofPath
  Assert-Phase151ValidatorEquals -Actual $Phase150Proof.status -Expected "PASS" -Name "phase150_status"
  Assert-Phase151ValidatorEquals -Actual $Phase150Proof.run_id -Expected $Phase150RunId -Name "phase150_run_id"
  Assert-Phase151ValidatorTrue -Actual $Phase150Proof.self_build_program_candidate_created -Name "phase150_candidate_created"
  Assert-Phase151ValidatorEquals -Actual $Phase150Proof.next_allowed_step -Expected $StepId -Name "phase150_next_allowed_step"

  $ProgramCandidate = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $ProgramCandidatePath
  Assert-Phase151ValidatorEquals -Actual $ProgramCandidate.status -Expected "PASS" -Name "candidate_status"
  Assert-Phase151ValidatorEquals -Actual $ProgramCandidate.program_id -Expected $ProgramId -Name "candidate_program_id"
  Assert-Phase151ValidatorEquals -Actual $ProgramCandidate.program_status -Expected "CANDIDATE_NOT_ADMITTED" -Name "candidate_program_status"
  Assert-Phase151ValidatorEquals -Actual $ProgramCandidate.target_micro_organ_id -Expected $TargetMicroOrganId -Name "candidate_target_micro_organ"
  Assert-Phase151ValidatorTrue -Actual $ProgramCandidate.validator_required -Name "candidate_validator_required"
  Assert-Phase151ValidatorTrue -Actual $ProgramCandidate.admission_required -Name "candidate_admission_required"
  foreach ($field in @("admitted","promoted","trusted","executed")) {
    Assert-Phase151ValidatorFalse -Actual $ProgramCandidate.$field -Name "candidate_$field"
  }

  $ProgramContract = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $ProgramContractPath
  Assert-Phase151ValidatorEquals -Actual $ProgramContract.status -Expected "PASS" -Name "contract_status"
  Assert-Phase151ValidatorEquals -Actual $ProgramContract.target_micro_organ_id -Expected $TargetMicroOrganId -Name "contract_target_micro_organ"

  $AdmissionChecklist = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $AdmissionChecklistPath
  Assert-Phase151ValidatorEquals -Actual $AdmissionChecklist.status -Expected "PASS" -Name "admission_checklist_status"
  Assert-Phase151ValidatorEquals -Actual $AdmissionChecklist.program_id -Expected $ProgramId -Name "admission_checklist_program_id"
  Assert-Phase151ValidatorTrue -Actual $AdmissionChecklist.requires_validator -Name "admission_requires_validator"
  Assert-Phase151ValidatorTrue -Actual $AdmissionChecklist.requires_sandbox_execution -Name "admission_requires_sandbox_execution"
  Assert-Phase151ValidatorFalse -Actual $AdmissionChecklist.accepted_state_change_requested -Name "admission_accepted_state_change_requested"

  $SourcePolicy = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $SourcePolicyPath
  Assert-Phase151ValidatorFalse -Actual $SourcePolicy.default_trust -Name "source_policy_default_trust"
  Assert-Phase151ValidatorFalse -Actual $SourcePolicy.external_fetch_allowed -Name "source_policy_external_fetch_allowed"
  Assert-Phase151ValidatorFalse -Actual $SourcePolicy.install_allowed -Name "source_policy_install_allowed"
  Assert-Phase151ValidatorFalse -Actual $SourcePolicy.executable_use_allowed -Name "source_policy_executable_use_allowed"

  $TrustedSources = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $TrustedSourcesPath
  Assert-Phase151ValidatorEquals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count"
  Assert-Phase151ValidatorEquals -Actual @($TrustedSources.trusted_sources).Count -Expected 0 -Name "trusted_sources_empty"

  $InternalQuestion = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $InternalQuestionPath
  Assert-Phase151ValidatorEquals -Actual $InternalQuestion.status -Expected "PASS" -Name "internal_question_status"
  Assert-Phase151ValidatorEquals -Actual $InternalQuestion.question_type -Expected "EXECUTION_BLOCKER" -Name "internal_question_type"
  Assert-Phase151ValidatorEquals -Actual $InternalQuestion.question -Expected "What is required before executing this self-build program candidate?" -Name "internal_question"
  Assert-Phase151ValidatorEquals -Actual $InternalQuestion.detected_blocker -Expected $DetectedBlocker -Name "internal_question_detected_blocker"
  Assert-Phase151ValidatorTrue -Actual $InternalQuestion.asked_by_builder_inner_loop -Name "asked_by_builder_inner_loop"

  $InternalAnswerSearch = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $InternalAnswerSearchPath
  Assert-Phase151ValidatorEquals -Actual $InternalAnswerSearch.status -Expected "PASS" -Name "answer_search_status"
  Assert-Phase151ValidatorEquals -Actual $InternalAnswerSearch.search_scope -Expected "internal_repo_only" -Name "answer_search_scope"
  Assert-Phase151ValidatorFalse -Actual $InternalAnswerSearch.external_fetch_performed -Name "answer_search_external_fetch"
  Assert-Phase151ValidatorTrue -Actual $InternalAnswerSearch.answer_found -Name "answer_found"
  Assert-Phase151ValidatorEquals -Actual $InternalAnswerSearch.answer -Expected "admit for sandbox execution only, do not mutate accepted state" -Name "answer_text"
  foreach ($source in @($Phase150ProofPath, $ProgramCandidatePath, $ProgramContractPath, $AdmissionChecklistPath, $SourcePolicyPath, $TrustedSourcesPath)) {
    if (-not (@($InternalAnswerSearch.sources_read) -contains $source)) {
      throw "PHASE151_VALIDATE_ANSWER_SOURCE_MISSING=$source"
    }
  }

  $AdmissionDecision = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $AdmissionDecisionPath
  Assert-Phase151ValidatorEquals -Actual $AdmissionDecision.status -Expected "PASS" -Name "admission_decision_status"
  Assert-Phase151ValidatorEquals -Actual $AdmissionDecision.admission_status -Expected $AdmissionStatus -Name "admission_status"
  Assert-Phase151ValidatorEquals -Actual $AdmissionDecision.program_id -Expected $ProgramId -Name "admission_program_id"
  Assert-Phase151ValidatorEquals -Actual $AdmissionDecision.target_micro_organ_id -Expected $TargetMicroOrganId -Name "admission_target_micro_organ"
  Assert-Phase151ValidatorFalse -Actual $AdmissionDecision.accepted_state_change_approved -Name "admission_accepted_state_change_approved"
  Assert-Phase151ValidatorTrue -Actual $AdmissionDecision.execution_allowed -Name "admission_execution_allowed"
  Assert-Phase151ValidatorEquals -Actual $AdmissionDecision.execution_scope -Expected $ExecutionScope -Name "admission_execution_scope"
  Assert-Phase151ValidatorFalse -Actual $AdmissionDecision.program_executed -Name "admission_program_executed"
  Assert-Phase151ValidatorEquals -Actual $AdmissionDecision.next_allowed_step -Expected $NextAllowedStep -Name "admission_next_allowed_step"

  $RiskAssessment = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $RiskAssessmentPath
  Assert-Phase151ValidatorEquals -Actual $RiskAssessment.status -Expected "PASS" -Name "risk_status"
  Assert-Phase151ValidatorEquals -Actual $RiskAssessment.risk_level -Expected "LOW_BOUNDED_SANDBOX" -Name "risk_level"
  foreach ($flag in @("external_fetch_allowed","install_allowed","executable_use_allowed","accepted_state_mutation_allowed","capability_shelf_mutation_allowed","dependency_install_performed","executable_materials_used","external_agents_created")) {
    Assert-Phase151ValidatorFalse -Actual $RiskAssessment.$flag -Name "risk_$flag"
  }

  $SandboxExecutionTicket = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $SandboxExecutionTicketPath
  Assert-Phase151ValidatorEquals -Actual $SandboxExecutionTicket.status -Expected "PASS" -Name "ticket_status_file"
  Assert-Phase151ValidatorEquals -Actual $SandboxExecutionTicket.ticket_status -Expected "ISSUED_FOR_PHASE152_ONLY" -Name "ticket_status"
  Assert-Phase151ValidatorEquals -Actual $SandboxExecutionTicket.execution_target -Expected $ProgramId -Name "ticket_execution_target"
  Assert-Phase151ValidatorEquals -Actual $SandboxExecutionTicket.allowed_execution_root -Expected $AllowedExecutionRoot -Name "ticket_allowed_execution_root"
  Assert-Phase151ValidatorFalse -Actual $SandboxExecutionTicket.owner_approval_required -Name "ticket_owner_approval_required"
  Assert-Phase151ValidatorFalse -Actual $SandboxExecutionTicket.accepted_state_mutation_allowed -Name "ticket_accepted_state_mutation_allowed"
  Assert-Phase151ValidatorEquals -Actual $SandboxExecutionTicket.execution_scope -Expected $ExecutionScope -Name "ticket_execution_scope"
  Assert-Phase151ValidatorFalse -Actual $SandboxExecutionTicket.program_executed -Name "ticket_program_executed"

  $ExecutionIntention = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $ExecutionIntentionPath
  Assert-Phase151ValidatorEquals -Actual $ExecutionIntention.status -Expected "PASS" -Name "execution_intention_status"
  Assert-Phase151ValidatorEquals -Actual $ExecutionIntention.intention_type -Expected "EXECUTE_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX" -Name "execution_intention_type"
  Assert-Phase151ValidatorEquals -Actual $ExecutionIntention.intended_next_step -Expected $NextAllowedStep -Name "execution_intention_next_step"
  Assert-Phase151ValidatorFalse -Actual $ExecutionIntention.program_executed_now -Name "execution_intention_program_executed_now"
  Assert-Phase151ValidatorEquals -Actual $ExecutionIntention.reason -Expected "admission completed; execution belongs to PHASE152" -Name "execution_intention_reason"

  $NextCycleDecision = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $NextCycleDecisionPath
  Assert-Phase151ValidatorEquals -Actual $NextCycleDecision.status -Expected "PASS" -Name "next_cycle_status"
  Assert-Phase151ValidatorEquals -Actual $NextCycleDecision.current_cycle_result -Expected "ADMISSION_READY" -Name "next_cycle_current_result"
  Assert-Phase151ValidatorEquals -Actual $NextCycleDecision.next_action -Expected "EXECUTE_IN_SANDBOX" -Name "next_cycle_next_action"
  Assert-Phase151ValidatorEquals -Actual $NextCycleDecision.next_allowed_step -Expected $NextAllowedStep -Name "next_cycle_next_allowed_step"
  Assert-Phase151ValidatorFalse -Actual $NextCycleDecision.codex_needed_for_next_step -Name "next_cycle_codex_needed"
  Assert-Phase151ValidatorFalse -Actual $NextCycleDecision.program_executed -Name "next_cycle_program_executed"

  $InnerLoopTrace = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $InnerLoopTracePath
  Assert-Phase151ValidatorEquals -Actual $InnerLoopTrace.status -Expected "PASS" -Name "inner_loop_trace_status"
  foreach ($field in @("observe_state","blocker_detected","internal_question_generated","internal_answer_found","bounded_decision_created","execution_intention_created")) {
    Assert-Phase151ValidatorTrue -Actual $InnerLoopTrace.$field -Name "trace_$field"
  }
  Assert-Phase151ValidatorFalse -Actual $InnerLoopTrace.program_executed -Name "trace_program_executed"

  $Result = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath
  foreach ($artifact in @($Result, $Report, $Proof)) {
    Assert-Phase151ValidatorEquals -Actual $artifact.status -Expected "PASS" -Name "artifact_status"
    Assert-Phase151ValidatorEquals -Actual $artifact.step_id -Expected $StepId -Name "artifact_step_id"
    Assert-Phase151ValidatorEquals -Actual $artifact.run_id -Expected $RunId -Name "artifact_run_id"
    Assert-Phase151ValidatorEquals -Actual $artifact.next_allowed_step -Expected $NextAllowedStep -Name "artifact_next_allowed_step"
  }

  foreach ($artifact in @($Result, $Proof)) {
    Assert-Phase151ValidatorTrue -Actual $artifact.phase150_verified -Name "phase150_verified"
    Assert-Phase151ValidatorTrue -Actual $artifact.program_candidate_verified -Name "program_candidate_verified"
    Assert-Phase151ValidatorTrue -Actual $artifact.contract_verified -Name "contract_verified"
    Assert-Phase151ValidatorTrue -Actual $artifact.admission_checklist_verified -Name "admission_checklist_verified"
    Assert-Phase151ValidatorTrue -Actual $artifact.internal_question_created -Name "internal_question_created"
    Assert-Phase151ValidatorTrue -Actual $artifact.internal_answer_search_created -Name "internal_answer_search_created"
    Assert-Phase151ValidatorTrue -Actual $artifact.internal_answer_found -Name "internal_answer_found"
    Assert-Phase151ValidatorTrue -Actual $artifact.blocker_detected -Name "blocker_detected"
    Assert-Phase151ValidatorEquals -Actual $artifact.detected_blocker -Expected $DetectedBlocker -Name "detected_blocker"
    Assert-Phase151ValidatorTrue -Actual $artifact.admission_decision_created -Name "admission_decision_created"
    Assert-Phase151ValidatorTrue -Actual $artifact.risk_assessment_created -Name "risk_assessment_created"
    Assert-Phase151ValidatorTrue -Actual $artifact.sandbox_execution_ticket_created -Name "sandbox_execution_ticket_created"
    Assert-Phase151ValidatorTrue -Actual $artifact.execution_intention_created -Name "execution_intention_created"
    Assert-Phase151ValidatorTrue -Actual $artifact.next_cycle_decision_created -Name "next_cycle_decision_created"
    Assert-Phase151ValidatorTrue -Actual $artifact.inner_loop_trace_created -Name "inner_loop_trace_created"
    Assert-Phase151ValidatorEquals -Actual $artifact.admission_status -Expected $AdmissionStatus -Name "artifact_admission_status"
    Assert-Phase151ValidatorTrue -Actual $artifact.execution_allowed -Name "artifact_execution_allowed"
    Assert-Phase151ValidatorEquals -Actual $artifact.execution_scope -Expected $ExecutionScope -Name "artifact_execution_scope"
    Assert-Phase151ValidatorFalse -Actual $artifact.program_executed -Name "artifact_program_executed"
    Assert-Phase151ValidatorFalse -Actual $artifact.accepted_state_change_approved -Name "artifact_accepted_state_change_approved"
    Assert-Phase151ValidatorFalse -Actual $artifact.codex_needed_for_next_step -Name "artifact_codex_needed_for_next_step"
    foreach ($flag in @("external_fetch_performed","dependency_install_performed","executable_materials_used","accepted_state_mutated","external_agents_created","orchestrator_changed","route_lock_changed","current_runtime_changed","capability_shelf_mutated")) {
      Assert-Phase151ValidatorFalse -Actual $artifact.$flag -Name $flag
    }
    Assert-Phase151ValidatorEquals -Actual $artifact.trusted_source_count -Expected 0 -Name "artifact_trusted_source_count"
    Assert-Phase151ValidatorEquals -Actual $artifact.queue_after -Expected "NONE" -Name "artifact_queue_after"
  }

  $Queue = Read-Phase151ValidatorJson -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
  Assert-Phase151ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  Write-Host "PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_VALIDATE_RESULT=PASS"
  Write-Host "PHASE150_VERIFIED=True"
  Write-Host "PROGRAM_CANDIDATE_VERIFIED=True"
  Write-Host "INTERNAL_QUESTION_CREATED=True"
  Write-Host "INTERNAL_ANSWER_FOUND=True"
  Write-Host "DETECTED_BLOCKER=program_not_admitted"
  Write-Host "ADMISSION_STATUS=ADMITTED_FOR_SANDBOX_EXECUTION_ONLY"
  Write-Host "EXECUTION_ALLOWED=True"
  Write-Host "EXECUTION_SCOPE=sandbox_only"
  Write-Host "PROGRAM_EXECUTED=False"
  Write-Host "ACCEPTED_STATE_CHANGE_APPROVED=False"
  Write-Host "CODEX_NEEDED_FOR_NEXT_STEP=False"
  Write-Host "EXTERNAL_FETCH_PERFORMED=False"
  Write-Host "DEPENDENCY_INSTALL_PERFORMED=False"
  Write-Host "EXECUTABLE_MATERIALS_USED=False"
  Write-Host "ACCEPTED_STATE_MUTATED=False"
  Write-Host "EXTERNAL_AGENTS_CREATED=False"
  Write-Host "ORCHESTRATOR_CHANGED=False"
  Write-Host "ROUTE_LOCK_CHANGED=False"
  Write-Host "CURRENT_RUNTIME_CHANGED=False"
  Write-Host "CAPABILITY_SHELF_MUTATED=False"
  Write-Host "TRUSTED_SOURCE_COUNT=0"
  Write-Host "QUEUE_AFTER=NONE"
  Write-Host "NEXT_ALLOWED_STEP=PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1"
} catch {
  Write-Host "PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE151_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  Pop-Location
}
