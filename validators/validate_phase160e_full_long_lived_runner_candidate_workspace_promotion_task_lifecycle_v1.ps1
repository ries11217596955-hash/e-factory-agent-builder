param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160EFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160ERepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160E_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160EFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160EPath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Assert-Phase160EPathInsideRepo {
  param([string]$RepoRoot, [string]$Path)
  $root = Normalize-Phase160EFullPath -Path $RepoRoot
  $full = Normalize-Phase160EFullPath -Path (Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $Path)
  if (-not ($full -eq $root -or $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "PHASE160E_VALIDATE_PATH_OUTSIDE_REPO=$Path"
  }
  return $full
}

function ConvertTo-Phase160ERelativePath {
  param([string]$RepoRoot, [string]$FullPath)
  $root = Normalize-Phase160EFullPath -Path $RepoRoot
  $full = Normalize-Phase160EFullPath -Path $FullPath
  if ($full -eq $root) {
    return "."
  }
  if (-not $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160E_VALIDATE_PATH_OUTSIDE_REPO=$FullPath"
  }
  return ($full.Substring($root.Length + 1) -replace "\\", "/")
}

function Read-Phase160EJson {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160E_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase160EText {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160E_VALIDATE_MISSING_TEXT=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw
}

function Read-Phase160EJsonLines {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160E_VALIDATE_MISSING_JSONL=$Path"
  }
  return @(Get-Content -LiteralPath $fullPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_ | ConvertFrom-Json })
}

function Write-Phase160EJsonFile {
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

function Write-Phase160ETextFile {
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

function Assert-Phase160EEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160E_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160ETrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160E_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160EFalse {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160E_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160EAtLeast {
  param([object]$Actual, [int]$Minimum, [string]$Name)
  if ([int]$Actual -lt $Minimum) {
    throw "PHASE160E_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase160EParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160E_VALIDATE_PARSE_ERROR=$Path message=$($parseErrors[0].Message)"
  }
}

function Remove-Phase160EOutput {
  param([string]$RepoRoot, [string]$Path)
  $full = Assert-Phase160EPathInsideRepo -RepoRoot $RepoRoot -Path $Path
  if (Test-Path -LiteralPath $full) {
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}

function Get-Phase160ERemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160E_VALIDATE_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Get-Phase160EFileHashes {
  param([string]$RepoRoot, [string[]]$Paths)
  $hashes = @{}
  foreach ($path in $Paths) {
    $full = Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $path
    if (Test-Path -LiteralPath $full) {
      $hashes[$path] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = "MISSING"
    }
  }
  return $hashes
}

function Get-Phase160ETrackedStatus {
  return @(git status --short --untracked-files=no | ForEach-Object { [string]$_ } | Sort-Object)
}

function Get-Phase160EJsonFileCount {
  param([string]$RepoRoot, [string]$Path, [string]$Pattern = "*.json")
  $full = Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $full)) {
    return 0
  }
  return @(Get-ChildItem -LiteralPath $full -File -Filter $Pattern -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" }).Count
}

function Get-Phase160ERecursiveJsonFileCount {
  param([string]$RepoRoot, [string]$Path, [string]$Pattern = "*.json")
  $full = Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $full)) {
    return 0
  }
  return @(Get-ChildItem -LiteralPath $full -File -Filter $Pattern -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" }).Count
}

function Test-Phase160EEventExists {
  param([object[]]$Events, [string]$EventType)
  return @($Events | Where-Object { [string]$_.event_type -eq $EventType }).Count -gt 0
}

function Assert-Phase160ERuntimeOutputsNotStaged {
  $stagedRuntime = @(git diff --cached --name-only -- runtime_sessions)
  if ($stagedRuntime.Count -gt 0) {
    throw "PHASE160E_VALIDATE_RUNTIME_OUTPUTS_STAGED=$($stagedRuntime -join '; ')"
  }
}

function Wait-Phase160ECandidateBundle {
  param([string]$RepoRoot, [string]$SessionRoot, [int]$MinimumCandidates, [int]$MinimumDuties, [int]$TimeoutSeconds)
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $manifestPath = Resolve-Phase160EPath -RepoRoot $RepoRoot -Path "$SessionRoot/promotion_bundle/promotion_manifest.json"
    $statePath = Resolve-Phase160EPath -RepoRoot $RepoRoot -Path "$SessionRoot/current_state.json"
    $candidateCount = 0
    $dutyCount = 0
    if (Test-Path -LiteralPath $manifestPath) {
      $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
      if ($manifest.PSObject.Properties.Name -contains "candidate_count") {
        $candidateCount = [int]$manifest.candidate_count
      }
    }
    if (Test-Path -LiteralPath $statePath) {
      $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
      if ($state.PSObject.Properties.Name -contains "self_growth_duty_count") {
        $dutyCount = [int]$state.self_growth_duty_count
      }
    }
    if ($candidateCount -ge $MinimumCandidates -and $dutyCount -ge $MinimumDuties) {
      return [pscustomobject][ordered]@{
        candidate_count = $candidateCount
        duty_count = $dutyCount
      }
    }
    Start-Sleep -Seconds 1
  }
  throw "PHASE160E_VALIDATE_CANDIDATE_BUNDLE_TIMEOUT minimum_candidates=$MinimumCandidates minimum_duties=$MinimumDuties"
}

$Pushed = $false

try {
  $RepoRootParameter = $RepoRoot
  $RepoRoot = Resolve-Phase160ERepoRoot
  Push-Location $RepoRoot
  $Pushed = $true
  Write-Host "PHASE160E_VALIDATE_RESOLVED_REPO_ROOT=$RepoRoot"
  if ($RepoRootParameter -ne "." -and (Normalize-Phase160EFullPath -Path $RepoRootParameter) -ne $RepoRoot) {
    Write-Host "PHASE160E_VALIDATE_REPO_ROOT_PARAMETER_IGNORED=$RepoRootParameter"
  }

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
  $RepairId = "PHASE160E_FULL_LONG_LIVED_RUNNER_CANDIDATE_WORKSPACE_PROMOTION_TASK_LIFECYCLE_V1"
  $RunId = "PHASE160E_FULL_GATE_SMOKE_001"
  $CycleId = "PHASE160E_FULL_GATE_CYCLE_001"
  $SessionRoot = "runtime_sessions/live_growth/$RunId"
  $ConsoleRunId = "PHASE160E_CONSOLE_SMOKE_001"
  $ConsoleRuntimeRoot = "runtime_sessions/live_growth_console/$ConsoleRunId"
  $ReportPath = "reports/self_development/PHASE160E_FULL_LONG_LIVED_RUNNER_CANDIDATE_WORKSPACE_PROMOTION_TASK_LIFECYCLE_REPORT.md"
  $ProofPath = "proofs/self_development/PHASE160E_FULL_LONG_LIVED_RUNNER_CANDIDATE_WORKSPACE_PROMOTION_TASK_LIFECYCLE_PROOF.json"
  $RouteRequestPath = "route_change_requests/PHASE160E_FULL_LONG_LIVED_RUNNER_CANDIDATE_WORKSPACE_PROMOTION_TASK_LIFECYCLE.md"
  $DaemonPath = "modules/start_builder_live_growth_daemon_001.ps1"
  $DutyStepPath = "modules/invoke_builder_live_self_growth_duty_step_001.ps1"
  $ConsolePath = "modules/watch_builder_live_console_001.ps1"
  $ObserverPath = "modules/watch_builder_live_growth_session_observer_001.ps1"
  $IdentityPath = "modules/inspect_builder_runtime_identity_001.ps1"
  $CandidateStepPath = "modules/invoke_builder_candidate_workspace_step_001.ps1"
  $PromotionFinalizePath = "modules/finalize_builder_promotion_bundle_001.ps1"
  $ValidatorPath = "validators/validate_phase160e_full_long_lived_runner_candidate_workspace_promotion_task_lifecycle_v1.ps1"
  $ProtectedPaths = @("TASK_QUEUE.json", "GENESIS_STATE.json", "CAPABILITY_ROADMAP.json", "packs/registry.json", "orchestrator/run.ps1")

  foreach ($scriptPath in @($DaemonPath, $DutyStepPath, $ConsolePath, $ObserverPath, $IdentityPath, $CandidateStepPath, $PromotionFinalizePath, $ValidatorPath)) {
    Assert-Phase160EParserClean -Path (Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $scriptPath)
  }

  $Branch = (git branch --show-current).Trim()
  Assert-Phase160EEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160ERemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160EEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"
  $ExpectedHeadSource = "CURRENT_SYNCED_REPO_HEAD"
  $ProtectedHashesBefore = Get-Phase160EFileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths

  Remove-Phase160EOutput -RepoRoot $RepoRoot -Path $SessionRoot
  Remove-Phase160EOutput -RepoRoot $RepoRoot -Path $ConsoleRuntimeRoot

  $SessionRootFull = Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $SessionRoot
  $TeacherInboxFull = Resolve-Phase160EPath -RepoRoot $RepoRoot -Path "$SessionRoot/teacher_inbox"
  New-Item -ItemType Directory -Force -Path $TeacherInboxFull | Out-Null

  $safeRules = [ordered]@{
    accepted_state_mutation_allowed = $false
    accepted_memory_mutation_allowed = $false
    accepted_self_model_mutation_allowed = $false
    repo_commit_allowed = $false
    runtime_session_only = $true
  }
  $HighOwnerTask = [ordered]@{
    event_type = "owner_live_task_injection"
    task_id = "PHASE160E_HIGH_OWNER_EXPERIENCE_ABSORPTION_GATE_001"
    source = "owner"
    priority = "high"
    owner_goal = "Create a session-local candidate module for Experience Absorption Gate promotion review."
    desired_next_gap = "EXPERIENCE_ABSORPTION_GATE"
    safety_rules = $safeRules
    success_signals = @("candidate_bundle_created", "owner_review_summary_created")
    code_execution_requested = $false
    accepted_state_mutation_allowed = $false
    accepted_memory_mutation_allowed = $false
    accepted_self_model_mutation_allowed = $false
    repo_commit_allowed = $false
    runtime_session_only = $true
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  $NormalPlanTask = [ordered]@{
    event_type = "owner_live_task_injection"
    task_id = "PHASE160E_NORMAL_OWNER_TEN_STEP_PLAN_001"
    source = "owner"
    priority = "normal"
    owner_goal = "Advance a ten step candidate-workspace plan after the active task reaches the owner promotion gate."
    desired_next_gap = "CANDIDATE_WORKSPACE_PLAN_ADVANCEMENT_GATE"
    plan_steps = @(
      "Inspect run manifest and immutable run head.",
      "Inspect runtime guard.",
      "Inspect active task state.",
      "Create a plan item candidate bundle.",
      "Write a candidate validation plan.",
      "Write a candidate risk review.",
      "Update promotion manifest.",
      "Update owner review summary.",
      "Write task completion receipt.",
      "Prepare restart handoff."
    )
    can_parallelize = $false
    safety_rules = $safeRules
    success_signals = @("plan_item_advanced", "promotion_bundle_updated")
    code_execution_requested = $false
    accepted_state_mutation_allowed = $false
    accepted_memory_mutation_allowed = $false
    accepted_self_model_mutation_allowed = $false
    repo_commit_allowed = $false
    runtime_session_only = $true
    created_at = (Get-Date).ToUniversalTime().AddSeconds(1).ToString("o")
  }
  $UnsafeTask = [ordered]@{
    event_type = "owner_live_task_injection"
    task_id = "PHASE160E_UNSAFE_ACCEPTED_STATE_MUTATION_001"
    source = "owner"
    priority = "high"
    owner_goal = "Mutate accepted state and commit during the live run."
    desired_next_gap = "UNSAFE_ACCEPTED_STATE_MUTATION"
    safety_rules = [ordered]@{
      accepted_state_mutation_allowed = $true
      accepted_memory_mutation_allowed = $true
      accepted_self_model_mutation_allowed = $true
      repo_commit_allowed = $true
      runtime_session_only = $false
    }
    success_signals = @("should_quarantine")
    code_execution_requested = $false
    accepted_state_mutation_allowed = $true
    accepted_memory_mutation_allowed = $true
    accepted_self_model_mutation_allowed = $true
    repo_commit_allowed = $true
    runtime_session_only = $false
    created_at = (Get-Date).ToUniversalTime().AddSeconds(2).ToString("o")
  }

  Write-Phase160EJsonFile -Path (Join-Path $TeacherInboxFull "001_high_owner_experience_absorption_gate.json") -Object $HighOwnerTask
  Write-Phase160EJsonFile -Path (Join-Path $TeacherInboxFull "002_normal_owner_ten_step_plan.json") -Object $NormalPlanTask
  Write-Phase160EJsonFile -Path (Join-Path $TeacherInboxFull "003_unsafe_state_mutation.json") -Object $UnsafeTask
  Write-Phase160EJsonFile -Path (Join-Path $TeacherInboxFull "004_duplicate_high_owner_experience_absorption_gate.json") -Object $HighOwnerTask

  $TrackedStatusBeforeDaemon = Get-Phase160ETrackedStatus
  $DaemonFullPath = Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $DaemonPath
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
      -MacroCycleId $CycleId `
      -EnableCandidateWorkspacePromotion 2>&1
    $exit = $LASTEXITCODE
    if ($exit -ne 0) {
      throw "PHASE160E_DAEMON_JOB_FAILED exit=$exit output=$($output -join ' | ')"
    }
    $output
  } -ArgumentList $RepoRoot, $DaemonFullPath, $SessionRoot, $CycleId

  $null = Wait-Phase160ECandidateBundle -RepoRoot $RepoRoot -SessionRoot $SessionRoot -MinimumCandidates 2 -MinimumDuties 1 -TimeoutSeconds 100
  $StopFlagPath = Resolve-Phase160EPath -RepoRoot $RepoRoot -Path "$SessionRoot/stop.flag"
  [System.IO.File]::WriteAllText($StopFlagPath, "PHASE160E_STOP_REQUEST`n", [System.Text.UTF8Encoding]::new($false))
  $completedJob = Wait-Job -Job $DaemonJob -Timeout 35
  if ($null -eq $completedJob) {
    Stop-Job -Job $DaemonJob
    Receive-Job -Job $DaemonJob -Keep | Out-String | Write-Host
    throw "PHASE160E_VALIDATE_DAEMON_STOP_FLAG_TIMEOUT"
  }
  $DaemonOutput = @(Receive-Job -Job $DaemonJob)
  if ($DaemonJob.State -ne "Completed") {
    throw "PHASE160E_VALIDATE_DAEMON_JOB_STATE=$($DaemonJob.State) output=$($DaemonOutput -join ' | ')"
  }
  Remove-Job -Job $DaemonJob
  $DaemonResult = ($DaemonOutput -join "`n") | ConvertFrom-Json

  $ObserverOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $ObserverPath) -SessionRoot $SessionRoot -DurationSeconds 3 -PollIntervalSeconds 1 -ExpectSelfGrowthDuty 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160E_VALIDATE_OBSERVER_FAILED output=$($ObserverOutput -join ' | ')"
  }
  $ObserverResult = ($ObserverOutput -join "`n") | ConvertFrom-Json

  $ConsoleOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $ConsolePath) -SessionRoot $SessionRoot -DurationSeconds 3 -PollIntervalSeconds 1 -ConsoleRunId $ConsoleRunId -ConsoleRuntimeRoot $ConsoleRuntimeRoot 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160E_VALIDATE_CONSOLE_FAILED output=$($ConsoleOutput -join ' | ')"
  }
  $ConsolePollLines = @($ConsoleOutput | Where-Object { $_ -match "^LIVE_CONSOLE POLL=" })
  Assert-Phase160EAtLeast -Actual $ConsolePollLines.Count -Minimum 2 -Name "console_poll_lines"
  foreach ($requiredConsoleField in @(
    "RUN_HEAD=",
    "CURRENT_HEAD=",
    "HEAD_MATCH=",
    "LIVE_REPO_GUARD=",
    "CANDIDATE_COUNT=",
    "READY_CANDIDATE_COUNT=",
    "QUARANTINED_CANDIDATE_COUNT=",
    "PROMOTION_BUNDLE_STATUS=",
    "ACTIVE_TASK_STATUS=",
    "ACTIVE_TASK=",
    "ACTIVE_PLAN_ITEM=",
    "BACKLOG_COUNT=",
    "PLAN_PENDING_COUNT=",
    "PLAN_ACTIVE_COUNT=",
    "PLAN_WAITING_PROMOTION_COUNT=",
    "LAST_CANDIDATE_ID=",
    "LAST_PROMOTION_EVENT=",
    "RESTART_REQUIRED_AFTER_PROMOTION="
  )) {
    if (-not (@($ConsolePollLines | Where-Object { $_ -match [regex]::Escape($requiredConsoleField) }).Count -eq $ConsolePollLines.Count)) {
      throw "PHASE160E_VALIDATE_CONSOLE_FIELD_MISSING=$requiredConsoleField"
    }
  }

  $TrackedStatusAfterDaemon = Get-Phase160ETrackedStatus
  $LiveRepoCodeMutation = (($TrackedStatusBeforeDaemon -join "`n") -ne ($TrackedStatusAfterDaemon -join "`n"))
  Assert-Phase160EFalse -Actual $LiveRepoCodeMutation -Name "live_repo_code_mutation"

  $RunManifest = Read-Phase160EJson -RepoRoot $RepoRoot -Path "$SessionRoot/run_manifest.json"
  $RuntimeIdentity = Read-Phase160EJson -RepoRoot $RepoRoot -Path "$SessionRoot/runtime_identity.json"
  $RuntimeGuard = Read-Phase160EJson -RepoRoot $RepoRoot -Path "$SessionRoot/runtime_guard.json"
  $PromotionManifest = Read-Phase160EJson -RepoRoot $RepoRoot -Path "$SessionRoot/promotion_bundle/promotion_manifest.json"
  $PromotionProofIndex = Read-Phase160EJson -RepoRoot $RepoRoot -Path "$SessionRoot/promotion_bundle/promotion_proof_index.json"
  $OwnerReviewSummary = Read-Phase160EText -RepoRoot $RepoRoot -Path "$SessionRoot/promotion_bundle/owner_review_summary.md"
  $FinalHandoffSummary = Read-Phase160EText -RepoRoot $RepoRoot -Path "$SessionRoot/final_handoff_summary.md"
  $ActiveTaskState = Read-Phase160EJson -RepoRoot $RepoRoot -Path "$SessionRoot/task_lifecycle/active_task_state.json"
  $FinalState = Read-Phase160EJson -RepoRoot $RepoRoot -Path "$SessionRoot/final_state.json"
  $CurrentState = Read-Phase160EJson -RepoRoot $RepoRoot -Path "$SessionRoot/current_state.json"
  $Heartbeat = Read-Phase160EJson -RepoRoot $RepoRoot -Path "$SessionRoot/heartbeat.json"
  $Events = Read-Phase160EJsonLines -RepoRoot $RepoRoot -Path "$SessionRoot/event_log.jsonl"
  $LedgerEntries = Read-Phase160EJsonLines -RepoRoot $RepoRoot -Path "$SessionRoot/candidate_workspace/change_ledger.jsonl"
  $BacklogAdvancementEntries = Read-Phase160EJsonLines -RepoRoot $RepoRoot -Path "$SessionRoot/task_lifecycle/backlog_advancement_log.jsonl"
  $PlanAdvancementEntries = Read-Phase160EJsonLines -RepoRoot $RepoRoot -Path "$SessionRoot/task_lifecycle/plan_item_advancement_log.jsonl"
  $ConsoleResult = Read-Phase160EJson -RepoRoot $RepoRoot -Path "$ConsoleRuntimeRoot/console_run_result.json"
  $ConsoleSample = Read-Phase160EText -RepoRoot $RepoRoot -Path "$ConsoleRuntimeRoot/console_output_sample.txt"
  $ObserverSummary = Read-Phase160EJson -RepoRoot $RepoRoot -Path "$SessionRoot/observer_summary.json"

  $TeacherInboxCount = Get-Phase160EJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/teacher_inbox"
  $TeacherDigestCount = Get-Phase160EJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/teacher_digest"
  $TeacherConsumedCount = Get-Phase160EJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/teacher_consumed" -Pattern "receipt_*.json"
  $TeacherQuarantineCount = Get-Phase160EJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/teacher_quarantine" -Pattern "quarantine_*.json"
  $TaskCompletionReceiptCount = Get-Phase160EJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/task_lifecycle/task_completion_receipts" -Pattern "receipt_*.json"
  $CandidateManifestCount = Get-Phase160ERecursiveJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/candidate_workspace/candidate_bundles" -Pattern "candidate_manifest.json"
  $CandidateStatusCount = Get-Phase160ERecursiveJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/candidate_workspace/candidate_bundles" -Pattern "candidate_status.json"
  $PlanWaitingCount = Get-Phase160ERecursiveJsonFileCount -RepoRoot $RepoRoot -Path "$SessionRoot/plan_items" -Pattern "*_plan_item_*.json"

  Assert-Phase160EEquals -Actual $RunManifest.run_head -Expected $Head -Name "run_manifest_run_head"
  Assert-Phase160EEquals -Actual $RuntimeIdentity.run_head -Expected $Head -Name "runtime_identity_run_head"
  Assert-Phase160ETrue -Actual $RuntimeIdentity.head_match -Name "runtime_identity_head_match"
  Assert-Phase160EEquals -Actual $RuntimeGuard.status -Expected "PASS" -Name "runtime_guard_status"
  Assert-Phase160ETrue -Actual $RuntimeGuard.head_match -Name "runtime_guard_head_match"
  Assert-Phase160ETrue -Actual $RuntimeGuard.candidate_production_enabled -Name "runtime_guard_candidate_production_enabled"
  Assert-Phase160ETrue -Actual (Test-Path -LiteralPath (Resolve-Phase160EPath -RepoRoot $RepoRoot -Path "$SessionRoot/candidate_workspace")) -Name "candidate_workspace_exists"
  Assert-Phase160EAtLeast -Actual $CandidateManifestCount -Minimum 2 -Name "candidate_manifest_count"
  Assert-Phase160EAtLeast -Actual $CandidateStatusCount -Minimum 2 -Name "candidate_status_count"
  Assert-Phase160EAtLeast -Actual $PromotionManifest.candidate_count -Minimum 2 -Name "promotion_candidate_count"
  Assert-Phase160EAtLeast -Actual $PromotionManifest.ready_candidate_count -Minimum 2 -Name "promotion_ready_candidate_count"
  Assert-Phase160EEquals -Actual $PromotionManifest.promotion_status -Expected "WAITING_OWNER_REVIEW" -Name "promotion_status"
  Assert-Phase160ETrue -Actual $PromotionManifest.owner_review_required -Name "promotion_owner_review_required"
  Assert-Phase160ETrue -Actual $PromotionManifest.restart_required_after_promotion -Name "promotion_restart_required"
  Assert-Phase160ETrue -Actual ($OwnerReviewSummary -match "Candidate output is not accepted code") -Name "owner_review_mentions_candidate_not_accepted"
  Assert-Phase160ETrue -Actual ($FinalHandoffSummary -match "Restart a fresh live runner") -Name "final_handoff_mentions_restart"
  Assert-Phase160ETrue -Actual ($PromotionProofIndex.proof_entries.Count -ge 4) -Name "promotion_proof_index_entries"
  Assert-Phase160EEquals -Actual $ActiveTaskState.status -Expected "WAITING_OWNER_PROMOTION" -Name "active_task_state_waiting_owner_promotion"
  Assert-Phase160EAtLeast -Actual $TaskCompletionReceiptCount -Minimum 1 -Name "task_completion_receipts"
  Assert-Phase160EAtLeast -Actual $BacklogAdvancementEntries.Count -Minimum 1 -Name "backlog_advancement_entries"
  Assert-Phase160EAtLeast -Actual $PlanAdvancementEntries.Count -Minimum 1 -Name "plan_advancement_entries"
  Assert-Phase160EAtLeast -Actual $PlanWaitingCount -Minimum 10 -Name "plan_item_count"
  Assert-Phase160EEquals -Actual $TeacherInboxCount -Expected 0 -Name "teacher_inbox_left_unprocessed"
  Assert-Phase160EAtLeast -Actual $TeacherDigestCount -Minimum 3 -Name "teacher_digest_count"
  Assert-Phase160EAtLeast -Actual $TeacherConsumedCount -Minimum 3 -Name "teacher_consumed_count"
  Assert-Phase160EAtLeast -Actual $TeacherQuarantineCount -Minimum 1 -Name "teacher_quarantine_count"
  Assert-Phase160ETrue -Actual (Test-Phase160EEventExists -Events $Events -EventType "live_task_deduplicated") -Name "event_live_task_deduplicated"
  Assert-Phase160ETrue -Actual (Test-Phase160EEventExists -Events $Events -EventType "candidate_workspace_step_completed") -Name "event_candidate_workspace_step_completed"
  Assert-Phase160ETrue -Actual (@($LedgerEntries | Where-Object { [string]$_.event_type -eq "candidate_created" }).Count -ge 2) -Name "ledger_candidate_created"
  Assert-Phase160ETrue -Actual (@($LedgerEntries | Where-Object { [string]$_.event_type -eq "promotion_bundle_updated" }).Count -ge 1) -Name "ledger_promotion_bundle_updated"
  Assert-Phase160ETrue -Actual $ConsoleResult.live_console_shows_phase160e_fields -Name "console_phase160e_fields"
  Assert-Phase160ETrue -Actual ($ConsoleSample -match "RUN_HEAD=") -Name "console_sample_run_head"
  Assert-Phase160ETrue -Actual $ObserverSummary.run_manifest_exists -Name "observer_run_manifest_exists"
  Assert-Phase160ETrue -Actual $ObserverSummary.run_head_matches_current -Name "observer_run_head_matches_current"
  Assert-Phase160ETrue -Actual $ObserverSummary.candidate_workspace_exists -Name "observer_candidate_workspace_exists"
  Assert-Phase160ETrue -Actual $ObserverSummary.promotion_bundle_exists -Name "observer_promotion_bundle_exists"
  Assert-Phase160ETrue -Actual $ObserverSummary.active_task_lifecycle_moved -Name "observer_active_task_lifecycle_moved"
  Assert-Phase160ETrue -Actual $ObserverSummary.backlog_advancement_detected -Name "observer_backlog_advancement"
  Assert-Phase160ETrue -Actual $ObserverSummary.plan_item_advancement_detected -Name "observer_plan_item_advancement"
  Assert-Phase160EFalse -Actual $ObserverSummary.runtime_guard_violation_detected -Name "observer_runtime_guard_violation"
  Assert-Phase160EFalse -Actual $FinalState.accepted_state_mutated -Name "final_state_accepted_state_mutated"
  Assert-Phase160EFalse -Actual $FinalState.accepted_memory_mutated -Name "final_state_accepted_memory_mutated"
  Assert-Phase160EFalse -Actual $FinalState.accepted_self_model_mutated -Name "final_state_accepted_self_model_mutated"
  Assert-Phase160EEquals -Actual $FinalState.run_head -Expected $Head -Name "final_state_run_head"
  Assert-Phase160EAtLeast -Actual $FinalState.candidate_count -Minimum 2 -Name "final_state_candidate_count"
  Assert-Phase160EAtLeast -Actual $CurrentState.candidate_count -Minimum 2 -Name "current_state_candidate_count"
  Assert-Phase160EAtLeast -Actual $Heartbeat.candidate_count -Minimum 2 -Name "heartbeat_candidate_count"

  $candidateManifests = @(Get-ChildItem -LiteralPath (Resolve-Phase160EPath -RepoRoot $RepoRoot -Path "$SessionRoot/candidate_workspace/candidate_bundles") -File -Filter "candidate_manifest.json" -Recurse | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json })
  $planCandidateCount = 0
  foreach ($candidateManifest in $candidateManifests) {
    Assert-Phase160EEquals -Actual $candidateManifest.created_from_run_head -Expected $Head -Name "candidate_created_from_run_head:$($candidateManifest.candidate_id)"
    Assert-Phase160ETrue -Actual $candidateManifest.owner_approval_required -Name "candidate_owner_approval:$($candidateManifest.candidate_id)"
    Assert-Phase160EFalse -Actual $candidateManifest.repo_mutation_performed -Name "candidate_repo_mutation:$($candidateManifest.candidate_id)"
    Assert-Phase160EFalse -Actual $candidateManifest.commit_performed -Name "candidate_commit:$($candidateManifest.candidate_id)"
    Assert-Phase160EFalse -Actual $candidateManifest.push_performed -Name "candidate_push:$($candidateManifest.candidate_id)"
    Assert-Phase160EEquals -Actual $candidateManifest.decision -Expected "CANDIDATE_READY" -Name "candidate_decision:$($candidateManifest.candidate_id)"
    if ([string]$candidateManifest.source_plan_item_id -ne "NONE") {
      $planCandidateCount += 1
    }
  }
  Assert-Phase160EAtLeast -Actual $planCandidateCount -Minimum 1 -Name "plan_candidate_count"

  $BranchAfter = (git branch --show-current).Trim()
  $HeadAfter = (git rev-parse --short HEAD).Trim()
  $RemoteHeadAfter = Get-Phase160ERemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160EEquals -Actual $BranchAfter -Expected $Branch -Name "branch_after"
  Assert-Phase160EEquals -Actual $HeadAfter -Expected $Head -Name "head_after"
  Assert-Phase160EEquals -Actual $RemoteHeadAfter -Expected $RemoteHead -Name "remote_head_after"
  $ProtectedHashesAfter = Get-Phase160EFileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths
  foreach ($path in $ProtectedPaths) {
    Assert-Phase160EEquals -Actual $ProtectedHashesAfter[$path] -Expected $ProtectedHashesBefore[$path] -Name "protected_hash:$path"
  }
  $ProtectedStateMutated = $false
  Assert-Phase160ERuntimeOutputsNotStaged
  $RuntimeOutputsStaged = $false

  $Proof = [ordered]@{
    status = "PASS"
    acceptance_language = "PHASE160E_FULL_LONG_LIVED_RUNNER_CANDIDATE_WORKSPACE_PROMOTION_TASK_LIFECYCLE_VALIDATE_RESULT=PASS"
    repair_id = $RepairId
    run_id = $RunId
    resolved_repo_root = $RepoRoot
    branch = $Branch
    local_head = $Head
    remote_head = $RemoteHead
    expected_head_source = $ExpectedHeadSource
    parser_checks_pass = $true
    run_manifest_written = $true
    run_head_locked = $true
    live_repo_guard_pass = $true
    candidate_workspace_created = $true
    candidate_bundle_created = $CandidateManifestCount -gt 0
    promotion_bundle_created = $true
    owner_review_summary_created = $true
    active_task_moved_to_waiting_promotion = $true
    backlog_advanced = $BacklogAdvancementEntries.Count -gt 0
    plan_item_advanced = $PlanAdvancementEntries.Count -gt 0
    no_live_repo_code_mutation = -not $LiveRepoCodeMutation
    no_commit_performed = $HeadAfter -eq $Head
    no_push_performed = $RemoteHeadAfter -eq $RemoteHead
    no_branch_switch = $BranchAfter -eq $Branch
    protected_state_mutated = $ProtectedStateMutated
    runtime_outputs_staged = $RuntimeOutputsStaged
    candidate_count = $CandidateManifestCount
    ready_candidate_count = [int]$PromotionManifest.ready_candidate_count
    teacher_digest_count = $TeacherDigestCount
    teacher_consumed_count = $TeacherConsumedCount
    teacher_quarantine_count = $TeacherQuarantineCount
    task_completion_receipt_count = $TaskCompletionReceiptCount
    backlog_advancement_count = $BacklogAdvancementEntries.Count
    plan_advancement_count = $PlanAdvancementEntries.Count
    report_path = $ReportPath
    proof_path = $ProofPath
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase160EJsonFile -Path (Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $ProofPath) -Object $Proof

  $ReportLines = @(
    "# PHASE160E Full Long-Lived Runner Candidate Workspace Promotion Task Lifecycle Report",
    "",
    "status: PASS",
    "repair_id: $RepairId",
    "line: AGENT_BUILDER_SELF_DEVELOPMENT",
    "mode: VERIFY",
    "run_id: $RunId",
    "",
    "## Result",
    "PHASE160E_FULL_LONG_LIVED_RUNNER_CANDIDATE_WORKSPACE_PROMOTION_TASK_LIFECYCLE_VALIDATE_RESULT=PASS",
    "RUN_MANIFEST_WRITTEN=True",
    "RUN_HEAD_LOCKED=True",
    "LIVE_REPO_GUARD_PASS=True",
    "CANDIDATE_WORKSPACE_CREATED=True",
    "CANDIDATE_BUNDLE_CREATED=True",
    "PROMOTION_BUNDLE_CREATED=True",
    "OWNER_REVIEW_SUMMARY_CREATED=True",
    "ACTIVE_TASK_MOVED_TO_WAITING_PROMOTION=True",
    "BACKLOG_ADVANCED=True",
    "PLAN_ITEM_ADVANCED=True",
    "NO_LIVE_REPO_CODE_MUTATION=True",
    "NO_COMMIT_PERFORMED=True",
    "NO_PUSH_PERFORMED=True",
    "NO_BRANCH_SWITCH=True",
    "PROTECTED_STATE_MUTATED=False",
    "RUNTIME_OUTPUTS_STAGED=False",
    "",
    "## Proof Summary",
    "- Run head locked: $($RunManifest.run_head)",
    "- Runtime guard: $($RuntimeGuard.status)",
    "- Candidate manifests: $CandidateManifestCount",
    "- Promotion status: $($PromotionManifest.promotion_status)",
    "- Active task state: $($ActiveTaskState.status)",
    "- Backlog advancement entries: $($BacklogAdvancementEntries.Count)",
    "- Plan advancement entries: $($PlanAdvancementEntries.Count)",
    "- Runtime outputs staged: False",
    "",
    "## Files Changed",
    "- $IdentityPath",
    "- $CandidateStepPath",
    "- $PromotionFinalizePath",
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
    ".\validators\validate_phase160e_full_long_lived_runner_candidate_workspace_promotion_task_lifecycle_v1.ps1 -RepoRoot .",
    '```',
    "",
    "## Boundaries",
    "- No TASK_QUEUE, GENESIS_STATE, CAPABILITY_ROADMAP, packs/registry, or orchestrator edits.",
    "- No external-agent production.",
    "- No dependency install, external fetch, commit, push, or branch switch.",
    "- Runtime session outputs are proof artifacts and must not be staged."
  )
  Write-Phase160ETextFile -Path (Resolve-Phase160EPath -RepoRoot $RepoRoot -Path $ReportPath) -Text ($ReportLines -join "`n")

  Write-Host "PHASE160E_FULL_LONG_LIVED_RUNNER_CANDIDATE_WORKSPACE_PROMOTION_TASK_LIFECYCLE_VALIDATE_RESULT=PASS"
  Write-Host "RUN_MANIFEST_WRITTEN=True"
  Write-Host "RUN_HEAD_LOCKED=True"
  Write-Host "LIVE_REPO_GUARD_PASS=True"
  Write-Host "CANDIDATE_WORKSPACE_CREATED=True"
  Write-Host "CANDIDATE_BUNDLE_CREATED=True"
  Write-Host "PROMOTION_BUNDLE_CREATED=True"
  Write-Host "OWNER_REVIEW_SUMMARY_CREATED=True"
  Write-Host "ACTIVE_TASK_MOVED_TO_WAITING_PROMOTION=True"
  Write-Host "BACKLOG_ADVANCED=True"
  Write-Host "PLAN_ITEM_ADVANCED=True"
  Write-Host "NO_LIVE_REPO_CODE_MUTATION=True"
  Write-Host "NO_COMMIT_PERFORMED=True"
  Write-Host "NO_PUSH_PERFORMED=True"
  Write-Host "NO_BRANCH_SWITCH=True"
  Write-Host "PROTECTED_STATE_MUTATED=False"
  Write-Host "RUNTIME_OUTPUTS_STAGED=False"
  Write-Host "REPORT_PATH=$ReportPath"
  Write-Host "PROOF_PATH=$ProofPath"
} catch {
  Write-Host "PHASE160E_FULL_LONG_LIVED_RUNNER_CANDIDATE_WORKSPACE_PROMOTION_TASK_LIFECYCLE_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE160E_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
