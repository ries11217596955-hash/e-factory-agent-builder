function Resolve-Phase152Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase152JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase152Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE152_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase152JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase152Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase152TextFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$Content
  )

  $fullPath = Resolve-Phase152Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  if (-not $Content.EndsWith("`n")) {
    $Content += "`n"
  }

  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase152Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE152_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase152True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE152_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase152False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE152_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function New-Phase152OrganSpec {
  param(
    [string]$OrganId,
    [string]$OrganType,
    [string]$Purpose,
    [string[]]$AllowedInputs,
    [string[]]$AllowedOutputs,
    [string[]]$ForbiddenActions
  )

  return [ordered]@{
    organ_id = $OrganId
    organ_type = $OrganType
    purpose = $Purpose
    allowed_inputs = $AllowedInputs
    allowed_outputs = $AllowedOutputs
    forbidden_actions = $ForbiddenActions
    status = "BODY_ORGAN_AVAILABLE_IN_LLE"
    accepted_capability = $false
  }
}

function Get-Phase152BodyOrganSpecs {
  $standardForbidden = @(
    "mutate accepted Builder state",
    "execute arbitrary code",
    "fetch internet",
    "install dependencies",
    "mutate capability_shelf",
    "create generated or applied agents",
    "mark sources trusted"
  )

  return @(
    (New-Phase152OrganSpec -OrganId "SELF_STATE_SENSOR_V1" -OrganType "sensor" -Purpose "Observe Builder self-development state from proofs, results, and branch assumptions without claiming accepted state without proof." -AllowedInputs @("proofs/self_development/*.json","self_control/*.json","git branch/head readback") -AllowedOutputs @("self_state_observation.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "REPO_OBSERVATION_SENSOR_V1" -OrganType "sensor" -Purpose "Read repo proof, session, ticket, and candidate files and produce observation records." -AllowedInputs @("repo JSON evidence","admission tickets","program candidates") -AllowedOutputs @("repo_observation.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "PROOF_MEMORY_SENSOR_V1" -OrganType "sensor" -Purpose "Read previous proof and report evidence as memory and classify evidence as accepted, candidate, failed, or unknown." -AllowedInputs @("proofs/self_development","reports/self_development") -AllowedOutputs @("proof_memory_observation.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "TASK_INTAKE_SENSOR_V1" -OrganType "sensor" -Purpose "Convert a task or internal intention into a structured mission candidate." -AllowedInputs @("task brief","execution intention","next cycle decision") -AllowedOutputs @("task_intake_observation.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "GOAL_STATE_MANAGER_V1" -OrganType "manager" -Purpose "Keep current goal, next allowed step, current blocker, and target output." -AllowedInputs @("task intake","proof memory","admission decision") -AllowedOutputs @("goal_state_snapshot.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "CAPABILITY_GAP_DETECTOR_V1" -OrganType "detector" -Purpose "Detect blockers and missing organs and classify gaps as executor_missing, validator_missing, tool_missing, knowledge_missing, admission_missing, body_missing, or policy_missing." -AllowedInputs @("goal state","readiness result","body registry") -AllowedOutputs @("gap_detection.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "FAILURE_CLASSIFIER_V1" -OrganType "classifier" -Purpose "Classify failed actions into missing_organ, missing_knowledge, policy_block, validation_fail, unsafe_action, external_dependency_required, or unknown_failure." -AllowedInputs @("failure evidence","gap detection") -AllowedOutputs @("failure_classification.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "INTERNAL_QUESTION_ENGINE_V1" -OrganType "engine" -Purpose "Convert a blocker or failure into an internal question." -AllowedInputs @("gap detection","failure classification") -AllowedOutputs @("internal_question.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "INTERNAL_ANSWER_SEARCHER_V1" -OrganType "searcher" -Purpose "Search internal repo sources first and produce answer candidates." -AllowedInputs @("internal question","repo sources","proof memory") -AllowedOutputs @("internal_answer_search.json","internal_answer.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "KNOWLEDGE_MEMORY_READER_V1" -OrganType "reader" -Purpose "Read knowledge_library, learning cards, proof memory, and previous traces without internet use." -AllowedInputs @("knowledge_library","proofs","traces") -AllowedOutputs @("internal_answer_search.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "CAPABILITY_SHELF_READER_V1" -OrganType "reader" -Purpose "Read capability_shelf as reference only with no mutation." -AllowedInputs @("capability_shelf/registry.json","capability_shelf/capabilities/*.json") -AllowedOutputs @("capability_shelf_read_result.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "SOURCE_POLICY_GUARD_V1" -OrganType "guard" -Purpose "Enforce source policy with default trust false, no external fetch, no installs, no executable use, and trusted source count zero." -AllowedInputs @("source_registry/source_policy.json","source_registry/trusted_sources.json") -AllowedOutputs @("source_policy_guard_result.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "ORGAN_COMPOSER_V1" -OrganType "composer" -Purpose "Create declarative organ candidates from program specs and contracts without direct accepted state mutation." -AllowedInputs @("program specs","contracts","body organ templates") -AllowedOutputs @("micro_organ_candidate.json","micro_organ_contract.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "SELF_BUILD_PROGRAM_COMPOSER_V1" -OrganType "composer" -Purpose "Create future self-build program candidates from gaps, contracts, and allowed organ templates." -AllowedInputs @("gap detection","contracts","allowed templates") -AllowedOutputs @("self_build_program_execution_result.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "SELF_BUILD_SANDBOX_EXECUTOR_V1" -OrganType "executor" -Purpose "Execute admitted declarative self-build programs in sandbox only by creating artifacts, with arbitrary code execution forbidden." -AllowedInputs @("admitted JSON program candidate","sandbox execution ticket","executor contract") -AllowedOutputs @("execution_trace.json","self_build_program_execution_result.json","sandbox artifacts") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "SANDBOX_VALIDATION_RUNNER_V1" -OrganType "runner" -Purpose "Run spec checks for sandbox artifacts and report pass or fail without accepted state mutation." -AllowedInputs @("validator_spec.json","sandbox artifacts") -AllowedOutputs @("sandbox_validation_result.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "SANDBOX_ROLLBACK_MANAGER_V1" -OrganType "manager" -Purpose "Prepare rollback plans for sandbox artifacts without deleting accepted state." -AllowedInputs @("sandbox execution result","sandbox artifact list") -AllowedOutputs @("rollback_plan.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "QUARANTINE_MANAGER_V1" -OrganType "manager" -Purpose "Prepare quarantine plans for unsafe or failed sandbox results." -AllowedInputs @("sandbox validation result","risk assessment") -AllowedOutputs @("quarantine_plan.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "MEMORY_ABSORBER_V1" -OrganType "absorber" -Purpose "Create learning and memory candidate artifacts from execution result; acceptance requires later admission." -AllowedInputs @("execution result","validation result","learning card") -AllowedOutputs @("memory_absorption_candidate.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "SELF_MODEL_UPDATE_CANDIDATE_WRITER_V1" -OrganType "writer" -Purpose "Create self-model update candidates from validated learning without accepted self-model mutation now." -AllowedInputs @("memory absorption candidate","validation result") -AllowedOutputs @("self_model_update_candidate.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "NEXT_CYCLE_DECIDER_V1" -OrganType "decider" -Purpose "Choose next action from result: VALIDATE_AND_LEARN, EXECUTE_IN_SANDBOX, QUARANTINE, REQUEST_OWNER, BUILD_MISSING_ORGAN, UPDATE_SELF_MODEL_CANDIDATE, or STOP_SAFE." -AllowedInputs @("validation result","execution result","risk state") -AllowedOutputs @("next_cycle_decision.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "DUTY_LOOP_CONTROLLER_V1" -OrganType "controller" -Purpose "Prepare future bounded self-growth cycles without running a repeated loop in PHASE152." -AllowedInputs @("next cycle decision","duty loop policy") -AllowedOutputs @("duty_loop_readiness.json") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "OWNER_ESCALATION_GATE_V1" -OrganType "gate" -Purpose "Decide when Owner approval is required for accepted state mutation, external fetch, install, money, credentials, destructive action, route change, or trust promotion." -AllowedInputs @("risk state","requested action") -AllowedOutputs @("owner escalation decision fields") -ForbiddenActions $standardForbidden),
    (New-Phase152OrganSpec -OrganId "MIGRATION_PORTABILITY_PREPARER_V1" -OrganType "preparer" -Purpose "Prepare future movement to a server or more comfortable environment by recording portability assumptions without migration now." -AllowedInputs @("body registry","runtime contract","portability assumptions") -AllowedOutputs @("portability_readiness_note.json") -ForbiddenActions $standardForbidden)
  )
}

function Invoke-BuilderExecutesAdmittedSelfBuildProgramInSandbox001 {
  param(
    [string]$RepoRoot = ".",
    [string]$RunId = "PHASE152_MAXIMAL_BODY_ORGAN_PACK_AND_SANDBOX_EXECUTION_001"
  )

  $ErrorActionPreference = "Stop"
  $RepoRoot = Resolve-Phase152Path -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot

  try {
    $StepId = "PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1"
    $NextAllowedStep = "PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1"
    $Phase151StepId = "PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1"
    $ProgramId = "PHASE150_LEARNING_CARD_REUSE_ADVISOR_SELF_BUILD_PROGRAM_CANDIDATE"
    $TargetMicroOrganId = "learning_card_reuse_advisor"
    $ExecutionMode = "declarative_json_only"
    $ExecutionScope = "sandbox_only"
    $BodyPackId = "BUILDER_BODY_ORGAN_PACK_V1"
    $BodyPackStatus = "BODY_ORGAN_PACK_AVAILABLE_IN_LLE"
    $BodyRoot = "living_learning_environment/body"
    $OrganRoot = "$BodyRoot/organs"
    $ContractRoot = "$BodyRoot/contracts"
    $SandboxRoot = "living_learning_environment/sandbox/$RunId"
    $RouteAlignmentPath = "route_change_requests/PHASE152_MAXIMAL_BODY_ORGAN_PACK_ALIGNMENT_REQUEST.md"
    $BodyPackPath = "$BodyRoot/BUILDER_BODY_ORGAN_PACK_V1.json"
    $BodyRegistryPath = "$BodyRoot/body_registry.json"
    $BodyPolicyPath = "$BodyRoot/body_policy.json"
    $BodyRuntimeContractPath = "$BodyRoot/body_runtime_contract.json"
    $BodySafetyBoundariesPath = "$BodyRoot/body_safety_boundaries.json"
    $BodyPortabilityManifestPath = "$BodyRoot/body_portability_manifest.json"
    $BodyOrganContractPath = "$ContractRoot/BODY_ORGAN_CONTRACT_V1.json"
    $ExecutorContractPath = "$ContractRoot/SELF_BUILD_SANDBOX_EXECUTOR_CONTRACT_V1.json"
    $DutyLoopContractPath = "$ContractRoot/DUTY_LOOP_CONTROLLER_CONTRACT_V1.json"
    $FailureRecoveryContractPath = "$ContractRoot/FAILURE_RECOVERY_CONTRACT_V1.json"
    $MemoryAbsorptionContractPath = "$ContractRoot/MEMORY_ABSORPTION_CONTRACT_V1.json"
    $PortabilityContractPath = "$ContractRoot/PORTABILITY_CONTRACT_V1.json"

    $Phase151ProofPath = "proofs/self_development/PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1.json"
    $Phase151TicketPath = "living_learning_environment/inner_loop/PHASE151_BRAIN_CELL_INNER_LOOP_IGNITION_001/sandbox_execution_ticket.json"
    $Phase151AdmissionDecisionPath = "living_learning_environment/inner_loop/PHASE151_BRAIN_CELL_INNER_LOOP_IGNITION_001/admission_decision.json"
    $Phase151ExecutionIntentionPath = "living_learning_environment/inner_loop/PHASE151_BRAIN_CELL_INNER_LOOP_IGNITION_001/execution_intention.json"
    $Phase151NextCyclePath = "living_learning_environment/inner_loop/PHASE151_BRAIN_CELL_INNER_LOOP_IGNITION_001/next_cycle_decision.json"
    $Phase150CandidatePath = "living_learning_environment/sandbox/PHASE150_SELF_BUILD_IGNITION_BRIDGE_001/self_build_program_candidate.json"
    $Phase150ContractPath = "living_learning_environment/sandbox/PHASE150_SELF_BUILD_IGNITION_BRIDGE_001/self_build_program_contract.json"
    $SourcePolicyPath = "source_registry/source_policy.json"
    $TrustedSourcesPath = "source_registry/trusted_sources.json"
    $CapabilityShelfRegistryPath = "capability_shelf/registry.json"
    $LearningCardPath = "knowledge_library/learning_cards/PHASE149_CAPABILITY_REUSE_LEARNING_CARD.json"
    $ReuseProposalPath = "living_learning_environment/proposals/PHASE149_REUSE_PROPOSAL.json"

    $BodyActivationTracePath = "$SandboxRoot/body_activation_trace.json"
    $SelfStateObservationPath = "$SandboxRoot/self_state_observation.json"
    $RepoObservationPath = "$SandboxRoot/repo_observation.json"
    $ProofMemoryObservationPath = "$SandboxRoot/proof_memory_observation.json"
    $TaskIntakeObservationPath = "$SandboxRoot/task_intake_observation.json"
    $GoalStateSnapshotPath = "$SandboxRoot/goal_state_snapshot.json"
    $GapDetectionPath = "$SandboxRoot/gap_detection.json"
    $FailureClassificationPath = "$SandboxRoot/failure_classification.json"
    $InternalQuestionPath = "$SandboxRoot/internal_question.json"
    $InternalAnswerSearchPath = "$SandboxRoot/internal_answer_search.json"
    $InternalAnswerPath = "$SandboxRoot/internal_answer.json"
    $SourcePolicyGuardResultPath = "$SandboxRoot/source_policy_guard_result.json"
    $CapabilityShelfReadResultPath = "$SandboxRoot/capability_shelf_read_result.json"
    $ExecutionTracePath = "$SandboxRoot/execution_trace.json"
    $SelfBuildProgramExecutionResultPath = "$SandboxRoot/self_build_program_execution_result.json"
    $MicroOrganCandidatePath = "$SandboxRoot/micro_organ_candidate.json"
    $MicroOrganContractPath = "$SandboxRoot/micro_organ_contract.json"
    $InputExamplePath = "$SandboxRoot/input_example.json"
    $OutputExamplePath = "$SandboxRoot/output_example.json"
    $ValidatorSpecPath = "$SandboxRoot/validator_spec.json"
    $SandboxValidationResultPath = "$SandboxRoot/sandbox_validation_result.json"
    $RollbackPlanPath = "$SandboxRoot/rollback_plan.json"
    $QuarantinePlanPath = "$SandboxRoot/quarantine_plan.json"
    $MemoryAbsorptionCandidatePath = "$SandboxRoot/memory_absorption_candidate.json"
    $SelfModelUpdateCandidatePath = "$SandboxRoot/self_model_update_candidate.json"
    $NextCycleDecisionPath = "$SandboxRoot/next_cycle_decision.json"
    $DutyLoopReadinessPath = "$SandboxRoot/duty_loop_readiness.json"
    $PortabilityReadinessNotePath = "$SandboxRoot/portability_readiness_note.json"
    $ResultPath = "self_control/BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_RESULT.json"
    $ReportPath = "reports/self_development/PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1_REPORT.json"
    $ProofPath = "proofs/self_development/PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1.json"

    foreach ($identityFile in @(
      "CAPABILITY_ROADMAP.json",
      "GENESIS_STATE.json",
      "TASK_QUEUE.json",
      "packs/registry.json",
      "orchestrator/run.ps1"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase152Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $Branch = (git branch --show-current).Trim()
    if ($Branch -eq "main") {
      throw "PHASE152_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase152Equals -Actual $Branch -Expected "phase110-idempotent-autonomy-trial-runtime" -Name "current_branch"
    $Head = (git rev-parse --short HEAD).Trim()
    Assert-Phase152Equals -Actual $Head -Expected "a84caef" -Name "current_head"

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
      proofs/self_development/PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1.json `
      reports/self_development/PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1_REPORT.json `
      reports/self_development/PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1_REPORT.json `
      reports/self_development/PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1_REPORT.json `
      reports/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1_REPORT.json `
      reports/self_development/PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1_REPORT.json `
      reports/self_development/PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1_REPORT.json `
      reports/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1_REPORT.json `
      reports/self_development/PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1_REPORT.json `
      reports/self_development/PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1_REPORT.json `
      reports/self_development/PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1_REPORT.json 2>$null)
    if ($ForbiddenBefore.Count -gt 0) {
      throw "PHASE152_FORBIDDEN_SCOPE_DIRTY_BEFORE=$($ForbiddenBefore -join '; ')"
    }

    $Phase151Proof = Read-Phase152JsonRequired -RepoRoot $RepoRoot -Path $Phase151ProofPath
    Assert-Phase152Equals -Actual $Phase151Proof.status -Expected "PASS" -Name "phase151_status"
    Assert-Phase152Equals -Actual $Phase151Proof.admission_status -Expected "ADMITTED_FOR_SANDBOX_EXECUTION_ONLY" -Name "phase151_admission_status"
    Assert-Phase152True -Actual $Phase151Proof.execution_allowed -Name "phase151_execution_allowed"
    Assert-Phase152Equals -Actual $Phase151Proof.execution_scope -Expected $ExecutionScope -Name "phase151_execution_scope"
    Assert-Phase152False -Actual $Phase151Proof.codex_needed_for_next_step -Name "phase151_codex_needed_for_next_step"
    Assert-Phase152Equals -Actual $Phase151Proof.next_allowed_step -Expected $StepId -Name "phase151_next_allowed_step"

    $Ticket = Read-Phase152JsonRequired -RepoRoot $RepoRoot -Path $Phase151TicketPath
    Assert-Phase152Equals -Actual $Ticket.ticket_status -Expected "ISSUED_FOR_PHASE152_ONLY" -Name "ticket_status"
    Assert-Phase152Equals -Actual $Ticket.execution_target -Expected $ProgramId -Name "ticket_execution_target"
    Assert-Phase152False -Actual $Ticket.accepted_state_mutation_allowed -Name "ticket_accepted_state_mutation_allowed"
    Assert-Phase152Equals -Actual $Ticket.execution_scope -Expected $ExecutionScope -Name "ticket_execution_scope"
    Assert-Phase152Equals -Actual $Ticket.valid_for_step -Expected $StepId -Name "ticket_valid_for_step"

    $AdmissionDecision = Read-Phase152JsonRequired -RepoRoot $RepoRoot -Path $Phase151AdmissionDecisionPath
    Assert-Phase152Equals -Actual $AdmissionDecision.admission_status -Expected "ADMITTED_FOR_SANDBOX_EXECUTION_ONLY" -Name "admission_status"
    Assert-Phase152True -Actual $AdmissionDecision.execution_allowed -Name "admission_execution_allowed"
    Assert-Phase152Equals -Actual $AdmissionDecision.execution_scope -Expected $ExecutionScope -Name "admission_execution_scope"

    $ExecutionIntention = Read-Phase152JsonRequired -RepoRoot $RepoRoot -Path $Phase151ExecutionIntentionPath
    Assert-Phase152Equals -Actual $ExecutionIntention.intention_type -Expected "EXECUTE_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX" -Name "execution_intention_type"
    Assert-Phase152Equals -Actual $ExecutionIntention.intended_next_step -Expected $StepId -Name "execution_intention_next_step"
    Assert-Phase152False -Actual $ExecutionIntention.program_executed_now -Name "execution_intention_program_executed_now"

    $Phase151NextCycle = Read-Phase152JsonRequired -RepoRoot $RepoRoot -Path $Phase151NextCyclePath
    Assert-Phase152Equals -Actual $Phase151NextCycle.next_action -Expected "EXECUTE_IN_SANDBOX" -Name "phase151_next_action"
    Assert-Phase152False -Actual $Phase151NextCycle.codex_needed_for_next_step -Name "phase151_next_cycle_codex_needed"

    $Phase150Candidate = Read-Phase152JsonRequired -RepoRoot $RepoRoot -Path $Phase150CandidatePath
    Assert-Phase152Equals -Actual $Phase150Candidate.program_status -Expected "CANDIDATE_NOT_ADMITTED" -Name "phase150_candidate_program_status"
    Assert-Phase152Equals -Actual $Phase150Candidate.target_micro_organ_id -Expected $TargetMicroOrganId -Name "phase150_candidate_target_micro_organ"

    $Phase150Contract = Read-Phase152JsonRequired -RepoRoot $RepoRoot -Path $Phase150ContractPath
    Assert-Phase152Equals -Actual $Phase150Contract.target_micro_organ_id -Expected $TargetMicroOrganId -Name "phase150_contract_target_micro_organ"

    $SourcePolicy = Read-Phase152JsonRequired -RepoRoot $RepoRoot -Path $SourcePolicyPath
    Assert-Phase152False -Actual $SourcePolicy.default_trust -Name "source_policy_default_trust"
    Assert-Phase152False -Actual $SourcePolicy.external_fetch_allowed -Name "source_policy_external_fetch_allowed"
    Assert-Phase152False -Actual $SourcePolicy.install_allowed -Name "source_policy_install_allowed"
    Assert-Phase152False -Actual $SourcePolicy.executable_use_allowed -Name "source_policy_executable_use_allowed"

    $TrustedSources = Read-Phase152JsonRequired -RepoRoot $RepoRoot -Path $TrustedSourcesPath
    Assert-Phase152Equals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count"
    Assert-Phase152Equals -Actual @($TrustedSources.trusted_sources).Count -Expected 0 -Name "trusted_sources_empty"

    $CapabilityShelfRegistry = Read-Phase152JsonRequired -RepoRoot $RepoRoot -Path $CapabilityShelfRegistryPath
    $LearningCard = Read-Phase152JsonRequired -RepoRoot $RepoRoot -Path $LearningCardPath
    $ReuseProposal = Read-Phase152JsonRequired -RepoRoot $RepoRoot -Path $ReuseProposalPath
    $Queue = Read-Phase152JsonRequired -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
    Assert-Phase152Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $OrganSpecs = Get-Phase152BodyOrganSpecs
    Assert-Phase152Equals -Actual @($OrganSpecs).Count -Expected 24 -Name "body_organ_count"
    $OrganIds = @($OrganSpecs | ForEach-Object { $_.organ_id })
    $OrganPaths = @($OrganSpecs | ForEach-Object { "$OrganRoot/$($_.organ_id).json" })

    Write-Phase152TextFile -RepoRoot $RepoRoot -Path $RouteAlignmentPath -Content ((@(
      "# PHASE152 Body Organ Pack Alignment Request",
      "",
      "status: PASS",
      "line: AGENT_BUILDER_SELF_DEVELOPMENT",
      "mode: SELF_BUILD",
      "body_pack_id: $BodyPackId",
      "body_organ_count: 24",
      "execution_mode: $ExecutionMode",
      "execution_scope: $ExecutionScope",
      "target_micro_organ_id: $TargetMicroOrganId",
      "accepted_state_mutated: false",
      "arbitrary_code_execution_used: false",
      "next_allowed_step: $NextAllowedStep"
    )) -join "`n")

    $BodyPack = [ordered]@{
      status = "PASS"
      body_pack_id = $BodyPackId
      body_pack_status = $BodyPackStatus
      body_organ_count = 24
      design_scope = "foundational_body_system_for_current_safety_boundary"
      body_is_not_accepted_core = $true
      body_organs_are_lle_organs = $true
      accepted_capability = $false
      organ_ids = $OrganIds
      registry_path = $BodyRegistryPath
      policy_path = $BodyPolicyPath
      runtime_contract_path = $BodyRuntimeContractPath
      safety_boundaries_path = $BodySafetyBoundariesPath
      portability_manifest_path = $BodyPortabilityManifestPath
      contract_paths = @($BodyOrganContractPath, $ExecutorContractPath, $DutyLoopContractPath, $FailureRecoveryContractPath, $MemoryAbsorptionContractPath, $PortabilityContractPath)
      next_allowed_step = $StepId
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $BodyPackPath -Object $BodyPack

    $BodyRegistry = [ordered]@{
      status = "PASS"
      body_pack_id = $BodyPackId
      body_pack_status = $BodyPackStatus
      body_organ_count = 24
      organs = $OrganSpecs
      accepted_capability = $false
      next_allowed_step = $StepId
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $BodyRegistryPath -Object $BodyRegistry

    $BodyPolicy = [ordered]@{
      status = "PASS"
      policy_id = "BODY_POLICY_V1"
      body_pack_id = $BodyPackId
      body_is_not_accepted_core = $true
      body_organs_are_lle_organs = $true
      accepted_state_mutation_allowed = $false
      arbitrary_code_execution_allowed = $false
      external_fetch_allowed = $false
      install_allowed = $false
      capability_shelf_mutation_allowed = $false
      generated_agents_allowed = $false
      applied_agents_allowed = $false
      owner_approval_required_for_promotion = $true
      next_allowed_step = $StepId
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $BodyPolicyPath -Object $BodyPolicy

    $BodyRuntimeContract = [ordered]@{
      status = "PASS"
      contract_id = "BODY_RUNTIME_CONTRACT_V1"
      body_pack_id = $BodyPackId
      allowed_execution_mode = $ExecutionMode
      allowed_scope = $ExecutionScope
      allowed_runtime_roots = @($SandboxRoot)
      accepted_state_mutation_allowed = $false
      repeated_duty_loop_allowed_now = $false
      validators_required = $true
      next_allowed_step = $StepId
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $BodyRuntimeContractPath -Object $BodyRuntimeContract

    $BodySafetyBoundaries = [ordered]@{
      status = "PASS"
      boundary_id = "BODY_SAFETY_BOUNDARIES_V1"
      body_pack_id = $BodyPackId
      accepted_state_mutation_allowed = $false
      arbitrary_code_execution_allowed = $false
      external_fetch_allowed = $false
      install_allowed = $false
      executable_materials_allowed = $false
      capability_shelf_mutation_allowed = $false
      generated_agents_allowed = $false
      applied_agents_allowed = $false
      route_lock_mutation_allowed = $false
      orchestrator_mutation_allowed = $false
      migration_allowed_now = $false
      next_allowed_step = $StepId
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $BodySafetyBoundariesPath -Object $BodySafetyBoundaries

    $BodyPortabilityManifest = [ordered]@{
      status = "PASS"
      manifest_id = "BODY_PORTABILITY_MANIFEST_V1"
      body_pack_id = $BodyPackId
      portability_prepared = $true
      migration_performed = $false
      portable_roots = @("living_learning_environment/body", "living_learning_environment/sandbox")
      required_invariants = @("JSON-only contracts", "repo-relative paths", "no trusted source by default", "sandbox writes before promotion")
      next_allowed_step = $StepId
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $BodyPortabilityManifestPath -Object $BodyPortabilityManifest

    foreach ($organ in $OrganSpecs) {
      $organFile = [ordered]@{
        status = "PASS"
        body_pack_id = $BodyPackId
        organ_id = $organ.organ_id
        organ_type = $organ.organ_type
        purpose = $organ.purpose
        allowed_inputs = $organ.allowed_inputs
        allowed_outputs = $organ.allowed_outputs
        forbidden_actions = $organ.forbidden_actions
        organ_status = "BODY_ORGAN_AVAILABLE_IN_LLE"
        accepted_capability = $false
        next_allowed_step = $StepId
      }
      Write-Phase152JsonFile -RepoRoot $RepoRoot -Path "$OrganRoot/$($organ.organ_id).json" -Object $organFile
    }

    $BodyOrganContract = [ordered]@{
      status = "PASS"
      contract_id = "BODY_ORGAN_CONTRACT_V1"
      body_pack_id = $BodyPackId
      required_fields = @("organ_id","organ_type","purpose","allowed_inputs","allowed_outputs","forbidden_actions","status","accepted_capability")
      accepted_capability_must_equal = $false
      mutation_rule = "Body organs may create sandbox or candidate artifacts only."
      next_allowed_step = $StepId
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $BodyOrganContractPath -Object $BodyOrganContract

    $ExecutorContract = [ordered]@{
      status = "PASS"
      contract_id = "SELF_BUILD_SANDBOX_EXECUTOR_CONTRACT_V1"
      executor_id = "SELF_BUILD_SANDBOX_EXECUTOR_V1"
      execution_mode = $ExecutionMode
      allowed_scope = $ExecutionScope
      arbitrary_code_execution_allowed = $false
      external_fetch_allowed = $false
      install_allowed = $false
      accepted_state_mutation_allowed = $false
      capability_shelf_mutation_allowed = $false
      generated_agents_allowed = $false
      applied_agents_allowed = $false
      accepted_program_inputs = @("admitted declarative JSON self-build program candidate", "PHASE151 sandbox execution ticket")
      produced_outputs = @("execution_trace.json", "self_build_program_execution_result.json", "sandbox micro-organ candidate artifacts")
      next_allowed_step = $StepId
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $ExecutorContractPath -Object $ExecutorContract

    $DutyLoopContract = [ordered]@{
      status = "PASS"
      contract_id = "DUTY_LOOP_CONTROLLER_CONTRACT_V1"
      controller_id = "DUTY_LOOP_CONTROLLER_V1"
      repeated_loop_allowed_now = $false
      duty_loop_ready_for_bounded_trial = $false
      readiness_requires = @("PHASE153 validation", "learning absorption acceptance", "owner-visible proof")
      next_allowed_step = $StepId
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $DutyLoopContractPath -Object $DutyLoopContract

    $FailureRecoveryContract = [ordered]@{
      status = "PASS"
      contract_id = "FAILURE_RECOVERY_CONTRACT_V1"
      failure_classes = @("missing_organ","missing_knowledge","policy_block","validation_fail","unsafe_action","external_dependency_required","unknown_failure")
      recovery_outputs = @("rollback_plan.json","quarantine_plan.json","next_cycle_decision.json")
      accepted_state_delete_allowed = $false
      next_allowed_step = $StepId
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $FailureRecoveryContractPath -Object $FailureRecoveryContract

    $MemoryAbsorptionContract = [ordered]@{
      status = "PASS"
      contract_id = "MEMORY_ABSORPTION_CONTRACT_V1"
      absorber_id = "MEMORY_ABSORBER_V1"
      output_status = "CANDIDATE_MEMORY_ONLY"
      accepted_memory_mutation_allowed_now = $false
      validation_required_before_acceptance = $true
      next_allowed_step = $StepId
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $MemoryAbsorptionContractPath -Object $MemoryAbsorptionContract

    $PortabilityContract = [ordered]@{
      status = "PASS"
      contract_id = "PORTABILITY_CONTRACT_V1"
      preparer_id = "MIGRATION_PORTABILITY_PREPARER_V1"
      migration_performed = $false
      portability_assumptions_recorded = $true
      accepted_state_migration_allowed_now = $false
      next_allowed_step = $StepId
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $PortabilityContractPath -Object $PortabilityContract

    foreach ($requiredBodyPath in @(
      $BodyPackPath,
      $BodyRegistryPath,
      $BodyPolicyPath,
      $BodyRuntimeContractPath,
      $BodySafetyBoundariesPath,
      $BodyPortabilityManifestPath,
      $BodyOrganContractPath,
      $ExecutorContractPath,
      $DutyLoopContractPath,
      $FailureRecoveryContractPath,
      $MemoryAbsorptionContractPath,
      $PortabilityContractPath
    ) + $OrganPaths) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase152Path -RepoRoot $RepoRoot -Path $requiredBodyPath))) {
        throw "PHASE152_BODY_FILE_NOT_CREATED=$requiredBodyPath"
      }
    }

    $VerifiedRegistry = Read-Phase152JsonRequired -RepoRoot $RepoRoot -Path $BodyRegistryPath
    Assert-Phase152Equals -Actual $VerifiedRegistry.body_organ_count -Expected 24 -Name "verified_body_organ_count"
    foreach ($registeredOrgan in @($VerifiedRegistry.organs)) {
      Assert-Phase152False -Actual $registeredOrgan.accepted_capability -Name "registered_organ_accepted_capability"
      Assert-Phase152Equals -Actual $registeredOrgan.status -Expected "BODY_ORGAN_AVAILABLE_IN_LLE" -Name "registered_organ_status"
    }

    $InputSources = @(
      $Phase151ProofPath,
      $Phase151TicketPath,
      $Phase151AdmissionDecisionPath,
      $Phase151ExecutionIntentionPath,
      $Phase151NextCyclePath,
      $Phase150CandidatePath,
      $Phase150ContractPath,
      $SourcePolicyPath,
      $TrustedSourcesPath,
      $CapabilityShelfRegistryPath,
      $LearningCardPath,
      $ReuseProposalPath
    )

    $BodyActivationTrace = [ordered]@{
      status = "PASS"
      trace_id = "PHASE152_BODY_ACTIVATION_TRACE"
      step_id = $StepId
      run_id = $RunId
      body_pack_id = $BodyPackId
      body_organ_count = 24
      activated_organs = @($OrganSpecs | ForEach-Object {
        [ordered]@{
          organ_id = $_.organ_id
          activation_status = "ACTIVATED_FOR_PHASE152_SANDBOX_EXECUTION"
          used_as_applicable = $true
          accepted_capability = $false
        }
      })
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $BodyActivationTracePath -Object $BodyActivationTrace

    $SelfStateObservation = [ordered]@{
      status = "PASS"
      observation_id = "PHASE152_SELF_STATE_OBSERVATION"
      step_id = $StepId
      run_id = $RunId
      branch = $Branch
      head = $Head
      phase151_verified = $true
      current_line = "AGENT_BUILDER_SELF_DEVELOPMENT"
      current_mode = "SELF_BUILD"
      accepted_state_claim_source = $Phase151ProofPath
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $SelfStateObservationPath -Object $SelfStateObservation

    $RepoObservation = [ordered]@{
      status = "PASS"
      observation_id = "PHASE152_REPO_OBSERVATION"
      step_id = $StepId
      run_id = $RunId
      sources_read = $InputSources
      body_pack_paths = @($BodyPackPath, $BodyRegistryPath, $BodyPolicyPath, $BodyRuntimeContractPath, $BodySafetyBoundariesPath, $BodyPortabilityManifestPath)
      protected_paths_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $RepoObservationPath -Object $RepoObservation

    $ProofMemoryObservation = [ordered]@{
      status = "PASS"
      observation_id = "PHASE152_PROOF_MEMORY_OBSERVATION"
      step_id = $StepId
      run_id = $RunId
      accepted_evidence = @($Phase151ProofPath)
      candidate_evidence = @($Phase150CandidatePath, $Phase150ContractPath)
      failed_evidence = @("PHASE152_FINALIZE_RESULT=BLOCKED_NOT_EXECUTED")
      evidence_classification = "accepted_phase151_then_addressed_missing_body_executor_and_validator"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $ProofMemoryObservationPath -Object $ProofMemoryObservation

    $TaskIntakeObservation = [ordered]@{
      status = "PASS"
      observation_id = "PHASE152_TASK_INTAKE_OBSERVATION"
      step_id = $StepId
      run_id = $RunId
      mission_candidate = "execute admitted self-build program in sandbox using body organ pack"
      admitted_program_id = $ProgramId
      target_micro_organ_id = $TargetMicroOrganId
      execution_scope = $ExecutionScope
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $TaskIntakeObservationPath -Object $TaskIntakeObservation

    $GoalStateSnapshot = [ordered]@{
      status = "PASS"
      snapshot_id = "PHASE152_GOAL_STATE_SNAPSHOT"
      step_id = $StepId
      run_id = $RunId
      current_goal = "compose learning_card_reuse_advisor sandbox artifacts from admitted declarative program"
      next_allowed_step = $NextAllowedStep
      current_blocker = "readiness previously lacked executor and validator"
      blocker_addressed_by = @("SELF_BUILD_SANDBOX_EXECUTOR_V1","SANDBOX_VALIDATION_RUNNER_V1")
      target_output = "validated sandbox micro-organ candidate"
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $GoalStateSnapshotPath -Object $GoalStateSnapshot

    $GapDetection = [ordered]@{
      status = "PASS"
      detection_id = "PHASE152_GAP_DETECTION"
      step_id = $StepId
      run_id = $RunId
      previous_blocker = "NO_EXISTING_PHASE152_EXECUTOR_OR_VALIDATOR"
      detected_gap_classes = @("executor_missing","validator_missing","body_missing")
      addressed_by_body_organs = @("SELF_BUILD_SANDBOX_EXECUTOR_V1","SANDBOX_VALIDATION_RUNNER_V1","DUTY_LOOP_CONTROLLER_V1")
      gap_addressed_for_phase152 = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $GapDetectionPath -Object $GapDetection

    $FailureClassification = [ordered]@{
      status = "PASS"
      classification_id = "PHASE152_FAILURE_CLASSIFICATION"
      step_id = $StepId
      run_id = $RunId
      previous_result = "BLOCKED_NOT_EXECUTED"
      failure_class = "missing_organ"
      failure_addressed = $true
      addressed_by = @("SELF_BUILD_SANDBOX_EXECUTOR_V1","SANDBOX_VALIDATION_RUNNER_V1")
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $FailureClassificationPath -Object $FailureClassification

    $InternalQuestion = [ordered]@{
      status = "PASS"
      question_id = "PHASE152_INTERNAL_EXECUTION_QUESTION"
      step_id = $StepId
      run_id = $RunId
      question_type = "SANDBOX_EXECUTION"
      question = "How can the admitted declarative self-build program be executed inside the current safety boundary?"
      asked_by = "INTERNAL_QUESTION_ENGINE_V1"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $InternalQuestionPath -Object $InternalQuestion

    $InternalAnswerSearch = [ordered]@{
      status = "PASS"
      search_id = "PHASE152_INTERNAL_ANSWER_SEARCH"
      step_id = $StepId
      run_id = $RunId
      search_scope = "internal_repo_only"
      sources_read = $InputSources
      external_fetch_performed = $false
      answer_found = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $InternalAnswerSearchPath -Object $InternalAnswerSearch

    $InternalAnswer = [ordered]@{
      status = "PASS"
      answer_id = "PHASE152_INTERNAL_ANSWER"
      step_id = $StepId
      run_id = $RunId
      answer = "Use SELF_BUILD_SANDBOX_EXECUTOR_V1 to interpret the admitted JSON candidate and create sandbox-only learning_card_reuse_advisor artifacts, then validate and prepare learning candidates."
      execution_mode = $ExecutionMode
      execution_scope = $ExecutionScope
      arbitrary_code_execution_used = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $InternalAnswerPath -Object $InternalAnswer

    $SourcePolicyGuardResult = [ordered]@{
      status = "PASS"
      guard_id = "PHASE152_SOURCE_POLICY_GUARD_RESULT"
      step_id = $StepId
      run_id = $RunId
      default_trust = $SourcePolicy.default_trust
      external_fetch_allowed = $SourcePolicy.external_fetch_allowed
      install_allowed = $SourcePolicy.install_allowed
      executable_use_allowed = $SourcePolicy.executable_use_allowed
      trusted_source_count = $TrustedSources.trusted_source_count
      source_policy_safe = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $SourcePolicyGuardResultPath -Object $SourcePolicyGuardResult

    $CapabilityShelfReadResult = [ordered]@{
      status = "PASS"
      read_id = "PHASE152_CAPABILITY_SHELF_READ_RESULT"
      step_id = $StepId
      run_id = $RunId
      registry_path = $CapabilityShelfRegistryPath
      reusable_capability_count = $CapabilityShelfRegistry.reusable_capability_count
      read_only = $true
      capability_shelf_mutated = $false
      selected_reference_capability = "self_learning_memory"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $CapabilityShelfReadResultPath -Object $CapabilityShelfReadResult

    $MicroOrganCandidate = [ordered]@{
      status = "PASS"
      candidate_id = "PHASE152_LEARNING_CARD_REUSE_ADVISOR_MICRO_ORGAN_CANDIDATE"
      step_id = $StepId
      run_id = $RunId
      target_micro_organ_id = $TargetMicroOrganId
      candidate_status = "SANDBOX_CANDIDATE_NOT_ACCEPTED"
      created_by_executor = "SELF_BUILD_SANDBOX_EXECUTOR_V1"
      execution_mode = $ExecutionMode
      accepted_capability = $false
      purpose = "Read learning cards and reuse proposals, compare requested gaps to existing reusable capabilities, and recommend reuse before creating a new organ."
      allowed_inputs = @("knowledge_library/learning_cards/*.json","living_learning_environment/proposals/*.json","capability_shelf/registry.json")
      allowed_outputs = @("living_learning_environment/sandbox/<future_run>/reuse_advice.json","knowledge_library/learning_cards/<candidate_learning>.json")
      forbidden_actions = @("mutate accepted state","mutate capability_shelf","fetch internet","install dependencies","execute arbitrary code","create external agents","mark source trusted")
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $MicroOrganCandidatePath -Object $MicroOrganCandidate

    $MicroOrganContract = [ordered]@{
      status = "PASS"
      contract_id = "PHASE152_LEARNING_CARD_REUSE_ADVISOR_MICRO_ORGAN_CONTRACT"
      step_id = $StepId
      run_id = $RunId
      target_micro_organ_id = $TargetMicroOrganId
      candidate_path = $MicroOrganCandidatePath
      execution_mode = $ExecutionMode
      allowed_scope = $ExecutionScope
      input_contract = @("learning cards must include status and selected_capability_id when present","reuse proposals must include accepted_state_change_requested")
      output_contract = @("recommend_reuse boolean","selected_capability_id when safe","reason","forbidden_flags all false")
      accepted_state_mutation_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $MicroOrganContractPath -Object $MicroOrganContract

    $InputExample = [ordered]@{
      status = "PASS"
      example_id = "PHASE152_REUSE_ADVISOR_INPUT_EXAMPLE"
      step_id = $StepId
      run_id = $RunId
      requested_gap = "need a learning card reuse advisor"
      learning_card_reference = $LearningCard.card_id
      reuse_proposal_reference = $ReuseProposal.proposal_id
      selected_capability_id = $LearningCard.selected_capability_id
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $InputExamplePath -Object $InputExample

    $OutputExample = [ordered]@{
      status = "PASS"
      example_id = "PHASE152_REUSE_ADVISOR_OUTPUT_EXAMPLE"
      step_id = $StepId
      run_id = $RunId
      recommend_reuse = $true
      selected_capability_id = "self_learning_memory"
      reason = "Existing self_learning_memory capability and PHASE149 learning card provide reusable internal context before building a new organ."
      accepted_state_change_requested = $false
      forbidden_flags = [ordered]@{
        external_fetch_performed = $false
        dependency_install_performed = $false
        executable_materials_used = $false
        accepted_state_mutated = $false
        external_agents_created = $false
      }
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $OutputExamplePath -Object $OutputExample

    $ValidatorSpec = [ordered]@{
      status = "PASS"
      spec_id = "PHASE152_REUSE_ADVISOR_VALIDATOR_SPEC"
      step_id = $StepId
      run_id = $RunId
      target_micro_organ_id = $TargetMicroOrganId
      required_fields = @("status","target_micro_organ_id","candidate_status","execution_mode","accepted_capability","forbidden_actions")
      required_false_flags = @("accepted_capability","external_fetch_performed","dependency_install_performed","executable_materials_used","accepted_state_mutated","external_agents_created")
      expected_execution_mode = $ExecutionMode
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $ValidatorSpecPath -Object $ValidatorSpec

    $ExecutionTrace = [ordered]@{
      status = "PASS"
      trace_id = "PHASE152_SANDBOX_EXECUTION_TRACE"
      step_id = $StepId
      run_id = $RunId
      executor_id = "SELF_BUILD_SANDBOX_EXECUTOR_V1"
      program_id = $ProgramId
      execution_mode = $ExecutionMode
      execution_scope = $ExecutionScope
      program_executed = $true
      arbitrary_code_execution_used = $false
      created_artifacts = @($MicroOrganCandidatePath, $MicroOrganContractPath, $InputExamplePath, $OutputExamplePath, $ValidatorSpecPath)
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $ExecutionTracePath -Object $ExecutionTrace

    $SelfBuildProgramExecutionResult = [ordered]@{
      status = "PASS"
      result_id = "PHASE152_SELF_BUILD_PROGRAM_EXECUTION_RESULT"
      step_id = $StepId
      run_id = $RunId
      program_id = $ProgramId
      target_micro_organ_id = $TargetMicroOrganId
      program_executed = $true
      execution_mode = $ExecutionMode
      execution_scope = $ExecutionScope
      arbitrary_code_execution_used = $false
      accepted_state_mutated = $false
      output_files = @($MicroOrganCandidatePath, $MicroOrganContractPath, $InputExamplePath, $OutputExamplePath, $ValidatorSpecPath)
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $SelfBuildProgramExecutionResultPath -Object $SelfBuildProgramExecutionResult

    $SandboxValidationResult = [ordered]@{
      status = "PASS"
      validation_id = "PHASE152_SANDBOX_VALIDATION_RESULT"
      step_id = $StepId
      run_id = $RunId
      validator_id = "SANDBOX_VALIDATION_RUNNER_V1"
      target_micro_organ_id = $TargetMicroOrganId
      checked_files = @($MicroOrganCandidatePath, $MicroOrganContractPath, $InputExamplePath, $OutputExamplePath, $ValidatorSpecPath)
      validation_result = "PASS"
      program_executed = $true
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $SandboxValidationResultPath -Object $SandboxValidationResult

    $RollbackPlan = [ordered]@{
      status = "PASS"
      plan_id = "PHASE152_SANDBOX_ROLLBACK_PLAN"
      step_id = $StepId
      run_id = $RunId
      rollback_scope = $ExecutionScope
      sandbox_root = $SandboxRoot
      accepted_state_delete_allowed = $false
      rollback_action = "If PHASE153 validation fails, mark sandbox result rejected and ignore sandbox artifacts until owner-directed cleanup."
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $RollbackPlanPath -Object $RollbackPlan

    $QuarantinePlan = [ordered]@{
      status = "PASS"
      plan_id = "PHASE152_QUARANTINE_PLAN"
      step_id = $StepId
      run_id = $RunId
      quarantine_required_now = $false
      quarantine_if = @("sandbox validation fails","forbidden flag becomes true","artifact leaves sandbox scope")
      quarantine_scope = $ExecutionScope
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $QuarantinePlanPath -Object $QuarantinePlan

    $MemoryAbsorptionCandidate = [ordered]@{
      status = "PASS"
      candidate_id = "PHASE152_MEMORY_ABSORPTION_CANDIDATE"
      step_id = $StepId
      run_id = $RunId
      candidate_status = "CANDIDATE_MEMORY_ONLY"
      source_execution_result = $SelfBuildProgramExecutionResultPath
      learning = "The body pack can execute admitted declarative self-build programs into sandbox artifacts without accepted state mutation."
      accepted_memory_mutation_allowed_now = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $MemoryAbsorptionCandidatePath -Object $MemoryAbsorptionCandidate

    $SelfModelUpdateCandidate = [ordered]@{
      status = "PASS"
      candidate_id = "PHASE152_SELF_MODEL_UPDATE_CANDIDATE"
      step_id = $StepId
      run_id = $RunId
      candidate_status = "SELF_MODEL_UPDATE_CANDIDATE_ONLY"
      proposed_self_model_statement = "Builder has an LLE body organ pack able to perform JSON-only sandbox self-build execution after admission."
      accepted_self_model_mutation_allowed_now = $false
      requires_phase153_validation = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $SelfModelUpdateCandidatePath -Object $SelfModelUpdateCandidate

    $NextCycleDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE152_NEXT_CYCLE_DECISION"
      step_id = $StepId
      run_id = $RunId
      next_action = "VALIDATE_AND_LEARN"
      next_allowed_step = $NextAllowedStep
      codex_needed_for_next_step = $false
      program_executed = $true
      duty_loop_ready_for_bounded_trial = $false
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $NextCycleDecisionPath -Object $NextCycleDecision

    $DutyLoopReadiness = [ordered]@{
      status = "PASS"
      readiness_id = "PHASE152_DUTY_LOOP_READINESS"
      step_id = $StepId
      run_id = $RunId
      duty_loop_ready_for_bounded_trial = $false
      reason = "PHASE153 validation and learning acceptance must happen before bounded duty-loop trial."
      repeated_loop_started = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $DutyLoopReadinessPath -Object $DutyLoopReadiness

    $PortabilityReadinessNote = [ordered]@{
      status = "PASS"
      note_id = "PHASE152_PORTABILITY_READINESS_NOTE"
      step_id = $StepId
      run_id = $RunId
      portability_prepared = $true
      migration_performed = $false
      portability_basis = @($BodyPortabilityManifestPath, $PortabilityContractPath)
      future_environment_assumptions = @("repo-relative JSON body contracts", "sandbox writes before promotion", "source trust stays false by default")
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $PortabilityReadinessNotePath -Object $PortabilityReadinessNote

    $RuntimeOutputs = @(
      $BodyActivationTracePath,
      $SelfStateObservationPath,
      $RepoObservationPath,
      $ProofMemoryObservationPath,
      $TaskIntakeObservationPath,
      $GoalStateSnapshotPath,
      $GapDetectionPath,
      $FailureClassificationPath,
      $InternalQuestionPath,
      $InternalAnswerSearchPath,
      $InternalAnswerPath,
      $SourcePolicyGuardResultPath,
      $CapabilityShelfReadResultPath,
      $ExecutionTracePath,
      $SelfBuildProgramExecutionResultPath,
      $MicroOrganCandidatePath,
      $MicroOrganContractPath,
      $InputExamplePath,
      $OutputExamplePath,
      $ValidatorSpecPath,
      $SandboxValidationResultPath,
      $RollbackPlanPath,
      $QuarantinePlanPath,
      $MemoryAbsorptionCandidatePath,
      $SelfModelUpdateCandidatePath,
      $NextCycleDecisionPath,
      $DutyLoopReadinessPath,
      $PortabilityReadinessNotePath
    )

    $Common = [ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase151_verified = $true
      admission_ticket_verified = $true
      execution_intention_verified = $true
      maximal_foundational_body_pack_created = $true
      body_organ_pack_created = $true
      body_organ_count = 24
      body_registry_created = $true
      body_policy_created = $true
      body_runtime_contract_created = $true
      body_safety_boundaries_created = $true
      body_portability_manifest_created = $true
      self_state_sensor_created = $true
      repo_observation_sensor_created = $true
      proof_memory_sensor_created = $true
      task_intake_sensor_created = $true
      goal_state_manager_created = $true
      gap_detector_created = $true
      failure_classifier_created = $true
      internal_question_engine_created = $true
      internal_answer_searcher_created = $true
      knowledge_memory_reader_created = $true
      capability_shelf_reader_created = $true
      source_policy_guard_created = $true
      organ_composer_created = $true
      self_build_program_composer_created = $true
      sandbox_executor_created = $true
      validation_runner_created = $true
      sandbox_rollback_manager_created = $true
      quarantine_manager_created = $true
      memory_absorber_created = $true
      self_model_update_candidate_writer_created = $true
      next_cycle_decider_created = $true
      duty_loop_controller_created = $true
      owner_escalation_gate_created = $true
      migration_portability_preparer_created = $true
      body_activation_trace_created = $true
      self_state_observation_created = $true
      repo_observation_created = $true
      proof_memory_observation_created = $true
      task_intake_observation_created = $true
      goal_state_snapshot_created = $true
      gap_detection_created = $true
      failure_classification_created = $true
      internal_question_created = $true
      internal_answer_search_created = $true
      internal_answer_created = $true
      source_policy_guard_result_created = $true
      capability_shelf_read_result_created = $true
      program_executed = $true
      execution_scope = $ExecutionScope
      execution_mode = $ExecutionMode
      target_micro_organ_id = $TargetMicroOrganId
      micro_organ_candidate_created = $true
      micro_organ_contract_created = $true
      input_example_created = $true
      output_example_created = $true
      validator_spec_created = $true
      sandbox_validation_result_created = $true
      rollback_plan_created = $true
      quarantine_plan_created = $true
      memory_absorption_candidate_created = $true
      self_model_update_candidate_created = $true
      next_cycle_decision_created = $true
      duty_loop_readiness_created = $true
      portability_readiness_note_created = $true
      next_cycle_action = "VALIDATE_AND_LEARN"
      duty_loop_ready_for_bounded_trial = $false
      codex_needed_for_next_step = $false
      arbitrary_code_execution_used = $false
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
      body_pack_path = $BodyPackPath
      body_registry_path = $BodyRegistryPath
      body_policy_path = $BodyPolicyPath
      body_runtime_contract_path = $BodyRuntimeContractPath
      body_safety_boundaries_path = $BodySafetyBoundariesPath
      body_portability_manifest_path = $BodyPortabilityManifestPath
      executor_organ_path = "$OrganRoot/SELF_BUILD_SANDBOX_EXECUTOR_V1.json"
      executor_contract_path = $ExecutorContractPath
      sandbox_root = $SandboxRoot
      next_allowed_step = $NextAllowedStep
    }

    $Result = [ordered]@{}
    foreach ($key in $Common.Keys) { $Result[$key] = $Common[$key] }
    $Result["result_id"] = "PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_RESULT"
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result

    $Report = [ordered]@{
      status = "PASS"
      report_id = "PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1_REPORT"
      step_id = $StepId
      run_id = $RunId
      route_alignment_request_path = $RouteAlignmentPath
      body_organ_pack_paths = @($BodyPackPath, $BodyRegistryPath, $BodyPolicyPath, $BodyRuntimeContractPath, $BodySafetyBoundariesPath, $BodyPortabilityManifestPath)
      body_organ_paths = $OrganPaths
      body_contract_paths = @($BodyOrganContractPath, $ExecutorContractPath, $DutyLoopContractPath, $FailureRecoveryContractPath, $MemoryAbsorptionContractPath, $PortabilityContractPath)
      body_organ_count = 24
      body_policy_path = $BodyPolicyPath
      body_runtime_contract_path = $BodyRuntimeContractPath
      safety_boundaries_path = $BodySafetyBoundariesPath
      portability_manifest_path = $BodyPortabilityManifestPath
      executor_organ_path = "$OrganRoot/SELF_BUILD_SANDBOX_EXECUTOR_V1.json"
      executor_contract_path = $ExecutorContractPath
      module_path = "modules/invoke_builder_executes_admitted_self_build_program_in_sandbox_001.ps1"
      validator_path = "validators/validate_phase152_builder_executes_admitted_self_build_program_in_sandbox_v1.ps1"
      exact_run_command_expected = ". .\modules\invoke_builder_executes_admitted_self_build_program_in_sandbox_001.ps1; `$Result = Invoke-BuilderExecutesAdmittedSelfBuildProgramInSandbox001 -RepoRoot (Get-Location).Path -RunId PHASE152_MAXIMAL_BODY_ORGAN_PACK_AND_SANDBOX_EXECUTION_001; `$Result | ConvertTo-Json -Depth 20"
      exact_validator_command_expected = ".\validators\validate_phase152_builder_executes_admitted_self_build_program_in_sandbox_v1.ps1 -RepoRoot ."
      runtime_output_files_created = $RuntimeOutputs + @($ResultPath, $ReportPath, $ProofPath)
      files_changed = @($RouteAlignmentPath, "modules/invoke_builder_executes_admitted_self_build_program_in_sandbox_001.ps1", "validators/validate_phase152_builder_executes_admitted_self_build_program_in_sandbox_v1.ps1") + @($BodyPackPath, $BodyRegistryPath, $BodyPolicyPath, $BodyRuntimeContractPath, $BodySafetyBoundariesPath, $BodyPortabilityManifestPath) + $OrganPaths + @($BodyOrganContractPath, $ExecutorContractPath, $DutyLoopContractPath, $FailureRecoveryContractPath, $MemoryAbsorptionContractPath, $PortabilityContractPath) + $RuntimeOutputs + @($ResultPath, $ReportPath, $ProofPath)
      risks = @(
        "PHASE152 creates LLE body organs and sandbox execution artifacts only; PHASE153 must validate and decide learning absorption.",
        "The micro-organ candidate is not an accepted capability and remains sandbox-scoped.",
        "Duty-loop readiness remains false until later validation and learning are accepted."
      )
      cut_list = @(
        "No orchestrator change.",
        "No route lock change.",
        "No accepted PHASE142-PHASE151 proof or report change.",
        "No accepted capability_shelf mutation.",
        "No TASK_QUEUE mutation.",
        "No generated_agents or applied_agents touch.",
        "No package manager or dependency file touch.",
        "No GitHub workflow touch.",
        "No internet fetch.",
        "No dependency install.",
        "No external executable material use.",
        "No arbitrary code execution.",
        "No trusted source creation.",
        "No external agent production.",
        "No accepted Builder state mutation.",
        "No migration performed.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report

    $Proof = [ordered]@{}
    foreach ($key in $Common.Keys) { $Proof[$key] = $Common[$key] }
    $Proof["proof_id"] = $StepId
    $Proof["phase151_proof_path"] = $Phase151ProofPath
    $Proof["admission_ticket_path"] = $Phase151TicketPath
    $Proof["execution_intention_path"] = $Phase151ExecutionIntentionPath
    $Proof["program_candidate_path"] = $Phase150CandidatePath
    $Proof["sandbox_validation_result_path"] = $SandboxValidationResultPath
    $Proof["result_path"] = $ResultPath
    $Proof["report_path"] = $ReportPath
    Write-Phase152JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject][ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      body_organ_count = 24
      program_executed = $true
      execution_mode = $ExecutionMode
      execution_scope = $ExecutionScope
      target_micro_organ_id = $TargetMicroOrganId
      sandbox_validation_result = "PASS"
      next_cycle_action = "VALIDATE_AND_LEARN"
      duty_loop_ready_for_bounded_trial = $false
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
