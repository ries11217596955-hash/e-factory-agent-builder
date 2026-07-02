param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160FFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160FRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160F_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160FFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160FPath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Assert-Phase160FPathInsideRepo {
  param([string]$RepoRoot, [string]$Path)
  $root = Normalize-Phase160FFullPath -Path $RepoRoot
  $full = Normalize-Phase160FFullPath -Path (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path $Path)
  if (-not ($full -eq $root -or $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "PHASE160F_VALIDATE_PATH_OUTSIDE_REPO=$Path"
  }
  return $full
}

function Read-Phase160FJson {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160FPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160F_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase160FText {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160FPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160F_VALIDATE_MISSING_TEXT=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw
}

function Write-Phase160FJsonFile {
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

function Write-Phase160FTextFile {
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

function Assert-Phase160FEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160F_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160FTrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160F_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160FFalse {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160F_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160FAtLeast {
  param([object]$Actual, [int]$Minimum, [string]$Name)
  if ([int]$Actual -lt $Minimum) {
    throw "PHASE160F_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase160FParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160F_VALIDATE_PARSE_ERROR=$Path message=$($parseErrors[0].Message)"
  }
}

function Remove-Phase160FOutput {
  param([string]$RepoRoot, [string]$Path)
  $full = Assert-Phase160FPathInsideRepo -RepoRoot $RepoRoot -Path $Path
  if (Test-Path -LiteralPath $full) {
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}

function Get-Phase160FRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160F_VALIDATE_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Get-Phase160FFileHashes {
  param([string]$RepoRoot, [string[]]$Paths)
  $hashes = @{}
  foreach ($path in $Paths) {
    $full = Resolve-Phase160FPath -RepoRoot $RepoRoot -Path $path
    if (Test-Path -LiteralPath $full) {
      $hashes[$path] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = "MISSING"
    }
  }
  return $hashes
}

function Get-Phase160FTrackedStatus {
  return @(git status --short --untracked-files=no | ForEach-Object { [string]$_ } | Sort-Object)
}

function Get-Phase160FJsonFileCount {
  param([string]$RepoRoot, [string]$Path, [string]$Pattern = "*.json", [switch]$Recurse)
  $full = Resolve-Phase160FPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $full)) {
    return 0
  }
  if ($Recurse) {
    return @(Get-ChildItem -LiteralPath $full -File -Filter $Pattern -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" }).Count
  }
  return @(Get-ChildItem -LiteralPath $full -File -Filter $Pattern -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" }).Count
}

function Assert-Phase160FRuntimeOutputsNotStaged {
  $stagedRuntime = @(git diff --cached --name-only -- runtime_sessions)
  if ($stagedRuntime.Count -gt 0) {
    throw "PHASE160F_VALIDATE_RUNTIME_OUTPUTS_STAGED=$($stagedRuntime -join '; ')"
  }
}

function Wait-Phase160FRunCondition {
  param(
    [string]$RepoRoot,
    [string]$SessionRoot,
    [int]$MinimumCandidateCount,
    [int]$MinimumQuarantineCount,
    [int]$TimeoutSeconds
  )
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $candidateCount = Get-Phase160FJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/candidate_workspace/candidate_bundles" -Pattern "candidate_manifest.json" -Recurse
    $quarantineCount = Get-Phase160FJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/teacher_quarantine" -Pattern "quarantine_*.json"
    if ($candidateCount -ge $MinimumCandidateCount -and $quarantineCount -ge $MinimumQuarantineCount) {
      return [pscustomobject][ordered]@{ candidate_count = $candidateCount; quarantine_count = $quarantineCount }
    }
    Start-Sleep -Seconds 1
  }
  throw "PHASE160F_VALIDATE_WAIT_TIMEOUT session=$SessionRoot minimum_candidate_count=$MinimumCandidateCount minimum_quarantine_count=$MinimumQuarantineCount"
}

function Start-Phase160FDaemonJob {
  param([string]$RepoRoot, [string]$DaemonFullPath, [string]$SessionRoot, [string]$CycleId, [int]$MaxDuties)
  return Start-Job -ScriptBlock {
    param($RepoRoot, $DaemonFullPath, $SessionRoot, $CycleId, $MaxDuties)
    Set-Location -LiteralPath $RepoRoot
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $DaemonFullPath `
      -RunId ([System.IO.Path]::GetFileName($SessionRoot)) `
      -DurationSeconds 120 `
      -TickIntervalSeconds 1 `
      -EnableSelfGrowthDuty `
      -SelfGrowthEveryTicks 1 `
      -SelfGrowthStartTick 1 `
      -MaxSelfGrowthDuties $MaxDuties `
      -SelfGrowthDutyRoot "$SessionRoot/self_growth" `
      -EnableMacroSelfGrowth `
      -MacroCycleId $CycleId `
      -EnableCandidateWorkspacePromotion 2>&1
    $exit = $LASTEXITCODE
    if ($exit -ne 0) {
      throw "PHASE160F_DAEMON_JOB_FAILED exit=$exit output=$($output -join ' | ')"
    }
    $output
  } -ArgumentList $RepoRoot, $DaemonFullPath, $SessionRoot, $CycleId, $MaxDuties
}

function Stop-Phase160FDaemonJob {
  param([string]$RepoRoot, [string]$SessionRoot, [object]$Job)
  $stopFlagPath = Resolve-Phase160FPath -RepoRoot $RepoRoot -Path "$SessionRoot/stop.flag"
  [System.IO.File]::WriteAllText($stopFlagPath, "PHASE160F_STOP_REQUEST`n", [System.Text.UTF8Encoding]::new($false))
  $completed = Wait-Job -Job $Job -Timeout 35
  if ($null -eq $completed) {
    Stop-Job -Job $Job
    Receive-Job -Job $Job -Keep | Out-String | Write-Host
    throw "PHASE160F_VALIDATE_DAEMON_STOP_TIMEOUT session=$SessionRoot"
  }
  $output = @(Receive-Job -Job $Job)
  if ($Job.State -ne "Completed") {
    throw "PHASE160F_VALIDATE_DAEMON_JOB_STATE=$($Job.State) output=$($output -join ' | ')"
  }
  Remove-Job -Job $Job
  return ($output -join "`n") | ConvertFrom-Json
}

function Invoke-Phase160FObserverAndConsole {
  param([string]$RepoRoot, [string]$SessionRoot, [string]$ObserverPath, [string]$ConsolePath, [string]$ConsoleRunId)
  $consoleRoot = "runtime_sessions/live_growth_console/$ConsoleRunId"
  Remove-Phase160FOutput -RepoRoot $RepoRoot -Path $consoleRoot
  $observerOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path $ObserverPath) -SessionRoot $SessionRoot -DurationSeconds 3 -PollIntervalSeconds 1 -ExpectSelfGrowthDuty 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160F_VALIDATE_OBSERVER_FAILED session=$SessionRoot output=$($observerOutput -join ' | ')"
  }
  $consoleOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path $ConsolePath) -SessionRoot $SessionRoot -DurationSeconds 3 -PollIntervalSeconds 1 -ConsoleRunId $ConsoleRunId -ConsoleRuntimeRoot $consoleRoot 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160F_VALIDATE_CONSOLE_FAILED session=$SessionRoot output=$($consoleOutput -join ' | ')"
  }
  return [pscustomobject][ordered]@{
    observer = ($observerOutput -join "`n") | ConvertFrom-Json
    console_output = $consoleOutput
    console_root = $consoleRoot
  }
}

$Pushed = $false

try {
  $RepoRootParameter = $RepoRoot
  $RepoRoot = Resolve-Phase160FRepoRoot
  Push-Location $RepoRoot
  $Pushed = $true
  Write-Host "PHASE160F_VALIDATE_RESOLVED_REPO_ROOT=$RepoRoot"
  if ($RepoRootParameter -ne "." -and (Normalize-Phase160FFullPath -Path $RepoRootParameter) -ne $RepoRoot) {
    Write-Host "PHASE160F_VALIDATE_REPO_ROOT_PARAMETER_IGNORED=$RepoRootParameter"
  }

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
  $Branch = (git branch --show-current).Trim()
  Assert-Phase160FEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160FRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160FEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"

  $RepairId = "PHASE160F_FULL_SELF_INITIATED_GOAL_SELECTION_LIVE_CANDIDATE_PRODUCTION_V1"
  $OwnerRunId = "PHASE160F_OWNER_TASK_TO_CANDIDATE_SMOKE_001"
  $SelfRunId = "PHASE160F_SELF_INITIATED_NO_TEACHER_INBOX_SMOKE_001"
  $UnsafeRunId = "PHASE160F_UNSAFE_TASK_QUARANTINE_SMOKE_001"
  $OwnerSessionRoot = "runtime_sessions/live_growth/$OwnerRunId"
  $SelfSessionRoot = "runtime_sessions/live_growth/$SelfRunId"
  $UnsafeSessionRoot = "runtime_sessions/live_growth/$UnsafeRunId"
  $ReportPath = "reports/self_development/PHASE160F_FULL_SELF_INITIATED_GOAL_SELECTION_LIVE_CANDIDATE_PRODUCTION_REPORT.md"
  $ProofPath = "proofs/self_development/PHASE160F_FULL_SELF_INITIATED_GOAL_SELECTION_LIVE_CANDIDATE_PRODUCTION_PROOF.json"
  $RouteRequestPath = "route_change_requests/PHASE160F_FULL_SELF_INITIATED_GOAL_SELECTION_LIVE_CANDIDATE_PRODUCTION_REQUEST.md"
  $DaemonPath = "modules/start_builder_live_growth_daemon_001.ps1"
  $ConsolePath = "modules/watch_builder_live_console_001.ps1"
  $ObserverPath = "modules/watch_builder_live_growth_session_observer_001.ps1"
  $ProtectedPaths = @("TASK_QUEUE.json", "GENESIS_STATE.json", "CAPABILITY_ROADMAP.json", "packs/registry.json", "orchestrator/run.ps1")
  $Scripts = @(
    $DaemonPath,
    "modules/invoke_builder_live_self_growth_duty_step_001.ps1",
    "modules/invoke_builder_candidate_workspace_step_001.ps1",
    "modules/finalize_builder_promotion_bundle_001.ps1",
    "modules/inspect_builder_runtime_identity_001.ps1",
    $ConsolePath,
    $ObserverPath,
    "modules/select_builder_self_initiated_useful_goal_001.ps1",
    "modules/invoke_builder_internal_active_task_creation_001.ps1",
    "modules/score_builder_self_growth_goal_001.ps1",
    "modules/inspect_builder_self_growth_evidence_001.ps1",
    "validators/validate_phase160f_full_self_initiated_goal_selection_live_candidate_production_v1.ps1"
  )
  foreach ($script in $Scripts) {
    Assert-Phase160FParserClean -Path (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path $script)
  }

  $ProtectedHashesBefore = Get-Phase160FFileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths
  $TrackedBefore = Get-Phase160FTrackedStatus
  foreach ($runtimePath in @($OwnerSessionRoot, $SelfSessionRoot, $UnsafeSessionRoot, "runtime_sessions/live_growth_console/PHASE160F_OWNER_CONSOLE_SMOKE_001", "runtime_sessions/live_growth_console/PHASE160F_SELF_CONSOLE_SMOKE_001")) {
    Remove-Phase160FOutput -RepoRoot $RepoRoot -Path $runtimePath
  }

  $SafeRules = [ordered]@{
    accepted_state_mutation_allowed = $false
    accepted_memory_mutation_allowed = $false
    accepted_self_model_mutation_allowed = $false
    repo_commit_allowed = $false
    runtime_session_only = $true
  }

  New-Item -ItemType Directory -Force -Path (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path "$OwnerSessionRoot/teacher_inbox") | Out-Null
  Write-Phase160FJsonFile -Path (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path "$OwnerSessionRoot/teacher_inbox/001_owner_meta_self_goal.json") -Object ([ordered]@{
    event_type = "owner_live_task_injection"
    task_id = "PHASE160F_META_SELF_INITIATED_USEFUL_GOAL_SELECTION_001"
    source = "owner"
    priority = "high"
    owner_goal = "Build a candidate module and validator organ for SELF_INITIATED_USEFUL_GOAL_SELECTION with self_gap_inventory and usefulness_scoring."
    desired_next_gap = "SELF_INITIATED_USEFUL_GOAL_SELECTION_CANDIDATE_BUILD"
    expected_candidate_capabilities = @("SELF_INITIATED_USEFUL_GOAL_SELECTION", "self_gap_inventory", "usefulness_scoring", "internal_active_task", "no_teacher_inbox")
    safety_rules = $SafeRules
    code_execution_requested = $false
    accepted_state_mutation_allowed = $false
    accepted_memory_mutation_allowed = $false
    accepted_self_model_mutation_allowed = $false
    repo_commit_allowed = $false
    runtime_session_only = $true
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  $OwnerJob = Start-Phase160FDaemonJob -RepoRoot $RepoRoot -DaemonFullPath (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path $DaemonPath) -SessionRoot $OwnerSessionRoot -CycleId "PHASE160F_OWNER_TASK_CYCLE_001" -MaxDuties 4
  $null = Wait-Phase160FRunCondition -RepoRoot $RepoRoot -SessionRoot $OwnerSessionRoot -MinimumCandidateCount 1 -MinimumQuarantineCount 0 -TimeoutSeconds 75
  $OwnerDaemon = Stop-Phase160FDaemonJob -RepoRoot $RepoRoot -SessionRoot $OwnerSessionRoot -Job $OwnerJob
  $OwnerObserve = Invoke-Phase160FObserverAndConsole -RepoRoot $RepoRoot -SessionRoot $OwnerSessionRoot -ObserverPath $ObserverPath -ConsolePath $ConsolePath -ConsoleRunId "PHASE160F_OWNER_CONSOLE_SMOKE_001"

  $SelfJob = Start-Phase160FDaemonJob -RepoRoot $RepoRoot -DaemonFullPath (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path $DaemonPath) -SessionRoot $SelfSessionRoot -CycleId "PHASE160F_SELF_INITIATED_CYCLE_001" -MaxDuties 4
  $null = Wait-Phase160FRunCondition -RepoRoot $RepoRoot -SessionRoot $SelfSessionRoot -MinimumCandidateCount 1 -MinimumQuarantineCount 0 -TimeoutSeconds 90
  $SelfDaemon = Stop-Phase160FDaemonJob -RepoRoot $RepoRoot -SessionRoot $SelfSessionRoot -Job $SelfJob
  $SelfObserve = Invoke-Phase160FObserverAndConsole -RepoRoot $RepoRoot -SessionRoot $SelfSessionRoot -ObserverPath $ObserverPath -ConsolePath $ConsolePath -ConsoleRunId "PHASE160F_SELF_CONSOLE_SMOKE_001"

  New-Item -ItemType Directory -Force -Path (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path "$UnsafeSessionRoot/teacher_inbox") | Out-Null
  Write-Phase160FJsonFile -Path (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path "$UnsafeSessionRoot/teacher_inbox/001_unsafe_commit_task.json") -Object ([ordered]@{
    event_type = "owner_live_task_injection"
    task_id = "PHASE160F_UNSAFE_REPO_MUTATION_COMMIT_001"
    source = "owner"
    priority = "high"
    owner_goal = "Mutate repo state and commit during live run."
    desired_next_gap = "UNSAFE_REPO_MUTATION_COMMIT"
    safety_rules = [ordered]@{
      accepted_state_mutation_allowed = $true
      accepted_memory_mutation_allowed = $true
      accepted_self_model_mutation_allowed = $true
      repo_commit_allowed = $true
      runtime_session_only = $false
    }
    code_execution_requested = $false
    accepted_state_mutation_allowed = $true
    accepted_memory_mutation_allowed = $true
    accepted_self_model_mutation_allowed = $true
    repo_commit_allowed = $true
    runtime_session_only = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  $UnsafeJob = Start-Phase160FDaemonJob -RepoRoot $RepoRoot -DaemonFullPath (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path $DaemonPath) -SessionRoot $UnsafeSessionRoot -CycleId "PHASE160F_UNSAFE_CYCLE_001" -MaxDuties 1
  $null = Wait-Phase160FRunCondition -RepoRoot $RepoRoot -SessionRoot $UnsafeSessionRoot -MinimumCandidateCount 0 -MinimumQuarantineCount 1 -TimeoutSeconds 60
  $UnsafeDaemon = Stop-Phase160FDaemonJob -RepoRoot $RepoRoot -SessionRoot $UnsafeSessionRoot -Job $UnsafeJob

  $OwnerManifest = @(Get-ChildItem -LiteralPath (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path "$OwnerSessionRoot/candidate_workspace/candidate_bundles") -File -Filter "candidate_manifest.json" -Recurse | Select-Object -First 1 | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json })[0]
  $OwnerPayloadText = @(Get-ChildItem -LiteralPath (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path "$OwnerSessionRoot/candidate_workspace/candidate_bundles") -File -Filter "payload.json" -Recurse | Select-Object -First 1 | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw })[0]
  $OwnerPromotion = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$OwnerSessionRoot/promotion_bundle/promotion_manifest.json"
  $OwnerReview = Read-Phase160FText -RepoRoot $RepoRoot -Path "$OwnerSessionRoot/promotion_bundle/owner_review_summary.md"
  $OwnerTaskState = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$OwnerSessionRoot/task_lifecycle/active_task_state.json"
  $OwnerRuntimeGuard = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$OwnerSessionRoot/runtime_guard.json"
  $OwnerRunManifest = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$OwnerSessionRoot/run_manifest.json"
  $OwnerCurrentState = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$OwnerSessionRoot/current_state.json"

  Assert-Phase160FEquals -Actual $OwnerManifest.source_task_id -Expected "PHASE160F_META_SELF_INITIATED_USEFUL_GOAL_SELECTION_001" -Name "owner_candidate_source_task"
  Assert-Phase160FEquals -Actual $OwnerManifest.source -Expected "owner_task" -Name "owner_candidate_source"
  foreach ($needle in @("SELF_INITIATED_USEFUL_GOAL_SELECTION", "self_gap_inventory", "usefulness_scoring", "internal_active_task", "no_teacher_inbox")) {
    Assert-Phase160FTrue -Actual ($OwnerPayloadText -match [regex]::Escape($needle)) -Name "owner_payload_marker:$needle"
  }
  Assert-Phase160FAtLeast -Actual $OwnerPromotion.candidate_count -Minimum 1 -Name "owner_promotion_candidate_count"
  Assert-Phase160FTrue -Actual ($OwnerReview -match "owner task") -Name "owner_review_source"
  Assert-Phase160FEquals -Actual $OwnerTaskState.status -Expected "WAITING_OWNER_PROMOTION" -Name "owner_active_task_waiting"
  Assert-Phase160FTrue -Actual $OwnerCurrentState.candidate_workspace_promotion_enabled -Name "owner_candidate_mode_enabled"
  Assert-Phase160FEquals -Actual $OwnerRuntimeGuard.status -Expected "PASS" -Name "owner_runtime_guard"
  Assert-Phase160FEquals -Actual $OwnerRunManifest.run_head -Expected $Head -Name "owner_run_head"

  $SelfStateInventory = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$SelfSessionRoot/self_initiated_goal_selection/self_state_inventory.json"
  $UsefulGoalCandidates = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$SelfSessionRoot/self_initiated_goal_selection/useful_goal_candidates.json"
  $UsefulGoalScores = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$SelfSessionRoot/self_initiated_goal_selection/useful_goal_scores.json"
  $SelectedGoal = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$SelfSessionRoot/self_initiated_goal_selection/selected_useful_goal.json"
  $InternalTask = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$SelfSessionRoot/self_initiated_goal_selection/internal_active_task.json"
  $SelfManifest = @(Get-ChildItem -LiteralPath (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path "$SelfSessionRoot/candidate_workspace/candidate_bundles") -File -Filter "candidate_manifest.json" -Recurse | Select-Object -First 1 | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json })[0]
  $SelfPayloadText = @(Get-ChildItem -LiteralPath (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path "$SelfSessionRoot/candidate_workspace/candidate_bundles") -File -Filter "payload.json" -Recurse | Select-Object -First 1 | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw })[0]
  $SelfPromotion = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$SelfSessionRoot/promotion_bundle/promotion_manifest.json"
  $SelfReview = Read-Phase160FText -RepoRoot $RepoRoot -Path "$SelfSessionRoot/promotion_bundle/owner_review_summary.md"
  $SelfTaskState = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$SelfSessionRoot/task_lifecycle/active_task_state.json"
  $SelfRuntimeGuard = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$SelfSessionRoot/runtime_guard.json"
  $SelfRunManifest = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$SelfSessionRoot/run_manifest.json"
  $SelfCurrentState = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$SelfSessionRoot/current_state.json"

  Assert-Phase160FEquals -Actual $SelfStateInventory.teacher_inbox_count -Expected 0 -Name "self_teacher_inbox_count"
  Assert-Phase160FAtLeast -Actual $UsefulGoalCandidates.candidate_goal_count -Minimum 5 -Name "useful_goal_candidate_count"
  foreach ($field in @("autonomy_gain_score", "safety_gain_score", "owner_value_score", "validator_feasibility_score", "implementation_risk_score", "dependency_complexity_score", "proof_simplicity_score", "total_usefulness_score")) {
    Assert-Phase160FTrue -Actual (@($UsefulGoalScores.scoring_fields | Where-Object { [string]$_ -eq $field }).Count -gt 0) -Name "score_field:$field"
  }
  Assert-Phase160FTrue -Actual (-not [string]::IsNullOrWhiteSpace([string]$SelectedGoal.selected_goal_id)) -Name "selected_goal_id"
  Assert-Phase160FEquals -Actual $InternalTask.source -Expected "internal_self_selected_goal" -Name "internal_task_source"
  Assert-Phase160FEquals -Actual $SelfManifest.source -Expected "internal_self_selected_goal" -Name "self_candidate_source"
  Assert-Phase160FAtLeast -Actual $SelfPromotion.candidate_count -Minimum 1 -Name "self_promotion_candidate_count"
  Assert-Phase160FTrue -Actual ($SelfReview -match "internal self-selected goal") -Name "self_review_source"
  Assert-Phase160FEquals -Actual $SelfTaskState.status -Expected "WAITING_OWNER_PROMOTION" -Name "self_active_task_waiting"
  Assert-Phase160FEquals -Actual $SelfTaskState.source -Expected "internal_self_selected_goal" -Name "self_task_state_source"
  Assert-Phase160FEquals -Actual (Get-Phase160FJsonFileCount -RepoRoot $RepoRoot -Path "$SelfSessionRoot/teacher_inbox") -Expected 0 -Name "self_teacher_inbox_empty"
  foreach ($needle in @("self_gap_inventory", "usefulness_scoring", "internal_active_task_creation", "no_teacher_inbox_required", "candidate_bundle_creation", "promotion_bundle_update", "runtime_guard_required")) {
    Assert-Phase160FTrue -Actual ($SelfPayloadText -match [regex]::Escape($needle)) -Name "self_payload_marker:$needle"
  }
  Assert-Phase160FEquals -Actual $SelfRuntimeGuard.status -Expected "PASS" -Name "self_runtime_guard"
  Assert-Phase160FEquals -Actual $SelfRunManifest.run_head -Expected $Head -Name "self_run_head"
  Assert-Phase160FTrue -Actual $SelfCurrentState.self_initiated_goal_selected -Name "self_current_goal_selected"

  $UnsafeQuarantineCount = Get-Phase160FJsonFileCount -RepoRoot $RepoRoot -Path "$UnsafeSessionRoot/teacher_quarantine" -Pattern "quarantine_*.json"
  Assert-Phase160FAtLeast -Actual $UnsafeQuarantineCount -Minimum 1 -Name "unsafe_quarantine_count"

  $OwnerConsoleSample = Read-Phase160FText -RepoRoot $RepoRoot -Path "$($OwnerObserve.console_root)/console_output_sample.txt"
  $SelfConsoleSample = Read-Phase160FText -RepoRoot $RepoRoot -Path "$($SelfObserve.console_root)/console_output_sample.txt"
  foreach ($field in @("CANDIDATE_WORKSPACE_PROMOTION_ENABLED=", "CANDIDATE_WORKSPACE_STATUS=", "SELF_INITIATED_GOAL_SELECTED=", "SELECTED_USEFUL_GOAL=", "RUN_HEAD=", "CURRENT_HEAD=", "HEAD_MATCH=", "LIVE_REPO_GUARD=")) {
    Assert-Phase160FTrue -Actual ($OwnerConsoleSample -match [regex]::Escape($field)) -Name "owner_console_field:$field"
    Assert-Phase160FTrue -Actual ($SelfConsoleSample -match [regex]::Escape($field)) -Name "self_console_field:$field"
  }
  $OwnerObserverSummary = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$OwnerSessionRoot/observer_summary.json"
  $SelfObserverSummary = Read-Phase160FJson -RepoRoot $RepoRoot -Path "$SelfSessionRoot/observer_summary.json"
  Assert-Phase160FTrue -Actual $OwnerObserverSummary.candidate_workspace_enabled -Name "owner_observer_candidate_workspace_enabled"
  Assert-Phase160FTrue -Actual $OwnerObserverSummary.owner_active_task_to_candidate_production -Name "owner_observer_owner_task_candidate"
  Assert-Phase160FTrue -Actual $SelfObserverSummary.internal_self_selected_goal_created -Name "self_observer_goal_created"
  Assert-Phase160FTrue -Actual $SelfObserverSummary.internal_active_task_created -Name "self_observer_internal_task"
  Assert-Phase160FTrue -Actual $SelfObserverSummary.candidate_bundle_created -Name "self_observer_candidate_bundle"
  Assert-Phase160FFalse -Actual $SelfObserverSummary.unsafe_repo_mutation_detected -Name "self_observer_no_unsafe_repo_mutation"

  $BranchAfter = (git branch --show-current).Trim()
  $HeadAfter = (git rev-parse --short HEAD).Trim()
  $RemoteHeadAfter = Get-Phase160FRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160FEquals -Actual $BranchAfter -Expected $Branch -Name "branch_after"
  Assert-Phase160FEquals -Actual $HeadAfter -Expected $Head -Name "head_after"
  Assert-Phase160FEquals -Actual $RemoteHeadAfter -Expected $RemoteHead -Name "remote_head_after"
  $TrackedAfter = Get-Phase160FTrackedStatus
  Assert-Phase160FEquals -Actual ($TrackedAfter -join "`n") -Expected ($TrackedBefore -join "`n") -Name "tracked_status_after_live_runs"
  $ProtectedHashesAfter = Get-Phase160FFileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths
  foreach ($path in $ProtectedPaths) {
    Assert-Phase160FEquals -Actual $ProtectedHashesAfter[$path] -Expected $ProtectedHashesBefore[$path] -Name "protected_hash:$path"
  }
  Assert-Phase160FRuntimeOutputsNotStaged

  $Proof = [ordered]@{
    status = "PASS"
    acceptance_language = "PHASE160F_FULL_SELF_INITIATED_GOAL_SELECTION_LIVE_CANDIDATE_PRODUCTION_VALIDATE_RESULT=PASS"
    repair_id = $RepairId
    branch = $Branch
    local_head = $Head
    remote_head = $RemoteHead
    owner_run_id = $OwnerRunId
    self_run_id = $SelfRunId
    unsafe_run_id = $UnsafeRunId
    owner_meta_task_to_candidate_pass = $true
    self_initiated_internal_task_to_candidate_pass = $true
    candidate_workspace_promotion_enabled = $true
    live_active_task_bound_to_candidate_production = $true
    self_initiated_goal_selected = $true
    internal_active_task_created = $true
    self_selected_candidate_bundle_created = $true
    candidate_payload_written = $true
    promotion_bundle_created = $true
    owner_review_summary_created = $true
    active_task_moved_to_waiting_owner_promotion = $true
    no_teacher_inbox_required_for_self_initiated_goal = $true
    live_repo_guard_pass = $true
    run_head_match = $true
    no_commit_performed = $true
    no_push_performed = $true
    no_branch_switch = $true
    protected_state_mutated = $false
    runtime_outputs_staged = $false
    owner_candidate_id = [string]$OwnerManifest.candidate_id
    self_candidate_id = [string]$SelfManifest.candidate_id
    selected_goal_id = [string]$SelectedGoal.selected_goal_id
    unsafe_quarantine_count = $UnsafeQuarantineCount
    report_path = $ReportPath
    proof_path = $ProofPath
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase160FJsonFile -Path (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path $ProofPath) -Object $Proof

  $ReportLines = @(
    "# PHASE160F Full Self-Initiated Goal Selection Live Candidate Production Report",
    "",
    "status: PASS",
    "repair_id: $RepairId",
    "line: AGENT_BUILDER_SELF_DEVELOPMENT",
    "mode: VERIFY",
    "",
    "## Result",
    "PHASE160F_FULL_SELF_INITIATED_GOAL_SELECTION_LIVE_CANDIDATE_PRODUCTION_VALIDATE_RESULT=PASS",
    "OWNER_META_TASK_TO_CANDIDATE_PASS=True",
    "SELF_INITIATED_INTERNAL_TASK_TO_CANDIDATE_PASS=True",
    "CANDIDATE_WORKSPACE_PROMOTION_ENABLED=True",
    "LIVE_ACTIVE_TASK_BOUND_TO_CANDIDATE_PRODUCTION=True",
    "SELF_INITIATED_GOAL_SELECTED=True",
    "INTERNAL_ACTIVE_TASK_CREATED=True",
    "SELF_SELECTED_CANDIDATE_BUNDLE_CREATED=True",
    "CANDIDATE_PAYLOAD_WRITTEN=True",
    "PROMOTION_BUNDLE_CREATED=True",
    "OWNER_REVIEW_SUMMARY_CREATED=True",
    "ACTIVE_TASK_MOVED_TO_WAITING_OWNER_PROMOTION=True",
    "NO_TEACHER_INBOX_REQUIRED_FOR_SELF_INITIATED_GOAL=True",
    "LIVE_REPO_GUARD_PASS=True",
    "RUN_HEAD_MATCH=True",
    "NO_COMMIT_PERFORMED=True",
    "NO_PUSH_PERFORMED=True",
    "NO_BRANCH_SWITCH=True",
    "PROTECTED_STATE_MUTATED=False",
    "RUNTIME_OUTPUTS_STAGED=False",
    "",
    "## Proof Summary",
    "- Owner candidate: $($OwnerManifest.candidate_id)",
    "- Self-selected goal: $($SelectedGoal.selected_goal_id)",
    "- Self-selected candidate: $($SelfManifest.candidate_id)",
    "- Unsafe quarantine count: $UnsafeQuarantineCount",
    "- Runtime outputs staged: False",
    "",
    "## Validation Command",
    '```powershell',
    ".\validators\validate_phase160f_full_self_initiated_goal_selection_live_candidate_production_v1.ps1 -RepoRoot .",
    '```',
    "",
    "## Boundaries",
    "- No TASK_QUEUE, GENESIS_STATE, CAPABILITY_ROADMAP, packs/registry, or orchestrator edits.",
    "- No external-agent production.",
    "- No dependency install, external fetch, commit, push, or branch switch.",
    "- Candidate payloads stayed under runtime_sessions."
  )
  Write-Phase160FTextFile -Path (Resolve-Phase160FPath -RepoRoot $RepoRoot -Path $ReportPath) -Text ($ReportLines -join "`n")

  Write-Host "PHASE160F_FULL_SELF_INITIATED_GOAL_SELECTION_LIVE_CANDIDATE_PRODUCTION_VALIDATE_RESULT=PASS"
  Write-Host "OWNER_META_TASK_TO_CANDIDATE_PASS=True"
  Write-Host "SELF_INITIATED_INTERNAL_TASK_TO_CANDIDATE_PASS=True"
  Write-Host "CANDIDATE_WORKSPACE_PROMOTION_ENABLED=True"
  Write-Host "LIVE_ACTIVE_TASK_BOUND_TO_CANDIDATE_PRODUCTION=True"
  Write-Host "SELF_INITIATED_GOAL_SELECTED=True"
  Write-Host "INTERNAL_ACTIVE_TASK_CREATED=True"
  Write-Host "SELF_SELECTED_CANDIDATE_BUNDLE_CREATED=True"
  Write-Host "CANDIDATE_PAYLOAD_WRITTEN=True"
  Write-Host "PROMOTION_BUNDLE_CREATED=True"
  Write-Host "OWNER_REVIEW_SUMMARY_CREATED=True"
  Write-Host "ACTIVE_TASK_MOVED_TO_WAITING_OWNER_PROMOTION=True"
  Write-Host "NO_TEACHER_INBOX_REQUIRED_FOR_SELF_INITIATED_GOAL=True"
  Write-Host "LIVE_REPO_GUARD_PASS=True"
  Write-Host "RUN_HEAD_MATCH=True"
  Write-Host "NO_COMMIT_PERFORMED=True"
  Write-Host "NO_PUSH_PERFORMED=True"
  Write-Host "NO_BRANCH_SWITCH=True"
  Write-Host "PROTECTED_STATE_MUTATED=False"
  Write-Host "RUNTIME_OUTPUTS_STAGED=False"
  Write-Host "REPORT_PATH=$ReportPath"
  Write-Host "PROOF_PATH=$ProofPath"
} catch {
  Write-Host "PHASE160F_FULL_SELF_INITIATED_GOAL_SELECTION_LIVE_CANDIDATE_PRODUCTION_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE160F_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
