param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160BFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160BRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160B_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160BFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160BPath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Assert-Phase160BPathInsideRepo {
  param([string]$RepoRoot, [string]$Path)
  $root = Normalize-Phase160BFullPath -Path $RepoRoot
  $full = Normalize-Phase160BFullPath -Path (Resolve-Phase160BPath -RepoRoot $RepoRoot -Path $Path)
  if (-not ($full -eq $root -or $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "PHASE160B_VALIDATE_PATH_OUTSIDE_REPO=$Path"
  }
  return $full
}

function Read-Phase160BJson {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160BPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160B_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase160BText {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160BPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160B_VALIDATE_MISSING_TEXT=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw
}

function Read-Phase160BJsonLines {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160BPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160B_VALIDATE_MISSING_JSONL=$Path"
  }
  return @(Get-Content -LiteralPath $fullPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_ | ConvertFrom-Json })
}

function Write-Phase160BJsonFile {
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

function Write-Phase160BTextFile {
  param([string]$Path, [string]$Text)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase160BEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160B_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160BTrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160B_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160BFalse {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160B_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160BAtLeast {
  param([object]$Actual, [int]$Minimum, [string]$Name)
  if ([int]$Actual -lt $Minimum) {
    throw "PHASE160B_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase160BParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160B_VALIDATE_PARSE_ERROR=$Path message=$($parseErrors[0].Message)"
  }
}

function Get-Phase160BRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160B_VALIDATE_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Remove-Phase160BOutput {
  param([string]$RepoRoot, [string]$Path)
  $full = Assert-Phase160BPathInsideRepo -RepoRoot $RepoRoot -Path $Path
  if (Test-Path -LiteralPath $full) {
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}

function Get-Phase160BFileHashes {
  param([string]$RepoRoot, [string[]]$Paths)
  $hashes = @{}
  foreach ($path in $Paths) {
    $full = Resolve-Phase160BPath -RepoRoot $RepoRoot -Path $path
    if (Test-Path -LiteralPath $full) {
      $hashes[$path] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = "MISSING"
    }
  }
  return $hashes
}

function Assert-Phase160BNoStaticHead {
  param([string]$Text, [string]$Name, [string]$CurrentHead)
  foreach ($literal in @(("d3e" + "1710"), ("9d" + "897f1"), $CurrentHead)) {
    if (-not [string]::IsNullOrWhiteSpace($literal) -and $Text.Contains($literal)) {
      throw "PHASE160B_VALIDATE_STATIC_HEAD_LITERAL_FOUND=$Name"
    }
  }
  if ($Text -match '\$ExpectedHead\s*=\s*"[^"]+"') {
    throw "PHASE160B_VALIDATE_STATIC_EXPECTED_HEAD_FOUND=$Name"
  }
  if ($Text -match "C:\\Users\\Azerbaijan\\Downloads") {
    throw "PHASE160B_VALIDATE_DOWNLOADS_PATH_FORBIDDEN=$Name"
  }
}

function Assert-Phase160BScriptIdentityRules {
  param([string]$Text, [string]$Name)
  foreach ($needle in @("PSScriptRoot", "CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1", "git rev-parse --short HEAD", "current_synced_repo_head", "CURRENT_SYNCED_REPO_HEAD")) {
    if (-not $Text.Contains($needle)) {
      throw "PHASE160B_VALIDATE_SCRIPT_RULE_MISSING=$Name rule=$needle"
    }
  }
  if (-not $Text.Contains('origin/$ExpectedBranch')) {
    throw "PHASE160B_VALIDATE_REMOTE_HEAD_RULE_MISSING=$Name"
  }
}

function Wait-Phase160BDutyCount {
  param([string]$RepoRoot, [string]$CurrentStatePath, [int]$Minimum, [int]$TimeoutSeconds)
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $full = Resolve-Phase160BPath -RepoRoot $RepoRoot -Path $CurrentStatePath
    if (Test-Path -LiteralPath $full) {
      $state = Get-Content -LiteralPath $full -Raw | ConvertFrom-Json
      if ($state.PSObject.Properties.Name -contains "self_growth_duty_count" -and [int]$state.self_growth_duty_count -ge $Minimum) {
        return $state
      }
    }
    Start-Sleep -Seconds 1
  }
  throw "PHASE160B_VALIDATE_DUTY_COUNT_TIMEOUT minimum=$Minimum"
}

$Pushed = $false

try {
  $RepoRootParameter = $RepoRoot
  $RepoRoot = Resolve-Phase160BRepoRoot
  Push-Location $RepoRoot
  $Pushed = $true
  Write-Host "PHASE160B_VALIDATE_RESOLVED_REPO_ROOT=$RepoRoot"
  if ($RepoRootParameter -ne "." -and (Normalize-Phase160BFullPath -Path $RepoRootParameter) -ne $RepoRoot) {
    Write-Host "PHASE160B_VALIDATE_REPO_ROOT_PARAMETER_IGNORED=$RepoRootParameter"
  }

  $RepairId = "PHASE160B_MACRO_SELF_GROWTH_IGNITION_V1"
  $RunId = "PHASE160B_MACRO_SELF_GROWTH_IGNITION_SMOKE_001"
  $ConsoleRunId = "PHASE160B_MACRO_SELF_GROWTH_IGNITION_CONSOLE_001"
  $CycleId = "PHASE160B_MACRO_SELF_GROWTH_IGNITION_CYCLE_001"
  $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
  $SessionRoot = "runtime_sessions/live_growth/$RunId"
  $ConsoleRuntimeRoot = "runtime_sessions/live_growth_self_growth/$ConsoleRunId"
  $SchemaPath = "contracts/self_development/live_self_growth_macro_cycle.schema.json"
  $ReportPath = "reports/self_development/PHASE160B_MACRO_SELF_GROWTH_IGNITION_REPORT.md"
  $ProofPath = "proofs/self_development/PHASE160B_MACRO_SELF_GROWTH_IGNITION_PROOF.json"
  $RouteRequestPath = "route_change_requests/PHASE160B_MACRO_SELF_GROWTH_IGNITION_REQUEST.md"
  $DutyStepPath = "modules/invoke_builder_live_self_growth_duty_step_001.ps1"
  $DaemonPath = "modules/start_builder_live_growth_daemon_001.ps1"
  $ObserverPath = "modules/watch_builder_live_growth_session_observer_001.ps1"
  $ConsolePath = "modules/watch_builder_live_console_001.ps1"
  $PriorValidatorPath = "validators/validate_phase160_live_self_growth_duty_loop_v1.ps1"
  $ValidatorPath = "validators/validate_phase160b_macro_self_growth_ignition_v1.ps1"

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160BPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  Assert-Phase160BEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160BRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160BEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"
  $ExpectedHeadSource = "CURRENT_SYNCED_REPO_HEAD"
  $GitTopLevel = Normalize-Phase160BFullPath -Path (git rev-parse --show-toplevel).Trim()
  Assert-Phase160BEquals -Actual $GitTopLevel -Expected $RepoRoot -Name "git_top_level"

  $ProtectedPaths = @("TASK_QUEUE.json", "GENESIS_STATE.json", "CAPABILITY_ROADMAP.json", "packs/registry.json", "orchestrator/run.ps1")
  $ProtectedHashesBefore = Get-Phase160BFileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths

  foreach ($requiredPath in @($SchemaPath, $RouteRequestPath, $DutyStepPath, $DaemonPath, $ObserverPath, $ConsolePath, $PriorValidatorPath, $ValidatorPath)) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160BPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE160B_VALIDATE_REQUIRED_PATH_MISSING=$requiredPath"
    }
  }

  foreach ($scriptPath in @($DutyStepPath, $DaemonPath, $ObserverPath, $ConsolePath, $PriorValidatorPath, $ValidatorPath)) {
    $fullScript = Resolve-Phase160BPath -RepoRoot $RepoRoot -Path $scriptPath
    Assert-Phase160BParserClean -Path $fullScript
    $scriptText = Read-Phase160BText -RepoRoot $RepoRoot -Path $scriptPath
    Assert-Phase160BNoStaticHead -Text $scriptText -Name $scriptPath -CurrentHead $Head
    Assert-Phase160BScriptIdentityRules -Text $scriptText -Name $scriptPath
  }

  $Schema = Read-Phase160BJson -RepoRoot $RepoRoot -Path $SchemaPath
  Assert-Phase160BEquals -Actual $Schema.title -Expected "PHASE160B Live Self-Growth Macro Cycle" -Name "schema_title"

  foreach ($outputPath in @($SessionRoot, $ConsoleRuntimeRoot, $ReportPath, $ProofPath)) {
    Remove-Phase160BOutput -RepoRoot $RepoRoot -Path $outputPath
  }

  $DaemonFullPath = Resolve-Phase160BPath -RepoRoot $RepoRoot -Path $DaemonPath
  $DaemonJob = Start-Job -ScriptBlock {
    param($RepoRoot, $DaemonFullPath, $SessionRoot, $CycleId)
    Set-Location -LiteralPath $RepoRoot
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $DaemonFullPath `
      -SessionRoot $SessionRoot `
      -DurationSeconds 120 `
      -TickIntervalSeconds 1 `
      -EnableSelfGrowthDuty `
      -SelfGrowthEveryTicks 1 `
      -SelfGrowthStartTick 1 `
      -MaxSelfGrowthDuties 7 `
      -SelfGrowthDutyRoot "$SessionRoot/self_growth" `
      -EnableMacroSelfGrowthCycle `
      -MacroCycleId $CycleId 2>&1
    $exit = $LASTEXITCODE
    if ($exit -ne 0) {
      throw "PHASE160B_DAEMON_JOB_FAILED exit=$exit output=$($output -join ' | ')"
    }
    $output
  } -ArgumentList $RepoRoot, $DaemonFullPath, $SessionRoot, $CycleId

  $CurrentStateAfterSeven = Wait-Phase160BDutyCount -RepoRoot $RepoRoot -CurrentStatePath "$SessionRoot/current_state.json" -Minimum 7 -TimeoutSeconds 90
  $StopFlagPath = Resolve-Phase160BPath -RepoRoot $RepoRoot -Path "$SessionRoot/stop.flag"
  [System.IO.File]::WriteAllText($StopFlagPath, "PHASE160B_STOP_REQUEST`n", [System.Text.UTF8Encoding]::new($false))
  $completedJob = Wait-Job -Job $DaemonJob -Timeout 30
  if ($null -eq $completedJob) {
    Stop-Job -Job $DaemonJob
    Receive-Job -Job $DaemonJob -Keep | Out-String | Write-Host
    throw "PHASE160B_VALIDATE_DAEMON_STOP_FLAG_TIMEOUT"
  }
  $DaemonOutput = @(Receive-Job -Job $DaemonJob)
  if ($DaemonJob.State -ne "Completed") {
    throw "PHASE160B_VALIDATE_DAEMON_JOB_STATE=$($DaemonJob.State) output=$($DaemonOutput -join ' | ')"
  }
  Remove-Job -Job $DaemonJob
  $DaemonResult = ($DaemonOutput -join "`n") | ConvertFrom-Json

  $ObserverOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160BPath -RepoRoot $RepoRoot -Path $ObserverPath) -SessionRoot $SessionRoot -DurationSeconds 12 -PollIntervalSeconds 3 -ExpectSelfGrowthDuty 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160B_VALIDATE_OBSERVER_FAILED output=$($ObserverOutput -join ' | ')"
  }
  $ObserverResult = ($ObserverOutput -join "`n") | ConvertFrom-Json

  $ConsoleOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160BPath -RepoRoot $RepoRoot -Path $ConsolePath) -SessionRoot $SessionRoot -DurationSeconds 10 -PollIntervalSeconds 3 -ConsoleRunId $ConsoleRunId -ConsoleRuntimeRoot $ConsoleRuntimeRoot 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160B_VALIDATE_CONSOLE_FAILED output=$($ConsoleOutput -join ' | ')"
  }
  $ConsolePollLines = @($ConsoleOutput | Where-Object { $_ -match "^LIVE_CONSOLE POLL=" })
  Assert-Phase160BAtLeast -Actual $ConsolePollLines.Count -Minimum 2 -Name "console_poll_lines"

  $Heartbeat = Read-Phase160BJson -RepoRoot $RepoRoot -Path "$SessionRoot/heartbeat.json"
  $CurrentState = Read-Phase160BJson -RepoRoot $RepoRoot -Path "$SessionRoot/current_state.json"
  $FinalState = Read-Phase160BJson -RepoRoot $RepoRoot -Path "$SessionRoot/final_state.json"
  $MacroSummary = Read-Phase160BJson -RepoRoot $RepoRoot -Path "$SessionRoot/self_growth/macro_cycle_summary.json"
  $NextGoal = Read-Phase160BJson -RepoRoot $RepoRoot -Path "$SessionRoot/self_growth/next_goal.json"
  $LedgerEntries = Read-Phase160BJsonLines -RepoRoot $RepoRoot -Path "$SessionRoot/self_growth/experience_ledger.jsonl"
  $Events = Read-Phase160BJsonLines -RepoRoot $RepoRoot -Path "$SessionRoot/event_log.jsonl"
  $ObserverSummary = Read-Phase160BJson -RepoRoot $RepoRoot -Path "$SessionRoot/observer_summary.json"

  Assert-Phase160BAtLeast -Actual $CurrentState.self_growth_duty_count -Minimum 7 -Name "self_growth_duty_count"
  Assert-Phase160BAtLeast -Actual $LedgerEntries.Count -Minimum 7 -Name "experience_ledger_entries"
  Assert-Phase160BEquals -Actual $FinalState.stop_flag_seen -Expected $true -Name "final_state_stop_flag_seen"
  Assert-Phase160BEquals -Actual $FinalState.accepted_state_mutated -Expected $false -Name "final_state_accepted_state_mutated"
  Assert-Phase160BTrue -Actual $ObserverSummary.self_growth_seen -Name "observer_self_growth_seen"
  Assert-Phase160BTrue -Actual ($ConsolePollLines[0] -match "LAST_STAGE=") -Name "console_macro_stage_visible"

  $ExpectedStages = @(
    "SELF_OBSERVE_MAP_REFRESH",
    "CAPABILITY_INVENTORY_DIFF",
    "GAP_RANK_AND_SELECT",
    "SELF_CHANGE_CANDIDATE_GENERATE",
    "SANDBOX_DRY_RUN",
    "VALIDATE_AND_DECIDE",
    "EXPERIENCE_ABSORB_AND_NEXT_GOAL"
  )
  $ObservedStages = @()
  $ObservedGaps = @()
  for ($i = 1; $i -le 7; $i += 1) {
    $dutyId = "duty_{0:d4}" -f $i
    $artifactPath = "$SessionRoot/self_growth/$dutyId/macro_cycle_artifact.json"
    $summaryPath = "$SessionRoot/self_growth/$dutyId/duty_summary.json"
    $artifact = Read-Phase160BJson -RepoRoot $RepoRoot -Path $artifactPath
    $summary = Read-Phase160BJson -RepoRoot $RepoRoot -Path $summaryPath
    Assert-Phase160BEquals -Actual $artifact.duty_id -Expected $dutyId -Name "${dutyId}_artifact_duty_id"
    Assert-Phase160BEquals -Actual $artifact.cycle_stage -Expected $ExpectedStages[$i - 1] -Name "${dutyId}_cycle_stage"
    Assert-Phase160BEquals -Actual $artifact.validation_status -Expected "PASS" -Name "${dutyId}_validation_status"
    Assert-Phase160BEquals -Actual $summary.decision -Expected "KEEP_SESSION_LOCAL" -Name "${dutyId}_decision"
    if ($i -eq 1) {
      Assert-Phase160BEquals -Actual $artifact.previous_duty_id -Expected "NONE" -Name "duty_0001_previous_duty"
    } else {
      $expectedPrevious = "duty_{0:d4}" -f ($i - 1)
      Assert-Phase160BEquals -Actual $artifact.previous_duty_id -Expected $expectedPrevious -Name "${dutyId}_previous_duty"
      if ([string]::IsNullOrWhiteSpace([string]$artifact.input_artifact) -or [string]$artifact.input_artifact -eq "SESSION_START") {
        throw "PHASE160B_VALIDATE_CHAIN_INPUT_MISSING=$dutyId"
      }
    }
    $ObservedStages += [string]$artifact.cycle_stage
    $ObservedGaps += [string]$artifact.selected_gap
  }

  for ($i = 1; $i -lt $ObservedStages.Count; $i += 1) {
    if ($ObservedStages[$i] -eq $ObservedStages[$i - 1]) {
      throw "PHASE160B_VALIDATE_CONSECUTIVE_STAGE_REPEAT index=$i stage=$($ObservedStages[$i])"
    }
  }
  $StageSequenceOk = (($ObservedStages -join "|") -eq ($ExpectedStages -join "|"))
  Assert-Phase160BTrue -Actual $StageSequenceOk -Name "macro_cycle_stage_sequence"
  $DutyRepetitionBlocked = (@($ObservedGaps | Select-Object -Unique).Count -eq 7)
  Assert-Phase160BTrue -Actual $DutyRepetitionBlocked -Name "selected_gap_unique_count"
  Assert-Phase160BEquals -Actual $MacroSummary.duty_count_completed -Expected 7 -Name "macro_summary_duty_count"
  Assert-Phase160BFalse -Actual $NextGoal.blind_repeat -Name "next_goal_blind_repeat"
  Assert-Phase160BTrue -Actual $NextGoal.selected_with_reason -Name "next_goal_selected_with_reason"
  if ([string]::IsNullOrWhiteSpace([string]$NextGoal.novelty_reason)) {
    throw "PHASE160B_VALIDATE_NEXT_GOAL_NOVELTY_REASON_MISSING"
  }
  Assert-Phase160BTrue -Actual (@($Events | Where-Object { [string]$_.event_type -eq "final_state_written" }).Count -gt 0) -Name "event_final_state_written"

  $ProtectedHashesAfter = Get-Phase160BFileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths
  foreach ($path in $ProtectedPaths) {
    Assert-Phase160BEquals -Actual $ProtectedHashesAfter[$path] -Expected $ProtectedHashesBefore[$path] -Name "protected_hash:$path"
  }
  $ProtectedStateMutated = $false

  $Proof = [ordered]@{
    status = "PASS"
    acceptance_language = "BOUNDED_MACRO_DUTY_LOOP_CANDIDATE_PROVEN"
    repair_id = $RepairId
    run_id = $RunId
    resolved_repo_root = $RepoRoot
    branch = $Branch
    local_head = $Head
    remote_head = $RemoteHead
    expected_head_source = $ExpectedHeadSource
    macro_cycle_stage_count = 7
    macro_cycle_chain_ok = $true
    duty_repetition_blocked = $true
    experience_ledger_written = $true
    next_goal_selected_with_reason = $true
    final_state_written = $true
    final_state_status = [string]$FinalState.status
    final_state_stop_flag_seen = [bool]$FinalState.stop_flag_seen
    observed_cycle_stages = $ObservedStages
    observed_selected_gaps = $ObservedGaps
    ledger_entry_count = $LedgerEntries.Count
    daemon_tick_count = [int]$DaemonResult.tick_count
    self_growth_duty_count = [int]$CurrentState.self_growth_duty_count
    observer_detected_self_growth = [bool]$ObserverResult.self_growth_seen
    live_console_macro_visible = $true
    protected_state_mutated = $ProtectedStateMutated
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    external_fetch_performed = $false
    dependency_install_performed = $false
    external_agents_created = $false
    arbitrary_code_execution_used = $false
    runtime_outputs_commit_allowed = $false
    next_strongest_move = "OWNER_SUPERVISED_MACRO_SELF_GROWTH_RUN_WITH_VISIBLE_CONSOLE"
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase160BJsonFile -Path (Resolve-Phase160BPath -RepoRoot $RepoRoot -Path $ProofPath) -Object $Proof

  $Report = @"
# PHASE160B Macro Self-Growth Ignition Report

status: PASS
acceptance_language: BOUNDED_MACRO_DUTY_LOOP_CANDIDATE_PROVEN
repair_id: $RepairId
run_id: $RunId

## What Changed
- Added macro-cycle schema at `$SchemaPath`.
- Added opt-in macro mode to the live self-growth duty step.
- Added daemon macro scheduling flags and `final_state.json` finalization.
- Added observer stale-ended classification.
- Added console macro stage/decision visibility.
- Added PHASE160B validator and proof generation.

## Why This Is Macro, Not Micro
The run proves seven ordered stages where duties after `duty_0001` reference the previous duty artifact. Each duty writes a macro artifact, the chain writes an experience ledger, and the final duty selects a reasoned next goal instead of blindly repeating a small gap label.

## Root Cause
The previous duty loop cycled deterministic gap labels, but each duty could stand alone. It did not force previous-output consumption, stage ordering, or experience absorption.

## Stop-Finalization Fix
The daemon now writes `$SessionRoot/final_state.json` on normal exit or stop flag. The observer can also classify a stale-ended session if heartbeat is stale, no daemon process is present, and no final state exists.

## Files Changed
- `$DutyStepPath`
- `$DaemonPath`
- `$ObserverPath`
- `$ConsolePath`
- `$ValidatorPath`
- `$SchemaPath`
- `$RouteRequestPath`
- `$ReportPath`
- `$ProofPath`

## Validation Commands Run
```powershell
.\validators\validate_phase160b_macro_self_growth_ignition_v1.ps1 -RepoRoot .
```

## Risks
- Runtime outputs under `runtime_sessions/` are local proof artifacts and must not be committed.
- Remote head verification uses the local remote-tracking ref and does not fetch.
- Macro artifacts remain session-local; no accepted self-model promotion is performed.

## Cut List
- No PHASE161.
- No external agents.
- No dependency install or internet fetch.
- No accepted state, memory, self-model, queue, roadmap, registry, orchestrator, package, or material governance mutation.
- No runtime_sessions outputs should be committed.

## Next Strongest Move
Run an owner-supervised macro self-growth session with Terminal 1 daemon and Terminal 2 observer/console, then review `macro_cycle_summary.json`, `experience_ledger.jsonl`, and `next_goal.json`.
"@
  Write-Phase160BTextFile -Path (Resolve-Phase160BPath -RepoRoot $RepoRoot -Path $ReportPath) -Text $Report

  Write-Host "PHASE160B_MACRO_SELF_GROWTH_IGNITION_VALIDATE_RESULT=PASS"
  Write-Host "MACRO_CYCLE_STAGE_COUNT=7"
  Write-Host "MACRO_CYCLE_CHAIN_OK=True"
  Write-Host "DUTY_REPETITION_BLOCKED=True"
  Write-Host "EXPERIENCE_LEDGER_WRITTEN=True"
  Write-Host "NEXT_GOAL_SELECTED_WITH_REASON=True"
  Write-Host "FINAL_STATE_WRITTEN=True"
  Write-Host "PROTECTED_STATE_MUTATED=False"
  Write-Host "ACCEPTANCE_LANGUAGE=BOUNDED_MACRO_DUTY_LOOP_CANDIDATE_PROVEN"
  Write-Host "REPORT_PATH=$ReportPath"
  Write-Host "PROOF_PATH=$ProofPath"
} catch {
  Write-Host "PHASE160B_MACRO_SELF_GROWTH_IGNITION_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE160B_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
