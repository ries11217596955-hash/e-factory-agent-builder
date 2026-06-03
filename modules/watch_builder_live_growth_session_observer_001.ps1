param(
  [string]$SessionRoot = "runtime_sessions/live_growth/PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_001",
  [int]$DurationSeconds = 90,
  [int]$PollIntervalSeconds = 5,
  [int]$StaleAfterSeconds = 25,
  [switch]$ExpectSelfGrowthDuty
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160ObserverFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160ObserverRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160_OBSERVER_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160ObserverFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160ObserverPath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Write-Phase160ObserverJsonFile {
  param([string]$Path, [object]$Object, [int]$Depth = 100)
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

function Add-Phase160ObserverJsonLine {
  param([string]$Path, [object]$Object)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $line = $Object | ConvertTo-Json -Depth 100 -Compress
  [System.IO.File]::AppendAllText($Path, "$line`n", [System.Text.UTF8Encoding]::new($false))
}

function Read-Phase160ObserverJsonSafe {
  param([string]$Path)
  try {
    if (-not (Test-Path -LiteralPath $Path)) {
      return $null
    }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Get-Phase160ObserverJsonLineCount {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return 0
  }
  return @((Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
}

function Get-Phase160ObserverJsonFileCount {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return 0
  }
  return @(Get-ChildItem -LiteralPath $Path -File -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" }).Count
}

function Get-Phase160ObserverMatchingLineCount {
  param([string]$Path, [string]$Pattern)
  if (-not (Test-Path -LiteralPath $Path)) {
    return 0
  }
  return @(Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue | Where-Object { $_ -match $Pattern }).Count
}

function Assert-Phase160ObserverEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160_OBSERVER_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Get-Phase160ObserverRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160_OBSERVER_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

$RepoRoot = Resolve-Phase160ObserverRepoRoot
$ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
$Pushed = $false

try {
  Push-Location $RepoRoot
  $Pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160ObserverPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  Assert-Phase160ObserverEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160ObserverRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160ObserverEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"
  $ExpectedHeadSource = "CURRENT_SYNCED_REPO_HEAD"

  if ($DurationSeconds -lt 1) {
    throw "PHASE160_OBSERVER_INVALID_DURATION=$DurationSeconds"
  }
  if ($PollIntervalSeconds -lt 1) {
    throw "PHASE160_OBSERVER_INVALID_POLL_INTERVAL=$PollIntervalSeconds"
  }

  $SessionRootFull = Resolve-Phase160ObserverPath -RepoRoot $RepoRoot -Path $SessionRoot
  $SessionRootRelative = $SessionRootFull.Substring($RepoRoot.Length + 1) -replace "\\", "/"
  foreach ($directory in @($SessionRootFull, (Join-Path $SessionRootFull "teacher_inbox"), (Join-Path $SessionRootFull "blocker_queue"))) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $HeartbeatPath = Join-Path $SessionRootFull "heartbeat.json"
  $CurrentStatePath = Join-Path $SessionRootFull "current_state.json"
  $EventLogPath = Join-Path $SessionRootFull "event_log.jsonl"
  $ObserverLogPath = Join-Path $SessionRootFull "observer_log.jsonl"
  $ObserverSummaryPath = Join-Path $SessionRootFull "observer_summary.json"
  $TeacherInboxPath = Join-Path $SessionRootFull "teacher_inbox"
  $BlockerQueuePath = Join-Path $SessionRootFull "blocker_queue"

  $StartTime = Get-Date
  $EndTime = $StartTime.AddSeconds($DurationSeconds)
  $PollCount = 0
  $BuilderAliveDetected = $false
  $StaleHeartbeatDetected = $false
  $NoProgressDetected = $false
  $RepeatedActionDetected = $false
  $LastHeartbeatCount = $null
  $SameHeartbeatCount = 0
  $SuggestionWritten = $false
  $MaxEventLineCount = 0
  $SelfGrowthSeen = $false
  $SelfGrowthStagnationDetected = $false
  $MaxSelfGrowthDutyCount = 0
  $LastSelfGrowthGap = "NONE"
  $LastSelfGrowthStatus = "NONE"
  $LastSelfGrowthDutyCount = $null
  $SameSelfGrowthDutyCountPolls = 0
  $RepeatedSameGapPolls = 0
  $PreviousSelfGrowthGap = $null

  Add-Phase160ObserverJsonLine -Path $ObserverLogPath -Object ([ordered]@{
    event_type = "observer_started"
    source = "observer"
    session_root = $SessionRootRelative
    duration_seconds = $DurationSeconds
    poll_interval_seconds = $PollIntervalSeconds
    occurred_at = $StartTime.ToUniversalTime().ToString("o")
  })

  while ((Get-Date) -lt $EndTime) {
    $PollCount += 1
    $Now = Get-Date
    $Heartbeat = Read-Phase160ObserverJsonSafe -Path $HeartbeatPath
    $HeartbeatPresent = $null -ne $Heartbeat
    $HeartbeatCount = $null
    $HeartbeatStatus = $null
    $AliveThisPoll = $false
    $StaleThisPoll = $false

    if ($HeartbeatPresent) {
      $HeartbeatCount = [int]$Heartbeat.heartbeat_count
      $HeartbeatStatus = [string]$Heartbeat.status
      $LastSeen = [datetime]$Heartbeat.updated_at
      $AgeSeconds = ($Now.ToUniversalTime() - $LastSeen.ToUniversalTime()).TotalSeconds
      $StaleThisPoll = $AgeSeconds -gt $StaleAfterSeconds
      if (-not $StaleThisPoll -and @("RUNNING", "STOPPED") -contains $HeartbeatStatus) {
        $AliveThisPoll = $true
        $BuilderAliveDetected = $true
      }
      if ($StaleThisPoll) {
        $StaleHeartbeatDetected = $true
      }
      if ($null -ne $LastHeartbeatCount -and $HeartbeatCount -eq $LastHeartbeatCount) {
        $SameHeartbeatCount += 1
      } else {
        $SameHeartbeatCount = 0
      }
      if ($SameHeartbeatCount -ge 3 -and $HeartbeatStatus -eq "RUNNING") {
        $NoProgressDetected = $true
      }
      $LastHeartbeatCount = $HeartbeatCount
    }

    $EventLineCount = Get-Phase160ObserverJsonLineCount -Path $EventLogPath
    if ($EventLineCount -gt $MaxEventLineCount) {
      $MaxEventLineCount = $EventLineCount
    }

    $CurrentState = Read-Phase160ObserverJsonSafe -Path $CurrentStatePath
    $CurrentSelfGrowthDutyCount = 0
    $CurrentSelfGrowthEnabled = $false
    $CurrentLastSelfGrowthDutyId = "NONE"
    $CurrentLastSelfGrowthGap = "NONE"
    $CurrentLastSelfGrowthStatus = "NONE"
    $CurrentNextSelfGrowthGap = "NONE"
    if ($null -ne $CurrentState) {
      if ($CurrentState.PSObject.Properties.Name -contains "self_growth_duty_count") {
        $CurrentSelfGrowthDutyCount = [int]$CurrentState.self_growth_duty_count
      }
      if ($CurrentState.PSObject.Properties.Name -contains "self_growth_enabled") {
        $CurrentSelfGrowthEnabled = [bool]$CurrentState.self_growth_enabled
      }
      if ($CurrentState.PSObject.Properties.Name -contains "last_self_growth_duty_id") {
        $CurrentLastSelfGrowthDutyId = [string]$CurrentState.last_self_growth_duty_id
      }
      if ($CurrentState.PSObject.Properties.Name -contains "last_self_growth_gap") {
        $CurrentLastSelfGrowthGap = [string]$CurrentState.last_self_growth_gap
      }
      if ($CurrentState.PSObject.Properties.Name -contains "last_self_growth_status") {
        $CurrentLastSelfGrowthStatus = [string]$CurrentState.last_self_growth_status
      }
      if ($CurrentState.PSObject.Properties.Name -contains "next_self_growth_gap") {
        $CurrentNextSelfGrowthGap = [string]$CurrentState.next_self_growth_gap
      }
    }
    $SelfGrowthCompletedEventCount = Get-Phase160ObserverMatchingLineCount -Path $EventLogPath -Pattern '"event_type":"self_growth_duty_completed"'
    $SelfGrowthStartedEventCount = Get-Phase160ObserverMatchingLineCount -Path $EventLogPath -Pattern '"event_type":"self_growth_duty_started"'
    if ($CurrentSelfGrowthDutyCount -gt 0 -or $SelfGrowthCompletedEventCount -gt 0 -or $SelfGrowthStartedEventCount -gt 0) {
      $SelfGrowthSeen = $true
    }
    if ($CurrentSelfGrowthDutyCount -gt $MaxSelfGrowthDutyCount) {
      $MaxSelfGrowthDutyCount = $CurrentSelfGrowthDutyCount
    }
    if (-not [string]::IsNullOrWhiteSpace($CurrentLastSelfGrowthGap) -and $CurrentLastSelfGrowthGap -ne "NONE") {
      $LastSelfGrowthGap = $CurrentLastSelfGrowthGap
    }
    if (-not [string]::IsNullOrWhiteSpace($CurrentLastSelfGrowthStatus) -and $CurrentLastSelfGrowthStatus -ne "NONE") {
      $LastSelfGrowthStatus = $CurrentLastSelfGrowthStatus
    }
    if ($null -ne $LastSelfGrowthDutyCount -and $CurrentSelfGrowthDutyCount -eq $LastSelfGrowthDutyCount -and $HeartbeatStatus -eq "RUNNING" -and ($ExpectSelfGrowthDuty -or $CurrentSelfGrowthEnabled)) {
      $SameSelfGrowthDutyCountPolls += 1
    } else {
      $SameSelfGrowthDutyCountPolls = 0
    }
    if ($null -ne $PreviousSelfGrowthGap -and $CurrentLastSelfGrowthGap -eq $PreviousSelfGrowthGap -and $CurrentLastSelfGrowthGap -ne "NONE" -and $HeartbeatStatus -eq "RUNNING") {
      $RepeatedSameGapPolls += 1
    } else {
      $RepeatedSameGapPolls = 0
    }
    $LastSelfGrowthDutyCount = $CurrentSelfGrowthDutyCount
    $PreviousSelfGrowthGap = $CurrentLastSelfGrowthGap
    if (($ExpectSelfGrowthDuty -or $CurrentSelfGrowthEnabled) -and -not $SelfGrowthSeen -and $PollCount -ge 3) {
      $SelfGrowthStagnationDetected = $true
    }
    if ($SameSelfGrowthDutyCountPolls -ge 3) {
      $SelfGrowthStagnationDetected = $true
    }
    if ($RepeatedSameGapPolls -ge 3) {
      $RepeatedActionDetected = $true
    }

    $BlockerQueueCount = Get-Phase160ObserverJsonFileCount -Path $BlockerQueuePath
    $TeacherInboxCount = Get-Phase160ObserverJsonFileCount -Path $TeacherInboxPath

    if (($StaleHeartbeatDetected -or $NoProgressDetected) -and -not $SuggestionWritten) {
      $SuggestionPath = Join-Path $TeacherInboxPath "observer_intervention_suggestion_0001.json"
      Write-Phase160ObserverJsonFile -Path $SuggestionPath -Object ([ordered]@{
        status = "SUGGESTED"
        suggestion_id = "observer_intervention_suggestion_0001"
        source = "observer"
        reason = if ($StaleHeartbeatDetected) { "stale_heartbeat" } else { "no_progress" }
        suggested_action = "teacher_review_live_session"
        code_execution_requested = $false
        accepted_state_mutated = $false
        created_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      $SuggestionWritten = $true
    }

    Add-Phase160ObserverJsonLine -Path $ObserverLogPath -Object ([ordered]@{
      event_type = "observer_poll"
      source = "observer"
      poll_number = $PollCount
      heartbeat_present = $HeartbeatPresent
      heartbeat_status = $HeartbeatStatus
      heartbeat_count = $HeartbeatCount
      builder_alive_this_poll = $AliveThisPoll
      stale_heartbeat = $StaleThisPoll
      event_log_line_count = $EventLineCount
      no_progress_detected = $NoProgressDetected
      repeated_action_detected = $RepeatedActionDetected
      intervention_request_supported = $true
      intervention_suggestion_written = $SuggestionWritten
      self_growth_expected = [bool]$ExpectSelfGrowthDuty
      self_growth_seen = $SelfGrowthSeen
      self_growth_enabled = $CurrentSelfGrowthEnabled
      self_growth_duty_count = $CurrentSelfGrowthDutyCount
      last_self_growth_duty_id = $CurrentLastSelfGrowthDutyId
      last_self_growth_gap = $CurrentLastSelfGrowthGap
      last_self_growth_status = $CurrentLastSelfGrowthStatus
      next_self_growth_gap = $CurrentNextSelfGrowthGap
      self_growth_stagnation_detected = $SelfGrowthStagnationDetected
      blocker_queue_count = $BlockerQueueCount
      teacher_inbox_count = $TeacherInboxCount
      occurred_at = $Now.ToUniversalTime().ToString("o")
    })

    $RemainingSeconds = [Math]::Floor(($EndTime - (Get-Date)).TotalSeconds)
    if ($RemainingSeconds -le 0) {
      break
    }
    Start-Sleep -Seconds ([Math]::Max(1, [Math]::Min($PollIntervalSeconds, $RemainingSeconds)))
  }

  $Summary = [ordered]@{
    status = "PASS"
    summary_id = "PHASE160_OBSERVER_SUMMARY"
    session_root = $SessionRootRelative
    observer_completed = $true
    poll_count = $PollCount
    observer_detected_builder_alive = $BuilderAliveDetected
    heartbeat_observed = $BuilderAliveDetected
    event_log_observed = $MaxEventLineCount -gt 0
    max_event_log_line_count = $MaxEventLineCount
    stale_heartbeat_detected = $StaleHeartbeatDetected
    no_progress_detected = $NoProgressDetected
    repeated_action_detected = $RepeatedActionDetected
    intervention_request_supported = $true
    intervention_suggestion_written = $SuggestionWritten
    self_growth_expected = [bool]$ExpectSelfGrowthDuty
    self_growth_seen = $SelfGrowthSeen
    self_growth_duty_count = $MaxSelfGrowthDutyCount
    last_self_growth_gap = $LastSelfGrowthGap
    last_self_growth_status = $LastSelfGrowthStatus
    self_growth_stagnation_detected = $SelfGrowthStagnationDetected
    code_execution_requested = $false
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    completed_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase160ObserverJsonFile -Path $ObserverSummaryPath -Object $Summary

  Add-Phase160ObserverJsonLine -Path $ObserverLogPath -Object ([ordered]@{
    event_type = "observer_stopped"
    source = "observer"
    observer_detected_builder_alive = $BuilderAliveDetected
    poll_count = $PollCount
    occurred_at = (Get-Date).ToUniversalTime().ToString("o")
  })

  [pscustomobject][ordered]@{
    status = "PASS"
    session_root = $SessionRootRelative
    resolved_repo_root = $RepoRoot
    local_head = $Head
    remote_head = $RemoteHead
    expected_head_source = $ExpectedHeadSource
    observer_detected_builder_alive = $BuilderAliveDetected
    event_log_observed = $MaxEventLineCount -gt 0
    poll_count = $PollCount
    self_growth_seen = $SelfGrowthSeen
    self_growth_duty_count = $MaxSelfGrowthDutyCount
    last_self_growth_gap = $LastSelfGrowthGap
    last_self_growth_status = $LastSelfGrowthStatus
    self_growth_stagnation_detected = $SelfGrowthStagnationDetected
    observer_log_created = (Test-Path -LiteralPath $ObserverLogPath)
    observer_summary_created = (Test-Path -LiteralPath $ObserverSummaryPath)
  } | ConvertTo-Json -Depth 20
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
