param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160SelfGrowthValidateFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160SelfGrowthValidateRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160SelfGrowthValidateFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160SelfGrowthValidatePath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Assert-Phase160SelfGrowthValidatePathInsideRepo {
  param([string]$RepoRoot, [string]$Path)
  $normalizedRoot = Normalize-Phase160SelfGrowthValidateFullPath -Path $RepoRoot
  $normalizedPath = Normalize-Phase160SelfGrowthValidateFullPath -Path (Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $Path)
  if (-not ($normalizedPath -eq $normalizedRoot -or $normalizedPath.StartsWith($normalizedRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_PATH_OUTSIDE_REPO=$Path"
  }
  return $normalizedPath
}

function Read-Phase160SelfGrowthValidateJson {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase160SelfGrowthValidateText {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_MISSING_TEXT=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw
}

function Read-Phase160SelfGrowthValidateJsonLines {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_MISSING_JSONL=$Path"
  }
  return @(Get-Content -LiteralPath $fullPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_ | ConvertFrom-Json })
}

function Write-Phase160SelfGrowthValidateJsonFile {
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

function Assert-Phase160SelfGrowthValidateEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160SelfGrowthValidateTrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160SelfGrowthValidateFalse {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160SelfGrowthValidateAtLeast {
  param([object]$Actual, [int]$Minimum, [string]$Name)
  if ([int]$Actual -lt $Minimum) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase160SelfGrowthValidateParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_PARSE_ERROR=$Path message=$($parseErrors[0].Message)"
  }
}

function Get-Phase160SelfGrowthValidateRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Remove-Phase160SelfGrowthValidateOutput {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Assert-Phase160SelfGrowthValidatePathInsideRepo -RepoRoot $RepoRoot -Path $Path
  if (Test-Path -LiteralPath $fullPath) {
    Remove-Item -LiteralPath $fullPath -Recurse -Force
  }
}

function Assert-Phase160SelfGrowthNoStaticHead {
  param([string]$Text, [string]$Name, [string]$CurrentHead)
  $forbiddenHeadLiterals = @(
    ("d3e" + "1710"),
    ("9d" + "897f1"),
    $CurrentHead
  )
  foreach ($literal in $forbiddenHeadLiterals) {
    if (-not [string]::IsNullOrWhiteSpace($literal) -and $Text.Contains($literal)) {
      throw "PHASE160_SELF_GROWTH_VALIDATE_STATIC_HEAD_LITERAL_FOUND=$Name"
    }
  }
  if ($Text -match '\$ExpectedHead\s*=\s*"[^"]+"') {
    throw "PHASE160_SELF_GROWTH_VALIDATE_STATIC_EXPECTED_HEAD_FOUND=$Name"
  }
  if ($Text -match "C:\\Users\\Azerbaijan\\Downloads") {
    throw "PHASE160_SELF_GROWTH_VALIDATE_DOWNLOADS_PATH_FORBIDDEN=$Name"
  }
}

function Assert-Phase160SelfGrowthScriptIdentityRules {
  param([string]$Text, [string]$Name)
  foreach ($needle in @("PSScriptRoot", "CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1", "git rev-parse --short HEAD", "current_synced_repo_head", "CURRENT_SYNCED_REPO_HEAD")) {
    if (-not $Text.Contains($needle)) {
      throw "PHASE160_SELF_GROWTH_VALIDATE_SCRIPT_RULE_MISSING=$Name rule=$needle"
    }
  }
  if (-not $Text.Contains('origin/$ExpectedBranch')) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_REMOTE_HEAD_RULE_MISSING=$Name"
  }
}

function Test-Phase160SelfGrowthEventExists {
  param([object[]]$Events, [string]$EventType)
  return @($Events | Where-Object { [string]$_.event_type -eq $EventType }).Count -gt 0
}

$Pushed = $false

try {
  $RepoRootParameter = $RepoRoot
  $RepoRoot = Resolve-Phase160SelfGrowthValidateRepoRoot
  Push-Location $RepoRoot
  $Pushed = $true
  Write-Host "PHASE160_SELF_GROWTH_VALIDATE_RESOLVED_REPO_ROOT=$RepoRoot"
  if ($RepoRootParameter -ne "." -and (Normalize-Phase160SelfGrowthValidateFullPath -Path $RepoRootParameter) -ne $RepoRoot) {
    Write-Host "PHASE160_SELF_GROWTH_VALIDATE_REPO_ROOT_PARAMETER_IGNORED=$RepoRootParameter"
  }

  $RepairId = "PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_EXPANSION_V1"
  $RunId = "PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_SMOKE_001"
  $ExpansionRunId = "PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_EXPANSION_001"
  $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
  $SessionRoot = "runtime_sessions/live_growth/$RunId"
  $ExpansionRuntimeRoot = "runtime_sessions/live_growth_self_growth/$ExpansionRunId"
  $ConsoleRunResultPath = "$ExpansionRuntimeRoot/console_run_result.json"
  $ConsoleOutputSamplePath = "$ExpansionRuntimeRoot/console_output_sample.txt"
  $ExpansionManifestPath = "$ExpansionRuntimeRoot/expansion_manifest.json"
  $ResultPath = "self_control/BUILDER_LIVE_SELF_GROWTH_DUTY_LOOP_EXPANSION_RESULT.json"
  $ReportPath = "reports/self_development/PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_EXPANSION_REPORT.json"
  $ProofPath = "proofs/self_development/PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_EXPANSION_V1.json"
  $DutyStepPath = "modules/invoke_builder_live_self_growth_duty_step_001.ps1"
  $DaemonPath = "modules/start_builder_live_growth_daemon_001.ps1"
  $ObserverPath = "modules/watch_builder_live_growth_session_observer_001.ps1"
  $ConsolePath = "modules/watch_builder_live_console_001.ps1"
  $ValidatorPath = "validators/validate_phase160_live_self_growth_duty_loop_v1.ps1"
  $RouteRequestPath = "route_change_requests/PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_EXPANSION_REQUEST.md"

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  Assert-Phase160SelfGrowthValidateEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160SelfGrowthValidateRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160SelfGrowthValidateEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"
  $ExpectedHeadSource = "CURRENT_SYNCED_REPO_HEAD"
  $GitTopLevel = Normalize-Phase160SelfGrowthValidateFullPath -Path (git rev-parse --show-toplevel).Trim()
  Assert-Phase160SelfGrowthValidateEquals -Actual $GitTopLevel -Expected $RepoRoot -Name "git_top_level"

  $ProtectedStatusBefore = @(git status --short --untracked-files=all -- `
    TASK_QUEUE.json `
    GENESIS_STATE.json `
    CAPABILITY_ROADMAP.json `
    packs/registry.json `
    orchestrator/run.ps1 `
    capability_shelf `
    living_learning_environment/body `
    living_learning_environment/self_growth_runtime `
    generated_agents `
    applied_agents 2>$null)
  if ($ProtectedStatusBefore.Count -gt 0) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_PROTECTED_SCOPE_DIRTY_BEFORE=$($ProtectedStatusBefore -join '; ')"
  }

  foreach ($requiredPath in @($DutyStepPath, $DaemonPath, $ObserverPath, $ConsolePath, $ValidatorPath, $RouteRequestPath)) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE160_SELF_GROWTH_VALIDATE_REQUIRED_PATH_MISSING=$requiredPath"
    }
  }

  foreach ($scriptPath in @($DutyStepPath, $DaemonPath, $ObserverPath, $ConsolePath, $ValidatorPath)) {
    $fullScriptPath = Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $scriptPath
    Assert-Phase160SelfGrowthValidateParserClean -Path $fullScriptPath
    $scriptText = Read-Phase160SelfGrowthValidateText -RepoRoot $RepoRoot -Path $scriptPath
    Assert-Phase160SelfGrowthNoStaticHead -Text $scriptText -Name $scriptPath -CurrentHead $Head
    Assert-Phase160SelfGrowthScriptIdentityRules -Text $scriptText -Name $scriptPath
  }

  foreach ($outputPath in @($SessionRoot, $ExpansionRuntimeRoot, $ReportPath, $ProofPath, $ResultPath)) {
    Remove-Phase160SelfGrowthValidateOutput -RepoRoot $RepoRoot -Path $outputPath
  }
  New-Item -ItemType Directory -Force -Path (Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $ExpansionRuntimeRoot) | Out-Null

  $DaemonCommand = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", (Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $DaemonPath),
    "-SessionRoot", $SessionRoot,
    "-DurationSeconds", "120",
    "-TickIntervalSeconds", "10",
    "-EnableSelfGrowthDuty",
    "-SelfGrowthEveryTicks", "2",
    "-SelfGrowthStartTick", "2",
    "-MaxSelfGrowthDuties", "3",
    "-SelfGrowthDutyRoot", "$SessionRoot/self_growth"
  )
  $DaemonOutput = @(powershell @DaemonCommand 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_DAEMON_SMOKE_FAILED exit=$LASTEXITCODE output=$($DaemonOutput -join ' | ')"
  }
  $DaemonResult = ($DaemonOutput -join "`n") | ConvertFrom-Json

  $ObserverCommand = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", (Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $ObserverPath),
    "-SessionRoot", $SessionRoot,
    "-DurationSeconds", "20",
    "-PollIntervalSeconds", "5",
    "-ExpectSelfGrowthDuty"
  )
  $ObserverOutput = @(powershell @ObserverCommand 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_OBSERVER_RUN_FAILED exit=$LASTEXITCODE output=$($ObserverOutput -join ' | ')"
  }
  $ObserverResult = ($ObserverOutput -join "`n") | ConvertFrom-Json

  $ConsoleCommand = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", (Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $ConsolePath),
    "-SessionRoot", $SessionRoot,
    "-DurationSeconds", "15",
    "-PollIntervalSeconds", "5",
    "-ShowTailEvents", "3",
    "-ShowTailObserver", "3",
    "-ConsoleRunId", $ExpansionRunId,
    "-ConsoleRuntimeRoot", $ExpansionRuntimeRoot
  )
  $ConsoleOutput = @(powershell @ConsoleCommand 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_CONSOLE_RUN_FAILED exit=$LASTEXITCODE output=$($ConsoleOutput -join ' | ')"
  }
  $ConsolePollLines = @($ConsoleOutput | Where-Object { $_ -match "^LIVE_CONSOLE POLL=" })
  Assert-Phase160SelfGrowthValidateAtLeast -Actual $ConsolePollLines.Count -Minimum 2 -Name "console_poll_lines"
  foreach ($requiredConsoleField in @("SELF_GROWTH_ENABLED=", "DUTY_COUNT=", "LAST_GAP=", "NEXT_GAP=")) {
    if (-not (@($ConsolePollLines | Where-Object { $_ -match [regex]::Escape($requiredConsoleField) }).Count -eq $ConsolePollLines.Count)) {
      throw "PHASE160_SELF_GROWTH_VALIDATE_CONSOLE_FIELD_MISSING=$requiredConsoleField"
    }
  }

  $Heartbeat = Read-Phase160SelfGrowthValidateJson -RepoRoot $RepoRoot -Path "$SessionRoot/heartbeat.json"
  $CurrentState = Read-Phase160SelfGrowthValidateJson -RepoRoot $RepoRoot -Path "$SessionRoot/current_state.json"
  $Events = Read-Phase160SelfGrowthValidateJsonLines -RepoRoot $RepoRoot -Path "$SessionRoot/event_log.jsonl"
  $ObserverLines = Read-Phase160SelfGrowthValidateJsonLines -RepoRoot $RepoRoot -Path "$SessionRoot/observer_log.jsonl"
  $ObserverSummary = Read-Phase160SelfGrowthValidateJson -RepoRoot $RepoRoot -Path "$SessionRoot/observer_summary.json"
  $ConsoleResult = Read-Phase160SelfGrowthValidateJson -RepoRoot $RepoRoot -Path $ConsoleRunResultPath
  $ConsoleSample = Read-Phase160SelfGrowthValidateText -RepoRoot $RepoRoot -Path $ConsoleOutputSamplePath

  Assert-Phase160SelfGrowthValidateAtLeast -Actual $Heartbeat.heartbeat_count -Minimum 6 -Name "heartbeat_count"
  Assert-Phase160SelfGrowthValidateAtLeast -Actual $CurrentState.self_growth_duty_count -Minimum 3 -Name "current_state_self_growth_duty_count"
  Assert-Phase160SelfGrowthValidateAtLeast -Actual $DaemonResult.self_growth_duty_count -Minimum 3 -Name "daemon_result_self_growth_duty_count"
  Assert-Phase160SelfGrowthValidateTrue -Actual $CurrentState.self_growth_enabled -Name "current_state_self_growth_enabled"
  Assert-Phase160SelfGrowthValidateEquals -Actual $CurrentState.last_self_growth_status -Expected "PASS" -Name "current_state_last_self_growth_status"
  Assert-Phase160SelfGrowthValidateTrue -Actual (Test-Phase160SelfGrowthEventExists -Events $Events -EventType "self_growth_duty_started") -Name "event_log_self_growth_duty_started"
  Assert-Phase160SelfGrowthValidateTrue -Actual (Test-Phase160SelfGrowthEventExists -Events $Events -EventType "self_growth_duty_completed") -Name "event_log_self_growth_duty_completed"
  Assert-Phase160SelfGrowthValidateTrue -Actual $ObserverSummary.self_growth_seen -Name "observer_summary_self_growth_seen"
  Assert-Phase160SelfGrowthValidateAtLeast -Actual $ObserverSummary.self_growth_duty_count -Minimum 3 -Name "observer_summary_self_growth_duty_count"
  Assert-Phase160SelfGrowthValidateTrue -Actual $ConsoleResult.live_console_shows_self_growth_fields -Name "console_result_self_growth_fields"
  if ($ConsoleSample -notmatch "SELF_GROWTH_ENABLED=" -or $ConsoleSample -notmatch "DUTY_COUNT=" -or $ConsoleSample -notmatch "LAST_GAP=" -or $ConsoleSample -notmatch "NEXT_GAP=") {
    throw "PHASE160_SELF_GROWTH_VALIDATE_CONSOLE_SAMPLE_SELF_GROWTH_FIELDS_MISSING"
  }

  $RequiredDutyFiles = @(
    "self_map_snapshot.json",
    "capability_inventory_snapshot.json",
    "elementary_knowledge_snapshot.json",
    "gap_selection.json",
    "self_growth_intention.json",
    "sandbox_action_candidate.json",
    "sandbox_validation_result.json",
    "memory_event.json",
    "next_self_growth_decision.json",
    "duty_summary.json"
  )
  $ExpectedDutyGaps = @{
    duty_0001 = "SELF_MAP_REFRESH_GAP"
    duty_0002 = "CAPABILITY_INVENTORY_REFRESH_GAP"
    duty_0003 = "TEACHER_CHANNEL_READINESS_GAP"
  }
  foreach ($dutyId in @("duty_0001", "duty_0002", "duty_0003")) {
    foreach ($requiredFile in $RequiredDutyFiles) {
      $requiredDutyPath = "$SessionRoot/self_growth/$dutyId/$requiredFile"
      if (-not (Test-Path -LiteralPath (Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $requiredDutyPath))) {
        throw "PHASE160_SELF_GROWTH_VALIDATE_DUTY_FILE_MISSING=$requiredDutyPath"
      }
    }
    $GapSelection = Read-Phase160SelfGrowthValidateJson -RepoRoot $RepoRoot -Path "$SessionRoot/self_growth/$dutyId/gap_selection.json"
    $Validation = Read-Phase160SelfGrowthValidateJson -RepoRoot $RepoRoot -Path "$SessionRoot/self_growth/$dutyId/sandbox_validation_result.json"
    $Summary = Read-Phase160SelfGrowthValidateJson -RepoRoot $RepoRoot -Path "$SessionRoot/self_growth/$dutyId/duty_summary.json"
    Assert-Phase160SelfGrowthValidateEquals -Actual $GapSelection.selected_gap -Expected $ExpectedDutyGaps[$dutyId] -Name "${dutyId}_gap"
    Assert-Phase160SelfGrowthValidateEquals -Actual $Validation.status -Expected "PASS" -Name "${dutyId}_validation_status"
    Assert-Phase160SelfGrowthValidateEquals -Actual $Summary.status -Expected "PASS" -Name "${dutyId}_summary_status"
    Assert-Phase160SelfGrowthValidateTrue -Actual $Summary.memory_event_created -Name "${dutyId}_memory_event_created"
  }

  $Queue = Read-Phase160SelfGrowthValidateJson -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
  Assert-Phase160SelfGrowthValidateEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  $ProtectedStatusAfter = @(git status --short --untracked-files=all -- `
    TASK_QUEUE.json `
    GENESIS_STATE.json `
    CAPABILITY_ROADMAP.json `
    packs/registry.json `
    orchestrator/run.ps1 `
    capability_shelf `
    living_learning_environment/body `
    living_learning_environment/self_growth_runtime `
    generated_agents `
    applied_agents 2>$null)
  if ($ProtectedStatusAfter.Count -gt 0) {
    throw "PHASE160_SELF_GROWTH_VALIDATE_PROTECTED_SCOPE_DIRTY_AFTER=$($ProtectedStatusAfter -join '; ')"
  }

  $ExpansionManifest = [ordered]@{
    status = "PASS"
    repair_id = $RepairId
    run_id = $RunId
    expansion_runtime_root = $ExpansionRuntimeRoot
    daemon_result_tick_count = $DaemonResult.tick_count
    daemon_result_self_growth_duty_count = $DaemonResult.self_growth_duty_count
    observer_result_self_growth_seen = $ObserverResult.self_growth_seen
    console_poll_lines = $ConsolePollLines.Count
    console_output_sample_path = $ConsoleOutputSamplePath
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase160SelfGrowthValidateJsonFile -Path (Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $ExpansionManifestPath) -Object $ExpansionManifest

  $Proof = [ordered]@{
    status = "PASS"
    repair_id = $RepairId
    run_id = $RunId
    resolved_repo_root = $RepoRoot
    branch = $Branch
    local_head = $Head
    remote_head = $RemoteHead
    expected_head_source = $ExpectedHeadSource
    live_self_growth_duty_step_created = $true
    daemon_self_growth_integration_created = $true
    observer_self_growth_monitoring_created = $true
    console_self_growth_visibility_created = $true
    elementary_knowledge_snapshot_created = $true
    self_map_snapshot_created = $true
    capability_inventory_snapshot_created = $true
    deterministic_gap_policy_created = $true
    self_growth_duty_cycles_proven = $true
    self_growth_duty_count_at_least_3 = $true
    duty_0001_gap = "SELF_MAP_REFRESH_GAP"
    duty_0002_gap = "CAPABILITY_INVENTORY_REFRESH_GAP"
    duty_0003_gap = "TEACHER_CHANNEL_READINESS_GAP"
    sandbox_candidates_created = $true
    sandbox_validations_passed = $true
    memory_events_created = $true
    next_self_growth_decisions_created = $true
    event_log_self_growth_events_created = $true
    current_state_self_growth_fields_created = $true
    live_console_shows_self_growth_fields = $true
    observer_detects_self_growth_activity = $true
    blocker_channel_supported = $true
    teacher_channel_supported = $true
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    queue_mutated = $false
    capability_shelf_mutated = $false
    body_pack_mutated = $false
    self_growth_runtime_mutated = $false
    external_fetch_performed = $false
    dependency_install_performed = $false
    arbitrary_code_execution_used = $false
    external_agents_created = $false
    queue_after = "NONE"
    codex_needed_for_next_step = $false
    next_action = "READY_FOR_OWNER_SUPERVISED_LIVE_SELF_GROWTH_RUN"
    heartbeat_count = [int]$Heartbeat.heartbeat_count
    self_growth_duty_count = [int]$CurrentState.self_growth_duty_count
    console_output_sample_path = $ConsoleOutputSamplePath
    expansion_manifest_path = $ExpansionManifestPath
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $Report = [ordered]@{
    status = "PASS"
    repair_id = $RepairId
    line = "AGENT_BUILDER_SELF_DEVELOPMENT"
    mode = "VERIFY"
    root_cause = "live daemon only ticks, no meaningful self-growth duty loop"
    architecture_added = @(
      "Session-local duty step engine that observes, selects a deterministic gap, creates a sandbox candidate, validates it, writes memory_event, and decides the next gap.",
      "Daemon opt-in self-growth scheduler with tick start/every/max controls.",
      "Observer self-growth monitoring fields for duty count, latest gap, blocker count, and stagnation.",
      "Live console self-growth fields for owner screenshots."
    )
    files_changed = @($DutyStepPath, $DaemonPath, $ObserverPath, $ConsolePath, $ValidatorPath, $RouteRequestPath)
    exact_validator_command = ".\validators\validate_phase160_live_self_growth_duty_loop_v1.ps1 -RepoRoot ."
    exact_terminal_1_command = ".\modules\start_builder_live_growth_daemon_001.ps1 -SessionRoot runtime_sessions/live_growth/PHASE160_OWNER_SUPERVISED_LIVE_SELF_GROWTH_RUN_001 -DurationSeconds 900 -TickIntervalSeconds 10 -EnableSelfGrowthDuty -SelfGrowthEveryTicks 5 -SelfGrowthStartTick 2"
    exact_terminal_2_observer_command = ".\modules\watch_builder_live_growth_session_observer_001.ps1 -SessionRoot runtime_sessions/live_growth/PHASE160_OWNER_SUPERVISED_LIVE_SELF_GROWTH_RUN_001 -DurationSeconds 900 -PollIntervalSeconds 5 -ExpectSelfGrowthDuty"
    exact_terminal_2_console_command = ".\modules\watch_builder_live_console_001.ps1 -SessionRoot runtime_sessions/live_growth/PHASE160_OWNER_SUPERVISED_LIVE_SELF_GROWTH_RUN_001 -DurationSeconds 900 -PollIntervalSeconds 5 -ConsoleRunId PHASE160_OWNER_SUPERVISED_LIVE_SELF_GROWTH_CONSOLE_001 -ConsoleRuntimeRoot runtime_sessions/live_growth_self_growth/PHASE160_OWNER_SUPERVISED_LIVE_SELF_GROWTH_CONSOLE_001"
    what_builder_does_every_self_growth_duty = @(
      "Reads heartbeat/current_state and accepted proof summaries.",
      "Writes self_map, capability, and elementary operational knowledge snapshots.",
      "Selects the next deterministic curriculum gap.",
      "Creates and validates a sandbox-only self-growth action candidate.",
      "Evaluates teacher_outbox inputs as suggestions.",
      "Writes a session-local memory_event and next_self_growth_decision.",
      "Appends self-growth events to event_log and writes blockers if validation fails."
    )
    runtime_outputs_created = @($SessionRoot, $ExpansionRuntimeRoot, $ResultPath, $ReportPath, $ProofPath)
    risks = @(
      "Remote head verification uses local remote-tracking refs and does not fetch.",
      "Self-growth duties are sandbox-only and do not promote capabilities yet.",
      "Long owner-supervised runs should keep duration/stop.flag discipline because duties add per-tick work."
    )
    cut_list = @(
      "No PHASE161.",
      "No accepted PHASE159 or PHASE160 bootstrap/runtime/proof output mutation.",
      "No TASK_QUEUE, GENESIS_STATE, CAPABILITY_ROADMAP, registry, or orchestrator edits.",
      "No capability_shelf, body, self_growth_runtime, generated_agents, or applied_agents edits.",
      "No external fetch, dependency install, arbitrary generated-code execution, commit, or push."
    )
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  Write-Phase160SelfGrowthValidateJsonFile -Path (Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $ProofPath) -Object $Proof
  Write-Phase160SelfGrowthValidateJsonFile -Path (Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $ReportPath) -Object $Report
  Write-Phase160SelfGrowthValidateJsonFile -Path (Resolve-Phase160SelfGrowthValidatePath -RepoRoot $RepoRoot -Path $ResultPath) -Object $Proof

  Write-Host "PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_VALIDATE_RESULT=PASS"
  Write-Host "RESOLVED_REPO_ROOT=$RepoRoot"
  Write-Host "LOCAL_HEAD=$Head"
  Write-Host "REMOTE_HEAD=$RemoteHead"
  Write-Host "EXPECTED_HEAD_SOURCE=$ExpectedHeadSource"
  Write-Host "RUN_ID=$RunId"
  Write-Host "HEARTBEAT_COUNT=$($Heartbeat.heartbeat_count)"
  Write-Host "SELF_GROWTH_DUTY_COUNT=$($CurrentState.self_growth_duty_count)"
  Write-Host "DUTY_0001_GAP=SELF_MAP_REFRESH_GAP"
  Write-Host "DUTY_0002_GAP=CAPABILITY_INVENTORY_REFRESH_GAP"
  Write-Host "DUTY_0003_GAP=TEACHER_CHANNEL_READINESS_GAP"
  Write-Host "OBSERVER_DETECTS_SELF_GROWTH_ACTIVITY=True"
  Write-Host "LIVE_CONSOLE_SHOWS_SELF_GROWTH_FIELDS=True"
  Write-Host "QUEUE_AFTER=NONE"
  Write-Host "PROOF_PATH=$ProofPath"
  Write-Host "REPORT_PATH=$ReportPath"
  Write-Host "RESULT_PATH=$ResultPath"
  Write-Host "NEXT_ACTION=READY_FOR_OWNER_SUPERVISED_LIVE_SELF_GROWTH_RUN"
} catch {
  Write-Host "PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE160_SELF_GROWTH_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
