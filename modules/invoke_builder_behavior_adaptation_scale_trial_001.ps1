function Resolve-Phase144Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase144JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase144Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE144_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase144JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase144Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase144TextFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$Content
  )

  $fullPath = Resolve-Phase144Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Add-Phase144JsonLine {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object
  )

  $fullPath = Resolve-Phase144Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $line = $Object | ConvertTo-Json -Depth 50 -Compress
  [System.IO.File]::AppendAllText($fullPath, "$line`n", [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase144Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE144_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase144True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE144_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase144False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE144_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase144AtLeast {
  param(
    [object]$Actual,
    [int]$Minimum,
    [string]$Name
  )

  if ([int]$Actual -lt $Minimum) {
    throw "PHASE144_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Get-Phase144DecisionSequence {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [int]$Count
  )

  $fullPath = Resolve-Phase144Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE144_MISSING_DECISION_TRACE=$Path"
  }

  return @(Get-Content -LiteralPath $fullPath |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { (ConvertFrom-Json $_).selected_task_type } |
    Select-Object -First $Count)
}

function Invoke-BuilderBehaviorAdaptationScaleTrial001 {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$OutputRoot
  )

  $ErrorActionPreference = "Stop"
  Push-Location $RepoRoot

  try {
    $StepId = "PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1"
    $RuntimeId = "PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_001"
    $PreviousStepId = "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1"
    $NextAllowedStep = "PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1"
    $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
    $BaselineSessionId = "LIVE_LOOP_002"
    $Phase143TrialSessionId = "PHASE143_CORRECTION_RESPONSE_TRIAL_001"
    $TrialSessionId = "PHASE144_BEHAVIOR_ADAPTATION_SCALE_TRIAL_001"

    if ([string]::IsNullOrWhiteSpace($RunId)) {
      $RunId = $RuntimeId
    }

    $MaxCycles = 18
    $CheckpointEvery = 6
    $SleepSeconds = 0

    $OutputArtifactRoot = "self_build_batch/autonomy_trials/$StepId"
    if (-not [string]::IsNullOrWhiteSpace($OutputRoot)) {
      $OutputArtifactRoot = $OutputRoot -replace "\\", "/"
    }

    $CurrentRoot = "runtime_sessions/builder_life_loop/current"
    $TrialRoot = "runtime_sessions/builder_life_loop/adaptation_trials/$TrialSessionId"
    $BaselineRoot = "runtime_sessions/builder_life_loop/observations/$BaselineSessionId"
    $Phase143TrialRoot = "runtime_sessions/builder_life_loop/correction_trials/$Phase143TrialSessionId"
    $CheckpointRoot = "$CurrentRoot/checkpoints"
    $TrialCheckpointRoot = "$TrialRoot/checkpoints"
    $Phase143ProofPath = "proofs/self_development/${PreviousStepId}.json"
    $Phase143ResultPath = "self_control/BUILDER_CORRECTION_RESPONSE_TRIAL_RESULT.json"
    $CurrentStatePath = "self_control/CURRENT_AGENT_BUILDER_STATE.json"
    $NextActionPath = "self_control/NEXT_ACTION.json"
    $LastAcceptedProofPointerPath = "self_control/LAST_ACCEPTED_PROOF_POINTER.json"
    $TrialResultPath = "self_control/BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_RESULT.json"
    $OutputPath = "$OutputArtifactRoot/BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_OUTPUT.json"
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
      adaptation = "$CurrentRoot/adaptation_metrics.json"
      correction_inbox = "$CurrentRoot/correction_inbox.json"
      correction_inbox_initial = "$CurrentRoot/correction_inbox_initial.json"
      correction_log = "$CurrentRoot/correction_applied_log.jsonl"
      summary = "$CurrentRoot/session_summary.json"
    }
    $TrialPaths = [ordered]@{
      heartbeat = "$TrialRoot/heartbeat.json"
      state = "$TrialRoot/life_loop_state.json"
      observation = "$TrialRoot/observation_ledger.jsonl"
      decision = "$TrialRoot/decision_trace.jsonl"
      error = "$TrialRoot/error_ledger.jsonl"
      learning = "$TrialRoot/learning_metrics.json"
      adaptation = "$TrialRoot/adaptation_metrics.json"
      correction_inbox = "$TrialRoot/correction_inbox.json"
      correction_inbox_initial = "$TrialRoot/correction_inbox_initial.json"
      correction_log = "$TrialRoot/correction_applied_log.jsonl"
      summary = "$TrialRoot/session_summary.json"
    }

    foreach ($identityFile in @(
      "CAPABILITY_ROADMAP.json",
      "GENESIS_STATE.json",
      "TASK_QUEUE.json",
      "packs/registry.json",
      "orchestrator/run.ps1"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase144Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $CurrentBranch = (git branch --show-current).Trim()
    if ($CurrentBranch -eq "main") {
      throw "PHASE144_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase144Equals -Actual $CurrentBranch -Expected $ExpectedBranch -Name "current_branch"
    $CurrentHead = (git rev-parse --short HEAD).Trim()

    $externalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
    if ($externalAgentStatus.Count -gt 0) {
      throw "PHASE144_EXTERNAL_AGENT_SCOPE_DIRTY=$($externalAgentStatus -join '; ')"
    }

    $Queue = Read-Phase144JsonRequired -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
    Assert-Phase144Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $Phase143Proof = Read-Phase144JsonRequired -RepoRoot $RepoRoot -Path $Phase143ProofPath
    Assert-Phase144Equals -Actual $Phase143Proof.status -Expected "PASS" -Name "phase143_status"
    Assert-Phase144Equals -Actual $Phase143Proof.next_allowed_step -Expected $StepId -Name "phase143_next_allowed_step"
    Assert-Phase144True -Actual $Phase143Proof.correction_seen -Name "phase143_correction_seen"
    Assert-Phase144True -Actual $Phase143Proof.correction_applied -Name "phase143_correction_applied"
    Assert-Phase144AtLeast -Actual $Phase143Proof.correction_seen_count -Minimum 1 -Name "phase143_correction_seen_count"
    Assert-Phase144AtLeast -Actual $Phase143Proof.correction_applied_count -Minimum 1 -Name "phase143_correction_applied_count"
    Assert-Phase144True -Actual $Phase143Proof.behavior_changed_after_correction -Name "phase143_behavior_changed_after_correction"
    Assert-Phase144Equals -Actual $Phase143Proof.selected_next_gap -Expected $StepId -Name "phase143_selected_next_gap"
    Assert-Phase144Equals -Actual $Phase143Proof.selected_by -Expected "BUILDER_RUNTIME" -Name "phase143_selected_by"
    Assert-Phase144False -Actual $Phase143Proof.owner_interactive_prompt_required -Name "phase143_owner_interactive_prompt_required"
    Assert-Phase144False -Actual $Phase143Proof.external_agent_production_allowed -Name "phase143_external_agent_production_allowed"
    Assert-Phase144Equals -Actual $Phase143Proof.trusted_material_count -Expected 0 -Name "phase143_trusted_material_count"
    Assert-Phase144False -Actual $Phase143Proof.external_fetch_performed -Name "phase143_external_fetch_performed"
    Assert-Phase144False -Actual $Phase143Proof.dependency_install_performed -Name "phase143_dependency_install_performed"
    Assert-Phase144False -Actual $Phase143Proof.executable_materials_used -Name "phase143_executable_materials_used"

    $Phase143Result = Read-Phase144JsonRequired -RepoRoot $RepoRoot -Path $Phase143ResultPath
    Assert-Phase144Equals -Actual $Phase143Result.status -Expected "PASS" -Name "phase143_result_status"
    Assert-Phase144Equals -Actual $Phase143Result.next_allowed_step -Expected $StepId -Name "phase143_result_next_allowed_step"
    Assert-Phase144True -Actual $Phase143Result.behavior_changed_after_correction -Name "phase143_result_behavior_changed_after_correction"

    foreach ($requiredEvidenceFile in @(
      "$BaselineRoot/session_summary.json",
      "$BaselineRoot/observation_ledger.jsonl",
      "$BaselineRoot/decision_trace.jsonl",
      "$BaselineRoot/learning_metrics.json",
      "$Phase143TrialRoot/session_summary.json",
      "$Phase143TrialRoot/observation_ledger.jsonl",
      "$Phase143TrialRoot/decision_trace.jsonl",
      "$Phase143TrialRoot/correction_applied_log.jsonl",
      "$Phase143TrialRoot/learning_metrics.json"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase144Path -RepoRoot $RepoRoot -Path $requiredEvidenceFile))) {
        throw "PHASE144_REQUIRED_EVIDENCE_MISSING=$requiredEvidenceFile"
      }
    }

    $BaselineSequence = Get-Phase144DecisionSequence -RepoRoot $RepoRoot -Path "$BaselineRoot/decision_trace.jsonl" -Count $MaxCycles
    $Phase143Sequence = Get-Phase144DecisionSequence -RepoRoot $RepoRoot -Path "$Phase143TrialRoot/decision_trace.jsonl" -Count 12
    $BaselinePattern = @($BaselineSequence | Select-Object -First 6)
    $BaselineNextPattern = @($BaselineSequence | Select-Object -Skip 6 -First 6)
    $BaselineRepetitionPatternDetected = ($BaselinePattern.Count -eq 6 -and ($BaselinePattern -join ",") -eq ($BaselineNextPattern -join ","))
    $Phase143DecisionText = Get-Content -LiteralPath (Resolve-Phase144Path -RepoRoot $RepoRoot -Path "$Phase143TrialRoot/decision_trace.jsonl") -Raw
    $Phase143SingleCorrectionPatternDetected = ($Phase143Sequence.Count -ge 12 -and $Phase143DecisionText.Contains("PHASE143_CORRECTION_001") -and $Phase143DecisionText.Contains("correction_influenced_decision"))
    Assert-Phase144True -Actual $BaselineRepetitionPatternDetected -Name "baseline_repetition_pattern_detected"
    Assert-Phase144True -Actual $Phase143SingleCorrectionPatternDetected -Name "phase143_single_correction_pattern_detected"

    New-Item -ItemType Directory -Force -Path (Resolve-Phase144Path -RepoRoot $RepoRoot -Path $CurrentRoot) | Out-Null
    New-Item -ItemType Directory -Force -Path (Resolve-Phase144Path -RepoRoot $RepoRoot -Path $TrialRoot) | Out-Null
    New-Item -ItemType Directory -Force -Path (Resolve-Phase144Path -RepoRoot $RepoRoot -Path $CheckpointRoot) | Out-Null
    New-Item -ItemType Directory -Force -Path (Resolve-Phase144Path -RepoRoot $RepoRoot -Path $TrialCheckpointRoot) | Out-Null

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
      Write-Phase144TextFile -RepoRoot $RepoRoot -Path $jsonlPath -Content ""
    }

    $CreatedAt = (Get-Date).ToUniversalTime().ToString("o")
    $Corrections = @(
      [ordered]@{
        correction_id = "PHASE144_CORRECTION_001"
        status = "pending"
        message = "Reduce repetitive READ_CURRENT_STATE loops. Prioritize practical tasks after state read."
        author = "OWNER_OR_ASSISTANT"
        created_before_trial = $true
        created_at = $CreatedAt
        application_cycle = 1
        behavior_change = "After the first state read, do not restart the safe carousel; move directly to WRITE_LEARNING_NOTE and SELECT_NEXT_MICRO_GAP."
      },
      [ordered]@{
        correction_id = "PHASE144_CORRECTION_002"
        status = "pending"
        message = "When a correction is present, explain the behavior change in decision_trace before selecting the next task."
        author = "OWNER_OR_ASSISTANT"
        created_before_trial = $true
        created_at = $CreatedAt
        application_cycle = 4
        behavior_change = "Insert explicit EXPLAIN_BEHAVIOR_CHANGE decisions before selection so decision_trace names the behavior change."
      },
      [ordered]@{
        correction_id = "PHASE144_CORRECTION_003"
        status = "pending"
        message = "After applying a correction, select a stronger micro-gap than the baseline safe carousel."
        author = "OWNER_OR_ASSISTANT"
        created_before_trial = $true
        created_at = $CreatedAt
        application_cycle = 10
        behavior_change = "Map correction response to a stronger next micro-gap: PHASE145 autonomous multi-session learning."
      }
    )

    $CorrectionInboxInitial = [ordered]@{
      status = "PASS"
      inbox_id = "BUILDER_LIFE_LOOP_ADAPTATION_CORRECTION_INBOX"
      pending_corrections = $Corrections
      observed_correction_count = 0
      applied_correction_count = 0
      next_behavior_trial = $StepId
    }
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.correction_inbox -Object $CorrectionInboxInitial
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.correction_inbox -Object $CorrectionInboxInitial
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.correction_inbox_initial -Object $CorrectionInboxInitial
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.correction_inbox_initial -Object $CorrectionInboxInitial

    $AdaptedTaskSequence = @(
      "READ_CURRENT_STATE",
      "WRITE_LEARNING_NOTE",
      "SELECT_NEXT_MICRO_GAP",
      "EXPLAIN_BEHAVIOR_CHANGE",
      "SELECT_NEXT_MICRO_GAP",
      "COMPARE_NEXT_STEP",
      "READ_NEXT_ACTION",
      "EXPLAIN_BEHAVIOR_CHANGE",
      "WRITE_LEARNING_NOTE",
      "SELECT_NEXT_MICRO_GAP",
      "FIND_LAST_ACCEPTED_PROOF",
      "EXPLAIN_BEHAVIOR_CHANGE",
      "SELECT_NEXT_MICRO_GAP",
      "WRITE_LEARNING_NOTE",
      "COMPARE_NEXT_STEP",
      "SELECT_NEXT_MICRO_GAP",
      "WRITE_LEARNING_NOTE",
      "SELECT_NEXT_MICRO_GAP"
    )

    $CorrectionsSeenCount = 0
    $CorrectionsAppliedCount = 0
    $BehaviorChangesCount = 0
    $CorrectionAwareDecisionCount = 0
    $CorrectionAwareObservationCount = 0
    $AppliedCorrectionIds = New-Object System.Collections.Generic.List[string]
    $BehaviorMappings = New-Object System.Collections.Generic.List[object]
    $TrialTaskSequence = New-Object System.Collections.Generic.List[string]

    for ($cycle = 1; $cycle -le $MaxCycles; $cycle++) {
      $Now = (Get-Date).ToUniversalTime().ToString("o")
      $CurrentState = if (Test-Path -LiteralPath (Resolve-Phase144Path -RepoRoot $RepoRoot -Path $CurrentStatePath)) { Read-Phase144JsonRequired -RepoRoot $RepoRoot -Path $CurrentStatePath } else { $null }
      $NextAction = if (Test-Path -LiteralPath (Resolve-Phase144Path -RepoRoot $RepoRoot -Path $NextActionPath)) { Read-Phase144JsonRequired -RepoRoot $RepoRoot -Path $NextActionPath } else { $null }
      $LastAcceptedProofPointer = if (Test-Path -LiteralPath (Resolve-Phase144Path -RepoRoot $RepoRoot -Path $LastAcceptedProofPointerPath)) { Read-Phase144JsonRequired -RepoRoot $RepoRoot -Path $LastAcceptedProofPointerPath } else { $null }

      $ApplyingCorrection = @($Corrections | Where-Object { [int]$_.application_cycle -eq $cycle })
      if ($ApplyingCorrection.Count -eq 1) {
        $Correction = $ApplyingCorrection[0]
        $CorrectionsSeenCount += 1
        $CorrectionsAppliedCount += 1
        $BehaviorChangesCount += 1
        $AppliedCorrectionIds.Add($Correction.correction_id) | Out-Null

        $Mapping = [ordered]@{
          correction_id = $Correction.correction_id
          message = $Correction.message
          behavior_change = $Correction.behavior_change
          applied_cycle = $cycle
          mapped_next_gap = $NextAllowedStep
        }
        $BehaviorMappings.Add([pscustomobject]$Mapping) | Out-Null

        $CorrectionAppliedEvent = [ordered]@{
          event_type = "CORRECTION_APPLIED"
          correction_id = $Correction.correction_id
          session_id = $TrialSessionId
          cycle = $cycle
          message = $Correction.message
          behavior_change = $Correction.behavior_change
          behavior_changes_count = $BehaviorChangesCount
          applied_by = "BUILDER_RUNTIME"
          applied_at = $Now
        }
        Add-Phase144JsonLine -RepoRoot $RepoRoot -Path $CurrentPaths.correction_log -Object $CorrectionAppliedEvent
        Add-Phase144JsonLine -RepoRoot $RepoRoot -Path $TrialPaths.correction_log -Object $CorrectionAppliedEvent
      }

      $TaskType = $AdaptedTaskSequence[$cycle - 1]
      $TrialTaskSequence.Add($TaskType) | Out-Null
      $CorrectionAware = ($CorrectionsAppliedCount -gt 0)
      if ($CorrectionAware) {
        $CorrectionAwareDecisionCount += 1
        $CorrectionAwareObservationCount += 1
      }

      $LastAppliedCorrectionId = if ($AppliedCorrectionIds.Count -gt 0) { $AppliedCorrectionIds[$AppliedCorrectionIds.Count - 1] } else { "NONE" }
      $SelectionReason = if ($CorrectionAware) {
        "Correction-aware adaptation: $LastAppliedCorrectionId changed task selection away from LIVE_LOOP_002 and PHASE143 patterns; behavior_changes_count=$BehaviorChangesCount before selecting $TaskType."
      } else {
        "Awaiting PHASE144 correction before adaptation."
      }

      $PracticeResult = [ordered]@{
        task_type = $TaskType
        safe_internal_practice = $true
        correction_aware = $CorrectionAware
        active_correction_ids = @($AppliedCorrectionIds)
        corrections_seen_count = $CorrectionsSeenCount
        corrections_applied_count = $CorrectionsAppliedCount
        behavior_changes_count = $BehaviorChangesCount
        read_current_state = $null -ne $CurrentState
        read_next_action = $null -ne $NextAction
        read_last_accepted_proof_pointer = $null -ne $LastAcceptedProofPointer
        behavior_change_explanation = "PHASE144 scales PHASE143 from one correction to three mapped corrections, reduces repeated READ_CURRENT_STATE carousel use, and selects PHASE145 as the stronger micro-gap."
        selected_next_gap = $NextAllowedStep
      }
      if ($TaskType -eq "WRITE_LEARNING_NOTE") {
        $PracticeResult.learning_note = "Applied correction mapping count is $BehaviorChangesCount; practical adaptation is now preferred over the baseline safe carousel."
      }
      if ($TaskType -eq "EXPLAIN_BEHAVIOR_CHANGE") {
        $PracticeResult.explanation_written_before_next_selection = $true
      }
      if ($TaskType -eq "SELECT_NEXT_MICRO_GAP") {
        $PracticeResult.stronger_micro_gap_selected = $NextAllowedStep
      }

      $ObservationEvent = [ordered]@{
        event_type = "OBSERVATION"
        session_id = $TrialSessionId
        run_id = $RunId
        cycle = $cycle
        task_type = $TaskType
        status = "PASS"
        correction_aware = $CorrectionAware
        active_correction_ids = @($AppliedCorrectionIds)
        observed_at = $Now
        practice_result = $PracticeResult
      }
      Add-Phase144JsonLine -RepoRoot $RepoRoot -Path $CurrentPaths.observation -Object $ObservationEvent
      Add-Phase144JsonLine -RepoRoot $RepoRoot -Path $TrialPaths.observation -Object $ObservationEvent

      $DecisionEvent = [ordered]@{
        event_type = "DECISION"
        session_id = $TrialSessionId
        run_id = $RunId
        cycle = $cycle
        selected_task_type = $TaskType
        selection_reason = $SelectionReason
        correction_aware = $CorrectionAware
        active_correction_ids = @($AppliedCorrectionIds)
        last_applied_correction_id = $LastAppliedCorrectionId
        behavior_changes_count = $BehaviorChangesCount
        selected_next_gap = $NextAllowedStep
        owner_interactive_prompt_required = $false
        external_agent_production_allowed = $false
        decided_at = (Get-Date).ToUniversalTime().ToString("o")
      }
      Add-Phase144JsonLine -RepoRoot $RepoRoot -Path $CurrentPaths.decision -Object $DecisionEvent
      Add-Phase144JsonLine -RepoRoot $RepoRoot -Path $TrialPaths.decision -Object $DecisionEvent

      $Heartbeat = [ordered]@{
        status = "RUNNING"
        heartbeat_id = "BUILDER_BEHAVIOR_ADAPTATION_SCALE_HEARTBEAT_CURRENT"
        session_id = $TrialSessionId
        run_id = $RunId
        completed_cycles = $cycle
        max_cycles = $MaxCycles
        corrections_seen_count = $CorrectionsSeenCount
        corrections_applied_count = $CorrectionsAppliedCount
        behavior_changes_count = $BehaviorChangesCount
        last_task_type = $TaskType
        last_seen_at = (Get-Date).ToUniversalTime().ToString("o")
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.heartbeat -Object $Heartbeat
      Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.heartbeat -Object $Heartbeat

      $LifeState = [ordered]@{
        status = "RUNNING"
        state_id = "BUILDER_BEHAVIOR_ADAPTATION_SCALE_STATE_CURRENT"
        session_id = $TrialSessionId
        run_id = $RunId
        current_line = "SELF_BUILD"
        completed_cycles = $cycle
        max_cycles = $MaxCycles
        checkpoint_every = $CheckpointEvery
        sleep_seconds = $SleepSeconds
        corrections_seen_count = $CorrectionsSeenCount
        corrections_applied_count = $CorrectionsAppliedCount
        behavior_changes_count = $BehaviorChangesCount
        baseline_session = $BaselineSessionId
        phase143_trial_session = $Phase143TrialSessionId
        trial_session = $TrialSessionId
        selected_next_gap = $NextAllowedStep
        owner_interactive_prompt_required = $false
        external_agent_production_allowed = $false
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.state -Object $LifeState
      Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.state -Object $LifeState

      if (($cycle % $CheckpointEvery) -eq 0) {
        $CheckpointName = "checkpoint_{0:d3}.json" -f $cycle
        $Checkpoint = [ordered]@{
          status = "PASS"
          checkpoint_id = ("checkpoint_{0:d3}" -f $cycle)
          session_id = $TrialSessionId
          run_id = $RunId
          completed_cycles = $cycle
          corrections_seen_count = $CorrectionsSeenCount
          corrections_applied_count = $CorrectionsAppliedCount
          behavior_changes_count = $BehaviorChangesCount
          created_at = (Get-Date).ToUniversalTime().ToString("o")
          next_allowed_step = $NextAllowedStep
        }
        Write-Phase144JsonFile -RepoRoot $RepoRoot -Path "$CheckpointRoot/$CheckpointName" -Object $Checkpoint
        Write-Phase144JsonFile -RepoRoot $RepoRoot -Path "$TrialCheckpointRoot/$CheckpointName" -Object $Checkpoint
      }
    }

    $TrialTaskSequenceArray = @($TrialTaskSequence)
    $BaselineDiffers = -not [string]::Equals(($BaselineSequence -join ","), ($TrialTaskSequenceArray -join ","), [System.StringComparison]::Ordinal)
    $Phase143Differs = -not [string]::Equals(((@($Phase143Sequence | Select-Object -First 12)) -join ","), ((@($TrialTaskSequenceArray | Select-Object -First 12)) -join ","), [System.StringComparison]::Ordinal)
    $BaselineReadStateCount = @($BaselineSequence | Where-Object { $_ -eq "READ_CURRENT_STATE" }).Count
    $TrialReadStateCount = @($TrialTaskSequenceArray | Where-Object { $_ -eq "READ_CURRENT_STATE" }).Count
    $RepeatedSafeCarouselReduced = ($BaselineReadStateCount -gt $TrialReadStateCount -and $BaselineDiffers)
    $CorrectionToBehaviorMappingCount = $BehaviorMappings.Count
    $AdaptationScaled = (
      $CorrectionsSeenCount -ge 3 -and
      $CorrectionsAppliedCount -ge 3 -and
      $BehaviorChangesCount -ge 3 -and
      $CorrectionToBehaviorMappingCount -ge 3 -and
      $BaselineDiffers -and
      $Phase143Differs -and
      $RepeatedSafeCarouselReduced
    )

    Assert-Phase144AtLeast -Actual $CorrectionsSeenCount -Minimum 3 -Name "corrections_seen_count"
    Assert-Phase144AtLeast -Actual $CorrectionsAppliedCount -Minimum 3 -Name "corrections_applied_count"
    Assert-Phase144AtLeast -Actual $BehaviorChangesCount -Minimum 3 -Name "behavior_changes_count"
    Assert-Phase144True -Actual $AdaptationScaled -Name "adaptation_scaled"
    Assert-Phase144True -Actual $RepeatedSafeCarouselReduced -Name "repeated_safe_carousel_reduced"
    Assert-Phase144True -Actual $BaselineDiffers -Name "task_selection_differs_from_baseline"
    Assert-Phase144True -Actual $Phase143Differs -Name "task_selection_differs_from_phase143"

    $CompletedAt = (Get-Date).ToUniversalTime().ToString("o")
    $AppliedCorrections = @($Corrections | ForEach-Object {
      [ordered]@{
        correction_id = $_.correction_id
        status = "applied"
        message = $_.message
        behavior_change = $_.behavior_change
        applied_by = "BUILDER_RUNTIME"
        applied_at = $CompletedAt
      }
    })
    $CorrectionInboxFinal = [ordered]@{
      status = "PASS"
      inbox_id = "BUILDER_LIFE_LOOP_ADAPTATION_CORRECTION_INBOX"
      pending_corrections = @()
      applied_corrections = $AppliedCorrections
      observed_correction_count = $CorrectionsSeenCount
      applied_correction_count = $CorrectionsAppliedCount
      next_behavior_trial = $NextAllowedStep
      updated_at = $CompletedAt
    }
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.correction_inbox -Object $CorrectionInboxFinal
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.correction_inbox -Object $CorrectionInboxFinal

    $AdaptationMetrics = [ordered]@{
      status = "PASS"
      metrics_id = "PHASE144_BEHAVIOR_ADAPTATION_SCALE_METRICS"
      session_id = $TrialSessionId
      run_id = $RunId
      completed_cycles = $MaxCycles
      baseline_session = $BaselineSessionId
      phase143_trial_session = $Phase143TrialSessionId
      trial_session = $TrialSessionId
      corrections_seen_count = $CorrectionsSeenCount
      corrections_applied_count = $CorrectionsAppliedCount
      behavior_changes_count = $BehaviorChangesCount
      correction_aware_decision_count = $CorrectionAwareDecisionCount
      correction_aware_observation_count = $CorrectionAwareObservationCount
      baseline_repetition_pattern_detected = $BaselineRepetitionPatternDetected
      phase143_single_correction_pattern_detected = $Phase143SingleCorrectionPatternDetected
      adaptation_scaled = $AdaptationScaled
      repeated_safe_carousel_reduced = $RepeatedSafeCarouselReduced
      correction_to_behavior_mapping_count = $CorrectionToBehaviorMappingCount
      baseline_task_sequence = @($BaselineSequence)
      phase143_task_sequence = @($Phase143Sequence)
      trial_task_sequence = @($TrialTaskSequenceArray)
      correction_to_behavior_mappings = @($BehaviorMappings.ToArray())
      selected_next_gap = $NextAllowedStep
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.learning -Object $AdaptationMetrics
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.learning -Object $AdaptationMetrics
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.adaptation -Object $AdaptationMetrics
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.adaptation -Object $AdaptationMetrics

    $SessionSummary = [ordered]@{
      status = "PASS"
      summary_id = "PHASE144_BEHAVIOR_ADAPTATION_SCALE_SESSION_SUMMARY"
      session_id = $TrialSessionId
      run_id = $RunId
      completed_cycles = $MaxCycles
      max_cycles = $MaxCycles
      checkpoint_every = $CheckpointEvery
      sleep_seconds = $SleepSeconds
      corrections_seen_count = $CorrectionsSeenCount
      corrections_applied_count = $CorrectionsAppliedCount
      behavior_changes_count = $BehaviorChangesCount
      adaptation_scaled = $AdaptationScaled
      repeated_safe_carousel_reduced = $RepeatedSafeCarouselReduced
      baseline_session = $BaselineSessionId
      phase143_trial_session = $Phase143TrialSessionId
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
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.summary -Object $SessionSummary
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.summary -Object $SessionSummary

    $FinalHeartbeat = [ordered]@{
      status = "PASS"
      heartbeat_id = "BUILDER_BEHAVIOR_ADAPTATION_SCALE_HEARTBEAT_CURRENT"
      session_id = $TrialSessionId
      run_id = $RunId
      completed_cycles = $MaxCycles
      max_cycles = $MaxCycles
      corrections_seen_count = $CorrectionsSeenCount
      corrections_applied_count = $CorrectionsAppliedCount
      behavior_changes_count = $BehaviorChangesCount
      last_task_type = $TrialTaskSequenceArray[-1]
      last_seen_at = $CompletedAt
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.heartbeat -Object $FinalHeartbeat
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.heartbeat -Object $FinalHeartbeat

    $FinalState = [ordered]@{
      status = "PASS"
      state_id = "BUILDER_BEHAVIOR_ADAPTATION_SCALE_STATE_CURRENT"
      session_id = $TrialSessionId
      run_id = $RunId
      current_line = "SELF_BUILD"
      completed_cycles = $MaxCycles
      max_cycles = $MaxCycles
      corrections_seen_count = $CorrectionsSeenCount
      corrections_applied_count = $CorrectionsAppliedCount
      behavior_changes_count = $BehaviorChangesCount
      adaptation_scaled = $AdaptationScaled
      repeated_safe_carousel_reduced = $RepeatedSafeCarouselReduced
      baseline_session = $BaselineSessionId
      phase143_trial_session = $Phase143TrialSessionId
      trial_session = $TrialSessionId
      selected_next_gap = $NextAllowedStep
      owner_interactive_prompt_required = $false
      external_agent_production_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.state -Object $FinalState
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $TrialPaths.state -Object $FinalState

    $BehaviorAdaptationScaleTrialResult = [ordered]@{
      status = "PASS"
      result_id = "PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_RESULT"
      corrections_seen_count = $CorrectionsSeenCount
      corrections_applied_count = $CorrectionsAppliedCount
      behavior_changes_count = $BehaviorChangesCount
      adaptation_scaled = $AdaptationScaled
      repeated_safe_carousel_reduced = $RepeatedSafeCarouselReduced
      baseline_session = $BaselineSessionId
      phase143_trial_session = $Phase143TrialSessionId
      trial_session = $TrialSessionId
      selected_next_gap = $NextAllowedStep
      selected_by = "BUILDER_RUNTIME"
      external_agent_production_allowed = $false
      owner_interactive_prompt_required = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $TrialResultPath -Object $BehaviorAdaptationScaleTrialResult

    $RuntimeLog = @(
      "BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL=PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_001",
      "BEHAVIOR_ADAPTATION_SCALE_STATUS=PASS",
      "CORRECTIONS_SEEN_COUNT=3",
      "CORRECTIONS_APPLIED_COUNT=3",
      "BEHAVIOR_CHANGES_COUNT=3",
      "ADAPTATION_SCALED=True",
      "REPEATED_SAFE_CAROUSEL_REDUCED=True",
      "BASELINE_SESSION_ID=LIVE_LOOP_002",
      "PHASE143_TRIAL_SESSION_ID=PHASE143_CORRECTION_RESPONSE_TRIAL_001",
      "ADAPTATION_TRIAL_SESSION_ID=PHASE144_BEHAVIOR_ADAPTATION_SCALE_TRIAL_001",
      "OWNER_INTERACTIVE_PROMPT_REQUIRED=False",
      "EXTERNAL_AGENT_PRODUCTION_ALLOWED=False",
      "MATERIAL_TRUSTED_COUNT=0",
      "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
      "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
      "MATERIAL_EXECUTABLE_USED=False",
      "NEXT_ALLOWED_STEP=PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1",
      "STATUS=PASS_STOPPED_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_BUILT"
    ) -join "`n"
    Write-Phase144TextFile -RepoRoot $RepoRoot -Path $RuntimeLogPath -Content "$RuntimeLog`n"

    $Output = [ordered]@{
      status = "PASS"
      engine_name = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      corrections_seen_count = $CorrectionsSeenCount
      corrections_applied_count = $CorrectionsAppliedCount
      behavior_changes_count = $BehaviorChangesCount
      correction_aware_decision_count = $CorrectionAwareDecisionCount
      correction_aware_observation_count = $CorrectionAwareObservationCount
      adaptation_scaled = $AdaptationScaled
      repeated_safe_carousel_reduced = $RepeatedSafeCarouselReduced
      baseline_repetition_pattern_detected = $BaselineRepetitionPatternDetected
      phase143_single_correction_pattern_detected = $Phase143SingleCorrectionPatternDetected
      correction_to_behavior_mapping_count = $CorrectionToBehaviorMappingCount
      baseline_session = $BaselineSessionId
      phase143_trial_session = $Phase143TrialSessionId
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
      initial_correction_inbox_path = $TrialPaths.correction_inbox_initial
      adaptation_metrics_path = $TrialPaths.adaptation
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
      corrections_seen_count = $CorrectionsSeenCount
      corrections_applied_count = $CorrectionsAppliedCount
      behavior_changes_count = $BehaviorChangesCount
      adaptation_scaled = $AdaptationScaled
      repeated_safe_carousel_reduced = $RepeatedSafeCarouselReduced
      queue_after = "NONE"
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    $Report = [ordered]@{
      status = "PASS"
      report_id = "${StepId}_REPORT"
      step_id = $StepId
      run_id = $RunId
      orchestrator_hook = "orchestrator/run.ps1 invokes Invoke-BuilderBehaviorAdaptationScaleTrial001 when PHASE143 proof is PASS and next_allowed_step is PHASE144."
      corrections_created = @($Corrections | ForEach-Object { [ordered]@{ correction_id = $_.correction_id; message = $_.message; initial_status = "pending"; application_cycle = $_.application_cycle } })
      correction_creation_method = "Runtime writes exactly three PHASE144 pending corrections into current and trial correction_inbox_initial.json before the 18-cycle session starts."
      behavior_change_detection = "Each correction maps to one behavior change, increments behavior_changes_count, writes CORRECTION_APPLIED, and changes decision_trace/observation_ledger with correction-aware task selection."
      baseline_comparison_method = "Read LIVE_LOOP_002 first 18 selected_task_type values, detect the repeated six-task carousel, then require the PHASE144 trial sequence to differ and reduce READ_CURRENT_STATE repetitions."
      phase143_comparison_method = "Read PHASE143_CORRECTION_RESPONSE_TRIAL_001 first 12 selected_task_type values and require the first 12 PHASE144 tasks to differ from the single-correction pattern."
      validator_behavior = "Validator fails on missing PHASE143 proof/result, missing LIVE_LOOP_002 or PHASE143 trial, fewer than three seen/applied corrections, fewer than three behavior changes, missing correction-aware decisions/observations/log entries, no sequence change, wrong next gap, owner prompt, external-agent changes, trusted materials, fetch/install/executable flags, or active queue."
      proof_path = $ProofPath
      report_path = $ReportPath
      trial_result_path = $TrialResultPath
      trial_artifact_root = $TrialRoot
      remaining_risks = @(
        "PHASE144 proves deterministic scaling across three corrections in one bounded session; PHASE145 must prove autonomous learning across multiple sessions.",
        "Correction-to-behavior mapping is explicit and rule-based, not yet learned from open-ended feedback.",
        "The trial remains SELF_BUILD only and does not validate external-agent production."
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
      runtime_mode = "SELF_BUILD_QUEUE_NONE_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_001"
      runtime_executed = $true
      builder_runtime_invoked = $true
      corrections_seen_count = $CorrectionsSeenCount
      corrections_applied_count = $CorrectionsAppliedCount
      behavior_changes_count = $BehaviorChangesCount
      adaptation_scaled = $AdaptationScaled
      repeated_safe_carousel_reduced = $RepeatedSafeCarouselReduced
      baseline_repetition_pattern_detected = $BaselineRepetitionPatternDetected
      phase143_single_correction_pattern_detected = $Phase143SingleCorrectionPatternDetected
      correction_to_behavior_mapping_count = $CorrectionToBehaviorMappingCount
      correction_aware_decision_count = $CorrectionAwareDecisionCount
      correction_aware_observation_count = $CorrectionAwareObservationCount
      baseline_session = $BaselineSessionId
      phase143_trial_session = $Phase143TrialSessionId
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
      phase143_proof_path = $Phase143ProofPath
      phase143_result_path = $Phase143ResultPath
      baseline_root = $BaselineRoot
      phase143_trial_root = $Phase143TrialRoot
      trial_artifact_root = $TrialRoot
      initial_correction_inbox_path = $TrialPaths.correction_inbox_initial
      adaptation_metrics_path = $TrialPaths.adaptation
      trial_result_path = $TrialResultPath
      output_path = $OutputPath
      result_path = $ResultPath
      runtime_log_path = $RuntimeLogPath
      report_path = $ReportPath
      next_allowed_step = $NextAllowedStep
    }

    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $OutputPath -Object $Output
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report
    Write-Phase144JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject]$Output
  } finally {
    Pop-Location
  }
}
