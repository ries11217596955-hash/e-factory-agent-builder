param(
  [string]$SessionRoot = "runtime_sessions/live_growth/PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_001",
  [int]$DurationSeconds = 90,
  [int]$TickIntervalSeconds = 10
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

  $SessionRootFull = Resolve-Phase160DaemonPath -RepoRoot $RepoRoot -Path $SessionRoot
  $SessionRootRelative = $SessionRootFull.Substring($RepoRoot.Length + 1) -replace "\\", "/"
  foreach ($directory in @(
    $SessionRootFull,
    (Join-Path $SessionRootFull "tick_records"),
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

  $StartTime = Get-Date
  $EndTime = $StartTime.AddSeconds($DurationSeconds)
  $ProcessedInterventions = @{}
  $TickCount = 0
  $StopReason = "duration_limit"
  $InvalidInterventionCount = 0

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
