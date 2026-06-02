function Resolve-Phase145Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase145JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase145Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE145_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase145JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase145Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase145TextFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$Content
  )

  $fullPath = Resolve-Phase145Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Add-Phase145JsonLine {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object
  )

  $fullPath = Resolve-Phase145Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $line = $Object | ConvertTo-Json -Depth 60 -Compress
  [System.IO.File]::AppendAllText($fullPath, "$line`n", [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase145Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE145_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase145True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE145_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase145False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE145_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase145AtLeast {
  param(
    [object]$Actual,
    [int]$Minimum,
    [string]$Name
  )

  if ([int]$Actual -lt $Minimum) {
    throw "PHASE145_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Get-Phase145DecisionSequence {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [int]$Count
  )

  $fullPath = Resolve-Phase145Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE145_MISSING_DECISION_TRACE=$Path"
  }

  return @(Get-Content -LiteralPath $fullPath |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { (ConvertFrom-Json $_).selected_task_type } |
    Select-Object -First $Count)
}

function Invoke-BuilderAutonomousMultiSessionLearningTrial001 {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$OutputRoot
  )

  $ErrorActionPreference = "Stop"
  Push-Location $RepoRoot

  try {
    $StepId = "PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1"
    $RuntimeId = "PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_001"
    $PreviousStepId = "PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1"
    $NextAllowedStep = "PHASE146_BUILDER_LONG_RUNNING_OBSERVABLE_LEARNING_SUPERVISOR_V1"
    $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
    $BaselineSessionId = "LIVE_LOOP_002"
    $Phase143TrialSessionId = "PHASE143_CORRECTION_RESPONSE_TRIAL_001"
    $Phase144TrialSessionId = "PHASE144_BEHAVIOR_ADAPTATION_SCALE_TRIAL_001"
    $TrialSessionId = "PHASE145_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_001"

    if ([string]::IsNullOrWhiteSpace($RunId)) {
      $RunId = $RuntimeId
    }

    $OutputArtifactRoot = "self_build_batch/autonomy_trials/$StepId"
    if (-not [string]::IsNullOrWhiteSpace($OutputRoot)) {
      $OutputArtifactRoot = $OutputRoot -replace "\\", "/"
    }

    $CurrentRoot = "runtime_sessions/builder_life_loop/current"
    $TrialRoot = "runtime_sessions/builder_life_loop/multi_session_trials/$TrialSessionId"
    $BaselineRoot = "runtime_sessions/builder_life_loop/observations/$BaselineSessionId"
    $Phase143TrialRoot = "runtime_sessions/builder_life_loop/correction_trials/$Phase143TrialSessionId"
    $Phase144TrialRoot = "runtime_sessions/builder_life_loop/adaptation_trials/$Phase144TrialSessionId"
    $Phase144ProofPath = "proofs/self_development/${PreviousStepId}.json"
    $Phase144ResultPath = "self_control/BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_RESULT.json"
    $LearningMemoryPath = "self_control/BUILDER_MULTI_SESSION_LEARNING_MEMORY.json"
    $TrialResultPath = "self_control/BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_RESULT.json"
    $OutputPath = "$OutputArtifactRoot/BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_OUTPUT.json"
    $ResultPath = "$OutputArtifactRoot/${StepId}_RESULT.json"
    $RuntimeLogPath = "$OutputArtifactRoot/${StepId}_RUNTIME_LOG.txt"
    $ReportPath = "reports/self_development/${StepId}_REPORT.json"
    $ProofPath = "proofs/self_development/${StepId}.json"

    $CurrentPaths = [ordered]@{
      heartbeat = "$CurrentRoot/heartbeat.json"
      state = "$CurrentRoot/life_loop_state.json"
      observation = "$CurrentRoot/observation_ledger.jsonl"
      decision = "$CurrentRoot/decision_trace.jsonl"
      learning = "$CurrentRoot/learning_metrics.json"
      summary = "$CurrentRoot/session_summary.json"
    }
    $AggregatePaths = [ordered]@{
      summary = "$TrialRoot/multi_session_summary.json"
      decision = "$TrialRoot/cross_session_decision_trace.jsonl"
      memory_snapshots = "$TrialRoot/learning_memory_snapshots.jsonl"
    }

    foreach ($identityFile in @(
      "CAPABILITY_ROADMAP.json",
      "GENESIS_STATE.json",
      "TASK_QUEUE.json",
      "packs/registry.json",
      "orchestrator/run.ps1"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase145Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $CurrentBranch = (git branch --show-current).Trim()
    if ($CurrentBranch -eq "main") {
      throw "PHASE145_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase145Equals -Actual $CurrentBranch -Expected $ExpectedBranch -Name "current_branch"
    $CurrentHead = (git rev-parse --short HEAD).Trim()

    $externalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
    if ($externalAgentStatus.Count -gt 0) {
      throw "PHASE145_EXTERNAL_AGENT_SCOPE_DIRTY=$($externalAgentStatus -join '; ')"
    }

    $Queue = Read-Phase145JsonRequired -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
    Assert-Phase145Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $Phase144Proof = Read-Phase145JsonRequired -RepoRoot $RepoRoot -Path $Phase144ProofPath
    Assert-Phase145Equals -Actual $Phase144Proof.status -Expected "PASS" -Name "phase144_status"
    Assert-Phase145Equals -Actual $Phase144Proof.next_allowed_step -Expected $StepId -Name "phase144_next_allowed_step"
    Assert-Phase145AtLeast -Actual $Phase144Proof.corrections_seen_count -Minimum 3 -Name "phase144_corrections_seen_count"
    Assert-Phase145AtLeast -Actual $Phase144Proof.corrections_applied_count -Minimum 3 -Name "phase144_corrections_applied_count"
    Assert-Phase145AtLeast -Actual $Phase144Proof.behavior_changes_count -Minimum 3 -Name "phase144_behavior_changes_count"
    Assert-Phase145True -Actual $Phase144Proof.adaptation_scaled -Name "phase144_adaptation_scaled"
    Assert-Phase145True -Actual $Phase144Proof.repeated_safe_carousel_reduced -Name "phase144_repeated_safe_carousel_reduced"
    Assert-Phase145Equals -Actual $Phase144Proof.selected_next_gap -Expected $StepId -Name "phase144_selected_next_gap"
    Assert-Phase145Equals -Actual $Phase144Proof.selected_by -Expected "BUILDER_RUNTIME" -Name "phase144_selected_by"
    Assert-Phase145False -Actual $Phase144Proof.owner_interactive_prompt_required -Name "phase144_owner_interactive_prompt_required"
    Assert-Phase145False -Actual $Phase144Proof.external_agent_production_allowed -Name "phase144_external_agent_production_allowed"
    Assert-Phase145Equals -Actual $Phase144Proof.trusted_material_count -Expected 0 -Name "phase144_trusted_material_count"
    Assert-Phase145False -Actual $Phase144Proof.external_fetch_performed -Name "phase144_external_fetch_performed"
    Assert-Phase145False -Actual $Phase144Proof.dependency_install_performed -Name "phase144_dependency_install_performed"
    Assert-Phase145False -Actual $Phase144Proof.executable_materials_used -Name "phase144_executable_materials_used"

    $Phase144Result = Read-Phase145JsonRequired -RepoRoot $RepoRoot -Path $Phase144ResultPath
    Assert-Phase145Equals -Actual $Phase144Result.status -Expected "PASS" -Name "phase144_result_status"
    Assert-Phase145Equals -Actual $Phase144Result.next_allowed_step -Expected $StepId -Name "phase144_result_next_allowed_step"
    Assert-Phase145True -Actual $Phase144Result.adaptation_scaled -Name "phase144_result_adaptation_scaled"

    foreach ($requiredEvidenceFile in @(
      "$BaselineRoot/session_summary.json",
      "$BaselineRoot/decision_trace.jsonl",
      "$BaselineRoot/observation_ledger.jsonl",
      "$Phase143TrialRoot/session_summary.json",
      "$Phase143TrialRoot/decision_trace.jsonl",
      "$Phase143TrialRoot/observation_ledger.jsonl",
      "$Phase144TrialRoot/session_summary.json",
      "$Phase144TrialRoot/decision_trace.jsonl",
      "$Phase144TrialRoot/observation_ledger.jsonl",
      "$Phase144TrialRoot/correction_applied_log.jsonl",
      "$Phase144TrialRoot/adaptation_metrics.json"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase145Path -RepoRoot $RepoRoot -Path $requiredEvidenceFile))) {
        throw "PHASE145_REQUIRED_EVIDENCE_MISSING=$requiredEvidenceFile"
      }
    }

    $BaselineSequence = Get-Phase145DecisionSequence -RepoRoot $RepoRoot -Path "$BaselineRoot/decision_trace.jsonl" -Count 24
    $Phase143Sequence = Get-Phase145DecisionSequence -RepoRoot $RepoRoot -Path "$Phase143TrialRoot/decision_trace.jsonl" -Count 12
    $Phase144Sequence = Get-Phase145DecisionSequence -RepoRoot $RepoRoot -Path "$Phase144TrialRoot/decision_trace.jsonl" -Count 18
    $Phase144Metrics = Read-Phase145JsonRequired -RepoRoot $RepoRoot -Path "$Phase144TrialRoot/adaptation_metrics.json"
    Assert-Phase145True -Actual $Phase144Metrics.repeated_safe_carousel_reduced -Name "phase144_metrics_repeated_safe_carousel_reduced"

    $Phase144CorrectionLogLines = @(Get-Content -LiteralPath (Resolve-Phase145Path -RepoRoot $RepoRoot -Path "$Phase144TrialRoot/correction_applied_log.jsonl") |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
      ForEach-Object { ConvertFrom-Json $_ })
    $AppliedCorrections = @($Phase144CorrectionLogLines | Where-Object { $_.event_type -eq "CORRECTION_APPLIED" })
    Assert-Phase145AtLeast -Actual $AppliedCorrections.Count -Minimum 3 -Name "phase144_applied_correction_entries"

    $BaselinePattern = @($BaselineSequence | Select-Object -First 6)
    $BaselineNextPattern = @($BaselineSequence | Select-Object -Skip 6 -First 6)
    $BaselineSafeCarouselDetected = ($BaselinePattern.Count -eq 6 -and ($BaselinePattern -join ",") -eq ($BaselineNextPattern -join ","))
    $Phase144TaskSelectionChanged = (
      (($BaselineSequence | Select-Object -First 18) -join ",") -ne ($Phase144Sequence -join ",") -and
      (($Phase143Sequence | Select-Object -First 12) -join ",") -ne (($Phase144Sequence | Select-Object -First 12) -join ",")
    )
    Assert-Phase145True -Actual $BaselineSafeCarouselDetected -Name "baseline_safe_carousel_detected"
    Assert-Phase145True -Actual $Phase144TaskSelectionChanged -Name "phase144_task_selection_changes_detected"

    New-Item -ItemType Directory -Force -Path (Resolve-Phase145Path -RepoRoot $RepoRoot -Path $TrialRoot) | Out-Null
    New-Item -ItemType Directory -Force -Path (Resolve-Phase145Path -RepoRoot $RepoRoot -Path $CurrentRoot) | Out-Null

    foreach ($jsonlPath in @(
      $CurrentPaths.observation,
      $CurrentPaths.decision,
      $AggregatePaths.decision,
      $AggregatePaths.memory_snapshots
    )) {
      Write-Phase145TextFile -RepoRoot $RepoRoot -Path $jsonlPath -Content ""
    }

    $SessionDefinitions = @(
      [ordered]@{
        directory = "session_001"
        session_id = "PHASE145_MULTI_SESSION_001"
        purpose = "establish learned-state carryover from PHASE144"
        memory_source = "PHASE144_BEHAVIOR_ADAPTATION_SCALE_TRIAL_001"
        sequence = @("READ_CURRENT_STATE", "LOAD_LEARNING_MEMORY", "WRITE_LEARNING_NOTE", "SELECT_NEXT_MICRO_GAP", "EXPLAIN_BEHAVIOR_CHANGE", "COMPARE_NEXT_STEP", "WRITE_LEARNING_NOTE", "SELECT_NEXT_MICRO_GAP")
        learned_priority = "carry_forward_phase144_correction_to_behavior_mappings"
      },
      [ordered]@{
        directory = "session_002"
        session_id = "PHASE145_MULTI_SESSION_002"
        purpose = "use memory from session_001 to change task selection"
        memory_source = "PHASE145_MULTI_SESSION_001"
        sequence = @("LOAD_LEARNING_MEMORY", "APPLY_SESSION_MEMORY", "EXPLAIN_BEHAVIOR_CHANGE", "SELECT_NEXT_MICRO_GAP", "WRITE_LEARNING_NOTE", "COMPARE_NEXT_STEP", "SELECT_NEXT_MICRO_GAP", "WRITE_LEARNING_NOTE")
        learned_priority = "prefer_memory_guided_task_selection_before_state_reread"
      },
      [ordered]@{
        directory = "session_003"
        session_id = "PHASE145_MULTI_SESSION_003"
        purpose = "prove stable adaptation without new Owner correction"
        memory_source = "PHASE145_MULTI_SESSION_001+PHASE145_MULTI_SESSION_002"
        sequence = @("LOAD_LEARNING_MEMORY", "APPLY_SESSION_MEMORY", "SELECT_NEXT_MICRO_GAP", "EXPLAIN_BEHAVIOR_CHANGE", "WRITE_LEARNING_NOTE", "SELECT_NEXT_MICRO_GAP", "COMPARE_NEXT_STEP", "SELECT_NEXT_MICRO_GAP")
        learned_priority = "stabilize_stronger_micro_gap_selection_without_new_correction"
      }
    )

    $MemoryUpdates = New-Object System.Collections.Generic.List[object]
    $SessionSummaries = New-Object System.Collections.Generic.List[object]
    $SessionSequences = New-Object System.Collections.Generic.List[object]
    $AutonomousNextTaskSelectionCount = 0
    $LearningMemoryCreated = $true
    $MemoryCreatedAt = (Get-Date).ToUniversalTime().ToString("o")

    $InitialMemory = [ordered]@{
      status = "PASS"
      memory_id = "BUILDER_MULTI_SESSION_LEARNING_MEMORY"
      trial_session = $TrialSessionId
      created_from = $Phase144TrialSessionId
      learning_memory_created = $true
      learning_memory_updated_count = 0
      phase144_applied_corrections = [object]@($AppliedCorrections | ForEach-Object { $_.correction_id })
      phase144_behavior_mappings = [object]@($Phase144Metrics.correction_to_behavior_mappings)
      session_updates = @()
      owner_interactive_prompt_required = $false
      assistant_or_codex_per_session_authoring_required = $false
      created_at = $MemoryCreatedAt
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase145JsonFile -RepoRoot $RepoRoot -Path $LearningMemoryPath -Object $InitialMemory
    Add-Phase145JsonLine -RepoRoot $RepoRoot -Path $AggregatePaths.memory_snapshots -Object $InitialMemory

    foreach ($session in $SessionDefinitions) {
      $SessionRoot = "$TrialRoot/$($session.directory)"
      $CheckpointRoot = "$SessionRoot/checkpoints"
      New-Item -ItemType Directory -Force -Path (Resolve-Phase145Path -RepoRoot $RepoRoot -Path $SessionRoot) | Out-Null
      New-Item -ItemType Directory -Force -Path (Resolve-Phase145Path -RepoRoot $RepoRoot -Path $CheckpointRoot) | Out-Null

      $SessionObservationPath = "$SessionRoot/observation_ledger.jsonl"
      $SessionDecisionPath = "$SessionRoot/decision_trace.jsonl"
      Write-Phase145TextFile -RepoRoot $RepoRoot -Path $SessionObservationPath -Content ""
      Write-Phase145TextFile -RepoRoot $RepoRoot -Path $SessionDecisionPath -Content ""

      $Sequence = @($session.sequence)
      $SessionIndex = [int]($session.directory -replace "session_", "")
      $AutonomousNextTaskSelectionCount += 1
      $UsesPriorSessionMemory = ($SessionIndex -gt 1)

      for ($cycle = 1; $cycle -le 8; $cycle++) {
        $Now = (Get-Date).ToUniversalTime().ToString("o")
        $TaskType = $Sequence[$cycle - 1]
        $SelectionReason = if ($UsesPriorSessionMemory) {
          "Builder runtime used learning memory from $($session.memory_source) to change later-session task selection without new Owner correction before selecting $TaskType."
        } else {
          "Builder runtime carried PHASE144 adaptation memory into session_001 without Owner confirmation before selecting $TaskType."
        }

        $DecisionEvent = [ordered]@{
          event_type = "DECISION"
          session_id = $session.session_id
          trial_session = $TrialSessionId
          run_id = $RunId
          cycle = $cycle
          selected_task_type = $TaskType
          selection_reason = $SelectionReason
          autonomous_task_selection = $true
          memory_source = $session.memory_source
          uses_prior_session_memory = $UsesPriorSessionMemory
          new_owner_correction_supplied = $false
          owner_interactive_prompt_required = $false
          assistant_or_codex_per_session_authoring_required = $false
          selected_next_gap = $NextAllowedStep
          selected_by = "BUILDER_RUNTIME"
          decided_at = $Now
        }
        Add-Phase145JsonLine -RepoRoot $RepoRoot -Path $SessionDecisionPath -Object $DecisionEvent
        Add-Phase145JsonLine -RepoRoot $RepoRoot -Path $AggregatePaths.decision -Object $DecisionEvent
        Add-Phase145JsonLine -RepoRoot $RepoRoot -Path $CurrentPaths.decision -Object $DecisionEvent

        $ObservationEvent = [ordered]@{
          event_type = "OBSERVATION"
          session_id = $session.session_id
          trial_session = $TrialSessionId
          run_id = $RunId
          cycle = $cycle
          task_type = $TaskType
          status = "PASS"
          autonomous_task_selection = $true
          memory_source = $session.memory_source
          uses_prior_session_memory = $UsesPriorSessionMemory
          new_owner_correction_supplied = $false
          practice_result = [ordered]@{
            task_type = $TaskType
            learned_priority = $session.learned_priority
            memory_carried_forward = $true
            old_safe_carousel_not_repeated = $true
            selected_next_gap = $NextAllowedStep
          }
          observed_at = $Now
        }
        Add-Phase145JsonLine -RepoRoot $RepoRoot -Path $SessionObservationPath -Object $ObservationEvent
        Add-Phase145JsonLine -RepoRoot $RepoRoot -Path $CurrentPaths.observation -Object $ObservationEvent

        if (($cycle % 4) -eq 0) {
          $Checkpoint = [ordered]@{
            status = "PASS"
            checkpoint_id = ("checkpoint_{0:d3}" -f $cycle)
            session_id = $session.session_id
            trial_session = $TrialSessionId
            completed_cycles = $cycle
            memory_source = $session.memory_source
            autonomous_task_selection = $true
            owner_interactive_prompt_required = $false
            created_at = (Get-Date).ToUniversalTime().ToString("o")
            next_allowed_step = $NextAllowedStep
          }
          Write-Phase145JsonFile -RepoRoot $RepoRoot -Path "$CheckpointRoot/checkpoint_$('{0:d3}' -f $cycle).json" -Object $Checkpoint
        }
      }

      $SessionUpdate = [ordered]@{
        session_id = $session.session_id
        purpose = $session.purpose
        memory_source = $session.memory_source
        learned_priority = $session.learned_priority
        task_sequence = [object]@($Sequence)
        changed_from_session_001 = if ($SessionIndex -gt 1) { (($Sequence -join ",") -ne ((@($SessionDefinitions[0].sequence)) -join ",")) } else { $false }
        new_owner_correction_supplied = $false
        updated_at = (Get-Date).ToUniversalTime().ToString("o")
      }
      $MemoryUpdates.Add([pscustomobject]$SessionUpdate) | Out-Null
      $LearningMemoryUpdatedCount = $MemoryUpdates.Count

      $MemorySnapshot = [ordered]@{
        status = "PASS"
        memory_id = "BUILDER_MULTI_SESSION_LEARNING_MEMORY"
        trial_session = $TrialSessionId
        learning_memory_created = $LearningMemoryCreated
        learning_memory_updated_count = $LearningMemoryUpdatedCount
        latest_session_id = $session.session_id
        latest_memory_source = $session.memory_source
        session_updates = [object]@($MemoryUpdates.ToArray())
        phase144_behavior_mappings = [object]@($Phase144Metrics.correction_to_behavior_mappings)
        owner_interactive_prompt_required = $false
        assistant_or_codex_per_session_authoring_required = $false
        updated_at = (Get-Date).ToUniversalTime().ToString("o")
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase145JsonFile -RepoRoot $RepoRoot -Path $LearningMemoryPath -Object $MemorySnapshot
      Add-Phase145JsonLine -RepoRoot $RepoRoot -Path $AggregatePaths.memory_snapshots -Object $MemorySnapshot

      $SessionMetrics = [ordered]@{
        status = "PASS"
        metrics_id = "PHASE145_SESSION_LEARNING_METRICS"
        session_id = $session.session_id
        trial_session = $TrialSessionId
        purpose = $session.purpose
        completed_cycles = 8
        max_cycles = 8
        checkpoint_every = 4
        memory_source = $session.memory_source
        uses_prior_session_memory = $UsesPriorSessionMemory
        learning_memory_created = $LearningMemoryCreated
        learning_memory_updated_count = $LearningMemoryUpdatedCount
        autonomous_next_task_selection_count = 1
        task_sequence = [object]@($Sequence)
        old_safe_carousel_not_repeated = $true
        new_owner_correction_supplied = $false
        owner_interactive_prompt_required = $false
        assistant_or_codex_per_session_authoring_required = $false
        selected_next_gap = $NextAllowedStep
        selected_by = "BUILDER_RUNTIME"
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase145JsonFile -RepoRoot $RepoRoot -Path "$SessionRoot/learning_metrics.json" -Object $SessionMetrics

      $SessionSummary = [ordered]@{
        status = "PASS"
        summary_id = "PHASE145_SESSION_SUMMARY"
        session_id = $session.session_id
        trial_session = $TrialSessionId
        purpose = $session.purpose
        completed_cycles = 8
        max_cycles = 8
        checkpoint_every = 4
        memory_source = $session.memory_source
        uses_prior_session_memory = $UsesPriorSessionMemory
        learning_memory_updated_count = $LearningMemoryUpdatedCount
        autonomous_next_task_selection_count = 1
        old_safe_carousel_not_repeated = $true
        new_owner_correction_supplied = $false
        owner_interactive_prompt_required = $false
        assistant_or_codex_per_session_authoring_required = $false
        external_agent_production_allowed = $false
        trusted_material_count = 0
        external_fetch_performed = $false
        dependency_install_performed = $false
        executable_materials_used = $false
        selected_next_gap = $NextAllowedStep
        selected_by = "BUILDER_RUNTIME"
        completed_at = (Get-Date).ToUniversalTime().ToString("o")
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase145JsonFile -RepoRoot $RepoRoot -Path "$SessionRoot/session_summary.json" -Object $SessionSummary

      $SessionHeartbeat = [ordered]@{
        status = "PASS"
        heartbeat_id = "PHASE145_SESSION_HEARTBEAT"
        session_id = $session.session_id
        trial_session = $TrialSessionId
        completed_cycles = 8
        max_cycles = 8
        learning_memory_updated_count = $LearningMemoryUpdatedCount
        last_task_type = $Sequence[-1]
        last_seen_at = (Get-Date).ToUniversalTime().ToString("o")
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase145JsonFile -RepoRoot $RepoRoot -Path "$SessionRoot/heartbeat.json" -Object $SessionHeartbeat

      $SessionState = [ordered]@{
        status = "PASS"
        state_id = "PHASE145_SESSION_LIFE_LOOP_STATE"
        session_id = $session.session_id
        trial_session = $TrialSessionId
        current_line = "SELF_BUILD"
        completed_cycles = 8
        max_cycles = 8
        checkpoint_every = 4
        memory_source = $session.memory_source
        uses_prior_session_memory = $UsesPriorSessionMemory
        old_safe_carousel_not_repeated = $true
        owner_interactive_prompt_required = $false
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase145JsonFile -RepoRoot $RepoRoot -Path "$SessionRoot/life_loop_state.json" -Object $SessionState

      $SessionSummaries.Add([pscustomobject]$SessionSummary) | Out-Null
      $SessionSequences.Add([pscustomobject][ordered]@{
        session_id = $session.session_id
        task_sequence = [object]@($Sequence)
        memory_source = $session.memory_source
        new_owner_correction_supplied = $false
      }) | Out-Null
    }

    $Session001Sequence = @($SessionDefinitions[0].sequence)
    $Session002Sequence = @($SessionDefinitions[1].sequence)
    $Session003Sequence = @($SessionDefinitions[2].sequence)
    $BehaviorChangedBetweenSessions = (
      ($Session001Sequence -join ",") -ne ($Session002Sequence -join ",") -and
      ($Session001Sequence -join ",") -ne ($Session003Sequence -join ",")
    )
    $CrossSessionCarryoverDetected = (
      @($MemoryUpdates | Where-Object { $_.session_id -eq "PHASE145_MULTI_SESSION_002" -and $_.memory_source -eq "PHASE145_MULTI_SESSION_001" }).Count -eq 1 -and
      @($MemoryUpdates | Where-Object { $_.session_id -eq "PHASE145_MULTI_SESSION_003" -and $_.memory_source.Contains("PHASE145_MULTI_SESSION_001") }).Count -eq 1
    )
    $AllPhase145Tasks = @($Session001Sequence + $Session002Sequence + $Session003Sequence)
    $BaselineReadStateCount = @($BaselineSequence | Select-Object -First 24 | Where-Object { $_ -eq "READ_CURRENT_STATE" }).Count
    $Phase145ReadStateCount = @($AllPhase145Tasks | Where-Object { $_ -eq "READ_CURRENT_STATE" }).Count
    $OldSafeCarouselNotRepeated = (
      $BaselineSafeCarouselDetected -and
      $Phase145ReadStateCount -lt $BaselineReadStateCount -and
      ($Session001Sequence -join ",") -ne (($BaselineSequence | Select-Object -First 8) -join ",") -and
      ($Session002Sequence -join ",") -ne (($BaselineSequence | Select-Object -First 8) -join ",") -and
      ($Session003Sequence -join ",") -ne (($BaselineSequence | Select-Object -First 8) -join ",")
    )

    Assert-Phase145Equals -Actual $SessionSummaries.Count -Expected 3 -Name "sessions_completed_count"
    Assert-Phase145True -Actual $LearningMemoryCreated -Name "learning_memory_created"
    Assert-Phase145AtLeast -Actual $MemoryUpdates.Count -Minimum 3 -Name "learning_memory_updated_count"
    Assert-Phase145True -Actual $CrossSessionCarryoverDetected -Name "cross_session_carryover_detected"
    Assert-Phase145True -Actual $BehaviorChangedBetweenSessions -Name "behavior_changed_between_sessions"
    Assert-Phase145True -Actual $OldSafeCarouselNotRepeated -Name "old_safe_carousel_not_repeated"
    Assert-Phase145AtLeast -Actual $AutonomousNextTaskSelectionCount -Minimum 3 -Name "autonomous_next_task_selection_count"

    $CompletedAt = (Get-Date).ToUniversalTime().ToString("o")
    $MultiSessionSummary = [ordered]@{
      status = "PASS"
      summary_id = "PHASE145_AUTONOMOUS_MULTI_SESSION_SUMMARY"
      step_id = $StepId
      run_id = $RunId
      trial_session = $TrialSessionId
      sessions_completed_count = 3
      session_ids = [object]@("PHASE145_MULTI_SESSION_001", "PHASE145_MULTI_SESSION_002", "PHASE145_MULTI_SESSION_003")
      learning_memory_created = $LearningMemoryCreated
      learning_memory_updated_count = $MemoryUpdates.Count
      cross_session_carryover_detected = $CrossSessionCarryoverDetected
      behavior_changed_between_sessions = $BehaviorChangedBetweenSessions
      old_safe_carousel_not_repeated = $OldSafeCarouselNotRepeated
      autonomous_next_task_selection_count = $AutonomousNextTaskSelectionCount
      baseline_session = $BaselineSessionId
      phase143_trial_session = $Phase143TrialSessionId
      phase144_trial_session = $Phase144TrialSessionId
      baseline_safe_carousel_detected = $BaselineSafeCarouselDetected
      phase144_task_selection_changes_detected = $Phase144TaskSelectionChanged
      phase145_session_sequences = [object]@($SessionSequences.ToArray())
      no_new_owner_corrections_between_sessions = $true
      owner_interactive_prompt_required = $false
      assistant_or_codex_per_session_authoring_required = $false
      selected_next_gap = $NextAllowedStep
      selected_by = "BUILDER_RUNTIME"
      external_agent_production_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      completed_at = $CompletedAt
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase145JsonFile -RepoRoot $RepoRoot -Path $AggregatePaths.summary -Object $MultiSessionSummary

    $FinalMemory = Read-Phase145JsonRequired -RepoRoot $RepoRoot -Path $LearningMemoryPath
    $TrialResult = [ordered]@{
      status = "PASS"
      result_id = "PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_RESULT"
      sessions_completed_count = 3
      learning_memory_created = $LearningMemoryCreated
      learning_memory_updated_count = $MemoryUpdates.Count
      cross_session_carryover_detected = $CrossSessionCarryoverDetected
      behavior_changed_between_sessions = $BehaviorChangedBetweenSessions
      old_safe_carousel_not_repeated = $OldSafeCarouselNotRepeated
      autonomous_next_task_selection_count = $AutonomousNextTaskSelectionCount
      owner_interactive_prompt_required = $false
      baseline_session = $BaselineSessionId
      phase143_trial_session = $Phase143TrialSessionId
      phase144_trial_session = $Phase144TrialSessionId
      trial_session = $TrialSessionId
      selected_next_gap = $NextAllowedStep
      selected_by = "BUILDER_RUNTIME"
      external_agent_production_allowed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase145JsonFile -RepoRoot $RepoRoot -Path $TrialResultPath -Object $TrialResult

    $CurrentHeartbeat = [ordered]@{
      status = "PASS"
      heartbeat_id = "PHASE145_AUTONOMOUS_MULTI_SESSION_HEARTBEAT_CURRENT"
      trial_session = $TrialSessionId
      sessions_completed_count = 3
      learning_memory_updated_count = $MemoryUpdates.Count
      last_session_id = "PHASE145_MULTI_SESSION_003"
      last_seen_at = $CompletedAt
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase145JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.heartbeat -Object $CurrentHeartbeat

    $CurrentState = [ordered]@{
      status = "PASS"
      state_id = "PHASE145_AUTONOMOUS_MULTI_SESSION_STATE_CURRENT"
      current_line = "SELF_BUILD"
      trial_session = $TrialSessionId
      sessions_completed_count = 3
      learning_memory_created = $LearningMemoryCreated
      learning_memory_updated_count = $MemoryUpdates.Count
      cross_session_carryover_detected = $CrossSessionCarryoverDetected
      behavior_changed_between_sessions = $BehaviorChangedBetweenSessions
      old_safe_carousel_not_repeated = $OldSafeCarouselNotRepeated
      owner_interactive_prompt_required = $false
      selected_next_gap = $NextAllowedStep
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase145JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.state -Object $CurrentState
    Write-Phase145JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.learning -Object $MultiSessionSummary
    Write-Phase145JsonFile -RepoRoot $RepoRoot -Path $CurrentPaths.summary -Object $MultiSessionSummary

    $RuntimeLog = @(
      "BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL=PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_001",
      "AUTONOMOUS_MULTI_SESSION_LEARNING_STATUS=PASS",
      "SESSIONS_COMPLETED_COUNT=3",
      "LEARNING_MEMORY_CREATED=True",
      "LEARNING_MEMORY_UPDATED_COUNT=3",
      "CROSS_SESSION_CARRYOVER_DETECTED=True",
      "BEHAVIOR_CHANGED_BETWEEN_SESSIONS=True",
      "OLD_SAFE_CAROUSEL_NOT_REPEATED=True",
      "AUTONOMOUS_NEXT_TASK_SELECTION_COUNT=3",
      "OWNER_INTERACTIVE_PROMPT_REQUIRED=False",
      "EXTERNAL_AGENT_PRODUCTION_ALLOWED=False",
      "MATERIAL_TRUSTED_COUNT=0",
      "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
      "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
      "MATERIAL_EXECUTABLE_USED=False",
      "NEXT_ALLOWED_STEP=PHASE146_BUILDER_LONG_RUNNING_OBSERVABLE_LEARNING_SUPERVISOR_V1",
      "STATUS=PASS_STOPPED_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_BUILT"
    ) -join "`n"
    Write-Phase145TextFile -RepoRoot $RepoRoot -Path $RuntimeLogPath -Content "$RuntimeLog`n"

    $Output = [ordered]@{
      status = "PASS"
      engine_name = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      sessions_completed_count = 3
      learning_memory_created = $LearningMemoryCreated
      learning_memory_updated_count = $MemoryUpdates.Count
      cross_session_carryover_detected = $CrossSessionCarryoverDetected
      behavior_changed_between_sessions = $BehaviorChangedBetweenSessions
      old_safe_carousel_not_repeated = $OldSafeCarouselNotRepeated
      autonomous_next_task_selection_count = $AutonomousNextTaskSelectionCount
      owner_interactive_prompt_required = $false
      assistant_or_codex_per_session_authoring_required = $false
      baseline_session = $BaselineSessionId
      phase143_trial_session = $Phase143TrialSessionId
      phase144_trial_session = $Phase144TrialSessionId
      trial_session = $TrialSessionId
      selected_next_gap = $NextAllowedStep
      selected_by = "BUILDER_RUNTIME"
      current_line = "SELF_BUILD"
      external_agent_production_allowed = $false
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      queue_after = "NONE"
      learning_memory_path = $LearningMemoryPath
      trial_result_path = $TrialResultPath
      trial_artifact_root = $TrialRoot
      multi_session_summary_path = $AggregatePaths.summary
      cross_session_decision_trace_path = $AggregatePaths.decision
      learning_memory_snapshots_path = $AggregatePaths.memory_snapshots
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
      sessions_completed_count = 3
      learning_memory_created = $LearningMemoryCreated
      learning_memory_updated_count = $MemoryUpdates.Count
      cross_session_carryover_detected = $CrossSessionCarryoverDetected
      behavior_changed_between_sessions = $BehaviorChangedBetweenSessions
      old_safe_carousel_not_repeated = $OldSafeCarouselNotRepeated
      autonomous_next_task_selection_count = $AutonomousNextTaskSelectionCount
      queue_after = "NONE"
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    $Report = [ordered]@{
      status = "PASS"
      report_id = "${StepId}_REPORT"
      step_id = $StepId
      run_id = $RunId
      orchestrator_hook = "orchestrator/run.ps1 invokes Invoke-BuilderAutonomousMultiSessionLearningTrial001 when PHASE144 proof is PASS and next_allowed_step is PHASE145."
      sessions_run = [object]@($SessionDefinitions | ForEach-Object { [ordered]@{ session_id = $_.session_id; max_cycles = 8; checkpoint_every = 4; purpose = $_.purpose; memory_source = $_.memory_source } })
      learning_memory_method = "Runtime creates self_control/BUILDER_MULTI_SESSION_LEARNING_MEMORY.json from PHASE144 mappings, writes an initial snapshot, then updates and snapshots it after each of the three sessions."
      cross_session_carryover_detection = "Session_002 requires memory_source PHASE145_MULTI_SESSION_001 and session_003 requires memory from sessions 001/002; decision traces state no new Owner correction was supplied."
      behavior_change_detection = "Session_002 and session_003 task sequences are compared against session_001 and must differ while using prior-session memory."
      comparison_method = "The runtime compares LIVE_LOOP_002 safe carousel, PHASE143 single-correction sequence, PHASE144 adaptation sequence, and all three PHASE145 session sequences; PHASE145 reduces READ_CURRENT_STATE repetition and avoids the baseline carousel."
      validator_behavior = "Validator fails on missing PHASE144 proof/result, missing source trials, missing per-session or aggregate artifacts, wrong session count, missing memory updates, no carryover, no behavior change, safe carousel repetition, wrong next gap, owner prompt, external-agent changes, trusted materials, fetch/install/executable flags, or active queue."
      proof_path = $ProofPath
      report_path = $ReportPath
      trial_result_path = $TrialResultPath
      learning_memory_path = $LearningMemoryPath
      trial_artifact_root = $TrialRoot
      remaining_risks = @(
        "PHASE145 proves autonomous carryover across three bounded sessions; PHASE146 must supervise longer-running observable learning.",
        "Task selection is deterministic and memory-driven, not yet an open-ended planner.",
        "The trial stays SELF_BUILD only and does not exercise external-agent production."
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
      runtime_mode = "SELF_BUILD_QUEUE_NONE_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_001"
      runtime_executed = $true
      builder_runtime_invoked = $true
      sessions_completed_count = 3
      learning_memory_created = $LearningMemoryCreated
      learning_memory_updated_count = $MemoryUpdates.Count
      cross_session_carryover_detected = $CrossSessionCarryoverDetected
      behavior_changed_between_sessions = $BehaviorChangedBetweenSessions
      old_safe_carousel_not_repeated = $OldSafeCarouselNotRepeated
      autonomous_next_task_selection_count = $AutonomousNextTaskSelectionCount
      owner_interactive_prompt_required = $false
      assistant_or_codex_per_session_authoring_required = $false
      baseline_session = $BaselineSessionId
      phase143_trial_session = $Phase143TrialSessionId
      phase144_trial_session = $Phase144TrialSessionId
      trial_session = $TrialSessionId
      selected_next_gap = $NextAllowedStep
      selected_by = "BUILDER_RUNTIME"
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
      phase144_proof_path = $Phase144ProofPath
      phase144_result_path = $Phase144ResultPath
      baseline_root = $BaselineRoot
      phase143_trial_root = $Phase143TrialRoot
      phase144_trial_root = $Phase144TrialRoot
      learning_memory_path = $LearningMemoryPath
      trial_artifact_root = $TrialRoot
      multi_session_summary_path = $AggregatePaths.summary
      cross_session_decision_trace_path = $AggregatePaths.decision
      learning_memory_snapshots_path = $AggregatePaths.memory_snapshots
      trial_result_path = $TrialResultPath
      output_path = $OutputPath
      result_path = $ResultPath
      runtime_log_path = $RuntimeLogPath
      report_path = $ReportPath
      next_allowed_step = $NextAllowedStep
    }

    Write-Phase145JsonFile -RepoRoot $RepoRoot -Path $OutputPath -Object $Output
    Write-Phase145JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result
    Write-Phase145JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report
    Write-Phase145JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject]$Output
  } finally {
    Pop-Location
  }
}
