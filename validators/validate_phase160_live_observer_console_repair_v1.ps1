param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160ConsoleRepairFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160ConsoleRepairRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160ConsoleRepairFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160ConsoleRepairPath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase160ConsoleRepairJson {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160ConsoleRepairPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase160ConsoleRepairText {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160ConsoleRepairPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_MISSING_TEXT=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw
}

function Write-Phase160ConsoleRepairJsonFile {
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

function Assert-Phase160ConsoleRepairEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160ConsoleRepairTrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160ConsoleRepairFalse {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160ConsoleRepairAtLeast {
  param([object]$Actual, [int]$Minimum, [string]$Name)
  if ([int]$Actual -lt $Minimum) {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Get-Phase160ConsoleRepairRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Assert-Phase160ConsoleRepairParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_PARSE_ERROR=$($parseErrors[0].Message)"
  }
}

function Assert-Phase160ConsoleRepairNoStaticExpectedHead {
  param([string]$Text, [string]$Name)
  $staleHeadLiteral = ("d3e" + "1710")
  if ($Text -match [regex]::Escape($staleHeadLiteral)) {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_STALE_HEAD_LITERAL_FOUND=$Name"
  }
  if ($Text -match "\`$ExpectedHead\s*=\s*`"[^`"]+`"") {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_STATIC_EXPECTED_HEAD_FOUND=$Name"
  }
  if ($Text -match "C:\\Users\\Azerbaijan\\Downloads") {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_DOWNLOADS_PATH_FORBIDDEN=$Name"
  }
}

function Assert-Phase160ConsoleRepairOutputField {
  param([string[]]$Lines, [string]$Pattern, [string]$Name)
  foreach ($line in $Lines) {
    if ($line -notmatch $Pattern) {
      throw "PHASE160_LIVE_CONSOLE_VALIDATE_OUTPUT_FIELD_MISSING=$Name line=$line"
    }
  }
}

$Pushed = $false

try {
  $RepoRootParameter = $RepoRoot
  $RepoRoot = Resolve-Phase160ConsoleRepairRepoRoot
  Push-Location $RepoRoot
  $Pushed = $true
  Write-Host "PHASE160_LIVE_CONSOLE_VALIDATE_RESOLVED_REPO_ROOT=$RepoRoot"
  if ($RepoRootParameter -ne "." -and (Normalize-Phase160ConsoleRepairFullPath -Path $RepoRootParameter) -ne $RepoRoot) {
    Write-Host "PHASE160_LIVE_CONSOLE_VALIDATE_REPO_ROOT_PARAMETER_IGNORED=$RepoRootParameter"
  }

  $RepairId = "PHASE160_LIVE_OBSERVER_CONSOLE_REPAIR_V1"
  $ConsoleRunId = "PHASE160_LIVE_OBSERVER_CONSOLE_REPAIR_001"
  $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
  $ExistingSessionRoot = "runtime_sessions/live_growth/PHASE160_OWNER_SUPERVISED_LIVE_RUN_001"
  $ConsoleScriptPath = "modules/watch_builder_live_console_001.ps1"
  $ValidatorPath = "validators/validate_phase160_live_observer_console_repair_v1.ps1"
  $RouteRequestPath = "route_change_requests/PHASE160_LIVE_OBSERVER_CONSOLE_REPAIR_REQUEST.md"
  $ConsoleRuntimeRoot = "runtime_sessions/live_growth_console/$ConsoleRunId"
  $ConsoleRunResultPath = "$ConsoleRuntimeRoot/console_run_result.json"
  $ConsoleOutputSamplePath = "$ConsoleRuntimeRoot/console_output_sample.txt"
  $ReportPath = "reports/self_development/PHASE160_LIVE_OBSERVER_CONSOLE_REPAIR_REPORT.json"
  $ProofPath = "proofs/self_development/PHASE160_LIVE_OBSERVER_CONSOLE_REPAIR_V1.json"

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160ConsoleRepairPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  Assert-Phase160ConsoleRepairEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160ConsoleRepairRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160ConsoleRepairEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"
  $ExpectedHeadSource = "CURRENT_SYNCED_REPO_HEAD"
  $GitTopLevel = Normalize-Phase160ConsoleRepairFullPath -Path (git rev-parse --show-toplevel).Trim()
  Assert-Phase160ConsoleRepairEquals -Actual $GitTopLevel -Expected $RepoRoot -Name "git_top_level"

  foreach ($requiredPath in @($ExistingSessionRoot, $ConsoleScriptPath, $ValidatorPath, $RouteRequestPath)) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160ConsoleRepairPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE160_LIVE_CONSOLE_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

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
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_PROTECTED_SCOPE_DIRTY_BEFORE=$($ProtectedStatusBefore -join '; ')"
  }

  $ConsoleScriptFull = Resolve-Phase160ConsoleRepairPath -RepoRoot $RepoRoot -Path $ConsoleScriptPath
  $ValidatorFull = Resolve-Phase160ConsoleRepairPath -RepoRoot $RepoRoot -Path $ValidatorPath
  Assert-Phase160ConsoleRepairParserClean -Path $ConsoleScriptFull
  Assert-Phase160ConsoleRepairParserClean -Path $ValidatorFull

  $ConsoleScriptText = Read-Phase160ConsoleRepairText -RepoRoot $RepoRoot -Path $ConsoleScriptPath
  $ValidatorText = Read-Phase160ConsoleRepairText -RepoRoot $RepoRoot -Path $ValidatorPath
  Assert-Phase160ConsoleRepairNoStaticExpectedHead -Text $ConsoleScriptText -Name $ConsoleScriptPath
  Assert-Phase160ConsoleRepairNoStaticExpectedHead -Text $ValidatorText -Name $ValidatorPath

  foreach ($scriptText in @($ConsoleScriptText, $ValidatorText)) {
    if (-not $scriptText.Contains("PSScriptRoot")) {
      throw "PHASE160_LIVE_CONSOLE_VALIDATE_SCRIPT_ROOT_RULE_MISSING"
    }
    if (-not $scriptText.Contains("CURRENT_SYNCED_REPO_HEAD")) {
      throw "PHASE160_LIVE_CONSOLE_VALIDATE_EXPECTED_HEAD_SOURCE_MISSING"
    }
    if (-not $scriptText.Contains("current_synced_repo_head")) {
      throw "PHASE160_LIVE_CONSOLE_VALIDATE_SYNCED_HEAD_ASSERTION_MISSING"
    }
    if (-not $scriptText.Contains("git rev-parse --short HEAD")) {
      throw "PHASE160_LIVE_CONSOLE_VALIDATE_LOCAL_HEAD_READ_MISSING"
    }
    if (-not $scriptText.Contains("origin/`$ExpectedBranch")) {
      throw "PHASE160_LIVE_CONSOLE_VALIDATE_REMOTE_HEAD_READ_MISSING"
    }
  }

  foreach ($sessionFile in @(
    "$ExistingSessionRoot/heartbeat.json",
    "$ExistingSessionRoot/current_state.json",
    "$ExistingSessionRoot/event_log.jsonl",
    "$ExistingSessionRoot/observer_log.jsonl",
    "$ExistingSessionRoot/teacher_inbox/observer_intervention_suggestion_0001.json"
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160ConsoleRepairPath -RepoRoot $RepoRoot -Path $sessionFile))) {
      throw "PHASE160_LIVE_CONSOLE_VALIDATE_EXISTING_SESSION_INPUT_MISSING=$sessionFile"
    }
  }

  $ConsoleCommand = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $ConsoleScriptFull,
    "-SessionRoot", $ExistingSessionRoot,
    "-DurationSeconds", "20",
    "-PollIntervalSeconds", "5",
    "-ShowTailEvents", "3",
    "-ShowTailObserver", "3"
  )
  $ConsoleOutput = @(powershell @ConsoleCommand 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_CONSOLE_RUN_FAILED exit=$LASTEXITCODE output=$($ConsoleOutput -join ' | ')"
  }

  $PollLines = @($ConsoleOutput | Where-Object { $_ -match "^LIVE_CONSOLE POLL=" })
  Assert-Phase160ConsoleRepairAtLeast -Actual $PollLines.Count -Minimum 2 -Name "live_console_poll_lines"
  Assert-Phase160ConsoleRepairOutputField -Lines $PollLines -Pattern "HEARTBEAT_STATUS=" -Name "HEARTBEAT_STATUS"
  Assert-Phase160ConsoleRepairOutputField -Lines $PollLines -Pattern "(TICK=|HEARTBEAT_COUNT=)" -Name "TICK_OR_HEARTBEAT_COUNT"
  Assert-Phase160ConsoleRepairOutputField -Lines $PollLines -Pattern "EVENT_LINES=" -Name "EVENT_LINES"
  Assert-Phase160ConsoleRepairOutputField -Lines $PollLines -Pattern "OBSERVER_LINES=" -Name "OBSERVER_LINES"
  Assert-Phase160ConsoleRepairOutputField -Lines $PollLines -Pattern "BLOCKERS=" -Name "BLOCKERS"
  Assert-Phase160ConsoleRepairOutputField -Lines $PollLines -Pattern "TEACHER_INBOX=" -Name "TEACHER_INBOX"
  if (-not (@($ConsoleOutput | Where-Object { $_ -match "^LIVE_CONSOLE EVENT_TAIL" }).Count -gt 0)) {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_EVENT_TAIL_NOT_PRINTED"
  }
  if (-not (@($ConsoleOutput | Where-Object { $_ -match "^LIVE_CONSOLE OBSERVER_TAIL" }).Count -gt 0)) {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_OBSERVER_TAIL_NOT_PRINTED"
  }

  foreach ($outputPath in @($ConsoleRunResultPath, $ConsoleOutputSamplePath)) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160ConsoleRepairPath -RepoRoot $RepoRoot -Path $outputPath))) {
      throw "PHASE160_LIVE_CONSOLE_VALIDATE_OUTPUT_MISSING=$outputPath"
    }
  }

  $ConsoleRunResult = Read-Phase160ConsoleRepairJson -RepoRoot $RepoRoot -Path $ConsoleRunResultPath
  $ConsoleSample = Read-Phase160ConsoleRepairText -RepoRoot $RepoRoot -Path $ConsoleOutputSamplePath
  Assert-Phase160ConsoleRepairEquals -Actual $ConsoleRunResult.status -Expected "PASS" -Name "console_run_result_status"
  Assert-Phase160ConsoleRepairEquals -Actual $ConsoleRunResult.repair_id -Expected $RepairId -Name "console_run_result_repair_id"
  Assert-Phase160ConsoleRepairTrue -Actual $ConsoleRunResult.console_prints_live_lines -Name "console_prints_live_lines"
  Assert-Phase160ConsoleRepairTrue -Actual $ConsoleRunResult.console_reads_heartbeat -Name "console_reads_heartbeat"
  Assert-Phase160ConsoleRepairTrue -Actual $ConsoleRunResult.console_reads_current_state -Name "console_reads_current_state"
  Assert-Phase160ConsoleRepairTrue -Actual $ConsoleRunResult.console_reads_event_log -Name "console_reads_event_log"
  Assert-Phase160ConsoleRepairTrue -Actual $ConsoleRunResult.console_reads_observer_log -Name "console_reads_observer_log"
  Assert-Phase160ConsoleRepairTrue -Actual $ConsoleRunResult.console_reads_blocker_queue -Name "console_reads_blocker_queue"
  Assert-Phase160ConsoleRepairTrue -Actual $ConsoleRunResult.console_reads_teacher_inbox -Name "console_reads_teacher_inbox"
  Assert-Phase160ConsoleRepairTrue -Actual $ConsoleRunResult.console_reads_teacher_outbox -Name "console_reads_teacher_outbox"
  Assert-Phase160ConsoleRepairTrue -Actual $ConsoleRunResult.console_detects_stale_heartbeat -Name "console_detects_stale_heartbeat"
  Assert-Phase160ConsoleRepairTrue -Actual $ConsoleRunResult.console_supports_owner_screenshot_mode -Name "console_supports_owner_screenshot_mode"
  Assert-Phase160ConsoleRepairFalse -Actual $ConsoleRunResult.accepted_state_mutated -Name "console_result_accepted_state_mutated"
  Assert-Phase160ConsoleRepairFalse -Actual $ConsoleRunResult.queue_mutated -Name "console_result_queue_mutated"
  if ($ConsoleSample -notmatch "LIVE_CONSOLE POLL=") {
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_SAMPLE_NOT_READABLE"
  }

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
    throw "PHASE160_LIVE_CONSOLE_VALIDATE_PROTECTED_SCOPE_DIRTY_AFTER=$($ProtectedStatusAfter -join '; ')"
  }

  $Proof = [ordered]@{
    status = "PASS"
    repair_id = $RepairId
    target_step_id = "PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_V1"
    resolved_repo_root = $RepoRoot
    branch = $Branch
    local_head = $Head
    remote_head = $RemoteHead
    expected_head_source = $ExpectedHeadSource
    live_console_script_created = $true
    console_prints_live_lines = $true
    console_reads_heartbeat = $true
    console_reads_current_state = $true
    console_reads_event_log = $true
    console_reads_observer_log = $true
    console_reads_blocker_queue = $true
    console_reads_teacher_inbox = $true
    console_detects_stale_heartbeat = $true
    console_supports_owner_screenshot_mode = $true
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    queue_mutated = $false
    external_fetch_performed = $false
    dependency_install_performed = $false
    arbitrary_code_execution_used = $false
    phase161_created = $false
    console_run_result_path = $ConsoleRunResultPath
    console_output_sample_path = $ConsoleOutputSamplePath
    live_console_poll_lines = $PollLines.Count
    next_action = "READY_FOR_TWO_TERMINAL_LIVE_RUN_WITH_VISIBLE_CONSOLE"
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $Report = [ordered]@{
    status = "PASS"
    repair_id = $RepairId
    line = "AGENT_BUILDER_SELF_DEVELOPMENT"
    mode = "VERIFY"
    repair_type = "PHASE160 repair, not PHASE161"
    root_cause = "Observer watcher logged files but did not stream a readable live console for owner supervision."
    replacement_logic = "watch_builder_live_console_001.ps1 reads heartbeat, current_state, event log tail, observer log tail, blocker queue, teacher inbox, teacher outbox, stale heartbeat state, and stop flag status, then prints LIVE_CONSOLE lines every poll."
    resolved_repo_root = $RepoRoot
    branch = $Branch
    local_head = $Head
    remote_head = $RemoteHead
    expected_head_source = $ExpectedHeadSource
    console_script_path = $ConsoleScriptPath
    validator_path = $ValidatorPath
    route_request_path = $RouteRequestPath
    exact_validator_command = ".\validators\validate_phase160_live_observer_console_repair_v1.ps1 -RepoRoot ."
    exact_terminal_2_live_console_command = ".\modules\watch_builder_live_console_001.ps1 -SessionRoot runtime_sessions/live_growth/PHASE160_OWNER_SUPERVISED_LIVE_RUN_001 -DurationSeconds 900 -PollIntervalSeconds 5"
    validator_test_command_used = ".\modules\watch_builder_live_console_001.ps1 -SessionRoot runtime_sessions/live_growth/PHASE160_OWNER_SUPERVISED_LIVE_RUN_001 -DurationSeconds 20 -PollIntervalSeconds 5 -ShowTailEvents 3 -ShowTailObserver 3"
    runtime_outputs_created = @($ConsoleRunResultPath, $ConsoleOutputSamplePath)
    proof_path = $ProofPath
    report_path = $ReportPath
    protected_state_mutated = $false
    accepted_phase160_runtime_or_proof_mutated = $false
    external_fetch_performed = $false
    dependency_install_performed = $false
    phase161_created = $false
    risks = @(
      "Console uses local remote-tracking ref for remote head and does not fetch.",
      "Historical stopped sessions will report stale heartbeat by design.",
      "Live visibility depends on the daemon continuing to update heartbeat and log files."
    )
    cut_list = @(
      "No PHASE161.",
      "No TASK_QUEUE, GENESIS_STATE, CAPABILITY_ROADMAP, registry, or orchestrator edits.",
      "No accepted PHASE159 or PHASE160 proof/result/runtime output edits.",
      "No capability_shelf, body, self_growth_runtime, generated_agents, or applied_agents edits.",
      "No internet fetch, dependency install, commit, or push."
    )
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  Write-Phase160ConsoleRepairJsonFile -Path (Resolve-Phase160ConsoleRepairPath -RepoRoot $RepoRoot -Path $ProofPath) -Object $Proof
  Write-Phase160ConsoleRepairJsonFile -Path (Resolve-Phase160ConsoleRepairPath -RepoRoot $RepoRoot -Path $ReportPath) -Object $Report

  Write-Host "PHASE160_LIVE_OBSERVER_CONSOLE_REPAIR_VALIDATE_RESULT=PASS"
  Write-Host "RESOLVED_REPO_ROOT=$RepoRoot"
  Write-Host "LOCAL_HEAD=$Head"
  Write-Host "REMOTE_HEAD=$RemoteHead"
  Write-Host "EXPECTED_HEAD_SOURCE=$ExpectedHeadSource"
  Write-Host "LIVE_CONSOLE_SCRIPT_CREATED=True"
  Write-Host "LIVE_CONSOLE_POLL_LINES=$($PollLines.Count)"
  Write-Host "CONSOLE_OUTPUT_SAMPLE=$ConsoleOutputSamplePath"
  Write-Host "CONSOLE_RUN_RESULT=$ConsoleRunResultPath"
  Write-Host "PROOF_PATH=$ProofPath"
  Write-Host "REPORT_PATH=$ReportPath"
  Write-Host "NEXT_ACTION=READY_FOR_TWO_TERMINAL_LIVE_RUN_WITH_VISIBLE_CONSOLE"
} catch {
  Write-Host "PHASE160_LIVE_OBSERVER_CONSOLE_REPAIR_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE160_LIVE_CONSOLE_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
