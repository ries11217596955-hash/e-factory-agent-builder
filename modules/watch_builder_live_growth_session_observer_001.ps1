param(
  [string]$SessionRoot = "",
  [string]$RunId = "",
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

function Test-Phase160ObserverDaemonProcessPresent {
  param([string]$SessionRoot)
  try {
    $escapedSession = [regex]::Escape($SessionRoot)
    $matches = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
      -not [string]::IsNullOrWhiteSpace([string]$_.CommandLine) -and
      $_.CommandLine -match "start_builder_live_growth_daemon_001\.ps1" -and
      $_.CommandLine -match $escapedSession
    })
    return $matches.Count -gt 0
  } catch {
    return $false
  }
}

function Assert-Phase160ObserverEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160_OBSERVER_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160ObserverRunIdSafe {
  param([string]$RunId)
  if ([string]::IsNullOrWhiteSpace($RunId)) {
    return
  }
  if ($RunId.IndexOfAny([char[]]@("/", "\")) -ge 0) {
    throw "PHASE160_OBSERVER_RUN_ID_MUST_BE_LEAF=$RunId"
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

  $SessionRootExplicit = ($PSBoundParameters.ContainsKey("SessionRoot") -and -not [string]::IsNullOrWhiteSpace($SessionRoot))
  Assert-Phase160ObserverRunIdSafe -RunId $RunId
  if (-not [string]::IsNullOrWhiteSpace($RunId) -and -not $SessionRootExplicit) {
    $SessionRoot = "runtime_sessions/live_growth/$RunId"
  }
  if ([string]::IsNullOrWhiteSpace($SessionRoot)) {
    $SessionRoot = "runtime_sessions/live_growth/PHASE160C_OWNER_SUPERVISED_LIVE_MACRO_RUN_001"
  }

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
  $FinalStatePath = Join-Path $SessionRootFull "final_state.json"
  $EventLogPath = Join-Path $SessionRootFull "event_log.jsonl"
  $ObserverLogPath = Join-Path $SessionRootFull "observer_log.jsonl"
  $ObserverSummaryPath = Join-Path $SessionRootFull "observer_summary.json"
  $TeacherInboxPath = Join-Path $SessionRootFull "teacher_inbox"
  $TeacherDigestPath = Join-Path $SessionRootFull "teacher_digest"
  $TeacherConsumedPath = Join-Path $SessionRootFull "teacher_consumed"
  $TeacherQuarantinePath = Join-Path $SessionRootFull "teacher_quarantine"
  $TaskBacklogPath = Join-Path $SessionRootFull "task_backlog"
  $BlockerQueuePath = Join-Path $SessionRootFull "blocker_queue"
  $RunManifestPath = Join-Path $SessionRootFull "run_manifest.json"
  $RuntimeGuardPath = Join-Path $SessionRootFull "runtime_guard.json"
  $CandidateWorkspacePath = Join-Path $SessionRootFull "candidate_workspace"
  $PromotionManifestPath = Join-Path $SessionRootFull "promotion_bundle/promotion_manifest.json"
  $ActiveTaskStatePath = Join-Path $SessionRootFull "task_lifecycle/active_task_state.json"
  $TaskCompletionReceiptsPath = Join-Path $SessionRootFull "task_lifecycle/task_completion_receipts"
  $BacklogAdvancementLogPath = Join-Path $SessionRootFull "task_lifecycle/backlog_advancement_log.jsonl"
  $PlanAdvancementLogPath = Join-Path $SessionRootFull "task_lifecycle/plan_item_advancement_log.jsonl"
  $SelectedUsefulGoalPath = Join-Path $SessionRootFull "self_initiated_goal_selection/selected_useful_goal.json"
  $InternalActiveTaskPath = Join-Path $SessionRootFull "self_initiated_goal_selection/internal_active_task.json"

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
  $StaleEndedSessionDetected = $false
  $RunManifestObserved = $false
  $RunHeadMatchesCurrent = $false
  $CandidateWorkspaceObserved = $false
  $PromotionBundleObserved = $false
  $ActiveTaskLifecycleMoved = $false
  $BacklogAdvancementDetected = $false
  $PlanItemAdvancementDetected = $false
  $RuntimeGuardViolationDetected = $false
  $CandidateWorkspaceEnabledDetected = $false
  $OwnerActiveTaskToCandidateDetected = $false
  $InternalSelfSelectedGoalDetected = $false
  $InternalActiveTaskDetected = $false
  $CandidateBundleCreatedDetected = $false
  $LiveRepoGuardPassDetected = $false
  $UnsafeRepoMutationDetected = $false
  $GuardPassWithAllowedRuntimeOutputsDetected = $false
  $GuardBlockedUnsafeMutationDetected = $false
  $ZeroCandidatePromotionTruthfulDetected = $false
  $PromotionBundleWithRealCandidateOnlyDetected = $false
  $QualityGateEnabledDetected = $false
  $MaxQualityReadyCount = 0
  $MaxRevisionRequiredCount = 0
  $MaxDraftCandidateCount = 0
  $MaxQuarantinedCandidateCount = 0
  $MaxBlockedCandidateCount = 0
  $LastQualityDecision = "NONE"
  $LastRevisionRequest = "NONE"
  $OwnerPromotionAllowedDetected = $false
  $SafeOwnerTaskAcceptedDetected = $false
  $SafeOwnerTaskBackloggedDetected = $false
  $UnsafeOwnerTaskQuarantinedDetected = $false
  $OwnerTaskNotLostDetected = $false
  $InternalSourceAttributionTruthfulDetected = $false
  $QualityResultFilesForEvaluatedCandidatesDetected = $false
  $PromotionManifestAgreesWithQualityResultsDetected = $false
  $ReadyCandidateWithoutQualityResultDetected = $false
  $WaitingOwnerReviewBlockedWhenQualityInconsistentDetected = $false
  $PlaceholderStillBlockedDetected = $false
  $UnsafeCandidateStillQuarantinedDetected = $false

  Add-Phase160ObserverJsonLine -Path $ObserverLogPath -Object ([ordered]@{
    event_type = "observer_started"
    source = "observer"
    run_id = if ([string]::IsNullOrWhiteSpace($RunId)) { "NONE" } else { $RunId }
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
    $CurrentMacroCycleEnabled = $false
    $CurrentMacroCycleId = "NONE"
    $CurrentMacroCycleStage = "NONE"
    $CurrentMacroDecision = "NONE"
    $CurrentOwnerTaskIntakeDecision = "NONE"
    $CurrentOwnerTaskQuarantineReason = "NONE"
    $CurrentOwnerTaskBacklogStatus = "NONE"
    $CurrentOwnerTaskBacklogCount = 0
    $CurrentOwnerTaskLost = $false
    $CurrentOwnerTaskLostFieldPresent = $false
    $CurrentActiveTaskBlocksOwnerTask = $false
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
      if ($CurrentState.PSObject.Properties.Name -contains "macro_cycle_enabled") {
        $CurrentMacroCycleEnabled = [bool]$CurrentState.macro_cycle_enabled
      }
      if ($CurrentState.PSObject.Properties.Name -contains "macro_cycle_id") {
        $CurrentMacroCycleId = [string]$CurrentState.macro_cycle_id
      }
      if ($CurrentState.PSObject.Properties.Name -contains "last_macro_cycle_stage") {
        $CurrentMacroCycleStage = [string]$CurrentState.last_macro_cycle_stage
      }
      if ($CurrentState.PSObject.Properties.Name -contains "last_macro_decision") {
        $CurrentMacroDecision = [string]$CurrentState.last_macro_decision
      }
      if ($CurrentState.PSObject.Properties.Name -contains "last_owner_task_intake_decision") {
        $CurrentOwnerTaskIntakeDecision = [string]$CurrentState.last_owner_task_intake_decision
      }
      if ($CurrentState.PSObject.Properties.Name -contains "last_owner_task_quarantine_reason") {
        $CurrentOwnerTaskQuarantineReason = [string]$CurrentState.last_owner_task_quarantine_reason
      }
      if ($CurrentState.PSObject.Properties.Name -contains "last_owner_task_backlog_status") {
        $CurrentOwnerTaskBacklogStatus = [string]$CurrentState.last_owner_task_backlog_status
      }
      if ($CurrentState.PSObject.Properties.Name -contains "owner_task_backlog_count") {
        $CurrentOwnerTaskBacklogCount = [int]$CurrentState.owner_task_backlog_count
      }
      if ($CurrentState.PSObject.Properties.Name -contains "owner_task_lost") {
        $CurrentOwnerTaskLost = [bool]$CurrentState.owner_task_lost
        $CurrentOwnerTaskLostFieldPresent = $true
      }
      if ($CurrentState.PSObject.Properties.Name -contains "active_task_blocks_owner_task") {
        $CurrentActiveTaskBlocksOwnerTask = [bool]$CurrentState.active_task_blocks_owner_task
      }
    }
    if ($CurrentOwnerTaskIntakeDecision -eq "ACCEPT_SAFE_OWNER_TASK") {
      $SafeOwnerTaskAcceptedDetected = $true
    }
    if ($CurrentOwnerTaskIntakeDecision -eq "BACKLOG_SAFE_OWNER_TASK" -or $CurrentOwnerTaskBacklogStatus -eq "BACKLOG_WAITING_ACTIVE_SLOT" -or ($CurrentOwnerTaskBacklogCount -gt 0 -and $CurrentActiveTaskBlocksOwnerTask)) {
      $SafeOwnerTaskBackloggedDetected = $true
    }
    if ($CurrentOwnerTaskIntakeDecision -eq "QUARANTINE_UNSAFE_OWNER_TASK" -or ($CurrentOwnerTaskQuarantineReason -ne "NONE" -and -not [string]::IsNullOrWhiteSpace($CurrentOwnerTaskQuarantineReason))) {
      $UnsafeOwnerTaskQuarantinedDetected = $true
    }
    if ($CurrentOwnerTaskLostFieldPresent -and -not $CurrentOwnerTaskLost) {
      $OwnerTaskNotLostDetected = $true
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
    $TeacherDigestCount = Get-Phase160ObserverJsonFileCount -Path $TeacherDigestPath
    $TeacherConsumedCount = Get-Phase160ObserverJsonFileCount -Path $TeacherConsumedPath
    $TeacherQuarantineCount = Get-Phase160ObserverJsonFileCount -Path $TeacherQuarantinePath
    $TaskBacklogCount = Get-Phase160ObserverJsonFileCount -Path $TaskBacklogPath
    $RunManifest = Read-Phase160ObserverJsonSafe -Path $RunManifestPath
    if ($null -ne $RunManifest) {
      $RunManifestObserved = $true
      try {
        $CurrentHeadForObserver = (git rev-parse --short HEAD).Trim()
        if ($RunManifest.PSObject.Properties.Name -contains "run_head" -and [string]$RunManifest.run_head -eq $CurrentHeadForObserver) {
          $RunHeadMatchesCurrent = $true
        }
      } catch {
        $RunHeadMatchesCurrent = $false
      }
    }
    if (Test-Path -LiteralPath $CandidateWorkspacePath) {
      $CandidateWorkspaceObserved = $true
    }
    if (Test-Path -LiteralPath $PromotionManifestPath) {
      $PromotionBundleObserved = $true
    }
    $CurrentQualityGateEnabled = $false
    $CurrentQualityReadyCount = 0
    $CurrentQualityResultFileCount = 0
    $CurrentQualityDecisionCount = 0
    $CurrentQualityArtifactConsistencyStatus = "UNKNOWN"
    $CurrentMissingQualityResultCount = 0
    $CurrentRevisionRequiredCount = 0
    $CurrentDraftCandidateCount = 0
    $CurrentQuarantinedCandidateCount = 0
    $CurrentBlockedCandidateCount = 0
    $CurrentLastQualityDecision = "NONE"
    $CurrentLastRevisionRequest = "NONE"
    $CurrentOwnerPromotionAllowed = $false
    $PromotionManifest = Read-Phase160ObserverJsonSafe -Path $PromotionManifestPath
    if ($null -ne $PromotionManifest) {
      $promotionStatus = if ($PromotionManifest.PSObject.Properties.Name -contains "promotion_status") { [string]$PromotionManifest.promotion_status } else { "UNKNOWN" }
      $promotionCandidateCount = if ($PromotionManifest.PSObject.Properties.Name -contains "candidate_count") { [int]$PromotionManifest.candidate_count } else { 0 }
      $promotionReadyCount = if ($PromotionManifest.PSObject.Properties.Name -contains "ready_candidate_count_after_quality") { [int]$PromotionManifest.ready_candidate_count_after_quality } elseif ($PromotionManifest.PSObject.Properties.Name -contains "ready_candidate_count") { [int]$PromotionManifest.ready_candidate_count } else { 0 }
      $CurrentQualityGateEnabled = if ($PromotionManifest.PSObject.Properties.Name -contains "quality_gate_enabled") { [bool]$PromotionManifest.quality_gate_enabled } else { $true }
      $CurrentQualityReadyCount = if ($PromotionManifest.PSObject.Properties.Name -contains "quality_ready_count") { [int]$PromotionManifest.quality_ready_count } else { $promotionReadyCount }
      $CurrentQualityResultFileCount = if ($PromotionManifest.PSObject.Properties.Name -contains "quality_result_file_count") { [int]$PromotionManifest.quality_result_file_count } else { 0 }
      $CurrentQualityDecisionCount = if ($PromotionManifest.PSObject.Properties.Name -contains "quality_decision_count") { [int]$PromotionManifest.quality_decision_count } else { $promotionCandidateCount }
      $CurrentQualityArtifactConsistencyStatus = if ($PromotionManifest.PSObject.Properties.Name -contains "quality_artifact_consistency_status") { [string]$PromotionManifest.quality_artifact_consistency_status } else { "UNKNOWN" }
      $CurrentMissingQualityResultCount = if ($PromotionManifest.PSObject.Properties.Name -contains "missing_quality_result_count") { [int]$PromotionManifest.missing_quality_result_count } else { 0 }
      $CurrentRevisionRequiredCount = if ($PromotionManifest.PSObject.Properties.Name -contains "revision_required_count") { [int]$PromotionManifest.revision_required_count } else { 0 }
      $CurrentDraftCandidateCount = if ($PromotionManifest.PSObject.Properties.Name -contains "draft_candidate_count") { [int]$PromotionManifest.draft_candidate_count } else { 0 }
      $CurrentQuarantinedCandidateCount = if ($PromotionManifest.PSObject.Properties.Name -contains "quarantined_candidate_count") { [int]$PromotionManifest.quarantined_candidate_count } else { 0 }
      $CurrentBlockedCandidateCount = if ($PromotionManifest.PSObject.Properties.Name -contains "blocked_candidate_count") { [int]$PromotionManifest.blocked_candidate_count } else { 0 }
      $CurrentLastQualityDecision = if ($PromotionManifest.PSObject.Properties.Name -contains "last_quality_decision") { [string]$PromotionManifest.last_quality_decision } else { "NONE" }
      $CurrentLastRevisionRequest = if ($PromotionManifest.PSObject.Properties.Name -contains "last_revision_request") { [string]$PromotionManifest.last_revision_request } else { "NONE" }
      $CurrentOwnerPromotionAllowed = if ($PromotionManifest.PSObject.Properties.Name -contains "owner_promotion_allowed") { [bool]$PromotionManifest.owner_promotion_allowed } else { $promotionReadyCount -gt 0 }
      if ($promotionCandidateCount -eq 0 -and @("NO_CANDIDATES", "BLOCKED_NO_CANDIDATES") -contains $promotionStatus) {
        $ZeroCandidatePromotionTruthfulDetected = $true
      }
      if ($promotionCandidateCount -gt 0 -and $promotionReadyCount -gt 0 -and $promotionStatus -eq "WAITING_OWNER_REVIEW") {
        $PromotionBundleWithRealCandidateOnlyDetected = $true
      }
    } elseif ($null -ne $CurrentState) {
      $CurrentQualityGateEnabled = if ($CurrentState.PSObject.Properties.Name -contains "quality_gate_enabled") { [bool]$CurrentState.quality_gate_enabled } else { $false }
      $CurrentQualityReadyCount = if ($CurrentState.PSObject.Properties.Name -contains "quality_ready_count") { [int]$CurrentState.quality_ready_count } else { 0 }
      $CurrentQualityResultFileCount = if ($CurrentState.PSObject.Properties.Name -contains "quality_result_file_count") { [int]$CurrentState.quality_result_file_count } else { 0 }
      $CurrentQualityDecisionCount = if ($CurrentState.PSObject.Properties.Name -contains "quality_decision_count") { [int]$CurrentState.quality_decision_count } else { 0 }
      $CurrentQualityArtifactConsistencyStatus = if ($CurrentState.PSObject.Properties.Name -contains "quality_artifact_consistency_status") { [string]$CurrentState.quality_artifact_consistency_status } else { "UNKNOWN" }
      $CurrentMissingQualityResultCount = if ($CurrentState.PSObject.Properties.Name -contains "missing_quality_result_count") { [int]$CurrentState.missing_quality_result_count } else { 0 }
      $CurrentRevisionRequiredCount = if ($CurrentState.PSObject.Properties.Name -contains "revision_required_count") { [int]$CurrentState.revision_required_count } else { 0 }
      $CurrentDraftCandidateCount = if ($CurrentState.PSObject.Properties.Name -contains "draft_candidate_count") { [int]$CurrentState.draft_candidate_count } else { 0 }
      $CurrentQuarantinedCandidateCount = if ($CurrentState.PSObject.Properties.Name -contains "quarantined_candidate_count") { [int]$CurrentState.quarantined_candidate_count } else { 0 }
      $CurrentBlockedCandidateCount = if ($CurrentState.PSObject.Properties.Name -contains "blocked_candidate_count") { [int]$CurrentState.blocked_candidate_count } else { 0 }
      $CurrentLastQualityDecision = if ($CurrentState.PSObject.Properties.Name -contains "last_quality_decision") { [string]$CurrentState.last_quality_decision } else { "NONE" }
      $CurrentLastRevisionRequest = if ($CurrentState.PSObject.Properties.Name -contains "last_revision_request") { [string]$CurrentState.last_revision_request } else { "NONE" }
      $CurrentOwnerPromotionAllowed = if ($CurrentState.PSObject.Properties.Name -contains "owner_promotion_allowed") { [bool]$CurrentState.owner_promotion_allowed } else { $false }
    }
    if ($CurrentQualityGateEnabled) {
      $QualityGateEnabledDetected = $true
    }
    if ($CurrentQualityDecisionCount -gt 0 -and $CurrentQualityResultFileCount -ge $CurrentQualityDecisionCount -and $CurrentMissingQualityResultCount -eq 0) {
      $QualityResultFilesForEvaluatedCandidatesDetected = $true
    }
    if ($CurrentQualityDecisionCount -gt 0 -and $CurrentQualityResultFileCount -eq $CurrentQualityDecisionCount -and @("PASS", "REPAIRED_WITH_CANONICAL_BACKFILL") -contains $CurrentQualityArtifactConsistencyStatus) {
      $PromotionManifestAgreesWithQualityResultsDetected = $true
    }
    if ($CurrentQualityReadyCount -gt $CurrentQualityResultFileCount) {
      $ReadyCandidateWithoutQualityResultDetected = $true
    }
    if ($CurrentQualityArtifactConsistencyStatus -eq "INCONSISTENT" -and $null -ne $PromotionManifest -and $PromotionManifest.PSObject.Properties.Name -contains "promotion_status" -and [string]$PromotionManifest.promotion_status -ne "WAITING_OWNER_REVIEW") {
      $WaitingOwnerReviewBlockedWhenQualityInconsistentDetected = $true
    }
    if ($CurrentRevisionRequiredCount -gt 0 -or $CurrentLastQualityDecision -eq "REVISION_REQUIRED") {
      $PlaceholderStillBlockedDetected = $true
    }
    if ($CurrentQuarantinedCandidateCount -gt 0 -or $CurrentBlockedCandidateCount -gt 0 -or $CurrentLastQualityDecision -match "QUARANTINED|BLOCKED") {
      $UnsafeCandidateStillQuarantinedDetected = $true
    }
    if ($CurrentQualityReadyCount -gt $MaxQualityReadyCount) {
      $MaxQualityReadyCount = $CurrentQualityReadyCount
    }
    if ($CurrentRevisionRequiredCount -gt $MaxRevisionRequiredCount) {
      $MaxRevisionRequiredCount = $CurrentRevisionRequiredCount
    }
    if ($CurrentDraftCandidateCount -gt $MaxDraftCandidateCount) {
      $MaxDraftCandidateCount = $CurrentDraftCandidateCount
    }
    if ($CurrentQuarantinedCandidateCount -gt $MaxQuarantinedCandidateCount) {
      $MaxQuarantinedCandidateCount = $CurrentQuarantinedCandidateCount
    }
    if ($CurrentBlockedCandidateCount -gt $MaxBlockedCandidateCount) {
      $MaxBlockedCandidateCount = $CurrentBlockedCandidateCount
    }
    if ($CurrentLastQualityDecision -ne "NONE") {
      $LastQualityDecision = $CurrentLastQualityDecision
    }
    if ($CurrentLastRevisionRequest -ne "NONE") {
      $LastRevisionRequest = $CurrentLastRevisionRequest
    }
    if ($CurrentOwnerPromotionAllowed) {
      $OwnerPromotionAllowedDetected = $true
    }
    $RuntimeGuard = Read-Phase160ObserverJsonSafe -Path $RuntimeGuardPath
    if ($null -ne $RuntimeGuard -and $RuntimeGuard.PSObject.Properties.Name -contains "status" -and [string]$RuntimeGuard.status -eq "BLOCKED") {
      $RuntimeGuardViolationDetected = $true
      $unsafeCount = if ($RuntimeGuard.PSObject.Properties.Name -contains "unsafe_tracked_code_mutation_count") { [int]$RuntimeGuard.unsafe_tracked_code_mutation_count } else { 0 }
      $protectedCount = if ($RuntimeGuard.PSObject.Properties.Name -contains "protected_state_mutation_count") { [int]$RuntimeGuard.protected_state_mutation_count } else { 0 }
      if ($unsafeCount -gt 0 -or $protectedCount -gt 0) {
        $GuardBlockedUnsafeMutationDetected = $true
        $UnsafeRepoMutationDetected = $true
      }
    }
    if ($null -ne $RuntimeGuard -and $RuntimeGuard.PSObject.Properties.Name -contains "status" -and [string]$RuntimeGuard.status -eq "PASS") {
      $LiveRepoGuardPassDetected = $true
      if ($RuntimeGuard.PSObject.Properties.Name -contains "allowed_runtime_output_count" -and [int]$RuntimeGuard.allowed_runtime_output_count -gt 0) {
        $GuardPassWithAllowedRuntimeOutputsDetected = $true
      }
      if ($CandidateWorkspaceObserved) {
        $CandidateWorkspaceEnabledDetected = $true
      }
    }
    $ActiveTaskState = Read-Phase160ObserverJsonSafe -Path $ActiveTaskStatePath
    $TaskCompletionReceiptCount = Get-Phase160ObserverJsonFileCount -Path $TaskCompletionReceiptsPath
    if (($null -ne $ActiveTaskState -and $ActiveTaskState.PSObject.Properties.Name -contains "status" -and [string]$ActiveTaskState.status -eq "WAITING_OWNER_PROMOTION") -or $TaskCompletionReceiptCount -gt 0) {
      $ActiveTaskLifecycleMoved = $true
    }
    if (Get-Phase160ObserverJsonLineCount -Path $BacklogAdvancementLogPath -gt 0) {
      $BacklogAdvancementDetected = $true
    }
    if (Get-Phase160ObserverJsonLineCount -Path $PlanAdvancementLogPath -gt 0) {
      $PlanItemAdvancementDetected = $true
    }
    if (Test-Path -LiteralPath $SelectedUsefulGoalPath) {
      $InternalSelfSelectedGoalDetected = $true
    }
    if (Test-Path -LiteralPath $InternalActiveTaskPath) {
      $InternalActiveTaskDetected = $true
    }
    $CandidateManifestCount = 0
    $CandidateManifests = @()
    $CandidateBundleRoot = Join-Path $SessionRootFull "candidate_workspace/candidate_bundles"
    if (Test-Path -LiteralPath $CandidateBundleRoot) {
      $CandidateManifestFiles = @(Get-ChildItem -LiteralPath $CandidateBundleRoot -File -Filter "candidate_manifest.json" -Recurse -ErrorAction SilentlyContinue)
      $CandidateManifestCount = $CandidateManifestFiles.Count
      foreach ($CandidateManifestFile in $CandidateManifestFiles) {
        $CandidateManifest = Read-Phase160ObserverJsonSafe -Path $CandidateManifestFile.FullName
        if ($null -ne $CandidateManifest) {
          $CandidateManifests += $CandidateManifest
        }
      }
    }
    if ($CandidateManifestCount -gt 0) {
      $CandidateBundleCreatedDetected = $true
    }
    if (@($CandidateManifests | Where-Object { [string]$_.source -eq "owner_task" -and [string]$_.source_task_id -eq "PHASE160F_META_SELF_INITIATED_USEFUL_GOAL_SELECTION_001" }).Count -gt 0) {
      $OwnerActiveTaskToCandidateDetected = $true
    }
    if (@($CandidateManifests | Where-Object { [string]$_.source -eq "internal_self_selected_goal" -and -not [string]::IsNullOrWhiteSpace([string]$_.source_task_id) }).Count -gt 0) {
      $ownerSourceWhileBacklogged = @($CandidateManifests | Where-Object { [string]$_.source -eq "owner_task" -and $CurrentOwnerTaskBacklogCount -gt 0 }).Count
      if ($ownerSourceWhileBacklogged -eq 0) {
        $InternalSourceAttributionTruthfulDetected = $true
      }
    }
    if ((Get-Phase160ObserverMatchingLineCount -Path $EventLogPath -Pattern '"event_type":"candidate_workspace_step_completed"') -gt 0 -and (Get-Phase160ObserverMatchingLineCount -Path $EventLogPath -Pattern 'PHASE160F_META_SELF_INITIATED_USEFUL_GOAL_SELECTION_001') -gt 0) {
      $OwnerActiveTaskToCandidateDetected = $true
    }

    if ($StaleThisPoll -and -not (Test-Path -LiteralPath $FinalStatePath)) {
      $DaemonPresent = Test-Phase160ObserverDaemonProcessPresent -SessionRoot $SessionRoot
      if (-not $DaemonPresent) {
        $StaleEndedSessionDetected = $true
        Write-Phase160ObserverJsonFile -Path $FinalStatePath -Object ([ordered]@{
          status = "STALE_ENDED"
          final_tick = if ($null -ne $CurrentState -and $CurrentState.PSObject.Properties.Name -contains "current_tick") { $CurrentState.current_tick } else { $HeartbeatCount }
          final_heartbeat_count = $HeartbeatCount
          final_self_growth_duty_count = $CurrentSelfGrowthDutyCount
          stop_flag_seen = Test-Path -LiteralPath (Join-Path $SessionRootFull "stop.flag")
          process_exit_reason = "heartbeat_stale_and_daemon_process_not_present"
          accepted_state_mutated = $false
          accepted_memory_mutated = $false
          accepted_self_model_mutated = $false
          next_recommended_action = "owner_review_stale_ended_session_and_resume_with_visible_console"
          finalized_at = (Get-Date).ToUniversalTime().ToString("o")
        })
      }
    }

    if (($StaleHeartbeatDetected -or $NoProgressDetected) -and -not $SuggestionWritten) {
      $SuggestionPath = Join-Path $TeacherInboxPath "observer_intervention_suggestion_0001.json"
      Write-Phase160ObserverJsonFile -Path $SuggestionPath -Object ([ordered]@{
        event_type = "owner_live_task_injection"
        task_id = "observer_intervention_suggestion_0001"
        source = "observer"
        priority = "low"
        owner_goal = if ($StaleHeartbeatDetected) { "Review stale heartbeat and decide whether the live session should stop or continue." } else { "Review no-progress signal and decide whether the live session should continue." }
        desired_next_gap = "LIVE_SESSION_OBSERVER_REVIEW_GAP"
        plan_steps = @(
          "Inspect heartbeat/current_state freshness.",
          "Inspect blocker_queue and event_log evidence.",
          "Decide whether to continue, stop, or quarantine the session-local result."
        )
        safety_rules = [ordered]@{
          accepted_state_mutation_allowed = $false
          accepted_memory_mutation_allowed = $false
          accepted_self_model_mutation_allowed = $false
          repo_commit_allowed = $false
          runtime_session_only = $true
        }
        success_signals = @("observer_suggestion_digest_written", "owner_review_possible")
        code_execution_requested = $false
        accepted_state_mutation_allowed = $false
        accepted_memory_mutation_allowed = $false
        accepted_self_model_mutation_allowed = $false
        repo_commit_allowed = $false
        runtime_session_only = $true
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
      macro_cycle_enabled = $CurrentMacroCycleEnabled
      macro_cycle_id = $CurrentMacroCycleId
      last_macro_cycle_stage = $CurrentMacroCycleStage
      last_macro_decision = $CurrentMacroDecision
      self_growth_stagnation_detected = $SelfGrowthStagnationDetected
      stale_ended_session_detected = $StaleEndedSessionDetected
      blocker_queue_count = $BlockerQueueCount
      teacher_inbox_count = $TeacherInboxCount
      teacher_digest_count = $TeacherDigestCount
      teacher_consumed_count = $TeacherConsumedCount
      teacher_quarantine_count = $TeacherQuarantineCount
      task_backlog_count = $TaskBacklogCount
      safe_owner_task_accepted = $SafeOwnerTaskAcceptedDetected
      safe_owner_task_backlogged_behind_active_task = $SafeOwnerTaskBackloggedDetected
      unsafe_owner_task_quarantined = $UnsafeOwnerTaskQuarantinedDetected
      owner_task_not_lost = $OwnerTaskNotLostDetected
      owner_task_lost_false_detected = $OwnerTaskNotLostDetected
      internal_source_attribution_truthful = $InternalSourceAttributionTruthfulDetected
      run_manifest_exists = $RunManifestObserved
      run_head_matches_current = $RunHeadMatchesCurrent
      candidate_workspace_exists = $CandidateWorkspaceObserved
      promotion_bundle_exists = $PromotionBundleObserved
      active_task_lifecycle_moved = $ActiveTaskLifecycleMoved
      backlog_advancement_detected = $BacklogAdvancementDetected
      plan_item_advancement_detected = $PlanItemAdvancementDetected
      runtime_guard_violation_detected = $RuntimeGuardViolationDetected
      candidate_workspace_enabled = $CandidateWorkspaceEnabledDetected
      owner_active_task_to_candidate_production = $OwnerActiveTaskToCandidateDetected
      internal_self_selected_goal_created = $InternalSelfSelectedGoalDetected
      internal_active_task_created = $InternalActiveTaskDetected
      candidate_bundle_created = $CandidateBundleCreatedDetected
      live_repo_guard_pass = $LiveRepoGuardPassDetected
      guard_pass_with_allowed_runtime_outputs = $GuardPassWithAllowedRuntimeOutputsDetected
      guard_blocked_with_unsafe_mutation = $GuardBlockedUnsafeMutationDetected
      zero_candidate_promotion_truthful = $ZeroCandidatePromotionTruthfulDetected
      promotion_bundle_with_real_candidate_only = $PromotionBundleWithRealCandidateOnlyDetected
      quality_result_files_exist_for_evaluated_candidates = $QualityResultFilesForEvaluatedCandidatesDetected
      promotion_manifest_agrees_with_quality_results = $PromotionManifestAgreesWithQualityResultsDetected
      ready_candidate_without_quality_result_detected = $ReadyCandidateWithoutQualityResultDetected
      waiting_owner_review_blocked_when_quality_inconsistent = $WaitingOwnerReviewBlockedWhenQualityInconsistentDetected
      placeholder_still_blocked = $PlaceholderStillBlockedDetected
      unsafe_still_quarantined = $UnsafeCandidateStillQuarantinedDetected
      quality_gate_enabled = $CurrentQualityGateEnabled
      quality_result_file_count = $CurrentQualityResultFileCount
      quality_decision_count = $CurrentQualityDecisionCount
      quality_artifact_consistency_status = $CurrentQualityArtifactConsistencyStatus
      missing_quality_result_count = $CurrentMissingQualityResultCount
      quality_ready_count = $CurrentQualityReadyCount
      revision_required_count = $CurrentRevisionRequiredCount
      draft_candidate_count = $CurrentDraftCandidateCount
      quarantined_candidate_count = $CurrentQuarantinedCandidateCount
      blocked_candidate_count = $CurrentBlockedCandidateCount
      last_quality_decision = $CurrentLastQualityDecision
      last_revision_request = $CurrentLastRevisionRequest
      owner_promotion_allowed = $CurrentOwnerPromotionAllowed
      unsafe_repo_mutation_detected = $UnsafeRepoMutationDetected
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
    run_id = if ([string]::IsNullOrWhiteSpace($RunId)) { "NONE" } else { $RunId }
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
    stale_ended_session_detected = $StaleEndedSessionDetected
    teacher_inbox_count = $TeacherInboxCount
    teacher_digest_count = $TeacherDigestCount
    teacher_consumed_count = $TeacherConsumedCount
    teacher_quarantine_count = $TeacherQuarantineCount
    task_backlog_count = $TaskBacklogCount
    safe_owner_task_accepted = $SafeOwnerTaskAcceptedDetected
    safe_owner_task_backlogged_behind_active_task = $SafeOwnerTaskBackloggedDetected
    unsafe_owner_task_quarantined = $UnsafeOwnerTaskQuarantinedDetected
    owner_task_not_lost = $OwnerTaskNotLostDetected
    owner_task_lost_false_detected = $OwnerTaskNotLostDetected
    internal_source_attribution_truthful = $InternalSourceAttributionTruthfulDetected
    run_manifest_exists = $RunManifestObserved
    run_head_matches_current = $RunHeadMatchesCurrent
    candidate_workspace_exists = $CandidateWorkspaceObserved
    promotion_bundle_exists = $PromotionBundleObserved
    active_task_lifecycle_moved = $ActiveTaskLifecycleMoved
    backlog_advancement_detected = $BacklogAdvancementDetected
    plan_item_advancement_detected = $PlanItemAdvancementDetected
    runtime_guard_violation_detected = $RuntimeGuardViolationDetected
    candidate_workspace_enabled = $CandidateWorkspaceEnabledDetected
    owner_active_task_to_candidate_production = $OwnerActiveTaskToCandidateDetected
    internal_self_selected_goal_created = $InternalSelfSelectedGoalDetected
    internal_active_task_created = $InternalActiveTaskDetected
    candidate_bundle_created = $CandidateBundleCreatedDetected
    live_repo_guard_pass = $LiveRepoGuardPassDetected
    guard_pass_with_allowed_runtime_outputs = $GuardPassWithAllowedRuntimeOutputsDetected
    guard_blocked_with_unsafe_mutation = $GuardBlockedUnsafeMutationDetected
    zero_candidate_promotion_truthful = $ZeroCandidatePromotionTruthfulDetected
    promotion_bundle_with_real_candidate_only = $PromotionBundleWithRealCandidateOnlyDetected
    quality_result_files_exist_for_evaluated_candidates = $QualityResultFilesForEvaluatedCandidatesDetected
    promotion_manifest_agrees_with_quality_results = $PromotionManifestAgreesWithQualityResultsDetected
    ready_candidate_without_quality_result_detected = $ReadyCandidateWithoutQualityResultDetected
    waiting_owner_review_blocked_when_quality_inconsistent = $WaitingOwnerReviewBlockedWhenQualityInconsistentDetected
    placeholder_still_blocked = $PlaceholderStillBlockedDetected
    unsafe_still_quarantined = $UnsafeCandidateStillQuarantinedDetected
    quality_gate_enabled = $QualityGateEnabledDetected
    quality_ready_count = $MaxQualityReadyCount
    revision_required_count = $MaxRevisionRequiredCount
    draft_candidate_count = $MaxDraftCandidateCount
    quarantined_candidate_count = $MaxQuarantinedCandidateCount
    blocked_candidate_count = $MaxBlockedCandidateCount
    last_quality_decision = $LastQualityDecision
    last_revision_request = $LastRevisionRequest
    owner_promotion_allowed = $OwnerPromotionAllowedDetected
    unsafe_repo_mutation_detected = $UnsafeRepoMutationDetected
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
    run_id = if ([string]::IsNullOrWhiteSpace($RunId)) { "NONE" } else { $RunId }
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
    stale_ended_session_detected = $StaleEndedSessionDetected
    safe_owner_task_accepted = $SafeOwnerTaskAcceptedDetected
    safe_owner_task_backlogged_behind_active_task = $SafeOwnerTaskBackloggedDetected
    unsafe_owner_task_quarantined = $UnsafeOwnerTaskQuarantinedDetected
    owner_task_not_lost = $OwnerTaskNotLostDetected
    owner_task_lost_false_detected = $OwnerTaskNotLostDetected
    internal_source_attribution_truthful = $InternalSourceAttributionTruthfulDetected
    run_manifest_exists = $RunManifestObserved
    run_head_matches_current = $RunHeadMatchesCurrent
    candidate_workspace_exists = $CandidateWorkspaceObserved
    promotion_bundle_exists = $PromotionBundleObserved
    active_task_lifecycle_moved = $ActiveTaskLifecycleMoved
    backlog_advancement_detected = $BacklogAdvancementDetected
    plan_item_advancement_detected = $PlanItemAdvancementDetected
    runtime_guard_violation_detected = $RuntimeGuardViolationDetected
    candidate_workspace_enabled = $CandidateWorkspaceEnabledDetected
    owner_active_task_to_candidate_production = $OwnerActiveTaskToCandidateDetected
    internal_self_selected_goal_created = $InternalSelfSelectedGoalDetected
    internal_active_task_created = $InternalActiveTaskDetected
    candidate_bundle_created = $CandidateBundleCreatedDetected
    live_repo_guard_pass = $LiveRepoGuardPassDetected
    guard_pass_with_allowed_runtime_outputs = $GuardPassWithAllowedRuntimeOutputsDetected
    guard_blocked_with_unsafe_mutation = $GuardBlockedUnsafeMutationDetected
    zero_candidate_promotion_truthful = $ZeroCandidatePromotionTruthfulDetected
    promotion_bundle_with_real_candidate_only = $PromotionBundleWithRealCandidateOnlyDetected
    quality_result_files_exist_for_evaluated_candidates = $QualityResultFilesForEvaluatedCandidatesDetected
    promotion_manifest_agrees_with_quality_results = $PromotionManifestAgreesWithQualityResultsDetected
    ready_candidate_without_quality_result_detected = $ReadyCandidateWithoutQualityResultDetected
    waiting_owner_review_blocked_when_quality_inconsistent = $WaitingOwnerReviewBlockedWhenQualityInconsistentDetected
    placeholder_still_blocked = $PlaceholderStillBlockedDetected
    unsafe_still_quarantined = $UnsafeCandidateStillQuarantinedDetected
    quality_gate_enabled = $QualityGateEnabledDetected
    quality_ready_count = $MaxQualityReadyCount
    revision_required_count = $MaxRevisionRequiredCount
    draft_candidate_count = $MaxDraftCandidateCount
    quarantined_candidate_count = $MaxQuarantinedCandidateCount
    blocked_candidate_count = $MaxBlockedCandidateCount
    last_quality_decision = $LastQualityDecision
    last_revision_request = $LastRevisionRequest
    owner_promotion_allowed = $OwnerPromotionAllowedDetected
    unsafe_repo_mutation_detected = $UnsafeRepoMutationDetected
    observer_log_created = (Test-Path -LiteralPath $ObserverLogPath)
    observer_summary_created = (Test-Path -LiteralPath $ObserverSummaryPath)
  } | ConvertTo-Json -Depth 20
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
