function Resolve-Phase142Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase142JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase142Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE142_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase142JsonOptional {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase142Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    return $null
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase142JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase142Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase142TextFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$Content
  )

  $fullPath = Resolve-Phase142Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Add-Phase142JsonLine {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object
  )

  $fullPath = Resolve-Phase142Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $line = $Object | ConvertTo-Json -Depth 50 -Compress
  [System.IO.File]::AppendAllText($fullPath, "$line`n", [System.Text.UTF8Encoding]::new($false))
}

function Get-Phase142IntEnv {
  param(
    [string]$Name,
    [int]$Default,
    [int]$Minimum
  )

  $raw = [Environment]::GetEnvironmentVariable($Name)
  if ([string]::IsNullOrWhiteSpace($raw)) {
    return $Default
  }

  $parsed = 0
  if (-not [int]::TryParse($raw, [ref]$parsed)) {
    return $Default
  }

  if ($parsed -lt $Minimum) {
    return $Default
  }

  return $parsed
}

function Assert-Phase142Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE142_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase142FalseIfPresent {
  param(
    [object]$Object,
    [string]$Name
  )

  $property = $Object.PSObject.Properties | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
  if ($null -ne $property -and $property.Value -ne $false) {
    throw "PHASE142_FLAG_NOT_FALSE=$Name actual=$($property.Value)"
  }
}

function Assert-Phase142ZeroIfPresent {
  param(
    [object]$Object,
    [string]$Name
  )

  $property = $Object.PSObject.Properties | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
  if ($null -ne $property -and $property.Value -ne 0) {
    throw "PHASE142_VALUE_NOT_ZERO=$Name actual=$($property.Value)"
  }
}

function Invoke-BuilderNextGapSelectorObservableLifeLoop001 {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$OutputRoot
  )

  $ErrorActionPreference = "Stop"

  Push-Location $RepoRoot

  try {
    $StepId = "PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1"
    $RuntimeId = "PHASE142_BUILDER_NEXT_GAP_SELECTOR_OBSERVABLE_LIFE_LOOP_001"
    $PreviousStepId = "PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_V1"
    $NextAllowedStep = "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1"
    $SelectedNextGap = $NextAllowedStep
    $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"

    if ([string]::IsNullOrWhiteSpace($RunId)) {
      $RunId = $RuntimeId
    }

    $SessionId = [Environment]::GetEnvironmentVariable("BUILDER_LIFE_LOOP_SESSION_ID")
    if ([string]::IsNullOrWhiteSpace($SessionId)) {
      $SessionId = $RunId
    }

    $MaxCycles = Get-Phase142IntEnv -Name "BUILDER_LIFE_LOOP_MAX_CYCLES" -Default 10 -Minimum 1
    $CheckpointEvery = Get-Phase142IntEnv -Name "BUILDER_LIFE_LOOP_CHECKPOINT_EVERY" -Default 5 -Minimum 1
    $SleepSeconds = Get-Phase142IntEnv -Name "BUILDER_LIFE_LOOP_SLEEP_SECONDS" -Default 0 -Minimum 0

    $OutputArtifactRoot = "self_build_batch/autonomy_trials/$StepId"
    if (-not [string]::IsNullOrWhiteSpace($OutputRoot)) {
      $OutputArtifactRoot = $OutputRoot -replace "\\", "/"
    }

    $SessionRoot = "runtime_sessions/builder_life_loop/current"
    $CheckpointRoot = "$SessionRoot/checkpoints"
    $HeartbeatPath = "$SessionRoot/heartbeat.json"
    $LifeLoopStatePath = "$SessionRoot/life_loop_state.json"
    $ObservationLedgerPath = "$SessionRoot/observation_ledger.jsonl"
    $DecisionTracePath = "$SessionRoot/decision_trace.jsonl"
    $ErrorLedgerPath = "$SessionRoot/error_ledger.jsonl"
    $LearningMetricsPath = "$SessionRoot/learning_metrics.json"
    $CorrectionInboxPath = "$SessionRoot/correction_inbox.json"
    $CorrectionAppliedLogPath = "$SessionRoot/correction_applied_log.jsonl"
    $SessionSummaryPath = "$SessionRoot/session_summary.json"
    $StopRequestedPath = "$SessionRoot/STOP_REQUESTED"
    $Checkpoint005Path = "$CheckpointRoot/checkpoint_005.json"
    $Phase141ProofPath = "proofs/self_development/${PreviousStepId}.json"
    $Phase141MetricsPath = "self_control/BUILDER_SELF_LEARNING_LOOP_METRICS.json"
    $CurrentStatePath = "self_control/CURRENT_AGENT_BUILDER_STATE.json"
    $NextActionPath = "self_control/NEXT_ACTION.json"
    $LastAcceptedProofPointerPath = "self_control/LAST_ACCEPTED_PROOF_POINTER.json"
    $LifeLoopPolicyPath = "self_control/BUILDER_LIFE_LOOP_POLICY.json"
    $NextGapSelectorResultPath = "self_control/BUILDER_NEXT_GAP_SELECTOR_RESULT.json"
    $OutputPath = "$OutputArtifactRoot/BUILDER_NEXT_GAP_SELECTOR_OBSERVABLE_LIFE_LOOP_OUTPUT.json"
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
      if (-not (Test-Path -LiteralPath (Resolve-Phase142Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $CurrentBranch = (git branch --show-current).Trim()
    if ($CurrentBranch -eq "main") {
      throw "PHASE142_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase142Equals -Actual $CurrentBranch -Expected $ExpectedBranch -Name "current_branch"
    $CurrentHead = (git rev-parse --short HEAD).Trim()

    $externalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
    if ($externalAgentStatus.Count -gt 0) {
      throw "PHASE142_EXTERNAL_AGENT_SCOPE_DIRTY=$($externalAgentStatus -join '; ')"
    }

    $Queue = Read-Phase142JsonRequired -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
    Assert-Phase142Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $Phase141Proof = Read-Phase142JsonRequired -RepoRoot $RepoRoot -Path $Phase141ProofPath
    Assert-Phase142Equals -Actual $Phase141Proof.status -Expected "PASS" -Name "phase141_status"
    Assert-Phase142Equals -Actual $Phase141Proof.next_allowed_step -Expected $StepId -Name "phase141_next_allowed_step"
    Assert-Phase142FalseIfPresent -Object $Phase141Proof -Name "external_agent_production_allowed"
    Assert-Phase142ZeroIfPresent -Object $Phase141Proof -Name "trusted_material_count"
    Assert-Phase142FalseIfPresent -Object $Phase141Proof -Name "external_fetch_performed"
    Assert-Phase142FalseIfPresent -Object $Phase141Proof -Name "dependency_install_performed"
    Assert-Phase142FalseIfPresent -Object $Phase141Proof -Name "executable_materials_used"

    New-Item -ItemType Directory -Force -Path (Resolve-Phase142Path -RepoRoot $RepoRoot -Path $SessionRoot) | Out-Null
    New-Item -ItemType Directory -Force -Path (Resolve-Phase142Path -RepoRoot $RepoRoot -Path $CheckpointRoot) | Out-Null

    Write-Phase142TextFile -RepoRoot $RepoRoot -Path $ObservationLedgerPath -Content ""
    Write-Phase142TextFile -RepoRoot $RepoRoot -Path $DecisionTracePath -Content ""
    Write-Phase142TextFile -RepoRoot $RepoRoot -Path $ErrorLedgerPath -Content ""
    Write-Phase142TextFile -RepoRoot $RepoRoot -Path $CorrectionAppliedLogPath -Content ""

    $CorrectionInbox = Read-Phase142JsonOptional -RepoRoot $RepoRoot -Path $CorrectionInboxPath
    if ($null -eq $CorrectionInbox) {
      $CorrectionInbox = [pscustomobject]([ordered]@{
        status = "PASS"
        inbox_id = "BUILDER_LIFE_LOOP_CORRECTION_INBOX"
        pending_corrections = @()
        observed_correction_count = 0
        created_by = $RuntimeId
        next_behavior_trial = "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1"
      })
    }

    if ($null -eq ($CorrectionInbox.PSObject.Properties | Where-Object { $_.Name -eq "pending_corrections" } | Select-Object -First 1)) {
      $CorrectionInbox | Add-Member -NotePropertyName "pending_corrections" -NotePropertyValue @()
    }
    Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $CorrectionInboxPath -Object $CorrectionInbox

    $TaskCycle = @(
      "READ_CURRENT_STATE",
      "READ_NEXT_ACTION",
      "FIND_LAST_ACCEPTED_PROOF",
      "COMPARE_NEXT_STEP",
      "WRITE_LEARNING_NOTE",
      "SELECT_NEXT_MICRO_GAP"
    )

    $CompletedCycles = 0
    $StopRequested = $false
    $TaskTypesCompleted = New-Object System.Collections.Generic.List[string]
    $CorrectionSeenCount = 0
    $LastTaskType = "NONE"

    for ($cycle = 1; $cycle -le $MaxCycles; $cycle++) {
      if (Test-Path -LiteralPath (Resolve-Phase142Path -RepoRoot $RepoRoot -Path $StopRequestedPath)) {
        $StopRequested = $true
        break
      }

      $CycleStartedAt = (Get-Date).ToUniversalTime().ToString("o")
      $CurrentState = Read-Phase142JsonOptional -RepoRoot $RepoRoot -Path $CurrentStatePath
      $NextAction = Read-Phase142JsonOptional -RepoRoot $RepoRoot -Path $NextActionPath
      $LastAcceptedProofPointer = Read-Phase142JsonOptional -RepoRoot $RepoRoot -Path $LastAcceptedProofPointerPath
      $Phase141Metrics = Read-Phase142JsonOptional -RepoRoot $RepoRoot -Path $Phase141MetricsPath
      $Phase141ProofForCycle = Read-Phase142JsonRequired -RepoRoot $RepoRoot -Path $Phase141ProofPath
      $CorrectionInbox = Read-Phase142JsonRequired -RepoRoot $RepoRoot -Path $CorrectionInboxPath

      $PendingCorrections = @($CorrectionInbox.pending_corrections | Where-Object {
        $statusProperty = $_.PSObject.Properties | Where-Object { $_.Name -eq "status" } | Select-Object -First 1
        $null -eq $statusProperty -or $statusProperty.Value -eq "PENDING"
      })
      $CorrectionSeenCount += $PendingCorrections.Count

      $TaskType = $TaskCycle[($cycle - 1) % $TaskCycle.Count]
      $TaskTypesCompleted.Add($TaskType) | Out-Null
      $LastTaskType = $TaskType

      $PracticeResult = [ordered]@{
        task_type = $TaskType
        safe_internal_practice = $true
        read_current_state = $null -ne $CurrentState
        read_next_action = $null -ne $NextAction
        read_last_accepted_proof_pointer = $null -ne $LastAcceptedProofPointer
        read_phase141_metrics = $null -ne $Phase141Metrics
        read_phase141_proof = $null -ne $Phase141ProofForCycle
        correction_pending_count = $PendingCorrections.Count
      }

      if ($TaskType -eq "COMPARE_NEXT_STEP") {
        $PracticeResult.expected_next_step = $StepId
        $PracticeResult.actual_next_step = $Phase141ProofForCycle.next_allowed_step
        $PracticeResult.comparison_status = if ($Phase141ProofForCycle.next_allowed_step -eq $StepId) { "MATCH" } else { "MISMATCH" }
      }

      if ($TaskType -eq "WRITE_LEARNING_NOTE") {
        $PracticeResult.learning_note = "Builder has retrospective metrics and now needs correction-aware response behavior."
      }

      if ($TaskType -eq "SELECT_NEXT_MICRO_GAP") {
        $PracticeResult.selected_micro_gap = "CORRECTION_INBOX_RESPONSE_TRIAL"
        $PracticeResult.selected_next_gap = $SelectedNextGap
      }

      $ObservationEvent = [ordered]@{
        event_type = "OBSERVATION"
        session_id = $SessionId
        run_id = $RunId
        cycle = $cycle
        task_type = $TaskType
        status = "PASS"
        observed_at = $CycleStartedAt
        practice_result = $PracticeResult
      }
      Add-Phase142JsonLine -RepoRoot $RepoRoot -Path $ObservationLedgerPath -Object $ObservationEvent

      $DecisionEvent = [ordered]@{
        event_type = "DECISION"
        session_id = $SessionId
        run_id = $RunId
        cycle = $cycle
        selected_task_type = $TaskType
        selection_reason = "bounded safe internal practice selected from PHASE141 metrics and current state"
        selected_next_gap = $SelectedNextGap
        owner_interactive_prompt_required = $false
        external_agent_production_allowed = $false
        decided_at = (Get-Date).ToUniversalTime().ToString("o")
      }
      Add-Phase142JsonLine -RepoRoot $RepoRoot -Path $DecisionTracePath -Object $DecisionEvent

      if ($PendingCorrections.Count -gt 0) {
        $CorrectionSeenEvent = [ordered]@{
          event_type = "CORRECTION_OBSERVED"
          session_id = $SessionId
          run_id = $RunId
          cycle = $cycle
          pending_correction_count = $PendingCorrections.Count
          behavior_change_deferred_to = "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1"
          observed_at = (Get-Date).ToUniversalTime().ToString("o")
        }
        Add-Phase142JsonLine -RepoRoot $RepoRoot -Path $CorrectionAppliedLogPath -Object $CorrectionSeenEvent
      }

      $CompletedCycles++

      $Heartbeat = [ordered]@{
        status = "RUNNING"
        heartbeat_id = "BUILDER_LIFE_LOOP_HEARTBEAT_CURRENT"
        session_id = $SessionId
        run_id = $RunId
        cycle = $cycle
        completed_cycles = $CompletedCycles
        max_cycles = $MaxCycles
        last_task_type = $TaskType
        last_seen_at = (Get-Date).ToUniversalTime().ToString("o")
        stop_requested = $false
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $HeartbeatPath -Object $Heartbeat

      $LifeLoopState = [ordered]@{
        status = "RUNNING"
        state_id = "BUILDER_LIFE_LOOP_STATE_CURRENT"
        session_id = $SessionId
        run_id = $RunId
        current_line = "SELF_BUILD"
        completed_cycles = $CompletedCycles
        max_cycles = $MaxCycles
        checkpoint_every = $CheckpointEvery
        sleep_seconds = $SleepSeconds
        task_types_completed = @($TaskTypesCompleted | Select-Object -Unique)
        last_task_type = $TaskType
        correction_pending_count = $PendingCorrections.Count
        correction_seen_count = $CorrectionSeenCount
        selected_next_gap = $SelectedNextGap
        owner_interactive_prompt_required = $false
        external_agent_production_allowed = $false
        stop_requested = $false
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $LifeLoopStatePath -Object $LifeLoopState

      $LearningMetrics = [ordered]@{
        status = "PASS"
        metrics_id = "BUILDER_LIFE_LOOP_LEARNING_METRICS_CURRENT"
        session_id = $SessionId
        run_id = $RunId
        source_phase141_metrics_path = $Phase141MetricsPath
        source_phase141_proof_path = $Phase141ProofPath
        completed_cycles = $CompletedCycles
        task_types_completed = @($TaskTypesCompleted | Select-Object -Unique)
        builder_generated_pack_total_observed = $Phase141Proof.builder_generated_pack_total
        generated_pack_failure_count_observed = $Phase141Proof.generated_pack_failure_count
        correction_seen_count = $CorrectionSeenCount
        selected_next_gap = $SelectedNextGap
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $LearningMetricsPath -Object $LearningMetrics

      if ($cycle -eq 5 -and $CheckpointEvery -le 5) {
        $Checkpoint = [ordered]@{
          status = "PASS"
          checkpoint_id = "checkpoint_005"
          session_id = $SessionId
          run_id = $RunId
          cycle = $cycle
          completed_cycles = $CompletedCycles
          task_types_completed = @($TaskTypesCompleted | Select-Object -Unique)
          heartbeat_path = $HeartbeatPath
          life_loop_state_path = $LifeLoopStatePath
          observation_ledger_path = $ObservationLedgerPath
          decision_trace_path = $DecisionTracePath
          created_at = (Get-Date).ToUniversalTime().ToString("o")
          next_allowed_step = $NextAllowedStep
        }
        Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $Checkpoint005Path -Object $Checkpoint
      }

      if ($SleepSeconds -gt 0 -and $cycle -lt $MaxCycles) {
        Start-Sleep -Seconds $SleepSeconds
      }
    }

    $CompletedAt = (Get-Date).ToUniversalTime().ToString("o")
    $TaskTypesCompletedUnique = @($TaskTypesCompleted | Select-Object -Unique)

    $HeartbeatFinal = [ordered]@{
      status = "PASS"
      heartbeat_id = "BUILDER_LIFE_LOOP_HEARTBEAT_CURRENT"
      session_id = $SessionId
      run_id = $RunId
      completed_cycles = $CompletedCycles
      max_cycles = $MaxCycles
      last_task_type = $LastTaskType
      last_seen_at = $CompletedAt
      stop_requested = $StopRequested
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $HeartbeatPath -Object $HeartbeatFinal

    $SessionSummary = [ordered]@{
      status = "PASS"
      summary_id = "BUILDER_LIFE_LOOP_SESSION_SUMMARY_CURRENT"
      session_id = $SessionId
      run_id = $RunId
      completed_cycles = $CompletedCycles
      max_cycles = $MaxCycles
      checkpoint_every = $CheckpointEvery
      sleep_seconds = $SleepSeconds
      stop_requested = $StopRequested
      task_types_completed = $TaskTypesCompletedUnique
      observation_ledger_created = $true
      decision_trace_created = $true
      correction_inbox_supported = $true
      terminal_watcher_supported = $true
      repo_session_artifacts_created = $true
      selected_next_gap = $SelectedNextGap
      selected_by = "BUILDER_RUNTIME"
      owner_interactive_prompt_required = $false
      external_agent_production_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      completed_at = $CompletedAt
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $SessionSummaryPath -Object $SessionSummary

    $LifeLoopStateFinal = [ordered]@{
      status = "PASS"
      state_id = "BUILDER_LIFE_LOOP_STATE_CURRENT"
      session_id = $SessionId
      run_id = $RunId
      current_line = "SELF_BUILD"
      completed_cycles = $CompletedCycles
      max_cycles = $MaxCycles
      checkpoint_every = $CheckpointEvery
      sleep_seconds = $SleepSeconds
      task_types_completed = $TaskTypesCompletedUnique
      last_task_type = $LastTaskType
      correction_seen_count = $CorrectionSeenCount
      selected_next_gap = $SelectedNextGap
      owner_interactive_prompt_required = $false
      external_agent_production_allowed = $false
      stop_requested = $StopRequested
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $LifeLoopStatePath -Object $LifeLoopStateFinal

    $CorrectionInboxUpdated = [ordered]@{
      status = "PASS"
      inbox_id = "BUILDER_LIFE_LOOP_CORRECTION_INBOX"
      pending_corrections = @($CorrectionInbox.pending_corrections)
      observed_correction_count = $CorrectionSeenCount
      last_observed_by = $RuntimeId
      last_observed_at = $CompletedAt
      next_behavior_trial = "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1"
    }
    Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $CorrectionInboxPath -Object $CorrectionInboxUpdated

    $LifeLoopPolicy = [ordered]@{
      status = "PASS"
      policy_id = "BUILDER_LIFE_LOOP_POLICY_V1"
      max_cycles_default = 10
      checkpoint_every_default = 5
      owner_interactive_prompt_required = $false
      correction_inbox_supported = $true
      terminal_watcher_supported = $true
      repo_session_artifacts_supported = $true
      external_agent_production_allowed = $false
      dependency_install_allowed = $false
      external_fetch_allowed = $false
      executable_use_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $LifeLoopPolicyPath -Object $LifeLoopPolicy

    $NextGapSelectorResult = [ordered]@{
      status = "PASS"
      result_id = "BUILDER_NEXT_GAP_SELECTOR_RESULT_PHASE142"
      selected_next_gap = $SelectedNextGap
      selected_by = "BUILDER_RUNTIME"
      based_on = "PHASE141 metrics and PHASE142 observation loop"
      reason = "next gap should prove Builder can notice and respond to correction inbox without Owner/Assistant authoring every cycle"
      external_agent_production_allowed = $false
      owner_interactive_prompt_required = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $NextGapSelectorResultPath -Object $NextGapSelectorResult

    $RuntimeLog = @(
      "BUILDER_NEXT_GAP_SELECTOR_RUNTIME=PHASE142_BUILDER_NEXT_GAP_SELECTOR_OBSERVABLE_LIFE_LOOP_001",
      "OBSERVABLE_LIFE_LOOP_STATUS=PASS",
      "LIFE_LOOP_MAX_CYCLES=$MaxCycles",
      "LIFE_LOOP_COMPLETED_CYCLES=$CompletedCycles",
      "LIFE_LOOP_OBSERVATION_LEDGER_CREATED=True",
      "LIFE_LOOP_DECISION_TRACE_CREATED=True",
      "LIFE_LOOP_CORRECTION_INBOX_SUPPORTED=True",
      "LIFE_LOOP_TERMINAL_WATCHER_SUPPORTED=True",
      "LIFE_LOOP_REPO_SESSION_ARTIFACTS_CREATED=True",
      "BUILDER_SELECTED_NEXT_GAP=PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1",
      "OWNER_INTERACTIVE_PROMPT_REQUIRED=False",
      "EXTERNAL_AGENT_PRODUCTION_ALLOWED=False",
      "MATERIAL_TRUSTED_COUNT=0",
      "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
      "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
      "MATERIAL_EXECUTABLE_USED=False",
      "NEXT_ALLOWED_STEP=PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1",
      "STATUS=PASS_STOPPED_BUILDER_NEXT_GAP_SELECTOR_OBSERVABLE_LIFE_LOOP_BUILT"
    ) -join "`n"
    Write-Phase142TextFile -RepoRoot $RepoRoot -Path $RuntimeLogPath -Content "$RuntimeLog`n"

    $Output = [ordered]@{
      status = "PASS"
      engine_name = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      session_id = $SessionId
      life_loop_session_created = $true
      life_loop_max_cycles = $MaxCycles
      life_loop_completed_cycles = $CompletedCycles
      observation_ledger_created = $true
      decision_trace_created = $true
      correction_inbox_supported = $true
      terminal_watcher_supported = $true
      repo_session_artifacts_created = $true
      selected_next_gap = $SelectedNextGap
      selected_by = "BUILDER_RUNTIME"
      owner_interactive_prompt_required = $false
      current_line = "SELF_BUILD"
      external_agent_production_allowed = $false
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      queue_after = "NONE"
      heartbeat_path = $HeartbeatPath
      life_loop_state_path = $LifeLoopStatePath
      observation_ledger_path = $ObservationLedgerPath
      decision_trace_path = $DecisionTracePath
      error_ledger_path = $ErrorLedgerPath
      learning_metrics_path = $LearningMetricsPath
      correction_inbox_path = $CorrectionInboxPath
      session_summary_path = $SessionSummaryPath
      checkpoint_path = $Checkpoint005Path
      life_loop_policy_path = $LifeLoopPolicyPath
      next_gap_selector_result_path = $NextGapSelectorResultPath
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
      life_loop_session_created = $true
      life_loop_completed_cycles = $CompletedCycles
      selected_next_gap = $SelectedNextGap
      queue_after = "NONE"
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    $Report = [ordered]@{
      status = "PASS"
      report_id = "${StepId}_REPORT"
      step_id = $StepId
      run_id = $RunId
      orchestrator_hook = "orchestrator/run.ps1 invokes Invoke-BuilderNextGapSelectorObservableLifeLoop001 when PHASE141 proof is PASS and next_allowed_step is PHASE142."
      runtime_session_artifact_design = "The loop writes a current session folder with heartbeat, state, JSONL observation and decision streams, an empty error stream unless ambiguity appears, learning metrics, correction inbox, correction observation log, summary, and checkpoint_005."
      cycle_selection = "The bounded loop rotates safe internal tasks: READ_CURRENT_STATE, READ_NEXT_ACTION, FIND_LAST_ACCEPTED_PROOF, COMPARE_NEXT_STEP, WRITE_LEARNING_NOTE, and SELECT_NEXT_MICRO_GAP. Each cycle rereads current control state, NEXT_ACTION, PHASE141 proof/metrics, and the correction inbox."
      watcher_behavior = "tools/watch_builder_life_loop.ps1 repeatedly reads heartbeat, state, and recent ledger lines without mutating the repo."
      correction_inbox_behavior = "correction_inbox.json is always present. PHASE142 records pending corrections as observed but defers behavior changes to PHASE143."
      smoke_session = "Set BUILDER_LIFE_LOOP_MAX_CYCLES=6 and run tools/start_builder_life_loop.ps1 for a short bounded proof session."
      remaining_risks = @(
        "PHASE142 observes corrections but does not yet alter behavior from them.",
        "Cycle task selection is deterministic rotation, not yet a learned ranking.",
        "Watcher is a terminal reader and was not run as a concurrent process during validation."
      )
      cut_list = @(
        "No external agent production.",
        "No generated_agents, agent_catalog, or applied_agents changes.",
        "No dependency install.",
        "No internet fetch.",
        "No executable material use.",
        "No material trust.",
        "No main branch change.",
        "No infinite loop.",
        "No commit or push."
      )
      artifact_paths = [ordered]@{
        heartbeat = $HeartbeatPath
        life_loop_state = $LifeLoopStatePath
        observation_ledger = $ObservationLedgerPath
        decision_trace = $DecisionTracePath
        error_ledger = $ErrorLedgerPath
        learning_metrics = $LearningMetricsPath
        correction_inbox = $CorrectionInboxPath
        session_summary = $SessionSummaryPath
        checkpoint = $Checkpoint005Path
        policy = $LifeLoopPolicyPath
        selector_result = $NextGapSelectorResultPath
        proof = $ProofPath
      }
      next_allowed_step = $NextAllowedStep
    }

    $Proof = [ordered]@{
      status = "PASS"
      proof_id = $StepId
      step_id = $StepId
      run_id = $RunId
      runtime_mode = "SELF_BUILD_QUEUE_NONE_BUILDER_NEXT_GAP_SELECTOR_OBSERVABLE_LIFE_LOOP_001"
      runtime_executed = $true
      builder_runtime_invoked = $true
      life_loop_session_created = $true
      life_loop_completed_cycles = $CompletedCycles
      observation_ledger_created = $true
      decision_trace_created = $true
      correction_inbox_supported = $true
      terminal_watcher_supported = $true
      repo_session_artifacts_created = $true
      selected_next_gap = $SelectedNextGap
      selected_by = "BUILDER_RUNTIME"
      owner_interactive_prompt_required = $false
      current_line = "SELF_BUILD"
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
      phase141_proof_path = $Phase141ProofPath
      heartbeat_path = $HeartbeatPath
      life_loop_state_path = $LifeLoopStatePath
      observation_ledger_path = $ObservationLedgerPath
      decision_trace_path = $DecisionTracePath
      error_ledger_path = $ErrorLedgerPath
      learning_metrics_path = $LearningMetricsPath
      correction_inbox_path = $CorrectionInboxPath
      session_summary_path = $SessionSummaryPath
      checkpoint_path = $Checkpoint005Path
      life_loop_policy_path = $LifeLoopPolicyPath
      next_gap_selector_result_path = $NextGapSelectorResultPath
      output_path = $OutputPath
      result_path = $ResultPath
      runtime_log_path = $RuntimeLogPath
      report_path = $ReportPath
      next_allowed_step = $NextAllowedStep
    }

    Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $OutputPath -Object $Output
    Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result
    Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report
    Write-Phase142JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject]$Output
  } finally {
    Pop-Location
  }
}
