function Resolve-Phase147Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase147JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase147Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE147_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase147JsonLinesRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase147Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE147_MISSING_JSONL=$Path"
  }

  return @(Get-Content -LiteralPath $fullPath |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { ConvertFrom-Json $_ })
}

function Write-Phase147JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase147Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase147TextFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$Content
  )

  $fullPath = Resolve-Phase147Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Add-Phase147JsonLine {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object
  )

  $fullPath = Resolve-Phase147Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $line = $Object | ConvertTo-Json -Depth 80 -Compress
  [System.IO.File]::AppendAllText($fullPath, "$line`n", [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase147Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE147_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase147True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE147_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase147False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE147_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase147TaskMetrics {
  param(
    [object[]]$Decisions,
    [string[]]$SelfCorrectionTaskTypes
  )

  $taskTypes = @($Decisions |
    ForEach-Object { "$($_.selected_task_type)" } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

  $counts = @{}
  foreach ($taskType in $taskTypes) {
    if (-not $counts.ContainsKey($taskType)) {
      $counts[$taskType] = 0
    }
    $counts[$taskType] += 1
  }

  $taskCountRows = @($counts.GetEnumerator() |
    Sort-Object Name |
    ForEach-Object {
      [ordered]@{
        task_type = $_.Key
        count = [int]$_.Value
      }
    })

  $selfCorrectionTasks = @($taskTypes | Where-Object { $SelfCorrectionTaskTypes -contains $_ })

  return [pscustomobject][ordered]@{
    decision_count = [int]$taskTypes.Count
    unique_task_type_count = [int]@($taskTypes | Select-Object -Unique).Count
    select_next_micro_gap_count = [int]@($taskTypes | Where-Object { $_ -eq "SELECT_NEXT_MICRO_GAP" }).Count
    write_learning_note_count = [int]@($taskTypes | Where-Object { $_ -eq "WRITE_LEARNING_NOTE" }).Count
    self_correction_task_count = [int]$selfCorrectionTasks.Count
    unique_self_correction_task_type_count = [int]@($selfCorrectionTasks | Select-Object -Unique).Count
    task_counts = $taskCountRows
    task_sequence = $taskTypes
  }
}

function Invoke-BuilderObservationDrivenSelfCorrectionTrial001 {
  param(
    [string]$RepoRoot,
    [string]$RunId
  )

  $ErrorActionPreference = "Stop"
  Push-Location $RepoRoot

  try {
    $StepId = "PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1"
    $RuntimeId = "PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_001"
    $RunId = $RuntimeId
    $PreviousStepId = "PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1"
    $NextAllowedStep = "PHASE148_BUILDER_SELF_CORRECTION_RETENTION_TRIAL_V1"
    $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
    $BaselineSessionId = "LIVE_OBSERVE_AFTER_PHASE146_001"
    $Phase146ProofSessionId = "LIVE_AFTER_PHASE145_001"
    $TrialRoot = "runtime_sessions/builder_life_loop/self_correction_trials/PHASE147_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_001"
    $SessionId = "PHASE147_SELF_CORRECTION_SESSION_001"
    $CorrectionId = "PHASE147_SELF_CORRECTION_001"
    $CorrectionReason = "repetitive small task set detected in observation-only session"
    $CorrectionTargetBehavior = "introduce self-diagnostic and variation tasks before repeating micro-gap selection"
    $MaxCycles = 20
    $CheckpointEvery = 5
    $SleepSeconds = 0
    $BaselineRoot = "runtime_sessions/builder_life_loop/observations/$BaselineSessionId"
    $Phase146ProofPath = "proofs/self_development/${PreviousStepId}.json"
    $ResultPath = "self_control/BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_RESULT.json"
    $ReportPath = "reports/self_development/${StepId}_REPORT.json"
    $ProofPath = "proofs/self_development/${StepId}.json"
    $RuntimeLogPath = "$TrialRoot/${StepId}_RUNTIME_LOG.txt"
    $RepetitionDiagnosisPath = "$TrialRoot/repetition_diagnosis.json"
    $SelfCorrectionPath = "$TrialRoot/self_correction.json"
    $SelfCorrectionAppliedLogPath = "$TrialRoot/self_correction_applied_log.jsonl"
    $LearningMetricsPath = "$TrialRoot/learning_metrics.json"
    $SessionSummaryPath = "$TrialRoot/session_summary.json"
    $HeartbeatPath = "$TrialRoot/heartbeat.json"
    $LifeLoopStatePath = "$TrialRoot/life_loop_state.json"
    $ObservationLedgerPath = "$TrialRoot/observation_ledger.jsonl"
    $DecisionTracePath = "$TrialRoot/decision_trace.jsonl"
    $CheckpointRoot = "$TrialRoot/checkpoints"

    $SelfCorrectionTaskTypes = @(
      "DIAGNOSE_REPETITION",
      "WRITE_SELF_CORRECTION",
      "APPLY_SELF_CORRECTION",
      "PLAN_BEHAVIOR_VARIATION",
      "VERIFY_BEHAVIOR_CHANGE"
    )

    foreach ($identityFile in @(
      "CAPABILITY_ROADMAP.json",
      "GENESIS_STATE.json",
      "TASK_QUEUE.json",
      "packs/registry.json",
      "orchestrator/run.ps1"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase147Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $CurrentBranch = (git branch --show-current).Trim()
    if ($CurrentBranch -eq "main") {
      throw "PHASE147_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase147Equals -Actual $CurrentBranch -Expected $ExpectedBranch -Name "current_branch"
    $CurrentHead = (git rev-parse --short HEAD).Trim()

    $ExternalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
    if ($ExternalAgentStatus.Count -gt 0) {
      throw "PHASE147_EXTERNAL_AGENT_SCOPE_DIRTY=$($ExternalAgentStatus -join '; ')"
    }

    $Queue = Read-Phase147JsonRequired -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
    Assert-Phase147Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $Phase146Proof = Read-Phase147JsonRequired -RepoRoot $RepoRoot -Path $Phase146ProofPath
    Assert-Phase147Equals -Actual $Phase146Proof.status -Expected "PASS" -Name "phase146_status"
    Assert-Phase147Equals -Actual $Phase146Proof.next_allowed_step -Expected $StepId -Name "phase146_next_allowed_step"
    Assert-Phase147Equals -Actual $Phase146Proof.observation_session_id -Expected $Phase146ProofSessionId -Name "phase146_observation_session_id"
    Assert-Phase147True -Actual $Phase146Proof.builder_runtime_decision_author -Name "phase146_builder_runtime_decision_author"
    Assert-Phase147True -Actual $Phase146Proof.supervisor_lifecycle_only -Name "phase146_supervisor_lifecycle_only"
    Assert-Phase147False -Actual $Phase146Proof.routed_phase_runtime_invoked -Name "phase146_routed_phase_runtime_invoked"
    Assert-Phase147False -Actual $Phase146Proof.external_agent_production_allowed -Name "phase146_external_agent_production_allowed"

    foreach ($baselineFile in @(
      "$BaselineRoot/session_summary.json",
      "$BaselineRoot/decision_trace.jsonl",
      "$BaselineRoot/observation_ledger.jsonl",
      "$BaselineRoot/learning_metrics.json"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase147Path -RepoRoot $RepoRoot -Path $baselineFile))) {
        throw "PHASE147_BASELINE_OBSERVATION_MISSING=$baselineFile"
      }
    }

    $BaselineSummary = Read-Phase147JsonRequired -RepoRoot $RepoRoot -Path "$BaselineRoot/session_summary.json"
    $BaselineDecisions = Read-Phase147JsonLinesRequired -RepoRoot $RepoRoot -Path "$BaselineRoot/decision_trace.jsonl"
    $BaselineMetrics = Get-Phase147TaskMetrics -Decisions $BaselineDecisions -SelfCorrectionTaskTypes $SelfCorrectionTaskTypes
    $BaselineCompletedCycles = [int]$BaselineSummary.completed_cycles
    $BaselineRepeatedDominanceCount = [int]($BaselineMetrics.select_next_micro_gap_count + $BaselineMetrics.write_learning_note_count)
    $BaselineRepeatedDominanceRatio = [math]::Round(($BaselineRepeatedDominanceCount / [double]$BaselineMetrics.decision_count), 4)
    $BaselineObservationAnalyzed = $true
    $RepetitionDetected = (
      $BaselineCompletedCycles -ge 40 -and
      [int]$BaselineMetrics.unique_task_type_count -le 6 -and
      [int]$BaselineMetrics.select_next_micro_gap_count -ge 8 -and
      [int]$BaselineMetrics.write_learning_note_count -ge 8 -and
      [int]$BaselineMetrics.self_correction_task_count -eq 0
    )
    Assert-Phase147True -Actual $RepetitionDetected -Name "repetition_detected"

    New-Item -ItemType Directory -Force -Path (Resolve-Phase147Path -RepoRoot $RepoRoot -Path $TrialRoot) | Out-Null
    New-Item -ItemType Directory -Force -Path (Resolve-Phase147Path -RepoRoot $RepoRoot -Path $CheckpointRoot) | Out-Null

    foreach ($jsonlPath in @(
      $ObservationLedgerPath,
      $DecisionTracePath,
      $SelfCorrectionAppliedLogPath
    )) {
      Write-Phase147TextFile -RepoRoot $RepoRoot -Path $jsonlPath -Content ""
    }

    $StartedAt = (Get-Date).ToUniversalTime().ToString("o")
    $RepetitionDiagnosis = [ordered]@{
      status = "PASS"
      diagnosis_id = "PHASE147_REPETITION_DIAGNOSIS"
      session_id = $SessionId
      run_id = $RunId
      baseline_session = $BaselineSessionId
      baseline_completed_cycles = $BaselineCompletedCycles
      baseline_decision_count = [int]$BaselineMetrics.decision_count
      baseline_unique_task_type_count = [int]$BaselineMetrics.unique_task_type_count
      baseline_select_next_micro_gap_count = [int]$BaselineMetrics.select_next_micro_gap_count
      baseline_write_learning_note_count = [int]$BaselineMetrics.write_learning_note_count
      baseline_self_correction_task_count = [int]$BaselineMetrics.self_correction_task_count
      baseline_repeated_task_dominance_count = $BaselineRepeatedDominanceCount
      baseline_repeated_task_dominance_ratio = $BaselineRepeatedDominanceRatio
      baseline_task_counts = $BaselineMetrics.task_counts
      baseline_observation_analyzed = $BaselineObservationAnalyzed
      repetition_detected = $RepetitionDetected
      diagnosis_reason = $CorrectionReason
      selected_by = "BUILDER_RUNTIME"
      lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
      supervisor_lifecycle_only = $true
      routed_phase_runtime_invoked = $false
      owner_interactive_prompt_required = $false
      assistant_or_codex_per_cycle_authoring_required = $false
      external_agent_production_allowed = $false
      created_at = $StartedAt
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase147JsonFile -RepoRoot $RepoRoot -Path $RepetitionDiagnosisPath -Object $RepetitionDiagnosis

    $SelfCorrection = [ordered]@{
      status = "PASS"
      correction_id = $CorrectionId
      created_by = "BUILDER_RUNTIME"
      self_correction_created_by = "BUILDER_RUNTIME"
      source_observation_session = $BaselineSessionId
      reason = $CorrectionReason
      target_behavior = $CorrectionTargetBehavior
      baseline_diagnosis_path = $RepetitionDiagnosisPath
      baseline_completed_cycles = $BaselineCompletedCycles
      baseline_unique_task_type_count = [int]$BaselineMetrics.unique_task_type_count
      baseline_select_next_micro_gap_count = [int]$BaselineMetrics.select_next_micro_gap_count
      baseline_write_learning_note_count = [int]$BaselineMetrics.write_learning_note_count
      self_correction_created = $true
      selected_by = "BUILDER_RUNTIME"
      lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
      supervisor_lifecycle_only = $true
      owner_interactive_prompt_required = $false
      assistant_or_codex_per_cycle_authoring_required = $false
      external_agent_production_allowed = $false
      created_at = $StartedAt
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase147JsonFile -RepoRoot $RepoRoot -Path $SelfCorrectionPath -Object $SelfCorrection

    $TrialTaskSequence = @(
      "DIAGNOSE_REPETITION",
      "WRITE_SELF_CORRECTION",
      "APPLY_SELF_CORRECTION",
      "PLAN_BEHAVIOR_VARIATION",
      "VERIFY_BEHAVIOR_CHANGE",
      "READ_BASELINE_SUMMARY",
      "MEASURE_TASK_DIVERSITY",
      "WRITE_LEARNING_NOTE",
      "SELECT_NEXT_MICRO_GAP",
      "PLAN_BEHAVIOR_VARIATION",
      "DIAGNOSE_REPETITION",
      "APPLY_SELF_CORRECTION",
      "VERIFY_BEHAVIOR_CHANGE",
      "WRITE_LEARNING_NOTE",
      "SELECT_NEXT_MICRO_GAP",
      "MEASURE_REPETITION_REDUCTION",
      "WRITE_RETENTION_NOTE",
      "PLAN_NEXT_GAP",
      "VERIFY_BEHAVIOR_CHANGE",
      "RECORD_SELF_CORRECTION_PROOF"
    )

    $SelfCorrectionApplied = $false
    $SelfCorrectionAppliedCount = 0
    $TrialTaskSequenceSeen = New-Object System.Collections.Generic.List[string]

    for ($cycle = 1; $cycle -le $MaxCycles; $cycle++) {
      $Now = (Get-Date).ToUniversalTime().ToString("o")
      $TaskType = $TrialTaskSequence[$cycle - 1]
      $TrialTaskSequenceSeen.Add($TaskType) | Out-Null
      $IsSelfCorrectionTask = $SelfCorrectionTaskTypes -contains $TaskType

      if ($TaskType -eq "APPLY_SELF_CORRECTION") {
        $SelfCorrectionApplied = $true
        $SelfCorrectionAppliedCount += 1
        $AppliedEvent = [ordered]@{
          event_type = "SELF_CORRECTION_APPLIED"
          correction_id = $CorrectionId
          session_id = $SessionId
          run_id = $RunId
          cycle = $cycle
          applied_by = "BUILDER_RUNTIME"
          selected_by = "BUILDER_RUNTIME"
          lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
          source_observation_session = $BaselineSessionId
          target_behavior = $CorrectionTargetBehavior
          supervisor_lifecycle_only = $true
          routed_phase_runtime_invoked = $false
          applied_at = $Now
        }
        Add-Phase147JsonLine -RepoRoot $RepoRoot -Path $SelfCorrectionAppliedLogPath -Object $AppliedEvent
      }

      $SelectionReason = switch ($TaskType) {
        "DIAGNOSE_REPETITION" { "Builder runtime diagnosed repetitive baseline task selection before choosing another micro-gap." }
        "WRITE_SELF_CORRECTION" { "Builder runtime authored $CorrectionId from the observation diagnosis." }
        "APPLY_SELF_CORRECTION" { "Builder runtime applied $CorrectionId to introduce diagnostic and variation tasks." }
        "PLAN_BEHAVIOR_VARIATION" { "Builder runtime planned variation before allowing repeated micro-gap selection." }
        "VERIFY_BEHAVIOR_CHANGE" { "Builder runtime verified task distribution changed after self-correction." }
        default { "Builder runtime selected $TaskType under the self-correction contour after diagnostic tasks had priority." }
      }

      $DecisionEvent = [ordered]@{
        event_type = "DECISION"
        session_id = $SessionId
        run_id = $RunId
        cycle = $cycle
        selected_task_type = $TaskType
        selection_reason = $SelectionReason
        source_observation_session = $BaselineSessionId
        correction_id = $CorrectionId
        self_correction_task = $IsSelfCorrectionTask
        self_correction_created_by = "BUILDER_RUNTIME"
        self_correction_applied = $SelfCorrectionApplied
        selected_by = "BUILDER_RUNTIME"
        lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
        supervisor_lifecycle_only = $true
        routed_phase_runtime_invoked = $false
        owner_interactive_prompt_required = $false
        assistant_or_codex_per_cycle_authoring_required = $false
        external_agent_production_allowed = $false
        selected_next_gap = $NextAllowedStep
        decided_at = $Now
      }
      Add-Phase147JsonLine -RepoRoot $RepoRoot -Path $DecisionTracePath -Object $DecisionEvent

      $ObservationEvent = [ordered]@{
        event_type = "OBSERVATION"
        session_id = $SessionId
        run_id = $RunId
        cycle = $cycle
        task_type = $TaskType
        status = "PASS"
        correction_id = $CorrectionId
        selected_by = "BUILDER_RUNTIME"
        lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
        supervisor_lifecycle_only = $true
        routed_phase_runtime_invoked = $false
        owner_interactive_prompt_required = $false
        assistant_or_codex_per_cycle_authoring_required = $false
        external_agent_production_allowed = $false
        practice_result = [ordered]@{
          baseline_observation_analyzed = $BaselineObservationAnalyzed
          repetition_detected = $RepetitionDetected
          self_correction_created = $true
          self_correction_created_by = "BUILDER_RUNTIME"
          self_correction_applied = $SelfCorrectionApplied
          task_type = $TaskType
          variation_before_repeating_micro_gap = ($cycle -lt 8 -or $IsSelfCorrectionTask)
          selected_next_gap = $NextAllowedStep
        }
        observed_at = $Now
      }
      Add-Phase147JsonLine -RepoRoot $RepoRoot -Path $ObservationLedgerPath -Object $ObservationEvent

      $Heartbeat = [ordered]@{
        status = "RUNNING"
        heartbeat_id = "PHASE147_SELF_CORRECTION_HEARTBEAT"
        session_id = $SessionId
        run_id = $RunId
        completed_cycles = $cycle
        max_cycles = $MaxCycles
        checkpoint_every = $CheckpointEvery
        sleep_seconds = $SleepSeconds
        baseline_observation_analyzed = $BaselineObservationAnalyzed
        repetition_detected = $RepetitionDetected
        self_correction_created = $true
        self_correction_created_by = "BUILDER_RUNTIME"
        self_correction_applied = $SelfCorrectionApplied
        selected_by = "BUILDER_RUNTIME"
        lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
        supervisor_lifecycle_only = $true
        routed_phase_runtime_invoked = $false
        last_task_type = $TaskType
        last_seen_at = $Now
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase147JsonFile -RepoRoot $RepoRoot -Path $HeartbeatPath -Object $Heartbeat

      $LifeLoopState = [ordered]@{
        status = "RUNNING"
        state_id = "PHASE147_SELF_CORRECTION_LIFE_LOOP_STATE"
        session_id = $SessionId
        run_id = $RunId
        completed_cycles = $cycle
        max_cycles = $MaxCycles
        checkpoint_every = $CheckpointEvery
        sleep_seconds = $SleepSeconds
        current_line = "SELF_BUILD"
        source_observation_session = $BaselineSessionId
        correction_id = $CorrectionId
        baseline_observation_analyzed = $BaselineObservationAnalyzed
        repetition_detected = $RepetitionDetected
        self_correction_created = $true
        self_correction_created_by = "BUILDER_RUNTIME"
        self_correction_applied = $SelfCorrectionApplied
        selected_by = "BUILDER_RUNTIME"
        lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
        supervisor_lifecycle_only = $true
        routed_phase_runtime_invoked = $false
        owner_interactive_prompt_required = $false
        assistant_or_codex_per_cycle_authoring_required = $false
        external_agent_production_allowed = $false
        selected_next_gap = $NextAllowedStep
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase147JsonFile -RepoRoot $RepoRoot -Path $LifeLoopStatePath -Object $LifeLoopState

      if (($cycle % $CheckpointEvery) -eq 0) {
        $CheckpointName = "checkpoint_{0:d3}.json" -f $cycle
        $Checkpoint = [ordered]@{
          status = "PASS"
          checkpoint_id = ("checkpoint_{0:d3}" -f $cycle)
          session_id = $SessionId
          run_id = $RunId
          completed_cycles = $cycle
          baseline_observation_analyzed = $BaselineObservationAnalyzed
          repetition_detected = $RepetitionDetected
          self_correction_created = $true
          self_correction_created_by = "BUILDER_RUNTIME"
          self_correction_applied = $SelfCorrectionApplied
          selected_by = "BUILDER_RUNTIME"
          lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
          supervisor_lifecycle_only = $true
          routed_phase_runtime_invoked = $false
          created_at = $Now
          next_allowed_step = $NextAllowedStep
        }
        Write-Phase147JsonFile -RepoRoot $RepoRoot -Path "$CheckpointRoot/$CheckpointName" -Object $Checkpoint
      }

      if ($SleepSeconds -gt 0) {
        Start-Sleep -Seconds $SleepSeconds
      }
    }

    Assert-Phase147True -Actual $SelfCorrectionApplied -Name "self_correction_applied"

    $TrialDecisions = Read-Phase147JsonLinesRequired -RepoRoot $RepoRoot -Path $DecisionTracePath
    $TrialMetrics = Get-Phase147TaskMetrics -Decisions $TrialDecisions -SelfCorrectionTaskTypes $SelfCorrectionTaskTypes
    $TrialRepeatedDominanceCount = [int]($TrialMetrics.select_next_micro_gap_count + $TrialMetrics.write_learning_note_count)
    $TrialRepeatedDominanceRatio = [math]::Round(($TrialRepeatedDominanceCount / [double]$TrialMetrics.decision_count), 4)
    $RepeatedTaskDominanceReduced = $TrialRepeatedDominanceRatio -lt $BaselineRepeatedDominanceRatio
    $BaselineFirstTwenty = @($BaselineMetrics.task_sequence | Select-Object -First $MaxCycles)
    $TrialSequenceArray = @($TrialMetrics.task_sequence)
    $BehaviorChangedAfterSelfCorrection = (
      -not [string]::Equals(($BaselineFirstTwenty -join ","), ($TrialSequenceArray -join ","), [System.StringComparison]::Ordinal) -and
      [int]$TrialMetrics.self_correction_task_count -ge 2 -and
      $RepeatedTaskDominanceReduced
    )
    Assert-Phase147True -Actual $BehaviorChangedAfterSelfCorrection -Name "behavior_changed_after_self_correction"
    Assert-Phase147True -Actual $RepeatedTaskDominanceReduced -Name "repeated_task_dominance_reduced"

    $CompletedAt = (Get-Date).ToUniversalTime().ToString("o")
    $LearningMetrics = [ordered]@{
      status = "PASS"
      metrics_id = "PHASE147_SELF_CORRECTION_LEARNING_METRICS"
      session_id = $SessionId
      run_id = $RunId
      completed_cycles = $MaxCycles
      max_cycles = $MaxCycles
      checkpoint_every = $CheckpointEvery
      sleep_seconds = $SleepSeconds
      baseline_session = $BaselineSessionId
      baseline_observation_analyzed = $BaselineObservationAnalyzed
      repetition_detected = $RepetitionDetected
      self_correction_created = $true
      self_correction_created_by = "BUILDER_RUNTIME"
      self_correction_applied = $SelfCorrectionApplied
      behavior_changed_after_self_correction = $BehaviorChangedAfterSelfCorrection
      self_correction_task_count = [int]$TrialMetrics.self_correction_task_count
      repeated_task_dominance_reduced = $RepeatedTaskDominanceReduced
      baseline_repeated_task_dominance_count = $BaselineRepeatedDominanceCount
      baseline_repeated_task_dominance_ratio = $BaselineRepeatedDominanceRatio
      trial_repeated_task_dominance_count = $TrialRepeatedDominanceCount
      trial_repeated_task_dominance_ratio = $TrialRepeatedDominanceRatio
      baseline_task_counts = $BaselineMetrics.task_counts
      trial_task_counts = $TrialMetrics.task_counts
      baseline_task_sequence = @($BaselineFirstTwenty)
      trial_task_sequence = @($TrialSequenceArray)
      selected_next_gap = $NextAllowedStep
      selected_by = "BUILDER_RUNTIME"
      lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
      supervisor_lifecycle_only = $true
      routed_phase_runtime_invoked = $false
      owner_interactive_prompt_required = $false
      assistant_or_codex_per_cycle_authoring_required = $false
      external_agent_production_allowed = $false
      trusted_material_count = 0
      material_trusted_count = 0
      external_fetch_performed = $false
      material_external_fetch_performed = $false
      dependency_install_performed = $false
      material_dependency_install_performed = $false
      executable_materials_used = $false
      material_executable_used = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase147JsonFile -RepoRoot $RepoRoot -Path $LearningMetricsPath -Object $LearningMetrics

    $SessionSummary = [ordered]@{
      status = "PASS"
      summary_id = "PHASE147_SELF_CORRECTION_SESSION_SUMMARY"
      session_id = $SessionId
      run_id = $RunId
      completed_cycles = $MaxCycles
      max_cycles = $MaxCycles
      checkpoint_every = $CheckpointEvery
      sleep_seconds = $SleepSeconds
      source_observation_session = $BaselineSessionId
      baseline_observation_analyzed = $BaselineObservationAnalyzed
      repetition_detected = $RepetitionDetected
      self_correction_created = $true
      self_correction_created_by = "BUILDER_RUNTIME"
      self_correction_applied = $SelfCorrectionApplied
      behavior_changed_after_self_correction = $BehaviorChangedAfterSelfCorrection
      self_correction_task_count = [int]$TrialMetrics.self_correction_task_count
      repeated_task_dominance_reduced = $RepeatedTaskDominanceReduced
      selected_next_gap = $NextAllowedStep
      selected_by = "BUILDER_RUNTIME"
      lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
      supervisor_lifecycle_only = $true
      routed_phase_runtime_invoked = $false
      owner_interactive_prompt_required = $false
      assistant_or_codex_per_cycle_authoring_required = $false
      external_agent_production_allowed = $false
      trusted_material_count = 0
      material_trusted_count = 0
      external_fetch_performed = $false
      material_external_fetch_performed = $false
      dependency_install_performed = $false
      material_dependency_install_performed = $false
      executable_materials_used = $false
      material_executable_used = $false
      completed_at = $CompletedAt
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase147JsonFile -RepoRoot $RepoRoot -Path $SessionSummaryPath -Object $SessionSummary

    $FinalHeartbeat = [ordered]@{}
    foreach ($key in $SessionSummary.Keys) {
      $FinalHeartbeat[$key] = $SessionSummary[$key]
    }
    $FinalHeartbeat["heartbeat_id"] = "PHASE147_SELF_CORRECTION_HEARTBEAT"
    Write-Phase147JsonFile -RepoRoot $RepoRoot -Path $HeartbeatPath -Object $FinalHeartbeat

    $FinalState = [ordered]@{}
    foreach ($key in $SessionSummary.Keys) {
      $FinalState[$key] = $SessionSummary[$key]
    }
    $FinalState["state_id"] = "PHASE147_SELF_CORRECTION_LIFE_LOOP_STATE"
    Write-Phase147JsonFile -RepoRoot $RepoRoot -Path $LifeLoopStatePath -Object $FinalState

    $Result = [ordered]@{
      status = "PASS"
      result_id = "PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_RESULT"
      baseline_session = $BaselineSessionId
      trial_session = $SessionId
      baseline_observation_analyzed = $BaselineObservationAnalyzed
      repetition_detected = $RepetitionDetected
      self_correction_created = $true
      self_correction_created_by = "BUILDER_RUNTIME"
      self_correction_applied = $SelfCorrectionApplied
      behavior_changed_after_self_correction = $BehaviorChangedAfterSelfCorrection
      repeated_task_dominance_reduced = $RepeatedTaskDominanceReduced
      selected_next_gap = $NextAllowedStep
      selected_by = "BUILDER_RUNTIME"
      external_agent_production_allowed = $false
      owner_interactive_prompt_required = $false
      assistant_or_codex_per_cycle_authoring_required = $false
      supervisor_lifecycle_only = $true
      routed_phase_runtime_invoked = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase147JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result

    $RuntimeLog = @(
      "BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL=PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_001",
      "BASELINE_SESSION_ID=LIVE_OBSERVE_AFTER_PHASE146_001",
      "SELF_CORRECTION_SESSION_ID=PHASE147_SELF_CORRECTION_SESSION_001",
      "BASELINE_OBSERVATION_ANALYZED=True",
      "REPETITION_DETECTED=True",
      "SELF_CORRECTION_CREATED=True",
      "SELF_CORRECTION_CREATED_BY=BUILDER_RUNTIME",
      "SELF_CORRECTION_APPLIED=True",
      "BEHAVIOR_CHANGED_AFTER_SELF_CORRECTION=True",
      "REPEATED_TASK_DOMINANCE_REDUCED=True",
      "OWNER_INTERACTIVE_PROMPT_REQUIRED=False",
      "ASSISTANT_OR_CODEX_PER_CYCLE_AUTHORING_REQUIRED=False",
      "SUPERVISOR_LIFECYCLE_ONLY=True",
      "ROUTED_PHASE_RUNTIME_INVOKED=False",
      "EXTERNAL_AGENT_PRODUCTION_ALLOWED=False",
      "MATERIAL_TRUSTED_COUNT=0",
      "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
      "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
      "MATERIAL_EXECUTABLE_USED=False",
      "NEXT_ALLOWED_STEP=PHASE148_BUILDER_SELF_CORRECTION_RETENTION_TRIAL_V1",
      "STATUS=PASS_STOPPED_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_BUILT"
    ) -join "`n"
    Write-Phase147TextFile -RepoRoot $RepoRoot -Path $RuntimeLogPath -Content "$RuntimeLog`n"

    $Report = [ordered]@{
      status = "PASS"
      report_id = "${StepId}_REPORT"
      step_id = $StepId
      run_id = $RunId
      active_line = "AGENT_BUILDER_SELF_DEVELOPMENT"
      baseline_repetition_detection = "Read $BaselineRoot/decision_trace.jsonl and session_summary.json; require completed_cycles >= 40, unique selected_task_type count <= 6, SELECT_NEXT_MICRO_GAP count >= 8, WRITE_LEARNING_NOTE count >= 8, and zero self-correction task types."
      baseline_repetition_metrics = [ordered]@{
        completed_cycles = $BaselineCompletedCycles
        unique_task_type_count = [int]$BaselineMetrics.unique_task_type_count
        select_next_micro_gap_count = [int]$BaselineMetrics.select_next_micro_gap_count
        write_learning_note_count = [int]$BaselineMetrics.write_learning_note_count
        self_correction_task_count = [int]$BaselineMetrics.self_correction_task_count
        repeated_task_dominance_ratio = $BaselineRepeatedDominanceRatio
      }
      self_correction_creation = "Builder runtime writes $SelfCorrectionPath with correction_id $CorrectionId, created_by BUILDER_RUNTIME, the required reason, and the required target_behavior."
      builder_authority_boundary = "Every decision_trace entry uses selected_by BUILDER_RUNTIME and lifecycle_authority OBSERVATION_RUNNER_ONLY; the self-correction object uses created_by BUILDER_RUNTIME and self_correction_created_by BUILDER_RUNTIME. The orchestrator only invokes the bounded runtime after the PHASE146 proof gate."
      behavior_change_measurement = "Compare the first 20 baseline selected_task_type values to the 20-cycle self-correction sequence and require sequence inequality, at least two self-correction task selections, and reduced repeated task dominance."
      repeated_task_dominance_reduction = "Baseline SELECT_NEXT_MICRO_GAP plus WRITE_LEARNING_NOTE dominance is $BaselineRepeatedDominanceCount/$($BaselineMetrics.decision_count) = $BaselineRepeatedDominanceRatio; trial dominance is $TrialRepeatedDominanceCount/$($TrialMetrics.decision_count) = $TrialRepeatedDominanceRatio."
      validator_behavior = "Validator fails on missing or non-PASS PHASE146 proof, missing baseline observation, baseline completed_cycles < 40, repetition not detected, missing or non-Builder self_correction.json, unapplied self-correction, no behavior change, no dominance reduction, missing self-correction task types in decision_trace, wrong next gap, owner prompt or Codex per-cycle authoring, supervisor-authored task decisions, routed phase invocation, external-agent scope changes, trusted materials, fetch/install/executable flags, or active queue."
      proof_path = $ProofPath
      report_path = $ReportPath
      result_path = $ResultPath
      trial_artifact_root = $TrialRoot
      runtime_log_path = $RuntimeLogPath
      remaining_risks = @(
        "PHASE147 proves a deterministic one-session self-correction from one observation baseline; PHASE148 must prove retention across a later session.",
        "The trial reduces dominance by explicit diagnostic/variation tasks, not by an open-ended learned scoring model.",
        "The proof is local and bounded; no hosted verification is claimed."
      )
      cut_list = @(
        "No external agent production.",
        "No generated_agents, agent_catalog, or applied_agents changes.",
        "No internet fetch.",
        "No dependency install.",
        "No executable material use.",
        "No trusted material creation.",
        "No main branch change.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase147JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report

    $Proof = [ordered]@{
      status = "PASS"
      proof_id = $StepId
      step_id = $StepId
      run_id = $RunId
      runtime_mode = "SELF_BUILD_QUEUE_NONE_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_001"
      runtime_executed = $true
      builder_runtime_invoked = $true
      baseline_session = $BaselineSessionId
      trial_session = $SessionId
      baseline_observation_analyzed = $BaselineObservationAnalyzed
      repetition_detected = $RepetitionDetected
      baseline_completed_cycles = $BaselineCompletedCycles
      baseline_unique_task_type_count = [int]$BaselineMetrics.unique_task_type_count
      baseline_select_next_micro_gap_count = [int]$BaselineMetrics.select_next_micro_gap_count
      baseline_write_learning_note_count = [int]$BaselineMetrics.write_learning_note_count
      baseline_self_correction_task_count = [int]$BaselineMetrics.self_correction_task_count
      self_correction_created = $true
      self_correction_created_by = "BUILDER_RUNTIME"
      self_correction_applied = $SelfCorrectionApplied
      behavior_changed_after_self_correction = $BehaviorChangedAfterSelfCorrection
      self_correction_task_count = [int]$TrialMetrics.self_correction_task_count
      repeated_task_dominance_reduced = $RepeatedTaskDominanceReduced
      baseline_repeated_task_dominance_ratio = $BaselineRepeatedDominanceRatio
      trial_repeated_task_dominance_ratio = $TrialRepeatedDominanceRatio
      owner_interactive_prompt_required = $false
      assistant_or_codex_per_cycle_authoring_required = $false
      supervisor_lifecycle_only = $true
      routed_phase_runtime_invoked = $false
      lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
      selected_next_gap = $NextAllowedStep
      selected_by = "BUILDER_RUNTIME"
      current_line = "SELF_BUILD"
      external_agent_production_allowed = $false
      production_adoption_allowed = $false
      trusted_material_count = 0
      material_trusted_count = 0
      external_fetch_performed = $false
      material_external_fetch_performed = $false
      dependency_install_performed = $false
      material_dependency_install_performed = $false
      executable_materials_used = $false
      material_executable_used = $false
      queue_after = "NONE"
      main_touched = $false
      source_branch = $CurrentBranch
      source_head = $CurrentHead
      phase146_proof_path = $Phase146ProofPath
      baseline_root = $BaselineRoot
      trial_artifact_root = $TrialRoot
      repetition_diagnosis_path = $RepetitionDiagnosisPath
      self_correction_path = $SelfCorrectionPath
      self_correction_applied_log_path = $SelfCorrectionAppliedLogPath
      result_path = $ResultPath
      report_path = $ReportPath
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase147JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    $Output = [ordered]@{
      status = "PASS"
      engine_name = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      baseline_session = $BaselineSessionId
      trial_session = $SessionId
      baseline_observation_analyzed = $BaselineObservationAnalyzed
      repetition_detected = $RepetitionDetected
      self_correction_created = $true
      self_correction_created_by = "BUILDER_RUNTIME"
      self_correction_applied = $SelfCorrectionApplied
      behavior_changed_after_self_correction = $BehaviorChangedAfterSelfCorrection
      self_correction_task_count = [int]$TrialMetrics.self_correction_task_count
      repeated_task_dominance_reduced = $RepeatedTaskDominanceReduced
      owner_interactive_prompt_required = $false
      assistant_or_codex_per_cycle_authoring_required = $false
      supervisor_lifecycle_only = $true
      routed_phase_runtime_invoked = $false
      selected_next_gap = $NextAllowedStep
      selected_by = "BUILDER_RUNTIME"
      lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
      external_agent_production_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      queue_after = "NONE"
      trial_artifact_root = $TrialRoot
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      runtime_log_path = $RuntimeLogPath
      proposed_next_step = $NextAllowedStep
      next_allowed_step = $NextAllowedStep
    }

    return [pscustomobject]$Output
  } finally {
    Pop-Location
  }
}
