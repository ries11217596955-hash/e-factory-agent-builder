param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase144ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase144ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase144ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE144_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase144ValidatorText {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase144ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE144_VALIDATE_MISSING_TEXT=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw
}

function Read-Phase144ValidatorJsonLines {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase144ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE144_VALIDATE_MISSING_JSONL=$Path"
  }

  return @(Get-Content -LiteralPath $fullPath |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { ConvertFrom-Json $_ })
}

function Assert-Phase144ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE144_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase144ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE144_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase144ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE144_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase144ValidatorAtLeast {
  param(
    [object]$Actual,
    [int]$Minimum,
    [string]$Name
  )

  if ([int]$Actual -lt $Minimum) {
    throw "PHASE144_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase144ValidatorContains {
  param(
    [string]$Text,
    [string]$Needle,
    [string]$Name
  )

  if (-not $Text.Contains($Needle)) {
    throw "PHASE144_VALIDATE_TEXT_MISSING=$Name needle=$Needle"
  }
}

try {
  $StepId = "PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1"
  $PreviousStepId = "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1"
  $NextAllowedStep = "PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1"
  $RuntimeId = "PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_001"
  $BaselineSessionId = "LIVE_LOOP_002"
  $Phase143TrialSessionId = "PHASE143_CORRECTION_RESPONSE_TRIAL_001"
  $TrialSessionId = "PHASE144_BEHAVIOR_ADAPTATION_SCALE_TRIAL_001"

  $ExpectedCorrections = @(
    [ordered]@{
      correction_id = "PHASE144_CORRECTION_001"
      message = "Reduce repetitive READ_CURRENT_STATE loops. Prioritize practical tasks after state read."
    },
    [ordered]@{
      correction_id = "PHASE144_CORRECTION_002"
      message = "When a correction is present, explain the behavior change in decision_trace before selecting the next task."
    },
    [ordered]@{
      correction_id = "PHASE144_CORRECTION_003"
      message = "After applying a correction, select a stronger micro-gap than the baseline safe carousel."
    }
  )

  $RepoRoot = Resolve-Phase144ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot

  foreach ($identityFile in @(
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1"
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase144ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE144_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }

  $Phase143ProofPath = "proofs/self_development/${PreviousStepId}.json"
  $Phase143ResultPath = "self_control/BUILDER_CORRECTION_RESPONSE_TRIAL_RESULT.json"
  $BaselineRoot = "runtime_sessions/builder_life_loop/observations/$BaselineSessionId"
  $Phase143TrialRoot = "runtime_sessions/builder_life_loop/correction_trials/$Phase143TrialSessionId"
  $TrialRoot = "runtime_sessions/builder_life_loop/adaptation_trials/$TrialSessionId"
  $CurrentRoot = "runtime_sessions/builder_life_loop/current"
  $OutputRoot = "self_build_batch/autonomy_trials/$StepId"

  $OutputPath = "$OutputRoot/BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_OUTPUT.json"
  $ResultPath = "$OutputRoot/${StepId}_RESULT.json"
  $RuntimeLogPath = "$OutputRoot/${StepId}_RUNTIME_LOG.txt"
  $ReportPath = "reports/self_development/${StepId}_REPORT.json"
  $ProofPath = "proofs/self_development/${StepId}.json"
  $TrialResultPath = "self_control/BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_RESULT.json"

  foreach ($requiredPath in @(
    "modules/invoke_builder_behavior_adaptation_scale_trial_001.ps1",
    "validators/validate_phase144_builder_behavior_adaptation_scale_trial_v1.ps1",
    "orchestrator/run.ps1",
    $Phase143ProofPath,
    $Phase143ResultPath,
    "$BaselineRoot/session_summary.json",
    "$BaselineRoot/observation_ledger.jsonl",
    "$BaselineRoot/decision_trace.jsonl",
    "$BaselineRoot/learning_metrics.json",
    "$Phase143TrialRoot/session_summary.json",
    "$Phase143TrialRoot/observation_ledger.jsonl",
    "$Phase143TrialRoot/decision_trace.jsonl",
    "$Phase143TrialRoot/correction_applied_log.jsonl",
    "$Phase143TrialRoot/learning_metrics.json",
    "$CurrentRoot/heartbeat.json",
    "$CurrentRoot/life_loop_state.json",
    "$CurrentRoot/observation_ledger.jsonl",
    "$CurrentRoot/decision_trace.jsonl",
    "$CurrentRoot/error_ledger.jsonl",
    "$CurrentRoot/learning_metrics.json",
    "$CurrentRoot/adaptation_metrics.json",
    "$CurrentRoot/correction_inbox.json",
    "$CurrentRoot/correction_inbox_initial.json",
    "$CurrentRoot/correction_applied_log.jsonl",
    "$CurrentRoot/session_summary.json",
    "$TrialRoot/heartbeat.json",
    "$TrialRoot/life_loop_state.json",
    "$TrialRoot/observation_ledger.jsonl",
    "$TrialRoot/decision_trace.jsonl",
    "$TrialRoot/error_ledger.jsonl",
    "$TrialRoot/learning_metrics.json",
    "$TrialRoot/adaptation_metrics.json",
    "$TrialRoot/correction_inbox.json",
    "$TrialRoot/correction_inbox_initial.json",
    "$TrialRoot/correction_applied_log.jsonl",
    "$TrialRoot/session_summary.json",
    "$TrialRoot/checkpoints/checkpoint_006.json",
    "$TrialRoot/checkpoints/checkpoint_012.json",
    "$TrialRoot/checkpoints/checkpoint_018.json",
    $TrialResultPath,
    $OutputPath,
    $ResultPath,
    $RuntimeLogPath,
    $ReportPath,
    $ProofPath
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase144ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE144_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $Phase143Proof = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path $Phase143ProofPath
  Assert-Phase144ValidatorEquals -Actual $Phase143Proof.status -Expected "PASS" -Name "phase143_status"
  Assert-Phase144ValidatorEquals -Actual $Phase143Proof.next_allowed_step -Expected $StepId -Name "phase143_next_allowed_step"
  Assert-Phase144ValidatorTrue -Actual $Phase143Proof.correction_seen -Name "phase143_correction_seen"
  Assert-Phase144ValidatorTrue -Actual $Phase143Proof.correction_applied -Name "phase143_correction_applied"
  Assert-Phase144ValidatorAtLeast -Actual $Phase143Proof.correction_seen_count -Minimum 1 -Name "phase143_correction_seen_count"
  Assert-Phase144ValidatorAtLeast -Actual $Phase143Proof.correction_applied_count -Minimum 1 -Name "phase143_correction_applied_count"
  Assert-Phase144ValidatorTrue -Actual $Phase143Proof.behavior_changed_after_correction -Name "phase143_behavior_changed_after_correction"
  Assert-Phase144ValidatorEquals -Actual $Phase143Proof.selected_next_gap -Expected $StepId -Name "phase143_selected_next_gap"
  Assert-Phase144ValidatorEquals -Actual $Phase143Proof.selected_by -Expected "BUILDER_RUNTIME" -Name "phase143_selected_by"
  Assert-Phase144ValidatorFalse -Actual $Phase143Proof.owner_interactive_prompt_required -Name "phase143_owner_interactive_prompt_required"
  Assert-Phase144ValidatorFalse -Actual $Phase143Proof.external_agent_production_allowed -Name "phase143_external_agent_production_allowed"
  Assert-Phase144ValidatorEquals -Actual $Phase143Proof.trusted_material_count -Expected 0 -Name "phase143_trusted_material_count"
  Assert-Phase144ValidatorFalse -Actual $Phase143Proof.external_fetch_performed -Name "phase143_external_fetch_performed"
  Assert-Phase144ValidatorFalse -Actual $Phase143Proof.dependency_install_performed -Name "phase143_dependency_install_performed"
  Assert-Phase144ValidatorFalse -Actual $Phase143Proof.executable_materials_used -Name "phase143_executable_materials_used"

  $Phase143Result = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path $Phase143ResultPath
  Assert-Phase144ValidatorEquals -Actual $Phase143Result.status -Expected "PASS" -Name "phase143_result_status"
  Assert-Phase144ValidatorEquals -Actual $Phase143Result.next_allowed_step -Expected $StepId -Name "phase143_result_next_allowed_step"

  $Output = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path $OutputPath
  $Result = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath
  $TrialResult = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path $TrialResultPath
  $CurrentSummary = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path "$CurrentRoot/session_summary.json"
  $TrialSummary = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/session_summary.json"
  $CurrentMetrics = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path "$CurrentRoot/adaptation_metrics.json"
  $TrialMetrics = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/adaptation_metrics.json"
  $CurrentInbox = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path "$CurrentRoot/correction_inbox.json"
  $TrialInbox = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/correction_inbox.json"
  $CurrentInitialInbox = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path "$CurrentRoot/correction_inbox_initial.json"
  $TrialInitialInbox = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/correction_inbox_initial.json"

  foreach ($artifact in @($Output, $Result, $Report, $Proof, $TrialResult, $CurrentSummary, $TrialSummary, $CurrentMetrics, $TrialMetrics, $CurrentInbox, $TrialInbox, $CurrentInitialInbox, $TrialInitialInbox)) {
    Assert-Phase144ValidatorEquals -Actual $artifact.status -Expected "PASS" -Name "artifact_status"
  }

  foreach ($artifact in @($Output, $Result, $Proof, $TrialResult, $CurrentSummary, $TrialSummary, $CurrentMetrics, $TrialMetrics)) {
    Assert-Phase144ValidatorEquals -Actual $artifact.next_allowed_step -Expected $NextAllowedStep -Name "next_allowed_step"
  }

  foreach ($artifact in @($Output, $Proof, $TrialResult, $CurrentSummary, $TrialSummary, $CurrentMetrics, $TrialMetrics)) {
    Assert-Phase144ValidatorAtLeast -Actual $artifact.corrections_seen_count -Minimum 3 -Name "corrections_seen_count"
    Assert-Phase144ValidatorAtLeast -Actual $artifact.corrections_applied_count -Minimum 3 -Name "corrections_applied_count"
    Assert-Phase144ValidatorAtLeast -Actual $artifact.behavior_changes_count -Minimum 3 -Name "behavior_changes_count"
    Assert-Phase144ValidatorTrue -Actual $artifact.adaptation_scaled -Name "adaptation_scaled"
    Assert-Phase144ValidatorTrue -Actual $artifact.repeated_safe_carousel_reduced -Name "repeated_safe_carousel_reduced"
    Assert-Phase144ValidatorEquals -Actual $artifact.baseline_session -Expected $BaselineSessionId -Name "baseline_session"
    Assert-Phase144ValidatorEquals -Actual $artifact.phase143_trial_session -Expected $Phase143TrialSessionId -Name "phase143_trial_session"
    Assert-Phase144ValidatorEquals -Actual $artifact.trial_session -Expected $TrialSessionId -Name "trial_session"
    Assert-Phase144ValidatorEquals -Actual $artifact.selected_next_gap -Expected $NextAllowedStep -Name "selected_next_gap"
  }

  foreach ($artifact in @($Output, $Proof, $TrialResult, $CurrentSummary, $TrialSummary)) {
    Assert-Phase144ValidatorFalse -Actual $artifact.owner_interactive_prompt_required -Name "owner_interactive_prompt_required"
    Assert-Phase144ValidatorFalse -Actual $artifact.external_agent_production_allowed -Name "external_agent_production_allowed"
  }

  foreach ($artifact in @($Output, $Proof, $CurrentSummary, $TrialSummary)) {
    Assert-Phase144ValidatorEquals -Actual $artifact.trusted_material_count -Expected 0 -Name "trusted_material_count"
    Assert-Phase144ValidatorFalse -Actual $artifact.external_fetch_performed -Name "external_fetch_performed"
    Assert-Phase144ValidatorFalse -Actual $artifact.dependency_install_performed -Name "dependency_install_performed"
    Assert-Phase144ValidatorFalse -Actual $artifact.executable_materials_used -Name "executable_materials_used"
  }

  Assert-Phase144ValidatorEquals -Actual $Output.engine_name -Expected $RuntimeId -Name "output_engine_name"
  Assert-Phase144ValidatorEquals -Actual $Proof.run_id -Expected $RuntimeId -Name "proof_run_id"
  Assert-Phase144ValidatorTrue -Actual $Proof.runtime_executed -Name "proof_runtime_executed"
  Assert-Phase144ValidatorTrue -Actual $Proof.builder_runtime_invoked -Name "proof_builder_runtime_invoked"
  Assert-Phase144ValidatorEquals -Actual $Proof.current_line -Expected "SELF_BUILD" -Name "proof_current_line"
  Assert-Phase144ValidatorFalse -Actual $Proof.production_adoption_allowed -Name "proof_production_adoption_allowed"
  Assert-Phase144ValidatorEquals -Actual $Output.queue_after -Expected "NONE" -Name "output_queue_after"
  Assert-Phase144ValidatorEquals -Actual $Result.queue_after -Expected "NONE" -Name "result_queue_after"
  Assert-Phase144ValidatorEquals -Actual $Proof.queue_after -Expected "NONE" -Name "proof_queue_after"
  Assert-Phase144ValidatorFalse -Actual $Proof.main_touched -Name "proof_main_touched"
  Assert-Phase144ValidatorEquals -Actual $Proof.source_branch -Expected $Branch -Name "proof_source_branch"
  Assert-Phase144ValidatorEquals -Actual $TrialResult.selected_by -Expected "BUILDER_RUNTIME" -Name "trial_selected_by"

  foreach ($metrics in @($Output, $Proof, $CurrentMetrics, $TrialMetrics)) {
    Assert-Phase144ValidatorTrue -Actual $metrics.baseline_repetition_pattern_detected -Name "baseline_repetition_pattern_detected"
    Assert-Phase144ValidatorTrue -Actual $metrics.phase143_single_correction_pattern_detected -Name "phase143_single_correction_pattern_detected"
    Assert-Phase144ValidatorAtLeast -Actual $metrics.correction_to_behavior_mapping_count -Minimum 3 -Name "correction_to_behavior_mapping_count"
  }

  foreach ($initialInbox in @($CurrentInitialInbox, $TrialInitialInbox)) {
    $InitialCorrections = @($initialInbox.pending_corrections)
    Assert-Phase144ValidatorEquals -Actual $InitialCorrections.Count -Expected 3 -Name "initial_pending_correction_count"
    for ($i = 0; $i -lt $ExpectedCorrections.Count; $i++) {
      Assert-Phase144ValidatorEquals -Actual $InitialCorrections[$i].correction_id -Expected $ExpectedCorrections[$i].correction_id -Name "initial_correction_id_$i"
      Assert-Phase144ValidatorEquals -Actual $InitialCorrections[$i].status -Expected "pending" -Name "initial_correction_status_$i"
      Assert-Phase144ValidatorEquals -Actual $InitialCorrections[$i].message -Expected $ExpectedCorrections[$i].message -Name "initial_correction_message_$i"
    }
  }

  foreach ($finalInbox in @($CurrentInbox, $TrialInbox)) {
    Assert-Phase144ValidatorEquals -Actual $finalInbox.observed_correction_count -Expected 3 -Name "final_inbox_seen_count"
    Assert-Phase144ValidatorEquals -Actual $finalInbox.applied_correction_count -Expected 3 -Name "final_inbox_applied_count"
    Assert-Phase144ValidatorEquals -Actual @($finalInbox.applied_corrections).Count -Expected 3 -Name "final_applied_correction_count"
  }

  $OrchestratorText = Read-Phase144ValidatorText -RepoRoot $RepoRoot -Path "orchestrator/run.ps1"
  Assert-Phase144ValidatorContains -Text $OrchestratorText -Needle "Invoke-BuilderBehaviorAdaptationScaleTrial001" -Name "orchestrator_hook"
  Assert-Phase144ValidatorContains -Text $OrchestratorText -Needle "BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL=PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_001" -Name "orchestrator_runtime_signal"

  $RuntimeLog = Read-Phase144ValidatorText -RepoRoot $RepoRoot -Path $RuntimeLogPath
  foreach ($signal in @(
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
  )) {
    Assert-Phase144ValidatorContains -Text $RuntimeLog -Needle $signal -Name "runtime_log_signal"
  }

  $CurrentCorrectionLog = Read-Phase144ValidatorJsonLines -RepoRoot $RepoRoot -Path "$CurrentRoot/correction_applied_log.jsonl"
  $TrialCorrectionLog = Read-Phase144ValidatorJsonLines -RepoRoot $RepoRoot -Path "$TrialRoot/correction_applied_log.jsonl"
  foreach ($correctionLog in @($CurrentCorrectionLog, $TrialCorrectionLog)) {
    $AppliedEntries = @($correctionLog | Where-Object { $_.event_type -eq "CORRECTION_APPLIED" })
    Assert-Phase144ValidatorAtLeast -Actual $AppliedEntries.Count -Minimum 3 -Name "correction_applied_log_entries"
    foreach ($expectedCorrection in $ExpectedCorrections) {
      if (-not @($AppliedEntries | Where-Object { $_.correction_id -eq $expectedCorrection.correction_id })) {
        throw "PHASE144_VALIDATE_CORRECTION_LOG_MISSING_ID=$($expectedCorrection.correction_id)"
      }
    }
  }

  $CurrentDecisions = Read-Phase144ValidatorJsonLines -RepoRoot $RepoRoot -Path "$CurrentRoot/decision_trace.jsonl"
  $TrialDecisions = Read-Phase144ValidatorJsonLines -RepoRoot $RepoRoot -Path "$TrialRoot/decision_trace.jsonl"
  foreach ($decisions in @($CurrentDecisions, $TrialDecisions)) {
    $CorrectionAwareDecisions = @($decisions | Where-Object { $_.correction_aware -eq $true })
    Assert-Phase144ValidatorAtLeast -Actual $CorrectionAwareDecisions.Count -Minimum 3 -Name "correction_aware_decisions"
    $DecisionText = ($decisions | ConvertTo-Json -Depth 50 -Compress)
    foreach ($expectedCorrection in $ExpectedCorrections) {
      Assert-Phase144ValidatorContains -Text $DecisionText -Needle $expectedCorrection.correction_id -Name "decision_trace_correction_id"
    }
    Assert-Phase144ValidatorContains -Text $DecisionText -Needle "behavior_changes_count" -Name "decision_trace_behavior_changes_count"
  }

  $CurrentObservations = Read-Phase144ValidatorJsonLines -RepoRoot $RepoRoot -Path "$CurrentRoot/observation_ledger.jsonl"
  $TrialObservations = Read-Phase144ValidatorJsonLines -RepoRoot $RepoRoot -Path "$TrialRoot/observation_ledger.jsonl"
  foreach ($observations in @($CurrentObservations, $TrialObservations)) {
    $CorrectionAwareObservations = @($observations | Where-Object { $_.correction_aware -eq $true -or $_.practice_result.correction_aware -eq $true })
    Assert-Phase144ValidatorAtLeast -Actual $CorrectionAwareObservations.Count -Minimum 3 -Name "correction_aware_observations"
    $ObservationText = ($observations | ConvertTo-Json -Depth 50 -Compress)
    Assert-Phase144ValidatorContains -Text $ObservationText -Needle "behavior_change_explanation" -Name "observation_ledger_behavior_change"
    foreach ($expectedCorrection in $ExpectedCorrections) {
      Assert-Phase144ValidatorContains -Text $ObservationText -Needle $expectedCorrection.correction_id -Name "observation_ledger_correction_id"
    }
  }

  $BaselineDecisions = Read-Phase144ValidatorJsonLines -RepoRoot $RepoRoot -Path "$BaselineRoot/decision_trace.jsonl"
  $Phase143Decisions = Read-Phase144ValidatorJsonLines -RepoRoot $RepoRoot -Path "$Phase143TrialRoot/decision_trace.jsonl"
  $BaselineSequence = @($BaselineDecisions | ForEach-Object { $_.selected_task_type } | Select-Object -First 18)
  $Phase143Sequence = @($Phase143Decisions | ForEach-Object { $_.selected_task_type } | Select-Object -First 12)
  $TrialSequence = @($TrialDecisions | ForEach-Object { $_.selected_task_type } | Select-Object -First 18)

  if ($BaselineSequence.Count -lt 18) {
    throw "PHASE144_VALIDATE_BASELINE_SEQUENCE_TOO_SHORT=$($BaselineSequence.Count)"
  }
  if ($Phase143Sequence.Count -lt 12) {
    throw "PHASE144_VALIDATE_PHASE143_SEQUENCE_TOO_SHORT=$($Phase143Sequence.Count)"
  }
  if ($TrialSequence.Count -ne 18) {
    throw "PHASE144_VALIDATE_TRIAL_SEQUENCE_UNEXPECTED_COUNT=$($TrialSequence.Count)"
  }
  if (($BaselineSequence -join ",") -eq ($TrialSequence -join ",")) {
    throw "PHASE144_VALIDATE_BEHAVIOR_DID_NOT_CHANGE_FROM_BASELINE"
  }
  if ((@($Phase143Sequence | Select-Object -First 12) -join ",") -eq (@($TrialSequence | Select-Object -First 12) -join ",")) {
    throw "PHASE144_VALIDATE_BEHAVIOR_DID_NOT_CHANGE_FROM_PHASE143"
  }
  $BaselineReadStateCount = @($BaselineSequence | Where-Object { $_ -eq "READ_CURRENT_STATE" }).Count
  $TrialReadStateCount = @($TrialSequence | Where-Object { $_ -eq "READ_CURRENT_STATE" }).Count
  if ($TrialReadStateCount -ge $BaselineReadStateCount) {
    throw "PHASE144_VALIDATE_SAFE_CAROUSEL_NOT_REDUCED baseline_read_state=$BaselineReadStateCount trial_read_state=$TrialReadStateCount"
  }
  Assert-Phase144ValidatorEquals -Actual $TrialSequence[0] -Expected "READ_CURRENT_STATE" -Name "trial_sequence_0"
  Assert-Phase144ValidatorEquals -Actual $TrialSequence[1] -Expected "WRITE_LEARNING_NOTE" -Name "trial_sequence_1"
  Assert-Phase144ValidatorEquals -Actual $TrialSequence[2] -Expected "SELECT_NEXT_MICRO_GAP" -Name "trial_sequence_2"
  if (-not @($TrialSequence | Where-Object { $_ -eq "EXPLAIN_BEHAVIOR_CHANGE" })) {
    throw "PHASE144_VALIDATE_EXPLANATION_TASK_MISSING"
  }

  $Queue = Read-Phase144ValidatorJson -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
  Assert-Phase144ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  $ExternalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
  if ($ExternalAgentStatus.Count -gt 0) {
    throw "PHASE144_VALIDATE_EXTERNAL_AGENT_SCOPE_DIRTY=$($ExternalAgentStatus -join '; ')"
  }

  Write-Host "PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_VALIDATE_RESULT=PASS"
  Write-Host "CORRECTIONS_SEEN_COUNT=$($Proof.corrections_seen_count)"
  Write-Host "CORRECTIONS_APPLIED_COUNT=$($Proof.corrections_applied_count)"
  Write-Host "BEHAVIOR_CHANGES_COUNT=$($Proof.behavior_changes_count)"
  Write-Host "ADAPTATION_SCALED=$($Proof.adaptation_scaled)"
  Write-Host "NEXT_ALLOWED_STEP=$($Proof.next_allowed_step)"
} catch {
  Write-Host "PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE144_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  Pop-Location
}
