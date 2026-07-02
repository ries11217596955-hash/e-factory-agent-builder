param(
  [string]$RunId = "PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_001",
  [int]$SmokeDurationSeconds = 35,
  [int]$TickIntervalSeconds = 10,
  [int]$ObserverPollIntervalSeconds = 5,
  [string]$ExpectedHead = ""
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160FullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160ScriptRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160FullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160Path {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Write-Phase160JsonFile {
  param([string]$RepoRoot, [string]$Path, [object]$Object, [int]$Depth = 100)
  $fullPath = Resolve-Phase160Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase160TextFile {
  param([string]$RepoRoot, [string]$Path, [string]$Content)
  $fullPath = Resolve-Phase160Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Read-Phase160JsonRequired {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase160JsonLines {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160_MISSING_JSONL=$Path"
  }
  return @(Get-Content -LiteralPath $fullPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { ConvertFrom-Json $_ })
}

function Assert-Phase160Equals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160True {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160False {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase160RemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Clear-Phase160RuntimeRoot {
  param([string]$RepoRoot, [string]$RuntimeRoot)
  $runtimeRootFull = Normalize-Phase160FullPath -Path (Resolve-Phase160Path -RepoRoot $RepoRoot -Path $RuntimeRoot)
  $allowedRoot = Normalize-Phase160FullPath -Path (Resolve-Phase160Path -RepoRoot $RepoRoot -Path "runtime_sessions/live_growth")
  if (-not $runtimeRootFull.StartsWith($allowedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160_RUNTIME_ROOT_OUTSIDE_ALLOWED_SCOPE=$runtimeRootFull"
  }
  if ($runtimeRootFull -eq $allowedRoot -or $runtimeRootFull -eq (Normalize-Phase160FullPath -Path $RepoRoot)) {
    throw "PHASE160_RUNTIME_ROOT_TOO_BROAD=$runtimeRootFull"
  }
  if (Test-Path -LiteralPath $runtimeRootFull) {
    Remove-Item -LiteralPath $runtimeRootFull -Recurse -Force
  }
}

function Wait-Phase160JobRequired {
  param([System.Management.Automation.Job]$Job, [int]$TimeoutSeconds, [string]$Name)
  $completed = Wait-Job -Job $Job -Timeout $TimeoutSeconds
  if ($null -eq $completed) {
    Stop-Job -Job $Job -ErrorAction SilentlyContinue
    throw "PHASE160_JOB_TIMEOUT=$Name"
  }
  if ($Job.State -ne "Completed") {
    $jobOutput = Receive-Job -Job $Job -ErrorAction SilentlyContinue
    throw "PHASE160_JOB_NOT_COMPLETED=$Name state=$($Job.State) output=$($jobOutput -join ' ')"
  }
  return @(Receive-Job -Job $Job -ErrorAction Stop)
}

function Invoke-BuilderLiveGrowthSessionDaemonBootstrap001 {
  param(
    [string]$RunId = "PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_001",
    [int]$SmokeDurationSeconds = 35,
    [int]$TickIntervalSeconds = 10,
    [int]$ObserverPollIntervalSeconds = 5,
    [string]$ExpectedHead = ""
  )

  $RepoRoot = Resolve-Phase160ScriptRepoRoot
  $Pushed = $false
  Push-Location $RepoRoot
  $Pushed = $true
  Write-Host "PHASE160_RESOLVED_REPO_ROOT=$RepoRoot"

  try {
    $StepId = "PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_V1"
    $NextAllowedStep = "PHASE160_LIVE_GROWTH_SESSION_READY_FOR_OWNER_SUPERVISED_RUN_V1"
    $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
    $RuntimeRoot = "runtime_sessions/live_growth/$RunId"
    $RouteAlignmentPath = "route_change_requests/PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_ALIGNMENT_REQUEST.md"
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

    foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase160Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    foreach ($requiredInput in @($RouteAlignmentPath, $BootstrapModulePath, $DaemonModulePath, $ObserverModulePath, $ValidatorPath, $Phase159ProofPath, $Phase159ResultPath, $Phase159LiveSkeletonPath, $Phase159TeacherContractPath, $Phase159CapabilityInventoryPath, $QueuePath)) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase160Path -RepoRoot $RepoRoot -Path $requiredInput))) {
        throw "PHASE160_MISSING_REQUIRED_INPUT=$requiredInput"
      }
    }

    $Branch = (git branch --show-current).Trim()
    Assert-Phase160Equals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
    $Head = (git rev-parse --short HEAD).Trim()
    $RemoteHead = Get-Phase160RemoteHead -ExpectedBranch $ExpectedBranch
    if ([string]::IsNullOrWhiteSpace($ExpectedHead)) {
      Assert-Phase160Equals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"
      $ExpectedHeadSource = "CURRENT_SYNCED_REPO_HEAD"
    } else {
      Assert-Phase160Equals -Actual $Head -Expected $ExpectedHead -Name "current_head"
      Assert-Phase160Equals -Actual $RemoteHead -Expected $ExpectedHead -Name "remote_head"
      $ExpectedHeadSource = "EXPLICIT_PARAMETER"
    }
    $GitTopLevel = Normalize-Phase160FullPath -Path (git rev-parse --show-toplevel).Trim()
    Assert-Phase160Equals -Actual $GitTopLevel -Expected $RepoRoot -Name "git_top_level"

    $Queue = Read-Phase160JsonRequired -RepoRoot $RepoRoot -Path $QueuePath
    Assert-Phase160Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $Phase159Proof = Read-Phase160JsonRequired -RepoRoot $RepoRoot -Path $Phase159ProofPath
    $Phase159Result = Read-Phase160JsonRequired -RepoRoot $RepoRoot -Path $Phase159ResultPath
    $Phase159Skeleton = Read-Phase160JsonRequired -RepoRoot $RepoRoot -Path $Phase159LiveSkeletonPath
    $Phase159TeacherContract = Read-Phase160JsonRequired -RepoRoot $RepoRoot -Path $Phase159TeacherContractPath
    $Phase159CapabilityInventory = Read-Phase160JsonRequired -RepoRoot $RepoRoot -Path $Phase159CapabilityInventoryPath

    Assert-Phase160Equals -Actual $Phase159Proof.status -Expected "PASS" -Name "phase159_status"
    Assert-Phase160Equals -Actual $Phase159Proof.next_allowed_step -Expected $StepId -Name "phase159_next_allowed_step"
    Assert-Phase160True -Actual $Phase159Proof.two_step_newborn_reflex_proven -Name "phase159_two_step"
    Assert-Phase160True -Actual $Phase159Proof.teacher_channels_prepared -Name "phase159_teacher_channels"
    Assert-Phase160True -Actual $Phase159Proof.live_session_skeleton_created -Name "phase159_live_skeleton"
    Assert-Phase160True -Actual $Phase159Proof.daemon_mode_prepared -Name "phase159_daemon_mode_prepared"
    Assert-Phase160False -Actual $Phase159Proof.live_daemon_started -Name "phase159_live_daemon_started"
    Assert-Phase160True -Actual $Phase159Result.live_session_skeleton_created -Name "phase159_result_live_skeleton"
    Assert-Phase160True -Actual $Phase159Skeleton.daemon_mode_prepared -Name "phase159_skeleton_daemon_mode"
    Assert-Phase160Equals -Actual $Phase159TeacherContract.channel_type -Expected "file_based" -Name "phase159_teacher_contract_channel_type"
    Assert-Phase160True -Actual $Phase159CapabilityInventory.capability_inventory_created -Name "phase159_capability_inventory"

    Clear-Phase160RuntimeRoot -RepoRoot $RepoRoot -RuntimeRoot $RuntimeRoot
    foreach ($directory in @(
      $RuntimeRoot,
      "$RuntimeRoot/teacher_inbox",
      "$RuntimeRoot/teacher_outbox",
      "$RuntimeRoot/blocker_queue",
      "$RuntimeRoot/accepted_interventions",
      "$RuntimeRoot/rejected_interventions",
      "$RuntimeRoot/tick_records"
    )) {
      New-Item -ItemType Directory -Force -Path (Resolve-Phase160Path -RepoRoot $RepoRoot -Path $directory) | Out-Null
    }

    Write-Phase160TextFile -RepoRoot $RepoRoot -Path $EventLogPath -Content ""
    Write-Phase160TextFile -RepoRoot $RepoRoot -Path $ObserverLogPath -Content ""

    $RepoIdentity = [ordered]@{
      status = "PASS"
      check_id = "PHASE160_REPO_IDENTITY_CHECK"
      step_id = $StepId
      run_id = $RunId
      resolved_repo_root = $RepoRoot
      repo_root_resolution_rule = "script_file_location_parent_of_modules_directory"
      git_top_level = $GitTopLevel
      branch = $Branch
      local_head = $Head
      remote_head = $RemoteHead
      expected_head_source = $ExpectedHeadSource
      required_markers_present = $true
    }
    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $RepoIdentityCheckPath -Object $RepoIdentity

    $SessionBoot = [ordered]@{
      status = "PASS"
      boot_id = "PHASE160_SESSION_BOOT"
      line = "AGENT_BUILDER_SELF_DEVELOPMENT"
      mode = "SELF_BUILD"
      step_id = $StepId
      run_id = $RunId
      root_cause = "PHASE160 live daemon entrypoint absent"
      repo_identity_gate_result = "PASS"
      resolved_repo_root = $RepoRoot
      branch = $Branch
      local_head = $Head
      remote_head = $RemoteHead
      expected_head_source = $ExpectedHeadSource
      runtime_root = $RuntimeRoot
      queue_active_task_id = $Queue.active_task_id
      phase159_verified = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $SessionBootPath -Object $SessionBoot

    $Phase159Readiness = [ordered]@{
      status = "PASS"
      read_id = "PHASE160_PHASE159_READINESS_READ"
      step_id = $StepId
      run_id = $RunId
      source_phase159_proof_path = $Phase159ProofPath
      source_phase159_result_path = $Phase159ResultPath
      phase159_verified = $true
      two_step_newborn_reflex_proven = $true
      teacher_channels_prepared = $true
      help_request_reflex_prepared = $true
      live_session_skeleton_created = $true
      daemon_mode_prepared = $true
      live_daemon_started = $false
      next_allowed_step_from_phase159 = $Phase159Proof.next_allowed_step
    }
    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $Phase159ReadinessReadPath -Object $Phase159Readiness

    $LiveSessionContract = [ordered]@{
      status = "PASS"
      contract_id = "PHASE160_LIVE_SESSION_CONTRACT"
      step_id = $StepId
      run_id = $RunId
      terminal_1_builder_loop = $true
      terminal_2_observer_loop = $true
      duration_based_session = $true
      fixed_tick_batch_mode = $false
      execution_scope = "sandbox_only"
      heartbeat_interval_seconds = $TickIntervalSeconds
      observer_poll_interval_seconds = $ObserverPollIntervalSeconds
      stop_flag_supported = $true
      teacher_inbox_supported = $true
      teacher_outbox_supported = $true
      blocker_queue_supported = $true
      accepted_interventions_supported = $true
      rejected_interventions_supported = $true
      daemon_can_run_until_stop_flag = $true
      smoke_duration_seconds = $SmokeDurationSeconds
    }
    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $LiveSessionContractPath -Object $LiveSessionContract

    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $DaemonStartCommandPath -Object ([ordered]@{
      status = "PASS"
      command_id = "PHASE160_DAEMON_START_COMMAND"
      command = ".\modules\start_builder_live_growth_daemon_001.ps1 -SessionRoot $RuntimeRoot -DurationSeconds $SmokeDurationSeconds -TickIntervalSeconds $TickIntervalSeconds"
      module_path = $DaemonModulePath
      session_root = $RuntimeRoot
      duration_based_session = $true
      fixed_tick_batch_mode = $false
    })
    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $ObserverStartCommandPath -Object ([ordered]@{
      status = "PASS"
      command_id = "PHASE160_OBSERVER_START_COMMAND"
      command = ".\modules\watch_builder_live_growth_session_observer_001.ps1 -SessionRoot $RuntimeRoot -DurationSeconds $SmokeDurationSeconds -PollIntervalSeconds $ObserverPollIntervalSeconds"
      module_path = $ObserverModulePath
      session_root = $RuntimeRoot
      duration_based_session = $true
    })
    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $BuilderDaemonRuntimeConfigPath -Object ([ordered]@{
      status = "PASS"
      config_id = "PHASE160_BUILDER_DAEMON_RUNTIME_CONFIG"
      session_root = $RuntimeRoot
      duration_seconds = $SmokeDurationSeconds
      tick_interval_seconds = $TickIntervalSeconds
      reads_teacher_outbox = $true
      writes_heartbeat = $true
      writes_event_log = $true
      writes_current_state = $true
      writes_tick_records = $true
      stop_flag_supported = $true
      duration_based_session = $true
      fixed_tick_batch_mode = $false
    })
    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $ObserverRuntimeConfigPath -Object ([ordered]@{
      status = "PASS"
      config_id = "PHASE160_OBSERVER_RUNTIME_CONFIG"
      session_root = $RuntimeRoot
      duration_seconds = $SmokeDurationSeconds
      poll_interval_seconds = $ObserverPollIntervalSeconds
      reads_heartbeat = $true
      reads_event_log = $true
      writes_observer_log = $true
      writes_observer_summary = $true
      intervention_request_supported = $true
      accepted_state_mutated = $false
    })

    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $StopPolicyPath -Object ([ordered]@{
      status = "PASS"
      policy_id = "PHASE160_STOP_POLICY"
      step_id = $StepId
      run_id = $RunId
      stop_flag_supported = $true
      stop_flag_path = "$RuntimeRoot/stop.flag"
      duration_limit_supported = $true
      smoke_duration_seconds = $SmokeDurationSeconds
      safe_stop_after_duration = $true
      daemon_can_run_until_stop_flag = $true
      uncontrolled_infinite_process_allowed = $false
    })
    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $StopFlagSamplePath -Object ([ordered]@{
      status = "SAMPLE"
      flag_id = "PHASE160_STOP_FLAG_SAMPLE"
      write_this_as = "$RuntimeRoot/stop.flag"
      requested_stop = $true
      reason = "owner_or_teacher_safe_stop"
      created_by = "teacher_or_owner"
    })
    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $TeacherChannelContractPath -Object ([ordered]@{
      status = "PASS"
      contract_id = "PHASE160_TEACHER_CHANNEL_CONTRACT"
      channel_type = "file_based"
      execution_scope = "sandbox_only"
      teacher_inbox_path = "$RuntimeRoot/teacher_inbox"
      teacher_outbox_path = "$RuntimeRoot/teacher_outbox"
      blocker_queue_path = "$RuntimeRoot/blocker_queue"
      accepted_interventions_path = "$RuntimeRoot/accepted_interventions"
      rejected_interventions_path = "$RuntimeRoot/rejected_interventions"
      required_outbox_fields = @("intervention_id", "message_type", "requested_action")
      allowed_message_types = @("teacher_instruction", "teacher_correction", "teacher_stop_request", "observer_suggestion")
    })

    foreach ($channelReadme in @(
      [ordered]@{ path = $TeacherInboxReadmePath; channel = "teacher_inbox"; purpose = "Observer and Builder suggestions for teacher review; suggestions only, no code execution." },
      [ordered]@{ path = $TeacherOutboxReadmePath; channel = "teacher_outbox"; purpose = "Teacher JSON interventions read by the Builder daemon during live session ticks." },
      [ordered]@{ path = $BlockerQueueReadmePath; channel = "blocker_queue"; purpose = "Sandbox-only blockers created when invalid interventions or stuck conditions appear." },
      [ordered]@{ path = $AcceptedInterventionsReadmePath; channel = "accepted_interventions"; purpose = "Valid teacher interventions recorded as accepted sandbox actions." },
      [ordered]@{ path = $RejectedInterventionsReadmePath; channel = "rejected_interventions"; purpose = "Invalid teacher interventions recorded with rejection reasons." }
    )) {
      Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $channelReadme.path -Object ([ordered]@{
        status = "PASS"
        channel = $channelReadme.channel
        step_id = $StepId
        run_id = $RunId
        purpose = $channelReadme.purpose
        file_based = $true
        execution_scope = "sandbox_only"
        accepted_state_mutated = $false
      })
    }

    $DaemonScriptFull = Resolve-Phase160Path -RepoRoot $RepoRoot -Path $DaemonModulePath
    $ObserverScriptFull = Resolve-Phase160Path -RepoRoot $RepoRoot -Path $ObserverModulePath

    $BuilderJob = Start-Job -Name "PHASE160_BUILDER_DAEMON_SMOKE" -ScriptBlock {
      param($ScriptPath, $SessionRoot, $DurationSeconds, $TickIntervalSeconds)
      & $ScriptPath -SessionRoot $SessionRoot -DurationSeconds $DurationSeconds -TickIntervalSeconds $TickIntervalSeconds
    } -ArgumentList $DaemonScriptFull, $RuntimeRoot, $SmokeDurationSeconds, $TickIntervalSeconds

    $ObserverJob = Start-Job -Name "PHASE160_OBSERVER_SMOKE" -ScriptBlock {
      param($ScriptPath, $SessionRoot, $DurationSeconds, $PollIntervalSeconds)
      & $ScriptPath -SessionRoot $SessionRoot -DurationSeconds $DurationSeconds -PollIntervalSeconds $PollIntervalSeconds
    } -ArgumentList $ObserverScriptFull, $RuntimeRoot, $SmokeDurationSeconds, $ObserverPollIntervalSeconds

    $BuilderJobOutput = Wait-Phase160JobRequired -Job $BuilderJob -TimeoutSeconds ($SmokeDurationSeconds + $TickIntervalSeconds + 30) -Name "builder_daemon"
    $ObserverJobOutput = Wait-Phase160JobRequired -Job $ObserverJob -TimeoutSeconds ($SmokeDurationSeconds + $ObserverPollIntervalSeconds + 30) -Name "observer"
    Remove-Job -Job $BuilderJob, $ObserverJob -Force -ErrorAction SilentlyContinue

    foreach ($requiredRuntime in @($HeartbeatPath, $CurrentStatePath, $EventLogPath, $ObserverLogPath, $ObserverSummaryPath, $Tick001Path, $Tick002Path, $Tick003Path)) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase160Path -RepoRoot $RepoRoot -Path $requiredRuntime))) {
        throw "PHASE160_MISSING_RUNTIME_OUTPUT=$requiredRuntime"
      }
    }

    $Heartbeat = Read-Phase160JsonRequired -RepoRoot $RepoRoot -Path $HeartbeatPath
    $ObserverSummary = Read-Phase160JsonRequired -RepoRoot $RepoRoot -Path $ObserverSummaryPath
    $EventLines = Read-Phase160JsonLines -RepoRoot $RepoRoot -Path $EventLogPath
    $ObserverLines = Read-Phase160JsonLines -RepoRoot $RepoRoot -Path $ObserverLogPath
    $TickFiles = @(Get-ChildItem -LiteralPath (Resolve-Phase160Path -RepoRoot $RepoRoot -Path "$RuntimeRoot/tick_records") -File -Filter "tick_*.json")
    $DynamicTickOutputPaths = @($TickFiles | Sort-Object Name | ForEach-Object { "$RuntimeRoot/tick_records/$($_.Name)" })
    $RuntimeOutputsCreated = @($RuntimeOutputs + ($DynamicTickOutputPaths | Where-Object { -not ($RuntimeOutputs -contains $_) }))
    $HeartbeatCount = [int]$Heartbeat.heartbeat_count
    $HeartbeatCountAtLeast3 = $HeartbeatCount -ge 3 -and $TickFiles.Count -ge 3
    Assert-Phase160True -Actual $HeartbeatCountAtLeast3 -Name "heartbeat_count_at_least_3"
    Assert-Phase160True -Actual $ObserverSummary.observer_detected_builder_alive -Name "observer_detected_builder_alive"

    $SmokeRunResult = [ordered]@{
      status = "PASS"
      result_id = "PHASE160_SMOKE_RUN_RESULT"
      step_id = $StepId
      run_id = $RunId
      builder_daemon_smoke_started = $true
      observer_smoke_started = $true
      builder_job_completed = $true
      observer_job_completed = $true
      jobs_forcibly_stopped = $false
      uncontrolled_process_left_running = $false
      duration_seconds = $SmokeDurationSeconds
      tick_interval_seconds = $TickIntervalSeconds
      observer_poll_interval_seconds = $ObserverPollIntervalSeconds
      duration_based_session = $true
      fixed_tick_batch_mode = $false
      heartbeat_count = $HeartbeatCount
      heartbeat_count_at_least_3 = $HeartbeatCountAtLeast3
      tick_record_count = $TickFiles.Count
      tick_record_paths = $DynamicTickOutputPaths
      event_log_line_count = $EventLines.Count
      observer_log_line_count = $ObserverLines.Count
      observer_detected_builder_alive = $ObserverSummary.observer_detected_builder_alive
      builder_job_output = $BuilderJobOutput
      observer_job_output = $ObserverJobOutput
      live_session_safe_stop = $true
    }
    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $SmokeRunResultPath -Object $SmokeRunResult

    $Common = [ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      resolved_repo_root = $RepoRoot
      phase159_verified = $true
      live_daemon_entrypoint_created = $true
      observer_entrypoint_created = $true
      two_terminal_model_prepared = $true
      builder_daemon_smoke_started = $true
      observer_smoke_started = $true
      duration_based_session = $true
      fixed_tick_batch_mode = $false
      heartbeat_proven = $true
      heartbeat_count_at_least_3 = $true
      heartbeat_count = $HeartbeatCount
      event_log_created = $true
      observer_log_created = $true
      observer_detected_builder_alive = $true
      teacher_inbox_supported = $true
      teacher_outbox_supported = $true
      blocker_queue_supported = $true
      accepted_interventions_supported = $true
      rejected_interventions_supported = $true
      stop_flag_supported = $true
      daemon_can_run_until_stop_flag = $true
      live_daemon_bootstrap_proven = $true
      live_session_safe_stop = $true
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
      capability_shelf_mutated = $false
      body_pack_mutated = $false
      self_growth_runtime_mutated = $false
      external_fetch_performed = $false
      dependency_install_performed = $false
      arbitrary_code_execution_used = $false
      external_agents_created = $false
      queue_after = "NONE"
      codex_needed_for_next_step = $false
      local_head = $Head
      remote_head = $RemoteHead
      expected_head_source = $ExpectedHeadSource
      runtime_root = $RuntimeRoot
      session_boot_path = $SessionBootPath
      repo_identity_check_path = $RepoIdentityCheckPath
      phase159_readiness_read_path = $Phase159ReadinessReadPath
      live_session_contract_path = $LiveSessionContractPath
      daemon_start_command_path = $DaemonStartCommandPath
      observer_start_command_path = $ObserverStartCommandPath
      builder_daemon_runtime_config_path = $BuilderDaemonRuntimeConfigPath
      observer_runtime_config_path = $ObserverRuntimeConfigPath
      heartbeat_path = $HeartbeatPath
      current_state_path = $CurrentStatePath
      event_log_path = $EventLogPath
      observer_log_path = $ObserverLogPath
      observer_summary_path = $ObserverSummaryPath
      smoke_run_result_path = $SmokeRunResultPath
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      next_allowed_step = $NextAllowedStep
    }

    $BootstrapSummary = [ordered]@{}
    foreach ($key in $Common.Keys) { $BootstrapSummary[$key] = $Common[$key] }
    $BootstrapSummary["summary_id"] = "PHASE160_LIVE_DAEMON_BOOTSTRAP_SUMMARY"
    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $BootstrapSummaryPath -Object $BootstrapSummary

    $Result = [ordered]@{}
    foreach ($key in $Common.Keys) { $Result[$key] = $Common[$key] }
    $Result["result_id"] = "PHASE160_BUILDER_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_RESULT"
    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result

    $Report = [ordered]@{
      status = "PASS"
      report_id = "PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_V1_REPORT"
      step_id = $StepId
      run_id = $RunId
      repo_identity_gate_result = "PASS"
      root_cause = "PHASE160 live daemon entrypoint absent"
      serial_plan_used = @(
        "Verify repo identity from script location and PHASE159 accepted proof.",
        "Create PHASE160 live session contracts and channel folders.",
        "Create daemon and observer start command artifacts.",
        "Run bounded duration-based smoke with Builder daemon and Observer watcher PowerShell jobs.",
        "Require at least three heartbeat/tick records and observer alive detection.",
        "Write result, report, proof, and safe-stop evidence without queue/state mutation."
      )
      files_changed = @($RouteAlignmentPath, $BootstrapModulePath, $DaemonModulePath, $ObserverModulePath, $ValidatorPath) + $RuntimeOutputsCreated
      daemon_module_path = $DaemonModulePath
      observer_module_path = $ObserverModulePath
      bootstrap_module_path = $BootstrapModulePath
      validator_path = $ValidatorPath
      exact_smoke_run_command = ".\modules\invoke_builder_live_growth_session_daemon_bootstrap_001.ps1"
      exact_validator_command = ".\validators\validate_phase160_live_growth_session_daemon_bootstrap_v1.ps1 -RepoRoot ."
      runtime_outputs_created_by_module = $RuntimeOutputsCreated
      risks = @(
        "Smoke run is bounded by duration for acceptance; future owner-supervised run can use longer duration or stop.flag.",
        "Observer suggestions are file-based only and do not execute code.",
        "Remote HEAD check uses existing remote-tracking ref without network fetch."
      )
      cut_list = @(
        "No PHASE161 build.",
        "No fixed tick-count batch loop.",
        "No uncontrolled infinite process.",
        "No orchestrator change.",
        "No TASK_QUEUE mutation.",
        "No GENESIS_STATE mutation.",
        "No CAPABILITY_ROADMAP mutation.",
        "No packs registry mutation.",
        "No accepted PHASE142-PHASE159 artifact mutation.",
        "No capability_shelf mutation.",
        "No living_learning_environment/body mutation.",
        "No living_learning_environment/self_growth_runtime mutation.",
        "No generated_agents or applied_agents touch.",
        "No internet fetch.",
        "No dependency install.",
        "No arbitrary generated code execution.",
        "No external agent production.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report

    $Proof = [ordered]@{}
    foreach ($key in $Common.Keys) { $Proof[$key] = $Common[$key] }
    $Proof["proof_id"] = $StepId
    $Proof["source_phase159_proof_path"] = $Phase159ProofPath
    $Proof["source_phase159_live_session_skeleton_path"] = $Phase159LiveSkeletonPath
    $Proof["runtime_outputs_created_by_module"] = $RuntimeOutputsCreated
    Write-Phase160JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject][ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      resolved_repo_root = $RepoRoot
      phase159_verified = $true
      live_daemon_entrypoint_created = $true
      observer_entrypoint_created = $true
      duration_based_session = $true
      fixed_tick_batch_mode = $false
      heartbeat_count = $HeartbeatCount
      heartbeat_count_at_least_3 = $true
      observer_detected_builder_alive = $true
      live_daemon_bootstrap_proven = $true
      live_session_safe_stop = $true
      queue_after = "NONE"
      codex_needed_for_next_step = $false
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      next_allowed_step = $NextAllowedStep
    }
  } finally {
    if ($Pushed) {
      Pop-Location
    }
  }
}

if ($MyInvocation.InvocationName -ne ".") {
  Invoke-BuilderLiveGrowthSessionDaemonBootstrap001 -RunId $RunId -SmokeDurationSeconds $SmokeDurationSeconds -TickIntervalSeconds $TickIntervalSeconds -ObserverPollIntervalSeconds $ObserverPollIntervalSeconds -ExpectedHead $ExpectedHead | ConvertTo-Json -Depth 20
}
