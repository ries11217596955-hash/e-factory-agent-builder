param(
  [string]$SessionRoot = "runtime_sessions/live_growth/PHASE160_OWNER_SUPERVISED_LIVE_RUN_001",
  [int]$DurationSeconds = 90,
  [int]$PollIntervalSeconds = 5,
  [int]$ShowTailEvents = 3,
  [int]$ShowTailObserver = 3,
  [string]$ConsoleRunId = "PHASE160_LIVE_OBSERVER_CONSOLE_REPAIR_001",
  [string]$ConsoleRuntimeRoot = ""
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160ConsoleFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160ConsoleRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160_LIVE_CONSOLE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160ConsoleFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160ConsolePath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function ConvertTo-Phase160ConsoleRelativePath {
  param([string]$RepoRoot, [string]$FullPath)
  $normalizedRoot = Normalize-Phase160ConsoleFullPath -Path $RepoRoot
  $normalizedPath = Normalize-Phase160ConsoleFullPath -Path $FullPath
  if ($normalizedPath -eq $normalizedRoot) {
    return "."
  }
  if (-not $normalizedPath.StartsWith($normalizedRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160_LIVE_CONSOLE_PATH_OUTSIDE_REPO=$FullPath"
  }
  return ($normalizedPath.Substring($normalizedRoot.Length + 1) -replace "\\", "/")
}

function Write-Phase160ConsoleJsonFile {
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

function Read-Phase160ConsoleJsonSafe {
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

function Read-Phase160ConsoleJsonLineSafe {
  param([string]$Line)
  try {
    if ([string]::IsNullOrWhiteSpace($Line)) {
      return $null
    }
    return $Line | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Get-Phase160ConsoleJsonLineCount {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return 0
  }
  return @((Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
}

function Get-Phase160ConsoleTailLines {
  param([string]$Path, [int]$Count)
  if ($Count -lt 1 -or -not (Test-Path -LiteralPath $Path)) {
    return @()
  }
  return @(Get-Content -LiteralPath $Path -Tail $Count -ErrorAction SilentlyContinue | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Get-Phase160ConsoleJsonFileSummary {
  param([string]$Directory)
  if (-not (Test-Path -LiteralPath $Directory)) {
    return [pscustomobject][ordered]@{
      count = 0
      latest_name = "NONE"
    }
  }
  $files = @(Get-ChildItem -LiteralPath $Directory -File -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" } | Sort-Object LastWriteTimeUtc, Name)
  $latest = "NONE"
  if ($files.Count -gt 0) {
    $latest = $files[-1].Name
  }
  return [pscustomobject][ordered]@{
    count = $files.Count
    latest_name = $latest
  }
}

function Format-Phase160ConsoleValue {
  param([object]$Value)
  if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
    return "NONE"
  }
  return ([string]$Value).Trim() -replace "\s+", "_"
}

function Get-Phase160ConsoleTailSummary {
  param([string]$Line)
  $json = Read-Phase160ConsoleJsonLineSafe -Line $Line
  if ($null -eq $json) {
    $clean = Format-Phase160ConsoleValue -Value $Line
    if ($clean.Length -gt 140) {
      return $clean.Substring(0, 140)
    }
    return $clean
  }

  $eventType = Format-Phase160ConsoleValue -Value $json.event_type
  $tickId = Format-Phase160ConsoleValue -Value $json.tick_id
  $poll = Format-Phase160ConsoleValue -Value $json.poll_number
  $heartbeat = Format-Phase160ConsoleValue -Value $json.heartbeat_count
  $stale = Format-Phase160ConsoleValue -Value $json.stale_heartbeat
  if ($tickId -ne "NONE") {
    return "event=$eventType tick=$tickId heartbeat=$heartbeat stale=$stale"
  }
  if ($poll -ne "NONE") {
    return "event=$eventType poll=$poll heartbeat=$heartbeat stale=$stale"
  }
  return "event=$eventType heartbeat=$heartbeat stale=$stale"
}

function Get-Phase160ConsoleLatestEventName {
  param([string]$EventLogPath)
  $tail = @(Get-Phase160ConsoleTailLines -Path $EventLogPath -Count 1)
  if ($tail.Count -lt 1) {
    return "NONE"
  }
  $json = Read-Phase160ConsoleJsonLineSafe -Line ([string]$tail[-1])
  if ($null -eq $json) {
    return "UNREADABLE"
  }
  $tick = Format-Phase160ConsoleValue -Value $json.tick_id
  if ($tick -ne "NONE") {
    return $tick
  }
  return Format-Phase160ConsoleValue -Value $json.event_type
}

function Assert-Phase160ConsoleEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160_LIVE_CONSOLE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Get-Phase160ConsoleRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160_LIVE_CONSOLE_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Write-Phase160ConsoleVisibleLine {
  param([string]$Line, [string]$SamplePath)
  Write-Host $Line
  [System.IO.File]::AppendAllText($SamplePath, "$Line`n", [System.Text.UTF8Encoding]::new($false))
}

$RepoRoot = Resolve-Phase160ConsoleRepoRoot
$ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
$RepairId = "PHASE160_LIVE_OBSERVER_CONSOLE_REPAIR_V1"
if ([string]::IsNullOrWhiteSpace($ConsoleRuntimeRoot)) {
  $ConsoleRuntimeRoot = "runtime_sessions/live_growth_console/$ConsoleRunId"
}
$Pushed = $false

try {
  Push-Location $RepoRoot
  $Pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160ConsolePath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  Assert-Phase160ConsoleEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160ConsoleRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160ConsoleEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"
  $ExpectedHeadSource = "CURRENT_SYNCED_REPO_HEAD"

  if ($DurationSeconds -lt 1) {
    throw "PHASE160_LIVE_CONSOLE_INVALID_DURATION=$DurationSeconds"
  }
  if ($PollIntervalSeconds -lt 1) {
    throw "PHASE160_LIVE_CONSOLE_INVALID_POLL_INTERVAL=$PollIntervalSeconds"
  }
  if ($ShowTailEvents -lt 0) {
    throw "PHASE160_LIVE_CONSOLE_INVALID_SHOW_TAIL_EVENTS=$ShowTailEvents"
  }
  if ($ShowTailObserver -lt 0) {
    throw "PHASE160_LIVE_CONSOLE_INVALID_SHOW_TAIL_OBSERVER=$ShowTailObserver"
  }

  $SessionRootFull = Resolve-Phase160ConsolePath -RepoRoot $RepoRoot -Path $SessionRoot
  $SessionRootRelative = ConvertTo-Phase160ConsoleRelativePath -RepoRoot $RepoRoot -FullPath $SessionRootFull
  if (-not (Test-Path -LiteralPath $SessionRootFull)) {
    throw "PHASE160_LIVE_CONSOLE_SESSION_ROOT_MISSING=$SessionRootRelative"
  }

  $ConsoleRuntimeRootFull = Resolve-Phase160ConsolePath -RepoRoot $RepoRoot -Path $ConsoleRuntimeRoot
  $ConsoleRuntimeRootRelative = ConvertTo-Phase160ConsoleRelativePath -RepoRoot $RepoRoot -FullPath $ConsoleRuntimeRootFull
  New-Item -ItemType Directory -Force -Path $ConsoleRuntimeRootFull | Out-Null
  $SamplePath = Join-Path $ConsoleRuntimeRootFull "console_output_sample.txt"
  $ResultPath = Join-Path $ConsoleRuntimeRootFull "console_run_result.json"
  [System.IO.File]::WriteAllText($SamplePath, "", [System.Text.UTF8Encoding]::new($false))

  $HeartbeatPath = Join-Path $SessionRootFull "heartbeat.json"
  $CurrentStatePath = Join-Path $SessionRootFull "current_state.json"
  $EventLogPath = Join-Path $SessionRootFull "event_log.jsonl"
  $ObserverLogPath = Join-Path $SessionRootFull "observer_log.jsonl"
  $BlockerQueuePath = Join-Path $SessionRootFull "blocker_queue"
  $TeacherInboxPath = Join-Path $SessionRootFull "teacher_inbox"
  $TeacherOutboxPath = Join-Path $SessionRootFull "teacher_outbox"
  $StopFlagPath = Join-Path $SessionRootFull "stop.flag"

  $StartTime = Get-Date
  $EndTime = $StartTime.AddSeconds($DurationSeconds)
  $PollCount = 0
  $LiveLineCount = 0
  $StaleHeartbeatDetected = $false
  $HeartbeatRead = $false
  $CurrentStateRead = $false
  $EventLogRead = $false
  $ObserverLogRead = $false
  $BlockerQueueRead = $false
  $TeacherInboxRead = $false
  $TeacherOutboxRead = $false
  $StopFlagRead = $false
  $SelfGrowthFieldsPrinted = $false
  $StaleAfterSeconds = [Math]::Max(25, $PollIntervalSeconds * 5)

  while ((Get-Date) -lt $EndTime) {
    $PollCount += 1
    $Now = Get-Date
    $Heartbeat = Read-Phase160ConsoleJsonSafe -Path $HeartbeatPath
    $CurrentState = Read-Phase160ConsoleJsonSafe -Path $CurrentStatePath
    $HeartbeatRead = $HeartbeatRead -or ($null -ne $Heartbeat)
    $CurrentStateRead = $CurrentStateRead -or ($null -ne $CurrentState)

    $HeartbeatStatus = "MISSING"
    $HeartbeatCount = "NONE"
    $HeartbeatAgeSeconds = "NONE"
    $StaleThisPoll = $true
    if ($null -ne $Heartbeat) {
      $HeartbeatStatus = Format-Phase160ConsoleValue -Value $Heartbeat.status
      $HeartbeatCount = Format-Phase160ConsoleValue -Value $Heartbeat.heartbeat_count
      if (-not [string]::IsNullOrWhiteSpace([string]$Heartbeat.updated_at)) {
        $LastSeen = [datetime]$Heartbeat.updated_at
        $HeartbeatAgeSecondsValue = [Math]::Floor(($Now.ToUniversalTime() - $LastSeen.ToUniversalTime()).TotalSeconds)
        $HeartbeatAgeSeconds = [string]$HeartbeatAgeSecondsValue
        $StaleThisPoll = $HeartbeatAgeSecondsValue -gt $StaleAfterSeconds
      }
    }
    if ($StaleThisPoll) {
      $StaleHeartbeatDetected = $true
    }

    $CurrentTick = "NONE"
    if ($null -ne $CurrentState) {
      $CurrentTick = Format-Phase160ConsoleValue -Value $CurrentState.current_tick
    }
    if ($CurrentTick -eq "NONE") {
      $CurrentTick = $HeartbeatCount
    }

    $SelfGrowthEnabled = "False"
    $SelfGrowthDutyCount = "0"
    $LastSelfGrowthDuty = "NONE"
    $LastSelfGrowthGap = "NONE"
    $LastSelfGrowthStatus = "NONE"
    $NextSelfGrowthGap = "NONE"
    if ($null -ne $Heartbeat -and $Heartbeat.PSObject.Properties.Name -contains "self_growth_enabled") {
      $SelfGrowthEnabled = Format-Phase160ConsoleValue -Value $Heartbeat.self_growth_enabled
    }
    if ($null -ne $Heartbeat -and $Heartbeat.PSObject.Properties.Name -contains "self_growth_duty_count") {
      $SelfGrowthDutyCount = Format-Phase160ConsoleValue -Value $Heartbeat.self_growth_duty_count
    }
    if ($null -ne $CurrentState) {
      if ($CurrentState.PSObject.Properties.Name -contains "self_growth_enabled") {
        $SelfGrowthEnabled = Format-Phase160ConsoleValue -Value $CurrentState.self_growth_enabled
      }
      if ($CurrentState.PSObject.Properties.Name -contains "self_growth_duty_count") {
        $SelfGrowthDutyCount = Format-Phase160ConsoleValue -Value $CurrentState.self_growth_duty_count
      }
      if ($CurrentState.PSObject.Properties.Name -contains "last_self_growth_duty_id") {
        $LastSelfGrowthDuty = Format-Phase160ConsoleValue -Value $CurrentState.last_self_growth_duty_id
      }
      if ($CurrentState.PSObject.Properties.Name -contains "last_self_growth_gap") {
        $LastSelfGrowthGap = Format-Phase160ConsoleValue -Value $CurrentState.last_self_growth_gap
      }
      if ($CurrentState.PSObject.Properties.Name -contains "last_self_growth_status") {
        $LastSelfGrowthStatus = Format-Phase160ConsoleValue -Value $CurrentState.last_self_growth_status
      }
      if ($CurrentState.PSObject.Properties.Name -contains "next_self_growth_gap") {
        $NextSelfGrowthGap = Format-Phase160ConsoleValue -Value $CurrentState.next_self_growth_gap
      }
    }

    $EventLineCount = Get-Phase160ConsoleJsonLineCount -Path $EventLogPath
    $ObserverLineCount = Get-Phase160ConsoleJsonLineCount -Path $ObserverLogPath
    $EventLogRead = $EventLogRead -or ($EventLineCount -gt 0)
    $ObserverLogRead = $ObserverLogRead -or ($ObserverLineCount -gt 0)
    $BlockerSummary = Get-Phase160ConsoleJsonFileSummary -Directory $BlockerQueuePath
    $TeacherInboxSummary = Get-Phase160ConsoleJsonFileSummary -Directory $TeacherInboxPath
    $TeacherOutboxSummary = Get-Phase160ConsoleJsonFileSummary -Directory $TeacherOutboxPath
    $BlockerQueueRead = $true
    $TeacherInboxRead = $true
    $TeacherOutboxRead = $true
    $StopFlagPresent = Test-Path -LiteralPath $StopFlagPath
    $StopFlagRead = $true
    $LastEvent = Get-Phase160ConsoleLatestEventName -EventLogPath $EventLogPath

    $Line = "LIVE_CONSOLE POLL=$PollCount HEARTBEAT_STATUS=$HeartbeatStatus TICK=$CurrentTick HEARTBEAT_COUNT=$HeartbeatCount SELF_GROWTH_ENABLED=$SelfGrowthEnabled DUTY_COUNT=$SelfGrowthDutyCount LAST_DUTY=$LastSelfGrowthDuty LAST_GAP=$LastSelfGrowthGap LAST_DUTY_STATUS=$LastSelfGrowthStatus NEXT_GAP=$NextSelfGrowthGap EVENT_LINES=$EventLineCount OBSERVER_LINES=$ObserverLineCount BLOCKERS=$($BlockerSummary.count) LATEST_BLOCKER=$($BlockerSummary.latest_name) TEACHER_INBOX=$($TeacherInboxSummary.count) LATEST_SUGGESTION=$($TeacherInboxSummary.latest_name) TEACHER_OUTBOX=$($TeacherOutboxSummary.count) STALE=$StaleThisPoll HEARTBEAT_AGE_SECONDS=$HeartbeatAgeSeconds STOP_FLAG=$StopFlagPresent LAST_EVENT=$LastEvent"
    Write-Phase160ConsoleVisibleLine -Line $Line -SamplePath $SamplePath
    $LiveLineCount += 1
    $SelfGrowthFieldsPrinted = $true

    $EventTail = Get-Phase160ConsoleTailLines -Path $EventLogPath -Count $ShowTailEvents
    for ($i = 0; $i -lt $EventTail.Count; $i += 1) {
      $TailSummary = Get-Phase160ConsoleTailSummary -Line $EventTail[$i]
      Write-Phase160ConsoleVisibleLine -Line "LIVE_CONSOLE EVENT_TAIL[$($i + 1)] $TailSummary" -SamplePath $SamplePath
    }

    $ObserverTail = Get-Phase160ConsoleTailLines -Path $ObserverLogPath -Count $ShowTailObserver
    for ($i = 0; $i -lt $ObserverTail.Count; $i += 1) {
      $TailSummary = Get-Phase160ConsoleTailSummary -Line $ObserverTail[$i]
      Write-Phase160ConsoleVisibleLine -Line "LIVE_CONSOLE OBSERVER_TAIL[$($i + 1)] $TailSummary" -SamplePath $SamplePath
    }

    $RemainingSeconds = [Math]::Floor(($EndTime - (Get-Date)).TotalSeconds)
    if ($RemainingSeconds -le 0) {
      break
    }
    Start-Sleep -Seconds ([Math]::Max(1, [Math]::Min($PollIntervalSeconds, $RemainingSeconds)))
  }

  $Result = [ordered]@{
    status = "PASS"
    repair_id = $RepairId
    run_id = $ConsoleRunId
    resolved_repo_root = $RepoRoot
    branch = $Branch
    local_head = $Head
    remote_head = $RemoteHead
    expected_head_source = $ExpectedHeadSource
    session_root = $SessionRootRelative
    console_runtime_root = $ConsoleRuntimeRootRelative
    console_output_sample_path = "$ConsoleRuntimeRoot/console_output_sample.txt"
    poll_count = $PollCount
    live_console_lines_count = $LiveLineCount
    console_prints_live_lines = $LiveLineCount -ge 2
    console_reads_heartbeat = $HeartbeatRead
    console_reads_current_state = $CurrentStateRead
    console_reads_event_log = $EventLogRead
    console_reads_observer_log = $ObserverLogRead
    console_reads_blocker_queue = $BlockerQueueRead
    console_reads_teacher_inbox = $TeacherInboxRead
    console_reads_teacher_outbox = $TeacherOutboxRead
    console_reads_stop_flag = $StopFlagRead
    console_detects_stale_heartbeat = $StaleHeartbeatDetected
    console_supports_owner_screenshot_mode = $true
    live_console_shows_self_growth_fields = $SelfGrowthFieldsPrinted
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    queue_mutated = $false
    external_fetch_performed = $false
    dependency_install_performed = $false
    arbitrary_code_execution_used = $false
    completed_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase160ConsoleJsonFile -Path $ResultPath -Object $Result
  Write-Phase160ConsoleVisibleLine -Line "LIVE_CONSOLE_DONE STATUS=PASS POLLS=$PollCount SAMPLE=$ConsoleRuntimeRoot/console_output_sample.txt RESULT=$ConsoleRuntimeRoot/console_run_result.json" -SamplePath $SamplePath
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
