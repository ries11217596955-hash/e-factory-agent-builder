param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160J1ValidatePath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160J1ValidateRepoRoot {
  param([string]$RepoRootParameter)
  if (-not [string]::IsNullOrWhiteSpace($RepoRootParameter) -and $RepoRootParameter -ne ".") {
    return Normalize-Phase160J1ValidatePath -Path $RepoRootParameter
  }
  $scriptRoot = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRoot) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRoot = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    throw "PHASE160J1_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160J1ValidatePath -Path (Join-Path $scriptRoot "..")
}

function Resolve-Phase160J1ValidatePath {
  param([string]$Root, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $Root $Path))
}

function ConvertTo-Phase160J1ValidateRelativePath {
  param([string]$Root, [string]$FullPath)
  $rootFull = Normalize-Phase160J1ValidatePath -Path $Root
  $pathFull = Normalize-Phase160J1ValidatePath -Path $FullPath
  if ($pathFull -eq $rootFull) {
    return "."
  }
  if (-not $pathFull.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160J1_VALIDATE_PATH_OUTSIDE_REPO=$FullPath"
  }
  return ($pathFull.Substring($rootFull.Length + 1) -replace "\\", "/")
}

function Assert-Phase160J1ValidatePathInside {
  param([string]$Root, [string]$Path)
  $rootFull = Normalize-Phase160J1ValidatePath -Path $Root
  $pathFull = Normalize-Phase160J1ValidatePath -Path (Resolve-Phase160J1ValidatePath -Root $Root -Path $Path)
  if (-not ($pathFull -eq $rootFull -or $pathFull.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "PHASE160J1_VALIDATE_PATH_OUTSIDE_REPO=$Path"
  }
  return $pathFull
}

function Write-Phase160J1ValidateJsonFile {
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

function Write-Phase160J1ValidateTextFile {
  param([string]$Path, [string]$Text)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  if (-not $Text.EndsWith("`n")) {
    $Text += "`n"
  }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Read-Phase160J1ValidateJson {
  param([string]$Root, [string]$Path)
  $fullPath = Resolve-Phase160J1ValidatePath -Root $Root -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160J1_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase160J1ValidateJsonSafeFull {
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

function Assert-Phase160J1ValidateTrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160J1_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160J1ValidateFalse {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160J1_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160J1ValidateEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160J1_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160J1ValidateHasProperty {
  param([object]$Object, [string]$PropertyName, [string]$Name)
  if ($null -eq $Object -or -not ($Object.PSObject.Properties.Name -contains $PropertyName)) {
    throw "PHASE160J1_VALIDATE_PROPERTY_MISSING=$Name property=$PropertyName"
  }
}

function Assert-Phase160J1ValidateContainsText {
  param([string]$Text, [string]$Needle, [string]$Name)
  if ($Text.IndexOf($Needle, [System.StringComparison]::Ordinal) -lt 0) {
    throw "PHASE160J1_VALIDATE_TEXT_MISSING=$Name needle=$Needle"
  }
}

function Assert-Phase160J1ValidateParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160J1_VALIDATE_PARSE_ERROR=$Path message=$($parseErrors[0].Message)"
  }
}

function Get-Phase160J1ValidateFileHashes {
  param([string]$Root, [string[]]$Paths)
  $hashes = @{}
  foreach ($path in $Paths) {
    $fullPath = Resolve-Phase160J1ValidatePath -Root $Root -Path $path
    if (Test-Path -LiteralPath $fullPath) {
      $hashes[$path] = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = "MISSING"
    }
  }
  return $hashes
}

function Get-Phase160J1ValidateRemoteHeadSafe {
  param([string]$Branch)
  $remoteHead = (git rev-parse --short "origin/$Branch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    return "UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Remove-Phase160J1ValidateOutput {
  param([string]$Root, [string]$Path)
  $fullPath = Assert-Phase160J1ValidatePathInside -Root $Root -Path $Path
  $relative = ConvertTo-Phase160J1ValidateRelativePath -Root $Root -FullPath $fullPath
  if (-not ($relative -match "^runtime_sessions/live_growth/PHASE160J1_" -or $relative -match "^runtime_sessions/live_growth_console/PHASE160J1_")) {
    throw "PHASE160J1_VALIDATE_REFUSE_DELETE=$relative"
  }
  if (Test-Path -LiteralPath $fullPath) {
    Remove-Item -LiteralPath $fullPath -Recurse -Force
  }
}

function Invoke-Phase160J1ValidateScriptJson {
  param([string]$Root, [string]$ScriptPath, [string[]]$Arguments)
  $scriptFull = Resolve-Phase160J1ValidatePath -Root $Root -Path $ScriptPath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $scriptFull @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160J1_VALIDATE_SCRIPT_FAILED script=$ScriptPath output=$($output -join ' | ')"
  }
  return ($output -join "`n") | ConvertFrom-Json
}

function Invoke-Phase160J1ValidateScriptText {
  param([string]$Root, [string]$ScriptPath, [string[]]$Arguments)
  $scriptFull = Resolve-Phase160J1ValidatePath -Root $Root -Path $ScriptPath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $scriptFull @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160J1_VALIDATE_SCRIPT_FAILED script=$ScriptPath output=$($output -join ' | ')"
  }
  return $output
}

function New-Phase160J1ValidateSessionFixture {
  param([string]$Root, [string]$SessionRoot, [string]$RunId, [string]$Branch, [string]$Head)
  Remove-Phase160J1ValidateOutput -Root $Root -Path $SessionRoot
  $sessionFull = Resolve-Phase160J1ValidatePath -Root $Root -Path $SessionRoot
  foreach ($directory in @(
    $sessionFull,
    (Join-Path $sessionFull "teacher_inbox"),
    (Join-Path $sessionFull "teacher_outbox"),
    (Join-Path $sessionFull "teacher_digest"),
    (Join-Path $sessionFull "teacher_consumed"),
    (Join-Path $sessionFull "teacher_quarantine"),
    (Join-Path $sessionFull "task_backlog"),
    (Join-Path $sessionFull "active_task"),
    (Join-Path $sessionFull "task_lifecycle"),
    (Join-Path $sessionFull "candidate_workspace/candidate_bundles"),
    (Join-Path $sessionFull "candidate_workspace/candidate_queue"),
    (Join-Path $sessionFull "promotion_bundle"),
    (Join-Path $sessionFull "blocker_queue")
  )) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  Write-Phase160J1ValidateJsonFile -Path (Join-Path $sessionFull "run_manifest.json") -Object ([ordered]@{
    run_manifest_status = "PASS"
    run_id = $RunId
    branch = $Branch
    run_head = $Head
    current_head = $Head
    head_match = $true
    commit_allowed = $false
    push_allowed = $false
    branch_switch_allowed = $false
    protected_state_mutation_allowed = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160J1ValidateJsonFile -Path (Join-Path $sessionFull "runtime_guard.json") -Object ([ordered]@{
    status = "PASS"
    run_id = $RunId
    run_head = $Head
    current_head = $Head
    head_match = $true
    candidate_production_enabled = $false
    allowed_runtime_output_count = 0
    allowed_tracked_runtime_sample_change = $false
    unsafe_tracked_code_mutation_count = 0
    protected_state_mutation_count = 0
    blocked_reasons = @()
    checked_at = (Get-Date).ToUniversalTime().ToString("o")
  })
}

function New-Phase160J1ValidateSafeOwnerTask {
  param([string]$TaskId)
  return [ordered]@{
    event_type = "owner_live_task_injection"
    task_id = $TaskId
    source = "owner"
    priority = "high"
    owner_goal = "Verify PHASE160J1 owner task lifecycle state exposure aliases without accepted repo mutation."
    desired_next_gap = "PHASE160J1_STATE_EXPOSURE_FIELD_ALIAS_GAP"
    expected_outputs = @("current_state owner lifecycle aliases", "truthful owner task visibility")
    safety_rules = [ordered]@{
      repo_commit_allowed = $false
      repo_push_allowed = $false
      branch_switch_allowed = $false
      live_repo_file_mutation_allowed = $false
      protected_state_mutation_allowed = $false
      accepted_repo_mutation_allowed = $false
      runtime_session_only = $true
      owner_promotion_required = $true
    }
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }
}

function Write-Phase160J1ValidateInboxTask {
  param([string]$Root, [string]$SessionRoot, [string]$FileName, [object]$Task)
  $path = Resolve-Phase160J1ValidatePath -Root $Root -Path (Join-Path $SessionRoot "teacher_inbox/$FileName")
  Write-Phase160J1ValidateJsonFile -Path $path -Object $Task
}

function Invoke-Phase160J1ValidateDuty {
  param([string]$Root, [string]$SessionRoot, [int]$DutyIndex = 1)
  return Invoke-Phase160J1ValidateScriptJson -Root $Root -ScriptPath "modules/invoke_builder_live_self_growth_duty_step_001.ps1" -Arguments @(
    "-SessionRoot", $SessionRoot,
    "-DutyIndex", [string]$DutyIndex,
    "-TickNumber", [string]$DutyIndex,
    "-MaxCandidateBytes", "8192"
  )
}

function Invoke-Phase160J1DaemonCurrentStateSample {
  param([string]$Root, [string]$SessionRoot, [string]$RunId)
  $scriptFull = Resolve-Phase160J1ValidatePath -Root $Root -Path "modules/start_builder_live_growth_daemon_001.ps1"
  $sessionFull = Resolve-Phase160J1ValidatePath -Root $Root -Path $SessionRoot
  $currentStatePath = Join-Path $sessionFull "current_state.json"
  $stopFlagPath = Join-Path $sessionFull "stop.flag"
  if (Test-Path -LiteralPath $stopFlagPath) {
    Remove-Item -LiteralPath $stopFlagPath -Force
  }
  $job = Start-Job -ScriptBlock {
    param([string]$ScriptFull, [string]$SessionRootArgument, [string]$RunIdArgument)
    & $ScriptFull -SessionRoot $SessionRootArgument -RunId $RunIdArgument -DurationSeconds 12 -TickIntervalSeconds 1
  } -ArgumentList $scriptFull, $SessionRoot, $RunId
  $sample = $null
  try {
    for ($i = 0; $i -lt 80; $i += 1) {
      Start-Sleep -Milliseconds 250
      $candidate = Read-Phase160J1ValidateJsonSafeFull -Path $currentStatePath
      if ($null -ne $candidate -and
          $candidate.PSObject.Properties.Name -contains "status" -and
          [string]$candidate.status -eq "RUNNING" -and
          $candidate.PSObject.Properties.Name -contains "current_tick" -and
          [int]$candidate.current_tick -ge 1 -and
          $candidate.PSObject.Properties.Name -contains "owner_task_intake_enabled") {
        $sample = $candidate
        break
      }
      if ($job.State -eq "Failed" -or $job.State -eq "Completed" -or $job.State -eq "Stopped") {
        break
      }
    }
    if ($null -eq $sample) {
      $jobOutput = @(Receive-Job -Job $job -Keep 2>&1 | ForEach-Object { [string]$_ })
      throw "PHASE160J1_VALIDATE_RUNNING_CURRENT_STATE_OWNER_FIELDS_MISSING session=$SessionRoot job_state=$($job.State) output=$($jobOutput -join ' | ')"
    }
    [System.IO.File]::WriteAllText($stopFlagPath, "PHASE160J1_VALIDATOR_STOP`n", [System.Text.UTF8Encoding]::new($false))
    $completed = Wait-Job -Job $job -Timeout 20
    if ($null -eq $completed) {
      Stop-Job -Job $job
      throw "PHASE160J1_VALIDATE_DAEMON_TIMEOUT session=$SessionRoot"
    }
    $output = @(Receive-Job -Job $job 2>&1 | ForEach-Object { [string]$_ })
    if ($job.State -ne "Completed") {
      throw "PHASE160J1_VALIDATE_DAEMON_FAILED session=$SessionRoot state=$($job.State) output=$($output -join ' | ')"
    }
    return $sample
  } finally {
    if ($null -ne $job -and ($job.State -eq "Running" -or $job.State -eq "NotStarted")) {
      Stop-Job -Job $job
    }
    if ($null -ne $job) {
      Remove-Job -Job $job -Force
    }
  }
}

function Assert-Phase160J1CurrentStateExposure {
  param([object]$CurrentState, [string]$Name)
  foreach ($property in @(
    "owner_task_intake_enabled",
    "last_owner_task_intake_decision",
    "last_owner_task_quarantine_reason",
    "last_owner_task_backlog_status",
    "owner_task_backlog_count",
    "latest_owner_backlog_task_id",
    "active_task_blocks_owner_task",
    "backlog_activation_ready",
    "owner_task_lost",
    "task_backlog_count",
    "teacher_quarantine_count",
    "last_consumed_task"
  )) {
    Assert-Phase160J1ValidateHasProperty -Object $CurrentState -PropertyName $property -Name $Name
  }
}

function Assert-Phase160J1RuntimeOutputsNotStaged {
  $stagedRuntime = @(git diff --cached --name-only -- runtime_sessions)
  if ($stagedRuntime.Count -gt 0) {
    throw "PHASE160J1_VALIDATE_RUNTIME_OUTPUTS_STAGED=$($stagedRuntime -join '; ')"
  }
}

$resolvedRoot = Resolve-Phase160J1ValidateRepoRoot -RepoRootParameter $RepoRoot
$pushed = $false

try {
  Push-Location $resolvedRoot
  $pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160J1ValidatePath -Root $resolvedRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $branchBefore = (git branch --show-current).Trim()
  $headBefore = (git rev-parse --short HEAD).Trim()
  $remoteBefore = Get-Phase160J1ValidateRemoteHeadSafe -Branch $branchBefore
  $runStamp = Get-Date -Format "yyyyMMddHHmmssfff"
  $protectedPaths = @("TASK_QUEUE.json", "GENESIS_STATE.json", "CAPABILITY_ROADMAP.json", "packs/registry.json", "orchestrator/run.ps1")
  $protectedBefore = Get-Phase160J1ValidateFileHashes -Root $resolvedRoot -Paths $protectedPaths

  $touchedPs1 = @(
    "modules/start_builder_live_growth_daemon_001.ps1",
    "modules/watch_builder_live_console_001.ps1",
    "modules/watch_builder_live_growth_session_observer_001.ps1",
    "modules/inspect_builder_owner_task_lifecycle_state_001.ps1",
    "modules/enqueue_builder_owner_task_backlog_001.ps1",
    "modules/promote_builder_backlog_task_to_active_001.ps1",
    "modules/normalize_builder_owner_live_task_001.ps1",
    "modules/classify_builder_owner_live_task_safety_001.ps1",
    "modules/invoke_builder_live_self_growth_duty_step_001.ps1",
    "validators/validate_phase160j1_state_exposure_field_alias_v1.ps1"
  )
  foreach ($path in $touchedPs1) {
    Assert-Phase160J1ValidateParserClean -Path (Resolve-Phase160J1ValidatePath -Root $resolvedRoot -Path $path)
  }

  . (Resolve-Phase160J1ValidatePath -Root $resolvedRoot -Path "modules/normalize_builder_owner_live_task_001.ps1")
  . (Resolve-Phase160J1ValidatePath -Root $resolvedRoot -Path "modules/classify_builder_owner_live_task_safety_001.ps1")
  . (Resolve-Phase160J1ValidatePath -Root $resolvedRoot -Path "modules/inspect_builder_owner_task_lifecycle_state_001.ps1")

  $safeTask = New-Phase160J1ValidateSafeOwnerTask -TaskId "PHASE160J1_SAFE_OWNER_WITH_RULES_001"
  $safeNormalized = ConvertTo-Phase160JOwnerLiveTaskNormalized -Task ([pscustomobject]$safeTask) -ContentHash "phase160j1safe001" -RawFileName "safe.json"
  $safeClassification = Invoke-Phase160JOwnerTaskSafetyClassification -Task ([pscustomobject]$safeTask) -NormalizedTask $safeNormalized
  Assert-Phase160J1ValidateFalse -Actual ([bool]$safeClassification.quarantine_required) -Name "safe_owner_task_not_quarantined"
  Assert-Phase160J1ValidateFalse -Actual ([string]$safeClassification.quarantine_reason -eq "unsafe_live_task_safety_rules") -Name "safe_owner_not_generic_quarantine"

  $unsafeCommitTask = New-Phase160J1ValidateSafeOwnerTask -TaskId "PHASE160J1_UNSAFE_COMMIT_001"
  $unsafeCommitTask.safety_rules["repo_commit_allowed"] = $true
  $unsafeCommitNormalized = ConvertTo-Phase160JOwnerLiveTaskNormalized -Task ([pscustomobject]$unsafeCommitTask) -ContentHash "phase160j1unsafe1" -RawFileName "unsafe_commit.json"
  $unsafeCommitClassification = Invoke-Phase160JOwnerTaskSafetyClassification -Task ([pscustomobject]$unsafeCommitTask) -NormalizedTask $unsafeCommitNormalized
  Assert-Phase160J1ValidateEquals -Actual ([string]$unsafeCommitClassification.decision) -Expected "QUARANTINE_UNSAFE_OWNER_TASK" -Name "unsafe_commit_decision"
  Assert-Phase160J1ValidateEquals -Actual ([string]$unsafeCommitClassification.quarantine_reason) -Expected "unsafe_commit_allowed" -Name "unsafe_commit_reason"

  $activeBacklogSession = "runtime_sessions/live_growth/PHASE160J1_ACTIVE_INTERNAL_BACKLOG_001_$runStamp"
  New-Phase160J1ValidateSessionFixture -Root $resolvedRoot -SessionRoot $activeBacklogSession -RunId "PHASE160J1_ACTIVE_INTERNAL_BACKLOG_001_$runStamp" -Branch $branchBefore -Head $headBefore
  $activeBacklogFull = Resolve-Phase160J1ValidatePath -Root $resolvedRoot -Path $activeBacklogSession
  Write-Phase160J1ValidateJsonFile -Path (Join-Path $activeBacklogFull "active_task/active_task.json") -Object ([ordered]@{
    status = "ACTIVE"
    task_id = "PHASE160J1_INTERNAL_ACTIVE_TASK_001"
    source = "internal_self_selected_goal"
    owner_goal = "Internal active task remains active while owner task waits."
    desired_next_gap = "SELF_INITIATED_USEFUL_GOAL_SELECTION"
    active_owner_task = $false
    selected_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160J1ValidateJsonFile -Path (Join-Path $activeBacklogFull "task_lifecycle/active_task_state.json") -Object ([ordered]@{
    status = "WAITING_OWNER_PROMOTION"
    source = "internal_self_selected_goal"
    active_task_id = "PHASE160J1_INTERNAL_ACTIVE_TASK_001"
    updated_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160J1ValidateInboxTask -Root $resolvedRoot -SessionRoot $activeBacklogSession -FileName "safe_owner_backlog.json" -Task (New-Phase160J1ValidateSafeOwnerTask -TaskId "PHASE160J1_SAFE_OWNER_BACKLOG_001")
  $activeBacklogDuty = Invoke-Phase160J1ValidateDuty -Root $resolvedRoot -SessionRoot $activeBacklogSession -DutyIndex 1
  $activeBacklogState = Invoke-Phase160J1DaemonCurrentStateSample -Root $resolvedRoot -SessionRoot $activeBacklogSession -RunId "PHASE160J1_ACTIVE_INTERNAL_BACKLOG_001_$runStamp"
  Assert-Phase160J1CurrentStateExposure -CurrentState $activeBacklogState -Name "active_backlog_current_state"
  Assert-Phase160J1ValidateEquals -Actual ([string]$activeBacklogState.last_owner_task_intake_decision) -Expected "BACKLOG_SAFE_OWNER_TASK" -Name "active_backlog_decision"
  Assert-Phase160J1ValidateEquals -Actual ([string]$activeBacklogState.last_owner_task_quarantine_reason) -Expected "NONE" -Name "active_backlog_quarantine_reason"
  Assert-Phase160J1ValidateEquals -Actual ([string]$activeBacklogState.last_owner_task_backlog_status) -Expected "BACKLOG_WAITING_ACTIVE_SLOT" -Name "active_backlog_status"
  Assert-Phase160J1ValidateEquals -Actual ([int]$activeBacklogState.owner_task_backlog_count) -Expected ([int]$activeBacklogState.task_backlog_count) -Name "owner_backlog_alias_count"
  Assert-Phase160J1ValidateEquals -Actual ([int]$activeBacklogState.owner_task_backlog_count) -Expected 1 -Name "owner_backlog_count"
  Assert-Phase160J1ValidateEquals -Actual ([string]$activeBacklogState.latest_owner_backlog_task_id) -Expected "PHASE160J1_SAFE_OWNER_BACKLOG_001" -Name "latest_owner_backlog_task_id"
  Assert-Phase160J1ValidateTrue -Actual ([bool]$activeBacklogState.active_task_blocks_owner_task) -Name "active_blocks_owner_task"
  Assert-Phase160J1ValidateFalse -Actual ([bool]$activeBacklogState.backlog_activation_ready) -Name "backlog_activation_not_ready"
  Assert-Phase160J1ValidateFalse -Actual ([bool]$activeBacklogState.owner_task_lost) -Name "backlogged_owner_task_not_lost"

  $acceptedSession = "runtime_sessions/live_growth/PHASE160J1_NO_ACTIVE_ACCEPT_001_$runStamp"
  New-Phase160J1ValidateSessionFixture -Root $resolvedRoot -SessionRoot $acceptedSession -RunId "PHASE160J1_NO_ACTIVE_ACCEPT_001_$runStamp" -Branch $branchBefore -Head $headBefore
  Write-Phase160J1ValidateInboxTask -Root $resolvedRoot -SessionRoot $acceptedSession -FileName "safe_owner_accept.json" -Task (New-Phase160J1ValidateSafeOwnerTask -TaskId "PHASE160J1_SAFE_OWNER_ACCEPT_001")
  $acceptedDuty = Invoke-Phase160J1ValidateDuty -Root $resolvedRoot -SessionRoot $acceptedSession -DutyIndex 2
  $acceptedState = Invoke-Phase160J1DaemonCurrentStateSample -Root $resolvedRoot -SessionRoot $acceptedSession -RunId "PHASE160J1_NO_ACTIVE_ACCEPT_001_$runStamp"
  Assert-Phase160J1CurrentStateExposure -CurrentState $acceptedState -Name "accepted_current_state"
  Assert-Phase160J1ValidateEquals -Actual ([string]$acceptedState.last_owner_task_intake_decision) -Expected "ACCEPT_SAFE_OWNER_TASK" -Name "accepted_decision"
  Assert-Phase160J1ValidateEquals -Actual ([int]$acceptedState.owner_task_backlog_count) -Expected 0 -Name "accepted_owner_backlog_count"
  Assert-Phase160J1ValidateEquals -Actual ([int]$acceptedState.task_backlog_count) -Expected 0 -Name "accepted_task_backlog_count"
  Assert-Phase160J1ValidateEquals -Actual ([string]$acceptedState.active_task_id) -Expected "PHASE160J1_SAFE_OWNER_ACCEPT_001" -Name "accepted_active_task_id"
  Assert-Phase160J1ValidateFalse -Actual ([bool]$acceptedState.active_task_blocks_owner_task) -Name "accepted_active_does_not_block_owner"
  Assert-Phase160J1ValidateFalse -Actual ([bool]$acceptedState.owner_task_lost) -Name "accepted_owner_task_not_lost"

  $unsafeSession = "runtime_sessions/live_growth/PHASE160J1_UNSAFE_COMMIT_QUARANTINE_001_$runStamp"
  New-Phase160J1ValidateSessionFixture -Root $resolvedRoot -SessionRoot $unsafeSession -RunId "PHASE160J1_UNSAFE_COMMIT_QUARANTINE_001_$runStamp" -Branch $branchBefore -Head $headBefore
  Write-Phase160J1ValidateInboxTask -Root $resolvedRoot -SessionRoot $unsafeSession -FileName "unsafe_commit.json" -Task $unsafeCommitTask
  $unsafeDuty = Invoke-Phase160J1ValidateDuty -Root $resolvedRoot -SessionRoot $unsafeSession -DutyIndex 3
  $unsafeState = Invoke-Phase160J1DaemonCurrentStateSample -Root $resolvedRoot -SessionRoot $unsafeSession -RunId "PHASE160J1_UNSAFE_COMMIT_QUARANTINE_001_$runStamp"
  Assert-Phase160J1CurrentStateExposure -CurrentState $unsafeState -Name "unsafe_current_state"
  Assert-Phase160J1ValidateEquals -Actual ([string]$unsafeState.last_owner_task_intake_decision) -Expected "QUARANTINE_UNSAFE_OWNER_TASK" -Name "unsafe_decision"
  Assert-Phase160J1ValidateEquals -Actual ([string]$unsafeState.last_owner_task_quarantine_reason) -Expected "unsafe_commit_allowed" -Name "unsafe_quarantine_reason_exposed"
  Assert-Phase160J1ValidateEquals -Actual ([int]$unsafeState.teacher_quarantine_count) -Expected 1 -Name "unsafe_quarantine_count"
  Assert-Phase160J1ValidateFalse -Actual ([bool]$unsafeState.owner_task_lost) -Name "unsafe_owner_task_intentional_quarantine_not_lost"

  $consoleRoot = "runtime_sessions/live_growth_console/PHASE160J1_CONSOLE_001_$runStamp"
  Remove-Phase160J1ValidateOutput -Root $resolvedRoot -Path $consoleRoot
  $consoleOutput = Invoke-Phase160J1ValidateScriptText -Root $resolvedRoot -ScriptPath "modules/watch_builder_live_console_001.ps1" -Arguments @(
    "-SessionRoot", $activeBacklogSession,
    "-RunId", "PHASE160J1_ACTIVE_INTERNAL_BACKLOG_001_$runStamp",
    "-DurationSeconds", "1",
    "-PollIntervalSeconds", "1",
    "-ShowTailEvents", "0",
    "-ShowTailObserver", "0",
    "-ConsoleRunId", "PHASE160J1_CONSOLE_001_$runStamp",
    "-ConsoleRuntimeRoot", $consoleRoot
  )
  $consoleSample = Get-Content -LiteralPath (Resolve-Phase160J1ValidatePath -Root $resolvedRoot -Path "$consoleRoot/console_output_sample.txt") -Raw
  foreach ($token in @("OWNER_TASK_INTAKE=", "LAST_INTAKE_DECISION=", "OWNER_BACKLOG_COUNT=", "LATEST_OWNER_BACKLOG_TASK=", "ACTIVE_TASK_BLOCKS_OWNER_TASK=", "LAST_QUARANTINE_REASON=", "OWNER_TASK_LOST=")) {
    Assert-Phase160J1ValidateContainsText -Text $consoleSample -Needle $token -Name "console_owner_field"
  }

  $observerSession = "runtime_sessions/live_growth/PHASE160J1_OBSERVER_SOURCE_001_$runStamp"
  New-Phase160J1ValidateSessionFixture -Root $resolvedRoot -SessionRoot $observerSession -RunId "PHASE160J1_OBSERVER_SOURCE_001_$runStamp" -Branch $branchBefore -Head $headBefore
  $observerFull = Resolve-Phase160J1ValidatePath -Root $resolvedRoot -Path $observerSession
  Write-Phase160J1ValidateJsonFile -Path (Join-Path $observerFull "heartbeat.json") -Object ([ordered]@{
    status = "RUNNING"
    heartbeat_id = "PHASE160_BUILDER_DAEMON_HEARTBEAT"
    session_root = $observerSession
    heartbeat_count = 1
    updated_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160J1ValidateJsonFile -Path (Join-Path $observerFull "current_state.json") -Object ([ordered]@{
    status = "RUNNING"
    state_id = "PHASE160_BUILDER_DAEMON_CURRENT_STATE"
    session_root = $observerSession
    current_tick = 1
    self_growth_enabled = $true
    self_growth_duty_count = 1
    last_self_growth_gap = "PHASE160J1_STATE_EXPOSURE_FIELD_ALIAS_GAP"
    last_self_growth_status = "PASS"
    teacher_quarantine_count = 0
    task_backlog_count = 1
    last_consumed_task = "PHASE160J1_SAFE_OWNER_BACKLOG_OBSERVER_001"
    owner_task_intake_enabled = $true
    last_owner_task_intake_decision = "BACKLOG_SAFE_OWNER_TASK"
    last_owner_task_quarantine_reason = "NONE"
    last_owner_task_backlog_status = "BACKLOG_WAITING_ACTIVE_SLOT"
    owner_task_backlog_count = 1
    latest_owner_backlog_task_id = "PHASE160J1_SAFE_OWNER_BACKLOG_OBSERVER_001"
    active_task_blocks_owner_task = $true
    backlog_activation_ready = $false
    owner_task_lost = $false
  })
  Write-Phase160J1ValidateJsonFile -Path (Join-Path $observerFull "task_backlog/PHASE160J1_SAFE_OWNER_BACKLOG_OBSERVER_001.json") -Object ([ordered]@{
    status = "BACKLOG"
    task_id = "PHASE160J1_SAFE_OWNER_BACKLOG_OBSERVER_001"
    source = "owner"
    backlog_status = "BACKLOG_WAITING_ACTIVE_SLOT"
    owner_task_lost = $false
  })
  $candidateDir = Join-Path $observerFull "candidate_workspace/candidate_bundles/PHASE160J1_INTERNAL_CANDIDATE"
  New-Item -ItemType Directory -Force -Path $candidateDir | Out-Null
  Write-Phase160J1ValidateJsonFile -Path (Join-Path $candidateDir "candidate_manifest.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = "PHASE160J1_INTERNAL_CANDIDATE"
    source = "internal_self_selected_goal"
    source_task_id = "PHASE160J1_INTERNAL_SOURCE_TASK_001"
    proposed_file_paths = @("modules/phase160j1_internal_fixture.ps1")
    owner_promotion_allowed = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  $observerResult = Invoke-Phase160J1ValidateScriptJson -Root $resolvedRoot -ScriptPath "modules/watch_builder_live_growth_session_observer_001.ps1" -Arguments @(
    "-SessionRoot", $observerSession,
    "-RunId", "PHASE160J1_OBSERVER_SOURCE_001_$runStamp",
    "-DurationSeconds", "1",
    "-PollIntervalSeconds", "1",
    "-StaleAfterSeconds", "99",
    "-ExpectSelfGrowthDuty"
  )
  Assert-Phase160J1ValidateTrue -Actual ([bool]$observerResult.safe_owner_task_backlogged_behind_active_task) -Name "observer_safe_owner_backlogged"
  Assert-Phase160J1ValidateTrue -Actual ([bool]$observerResult.owner_task_not_lost) -Name "observer_owner_task_not_lost"
  Assert-Phase160J1ValidateTrue -Actual ([bool]$observerResult.owner_task_lost_false_detected) -Name "observer_owner_task_lost_false_detected"
  Assert-Phase160J1ValidateTrue -Actual ([bool]$observerResult.internal_source_attribution_truthful) -Name "observer_source_attribution_truthful"

  $runtimeJsonRoots = @($activeBacklogSession, $acceptedSession, $unsafeSession, $observerSession, $consoleRoot)
  foreach ($session in $runtimeJsonRoots) {
    $sessionFull = Resolve-Phase160J1ValidatePath -Root $resolvedRoot -Path $session
    foreach ($jsonFile in @(Get-ChildItem -LiteralPath $sessionFull -File -Filter "*.json" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "raw_*.json" })) {
      Get-Content -LiteralPath $jsonFile.FullName -Raw | ConvertFrom-Json | Out-Null
    }
  }

  $reportPath = Resolve-Phase160J1ValidatePath -Root $resolvedRoot -Path "reports/self_development/PHASE160J1_STATE_EXPOSURE_FIELD_ALIAS_REPORT.md"
  $proofPath = Resolve-Phase160J1ValidatePath -Root $resolvedRoot -Path "proofs/self_development/PHASE160J1_STATE_EXPOSURE_FIELD_ALIAS_PROOF.json"
  $routePath = Resolve-Phase160J1ValidatePath -Root $resolvedRoot -Path "route_change_requests/PHASE160J1_STATE_EXPOSURE_FIELD_ALIAS_REQUEST.md"
  Write-Phase160J1ValidateTextFile -Path $reportPath -Text (@(
    "# PHASE160J1 State Exposure Field Alias Report",
    "",
    "ACTIVE_LINE: AGENT_BUILDER_SELF_DEVELOPMENT",
    "MODE: SELF_BUILD / VERIFY",
    "",
    "Repaired current_state owner task lifecycle exposure for accepted, backlogged, and intentionally quarantined owner tasks.",
    "",
    "Validated live RUNNING current_state aliases, console visibility, observer detection, exact unsafe commit quarantine reason, safe task safety_rules compatibility, preserved legacy fields, and no protected state mutation.",
    "",
    "Result: PASS"
  ) -join "`n")
  Write-Phase160J1ValidateJsonFile -Path $proofPath -Object ([ordered]@{
    status = "PASS"
    phase = "PHASE160J1_STATE_EXPOSURE_FIELD_ALIAS_REPAIR_V1"
    active_line = "AGENT_BUILDER_SELF_DEVELOPMENT"
    mode = "SELF_BUILD"
    running_current_state_owner_fields_exposed = $true
    owner_task_backlog_count_exposed = $true
    last_owner_task_intake_decision_exposed = $true
    last_owner_task_quarantine_reason_exposed = $true
    latest_owner_backlog_task_id_exposed = $true
    owner_task_lost_false_for_backlogged_task = $true
    owner_task_lost_false_for_accepted_task = $true
    unsafe_task_quarantine_reason_exposed = $true
    safe_task_generic_unsafe_false_quarantine_absent = $true
    phase160j_behavior_compatibility_pass = $true
    observer_owner_task_lost_false_detected = $true
    observer_source_attribution_truthful = $true
    console_owner_task_lost_visible = $true
    old_fields_preserved = @("task_backlog_count", "teacher_quarantine_count", "last_consumed_task")
    artifacts = @(
      $activeBacklogSession,
      $acceptedSession,
      $unsafeSession,
      $observerSession,
      $consoleRoot
    )
    report = "reports/self_development/PHASE160J1_STATE_EXPOSURE_FIELD_ALIAS_REPORT.md"
    route_request = "route_change_requests/PHASE160J1_STATE_EXPOSURE_FIELD_ALIAS_REQUEST.md"
    accepted_state_mutated = $false
    protected_state_mutated = $false
    commit_performed = $false
    push_performed = $false
    branch_switch_performed = $false
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160J1ValidateTextFile -Path $routePath -Text (@(
    "# PHASE160J1 State Exposure Field Alias Request",
    "",
    "Request: accept PHASE160J1 as the state exposure repair after PHASE160J.",
    "",
    "Scope remained AGENT_BUILDER_SELF_DEVELOPMENT. No external agents, no package installs, no commit, no push, no branch switch, and no protected state mutation.",
    "",
    "Validator: validators/validate_phase160j1_state_exposure_field_alias_v1.ps1"
  ) -join "`n")

  Read-Phase160J1ValidateJson -Root $resolvedRoot -Path "proofs/self_development/PHASE160J1_STATE_EXPOSURE_FIELD_ALIAS_PROOF.json" | Out-Null

  $protectedAfter = Get-Phase160J1ValidateFileHashes -Root $resolvedRoot -Paths $protectedPaths
  foreach ($path in $protectedPaths) {
    Assert-Phase160J1ValidateEquals -Actual $protectedAfter[$path] -Expected $protectedBefore[$path] -Name "protected_state_hash_$path"
  }
  Assert-Phase160J1RuntimeOutputsNotStaged
  $branchAfter = (git branch --show-current).Trim()
  $headAfter = (git rev-parse --short HEAD).Trim()
  $remoteAfter = Get-Phase160J1ValidateRemoteHeadSafe -Branch $branchAfter
  Assert-Phase160J1ValidateEquals -Actual $branchAfter -Expected $branchBefore -Name "branch_unchanged"
  Assert-Phase160J1ValidateEquals -Actual $headAfter -Expected $headBefore -Name "head_unchanged_no_commit"
  Assert-Phase160J1ValidateEquals -Actual $remoteAfter -Expected $remoteBefore -Name "remote_head_unchanged_no_push"

  Write-Host "PHASE160J1_STATE_EXPOSURE_FIELD_ALIAS_VALIDATE_RESULT=PASS"
  Write-Host "OWNER_TASK_BACKLOG_COUNT_EXPOSED=True"
  Write-Host "LAST_OWNER_TASK_INTAKE_DECISION_EXPOSED=True"
  Write-Host "LAST_OWNER_TASK_QUARANTINE_REASON_EXPOSED=True"
  Write-Host "LATEST_OWNER_BACKLOG_TASK_ID_EXPOSED=True"
  Write-Host "OWNER_TASK_LOST_FALSE_FOR_BACKLOGGED_TASK=True"
  Write-Host "OWNER_TASK_LOST_FALSE_FOR_ACCEPTED_TASK=True"
  Write-Host "UNSAFE_TASK_QUARANTINE_REASON_EXPOSED=True"
  Write-Host "SAFE_TASK_GENERIC_UNSAFE_FALSE_QUARANTINE_ABSENT=True"
  Write-Host "PHASE160J_BEHAVIOR_COMPATIBILITY_PASS=True"
  Write-Host "NO_PROTECTED_STATE_MUTATION=True"
  Write-Host "RUNTIME_OUTPUTS_STAGED=False"
  Write-Host "NO_COMMIT_PERFORMED=True"
  Write-Host "NO_PUSH_PERFORMED=True"
  Write-Host "NO_BRANCH_SWITCH=True"
} finally {
  if ($pushed) {
    Pop-Location
  }
}
