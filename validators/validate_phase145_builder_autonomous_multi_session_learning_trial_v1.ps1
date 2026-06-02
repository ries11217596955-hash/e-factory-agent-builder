param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase145ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase145ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase145ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE145_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase145ValidatorText {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase145ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE145_VALIDATE_MISSING_TEXT=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw
}

function Read-Phase145ValidatorJsonLines {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase145ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE145_VALIDATE_MISSING_JSONL=$Path"
  }

  return @(Get-Content -LiteralPath $fullPath |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { ConvertFrom-Json $_ })
}

function Assert-Phase145ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE145_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase145ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE145_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase145ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE145_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase145ValidatorAtLeast {
  param(
    [object]$Actual,
    [int]$Minimum,
    [string]$Name
  )

  if ([int]$Actual -lt $Minimum) {
    throw "PHASE145_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase145ValidatorContains {
  param(
    [string]$Text,
    [string]$Needle,
    [string]$Name
  )

  if (-not $Text.Contains($Needle)) {
    throw "PHASE145_VALIDATE_TEXT_MISSING=$Name needle=$Needle"
  }
}

try {
  $StepId = "PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1"
  $PreviousStepId = "PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1"
  $NextAllowedStep = "PHASE146_BUILDER_LONG_RUNNING_OBSERVABLE_LEARNING_SUPERVISOR_V1"
  $RuntimeId = "PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_001"
  $BaselineSessionId = "LIVE_LOOP_002"
  $Phase143TrialSessionId = "PHASE143_CORRECTION_RESPONSE_TRIAL_001"
  $Phase144TrialSessionId = "PHASE144_BEHAVIOR_ADAPTATION_SCALE_TRIAL_001"
  $TrialSessionId = "PHASE145_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_001"

  $RepoRoot = Resolve-Phase145ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot

  foreach ($identityFile in @(
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1"
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase145ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE145_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }

  $Phase144ProofPath = "proofs/self_development/${PreviousStepId}.json"
  $Phase144ResultPath = "self_control/BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_RESULT.json"
  $BaselineRoot = "runtime_sessions/builder_life_loop/observations/$BaselineSessionId"
  $Phase143TrialRoot = "runtime_sessions/builder_life_loop/correction_trials/$Phase143TrialSessionId"
  $Phase144TrialRoot = "runtime_sessions/builder_life_loop/adaptation_trials/$Phase144TrialSessionId"
  $TrialRoot = "runtime_sessions/builder_life_loop/multi_session_trials/$TrialSessionId"
  $CurrentRoot = "runtime_sessions/builder_life_loop/current"
  $OutputRoot = "self_build_batch/autonomy_trials/$StepId"
  $LearningMemoryPath = "self_control/BUILDER_MULTI_SESSION_LEARNING_MEMORY.json"
  $TrialResultPath = "self_control/BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_RESULT.json"
  $OutputPath = "$OutputRoot/BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_OUTPUT.json"
  $ResultPath = "$OutputRoot/${StepId}_RESULT.json"
  $RuntimeLogPath = "$OutputRoot/${StepId}_RUNTIME_LOG.txt"
  $ReportPath = "reports/self_development/${StepId}_REPORT.json"
  $ProofPath = "proofs/self_development/${StepId}.json"
  $MultiSessionSummaryPath = "$TrialRoot/multi_session_summary.json"
  $CrossSessionDecisionPath = "$TrialRoot/cross_session_decision_trace.jsonl"
  $LearningMemorySnapshotsPath = "$TrialRoot/learning_memory_snapshots.jsonl"

  foreach ($requiredPath in @(
    "modules/invoke_builder_autonomous_multi_session_learning_trial_001.ps1",
    "validators/validate_phase145_builder_autonomous_multi_session_learning_trial_v1.ps1",
    "orchestrator/run.ps1",
    $Phase144ProofPath,
    $Phase144ResultPath,
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
    "$Phase144TrialRoot/adaptation_metrics.json",
    "$CurrentRoot/heartbeat.json",
    "$CurrentRoot/life_loop_state.json",
    "$CurrentRoot/observation_ledger.jsonl",
    "$CurrentRoot/decision_trace.jsonl",
    "$CurrentRoot/learning_metrics.json",
    "$CurrentRoot/session_summary.json",
    $LearningMemoryPath,
    $TrialResultPath,
    $OutputPath,
    $ResultPath,
    $RuntimeLogPath,
    $ReportPath,
    $ProofPath,
    $MultiSessionSummaryPath,
    $CrossSessionDecisionPath,
    $LearningMemorySnapshotsPath
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase145ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE145_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  foreach ($sessionDir in @("session_001", "session_002", "session_003")) {
    foreach ($sessionFile in @(
      "heartbeat.json",
      "life_loop_state.json",
      "observation_ledger.jsonl",
      "decision_trace.jsonl",
      "learning_metrics.json",
      "session_summary.json"
    )) {
      $sessionPath = "$TrialRoot/$sessionDir/$sessionFile"
      if (-not (Test-Path -LiteralPath (Resolve-Phase145ValidatorPath -RepoRoot $RepoRoot -Path $sessionPath))) {
        throw "PHASE145_VALIDATE_MISSING_SESSION_ARTIFACT=$sessionPath"
      }
    }
  }

  $SessionDirectories = @(Get-ChildItem -LiteralPath (Resolve-Phase145ValidatorPath -RepoRoot $RepoRoot -Path $TrialRoot) -Directory | Where-Object { $_.Name -like "session_*" })
  Assert-Phase145ValidatorEquals -Actual $SessionDirectories.Count -Expected 3 -Name "session_directory_count"

  $Phase144Proof = Read-Phase145ValidatorJson -RepoRoot $RepoRoot -Path $Phase144ProofPath
  Assert-Phase145ValidatorEquals -Actual $Phase144Proof.status -Expected "PASS" -Name "phase144_status"
  Assert-Phase145ValidatorEquals -Actual $Phase144Proof.next_allowed_step -Expected $StepId -Name "phase144_next_allowed_step"
  Assert-Phase145ValidatorAtLeast -Actual $Phase144Proof.corrections_seen_count -Minimum 3 -Name "phase144_corrections_seen_count"
  Assert-Phase145ValidatorAtLeast -Actual $Phase144Proof.corrections_applied_count -Minimum 3 -Name "phase144_corrections_applied_count"
  Assert-Phase145ValidatorAtLeast -Actual $Phase144Proof.behavior_changes_count -Minimum 3 -Name "phase144_behavior_changes_count"
  Assert-Phase145ValidatorTrue -Actual $Phase144Proof.adaptation_scaled -Name "phase144_adaptation_scaled"
  Assert-Phase145ValidatorTrue -Actual $Phase144Proof.repeated_safe_carousel_reduced -Name "phase144_repeated_safe_carousel_reduced"
  Assert-Phase145ValidatorEquals -Actual $Phase144Proof.selected_next_gap -Expected $StepId -Name "phase144_selected_next_gap"
  Assert-Phase145ValidatorEquals -Actual $Phase144Proof.selected_by -Expected "BUILDER_RUNTIME" -Name "phase144_selected_by"
  Assert-Phase145ValidatorFalse -Actual $Phase144Proof.owner_interactive_prompt_required -Name "phase144_owner_interactive_prompt_required"
  Assert-Phase145ValidatorFalse -Actual $Phase144Proof.external_agent_production_allowed -Name "phase144_external_agent_production_allowed"
  Assert-Phase145ValidatorEquals -Actual $Phase144Proof.trusted_material_count -Expected 0 -Name "phase144_trusted_material_count"
  Assert-Phase145ValidatorFalse -Actual $Phase144Proof.external_fetch_performed -Name "phase144_external_fetch_performed"
  Assert-Phase145ValidatorFalse -Actual $Phase144Proof.dependency_install_performed -Name "phase144_dependency_install_performed"
  Assert-Phase145ValidatorFalse -Actual $Phase144Proof.executable_materials_used -Name "phase144_executable_materials_used"

  $Phase144Result = Read-Phase145ValidatorJson -RepoRoot $RepoRoot -Path $Phase144ResultPath
  Assert-Phase145ValidatorEquals -Actual $Phase144Result.status -Expected "PASS" -Name "phase144_result_status"
  Assert-Phase145ValidatorEquals -Actual $Phase144Result.next_allowed_step -Expected $StepId -Name "phase144_result_next_allowed_step"

  $Output = Read-Phase145ValidatorJson -RepoRoot $RepoRoot -Path $OutputPath
  $Result = Read-Phase145ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase145ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase145ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath
  $TrialResult = Read-Phase145ValidatorJson -RepoRoot $RepoRoot -Path $TrialResultPath
  $LearningMemory = Read-Phase145ValidatorJson -RepoRoot $RepoRoot -Path $LearningMemoryPath
  $MultiSessionSummary = Read-Phase145ValidatorJson -RepoRoot $RepoRoot -Path $MultiSessionSummaryPath

  foreach ($artifact in @($Output, $Result, $Report, $Proof, $TrialResult, $LearningMemory, $MultiSessionSummary)) {
    Assert-Phase145ValidatorEquals -Actual $artifact.status -Expected "PASS" -Name "artifact_status"
  }

  foreach ($artifact in @($Output, $Result, $Proof, $TrialResult, $LearningMemory, $MultiSessionSummary)) {
    Assert-Phase145ValidatorEquals -Actual $artifact.next_allowed_step -Expected $NextAllowedStep -Name "next_allowed_step"
  }

  foreach ($artifact in @($Output, $Proof, $TrialResult, $MultiSessionSummary)) {
    Assert-Phase145ValidatorEquals -Actual $artifact.sessions_completed_count -Expected 3 -Name "sessions_completed_count"
    Assert-Phase145ValidatorTrue -Actual $artifact.learning_memory_created -Name "learning_memory_created"
    Assert-Phase145ValidatorAtLeast -Actual $artifact.learning_memory_updated_count -Minimum 3 -Name "learning_memory_updated_count"
    Assert-Phase145ValidatorTrue -Actual $artifact.cross_session_carryover_detected -Name "cross_session_carryover_detected"
    Assert-Phase145ValidatorTrue -Actual $artifact.behavior_changed_between_sessions -Name "behavior_changed_between_sessions"
    Assert-Phase145ValidatorTrue -Actual $artifact.old_safe_carousel_not_repeated -Name "old_safe_carousel_not_repeated"
    Assert-Phase145ValidatorAtLeast -Actual $artifact.autonomous_next_task_selection_count -Minimum 3 -Name "autonomous_next_task_selection_count"
    Assert-Phase145ValidatorEquals -Actual $artifact.baseline_session -Expected $BaselineSessionId -Name "baseline_session"
    Assert-Phase145ValidatorEquals -Actual $artifact.phase143_trial_session -Expected $Phase143TrialSessionId -Name "phase143_trial_session"
    Assert-Phase145ValidatorEquals -Actual $artifact.phase144_trial_session -Expected $Phase144TrialSessionId -Name "phase144_trial_session"
    Assert-Phase145ValidatorEquals -Actual $artifact.trial_session -Expected $TrialSessionId -Name "trial_session"
    Assert-Phase145ValidatorEquals -Actual $artifact.selected_next_gap -Expected $NextAllowedStep -Name "selected_next_gap"
    Assert-Phase145ValidatorEquals -Actual $artifact.selected_by -Expected "BUILDER_RUNTIME" -Name "selected_by"
    Assert-Phase145ValidatorFalse -Actual $artifact.owner_interactive_prompt_required -Name "owner_interactive_prompt_required"
    Assert-Phase145ValidatorFalse -Actual $artifact.external_agent_production_allowed -Name "external_agent_production_allowed"
  }

  foreach ($artifact in @($Output, $Proof, $MultiSessionSummary)) {
    Assert-Phase145ValidatorEquals -Actual $artifact.trusted_material_count -Expected 0 -Name "trusted_material_count"
    Assert-Phase145ValidatorFalse -Actual $artifact.external_fetch_performed -Name "external_fetch_performed"
    Assert-Phase145ValidatorFalse -Actual $artifact.dependency_install_performed -Name "dependency_install_performed"
    Assert-Phase145ValidatorFalse -Actual $artifact.executable_materials_used -Name "executable_materials_used"
  }

  Assert-Phase145ValidatorEquals -Actual $Output.engine_name -Expected $RuntimeId -Name "output_engine_name"
  Assert-Phase145ValidatorEquals -Actual $Proof.run_id -Expected $RuntimeId -Name "proof_run_id"
  Assert-Phase145ValidatorTrue -Actual $Proof.runtime_executed -Name "proof_runtime_executed"
  Assert-Phase145ValidatorTrue -Actual $Proof.builder_runtime_invoked -Name "proof_builder_runtime_invoked"
  Assert-Phase145ValidatorEquals -Actual $Proof.current_line -Expected "SELF_BUILD" -Name "proof_current_line"
  Assert-Phase145ValidatorFalse -Actual $Proof.production_adoption_allowed -Name "proof_production_adoption_allowed"
  Assert-Phase145ValidatorEquals -Actual $Output.queue_after -Expected "NONE" -Name "output_queue_after"
  Assert-Phase145ValidatorEquals -Actual $Result.queue_after -Expected "NONE" -Name "result_queue_after"
  Assert-Phase145ValidatorEquals -Actual $Proof.queue_after -Expected "NONE" -Name "proof_queue_after"
  Assert-Phase145ValidatorFalse -Actual $Proof.main_touched -Name "proof_main_touched"
  Assert-Phase145ValidatorEquals -Actual $Proof.source_branch -Expected $Branch -Name "proof_source_branch"
  Assert-Phase145ValidatorFalse -Actual $Proof.assistant_or_codex_per_session_authoring_required -Name "proof_assistant_or_codex_authoring"
  Assert-Phase145ValidatorFalse -Actual $MultiSessionSummary.assistant_or_codex_per_session_authoring_required -Name "summary_assistant_or_codex_authoring"

  $MemoryUpdates = @($LearningMemory.session_updates)
  Assert-Phase145ValidatorAtLeast -Actual $MemoryUpdates.Count -Minimum 3 -Name "memory_session_updates"
  foreach ($expectedSession in @("PHASE145_MULTI_SESSION_001", "PHASE145_MULTI_SESSION_002", "PHASE145_MULTI_SESSION_003")) {
    if (-not @($MemoryUpdates | Where-Object { $_.session_id -eq $expectedSession })) {
      throw "PHASE145_VALIDATE_MEMORY_UPDATE_MISSING_SESSION=$expectedSession"
    }
  }
  if (-not @($MemoryUpdates | Where-Object { $_.session_id -eq "PHASE145_MULTI_SESSION_002" -and $_.memory_source -eq "PHASE145_MULTI_SESSION_001" })) {
    throw "PHASE145_VALIDATE_SESSION_002_MEMORY_SOURCE_MISSING"
  }
  if (-not @($MemoryUpdates | Where-Object { $_.session_id -eq "PHASE145_MULTI_SESSION_003" -and "$($_.memory_source)".Contains("PHASE145_MULTI_SESSION_002") })) {
    throw "PHASE145_VALIDATE_SESSION_003_MEMORY_SOURCE_MISSING"
  }

  $Snapshots = Read-Phase145ValidatorJsonLines -RepoRoot $RepoRoot -Path $LearningMemorySnapshotsPath
  Assert-Phase145ValidatorAtLeast -Actual $Snapshots.Count -Minimum 4 -Name "learning_memory_snapshots_count"
  Assert-Phase145ValidatorAtLeast -Actual $Snapshots[-1].learning_memory_updated_count -Minimum 3 -Name "final_snapshot_update_count"

  $CrossSessionDecisions = Read-Phase145ValidatorJsonLines -RepoRoot $RepoRoot -Path $CrossSessionDecisionPath
  Assert-Phase145ValidatorEquals -Actual $CrossSessionDecisions.Count -Expected 24 -Name "cross_session_decision_count"
  Assert-Phase145ValidatorAtLeast -Actual @($CrossSessionDecisions | Where-Object { $_.autonomous_task_selection -eq $true }).Count -Minimum 3 -Name "autonomous_task_selection_decisions"
  if (@($CrossSessionDecisions | Where-Object { $_.new_owner_correction_supplied -ne $false }).Count -gt 0) {
    throw "PHASE145_VALIDATE_NEW_OWNER_CORRECTION_DETECTED"
  }
  if (@($CrossSessionDecisions | Where-Object { $_.assistant_or_codex_per_session_authoring_required -ne $false }).Count -gt 0) {
    throw "PHASE145_VALIDATE_ASSISTANT_OR_CODEX_AUTHORING_REQUIRED"
  }

  $SessionSequences = @()
  foreach ($sessionDir in @("session_001", "session_002", "session_003")) {
    $SessionRoot = "$TrialRoot/$sessionDir"
    $SessionSummary = Read-Phase145ValidatorJson -RepoRoot $RepoRoot -Path "$SessionRoot/session_summary.json"
    $SessionMetrics = Read-Phase145ValidatorJson -RepoRoot $RepoRoot -Path "$SessionRoot/learning_metrics.json"
    $SessionDecisions = Read-Phase145ValidatorJsonLines -RepoRoot $RepoRoot -Path "$SessionRoot/decision_trace.jsonl"
    $SessionObservations = Read-Phase145ValidatorJsonLines -RepoRoot $RepoRoot -Path "$SessionRoot/observation_ledger.jsonl"

    foreach ($sessionArtifact in @($SessionSummary, $SessionMetrics)) {
      Assert-Phase145ValidatorEquals -Actual $sessionArtifact.status -Expected "PASS" -Name "session_artifact_status"
      Assert-Phase145ValidatorEquals -Actual $sessionArtifact.completed_cycles -Expected 8 -Name "session_completed_cycles"
      Assert-Phase145ValidatorEquals -Actual $sessionArtifact.max_cycles -Expected 8 -Name "session_max_cycles"
      Assert-Phase145ValidatorEquals -Actual $sessionArtifact.checkpoint_every -Expected 4 -Name "session_checkpoint_every"
      Assert-Phase145ValidatorTrue -Actual $sessionArtifact.old_safe_carousel_not_repeated -Name "session_old_safe_carousel_not_repeated"
      Assert-Phase145ValidatorFalse -Actual $sessionArtifact.new_owner_correction_supplied -Name "session_new_owner_correction_supplied"
      Assert-Phase145ValidatorFalse -Actual $sessionArtifact.owner_interactive_prompt_required -Name "session_owner_prompt"
      Assert-Phase145ValidatorFalse -Actual $sessionArtifact.assistant_or_codex_per_session_authoring_required -Name "session_assistant_or_codex_authoring"
      Assert-Phase145ValidatorEquals -Actual $sessionArtifact.selected_next_gap -Expected $NextAllowedStep -Name "session_selected_next_gap"
      Assert-Phase145ValidatorEquals -Actual $sessionArtifact.selected_by -Expected "BUILDER_RUNTIME" -Name "session_selected_by"
    }

    Assert-Phase145ValidatorEquals -Actual $SessionDecisions.Count -Expected 8 -Name "session_decision_count"
    Assert-Phase145ValidatorEquals -Actual $SessionObservations.Count -Expected 8 -Name "session_observation_count"
    $SessionSequences += ,@($SessionDecisions | ForEach-Object { $_.selected_task_type })
  }

  if (($SessionSequences[0] -join ",") -eq ($SessionSequences[1] -join ",")) {
    throw "PHASE145_VALIDATE_SESSION_002_DID_NOT_CHANGE_FROM_SESSION_001"
  }
  if (($SessionSequences[0] -join ",") -eq ($SessionSequences[2] -join ",")) {
    throw "PHASE145_VALIDATE_SESSION_003_DID_NOT_CHANGE_FROM_SESSION_001"
  }

  $BaselineDecisions = Read-Phase145ValidatorJsonLines -RepoRoot $RepoRoot -Path "$BaselineRoot/decision_trace.jsonl"
  $Phase143Decisions = Read-Phase145ValidatorJsonLines -RepoRoot $RepoRoot -Path "$Phase143TrialRoot/decision_trace.jsonl"
  $Phase144Decisions = Read-Phase145ValidatorJsonLines -RepoRoot $RepoRoot -Path "$Phase144TrialRoot/decision_trace.jsonl"
  $BaselineSequence = @($BaselineDecisions | ForEach-Object { $_.selected_task_type } | Select-Object -First 24)
  $Phase143Sequence = @($Phase143Decisions | ForEach-Object { $_.selected_task_type } | Select-Object -First 12)
  $Phase144Sequence = @($Phase144Decisions | ForEach-Object { $_.selected_task_type } | Select-Object -First 18)
  $Phase145CombinedSequence = @($SessionSequences[0] + $SessionSequences[1] + $SessionSequences[2])

  if ($BaselineSequence.Count -lt 24) {
    throw "PHASE145_VALIDATE_BASELINE_SEQUENCE_TOO_SHORT=$($BaselineSequence.Count)"
  }
  if ($Phase143Sequence.Count -lt 12) {
    throw "PHASE145_VALIDATE_PHASE143_SEQUENCE_TOO_SHORT=$($Phase143Sequence.Count)"
  }
  if ($Phase144Sequence.Count -lt 18) {
    throw "PHASE145_VALIDATE_PHASE144_SEQUENCE_TOO_SHORT=$($Phase144Sequence.Count)"
  }
  if (($Phase145CombinedSequence -join ",") -eq ($BaselineSequence -join ",")) {
    throw "PHASE145_VALIDATE_BEHAVIOR_DID_NOT_CHANGE_FROM_BASELINE"
  }
  if ((@($Phase145CombinedSequence | Select-Object -First 12) -join ",") -eq ($Phase143Sequence -join ",")) {
    throw "PHASE145_VALIDATE_BEHAVIOR_DID_NOT_CHANGE_FROM_PHASE143"
  }
  if ((@($Phase145CombinedSequence | Select-Object -First 18) -join ",") -eq ($Phase144Sequence -join ",")) {
    throw "PHASE145_VALIDATE_BEHAVIOR_DID_NOT_CHANGE_FROM_PHASE144"
  }
  $BaselineReadStateCount = @($BaselineSequence | Where-Object { $_ -eq "READ_CURRENT_STATE" }).Count
  $Phase145ReadStateCount = @($Phase145CombinedSequence | Where-Object { $_ -eq "READ_CURRENT_STATE" }).Count
  if ($Phase145ReadStateCount -ge $BaselineReadStateCount) {
    throw "PHASE145_VALIDATE_OLD_SAFE_CAROUSEL_REPEATED baseline_read_state=$BaselineReadStateCount phase145_read_state=$Phase145ReadStateCount"
  }

  $OrchestratorText = Read-Phase145ValidatorText -RepoRoot $RepoRoot -Path "orchestrator/run.ps1"
  Assert-Phase145ValidatorContains -Text $OrchestratorText -Needle "Invoke-BuilderAutonomousMultiSessionLearningTrial001" -Name "orchestrator_hook"
  Assert-Phase145ValidatorContains -Text $OrchestratorText -Needle "BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL=PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_001" -Name "orchestrator_runtime_signal"

  $RuntimeLog = Read-Phase145ValidatorText -RepoRoot $RepoRoot -Path $RuntimeLogPath
  foreach ($signal in @(
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
  )) {
    Assert-Phase145ValidatorContains -Text $RuntimeLog -Needle $signal -Name "runtime_log_signal"
  }

  $Queue = Read-Phase145ValidatorJson -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
  Assert-Phase145ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  $ExternalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
  if ($ExternalAgentStatus.Count -gt 0) {
    throw "PHASE145_VALIDATE_EXTERNAL_AGENT_SCOPE_DIRTY=$($ExternalAgentStatus -join '; ')"
  }

  Write-Host "PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_VALIDATE_RESULT=PASS"
  Write-Host "SESSIONS_COMPLETED_COUNT=$($Proof.sessions_completed_count)"
  Write-Host "LEARNING_MEMORY_UPDATED_COUNT=$($Proof.learning_memory_updated_count)"
  Write-Host "CROSS_SESSION_CARRYOVER_DETECTED=$($Proof.cross_session_carryover_detected)"
  Write-Host "OLD_SAFE_CAROUSEL_NOT_REPEATED=$($Proof.old_safe_carousel_not_repeated)"
  Write-Host "NEXT_ALLOWED_STEP=$($Proof.next_allowed_step)"
} catch {
  Write-Host "PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE145_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  Pop-Location
}
