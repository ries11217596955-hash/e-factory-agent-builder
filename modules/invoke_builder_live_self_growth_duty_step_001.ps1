param(
  [string]$SessionRoot = "runtime_sessions/live_growth/PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_SMOKE_001",
  [int]$TickNumber = 0,
  [int]$DutyIndex = 1,
  [string]$DutyRoot = "",
  [string]$TeacherOutboxDir = "",
  [int]$MaxCandidateBytes = 8192,
  [switch]$DryRun,
  [switch]$EnableMacroCycle,
  [string]$MacroCycleId = ""
)

$ErrorActionPreference = "Stop"

foreach ($phase160JModule in @(
  "normalize_builder_owner_live_task_001.ps1",
  "classify_builder_owner_live_task_safety_001.ps1",
  "enqueue_builder_owner_task_backlog_001.ps1",
  "promote_builder_backlog_task_to_active_001.ps1",
  "inspect_builder_owner_task_lifecycle_state_001.ps1"
)) {
  . (Join-Path $PSScriptRoot $phase160JModule)
}

function Normalize-Phase160DutyFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160DutyRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160_SELF_GROWTH_DUTY_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160DutyFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160DutyPath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function ConvertTo-Phase160DutyRelativePath {
  param([string]$RepoRoot, [string]$FullPath)
  $normalizedRoot = Normalize-Phase160DutyFullPath -Path $RepoRoot
  $normalizedPath = Normalize-Phase160DutyFullPath -Path $FullPath
  if ($normalizedPath -eq $normalizedRoot) {
    return "."
  }
  if (-not $normalizedPath.StartsWith($normalizedRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160_SELF_GROWTH_DUTY_PATH_OUTSIDE_REPO=$FullPath"
  }
  return ($normalizedPath.Substring($normalizedRoot.Length + 1) -replace "\\", "/")
}

function Write-Phase160DutyJsonFile {
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

function Add-Phase160DutyJsonLine {
  param([string]$Path, [object]$Object)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $line = $Object | ConvertTo-Json -Depth 100 -Compress
  [System.IO.File]::AppendAllText($Path, "$line`n", [System.Text.UTF8Encoding]::new($false))
}

function Read-Phase160DutyJsonSafe {
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

function Read-Phase160DutyJsonSummarySafe {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160DutyPath -RepoRoot $RepoRoot -Path $Path
  $artifact = Read-Phase160DutyJsonSafe -Path $fullPath
  if ($null -eq $artifact) {
    return [ordered]@{
      path = $Path
      present = $false
    }
  }
  return [ordered]@{
    path = $Path
    present = $true
    status = [string]$artifact.status
    step_id = [string]$artifact.step_id
    repair_id = [string]$artifact.repair_id
    run_id = [string]$artifact.run_id
    next_allowed_step = [string]$artifact.next_allowed_step
    next_action = [string]$artifact.next_action
  }
}

function Assert-Phase160DutyEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160_SELF_GROWTH_DUTY_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Get-Phase160DutyRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160_SELF_GROWTH_DUTY_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Get-Phase160DutyGapForIndex {
  param([int]$Index)
  $curriculum = @(
    "SELF_MAP_REFRESH_GAP",
    "CAPABILITY_INVENTORY_REFRESH_GAP",
    "TEACHER_CHANNEL_READINESS_GAP",
    "BLOCKER_CHANNEL_READINESS_GAP",
    "SELF_GROWTH_RESULT_SUMMARY_GAP",
    "NEXT_SELF_GROWTH_GOAL_SELECTION_GAP"
  )
  if ($Index -lt 1) {
    throw "PHASE160_SELF_GROWTH_DUTY_INVALID_INDEX=$Index"
  }
  return $curriculum[(($Index - 1) % $curriculum.Count)]
}

function Get-Phase160DutyMacroStageForIndex {
  param([int]$Index)
  $stages = @(
    "SELF_OBSERVE_MAP_REFRESH",
    "CAPABILITY_INVENTORY_DIFF",
    "GAP_RANK_AND_SELECT",
    "SELF_CHANGE_CANDIDATE_GENERATE",
    "SANDBOX_DRY_RUN",
    "VALIDATE_AND_DECIDE",
    "EXPERIENCE_ABSORB_AND_NEXT_GOAL"
  )
  if ($Index -lt 1) {
    throw "PHASE160B_MACRO_DUTY_INVALID_INDEX=$Index"
  }
  return $stages[(($Index - 1) % $stages.Count)]
}

function Get-Phase160DutyMacroGapForStage {
  param([string]$Stage)
  switch ($Stage) {
    "SELF_OBSERVE_MAP_REFRESH" { return "MACRO_SELF_OBSERVE_MAP_REFRESH_GAP" }
    "CAPABILITY_INVENTORY_DIFF" { return "MACRO_CAPABILITY_INVENTORY_DIFF_GAP" }
    "GAP_RANK_AND_SELECT" { return "MACRO_GAP_RANK_AND_SELECT_GAP" }
    "SELF_CHANGE_CANDIDATE_GENERATE" { return "MACRO_SELF_CHANGE_CANDIDATE_GENERATE_GAP" }
    "SANDBOX_DRY_RUN" { return "MACRO_SANDBOX_DRY_RUN_GAP" }
    "VALIDATE_AND_DECIDE" { return "MACRO_VALIDATE_AND_DECIDE_GAP" }
    "EXPERIENCE_ABSORB_AND_NEXT_GOAL" { return "MACRO_EXPERIENCE_ABSORB_AND_NEXT_GOAL_GAP" }
    default { throw "PHASE160B_MACRO_STAGE_UNKNOWN=$Stage" }
  }
}

function Get-Phase160DutyMacroNoveltyReason {
  param([string]$Stage)
  switch ($Stage) {
    "SELF_OBSERVE_MAP_REFRESH" { return "Starts the macro cycle by grounding the session in current runtime evidence instead of repeating a gap label." }
    "CAPABILITY_INVENTORY_DIFF" { return "Consumes the self-map and compares available session capabilities against the observed runtime contour." }
    "GAP_RANK_AND_SELECT" { return "Consumes the capability diff and ranks a next gap with an explicit selection reason." }
    "SELF_CHANGE_CANDIDATE_GENERATE" { return "Consumes the ranked gap and produces a bounded session-local change candidate." }
    "SANDBOX_DRY_RUN" { return "Consumes the candidate and exercises it as a dry-run artifact without executing generated code." }
    "VALIDATE_AND_DECIDE" { return "Consumes the dry-run and records a keep/quarantine/rollback decision." }
    "EXPERIENCE_ABSORB_AND_NEXT_GOAL" { return "Consumes the decision and writes an experience ledger entry plus a non-repeated next goal." }
    default { return "Macro stage advances the chain with a new artifact." }
  }
}

function Get-Phase160DutyMacroProgressClaim {
  param([string]$Stage)
  switch ($Stage) {
    "SELF_OBSERVE_MAP_REFRESH" { return "Session has a refreshed macro self-map input for the next duty." }
    "CAPABILITY_INVENTORY_DIFF" { return "Session has a diff between observed needs and current live capabilities." }
    "GAP_RANK_AND_SELECT" { return "Session has a ranked gap and selection reason." }
    "SELF_CHANGE_CANDIDATE_GENERATE" { return "Session has a bounded self-change candidate kept local." }
    "SANDBOX_DRY_RUN" { return "Session has a dry-run result without arbitrary code execution." }
    "VALIDATE_AND_DECIDE" { return "Session has a validation decision for the candidate." }
    "EXPERIENCE_ABSORB_AND_NEXT_GOAL" { return "Session has absorbed experience and selected a non-repeated next goal." }
    default { return "Session macro chain advanced." }
  }
}

function Get-Phase160DutyMacroDecision {
  param([bool]$ValidationPassed)
  if ($ValidationPassed) {
    return "KEEP_SESSION_LOCAL"
  }
  return "QUARANTINE_RESULT"
}

function Test-Phase160DutyTeacherInterventionValid {
  param([object]$Intervention)
  if ($null -eq $Intervention) {
    return $false
  }
  return (
    -not [string]::IsNullOrWhiteSpace([string]$Intervention.intervention_id) -and
    -not [string]::IsNullOrWhiteSpace([string]$Intervention.message_type) -and
    -not [string]::IsNullOrWhiteSpace([string]$Intervention.requested_action) -and
    (@("teacher_instruction", "teacher_correction", "teacher_stop_request", "observer_suggestion") -contains [string]$Intervention.message_type)
  )
}

function Get-Phase160DutyObjectProperty {
  param([object]$Object, [string]$Name, [object]$Default = $null)
  if ($null -eq $Object) {
    return $Default
  }
  if ($Object.PSObject.Properties.Name -contains $Name) {
    return $Object.$Name
  }
  return $Default
}

function Get-Phase160DutyStringProperty {
  param([object]$Object, [string]$Name, [string]$Default = "")
  $value = Get-Phase160DutyObjectProperty -Object $Object -Name $Name -Default $Default
  if ($null -eq $value) {
    return $Default
  }
  return [string]$value
}

function Get-Phase160DutyTaskSafetyFlag {
  param([object]$Task, [string]$Name)
  $rules = Get-Phase160DutyObjectProperty -Object $Task -Name "safety_rules" -Default $null
  if ($null -ne $rules -and $rules.PSObject.Properties.Name -contains $Name) {
    return $rules.$Name
  }
  if ($Task.PSObject.Properties.Name -contains $Name) {
    return $Task.$Name
  }
  return $null
}

function Test-Phase160DutyTaskSafetyAllowed {
  param([object]$Task)
  if ($null -eq $Task) {
    return $false
  }
  $requiredFalse = @(
    "accepted_state_mutation_allowed",
    "accepted_memory_mutation_allowed",
    "accepted_self_model_mutation_allowed",
    "repo_commit_allowed"
  )
  foreach ($flag in $requiredFalse) {
    $value = Get-Phase160DutyTaskSafetyFlag -Task $Task -Name $flag
    if ($null -eq $value -or [bool]$value -ne $false) {
      return $false
    }
  }
  $runtimeOnly = Get-Phase160DutyTaskSafetyFlag -Task $Task -Name "runtime_session_only"
  return ($null -ne $runtimeOnly -and [bool]$runtimeOnly -eq $true)
}

function Test-Phase160DutyTaskEnvelopeValid {
  param([object]$Task)
  if ($null -eq $Task) {
    return $false
  }
  if ((Get-Phase160DutyStringProperty -Object $Task -Name "event_type") -ne "owner_live_task_injection") {
    return $false
  }
  foreach ($required in @("task_id", "source", "priority", "owner_goal", "desired_next_gap")) {
    if ([string]::IsNullOrWhiteSpace((Get-Phase160DutyStringProperty -Object $Task -Name $required))) {
      return $false
    }
  }
  return $true
}

function ConvertTo-Phase160DutySafeLeaf {
  param([string]$Value)
  $leaf = if ([string]::IsNullOrWhiteSpace($Value)) { "UNKNOWN" } else { $Value }
  $leaf = $leaf -replace '[^A-Za-z0-9_.-]', '_'
  if ($leaf.Length -gt 80) {
    $leaf = $leaf.Substring(0, 80)
  }
  return $leaf
}

function Get-Phase160DutyContentHash {
  param([string]$Content)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    return ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace "-", "").ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function Get-Phase160DutyPriorityRank {
  param([string]$Priority)
  switch ($Priority.ToLowerInvariant()) {
    "high" { return 3 }
    "normal" { return 2 }
    "low" { return 1 }
    default { return 0 }
  }
}

function Get-Phase160DutySourceRank {
  param([string]$Source)
  switch ($Source.ToLowerInvariant()) {
    "owner" { return 3 }
    "observer" { return 2 }
    "system" { return 1 }
    default { return 0 }
  }
}

function Get-Phase160DutyCreatedAtUtc {
  param([object]$Task, [datetime]$Fallback)
  $createdAt = Get-Phase160DutyStringProperty -Object $Task -Name "created_at"
  if (-not [string]::IsNullOrWhiteSpace($createdAt)) {
    try {
      return ([datetime]$createdAt).ToUniversalTime().ToString("o")
    } catch {
      return $Fallback.ToUniversalTime().ToString("o")
    }
  }
  return $Fallback.ToUniversalTime().ToString("o")
}

function Move-Phase160DutyFileUnique {
  param([string]$SourcePath, [string]$DestinationDirectory, [string]$Prefix = "")
  New-Item -ItemType Directory -Force -Path $DestinationDirectory | Out-Null
  $name = [System.IO.Path]::GetFileName($SourcePath)
  if (-not [string]::IsNullOrWhiteSpace($Prefix)) {
    $name = "$Prefix$name"
  }
  $target = Join-Path $DestinationDirectory $name
  $base = [System.IO.Path]::GetFileNameWithoutExtension($name)
  $extension = [System.IO.Path]::GetExtension($name)
  $index = 1
  while (Test-Path -LiteralPath $target) {
    $target = Join-Path $DestinationDirectory ("{0}_{1:d4}{2}" -f $base, $index, $extension)
    $index += 1
  }
  Move-Item -LiteralPath $SourcePath -Destination $target
  return $target
}

function Get-Phase160DutyUniqueFilePath {
  param([string]$Directory, [string]$Name)
  New-Item -ItemType Directory -Force -Path $Directory | Out-Null
  $target = Join-Path $Directory $Name
  $base = [System.IO.Path]::GetFileNameWithoutExtension($Name)
  $extension = [System.IO.Path]::GetExtension($Name)
  $index = 1
  while (Test-Path -LiteralPath $target) {
    $target = Join-Path $Directory ("{0}_{1:d4}{2}" -f $base, $index, $extension)
    $index += 1
  }
  return $target
}

function Get-Phase160DutyJsonFileCount {
  param([string]$Directory)
  if (-not (Test-Path -LiteralPath $Directory)) {
    return 0
  }
  return @(Get-ChildItem -LiteralPath $Directory -File -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" }).Count
}

function Get-Phase160DutyLatestJson {
  param([string]$Directory, [string]$Pattern = "*.json")
  if (-not (Test-Path -LiteralPath $Directory)) {
    return $null
  }
  $files = @(Get-ChildItem -LiteralPath $Directory -File -Filter $Pattern -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" } | Sort-Object LastWriteTimeUtc, Name)
  if ($files.Count -lt 1) {
    return $null
  }
  return $files[-1]
}

function Read-Phase160DutyActiveTask {
  param([string]$SessionRootFull)
  return Read-Phase160DutyJsonSafe -Path (Join-Path $SessionRootFull "active_task/active_task.json")
}

function Read-Phase160DutyActivePlanItem {
  param([string]$SessionRootFull)
  return Read-Phase160DutyJsonSafe -Path (Join-Path $SessionRootFull "active_task/active_plan_item.json")
}

function Get-Phase160DutyDesiredMacroGap {
  param([object]$Task)
  if ($null -eq $Task) {
    return "NONE"
  }
  $desired = Get-Phase160DutyStringProperty -Object $Task -Name "desired_next_gap"
  $goal = Get-Phase160DutyStringProperty -Object $Task -Name "owner_goal"
  if ($desired -match "EXPERIENCE_ABSORPTION_GATE" -or $goal -match "Experience Absorption Gate") {
    return "MACRO_EXPERIENCE_ABSORPTION_GATE_GAP"
  }
  if ([string]::IsNullOrWhiteSpace($desired)) {
    return "NONE"
  }
  if ($desired.StartsWith("MACRO_", [System.StringComparison]::OrdinalIgnoreCase)) {
    return $desired
  }
  return "MACRO_$desired"
}

function Get-Phase160DutyLiveTaskCounts {
  param([string]$SessionRootFull)
  $activeTask = Read-Phase160DutyActiveTask -SessionRootFull $SessionRootFull
  $activePlanItem = Read-Phase160DutyActivePlanItem -SessionRootFull $SessionRootFull
  $latestConsumed = Get-Phase160DutyLatestJson -Directory (Join-Path $SessionRootFull "teacher_consumed") -Pattern "receipt_*.json"
  $latestConsumedRecord = if ($null -ne $latestConsumed) { Read-Phase160DutyJsonSafe -Path $latestConsumed.FullName } else { $null }
  return [ordered]@{
    teacher_inbox_count = Get-Phase160DutyJsonFileCount -Directory (Join-Path $SessionRootFull "teacher_inbox")
    teacher_digest_count = Get-Phase160DutyJsonFileCount -Directory (Join-Path $SessionRootFull "teacher_digest")
    teacher_consumed_count = @(Get-ChildItem -LiteralPath (Join-Path $SessionRootFull "teacher_consumed") -File -Filter "receipt_*.json" -ErrorAction SilentlyContinue).Count
    teacher_quarantine_count = @(Get-ChildItem -LiteralPath (Join-Path $SessionRootFull "teacher_quarantine") -File -Filter "quarantine_*.json" -ErrorAction SilentlyContinue).Count
    task_backlog_count = Get-Phase160DutyJsonFileCount -Directory (Join-Path $SessionRootFull "task_backlog")
    active_task_id = if ($null -ne $activeTask) { Get-Phase160DutyStringProperty -Object $activeTask -Name "task_id" -Default "NONE" } else { "NONE" }
    active_plan_item_id = if ($null -ne $activePlanItem) { Get-Phase160DutyStringProperty -Object $activePlanItem -Name "item_id" -Default "NONE" } else { "NONE" }
    last_consumed_task = if ($null -ne $latestConsumedRecord) { Get-Phase160DutyStringProperty -Object $latestConsumedRecord -Name "task_id" -Default "NONE" } else { "NONE" }
  }
}

function Invoke-Phase160DutyLiveTaskIntake {
  param(
    [string]$RepoRoot,
    [string]$SessionRootFull,
    [string]$SessionRootRelative,
    [string]$DutyId,
    [string]$EventLogPath
  )

  $teacherInbox = Join-Path $SessionRootFull "teacher_inbox"
  $teacherDigest = Join-Path $SessionRootFull "teacher_digest"
  $teacherConsumed = Join-Path $SessionRootFull "teacher_consumed"
  $teacherQuarantine = Join-Path $SessionRootFull "teacher_quarantine"
  $taskBacklog = Join-Path $SessionRootFull "task_backlog"
  $activeTaskDir = Join-Path $SessionRootFull "active_task"
  $planItemsRoot = Join-Path $SessionRootFull "plan_items"
  $ownerTaskLifecycleRoot = Join-Path $SessionRootFull "owner_task_lifecycle"
  $taskLifecycleRoot = Join-Path $SessionRootFull "task_lifecycle"
  foreach ($directory in @($teacherInbox, $teacherDigest, $teacherConsumed, $teacherQuarantine, $taskBacklog, $activeTaskDir, $planItemsRoot, $ownerTaskLifecycleRoot, $taskLifecycleRoot)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $rawFiles = @(Get-ChildItem -LiteralPath $teacherInbox -File -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" } | Sort-Object FullName)
  Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
    event_type = "live_task_inbox_scan_started"
    source = "builder_live_task_intake"
    duty_id = $DutyId
    inbox_count = $rawFiles.Count
    occurred_at = (Get-Date).ToUniversalTime().ToString("o")
  })

  $validCandidates = @()
  $seenTaskIds = @{}
  $seenHashes = @{}
  $detectedCount = 0
  $validatedCount = 0
  $deduplicatedCount = 0
  $digestCount = 0
  $consumedCount = 0
  $quarantineCount = 0
  $planSplitCount = 0
  $backlogCount = 0
  $activeSelected = $false

  foreach ($rawFile in $rawFiles) {
    $detectedCount += 1
    $rawText = Get-Content -LiteralPath $rawFile.FullName -Raw
    $contentHash = Get-Phase160DutyContentHash -Content $rawText
    $task = $null
    $parseError = $null
    try {
      $task = $rawText | ConvertFrom-Json
    } catch {
      $parseError = $_.Exception.Message
    }

    $taskId = if ($null -ne $task) { Get-Phase160DutyStringProperty -Object $task -Name "task_id" -Default ("UNPARSED_" + $contentHash.Substring(0, 12)) } else { "UNPARSED_" + $contentHash.Substring(0, 12) }
    $safeTaskId = ConvertTo-Phase160DutySafeLeaf -Value $taskId
    $source = if ($null -ne $task) { Get-Phase160DutyStringProperty -Object $task -Name "source" -Default "owner" } else { "owner" }
    if ([string]::IsNullOrWhiteSpace($source)) { $source = "owner" }
    $priority = if ($null -ne $task) { Get-Phase160DutyStringProperty -Object $task -Name "priority" -Default "normal" } else { "normal" }
    if ([string]::IsNullOrWhiteSpace($priority)) { $priority = "normal" }
    $createdAtUtc = if ($null -ne $task) { Get-Phase160DutyCreatedAtUtc -Task $task -Fallback $rawFile.LastWriteTimeUtc } else { $rawFile.LastWriteTimeUtc.ToUniversalTime().ToString("o") }

    Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
      event_type = "live_task_detected"
      source = "builder_live_task_intake"
      duty_id = $DutyId
      task_id = $taskId
      raw_file = $rawFile.Name
      content_hash = $contentHash
      priority = $priority
      task_source = $source
      occurred_at = (Get-Date).ToUniversalTime().ToString("o")
    })

    $existingActiveForDecision = Read-Phase160DutyActiveTask -SessionRootFull $SessionRootFull
    $existingActiveStateForDecision = Read-Phase160DutyJsonSafe -Path (Join-Path $taskLifecycleRoot "active_task_state.json")
    $existingActiveStatusForDecision = if ($null -ne $existingActiveStateForDecision -and $existingActiveStateForDecision.PSObject.Properties.Name -contains "status") { [string]$existingActiveStateForDecision.status } elseif ($null -ne $existingActiveForDecision) { "ACTIVE" } else { "NONE" }
    $normalizedTask = if ($null -ne $task) { ConvertTo-Phase160JOwnerLiveTaskNormalized -Task $task -ContentHash $contentHash -RawFileName $rawFile.Name -CreatedAtUtc $createdAtUtc } else { $null }
    $safetyDecision = Invoke-Phase160JOwnerTaskSafetyClassification -Task $task -NormalizedTask $normalizedTask -ParseError $parseError -ExistingActiveTask $existingActiveForDecision -ExistingActiveStatus $existingActiveStatusForDecision
    if ($null -ne $normalizedTask) {
      $normalizedTask.accepted_by_intake = [bool]$safetyDecision.accepted_by_intake
      $normalizedTask.quarantine_required = [bool]$safetyDecision.quarantine_required
      $normalizedTask.quarantine_reason = [string]$safetyDecision.quarantine_reason
      $normalizedTask.backlog_allowed = [bool]$safetyDecision.backlog_allowed
      $normalizedTask.active_allowed = [bool]$safetyDecision.active_allowed
    }
    Write-Phase160DutyJsonFile -Path (Join-Path $ownerTaskLifecycleRoot "last_owner_task_intake.json") -Object ([ordered]@{
      status = if ([bool]$safetyDecision.quarantine_required) { "QUARANTINED_OR_REJECTED" } else { "ACCEPTED_BY_INTAKE" }
      duty_id = $DutyId
      task_id = $taskId
      normalized_task_id = [string]$safetyDecision.normalized_task_id
      decision = [string]$safetyDecision.decision
      quarantine_reason = [string]$safetyDecision.quarantine_reason
      failed_fields = @($safetyDecision.failed_fields)
      backlog_status = "NONE"
      active_task_blocks_owner_task = [bool]$safetyDecision.active_task_blocks_owner_task
      blocked_by_active_task_id = [string]$safetyDecision.blocked_by_active_task_id
      blocked_by_status = [string]$safetyDecision.blocked_by_status
      owner_task_lost = $false
      updated_at = (Get-Date).ToUniversalTime().ToString("o")
    })
    Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
      event_type = "owner_task_intake_decision"
      source = "builder_live_task_intake"
      duty_id = $DutyId
      task_id = $taskId
      normalized_task_id = [string]$safetyDecision.normalized_task_id
      decision = [string]$safetyDecision.decision
      quarantine_reason = [string]$safetyDecision.quarantine_reason
      active_task_blocks_owner_task = [bool]$safetyDecision.active_task_blocks_owner_task
      blocked_by_active_task_id = [string]$safetyDecision.blocked_by_active_task_id
      occurred_at = (Get-Date).ToUniversalTime().ToString("o")
    })
    if ([bool]$safetyDecision.quarantine_required) {
      $reason = [string]$safetyDecision.quarantine_reason
      Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
        event_type = "live_task_validated"
        source = "builder_live_task_intake"
        duty_id = $DutyId
        task_id = $taskId
        valid = $false
        reason = $reason
        occurred_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      $quarantinePath = Get-Phase160DutyUniqueFilePath -Directory $teacherQuarantine -Name ("quarantine_{0}_{1}.json" -f $safeTaskId, $contentHash.Substring(0, 12))
      Write-Phase160DutyJsonFile -Path $quarantinePath -Object ([ordered]@{
        status = if ([string]$safetyDecision.decision -eq "REJECT_MALFORMED_TASK") { "REJECTED" } else { "QUARANTINED" }
        duty_id = $DutyId
        task_id = $taskId
        normalized_task_id = [string]$safetyDecision.normalized_task_id
        decision = [string]$safetyDecision.decision
        source_file = $rawFile.Name
        reason = $reason
        failed_fields = @($safetyDecision.failed_fields)
        normalized_task = $normalizedTask
        content_hash = $contentHash
        accepted_state_mutated = $false
        accepted_memory_mutated = $false
        accepted_self_model_mutated = $false
        repo_commit_performed = $false
        repo_push_performed = $false
        branch_switch_performed = $false
        protected_state_mutated = $false
        created_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      $movedRaw = Move-Phase160DutyFileUnique -SourcePath $rawFile.FullName -DestinationDirectory $teacherQuarantine -Prefix "raw_"
      $quarantineCount += 1
      Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
        event_type = "live_task_quarantined"
        source = "builder_live_task_intake"
        duty_id = $DutyId
        task_id = $taskId
        reason = $reason
        quarantine_path = (ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $quarantinePath)
        moved_raw_path = (ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $movedRaw)
        occurred_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      continue
    }

    $validatedCount += 1
    Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
      event_type = "live_task_validated"
      source = "builder_live_task_intake"
      duty_id = $DutyId
      task_id = $taskId
      valid = $true
      normalized_task_id = [string]$normalizedTask.normalized_task_id
      decision = [string]$safetyDecision.decision
      safety = "runtime_session_only"
      occurred_at = (Get-Date).ToUniversalTime().ToString("o")
    })

    $duplicateOf = "NONE"
    $isDuplicate = $false
    if ($seenTaskIds.ContainsKey($taskId)) {
      $duplicateOf = [string]$seenTaskIds[$taskId]
      $isDuplicate = $true
    } elseif ($seenHashes.ContainsKey($contentHash)) {
      $duplicateOf = [string]$seenHashes[$contentHash]
      $isDuplicate = $true
    }
    if (-not $seenTaskIds.ContainsKey($taskId)) {
      $seenTaskIds[$taskId] = $taskId
    }
    if (-not $seenHashes.ContainsKey($contentHash)) {
      $seenHashes[$contentHash] = $taskId
    }

    $digestPath = Get-Phase160DutyUniqueFilePath -Directory $teacherDigest -Name ("digest_{0}_{1}.json" -f $safeTaskId, $contentHash.Substring(0, 12))
    $planItems = @($normalizedTask.plan_items)
    $planSteps = @($planItems | ForEach-Object { [string]$_.description })
    $digestRecord = [ordered]@{
      status = if ($isDuplicate) { "DUPLICATE" } else { "VALID" }
      duty_id = $DutyId
      task_id = $taskId
      normalized_task_id = [string]$normalizedTask.normalized_task_id
      source = $source
      priority = $priority
      owner_goal = [string]$normalizedTask.owner_goal
      desired_next_gap = [string]$normalizedTask.desired_next_gap
      content_hash = $contentHash
      duplicate = $isDuplicate
      duplicate_of = $duplicateOf
      plan_step_count = $planSteps.Count
      plan_items = @($planItems)
      intake_decision = [string]$safetyDecision.decision
      raw_file_name = $rawFile.Name
      created_at = $createdAtUtc
      digested_at = (Get-Date).ToUniversalTime().ToString("o")
    }
    Write-Phase160DutyJsonFile -Path $digestPath -Object $digestRecord
    $digestCount += 1
    Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
      event_type = "live_task_digest_written"
      source = "builder_live_task_intake"
      duty_id = $DutyId
      task_id = $taskId
      teacher_digest_path = (ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $digestPath)
      content_hash = $contentHash
      duplicate = $isDuplicate
      occurred_at = (Get-Date).ToUniversalTime().ToString("o")
    })

    if ($isDuplicate) {
      $deduplicatedCount += 1
      Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
        event_type = "live_task_deduplicated"
        source = "builder_live_task_intake"
        duty_id = $DutyId
        task_id = $taskId
        duplicate_of = $duplicateOf
        content_hash = $contentHash
        occurred_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      $receiptPath = Get-Phase160DutyUniqueFilePath -Directory $teacherConsumed -Name ("receipt_duplicate_{0}_{1}.json" -f $safeTaskId, $contentHash.Substring(0, 12))
      Write-Phase160DutyJsonFile -Path $receiptPath -Object ([ordered]@{
        status = "CONSUMED_DUPLICATE"
        duty_id = $DutyId
        task_id = $taskId
        source_file = $rawFile.Name
        teacher_digest_path = (ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $digestPath)
        duplicate_of = $duplicateOf
        content_hash = $contentHash
        consumed_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      $movedRaw = Move-Phase160DutyFileUnique -SourcePath $rawFile.FullName -DestinationDirectory $teacherConsumed -Prefix "raw_"
      $consumedCount += 1
      Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
        event_type = "live_task_consumed"
        source = "builder_live_task_intake"
        duty_id = $DutyId
        task_id = $taskId
        consumed_receipt_path = (ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $receiptPath)
        moved_raw_path = (ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $movedRaw)
        duplicate = $true
        occurred_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      continue
    }

    $validCandidates += [pscustomobject][ordered]@{
      task = $task
      normalized_task = $normalizedTask
      intake_decision = [string]$safetyDecision.decision
      task_id = $taskId
      safe_task_id = $safeTaskId
      source = $source
      source_rank = Get-Phase160DutySourceRank -Source $source
      priority = $priority
      priority_rank = Get-Phase160DutyPriorityRank -Priority $priority
      owner_goal = [string]$normalizedTask.owner_goal
      desired_next_gap = [string]$normalizedTask.desired_next_gap
      content_hash = $contentHash
      created_at_utc = $createdAtUtc
      raw_file = $rawFile
      digest_path = $digestPath
      digest_relative_path = ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $digestPath
      plan_steps = $planSteps
      plan_items = @($planItems)
      can_parallelize = [bool](Get-Phase160DutyObjectProperty -Object $task -Name "can_parallelize" -Default $false)
      safety_rules = $normalizedTask.safety_profile
      success_signals = Get-Phase160DutyObjectProperty -Object $task -Name "success_signals" -Default @()
    }
  }

  $existingActive = Read-Phase160DutyActiveTask -SessionRootFull $SessionRootFull
  $sorted = @($validCandidates | Sort-Object `
    @{ Expression = { -[int]$_.priority_rank } }, `
    @{ Expression = { -[int]$_.source_rank } }, `
    @{ Expression = { [string]$_.created_at_utc } }, `
    @{ Expression = { [string]$_.task_id } }, `
    @{ Expression = { [string]$_.content_hash } })
  $selected = $null
  if ($null -eq $existingActive -and $sorted.Count -gt 0) {
    $selected = $sorted[0]
  }

  foreach ($candidate in $sorted) {
    $isActive = ($null -ne $selected -and [string]$candidate.task_id -eq [string]$selected.task_id -and [string]$candidate.content_hash -eq [string]$selected.content_hash)
    $planItemRecords = @()
    if ($candidate.plan_steps.Count -gt 0) {
      $taskPlanDir = Join-Path $planItemsRoot $candidate.safe_task_id
      New-Item -ItemType Directory -Force -Path $taskPlanDir | Out-Null
      $planDigestPath = Join-Path $taskPlanDir "plan_digest.json"
      Write-Phase160DutyJsonFile -Path $planDigestPath -Object ([ordered]@{
        status = "PASS"
        duty_id = $DutyId
        parent_task_id = $candidate.task_id
        plan_step_count = $candidate.plan_steps.Count
        teacher_digest_path = $candidate.digest_relative_path
        split_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      $planSplitCount += 1
      Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
        event_type = "live_task_plan_split"
        source = "builder_live_task_intake"
        duty_id = $DutyId
        task_id = $candidate.task_id
        plan_digest_path = (ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $planDigestPath)
        plan_item_count = $candidate.plan_steps.Count
        occurred_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      for ($i = 0; $i -lt $candidate.plan_steps.Count; $i += 1) {
        $description = [string]$candidate.plan_steps[$i]
        $itemId = "{0}_plan_item_{1:d3}" -f $candidate.safe_task_id, ($i + 1)
        $itemStatus = if ($isActive -and $i -eq 0) { "ACTIVE" } else { "PENDING" }
        $itemRecord = [ordered]@{
          item_id = $itemId
          parent_task_id = $candidate.task_id
          item_index = $i + 1
          description = $description
          status = $itemStatus
          dependency = if ($i -eq 0) { "NONE" } else { "{0}_plan_item_{1:d3}" -f $candidate.safe_task_id, $i }
          expected_artifact = "session_local_runtime_artifact"
          safety_boundary = "runtime_session_only_no_accepted_state_mutation"
          teacher_digest_path = $candidate.digest_relative_path
          created_at = (Get-Date).ToUniversalTime().ToString("o")
        }
        $itemPath = Join-Path $taskPlanDir ("{0}.json" -f $itemId)
        Write-Phase160DutyJsonFile -Path $itemPath -Object $itemRecord
        $planItemRecords += [pscustomobject][ordered]@{
          item = $itemRecord
          path = $itemPath
          relative_path = ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $itemPath
        }
      }
    }

    if ($isActive) {
      $activePlanItem = if ($planItemRecords.Count -gt 0) { $planItemRecords[0] } else { $null }
      $activeRecord = [ordered]@{
        status = "ACTIVE"
        duty_id = $DutyId
        task_id = $candidate.task_id
        normalized_task_id = [string]$candidate.normalized_task.normalized_task_id
        source = "owner"
        priority = $candidate.priority
        owner_goal = $candidate.owner_goal
        desired_next_gap = $candidate.desired_next_gap
        normalized_desired_macro_gap = Get-Phase160DutyDesiredMacroGap -Task $candidate.task
        teacher_digest_path = $candidate.digest_relative_path
        content_hash = $candidate.content_hash
        can_parallelize = $candidate.can_parallelize
        active_plan_item_id = if ($null -ne $activePlanItem) { [string]$activePlanItem.item.item_id } else { "NONE" }
        active_plan_item_path = if ($null -ne $activePlanItem) { [string]$activePlanItem.relative_path } else { "NONE" }
        plan_step_count = $candidate.plan_steps.Count
        success_signals = $candidate.success_signals
        selected_for_macro_cycle = $true
        active_owner_task = $true
        selected_at = (Get-Date).ToUniversalTime().ToString("o")
      }
      Write-Phase160DutyJsonFile -Path (Join-Path $activeTaskDir "active_task.json") -Object $activeRecord
      Write-Phase160DutyJsonFile -Path (Join-Path $taskLifecycleRoot "active_task_state.json") -Object ([ordered]@{
        status = "ACTIVE"
        source = "owner_task"
        active_task_id = $candidate.task_id
        active_plan_item_id = $activeRecord.active_plan_item_id
        normalized_task_id = [string]$candidate.normalized_task.normalized_task_id
        owner_task_active = $true
        duty_id = $DutyId
        updated_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      Write-Phase160DutyJsonFile -Path (Join-Path $ownerTaskLifecycleRoot "last_owner_task_intake.json") -Object ([ordered]@{
        status = "ACCEPTED_ACTIVE"
        duty_id = $DutyId
        task_id = $candidate.task_id
        normalized_task_id = [string]$candidate.normalized_task.normalized_task_id
        decision = "ACCEPT_SAFE_OWNER_TASK"
        quarantine_reason = "NONE"
        failed_fields = @()
        backlog_status = "NONE"
        active_task_blocks_owner_task = $false
        blocked_by_active_task_id = "NONE"
        blocked_by_status = "NONE"
        active_task_id = $candidate.task_id
        owner_task_lost = $false
        updated_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      if ($null -ne $activePlanItem) {
        Write-Phase160DutyJsonFile -Path (Join-Path $activeTaskDir "active_plan_item.json") -Object $activePlanItem.item
        Write-Phase160DutyJsonFile -Path (Join-Path $planItemsRoot "active_plan_item.json") -Object $activePlanItem.item
      } elseif (Test-Path -LiteralPath (Join-Path $activeTaskDir "active_plan_item.json")) {
        Remove-Item -LiteralPath (Join-Path $activeTaskDir "active_plan_item.json") -Force
      }
      $activeSelected = $true
      Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
        event_type = "live_task_active_selected"
        source = "builder_live_task_intake"
        duty_id = $DutyId
        task_id = $candidate.task_id
        normalized_task_id = [string]$candidate.normalized_task.normalized_task_id
        decision = "ACCEPT_SAFE_OWNER_TASK"
        priority = $candidate.priority
        teacher_digest_path = $candidate.digest_relative_path
        active_plan_item_id = $activeRecord.active_plan_item_id
        desired_next_gap = $candidate.desired_next_gap
        occurred_at = (Get-Date).ToUniversalTime().ToString("o")
      })
    } else {
      $activeStateForBacklog = Read-Phase160DutyJsonSafe -Path (Join-Path $taskLifecycleRoot "active_task_state.json")
      $blockingActiveForBacklog = $existingActive
      if ($null -eq $blockingActiveForBacklog -and $null -ne $selected) {
        $blockingActiveForBacklog = [pscustomobject][ordered]@{ task_id = [string]$selected.task_id }
      }
      $activeStatusForBacklog = if ($null -ne $activeStateForBacklog -and $activeStateForBacklog.PSObject.Properties.Name -contains "status") { [string]$activeStateForBacklog.status } elseif ($null -ne $blockingActiveForBacklog) { "ACTIVE" } else { "NONE" }
      $backlogWrite = Add-Phase160JOwnerTaskBacklog -TaskBacklogDirectory $taskBacklog -NormalizedTask $candidate.normalized_task -ExistingActiveTask $blockingActiveForBacklog -ExistingActiveStatus $activeStatusForBacklog -DutyId $DutyId -TeacherDigestPath $candidate.digest_relative_path -ContentHash $candidate.content_hash
      $backlogPath = [string]$backlogWrite.backlog_path
      Write-Phase160DutyJsonFile -Path (Join-Path $ownerTaskLifecycleRoot "last_owner_task_intake.json") -Object ([ordered]@{
        status = "BACKLOGGED"
        duty_id = $DutyId
        task_id = $candidate.task_id
        normalized_task_id = [string]$candidate.normalized_task.normalized_task_id
        decision = "BACKLOG_SAFE_OWNER_TASK"
        quarantine_reason = "NONE"
        failed_fields = @()
        backlog_status = [string]$backlogWrite.backlog_status
        active_task_blocks_owner_task = $true
        blocked_by_active_task_id = [string]$backlogWrite.blocked_by_active_task_id
        blocked_by_status = [string]$backlogWrite.blocked_by_status
        owner_task_lost = $false
        updated_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      $backlogCount += 1
      Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
        event_type = "live_task_backlog_written"
        source = "builder_live_task_intake"
        duty_id = $DutyId
        task_id = $candidate.task_id
        normalized_task_id = [string]$candidate.normalized_task.normalized_task_id
        decision = "BACKLOG_SAFE_OWNER_TASK"
        backlog_status = [string]$backlogWrite.backlog_status
        blocked_by_active_task_id = [string]$backlogWrite.blocked_by_active_task_id
        backlog_path = (ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $backlogPath)
        teacher_digest_path = $candidate.digest_relative_path
        occurred_at = (Get-Date).ToUniversalTime().ToString("o")
      })
    }

    $receiptPath = Get-Phase160DutyUniqueFilePath -Directory $teacherConsumed -Name ("receipt_{0}_{1}.json" -f $candidate.safe_task_id, $candidate.content_hash.Substring(0, 12))
    Write-Phase160DutyJsonFile -Path $receiptPath -Object ([ordered]@{
      status = "CONSUMED"
      duty_id = $DutyId
      task_id = $candidate.task_id
      normalized_task_id = [string]$candidate.normalized_task.normalized_task_id
      source = "owner"
      priority = $candidate.priority
      source_file = $candidate.raw_file.Name
      teacher_digest_path = $candidate.digest_relative_path
      intake_decision = if ($isActive) { "ACCEPT_SAFE_OWNER_TASK" } else { "BACKLOG_SAFE_OWNER_TASK" }
      active_selected = $isActive
      backlog_written = -not $isActive
      plan_split = $candidate.plan_steps.Count -gt 0
      content_hash = $candidate.content_hash
      owner_task_lost = $false
      consumed_at = (Get-Date).ToUniversalTime().ToString("o")
    })
    $movedRaw = Move-Phase160DutyFileUnique -SourcePath $candidate.raw_file.FullName -DestinationDirectory $teacherConsumed -Prefix "raw_"
    $consumedCount += 1
    Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
      event_type = "live_task_consumed"
      source = "builder_live_task_intake"
      duty_id = $DutyId
      task_id = $candidate.task_id
      normalized_task_id = [string]$candidate.normalized_task.normalized_task_id
      consumed_receipt_path = (ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $receiptPath)
      moved_raw_path = (ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $movedRaw)
      intake_decision = if ($isActive) { "ACCEPT_SAFE_OWNER_TASK" } else { "BACKLOG_SAFE_OWNER_TASK" }
      active_selected = $isActive
      occurred_at = (Get-Date).ToUniversalTime().ToString("o")
    })
  }

  $counts = Get-Phase160DutyLiveTaskCounts -SessionRootFull $SessionRootFull
  $ownerLifecycle = Get-Phase160JOwnerTaskLifecycleState -SessionRootFull $SessionRootFull
  return [pscustomobject][ordered]@{
    status = "PASS"
    duty_id = $DutyId
    detected_count = $detectedCount
    validated_count = $validatedCount
    digest_written_count = $digestCount
    deduplicated_count = $deduplicatedCount
    consumed_count = $consumedCount
    quarantine_count = $quarantineCount
    plan_split_count = $planSplitCount
    backlog_written_count = $backlogCount
    active_selected = $activeSelected
    teacher_inbox_count = [int]$counts.teacher_inbox_count
    teacher_digest_count = [int]$counts.teacher_digest_count
    teacher_consumed_count = [int]$counts.teacher_consumed_count
    teacher_quarantine_count = [int]$counts.teacher_quarantine_count
    task_backlog_count = [int]$counts.task_backlog_count
    active_task_id = [string]$counts.active_task_id
    active_plan_item_id = [string]$counts.active_plan_item_id
    last_consumed_task = [string]$counts.last_consumed_task
    owner_task_intake_enabled = [bool]$ownerLifecycle.owner_task_intake_enabled
    last_owner_task_intake_decision = [string]$ownerLifecycle.last_owner_task_intake_decision
    last_owner_task_quarantine_reason = [string]$ownerLifecycle.last_owner_task_quarantine_reason
    last_owner_task_backlog_status = [string]$ownerLifecycle.last_owner_task_backlog_status
    owner_task_backlog_count = [int]$ownerLifecycle.owner_task_backlog_count
    latest_owner_backlog_task_id = [string]$ownerLifecycle.latest_owner_backlog_task_id
    active_task_blocks_owner_task = [bool]$ownerLifecycle.active_task_blocks_owner_task
    backlog_activation_ready = [bool]$ownerLifecycle.backlog_activation_ready
    owner_task_lost = [bool]$ownerLifecycle.owner_task_lost
  }
}

$RepoRoot = Resolve-Phase160DutyRepoRoot
$ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
$RepairId = if ($EnableMacroCycle) { "PHASE160B_MACRO_SELF_GROWTH_IGNITION_V1" } else { "PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_EXPANSION_V1" }
$Pushed = $false

try {
  Push-Location $RepoRoot
  $Pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160DutyPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  Assert-Phase160DutyEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160DutyRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160DutyEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"
  $ExpectedHeadSource = "CURRENT_SYNCED_REPO_HEAD"

  if ($TickNumber -lt 0) {
    throw "PHASE160_SELF_GROWTH_DUTY_INVALID_TICK=$TickNumber"
  }
  if ($DutyIndex -lt 1) {
    throw "PHASE160_SELF_GROWTH_DUTY_INVALID_DUTY_INDEX=$DutyIndex"
  }
  if ($MaxCandidateBytes -lt 512) {
    throw "PHASE160_SELF_GROWTH_DUTY_MAX_CANDIDATE_BYTES_TOO_LOW=$MaxCandidateBytes"
  }

  $SessionRootFull = Resolve-Phase160DutyPath -RepoRoot $RepoRoot -Path $SessionRoot
  $SessionRootRelative = ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $SessionRootFull
  if (-not (Test-Path -LiteralPath $SessionRootFull)) {
    throw "PHASE160_SELF_GROWTH_DUTY_SESSION_ROOT_MISSING=$SessionRootRelative"
  }

  if ([string]::IsNullOrWhiteSpace($DutyRoot)) {
    $DutyRoot = "$SessionRootRelative/self_growth"
  }
  if ([string]::IsNullOrWhiteSpace($TeacherOutboxDir)) {
    $TeacherOutboxDir = "$SessionRootRelative/teacher_outbox"
  }

  $DutyRootFull = Resolve-Phase160DutyPath -RepoRoot $RepoRoot -Path $DutyRoot
  $DutyRootRelative = ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $DutyRootFull
  $DutyId = "duty_{0:d4}" -f $DutyIndex
  $DutyDirFull = Join-Path $DutyRootFull $DutyId
  $DutyDirRelative = ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $DutyDirFull
  New-Item -ItemType Directory -Force -Path $DutyDirFull | Out-Null

  $HeartbeatPath = Join-Path $SessionRootFull "heartbeat.json"
  $CurrentStatePath = Join-Path $SessionRootFull "current_state.json"
  $EventLogPath = Join-Path $SessionRootFull "event_log.jsonl"
  $TeacherOutboxFull = Resolve-Phase160DutyPath -RepoRoot $RepoRoot -Path $TeacherOutboxDir
  $TeacherInboxFull = Join-Path $SessionRootFull "teacher_inbox"
  $TeacherDigestPath = Join-Path $SessionRootFull "teacher_digest"
  $TeacherConsumedPath = Join-Path $SessionRootFull "teacher_consumed"
  $TeacherQuarantinePath = Join-Path $SessionRootFull "teacher_quarantine"
  $TaskBacklogPath = Join-Path $SessionRootFull "task_backlog"
  $ActiveTaskPath = Join-Path $SessionRootFull "active_task"
  $PlanItemsPath = Join-Path $SessionRootFull "plan_items"
  $AcceptedInterventionsPath = Join-Path $SessionRootFull "accepted_interventions"
  $RejectedInterventionsPath = Join-Path $SessionRootFull "rejected_interventions"
  $BlockerQueuePath = Join-Path $SessionRootFull "blocker_queue"
  foreach ($directory in @($TeacherOutboxFull, $TeacherInboxFull, $TeacherDigestPath, $TeacherConsumedPath, $TeacherQuarantinePath, $TaskBacklogPath, $ActiveTaskPath, $PlanItemsPath, $AcceptedInterventionsPath, $RejectedInterventionsPath, $BlockerQueuePath)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $StartedAt = Get-Date
  $LiveTaskIntake = Invoke-Phase160DutyLiveTaskIntake -RepoRoot $RepoRoot -SessionRootFull $SessionRootFull -SessionRootRelative $SessionRootRelative -DutyId $DutyId -EventLogPath $EventLogPath
  $ActiveTask = Read-Phase160DutyActiveTask -SessionRootFull $SessionRootFull
  $ActivePlanItem = Read-Phase160DutyActivePlanItem -SessionRootFull $SessionRootFull
  $LiveTaskCounts = Get-Phase160DutyLiveTaskCounts -SessionRootFull $SessionRootFull
  $ActiveTaskId = if ($null -ne $ActiveTask) { Get-Phase160DutyStringProperty -Object $ActiveTask -Name "task_id" -Default "NONE" } else { "NONE" }
  $ActivePlanItemId = if ($null -ne $ActivePlanItem) { Get-Phase160DutyStringProperty -Object $ActivePlanItem -Name "item_id" -Default "NONE" } else { "NONE" }
  $ActiveTaskOwnerGoal = if ($null -ne $ActiveTask) { Get-Phase160DutyStringProperty -Object $ActiveTask -Name "owner_goal" -Default "NONE" } else { "NONE" }
  $ActiveTaskDesiredGap = if ($null -ne $ActiveTask) { Get-Phase160DutyStringProperty -Object $ActiveTask -Name "desired_next_gap" -Default "NONE" } else { "NONE" }
  $ActiveTaskDigestPath = if ($null -ne $ActiveTask) { Get-Phase160DutyStringProperty -Object $ActiveTask -Name "teacher_digest_path" -Default "NONE" } else { "NONE" }
  $TaskInfluencedGapSelection = $false
  if ([string]::IsNullOrWhiteSpace($MacroCycleId)) {
    $MacroCycleId = "PHASE160B_MACRO_SELF_GROWTH_IGNITION_CYCLE_001"
  }
  $CycleStage = if ($EnableMacroCycle) { Get-Phase160DutyMacroStageForIndex -Index $DutyIndex } else { "MICRO_DUTY" }
  $NextCycleStage = if ($EnableMacroCycle) { Get-Phase160DutyMacroStageForIndex -Index ($DutyIndex + 1) } else { "MICRO_DUTY" }
  $Gap = if ($EnableMacroCycle) { Get-Phase160DutyMacroGapForStage -Stage $CycleStage } else { Get-Phase160DutyGapForIndex -Index $DutyIndex }
  $NextGap = if ($EnableMacroCycle) { Get-Phase160DutyMacroGapForStage -Stage $NextCycleStage } else { Get-Phase160DutyGapForIndex -Index ($DutyIndex + 1) }
  if ($EnableMacroCycle -and $CycleStage -eq "GAP_RANK_AND_SELECT" -and $null -ne $ActiveTask) {
    $Gap = Get-Phase160DutyDesiredMacroGap -Task $ActiveTask
    $TaskInfluencedGapSelection = $true
    Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
      event_type = "live_task_injected_into_macro_ranking"
      source = "builder_live_task_intake"
      duty_id = $DutyId
      task_id = $ActiveTaskId
      active_plan_item_id = $ActivePlanItemId
      owner_goal = $ActiveTaskOwnerGoal
      desired_next_gap = $ActiveTaskDesiredGap
      selected_gap = $Gap
      teacher_digest_path = $ActiveTaskDigestPath
      occurred_at = (Get-Date).ToUniversalTime().ToString("o")
    })
  }
  $PreviousDutyId = if ($DutyIndex -gt 1) { "duty_{0:d4}" -f ($DutyIndex - 1) } else { "NONE" }
  $PreviousDutyArtifact = if ($DutyIndex -gt 1) { "$DutyRootRelative/$PreviousDutyId/macro_cycle_artifact.json" } else { "NONE" }
  $PreviousDutyArtifactFull = if ($DutyIndex -gt 1) { Resolve-Phase160DutyPath -RepoRoot $RepoRoot -Path $PreviousDutyArtifact } else { $null }
  $InputArtifact = if ($DutyIndex -gt 1 -and (Test-Path -LiteralPath $PreviousDutyArtifactFull)) { $PreviousDutyArtifact } else { "SESSION_START" }
  $OutputArtifact = "$DutyDirRelative/macro_cycle_artifact.json"
  $NoveltyReason = if ($EnableMacroCycle) { Get-Phase160DutyMacroNoveltyReason -Stage $CycleStage } else { "Bounded micro duty advances the deterministic session-local curriculum." }
  $ProgressClaim = if ($EnableMacroCycle) { Get-Phase160DutyMacroProgressClaim -Stage $CycleStage } else { "Session-local duty completed without accepted-state mutation." }
  $Heartbeat = Read-Phase160DutyJsonSafe -Path $HeartbeatPath
  $CurrentState = Read-Phase160DutyJsonSafe -Path $CurrentStatePath
  $ProofPaths = @(
    "proofs/self_development/PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1.json",
    "proofs/self_development/PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1.json",
    "proofs/self_development/PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1.json",
    "proofs/self_development/PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1.json",
    "proofs/self_development/PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1.json",
    "proofs/self_development/PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1.json",
    "proofs/self_development/PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1.json",
    "proofs/self_development/PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1.json",
    "proofs/self_development/PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_V1.json",
    "proofs/self_development/PHASE160_LIVE_OBSERVER_CONSOLE_REPAIR_V1.json"
  )
  $ProofSummaries = @()
  foreach ($proofPath in $ProofPaths) {
    $ProofSummaries += Read-Phase160DutyJsonSummarySafe -RepoRoot $RepoRoot -Path $proofPath
  }

  $SelfMapSnapshot = [ordered]@{
    status = "PASS"
    repair_id = $RepairId
    duty_id = $DutyId
    session_root = $SessionRootRelative
    tick_number = $TickNumber
    duty_index = $DutyIndex
    resolved_repo_root = $RepoRoot
    branch = $Branch
    local_head = $Head
    remote_head = $RemoteHead
    expected_head_source = $ExpectedHeadSource
    heartbeat_present = $null -ne $Heartbeat
    heartbeat_status = if ($null -ne $Heartbeat) { [string]$Heartbeat.status } else { "MISSING" }
    heartbeat_count = if ($null -ne $Heartbeat) { $Heartbeat.heartbeat_count } else { $null }
    current_state_present = $null -ne $CurrentState
    current_tick = if ($null -ne $CurrentState) { $CurrentState.current_tick } else { $TickNumber }
    accepted_proof_summaries = $ProofSummaries
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    created_at = $StartedAt.ToUniversalTime().ToString("o")
  }

  $CapabilityInventorySnapshot = [ordered]@{
    status = "PASS"
    duty_id = $DutyId
    inventory_scope = "session_local_runtime_capability_snapshot"
    modules_available = @(
      "modules/start_builder_live_growth_daemon_001.ps1",
      "modules/watch_builder_live_growth_session_observer_001.ps1",
      "modules/watch_builder_live_console_001.ps1",
      "modules/invoke_builder_live_self_growth_duty_step_001.ps1"
    )
    validators_available = @(
      "validators/validate_phase160_live_growth_session_daemon_bootstrap_v1.ps1",
      "validators/validate_phase160_live_observer_console_repair_v1.ps1",
      "validators/validate_phase160_live_self_growth_duty_loop_v1.ps1"
    )
    channels_available = @("teacher_outbox", "teacher_inbox", "teacher_digest", "teacher_consumed", "teacher_quarantine", "task_backlog", "active_task", "plan_items", "blocker_queue", "accepted_interventions", "rejected_interventions", "event_log")
    live_task_intake_queue_available = $true
    live_task_intake_scan_status = [string]$LiveTaskIntake.status
    live_task_intake_detected_count = [int]$LiveTaskIntake.detected_count
    live_task_intake_quarantine_count = [int]$LiveTaskIntake.quarantine_count
    deterministic_gap_policy_available = $true
    arbitrary_code_execution_allowed = $false
    capability_shelf_promotion_allowed = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $ElementaryKnowledgeSnapshot = [ordered]@{
    status = "PASS"
    duty_id = $DutyId
    knowledge_type = "operational_seed_only"
    identity = "Builder is local-first self-growing action machine"
    safety = "sandbox-only until admission"
    scope = "no accepted state mutation"
    method = "observe -> select gap -> candidate -> validate -> memory event -> next decision"
    teacher_channel = "teacher_outbox suggestions are input, not commands"
    blocker_channel = "if unable, write blocker/help request"
    stop = "obey stop.flag and duration limit"
    world_knowledge_loaded = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $GapSelection = [ordered]@{
    status = "PASS"
    duty_id = $DutyId
    policy = "DETERMINISTIC_PHASE160_SELF_GROWTH_CURRICULUM"
    active_task_id = $ActiveTaskId
    active_plan_item_id = $ActivePlanItemId
    owner_goal = $ActiveTaskOwnerGoal
    desired_next_gap = $ActiveTaskDesiredGap
    teacher_digest_path = $ActiveTaskDigestPath
    task_influenced_gap_selection = $TaskInfluencedGapSelection
    live_task_binding_policy = if ($TaskInfluencedGapSelection) { "ACTIVE_TASK_DESIRED_GAP_OVERRIDES_MACRO_RANKING" } else { "NO_ACTIVE_TASK_OVERRIDE" }
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    previous_duty_id = $PreviousDutyId
    input_artifact = $InputArtifact
    novelty_reason = $NoveltyReason
    duty_index = $DutyIndex
    selected_gap = $Gap
    next_gap = $NextGap
    curriculum = @(
      "SELF_MAP_REFRESH_GAP",
      "CAPABILITY_INVENTORY_REFRESH_GAP",
      "TEACHER_CHANNEL_READINESS_GAP",
      "BLOCKER_CHANNEL_READINESS_GAP",
      "SELF_GROWTH_RESULT_SUMMARY_GAP",
      "NEXT_SELF_GROWTH_GOAL_SELECTION_GAP"
    )
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $TeacherFiles = @(Get-ChildItem -LiteralPath $TeacherOutboxFull -File -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" } | Sort-Object FullName)
  $AcceptedTeacherInputs = @()
  $RejectedTeacherInputs = @()
  foreach ($teacherFile in $TeacherFiles) {
    $Intervention = Read-Phase160DutyJsonSafe -Path $teacherFile.FullName
    if (Test-Phase160DutyTeacherInterventionValid -Intervention $Intervention) {
      $AcceptedTeacherInputs += $teacherFile.Name
      Write-Phase160DutyJsonFile -Path (Join-Path $AcceptedInterventionsPath ("{0}_{1}" -f $DutyId, $teacherFile.Name)) -Object ([ordered]@{
        status = "ACCEPTED"
        duty_id = $DutyId
        source_file = $teacherFile.Name
        action_taken = "accepted_as_session_local_self_growth_input"
        accepted_state_mutated = $false
        accepted_memory_mutated = $false
        created_at = (Get-Date).ToUniversalTime().ToString("o")
      })
    } else {
      $RejectedTeacherInputs += $teacherFile.Name
      Write-Phase160DutyJsonFile -Path (Join-Path $RejectedInterventionsPath ("{0}_{1}" -f $DutyId, $teacherFile.Name)) -Object ([ordered]@{
        status = "REJECTED"
        duty_id = $DutyId
        source_file = $teacherFile.Name
        reason = "invalid_teacher_intervention_schema"
        accepted_state_mutated = $false
        accepted_memory_mutated = $false
        created_at = (Get-Date).ToUniversalTime().ToString("o")
      })
    }
  }

  $SelfGrowthIntention = [ordered]@{
    status = "PASS"
    duty_id = $DutyId
    selected_gap = $Gap
    active_task_id = $ActiveTaskId
    active_plan_item_id = $ActivePlanItemId
    owner_goal = $ActiveTaskOwnerGoal
    desired_next_gap = $ActiveTaskDesiredGap
    task_influenced_gap_selection = $TaskInfluencedGapSelection
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    previous_duty_id = $PreviousDutyId
    input_artifact = $InputArtifact
    output_artifact = $OutputArtifact
    intention = "perform_bounded_session_local_self_growth_duty"
    owner_visible = $true
    dry_run = [bool]$DryRun
    accepted_state_mutation_requested = $false
    accepted_memory_mutation_requested = $false
    capability_shelf_promotion_requested = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $CandidateDecision = if ($null -ne $ActiveTask -and ($Gap -eq "MACRO_EXPERIENCE_ABSORPTION_GATE_GAP" -or $ActiveTaskDesiredGap -match "EXPERIENCE_ABSORPTION_GATE" -or $ActiveTaskOwnerGoal -match "Experience Absorption Gate")) {
    "OWNER_DECISION_REQUIRED"
  } else {
    "KEEP_SESSION_LOCAL"
  }
  $ActiveTaskInfluenceReason = if ($ActiveTaskId -ne "NONE") {
    "active_task selected from teacher_inbox digest/backlog intake influences macro candidate"
  } else {
    "no active_task selected"
  }

  $Candidate = [ordered]@{
    status = "CANDIDATE"
    duty_id = $DutyId
    selected_gap = $Gap
    active_task_id = $ActiveTaskId
    active_plan_item_id = $ActivePlanItemId
    owner_goal = $ActiveTaskOwnerGoal
    desired_next_gap = $ActiveTaskDesiredGap
    teacher_digest_path = $ActiveTaskDigestPath
    why_this_task_influenced_candidate = $ActiveTaskInfluenceReason
    experience_absorption_gate_decision_options = if ($CandidateDecision -eq "OWNER_DECISION_REQUIRED") { @("promote", "archive", "quarantine", "Owner approval") } else { @() }
    decision = $CandidateDecision
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    previous_duty_id = $PreviousDutyId
    input_artifact = $InputArtifact
    output_artifact = $OutputArtifact
    candidate_type = "sandbox_only_self_growth_action"
    proposed_action = if ($EnableMacroCycle) {
      switch ($CycleStage) {
        "SELF_OBSERVE_MAP_REFRESH" { "refresh the session macro self-map from heartbeat/current_state/event evidence" }
        "CAPABILITY_INVENTORY_DIFF" { "compare observed runtime contour against available live modules and validators" }
        "GAP_RANK_AND_SELECT" { "rank candidate macro gaps and select the next bounded improvement target" }
        "SELF_CHANGE_CANDIDATE_GENERATE" { "generate a session-local change candidate from the ranked gap" }
        "SANDBOX_DRY_RUN" { "dry-run the candidate as data without executing generated code" }
        "VALIDATE_AND_DECIDE" { "validate the dry-run result and decide whether to keep it session-local" }
        default { "absorb the cycle experience into a ledger and select a non-repeated next goal" }
      }
    } else {
      switch ($Gap) {
        "SELF_MAP_REFRESH_GAP" { "refresh session-local map of current Builder runtime contour" }
        "CAPABILITY_INVENTORY_REFRESH_GAP" { "refresh session-local inventory of live modules, validators, and channels" }
        "TEACHER_CHANNEL_READINESS_GAP" { "verify teacher_outbox input handling and teacher_inbox suggestion visibility" }
        "BLOCKER_CHANNEL_READINESS_GAP" { "verify blocker_queue support and safe help-request shape" }
        "SELF_GROWTH_RESULT_SUMMARY_GAP" { "summarize prior self-growth duty outputs into session-local memory event" }
        default { "select the next bounded self-growth goal from deterministic curriculum" }
      }
    }
    candidate_payload = [ordered]@{
      observe = $true
      select_gap = $Gap
      active_task_id = $ActiveTaskId
      active_plan_item_id = $ActivePlanItemId
      owner_goal = $ActiveTaskOwnerGoal
      desired_next_gap = $ActiveTaskDesiredGap
      task_influenced_gap_selection = $TaskInfluencedGapSelection
      decision = $CandidateDecision
      cycle_stage = $CycleStage
      input_artifact = $InputArtifact
      output_artifact = $OutputArtifact
      validate_before_promotion = $true
      write_session_memory_event = $true
      mutate_accepted_state = $false
      execute_generated_code = $false
      create_external_agent = $false
    }
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  $CandidateBytes = [System.Text.Encoding]::UTF8.GetByteCount(($Candidate | ConvertTo-Json -Depth 100 -Compress))
  $ValidationPassed = (
    $CandidateBytes -le $MaxCandidateBytes -and
    $Candidate.candidate_payload.mutate_accepted_state -eq $false -and
    $Candidate.candidate_payload.execute_generated_code -eq $false -and
    $Candidate.candidate_payload.create_external_agent -eq $false
  )
  $ValidationResult = [ordered]@{
    status = if ($ValidationPassed) { "PASS" } else { "FAIL" }
    duty_id = $DutyId
    selected_gap = $Gap
    active_task_id = $ActiveTaskId
    active_plan_item_id = $ActivePlanItemId
    task_influenced_gap_selection = $TaskInfluencedGapSelection
    decision = $CandidateDecision
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    previous_duty_id = $PreviousDutyId
    input_artifact = $InputArtifact
    output_artifact = $OutputArtifact
    candidate_bytes = $CandidateBytes
    max_candidate_bytes = $MaxCandidateBytes
    sandbox_only = $true
    arbitrary_code_execution_used = $false
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    external_agents_created = $false
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  if (-not $ValidationPassed) {
    Write-Phase160DutyJsonFile -Path (Join-Path $BlockerQueuePath ("blocker_{0}.json" -f $DutyId)) -Object ([ordered]@{
      status = "BLOCKED"
      blocker_id = "PHASE160_SELF_GROWTH_DUTY_VALIDATION_FAILED"
      duty_id = $DutyId
      selected_gap = $Gap
      safe_stop_recommended = $false
      created_at = (Get-Date).ToUniversalTime().ToString("o")
    })
  }

  $MemoryEvent = [ordered]@{
    status = if ($ValidationPassed) { "PASS" } else { "BLOCKED" }
    duty_id = $DutyId
    memory_scope = "session_local_only"
    event_type = "self_growth_duty_memory_event"
    selected_gap = $Gap
    active_task_id = $ActiveTaskId
    active_plan_item_id = $ActivePlanItemId
    owner_goal = $ActiveTaskOwnerGoal
    desired_next_gap = $ActiveTaskDesiredGap
    task_influenced_gap_selection = $TaskInfluencedGapSelection
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    previous_duty_id = $PreviousDutyId
    input_artifact = $InputArtifact
    output_artifact = $OutputArtifact
    lesson = "bounded duty completed without accepted state mutation"
    accepted_teacher_inputs = $AcceptedTeacherInputs
    rejected_teacher_inputs = $RejectedTeacherInputs
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $NextDecision = [ordered]@{
    status = "PASS"
    duty_id = $DutyId
    completed_gap = $Gap
    next_gap = $NextGap
    active_task_id = $ActiveTaskId
    active_plan_item_id = $ActivePlanItemId
    task_influenced_gap_selection = $TaskInfluencedGapSelection
    decision = $CandidateDecision
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    next_cycle_stage = $NextCycleStage
    novelty_reason = $NoveltyReason
    next_action = "continue_bounded_self_growth_curriculum"
    codex_needed_for_next_step = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $RequiredObjects = [ordered]@{
    self_map_snapshot = $SelfMapSnapshot
    capability_inventory_snapshot = $CapabilityInventorySnapshot
    elementary_knowledge_snapshot = $ElementaryKnowledgeSnapshot
    gap_selection = $GapSelection
    self_growth_intention = $SelfGrowthIntention
    sandbox_action_candidate = $Candidate
    sandbox_validation_result = $ValidationResult
    memory_event = $MemoryEvent
    next_self_growth_decision = $NextDecision
  }
  foreach ($entry in $RequiredObjects.GetEnumerator()) {
    Write-Phase160DutyJsonFile -Path (Join-Path $DutyDirFull ("{0}.json" -f $entry.Key)) -Object $entry.Value
  }

  $Decision = if ($ValidationPassed) { $CandidateDecision } else { Get-Phase160DutyMacroDecision -ValidationPassed $ValidationPassed }
  $ConsumedOwnerTask = ($ActiveTaskId -ne "NONE" -and $null -ne $ActiveTask -and (Get-Phase160DutyStringProperty -Object $ActiveTask -Name "source" -Default "unknown") -eq "owner")
  if ($EnableMacroCycle) {
    $MacroArtifact = [ordered]@{
      status = if ($ValidationPassed) { "PASS" } else { "BLOCKED" }
      duty_id = $DutyId
      cycle_id = $MacroCycleId
      cycle_stage = $CycleStage
      selected_gap = $Gap
      active_task_id = $ActiveTaskId
      active_plan_item_id = $ActivePlanItemId
      owner_goal = $ActiveTaskOwnerGoal
      desired_next_gap = $ActiveTaskDesiredGap
      teacher_digest_path = $ActiveTaskDigestPath
      consumed_owner_task = $ConsumedOwnerTask
      task_influenced_gap_selection = $TaskInfluencedGapSelection
      backlog_count = [int]$LiveTaskCounts.task_backlog_count
      consumed_count = [int]$LiveTaskCounts.teacher_consumed_count
      quarantine_count = [int]$LiveTaskCounts.teacher_quarantine_count
      input_artifact = $InputArtifact
      output_artifact = $OutputArtifact
      previous_duty_id = $PreviousDutyId
      novelty_reason = $NoveltyReason
      progress_claim = $ProgressClaim
      validation_status = if ($ValidationPassed) { "PASS" } else { "FAIL" }
      decision = $Decision
      next_gap = $NextGap
      next_cycle_stage = $NextCycleStage
      created_at = (Get-Date).ToUniversalTime().ToString("o")
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
      arbitrary_code_execution_used = $false
      external_agents_created = $false
    }
    Write-Phase160DutyJsonFile -Path (Join-Path $DutyDirFull "macro_cycle_artifact.json") -Object $MacroArtifact
    Add-Phase160DutyJsonLine -Path (Join-Path $DutyRootFull "experience_ledger.jsonl") -Object ([ordered]@{
      event_type = "macro_experience_ledger_entry"
      duty_id = $DutyId
      cycle_id = $MacroCycleId
      cycle_stage = $CycleStage
      selected_gap = $Gap
      active_task_id = $ActiveTaskId
      teacher_digest_path = $ActiveTaskDigestPath
      active_plan_item_id = $ActivePlanItemId
      consumed_owner_task = $ConsumedOwnerTask
      task_influenced_gap_selection = $TaskInfluencedGapSelection
      backlog_count = [int]$LiveTaskCounts.task_backlog_count
      consumed_count = [int]$LiveTaskCounts.teacher_consumed_count
      quarantine_count = [int]$LiveTaskCounts.teacher_quarantine_count
      previous_duty_id = $PreviousDutyId
      input_artifact = $InputArtifact
      output_artifact = $OutputArtifact
      novelty_reason = $NoveltyReason
      progress_claim = $ProgressClaim
      validation_status = if ($ValidationPassed) { "PASS" } else { "FAIL" }
      decision = $Decision
      next_gap = $NextGap
      created_at = (Get-Date).ToUniversalTime().ToString("o")
    })
    Write-Phase160DutyJsonFile -Path (Join-Path $DutyRootFull "macro_cycle_summary.json") -Object ([ordered]@{
      status = "PASS"
      cycle_id = $MacroCycleId
      repair_id = "PHASE160B_MACRO_SELF_GROWTH_IGNITION_V1"
      session_root = $SessionRootRelative
      duty_count_completed = $DutyIndex
      latest_duty_id = $DutyId
      latest_cycle_stage = $CycleStage
      latest_selected_gap = $Gap
      active_task_id = $ActiveTaskId
      active_plan_item_id = $ActivePlanItemId
      teacher_digest_path = $ActiveTaskDigestPath
      consumed_owner_task = $ConsumedOwnerTask
      task_influenced_gap_selection = $TaskInfluencedGapSelection
      backlog_count = [int]$LiveTaskCounts.task_backlog_count
      consumed_count = [int]$LiveTaskCounts.teacher_consumed_count
      quarantine_count = [int]$LiveTaskCounts.teacher_quarantine_count
      chain_requires_previous_artifact = $true
      stage_sequence_target = @(
        "SELF_OBSERVE_MAP_REFRESH",
        "CAPABILITY_INVENTORY_DIFF",
        "GAP_RANK_AND_SELECT",
        "SELF_CHANGE_CANDIDATE_GENERATE",
        "SANDBOX_DRY_RUN",
        "VALIDATE_AND_DECIDE",
        "EXPERIENCE_ABSORB_AND_NEXT_GOAL"
      )
      no_consecutive_stage_repeat_expected = $true
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
      updated_at = (Get-Date).ToUniversalTime().ToString("o")
    })
    Write-Phase160DutyJsonFile -Path (Join-Path $DutyRootFull "next_goal.json") -Object ([ordered]@{
      status = "PASS"
      cycle_id = $MacroCycleId
      source_duty_id = $DutyId
      completed_stage = $CycleStage
      next_gap = $NextGap
      next_cycle_stage = $NextCycleStage
      active_task_id = $ActiveTaskId
      active_plan_item_id = $ActivePlanItemId
      owner_goal = $ActiveTaskOwnerGoal
      desired_next_gap = $ActiveTaskDesiredGap
      novelty_reason = "Next goal advances from $CycleStage to $NextCycleStage instead of blindly repeating the same gap."
      blind_repeat = $false
      selected_with_reason = $true
      accepted_state_mutated = $false
      created_at = (Get-Date).ToUniversalTime().ToString("o")
    })
  }

  Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
    event_type = "self_growth_gap_selected"
    source = "builder_self_growth_duty"
    duty_id = $DutyId
    duty_index = $DutyIndex
    tick_number = $TickNumber
    selected_gap = $Gap
    active_task_id = $ActiveTaskId
    active_plan_item_id = $ActivePlanItemId
    task_influenced_gap_selection = $TaskInfluencedGapSelection
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    next_gap = $NextGap
    occurred_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
    event_type = "self_growth_memory_event_written"
    source = "builder_self_growth_duty"
    duty_id = $DutyId
    selected_gap = $Gap
    active_task_id = $ActiveTaskId
    active_plan_item_id = $ActivePlanItemId
    task_influenced_gap_selection = $TaskInfluencedGapSelection
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    memory_scope = "session_local_only"
    occurred_at = (Get-Date).ToUniversalTime().ToString("o")
  })

  $DutySummary = [ordered]@{
    status = if ($ValidationPassed) { "PASS" } else { "BLOCKED" }
    repair_id = $RepairId
    duty_id = $DutyId
    duty_index = $DutyIndex
    tick_number = $TickNumber
    session_root = $SessionRootRelative
    duty_root = $DutyRootRelative
    duty_dir = $DutyDirRelative
    selected_gap = $Gap
    next_gap = $NextGap
    active_task_id = $ActiveTaskId
    active_plan_item_id = $ActivePlanItemId
    owner_goal = $ActiveTaskOwnerGoal
    desired_next_gap = $ActiveTaskDesiredGap
    teacher_digest_path = $ActiveTaskDigestPath
    consumed_owner_task = $ConsumedOwnerTask
    task_influenced_gap_selection = $TaskInfluencedGapSelection
    teacher_inbox_count = [int]$LiveTaskCounts.teacher_inbox_count
    teacher_digest_count = [int]$LiveTaskCounts.teacher_digest_count
    teacher_consumed_count = [int]$LiveTaskCounts.teacher_consumed_count
    teacher_quarantine_count = [int]$LiveTaskCounts.teacher_quarantine_count
    task_backlog_count = [int]$LiveTaskCounts.task_backlog_count
    last_consumed_task = [string]$LiveTaskCounts.last_consumed_task
    live_task_intake_detected_count = [int]$LiveTaskIntake.detected_count
    live_task_intake_deduplicated_count = [int]$LiveTaskIntake.deduplicated_count
    live_task_intake_plan_split_count = [int]$LiveTaskIntake.plan_split_count
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    input_artifact = $InputArtifact
    output_artifact = $OutputArtifact
    previous_duty_id = $PreviousDutyId
    novelty_reason = $NoveltyReason
    progress_claim = $ProgressClaim
    validation_status = if ($ValidationPassed) { "PASS" } else { "FAIL" }
    decision = $Decision
    elementary_knowledge_snapshot_created = $true
    self_map_snapshot_created = $true
    capability_inventory_snapshot_created = $true
    deterministic_gap_policy_used = $true
    sandbox_candidate_created = $true
    sandbox_validation_passed = $ValidationPassed
    memory_event_created = $true
    next_self_growth_decision_created = $true
    teacher_channel_supported = $true
    blocker_channel_supported = $true
    accepted_teacher_input_count = $AcceptedTeacherInputs.Count
    rejected_teacher_input_count = $RejectedTeacherInputs.Count
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    arbitrary_code_execution_used = $false
    external_agents_created = $false
    completed_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase160DutyJsonFile -Path (Join-Path $DutyDirFull "duty_summary.json") -Object $DutySummary

  [pscustomobject][ordered]@{
    status = $DutySummary.status
    repair_id = $RepairId
    duty_id = $DutyId
    duty_index = $DutyIndex
    tick_number = $TickNumber
    session_root = $SessionRootRelative
    duty_dir = $DutyDirRelative
    selected_gap = $Gap
    next_gap = $NextGap
    active_task_id = $ActiveTaskId
    active_plan_item_id = $ActivePlanItemId
    teacher_digest_path = $ActiveTaskDigestPath
    consumed_owner_task = $ConsumedOwnerTask
    task_influenced_gap_selection = $TaskInfluencedGapSelection
    backlog_count = [int]$LiveTaskCounts.task_backlog_count
    consumed_count = [int]$LiveTaskCounts.teacher_consumed_count
    quarantine_count = [int]$LiveTaskCounts.teacher_quarantine_count
    last_consumed_task = [string]$LiveTaskCounts.last_consumed_task
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    input_artifact = $InputArtifact
    output_artifact = $OutputArtifact
    previous_duty_id = $PreviousDutyId
    novelty_reason = $NoveltyReason
    progress_claim = $ProgressClaim
    validation_status = if ($ValidationPassed) { "PASS" } else { "FAIL" }
    decision = $Decision
    sandbox_validation_passed = $ValidationPassed
    memory_event_created = $true
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
  } | ConvertTo-Json -Depth 20
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
