param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase147ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase147ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase147ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE147_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase147ValidatorText {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase147ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE147_VALIDATE_MISSING_TEXT=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw
}

function Read-Phase147ValidatorJsonLines {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase147ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE147_VALIDATE_MISSING_JSONL=$Path"
  }

  return @(Get-Content -LiteralPath $fullPath |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { ConvertFrom-Json $_ })
}

function Assert-Phase147ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE147_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase147ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE147_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase147ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE147_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase147ValidatorAtLeast {
  param(
    [object]$Actual,
    [int]$Minimum,
    [string]$Name
  )

  if ([int]$Actual -lt $Minimum) {
    throw "PHASE147_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase147ValidatorAtMost {
  param(
    [object]$Actual,
    [int]$Maximum,
    [string]$Name
  )

  if ([int]$Actual -gt $Maximum) {
    throw "PHASE147_VALIDATE_COUNT_TOO_HIGH=$Name actual=$Actual maximum=$Maximum"
  }
}

function Assert-Phase147ValidatorContains {
  param(
    [string]$Text,
    [string]$Needle,
    [string]$Name
  )

  if (-not $Text.Contains($Needle)) {
    throw "PHASE147_VALIDATE_TEXT_MISSING=$Name needle=$Needle"
  }
}

function Get-Phase147ValidatorTaskMetrics {
  param(
    [object[]]$Decisions,
    [string[]]$SelfCorrectionTaskTypes
  )

  $taskTypes = @($Decisions |
    ForEach-Object { "$($_.selected_task_type)" } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  $selfCorrectionTasks = @($taskTypes | Where-Object { $SelfCorrectionTaskTypes -contains $_ })

  return [pscustomobject][ordered]@{
    decision_count = [int]$taskTypes.Count
    unique_task_type_count = [int]@($taskTypes | Select-Object -Unique).Count
    select_next_micro_gap_count = [int]@($taskTypes | Where-Object { $_ -eq "SELECT_NEXT_MICRO_GAP" }).Count
    write_learning_note_count = [int]@($taskTypes | Where-Object { $_ -eq "WRITE_LEARNING_NOTE" }).Count
    self_correction_task_count = [int]$selfCorrectionTasks.Count
    unique_self_correction_task_type_count = [int]@($selfCorrectionTasks | Select-Object -Unique).Count
    task_sequence = $taskTypes
  }
}

try {
  $StepId = "PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1"
  $RunId = "PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_001"
  $PreviousStepId = "PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1"
  $NextAllowedStep = "PHASE148_BUILDER_SELF_CORRECTION_RETENTION_TRIAL_V1"
  $BaselineSessionId = "LIVE_OBSERVE_AFTER_PHASE146_001"
  $Phase146ProofSessionId = "LIVE_AFTER_PHASE145_001"
  $SessionId = "PHASE147_SELF_CORRECTION_SESSION_001"
  $CorrectionId = "PHASE147_SELF_CORRECTION_001"
  $CorrectionReason = "repetitive small task set detected in observation-only session"
  $CorrectionTargetBehavior = "introduce self-diagnostic and variation tasks before repeating micro-gap selection"
  $MaxCycles = 20
  $SelfCorrectionTaskTypes = @(
    "DIAGNOSE_REPETITION",
    "WRITE_SELF_CORRECTION",
    "APPLY_SELF_CORRECTION",
    "PLAN_BEHAVIOR_VARIATION",
    "VERIFY_BEHAVIOR_CHANGE"
  )

  $RepoRoot = Resolve-Phase147ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot

  foreach ($identityFile in @(
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1"
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase147ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE147_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }

  $Phase146ProofPath = "proofs/self_development/${PreviousStepId}.json"
  $BaselineRoot = "runtime_sessions/builder_life_loop/observations/$BaselineSessionId"
  $TrialRoot = "runtime_sessions/builder_life_loop/self_correction_trials/PHASE147_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_001"
  $ResultPath = "self_control/BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_RESULT.json"
  $ReportPath = "reports/self_development/${StepId}_REPORT.json"
  $ProofPath = "proofs/self_development/${StepId}.json"
  $RuntimeLogPath = "$TrialRoot/${StepId}_RUNTIME_LOG.txt"
  $RepetitionDiagnosisPath = "$TrialRoot/repetition_diagnosis.json"
  $SelfCorrectionPath = "$TrialRoot/self_correction.json"
  $SelfCorrectionAppliedLogPath = "$TrialRoot/self_correction_applied_log.jsonl"

  foreach ($requiredPath in @(
    "modules/invoke_builder_observation_driven_self_correction_trial_001.ps1",
    "validators/validate_phase147_builder_observation_driven_self_correction_trial_v1.ps1",
    "orchestrator/run.ps1",
    $Phase146ProofPath,
    "$BaselineRoot/session_summary.json",
    "$BaselineRoot/decision_trace.jsonl",
    "$BaselineRoot/observation_ledger.jsonl",
    "$BaselineRoot/learning_metrics.json",
    "$TrialRoot/heartbeat.json",
    "$TrialRoot/life_loop_state.json",
    "$TrialRoot/observation_ledger.jsonl",
    "$TrialRoot/decision_trace.jsonl",
    "$TrialRoot/learning_metrics.json",
    "$TrialRoot/session_summary.json",
    $SelfCorrectionPath,
    $SelfCorrectionAppliedLogPath,
    $RepetitionDiagnosisPath,
    "$TrialRoot/checkpoints/checkpoint_005.json",
    "$TrialRoot/checkpoints/checkpoint_010.json",
    "$TrialRoot/checkpoints/checkpoint_015.json",
    "$TrialRoot/checkpoints/checkpoint_020.json",
    $ResultPath,
    $ReportPath,
    $ProofPath,
    $RuntimeLogPath
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase147ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE147_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $Phase146Proof = Read-Phase147ValidatorJson -RepoRoot $RepoRoot -Path $Phase146ProofPath
  Assert-Phase147ValidatorEquals -Actual $Phase146Proof.status -Expected "PASS" -Name "phase146_status"
  Assert-Phase147ValidatorEquals -Actual $Phase146Proof.next_allowed_step -Expected $StepId -Name "phase146_next_allowed_step"
  Assert-Phase147ValidatorEquals -Actual $Phase146Proof.observation_session_id -Expected $Phase146ProofSessionId -Name "phase146_observation_session_id"
  Assert-Phase147ValidatorTrue -Actual $Phase146Proof.builder_runtime_decision_author -Name "phase146_builder_runtime_decision_author"
  Assert-Phase147ValidatorTrue -Actual $Phase146Proof.supervisor_lifecycle_only -Name "phase146_supervisor_lifecycle_only"
  Assert-Phase147ValidatorFalse -Actual $Phase146Proof.routed_phase_runtime_invoked -Name "phase146_routed_phase_runtime_invoked"
  Assert-Phase147ValidatorFalse -Actual $Phase146Proof.external_agent_production_allowed -Name "phase146_external_agent_production_allowed"

  $BaselineSummary = Read-Phase147ValidatorJson -RepoRoot $RepoRoot -Path "$BaselineRoot/session_summary.json"
  $BaselineDecisions = Read-Phase147ValidatorJsonLines -RepoRoot $RepoRoot -Path "$BaselineRoot/decision_trace.jsonl"
  $BaselineMetrics = Get-Phase147ValidatorTaskMetrics -Decisions $BaselineDecisions -SelfCorrectionTaskTypes $SelfCorrectionTaskTypes
  Assert-Phase147ValidatorAtLeast -Actual $BaselineSummary.completed_cycles -Minimum 40 -Name "baseline_completed_cycles"
  Assert-Phase147ValidatorAtMost -Actual $BaselineMetrics.unique_task_type_count -Maximum 6 -Name "baseline_unique_task_type_count"
  Assert-Phase147ValidatorAtLeast -Actual $BaselineMetrics.select_next_micro_gap_count -Minimum 8 -Name "baseline_select_next_micro_gap_count"
  Assert-Phase147ValidatorAtLeast -Actual $BaselineMetrics.write_learning_note_count -Minimum 8 -Name "baseline_write_learning_note_count"
  Assert-Phase147ValidatorEquals -Actual $BaselineMetrics.self_correction_task_count -Expected 0 -Name "baseline_self_correction_task_count"

  $BaselineRepeatedDominanceCount = [int]($BaselineMetrics.select_next_micro_gap_count + $BaselineMetrics.write_learning_note_count)
  $BaselineRepeatedDominanceRatio = [math]::Round(($BaselineRepeatedDominanceCount / [double]$BaselineMetrics.decision_count), 4)

  $Result = Read-Phase147ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase147ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase147ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath
  $Heartbeat = Read-Phase147ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/heartbeat.json"
  $LifeLoopState = Read-Phase147ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/life_loop_state.json"
  $LearningMetrics = Read-Phase147ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/learning_metrics.json"
  $SessionSummary = Read-Phase147ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/session_summary.json"
  $SelfCorrection = Read-Phase147ValidatorJson -RepoRoot $RepoRoot -Path $SelfCorrectionPath
  $RepetitionDiagnosis = Read-Phase147ValidatorJson -RepoRoot $RepoRoot -Path $RepetitionDiagnosisPath

  foreach ($artifact in @($Result, $Report, $Proof, $Heartbeat, $LifeLoopState, $LearningMetrics, $SessionSummary, $SelfCorrection, $RepetitionDiagnosis)) {
    Assert-Phase147ValidatorEquals -Actual $artifact.status -Expected "PASS" -Name "artifact_status"
    Assert-Phase147ValidatorEquals -Actual $artifact.next_allowed_step -Expected $NextAllowedStep -Name "artifact_next_allowed_step"
  }

  foreach ($artifact in @($Result, $Proof, $Heartbeat, $LifeLoopState, $LearningMetrics, $SessionSummary)) {
    Assert-Phase147ValidatorTrue -Actual $artifact.baseline_observation_analyzed -Name "baseline_observation_analyzed"
    Assert-Phase147ValidatorTrue -Actual $artifact.repetition_detected -Name "repetition_detected"
    Assert-Phase147ValidatorTrue -Actual $artifact.self_correction_created -Name "self_correction_created"
    Assert-Phase147ValidatorEquals -Actual $artifact.self_correction_created_by -Expected "BUILDER_RUNTIME" -Name "self_correction_created_by"
    Assert-Phase147ValidatorTrue -Actual $artifact.self_correction_applied -Name "self_correction_applied"
    Assert-Phase147ValidatorEquals -Actual $artifact.selected_by -Expected "BUILDER_RUNTIME" -Name "selected_by"
    Assert-Phase147ValidatorTrue -Actual $artifact.supervisor_lifecycle_only -Name "supervisor_lifecycle_only"
    Assert-Phase147ValidatorFalse -Actual $artifact.routed_phase_runtime_invoked -Name "routed_phase_runtime_invoked"
    Assert-Phase147ValidatorFalse -Actual $artifact.owner_interactive_prompt_required -Name "owner_interactive_prompt_required"
    Assert-Phase147ValidatorFalse -Actual $artifact.assistant_or_codex_per_cycle_authoring_required -Name "assistant_or_codex_per_cycle_authoring_required"
    Assert-Phase147ValidatorFalse -Actual $artifact.external_agent_production_allowed -Name "external_agent_production_allowed"
  }

  foreach ($artifact in @($Result, $Proof, $LearningMetrics, $SessionSummary)) {
    Assert-Phase147ValidatorTrue -Actual $artifact.behavior_changed_after_self_correction -Name "behavior_changed_after_self_correction"
    Assert-Phase147ValidatorTrue -Actual $artifact.repeated_task_dominance_reduced -Name "repeated_task_dominance_reduced"
    Assert-Phase147ValidatorEquals -Actual $artifact.selected_next_gap -Expected $NextAllowedStep -Name "selected_next_gap"
  }

  foreach ($artifact in @($Proof, $LearningMetrics, $SessionSummary)) {
    Assert-Phase147ValidatorAtLeast -Actual $artifact.self_correction_task_count -Minimum 2 -Name "self_correction_task_count"
    Assert-Phase147ValidatorEquals -Actual $artifact.lifecycle_authority -Expected "OBSERVATION_RUNNER_ONLY" -Name "lifecycle_authority"
  }

  foreach ($artifact in @($Result, $Proof, $LearningMetrics, $SessionSummary)) {
    Assert-Phase147ValidatorEquals -Actual $artifact.trusted_material_count -Expected 0 -Name "trusted_material_count"
    Assert-Phase147ValidatorFalse -Actual $artifact.external_fetch_performed -Name "external_fetch_performed"
    Assert-Phase147ValidatorFalse -Actual $artifact.dependency_install_performed -Name "dependency_install_performed"
    Assert-Phase147ValidatorFalse -Actual $artifact.executable_materials_used -Name "executable_materials_used"
  }

  Assert-Phase147ValidatorEquals -Actual $Proof.run_id -Expected $RunId -Name "proof_run_id"
  Assert-Phase147ValidatorTrue -Actual $Proof.runtime_executed -Name "proof_runtime_executed"
  Assert-Phase147ValidatorTrue -Actual $Proof.builder_runtime_invoked -Name "proof_builder_runtime_invoked"
  Assert-Phase147ValidatorEquals -Actual $Proof.current_line -Expected "SELF_BUILD" -Name "proof_current_line"
  Assert-Phase147ValidatorFalse -Actual $Proof.production_adoption_allowed -Name "proof_production_adoption_allowed"
  Assert-Phase147ValidatorEquals -Actual $Proof.queue_after -Expected "NONE" -Name "proof_queue_after"
  Assert-Phase147ValidatorFalse -Actual $Proof.main_touched -Name "proof_main_touched"
  Assert-Phase147ValidatorEquals -Actual $Proof.source_branch -Expected $Branch -Name "proof_source_branch"
  Assert-Phase147ValidatorEquals -Actual $Proof.phase146_proof_path -Expected $Phase146ProofPath -Name "proof_phase146_proof_path"
  Assert-Phase147ValidatorEquals -Actual $Proof.baseline_session -Expected $BaselineSessionId -Name "proof_baseline_session"
  Assert-Phase147ValidatorEquals -Actual $Proof.trial_session -Expected $SessionId -Name "proof_trial_session"

  Assert-Phase147ValidatorEquals -Actual $Result.baseline_session -Expected $BaselineSessionId -Name "result_baseline_session"
  Assert-Phase147ValidatorEquals -Actual $Result.trial_session -Expected $SessionId -Name "result_trial_session"
  Assert-Phase147ValidatorEquals -Actual $Result.selected_by -Expected "BUILDER_RUNTIME" -Name "result_selected_by"

  Assert-Phase147ValidatorEquals -Actual $SelfCorrection.correction_id -Expected $CorrectionId -Name "self_correction_id"
  Assert-Phase147ValidatorEquals -Actual $SelfCorrection.created_by -Expected "BUILDER_RUNTIME" -Name "self_correction_created_by_created_by"
  Assert-Phase147ValidatorEquals -Actual $SelfCorrection.self_correction_created_by -Expected "BUILDER_RUNTIME" -Name "self_correction_created_by"
  Assert-Phase147ValidatorEquals -Actual $SelfCorrection.source_observation_session -Expected $BaselineSessionId -Name "self_correction_source_observation_session"
  Assert-Phase147ValidatorEquals -Actual $SelfCorrection.reason -Expected $CorrectionReason -Name "self_correction_reason"
  Assert-Phase147ValidatorEquals -Actual $SelfCorrection.target_behavior -Expected $CorrectionTargetBehavior -Name "self_correction_target_behavior"
  Assert-Phase147ValidatorFalse -Actual $SelfCorrection.owner_interactive_prompt_required -Name "self_correction_owner_prompt"
  Assert-Phase147ValidatorFalse -Actual $SelfCorrection.assistant_or_codex_per_cycle_authoring_required -Name "self_correction_codex_authoring"
  Assert-Phase147ValidatorFalse -Actual $SelfCorrection.external_agent_production_allowed -Name "self_correction_external_agent_production_allowed"

  Assert-Phase147ValidatorTrue -Actual $RepetitionDiagnosis.baseline_observation_analyzed -Name "diagnosis_baseline_observation_analyzed"
  Assert-Phase147ValidatorTrue -Actual $RepetitionDiagnosis.repetition_detected -Name "diagnosis_repetition_detected"
  Assert-Phase147ValidatorEquals -Actual $RepetitionDiagnosis.baseline_session -Expected $BaselineSessionId -Name "diagnosis_baseline_session"
  Assert-Phase147ValidatorEquals -Actual $RepetitionDiagnosis.diagnosis_reason -Expected $CorrectionReason -Name "diagnosis_reason"

  $Decisions = Read-Phase147ValidatorJsonLines -RepoRoot $RepoRoot -Path "$TrialRoot/decision_trace.jsonl"
  $Observations = Read-Phase147ValidatorJsonLines -RepoRoot $RepoRoot -Path "$TrialRoot/observation_ledger.jsonl"
  $AppliedLog = Read-Phase147ValidatorJsonLines -RepoRoot $RepoRoot -Path $SelfCorrectionAppliedLogPath
  Assert-Phase147ValidatorEquals -Actual $Decisions.Count -Expected $MaxCycles -Name "decision_trace_count"
  Assert-Phase147ValidatorEquals -Actual $Observations.Count -Expected $MaxCycles -Name "observation_ledger_count"

  foreach ($decision in $Decisions) {
    Assert-Phase147ValidatorEquals -Actual $decision.selected_by -Expected "BUILDER_RUNTIME" -Name "decision_selected_by"
    Assert-Phase147ValidatorEquals -Actual $decision.lifecycle_authority -Expected "OBSERVATION_RUNNER_ONLY" -Name "decision_lifecycle_authority"
    Assert-Phase147ValidatorEquals -Actual $decision.self_correction_created_by -Expected "BUILDER_RUNTIME" -Name "decision_self_correction_created_by"
    Assert-Phase147ValidatorTrue -Actual $decision.supervisor_lifecycle_only -Name "decision_supervisor_lifecycle_only"
    Assert-Phase147ValidatorFalse -Actual $decision.routed_phase_runtime_invoked -Name "decision_routed_phase_runtime_invoked"
    Assert-Phase147ValidatorFalse -Actual $decision.owner_interactive_prompt_required -Name "decision_owner_prompt"
    Assert-Phase147ValidatorFalse -Actual $decision.assistant_or_codex_per_cycle_authoring_required -Name "decision_codex_authoring"
    Assert-Phase147ValidatorFalse -Actual $decision.external_agent_production_allowed -Name "decision_external_agent_production_allowed"
    Assert-Phase147ValidatorEquals -Actual $decision.selected_next_gap -Expected $NextAllowedStep -Name "decision_selected_next_gap"
  }

  foreach ($observation in $Observations) {
    Assert-Phase147ValidatorEquals -Actual $observation.selected_by -Expected "BUILDER_RUNTIME" -Name "observation_selected_by"
    Assert-Phase147ValidatorEquals -Actual $observation.lifecycle_authority -Expected "OBSERVATION_RUNNER_ONLY" -Name "observation_lifecycle_authority"
    Assert-Phase147ValidatorTrue -Actual $observation.supervisor_lifecycle_only -Name "observation_supervisor_lifecycle_only"
    Assert-Phase147ValidatorFalse -Actual $observation.routed_phase_runtime_invoked -Name "observation_routed_phase_runtime_invoked"
    Assert-Phase147ValidatorFalse -Actual $observation.owner_interactive_prompt_required -Name "observation_owner_prompt"
    Assert-Phase147ValidatorFalse -Actual $observation.assistant_or_codex_per_cycle_authoring_required -Name "observation_codex_authoring"
    Assert-Phase147ValidatorFalse -Actual $observation.external_agent_production_allowed -Name "observation_external_agent_production_allowed"
  }

  $TrialMetrics = Get-Phase147ValidatorTaskMetrics -Decisions $Decisions -SelfCorrectionTaskTypes $SelfCorrectionTaskTypes
  Assert-Phase147ValidatorAtLeast -Actual $TrialMetrics.self_correction_task_count -Minimum 2 -Name "decision_trace_self_correction_task_count"
  Assert-Phase147ValidatorAtLeast -Actual $TrialMetrics.unique_self_correction_task_type_count -Minimum 2 -Name "decision_trace_unique_self_correction_task_type_count"

  $TrialRepeatedDominanceCount = [int]($TrialMetrics.select_next_micro_gap_count + $TrialMetrics.write_learning_note_count)
  $TrialRepeatedDominanceRatio = [math]::Round(($TrialRepeatedDominanceCount / [double]$TrialMetrics.decision_count), 4)
  if ($TrialRepeatedDominanceRatio -ge $BaselineRepeatedDominanceRatio) {
    throw "PHASE147_VALIDATE_REPEATED_TASK_DOMINANCE_NOT_REDUCED baseline=$BaselineRepeatedDominanceRatio trial=$TrialRepeatedDominanceRatio"
  }

  $BaselineFirstTwenty = @($BaselineMetrics.task_sequence | Select-Object -First $MaxCycles)
  $TrialSequence = @($TrialMetrics.task_sequence)
  if (($BaselineFirstTwenty -join ",") -eq ($TrialSequence -join ",")) {
    throw "PHASE147_VALIDATE_BEHAVIOR_DID_NOT_CHANGE_AFTER_SELF_CORRECTION"
  }

  $AppliedEntries = @($AppliedLog | Where-Object { $_.event_type -eq "SELF_CORRECTION_APPLIED" })
  Assert-Phase147ValidatorAtLeast -Actual $AppliedEntries.Count -Minimum 1 -Name "self_correction_applied_log_entries"
  foreach ($entry in $AppliedEntries) {
    Assert-Phase147ValidatorEquals -Actual $entry.correction_id -Expected $CorrectionId -Name "applied_log_correction_id"
    Assert-Phase147ValidatorEquals -Actual $entry.applied_by -Expected "BUILDER_RUNTIME" -Name "applied_log_applied_by"
    Assert-Phase147ValidatorEquals -Actual $entry.lifecycle_authority -Expected "OBSERVATION_RUNNER_ONLY" -Name "applied_log_lifecycle_authority"
    Assert-Phase147ValidatorFalse -Actual $entry.routed_phase_runtime_invoked -Name "applied_log_routed_phase_runtime_invoked"
  }

  foreach ($checkpoint in @("checkpoint_005.json", "checkpoint_010.json", "checkpoint_015.json", "checkpoint_020.json")) {
    $Checkpoint = Read-Phase147ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/checkpoints/$checkpoint"
    Assert-Phase147ValidatorEquals -Actual $Checkpoint.status -Expected "PASS" -Name "checkpoint_status"
    Assert-Phase147ValidatorEquals -Actual $Checkpoint.session_id -Expected $SessionId -Name "checkpoint_session_id"
    Assert-Phase147ValidatorEquals -Actual $Checkpoint.self_correction_created_by -Expected "BUILDER_RUNTIME" -Name "checkpoint_self_correction_created_by"
    Assert-Phase147ValidatorEquals -Actual $Checkpoint.selected_by -Expected "BUILDER_RUNTIME" -Name "checkpoint_selected_by"
    Assert-Phase147ValidatorEquals -Actual $Checkpoint.lifecycle_authority -Expected "OBSERVATION_RUNNER_ONLY" -Name "checkpoint_lifecycle_authority"
    Assert-Phase147ValidatorFalse -Actual $Checkpoint.routed_phase_runtime_invoked -Name "checkpoint_routed_phase_runtime_invoked"
  }

  $OrchestratorText = Read-Phase147ValidatorText -RepoRoot $RepoRoot -Path "orchestrator/run.ps1"
  Assert-Phase147ValidatorContains -Text $OrchestratorText -Needle "Invoke-BuilderObservationDrivenSelfCorrectionTrial001" -Name "orchestrator_hook"
  Assert-Phase147ValidatorContains -Text $OrchestratorText -Needle "BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL=PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_001" -Name "orchestrator_runtime_signal"

  $RuntimeLog = Read-Phase147ValidatorText -RepoRoot $RepoRoot -Path $RuntimeLogPath
  foreach ($signal in @(
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
  )) {
    Assert-Phase147ValidatorContains -Text $RuntimeLog -Needle $signal -Name "runtime_log_signal"
  }

  $Queue = Read-Phase147ValidatorJson -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
  Assert-Phase147ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  $ExternalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
  if ($ExternalAgentStatus.Count -gt 0) {
    throw "PHASE147_VALIDATE_EXTERNAL_AGENT_SCOPE_DIRTY=$($ExternalAgentStatus -join '; ')"
  }

  Write-Host "PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_VALIDATE_RESULT=PASS"
  Write-Host "BASELINE_SESSION_ID=$($Proof.baseline_session)"
  Write-Host "SELF_CORRECTION_SESSION_ID=$($Proof.trial_session)"
  Write-Host "SELF_CORRECTION_CREATED_BY=$($Proof.self_correction_created_by)"
  Write-Host "SELF_CORRECTION_TASK_COUNT=$($Proof.self_correction_task_count)"
  Write-Host "REPEATED_TASK_DOMINANCE_REDUCED=$($Proof.repeated_task_dominance_reduced)"
  Write-Host "NEXT_ALLOWED_STEP=$($Proof.next_allowed_step)"
} catch {
  Write-Host "PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE147_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  Pop-Location
}
