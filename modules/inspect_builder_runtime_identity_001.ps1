param(
  [string]$SessionRoot = "",
  [string]$RunId = "",
  [ValidateSet("Initialize", "GuardCheck")]
  [string]$Mode = "GuardCheck",
  [string]$GuardLabel = "runtime_guard"
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160EIdentityFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160EIdentityRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160E_IDENTITY_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160EIdentityFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160EIdentityPath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function ConvertTo-Phase160EIdentityRelativePath {
  param([string]$RepoRoot, [string]$FullPath)
  $root = Normalize-Phase160EIdentityFullPath -Path $RepoRoot
  $full = Normalize-Phase160EIdentityFullPath -Path $FullPath
  if ($full -eq $root) {
    return "."
  }
  if (-not $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160E_IDENTITY_PATH_OUTSIDE_REPO=$FullPath"
  }
  return ($full.Substring($root.Length + 1) -replace "\\", "/")
}

function Write-Phase160EIdentityJsonFile {
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

function Add-Phase160EIdentityJsonLine {
  param([string]$Path, [object]$Object)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $line = $Object | ConvertTo-Json -Depth 100 -Compress
  [System.IO.File]::AppendAllText($Path, "$line`n", [System.Text.UTF8Encoding]::new($false))
}

function Read-Phase160EIdentityJsonSafe {
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

function Get-Phase160EIdentityRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160E_IDENTITY_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Get-Phase160EIdentityTrackedStatus {
  $lines = @(git status --short --untracked-files=no | ForEach-Object { [string]$_ } | Sort-Object)
  return $lines
}

function Get-Phase160EIdentityProtectedStatus {
  $lines = @(git status --short --untracked-files=no -- `
    TASK_QUEUE.json `
    GENESIS_STATE.json `
    CAPABILITY_ROADMAP.json `
    packs/registry.json `
    orchestrator/run.ps1 2>$null | ForEach-Object { [string]$_ } | Sort-Object)
  return $lines
}

function Get-Phase160EIdentityScriptHashes {
  param([string]$RepoRoot, [string[]]$Paths)
  $hashes = [ordered]@{}
  foreach ($path in $Paths) {
    $full = Resolve-Phase160EIdentityPath -RepoRoot $RepoRoot -Path $path
    if (Test-Path -LiteralPath $full) {
      $hashes[$path] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = "MISSING"
    }
  }
  return $hashes
}

function Assert-Phase160EIdentityRunIdSafe {
  param([string]$RunId)
  if ([string]::IsNullOrWhiteSpace($RunId)) {
    return
  }
  if ($RunId.IndexOfAny([char[]]@("/", "\")) -ge 0) {
    throw "PHASE160E_IDENTITY_RUN_ID_MUST_BE_LEAF=$RunId"
  }
}

$RepoRoot = Resolve-Phase160EIdentityRepoRoot
$ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
$Pushed = $false

try {
  Push-Location $RepoRoot
  $Pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160EIdentityPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  Assert-Phase160EIdentityRunIdSafe -RunId $RunId
  if (-not [string]::IsNullOrWhiteSpace($RunId) -and [string]::IsNullOrWhiteSpace($SessionRoot)) {
    $SessionRoot = "runtime_sessions/live_growth/$RunId"
  }
  if ([string]::IsNullOrWhiteSpace($SessionRoot)) {
    throw "PHASE160E_IDENTITY_SESSION_ROOT_REQUIRED"
  }

  $SessionRootFull = Resolve-Phase160EIdentityPath -RepoRoot $RepoRoot -Path $SessionRoot
  $SessionRootRelative = ConvertTo-Phase160EIdentityRelativePath -RepoRoot $RepoRoot -FullPath $SessionRootFull
  $ManifestPath = Join-Path $SessionRootFull "run_manifest.json"
  $RuntimeIdentityPath = Join-Path $SessionRootFull "runtime_identity.json"
  $RuntimeGuardPath = Join-Path $SessionRootFull "runtime_guard.json"
  $CandidateWorkspace = Join-Path $SessionRootFull "candidate_workspace"
  $ChangeLedgerPath = Join-Path $CandidateWorkspace "change_ledger.jsonl"
  foreach ($directory in @(
    $SessionRootFull,
    $CandidateWorkspace,
    (Join-Path $CandidateWorkspace "candidate_bundles"),
    (Join-Path $CandidateWorkspace "candidate_queue"),
    (Join-Path $CandidateWorkspace "candidate_quarantine"),
    (Join-Path $SessionRootFull "promotion_bundle"),
    (Join-Path $SessionRootFull "task_lifecycle"),
    (Join-Path $SessionRootFull "task_lifecycle/task_completion_receipts")
  )) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $Branch = (git branch --show-current).Trim()
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160EIdentityRemoteHead -ExpectedBranch $ExpectedBranch
  $ExpectedHeadSource = "CURRENT_SYNCED_REPO_HEAD"
  $KeyScripts = @(
    "modules/start_builder_live_growth_daemon_001.ps1",
    "modules/invoke_builder_live_self_growth_duty_step_001.ps1",
    "modules/watch_builder_live_console_001.ps1",
    "modules/watch_builder_live_growth_session_observer_001.ps1",
    "modules/inspect_builder_runtime_identity_001.ps1",
    "modules/invoke_builder_candidate_workspace_step_001.ps1",
    "modules/finalize_builder_promotion_bundle_001.ps1",
    "modules/select_builder_self_initiated_useful_goal_001.ps1",
    "modules/invoke_builder_internal_active_task_creation_001.ps1",
    "modules/score_builder_self_growth_goal_001.ps1",
    "modules/inspect_builder_self_growth_evidence_001.ps1"
  )

  if ($Mode -eq "Initialize") {
    $TrackedStatusBaseline = Get-Phase160EIdentityTrackedStatus
    $ProtectedStatus = Get-Phase160EIdentityProtectedStatus
    $ScriptHashes = Get-Phase160EIdentityScriptHashes -RepoRoot $RepoRoot -Paths $KeyScripts
    $StartedAt = (Get-Date).ToUniversalTime().ToString("o")
    $Manifest = [ordered]@{
      run_id = if ([string]::IsNullOrWhiteSpace($RunId)) { "NONE" } else { $RunId }
      repo_root = $RepoRoot
      session_root = $SessionRootRelative
      branch = $Branch
      run_head = $Head
      remote_head = $RemoteHead
      expected_head_source = $ExpectedHeadSource
      started_at = $StartedAt
      live_repo_mutation_allowed = $false
      commit_allowed = $false
      push_allowed = $false
      branch_switch_allowed = $false
      protected_state_mutation_allowed = $false
      runtime_only_write_policy = $true
      key_script_paths = $KeyScripts
      key_script_hashes = $ScriptHashes
      tracked_status_baseline = $TrackedStatusBaseline
      protected_status_at_start = $ProtectedStatus
      run_manifest_status = "PASS"
    }
    Write-Phase160EIdentityJsonFile -Path $ManifestPath -Object $Manifest
    Write-Phase160EIdentityJsonFile -Path $RuntimeIdentityPath -Object ([ordered]@{
      status = "PASS"
      run_id = $Manifest.run_id
      branch = $Branch
      run_head = $Head
      current_head = $Head
      remote_head = $RemoteHead
      head_match = $true
      tracked_status_baseline = $TrackedStatusBaseline
      runtime_identity_written_at = $StartedAt
      live_repo_mutation_allowed = $false
    })
    Add-Phase160EIdentityJsonLine -Path $ChangeLedgerPath -Object ([ordered]@{
      event_type = "candidate_workspace_initialized"
      source = "runtime_identity"
      run_id = $Manifest.run_id
      run_head = $Head
      occurred_at = $StartedAt
    })
  }

  $ManifestForGuard = Read-Phase160EIdentityJsonSafe -Path $ManifestPath
  if ($null -eq $ManifestForGuard) {
    throw "PHASE160E_IDENTITY_RUN_MANIFEST_MISSING=$SessionRootRelative/run_manifest.json"
  }

  $CurrentBranch = (git branch --show-current).Trim()
  $CurrentHead = (git rev-parse --short HEAD).Trim()
  $CurrentTrackedStatus = Get-Phase160EIdentityTrackedStatus
  $BaselineTrackedStatus = @($ManifestForGuard.tracked_status_baseline | ForEach-Object { [string]$_ } | Sort-Object)
  $ProtectedStatus = Get-Phase160EIdentityProtectedStatus
  $RuntimeStaged = @(git diff --cached --name-only -- runtime_sessions)
  $BranchMatches = $CurrentBranch -eq [string]$ManifestForGuard.branch
  $HeadMatches = $CurrentHead -eq [string]$ManifestForGuard.run_head
  $ProtectedClean = $ProtectedStatus.Count -eq 0
  $TrackedStatusMatches = (($CurrentTrackedStatus -join "`n") -eq ($BaselineTrackedStatus -join "`n"))
  $RuntimeOutputsStaged = $RuntimeStaged.Count -gt 0
  $GuardPassed = ($BranchMatches -and $HeadMatches -and $ProtectedClean -and $TrackedStatusMatches -and -not $RuntimeOutputsStaged)
  $Guard = [ordered]@{
    status = if ($GuardPassed) { "PASS" } else { "BLOCKED" }
    guard_label = $GuardLabel
    run_id = [string]$ManifestForGuard.run_id
    branch = [string]$ManifestForGuard.branch
    current_branch = $CurrentBranch
    run_head = [string]$ManifestForGuard.run_head
    current_head = $CurrentHead
    head_match = $HeadMatches
    branch_match = $BranchMatches
    protected_files_clean = $ProtectedClean
    tracked_status_matches_run_baseline = $TrackedStatusMatches
    runtime_outputs_staged = $RuntimeOutputsStaged
    candidate_production_enabled = $GuardPassed
    commit_performed = $false
    push_performed = $false
    branch_switch_performed = $false
    protected_state_mutated = -not $ProtectedClean
    checked_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase160EIdentityJsonFile -Path $RuntimeGuardPath -Object $Guard
  Write-Phase160EIdentityJsonFile -Path $RuntimeIdentityPath -Object ([ordered]@{
    status = if ($GuardPassed) { "PASS" } else { "BLOCKED" }
    run_id = [string]$ManifestForGuard.run_id
    branch = [string]$ManifestForGuard.branch
    run_head = [string]$ManifestForGuard.run_head
    current_head = $CurrentHead
    remote_head = [string]$ManifestForGuard.remote_head
    head_match = $HeadMatches
    live_repo_guard = $Guard.status
    candidate_production_enabled = $GuardPassed
    updated_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Add-Phase160EIdentityJsonLine -Path $ChangeLedgerPath -Object ([ordered]@{
    event_type = if ($GuardPassed) { "live_repo_guard_passed" } else { "live_repo_guard_failed" }
    source = "runtime_identity"
    guard_label = $GuardLabel
    run_id = [string]$ManifestForGuard.run_id
    run_head = [string]$ManifestForGuard.run_head
    current_head = $CurrentHead
    status = $Guard.status
    occurred_at = (Get-Date).ToUniversalTime().ToString("o")
  })

  if (-not $GuardPassed) {
    $BlockerQueuePath = Join-Path $SessionRootFull "blocker_queue"
    New-Item -ItemType Directory -Force -Path $BlockerQueuePath | Out-Null
    Write-Phase160EIdentityJsonFile -Path (Join-Path $BlockerQueuePath "blocker_phase160e_runtime_guard.json") -Object ([ordered]@{
      status = "BLOCKED"
      blocker_id = "PHASE160E_RUNTIME_GUARD_FAILED"
      guard_label = $GuardLabel
      branch_match = $BranchMatches
      head_match = $HeadMatches
      protected_files_clean = $ProtectedClean
      tracked_status_matches_run_baseline = $TrackedStatusMatches
      runtime_outputs_staged = $RuntimeOutputsStaged
      candidate_production_disabled = $true
      created_at = (Get-Date).ToUniversalTime().ToString("o")
    })
  }

  [pscustomobject][ordered]@{
    status = $Guard.status
    mode = $Mode
    run_id = [string]$ManifestForGuard.run_id
    session_root = $SessionRootRelative
    branch = [string]$ManifestForGuard.branch
    run_head = [string]$ManifestForGuard.run_head
    current_head = $CurrentHead
    remote_head = [string]$ManifestForGuard.remote_head
    expected_head_source = [string]$ManifestForGuard.expected_head_source
    head_match = $HeadMatches
    live_repo_guard = $Guard.status
    candidate_production_enabled = $GuardPassed
    run_manifest_written = Test-Path -LiteralPath $ManifestPath
    runtime_identity_written = Test-Path -LiteralPath $RuntimeIdentityPath
    runtime_guard_written = Test-Path -LiteralPath $RuntimeGuardPath
  } | ConvertTo-Json -Depth 20
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
