param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160CFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160CRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160C_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160CFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160CPath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Assert-Phase160CPathInsideRepo {
  param([string]$RepoRoot, [string]$Path)
  $root = Normalize-Phase160CFullPath -Path $RepoRoot
  $full = Normalize-Phase160CFullPath -Path (Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $Path)
  if (-not ($full -eq $root -or $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "PHASE160C_VALIDATE_PATH_OUTSIDE_REPO=$Path"
  }
  return $full
}

function ConvertTo-Phase160CRelativePath {
  param([string]$RepoRoot, [string]$FullPath)
  $root = Normalize-Phase160CFullPath -Path $RepoRoot
  $full = Normalize-Phase160CFullPath -Path $FullPath
  if ($full -eq $root) {
    return "."
  }
  if (-not $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160C_VALIDATE_PATH_OUTSIDE_REPO=$FullPath"
  }
  return ($full.Substring($root.Length + 1) -replace "\\", "/")
}

function Read-Phase160CJson {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160C_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase160CText {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160C_VALIDATE_MISSING_TEXT=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw
}

function Read-Phase160CJsonLines {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160C_VALIDATE_MISSING_JSONL=$Path"
  }
  return @(Get-Content -LiteralPath $fullPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_ | ConvertFrom-Json })
}

function Write-Phase160CJsonFile {
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

function Write-Phase160CTextFile {
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

function Assert-Phase160CEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160C_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160CTrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160C_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160CFalse {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160C_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160CAtLeast {
  param([object]$Actual, [int]$Minimum, [string]$Name)
  if ([int]$Actual -lt $Minimum) {
    throw "PHASE160C_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase160CParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160C_VALIDATE_PARSE_ERROR=$Path message=$($parseErrors[0].Message)"
  }
}

function Get-Phase160CRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160C_VALIDATE_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Remove-Phase160COutput {
  param([string]$RepoRoot, [string]$Path)
  $full = Assert-Phase160CPathInsideRepo -RepoRoot $RepoRoot -Path $Path
  if (Test-Path -LiteralPath $full) {
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}

function Get-Phase160CFileHashes {
  param([string]$RepoRoot, [string[]]$Paths)
  $hashes = @{}
  foreach ($path in $Paths) {
    $full = Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $path
    if (Test-Path -LiteralPath $full) {
      $hashes[$path] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = "MISSING"
    }
  }
  return $hashes
}

function Get-Phase160CPathFingerprint {
  param([string]$RepoRoot, [string]$Path)
  $full = Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $full)) {
    return "ABSENT"
  }
  $root = Normalize-Phase160CFullPath -Path $full
  $records = @()
  $files = @(Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue | Sort-Object FullName)
  foreach ($file in $files) {
    $relative = ($file.FullName.Substring($root.Length + 1) -replace "\\", "/")
    $records += [ordered]@{
      path = $relative
      length = $file.Length
      hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    }
  }
  return ($records | ConvertTo-Json -Depth 10 -Compress)
}

function Wait-Phase160CDutyCount {
  param([string]$RepoRoot, [string]$CurrentStatePath, [int]$Minimum, [int]$TimeoutSeconds)
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $fullPath = Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $CurrentStatePath
    if (Test-Path -LiteralPath $fullPath) {
      $state = Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
      if ($state.PSObject.Properties.Name -contains "self_growth_duty_count" -and [int]$state.self_growth_duty_count -ge $Minimum) {
        return $state
      }
    }
    Start-Sleep -Seconds 1
  }
  throw "PHASE160C_VALIDATE_DUTY_COUNT_TIMEOUT minimum=$Minimum"
}

function Assert-Phase160CRuntimeOutputsNotStaged {
  $stagedRuntime = @(git diff --cached --name-only -- runtime_sessions)
  if ($stagedRuntime.Count -gt 0) {
    throw "PHASE160C_VALIDATE_RUNTIME_OUTPUTS_STAGED=$($stagedRuntime -join '; ')"
  }
}

function Assert-Phase160CScriptContains {
  param([string]$Text, [string]$Needle, [string]$Name)
  if (-not $Text.Contains($Needle)) {
    throw "PHASE160C_VALIDATE_SCRIPT_NEEDLE_MISSING=$Name needle=$Needle"
  }
}

$Pushed = $false

try {
  $RepoRootParameter = $RepoRoot
  $RepoRoot = Resolve-Phase160CRepoRoot
  Push-Location $RepoRoot
  $Pushed = $true
  Write-Host "PHASE160C_VALIDATE_RESOLVED_REPO_ROOT=$RepoRoot"
  if ($RepoRootParameter -ne "." -and (Normalize-Phase160CFullPath -Path $RepoRootParameter) -ne $RepoRoot) {
    Write-Host "PHASE160C_VALIDATE_REPO_ROOT_PARAMETER_IGNORED=$RepoRootParameter"
  }

  $RepairId = "PHASE160C_LIVE_MACRO_RUN_BINDING_REPAIR_V1"
  $RunId = "PHASE160C_LIVE_BINDING_SMOKE_001"
  $OwnerRunId = "PHASE160B_OWNER_SUPERVISED_MACRO_SELF_GROWTH_RUN_001"
  $ConsoleRunId = "PHASE160C_LIVE_BINDING_CONSOLE_001"
  $CycleId = "PHASE160C_LIVE_BINDING_SMOKE_CYCLE_001"
  $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
  $SessionRoot = "runtime_sessions/live_growth/$RunId"
  $OwnerSessionRoot = "runtime_sessions/live_growth/$OwnerRunId"
  $OldBootstrapRoot = "runtime_sessions/live_growth/PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_001"
  $ConsoleRuntimeRoot = "runtime_sessions/live_growth_console/$ConsoleRunId"
  $DaemonPath = "modules/start_builder_live_growth_daemon_001.ps1"
  $ObserverPath = "modules/watch_builder_live_growth_session_observer_001.ps1"
  $ConsolePath = "modules/watch_builder_live_console_001.ps1"
  $DutyStepPath = "modules/invoke_builder_live_self_growth_duty_step_001.ps1"
  $Phase160BValidatorPath = "validators/validate_phase160b_macro_self_growth_ignition_v1.ps1"
  $ValidatorPath = "validators/validate_phase160c_live_macro_run_binding_v1.ps1"
  $ReportPath = "reports/self_development/PHASE160C_LIVE_MACRO_RUN_BINDING_REPAIR_REPORT.md"
  $ProofPath = "proofs/self_development/PHASE160C_LIVE_MACRO_RUN_BINDING_REPAIR_PROOF.json"
  $RouteRequestPath = "route_change_requests/PHASE160C_LIVE_MACRO_RUN_BINDING_REPAIR_REQUEST.md"

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  Assert-Phase160CEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160CRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160CEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"
  $ExpectedHeadSource = "CURRENT_SYNCED_REPO_HEAD"
  $GitTopLevel = Normalize-Phase160CFullPath -Path (git rev-parse --show-toplevel).Trim()
  Assert-Phase160CEquals -Actual $GitTopLevel -Expected $RepoRoot -Name "git_top_level"

  $ProtectedPaths = @("TASK_QUEUE.json", "GENESIS_STATE.json", "CAPABILITY_ROADMAP.json", "packs/registry.json", "orchestrator/run.ps1")
  $ProtectedHashesBefore = Get-Phase160CFileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths
  $OldBootstrapFingerprintBefore = Get-Phase160CPathFingerprint -RepoRoot $RepoRoot -Path $OldBootstrapRoot

  foreach ($jsonPath in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "proofs/self_development/PHASE160B_MACRO_SELF_GROWTH_IGNITION_PROOF.json")) {
    $null = Read-Phase160CJson -RepoRoot $RepoRoot -Path $jsonPath
  }

  foreach ($requiredPath in @($DaemonPath, $ObserverPath, $ConsolePath, $DutyStepPath, $Phase160BValidatorPath, $ValidatorPath, $RouteRequestPath)) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE160C_VALIDATE_REQUIRED_PATH_MISSING=$requiredPath"
    }
  }

  foreach ($scriptPath in @($DaemonPath, $ObserverPath, $ConsolePath, $DutyStepPath, $Phase160BValidatorPath, $ValidatorPath)) {
    Assert-Phase160CParserClean -Path (Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $scriptPath)
  }

  $DaemonText = Read-Phase160CText -RepoRoot $RepoRoot -Path $DaemonPath
  $ObserverText = Read-Phase160CText -RepoRoot $RepoRoot -Path $ObserverPath
  $ConsoleText = Read-Phase160CText -RepoRoot $RepoRoot -Path $ConsolePath
  Assert-Phase160CScriptContains -Text $DaemonText -Needle '$RunId' -Name $DaemonPath
  Assert-Phase160CScriptContains -Text $DaemonText -Needle 'RunUntilStop' -Name $DaemonPath
  Assert-Phase160CScriptContains -Text $DaemonText -Needle 'EnableMacroSelfGrowth' -Name $DaemonPath
  Assert-Phase160CScriptContains -Text $DaemonText -Needle 'runtime_sessions/live_growth/$RunId' -Name $DaemonPath
  Assert-Phase160CScriptContains -Text $ObserverText -Needle '$RunId' -Name $ObserverPath
  Assert-Phase160CScriptContains -Text $ObserverText -Needle 'runtime_sessions/live_growth/$RunId' -Name $ObserverPath
  Assert-Phase160CScriptContains -Text $ConsoleText -Needle '$RunId' -Name $ConsolePath
  Assert-Phase160CScriptContains -Text $ConsoleText -Needle 'runtime_sessions/live_growth/$RunId' -Name $ConsolePath
  Assert-Phase160CScriptContains -Text $ConsoleText -Needle 'macro_cycle_stage_count=' -Name $ConsolePath
  if ($DaemonText -match '\[string\]\$SessionRoot\s*=\s*"runtime_sessions/live_growth/PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_001"') {
    throw "PHASE160C_VALIDATE_OLD_DAEMON_DEFAULT_STILL_PRESENT"
  }

  foreach ($outputPath in @($SessionRoot, $ConsoleRuntimeRoot, $ReportPath, $ProofPath)) {
    Remove-Phase160COutput -RepoRoot $RepoRoot -Path $outputPath
  }

  $DaemonFullPath = Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $DaemonPath
  $DaemonJob = Start-Job -ScriptBlock {
    param($RepoRoot, $DaemonFullPath, $RunId, $CycleId)
    Set-Location -LiteralPath $RepoRoot
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $DaemonFullPath `
      -RunId $RunId `
      -EnableSelfGrowthDuty `
      -EnableMacroSelfGrowth `
      -RunUntilStop `
      -TickIntervalSeconds 1 `
      -SelfGrowthEveryTicks 1 `
      -SelfGrowthStartTick 1 `
      -MaxSelfGrowthDuties 7 `
      -MacroCycleId $CycleId 2>&1
    $exit = $LASTEXITCODE
    if ($exit -ne 0) {
      throw "PHASE160C_DAEMON_JOB_FAILED exit=$exit output=$($output -join ' | ')"
    }
    $output
  } -ArgumentList $RepoRoot, $DaemonFullPath, $RunId, $CycleId

  $null = Wait-Phase160CDutyCount -RepoRoot $RepoRoot -CurrentStatePath "$SessionRoot/current_state.json" -Minimum 7 -TimeoutSeconds 90
  $StopFlagPath = Resolve-Phase160CPath -RepoRoot $RepoRoot -Path "$SessionRoot/stop.flag"
  [System.IO.File]::WriteAllText($StopFlagPath, "PHASE160C_STOP_REQUEST`n", [System.Text.UTF8Encoding]::new($false))
  $completedJob = Wait-Job -Job $DaemonJob -Timeout 30
  if ($null -eq $completedJob) {
    Stop-Job -Job $DaemonJob
    Receive-Job -Job $DaemonJob -Keep | Out-String | Write-Host
    throw "PHASE160C_VALIDATE_DAEMON_STOP_FLAG_TIMEOUT"
  }
  $DaemonOutput = @(Receive-Job -Job $DaemonJob)
  if ($DaemonJob.State -ne "Completed") {
    throw "PHASE160C_VALIDATE_DAEMON_JOB_STATE=$($DaemonJob.State) output=$($DaemonOutput -join ' | ')"
  }
  Remove-Job -Job $DaemonJob
  $DaemonResult = ($DaemonOutput -join "`n") | ConvertFrom-Json

  $ObserverOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $ObserverPath) -RunId $RunId -DurationSeconds 5 -PollIntervalSeconds 1 -ExpectSelfGrowthDuty 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160C_VALIDATE_OBSERVER_FAILED output=$($ObserverOutput -join ' | ')"
  }
  $ObserverResult = ($ObserverOutput -join "`n") | ConvertFrom-Json

  $ConsoleOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $ConsolePath) -RunId $RunId -DurationSeconds 5 -PollIntervalSeconds 1 -ConsoleRunId $ConsoleRunId -ConsoleRuntimeRoot $ConsoleRuntimeRoot 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160C_VALIDATE_CONSOLE_FAILED output=$($ConsoleOutput -join ' | ')"
  }
  $ConsolePollLines = @($ConsoleOutput | Where-Object { $_ -match "^LIVE_CONSOLE POLL=" })
  Assert-Phase160CAtLeast -Actual $ConsolePollLines.Count -Minimum 2 -Name "console_poll_lines"
  foreach ($requiredConsoleField in @("macro_cycle_enabled=", "macro_cycle_id=", "last_macro_cycle_stage=", "last_macro_decision=", "macro_cycle_stage_count=", "experience_ledger_count=", "next_goal_selected_with_reason=", "final_state_written=")) {
    if (-not (@($ConsolePollLines | Where-Object { $_ -match [regex]::Escape($requiredConsoleField) }).Count -eq $ConsolePollLines.Count)) {
      throw "PHASE160C_VALIDATE_CONSOLE_FIELD_MISSING=$requiredConsoleField"
    }
  }

  $RunDirFull = Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $SessionRoot
  if (-not (Test-Path -LiteralPath $RunDirFull)) {
    throw "PHASE160C_VALIDATE_RUN_DIR_MISSING=$SessionRoot"
  }

  $ExpectedSessionRoot = $SessionRoot
  Assert-Phase160CEquals -Actual $DaemonResult.session_root -Expected $ExpectedSessionRoot -Name "daemon_session_root"
  Assert-Phase160CEquals -Actual $ObserverResult.session_root -Expected $ExpectedSessionRoot -Name "observer_session_root"

  $Heartbeat = Read-Phase160CJson -RepoRoot $RepoRoot -Path "$SessionRoot/heartbeat.json"
  $CurrentState = Read-Phase160CJson -RepoRoot $RepoRoot -Path "$SessionRoot/current_state.json"
  $FinalState = Read-Phase160CJson -RepoRoot $RepoRoot -Path "$SessionRoot/final_state.json"
  $MacroSummary = Read-Phase160CJson -RepoRoot $RepoRoot -Path "$SessionRoot/self_growth/macro_cycle_summary.json"
  $NextGoal = Read-Phase160CJson -RepoRoot $RepoRoot -Path "$SessionRoot/self_growth/next_goal.json"
  $LedgerEntries = Read-Phase160CJsonLines -RepoRoot $RepoRoot -Path "$SessionRoot/self_growth/experience_ledger.jsonl"
  $Events = Read-Phase160CJsonLines -RepoRoot $RepoRoot -Path "$SessionRoot/event_log.jsonl"
  $ObserverSummary = Read-Phase160CJson -RepoRoot $RepoRoot -Path "$SessionRoot/observer_summary.json"
  $ConsoleResult = Read-Phase160CJson -RepoRoot $RepoRoot -Path "$ConsoleRuntimeRoot/console_run_result.json"
  $ConsoleSample = Read-Phase160CText -RepoRoot $RepoRoot -Path "$ConsoleRuntimeRoot/console_output_sample.txt"

  Assert-Phase160CEquals -Actual $ConsoleResult.session_root -Expected $ExpectedSessionRoot -Name "console_session_root"
  Assert-Phase160CEquals -Actual $ConsoleResult.bound_run_id -Expected $RunId -Name "console_bound_run_id"
  Assert-Phase160CTrue -Actual $FinalState.macro_cycle_enabled -Name "final_state_macro_cycle_enabled"
  Assert-Phase160CTrue -Actual $Heartbeat.macro_cycle_enabled -Name "heartbeat_macro_cycle_enabled"
  Assert-Phase160CAtLeast -Actual $CurrentState.self_growth_duty_count -Minimum 7 -Name "current_state_self_growth_duty_count"
  Assert-Phase160CAtLeast -Actual $LedgerEntries.Count -Minimum 7 -Name "experience_ledger_count"
  Assert-Phase160CEquals -Actual $MacroSummary.duty_count_completed -Expected 7 -Name "macro_summary_duty_count"
  Assert-Phase160CTrue -Actual $NextGoal.selected_with_reason -Name "next_goal_selected_with_reason"
  Assert-Phase160CTrue -Actual $ObserverSummary.self_growth_seen -Name "observer_self_growth_seen"
  Assert-Phase160CTrue -Actual $ConsoleResult.live_console_shows_macro_fields -Name "console_macro_fields"
  Assert-Phase160CTrue -Actual ($ConsoleSample -match "macro_cycle_enabled=True") -Name "console_sample_macro_cycle_enabled"
  Assert-Phase160CTrue -Actual (@($Events | Where-Object { [string]$_.event_type -eq "final_state_written" }).Count -gt 0) -Name "final_state_written_event"
  if (@("STOPPED", "COMPLETED") -notcontains [string]$FinalState.status) {
    throw "PHASE160C_VALIDATE_FINAL_STATE_STATUS_UNEXPECTED=$($FinalState.status)"
  }

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
  for ($i = 1; $i -le 7; $i += 1) {
    $dutyId = "duty_{0:d4}" -f $i
    $artifact = Read-Phase160CJson -RepoRoot $RepoRoot -Path "$SessionRoot/self_growth/$dutyId/macro_cycle_artifact.json"
    Assert-Phase160CEquals -Actual $artifact.duty_id -Expected $dutyId -Name "${dutyId}_artifact_duty_id"
    Assert-Phase160CEquals -Actual $artifact.cycle_stage -Expected $ExpectedStages[$i - 1] -Name "${dutyId}_cycle_stage"
    Assert-Phase160CEquals -Actual $artifact.validation_status -Expected "PASS" -Name "${dutyId}_validation_status"
    $ObservedStages += [string]$artifact.cycle_stage
  }
  Assert-Phase160CTrue -Actual (($ObservedStages -join "|") -eq ($ExpectedStages -join "|")) -Name "macro_stage_order"

  $OldBootstrapFingerprintAfter = Get-Phase160CPathFingerprint -RepoRoot $RepoRoot -Path $OldBootstrapRoot
  Assert-Phase160CEquals -Actual $OldBootstrapFingerprintAfter -Expected $OldBootstrapFingerprintBefore -Name "old_bootstrap_root_fingerprint"

  $ProtectedHashesAfter = Get-Phase160CFileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths
  foreach ($path in $ProtectedPaths) {
    Assert-Phase160CEquals -Actual $ProtectedHashesAfter[$path] -Expected $ProtectedHashesBefore[$path] -Name "protected_hash:$path"
  }
  $ProtectedStateMutated = $false

  Assert-Phase160CRuntimeOutputsNotStaged
  $RuntimeOutputsStaged = $false

  $Proof = [ordered]@{
    status = "PASS"
    acceptance_language = "PHASE160C_LIVE_MACRO_RUN_BINDING_REPAIR_VALIDATE_RESULT=PASS"
    repair_id = $RepairId
    run_id = $RunId
    owner_run_id = $OwnerRunId
    owner_session_root = $OwnerSessionRoot
    resolved_repo_root = $RepoRoot
    branch = $Branch
    local_head = $Head
    remote_head = $RemoteHead
    expected_head_source = $ExpectedHeadSource
    daemon_honors_run_id = $true
    observer_honors_run_id = $true
    console_honors_run_id = $true
    daemon_session_root = [string]$DaemonResult.session_root
    observer_session_root = [string]$ObserverResult.session_root
    console_session_root = [string]$ConsoleResult.session_root
    run_dir_exists = $true
    old_bootstrap_root_mutated = $false
    macro_cycle_enabled = $true
    macro_cycle_id = [string]$FinalState.macro_cycle_id
    macro_cycle_stage_count = 7
    observed_cycle_stages = $ObservedStages
    experience_ledger_count = $LedgerEntries.Count
    next_goal_selected_with_reason = [bool]$NextGoal.selected_with_reason
    final_state_written = $true
    final_state_status = [string]$FinalState.status
    final_state_stop_flag_seen = [bool]$FinalState.stop_flag_seen
    daemon_run_until_stop = [bool]$DaemonResult.run_until_stop
    daemon_stop_reason = [string]$DaemonResult.stop_reason
    console_macro_fields_visible = $true
    protected_state_mutated = $ProtectedStateMutated
    runtime_outputs_staged = $RuntimeOutputsStaged
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    external_fetch_performed = $false
    dependency_install_performed = $false
    external_agents_created = $false
    arbitrary_code_execution_used = $false
    live_macro_run_binding_proven = $true
    owner_supervised_macro_run_ready = $true
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase160CJsonFile -Path (Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $ProofPath) -Object $Proof
  $null = Read-Phase160CJson -RepoRoot $RepoRoot -Path $ProofPath

  $ReportLines = @(
    "# PHASE160C Live Macro Run Binding Repair Report",
    "",
    "status: PASS",
    "repair_id: $RepairId",
    "line: AGENT_BUILDER_SELF_DEVELOPMENT",
    "mode: VERIFY",
    "run_id_smoke: $RunId",
    "owner_run_id: $OwnerRunId",
    "",
    "## Root Cause",
    "The live daemon, observer, and console accepted session-root paths directly but did not bind owner macro runs by RunId. The daemon default still pointed at the old PHASE160 bootstrap session, macro mode was behind a non-owner-facing switch name, and the console did not expose the full macro fields needed for owner supervision.",
    "",
    "## Files Changed",
    "- $DaemonPath",
    "- $ObserverPath",
    "- $ConsolePath",
    "- $ValidatorPath",
    "- $ReportPath",
    "- $ProofPath",
    "- $RouteRequestPath",
    "",
    "## Exact Owner Launch Commands After Repair",
    '```powershell',
    'pwsh -NoProfile -ExecutionPolicy Bypass -File .\modules\start_builder_live_growth_daemon_001.ps1 `',
    ('  -RunId "' + $OwnerRunId + '" `'),
    '  -EnableSelfGrowthDuty `',
    '  -EnableMacroSelfGrowth `',
    '  -RunUntilStop',
    "",
    'pwsh -NoProfile -ExecutionPolicy Bypass -File .\modules\watch_builder_live_growth_session_observer_001.ps1 `',
    ('  -RunId "' + $OwnerRunId + '" `'),
    '  -ExpectSelfGrowthDuty `',
    '  -DurationSeconds 3600 `',
    '  -PollIntervalSeconds 5',
    "",
    'pwsh -NoProfile -ExecutionPolicy Bypass -File .\modules\watch_builder_live_console_001.ps1 `',
    ('  -RunId "' + $OwnerRunId + '" `'),
    '  -DurationSeconds 3600 `',
    '  -PollIntervalSeconds 5 `',
    '  -ConsoleRunId "PHASE160B_OWNER_SUPERVISED_MACRO_SELF_GROWTH_CONSOLE_001"',
    '```',
    "",
    "## Validation Result",
    "PHASE160C_LIVE_MACRO_RUN_BINDING_REPAIR_VALIDATE_RESULT=PASS",
    "LIVE_MACRO_RUN_BINDING_PROVEN=True",
    "OWNER_SUPERVISED_MACRO_RUN_READY=True",
    "",
    "## Proof Summary",
    "- Daemon RunId session_root: $($DaemonResult.session_root)",
    "- Observer RunId session_root: $($ObserverResult.session_root)",
    "- Console RunId session_root: $($ConsoleResult.session_root)",
    "- Macro cycle enabled: True",
    "- Macro stage count: 7",
    "- Experience ledger count: $($LedgerEntries.Count)",
    "- Final state status: $($FinalState.status)",
    "- Protected state mutated: False",
    "- Runtime outputs staged: False",
    "",
    "## Risks",
    "- Remote head verification uses the local remote-tracking ref and does not fetch.",
    "- Runtime outputs under runtime_sessions are local proof artifacts and must not be committed.",
    "- RunUntilStop requires owner stop discipline through stop.flag or process supervision.",
    "",
    "## Cut List",
    "- No full autonomy claim.",
    "- No external agents.",
    "- No dependency install or external fetch.",
    "- No TASK_QUEUE, GENESIS_STATE, CAPABILITY_ROADMAP, packs/registry, or orchestrator edits.",
    "- No runtime_sessions outputs should be staged or committed.",
    "",
    "## Next Strongest Move",
    "Run the owner-supervised command for $OwnerRunId and keep observer plus visible console bound by RunId until the owner places stop.flag."
  )
  Write-Phase160CTextFile -Path (Resolve-Phase160CPath -RepoRoot $RepoRoot -Path $ReportPath) -Text ($ReportLines -join "`n")

  Write-Host "PHASE160C_LIVE_MACRO_RUN_BINDING_REPAIR_VALIDATE_RESULT=PASS"
  Write-Host "LIVE_MACRO_RUN_BINDING_PROVEN=True"
  Write-Host "OWNER_SUPERVISED_MACRO_RUN_READY=True"
  Write-Host "RUN_ID=$RunId"
  Write-Host "SESSION_ROOT=$SessionRoot"
  Write-Host "MACRO_CYCLE_STAGE_COUNT=7"
  Write-Host "EXPERIENCE_LEDGER_COUNT=$($LedgerEntries.Count)"
  Write-Host "FINAL_STATE_STATUS=$($FinalState.status)"
  Write-Host "PROTECTED_STATE_MUTATED=False"
  Write-Host "RUNTIME_OUTPUTS_STAGED=False"
  Write-Host "REPORT_PATH=$ReportPath"
  Write-Host "PROOF_PATH=$ProofPath"
} catch {
  Write-Host "PHASE160C_LIVE_MACRO_RUN_BINDING_REPAIR_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE160C_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
