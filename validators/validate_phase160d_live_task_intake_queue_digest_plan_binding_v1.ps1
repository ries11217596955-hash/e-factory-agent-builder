param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160DFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160DRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160D_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160DFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160DPath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Assert-Phase160DPathInsideRepo {
  param([string]$RepoRoot, [string]$Path)
  $root = Normalize-Phase160DFullPath -Path $RepoRoot
  $full = Normalize-Phase160DFullPath -Path (Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $Path)
  if (-not ($full -eq $root -or $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "PHASE160D_VALIDATE_PATH_OUTSIDE_REPO=$Path"
  }
  return $full
}

function Read-Phase160DJson {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160D_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase160DText {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160D_VALIDATE_MISSING_TEXT=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw
}

function Read-Phase160DJsonLines {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160D_VALIDATE_MISSING_JSONL=$Path"
  }
  return @(Get-Content -LiteralPath $fullPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_ | ConvertFrom-Json })
}

function Write-Phase160DJsonFile {
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

function Write-Phase160DTextFile {
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

function Assert-Phase160DEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160D_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160DTrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160D_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160DFalse {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160D_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160DAtLeast {
  param([object]$Actual, [int]$Minimum, [string]$Name)
  if ([int]$Actual -lt $Minimum) {
    throw "PHASE160D_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase160DParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160D_VALIDATE_PARSE_ERROR=$Path message=$($parseErrors[0].Message)"
  }
}

function Get-Phase160DRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160D_VALIDATE_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Remove-Phase160DOutput {
  param([string]$RepoRoot, [string]$Path)
  $full = Assert-Phase160DPathInsideRepo -RepoRoot $RepoRoot -Path $Path
  if (Test-Path -LiteralPath $full) {
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}

function Get-Phase160DFileHashes {
  param([string]$RepoRoot, [string[]]$Paths)
  $hashes = @{}
  foreach ($path in $Paths) {
    $full = Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $path
    if (Test-Path -LiteralPath $full) {
      $hashes[$path] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = "MISSING"
    }
  }
  return $hashes
}

function Get-Phase160DJsonFileCount {
  param([string]$RepoRoot, [string]$Path, [string]$Pattern = "*.json")
  $full = Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $full)) {
    return 0
  }
  return @(Get-ChildItem -LiteralPath $full -File -Filter $Pattern -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" }).Count
}

function Get-Phase160DRecursiveJsonFileCount {
  param([string]$RepoRoot, [string]$Path, [string]$Pattern = "*.json")
  $full = Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $full)) {
    return 0
  }
  return @(Get-ChildItem -LiteralPath $full -File -Filter $Pattern -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" -and $_.Name -ne "plan_digest.json" }).Count
}

function Test-Phase160DEventExists {
  param([object[]]$Events, [string]$EventType)
  return @($Events | Where-Object { [string]$_.event_type -eq $EventType }).Count -gt 0
}

function Wait-Phase160DDutyCount {
  param([string]$RepoRoot, [string]$CurrentStatePath, [int]$Minimum, [int]$TimeoutSeconds)
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $fullPath = Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $CurrentStatePath
    if (Test-Path -LiteralPath $fullPath) {
      $state = Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
      if ($state.PSObject.Properties.Name -contains "self_growth_duty_count" -and [int]$state.self_growth_duty_count -ge $Minimum) {
        return $state
      }
    }
    Start-Sleep -Seconds 1
  }
  throw "PHASE160D_VALIDATE_DUTY_COUNT_TIMEOUT minimum=$Minimum"
}

function Assert-Phase160DRuntimeOutputsNotStaged {
  $stagedRuntime = @(git diff --cached --name-only -- runtime_sessions)
  if ($stagedRuntime.Count -gt 0) {
    throw "PHASE160D_VALIDATE_RUNTIME_OUTPUTS_STAGED=$($stagedRuntime -join '; ')"
  }
}

$Pushed = $false

try {
  $RepoRootParameter = $RepoRoot
  $RepoRoot = Resolve-Phase160DRepoRoot
  Push-Location $RepoRoot
  $Pushed = $true
  Write-Host "PHASE160D_VALIDATE_RESOLVED_REPO_ROOT=$RepoRoot"
  if ($RepoRootParameter -ne "." -and (Normalize-Phase160DFullPath -Path $RepoRootParameter) -ne $RepoRoot) {
    Write-Host "PHASE160D_VALIDATE_REPO_ROOT_PARAMETER_IGNORED=$RepoRootParameter"
  }

  $RepairId = "PHASE160D_LIVE_TASK_INTAKE_QUEUE_DIGEST_PLAN_BINDING_V1"
  $RunId = "PHASE160D_LIVE_TASK_INTAKE_SMOKE_001"
  $ConsoleRunId = "PHASE160D_LIVE_TASK_INTAKE_CONSOLE_001"
  $CycleId = "PHASE160D_LIVE_TASK_INTAKE_CYCLE_001"
  $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
  $SessionRoot = "runtime_sessions/live_growth/$RunId"
  $ConsoleRuntimeRoot = "runtime_sessions/live_growth_console/$ConsoleRunId"
  $DutyStepPath = "modules/invoke_builder_live_self_growth_duty_step_001.ps1"
  $DaemonPath = "modules/start_builder_live_growth_daemon_001.ps1"
  $ObserverPath = "modules/watch_builder_live_growth_session_observer_001.ps1"
  $ConsolePath = "modules/watch_builder_live_console_001.ps1"
  $ValidatorPath = "validators/validate_phase160d_live_task_intake_queue_digest_plan_binding_v1.ps1"
  $ReportPath = "reports/self_development/PHASE160D_LIVE_TASK_INTAKE_QUEUE_DIGEST_PLAN_BINDING_REPORT.md"
  $ProofPath = "proofs/self_development/PHASE160D_LIVE_TASK_INTAKE_QUEUE_DIGEST_PLAN_BINDING_PROOF.json"
  $RouteRequestPath = "route_change_requests/PHASE160D_LIVE_TASK_INTAKE_QUEUE_DIGEST_PLAN_BINDING_REQUEST.md"

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  Assert-Phase160DEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160DRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160DEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"
  $ExpectedHeadSource = "CURRENT_SYNCED_REPO_HEAD"
  $GitTopLevel = Normalize-Phase160DFullPath -Path (git rev-parse --show-toplevel).Trim()
  Assert-Phase160DEquals -Actual $GitTopLevel -Expected $RepoRoot -Name "git_top_level"

  $ProtectedPaths = @("TASK_QUEUE.json", "GENESIS_STATE.json", "CAPABILITY_ROADMAP.json", "packs/registry.json", "orchestrator/run.ps1")
  $ProtectedHashesBefore = Get-Phase160DFileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths

  foreach ($requiredPath in @($DutyStepPath, $DaemonPath, $ObserverPath, $ConsolePath, $ValidatorPath, $RouteRequestPath)) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE160D_VALIDATE_REQUIRED_PATH_MISSING=$requiredPath"
    }
  }
  foreach ($scriptPath in @($DutyStepPath, $DaemonPath, $ObserverPath, $ConsolePath, $ValidatorPath)) {
    Assert-Phase160DParserClean -Path (Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $scriptPath)
  }

  foreach ($outputPath in @($SessionRoot, $ConsoleRuntimeRoot, $ReportPath, $ProofPath)) {
    Remove-Phase160DOutput -RepoRoot $RepoRoot -Path $outputPath
  }
  $TeacherInboxFull = Resolve-Phase160DPath -RepoRoot $RepoRoot -Path "$SessionRoot/teacher_inbox"
  New-Item -ItemType Directory -Force -Path $TeacherInboxFull | Out-Null

  $SafetyRules = [ordered]@{
    accepted_state_mutation_allowed = $false
    accepted_memory_mutation_allowed = $false
    accepted_self_model_mutation_allowed = $false
    repo_commit_allowed = $false
    runtime_session_only = $true
  }
  $HighOwnerTask = [ordered]@{
    event_type = "owner_live_task_injection"
    task_id = "PHASE160D_HIGH_OWNER_EXPERIENCE_ABSORPTION_GATE_001"
    source = "owner"
    priority = "high"
    created_at = "2026-06-04T00:00:00Z"
    owner_goal = "Experience Absorption Gate should drive the next macro-cycle gap selection."
    desired_next_gap = "EXPERIENCE_ABSORPTION_GATE"
    safety_rules = $SafetyRules
    accepted_state_mutation_allowed = $false
    accepted_memory_mutation_allowed = $false
    accepted_self_model_mutation_allowed = $false
    repo_commit_allowed = $false
    runtime_session_only = $true
    success_signals = @("active_task_selected", "macro_gap_ranked_to_experience_absorption_gate")
  }
  $PlanSteps = @()
  for ($i = 1; $i -le 10; $i += 1) {
    $PlanSteps += "Plan step $i for backlog-only long plan digestion."
  }
  $NormalPlanTask = [ordered]@{
    event_type = "owner_live_task_injection"
    task_id = "PHASE160D_NORMAL_OWNER_TEN_STEP_PLAN_001"
    source = "owner"
    priority = "normal"
    created_at = "2026-06-04T00:01:00Z"
    owner_goal = "Store this 10-step plan as backlog and split it into session-local plan items."
    desired_next_gap = "LONG_PLAN_BACKLOG_BINDING_GAP"
    plan_steps = $PlanSteps
    safety_rules = $SafetyRules
    accepted_state_mutation_allowed = $false
    accepted_memory_mutation_allowed = $false
    accepted_self_model_mutation_allowed = $false
    repo_commit_allowed = $false
    runtime_session_only = $true
    success_signals = @("plan_digest_written", "ten_plan_items_created")
  }
  $UnsafeTask = [ordered]@{
    event_type = "owner_live_task_injection"
    task_id = "PHASE160D_UNSAFE_STATE_MUTATION_001"
    source = "owner"
    priority = "high"
    created_at = "2026-06-04T00:02:00Z"
    owner_goal = "Unsafe request that must be quarantined."
    desired_next_gap = "UNSAFE_ACCEPTED_STATE_MUTATION_GAP"
    safety_rules = [ordered]@{
      accepted_state_mutation_allowed = $true
      accepted_memory_mutation_allowed = $false
      accepted_self_model_mutation_allowed = $false
      repo_commit_allowed = $false
      runtime_session_only = $true
    }
    accepted_state_mutation_allowed = $true
    accepted_memory_mutation_allowed = $false
    accepted_self_model_mutation_allowed = $false
    repo_commit_allowed = $false
    runtime_session_only = $true
    success_signals = @("must_not_execute")
  }

  Write-Phase160DJsonFile -Path (Join-Path $TeacherInboxFull "001_high_owner_experience_absorption_gate.json") -Object $HighOwnerTask
  Write-Phase160DJsonFile -Path (Join-Path $TeacherInboxFull "002_normal_owner_ten_step_plan.json") -Object $NormalPlanTask
  Write-Phase160DJsonFile -Path (Join-Path $TeacherInboxFull "003_unsafe_state_mutation.json") -Object $UnsafeTask
  Write-Phase160DJsonFile -Path (Join-Path $TeacherInboxFull "004_duplicate_high_owner_experience_absorption_gate.json") -Object $HighOwnerTask

  $DaemonFullPath = Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $DaemonPath
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
      -MaxSelfGrowthDuties 4 `
      -SelfGrowthDutyRoot "$SessionRoot/self_growth" `
      -EnableMacroSelfGrowthCycle `
      -MacroCycleId $CycleId 2>&1
    $exit = $LASTEXITCODE
    if ($exit -ne 0) {
      throw "PHASE160D_DAEMON_JOB_FAILED exit=$exit output=$($output -join ' | ')"
    }
    $output
  } -ArgumentList $RepoRoot, $DaemonFullPath, $SessionRoot, $CycleId

  $null = Wait-Phase160DDutyCount -RepoRoot $RepoRoot -CurrentStatePath "$SessionRoot/current_state.json" -Minimum 4 -TimeoutSeconds 90
  $StopFlagPath = Resolve-Phase160DPath -RepoRoot $RepoRoot -Path "$SessionRoot/stop.flag"
  [System.IO.File]::WriteAllText($StopFlagPath, "PHASE160D_STOP_REQUEST`n", [System.Text.UTF8Encoding]::new($false))
  $completedJob = Wait-Job -Job $DaemonJob -Timeout 30
  if ($null -eq $completedJob) {
    Stop-Job -Job $DaemonJob
    Receive-Job -Job $DaemonJob -Keep | Out-String | Write-Host
    throw "PHASE160D_VALIDATE_DAEMON_STOP_FLAG_TIMEOUT"
  }
  $DaemonOutput = @(Receive-Job -Job $DaemonJob)
  if ($DaemonJob.State -ne "Completed") {
    throw "PHASE160D_VALIDATE_DAEMON_JOB_STATE=$($DaemonJob.State) output=$($DaemonOutput -join ' | ')"
  }
  Remove-Job -Job $DaemonJob
  $DaemonResult = ($DaemonOutput -join "`n") | ConvertFrom-Json

  $ObserverOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $ObserverPath) -SessionRoot $SessionRoot -DurationSeconds 3 -PollIntervalSeconds 1 -ExpectSelfGrowthDuty 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160D_VALIDATE_OBSERVER_FAILED output=$($ObserverOutput -join ' | ')"
  }
  $ObserverResult = ($ObserverOutput -join "`n") | ConvertFrom-Json

  $ConsoleOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $ConsolePath) -SessionRoot $SessionRoot -DurationSeconds 3 -PollIntervalSeconds 1 -ConsoleRunId $ConsoleRunId -ConsoleRuntimeRoot $ConsoleRuntimeRoot 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160D_VALIDATE_CONSOLE_FAILED output=$($ConsoleOutput -join ' | ')"
  }
  $ConsolePollLines = @($ConsoleOutput | Where-Object { $_ -match "^LIVE_CONSOLE POLL=" })
  Assert-Phase160DAtLeast -Actual $ConsolePollLines.Count -Minimum 2 -Name "console_poll_lines"
  foreach ($requiredConsoleField in @("TEACHER_INBOX_COUNT=", "TEACHER_DIGEST_COUNT=", "TEACHER_CONSUMED_COUNT=", "TEACHER_QUARANTINE_COUNT=", "TASK_BACKLOG_COUNT=", "ACTIVE_TASK=", "ACTIVE_PLAN_ITEM=", "LAST_CONSUMED_TASK=", "LAST_TASK_INFLUENCED_GAP=")) {
    if (-not (@($ConsolePollLines | Where-Object { $_ -match [regex]::Escape($requiredConsoleField) }).Count -eq $ConsolePollLines.Count)) {
      throw "PHASE160D_VALIDATE_CONSOLE_FIELD_MISSING=$requiredConsoleField"
    }
  }

  $Heartbeat = Read-Phase160DJson -RepoRoot $RepoRoot -Path "$SessionRoot/heartbeat.json"
  $CurrentState = Read-Phase160DJson -RepoRoot $RepoRoot -Path "$SessionRoot/current_state.json"
  $FinalState = Read-Phase160DJson -RepoRoot $RepoRoot -Path "$SessionRoot/final_state.json"
  $ActiveTask = Read-Phase160DJson -RepoRoot $RepoRoot -Path "$SessionRoot/active_task/active_task.json"
  $GapRank = Read-Phase160DJson -RepoRoot $RepoRoot -Path "$SessionRoot/self_growth/duty_0003/gap_selection.json"
  $Candidate = Read-Phase160DJson -RepoRoot $RepoRoot -Path "$SessionRoot/self_growth/duty_0004/sandbox_action_candidate.json"
  $Events = Read-Phase160DJsonLines -RepoRoot $RepoRoot -Path "$SessionRoot/event_log.jsonl"
  $LedgerEntries = Read-Phase160DJsonLines -RepoRoot $RepoRoot -Path "$SessionRoot/self_growth/experience_ledger.jsonl"
  $ConsoleResult = Read-Phase160DJson -RepoRoot $RepoRoot -Path "$ConsoleRuntimeRoot/console_run_result.json"

  $TeacherInboxCount = Get-Phase160DJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/teacher_inbox"
  $TeacherDigestCount = Get-Phase160DJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/teacher_digest"
  $TeacherConsumedCount = Get-Phase160DJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/teacher_consumed" -Pattern "receipt_*.json"
  $TeacherQuarantineCount = Get-Phase160DJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/teacher_quarantine" -Pattern "quarantine_*.json"
  $TaskBacklogCount = Get-Phase160DJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/task_backlog"
  $PlanItemCount = Get-Phase160DRecursiveJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/plan_items" -Pattern "*_plan_item_*.json"

  Assert-Phase160DAtLeast -Actual $DaemonResult.self_growth_duty_count -Minimum 4 -Name "daemon_self_growth_duty_count"
  Assert-Phase160DAtLeast -Actual $CurrentState.self_growth_duty_count -Minimum 4 -Name "current_state_self_growth_duty_count"
  Assert-Phase160DEquals -Actual $TeacherInboxCount -Expected 0 -Name "teacher_inbox_left_unprocessed"
  Assert-Phase160DAtLeast -Actual $TeacherDigestCount -Minimum 3 -Name "teacher_digest_count"
  Assert-Phase160DAtLeast -Actual $TeacherConsumedCount -Minimum 3 -Name "teacher_consumed_count"
  Assert-Phase160DAtLeast -Actual $TeacherQuarantineCount -Minimum 1 -Name "teacher_quarantine_count"
  Assert-Phase160DAtLeast -Actual $TaskBacklogCount -Minimum 1 -Name "task_backlog_count"
  Assert-Phase160DAtLeast -Actual $PlanItemCount -Minimum 10 -Name "plan_item_count"
  Assert-Phase160DEquals -Actual $ActiveTask.task_id -Expected "PHASE160D_HIGH_OWNER_EXPERIENCE_ABSORPTION_GATE_001" -Name "active_task_id"
  Assert-Phase160DEquals -Actual $GapRank.selected_gap -Expected "MACRO_EXPERIENCE_ABSORPTION_GATE_GAP" -Name "gap_rank_selected_gap"
  Assert-Phase160DTrue -Actual $GapRank.task_influenced_gap_selection -Name "gap_rank_task_influenced"
  Assert-Phase160DEquals -Actual $Candidate.active_task_id -Expected "PHASE160D_HIGH_OWNER_EXPERIENCE_ABSORPTION_GATE_001" -Name "candidate_active_task_id"
  Assert-Phase160DTrue -Actual ([string]$Candidate.owner_goal -match "Experience Absorption Gate") -Name "candidate_owner_goal_mentions_experience_absorption_gate"
  Assert-Phase160DEquals -Actual $Candidate.decision -Expected "OWNER_DECISION_REQUIRED" -Name "candidate_decision"
  Assert-Phase160DTrue -Actual $ConsoleResult.live_console_shows_task_intake_fields -Name "console_task_intake_fields"
  Assert-Phase160DFalse -Actual $FinalState.accepted_state_mutated -Name "final_state_accepted_state_mutated"
  Assert-Phase160DFalse -Actual $FinalState.accepted_memory_mutated -Name "final_state_accepted_memory_mutated"
  Assert-Phase160DFalse -Actual $FinalState.accepted_self_model_mutated -Name "final_state_accepted_self_model_mutated"

  foreach ($eventType in @(
    "live_task_inbox_scan_started",
    "live_task_detected",
    "live_task_validated",
    "live_task_deduplicated",
    "live_task_digest_written",
    "live_task_plan_split",
    "live_task_backlog_written",
    "live_task_active_selected",
    "live_task_consumed",
    "live_task_quarantined",
    "live_task_injected_into_macro_ranking"
  )) {
    Assert-Phase160DTrue -Actual (Test-Phase160DEventExists -Events $Events -EventType $eventType) -Name "event:$eventType"
  }

  $InfluencedLedgerEntries = @($LedgerEntries | Where-Object { $_.PSObject.Properties.Name -contains "task_influenced_gap_selection" -and [bool]$_.task_influenced_gap_selection })
  Assert-Phase160DAtLeast -Actual $InfluencedLedgerEntries.Count -Minimum 1 -Name "ledger_task_influenced_entries"
  foreach ($entry in $LedgerEntries) {
    foreach ($requiredLedgerField in @("active_task_id", "teacher_digest_path", "consumed_owner_task", "task_influenced_gap_selection", "backlog_count", "consumed_count", "quarantine_count")) {
      if (-not ($entry.PSObject.Properties.Name -contains $requiredLedgerField)) {
        throw "PHASE160D_VALIDATE_LEDGER_FIELD_MISSING=$requiredLedgerField"
      }
    }
  }

  $ProtectedHashesAfter = Get-Phase160DFileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths
  foreach ($path in $ProtectedPaths) {
    Assert-Phase160DEquals -Actual $ProtectedHashesAfter[$path] -Expected $ProtectedHashesBefore[$path] -Name "protected_hash:$path"
  }
  $ProtectedStateMutated = $false

  Assert-Phase160DRuntimeOutputsNotStaged
  $RuntimeOutputsStaged = $false

  $Proof = [ordered]@{
    status = "PASS"
    acceptance_language = "PHASE160D_LIVE_TASK_INTAKE_QUEUE_DIGEST_PLAN_BINDING_VALIDATE_RESULT=PASS"
    repair_id = $RepairId
    run_id = $RunId
    resolved_repo_root = $RepoRoot
    branch = $Branch
    local_head = $Head
    remote_head = $RemoteHead
    expected_head_source = $ExpectedHeadSource
    parser_checks_pass = $true
    custom_run_id_smoke_works = $true
    inbox_tasks_seeded_count = 4
    inbox_scan_detected_all = $true
    valid_task_digests_written = $true
    duplicate_task_handling_works = $true
    unsafe_task_quarantined = $true
    long_plan_split_supported = $true
    active_task_selected = $true
    task_backlog_written = $true
    raw_processed_files_left_in_inbox = $false
    consumed_receipts_exist = $true
    task_influenced_macro_gap = $true
    self_change_candidate_mentions_active_task = $true
    ledger_references_active_task_and_digest = $true
    console_fields_visible = $true
    protected_state_mutated = $ProtectedStateMutated
    runtime_outputs_staged = $RuntimeOutputsStaged
    teacher_inbox_count = $TeacherInboxCount
    teacher_digest_count = $TeacherDigestCount
    teacher_consumed_count = $TeacherConsumedCount
    teacher_quarantine_count = $TeacherQuarantineCount
    task_backlog_count = $TaskBacklogCount
    plan_item_count = $PlanItemCount
    active_task_id = [string]$ActiveTask.task_id
    active_plan_item_id = [string]$ActiveTask.active_plan_item_id
    selected_gap = [string]$GapRank.selected_gap
    candidate_decision = [string]$Candidate.decision
    observer_detected_self_growth = [bool]$ObserverResult.self_growth_seen
    heartbeat_active_task_id = [string]$Heartbeat.active_task_id
    current_state_active_task_id = [string]$CurrentState.active_task_id
    final_state_active_task_id = [string]$FinalState.active_task_id
    report_path = $ReportPath
    proof_path = $ProofPath
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase160DJsonFile -Path (Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $ProofPath) -Object $Proof

  $ReportLines = @(
    "# PHASE160D Live Task Intake Queue Digest Plan Binding Report",
    "",
    "status: PASS",
    "repair_id: $RepairId",
    "line: AGENT_BUILDER_SELF_DEVELOPMENT",
    "mode: VERIFY",
    "run_id: $RunId",
    "",
    "## Result",
    "PHASE160D_LIVE_TASK_INTAKE_QUEUE_DIGEST_PLAN_BINDING_VALIDATE_RESULT=PASS",
    "MULTI_TASK_INBOX_SUPPORTED=True",
    "LONG_PLAN_SPLIT_SUPPORTED=True",
    "OWNER_TASK_CONSUMED=True",
    "TASK_DIGEST_WRITTEN=True",
    "TASK_BACKLOG_WRITTEN=True",
    "ACTIVE_TASK_SELECTED=True",
    "TASK_INFLUENCED_MACRO_GAP=True",
    "INBOX_LEFT_UNPROCESSED=False",
    "UNSAFE_TASK_QUARANTINED=True",
    "PROTECTED_STATE_MUTATED=False",
    "",
    "## Proof Summary",
    "- Teacher inbox count after run: $TeacherInboxCount",
    "- Teacher digest count: $TeacherDigestCount",
    "- Teacher consumed receipt count: $TeacherConsumedCount",
    "- Teacher quarantine count: $TeacherQuarantineCount",
    "- Task backlog count: $TaskBacklogCount",
    "- Plan item count: $PlanItemCount",
    "- Active task: $($ActiveTask.task_id)",
    "- Gap rank selected gap: $($GapRank.selected_gap)",
    "- Candidate decision: $($Candidate.decision)",
    "- Runtime outputs staged: False",
    "",
    "## Files Changed",
    "- $DutyStepPath",
    "- $DaemonPath",
    "- $ConsolePath",
    "- $ObserverPath",
    "- $ValidatorPath",
    "- $ReportPath",
    "- $ProofPath",
    "- $RouteRequestPath",
    "",
    "## Validation Command",
    '```powershell',
    ".\validators\validate_phase160d_live_task_intake_queue_digest_plan_binding_v1.ps1 -RepoRoot .",
    '```',
    "",
    "## Cut List",
    "- No TASK_QUEUE, GENESIS_STATE, CAPABILITY_ROADMAP, packs/registry, or orchestrator edits.",
    "- No external-agent production.",
    "- No dependency install, external fetch, commit, or push.",
    "- Runtime session outputs are proof artifacts and must not be staged."
  )
  Write-Phase160DTextFile -Path (Resolve-Phase160DPath -RepoRoot $RepoRoot -Path $ReportPath) -Text ($ReportLines -join "`n")

  Write-Host "PHASE160D_LIVE_TASK_INTAKE_QUEUE_DIGEST_PLAN_BINDING_VALIDATE_RESULT=PASS"
  Write-Host "MULTI_TASK_INBOX_SUPPORTED=True"
  Write-Host "LONG_PLAN_SPLIT_SUPPORTED=True"
  Write-Host "OWNER_TASK_CONSUMED=True"
  Write-Host "TASK_DIGEST_WRITTEN=True"
  Write-Host "TASK_BACKLOG_WRITTEN=True"
  Write-Host "ACTIVE_TASK_SELECTED=True"
  Write-Host "TASK_INFLUENCED_MACRO_GAP=True"
  Write-Host "INBOX_LEFT_UNPROCESSED=False"
  Write-Host "UNSAFE_TASK_QUARANTINED=True"
  Write-Host "PROTECTED_STATE_MUTATED=False"
  Write-Host "REPORT_PATH=$ReportPath"
  Write-Host "PROOF_PATH=$ProofPath"
} catch {
  Write-Host "PHASE160D_LIVE_TASK_INTAKE_QUEUE_DIGEST_PLAN_BINDING_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE160D_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
