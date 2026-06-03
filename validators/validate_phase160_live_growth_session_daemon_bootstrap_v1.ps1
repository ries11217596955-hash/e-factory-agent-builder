param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160ValidatorFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160ValidatorRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160ValidatorFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160ValidatorPath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase160ValidatorJson {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase160ValidatorText {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160_VALIDATE_MISSING_TEXT=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw
}

function Read-Phase160ValidatorJsonLines {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160_VALIDATE_MISSING_JSONL=$Path"
  }
  return @(Get-Content -LiteralPath $fullPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { ConvertFrom-Json $_ })
}

function Assert-Phase160ValidatorEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160ValidatorTrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160ValidatorFalse {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160ValidatorAtLeast {
  param([object]$Actual, [int]$Minimum, [string]$Name)
  if ([int]$Actual -lt $Minimum) {
    throw "PHASE160_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase160ValidatorContains {
  param([object[]]$Values, [string]$Expected, [string]$Name)
  if (-not (@($Values) -contains $Expected)) {
    throw "PHASE160_VALIDATE_EXPECTED_VALUE_MISSING=$Name expected=$Expected"
  }
}

function Assert-Phase160ValidatorFlagsFalse {
  param([object]$Artifact, [string[]]$Flags, [string]$Name)
  foreach ($flag in $Flags) {
    Assert-Phase160ValidatorFalse -Actual $Artifact.$flag -Name "${Name}:$flag"
  }
}

function Get-Phase160ValidatorStatusPath {
  param([string]$StatusLine)
  if ($StatusLine -match '^.. (.+)$') {
    return ($Matches[1] -replace '\\', '/')
  }
  return ($StatusLine -replace '\\', '/')
}

function Get-Phase160ValidatorRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160_VALIDATE_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Assert-Phase160ProofFields {
  param([object]$Artifact, [string]$Name, [string]$RepoRoot, [string]$NextAllowedStep)

  Assert-Phase160ValidatorEquals -Actual $Artifact.status -Expected "PASS" -Name "${Name}:status"
  Assert-Phase160ValidatorEquals -Actual $Artifact.step_id -Expected "PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_V1" -Name "${Name}:step_id"
  Assert-Phase160ValidatorEquals -Actual $Artifact.run_id -Expected "PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_001" -Name "${Name}:run_id"
  Assert-Phase160ValidatorEquals -Actual $Artifact.resolved_repo_root -Expected $RepoRoot -Name "${Name}:resolved_repo_root"
  foreach ($flag in @(
    "phase159_verified",
    "live_daemon_entrypoint_created",
    "observer_entrypoint_created",
    "two_terminal_model_prepared",
    "builder_daemon_smoke_started",
    "observer_smoke_started",
    "duration_based_session",
    "heartbeat_proven",
    "heartbeat_count_at_least_3",
    "event_log_created",
    "observer_log_created",
    "observer_detected_builder_alive",
    "teacher_inbox_supported",
    "teacher_outbox_supported",
    "blocker_queue_supported",
    "accepted_interventions_supported",
    "rejected_interventions_supported",
    "stop_flag_supported",
    "daemon_can_run_until_stop_flag",
    "live_daemon_bootstrap_proven",
    "live_session_safe_stop"
  )) {
    Assert-Phase160ValidatorTrue -Actual $Artifact.$flag -Name "${Name}:$flag"
  }
  Assert-Phase160ValidatorFalse -Actual $Artifact.fixed_tick_batch_mode -Name "${Name}:fixed_tick_batch_mode"
  Assert-Phase160ValidatorFlagsFalse -Artifact $Artifact -Flags @("accepted_state_mutated", "accepted_memory_mutated", "accepted_self_model_mutated", "capability_shelf_mutated", "body_pack_mutated", "self_growth_runtime_mutated", "external_fetch_performed", "dependency_install_performed", "arbitrary_code_execution_used", "external_agents_created", "codex_needed_for_next_step") -Name $Name
  Assert-Phase160ValidatorEquals -Actual $Artifact.queue_after -Expected "NONE" -Name "${Name}:queue_after"
  Assert-Phase160ValidatorEquals -Actual $Artifact.next_allowed_step -Expected $NextAllowedStep -Name "${Name}:next_allowed_step"
}

$Pushed = $false

try {
  $RepoRootParameter = $RepoRoot
  $RepoRoot = Resolve-Phase160ValidatorRepoRoot
  Push-Location $RepoRoot
  $Pushed = $true
  Write-Host "PHASE160_VALIDATE_RESOLVED_REPO_ROOT=$RepoRoot"
  if ($RepoRootParameter -ne "." -and (Normalize-Phase160ValidatorFullPath -Path $RepoRootParameter) -ne $RepoRoot) {
    Write-Host "PHASE160_VALIDATE_REPO_ROOT_PARAMETER_IGNORED=$RepoRootParameter"
  }

  $StepId = "PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_V1"
  $RunId = "PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_001"
  $NextAllowedStep = "PHASE160_LIVE_GROWTH_SESSION_READY_FOR_OWNER_SUPERVISED_RUN_V1"
  $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
  $RuntimeRoot = "runtime_sessions/live_growth/$RunId"
  $RouteAlignmentPath = "route_change_requests/PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_ALIGNMENT_REQUEST.md"
  $PostCommitRepairRequestPath = "route_change_requests/PHASE160_POST_COMMIT_RUNNABILITY_REPAIR_REQUEST.md"
  $BootstrapModulePath = "modules/invoke_builder_live_growth_session_daemon_bootstrap_001.ps1"
  $DaemonModulePath = "modules/start_builder_live_growth_daemon_001.ps1"
  $ObserverModulePath = "modules/watch_builder_live_growth_session_observer_001.ps1"
  $ValidatorPath = "validators/validate_phase160_live_growth_session_daemon_bootstrap_v1.ps1"
  $Phase159ProofPath = "proofs/self_development/PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1.json"
  $Phase159ResultPath = "self_control/BUILDER_NEWBORN_REFLEX_CORE_AND_LIVE_SESSION_PREP_RESULT.json"
  $Phase159LiveSkeletonPath = "runtime_sessions/newborn_reflex/PHASE159_NEWBORN_REFLEX_CORE_AND_LIVE_SESSION_PREP_001/live_session_skeleton.json"
  $Phase159TeacherContractPath = "runtime_sessions/newborn_reflex/PHASE159_NEWBORN_REFLEX_CORE_AND_LIVE_SESSION_PREP_001/teacher_channel_contract.json"
  $Phase159CapabilityInventoryPath = "runtime_sessions/newborn_reflex/PHASE159_NEWBORN_REFLEX_CORE_AND_LIVE_SESSION_PREP_001/capability_inventory.json"
  $QueuePath = "TASK_QUEUE.json"
  $ResultPath = "self_control/BUILDER_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_RESULT.json"
  $ReportPath = "reports/self_development/PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_V1_REPORT.json"
  $ProofPath = "proofs/self_development/PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_V1.json"

  $SessionBootPath = "$RuntimeRoot/session_boot.json"
  $RepoIdentityCheckPath = "$RuntimeRoot/repo_identity_check.json"
  $Phase159ReadinessReadPath = "$RuntimeRoot/phase159_readiness_read.json"
  $LiveSessionContractPath = "$RuntimeRoot/live_session_contract.json"
  $DaemonStartCommandPath = "$RuntimeRoot/daemon_start_command.json"
  $ObserverStartCommandPath = "$RuntimeRoot/observer_start_command.json"
  $BuilderDaemonRuntimeConfigPath = "$RuntimeRoot/builder_daemon_runtime_config.json"
  $ObserverRuntimeConfigPath = "$RuntimeRoot/observer_runtime_config.json"
  $HeartbeatPath = "$RuntimeRoot/heartbeat.json"
  $CurrentStatePath = "$RuntimeRoot/current_state.json"
  $EventLogPath = "$RuntimeRoot/event_log.jsonl"
  $ObserverLogPath = "$RuntimeRoot/observer_log.jsonl"
  $ObserverSummaryPath = "$RuntimeRoot/observer_summary.json"
  $StopPolicyPath = "$RuntimeRoot/stop_policy.json"
  $StopFlagSamplePath = "$RuntimeRoot/stop.flag.sample.json"
  $TeacherChannelContractPath = "$RuntimeRoot/teacher_channel_contract.json"
  $TeacherInboxReadmePath = "$RuntimeRoot/teacher_inbox/README.json"
  $TeacherOutboxReadmePath = "$RuntimeRoot/teacher_outbox/README.json"
  $BlockerQueueReadmePath = "$RuntimeRoot/blocker_queue/README.json"
  $AcceptedInterventionsReadmePath = "$RuntimeRoot/accepted_interventions/README.json"
  $RejectedInterventionsReadmePath = "$RuntimeRoot/rejected_interventions/README.json"
  $Tick001Path = "$RuntimeRoot/tick_records/tick_0001.json"
  $Tick002Path = "$RuntimeRoot/tick_records/tick_0002.json"
  $Tick003Path = "$RuntimeRoot/tick_records/tick_0003.json"
  $SmokeRunResultPath = "$RuntimeRoot/smoke_run_result.json"
  $BootstrapSummaryPath = "$RuntimeRoot/live_daemon_bootstrap_summary.json"

  $RuntimeOutputs = @(
    $SessionBootPath,
    $RepoIdentityCheckPath,
    $Phase159ReadinessReadPath,
    $LiveSessionContractPath,
    $DaemonStartCommandPath,
    $ObserverStartCommandPath,
    $BuilderDaemonRuntimeConfigPath,
    $ObserverRuntimeConfigPath,
    $HeartbeatPath,
    $CurrentStatePath,
    $EventLogPath,
    $ObserverLogPath,
    $ObserverSummaryPath,
    $StopPolicyPath,
    $StopFlagSamplePath,
    $TeacherChannelContractPath,
    $TeacherInboxReadmePath,
    $TeacherOutboxReadmePath,
    $BlockerQueueReadmePath,
    $AcceptedInterventionsReadmePath,
    $RejectedInterventionsReadmePath,
    $Tick001Path,
    $Tick002Path,
    $Tick003Path,
    $SmokeRunResultPath,
    $BootstrapSummaryPath,
    $ResultPath,
    $ReportPath,
    $ProofPath
  )
  $AllowedExact = @($RouteAlignmentPath, $PostCommitRepairRequestPath, $BootstrapModulePath, $DaemonModulePath, $ObserverModulePath, $ValidatorPath) + $RuntimeOutputs

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  Assert-Phase160ValidatorEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160ValidatorRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160ValidatorEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"
  $ExpectedHeadSource = "CURRENT_SYNCED_REPO_HEAD"
  $GitTopLevel = Normalize-Phase160ValidatorFullPath -Path (git rev-parse --show-toplevel).Trim()
  Assert-Phase160ValidatorEquals -Actual $GitTopLevel -Expected $RepoRoot -Name "git_top_level"

  $RequiredPaths = @($RouteAlignmentPath, $BootstrapModulePath, $DaemonModulePath, $ObserverModulePath, $ValidatorPath, $Phase159ProofPath, $Phase159ResultPath, $Phase159LiveSkeletonPath, $Phase159TeacherContractPath, $Phase159CapabilityInventoryPath, $QueuePath) + $RuntimeOutputs
  foreach ($requiredPath in $RequiredPaths) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE160_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $StatusLines = @(git status --short --untracked-files=all)
  foreach ($line in $StatusLines) {
    $path = Get-Phase160ValidatorStatusPath -StatusLine $line
    if ($path -match "^runtime_sessions/live_growth/PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_001/tick_records/tick_[0-9]{4}\.json$") {
      continue
    }
    if (-not ($AllowedExact -contains $path)) {
      throw "PHASE160_VALIDATE_CHANGE_OUTSIDE_ALLOWED_SCOPE=$line"
    }
  }

  $ProtectedStatus = @(git status --short --untracked-files=all -- `
    TASK_QUEUE.json `
    GENESIS_STATE.json `
    CAPABILITY_ROADMAP.json `
    packs/registry.json `
    orchestrator/run.ps1 `
    capability_shelf `
    living_learning_environment/body `
    living_learning_environment/self_growth_runtime `
    generated_agents `
    applied_agents `
    .github/workflows `
    route_locks `
    proofs/self_development/PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1.json `
    proofs/self_development/PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1.json `
    proofs/self_development/PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1.json `
    proofs/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1.json `
    proofs/self_development/PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1.json `
    proofs/self_development/PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1.json `
    proofs/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1.json `
    proofs/self_development/PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1.json `
    proofs/self_development/PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1.json `
    proofs/self_development/PHASE151_BUILDER_SELF_BUILD_PROGRAM_ADMISSION_GATE_V1.json `
    proofs/self_development/PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1.json `
    proofs/self_development/PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1.json `
    proofs/self_development/PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1.json `
    proofs/self_development/PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1.json `
    proofs/self_development/PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1.json `
    proofs/self_development/PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1.json `
    proofs/self_development/PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1.json `
    $Phase159ProofPath `
    reports/self_development/PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1_REPORT.json `
    $Phase159ResultPath `
    runtime_sessions/newborn_reflex/PHASE159_NEWBORN_REFLEX_CORE_AND_LIVE_SESSION_PREP_001 2>$null)
  if ($ProtectedStatus.Count -gt 0) {
    throw "PHASE160_VALIDATE_PROTECTED_SCOPE_CHANGED=$($ProtectedStatus -join '; ')"
  }

  $Phase159Proof = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $Phase159ProofPath
  Assert-Phase160ValidatorEquals -Actual $Phase159Proof.status -Expected "PASS" -Name "phase159_status"
  Assert-Phase160ValidatorEquals -Actual $Phase159Proof.next_allowed_step -Expected $StepId -Name "phase159_next_allowed_step"
  Assert-Phase160ValidatorTrue -Actual $Phase159Proof.daemon_mode_prepared -Name "phase159_daemon_mode_prepared"
  Assert-Phase160ValidatorFalse -Actual $Phase159Proof.live_daemon_started -Name "phase159_live_daemon_started"

  $RepoIdentity = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $RepoIdentityCheckPath
  Assert-Phase160ValidatorEquals -Actual $RepoIdentity.resolved_repo_root -Expected $RepoRoot -Name "repo_identity_resolved_repo_root"
  Assert-Phase160ValidatorEquals -Actual $RepoIdentity.git_top_level -Expected $GitTopLevel -Name "repo_identity_git_top_level"
  if (-not [string]::IsNullOrWhiteSpace([string]$RepoIdentity.local_head) -and -not [string]::IsNullOrWhiteSpace([string]$RepoIdentity.remote_head)) {
    Assert-Phase160ValidatorEquals -Actual $RepoIdentity.local_head -Expected $RepoIdentity.remote_head -Name "repo_identity_recorded_heads_synced"
  }
  if ($RepoIdentity.PSObject.Properties.Name -contains "expected_head_source") {
    Assert-Phase160ValidatorEquals -Actual $RepoIdentity.expected_head_source -Expected $ExpectedHeadSource -Name "repo_identity_expected_head_source"
  }
  Assert-Phase160ValidatorTrue -Actual $RepoIdentity.required_markers_present -Name "repo_identity_markers"

  $LiveContract = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $LiveSessionContractPath
  Assert-Phase160ValidatorTrue -Actual $LiveContract.terminal_1_builder_loop -Name "live_contract_terminal_1"
  Assert-Phase160ValidatorTrue -Actual $LiveContract.terminal_2_observer_loop -Name "live_contract_terminal_2"
  Assert-Phase160ValidatorTrue -Actual $LiveContract.duration_based_session -Name "live_contract_duration_based"
  Assert-Phase160ValidatorFalse -Actual $LiveContract.fixed_tick_batch_mode -Name "live_contract_fixed_tick_batch"
  Assert-Phase160ValidatorTrue -Actual $LiveContract.daemon_can_run_until_stop_flag -Name "live_contract_stop_flag_run"

  $DaemonModuleText = Read-Phase160ValidatorText -RepoRoot $RepoRoot -Path $DaemonModulePath
  $ObserverModuleText = Read-Phase160ValidatorText -RepoRoot $RepoRoot -Path $ObserverModulePath
  $BootstrapModuleText = Read-Phase160ValidatorText -RepoRoot $RepoRoot -Path $BootstrapModulePath
  foreach ($scriptText in @($DaemonModuleText, $ObserverModuleText, $BootstrapModuleText)) {
    if (-not $scriptText.Contains("PSScriptRoot")) {
      throw "PHASE160_VALIDATE_SCRIPT_ROOT_RULE_MISSING"
    }
    if ($scriptText.Contains("C:\Users\Azerbaijan\Downloads")) {
      throw "PHASE160_VALIDATE_DOWNLOADS_PATH_FORBIDDEN"
    }
  }
  if (-not $DaemonModuleText.Contains("while ((Get-Date) -lt `$EndTime)")) {
    throw "PHASE160_VALIDATE_DAEMON_NOT_DURATION_LOOP"
  }
  if (-not $DaemonModuleText.Contains("stop.flag")) {
    throw "PHASE160_VALIDATE_DAEMON_STOP_FLAG_SUPPORT_MISSING"
  }
  if (-not $BootstrapModuleText.Contains("Start-Job")) {
    throw "PHASE160_VALIDATE_BOOTSTRAP_JOBS_MISSING"
  }

  $Heartbeat = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $HeartbeatPath
  Assert-Phase160ValidatorAtLeast -Actual $Heartbeat.heartbeat_count -Minimum 3 -Name "heartbeat_count"
  Assert-Phase160ValidatorTrue -Actual $Heartbeat.duration_based_session -Name "heartbeat_duration_based"
  Assert-Phase160ValidatorFalse -Actual $Heartbeat.fixed_tick_batch_mode -Name "heartbeat_fixed_tick_batch"

  $CurrentState = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $CurrentStatePath
  Assert-Phase160ValidatorEquals -Actual $CurrentState.status -Expected "STOPPED" -Name "current_state_status"
  Assert-Phase160ValidatorTrue -Actual $CurrentState.live_session_safe_stop -Name "current_state_safe_stop"
  Assert-Phase160ValidatorEquals -Actual $CurrentState.stop_reason -Expected "duration_limit" -Name "current_state_stop_reason"

  $EventLines = Read-Phase160ValidatorJsonLines -RepoRoot $RepoRoot -Path $EventLogPath
  $ObserverLines = Read-Phase160ValidatorJsonLines -RepoRoot $RepoRoot -Path $ObserverLogPath
  Assert-Phase160ValidatorAtLeast -Actual $EventLines.Count -Minimum 5 -Name "event_log_line_count"
  Assert-Phase160ValidatorAtLeast -Actual $ObserverLines.Count -Minimum 3 -Name "observer_log_line_count"

  $Tick1 = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $Tick001Path
  $Tick2 = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $Tick002Path
  $Tick3 = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $Tick003Path
  foreach ($tick in @($Tick1, $Tick2, $Tick3)) {
    Assert-Phase160ValidatorEquals -Actual $tick.status -Expected "PASS" -Name "tick_status"
    Assert-Phase160ValidatorTrue -Actual $tick.heartbeat_written -Name "tick_heartbeat_written"
    Assert-Phase160ValidatorTrue -Actual $tick.duration_based_session -Name "tick_duration_based"
    Assert-Phase160ValidatorFalse -Actual $tick.fixed_tick_batch_mode -Name "tick_fixed_tick_batch"
  }

  $ObserverSummary = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $ObserverSummaryPath
  Assert-Phase160ValidatorTrue -Actual $ObserverSummary.observer_completed -Name "observer_completed"
  Assert-Phase160ValidatorTrue -Actual $ObserverSummary.observer_detected_builder_alive -Name "observer_detected_builder_alive"
  Assert-Phase160ValidatorTrue -Actual $ObserverSummary.event_log_observed -Name "observer_event_log_observed"
  Assert-Phase160ValidatorFalse -Actual $ObserverSummary.code_execution_requested -Name "observer_code_execution_requested"
  Assert-Phase160ValidatorFalse -Actual $ObserverSummary.accepted_state_mutated -Name "observer_accepted_state_mutated"

  $Smoke = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $SmokeRunResultPath
  Assert-Phase160ValidatorTrue -Actual $Smoke.builder_daemon_smoke_started -Name "smoke_builder_started"
  Assert-Phase160ValidatorTrue -Actual $Smoke.observer_smoke_started -Name "smoke_observer_started"
  Assert-Phase160ValidatorTrue -Actual $Smoke.builder_job_completed -Name "smoke_builder_completed"
  Assert-Phase160ValidatorTrue -Actual $Smoke.observer_job_completed -Name "smoke_observer_completed"
  Assert-Phase160ValidatorFalse -Actual $Smoke.jobs_forcibly_stopped -Name "smoke_jobs_forcibly_stopped"
  Assert-Phase160ValidatorFalse -Actual $Smoke.uncontrolled_process_left_running -Name "smoke_uncontrolled_process"
  Assert-Phase160ValidatorTrue -Actual $Smoke.duration_based_session -Name "smoke_duration_based"
  Assert-Phase160ValidatorFalse -Actual $Smoke.fixed_tick_batch_mode -Name "smoke_fixed_tick_batch"
  Assert-Phase160ValidatorTrue -Actual $Smoke.heartbeat_count_at_least_3 -Name "smoke_heartbeat_count_at_least_3"
  Assert-Phase160ValidatorTrue -Actual $Smoke.observer_detected_builder_alive -Name "smoke_observer_alive"
  Assert-Phase160ValidatorTrue -Actual $Smoke.live_session_safe_stop -Name "smoke_safe_stop"

  foreach ($channelPath in @($TeacherInboxReadmePath, $TeacherOutboxReadmePath, $BlockerQueueReadmePath, $AcceptedInterventionsReadmePath, $RejectedInterventionsReadmePath)) {
    $Channel = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $channelPath
    Assert-Phase160ValidatorEquals -Actual $Channel.status -Expected "PASS" -Name "channel_status"
    Assert-Phase160ValidatorTrue -Actual $Channel.file_based -Name "channel_file_based"
    Assert-Phase160ValidatorFalse -Actual $Channel.accepted_state_mutated -Name "channel_accepted_state_mutated"
  }
  $StopPolicy = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $StopPolicyPath
  Assert-Phase160ValidatorTrue -Actual $StopPolicy.stop_flag_supported -Name "stop_policy_stop_flag"
  Assert-Phase160ValidatorTrue -Actual $StopPolicy.duration_limit_supported -Name "stop_policy_duration"
  Assert-Phase160ValidatorFalse -Actual $StopPolicy.uncontrolled_infinite_process_allowed -Name "stop_policy_uncontrolled"

  $Result = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath
  $Summary = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $BootstrapSummaryPath
  Assert-Phase160ProofFields -Artifact $Result -Name "result" -RepoRoot $RepoRoot -NextAllowedStep $NextAllowedStep
  Assert-Phase160ProofFields -Artifact $Proof -Name "proof" -RepoRoot $RepoRoot -NextAllowedStep $NextAllowedStep
  Assert-Phase160ProofFields -Artifact $Summary -Name "summary" -RepoRoot $RepoRoot -NextAllowedStep $NextAllowedStep

  Assert-Phase160ValidatorEquals -Actual $Report.status -Expected "PASS" -Name "report_status"
  Assert-Phase160ValidatorEquals -Actual $Report.repo_identity_gate_result -Expected "PASS" -Name "report_repo_identity"
  Assert-Phase160ValidatorEquals -Actual $Report.root_cause -Expected "PHASE160 live daemon entrypoint absent" -Name "report_root_cause"
  Assert-Phase160ValidatorEquals -Actual $Report.daemon_module_path -Expected $DaemonModulePath -Name "report_daemon_path"
  Assert-Phase160ValidatorEquals -Actual $Report.observer_module_path -Expected $ObserverModulePath -Name "report_observer_path"
  Assert-Phase160ValidatorEquals -Actual $Report.bootstrap_module_path -Expected $BootstrapModulePath -Name "report_bootstrap_path"
  Assert-Phase160ValidatorEquals -Actual $Report.validator_path -Expected $ValidatorPath -Name "report_validator_path"
  Assert-Phase160ValidatorEquals -Actual $Report.exact_smoke_run_command -Expected ".\modules\invoke_builder_live_growth_session_daemon_bootstrap_001.ps1" -Name "report_smoke_command"
  Assert-Phase160ValidatorEquals -Actual $Report.exact_validator_command -Expected ".\validators\validate_phase160_live_growth_session_daemon_bootstrap_v1.ps1 -RepoRoot ." -Name "report_validator_command"
  foreach ($runtimePath in $RuntimeOutputs) {
    Assert-Phase160ValidatorContains -Values @($Report.runtime_outputs_created_by_module) -Expected $runtimePath -Name "report_runtime_outputs"
    Assert-Phase160ValidatorContains -Values @($Proof.runtime_outputs_created_by_module) -Expected $runtimePath -Name "proof_runtime_outputs"
  }

  $Queue = Read-Phase160ValidatorJson -RepoRoot $RepoRoot -Path $QueuePath
  Assert-Phase160ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  Write-Host "PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_VALIDATE_RESULT=PASS"
  Write-Host "RESOLVED_REPO_ROOT=$RepoRoot"
  Write-Host "LOCAL_HEAD=$Head"
  Write-Host "REMOTE_HEAD=$RemoteHead"
  Write-Host "EXPECTED_HEAD_SOURCE=$ExpectedHeadSource"
  Write-Host "PHASE159_VERIFIED=True"
  Write-Host "LIVE_DAEMON_ENTRYPOINT_CREATED=True"
  Write-Host "OBSERVER_ENTRYPOINT_CREATED=True"
  Write-Host "TWO_TERMINAL_MODEL_PREPARED=True"
  Write-Host "DURATION_BASED_SESSION=True"
  Write-Host "FIXED_TICK_BATCH_MODE=False"
  Write-Host "HEARTBEAT_COUNT=$($Heartbeat.heartbeat_count)"
  Write-Host "HEARTBEAT_COUNT_AT_LEAST_3=True"
  Write-Host "OBSERVER_DETECTED_BUILDER_ALIVE=True"
  Write-Host "LIVE_DAEMON_BOOTSTRAP_PROVEN=True"
  Write-Host "LIVE_SESSION_SAFE_STOP=True"
  Write-Host "QUEUE_AFTER=NONE"
  Write-Host "CODEX_NEEDED_FOR_NEXT_STEP=False"
  Write-Host "NEXT_ALLOWED_STEP=PHASE160_LIVE_GROWTH_SESSION_READY_FOR_OWNER_SUPERVISED_RUN_V1"
} catch {
  Write-Host "PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE160_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
