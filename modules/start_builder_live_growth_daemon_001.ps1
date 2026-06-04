param(
  [string]$SessionRoot = "",
  [string]$RunId = "",
  [int]$DurationSeconds = 3600,
  [int]$TickIntervalSeconds = 10,
  [switch]$RunUntilStop,
  [switch]$EnableSelfGrowthDuty,
  [int]$SelfGrowthEveryTicks = 5,
  [int]$SelfGrowthStartTick = 2,
  [int]$MaxSelfGrowthDuties = 0,
  [string]$SelfGrowthDutyRoot = "",
  [switch]$EnableMacroSelfGrowth,
  [switch]$EnableMacroSelfGrowthCycle,
  [string]$MacroCycleId = "PHASE160B_MACRO_SELF_GROWTH_IGNITION_CYCLE_001",
  [switch]$EnableCandidateWorkspacePromotion
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

function Get-Phase160DaemonJsonFileCount {
  param([string]$Path, [string]$Pattern = "*.json")
  if (-not (Test-Path -LiteralPath $Path)) {
    return 0
  }
  return @(Get-ChildItem -LiteralPath $Path -File -Filter $Pattern -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" }).Count
}

function Get-Phase160DaemonLatestJson {
  param([string]$Path, [string]$Pattern = "*.json")
  if (-not (Test-Path -LiteralPath $Path)) {
    return $null
  }
  $files = @(Get-ChildItem -LiteralPath $Path -File -Filter $Pattern -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" } | Sort-Object LastWriteTimeUtc, Name)
  if ($files.Count -lt 1) {
    return $null
  }
  return Read-Phase160DaemonJsonSafe -Path $files[-1].FullName
}

function Get-Phase160DaemonLiveTaskSnapshot {
  param([string]$SessionRootFull)
  $activeTask = Read-Phase160DaemonJsonSafe -Path (Join-Path $SessionRootFull "active_task/active_task.json")
  $activePlanItem = Read-Phase160DaemonJsonSafe -Path (Join-Path $SessionRootFull "active_task/active_plan_item.json")
  $runManifest = Read-Phase160DaemonJsonSafe -Path (Join-Path $SessionRootFull "run_manifest.json")
  $runtimeIdentity = Read-Phase160DaemonJsonSafe -Path (Join-Path $SessionRootFull "runtime_identity.json")
  $runtimeGuard = Read-Phase160DaemonJsonSafe -Path (Join-Path $SessionRootFull "runtime_guard.json")
  $promotionManifest = Read-Phase160DaemonJsonSafe -Path (Join-Path $SessionRootFull "promotion_bundle/promotion_manifest.json")
  $activeTaskState = Read-Phase160DaemonJsonSafe -Path (Join-Path $SessionRootFull "task_lifecycle/active_task_state.json")
  $selectedUsefulGoal = Read-Phase160DaemonJsonSafe -Path (Join-Path $SessionRootFull "self_initiated_goal_selection/selected_useful_goal.json")
  $internalActiveTask = Read-Phase160DaemonJsonSafe -Path (Join-Path $SessionRootFull "self_initiated_goal_selection/internal_active_task.json")
  $latestConsumed = Get-Phase160DaemonLatestJson -Path (Join-Path $SessionRootFull "teacher_consumed") -Pattern "receipt_*.json"
  $candidateBundleRoot = Join-Path $SessionRootFull "candidate_workspace/candidate_bundles"
  $candidateCount = 0
  $readyCandidateCount = 0
  $quarantinedCandidateCount = 0
  $lastCandidateId = "NONE"
  if (Test-Path -LiteralPath $candidateBundleRoot) {
    $candidateBundleDirs = @(Get-ChildItem -LiteralPath $candidateBundleRoot -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc, Name)
    foreach ($candidateBundleDir in $candidateBundleDirs) {
      $candidateManifest = Read-Phase160DaemonJsonSafe -Path (Join-Path $candidateBundleDir.FullName "candidate_manifest.json")
      if ($null -eq $candidateManifest) {
        continue
      }
      $candidateCount += 1
      $candidateDecision = if ($candidateManifest.PSObject.Properties.Name -contains "decision") { [string]$candidateManifest.decision } else { "UNKNOWN" }
      if ($candidateDecision -eq "CANDIDATE_READY") {
        $readyCandidateCount += 1
      }
      if ($candidateDecision -match "QUARANTINE|QUARANTINED") {
        $quarantinedCandidateCount += 1
      }
      $lastCandidateId = if ($candidateManifest.PSObject.Properties.Name -contains "candidate_id") { [string]$candidateManifest.candidate_id } else { $candidateBundleDir.Name }
    }
  }
  $planPendingCount = 0
  $planActiveCount = 0
  $planWaitingPromotionCount = 0
  $planItemsRoot = Join-Path $SessionRootFull "plan_items"
  if (Test-Path -LiteralPath $planItemsRoot) {
    $planItemFiles = @(Get-ChildItem -LiteralPath $planItemsRoot -File -Filter "*_plan_item_*.json" -Recurse -ErrorAction SilentlyContinue)
    foreach ($planItemFile in $planItemFiles) {
      $planItem = Read-Phase160DaemonJsonSafe -Path $planItemFile.FullName
      if ($null -eq $planItem -or -not ($planItem.PSObject.Properties.Name -contains "status")) {
        continue
      }
      switch ([string]$planItem.status) {
        "PENDING" { $planPendingCount += 1 }
        "ACTIVE" { $planActiveCount += 1 }
        "WAITING_OWNER_PROMOTION" { $planWaitingPromotionCount += 1 }
      }
    }
  }
  $lastPromotionEvent = "NONE"
  $changeLedgerPath = Join-Path $SessionRootFull "candidate_workspace/change_ledger.jsonl"
  if (Test-Path -LiteralPath $changeLedgerPath) {
    $ledgerTail = @(Get-Content -LiteralPath $changeLedgerPath -Tail 25 -ErrorAction SilentlyContinue | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    foreach ($ledgerLine in $ledgerTail) {
      $ledgerEntry = $null
      try {
        $ledgerEntry = $ledgerLine | ConvertFrom-Json
      } catch {
        $ledgerEntry = $null
      }
      if ($null -ne $ledgerEntry -and $ledgerEntry.PSObject.Properties.Name -contains "event_type" -and [string]$ledgerEntry.event_type -match "promotion") {
        $lastPromotionEvent = [string]$ledgerEntry.event_type
      }
    }
  }
  $currentHead = "UNKNOWN"
  try {
    $currentHead = (git rev-parse --short HEAD).Trim()
  } catch {
    $currentHead = "UNKNOWN"
  }
  $runHead = if ($null -ne $runManifest -and $runManifest.PSObject.Properties.Name -contains "run_head") { [string]$runManifest.run_head } else { "NONE" }
  $headMatch = if ($runHead -eq "NONE" -or $currentHead -eq "UNKNOWN") { $false } else { $runHead -eq $currentHead }
  return [ordered]@{
    run_head = $runHead
    current_head = $currentHead
    head_match = $headMatch
    live_repo_guard = if ($null -ne $runtimeGuard -and $runtimeGuard.PSObject.Properties.Name -contains "status") { [string]$runtimeGuard.status } elseif ($null -ne $runtimeIdentity -and $runtimeIdentity.PSObject.Properties.Name -contains "live_repo_guard") { [string]$runtimeIdentity.live_repo_guard } else { "UNKNOWN" }
    candidate_workspace_status = if ($null -ne $runtimeGuard -and $runtimeGuard.PSObject.Properties.Name -contains "status" -and [string]$runtimeGuard.status -eq "PASS") { "ENABLED" } elseif ($null -ne $runtimeGuard -and $runtimeGuard.PSObject.Properties.Name -contains "status" -and [string]$runtimeGuard.status -eq "BLOCKED") { "BLOCKED" } else { "UNKNOWN" }
    candidate_count = $candidateCount
    ready_candidate_count = $readyCandidateCount
    quarantined_candidate_count = $quarantinedCandidateCount
    promotion_bundle_status = if ($null -ne $promotionManifest -and $promotionManifest.PSObject.Properties.Name -contains "promotion_status") { [string]$promotionManifest.promotion_status } else { "NONE" }
    restart_required_after_promotion = if ($null -ne $promotionManifest -and $promotionManifest.PSObject.Properties.Name -contains "restart_required_after_promotion") { [bool]$promotionManifest.restart_required_after_promotion } else { $false }
    active_task_status = if ($null -ne $activeTaskState -and $activeTaskState.PSObject.Properties.Name -contains "status") { [string]$activeTaskState.status } else { "NONE" }
    plan_pending_count = $planPendingCount
    plan_active_count = $planActiveCount
    plan_waiting_promotion_count = $planWaitingPromotionCount
    last_candidate_id = $lastCandidateId
    last_promotion_event = $lastPromotionEvent
    self_initiated_goal_selected = $null -ne $selectedUsefulGoal
    selected_useful_goal = if ($null -ne $selectedUsefulGoal -and $selectedUsefulGoal.PSObject.Properties.Name -contains "selected_goal_id") { [string]$selectedUsefulGoal.selected_goal_id } else { "NONE" }
    internal_active_task_created = $null -ne $internalActiveTask
    teacher_inbox_count = Get-Phase160DaemonJsonFileCount -Path (Join-Path $SessionRootFull "teacher_inbox")
    teacher_digest_count = Get-Phase160DaemonJsonFileCount -Path (Join-Path $SessionRootFull "teacher_digest")
    teacher_consumed_count = Get-Phase160DaemonJsonFileCount -Path (Join-Path $SessionRootFull "teacher_consumed") -Pattern "receipt_*.json"
    teacher_quarantine_count = Get-Phase160DaemonJsonFileCount -Path (Join-Path $SessionRootFull "teacher_quarantine") -Pattern "quarantine_*.json"
    task_backlog_count = Get-Phase160DaemonJsonFileCount -Path (Join-Path $SessionRootFull "task_backlog")
    active_task_id = if ($null -ne $activeTask -and $activeTask.PSObject.Properties.Name -contains "task_id") { [string]$activeTask.task_id } else { "NONE" }
    active_plan_item_id = if ($null -ne $activePlanItem -and $activePlanItem.PSObject.Properties.Name -contains "item_id") { [string]$activePlanItem.item_id } else { "NONE" }
    last_consumed_task = if ($null -ne $latestConsumed -and $latestConsumed.PSObject.Properties.Name -contains "task_id") { [string]$latestConsumed.task_id } else { "NONE" }
  }
}

function Assert-Phase160DaemonEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160_DAEMON_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160DaemonRunIdSafe {
  param([string]$RunId)
  if ([string]::IsNullOrWhiteSpace($RunId)) {
    return
  }
  if ($RunId.IndexOfAny([char[]]@("/", "\")) -ge 0) {
    throw "PHASE160_DAEMON_RUN_ID_MUST_BE_LEAF=$RunId"
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

  $SessionRootExplicit = ($PSBoundParameters.ContainsKey("SessionRoot") -and -not [string]::IsNullOrWhiteSpace($SessionRoot))
  Assert-Phase160DaemonRunIdSafe -RunId $RunId
  if (-not [string]::IsNullOrWhiteSpace($RunId) -and -not $SessionRootExplicit) {
    $SessionRoot = "runtime_sessions/live_growth/$RunId"
  }
  if ([string]::IsNullOrWhiteSpace($SessionRoot)) {
    $SessionRoot = "runtime_sessions/live_growth/PHASE160C_OWNER_SUPERVISED_LIVE_MACRO_RUN_001"
  }
  $MacroSelfGrowthEnabled = [bool]($EnableMacroSelfGrowth -or $EnableMacroSelfGrowthCycle)

  if (-not $RunUntilStop -and $DurationSeconds -lt 1) {
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
  if ([string]::IsNullOrWhiteSpace($RunId)) {
    $RunId = [System.IO.Path]::GetFileName(($SessionRootRelative -replace "/", [System.IO.Path]::DirectorySeparatorChar))
  }
  foreach ($directory in @(
    $SessionRootFull,
    (Join-Path $SessionRootFull "tick_records"),
    (Join-Path $SessionRootFull "self_growth"),
    (Join-Path $SessionRootFull "teacher_inbox"),
    (Join-Path $SessionRootFull "teacher_digest"),
    (Join-Path $SessionRootFull "teacher_consumed"),
    (Join-Path $SessionRootFull "teacher_quarantine"),
    (Join-Path $SessionRootFull "task_backlog"),
    (Join-Path $SessionRootFull "active_task"),
    (Join-Path $SessionRootFull "plan_items"),
    (Join-Path $SessionRootFull "candidate_workspace"),
    (Join-Path $SessionRootFull "candidate_workspace/candidate_bundles"),
    (Join-Path $SessionRootFull "candidate_workspace/candidate_queue"),
    (Join-Path $SessionRootFull "candidate_workspace/candidate_quarantine"),
    (Join-Path $SessionRootFull "promotion_bundle"),
    (Join-Path $SessionRootFull "task_lifecycle"),
    (Join-Path $SessionRootFull "task_lifecycle/task_completion_receipts"),
    (Join-Path $SessionRootFull "teacher_outbox"),
    (Join-Path $SessionRootFull "blocker_queue"),
    (Join-Path $SessionRootFull "accepted_interventions"),
    (Join-Path $SessionRootFull "rejected_interventions")
  )) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $HeartbeatPath = Join-Path $SessionRootFull "heartbeat.json"
  $CurrentStatePath = Join-Path $SessionRootFull "current_state.json"
  $FinalStatePath = Join-Path $SessionRootFull "final_state.json"
  $EventLogPath = Join-Path $SessionRootFull "event_log.jsonl"
  $TeacherOutboxPath = Join-Path $SessionRootFull "teacher_outbox"
  $BlockerQueuePath = Join-Path $SessionRootFull "blocker_queue"
  $AcceptedInterventionsPath = Join-Path $SessionRootFull "accepted_interventions"
  $RejectedInterventionsPath = Join-Path $SessionRootFull "rejected_interventions"
  $StopFlagPath = Join-Path $SessionRootFull "stop.flag"
  $SelfGrowthDutyScriptPath = Resolve-Phase160DaemonPath -RepoRoot $RepoRoot -Path "modules/invoke_builder_live_self_growth_duty_step_001.ps1"
  $RuntimeIdentityScriptPath = Resolve-Phase160DaemonPath -RepoRoot $RepoRoot -Path "modules/inspect_builder_runtime_identity_001.ps1"
  $CandidateWorkspaceScriptPath = Resolve-Phase160DaemonPath -RepoRoot $RepoRoot -Path "modules/invoke_builder_candidate_workspace_step_001.ps1"
  $PromotionFinalizeScriptPath = Resolve-Phase160DaemonPath -RepoRoot $RepoRoot -Path "modules/finalize_builder_promotion_bundle_001.ps1"
  $SelfInitiatedGoalSelectScriptPath = Resolve-Phase160DaemonPath -RepoRoot $RepoRoot -Path "modules/select_builder_self_initiated_useful_goal_001.ps1"
  if ($EnableSelfGrowthDuty -and -not (Test-Path -LiteralPath $SelfGrowthDutyScriptPath)) {
    throw "PHASE160_DAEMON_SELF_GROWTH_DUTY_SCRIPT_MISSING=modules/invoke_builder_live_self_growth_duty_step_001.ps1"
  }
  if (-not (Test-Path -LiteralPath $RuntimeIdentityScriptPath)) {
    throw "PHASE160E_DAEMON_RUNTIME_IDENTITY_SCRIPT_MISSING=modules/inspect_builder_runtime_identity_001.ps1"
  }
  if ($EnableCandidateWorkspacePromotion -and -not (Test-Path -LiteralPath $CandidateWorkspaceScriptPath)) {
    throw "PHASE160E_DAEMON_CANDIDATE_WORKSPACE_SCRIPT_MISSING=modules/invoke_builder_candidate_workspace_step_001.ps1"
  }
  if ($EnableCandidateWorkspacePromotion -and -not (Test-Path -LiteralPath $PromotionFinalizeScriptPath)) {
    throw "PHASE160E_DAEMON_PROMOTION_FINALIZE_SCRIPT_MISSING=modules/finalize_builder_promotion_bundle_001.ps1"
  }
  if ($EnableCandidateWorkspacePromotion -and -not (Test-Path -LiteralPath $SelfInitiatedGoalSelectScriptPath)) {
    throw "PHASE160F_DAEMON_SELF_INITIATED_GOAL_SELECT_SCRIPT_MISSING=modules/select_builder_self_initiated_useful_goal_001.ps1"
  }
  if ([string]::IsNullOrWhiteSpace($SelfGrowthDutyRoot)) {
    $SelfGrowthDutyRootFull = Join-Path $SessionRootFull "self_growth"
  } else {
    $SelfGrowthDutyRootFull = Resolve-Phase160DaemonPath -RepoRoot $RepoRoot -Path $SelfGrowthDutyRoot
  }
  $SelfGrowthDutyRootRelative = ConvertTo-Phase160DaemonRelativePath -RepoRoot $RepoRoot -FullPath $SelfGrowthDutyRootFull
  $TeacherOutboxRelative = ConvertTo-Phase160DaemonRelativePath -RepoRoot $RepoRoot -FullPath $TeacherOutboxPath

  $RuntimeIdentityOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File $RuntimeIdentityScriptPath -SessionRoot $SessionRootRelative -RunId $RunId -Mode Initialize -GuardLabel "daemon_start" 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160E_DAEMON_RUNTIME_IDENTITY_INITIALIZE_FAILED exit=$LASTEXITCODE output=$($RuntimeIdentityOutput -join ' | ')"
  }
  $RuntimeIdentityResult = ($RuntimeIdentityOutput -join "`n") | ConvertFrom-Json
  $RunHead = [string]$RuntimeIdentityResult.run_head
  $CurrentHead = [string]$RuntimeIdentityResult.current_head
  $HeadMatch = [bool]$RuntimeIdentityResult.head_match
  $LiveRepoGuard = [string]$RuntimeIdentityResult.live_repo_guard
  $CandidateProductionEnabled = [bool]$RuntimeIdentityResult.candidate_production_enabled

  $StartTime = Get-Date
  $EndTime = if ($RunUntilStop) { [datetime]::MaxValue } else { $StartTime.AddSeconds($DurationSeconds) }
  $ProcessedInterventions = @{}
  $TickCount = 0
  $StopReason = "duration_limit"
  $StopFlagSeen = $false
  $InvalidInterventionCount = 0
  $SelfGrowthDutyCount = 0
  $LastSelfGrowthDutyId = "NONE"
  $LastSelfGrowthGap = "NONE"
  $LastSelfGrowthStatus = if ($EnableSelfGrowthDuty) { "READY" } else { "DISABLED" }
  $NextSelfGrowthGap = if ($EnableSelfGrowthDuty) { "SELF_MAP_REFRESH_GAP" } else { "NONE" }
  $LastMacroCycleStage = "NONE"
  $LastMacroDecision = "NONE"
  $ActiveMacroCycleId = if ($MacroSelfGrowthEnabled) { $MacroCycleId } else { "NONE" }
  $LastTaskInfluencedGapSelection = $false
  $LiveTaskSnapshot = Get-Phase160DaemonLiveTaskSnapshot -SessionRootFull $SessionRootFull

  Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
    event_type = "daemon_started"
    source = "builder_daemon"
    run_id = if ([string]::IsNullOrWhiteSpace($RunId)) { "NONE" } else { $RunId }
    session_root = $SessionRootRelative
    duration_seconds = $DurationSeconds
    run_until_stop = [bool]$RunUntilStop
    tick_interval_seconds = $TickIntervalSeconds
    run_head = $RunHead
    current_head = $CurrentHead
    head_match = $HeadMatch
    live_repo_guard = $LiveRepoGuard
    candidate_workspace_promotion_enabled = [bool]$EnableCandidateWorkspacePromotion
    candidate_workspace_status = if ($EnableCandidateWorkspacePromotion -and $CandidateProductionEnabled) { "ENABLED" } elseif ($EnableCandidateWorkspacePromotion) { "BLOCKED" } else { "DISABLED" }
    self_initiated_goal_selected = $false
    selected_useful_goal = "NONE"
    internal_active_task_created = $false
    candidate_production_enabled = $CandidateProductionEnabled
    duration_based_session = $true
    fixed_tick_batch_mode = $false
    occurred_at = $StartTime.ToUniversalTime().ToString("o")
  })

  while ($RunUntilStop -or (Get-Date) -lt $EndTime) {
    if (Test-Path -LiteralPath $StopFlagPath) {
      $StopReason = "stop_flag"
      $StopFlagSeen = $true
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
        if ($MacroSelfGrowthEnabled) {
          $DutyCommand += @("-EnableMacroCycle", "-MacroCycleId", $MacroCycleId)
        }
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
        if ($DutyResult.PSObject.Properties.Name -contains "cycle_stage") {
          $LastMacroCycleStage = [string]$DutyResult.cycle_stage
        }
        if ($DutyResult.PSObject.Properties.Name -contains "decision") {
          $LastMacroDecision = [string]$DutyResult.decision
        }
        if ($DutyResult.PSObject.Properties.Name -contains "task_influenced_gap_selection") {
          $LastTaskInfluencedGapSelection = [bool]$DutyResult.task_influenced_gap_selection
        }
        $CandidateWorkspaceResultStatus = "DISABLED"
        $LastCandidateWorkspaceCandidateId = "NONE"
        $SelfInitiatedSelectionStatus = "NOT_RUN"
        $SelfInitiatedGoalSelected = $false
        $SelectedUsefulGoal = "NONE"
        if ($EnableCandidateWorkspacePromotion) {
          $RuntimeGuardOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File $RuntimeIdentityScriptPath -SessionRoot $SessionRootRelative -RunId $RunId -Mode GuardCheck -GuardLabel ("after_{0}" -f $NextDutyId) 2>&1 | ForEach-Object { [string]$_ })
          if ($LASTEXITCODE -ne 0) {
            throw "PHASE160E_DAEMON_RUNTIME_GUARD_FAILED exit=$LASTEXITCODE output=$($RuntimeGuardOutput -join ' | ')"
          }
          $RuntimeGuardResult = ($RuntimeGuardOutput -join "`n") | ConvertFrom-Json
          $RunHead = [string]$RuntimeGuardResult.run_head
          $CurrentHead = [string]$RuntimeGuardResult.current_head
          $HeadMatch = [bool]$RuntimeGuardResult.head_match
          $LiveRepoGuard = [string]$RuntimeGuardResult.live_repo_guard
          $CandidateProductionEnabled = [bool]$RuntimeGuardResult.candidate_production_enabled
          if ($CandidateProductionEnabled) {
            $SelfSelectionOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File $SelfInitiatedGoalSelectScriptPath -SessionRoot $SessionRootRelative -RunId $RunId -DutyId $LastSelfGrowthDutyId -TickNumber $TickCount -MacroCycleStage $LastMacroCycleStage -CandidateWorkspacePromotionEnabled 2>&1 | ForEach-Object { [string]$_ })
            if ($LASTEXITCODE -ne 0) {
              throw "PHASE160F_DAEMON_SELF_INITIATED_GOAL_SELECTION_FAILED exit=$LASTEXITCODE output=$($SelfSelectionOutput -join ' | ')"
            }
            $SelfSelectionResult = ($SelfSelectionOutput -join "`n") | ConvertFrom-Json
            $SelfInitiatedSelectionStatus = [string]$SelfSelectionResult.status
            if ($SelfSelectionResult.PSObject.Properties.Name -contains "self_initiated_goal_selected") {
              $SelfInitiatedGoalSelected = [bool]$SelfSelectionResult.self_initiated_goal_selected
            }
            if ($SelfSelectionResult.PSObject.Properties.Name -contains "selected_goal_id") {
              $SelectedUsefulGoal = [string]$SelfSelectionResult.selected_goal_id
            }
            Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
              event_type = "self_initiated_goal_selection_checked"
              source = "builder_daemon"
              duty_id = $LastSelfGrowthDutyId
              tick_number = $TickCount
              macro_cycle_stage = $LastMacroCycleStage
              status = $SelfInitiatedSelectionStatus
              self_initiated_goal_selected = $SelfInitiatedGoalSelected
              selected_useful_goal = $SelectedUsefulGoal
              occurred_at = (Get-Date).ToUniversalTime().ToString("o")
            })
            $CandidateWorkspaceOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File $CandidateWorkspaceScriptPath -SessionRoot $SessionRootRelative -RunId $RunId -DutyId $LastSelfGrowthDutyId -TickNumber $TickCount 2>&1 | ForEach-Object { [string]$_ })
            if ($LASTEXITCODE -ne 0) {
              throw "PHASE160E_DAEMON_CANDIDATE_WORKSPACE_STEP_FAILED exit=$LASTEXITCODE output=$($CandidateWorkspaceOutput -join ' | ')"
            }
            $CandidateWorkspaceResult = ($CandidateWorkspaceOutput -join "`n") | ConvertFrom-Json
            $CandidateWorkspaceResultStatus = [string]$CandidateWorkspaceResult.status
            if ($CandidateWorkspaceResult.PSObject.Properties.Name -contains "last_candidate_id") {
              $LastCandidateWorkspaceCandidateId = [string]$CandidateWorkspaceResult.last_candidate_id
            }
            Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
              event_type = "candidate_workspace_step_completed"
              source = "builder_daemon"
              duty_id = $LastSelfGrowthDutyId
              tick_number = $TickCount
              status = $CandidateWorkspaceResultStatus
              candidate_count = if ($CandidateWorkspaceResult.PSObject.Properties.Name -contains "candidate_count") { [int]$CandidateWorkspaceResult.candidate_count } else { 0 }
              ready_candidate_count = if ($CandidateWorkspaceResult.PSObject.Properties.Name -contains "ready_candidate_count") { [int]$CandidateWorkspaceResult.ready_candidate_count } else { 0 }
              last_candidate_id = $LastCandidateWorkspaceCandidateId
              promotion_bundle_status = if ($CandidateWorkspaceResult.PSObject.Properties.Name -contains "promotion_bundle_status") { [string]$CandidateWorkspaceResult.promotion_bundle_status } else { "NONE" }
              occurred_at = (Get-Date).ToUniversalTime().ToString("o")
            })
          } else {
            $CandidateWorkspaceResultStatus = "BLOCKED"
            Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
              event_type = "candidate_workspace_step_blocked_by_runtime_guard"
              source = "builder_daemon"
              duty_id = $LastSelfGrowthDutyId
              tick_number = $TickCount
              live_repo_guard = $LiveRepoGuard
              run_head = $RunHead
              current_head = $CurrentHead
              occurred_at = (Get-Date).ToUniversalTime().ToString("o")
            })
          }
        }
        $LiveTaskSnapshot = Get-Phase160DaemonLiveTaskSnapshot -SessionRootFull $SessionRootFull
        Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
          event_type = "self_growth_duty_completed"
          source = "builder_daemon"
          duty_id = $LastSelfGrowthDutyId
          duty_index = $SelfGrowthDutyCount
          tick_number = $TickCount
          selected_gap = $LastSelfGrowthGap
          macro_cycle_enabled = [bool]$MacroSelfGrowthEnabled
          cycle_id = $ActiveMacroCycleId
          cycle_stage = $LastMacroCycleStage
          status = $LastSelfGrowthStatus
          decision = $LastMacroDecision
          active_task_id = [string]$LiveTaskSnapshot.active_task_id
          active_plan_item_id = [string]$LiveTaskSnapshot.active_plan_item_id
          task_influenced_gap_selection = $LastTaskInfluencedGapSelection
          backlog_count = [int]$LiveTaskSnapshot.task_backlog_count
          consumed_count = [int]$LiveTaskSnapshot.teacher_consumed_count
          quarantine_count = [int]$LiveTaskSnapshot.teacher_quarantine_count
          run_head = [string]$LiveTaskSnapshot.run_head
          current_head = [string]$LiveTaskSnapshot.current_head
          head_match = [bool]$LiveTaskSnapshot.head_match
          live_repo_guard = [string]$LiveTaskSnapshot.live_repo_guard
          candidate_workspace_status = $CandidateWorkspaceResultStatus
          self_initiated_goal_selection_status = $SelfInitiatedSelectionStatus
          self_initiated_goal_selected = $SelfInitiatedGoalSelected
          selected_useful_goal = $SelectedUsefulGoal
          last_candidate_id = $LastCandidateWorkspaceCandidateId
          candidate_count = [int]$LiveTaskSnapshot.candidate_count
          promotion_bundle_status = [string]$LiveTaskSnapshot.promotion_bundle_status
          next_gap = $NextSelfGrowthGap
          occurred_at = (Get-Date).ToUniversalTime().ToString("o")
        })
      } catch {
        $LastSelfGrowthDutyId = $NextDutyId
        $LastSelfGrowthGap = $NextSelfGrowthGap
        $LastSelfGrowthStatus = "FAILED"
        $LastMacroDecision = "QUARANTINE_RESULT"
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
          macro_cycle_enabled = [bool]$MacroSelfGrowthEnabled
          cycle_id = $ActiveMacroCycleId
          cycle_stage = $LastMacroCycleStage
          error = $_.Exception.Message
          daemon_kept_alive = $true
          occurred_at = (Get-Date).ToUniversalTime().ToString("o")
        })
      }
    }

    $LiveTaskSnapshot = Get-Phase160DaemonLiveTaskSnapshot -SessionRootFull $SessionRootFull

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
      macro_cycle_enabled = [bool]$MacroSelfGrowthEnabled
      macro_cycle_id = $ActiveMacroCycleId
      last_macro_cycle_stage = $LastMacroCycleStage
      last_macro_decision = $LastMacroDecision
      candidate_workspace_promotion_enabled = [bool]$EnableCandidateWorkspacePromotion
      candidate_workspace_status = if ($EnableCandidateWorkspacePromotion) { [string]$LiveTaskSnapshot.candidate_workspace_status } else { "DISABLED" }
      self_initiated_goal_selected = [bool]$LiveTaskSnapshot.self_initiated_goal_selected
      selected_useful_goal = [string]$LiveTaskSnapshot.selected_useful_goal
      internal_active_task_created = [bool]$LiveTaskSnapshot.internal_active_task_created
      run_head = [string]$LiveTaskSnapshot.run_head
      current_head = [string]$LiveTaskSnapshot.current_head
      head_match = [bool]$LiveTaskSnapshot.head_match
      live_repo_guard = [string]$LiveTaskSnapshot.live_repo_guard
      candidate_count = [int]$LiveTaskSnapshot.candidate_count
      ready_candidate_count = [int]$LiveTaskSnapshot.ready_candidate_count
      quarantined_candidate_count = [int]$LiveTaskSnapshot.quarantined_candidate_count
      promotion_bundle_status = [string]$LiveTaskSnapshot.promotion_bundle_status
      active_task_status = [string]$LiveTaskSnapshot.active_task_status
      plan_pending_count = [int]$LiveTaskSnapshot.plan_pending_count
      plan_active_count = [int]$LiveTaskSnapshot.plan_active_count
      plan_waiting_promotion_count = [int]$LiveTaskSnapshot.plan_waiting_promotion_count
      last_candidate_id = [string]$LiveTaskSnapshot.last_candidate_id
      last_promotion_event = [string]$LiveTaskSnapshot.last_promotion_event
      restart_required_after_promotion = [bool]$LiveTaskSnapshot.restart_required_after_promotion
      teacher_inbox_count = [int]$LiveTaskSnapshot.teacher_inbox_count
      teacher_digest_count = [int]$LiveTaskSnapshot.teacher_digest_count
      teacher_consumed_count = [int]$LiveTaskSnapshot.teacher_consumed_count
      teacher_quarantine_count = [int]$LiveTaskSnapshot.teacher_quarantine_count
      task_backlog_count = [int]$LiveTaskSnapshot.task_backlog_count
      active_task_id = [string]$LiveTaskSnapshot.active_task_id
      active_plan_item_id = [string]$LiveTaskSnapshot.active_plan_item_id
      last_consumed_task = [string]$LiveTaskSnapshot.last_consumed_task
      last_task_influenced_gap_selection = $LastTaskInfluencedGapSelection
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
      macro_cycle_enabled = [bool]$MacroSelfGrowthEnabled
      macro_cycle_id = $ActiveMacroCycleId
      last_macro_cycle_stage = $LastMacroCycleStage
      last_macro_decision = $LastMacroDecision
      candidate_workspace_promotion_enabled = [bool]$EnableCandidateWorkspacePromotion
      candidate_workspace_status = if ($EnableCandidateWorkspacePromotion) { [string]$LiveTaskSnapshot.candidate_workspace_status } else { "DISABLED" }
      self_initiated_goal_selected = [bool]$LiveTaskSnapshot.self_initiated_goal_selected
      selected_useful_goal = [string]$LiveTaskSnapshot.selected_useful_goal
      internal_active_task_created = [bool]$LiveTaskSnapshot.internal_active_task_created
      run_head = [string]$LiveTaskSnapshot.run_head
      current_head = [string]$LiveTaskSnapshot.current_head
      head_match = [bool]$LiveTaskSnapshot.head_match
      live_repo_guard = [string]$LiveTaskSnapshot.live_repo_guard
      candidate_count = [int]$LiveTaskSnapshot.candidate_count
      ready_candidate_count = [int]$LiveTaskSnapshot.ready_candidate_count
      quarantined_candidate_count = [int]$LiveTaskSnapshot.quarantined_candidate_count
      promotion_bundle_status = [string]$LiveTaskSnapshot.promotion_bundle_status
      active_task_status = [string]$LiveTaskSnapshot.active_task_status
      plan_pending_count = [int]$LiveTaskSnapshot.plan_pending_count
      plan_active_count = [int]$LiveTaskSnapshot.plan_active_count
      plan_waiting_promotion_count = [int]$LiveTaskSnapshot.plan_waiting_promotion_count
      last_candidate_id = [string]$LiveTaskSnapshot.last_candidate_id
      last_promotion_event = [string]$LiveTaskSnapshot.last_promotion_event
      restart_required_after_promotion = [bool]$LiveTaskSnapshot.restart_required_after_promotion
      teacher_inbox_count = [int]$LiveTaskSnapshot.teacher_inbox_count
      teacher_digest_count = [int]$LiveTaskSnapshot.teacher_digest_count
      teacher_consumed_count = [int]$LiveTaskSnapshot.teacher_consumed_count
      teacher_quarantine_count = [int]$LiveTaskSnapshot.teacher_quarantine_count
      task_backlog_count = [int]$LiveTaskSnapshot.task_backlog_count
      active_task_id = [string]$LiveTaskSnapshot.active_task_id
      active_plan_item_id = [string]$LiveTaskSnapshot.active_plan_item_id
      last_consumed_task = [string]$LiveTaskSnapshot.last_consumed_task
      last_task_influenced_gap_selection = $LastTaskInfluencedGapSelection
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
      macro_cycle_enabled = [bool]$MacroSelfGrowthEnabled
      macro_cycle_id = $ActiveMacroCycleId
      last_macro_cycle_stage = $LastMacroCycleStage
      last_macro_decision = $LastMacroDecision
      candidate_workspace_promotion_enabled = [bool]$EnableCandidateWorkspacePromotion
      candidate_workspace_status = if ($EnableCandidateWorkspacePromotion) { [string]$LiveTaskSnapshot.candidate_workspace_status } else { "DISABLED" }
      self_initiated_goal_selected = [bool]$LiveTaskSnapshot.self_initiated_goal_selected
      selected_useful_goal = [string]$LiveTaskSnapshot.selected_useful_goal
      internal_active_task_created = [bool]$LiveTaskSnapshot.internal_active_task_created
      run_head = [string]$LiveTaskSnapshot.run_head
      current_head = [string]$LiveTaskSnapshot.current_head
      head_match = [bool]$LiveTaskSnapshot.head_match
      live_repo_guard = [string]$LiveTaskSnapshot.live_repo_guard
      candidate_count = [int]$LiveTaskSnapshot.candidate_count
      ready_candidate_count = [int]$LiveTaskSnapshot.ready_candidate_count
      quarantined_candidate_count = [int]$LiveTaskSnapshot.quarantined_candidate_count
      promotion_bundle_status = [string]$LiveTaskSnapshot.promotion_bundle_status
      active_task_status = [string]$LiveTaskSnapshot.active_task_status
      plan_pending_count = [int]$LiveTaskSnapshot.plan_pending_count
      plan_active_count = [int]$LiveTaskSnapshot.plan_active_count
      plan_waiting_promotion_count = [int]$LiveTaskSnapshot.plan_waiting_promotion_count
      last_candidate_id = [string]$LiveTaskSnapshot.last_candidate_id
      last_promotion_event = [string]$LiveTaskSnapshot.last_promotion_event
      restart_required_after_promotion = [bool]$LiveTaskSnapshot.restart_required_after_promotion
      teacher_inbox_count = [int]$LiveTaskSnapshot.teacher_inbox_count
      teacher_digest_count = [int]$LiveTaskSnapshot.teacher_digest_count
      teacher_consumed_count = [int]$LiveTaskSnapshot.teacher_consumed_count
      teacher_quarantine_count = [int]$LiveTaskSnapshot.teacher_quarantine_count
      task_backlog_count = [int]$LiveTaskSnapshot.task_backlog_count
      active_task_id = [string]$LiveTaskSnapshot.active_task_id
      active_plan_item_id = [string]$LiveTaskSnapshot.active_plan_item_id
      last_consumed_task = [string]$LiveTaskSnapshot.last_consumed_task
      last_task_influenced_gap_selection = $LastTaskInfluencedGapSelection
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
      macro_cycle_enabled = [bool]$MacroSelfGrowthEnabled
      macro_cycle_id = $ActiveMacroCycleId
      last_macro_cycle_stage = $LastMacroCycleStage
      last_macro_decision = $LastMacroDecision
      candidate_workspace_promotion_enabled = [bool]$EnableCandidateWorkspacePromotion
      candidate_workspace_status = if ($EnableCandidateWorkspacePromotion) { [string]$LiveTaskSnapshot.candidate_workspace_status } else { "DISABLED" }
      self_initiated_goal_selected = [bool]$LiveTaskSnapshot.self_initiated_goal_selected
      selected_useful_goal = [string]$LiveTaskSnapshot.selected_useful_goal
      internal_active_task_created = [bool]$LiveTaskSnapshot.internal_active_task_created
      run_head = [string]$LiveTaskSnapshot.run_head
      current_head = [string]$LiveTaskSnapshot.current_head
      head_match = [bool]$LiveTaskSnapshot.head_match
      live_repo_guard = [string]$LiveTaskSnapshot.live_repo_guard
      candidate_count = [int]$LiveTaskSnapshot.candidate_count
      ready_candidate_count = [int]$LiveTaskSnapshot.ready_candidate_count
      quarantined_candidate_count = [int]$LiveTaskSnapshot.quarantined_candidate_count
      promotion_bundle_status = [string]$LiveTaskSnapshot.promotion_bundle_status
      active_task_status = [string]$LiveTaskSnapshot.active_task_status
      plan_pending_count = [int]$LiveTaskSnapshot.plan_pending_count
      plan_active_count = [int]$LiveTaskSnapshot.plan_active_count
      plan_waiting_promotion_count = [int]$LiveTaskSnapshot.plan_waiting_promotion_count
      last_candidate_id = [string]$LiveTaskSnapshot.last_candidate_id
      last_promotion_event = [string]$LiveTaskSnapshot.last_promotion_event
      restart_required_after_promotion = [bool]$LiveTaskSnapshot.restart_required_after_promotion
      active_task_id = [string]$LiveTaskSnapshot.active_task_id
      active_plan_item_id = [string]$LiveTaskSnapshot.active_plan_item_id
      task_influenced_gap_selection = $LastTaskInfluencedGapSelection
      backlog_count = [int]$LiveTaskSnapshot.task_backlog_count
      consumed_count = [int]$LiveTaskSnapshot.teacher_consumed_count
      quarantine_count = [int]$LiveTaskSnapshot.teacher_quarantine_count
      duration_based_session = $true
      fixed_tick_batch_mode = $false
      occurred_at = $Now.ToUniversalTime().ToString("o")
    })

    if ($RunUntilStop) {
      Start-Sleep -Seconds $TickIntervalSeconds
    } else {
      $RemainingSeconds = [Math]::Floor(($EndTime - (Get-Date)).TotalSeconds)
      if ($RemainingSeconds -le 0) {
        break
      }
      Start-Sleep -Seconds ([Math]::Max(1, [Math]::Min($TickIntervalSeconds, $RemainingSeconds)))
    }
  }

  $StoppedAt = (Get-Date).ToUniversalTime().ToString("o")
  $FinalStatus = if ($StopReason -eq "duration_limit") { "COMPLETED" } elseif ($StopReason -eq "stop_flag") { "STOPPED" } else { "STOPPED" }
  if ($EnableCandidateWorkspacePromotion) {
    $FinalPromotionOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File $PromotionFinalizeScriptPath -SessionRoot $SessionRootRelative -RunId $RunId -WriteFinalHandoff 2>&1 | ForEach-Object { [string]$_ })
    if ($LASTEXITCODE -ne 0) {
      throw "PHASE160E_DAEMON_FINAL_PROMOTION_BUNDLE_FAILED exit=$LASTEXITCODE output=$($FinalPromotionOutput -join ' | ')"
    }
    Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
      event_type = "final_promotion_bundle_written"
      source = "builder_daemon"
      stop_reason = $StopReason
      occurred_at = (Get-Date).ToUniversalTime().ToString("o")
    })
  }
  $LiveTaskSnapshot = Get-Phase160DaemonLiveTaskSnapshot -SessionRootFull $SessionRootFull
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
      macro_cycle_enabled = [bool]$MacroSelfGrowthEnabled
      macro_cycle_id = $ActiveMacroCycleId
      last_macro_cycle_stage = $LastMacroCycleStage
      last_macro_decision = $LastMacroDecision
      candidate_workspace_promotion_enabled = [bool]$EnableCandidateWorkspacePromotion
      candidate_workspace_status = if ($EnableCandidateWorkspacePromotion) { [string]$LiveTaskSnapshot.candidate_workspace_status } else { "DISABLED" }
      self_initiated_goal_selected = [bool]$LiveTaskSnapshot.self_initiated_goal_selected
      selected_useful_goal = [string]$LiveTaskSnapshot.selected_useful_goal
      internal_active_task_created = [bool]$LiveTaskSnapshot.internal_active_task_created
      run_head = [string]$LiveTaskSnapshot.run_head
      current_head = [string]$LiveTaskSnapshot.current_head
      head_match = [bool]$LiveTaskSnapshot.head_match
      live_repo_guard = [string]$LiveTaskSnapshot.live_repo_guard
      candidate_count = [int]$LiveTaskSnapshot.candidate_count
      ready_candidate_count = [int]$LiveTaskSnapshot.ready_candidate_count
      quarantined_candidate_count = [int]$LiveTaskSnapshot.quarantined_candidate_count
      promotion_bundle_status = [string]$LiveTaskSnapshot.promotion_bundle_status
      active_task_status = [string]$LiveTaskSnapshot.active_task_status
      plan_pending_count = [int]$LiveTaskSnapshot.plan_pending_count
      plan_active_count = [int]$LiveTaskSnapshot.plan_active_count
      plan_waiting_promotion_count = [int]$LiveTaskSnapshot.plan_waiting_promotion_count
      last_candidate_id = [string]$LiveTaskSnapshot.last_candidate_id
      last_promotion_event = [string]$LiveTaskSnapshot.last_promotion_event
      restart_required_after_promotion = [bool]$LiveTaskSnapshot.restart_required_after_promotion
      teacher_inbox_count = [int]$LiveTaskSnapshot.teacher_inbox_count
      teacher_digest_count = [int]$LiveTaskSnapshot.teacher_digest_count
    teacher_consumed_count = [int]$LiveTaskSnapshot.teacher_consumed_count
    teacher_quarantine_count = [int]$LiveTaskSnapshot.teacher_quarantine_count
    task_backlog_count = [int]$LiveTaskSnapshot.task_backlog_count
    active_task_id = [string]$LiveTaskSnapshot.active_task_id
    active_plan_item_id = [string]$LiveTaskSnapshot.active_plan_item_id
    last_consumed_task = [string]$LiveTaskSnapshot.last_consumed_task
    last_task_influenced_gap_selection = $LastTaskInfluencedGapSelection
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
    run_until_stop = [bool]$RunUntilStop
    fixed_tick_batch_mode = $false
    daemon_can_run_until_stop_flag = $true
    stop_flag_supported = $true
    self_growth_enabled = [bool]$EnableSelfGrowthDuty
    self_growth_duty_count = $SelfGrowthDutyCount
      macro_cycle_enabled = [bool]$MacroSelfGrowthEnabled
      macro_cycle_id = $ActiveMacroCycleId
      last_macro_cycle_stage = $LastMacroCycleStage
      last_macro_decision = $LastMacroDecision
      candidate_workspace_promotion_enabled = [bool]$EnableCandidateWorkspacePromotion
      candidate_workspace_status = if ($EnableCandidateWorkspacePromotion) { [string]$LiveTaskSnapshot.candidate_workspace_status } else { "DISABLED" }
      self_initiated_goal_selected = [bool]$LiveTaskSnapshot.self_initiated_goal_selected
      selected_useful_goal = [string]$LiveTaskSnapshot.selected_useful_goal
      internal_active_task_created = [bool]$LiveTaskSnapshot.internal_active_task_created
      run_head = [string]$LiveTaskSnapshot.run_head
      current_head = [string]$LiveTaskSnapshot.current_head
      head_match = [bool]$LiveTaskSnapshot.head_match
      live_repo_guard = [string]$LiveTaskSnapshot.live_repo_guard
      candidate_count = [int]$LiveTaskSnapshot.candidate_count
      ready_candidate_count = [int]$LiveTaskSnapshot.ready_candidate_count
      quarantined_candidate_count = [int]$LiveTaskSnapshot.quarantined_candidate_count
      promotion_bundle_status = [string]$LiveTaskSnapshot.promotion_bundle_status
      active_task_status = [string]$LiveTaskSnapshot.active_task_status
      plan_pending_count = [int]$LiveTaskSnapshot.plan_pending_count
      plan_active_count = [int]$LiveTaskSnapshot.plan_active_count
      plan_waiting_promotion_count = [int]$LiveTaskSnapshot.plan_waiting_promotion_count
      last_candidate_id = [string]$LiveTaskSnapshot.last_candidate_id
      last_promotion_event = [string]$LiveTaskSnapshot.last_promotion_event
      restart_required_after_promotion = [bool]$LiveTaskSnapshot.restart_required_after_promotion
      teacher_inbox_count = [int]$LiveTaskSnapshot.teacher_inbox_count
      teacher_digest_count = [int]$LiveTaskSnapshot.teacher_digest_count
    teacher_consumed_count = [int]$LiveTaskSnapshot.teacher_consumed_count
    teacher_quarantine_count = [int]$LiveTaskSnapshot.teacher_quarantine_count
    task_backlog_count = [int]$LiveTaskSnapshot.task_backlog_count
    active_task_id = [string]$LiveTaskSnapshot.active_task_id
    active_plan_item_id = [string]$LiveTaskSnapshot.active_plan_item_id
    last_consumed_task = [string]$LiveTaskSnapshot.last_consumed_task
    last_task_influenced_gap_selection = $LastTaskInfluencedGapSelection
  }
  Write-Phase160DaemonJsonFile -Path $HeartbeatPath -Object $FinalHeartbeat

  $FinalStateRecord = [ordered]@{
    status = $FinalStatus
    final_tick = $TickCount
    final_heartbeat_count = $TickCount
    final_self_growth_duty_count = $SelfGrowthDutyCount
    stop_flag_seen = $StopFlagSeen
    process_exit_reason = $StopReason
    macro_cycle_enabled = [bool]$MacroSelfGrowthEnabled
    macro_cycle_id = $ActiveMacroCycleId
      last_macro_cycle_stage = $LastMacroCycleStage
      last_macro_decision = $LastMacroDecision
      candidate_workspace_promotion_enabled = [bool]$EnableCandidateWorkspacePromotion
      candidate_workspace_status = if ($EnableCandidateWorkspacePromotion) { [string]$LiveTaskSnapshot.candidate_workspace_status } else { "DISABLED" }
      self_initiated_goal_selected = [bool]$LiveTaskSnapshot.self_initiated_goal_selected
      selected_useful_goal = [string]$LiveTaskSnapshot.selected_useful_goal
      internal_active_task_created = [bool]$LiveTaskSnapshot.internal_active_task_created
      run_head = [string]$LiveTaskSnapshot.run_head
    current_head = [string]$LiveTaskSnapshot.current_head
    head_match = [bool]$LiveTaskSnapshot.head_match
    live_repo_guard = [string]$LiveTaskSnapshot.live_repo_guard
    candidate_count = [int]$LiveTaskSnapshot.candidate_count
    ready_candidate_count = [int]$LiveTaskSnapshot.ready_candidate_count
    quarantined_candidate_count = [int]$LiveTaskSnapshot.quarantined_candidate_count
    promotion_bundle_status = [string]$LiveTaskSnapshot.promotion_bundle_status
    active_task_status = [string]$LiveTaskSnapshot.active_task_status
    plan_pending_count = [int]$LiveTaskSnapshot.plan_pending_count
    plan_active_count = [int]$LiveTaskSnapshot.plan_active_count
    plan_waiting_promotion_count = [int]$LiveTaskSnapshot.plan_waiting_promotion_count
    last_candidate_id = [string]$LiveTaskSnapshot.last_candidate_id
    last_promotion_event = [string]$LiveTaskSnapshot.last_promotion_event
    restart_required_after_promotion = [bool]$LiveTaskSnapshot.restart_required_after_promotion
    last_self_growth_duty_id = $LastSelfGrowthDutyId
    last_self_growth_gap = $LastSelfGrowthGap
    last_self_growth_status = $LastSelfGrowthStatus
    teacher_inbox_count = [int]$LiveTaskSnapshot.teacher_inbox_count
    teacher_digest_count = [int]$LiveTaskSnapshot.teacher_digest_count
    teacher_consumed_count = [int]$LiveTaskSnapshot.teacher_consumed_count
    teacher_quarantine_count = [int]$LiveTaskSnapshot.teacher_quarantine_count
    task_backlog_count = [int]$LiveTaskSnapshot.task_backlog_count
    active_task_id = [string]$LiveTaskSnapshot.active_task_id
    active_plan_item_id = [string]$LiveTaskSnapshot.active_plan_item_id
    last_consumed_task = [string]$LiveTaskSnapshot.last_consumed_task
    last_task_influenced_gap_selection = $LastTaskInfluencedGapSelection
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    next_recommended_action = if ($MacroSelfGrowthEnabled) { "review_macro_cycle_summary_and_prepare_owner_supervised_macro_run" } else { "review_live_session_summary" }
    finalized_at = $StoppedAt
  }
  Write-Phase160DaemonJsonFile -Path $FinalStatePath -Object $FinalStateRecord

  Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
    event_type = "daemon_stopped"
    source = "builder_daemon"
    stop_reason = $StopReason
    tick_count = $TickCount
    live_session_safe_stop = $true
    occurred_at = $StoppedAt
  })
  Add-Phase160DaemonJsonLine -Path $EventLogPath -Object ([ordered]@{
    event_type = "final_state_written"
    source = "builder_daemon"
    final_state_path = "$SessionRootRelative/final_state.json"
    status = $FinalStatus
    stop_flag_seen = $StopFlagSeen
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
    duration_based_session = $true
    run_until_stop = [bool]$RunUntilStop
    fixed_tick_batch_mode = $false
    tick_count = $TickCount
    self_growth_enabled = [bool]$EnableSelfGrowthDuty
    self_growth_duty_count = $SelfGrowthDutyCount
    last_self_growth_duty_id = $LastSelfGrowthDutyId
    last_self_growth_gap = $LastSelfGrowthGap
    last_self_growth_status = $LastSelfGrowthStatus
    next_self_growth_gap = $NextSelfGrowthGap
    macro_cycle_enabled = [bool]$MacroSelfGrowthEnabled
    macro_cycle_id = $ActiveMacroCycleId
    last_macro_cycle_stage = $LastMacroCycleStage
    last_macro_decision = $LastMacroDecision
    candidate_workspace_promotion_enabled = [bool]$EnableCandidateWorkspacePromotion
    candidate_workspace_status = if ($EnableCandidateWorkspacePromotion) { [string]$LiveTaskSnapshot.candidate_workspace_status } else { "DISABLED" }
    self_initiated_goal_selected = [bool]$LiveTaskSnapshot.self_initiated_goal_selected
    selected_useful_goal = [string]$LiveTaskSnapshot.selected_useful_goal
    internal_active_task_created = [bool]$LiveTaskSnapshot.internal_active_task_created
    run_head = [string]$LiveTaskSnapshot.run_head
    current_head = [string]$LiveTaskSnapshot.current_head
    head_match = [bool]$LiveTaskSnapshot.head_match
    live_repo_guard = [string]$LiveTaskSnapshot.live_repo_guard
    candidate_count = [int]$LiveTaskSnapshot.candidate_count
    ready_candidate_count = [int]$LiveTaskSnapshot.ready_candidate_count
    quarantined_candidate_count = [int]$LiveTaskSnapshot.quarantined_candidate_count
    promotion_bundle_status = [string]$LiveTaskSnapshot.promotion_bundle_status
    active_task_status = [string]$LiveTaskSnapshot.active_task_status
    plan_pending_count = [int]$LiveTaskSnapshot.plan_pending_count
    plan_active_count = [int]$LiveTaskSnapshot.plan_active_count
    plan_waiting_promotion_count = [int]$LiveTaskSnapshot.plan_waiting_promotion_count
    last_candidate_id = [string]$LiveTaskSnapshot.last_candidate_id
    last_promotion_event = [string]$LiveTaskSnapshot.last_promotion_event
    restart_required_after_promotion = [bool]$LiveTaskSnapshot.restart_required_after_promotion
    teacher_inbox_count = [int]$LiveTaskSnapshot.teacher_inbox_count
    teacher_digest_count = [int]$LiveTaskSnapshot.teacher_digest_count
    teacher_consumed_count = [int]$LiveTaskSnapshot.teacher_consumed_count
    teacher_quarantine_count = [int]$LiveTaskSnapshot.teacher_quarantine_count
    task_backlog_count = [int]$LiveTaskSnapshot.task_backlog_count
    active_task_id = [string]$LiveTaskSnapshot.active_task_id
    active_plan_item_id = [string]$LiveTaskSnapshot.active_plan_item_id
    last_consumed_task = [string]$LiveTaskSnapshot.last_consumed_task
    last_task_influenced_gap_selection = $LastTaskInfluencedGapSelection
    heartbeat_written = (Test-Path -LiteralPath $HeartbeatPath)
    event_log_created = (Test-Path -LiteralPath $EventLogPath)
    final_state_written = (Test-Path -LiteralPath $FinalStatePath)
    stop_reason = $StopReason
    live_session_safe_stop = $true
  } | ConvertTo-Json -Depth 20
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
