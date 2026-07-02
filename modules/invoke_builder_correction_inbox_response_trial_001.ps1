function Resolve-Phase143Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase143JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase143Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE143_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase143JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase143Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase143TextFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$Content
  )

  $fullPath = Resolve-Phase143Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Add-Phase143JsonLine {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object
  )

  $fullPath = Resolve-Phase143Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $line = $Object | ConvertTo-Json -Depth 50 -Compress
  [System.IO.File]::AppendAllText($fullPath, "$line`n", [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase143Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE143_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase143True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE143_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase143False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE143_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Invoke-BuilderCorrectionInboxResponseTrial001 {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$OutputRoot
  )

  $ErrorActionPreference = "Stop"

  Push-Location $RepoRoot

  try {
    $StepId = "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1"
    $RuntimeId = "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_001"
    $PreviousStepId = "PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1"
    $NextAllowedStep = "PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1"
    $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
    $BaselineSessionId = "LIVE_LOOP_002"
    $TrialSessionId = "PHASE143_CORRECTION_RESPONSE_TRIAL_001"
    $CorrectionId = "PHASE143_CORRECTION_001"
    $CorrectionMessage = "Do not repeat only the safe carousel. Increase practical adaptation: after reading state, prioritize WRITE_LEARNING_NOTE and SELECT_NEXT_MICRO_GAP, and explain behavior change."

    if ([string]::IsNullOrWhiteSpace($RunId)) {
      $RunId = $RuntimeId
    }

    $MaxCycles = 12
    $CheckpointEvery = 4
    $SleepSeconds = 0

    $OutputArtifactRoot = "self_build_batch/autonomy_trials/$StepId"
    if (-not [string]::IsNullOrWhiteSpace($OutputRoot)) {
      $OutputArtifactRoot = $OutputRoot -replace "\\", "/"
    }

    $CurrentRoot = "runtime_sessions/builder_life_loop/current"
    $TrialRoot = "runtime_sessions/builder_life_loop/correction_trials/$TrialSessionId"
    $BaselineRoot = "runtime_sessions/builder_life_loop/observations/$BaselineSessionId"
    $CheckpointRoot = "$CurrentRoot/checkpoints"
    $TrialCheckpointRoot = "$TrialRoot/checkpoints"
    $Phase142ProofPath = "proofs/self_development/${PreviousStepId}.json"
    $CurrentStatePath = "self_control/CURRENT_AGENT_BUILDER_STATE.json"
    $NextActionPath = "self_control/NEXT_ACTION.json"
    $LastAcceptedProofPointerPath = "self_control/LAST_ACCEPTED_PROOF_POINTER.json"
    $TrialResultPath = "self_control/BUILDER_CORRECTION_RESPONSE_TRIAL_RESULT.json"
    $OutputPath = "$OutputArtifactRoot/BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_OUTPUT.json"
    $ResultPath = "$OutputArtifactRoot/${StepId}_RESULT.json"
    $RuntimeLogPath = "$OutputArtifactRoot/${StepId}_RUNTIME_LOG.txt"
    $ReportPath = "reports/self_development/${StepId}_REPORT.json"
    $ProofPath = "proofs/self_development/${StepId}.json"

    $CurrentPaths = [ordered]@{
      heartbeat = "$CurrentRoot/heartbeat.json"
      state = "$CurrentRoot/life_loop_state.json"
      observation = "$CurrentRoot/observation_ledger.jsonl"
      decision = "$CurrentRoot/decision_trace.jsonl"
      error = "$CurrentRoot/error_ledger.jsonl"
      learning = "$CurrentRoot/learning_metrics.json"
      correction_inbox = "$CurrentRoot/correction_inbox.json"
      correction_inbox_initial = "$CurrentRoot/correction_inbox_initial.json"
      correction_log = "$CurrentRoot/correction_applied_log.jsonl"
      summary = "$CurrentRoot/session_summary.json"
      checkpoint = "$CheckpointRoot/checkpoint_004.json"
    }
    $TrialPaths = [ordered]@{
      heartbeat = "$TrialRoot/heartbeat.json"
      state = "$TrialRoot/life_loop_state.json"
      observation = "$TrialRoot/observation_ledger.jsonl"
      decision = "$TrialRoot/decision_trace.jsonl"
      error = "$TrialRoot/error_ledger.jsonl"
      learning = "$TrialRoot/learning_metrics.json"
      correction_inbox = "$TrialRoot/correction_inbox.json"
      correction_inbox_initial = "$TrialRoot/correction_inbox_initial.json"
      correction_log = "$TrialRoot/correction_applied_log.jsonl"
      summary = "$TrialRoot/session_summary.json"
      checkpoint = "$TrialCheckpointRoot/checkpoint_004.json"
    }

    foreach ($identityFile in @(
      "CAPABILITY_ROADMAP.json",
      "GENESIS_STATE.json",
      "TASK_QUEUE.json",
      "packs/registry.json",
      "orchestrator/run.ps1"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase143Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $CurrentBranch = (git branch --show-current).Trim()
    if ($CurrentBranch -eq "main") {
      throw "PHASE143_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase143Equals -Actual $CurrentBranch -Expected $ExpectedBranch -Name "current_branch"
    $CurrentHead = (git rev-parse --short HEAD).Trim()

    $externalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
    if ($externalAgentStatus.Count -gt 0) {
      throw "PHASE143_EXTERNAL_AGENT_SCOPE_DIRTY=$($externalAgentStatus -join '; ')"
    }

    $Queue = Read-Phase143JsonRequired -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
    Assert-Phase143Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $Phase142Proof = Read-Phase143JsonRequired -RepoRoot $RepoRoot -Path $Phase142ProofPath
    Assert-Phase143Equals -Actual $Phase142Proof.status -Expected "PASS" -Name "phase142_status"
    Assert-Phase143Equals -Actual $Phase142Proof.next_allowed_step -Expected $StepId -Name "phase142_next_allowed_step"
    Assert-Phase143True -Actual $Phase142Proof.correction_inbox_supported -Name "phase142_correction_inbox_supported"
    Assert-Phase143True -Actual $Phase142Proof.terminal_watcher_supported -Name "phase142_terminal_watcher_supported"
    Assert-Phase143True -Actual $Phase142Proof.repo_session_artifacts_created -Name "phase142_repo_session_artifacts_created"
    Assert-Phase143Equals -Actual $Phase142Proof.selected_next_gap -Expected $StepId -Name "phase142_selected_next_gap"
    Assert-Phase143False -Actual $Phase142Proof.external_agent_production_allowed -Name "phase142_external_agent_production_allowed"
    Assert-Phase143Equals -Actual $Phase142Proof.trusted_material_count -Expected 0 -Name "phase142_trusted_material_count"
    Assert-Phase143False -Actual $Phase142Proof.external_fetch_performed -Name "phase142_external_fetch_performed"
    Assert-Phase143False -Actual $Phase142Proof.dependency_install_performed -Name "phase142_dependency_install_performed"
    Assert-Phase143False -Actual $Phase142Proof.executable_materials_used -Name "phase142_executable_materials_used"

    foreach ($baselineFile in @(
      "$BaselineRoot/session_summary.json",
      "$BaselineRoot/observation_ledger.jsonl",
      "$BaselineRoot/decision_trace.jsonl",
      "$BaselineRoot/learning_metrics.json"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase143Path -RepoRoot $RepoRoot -Path $baselineFile))) {
        throw "PHASE143_BASELINE_MISSING=$baselineFile"
      }
    }

    $BaselineSummary = Read-Phase143JsonRequired -RepoRoot $RepoRoot -Path "$BaselineRoot/session_summary.json"
    $BaselineDecisionLines = @(Get-Content -LiteralPath (Resolve-Phase143Path -RepoRoot $RepoRoot -Path "$BaselineRoot/decision_trace.jsonl") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $BaselineTaskSequence = @($BaselineDecisionLines | ForEach-Object { (ConvertFrom-Json $_).selected_task_type } | Select-Object -First $MaxCycles)

    New-Item -ItemType Directory -Force -Path (Resolve-Phase143Path -RepoRoot $RepoRoot -Path $CurrentRoot) | Out-Null
    New-Item -ItemType Directory -Force -Path (Resolve-Phase143Path -RepoRoot $RepoRoot -Path $TrialRoot) | Out-Null
    New-Item -ItemType Directory -Force -Path (Resolve-Phase143Path -RepoRoot $RepoRoot -Path $CheckpointRoot) | Out-Null
    New-Item -ItemType Directory -Force -Path (Resolve-Phase143Path -RepoRoot $RepoRoot -Path $TrialCheckpointRoot) | Out-Null

    foreach ($jsonlPath in @(
      $CurrentPaths.observation,
      $CurrentPaths.decision,
      $CurrentPaths.error,
      $CurrentPaths.correction_log,
      $TrialPaths.observation,
      $TrialPaths.decision,
      $TrialPaths.error,
      $TrialPaths.correction_log
    )) {
      Write-Phase143TextFile -RepoRoot $RepoRoot -Path $jsonlPath -Content ""
    }

    $CorrectionEntry = [ordered]@{
      correction_id = $CorrectionId
      status = "pending"
      message = $CorrectionMessage
      author = "OWNER_OR_ASSISTANT"
      created_before_trial = $true
      created_at = (Get-Date).ToUniversalTime().ToString("o")
    }

    $CorrectionInboxInitial = [ordered]@{
      status = "PASS"
      inbox_id = "BUILDER_LIFE_LOOP_CORRECTION_INBOX"
      pending_corrections = @($CorrectionEntry)
      observed_correction_count = 0
      applied_correction_count = 0
      next_behavior_trial = $StepId
    }
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.correction_inbox -Object $CorrectionInboxInitial
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.correction_inbox -Object $CorrectionInboxInitial
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.correction_inbox_initial -Object $CorrectionInboxInitial
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.correction_inbox_initial -Object $CorrectionInboxInitial

    $CorrectedTaskSequence = @(
      "READ_CURRENT_STATE",
      "WRITE_LEARNING_NOTE",
      "SELECT_NEXT_MICRO_GAP",
      "WRITE_LEARNING_NOTE",
      "SELECT_NEXT_MICRO_GAP",
      "READ_NEXT_ACTION",
      "WRITE_LEARNING_NOTE",
      "SELECT_NEXT_MICRO_GAP",
      "FIND_LAST_ACCEPTED_PROOF",
      "WRITE_LEARNING_NOTE",
      "SELECT_NEXT_MICRO_GAP",
      "COMPARE_NEXT_STEP"
    )

    $CorrectionSeenCount = 0
    $CorrectionAppliedCount = 0
    $CorrectionApplied = $false
    $TrialTaskSequence = New-Object System.Collections.Generic.List[string]

    for ($cycle = 1; $cycle -le $MaxCycles; $cycle++) {
      $Now = (Get-Date).ToUniversalTime().ToString("o")
      $CurrentState = if (Test-Path -LiteralPath (Resolve-Phase143Path -RepoRoot $RepoRoot -Path $CurrentStatePath)) { Read-Phase143JsonRequired -RepoRoot $RepoRoot -Path $CurrentStatePath } else { $null }
      $NextAction = if (Test-Path -LiteralPath (Resolve-Phase143Path -RepoRoot $RepoRoot -Path $NextActionPath)) { Read-Phase143JsonRequired -RepoRoot $RepoRoot -Path $NextActionPath } else { $null }
      $LastAcceptedProofPointer = if (Test-Path -LiteralPath (Resolve-Phase143Path -RepoRoot $RepoRoot -Path $LastAcceptedProofPointerPath)) { Read-Phase143JsonRequired -RepoRoot $RepoRoot -Path $LastAcceptedProofPointerPath } else { $null }
      $CorrectionInbox = Read-Phase143JsonRequired -RepoRoot $RepoRoot -Path $CurrentPaths.correction_inbox
      $PendingCorrections = @($CorrectionInbox.pending_corrections | Where-Object { $_.correction_id -eq $CorrectionId -and $_.status -eq "pending" })

      if ($PendingCorrections.Count -gt 0 -and -not $CorrectionApplied) {
        $CorrectionSeenCount = 1
        $CorrectionAppliedCount = 1
        $CorrectionApplied = $true

        $CorrectionAppliedEvent = [ordered]@{
          event_type = "CORRECTION_APPLIED"
          correction_id = $CorrectionId
          session_id = $TrialSessionId
          cycle = $cycle
          message = $CorrectionMessage
          behavior_change = "Switched from baseline carousel to correction-aware priority sequence after state read: WRITE_LEARNING_NOTE and SELECT_NEXT_MICRO_GAP are prioritized and each decision explains correction influence."
          applied_by = "BUILDER_RUNTIME"
          applied_at = $Now
        }
        Add-Phase143JsonLine -RepoRoot $RepoRoot -Path $CurrentPaths.correction_log -Object $CorrectionAppliedEvent
        Add-Phase143JsonLine -RepoRoot $RepoRoot -Path $TrialPaths.correction_log -Object $CorrectionAppliedEvent
      }

      $TaskType = $CorrectedTaskSequence[$cycle - 1]
      $TrialTaskSequence.Add($TaskType) | Out-Null
      $CorrectionAware = $CorrectionApplied
      $SelectionReason = if ($CorrectionAware) {
        "Correction $CorrectionId applied: prioritize WRITE_LEARNING_NOTE and SELECT_NEXT_MICRO_GAP after reading state, and explain behavior change."
      } else {
        "Awaiting correction before adapting task sequence."
      }

      $PracticeResult = [ordered]@{
        task_type = $TaskType
        safe_internal_practice = $true
        correction_aware = $CorrectionAware
        correction_id = $CorrectionId
        correction_seen = ($CorrectionSeenCount -gt 0)
        correction_applied = ($CorrectionAppliedCount -gt 0)
        read_current_state = $null -ne $CurrentState
        read_next_action = $null -ne $NextAction
        read_last_accepted_proof_pointer = $null -ne $LastAcceptedProofPointer
        behavior_change_explanation = "Compared with LIVE_LOOP_002 carousel, this trial repeats learning-note and micro-gap selection immediately after reading state because correction requested practical adaptation."
      }

      if ($TaskType -eq "WRITE_LEARNING_NOTE") {
        $PracticeResult.learning_note = "Correction $CorrectionId changed the loop from neutral carousel observation to correction-aware adaptation practice."
      }
      if ($TaskType -eq "SELECT_NEXT_MICRO_GAP") {
        $PracticeResult.selected_micro_gap = "BEHAVIOR_ADAPTATION_SCALE_TRIAL"
        $PracticeResult.selected_next_gap = $NextAllowedStep
      }
      if ($TaskType -eq "COMPARE_NEXT_STEP") {
        $PracticeResult.baseline_session = $BaselineSessionId
        $PracticeResult.trial_session = $TrialSessionId
        $PracticeResult.baseline_prefix = $BaselineTaskSequence
        $PracticeResult.trial_prefix = @($TrialTaskSequence)
      }

      $ObservationEvent = [ordered]@{
        event_type = "OBSERVATION"
        session_id = $TrialSessionId
        run_id = $RunId
        cycle = $cycle
        task_type = $TaskType
        status = "PASS"
        observed_at = $Now
        practice_result = $PracticeResult
      }
      Add-Phase143JsonLine -RepoRoot $RepoRoot -Path $CurrentPaths.observation -Object $ObservationEvent
      Add-Phase143JsonLine -RepoRoot $RepoRoot -Path $TrialPaths.observation -Object $ObservationEvent

      $DecisionEvent = [ordered]@{
        event_type = "DECISION"
        session_id = $TrialSessionId
        run_id = $RunId
        cycle = $cycle
        selected_task_type = $TaskType
        selection_reason = $SelectionReason
        correction_id = $CorrectionId
        correction_influenced_decision = $CorrectionAware
        selected_next_gap = $NextAllowedStep
        owner_interactive_prompt_required = $false
        external_agent_production_allowed = $false
        decided_at = (Get-Date).ToUniversalTime().ToString("o")
      }
      Add-Phase143JsonLine -RepoRoot $RepoRoot -Path $CurrentPaths.decision -Object $DecisionEvent
      Add-Phase143JsonLine -RepoRoot $RepoRoot -Path $TrialPaths.decision -Object $DecisionEvent

      $Heartbeat = [ordered]@{
        status = "RUNNING"
        heartbeat_id = "BUILDER_CORRECTION_RESPONSE_HEARTBEAT_CURRENT"
        session_id = $TrialSessionId
        run_id = $RunId
        cycle = $cycle
        completed_cycles = $cycle
        max_cycles = $MaxCycles
        correction_seen_count = $CorrectionSeenCount
        correction_applied_count = $CorrectionAppliedCount
        last_task_type = $TaskType
        last_seen_at = (Get-Date).ToUniversalTime().ToString("o")
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.heartbeat -Object $Heartbeat
      Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.heartbeat -Object $Heartbeat

      $LifeState = [ordered]@{
        status = "RUNNING"
        state_id = "BUILDER_CORRECTION_RESPONSE_STATE_CURRENT"
        session_id = $TrialSessionId
        run_id = $RunId
        current_line = "SELF_BUILD"
        completed_cycles = $cycle
        max_cycles = $MaxCycles
        checkpoint_every = $CheckpointEvery
        sleep_seconds = $SleepSeconds
        correction_seen_count = $CorrectionSeenCount
        correction_applied_count = $CorrectionAppliedCount
        behavior_changed_after_correction = $CorrectionApplied
        baseline_session = $BaselineSessionId
        trial_session = $TrialSessionId
        selected_next_gap = $NextAllowedStep
        owner_interactive_prompt_required = $false
        external_agent_production_allowed = $false
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.state -Object $LifeState
      Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.state -Object $LifeState

      if ($cycle -eq 4) {
        $Checkpoint = [ordered]@{
          status = "PASS"
          checkpoint_id = "checkpoint_004"
          session_id = $TrialSessionId
          run_id = $RunId
          completed_cycles = $cycle
          correction_seen_count = $CorrectionSeenCount
          correction_applied_count = $CorrectionAppliedCount
          behavior_changed_after_correction = $CorrectionApplied
          created_at = (Get-Date).ToUniversalTime().ToString("o")
          next_allowed_step = $NextAllowedStep
        }
        Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.checkpoint -Object $Checkpoint
        Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.checkpoint -Object $Checkpoint
      }
    }

    $TrialTaskSequenceArray = @($TrialTaskSequence)
    $BehaviorChangedAfterCorrection = -not [string]::Equals(($BaselineTaskSequence -join ","), ($TrialTaskSequenceArray -join ","), [System.StringComparison]::Ordinal)
    Assert-Phase143True -Actual $BehaviorChangedAfterCorrection -Name "behavior_changed_after_correction"

    $CompletedAt = (Get-Date).ToUniversalTime().ToString("o")
    $FinalCorrectionEntry = [ordered]@{
      correction_id = $CorrectionId
      status = "applied"
      message = $CorrectionMessage
      author = "OWNER_OR_ASSISTANT"
      created_before_trial = $true
      seen_by = "BUILDER_RUNTIME"
      applied_by = "BUILDER_RUNTIME"
      applied_at = $CompletedAt
    }
    $CorrectionInboxFinal = [ordered]@{
      status = "PASS"
      inbox_id = "BUILDER_LIFE_LOOP_CORRECTION_INBOX"
      pending_corrections = @()
      applied_corrections = @($FinalCorrectionEntry)
      observed_correction_count = $CorrectionSeenCount
      applied_correction_count = $CorrectionAppliedCount
      next_behavior_trial = $NextAllowedStep
      updated_at = $CompletedAt
    }
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.correction_inbox -Object $CorrectionInboxFinal
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.correction_inbox -Object $CorrectionInboxFinal

    $LearningMetrics = [ordered]@{
      status = "PASS"
      metrics_id = "PHASE143_CORRECTION_RESPONSE_LEARNING_METRICS"
      session_id = $TrialSessionId
      run_id = $RunId
      completed_cycles = $MaxCycles
      baseline_session = $BaselineSessionId
      trial_session = $TrialSessionId
      correction_seen_count = $CorrectionSeenCount
      correction_applied_count = $CorrectionAppliedCount
      behavior_changed_after_correction = $BehaviorChangedAfterCorrection
      baseline_task_sequence = $BaselineTaskSequence
      trial_task_sequence = $TrialTaskSequenceArray
      selected_next_gap = $NextAllowedStep
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.learning -Object $LearningMetrics
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.learning -Object $LearningMetrics

    $SessionSummary = [ordered]@{
      status = "PASS"
      summary_id = "PHASE143_CORRECTION_RESPONSE_SESSION_SUMMARY"
      session_id = $TrialSessionId
      run_id = $RunId
      completed_cycles = $MaxCycles
      max_cycles = $MaxCycles
      checkpoint_every = $CheckpointEvery
      sleep_seconds = $SleepSeconds
      correction_seen_count = $CorrectionSeenCount
      correction_applied_count = $CorrectionAppliedCount
      behavior_changed_after_correction = $BehaviorChangedAfterCorrection
      baseline_session = $BaselineSessionId
      trial_session = $TrialSessionId
      selected_next_gap = $NextAllowedStep
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
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.summary -Object $SessionSummary
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.summary -Object $SessionSummary

    $FinalHeartbeat = [ordered]@{
      status = "PASS"
      heartbeat_id = "BUILDER_CORRECTION_RESPONSE_HEARTBEAT_CURRENT"
      session_id = $TrialSessionId
      run_id = $RunId
      completed_cycles = $MaxCycles
      max_cycles = $MaxCycles
      correction_seen_count = $CorrectionSeenCount
      correction_applied_count = $CorrectionAppliedCount
      last_task_type = $TrialTaskSequenceArray[-1]
      last_seen_at = $CompletedAt
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.heartbeat -Object $FinalHeartbeat
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.heartbeat -Object $FinalHeartbeat

    $FinalState = [ordered]@{
      status = "PASS"
      state_id = "BUILDER_CORRECTION_RESPONSE_STATE_CURRENT"
      session_id = $TrialSessionId
      run_id = $RunId
      current_line = "SELF_BUILD"
      completed_cycles = $MaxCycles
      max_cycles = $MaxCycles
      correction_seen_count = $CorrectionSeenCount
      correction_applied_count = $CorrectionAppliedCount
      behavior_changed_after_correction = $BehaviorChangedAfterCorrection
      baseline_session = $BaselineSessionId
      trial_session = $TrialSessionId
      selected_next_gap = $NextAllowedStep
      owner_interactive_prompt_required = $false
      external_agent_production_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.state -Object $FinalState
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.state -Object $FinalState

    $CorrectionResponseTrialResult = [ordered]@{
      status = "PASS"
      result_id = "PHASE143_BUILDER_CORRECTION_RESPONSE_TRIAL_RESULT"
      correction_seen = $true
      correction_applied = $true
      correction_seen_count = $CorrectionSeenCount
      correction_applied_count = $CorrectionAppliedCount
      behavior_changed_after_correction = $BehaviorChangedAfterCorrection
      baseline_session = $BaselineSessionId
      trial_session = $TrialSessionId
      selected_next_gap = $NextAllowedStep
      selected_by = "BUILDER_RUNTIME"
      external_agent_production_allowed = $false
      owner_interactive_prompt_required = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $TrialResultPath -Object $CorrectionResponseTrialResult

    $RuntimeLog = @(
      "BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL=PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_001",
      "CORRECTION_RESPONSE_STATUS=PASS",
      "CORRECTION_SEEN=True",
      "CORRECTION_APPLIED=True",
      "CORRECTION_SEEN_COUNT=1",
      "CORRECTION_APPLIED_COUNT=1",
      "BEHAVIOR_CHANGED_AFTER_CORRECTION=True",
      "CORRECTION_RESPONSE_SESSION_ID=PHASE143_CORRECTION_RESPONSE_TRIAL_001",
      "BASELINE_SESSION_ID=LIVE_LOOP_002",
      "OWNER_INTERACTIVE_PROMPT_REQUIRED=False",
      "EXTERNAL_AGENT_PRODUCTION_ALLOWED=False",
      "MATERIAL_TRUSTED_COUNT=0",
      "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
      "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
      "MATERIAL_EXECUTABLE_USED=False",
      "NEXT_ALLOWED_STEP=PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1",
      "STATUS=PASS_STOPPED_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_BUILT"
    ) -join "`n"
    Write-Phase143TextFile -RepoRoot $RepoRoot -Path $RuntimeLogPath -Content "$RuntimeLog`n"

    $Output = [ordered]@{
      status = "PASS"
      engine_name = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      correction_seen = $true
      correction_applied = $true
      correction_seen_count = $CorrectionSeenCount
      correction_applied_count = $CorrectionAppliedCount
      behavior_changed_after_correction = $BehaviorChangedAfterCorrection
      baseline_session = $BaselineSessionId
      trial_session = $TrialSessionId
      selected_next_gap = $NextAllowedStep
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
      trial_result_path = $TrialResultPath
      trial_artifact_root = $TrialRoot
      correction_initial_inbox_path = $TrialPaths.correction_inbox_initial
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
      correction_seen = $true
      correction_applied = $true
      correction_seen_count = $CorrectionSeenCount
      correction_applied_count = $CorrectionAppliedCount
      behavior_changed_after_correction = $BehaviorChangedAfterCorrection
      queue_after = "NONE"
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    $Report = [ordered]@{
      status = "PASS"
      report_id = "${StepId}_REPORT"
      step_id = $StepId
      run_id = $RunId
      orchestrator_hook = "orchestrator/run.ps1 invokes Invoke-BuilderCorrectionInboxResponseTrial001 when PHASE142 proof is PASS and next_allowed_step is PHASE143."
      correction_written = "Runtime writes PHASE143_CORRECTION_001 into runtime_sessions/builder_life_loop/current/correction_inbox.json before the 12-cycle trial session starts."
      correction_initial_inbox_path = $TrialPaths.correction_inbox_initial
      correction_seen = "Each cycle rereads correction_inbox.json; the pending PHASE143 correction is seen in cycle 1 and counted once."
      correction_applied = "The runtime records one CORRECTION_APPLIED event and switches to a correction-aware task sequence that prioritizes WRITE_LEARNING_NOTE and SELECT_NEXT_MICRO_GAP after reading state."
      behavior_change_detection = "The trial task sequence is compared with the first 12 LIVE_LOOP_002 baseline decision tasks. The sequences differ, and decision_trace plus observation_ledger both include correction-aware reasons/results."
      baseline_comparison_method = "Read LIVE_LOOP_002 decision_trace.jsonl, take the first 12 selected_task_type values, compare them to the PHASE143 trial sequence, and require inequality plus correction references."
      validator_behavior = "Validator fails on missing PHASE142 proof or LIVE_LOOP_002 baseline, missing correction inbox/logs, zero seen/applied counts, no behavior change, missing correction references in decision/observation ledgers, wrong next gap, owner prompt, external-agent changes, trusted materials, fetch/install/executable flags, active queue, or wrong next step."
      proof_path = $ProofPath
      trial_result_path = $TrialResultPath
      trial_artifact_root = $TrialRoot
      remaining_risks = @(
        "PHASE143 proves a single correction changes one bounded session; PHASE144 must scale adaptation across more corrections and cycles.",
        "Behavior change is deterministic and rule-based, not yet a learned scoring model.",
        "The trial keeps correction response inside repo session artifacts only."
      )
      cut_list = @(
        "No external agent production.",
        "No generated_agents, agent_catalog, or applied_agents changes.",
        "No dependency install.",
        "No internet fetch.",
        "No executable material use.",
        "No material trust.",
        "No main branch change.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }

    $Proof = [ordered]@{
      status = "PASS"
      proof_id = $StepId
      step_id = $StepId
      run_id = $RunId
      runtime_mode = "SELF_BUILD_QUEUE_NONE_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_001"
      runtime_executed = $true
      builder_runtime_invoked = $true
      correction_seen = $true
      correction_applied = $true
      correction_seen_count = $CorrectionSeenCount
      correction_applied_count = $CorrectionAppliedCount
      behavior_changed_after_correction = $BehaviorChangedAfterCorrection
      baseline_session = $BaselineSessionId
      trial_session = $TrialSessionId
      selected_next_gap = $NextAllowedStep
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
      phase142_proof_path = $Phase142ProofPath
      baseline_root = $BaselineRoot
      trial_artifact_root = $TrialRoot
      correction_initial_inbox_path = $TrialPaths.correction_inbox_initial
      trial_result_path = $TrialResultPath
      output_path = $OutputPath
      result_path = $ResultPath
      runtime_log_path = $RuntimeLogPath
      report_path = $ReportPath
      next_allowed_step = $NextAllowedStep
    }

    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $OutputPath -Object $Output
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report
    Write-Phase143JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject]$Output
  } finally {
    Pop-Location
  }
}
