param(
  [string]$RepoRoot = ".",
  [string]$SessionId = "LIVE_AFTER_PHASE145_001"
)

$ErrorActionPreference = "Stop"

function Resolve-Phase146ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase146ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase146ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE146_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase146ValidatorText {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase146ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE146_VALIDATE_MISSING_TEXT=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw
}

function Read-Phase146ValidatorJsonLines {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase146ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE146_VALIDATE_MISSING_JSONL=$Path"
  }

  return @(Get-Content -LiteralPath $fullPath |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { ConvertFrom-Json $_ })
}

function Assert-Phase146ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE146_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase146ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE146_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase146ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE146_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase146ValidatorAtLeast {
  param(
    [object]$Actual,
    [int]$Minimum,
    [string]$Name
  )

  if ([int]$Actual -lt $Minimum) {
    throw "PHASE146_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase146ValidatorContains {
  param(
    [string]$Text,
    [string]$Needle,
    [string]$Name
  )

  if (-not $Text.Contains($Needle)) {
    throw "PHASE146_VALIDATE_TEXT_MISSING=$Name needle=$Needle"
  }
}

try {
  $StepId = "PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1"
  $RunId = "PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_001"
  $PreviousNextAllowedStep = "PHASE146_BUILDER_LONG_RUNNING_OBSERVABLE_LEARNING_SUPERVISOR_V1"
  $NextAllowedStep = "PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1"

  $RepoRoot = Resolve-Phase146ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot

  foreach ($identityFile in @(
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1"
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase146ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE146_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }

  $ObservationRoot = "runtime_sessions/builder_life_loop/observations/$SessionId"
  $Phase145ProofPath = "proofs/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1.json"
  $Phase145ReportPath = "reports/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1_REPORT.json"
  $Phase145ResultPath = "self_control/BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_RESULT.json"
  $Phase145BatchRoot = "self_build_batch/autonomy_trials/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1"
  $Phase145TrialRoot = "runtime_sessions/builder_life_loop/multi_session_trials/PHASE145_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_001"
  $CurrentRoot = "runtime_sessions/builder_life_loop/current"
  $LearningMemoryPath = "self_control/BUILDER_MULTI_SESSION_LEARNING_MEMORY.json"
  $ResultPath = "self_control/BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_RESULT.json"
  $ReportPath = "reports/self_development/${StepId}_REPORT.json"
  $ProofPath = "proofs/self_development/${StepId}.json"
  $RuntimeLogPath = "$ObservationRoot/${StepId}_RUNTIME_LOG.txt"

  foreach ($requiredPath in @(
    "tools/start_builder_observation_session.ps1",
    "tools/watch_builder_observation_session.ps1",
    "tools/stop_builder_observation_session.ps1",
    "modules/invoke_builder_observation_only_live_runner_001.ps1",
    "validators/validate_phase146_builder_observation_only_live_runner_v1.ps1",
    $Phase145ProofPath,
    $Phase145ReportPath,
    $Phase145ResultPath,
    $LearningMemoryPath,
    $ObservationRoot,
    "$ObservationRoot/heartbeat.json",
    "$ObservationRoot/life_loop_state.json",
    "$ObservationRoot/observation_ledger.jsonl",
    "$ObservationRoot/decision_trace.jsonl",
    "$ObservationRoot/learning_metrics.json",
    "$ObservationRoot/session_summary.json",
    "$ObservationRoot/protected_artifact_hashes_before.json",
    "$ObservationRoot/protected_artifact_hashes_after.json",
    $RuntimeLogPath,
    $ResultPath,
    $ReportPath,
    $ProofPath
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase146ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE146_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  foreach ($checkpoint in @("checkpoint_005.json", "checkpoint_010.json", "checkpoint_015.json", "checkpoint_020.json", "checkpoint_025.json", "checkpoint_030.json")) {
    $checkpointPath = "$ObservationRoot/checkpoints/$checkpoint"
    if (-not (Test-Path -LiteralPath (Resolve-Phase146ValidatorPath -RepoRoot $RepoRoot -Path $checkpointPath))) {
      throw "PHASE146_VALIDATE_MISSING_CHECKPOINT=$checkpointPath"
    }
  }

  $Phase145Proof = Read-Phase146ValidatorJson -RepoRoot $RepoRoot -Path $Phase145ProofPath
  Assert-Phase146ValidatorEquals -Actual $Phase145Proof.status -Expected "PASS" -Name "phase145_status"
  Assert-Phase146ValidatorEquals -Actual $Phase145Proof.next_allowed_step -Expected $PreviousNextAllowedStep -Name "phase145_next_allowed_step"
  Assert-Phase146ValidatorEquals -Actual $Phase145Proof.selected_by -Expected "BUILDER_RUNTIME" -Name "phase145_selected_by"
  Assert-Phase146ValidatorFalse -Actual $Phase145Proof.owner_interactive_prompt_required -Name "phase145_owner_prompt"
  Assert-Phase146ValidatorFalse -Actual $Phase145Proof.external_agent_production_allowed -Name "phase145_external_agent_production_allowed"

  $SessionSummary = Read-Phase146ValidatorJson -RepoRoot $RepoRoot -Path "$ObservationRoot/session_summary.json"
  $LearningMetrics = Read-Phase146ValidatorJson -RepoRoot $RepoRoot -Path "$ObservationRoot/learning_metrics.json"
  $Result = Read-Phase146ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase146ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase146ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath

  foreach ($artifact in @($SessionSummary, $LearningMetrics, $Result, $Report, $Proof)) {
    Assert-Phase146ValidatorEquals -Actual $artifact.status -Expected "PASS" -Name "artifact_status"
    Assert-Phase146ValidatorEquals -Actual $artifact.next_allowed_step -Expected $NextAllowedStep -Name "artifact_next_allowed_step"
  }

  foreach ($artifact in @($SessionSummary, $LearningMetrics, $Result, $Proof)) {
    Assert-Phase146ValidatorEquals -Actual $artifact.observation_session_id -Expected $SessionId -Name "observation_session_id"
    Assert-Phase146ValidatorAtLeast -Actual $artifact.completed_cycles -Minimum 30 -Name "completed_cycles"
    Assert-Phase146ValidatorTrue -Actual $artifact.builder_runtime_decision_author -Name "builder_runtime_decision_author"
    Assert-Phase146ValidatorTrue -Actual $artifact.supervisor_lifecycle_only -Name "supervisor_lifecycle_only"
    Assert-Phase146ValidatorTrue -Actual $artifact.accepted_phase_artifacts_untouched -Name "accepted_phase_artifacts_untouched"
    Assert-Phase146ValidatorFalse -Actual $artifact.routed_phase_runtime_invoked -Name "routed_phase_runtime_invoked"
    Assert-Phase146ValidatorFalse -Actual $artifact.owner_interactive_prompt_required -Name "owner_interactive_prompt_required"
    Assert-Phase146ValidatorFalse -Actual $artifact.external_agent_production_allowed -Name "external_agent_production_allowed"
    Assert-Phase146ValidatorEquals -Actual $artifact.selected_next_gap -Expected $NextAllowedStep -Name "selected_next_gap"
    Assert-Phase146ValidatorEquals -Actual $artifact.selected_by -Expected "BUILDER_RUNTIME" -Name "selected_by"
  }

  foreach ($artifact in @($SessionSummary, $LearningMetrics, $Proof)) {
    Assert-Phase146ValidatorEquals -Actual $artifact.trusted_material_count -Expected 0 -Name "trusted_material_count"
    Assert-Phase146ValidatorFalse -Actual $artifact.external_fetch_performed -Name "external_fetch_performed"
    Assert-Phase146ValidatorFalse -Actual $artifact.dependency_install_performed -Name "dependency_install_performed"
    Assert-Phase146ValidatorFalse -Actual $artifact.executable_materials_used -Name "executable_materials_used"
  }

  Assert-Phase146ValidatorTrue -Actual $Result.observation_artifacts_created -Name "result_observation_artifacts_created"
  Assert-Phase146ValidatorTrue -Actual $Result.watcher_supported -Name "result_watcher_supported"
  Assert-Phase146ValidatorTrue -Actual $Result.stop_file_supported -Name "result_stop_file_supported"
  Assert-Phase146ValidatorTrue -Actual $Proof.runtime_executed -Name "proof_runtime_executed"
  Assert-Phase146ValidatorTrue -Actual $Proof.builder_runtime_invoked -Name "proof_builder_runtime_invoked"
  Assert-Phase146ValidatorFalse -Actual $Proof.production_adoption_allowed -Name "proof_production_adoption_allowed"
  Assert-Phase146ValidatorEquals -Actual $Proof.queue_after -Expected "NONE" -Name "proof_queue_after"
  Assert-Phase146ValidatorFalse -Actual $Proof.main_touched -Name "proof_main_touched"
  Assert-Phase146ValidatorEquals -Actual $Proof.source_branch -Expected $Branch -Name "proof_source_branch"

  $Decisions = Read-Phase146ValidatorJsonLines -RepoRoot $RepoRoot -Path "$ObservationRoot/decision_trace.jsonl"
  $Observations = Read-Phase146ValidatorJsonLines -RepoRoot $RepoRoot -Path "$ObservationRoot/observation_ledger.jsonl"
  Assert-Phase146ValidatorAtLeast -Actual $Decisions.Count -Minimum 30 -Name "decision_trace_count"
  Assert-Phase146ValidatorAtLeast -Actual $Observations.Count -Minimum 30 -Name "observation_ledger_count"

  foreach ($decision in $Decisions) {
    Assert-Phase146ValidatorEquals -Actual $decision.selected_by -Expected "BUILDER_RUNTIME" -Name "decision_selected_by"
    Assert-Phase146ValidatorEquals -Actual $decision.lifecycle_authority -Expected "OBSERVATION_RUNNER_ONLY" -Name "decision_lifecycle_authority"
    Assert-Phase146ValidatorTrue -Actual $decision.uses_learning_memory -Name "decision_uses_learning_memory"
    Assert-Phase146ValidatorFalse -Actual $decision.owner_interactive_prompt_required -Name "decision_owner_prompt"
    if ([string]::IsNullOrWhiteSpace($decision.selected_task_type)) {
      throw "PHASE146_VALIDATE_DECISION_MISSING_SELECTED_TASK_TYPE"
    }
    if ([string]::IsNullOrWhiteSpace($decision.selection_reason)) {
      throw "PHASE146_VALIDATE_DECISION_MISSING_SELECTION_REASON"
    }
  }

  foreach ($observation in $Observations) {
    Assert-Phase146ValidatorEquals -Actual $observation.selected_by -Expected "BUILDER_RUNTIME" -Name "observation_selected_by"
    Assert-Phase146ValidatorEquals -Actual $observation.lifecycle_authority -Expected "OBSERVATION_RUNNER_ONLY" -Name "observation_lifecycle_authority"
    Assert-Phase146ValidatorTrue -Actual $observation.uses_learning_memory -Name "observation_uses_learning_memory"
    Assert-Phase146ValidatorTrue -Actual $observation.supervisor_lifecycle_only -Name "observation_supervisor_lifecycle_only"
    Assert-Phase146ValidatorFalse -Actual $observation.routed_phase_runtime_invoked -Name "observation_routed_phase_runtime_invoked"
  }

  $BeforeSnapshot = Read-Phase146ValidatorJson -RepoRoot $RepoRoot -Path "$ObservationRoot/protected_artifact_hashes_before.json"
  $AfterSnapshot = Read-Phase146ValidatorJson -RepoRoot $RepoRoot -Path "$ObservationRoot/protected_artifact_hashes_after.json"
  $beforeJson = (@($BeforeSnapshot) | ConvertTo-Json -Depth 20 -Compress)
  $afterJson = (@($AfterSnapshot) | ConvertTo-Json -Depth 20 -Compress)
  if (-not [string]::Equals($beforeJson, $afterJson, [System.StringComparison]::Ordinal)) {
    throw "PHASE146_VALIDATE_PROTECTED_HASH_SNAPSHOT_CHANGED"
  }

  $ProtectedStatus = @(git status --short --untracked-files=all -- `
    $Phase145ProofPath `
    $Phase145ReportPath `
    $Phase145ResultPath `
    $Phase145BatchRoot `
    $Phase145TrialRoot `
    $CurrentRoot `
    $LearningMemoryPath 2>$null)
  if ($ProtectedStatus.Count -gt 0) {
    throw "PHASE146_VALIDATE_PROTECTED_PATH_DIRTY=$($ProtectedStatus -join '; ')"
  }

  $ExternalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
  if ($ExternalAgentStatus.Count -gt 0) {
    throw "PHASE146_VALIDATE_EXTERNAL_AGENT_SCOPE_DIRTY=$($ExternalAgentStatus -join '; ')"
  }

  $Queue = Read-Phase146ValidatorJson -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
  Assert-Phase146ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  $StartTool = Read-Phase146ValidatorText -RepoRoot $RepoRoot -Path "tools/start_builder_observation_session.ps1"
  $WatchTool = Read-Phase146ValidatorText -RepoRoot $RepoRoot -Path "tools/watch_builder_observation_session.ps1"
  $StopTool = Read-Phase146ValidatorText -RepoRoot $RepoRoot -Path "tools/stop_builder_observation_session.ps1"
  Assert-Phase146ValidatorContains -Text $StartTool -Needle "Invoke-BuilderObservationOnlyLiveRunner001" -Name "start_invokes_observation_module"
  if ($StartTool.Contains("-Mode SELF_BUILD") -or $StartTool.Contains("& (Join-Path `$RepoRoot `"orchestrator/run.ps1`")")) {
    throw "PHASE146_VALIDATE_START_TOOL_CALLS_ORCHESTRATOR_ROUTE"
  }
  Assert-Phase146ValidatorContains -Text $WatchTool -Needle "runtime_sessions/builder_life_loop/observations/" -Name "watch_observation_root"
  if ($WatchTool.Contains("runtime_sessions/builder_life_loop/current")) {
    throw "PHASE146_VALIDATE_WATCH_TOOL_READS_CURRENT"
  }
  Assert-Phase146ValidatorContains -Text $WatchTool -Needle "Iterations" -Name "watch_iterations_supported"
  Assert-Phase146ValidatorContains -Text $StopTool -Needle "STOP_REQUESTED" -Name "stop_file_supported"

  $RuntimeLog = Read-Phase146ValidatorText -RepoRoot $RepoRoot -Path $RuntimeLogPath
  foreach ($signal in @(
    "BUILDER_OBSERVATION_ONLY_LIVE_RUNNER=PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_001",
    "OBSERVATION_SESSION_ID=LIVE_AFTER_PHASE145_001",
    "OBSERVATION_ONLY_STATUS=PASS",
    "COMPLETED_CYCLES=30",
    "BUILDER_RUNTIME_DECISION_AUTHOR=True",
    "SUPERVISOR_LIFECYCLE_ONLY=True",
    "ACCEPTED_PHASE_ARTIFACTS_UNTOUCHED=True",
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
  )) {
    Assert-Phase146ValidatorContains -Text $RuntimeLog -Needle $signal -Name "runtime_log_signal"
  }

  Write-Host "PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_VALIDATE_RESULT=PASS"
  Write-Host "OBSERVATION_SESSION_ID=$($Proof.observation_session_id)"
  Write-Host "COMPLETED_CYCLES=$($Proof.completed_cycles)"
  Write-Host "BUILDER_RUNTIME_DECISION_AUTHOR=$($Proof.builder_runtime_decision_author)"
  Write-Host "SUPERVISOR_LIFECYCLE_ONLY=$($Proof.supervisor_lifecycle_only)"
  Write-Host "NEXT_ALLOWED_STEP=$($Proof.next_allowed_step)"
} catch {
  Write-Host "PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE146_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  Pop-Location
}
