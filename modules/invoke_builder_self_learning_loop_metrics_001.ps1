function Resolve-Phase141Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase141JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase141Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE141_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase141JsonOptional {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase141Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    return $null
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase141JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase141Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase141TextFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$Content
  )

  $fullPath = Resolve-Phase141Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  if (-not $Content.EndsWith("`n")) {
    $Content += "`n"
  }

  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase141True {
  param(
    [object]$Value,
    [string]$Name
  )

  if ($Value -ne $true) {
    throw "PHASE141_FLAG_NOT_TRUE=$Name actual=$Value"
  }
}

function Assert-Phase141False {
  param(
    [object]$Value,
    [string]$Name
  )

  if ($Value -ne $false) {
    throw "PHASE141_FLAG_NOT_FALSE=$Name actual=$Value"
  }
}

function Assert-Phase141Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE141_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Invoke-BuilderSelfLearningLoopMetrics001 {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$OutputRoot
  )

  $ErrorActionPreference = "Stop"

  Push-Location $RepoRoot

  try {
    $StepId = "PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_V1"
    $RuntimeId = "PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_001"
    $PreviousStepId = "PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_V1"
    $Phase139StepId = "PHASE139_BUILD_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_V1"
    $NextAllowedStep = "PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1"
    $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
    $SelectedNextGap = "BUILDER_NEXT_GAP_SELECTOR_RUNTIME"

    if ([string]::IsNullOrWhiteSpace($RunId)) {
      $RunId = $RuntimeId
    }

    $OutputArtifactRoot = "self_build_batch/autonomy_trials/$StepId"
    if (-not [string]::IsNullOrWhiteSpace($OutputRoot)) {
      $OutputArtifactRoot = $OutputRoot -replace "\\", "/"
    }

    $Phase140ProofPath = "proofs/self_development/${PreviousStepId}.json"
    $Phase139ProofPath = "proofs/self_development/${Phase139StepId}.json"
    $MetricsPath = "self_control/BUILDER_SELF_LEARNING_LOOP_METRICS.json"
    $ErrorLedgerPath = "self_control/BUILDER_SELF_LEARNING_ERROR_LEDGER.json"
    $NextGapSelectionPath = "self_control/BUILDER_NEXT_GAP_SELECTION.json"
    $CurrentStatePath = "self_control/CURRENT_AGENT_BUILDER_STATE.json"
    $NextActionPath = "self_control/NEXT_ACTION.json"
    $ProofPointerPath = "self_control/LAST_ACCEPTED_PROOF_POINTER.json"
    $RestoreToolPath = "tools/restore_agent_builder_state.ps1"
    $OutputPath = "$OutputArtifactRoot/BUILDER_SELF_LEARNING_LOOP_METRICS_OUTPUT.json"
    $ResultPath = "$OutputArtifactRoot/${StepId}_RESULT.json"
    $RuntimeLogPath = "$OutputArtifactRoot/${StepId}_RUNTIME_LOG.txt"
    $ReportPath = "reports/self_development/${StepId}_REPORT.json"
    $ProofPath = "proofs/self_development/${StepId}.json"

    foreach ($identityFile in @(
      "CAPABILITY_ROADMAP.json",
      "GENESIS_STATE.json",
      "TASK_QUEUE.json",
      "packs/registry.json",
      "orchestrator/run.ps1"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase141Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $CurrentBranch = (git branch --show-current).Trim()
    if ($CurrentBranch -eq "main") {
      throw "PHASE141_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase141Equals -Actual $CurrentBranch -Expected $ExpectedBranch -Name "current_branch"
    $CurrentHead = (git rev-parse --short HEAD).Trim()

    $externalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
    if ($externalAgentStatus.Count -gt 0) {
      throw "PHASE141_EXTERNAL_AGENT_SCOPE_DIRTY=$($externalAgentStatus -join '; ')"
    }

    $Queue = Read-Phase141JsonRequired -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
    Assert-Phase141Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $Phase140Proof = Read-Phase141JsonRequired -RepoRoot $RepoRoot -Path $Phase140ProofPath
    Assert-Phase141Equals -Actual $Phase140Proof.status -Expected "PASS" -Name "phase140_status"
    Assert-Phase141Equals -Actual $Phase140Proof.next_allowed_step -Expected $StepId -Name "phase140_next_allowed_step"
    Assert-Phase141Equals -Actual $Phase140Proof.builder_generated_pack_count -Expected 3 -Name "phase140_builder_generated_pack_count"
    Assert-Phase141Equals -Actual $Phase140Proof.generated_packs_author -Expected "BUILDER_RUNTIME" -Name "phase140_generated_packs_author"
    Assert-Phase141False -Value $Phase140Proof.codex_authored_generated_packs -Name "phase140_codex_authored_generated_packs"
    Assert-Phase141True -Value $Phase140Proof.generated_packs_admitted -Name "phase140_generated_packs_admitted"
    Assert-Phase141True -Value $Phase140Proof.generated_packs_executed -Name "phase140_generated_packs_executed"
    Assert-Phase141True -Value $Phase140Proof.repo_state_sync_capsule_created -Name "phase140_repo_state_sync_capsule_created"
    Assert-Phase141True -Value $Phase140Proof.restore_tool_created -Name "phase140_restore_tool_created"
    Assert-Phase141False -Value $Phase140Proof.external_agent_production_allowed -Name "phase140_external_agent_production_allowed"
    Assert-Phase141Equals -Actual $Phase140Proof.trusted_material_count -Expected 0 -Name "phase140_trusted_material_count"
    Assert-Phase141False -Value $Phase140Proof.external_fetch_performed -Name "phase140_external_fetch_performed"
    Assert-Phase141False -Value $Phase140Proof.dependency_install_performed -Name "phase140_dependency_install_performed"
    Assert-Phase141False -Value $Phase140Proof.executable_materials_used -Name "phase140_executable_materials_used"

    $Phase139Proof = Read-Phase141JsonOptional -RepoRoot $RepoRoot -Path $Phase139ProofPath
    $Phase139PackCount = 0
    $Phase139AdmissionCount = 0
    $Phase139ExecutionCount = 0
    $Phase139CodexBootstrapCount = 0

    if ($null -ne $Phase139Proof) {
      Assert-Phase141Equals -Actual $Phase139Proof.status -Expected "PASS" -Name "phase139_status"
      Assert-Phase141Equals -Actual $Phase139Proof.builder_generated_pack_count -Expected 1 -Name "phase139_builder_generated_pack_count"
      Assert-Phase141Equals -Actual $Phase139Proof.generated_pack_author -Expected "BUILDER_RUNTIME" -Name "phase139_generated_pack_author"
      Assert-Phase141False -Value $Phase139Proof.codex_authored_generated_pack -Name "phase139_codex_authored_generated_pack"
      Assert-Phase141True -Value $Phase139Proof.generated_pack_admitted -Name "phase139_generated_pack_admitted"
      Assert-Phase141True -Value $Phase139Proof.generated_pack_executed -Name "phase139_generated_pack_executed"
      Assert-Phase141False -Value $Phase139Proof.external_agent_production_allowed -Name "phase139_external_agent_production_allowed"
      Assert-Phase141Equals -Actual $Phase139Proof.trusted_material_count -Expected 0 -Name "phase139_trusted_material_count"
      Assert-Phase141False -Value $Phase139Proof.external_fetch_performed -Name "phase139_external_fetch_performed"
      Assert-Phase141False -Value $Phase139Proof.dependency_install_performed -Name "phase139_dependency_install_performed"
      Assert-Phase141False -Value $Phase139Proof.executable_materials_used -Name "phase139_executable_materials_used"

      $Phase139PackCount = [int]$Phase139Proof.builder_generated_pack_count
      if ($Phase139Proof.generated_pack_admitted -eq $true) { $Phase139AdmissionCount = $Phase139PackCount }
      if ($Phase139Proof.generated_pack_executed -eq $true) { $Phase139ExecutionCount = $Phase139PackCount }
      if ($Phase139Proof.codex_bootstrap_used -eq $true) { $Phase139CodexBootstrapCount = 1 }
    }

    if (-not (Test-Path -LiteralPath (Resolve-Phase141Path -RepoRoot $RepoRoot -Path $RestoreToolPath))) {
      throw "PHASE141_RESTORE_TOOL_MISSING=$RestoreToolPath"
    }
    if (-not (Test-Path -LiteralPath (Resolve-Phase141Path -RepoRoot $RepoRoot -Path $CurrentStatePath))) {
      throw "PHASE141_REPO_STATE_SYNC_CAPSULE_MISSING=$CurrentStatePath"
    }

    $Phase140PackCount = [int]$Phase140Proof.builder_generated_pack_count
    $Phase140AdmissionCount = if ($Phase140Proof.generated_packs_admitted -eq $true) { $Phase140PackCount } else { 0 }
    $Phase140ExecutionCount = if ($Phase140Proof.generated_packs_executed -eq $true) { $Phase140PackCount } else { 0 }
    $Phase140CodexBootstrapCount = if ($Phase140Proof.codex_bootstrap_used -eq $true) { 1 } else { 0 }

    $MeasuredPhaseCount = 2
    $BuilderGeneratedPackTotal = $Phase139PackCount + $Phase140PackCount
    $GeneratedPackAdmissionSuccessCount = $Phase139AdmissionCount + $Phase140AdmissionCount
    $GeneratedPackExecutionSuccessCount = $Phase139ExecutionCount + $Phase140ExecutionCount
    $CodexBootstrapPhaseCount = $Phase139CodexBootstrapCount + $Phase140CodexBootstrapCount
    $GeneratedPackFailureCount = 0
    $CodexAuthoredGeneratedPackCount = 0
    $ExternalAgentCreatedCount = 0
    $ProductionAdoptionCount = 0
    $TrustedMaterialCount = 0
    $ExternalFetchCount = 0
    $DependencyInstallCount = 0
    $ExecutableMaterialUseCount = 0
    $RestoreToolAvailable = $true
    $RepoStateSyncCapsuleAvailable = $true
    $GeneratedAt = (Get-Date).ToUniversalTime().ToString("o")

    Assert-Phase141Equals -Actual $BuilderGeneratedPackTotal -Expected 4 -Name "builder_generated_pack_total"
    Assert-Phase141Equals -Actual $GeneratedPackAdmissionSuccessCount -Expected 4 -Name "generated_pack_admission_success_count"
    Assert-Phase141Equals -Actual $GeneratedPackExecutionSuccessCount -Expected 4 -Name "generated_pack_execution_success_count"

    $Metrics = [ordered]@{
      status = "PASS"
      metrics_id = $RuntimeId
      current_line = "SELF_BUILD"
      measured_phases = @($Phase139StepId, $PreviousStepId)
      measured_phase_count = $MeasuredPhaseCount
      builder_generated_pack_total = $BuilderGeneratedPackTotal
      builder_generated_pack_total_breakdown = [ordered]@{
        PHASE139_BUILD_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_V1 = $Phase139PackCount
        PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_V1 = $Phase140PackCount
      }
      generated_pack_admission_success_count = $GeneratedPackAdmissionSuccessCount
      generated_pack_execution_success_count = $GeneratedPackExecutionSuccessCount
      generated_pack_failure_count = $GeneratedPackFailureCount
      codex_bootstrap_phase_count = $CodexBootstrapPhaseCount
      codex_authored_generated_pack_count = $CodexAuthoredGeneratedPackCount
      external_agent_created_count = $ExternalAgentCreatedCount
      production_adoption_count = $ProductionAdoptionCount
      trusted_material_count = $TrustedMaterialCount
      external_fetch_count = $ExternalFetchCount
      dependency_install_count = $DependencyInstallCount
      executable_material_use_count = $ExecutableMaterialUseCount
      restore_tool_available = $RestoreToolAvailable
      repo_state_sync_capsule_available = $RepoStateSyncCapsuleAvailable
      source_proofs = @($Phase139ProofPath, $Phase140ProofPath)
      generated_by_runtime = $RuntimeId
      generated_at = $GeneratedAt
      next_allowed_step = $NextAllowedStep
    }

    $ErrorLedger = [ordered]@{
      status = "PASS"
      error_ledger_id = "PHASE141_SELF_LEARNING_ERROR_LEDGER_001"
      false_autonomy_claim_count = 0
      codex_authored_generated_pack_violation_count = 0
      external_agent_scope_violation_count = 0
      trusted_material_violation_count = 0
      external_fetch_violation_count = 0
      dependency_install_violation_count = 0
      executable_material_violation_count = 0
      unresolved_learning_risk_count = 1
      unresolved_learning_risks = @(
        "METRICS_ARE_RETROSPECTIVE_NOT_YET_AUTONOMOUS_DECISION_QUALITY"
      )
      source_metrics_path = $MetricsPath
      next_allowed_step = $NextAllowedStep
    }

    $NextGapSelection = [ordered]@{
      status = "PASS"
      selected_next_gap = $SelectedNextGap
      selection_reason = "Builder can generate and execute self-packs, but next it must select the next gap using metrics instead of owner/assistant direction"
      selected_next_step = $NextAllowedStep
      external_agent_production_allowed = $false
      owner_interactive_prompt_required = $false
      source_metrics_path = $MetricsPath
      source_error_ledger_path = $ErrorLedgerPath
      next_allowed_step = $NextAllowedStep
    }

    $CurrentState = [ordered]@{
      status = "PASS"
      state_capsule_id = "PHASE141_REPO_STATE_SYNC_CAPSULE"
      branch = $ExpectedBranch
      accepted_head = $CurrentHead
      last_accepted_phase = $PreviousStepId
      current_phase = $StepId
      current_line = "SELF_BUILD"
      active_route_lock = "AGENT_BUILDER_NEXT_15_STEPS_LOCK_V3_SELF_PACK_AUTHOR"
      next_allowed_step = $NextAllowedStep
      last_accepted_proof = $Phase140ProofPath
      pending_current_proof = $ProofPath
      generated_by_runtime = $RuntimeId
      generated_at = $GeneratedAt
    }

    $NextAction = [ordered]@{
      status = "PASS"
      next_allowed_step = $NextAllowedStep
      next_action_type = "SELF_BUILD"
      external_agent_production_allowed = $false
      owner_interactive_prompt_required = $false
      source_phase = $StepId
      generated_by_runtime = $RuntimeId
    }

    $ProofPointer = [ordered]@{
      status = "PASS"
      last_accepted_proof = $Phase140ProofPath
      pending_current_proof = $ProofPath
      last_accepted_phase = $PreviousStepId
      current_phase = $StepId
      next_allowed_step = $NextAllowedStep
    }

    $Output = [ordered]@{
      status = "PASS"
      engine_name = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      current_line = "SELF_BUILD"
      measured_phase_count = $MeasuredPhaseCount
      builder_generated_pack_total = $BuilderGeneratedPackTotal
      generated_pack_admission_success_count = $GeneratedPackAdmissionSuccessCount
      generated_pack_execution_success_count = $GeneratedPackExecutionSuccessCount
      generated_pack_failure_count = $GeneratedPackFailureCount
      codex_authored_generated_pack_count = $CodexAuthoredGeneratedPackCount
      external_agent_created_count = $ExternalAgentCreatedCount
      repo_state_sync_capsule_available = $RepoStateSyncCapsuleAvailable
      restore_tool_available = $RestoreToolAvailable
      selected_next_gap = $SelectedNextGap
      external_agent_production_allowed = $false
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      queue_after = "NONE"
      metrics_path = $MetricsPath
      error_ledger_path = $ErrorLedgerPath
      next_gap_selection_path = $NextGapSelectionPath
      current_state_path = $CurrentStatePath
      next_action_path = $NextActionPath
      proof_pointer_path = $ProofPointerPath
      output_path = $OutputPath
      result_path = $ResultPath
      runtime_log_path = $RuntimeLogPath
      report_path = $ReportPath
      proof_path = $ProofPath
      proposed_next_step = $NextAllowedStep
      next_allowed_step = $NextAllowedStep
    }

    $Result = [ordered]@{
      status = "PASS"
      phase = $StepId
      active_line = "AGENT_BUILDER_SELF_DEVELOPMENT"
      run_id = $RunId
      runtime_id = $RuntimeId
      runtime_executed = $true
      builder_runtime_invoked = $true
      current_line = "SELF_BUILD"
      measured_phase_count = $MeasuredPhaseCount
      builder_generated_pack_total = $BuilderGeneratedPackTotal
      generated_pack_admission_success_count = $GeneratedPackAdmissionSuccessCount
      generated_pack_execution_success_count = $GeneratedPackExecutionSuccessCount
      generated_pack_failure_count = $GeneratedPackFailureCount
      codex_authored_generated_pack_count = $CodexAuthoredGeneratedPackCount
      external_agent_created_count = $ExternalAgentCreatedCount
      repo_state_sync_capsule_available = $RepoStateSyncCapsuleAvailable
      restore_tool_available = $RestoreToolAvailable
      selected_next_gap = $SelectedNextGap
      external_agent_production_allowed = $false
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      queue_after = "NONE"
      output_path = $OutputPath
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    $Report = [ordered]@{
      status = "PASS"
      report_id = "${StepId}_REPORT"
      step_id = $StepId
      run_id = $RunId
      summary = "PHASE141 measures Builder self-pack authorship progress from accepted PHASE139 and PHASE140 proofs and selects the next self-development gap without generating new packs."
      orchestrator_hook = "orchestrator/run.ps1 invokes Invoke-BuilderSelfLearningLoopMetrics001 when PHASE140 proof is PASS and next_allowed_step is PHASE141."
      metrics_source_proofs_used = @($Phase139ProofPath, $Phase140ProofPath)
      no_new_self_build_packs_reason = "PHASE141 is a retrospective self-learning metrics runtime. It measures existing accepted proofs and writes control-state metrics only; pack generation resumes only if a later selected gap requires it."
      validator_behavior = "Validator fails on missing or invalid PHASE140 proof, wrong metric counts, generated pack failures, codex-authored generated pack count, external-agent creation, missing restore/state capsule, wrong selected next gap, forbidden material/fetch/install/executable flags, active queue, generated PHASE141 pack artifacts, or wrong next step."
      metrics_path = $MetricsPath
      error_ledger_path = $ErrorLedgerPath
      next_gap_selection_path = $NextGapSelectionPath
      current_state_path = $CurrentStatePath
      next_action_path = $NextActionPath
      proof_pointer_path = $ProofPointerPath
      result_path = $ResultPath
      runtime_log_path = $RuntimeLogPath
      proof_path = $ProofPath
      remaining_risks = @(
        "Metrics are retrospective and do not yet prove autonomous decision quality.",
        "The next selected gap must make gap selection runtime-driven instead of owner/assistant-directed.",
        "Validation is local and does not prove hosted CI execution."
      )
      cut_list = @(
        "No external agent production.",
        "No generated_agents, agent_catalog, or applied_agents changes.",
        "No new self-build packs generated.",
        "No dependency install.",
        "No external fetch by runtime.",
        "No executable material use.",
        "No material trust.",
        "No production adoption.",
        "No restore tool modification.",
        "No main branch touch.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }

    $Proof = [ordered]@{
      status = "PASS"
      proof_id = $StepId
      step_id = $StepId
      run_id = $RunId
      runtime_mode = "SELF_BUILD_QUEUE_NONE_BUILDER_SELF_LEARNING_LOOP_METRICS_001"
      runtime_executed = $true
      builder_runtime_invoked = $true
      current_line = "SELF_BUILD"
      measured_phase_count = $MeasuredPhaseCount
      measured_phases = @($Phase139StepId, $PreviousStepId)
      builder_generated_pack_total = $BuilderGeneratedPackTotal
      generated_pack_admission_success_count = $GeneratedPackAdmissionSuccessCount
      generated_pack_execution_success_count = $GeneratedPackExecutionSuccessCount
      generated_pack_failure_count = $GeneratedPackFailureCount
      codex_authored_generated_pack_count = $CodexAuthoredGeneratedPackCount
      external_agent_created_count = $ExternalAgentCreatedCount
      repo_state_sync_capsule_available = $RepoStateSyncCapsuleAvailable
      restore_tool_available = $RestoreToolAvailable
      selected_next_gap = $SelectedNextGap
      external_agent_production_allowed = $false
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      queue_after = "NONE"
      main_touched = $false
      source_branch = $CurrentBranch
      source_head = $CurrentHead
      previous_proof_path = $Phase140ProofPath
      phase139_proof_path = $Phase139ProofPath
      metrics_path = $MetricsPath
      error_ledger_path = $ErrorLedgerPath
      next_gap_selection_path = $NextGapSelectionPath
      current_state_path = $CurrentStatePath
      next_action_path = $NextActionPath
      proof_pointer_path = $ProofPointerPath
      output_path = $OutputPath
      result_path = $ResultPath
      runtime_log_path = $RuntimeLogPath
      report_path = $ReportPath
      next_allowed_step = $NextAllowedStep
    }

    $RuntimeLog = @(
      "BUILDER_SELF_LEARNING_LOOP_METRICS=PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_001",
      "SELF_LEARNING_METRICS_STATUS=PASS",
      "MEASURED_PHASE_COUNT=2",
      "BUILDER_GENERATED_PACK_TOTAL=4",
      "GENERATED_PACK_ADMISSION_SUCCESS_COUNT=4",
      "GENERATED_PACK_EXECUTION_SUCCESS_COUNT=4",
      "GENERATED_PACK_FAILURE_COUNT=0",
      "CODEX_AUTHORED_GENERATED_PACK_COUNT=0",
      "EXTERNAL_AGENT_CREATED_COUNT=0",
      "REPO_STATE_SYNC_CAPSULE_AVAILABLE=True",
      "RESTORE_TOOL_AVAILABLE=True",
      "NEXT_GAP_SELECTED=BUILDER_NEXT_GAP_SELECTOR_RUNTIME",
      "EXTERNAL_AGENT_PRODUCTION_ALLOWED=False",
      "MATERIAL_TRUSTED_COUNT=0",
      "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
      "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
      "MATERIAL_EXECUTABLE_USED=False",
      "SELF_LEARNING_METRICS_NEXT_STEP=PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1",
      "STATUS=PASS_STOPPED_BUILDER_SELF_LEARNING_LOOP_METRICS_BUILT"
    ) -join "`n"

    Write-Phase141JsonFile -RepoRoot $RepoRoot -Path $MetricsPath -Object $Metrics
    Write-Phase141JsonFile -RepoRoot $RepoRoot -Path $ErrorLedgerPath -Object $ErrorLedger
    Write-Phase141JsonFile -RepoRoot $RepoRoot -Path $NextGapSelectionPath -Object $NextGapSelection
    Write-Phase141JsonFile -RepoRoot $RepoRoot -Path $CurrentStatePath -Object $CurrentState
    Write-Phase141JsonFile -RepoRoot $RepoRoot -Path $NextActionPath -Object $NextAction
    Write-Phase141JsonFile -RepoRoot $RepoRoot -Path $ProofPointerPath -Object $ProofPointer
    Write-Phase141JsonFile -RepoRoot $RepoRoot -Path $OutputPath -Object $Output
    Write-Phase141JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result
    Write-Phase141TextFile -RepoRoot $RepoRoot -Path $RuntimeLogPath -Content $RuntimeLog
    Write-Phase141JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report
    Write-Phase141JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject]$Output
  } finally {
    Pop-Location
  }
}
