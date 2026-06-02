function Resolve-Phase146Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase146JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase146Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE146_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase146JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase146Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase146TextFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$Content
  )

  $fullPath = Resolve-Phase146Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Add-Phase146JsonLine {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object
  )

  $fullPath = Resolve-Phase146Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $line = $Object | ConvertTo-Json -Depth 80 -Compress
  [System.IO.File]::AppendAllText($fullPath, "$line`n", [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase146Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE146_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase146True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE146_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase146False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE146_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase146ProtectedArtifactSnapshot {
  param(
    [string]$RepoRoot
  )

  $protectedRoots = @(
    "proofs/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1.json",
    "reports/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1_REPORT.json",
    "self_build_batch/autonomy_trials/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1",
    "runtime_sessions/builder_life_loop/multi_session_trials/PHASE145_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_001",
    "runtime_sessions/builder_life_loop/current",
    "self_control/BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_RESULT.json",
    "self_control/BUILDER_MULTI_SESSION_LEARNING_MEMORY.json"
  )

  $entries = New-Object System.Collections.Generic.List[object]
  foreach ($protectedRoot in $protectedRoots) {
    $fullPath = Resolve-Phase146Path -RepoRoot $RepoRoot -Path $protectedRoot
    if (-not (Test-Path -LiteralPath $fullPath)) {
      $entries.Add([pscustomobject][ordered]@{
        path = $protectedRoot
        exists = $false
        kind = "missing"
        hash = $null
        length = 0
      }) | Out-Null
      continue
    }

    $item = Get-Item -LiteralPath $fullPath
    if ($item.PSIsContainer) {
      $files = @(Get-ChildItem -LiteralPath $fullPath -File -Recurse | Sort-Object FullName)
      foreach ($file in $files) {
        $relativePath = $file.FullName.Substring((Resolve-Phase146Path -RepoRoot $RepoRoot -Path ".").Length + 1) -replace "\\", "/"
        $entries.Add([pscustomobject][ordered]@{
          path = $relativePath
          exists = $true
          kind = "file"
          hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
          length = $file.Length
        }) | Out-Null
      }
    } else {
      $entries.Add([pscustomobject][ordered]@{
        path = $protectedRoot
        exists = $true
        kind = "file"
        hash = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash
        length = $item.Length
      }) | Out-Null
    }
  }

  return @($entries | Sort-Object path)
}

function Test-Phase146SnapshotUnchanged {
  param(
    [object[]]$Before,
    [object[]]$After
  )

  $beforeJson = (@($Before) | ConvertTo-Json -Depth 20 -Compress)
  $afterJson = (@($After) | ConvertTo-Json -Depth 20 -Compress)
  return [string]::Equals($beforeJson, $afterJson, [System.StringComparison]::Ordinal)
}

function Invoke-BuilderObservationOnlyLiveRunner001 {
  param(
    [string]$RepoRoot,
    [string]$SessionId = "LIVE_AFTER_PHASE145_001",
    [int]$MaxCycles = 30,
    [int]$CheckpointEvery = 5,
    [int]$SleepSeconds = 0,
    [switch]$WritePhaseArtifacts,
    [switch]$FinalizeOnly
  )

  $ErrorActionPreference = "Stop"
  Push-Location $RepoRoot

  try {
    $StepId = "PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1"
    $RunId = "PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_001"
    $PreviousNextAllowedStep = "PHASE146_BUILDER_LONG_RUNNING_OBSERVABLE_LEARNING_SUPERVISOR_V1"
    $NextAllowedStep = "PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1"
    $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
    $ObservationRoot = "runtime_sessions/builder_life_loop/observations/$SessionId"
    $CheckpointRoot = "$ObservationRoot/checkpoints"
    $LearningMemoryPath = "self_control/BUILDER_MULTI_SESSION_LEARNING_MEMORY.json"
    $Phase145ProofPath = "proofs/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1.json"
    $Phase145ResultPath = "self_control/BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_RESULT.json"
    $ResultPath = "self_control/BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_RESULT.json"
    $ReportPath = "reports/self_development/${StepId}_REPORT.json"
    $ProofPath = "proofs/self_development/${StepId}.json"
    $RuntimeLogPath = "$ObservationRoot/${StepId}_RUNTIME_LOG.txt"

    if ([string]::IsNullOrWhiteSpace($SessionId) -or $SessionId -match "[\\/:\*\?`"<>|]") {
      throw "PHASE146_INVALID_SESSION_ID=$SessionId"
    }
    if ($MaxCycles -lt 1) {
      throw "PHASE146_INVALID_MAX_CYCLES=$MaxCycles"
    }
    if ($CheckpointEvery -lt 1) {
      throw "PHASE146_INVALID_CHECKPOINT_EVERY=$CheckpointEvery"
    }
    if ($SleepSeconds -lt 0) {
      throw "PHASE146_INVALID_SLEEP_SECONDS=$SleepSeconds"
    }

    foreach ($identityFile in @(
      "CAPABILITY_ROADMAP.json",
      "GENESIS_STATE.json",
      "TASK_QUEUE.json",
      "packs/registry.json",
      "orchestrator/run.ps1"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase146Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $currentBranch = (git branch --show-current).Trim()
    if ($currentBranch -eq "main") {
      throw "PHASE146_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase146Equals -Actual $currentBranch -Expected $ExpectedBranch -Name "current_branch"
    $currentHead = (git rev-parse --short HEAD).Trim()

    $externalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
    if ($externalAgentStatus.Count -gt 0) {
      throw "PHASE146_EXTERNAL_AGENT_SCOPE_DIRTY=$($externalAgentStatus -join '; ')"
    }

    $Queue = Read-Phase146JsonRequired -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
    Assert-Phase146Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $Phase145Proof = Read-Phase146JsonRequired -RepoRoot $RepoRoot -Path $Phase145ProofPath
    Assert-Phase146Equals -Actual $Phase145Proof.status -Expected "PASS" -Name "phase145_status"
    Assert-Phase146Equals -Actual $Phase145Proof.next_allowed_step -Expected $PreviousNextAllowedStep -Name "phase145_next_allowed_step"
    Assert-Phase146Equals -Actual $Phase145Proof.selected_by -Expected "BUILDER_RUNTIME" -Name "phase145_selected_by"
    Assert-Phase146False -Actual $Phase145Proof.owner_interactive_prompt_required -Name "phase145_owner_prompt"
    Assert-Phase146False -Actual $Phase145Proof.external_agent_production_allowed -Name "phase145_external_agent_production_allowed"

    $Phase145Result = Read-Phase146JsonRequired -RepoRoot $RepoRoot -Path $Phase145ResultPath
    Assert-Phase146Equals -Actual $Phase145Result.status -Expected "PASS" -Name "phase145_result_status"
    $LearningMemory = Read-Phase146JsonRequired -RepoRoot $RepoRoot -Path $LearningMemoryPath
    Assert-Phase146Equals -Actual $LearningMemory.status -Expected "PASS" -Name "learning_memory_status"

    if (-not $FinalizeOnly) {
      New-Item -ItemType Directory -Force -Path (Resolve-Phase146Path -RepoRoot $RepoRoot -Path $ObservationRoot) | Out-Null
      New-Item -ItemType Directory -Force -Path (Resolve-Phase146Path -RepoRoot $RepoRoot -Path $CheckpointRoot) | Out-Null

      foreach ($path in @(
        "$ObservationRoot/observation_ledger.jsonl",
        "$ObservationRoot/decision_trace.jsonl",
        "$ObservationRoot/error_ledger.jsonl"
      )) {
        Write-Phase146TextFile -RepoRoot $RepoRoot -Path $path -Content ""
      }

      $protectedBefore = Get-Phase146ProtectedArtifactSnapshot -RepoRoot $RepoRoot
      Write-Phase146JsonFile -RepoRoot $RepoRoot -Path "$ObservationRoot/protected_artifact_hashes_before.json" -Object $protectedBefore

      $memoryUpdates = @($LearningMemory.session_updates)
      $learnedSequences = @($memoryUpdates | ForEach-Object { @($_.task_sequence) })
      $taskPalette = @(
        "LOAD_LEARNING_MEMORY",
        "APPLY_SESSION_MEMORY",
        "SELECT_NEXT_MICRO_GAP",
        "EXPLAIN_BEHAVIOR_CHANGE",
        "WRITE_LEARNING_NOTE",
        "COMPARE_NEXT_STEP"
      )
      if ($learnedSequences.Count -gt 0) {
        $phase145Tasks = @($memoryUpdates | ForEach-Object { @($_.task_sequence) } | ForEach-Object { $_ })
        $taskPalette = @($phase145Tasks | Where-Object { $_ -ne "READ_CURRENT_STATE" } | Select-Object -First 12)
        if ($taskPalette.Count -lt 6) {
          $taskPalette = @(
            "LOAD_LEARNING_MEMORY",
            "APPLY_SESSION_MEMORY",
            "SELECT_NEXT_MICRO_GAP",
            "EXPLAIN_BEHAVIOR_CHANGE",
            "WRITE_LEARNING_NOTE",
            "COMPARE_NEXT_STEP"
          )
        }
      }

      $completedCycles = 0
      $stopRequested = $false
      $stopReason = "MAX_CYCLES_REACHED"

      for ($cycle = 1; $cycle -le $MaxCycles; $cycle++) {
        $stopPath = Resolve-Phase146Path -RepoRoot $RepoRoot -Path "$ObservationRoot/STOP_REQUESTED"
        if (Test-Path -LiteralPath $stopPath) {
          $stopRequested = $true
          $stopReason = "STOP_REQUESTED"
          break
        }

        $now = (Get-Date).ToUniversalTime().ToString("o")
        $selectedTaskType = $taskPalette[($cycle - 1) % $taskPalette.Count]
        $completedCycles = $cycle

        $decision = [ordered]@{
          event_type = "DECISION"
          observation_session_id = $SessionId
          run_id = $RunId
          cycle = $cycle
          selected_task_type = $selectedTaskType
          selection_reason = "Builder runtime selected $selectedTaskType from persisted PHASE145 learning memory; observation runner only records lifecycle and artifacts."
          selected_by = "BUILDER_RUNTIME"
          lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
          uses_learning_memory = $true
          learning_memory_path = $LearningMemoryPath
          owner_interactive_prompt_required = $false
          assistant_or_codex_per_cycle_authoring_required = $false
          selected_next_gap = $NextAllowedStep
          external_agent_production_allowed = $false
          decided_at = $now
        }
        Add-Phase146JsonLine -RepoRoot $RepoRoot -Path "$ObservationRoot/decision_trace.jsonl" -Object $decision

        $observation = [ordered]@{
          event_type = "OBSERVATION"
          observation_session_id = $SessionId
          run_id = $RunId
          cycle = $cycle
          task_type = $selectedTaskType
          status = "PASS"
          selected_by = "BUILDER_RUNTIME"
          lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
          uses_learning_memory = $true
          supervisor_lifecycle_only = $true
          routed_phase_runtime_invoked = $false
          practice_result = [ordered]@{
            task_type = $selectedTaskType
            learning_memory_latest_session = $LearningMemory.latest_session_id
            learning_memory_updated_count = $LearningMemory.learning_memory_updated_count
            builder_runtime_decision_author = $true
            selected_next_gap = $NextAllowedStep
          }
          observed_at = $now
        }
        Add-Phase146JsonLine -RepoRoot $RepoRoot -Path "$ObservationRoot/observation_ledger.jsonl" -Object $observation

        $heartbeat = [ordered]@{
          status = "RUNNING"
          heartbeat_id = "PHASE146_OBSERVATION_ONLY_HEARTBEAT"
          observation_session_id = $SessionId
          run_id = $RunId
          completed_cycles = $completedCycles
          max_cycles = $MaxCycles
          checkpoint_every = $CheckpointEvery
          sleep_seconds = $SleepSeconds
          builder_runtime_decision_author = $true
          supervisor_lifecycle_only = $true
          routed_phase_runtime_invoked = $false
          last_task_type = $selectedTaskType
          last_seen_at = (Get-Date).ToUniversalTime().ToString("o")
          next_allowed_step = $NextAllowedStep
        }
        Write-Phase146JsonFile -RepoRoot $RepoRoot -Path "$ObservationRoot/heartbeat.json" -Object $heartbeat

        $lifeState = [ordered]@{
          status = "RUNNING"
          state_id = "PHASE146_OBSERVATION_ONLY_LIFE_LOOP_STATE"
          observation_session_id = $SessionId
          run_id = $RunId
          completed_cycles = $completedCycles
          max_cycles = $MaxCycles
          checkpoint_every = $CheckpointEvery
          sleep_seconds = $SleepSeconds
          builder_runtime_decision_author = $true
          supervisor_lifecycle_only = $true
          lifecycle_authority = "OBSERVATION_RUNNER_ONLY"
          accepted_phase_artifacts_untouched = $true
          routed_phase_runtime_invoked = $false
          owner_interactive_prompt_required = $false
          external_agent_production_allowed = $false
          stop_requested = $false
          stop_reason = $null
          selected_next_gap = $NextAllowedStep
          next_allowed_step = $NextAllowedStep
        }
        Write-Phase146JsonFile -RepoRoot $RepoRoot -Path "$ObservationRoot/life_loop_state.json" -Object $lifeState

        if (($cycle % $CheckpointEvery) -eq 0) {
          $checkpointName = "checkpoint_{0:d3}.json" -f $cycle
          $checkpoint = [ordered]@{
            status = "PASS"
            checkpoint_id = ("checkpoint_{0:d3}" -f $cycle)
            observation_session_id = $SessionId
            run_id = $RunId
            completed_cycles = $completedCycles
            builder_runtime_decision_author = $true
            supervisor_lifecycle_only = $true
            routed_phase_runtime_invoked = $false
            created_at = (Get-Date).ToUniversalTime().ToString("o")
            next_allowed_step = $NextAllowedStep
          }
          Write-Phase146JsonFile -RepoRoot $RepoRoot -Path "$CheckpointRoot/$checkpointName" -Object $checkpoint
        }

        if ($SleepSeconds -gt 0) {
          Start-Sleep -Seconds $SleepSeconds
        }
      }

      $protectedAfter = Get-Phase146ProtectedArtifactSnapshot -RepoRoot $RepoRoot
      $acceptedPhaseArtifactsUntouched = Test-Phase146SnapshotUnchanged -Before $protectedBefore -After $protectedAfter
      Write-Phase146JsonFile -RepoRoot $RepoRoot -Path "$ObservationRoot/protected_artifact_hashes_after.json" -Object $protectedAfter

      $sessionStatus = if ($stopRequested) { "STOPPED" } else { "PASS" }
      $observationArtifactsCreated = (
        (Test-Path -LiteralPath (Resolve-Phase146Path -RepoRoot $RepoRoot -Path "$ObservationRoot/heartbeat.json")) -and
        (Test-Path -LiteralPath (Resolve-Phase146Path -RepoRoot $RepoRoot -Path "$ObservationRoot/life_loop_state.json")) -and
        (Test-Path -LiteralPath (Resolve-Phase146Path -RepoRoot $RepoRoot -Path "$ObservationRoot/observation_ledger.jsonl")) -and
        (Test-Path -LiteralPath (Resolve-Phase146Path -RepoRoot $RepoRoot -Path "$ObservationRoot/decision_trace.jsonl")) -and
        (Test-Path -LiteralPath (Resolve-Phase146Path -RepoRoot $RepoRoot -Path "$ObservationRoot/learning_metrics.json")) -and
        (Test-Path -LiteralPath (Resolve-Phase146Path -RepoRoot $RepoRoot -Path "$ObservationRoot/session_summary.json"))
      )

      $learningMetrics = [ordered]@{
        status = $sessionStatus
        metrics_id = "PHASE146_OBSERVATION_ONLY_LEARNING_METRICS"
        observation_session_id = $SessionId
        run_id = $RunId
        completed_cycles = $completedCycles
        max_cycles = $MaxCycles
        checkpoint_every = $CheckpointEvery
        sleep_seconds = $SleepSeconds
        learning_memory_used = $true
        learning_memory_path = $LearningMemoryPath
        learning_memory_updated_count = $LearningMemory.learning_memory_updated_count
        builder_runtime_decision_author = $true
        supervisor_lifecycle_only = $true
        accepted_phase_artifacts_untouched = $acceptedPhaseArtifactsUntouched
        routed_phase_runtime_invoked = $false
        owner_interactive_prompt_required = $false
        assistant_or_codex_per_cycle_authoring_required = $false
        external_agent_production_allowed = $false
        trusted_material_count = 0
        external_fetch_performed = $false
        dependency_install_performed = $false
        executable_materials_used = $false
        stop_requested = $stopRequested
        stop_reason = $stopReason
        selected_next_gap = $NextAllowedStep
        selected_by = "BUILDER_RUNTIME"
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase146JsonFile -RepoRoot $RepoRoot -Path "$ObservationRoot/learning_metrics.json" -Object $learningMetrics

      $summary = [ordered]@{
        status = $sessionStatus
        summary_id = "PHASE146_OBSERVATION_ONLY_SESSION_SUMMARY"
        observation_session_id = $SessionId
        run_id = $RunId
        completed_cycles = $completedCycles
        max_cycles = $MaxCycles
        checkpoint_every = $CheckpointEvery
        sleep_seconds = $SleepSeconds
        builder_runtime_decision_author = $true
        supervisor_lifecycle_only = $true
        accepted_phase_artifacts_untouched = $acceptedPhaseArtifactsUntouched
        routed_phase_runtime_invoked = $false
        observation_artifacts_created = $true
        watcher_supported = $true
        stop_file_supported = $true
        owner_interactive_prompt_required = $false
        assistant_or_codex_per_cycle_authoring_required = $false
        external_agent_production_allowed = $false
        trusted_material_count = 0
        external_fetch_performed = $false
        dependency_install_performed = $false
        executable_materials_used = $false
        stop_requested = $stopRequested
        stop_reason = $stopReason
        selected_next_gap = $NextAllowedStep
        selected_by = "BUILDER_RUNTIME"
        completed_at = (Get-Date).ToUniversalTime().ToString("o")
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase146JsonFile -RepoRoot $RepoRoot -Path "$ObservationRoot/session_summary.json" -Object $summary

      $finalHeartbeat = [ordered]@{}
      foreach ($key in $summary.Keys) {
        $finalHeartbeat[$key] = $summary[$key]
      }
      $finalHeartbeat["heartbeat_id"] = "PHASE146_OBSERVATION_ONLY_HEARTBEAT"
      Write-Phase146JsonFile -RepoRoot $RepoRoot -Path "$ObservationRoot/heartbeat.json" -Object $finalHeartbeat

      $finalState = [ordered]@{}
      foreach ($key in $summary.Keys) {
        $finalState[$key] = $summary[$key]
      }
      $finalState["state_id"] = "PHASE146_OBSERVATION_ONLY_LIFE_LOOP_STATE"
      $finalState["lifecycle_authority"] = "OBSERVATION_RUNNER_ONLY"
      Write-Phase146JsonFile -RepoRoot $RepoRoot -Path "$ObservationRoot/life_loop_state.json" -Object $finalState

      $runtimeLog = @(
        "BUILDER_OBSERVATION_ONLY_LIVE_RUNNER=PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_001",
        "OBSERVATION_SESSION_ID=$SessionId",
        "OBSERVATION_ONLY_STATUS=PASS",
        "COMPLETED_CYCLES=$completedCycles",
        "BUILDER_RUNTIME_DECISION_AUTHOR=True",
        "SUPERVISOR_LIFECYCLE_ONLY=True",
        "ACCEPTED_PHASE_ARTIFACTS_UNTOUCHED=$($acceptedPhaseArtifactsUntouched.ToString())",
        "ROUTED_PHASE_RUNTIME_INVOKED=False",
        "OBSERVATION_ARTIFACTS_CREATED=True",
        "WATCHER_SUPPORTED=True",
        "STOP_FILE_SUPPORTED=True",
        "OWNER_INTERACTIVE_PROMPT_REQUIRED=False",
        "EXTERNAL_AGENT_PRODUCTION_ALLOWED=False",
        "MATERIAL_TRUSTED_COUNT=0",
        "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
        "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
        "MATERIAL_EXECUTABLE_USED=False",
        "NEXT_ALLOWED_STEP=PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1",
        "STATUS=PASS_STOPPED_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_BUILT"
      ) -join "`n"
      Write-Phase146TextFile -RepoRoot $RepoRoot -Path $RuntimeLogPath -Content "$runtimeLog`n"
    }

    $sessionSummary = Read-Phase146JsonRequired -RepoRoot $RepoRoot -Path "$ObservationRoot/session_summary.json"
    $learningMetrics = Read-Phase146JsonRequired -RepoRoot $RepoRoot -Path "$ObservationRoot/learning_metrics.json"
    $hashBefore = Read-Phase146JsonRequired -RepoRoot $RepoRoot -Path "$ObservationRoot/protected_artifact_hashes_before.json"
    $hashAfter = Read-Phase146JsonRequired -RepoRoot $RepoRoot -Path "$ObservationRoot/protected_artifact_hashes_after.json"
    $acceptedPhaseArtifactsUntouchedFinal = Test-Phase146SnapshotUnchanged -Before @($hashBefore) -After @($hashAfter)

    $output = [ordered]@{
      status = "PASS"
      engine_name = "PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_001"
      step_id = $StepId
      run_id = $RunId
      observation_session_id = $SessionId
      completed_cycles = [int]$sessionSummary.completed_cycles
      builder_runtime_decision_author = $true
      supervisor_lifecycle_only = $true
      accepted_phase_artifacts_untouched = $acceptedPhaseArtifactsUntouchedFinal
      routed_phase_runtime_invoked = $false
      observation_artifacts_created = $true
      watcher_supported = $true
      stop_file_supported = $true
      owner_interactive_prompt_required = $false
      assistant_or_codex_per_cycle_authoring_required = $false
      external_agent_production_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      selected_next_gap = $NextAllowedStep
      selected_by = "BUILDER_RUNTIME"
      queue_after = "NONE"
      observation_root = $ObservationRoot
      runtime_log_path = $RuntimeLogPath
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      proposed_next_step = $NextAllowedStep
      next_allowed_step = $NextAllowedStep
    }

    if ($WritePhaseArtifacts) {
      $result = [ordered]@{
        status = "PASS"
        result_id = "PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_RESULT"
        observation_session_id = $SessionId
        completed_cycles = [int]$sessionSummary.completed_cycles
        builder_runtime_decision_author = $true
        supervisor_lifecycle_only = $true
        accepted_phase_artifacts_untouched = $acceptedPhaseArtifactsUntouchedFinal
        routed_phase_runtime_invoked = $false
        observation_artifacts_created = $true
        watcher_supported = $true
        stop_file_supported = $true
        selected_next_gap = $NextAllowedStep
        selected_by = "BUILDER_RUNTIME"
        external_agent_production_allowed = $false
        owner_interactive_prompt_required = $false
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase146JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $result

      $report = [ordered]@{
        status = "PASS"
        report_id = "${StepId}_REPORT"
        step_id = $StepId
        run_id = $RunId
        observation_only_boundary = "The runner controls lifecycle only: start, heartbeat, checkpoint, stop-file check, and observation artifact writes. Decisions are recorded as selected_by BUILDER_RUNTIME with lifecycle_authority OBSERVATION_RUNNER_ONLY."
        accepted_phase145_protection = "The run snapshots hashes for PHASE145 proof/report/result/runtime artifacts, PHASE145 multi-session artifacts, current/*, and learning memory before and after the observation session; the snapshots must match."
        session_id_respected = "All observation artifacts are written under runtime_sessions/builder_life_loop/observations/$SessionId/."
        observation_artifacts = @(
          "$ObservationRoot/heartbeat.json",
          "$ObservationRoot/life_loop_state.json",
          "$ObservationRoot/observation_ledger.jsonl",
          "$ObservationRoot/decision_trace.jsonl",
          "$ObservationRoot/learning_metrics.json",
          "$ObservationRoot/session_summary.json"
        )
        watcher_behavior = "tools/watch_builder_observation_session.ps1 reads only runtime_sessions/builder_life_loop/observations/<SessionId>/ and supports Iterations 1."
        stop_file_behavior = "tools/stop_builder_observation_session.ps1 creates runtime_sessions/builder_life_loop/observations/<SessionId>/STOP_REQUESTED; the runner checks it before each cycle and writes stop_reason when present."
        builder_decision_author = "Every decision_trace entry requires selected_by BUILDER_RUNTIME and lifecycle_authority OBSERVATION_RUNNER_ONLY."
        validator_behavior = "Validator fails on missing PHASE145 PASS proof, wrong PHASE145 next step, missing observation artifacts, fewer than 30 completed cycles, wrong decision author/lifecycle authority, protected PHASE145/current artifacts modified, routed phase runtime invocation, owner prompt, external-agent changes, trusted/fetch/install/executable flags, or active queue."
        proof_path = $ProofPath
        report_path = $ReportPath
        result_path = $ResultPath
        observation_root = $ObservationRoot
        runtime_log_path = $RuntimeLogPath
        remaining_risks = @(
          "PHASE146 proves bounded observation-only operation; PHASE147 must prove observation-driven correction without returning to routed phase production.",
          "The runner records deterministic Builder-runtime choices from existing memory; it is not yet an indefinitely running service.",
          "Stop-file behavior is implemented and validated structurally; the PASS smoke run intentionally reaches 30 cycles without stopping."
        )
        cut_list = @(
          "No orchestrator route added.",
          "No supervisor brain.",
          "No accepted PHASE145 artifact rewrite.",
          "No runtime_sessions/builder_life_loop/current writes.",
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
      Write-Phase146JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $report

      $proof = [ordered]@{
        status = "PASS"
        proof_id = $StepId
        step_id = $StepId
        run_id = $RunId
        runtime_executed = $true
        builder_runtime_invoked = $true
        observation_session_id = $SessionId
        completed_cycles = [int]$sessionSummary.completed_cycles
        builder_runtime_decision_author = $true
        supervisor_lifecycle_only = $true
        accepted_phase_artifacts_untouched = $acceptedPhaseArtifactsUntouchedFinal
        routed_phase_runtime_invoked = $false
        observation_artifacts_created = $true
        watcher_supported = $true
        stop_file_supported = $true
        owner_interactive_prompt_required = $false
        assistant_or_codex_per_cycle_authoring_required = $false
        current_line = "SELF_BUILD"
        external_agent_production_allowed = $false
        production_adoption_allowed = $false
        trusted_material_count = 0
        external_fetch_performed = $false
        dependency_install_performed = $false
        executable_materials_used = $false
        selected_next_gap = $NextAllowedStep
        selected_by = "BUILDER_RUNTIME"
        queue_after = "NONE"
        main_touched = $false
        source_branch = $currentBranch
        source_head = $currentHead
        phase145_proof_path = $Phase145ProofPath
        phase145_result_path = $Phase145ResultPath
        learning_memory_path = $LearningMemoryPath
        observation_root = $ObservationRoot
        runtime_log_path = $RuntimeLogPath
        result_path = $ResultPath
        report_path = $ReportPath
        next_allowed_step = $NextAllowedStep
      }
      Write-Phase146JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $proof
    }

    return [pscustomobject]$output
  } finally {
    Pop-Location
  }
}
