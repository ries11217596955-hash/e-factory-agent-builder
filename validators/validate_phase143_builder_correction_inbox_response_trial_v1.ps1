param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase143ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase143ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase143ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE143_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase143ValidatorText {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase143ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE143_VALIDATE_MISSING_TEXT=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw
}

function Assert-Phase143ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE143_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase143ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE143_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase143ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE143_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase143ValidatorAtLeast {
  param(
    [object]$Actual,
    [int]$Minimum,
    [string]$Name
  )

  if ([int]$Actual -lt $Minimum) {
    throw "PHASE143_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase143ValidatorContains {
  param(
    [string]$Text,
    [string]$Needle,
    [string]$Name
  )

  if (-not $Text.Contains($Needle)) {
    throw "PHASE143_VALIDATE_TEXT_MISSING=$Name needle=$Needle"
  }
}

try {
  $StepId = "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1"
  $PreviousStepId = "PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1"
  $NextAllowedStep = "PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1"
  $RuntimeId = "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_001"
  $BaselineSessionId = "LIVE_LOOP_002"
  $TrialSessionId = "PHASE143_CORRECTION_RESPONSE_TRIAL_001"
  $CorrectionId = "PHASE143_CORRECTION_001"
  $CorrectionMessage = "Do not repeat only the safe carousel. Increase practical adaptation: after reading state, prioritize WRITE_LEARNING_NOTE and SELECT_NEXT_MICRO_GAP, and explain behavior change."

  $RepoRoot = Resolve-Phase143ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot

  foreach ($identityFile in @(
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1"
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase143ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE143_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }

  $Phase142ProofPath = "proofs/self_development/${PreviousStepId}.json"
  $BaselineRoot = "runtime_sessions/builder_life_loop/observations/$BaselineSessionId"
  $TrialRoot = "runtime_sessions/builder_life_loop/correction_trials/$TrialSessionId"
  $CurrentRoot = "runtime_sessions/builder_life_loop/current"
  $OutputRoot = "self_build_batch/autonomy_trials/$StepId"

  $OutputPath = "$OutputRoot/BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_OUTPUT.json"
  $ResultPath = "$OutputRoot/${StepId}_RESULT.json"
  $RuntimeLogPath = "$OutputRoot/${StepId}_RUNTIME_LOG.txt"
  $ReportPath = "reports/self_development/${StepId}_REPORT.json"
  $ProofPath = "proofs/self_development/${StepId}.json"
  $TrialResultPath = "self_control/BUILDER_CORRECTION_RESPONSE_TRIAL_RESULT.json"

  foreach ($requiredPath in @(
    "modules/invoke_builder_correction_inbox_response_trial_001.ps1",
    "validators/validate_phase143_builder_correction_inbox_response_trial_v1.ps1",
    "orchestrator/run.ps1",
    $Phase142ProofPath,
    "$BaselineRoot/session_summary.json",
    "$BaselineRoot/observation_ledger.jsonl",
    "$BaselineRoot/decision_trace.jsonl",
    "$BaselineRoot/learning_metrics.json",
    "$CurrentRoot/heartbeat.json",
    "$CurrentRoot/life_loop_state.json",
    "$CurrentRoot/observation_ledger.jsonl",
    "$CurrentRoot/decision_trace.jsonl",
    "$CurrentRoot/error_ledger.jsonl",
    "$CurrentRoot/learning_metrics.json",
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
    "$TrialRoot/correction_inbox.json",
    "$TrialRoot/correction_inbox_initial.json",
    "$TrialRoot/correction_applied_log.jsonl",
    "$TrialRoot/session_summary.json",
    $TrialResultPath,
    $OutputPath,
    $ResultPath,
    $RuntimeLogPath,
    $ReportPath,
    $ProofPath
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase143ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE143_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $Phase142Proof = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path $Phase142ProofPath
  Assert-Phase143ValidatorEquals -Actual $Phase142Proof.status -Expected "PASS" -Name "phase142_status"
  Assert-Phase143ValidatorEquals -Actual $Phase142Proof.next_allowed_step -Expected $StepId -Name "phase142_next_allowed_step"
  Assert-Phase143ValidatorTrue -Actual $Phase142Proof.correction_inbox_supported -Name "phase142_correction_inbox_supported"
  Assert-Phase143ValidatorTrue -Actual $Phase142Proof.terminal_watcher_supported -Name "phase142_terminal_watcher_supported"
  Assert-Phase143ValidatorTrue -Actual $Phase142Proof.repo_session_artifacts_created -Name "phase142_repo_session_artifacts_created"
  Assert-Phase143ValidatorEquals -Actual $Phase142Proof.selected_next_gap -Expected $StepId -Name "phase142_selected_next_gap"
  Assert-Phase143ValidatorFalse -Actual $Phase142Proof.external_agent_production_allowed -Name "phase142_external_agent_production_allowed"
  Assert-Phase143ValidatorEquals -Actual $Phase142Proof.trusted_material_count -Expected 0 -Name "phase142_trusted_material_count"
  Assert-Phase143ValidatorFalse -Actual $Phase142Proof.external_fetch_performed -Name "phase142_external_fetch_performed"
  Assert-Phase143ValidatorFalse -Actual $Phase142Proof.dependency_install_performed -Name "phase142_dependency_install_performed"
  Assert-Phase143ValidatorFalse -Actual $Phase142Proof.executable_materials_used -Name "phase142_executable_materials_used"

  $Output = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path $OutputPath
  $Result = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath
  $TrialResult = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path $TrialResultPath
  $CurrentSummary = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path "$CurrentRoot/session_summary.json"
  $TrialSummary = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/session_summary.json"
  $CurrentLearning = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path "$CurrentRoot/learning_metrics.json"
  $TrialLearning = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/learning_metrics.json"
  $CurrentInbox = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path "$CurrentRoot/correction_inbox.json"
  $TrialInbox = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/correction_inbox.json"
  $CurrentInitialInbox = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path "$CurrentRoot/correction_inbox_initial.json"
  $TrialInitialInbox = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path "$TrialRoot/correction_inbox_initial.json"

  foreach ($artifact in @($Output, $Result, $Report, $Proof, $TrialResult, $CurrentSummary, $TrialSummary, $CurrentLearning, $TrialLearning, $CurrentInbox, $TrialInbox, $CurrentInitialInbox, $TrialInitialInbox)) {
    Assert-Phase143ValidatorEquals -Actual $artifact.status -Expected "PASS" -Name "artifact_status"
  }

  foreach ($artifact in @($Output, $Result, $Proof, $TrialResult, $CurrentSummary, $TrialSummary, $CurrentLearning, $TrialLearning)) {
    Assert-Phase143ValidatorEquals -Actual $artifact.next_allowed_step -Expected $NextAllowedStep -Name "next_allowed_step"
  }

  foreach ($artifact in @($Output, $Proof, $TrialResult, $CurrentSummary, $TrialSummary, $CurrentLearning, $TrialLearning)) {
    Assert-Phase143ValidatorAtLeast -Actual $artifact.correction_seen_count -Minimum 1 -Name "correction_seen_count"
    Assert-Phase143ValidatorAtLeast -Actual $artifact.correction_applied_count -Minimum 1 -Name "correction_applied_count"
    Assert-Phase143ValidatorTrue -Actual $artifact.behavior_changed_after_correction -Name "behavior_changed_after_correction"
    Assert-Phase143ValidatorEquals -Actual $artifact.baseline_session -Expected $BaselineSessionId -Name "baseline_session"
    Assert-Phase143ValidatorEquals -Actual $artifact.trial_session -Expected $TrialSessionId -Name "trial_session"
    Assert-Phase143ValidatorEquals -Actual $artifact.selected_next_gap -Expected $NextAllowedStep -Name "selected_next_gap"
  }

  foreach ($artifact in @($Output, $Proof, $TrialResult, $CurrentSummary, $TrialSummary)) {
    Assert-Phase143ValidatorFalse -Actual $artifact.owner_interactive_prompt_required -Name "owner_interactive_prompt_required"
    Assert-Phase143ValidatorFalse -Actual $artifact.external_agent_production_allowed -Name "external_agent_production_allowed"
  }

  foreach ($artifact in @($Output, $Proof, $CurrentSummary, $TrialSummary)) {
    Assert-Phase143ValidatorEquals -Actual $artifact.trusted_material_count -Expected 0 -Name "trusted_material_count"
    Assert-Phase143ValidatorFalse -Actual $artifact.external_fetch_performed -Name "external_fetch_performed"
    Assert-Phase143ValidatorFalse -Actual $artifact.dependency_install_performed -Name "dependency_install_performed"
    Assert-Phase143ValidatorFalse -Actual $artifact.executable_materials_used -Name "executable_materials_used"
  }

  Assert-Phase143ValidatorEquals -Actual $Output.queue_after -Expected "NONE" -Name "output_queue_after"
  Assert-Phase143ValidatorEquals -Actual $Result.queue_after -Expected "NONE" -Name "result_queue_after"
  Assert-Phase143ValidatorEquals -Actual $Proof.queue_after -Expected "NONE" -Name "proof_queue_after"
  Assert-Phase143ValidatorFalse -Actual $Proof.main_touched -Name "proof_main_touched"
  Assert-Phase143ValidatorEquals -Actual $Proof.source_branch -Expected $Branch -Name "proof_source_branch"

  Assert-Phase143ValidatorEquals -Actual $Output.engine_name -Expected $RuntimeId -Name "output_engine_name"
  Assert-Phase143ValidatorEquals -Actual $Proof.run_id -Expected $RuntimeId -Name "proof_run_id"
  Assert-Phase143ValidatorEquals -Actual $TrialResult.selected_by -Expected "BUILDER_RUNTIME" -Name "trial_selected_by"
  Assert-Phase143ValidatorEquals -Actual $CurrentSummary.selected_by -Expected "BUILDER_RUNTIME" -Name "current_summary_selected_by"
  Assert-Phase143ValidatorEquals -Actual $TrialSummary.selected_by -Expected "BUILDER_RUNTIME" -Name "trial_summary_selected_by"

  Assert-Phase143ValidatorEquals -Actual $CurrentInbox.applied_correction_count -Expected 1 -Name "current_inbox_applied_count"
  Assert-Phase143ValidatorEquals -Actual $TrialInbox.applied_correction_count -Expected 1 -Name "trial_inbox_applied_count"
  Assert-Phase143ValidatorEquals -Actual $CurrentInbox.observed_correction_count -Expected 1 -Name "current_inbox_seen_count"
  Assert-Phase143ValidatorEquals -Actual $TrialInbox.observed_correction_count -Expected 1 -Name "trial_inbox_seen_count"

  foreach ($initialInbox in @($CurrentInitialInbox, $TrialInitialInbox)) {
    Assert-Phase143ValidatorEquals -Actual $initialInbox.pending_corrections.Count -Expected 1 -Name "initial_pending_correction_count"
    Assert-Phase143ValidatorEquals -Actual $initialInbox.pending_corrections[0].correction_id -Expected $CorrectionId -Name "initial_correction_id"
    Assert-Phase143ValidatorEquals -Actual $initialInbox.pending_corrections[0].status -Expected "pending" -Name "initial_correction_status"
    Assert-Phase143ValidatorEquals -Actual $initialInbox.pending_corrections[0].message -Expected $CorrectionMessage -Name "initial_correction_message"
  }

  $OrchestratorText = Read-Phase143ValidatorText -RepoRoot $RepoRoot -Path "orchestrator/run.ps1"
  Assert-Phase143ValidatorContains -Text $OrchestratorText -Needle "Invoke-BuilderCorrectionInboxResponseTrial001" -Name "orchestrator_hook"
  Assert-Phase143ValidatorContains -Text $OrchestratorText -Needle "BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL=PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_001" -Name "orchestrator_runtime_signal"

  $RuntimeLog = Read-Phase143ValidatorText -RepoRoot $RepoRoot -Path $RuntimeLogPath
  foreach ($signal in @(
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
  )) {
    Assert-Phase143ValidatorContains -Text $RuntimeLog -Needle $signal -Name "runtime_log_signal"
  }

  $CurrentCorrectionLog = Read-Phase143ValidatorText -RepoRoot $RepoRoot -Path "$CurrentRoot/correction_applied_log.jsonl"
  $TrialCorrectionLog = Read-Phase143ValidatorText -RepoRoot $RepoRoot -Path "$TrialRoot/correction_applied_log.jsonl"
  foreach ($logText in @($CurrentCorrectionLog, $TrialCorrectionLog)) {
    Assert-Phase143ValidatorContains -Text $logText -Needle '"event_type":"CORRECTION_APPLIED"' -Name "correction_applied_log_event"
    Assert-Phase143ValidatorContains -Text $logText -Needle $CorrectionId -Name "correction_applied_log_id"
  }

  $CurrentDecisionText = Read-Phase143ValidatorText -RepoRoot $RepoRoot -Path "$CurrentRoot/decision_trace.jsonl"
  $TrialDecisionText = Read-Phase143ValidatorText -RepoRoot $RepoRoot -Path "$TrialRoot/decision_trace.jsonl"
  foreach ($decisionText in @($CurrentDecisionText, $TrialDecisionText)) {
    Assert-Phase143ValidatorContains -Text $decisionText -Needle "Correction $CorrectionId applied" -Name "decision_trace_correction_reason"
    Assert-Phase143ValidatorContains -Text $decisionText -Needle '"correction_influenced_decision":true' -Name "decision_trace_correction_flag"
    Assert-Phase143ValidatorContains -Text $decisionText -Needle $CorrectionId -Name "decision_trace_correction_id"
  }

  $CurrentObservationText = Read-Phase143ValidatorText -RepoRoot $RepoRoot -Path "$CurrentRoot/observation_ledger.jsonl"
  $TrialObservationText = Read-Phase143ValidatorText -RepoRoot $RepoRoot -Path "$TrialRoot/observation_ledger.jsonl"
  foreach ($observationText in @($CurrentObservationText, $TrialObservationText)) {
    Assert-Phase143ValidatorContains -Text $observationText -Needle '"correction_aware":true' -Name "observation_ledger_correction_aware"
    Assert-Phase143ValidatorContains -Text $observationText -Needle "behavior_change_explanation" -Name "observation_ledger_behavior_change"
    Assert-Phase143ValidatorContains -Text $observationText -Needle $CorrectionId -Name "observation_ledger_correction_id"
  }

  $BaselineDecisionLines = @(Get-Content -LiteralPath (Resolve-Phase143ValidatorPath -RepoRoot $RepoRoot -Path "$BaselineRoot/decision_trace.jsonl") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  $TrialDecisionLines = @(Get-Content -LiteralPath (Resolve-Phase143ValidatorPath -RepoRoot $RepoRoot -Path "$TrialRoot/decision_trace.jsonl") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  $BaselineSequence = @($BaselineDecisionLines | ForEach-Object { (ConvertFrom-Json $_).selected_task_type } | Select-Object -First 12)
  $TrialSequence = @($TrialDecisionLines | ForEach-Object { (ConvertFrom-Json $_).selected_task_type } | Select-Object -First 12)

  if ($BaselineSequence.Count -lt 12) {
    throw "PHASE143_VALIDATE_BASELINE_SEQUENCE_TOO_SHORT=$($BaselineSequence.Count)"
  }
  if ($TrialSequence.Count -ne 12) {
    throw "PHASE143_VALIDATE_TRIAL_SEQUENCE_UNEXPECTED_COUNT=$($TrialSequence.Count)"
  }
  if (($BaselineSequence -join ",") -eq ($TrialSequence -join ",")) {
    throw "PHASE143_VALIDATE_BEHAVIOR_DID_NOT_CHANGE"
  }
  Assert-Phase143ValidatorEquals -Actual $TrialSequence[0] -Expected "READ_CURRENT_STATE" -Name "trial_sequence_0"
  Assert-Phase143ValidatorEquals -Actual $TrialSequence[1] -Expected "WRITE_LEARNING_NOTE" -Name "trial_sequence_1"
  Assert-Phase143ValidatorEquals -Actual $TrialSequence[2] -Expected "SELECT_NEXT_MICRO_GAP" -Name "trial_sequence_2"

  $Queue = Read-Phase143ValidatorJson -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
  Assert-Phase143ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  $ExternalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
  if ($ExternalAgentStatus.Count -gt 0) {
    throw "PHASE143_VALIDATE_EXTERNAL_AGENT_SCOPE_DIRTY=$($ExternalAgentStatus -join '; ')"
  }

  Write-Host "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_VALIDATE_RESULT=PASS"
  Write-Host "CORRECTION_SEEN_COUNT=$($Proof.correction_seen_count)"
  Write-Host "CORRECTION_APPLIED_COUNT=$($Proof.correction_applied_count)"
  Write-Host "BEHAVIOR_CHANGED_AFTER_CORRECTION=$($Proof.behavior_changed_after_correction)"
  Write-Host "NEXT_ALLOWED_STEP=$($Proof.next_allowed_step)"
} catch {
  Write-Host "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE143_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  Pop-Location
}
