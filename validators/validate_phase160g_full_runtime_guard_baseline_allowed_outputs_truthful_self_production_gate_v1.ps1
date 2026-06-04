param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160GFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160GRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160G_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160GFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160GPath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Assert-Phase160GPathInsideRepo {
  param([string]$RepoRoot, [string]$Path)
  $root = Normalize-Phase160GFullPath -Path $RepoRoot
  $full = Normalize-Phase160GFullPath -Path (Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $Path)
  if (-not ($full -eq $root -or $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "PHASE160G_VALIDATE_PATH_OUTSIDE_REPO=$Path"
  }
  return $full
}

function Read-Phase160GJson {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160G_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase160GText {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160G_VALIDATE_MISSING_TEXT=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw
}

function Write-Phase160GJsonFile {
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

function Write-Phase160GTextFile {
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

function Assert-Phase160GEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160G_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160GTrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160G_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160GFalse {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160G_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160GAtLeast {
  param([object]$Actual, [int]$Minimum, [string]$Name)
  if ([int]$Actual -lt $Minimum) {
    throw "PHASE160G_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase160GParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160G_VALIDATE_PARSE_ERROR=$Path message=$($parseErrors[0].Message)"
  }
}

function Remove-Phase160GOutput {
  param([string]$RepoRoot, [string]$Path)
  $full = Assert-Phase160GPathInsideRepo -RepoRoot $RepoRoot -Path $Path
  if (Test-Path -LiteralPath $full) {
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}

function Get-Phase160GRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160G_VALIDATE_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Get-Phase160GFileHashes {
  param([string]$RepoRoot, [string[]]$Paths)
  $hashes = @{}
  foreach ($path in $Paths) {
    $full = Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $path
    if (Test-Path -LiteralPath $full) {
      $hashes[$path] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = "MISSING"
    }
  }
  return $hashes
}

function Get-Phase160GJsonFileCount {
  param([string]$RepoRoot, [string]$Path, [string]$Pattern = "*.json", [switch]$Recurse)
  $full = Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $full)) {
    return 0
  }
  if ($Recurse) {
    return @(Get-ChildItem -LiteralPath $full -File -Filter $Pattern -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" }).Count
  }
  return @(Get-ChildItem -LiteralPath $full -File -Filter $Pattern -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" }).Count
}

function Assert-Phase160GRuntimeOutputsNotStaged {
  $stagedRuntime = @(git diff --cached --name-only -- runtime_sessions)
  if ($stagedRuntime.Count -gt 0) {
    throw "PHASE160G_VALIDATE_RUNTIME_OUTPUTS_STAGED=$($stagedRuntime -join '; ')"
  }
}

function Assert-Phase160GRuntimeJsonClean {
  param([string]$RepoRoot, [string[]]$SessionRoots)
  foreach ($sessionRoot in $SessionRoots) {
    $full = Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $sessionRoot
    if (-not (Test-Path -LiteralPath $full)) {
      continue
    }
    foreach ($jsonFile in @(Get-ChildItem -LiteralPath $full -File -Filter "*.json" -Recurse -ErrorAction SilentlyContinue)) {
      try {
        Get-Content -LiteralPath $jsonFile.FullName -Raw | ConvertFrom-Json | Out-Null
      } catch {
        throw "PHASE160G_VALIDATE_RUNTIME_JSON_PARSE_ERROR=$($jsonFile.FullName) message=$($_.Exception.Message)"
      }
    }
  }
}

function Wait-Phase160GRunCondition {
  param([string]$RepoRoot, [string]$SessionRoot, [int]$MinimumCandidateCount, [int]$TimeoutSeconds)
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $candidateCount = Get-Phase160GJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/candidate_workspace/candidate_bundles" -Pattern "candidate_manifest.json" -Recurse
    if ($candidateCount -ge $MinimumCandidateCount) {
      return [pscustomobject][ordered]@{ candidate_count = $candidateCount }
    }
    Start-Sleep -Seconds 1
  }
  throw "PHASE160G_VALIDATE_WAIT_TIMEOUT session=$SessionRoot minimum_candidate_count=$MinimumCandidateCount"
}

function Start-Phase160GDaemonJob {
  param([string]$RepoRoot, [string]$DaemonFullPath, [string]$SessionRoot, [string]$CycleId)
  return Start-Job -ScriptBlock {
    param($RepoRoot, $DaemonFullPath, $SessionRoot, $CycleId)
    Set-Location -LiteralPath $RepoRoot
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $DaemonFullPath `
      -RunId ([System.IO.Path]::GetFileName($SessionRoot)) `
      -DurationSeconds 90 `
      -TickIntervalSeconds 1 `
      -EnableSelfGrowthDuty `
      -SelfGrowthEveryTicks 1 `
      -SelfGrowthStartTick 1 `
      -MaxSelfGrowthDuties 2 `
      -SelfGrowthDutyRoot "$SessionRoot/self_growth" `
      -EnableMacroSelfGrowth `
      -MacroCycleId $CycleId `
      -EnableCandidateWorkspacePromotion 2>&1
    $exit = $LASTEXITCODE
    if ($exit -ne 0) {
      throw "PHASE160G_DAEMON_JOB_FAILED exit=$exit output=$($output -join ' | ')"
    }
    $output
  } -ArgumentList $RepoRoot, $DaemonFullPath, $SessionRoot, $CycleId
}

function Stop-Phase160GDaemonJob {
  param([string]$RepoRoot, [string]$SessionRoot, [object]$Job)
  $stopFlagPath = Resolve-Phase160GPath -RepoRoot $RepoRoot -Path "$SessionRoot/stop.flag"
  [System.IO.File]::WriteAllText($stopFlagPath, "PHASE160G_STOP_REQUEST`n", [System.Text.UTF8Encoding]::new($false))
  $completed = Wait-Job -Job $Job -Timeout 35
  if ($null -eq $completed) {
    Stop-Job -Job $Job
    $output = @(Receive-Job -Job $Job -Keep)
    throw "PHASE160G_VALIDATE_DAEMON_STOP_TIMEOUT session=$SessionRoot output=$($output -join ' | ')"
  }
  $jobOutput = @(Receive-Job -Job $Job)
  if ($Job.State -ne "Completed") {
    throw "PHASE160G_VALIDATE_DAEMON_JOB_STATE=$($Job.State) output=$($jobOutput -join ' | ')"
  }
  Remove-Job -Job $Job
  return ($jobOutput -join "`n") | ConvertFrom-Json
}

function Invoke-Phase160GObserverAndConsole {
  param([string]$RepoRoot, [string]$SessionRoot, [string]$ObserverPath, [string]$ConsolePath, [string]$ConsoleRunId)
  $consoleRoot = "runtime_sessions/live_growth_console/$ConsoleRunId"
  Remove-Phase160GOutput -RepoRoot $RepoRoot -Path $consoleRoot
  $observerOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $ObserverPath) -SessionRoot $SessionRoot -DurationSeconds 3 -PollIntervalSeconds 1 -ExpectSelfGrowthDuty 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160G_VALIDATE_OBSERVER_FAILED session=$SessionRoot output=$($observerOutput -join ' | ')"
  }
  $consoleOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $ConsolePath) -SessionRoot $SessionRoot -DurationSeconds 3 -PollIntervalSeconds 1 -ConsoleRunId $ConsoleRunId -ConsoleRuntimeRoot $consoleRoot 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160G_VALIDATE_CONSOLE_FAILED session=$SessionRoot output=$($consoleOutput -join ' | ')"
  }
  return [pscustomobject][ordered]@{
    observer = ($observerOutput -join "`n") | ConvertFrom-Json
    console_root = $consoleRoot
  }
}

function Invoke-Phase160GIdentity {
  param([string]$RepoRoot, [string]$SessionRoot, [string]$RunId, [string]$Mode, [string]$GuardLabel)
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160GPath -RepoRoot $RepoRoot -Path "modules/inspect_builder_runtime_identity_001.ps1") -SessionRoot $SessionRoot -RunId $RunId -Mode $Mode -GuardLabel $GuardLabel 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160G_VALIDATE_IDENTITY_FAILED mode=$Mode session=$SessionRoot output=$($output -join ' | ')"
  }
  return ($output -join "`n") | ConvertFrom-Json
}

function Invoke-Phase160GCandidateStep {
  param([string]$RepoRoot, [string]$SessionRoot, [string]$RunId, [string]$DutyId)
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160GPath -RepoRoot $RepoRoot -Path "modules/invoke_builder_candidate_workspace_step_001.ps1") -SessionRoot $SessionRoot -RunId $RunId -DutyId $DutyId -TickNumber 0 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160G_VALIDATE_CANDIDATE_STEP_FAILED session=$SessionRoot output=$($output -join ' | ')"
  }
  return ($output -join "`n") | ConvertFrom-Json
}

function Invoke-Phase160GFinalizePromotion {
  param([string]$RepoRoot, [string]$SessionRoot, [string]$RunId)
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160GPath -RepoRoot $RepoRoot -Path "modules/finalize_builder_promotion_bundle_001.ps1") -SessionRoot $SessionRoot -RunId $RunId -WriteFinalHandoff 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160G_VALIDATE_FINALIZE_FAILED session=$SessionRoot output=$($output -join ' | ')"
  }
  return ($output -join "`n") | ConvertFrom-Json
}

$Pushed = $false

try {
  $RepoRootParameter = $RepoRoot
  $RepoRoot = Resolve-Phase160GRepoRoot
  Push-Location $RepoRoot
  $Pushed = $true
  Write-Host "PHASE160G_VALIDATE_RESOLVED_REPO_ROOT=$RepoRoot"
  if ($RepoRootParameter -ne "." -and (Normalize-Phase160GFullPath -Path $RepoRootParameter) -ne $RepoRoot) {
    Write-Host "PHASE160G_VALIDATE_REPO_ROOT_PARAMETER_IGNORED=$RepoRootParameter"
  }

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
  $Branch = (git branch --show-current).Trim()
  Assert-Phase160GEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160GRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160GEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"

  $RepairId = "PHASE160G_FULL_RUNTIME_GUARD_BASELINE_ALLOWED_OUTPUTS_AND_TRUTHFUL_SELF_PRODUCTION_GATE_REPAIR_V1"
  $AllowedRunId = "PHASE160G_ALLOWED_RUNTIME_OUTPUTS_SELF_PRODUCTION_SMOKE_001"
  $ZeroRunId = "PHASE160G_ZERO_CANDIDATE_PROMOTION_TRUTH_SMOKE_001"
  $UnsafeRunId = "PHASE160G_UNSAFE_TRACKED_MUTATION_BLOCK_SMOKE_001"
  $ProtectedRunId = "PHASE160G_PROTECTED_STATE_BLOCK_SMOKE_001"
  $SampleRunId = "PHASE160G_TRACKED_CONSOLE_SAMPLE_ALLOWED_SMOKE_001"
  $AllowedSessionRoot = "runtime_sessions/live_growth/$AllowedRunId"
  $ZeroSessionRoot = "runtime_sessions/live_growth/$ZeroRunId"
  $UnsafeSessionRoot = "runtime_sessions/live_growth/$UnsafeRunId"
  $ProtectedSessionRoot = "runtime_sessions/live_growth/$ProtectedRunId"
  $SampleSessionRoot = "runtime_sessions/live_growth/$SampleRunId"
  $ReportPath = "reports/self_development/PHASE160G_FULL_RUNTIME_GUARD_BASELINE_ALLOWED_OUTPUTS_TRUTHFUL_SELF_PRODUCTION_GATE_REPORT.md"
  $ProofPath = "proofs/self_development/PHASE160G_FULL_RUNTIME_GUARD_BASELINE_ALLOWED_OUTPUTS_TRUTHFUL_SELF_PRODUCTION_GATE_PROOF.json"
  $RouteRequestPath = "route_change_requests/PHASE160G_FULL_RUNTIME_GUARD_BASELINE_ALLOWED_OUTPUTS_TRUTHFUL_SELF_PRODUCTION_GATE_REQUEST.md"
  $DaemonPath = "modules/start_builder_live_growth_daemon_001.ps1"
  $ConsolePath = "modules/watch_builder_live_console_001.ps1"
  $ObserverPath = "modules/watch_builder_live_growth_session_observer_001.ps1"
  $UnsafeFixturePath = "modules/invoke_builder_internal_active_task_creation_001.ps1"
  $ProtectedFixturePath = "TASK_QUEUE.json"
  $TrackedConsoleSamplePath = "runtime_sessions/live_growth_console/PHASE160_LIVE_OBSERVER_CONSOLE_REPAIR_001/console_output_sample.txt"
  $ProtectedPaths = @("TASK_QUEUE.json", "GENESIS_STATE.json", "CAPABILITY_ROADMAP.json", "packs/registry.json", "orchestrator/run.ps1")
  $TouchedScripts = @(
    $DaemonPath,
    "modules/invoke_builder_live_self_growth_duty_step_001.ps1",
    "modules/invoke_builder_candidate_workspace_step_001.ps1",
    "modules/finalize_builder_promotion_bundle_001.ps1",
    "modules/inspect_builder_runtime_identity_001.ps1",
    $ConsolePath,
    $ObserverPath,
    "modules/select_builder_self_initiated_useful_goal_001.ps1",
    "modules/invoke_builder_internal_active_task_creation_001.ps1",
    "validators/validate_phase160g_full_runtime_guard_baseline_allowed_outputs_truthful_self_production_gate_v1.ps1"
  )
  foreach ($script in $TouchedScripts) {
    Assert-Phase160GParserClean -Path (Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $script)
  }

  $ProtectedHashesBefore = Get-Phase160GFileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths
  $UnsafeFixtureOriginal = [System.IO.File]::ReadAllText((Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $UnsafeFixturePath))
  $ProtectedFixtureOriginal = [System.IO.File]::ReadAllText((Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $ProtectedFixturePath))
  $TrackedSampleOriginal = [System.IO.File]::ReadAllText((Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $TrackedConsoleSamplePath))
  $FixtureHashesBefore = Get-Phase160GFileHashes -RepoRoot $RepoRoot -Paths @($UnsafeFixturePath, $TrackedConsoleSamplePath)

  foreach ($runtimePath in @(
    $AllowedSessionRoot,
    $ZeroSessionRoot,
    $UnsafeSessionRoot,
    $ProtectedSessionRoot,
    $SampleSessionRoot,
    "runtime_sessions/live_growth_console/PHASE160G_ALLOWED_CONSOLE_SMOKE_001"
  )) {
    Remove-Phase160GOutput -RepoRoot $RepoRoot -Path $runtimePath
  }

  $AllowedJob = Start-Phase160GDaemonJob -RepoRoot $RepoRoot -DaemonFullPath (Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $DaemonPath) -SessionRoot $AllowedSessionRoot -CycleId "PHASE160G_ALLOWED_RUNTIME_OUTPUTS_CYCLE_001"
  $null = Wait-Phase160GRunCondition -RepoRoot $RepoRoot -SessionRoot $AllowedSessionRoot -MinimumCandidateCount 1 -TimeoutSeconds 75
  $AllowedDaemon = Stop-Phase160GDaemonJob -RepoRoot $RepoRoot -SessionRoot $AllowedSessionRoot -Job $AllowedJob
  $AllowedObserve = Invoke-Phase160GObserverAndConsole -RepoRoot $RepoRoot -SessionRoot $AllowedSessionRoot -ObserverPath $ObserverPath -ConsolePath $ConsolePath -ConsoleRunId "PHASE160G_ALLOWED_CONSOLE_SMOKE_001"

  $RunManifest = Read-Phase160GJson -RepoRoot $RepoRoot -Path "$AllowedSessionRoot/run_manifest.json"
  $RuntimeGuard = Read-Phase160GJson -RepoRoot $RepoRoot -Path "$AllowedSessionRoot/runtime_guard.json"
  Assert-Phase160GEquals -Actual $RunManifest.run_manifest_status -Expected "PASS" -Name "run_manifest_status"
  foreach ($field in @("run_id", "repo_root", "branch", "current_branch", "run_head", "current_head", "head_match", "branch_match", "started_at", "live_repo_mutation_allowed", "commit_allowed", "push_allowed", "branch_switch_allowed", "protected_state_mutation_allowed", "runtime_only_write_policy", "key_script_paths", "key_script_hashes", "tracked_status_baseline", "protected_status_at_start")) {
    Assert-Phase160GTrue -Actual ($RunManifest.PSObject.Properties.Name -contains $field) -Name "run_manifest_field:$field"
  }
  Assert-Phase160GTrue -Actual ($RunManifest.tracked_status_baseline.PSObject.Properties.Name -contains "clean") -Name "baseline_clean_field"
  Assert-Phase160GTrue -Actual ($RunManifest.tracked_status_baseline.PSObject.Properties.Name -contains "status_lines") -Name "baseline_status_lines_field"
  if (@($RunManifest.tracked_status_baseline.status_lines).Count -eq 0) {
    Assert-Phase160GTrue -Actual $RunManifest.tracked_status_baseline.clean -Name "empty_baseline_explicit_clean"
  }
  Assert-Phase160GEquals -Actual $RuntimeGuard.status -Expected "PASS" -Name "allowed_runtime_guard_pass"
  Assert-Phase160GTrue -Actual $RuntimeGuard.candidate_production_enabled -Name "allowed_candidate_production_enabled"
  Assert-Phase160GAtLeast -Actual $RuntimeGuard.allowed_runtime_output_count -Minimum 1 -Name "allowed_runtime_output_count"
  Assert-Phase160GEquals -Actual $RuntimeGuard.unsafe_tracked_code_mutation_count -Expected 0 -Name "allowed_unsafe_mutation_count"
  Assert-Phase160GEquals -Actual $RuntimeGuard.protected_state_mutation_count -Expected 0 -Name "allowed_protected_mutation_count"
  Assert-Phase160GEquals -Actual $RuntimeGuard.unknown_status_line_count -Expected 0 -Name "allowed_unknown_count"

  $SelfStateInventory = Read-Phase160GJson -RepoRoot $RepoRoot -Path "$AllowedSessionRoot/self_initiated_goal_selection/self_state_inventory.json"
  $UsefulGoalCandidates = Read-Phase160GJson -RepoRoot $RepoRoot -Path "$AllowedSessionRoot/self_initiated_goal_selection/useful_goal_candidates.json"
  $UsefulGoalScores = Read-Phase160GJson -RepoRoot $RepoRoot -Path "$AllowedSessionRoot/self_initiated_goal_selection/useful_goal_scores.json"
  $SelectedGoal = Read-Phase160GJson -RepoRoot $RepoRoot -Path "$AllowedSessionRoot/self_initiated_goal_selection/selected_useful_goal.json"
  $InternalTask = Read-Phase160GJson -RepoRoot $RepoRoot -Path "$AllowedSessionRoot/self_initiated_goal_selection/internal_active_task.json"
  $ActiveInternalTask = Read-Phase160GJson -RepoRoot $RepoRoot -Path "$AllowedSessionRoot/active_task/internal_self_selected_active_task.json"
  $TaskState = Read-Phase160GJson -RepoRoot $RepoRoot -Path "$AllowedSessionRoot/task_lifecycle/active_task_state.json"
  Assert-Phase160GEquals -Actual $SelfStateInventory.teacher_inbox_count -Expected 0 -Name "self_teacher_inbox_count"
  Assert-Phase160GAtLeast -Actual $UsefulGoalCandidates.candidate_goal_count -Minimum 5 -Name "useful_goal_candidate_count"
  foreach ($field in @("autonomy_gain_score", "safety_gain_score", "owner_value_score", "validator_feasibility_score", "implementation_risk_score", "dependency_complexity_score", "proof_simplicity_score", "total_usefulness_score")) {
    Assert-Phase160GTrue -Actual (@($UsefulGoalScores.scoring_fields | Where-Object { [string]$_ -eq $field }).Count -gt 0) -Name "score_field:$field"
  }
  Assert-Phase160GTrue -Actual (-not [string]::IsNullOrWhiteSpace([string]$SelectedGoal.selected_goal_id)) -Name "selected_goal_id"
  Assert-Phase160GEquals -Actual $InternalTask.source -Expected "internal_self_selected_goal" -Name "internal_task_source"
  Assert-Phase160GEquals -Actual $ActiveInternalTask.source -Expected "internal_self_selected_goal" -Name "active_internal_task_source"
  Assert-Phase160GEquals -Actual $TaskState.source -Expected "internal_self_selected_goal" -Name "task_state_source"
  Assert-Phase160GEquals -Actual $TaskState.owner_approval_required -Expected $true -Name "task_state_owner_approval"
  Assert-Phase160GEquals -Actual $TaskState.desired_next_gap -Expected "SELF_SELECTED_USEFUL_CANDIDATE_PRODUCTION" -Name "task_state_desired_gap"

  $CandidateManifest = @(Get-ChildItem -LiteralPath (Resolve-Phase160GPath -RepoRoot $RepoRoot -Path "$AllowedSessionRoot/candidate_workspace/candidate_bundles") -File -Filter "candidate_manifest.json" -Recurse | Select-Object -First 1 | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json })[0]
  $CandidatePayloadText = @(Get-ChildItem -LiteralPath (Resolve-Phase160GPath -RepoRoot $RepoRoot -Path "$AllowedSessionRoot/candidate_workspace/candidate_bundles") -File -Filter "payload.json" -Recurse | Select-Object -First 1 | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw })[0]
  Assert-Phase160GEquals -Actual $CandidateManifest.source -Expected "internal_self_selected_goal" -Name "candidate_source"
  foreach ($field in @("candidate_id", "created_from_run_head", "proposed_file_paths", "proposed_validator_paths", "owner_approval_required", "repo_mutation_performed", "commit_performed", "push_performed", "branch_switch_performed", "protected_state_mutated")) {
    Assert-Phase160GTrue -Actual ($CandidateManifest.PSObject.Properties.Name -contains $field) -Name "candidate_manifest_field:$field"
  }
  Assert-Phase160GTrue -Actual $CandidateManifest.owner_approval_required -Name "candidate_owner_approval"
  Assert-Phase160GFalse -Actual $CandidateManifest.repo_mutation_performed -Name "candidate_no_repo_mutation"
  foreach ($needle in @("self_gap_inventory", "usefulness_scoring", "internal_active_task", "no_teacher_inbox_required", "candidate_bundle_creation", "promotion_bundle_update", "runtime_guard_required")) {
    Assert-Phase160GTrue -Actual ($CandidatePayloadText -match [regex]::Escape($needle)) -Name "candidate_payload_marker:$needle"
  }

  $PromotionManifest = Read-Phase160GJson -RepoRoot $RepoRoot -Path "$AllowedSessionRoot/promotion_bundle/promotion_manifest.json"
  $OwnerReview = Read-Phase160GText -RepoRoot $RepoRoot -Path "$AllowedSessionRoot/promotion_bundle/owner_review_summary.md"
  Assert-Phase160GAtLeast -Actual $PromotionManifest.candidate_count -Minimum 1 -Name "promotion_candidate_count"
  Assert-Phase160GAtLeast -Actual $PromotionManifest.ready_candidate_count -Minimum 1 -Name "promotion_ready_count"
  Assert-Phase160GEquals -Actual $PromotionManifest.promotion_status -Expected "WAITING_OWNER_REVIEW" -Name "promotion_status_with_candidate"
  Assert-Phase160GTrue -Actual ($OwnerReview -match "internal self-selected goal") -Name "owner_review_truthful_source"
  Assert-Phase160GTrue -Actual $AllowedObserve.observer.guard_pass_with_allowed_runtime_outputs -Name "observer_allowed_runtime_pass"
  Assert-Phase160GTrue -Actual $AllowedObserve.observer.promotion_bundle_with_real_candidate_only -Name "observer_real_candidate_promotion"
  $ConsoleSample = Read-Phase160GText -RepoRoot $RepoRoot -Path "$($AllowedObserve.console_root)/console_output_sample.txt"
  foreach ($field in @("LIVE_REPO_GUARD=", "RUNTIME_GUARD_STATUS=", "GUARD_BLOCK_REASON=", "ALLOWED_RUNTIME_OUTPUT_COUNT=", "ALLOWED_TRACKED_RUNTIME_SAMPLE_CHANGE=", "UNSAFE_TRACKED_MUTATION_COUNT=", "PROTECTED_STATE_MUTATION_COUNT=", "CANDIDATE_PRODUCTION_ENABLED=", "CANDIDATE_WORKSPACE_PROMOTION_ENABLED=", "CANDIDATE_WORKSPACE_STATUS=", "SELF_INITIATED_GOAL_SELECTED=", "SELECTED_USEFUL_GOAL=", "INTERNAL_ACTIVE_TASK_CREATED=", "CANDIDATE_COUNT=", "READY_CANDIDATE_COUNT=", "PROMOTION_BUNDLE_STATUS=", "LAST_CANDIDATE_ID=")) {
    Assert-Phase160GTrue -Actual ($ConsoleSample -match [regex]::Escape($field)) -Name "console_field:$field"
  }

  Remove-Phase160GOutput -RepoRoot $RepoRoot -Path $ZeroSessionRoot
  $null = Invoke-Phase160GIdentity -RepoRoot $RepoRoot -SessionRoot $ZeroSessionRoot -RunId $ZeroRunId -Mode "Initialize" -GuardLabel "zero_candidate_initialize"
  $null = Invoke-Phase160GFinalizePromotion -RepoRoot $RepoRoot -SessionRoot $ZeroSessionRoot -RunId $ZeroRunId
  $ZeroPromotion = Read-Phase160GJson -RepoRoot $RepoRoot -Path "$ZeroSessionRoot/promotion_bundle/promotion_manifest.json"
  $ZeroReview = Read-Phase160GText -RepoRoot $RepoRoot -Path "$ZeroSessionRoot/promotion_bundle/owner_review_summary.md"
  Assert-Phase160GEquals -Actual $ZeroPromotion.candidate_count -Expected 0 -Name "zero_candidate_count"
  Assert-Phase160GTrue -Actual (@("NO_CANDIDATES", "BLOCKED_NO_CANDIDATES") -contains [string]$ZeroPromotion.promotion_status) -Name "zero_candidate_truth_status"
  Assert-Phase160GFalse -Actual ([string]$ZeroPromotion.promotion_status -eq "WAITING_OWNER_REVIEW") -Name "zero_candidate_not_waiting"
  Assert-Phase160GTrue -Actual ($ZeroReview -match "No candidate was created") -Name "zero_review_no_candidate"
  Assert-Phase160GTrue -Actual ($ZeroReview -match "Nothing is ready for promotion") -Name "zero_review_nothing_ready"

  Remove-Phase160GOutput -RepoRoot $RepoRoot -Path $UnsafeSessionRoot
  $null = Invoke-Phase160GIdentity -RepoRoot $RepoRoot -SessionRoot $UnsafeSessionRoot -RunId $UnsafeRunId -Mode "Initialize" -GuardLabel "unsafe_initialize"
  try {
    [System.IO.File]::AppendAllText((Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $UnsafeFixturePath), "`n# PHASE160G_TEMP_UNSAFE_MUTATION`n", [System.Text.UTF8Encoding]::new($false))
    $UnsafeGuardResult = Invoke-Phase160GIdentity -RepoRoot $RepoRoot -SessionRoot $UnsafeSessionRoot -RunId $UnsafeRunId -Mode "GuardCheck" -GuardLabel "unsafe_mutation_guard"
    $UnsafeStep = Invoke-Phase160GCandidateStep -RepoRoot $RepoRoot -SessionRoot $UnsafeSessionRoot -RunId $UnsafeRunId -DutyId "unsafe_mutation"
    $UnsafeGuard = Read-Phase160GJson -RepoRoot $RepoRoot -Path "$UnsafeSessionRoot/runtime_guard.json"
    Assert-Phase160GEquals -Actual $UnsafeGuard.status -Expected "BLOCKED" -Name "unsafe_guard_blocked"
    Assert-Phase160GFalse -Actual $UnsafeGuard.candidate_production_enabled -Name "unsafe_candidate_disabled"
    Assert-Phase160GAtLeast -Actual $UnsafeGuard.unsafe_tracked_code_mutation_count -Minimum 1 -Name "unsafe_mutation_count"
    Assert-Phase160GEquals -Actual $UnsafeStep.status -Expected "BLOCKED" -Name "unsafe_candidate_step_blocked"
    Assert-Phase160GAtLeast -Actual (Get-Phase160GJsonFileCount -RepoRoot $RepoRoot -Path "$UnsafeSessionRoot/blocker_queue" -Pattern "blocker_candidate_workspace_runtime_guard_*.json") -Minimum 1 -Name "unsafe_blocker_written"
  } finally {
    [System.IO.File]::WriteAllText((Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $UnsafeFixturePath), $UnsafeFixtureOriginal, [System.Text.UTF8Encoding]::new($false))
  }

  Remove-Phase160GOutput -RepoRoot $RepoRoot -Path $ProtectedSessionRoot
  $null = Invoke-Phase160GIdentity -RepoRoot $RepoRoot -SessionRoot $ProtectedSessionRoot -RunId $ProtectedRunId -Mode "Initialize" -GuardLabel "protected_initialize"
  try {
    [System.IO.File]::AppendAllText((Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $ProtectedFixturePath), "`n", [System.Text.UTF8Encoding]::new($false))
    $ProtectedGuardResult = Invoke-Phase160GIdentity -RepoRoot $RepoRoot -SessionRoot $ProtectedSessionRoot -RunId $ProtectedRunId -Mode "GuardCheck" -GuardLabel "protected_mutation_guard"
    $ProtectedStep = Invoke-Phase160GCandidateStep -RepoRoot $RepoRoot -SessionRoot $ProtectedSessionRoot -RunId $ProtectedRunId -DutyId "protected_mutation"
    $ProtectedGuard = Read-Phase160GJson -RepoRoot $RepoRoot -Path "$ProtectedSessionRoot/runtime_guard.json"
    Assert-Phase160GEquals -Actual $ProtectedGuard.status -Expected "BLOCKED" -Name "protected_guard_blocked"
    Assert-Phase160GFalse -Actual $ProtectedGuard.candidate_production_enabled -Name "protected_candidate_disabled"
    Assert-Phase160GAtLeast -Actual $ProtectedGuard.protected_state_mutation_count -Minimum 1 -Name "protected_mutation_count"
    Assert-Phase160GEquals -Actual $ProtectedStep.status -Expected "BLOCKED" -Name "protected_candidate_step_blocked"
  } finally {
    [System.IO.File]::WriteAllText((Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $ProtectedFixturePath), $ProtectedFixtureOriginal, [System.Text.UTF8Encoding]::new($false))
  }

  Remove-Phase160GOutput -RepoRoot $RepoRoot -Path $SampleSessionRoot
  $null = Invoke-Phase160GIdentity -RepoRoot $RepoRoot -SessionRoot $SampleSessionRoot -RunId $SampleRunId -Mode "Initialize" -GuardLabel "sample_initialize"
  try {
    [System.IO.File]::AppendAllText((Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $TrackedConsoleSamplePath), "`nPHASE160G_ALLOWED_TRACKED_SAMPLE_CHANGE`n", [System.Text.UTF8Encoding]::new($false))
    $SampleGuardResult = Invoke-Phase160GIdentity -RepoRoot $RepoRoot -SessionRoot $SampleSessionRoot -RunId $SampleRunId -Mode "GuardCheck" -GuardLabel "tracked_console_sample_guard"
    $SampleGuard = Read-Phase160GJson -RepoRoot $RepoRoot -Path "$SampleSessionRoot/runtime_guard.json"
    Assert-Phase160GEquals -Actual $SampleGuard.status -Expected "PASS" -Name "sample_guard_pass"
    Assert-Phase160GTrue -Actual $SampleGuard.allowed_tracked_runtime_sample_change -Name "sample_allowed_tracked_change"
    Assert-Phase160GTrue -Actual $SampleGuard.candidate_production_enabled -Name "sample_candidate_enabled"
  } finally {
    [System.IO.File]::WriteAllText((Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $TrackedConsoleSamplePath), $TrackedSampleOriginal, [System.Text.UTF8Encoding]::new($false))
  }

  Assert-Phase160GRuntimeJsonClean -RepoRoot $RepoRoot -SessionRoots @($AllowedSessionRoot, $ZeroSessionRoot, $UnsafeSessionRoot, $ProtectedSessionRoot, $SampleSessionRoot, $AllowedObserve.console_root)

  $BranchAfter = (git branch --show-current).Trim()
  $HeadAfter = (git rev-parse --short HEAD).Trim()
  $RemoteHeadAfter = Get-Phase160GRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160GEquals -Actual $BranchAfter -Expected $Branch -Name "branch_after"
  Assert-Phase160GEquals -Actual $HeadAfter -Expected $Head -Name "head_after"
  Assert-Phase160GEquals -Actual $RemoteHeadAfter -Expected $RemoteHead -Name "remote_head_after"
  $ProtectedHashesAfter = Get-Phase160GFileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths
  foreach ($path in $ProtectedPaths) {
    Assert-Phase160GEquals -Actual $ProtectedHashesAfter[$path] -Expected $ProtectedHashesBefore[$path] -Name "protected_hash:$path"
  }
  $FixtureHashesAfter = Get-Phase160GFileHashes -RepoRoot $RepoRoot -Paths @($UnsafeFixturePath, $TrackedConsoleSamplePath)
  foreach ($path in @($UnsafeFixturePath, $TrackedConsoleSamplePath)) {
    Assert-Phase160GEquals -Actual $FixtureHashesAfter[$path] -Expected $FixtureHashesBefore[$path] -Name "fixture_hash_restored:$path"
  }
  Assert-Phase160GRuntimeOutputsNotStaged

  $Proof = [ordered]@{
    status = "PASS"
    acceptance_language = "PHASE160G_FULL_RUNTIME_GUARD_BASELINE_ALLOWED_OUTPUTS_TRUTHFUL_SELF_PRODUCTION_GATE_VALIDATE_RESULT=PASS"
    repair_id = $RepairId
    branch = $Branch
    local_head = $Head
    remote_head = $RemoteHead
    allowed_run_id = $AllowedRunId
    zero_candidate_run_id = $ZeroRunId
    unsafe_mutation_run_id = $UnsafeRunId
    protected_state_run_id = $ProtectedRunId
    tracked_sample_run_id = $SampleRunId
    run_manifest_baseline_captured = $true
    allowed_runtime_outputs_do_not_block = $true
    allowed_tracked_runtime_sample_does_not_block = $true
    unsafe_tracked_code_mutation_blocks = $true
    protected_state_mutation_blocks = $true
    candidate_production_enabled_with_allowed_runtime_outputs = $true
    self_initiated_goal_selected = $true
    internal_active_task_created = $true
    self_selected_candidate_bundle_created = $true
    candidate_payload_written = $true
    promotion_bundle_created = $true
    zero_candidate_promotion_not_waiting_owner_review = $true
    owner_review_summary_truthful = $true
    live_repo_guard_pass = $true
    run_head_match = $true
    no_commit_performed = $true
    no_push_performed = $true
    no_branch_switch = $true
    protected_state_mutated = $false
    runtime_outputs_staged = $false
    selected_goal_id = [string]$SelectedGoal.selected_goal_id
    candidate_id = [string]$CandidateManifest.candidate_id
    zero_candidate_promotion_status = [string]$ZeroPromotion.promotion_status
    unsafe_blocked_reasons = @($UnsafeGuard.blocked_reasons)
    protected_blocked_reasons = @($ProtectedGuard.blocked_reasons)
    sample_allowed_tracked_runtime_sample_change = [bool]$SampleGuard.allowed_tracked_runtime_sample_change
    report_path = $ReportPath
    proof_path = $ProofPath
    route_request_path = $RouteRequestPath
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase160GJsonFile -Path (Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $ProofPath) -Object $Proof

  $ReportLines = @(
    "# PHASE160G Runtime Guard Baseline, Allowed Outputs, And Truthful Self-Production Gate Report",
    "",
    "status: PASS",
    "repair_id: $RepairId",
    "line: AGENT_BUILDER_SELF_DEVELOPMENT",
    "mode: VERIFY",
    "",
    "## Result",
    "PHASE160G_FULL_RUNTIME_GUARD_BASELINE_ALLOWED_OUTPUTS_TRUTHFUL_SELF_PRODUCTION_GATE_VALIDATE_RESULT=PASS",
    "RUN_MANIFEST_BASELINE_CAPTURED=True",
    "ALLOWED_RUNTIME_OUTPUTS_DO_NOT_BLOCK=True",
    "ALLOWED_TRACKED_RUNTIME_SAMPLE_DOES_NOT_BLOCK=True",
    "UNSAFE_TRACKED_CODE_MUTATION_BLOCKS=True",
    "PROTECTED_STATE_MUTATION_BLOCKS=True",
    "CANDIDATE_PRODUCTION_ENABLED_WITH_ALLOWED_RUNTIME_OUTPUTS=True",
    "SELF_INITIATED_GOAL_SELECTED=True",
    "INTERNAL_ACTIVE_TASK_CREATED=True",
    "SELF_SELECTED_CANDIDATE_BUNDLE_CREATED=True",
    "CANDIDATE_PAYLOAD_WRITTEN=True",
    "PROMOTION_BUNDLE_CREATED=True",
    "ZERO_CANDIDATE_PROMOTION_NOT_WAITING_OWNER_REVIEW=True",
    "OWNER_REVIEW_SUMMARY_TRUTHFUL=True",
    "LIVE_REPO_GUARD_PASS=True",
    "RUN_HEAD_MATCH=True",
    "NO_COMMIT_PERFORMED=True",
    "NO_PUSH_PERFORMED=True",
    "NO_BRANCH_SWITCH=True",
    "PROTECTED_STATE_MUTATED=False",
    "RUNTIME_OUTPUTS_STAGED=False",
    "",
    "## Proof Summary",
    "- Allowed-runtime self-production run: $AllowedRunId",
    "- Candidate: $($CandidateManifest.candidate_id)",
    "- Self-selected goal: $($SelectedGoal.selected_goal_id)",
    "- Zero-candidate status: $($ZeroPromotion.promotion_status)",
    "- Unsafe code mutation blocked: True",
    "- Protected state mutation blocked: True",
    "- Runtime outputs staged: False",
    "",
    "## Validation Command",
    '```powershell',
    ".\validators\validate_phase160g_full_runtime_guard_baseline_allowed_outputs_truthful_self_production_gate_v1.ps1 -RepoRoot .",
    '```',
    "",
    "## Boundaries",
    "- No TASK_QUEUE, GENESIS_STATE, CAPABILITY_ROADMAP, packs/registry, or orchestrator persistent edits.",
    "- Temporary unsafe/protected/sample mutations were restored before PASS.",
    "- No external-agent production, dependency install, external fetch, commit, push, or branch switch.",
    "- Candidate payloads stayed under runtime_sessions."
  )
  Write-Phase160GTextFile -Path (Resolve-Phase160GPath -RepoRoot $RepoRoot -Path $ReportPath) -Text ($ReportLines -join "`n")

  Write-Host "PHASE160G_FULL_RUNTIME_GUARD_BASELINE_ALLOWED_OUTPUTS_TRUTHFUL_SELF_PRODUCTION_GATE_VALIDATE_RESULT=PASS"
  Write-Host "RUN_MANIFEST_BASELINE_CAPTURED=True"
  Write-Host "ALLOWED_RUNTIME_OUTPUTS_DO_NOT_BLOCK=True"
  Write-Host "ALLOWED_TRACKED_RUNTIME_SAMPLE_DOES_NOT_BLOCK=True"
  Write-Host "UNSAFE_TRACKED_CODE_MUTATION_BLOCKS=True"
  Write-Host "PROTECTED_STATE_MUTATION_BLOCKS=True"
  Write-Host "CANDIDATE_PRODUCTION_ENABLED_WITH_ALLOWED_RUNTIME_OUTPUTS=True"
  Write-Host "SELF_INITIATED_GOAL_SELECTED=True"
  Write-Host "INTERNAL_ACTIVE_TASK_CREATED=True"
  Write-Host "SELF_SELECTED_CANDIDATE_BUNDLE_CREATED=True"
  Write-Host "CANDIDATE_PAYLOAD_WRITTEN=True"
  Write-Host "PROMOTION_BUNDLE_CREATED=True"
  Write-Host "ZERO_CANDIDATE_PROMOTION_NOT_WAITING_OWNER_REVIEW=True"
  Write-Host "OWNER_REVIEW_SUMMARY_TRUTHFUL=True"
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
  Write-Host "PHASE160G_FULL_RUNTIME_GUARD_BASELINE_ALLOWED_OUTPUTS_TRUTHFUL_SELF_PRODUCTION_GATE_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE160G_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
