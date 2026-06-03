param(
  [string]$SessionRoot = "runtime_sessions/live_growth/PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_001",
  [int]$DurationSeconds = 90,
  [int]$TickIntervalSeconds = 10,
  [switch]$EnableSelfGrowthDuty,
  [int]$SelfGrowthEveryTicks = 5,
  [int]$SelfGrowthStartTick = 2,
  [int]$MaxSelfGrowthDuties = 0,
  [string]$SelfGrowthDutyRoot = ""
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160DaemonFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160DaemonRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160_DAEMON_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160DaemonFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160DaemonPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function ConvertTo-Phase160DaemonRelativePath {
  param([string]$RepoRoot, [string]$FullPath)
  $normalizedRoot = Normalize-Phase160DaemonFullPath -Path $RepoRoot
  $normalizedPath = Normalize-Phase160DaemonFullPath -Path $FullPath
  if ($normalizedPath -eq $normalizedRoot) {
    return "."
  }
  if (-not $normalizedPath.StartsWith($normalizedRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160_DAEMON_PATH_OUTSIDE_REPO=$FullPath"
  }
  return ($normalizedPath.Substring($normalizedRoot.Length + 1) -replace "\\", "/")
}

function Write-Phase160DaemonJsonFile {
  param(
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $json = ($Object | ConvertTo-Json -Depth $Depth) -replace "`r`n", "`n"
  if (-not $json.EndsWith("`n")) {
    $json += "`n"
  }
  [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Add-Phase160DaemonJsonLine {
  param(
    [string]$Path,
    [object]$Object
  )
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $line = $Object | ConvertTo-Json -Depth 100 -Compress
  [System.IO.File]::AppendAllText($Path, "$line`n", [System.Text.UTF8Encoding]::new($false))
}

function Read-Phase160DaemonJsonSafe {
  param([string]$Path)
  try {
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Assert-Phase160DaemonEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160_DAEMON_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Get-Phase160DaemonRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160_DAEMON_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

$RepoRoot = Resolve-Phase160DaemonRepoRoot
$ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
$Pushed = $false

try {
  Push-Location $RepoRoot
  $Pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160DaemonPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  Assert-Phase160DaemonEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160DaemonRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160DaemonEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"
  $ExpectedHeadSource = "CURRENT_SYNCED_REPO_HEAD"

  if ($DurationSeconds -lt 1) {
    throw "PHASE160_DAEMON_INVALID_DURATION=$DurationSeconds"
  }
  if ($TickIntervalSeconds -lt 1) {
    throw "PHASE160_DAEMON_INVALID_TICK_INTERVAL=$TickIntervalSeconds"
  }
  if ($SelfGrowthEveryTicks -lt 1) {
    throw "PHASE160_DAEMON_INVALID_SELF_GROWTH_EVERY_TICKS=$SelfGrowthEveryTicks"
  }
  if ($SelfGrowthStartTick -lt 1) {
    throw "PHASE160_DAEMON_INVALID_SELF_GROWTH_START_TICK=$SelfGrowthStartTick"
  }
  if ($MaxSelfGrowthDuties -lt 0) {
    throw "PHASE160_DAEMON_INVALID_MAX_SELF_GROWTH_DUTIES=$MaxSelfGrowthDuties"
  }

  $SessionRootFull = Resolve-Phase160DaemonPath -RepoRoot $RepoRoot -Path $SessionRoot
  $SessionRootRelative = ConvertTo-Phase160DaemonRelativePath -RepoRoot $RepoRoot -FullPath $SessionRootFull
  foreach ($directory in @(
    $SessionRootFull,
    (Join-Path $SessionRootFull "tick_records"),
    (Join-Path $SessionRootFull "self_growth"),
    (Join-Path $SessionRootFull "teacher_inbox"),
    (Join-Path $SessionRootFull "teacher_outbox"),
    (Join-Path $SessionRootFull "blocker_queue"),
    (Join-Path $SessionRootFull "accepted_interventions"),
    (Join-Path $SessionRootFull "rejected_interventions")
  )) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $HeartbeatPath = Join-Path $SessionRootFull "heartbeat.json"
  $CurrentStatePath = Join-Path $SessionRootFull "current_state.json"
  $EventLogPath = Join-Path $SessionRootFull "event_log.jsonl"
  $TeacherOutboxPath = Join-Path $SessionRootFull "teacher_outbox"
  $BlockerQueuePath = Join-Path $SessionRootFull "blocker_queue"
  $AcceptedInterventionsPath = Join-Path $SessionRootFull "accepted_interventions"
  $RejectedInterventionsPath = Join-Path $SessionRootFull "rejected_interventions"
  $StopFlagPath = Join-Path $SessionRootFull "stop.flag"
  $SelfGrowthDutyScriptPath = Resolve-Phase160DaemonPath -RepoRoot $RepoRoot -Path "modules/invoke_builder_live_self_growth_duty_step_001.ps1"
  if ($EnableSelfGrowthDuty -and -not (Test-Path -LiteralPath $SelfGrowthDutyScriptPath)) {
    throw "PHASE160_DAEMON_SELF_GROWTH_DUTY_SCRIPT_MISSING=modules/invoke_builder_live_self_growth_duty_step_001.ps1"
  }
  if ([string]::IsNullOrWhiteSpace($SelfGrowthDutyRoot)) {
    $SelfGrowthDutyRootFull = Join-Path $SessionRootFull "self_growth"
  } else {
    $SelfGrowthDutyRootFull = Resolve-Phase160DaemonPath -RepoRoot $RepoRoot -Path $SelfGrowthDutyRoot
  }
  $SelfGrowthDutyRootRelative = ConvertTo-Phase160DaemonRelativePath -RepoRoot $RepoRoot -FullPath $SelfGrowthDutyRootFull
  $TeacherOutboxRelative = ConvertTo-Phase160DaemonRelativePath -RepoRoot $RepoRoot -FullPath $TeacherOutboxPath

  $StartTime = Get-Date
  $EndTime = $StartTime.AddSeconds($DurationSeconds)
  $ProcessedInterventions = @{}
  $TickCount = 0
  $StopReason = "duration_limit"
  $InvalidInterventionCount = 0
  $SelfGrowthDutyCount = 0
  $LastSelfGrowthDutyId = "NONE"
  $LastSelfGrowthGap = "NONE"
  $LastSelfGrowthStatus = if ($EnableSelfGrowthDuty) { "READY" } else { "DISABLED" }
  $NextSelfGrowthGap = if ($EnableSelfGrowthDuty) { "SELF_MAP_REFRESH_GAP" } else { "NONE" }

  Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
    event_type = "daemon_started"
    source = "builder_daemon"
    session_root = $SessionRootRelative
    duration_seconds = $DurationSeconds
    tick_interval_seconds = $TickIntervalSeconds
    duration_based_session = $true
    fixed_tick_batch_mode = $false
    occurred_at = $StartTime.ToUniversalTime().ToString("o")
  })

  while ((Get-Date) -lt $EndTime) {
    if (Test-Path -LiteralPath $StopFlagPath) {
      $StopReason = "stop_flag"
      Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
        event_type = "stop_flag_detected"
        source = "builder_daemon"
        stop_flag_path = "$SessionRootRelative/stop.flag"
        occurred_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      break
    }

    $TickCount += 1
    $TickId = "tick_{0:d4}" -f $TickCount
    $Now = Get-Date

    $TeacherFiles = @(Get-ChildItem -LiteralPath $TeacherOutboxPath -File -Filter "*.json" -ErrorAction SilentlyContinue | Sort-Object FullName)
    foreach ($teacherFile in $TeacherFiles) {
      if ($teacherFile.Name -eq "README.json") {
        continue
      }
      if ($ProcessedInterventions.ContainsKey($teacherFile.FullName)) {
        continue
      }
      $ProcessedInterventions[$teacherFile.FullName] = $true
      $Intervention = Read-Phase160DaemonJsonSafe -Path $teacherFile.FullName
      $Valid = $false
      $Reason = $null
      if ($null -ne $Intervention) {
        $Valid = (
          -not [string]::IsNullOrWhiteSpace([string]$Intervention.intervention_id) -and
          -not [string]::IsNullOrWhiteSpace([string]$Intervention.message_type) -and
          -not [string]::IsNullOrWhiteSpace([string]$Intervention.requested_action) -and
          (@("teacher_instruction", "teacher_correction", "teacher_stop_request", "observer_suggestion") -contains [string]$Intervention.message_type)
        )
      }
      if (-not $Valid) {
        $InvalidInterventionCount += 1
        $Reason = "invalid_teacher_intervention_schema"
        $RejectedPath = Join-Path $RejectedInterventionsPath ("rejected_{0:d4}.json" -f $InvalidInterventionCount)
        $BlockerPath = Join-Path $BlockerQueuePath ("blocker_invalid_intervention_{0:d4}.json" -f $InvalidInterventionCount)
        $Rejected = [ordered]@{
          status = "REJECTED"
          source_file = $teacherFile.Name
          reason = $Reason
          accepted_state_mutated = $false
          accepted_memory_mutated = $false
          created_at = (Get-Date).ToUniversalTime().ToString("o")
        }
        Write-Phase160DaemonJsonFile -Path $RejectedPath -Object $Rejected
        Write-Phase160DaemonJsonFile -Path $BlockerPath -Object ([ordered]@{
          status = "BLOCKED"
          blocker_id = "PHASE160_INVALID_TEACHER_INTERVENTION"
          source_file = $teacherFile.Name
          blocking_condition = $Reason
          safe_stop_recommended = $false
          created_at = (Get-Date).ToUniversalTime().ToString("o")
        })
        Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
          event_type = "teacher_intervention_rejected"
          source = "builder_daemon"
          source_file = $teacherFile.Name
          reason = $Reason
          occurred_at = (Get-Date).ToUniversalTime().ToString("o")
        })
      } else {
        $AcceptedPath = Join-Path $AcceptedInterventionsPath ("$($Intervention.intervention_id).json")
        Write-Phase160DaemonJsonFile -Path $AcceptedPath -Object ([ordered]@{
          status = "ACCEPTED"
          intervention_id = $Intervention.intervention_id
          message_type = $Intervention.message_type
          requested_action = $Intervention.requested_action
          action_taken = "recorded_for_sandbox_only_live_session"
          accepted_state_mutated = $false
          accepted_memory_mutated = $false
          created_at = (Get-Date).ToUniversalTime().ToString("o")
        })
        Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
          event_type = "teacher_intervention_accepted"
          source = "builder_daemon"
          intervention_id = $Intervention.intervention_id
          requested_action = $Intervention.requested_action
          occurred_at = (Get-Date).ToUniversalTime().ToString("o")
        })
      }
    }

    $SelfGrowthDutyDue = (
      $EnableSelfGrowthDuty -and
      $TickCount -ge $SelfGrowthStartTick -and
      ((($TickCount - $SelfGrowthStartTick) % $SelfGrowthEveryTicks) -eq 0) -and
      ($MaxSelfGrowthDuties -eq 0 -or $SelfGrowthDutyCount -lt $MaxSelfGrowthDuties)
    )
    if ($SelfGrowthDutyDue) {
      $NextDutyIndex = $SelfGrowthDutyCount + 1
      $NextDutyId = "duty_{0:d4}" -f $NextDutyIndex
      Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
        event_type = "self_growth_duty_started"
        source = "builder_daemon"
        duty_id = $NextDutyId
        duty_index = $NextDutyIndex
        tick_number = $TickCount
        expected_gap = $NextSelfGrowthGap
        occurred_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      try {
        $DutyCommand = @(
          "-NoProfile",
          "-ExecutionPolicy", "Bypass",
          "-File", $SelfGrowthDutyScriptPath,
          "-SessionRoot", $SessionRootRelative,
          "-TickNumber", [string]$TickCount,
          "-DutyIndex", [string]$NextDutyIndex,
          "-DutyRoot", $SelfGrowthDutyRootRelative,
          "-TeacherOutboxDir", $TeacherOutboxRelative
        )
        $DutyOutput = @(powershell @DutyCommand 2>&1 | ForEach-Object { [string]$_ })
        if ($LASTEXITCODE -ne 0) {
          throw "PHASE160_DAEMON_SELF_GROWTH_DUTY_PROCESS_FAILED exit=$LASTEXITCODE output=$($DutyOutput -join ' | ')"
        }
        $DutyResult = ($DutyOutput -join "`n") | ConvertFrom-Json
        $SelfGrowthDutyCount += 1
        $LastSelfGrowthDutyId = [string]$DutyResult.duty_id
        $LastSelfGrowthGap = [string]$DutyResult.selected_gap
        $LastSelfGrowthStatus = [string]$DutyResult.status
        $NextSelfGrowthGap = [string]$DutyResult.next_gap
        Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
          event_type = "self_growth_duty_completed"
          source = "builder_daemon"
          duty_id = $LastSelfGrowthDutyId
          duty_index = $SelfGrowthDutyCount
          tick_number = $TickCount
          selected_gap = $LastSelfGrowthGap
          status = $LastSelfGrowthStatus
          next_gap = $NextSelfGrowthGap
          occurred_at = (Get-Date).ToUniversalTime().ToString("o")
        })
      } catch {
        $LastSelfGrowthDutyId = $NextDutyId
        $LastSelfGrowthGap = $NextSelfGrowthGap
        $LastSelfGrowthStatus = "FAILED"
        $BlockerPath = Join-Path $BlockerQueuePath ("blocker_self_growth_{0}.json" -f $NextDutyId)
        Write-Phase160DaemonJsonFile -Path $BlockerPath -Object ([ordered]@{
          status = "BLOCKED"
          blocker_id = "PHASE160_SELF_GROWTH_DUTY_FAILED"
          duty_id = $NextDutyId
          selected_gap = $LastSelfGrowthGap
          blocking_condition = $_.Exception.Message
          safe_stop_recommended = $false
          accepted_state_mutated = $false
          accepted_memory_mutated = $false
          created_at = (Get-Date).ToUniversalTime().ToString("o")
        })
        Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
          event_type = "self_growth_duty_failed"
          source = "builder_daemon"
          duty_id = $NextDutyId
          tick_number = $TickCount
          selected_gap = $LastSelfGrowthGap
          error = $_.Exception.Message
          daemon_kept_alive = $true
          occurred_at = (Get-Date).ToUniversalTime().ToString("o")
        })
      }
    }

    $Heartbeat = [ordered]@{
      status = "RUNNING"
      heartbeat_id = "PHASE160_BUILDER_DAEMON_HEARTBEAT"
      session_root = $SessionRootRelative
      heartbeat_count = $TickCount
      last_tick_id = $TickId
      updated_at = $Now.ToUniversalTime().ToString("o")
      duration_based_session = $true
      fixed_tick_batch_mode = $false
      daemon_can_run_until_stop_flag = $true
      stop_flag_supported = $true
      self_growth_enabled = [bool]$EnableSelfGrowthDuty
      self_growth_duty_count = $SelfGrowthDutyCount
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
    }
    Write-Phase160DaemonJsonFile -Path $HeartbeatPath -Object $Heartbeat

    $CurrentState = [ordered]@{
      status = "RUNNING"
      state_id = "PHASE160_BUILDER_DAEMON_CURRENT_STATE"
      session_root = $SessionRootRelative
      current_tick = $TickCount
      last_tick_id = $TickId
      last_progress_at = $Now.ToUniversalTime().ToString("o")
      active_action = "SANDBOX_LIVE_HEARTBEAT_AND_CHANNEL_SCAN"
      duration_based_session = $true
      fixed_tick_batch_mode = $false
      stop_flag_seen = $false
      self_growth_enabled = [bool]$EnableSelfGrowthDuty
      self_growth_duty_count = $SelfGrowthDutyCount
      last_self_growth_duty_id = $LastSelfGrowthDutyId
      last_self_growth_gap = $LastSelfGrowthGap
      last_self_growth_status = $LastSelfGrowthStatus
      next_self_growth_gap = $NextSelfGrowthGap
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
    }
    Write-Phase160DaemonJsonFile -Path $CurrentStatePath -Object $CurrentState

    $TickRecord = [ordered]@{
      status = "PASS"
      tick_id = $TickId
      tick_number = $TickCount
      session_root = $SessionRootRelative
      heartbeat_written = $true
      current_state_written = $true
      teacher_outbox_scanned = $true
      accepted_interventions_supported = $true
      rejected_interventions_supported = $true
      blocker_queue_supported = $true
      self_growth_enabled = [bool]$EnableSelfGrowthDuty
      self_growth_duty_count = $SelfGrowthDutyCount
      last_self_growth_duty_id = $LastSelfGrowthDutyId
      last_self_growth_gap = $LastSelfGrowthGap
      last_self_growth_status = $LastSelfGrowthStatus
      next_self_growth_gap = $NextSelfGrowthGap
      duration_based_session = $true
      fixed_tick_batch_mode = $false
      occurred_at = $Now.ToUniversalTime().ToString("o")
    }
    Write-Phase160DaemonJsonFile -Path (Join-Path $SessionRootFull ("tick_records/{0}.json" -f $TickId)) -Object $TickRecord

    Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
      event_type = "tick"
      source = "builder_daemon"
      tick_id = $TickId
      tick_number = $TickCount
      heartbeat_written = $true
      current_state_written = $true
      self_growth_enabled = [bool]$EnableSelfGrowthDuty
      self_growth_duty_count = $SelfGrowthDutyCount
      last_self_growth_duty_id = $LastSelfGrowthDutyId
      last_self_growth_gap = $LastSelfGrowthGap
      last_self_growth_status = $LastSelfGrowthStatus
      next_self_growth_gap = $NextSelfGrowthGap
      duration_based_session = $true
      fixed_tick_batch_mode = $false
      occurred_at = $Now.ToUniversalTime().ToString("o")
    })

    $RemainingSeconds = [Math]::Floor(($EndTime - (Get-Date)).TotalSeconds)
    if ($RemainingSeconds -le 0) {
      break
    }
    Start-Sleep -Seconds ([Math]::Max(1, [Math]::Min($TickIntervalSeconds, $RemainingSeconds)))
  }

  $StoppedAt = (Get-Date).ToUniversalTime().ToString("o")
  $FinalState = [ordered]@{
    status = "STOPPED"
    state_id = "PHASE160_BUILDER_DAEMON_CURRENT_STATE"
    session_root = $SessionRootRelative
    current_tick = $TickCount
    last_tick_id = if ($TickCount -gt 0) { "tick_{0:d4}" -f $TickCount } else { $null }
    stop_reason = $StopReason
    stopped_at = $StoppedAt
    duration_based_session = $true
    fixed_tick_batch_mode = $false
    live_session_safe_stop = $true
    self_growth_enabled = [bool]$EnableSelfGrowthDuty
    self_growth_duty_count = $SelfGrowthDutyCount
    last_self_growth_duty_id = $LastSelfGrowthDutyId
    last_self_growth_gap = $LastSelfGrowthGap
    last_self_growth_status = $LastSelfGrowthStatus
    next_self_growth_gap = $NextSelfGrowthGap
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
  }
  Write-Phase160DaemonJsonFile -Path $CurrentStatePath -Object $FinalState

  $FinalHeartbeat = [ordered]@{
    status = "STOPPED"
    heartbeat_id = "PHASE160_BUILDER_DAEMON_HEARTBEAT"
    session_root = $SessionRootRelative
    heartbeat_count = $TickCount
    updated_at = $StoppedAt
    stop_reason = $StopReason
    duration_based_session = $true
    fixed_tick_batch_mode = $false
    daemon_can_run_until_stop_flag = $true
    stop_flag_supported = $true
    self_growth_enabled = [bool]$EnableSelfGrowthDuty
    self_growth_duty_count = $SelfGrowthDutyCount
  }
  Write-Phase160DaemonJsonFile -Path $HeartbeatPath -Object $FinalHeartbeat

  Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
    event_type = "daemon_stopped"
    source = "builder_daemon"
    stop_reason = $StopReason
    tick_count = $TickCount
    live_session_safe_stop = $true
    occurred_at = $StoppedAt
  })

  [pscustomobject][ordered]@{
    status = "PASS"
    session_root = $SessionRootRelative
    resolved_repo_root = $RepoRoot
    local_head = $Head
    remote_head = $RemoteHead
    expected_head_source = $ExpectedHeadSource
    duration_based_session = $true
    fixed_tick_batch_mode = $false
    tick_count = $TickCount
    self_growth_enabled = [bool]$EnableSelfGrowthDuty
    self_growth_duty_count = $SelfGrowthDutyCount
    last_self_growth_duty_id = $LastSelfGrowthDutyId
    last_self_growth_gap = $LastSelfGrowthGap
    last_self_growth_status = $LastSelfGrowthStatus
    next_self_growth_gap = $NextSelfGrowthGap
    heartbeat_written = (Test-Path -LiteralPath $HeartbeatPath)
    event_log_created = (Test-Path -LiteralPath $EventLogPath)
    stop_reason = $StopReason
    live_session_safe_stop = $true
  } | ConvertTo-Json -Depth 20
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
