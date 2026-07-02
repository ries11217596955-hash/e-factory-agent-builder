$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

function Read-JsonOrFail {
  param([string]$Path)

  try {
    if (-not (Test-Path -LiteralPath $Path)) {
      Mark-Fail "MISSING=$Path"
      return $null
    }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  } catch {
    Mark-Fail "JSON_PARSE_FAIL=$Path :: $($_.Exception.Message)"
    return $null
  }
}

function Test-PropertyExists {
  param(
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object) { return $false }
  return $null -ne ($Object.PSObject.Properties | Where-Object { $_.Name -eq $Name } | Select-Object -First 1)
}

function Get-PropertyValue {
  param(
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object) { return $null }
  $property = $Object.PSObject.Properties | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
  if ($null -eq $property) { return $null }
  return $property.Value
}

function Assert-Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    Mark-Fail "$Name`_UNEXPECTED=$Actual EXPECTED=$Expected"
  }
}

function Assert-True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    Mark-Fail "$Name`_NOT_TRUE=$Actual"
  }
}

function Assert-False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    Mark-Fail "$Name`_NOT_FALSE=$Actual"
  }
}

function Assert-FalseProperty {
  param(
    [object]$Object,
    [string]$PropertyName,
    [string]$Context
  )

  if (Test-PropertyExists -Object $Object -Name $PropertyName) {
    $value = Get-PropertyValue -Object $Object -Name $PropertyName
    if ($value -ne $false) {
      Mark-Fail "$Context`_$PropertyName`_NOT_FALSE=$value"
    }
  }
}

function Assert-ZeroProperty {
  param(
    [object]$Object,
    [string]$PropertyName,
    [string]$Context
  )

  if (Test-PropertyExists -Object $Object -Name $PropertyName) {
    $value = Get-PropertyValue -Object $Object -Name $PropertyName
    if ($value -ne 0) {
      Mark-Fail "$Context`_$PropertyName`_NOT_ZERO=$value"
    }
  }
}

function Assert-NoForbiddenFlags {
  param(
    [object]$Object,
    [string]$Context
  )

  foreach ($propertyName in @(
    "external_agent_production_allowed",
    "production_adoption_allowed",
    "external_fetch_performed",
    "dependency_install_performed",
    "executable_materials_used",
    "dependency_install_allowed",
    "external_fetch_allowed",
    "executable_use_allowed",
    "codex_authored",
    "codex_authored_generated_pack",
    "codex_authored_generated_packs",
    "owner_interactive_prompt_required"
  )) {
    if ($propertyName -eq "owner_interactive_prompt_required") {
      Assert-FalseProperty -Object $Object -PropertyName $propertyName -Context $Context
    } else {
      Assert-FalseProperty -Object $Object -PropertyName $propertyName -Context $Context
    }
  }

  Assert-ZeroProperty -Object $Object -PropertyName "trusted_material_count" -Context $Context
}

function Assert-TextContains {
  param(
    [string]$Text,
    [string]$Needle,
    [string]$Name
  )

  if ($Text -notmatch [regex]::Escape($Needle)) {
    Mark-Fail "$Name`_TEXT_MISSING=$Needle"
  }
}

$StepId = "PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1"
$RunId = "PHASE142_BUILDER_NEXT_GAP_SELECTOR_OBSERVABLE_LIFE_LOOP_001"
$PreviousStepId = "PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_V1"
$NextAllowed = "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1"
$ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"

$SessionRoot = "runtime_sessions/builder_life_loop/current"
$HeartbeatPath = "$SessionRoot/heartbeat.json"
$LifeLoopStatePath = "$SessionRoot/life_loop_state.json"
$ObservationLedgerPath = "$SessionRoot/observation_ledger.jsonl"
$DecisionTracePath = "$SessionRoot/decision_trace.jsonl"
$ErrorLedgerPath = "$SessionRoot/error_ledger.jsonl"
$LearningMetricsPath = "$SessionRoot/learning_metrics.json"
$CorrectionInboxPath = "$SessionRoot/correction_inbox.json"
$CorrectionAppliedLogPath = "$SessionRoot/correction_applied_log.jsonl"
$SessionSummaryPath = "$SessionRoot/session_summary.json"
$Checkpoint005Path = "$SessionRoot/checkpoints/checkpoint_005.json"
$Phase141ProofPath = "proofs/self_development/${PreviousStepId}.json"
$LifeLoopPolicyPath = "self_control/BUILDER_LIFE_LOOP_POLICY.json"
$NextGapSelectorResultPath = "self_control/BUILDER_NEXT_GAP_SELECTOR_RESULT.json"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/BUILDER_NEXT_GAP_SELECTOR_OBSERVABLE_LIFE_LOOP_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$RuntimeLogPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RUNTIME_LOG.txt"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($path in @(
  "modules/invoke_builder_next_gap_selector_observable_life_loop_001.ps1",
  "validators/validate_phase142_builder_next_gap_selector_observable_life_loop_v1.ps1",
  "orchestrator/run.ps1",
  "tools/start_builder_life_loop.ps1",
  "tools/watch_builder_life_loop.ps1",
  "tools/stop_builder_life_loop.ps1",
  "tools/write_builder_life_loop_correction.ps1",
  "tools/publish_builder_life_loop_checkpoint.ps1",
  $Phase141ProofPath,
  $HeartbeatPath,
  $LifeLoopStatePath,
  $ObservationLedgerPath,
  $DecisionTracePath,
  $ErrorLedgerPath,
  $LearningMetricsPath,
  $CorrectionInboxPath,
  $CorrectionAppliedLogPath,
  $SessionSummaryPath,
  $Checkpoint005Path,
  $LifeLoopPolicyPath,
  $NextGapSelectorResultPath,
  $OutputPath,
  $ResultPath,
  $RuntimeLogPath,
  $ReportPath,
  $ProofPath
)) {
  if (-not (Test-Path -LiteralPath $path)) {
    Mark-Fail "MISSING=$path"
  } else {
    Write-Output "EXISTS=$path"
  }
}

$Phase141Proof = Read-JsonOrFail -Path $Phase141ProofPath
$Heartbeat = Read-JsonOrFail -Path $HeartbeatPath
$LifeLoopState = Read-JsonOrFail -Path $LifeLoopStatePath
$LearningMetrics = Read-JsonOrFail -Path $LearningMetricsPath
$CorrectionInbox = Read-JsonOrFail -Path $CorrectionInboxPath
$SessionSummary = Read-JsonOrFail -Path $SessionSummaryPath
$Checkpoint005 = Read-JsonOrFail -Path $Checkpoint005Path
$LifeLoopPolicy = Read-JsonOrFail -Path $LifeLoopPolicyPath
$NextGapSelectorResult = Read-JsonOrFail -Path $NextGapSelectorResultPath
$Output = Read-JsonOrFail -Path $OutputPath
$Result = Read-JsonOrFail -Path $ResultPath
$Report = Read-JsonOrFail -Path $ReportPath
$Proof = Read-JsonOrFail -Path $ProofPath
$Queue = Read-JsonOrFail -Path "TASK_QUEUE.json"

try {
  $OrchestratorText = Get-Content -LiteralPath "orchestrator/run.ps1" -Raw
  Assert-TextContains -Text $OrchestratorText -Needle "Invoke-BuilderNextGapSelectorObservableLifeLoop001" -Name "ORCHESTRATOR"
  Assert-TextContains -Text $OrchestratorText -Needle "BUILDER_NEXT_GAP_SELECTOR_RUNTIME=PHASE142_BUILDER_NEXT_GAP_SELECTOR_OBSERVABLE_LIFE_LOOP_001" -Name "ORCHESTRATOR"
} catch {
  Mark-Fail "ORCHESTRATOR_READ_FAIL=$($_.Exception.Message)"
}

try {
  $RuntimeLog = Get-Content -LiteralPath $RuntimeLogPath -Raw
  foreach ($requiredSignal in @(
    "BUILDER_NEXT_GAP_SELECTOR_RUNTIME=PHASE142_BUILDER_NEXT_GAP_SELECTOR_OBSERVABLE_LIFE_LOOP_001",
    "OBSERVABLE_LIFE_LOOP_STATUS=PASS",
    "LIFE_LOOP_OBSERVATION_LEDGER_CREATED=True",
    "LIFE_LOOP_DECISION_TRACE_CREATED=True",
    "LIFE_LOOP_CORRECTION_INBOX_SUPPORTED=True",
    "LIFE_LOOP_TERMINAL_WATCHER_SUPPORTED=True",
    "LIFE_LOOP_REPO_SESSION_ARTIFACTS_CREATED=True",
    "BUILDER_SELECTED_NEXT_GAP=PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1",
    "OWNER_INTERACTIVE_PROMPT_REQUIRED=False",
    "EXTERNAL_AGENT_PRODUCTION_ALLOWED=False",
    "MATERIAL_TRUSTED_COUNT=0",
    "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
    "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
    "MATERIAL_EXECUTABLE_USED=False",
    "NEXT_ALLOWED_STEP=PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1",
    "STATUS=PASS_STOPPED_BUILDER_NEXT_GAP_SELECTOR_OBSERVABLE_LIFE_LOOP_BUILT"
  )) {
    if ($RuntimeLog -notmatch [regex]::Escape($requiredSignal)) {
      Mark-Fail "RUNTIME_LOG_SIGNAL_MISSING=$requiredSignal"
    } else {
      Write-Output "RUNTIME_LOG_SIGNAL_PRESENT=$requiredSignal"
    }
  }

  if ($RuntimeLog -notmatch "LIFE_LOOP_MAX_CYCLES=\d+") {
    Mark-Fail "RUNTIME_LOG_LIFE_LOOP_MAX_CYCLES_SIGNAL_MISSING"
  }
  if ($RuntimeLog -notmatch "LIFE_LOOP_COMPLETED_CYCLES=\d+") {
    Mark-Fail "RUNTIME_LOG_LIFE_LOOP_COMPLETED_CYCLES_SIGNAL_MISSING"
  }
} catch {
  Mark-Fail "RUNTIME_LOG_READ_FAIL=$($_.Exception.Message)"
}

try {
  $ObservationText = Get-Content -LiteralPath $ObservationLedgerPath -Raw
  $DecisionText = Get-Content -LiteralPath $DecisionTracePath -Raw

  foreach ($taskType in @(
    "READ_CURRENT_STATE",
    "READ_NEXT_ACTION",
    "FIND_LAST_ACCEPTED_PROOF",
    "COMPARE_NEXT_STEP",
    "WRITE_LEARNING_NOTE",
    "SELECT_NEXT_MICRO_GAP"
  )) {
    Assert-TextContains -Text $ObservationText -Needle "`"task_type`":`"$taskType`"" -Name "OBSERVATION_LEDGER"
    Assert-TextContains -Text $DecisionText -Needle "`"selected_task_type`":`"$taskType`"" -Name "DECISION_TRACE"
  }
} catch {
  Mark-Fail "LEDGER_READ_FAIL=$($_.Exception.Message)"
}

try {
  $ExternalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
  if ($ExternalAgentStatus.Count -gt 0) {
    Mark-Fail "EXTERNAL_AGENT_FOLDER_CREATED_OR_TOUCHED=$($ExternalAgentStatus -join '; ')"
  } else {
    Write-Output "EXTERNAL_AGENT_SCOPE_STATUS=CLEAN"
  }
} catch {
  Mark-Fail "EXTERNAL_AGENT_SCOPE_STATUS_READ_FAIL=$($_.Exception.Message)"
}

if ($null -ne $Phase141Proof) {
  Assert-Equals -Actual $Phase141Proof.status -Expected "PASS" -Name "PHASE141_PROOF_STATUS"
  Assert-Equals -Actual $Phase141Proof.next_allowed_step -Expected $StepId -Name "PHASE141_PROOF_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenFlags -Object $Phase141Proof -Context "PHASE141_PROOF"
}

foreach ($artifactSpec in @(
  @{ Name = "HEARTBEAT"; Object = $Heartbeat },
  @{ Name = "LIFE_LOOP_STATE"; Object = $LifeLoopState },
  @{ Name = "LEARNING_METRICS"; Object = $LearningMetrics },
  @{ Name = "CORRECTION_INBOX"; Object = $CorrectionInbox },
  @{ Name = "SESSION_SUMMARY"; Object = $SessionSummary },
  @{ Name = "CHECKPOINT_005"; Object = $Checkpoint005 },
  @{ Name = "LIFE_LOOP_POLICY"; Object = $LifeLoopPolicy },
  @{ Name = "NEXT_GAP_SELECTOR_RESULT"; Object = $NextGapSelectorResult },
  @{ Name = "OUTPUT"; Object = $Output },
  @{ Name = "RESULT"; Object = $Result },
  @{ Name = "REPORT"; Object = $Report },
  @{ Name = "PROOF"; Object = $Proof }
)) {
  $artifactName = $artifactSpec.Name
  $artifact = $artifactSpec.Object
  if ($null -eq $artifact) { continue }

  Write-Output "$artifactName`_STATUS=$($artifact.status)"
  Assert-Equals -Actual $artifact.status -Expected "PASS" -Name "$artifactName`_STATUS"
  Assert-NoForbiddenFlags -Object $artifact -Context $artifactName
}

if ($null -ne $LifeLoopPolicy) {
  Assert-Equals -Actual $LifeLoopPolicy.max_cycles_default -Expected 10 -Name "POLICY_MAX_CYCLES_DEFAULT"
  Assert-Equals -Actual $LifeLoopPolicy.checkpoint_every_default -Expected 5 -Name "POLICY_CHECKPOINT_EVERY_DEFAULT"
  Assert-False -Actual $LifeLoopPolicy.owner_interactive_prompt_required -Name "POLICY_OWNER_INTERACTIVE_PROMPT_REQUIRED"
  Assert-True -Actual $LifeLoopPolicy.correction_inbox_supported -Name "POLICY_CORRECTION_INBOX_SUPPORTED"
  Assert-True -Actual $LifeLoopPolicy.terminal_watcher_supported -Name "POLICY_TERMINAL_WATCHER_SUPPORTED"
  Assert-True -Actual $LifeLoopPolicy.repo_session_artifacts_supported -Name "POLICY_REPO_SESSION_ARTIFACTS_SUPPORTED"
  Assert-False -Actual $LifeLoopPolicy.external_agent_production_allowed -Name "POLICY_EXTERNAL_AGENT_PRODUCTION_ALLOWED"
  Assert-False -Actual $LifeLoopPolicy.dependency_install_allowed -Name "POLICY_DEPENDENCY_INSTALL_ALLOWED"
  Assert-False -Actual $LifeLoopPolicy.external_fetch_allowed -Name "POLICY_EXTERNAL_FETCH_ALLOWED"
  Assert-False -Actual $LifeLoopPolicy.executable_use_allowed -Name "POLICY_EXECUTABLE_USE_ALLOWED"
}

if ($null -ne $NextGapSelectorResult) {
  Assert-Equals -Actual $NextGapSelectorResult.selected_next_gap -Expected $NextAllowed -Name "SELECTOR_RESULT_SELECTED_NEXT_GAP"
  Assert-Equals -Actual $NextGapSelectorResult.selected_by -Expected "BUILDER_RUNTIME" -Name "SELECTOR_RESULT_SELECTED_BY"
  Assert-Equals -Actual $NextGapSelectorResult.based_on -Expected "PHASE141 metrics and PHASE142 observation loop" -Name "SELECTOR_RESULT_BASED_ON"
  Assert-Equals -Actual $NextGapSelectorResult.reason -Expected "next gap should prove Builder can notice and respond to correction inbox without Owner/Assistant authoring every cycle" -Name "SELECTOR_RESULT_REASON"
  Assert-False -Actual $NextGapSelectorResult.external_agent_production_allowed -Name "SELECTOR_RESULT_EXTERNAL_AGENT_PRODUCTION_ALLOWED"
}

if ($null -ne $SessionSummary) {
  if ($SessionSummary.completed_cycles -lt 5) {
    Mark-Fail "SESSION_SUMMARY_COMPLETED_CYCLES_TOO_LOW=$($SessionSummary.completed_cycles)"
  }
  Assert-True -Actual $SessionSummary.observation_ledger_created -Name "SESSION_SUMMARY_OBSERVATION_LEDGER_CREATED"
  Assert-True -Actual $SessionSummary.decision_trace_created -Name "SESSION_SUMMARY_DECISION_TRACE_CREATED"
  Assert-True -Actual $SessionSummary.correction_inbox_supported -Name "SESSION_SUMMARY_CORRECTION_INBOX_SUPPORTED"
  Assert-True -Actual $SessionSummary.terminal_watcher_supported -Name "SESSION_SUMMARY_TERMINAL_WATCHER_SUPPORTED"
  Assert-True -Actual $SessionSummary.repo_session_artifacts_created -Name "SESSION_SUMMARY_REPO_SESSION_ARTIFACTS_CREATED"
  Assert-Equals -Actual $SessionSummary.selected_next_gap -Expected $NextAllowed -Name "SESSION_SUMMARY_SELECTED_NEXT_GAP"
}

if ($null -ne $Proof) {
  Assert-True -Actual $Proof.runtime_executed -Name "PROOF_RUNTIME_EXECUTED"
  Assert-True -Actual $Proof.builder_runtime_invoked -Name "PROOF_BUILDER_RUNTIME_INVOKED"
  Assert-True -Actual $Proof.life_loop_session_created -Name "PROOF_LIFE_LOOP_SESSION_CREATED"
  if ($Proof.life_loop_completed_cycles -lt 5) {
    Mark-Fail "PROOF_LIFE_LOOP_COMPLETED_CYCLES_TOO_LOW=$($Proof.life_loop_completed_cycles)"
  }
  Assert-True -Actual $Proof.observation_ledger_created -Name "PROOF_OBSERVATION_LEDGER_CREATED"
  Assert-True -Actual $Proof.decision_trace_created -Name "PROOF_DECISION_TRACE_CREATED"
  Assert-True -Actual $Proof.correction_inbox_supported -Name "PROOF_CORRECTION_INBOX_SUPPORTED"
  Assert-True -Actual $Proof.terminal_watcher_supported -Name "PROOF_TERMINAL_WATCHER_SUPPORTED"
  Assert-True -Actual $Proof.repo_session_artifacts_created -Name "PROOF_REPO_SESSION_ARTIFACTS_CREATED"
  Assert-Equals -Actual $Proof.selected_next_gap -Expected $NextAllowed -Name "PROOF_SELECTED_NEXT_GAP"
  Assert-Equals -Actual $Proof.selected_by -Expected "BUILDER_RUNTIME" -Name "PROOF_SELECTED_BY"
  Assert-False -Actual $Proof.owner_interactive_prompt_required -Name "PROOF_OWNER_INTERACTIVE_PROMPT_REQUIRED"
  Assert-Equals -Actual $Proof.current_line -Expected "SELF_BUILD" -Name "PROOF_CURRENT_LINE"
  Assert-False -Actual $Proof.external_agent_production_allowed -Name "PROOF_EXTERNAL_AGENT_PRODUCTION_ALLOWED"
  Assert-False -Actual $Proof.production_adoption_allowed -Name "PROOF_PRODUCTION_ADOPTION_ALLOWED"
  Assert-Equals -Actual $Proof.trusted_material_count -Expected 0 -Name "PROOF_TRUSTED_COUNT"
  Assert-False -Actual $Proof.external_fetch_performed -Name "PROOF_EXTERNAL_FETCH_PERFORMED"
  Assert-False -Actual $Proof.dependency_install_performed -Name "PROOF_DEPENDENCY_INSTALL_PERFORMED"
  Assert-False -Actual $Proof.executable_materials_used -Name "PROOF_EXECUTABLE_MATERIALS_USED"
  Assert-Equals -Actual $Proof.queue_after -Expected "NONE" -Name "PROOF_QUEUE_AFTER"
  Assert-False -Actual $Proof.main_touched -Name "PROOF_MAIN_TOUCHED"
  Assert-Equals -Actual $Proof.source_branch -Expected $ExpectedBranch -Name "PROOF_SOURCE_BRANCH"
  Assert-Equals -Actual $Proof.next_allowed_step -Expected $NextAllowed -Name "PROOF_NEXT_ALLOWED_STEP"
}

if ($null -ne $Queue) {
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"
  Assert-Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "TASK_QUEUE_ACTIVE_TASK_ID"
}

if ($Ok -eq $true) {
  Write-Output "PHASE142_BUILDER_NEXT_GAP_SELECTOR_OBSERVABLE_LIFE_LOOP_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE142_BUILDER_NEXT_GAP_SELECTOR_OBSERVABLE_LIFE_LOOP_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE142 validation failed."
}
