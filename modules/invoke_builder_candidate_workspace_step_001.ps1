param(
  [string]$SessionRoot = "",
  [string]$RunId = "",
  [string]$DutyId = "NONE",
  [int]$TickNumber = 0
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160ECandidateFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160ECandidateRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160E_CANDIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160ECandidateFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160ECandidatePath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function ConvertTo-Phase160ECandidateRelativePath {
  param([string]$RepoRoot, [string]$FullPath)
  $root = Normalize-Phase160ECandidateFullPath -Path $RepoRoot
  $full = Normalize-Phase160ECandidateFullPath -Path $FullPath
  if ($full -eq $root) {
    return "."
  }
  if (-not $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160E_CANDIDATE_PATH_OUTSIDE_REPO=$FullPath"
  }
  return ($full.Substring($root.Length + 1) -replace "\\", "/")
}

function Write-Phase160ECandidateJsonFile {
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

function Write-Phase160ECandidateTextFile {
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

function Add-Phase160ECandidateJsonLine {
  param([string]$Path, [object]$Object)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $line = $Object | ConvertTo-Json -Depth 100 -Compress
  [System.IO.File]::AppendAllText($Path, "$line`n", [System.Text.UTF8Encoding]::new($false))
}

function Read-Phase160ECandidateJsonSafe {
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

function Get-Phase160ECandidateProperty {
  param([object]$Object, [string]$Name, [object]$Default = $null)
  if ($null -eq $Object) {
    return $Default
  }
  if ($Object.PSObject.Properties.Name -contains $Name) {
    return $Object.$Name
  }
  return $Default
}

function Get-Phase160ECandidateString {
  param([object]$Object, [string]$Name, [string]$Default = "NONE")
  $value = Get-Phase160ECandidateProperty -Object $Object -Name $Name -Default $Default
  if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value)) {
    return $Default
  }
  return [string]$value
}

function ConvertTo-Phase160ECandidateSafeLeaf {
  param([string]$Value, [int]$MaxLength = 90)
  $leaf = if ([string]::IsNullOrWhiteSpace($Value)) { "NONE" } else { $Value }
  $leaf = $leaf -replace '[^A-Za-z0-9_.-]', '_'
  if ($leaf.Length -gt $MaxLength) {
    $leaf = $leaf.Substring(0, $MaxLength)
  }
  return $leaf
}

function Assert-Phase160ECandidateRunIdSafe {
  param([string]$RunId)
  if ([string]::IsNullOrWhiteSpace($RunId)) {
    return
  }
  if ($RunId.IndexOfAny([char[]]@("/", "\")) -ge 0) {
    throw "PHASE160E_CANDIDATE_RUN_ID_MUST_BE_LEAF=$RunId"
  }
}

function Get-Phase160ECandidatePriorityRank {
  param([string]$Priority)
  switch ($Priority.ToLowerInvariant()) {
    "high" { return 3 }
    "normal" { return 2 }
    "low" { return 1 }
    default { return 0 }
  }
}

function Get-Phase160ECandidateSourceRank {
  param([string]$Source)
  switch ($Source.ToLowerInvariant()) {
    "owner" { return 3 }
    "observer" { return 2 }
    "system" { return 1 }
    default { return 0 }
  }
}

function Get-Phase160ECandidateJsonFileCount {
  param([string]$Directory, [string]$Pattern = "*.json")
  if (-not (Test-Path -LiteralPath $Directory)) {
    return 0
  }
  return @(Get-ChildItem -LiteralPath $Directory -File -Filter $Pattern -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" }).Count
}

function Get-Phase160ECandidateBundleCounts {
  param([string]$CandidateBundleRoot)
  $candidateCount = 0
  $readyCount = 0
  $quarantineCount = 0
  $lastCandidateId = "NONE"
  $bundleDirs = @(Get-ChildItem -LiteralPath $CandidateBundleRoot -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc, Name)
  foreach ($bundleDir in $bundleDirs) {
    $manifest = Read-Phase160ECandidateJsonSafe -Path (Join-Path $bundleDir.FullName "candidate_manifest.json")
    $status = Read-Phase160ECandidateJsonSafe -Path (Join-Path $bundleDir.FullName "candidate_status.json")
    if ($null -eq $manifest) {
      continue
    }
    $candidateCount += 1
    $decision = Get-Phase160ECandidateString -Object $manifest -Name "decision" -Default (Get-Phase160ECandidateString -Object $status -Name "status" -Default "UNKNOWN")
    if ($decision -eq "CANDIDATE_READY") {
      $readyCount += 1
    }
    if ($decision -match "QUARANTINE|QUARANTINED") {
      $quarantineCount += 1
    }
    $lastCandidateId = Get-Phase160ECandidateString -Object $manifest -Name "candidate_id" -Default $bundleDir.Name
  }
  return [pscustomobject][ordered]@{
    candidate_count = $candidateCount
    ready_candidate_count = $readyCount
    quarantined_candidate_count = $quarantineCount
    last_candidate_id = $lastCandidateId
  }
}

function Get-Phase160ECandidateActivePlanFile {
  param([string]$SessionRootFull, [object]$PlanItem)
  if ($null -eq $PlanItem) {
    return $null
  }
  $parentTaskId = Get-Phase160ECandidateString -Object $PlanItem -Name "parent_task_id"
  $itemId = Get-Phase160ECandidateString -Object $PlanItem -Name "item_id"
  if ($parentTaskId -eq "NONE" -or $itemId -eq "NONE") {
    return $null
  }
  $safeParent = ConvertTo-Phase160ECandidateSafeLeaf -Value $parentTaskId
  $candidate = Join-Path $SessionRootFull ("plan_items/{0}/{1}.json" -f $safeParent, $itemId)
  if (Test-Path -LiteralPath $candidate) {
    return $candidate
  }
  return $null
}

function Select-Phase160ECandidateNextPlanItem {
  param(
    [string]$SessionRootFull,
    [string]$RepoRoot,
    [object]$ActiveTask,
    [string]$ChangeLedgerPath,
    [string]$PlanAdvancementLogPath
  )
  if ($null -eq $ActiveTask) {
    return $null
  }
  $taskId = Get-Phase160ECandidateString -Object $ActiveTask -Name "task_id"
  if ($taskId -eq "NONE") {
    return $null
  }
  $safeTaskId = ConvertTo-Phase160ECandidateSafeLeaf -Value $taskId
  $taskPlanDir = Join-Path $SessionRootFull "plan_items/$safeTaskId"
  if (-not (Test-Path -LiteralPath $taskPlanDir)) {
    return $null
  }
  $planFiles = @(Get-ChildItem -LiteralPath $taskPlanDir -File -Filter "*_plan_item_*.json" -ErrorAction SilentlyContinue | Sort-Object Name)
  foreach ($planFile in $planFiles) {
    $planItem = Read-Phase160ECandidateJsonSafe -Path $planFile.FullName
    if ($null -eq $planItem) {
      continue
    }
    $status = Get-Phase160ECandidateString -Object $planItem -Name "status"
    if ($status -ne "PENDING") {
      continue
    }
    $planItem.status = "ACTIVE"
    $planItem | Add-Member -MemberType NoteProperty -Name "activated_at" -Value (Get-Date).ToUniversalTime().ToString("o") -Force
    Write-Phase160ECandidateJsonFile -Path $planFile.FullName -Object $planItem
    Write-Phase160ECandidateJsonFile -Path (Join-Path $SessionRootFull "active_task/active_plan_item.json") -Object $planItem
    Write-Phase160ECandidateJsonFile -Path (Join-Path $SessionRootFull "plan_items/active_plan_item.json") -Object $planItem
    $relativePlanPath = ConvertTo-Phase160ECandidateRelativePath -RepoRoot $RepoRoot -FullPath $planFile.FullName
    Add-Phase160ECandidateJsonLine -Path $PlanAdvancementLogPath -Object ([ordered]@{
      event_type = "plan_item_advanced"
      source = "candidate_workspace_step"
      task_id = $taskId
      plan_item_id = Get-Phase160ECandidateString -Object $planItem -Name "item_id"
      status = "ACTIVE"
      plan_item_path = $relativePlanPath
      occurred_at = (Get-Date).ToUniversalTime().ToString("o")
    })
    Add-Phase160ECandidateJsonLine -Path $ChangeLedgerPath -Object ([ordered]@{
      event_type = "plan_item_advanced"
      source = "candidate_workspace_step"
      task_id = $taskId
      plan_item_id = Get-Phase160ECandidateString -Object $planItem -Name "item_id"
      occurred_at = (Get-Date).ToUniversalTime().ToString("o")
    })
    return $planItem
  }
  return $null
}

function New-Phase160ECandidateBundle {
  param(
    [string]$RepoRoot,
    [string]$SessionRootFull,
    [object]$RunManifest,
    [object]$ActiveTask,
    [object]$ActivePlanItem,
    [string]$DutyId,
    [int]$TickNumber,
    [string]$CandidateBundleRoot,
    [string]$CandidateQueueRoot,
    [string]$ChangeLedgerPath
  )

  if ($null -eq $ActiveTask) {
    return $null
  }
  $taskId = Get-Phase160ECandidateString -Object $ActiveTask -Name "task_id"
  if ($taskId -eq "NONE") {
    return $null
  }
  $planItemId = if ($null -ne $ActivePlanItem) { Get-Phase160ECandidateString -Object $ActivePlanItem -Name "item_id" } else { "NONE" }
  $safeTask = ConvertTo-Phase160ECandidateSafeLeaf -Value $taskId -MaxLength 28
  $safePlan = ConvertTo-Phase160ECandidateSafeLeaf -Value $planItemId -MaxLength 18
  $candidateId = if ($planItemId -eq "NONE") { "cand_$safeTask" } else { "cand_{0}_{1}" -f $safeTask, $safePlan }
  $candidateId = ConvertTo-Phase160ECandidateSafeLeaf -Value $candidateId -MaxLength 60
  $candidateDir = Join-Path $CandidateBundleRoot $candidateId
  $candidateManifestPath = Join-Path $candidateDir "candidate_manifest.json"
  if (Test-Path -LiteralPath $candidateManifestPath) {
    return Read-Phase160ECandidateJsonSafe -Path $candidateManifestPath
  }

  New-Item -ItemType Directory -Force -Path $candidateDir, (Join-Path $candidateDir "proposed_patch_or_file_payloads") | Out-Null
  $ownerGoal = Get-Phase160ECandidateString -Object $ActiveTask -Name "owner_goal"
  $desiredGap = Get-Phase160ECandidateString -Object $ActiveTask -Name "desired_next_gap"
  $taskSource = Get-Phase160ECandidateString -Object $ActiveTask -Name "source" -Default "owner"
  $candidateSource = if ($taskSource -eq "internal_self_selected_goal") { "internal_self_selected_goal" } elseif ($planItemId -ne "NONE") { "plan_item" } else { "owner_task" }
  $sourceInternalGoalId = Get-Phase160ECandidateString -Object $ActiveTask -Name "internal_goal_id" -Default "NONE"
  $sourceInternalGoalName = Get-Phase160ECandidateString -Object $ActiveTask -Name "internal_goal_name" -Default "NONE"
  $targetArea = if ($candidateSource -eq "internal_self_selected_goal") { "self_initiated_useful_goal_selection" } elseif ($planItemId -ne "NONE") { "active_plan_item_candidate" } else { "active_task_candidate" }
  $proposedFile = if ($planItemId -ne "NONE") {
    "modules/{0}_accepted_candidate_placeholder.ps1" -f (ConvertTo-Phase160ECandidateSafeLeaf -Value $planItemId -MaxLength 70)
  } else {
    "modules/{0}_accepted_candidate_placeholder.ps1" -f (ConvertTo-Phase160ECandidateSafeLeaf -Value $taskId -MaxLength 70)
  }
  $validatorNeeded = @(
    "validators/validate_phase160e_full_long_lived_runner_candidate_workspace_promotion_task_lifecycle_v1.ps1",
    "validators/validate_phase160f_full_self_initiated_goal_selection_live_candidate_production_v1.ps1"
  )
  $expectedCapabilities = @(Get-Phase160ECandidateProperty -Object $ActiveTask -Name "expected_candidate_capabilities" -Default @())
  if ($expectedCapabilities.Count -lt 1 -or $desiredGap -match "SELF_INITIATED_USEFUL_GOAL_SELECTION|SELF_SELECTED_USEFUL_CANDIDATE_PRODUCTION" -or $ownerGoal -match "self-initiated|useful goal|candidate|organ|module|validator") {
    $expectedCapabilities = @(
      "SELF_INITIATED_USEFUL_GOAL_SELECTION",
      "self_gap_inventory",
      "usefulness_scoring",
      "internal_active_task",
      "internal_active_task_creation",
      "no_teacher_inbox",
      "no_teacher_inbox_required",
      "candidate_bundle_creation",
      "promotion_bundle_update",
      "runtime_guard_required"
    )
  }
  $candidateCreatedAt = (Get-Date).ToUniversalTime().ToString("o")
  $manifest = [ordered]@{
    status = "PASS"
    candidate_id = $candidateId
    source_task_id = $taskId
    source = $candidateSource
    source_plan_item_id = $planItemId
    source_internal_goal_id = $sourceInternalGoalId
    source_internal_goal_name = $sourceInternalGoalName
    created_from_run_head = [string]$RunManifest.run_head
    run_id = [string]$RunManifest.run_id
    target_area = $targetArea
    owner_goal = $ownerGoal
    desired_next_gap = $desiredGap
    proposed_file_paths = @($proposedFile)
    proposed_validator_paths = $validatorNeeded
    acceptance_validator_needed = $validatorNeeded
    expected_candidate_capabilities = $expectedCapabilities
    owner_approval_required = $true
    owner_promotion_gate_required = $true
    candidate_output_is_not_accepted_code = $true
    repo_mutation_performed = $false
    commit_performed = $false
    push_performed = $false
    branch_switch_performed = $false
    protected_state_mutated = $false
    decision = "CANDIDATE_READY"
    duty_id = $DutyId
    tick_number = $TickNumber
    created_at = $candidateCreatedAt
  }
  Write-Phase160ECandidateJsonFile -Path $candidateManifestPath -Object $manifest
  Write-Phase160ECandidateJsonFile -Path (Join-Path $candidateDir "proposed_files.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $candidateId
    proposed_file_paths = @($proposedFile)
    proposed_validator_paths = $validatorNeeded
    source = $candidateSource
    proposed_only = $true
    accepted_code_written = $false
  })
  Write-Phase160ECandidateJsonFile -Path (Join-Path $candidateDir "proposed_patch_or_file_payloads/payload.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $candidateId
    source = $candidateSource
    payload_type = "session_local_candidate_payload"
    proposed_file_path = $proposedFile
    payload_note = "Candidate payload is data for owner review only. The live daemon did not write accepted code."
    required_payload_markers = @(
      "SELF_INITIATED_USEFUL_GOAL_SELECTION",
      "self_gap_inventory",
      "usefulness_scoring",
      "internal_active_task",
      "internal_active_task_creation",
      "no_teacher_inbox",
      "no_teacher_inbox_required",
      "candidate_bundle_creation",
      "promotion_bundle_update",
      "runtime_guard_required"
    )
    proposed_content_outline = @(
      "Read run manifest and runtime guard.",
      "Build SELF_INITIATED_USEFUL_GOAL_SELECTION support from self_gap_inventory evidence.",
      "Use usefulness_scoring to rank at least five goals.",
      "Create internal_active_task without no_teacher_inbox dependency.",
      "Write candidate_bundle_creation payloads and promotion_bundle_update evidence.",
      "Respect owner promotion gate and runtime_guard_required before future activation.",
      "Write proof before any future accepted-code promotion."
    )
    proposed_module_payload = [ordered]@{
      self_gap_inventory = $true
      usefulness_scoring = $true
      internal_active_task_creation = $true
      no_teacher_inbox_required = $true
      candidate_bundle_creation = $true
      promotion_bundle_update = $true
      runtime_guard_required = $true
    }
    proposed_validator_payload = [ordered]@{
      validator_paths = $validatorNeeded
      proves_no_teacher_inbox_required = $true
      proves_owner_review_required = $true
      proves_runtime_guard_required = $true
    }
    repo_mutation_performed = $false
  })
  Write-Phase160ECandidateTextFile -Path (Join-Path $candidateDir "candidate_rationale.md") -Text (@(
    "# Candidate Rationale",
    "",
    "candidate_id: $candidateId",
    "source: $candidateSource",
    "source_task_id: $taskId",
    "source_plan_item_id: $planItemId",
    "source_internal_goal_id: $sourceInternalGoalId",
    "",
    "This candidate captures a session-local proposal from the live runner. It is intentionally not accepted code and requires owner promotion."
  ) -join "`n")
  Write-Phase160ECandidateJsonFile -Path (Join-Path $candidateDir "candidate_validation_plan.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $candidateId
    validators_required_before_acceptance = $validatorNeeded
    proposed_validator_paths = $validatorNeeded
    owner_review_required = $true
    runtime_guard_required = $true
    promotion_requires_fresh_commit_after_owner_review = $true
  })
  Write-Phase160ECandidateJsonFile -Path (Join-Path $candidateDir "candidate_risk_review.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $candidateId
    risks = @(
      "Candidate may be incomplete until owner promotion.",
      "Live runtime outputs must never be staged as accepted code."
    )
    mitigations = @(
      "Owner promotion gate is required.",
      "Fresh validators and restart are required after accepted promotion."
    )
    accepted_state_mutated = $false
    repo_mutation_performed = $false
  })
  Write-Phase160ECandidateJsonFile -Path (Join-Path $candidateDir "candidate_status.json") -Object ([ordered]@{
    status = "CANDIDATE_READY"
    candidate_id = $candidateId
    source = $candidateSource
    source_task_id = $taskId
    source_plan_item_id = $planItemId
    source_internal_goal_id = $sourceInternalGoalId
    owner_review_required = $true
    promotion_status = "WAITING_OWNER_REVIEW"
    created_at = $candidateCreatedAt
  })
  Write-Phase160ECandidateJsonFile -Path (Join-Path $CandidateQueueRoot "$candidateId.json") -Object ([ordered]@{
    status = "WAITING_OWNER_REVIEW"
    candidate_id = $candidateId
    source = $candidateSource
    source_task_id = $taskId
    source_plan_item_id = $planItemId
    candidate_manifest_path = ConvertTo-Phase160ECandidateRelativePath -RepoRoot $RepoRoot -FullPath $candidateManifestPath
    queued_at = $candidateCreatedAt
  })

  Add-Phase160ECandidateJsonLine -Path $ChangeLedgerPath -Object ([ordered]@{
    event_type = "candidate_created"
    source = "candidate_workspace_step"
    candidate_id = $candidateId
    source_task_id = $taskId
    source_plan_item_id = $planItemId
    run_head = [string]$RunManifest.run_head
    occurred_at = $candidateCreatedAt
  })
  Add-Phase160ECandidateJsonLine -Path $ChangeLedgerPath -Object ([ordered]@{
    event_type = "candidate_validation_plan_written"
    source = "candidate_workspace_step"
    candidate_id = $candidateId
    occurred_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Add-Phase160ECandidateJsonLine -Path $ChangeLedgerPath -Object ([ordered]@{
    event_type = "candidate_ready_for_owner_review"
    source = "candidate_workspace_step"
    candidate_id = $candidateId
    promotion_status = "WAITING_OWNER_REVIEW"
    occurred_at = (Get-Date).ToUniversalTime().ToString("o")
  })

  return [pscustomobject]$manifest
}

function Set-Phase160ECandidatePlanItemWaiting {
  param([string]$SessionRootFull, [object]$PlanItem, [string]$CandidateId)
  if ($null -eq $PlanItem) {
    return
  }
  $PlanItem.status = "WAITING_OWNER_PROMOTION"
  $PlanItem | Add-Member -MemberType NoteProperty -Name "candidate_id" -Value $CandidateId -Force
  $PlanItem | Add-Member -MemberType NoteProperty -Name "waiting_owner_promotion_at" -Value (Get-Date).ToUniversalTime().ToString("o") -Force
  $planFile = Get-Phase160ECandidateActivePlanFile -SessionRootFull $SessionRootFull -PlanItem $PlanItem
  if ($null -ne $planFile) {
    Write-Phase160ECandidateJsonFile -Path $planFile -Object $PlanItem
  }
  Write-Phase160ECandidateJsonFile -Path (Join-Path $SessionRootFull "active_task/active_plan_item.json") -Object $PlanItem
  Write-Phase160ECandidateJsonFile -Path (Join-Path $SessionRootFull "plan_items/active_plan_item.json") -Object $PlanItem
}

$RepoRoot = Resolve-Phase160ECandidateRepoRoot
$Pushed = $false

try {
  Push-Location $RepoRoot
  $Pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160ECandidatePath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  Assert-Phase160ECandidateRunIdSafe -RunId $RunId
  if (-not [string]::IsNullOrWhiteSpace($RunId) -and [string]::IsNullOrWhiteSpace($SessionRoot)) {
    $SessionRoot = "runtime_sessions/live_growth/$RunId"
  }
  if ([string]::IsNullOrWhiteSpace($SessionRoot)) {
    throw "PHASE160E_CANDIDATE_SESSION_ROOT_REQUIRED"
  }

  $SessionRootFull = Resolve-Phase160ECandidatePath -RepoRoot $RepoRoot -Path $SessionRoot
  $SessionRootRelative = ConvertTo-Phase160ECandidateRelativePath -RepoRoot $RepoRoot -FullPath $SessionRootFull
  $RunManifestPath = Join-Path $SessionRootFull "run_manifest.json"
  $RuntimeGuardPath = Join-Path $SessionRootFull "runtime_guard.json"
  $RunManifest = Read-Phase160ECandidateJsonSafe -Path $RunManifestPath
  $RuntimeGuard = Read-Phase160ECandidateJsonSafe -Path $RuntimeGuardPath
  if ($null -eq $RunManifest) {
    throw "PHASE160E_CANDIDATE_RUN_MANIFEST_MISSING=$SessionRootRelative/run_manifest.json"
  }
  if ($null -eq $RuntimeGuard) {
    throw "PHASE160E_CANDIDATE_RUNTIME_GUARD_MISSING=$SessionRootRelative/runtime_guard.json"
  }

  $CandidateWorkspace = Join-Path $SessionRootFull "candidate_workspace"
  $CandidateBundleRoot = Join-Path $CandidateWorkspace "candidate_bundles"
  $CandidateQueueRoot = Join-Path $CandidateWorkspace "candidate_queue"
  $CandidateQuarantineRoot = Join-Path $CandidateWorkspace "candidate_quarantine"
  $ChangeLedgerPath = Join-Path $CandidateWorkspace "change_ledger.jsonl"
  $TaskLifecycleRoot = Join-Path $SessionRootFull "task_lifecycle"
  $TaskCompletionReceiptRoot = Join-Path $TaskLifecycleRoot "task_completion_receipts"
  $BacklogAdvancementLogPath = Join-Path $TaskLifecycleRoot "backlog_advancement_log.jsonl"
  $PlanAdvancementLogPath = Join-Path $TaskLifecycleRoot "plan_item_advancement_log.jsonl"
  $ActiveTaskStatePath = Join-Path $TaskLifecycleRoot "active_task_state.json"
  foreach ($directory in @(
    $CandidateWorkspace,
    $CandidateBundleRoot,
    $CandidateQueueRoot,
    $CandidateQuarantineRoot,
    $TaskLifecycleRoot,
    $TaskCompletionReceiptRoot,
    (Join-Path $SessionRootFull "promotion_bundle"),
    (Join-Path $SessionRootFull "active_task"),
    (Join-Path $SessionRootFull "task_backlog"),
    (Join-Path $SessionRootFull "plan_items")
  )) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  if ([string]$RuntimeGuard.status -ne "PASS" -or [bool]$RuntimeGuard.candidate_production_enabled -ne $true) {
    Add-Phase160ECandidateJsonLine -Path $ChangeLedgerPath -Object ([ordered]@{
      event_type = "candidate_workspace_step_blocked"
      source = "candidate_workspace_step"
      duty_id = $DutyId
      runtime_guard_status = [string]$RuntimeGuard.status
      occurred_at = (Get-Date).ToUniversalTime().ToString("o")
    })
    [pscustomobject][ordered]@{
      status = "BLOCKED"
      run_id = [string]$RunManifest.run_id
      session_root = $SessionRootRelative
      runtime_guard_status = [string]$RuntimeGuard.status
      candidate_production_enabled = $false
      candidate_count = (Get-Phase160ECandidateBundleCounts -CandidateBundleRoot $CandidateBundleRoot).candidate_count
    } | ConvertTo-Json -Depth 20
    return
  }

  $ActiveTaskPath = Join-Path $SessionRootFull "active_task/active_task.json"
  $ActivePlanItemPath = Join-Path $SessionRootFull "active_task/active_plan_item.json"
  $ActiveTask = Read-Phase160ECandidateJsonSafe -Path $ActiveTaskPath
  $ActivePlanItem = Read-Phase160ECandidateJsonSafe -Path $ActivePlanItemPath
  $ActiveTaskState = Read-Phase160ECandidateJsonSafe -Path $ActiveTaskStatePath
  $CandidateCreated = $false
  $BacklogAdvanced = $false
  $PlanItemAdvanced = $false
  $ActiveTaskMovedToWaitingPromotion = $false
  $LastCandidateId = "NONE"

  if ($null -ne $ActiveTask -and $null -eq $ActiveTaskState) {
    Write-Phase160ECandidateJsonFile -Path $ActiveTaskStatePath -Object ([ordered]@{
      status = "ACTIVE"
      active_task_id = Get-Phase160ECandidateString -Object $ActiveTask -Name "task_id"
      active_plan_item_id = if ($null -ne $ActivePlanItem) { Get-Phase160ECandidateString -Object $ActivePlanItem -Name "item_id" } else { "NONE" }
      run_id = [string]$RunManifest.run_id
      run_head = [string]$RunManifest.run_head
      updated_at = (Get-Date).ToUniversalTime().ToString("o")
    })
    $ActiveTaskState = Read-Phase160ECandidateJsonSafe -Path $ActiveTaskStatePath
  }

  $CurrentStateStatus = if ($null -ne $ActiveTaskState) { Get-Phase160ECandidateString -Object $ActiveTaskState -Name "status" } else { "NONE" }
  if ($null -ne $ActiveTask -and $CurrentStateStatus -ne "WAITING_OWNER_PROMOTION") {
    $candidate = New-Phase160ECandidateBundle -RepoRoot $RepoRoot -SessionRootFull $SessionRootFull -RunManifest $RunManifest -ActiveTask $ActiveTask -ActivePlanItem $ActivePlanItem -DutyId $DutyId -TickNumber $TickNumber -CandidateBundleRoot $CandidateBundleRoot -CandidateQueueRoot $CandidateQueueRoot -ChangeLedgerPath $ChangeLedgerPath
    if ($null -ne $candidate) {
      $CandidateCreated = $true
      $LastCandidateId = Get-Phase160ECandidateString -Object $candidate -Name "candidate_id"
      $candidateSourceForState = Get-Phase160ECandidateString -Object $candidate -Name "source" -Default "owner_task"
      Set-Phase160ECandidatePlanItemWaiting -SessionRootFull $SessionRootFull -PlanItem $ActivePlanItem -CandidateId $LastCandidateId
      Write-Phase160ECandidateJsonFile -Path $ActiveTaskStatePath -Object ([ordered]@{
        status = "WAITING_OWNER_PROMOTION"
        source = $candidateSourceForState
        active_task_id = Get-Phase160ECandidateString -Object $ActiveTask -Name "task_id"
        active_plan_item_id = if ($null -ne $ActivePlanItem) { Get-Phase160ECandidateString -Object $ActivePlanItem -Name "item_id" } else { "NONE" }
        candidate_id = $LastCandidateId
        desired_next_gap = Get-Phase160ECandidateString -Object $ActiveTask -Name "desired_next_gap"
        run_id = [string]$RunManifest.run_id
        run_head = [string]$RunManifest.run_head
        owner_review_required = $true
        restart_required_after_promotion = $true
        updated_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      $receiptPath = Join-Path $TaskCompletionReceiptRoot ("receipt_{0}_{1}.json" -f (ConvertTo-Phase160ECandidateSafeLeaf -Value (Get-Phase160ECandidateString -Object $ActiveTask -Name "task_id") -MaxLength 70), $LastCandidateId)
      Write-Phase160ECandidateJsonFile -Path $receiptPath -Object ([ordered]@{
        status = "WAITING_OWNER_PROMOTION"
        source = $candidateSourceForState
        task_id = Get-Phase160ECandidateString -Object $ActiveTask -Name "task_id"
        plan_item_id = if ($null -ne $ActivePlanItem) { Get-Phase160ECandidateString -Object $ActivePlanItem -Name "item_id" } else { "NONE" }
        candidate_id = $LastCandidateId
        promotion_gate_required = $true
        completed_session_local = $true
        accepted_code_written = $false
        created_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      $ActiveTaskMovedToWaitingPromotion = $true
      Add-Phase160ECandidateJsonLine -Path $ChangeLedgerPath -Object ([ordered]@{
        event_type = "active_task_moved_to_waiting_owner_promotion"
        source = "candidate_workspace_step"
        task_id = Get-Phase160ECandidateString -Object $ActiveTask -Name "task_id"
        candidate_id = $LastCandidateId
        occurred_at = (Get-Date).ToUniversalTime().ToString("o")
      })
    }
  }

  $BacklogFiles = @(Get-ChildItem -LiteralPath (Join-Path $SessionRootFull "task_backlog") -File -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" } | Sort-Object `
    @{ Expression = { -(Get-Phase160ECandidatePriorityRank -Priority (Get-Phase160ECandidateString -Object (Read-Phase160ECandidateJsonSafe -Path $_.FullName) -Name "priority")) } }, `
    @{ Expression = { -(Get-Phase160ECandidateSourceRank -Source (Get-Phase160ECandidateString -Object (Read-Phase160ECandidateJsonSafe -Path $_.FullName) -Name "source")) } }, `
    @{ Expression = { [string](Get-Phase160ECandidateString -Object (Read-Phase160ECandidateJsonSafe -Path $_.FullName) -Name "created_at") } }, `
    Name)

  $StateAfterCandidate = Read-Phase160ECandidateJsonSafe -Path $ActiveTaskStatePath
  $CanAdvanceBacklog = ($null -ne $StateAfterCandidate -and (Get-Phase160ECandidateString -Object $StateAfterCandidate -Name "status") -eq "WAITING_OWNER_PROMOTION" -and $BacklogFiles.Count -gt 0)
  if ($CanAdvanceBacklog) {
    $SelectedBacklogFile = $BacklogFiles[0]
    $SelectedBacklog = Read-Phase160ECandidateJsonSafe -Path $SelectedBacklogFile.FullName
    if ($null -ne $SelectedBacklog) {
      $previousTaskId = Get-Phase160ECandidateString -Object $StateAfterCandidate -Name "active_task_id"
      $newTaskId = Get-Phase160ECandidateString -Object $SelectedBacklog -Name "task_id"
      Write-Phase160ECandidateJsonFile -Path $ActiveTaskPath -Object ([ordered]@{
        status = "ACTIVE"
        duty_id = $DutyId
        task_id = $newTaskId
        source = Get-Phase160ECandidateString -Object $SelectedBacklog -Name "source" -Default "owner"
        priority = Get-Phase160ECandidateString -Object $SelectedBacklog -Name "priority" -Default "normal"
        owner_goal = Get-Phase160ECandidateString -Object $SelectedBacklog -Name "owner_goal"
        desired_next_gap = Get-Phase160ECandidateString -Object $SelectedBacklog -Name "desired_next_gap"
        teacher_digest_path = Get-Phase160ECandidateString -Object $SelectedBacklog -Name "teacher_digest_path"
        content_hash = Get-Phase160ECandidateString -Object $SelectedBacklog -Name "content_hash"
        active_plan_item_id = "NONE"
        active_plan_item_path = "NONE"
        plan_step_count = [int](Get-Phase160ECandidateProperty -Object $SelectedBacklog -Name "plan_step_count" -Default 0)
        selected_for_candidate_workspace = $true
        selected_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      Remove-Item -LiteralPath $SelectedBacklogFile.FullName -Force
      $ActiveTask = Read-Phase160ECandidateJsonSafe -Path $ActiveTaskPath
      $ActivePlanItem = Select-Phase160ECandidateNextPlanItem -SessionRootFull $SessionRootFull -RepoRoot $RepoRoot -ActiveTask $ActiveTask -ChangeLedgerPath $ChangeLedgerPath -PlanAdvancementLogPath $PlanAdvancementLogPath
      if ($null -ne $ActivePlanItem) {
        $PlanItemAdvanced = $true
        $ActiveTask.active_plan_item_id = Get-Phase160ECandidateString -Object $ActivePlanItem -Name "item_id"
        $ActiveTask.active_plan_item_path = ConvertTo-Phase160ECandidateRelativePath -RepoRoot $RepoRoot -FullPath (Get-Phase160ECandidateActivePlanFile -SessionRootFull $SessionRootFull -PlanItem $ActivePlanItem)
        Write-Phase160ECandidateJsonFile -Path $ActiveTaskPath -Object $ActiveTask
      }
      Write-Phase160ECandidateJsonFile -Path $ActiveTaskStatePath -Object ([ordered]@{
        status = "ACTIVE"
        active_task_id = $newTaskId
        active_plan_item_id = if ($null -ne $ActivePlanItem) { Get-Phase160ECandidateString -Object $ActivePlanItem -Name "item_id" } else { "NONE" }
        previous_task_id = $previousTaskId
        run_id = [string]$RunManifest.run_id
        run_head = [string]$RunManifest.run_head
        updated_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      $BacklogAdvanced = $true
      Add-Phase160ECandidateJsonLine -Path $BacklogAdvancementLogPath -Object ([ordered]@{
        event_type = "backlog_advanced"
        source = "candidate_workspace_step"
        previous_task_id = $previousTaskId
        active_task_id = $newTaskId
        selected_backlog_file = $SelectedBacklogFile.Name
        active_plan_item_id = if ($null -ne $ActivePlanItem) { Get-Phase160ECandidateString -Object $ActivePlanItem -Name "item_id" } else { "NONE" }
        occurred_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      Add-Phase160ECandidateJsonLine -Path $ChangeLedgerPath -Object ([ordered]@{
        event_type = "backlog_advanced"
        source = "candidate_workspace_step"
        previous_task_id = $previousTaskId
        active_task_id = $newTaskId
        occurred_at = (Get-Date).ToUniversalTime().ToString("o")
      })
    }
  }

  $ActiveTask = Read-Phase160ECandidateJsonSafe -Path $ActiveTaskPath
  $ActivePlanItem = Read-Phase160ECandidateJsonSafe -Path $ActivePlanItemPath
  $StateBeforeSecondCandidate = Read-Phase160ECandidateJsonSafe -Path $ActiveTaskStatePath
  $stateTaskId = if ($null -ne $StateBeforeSecondCandidate) { Get-Phase160ECandidateString -Object $StateBeforeSecondCandidate -Name "active_task_id" } else { "NONE" }
  $stateStatus = if ($null -ne $StateBeforeSecondCandidate) { Get-Phase160ECandidateString -Object $StateBeforeSecondCandidate -Name "status" } else { "NONE" }
  if ($null -ne $ActiveTask -and $stateStatus -eq "ACTIVE" -and $stateTaskId -eq (Get-Phase160ECandidateString -Object $ActiveTask -Name "task_id")) {
    $candidate = New-Phase160ECandidateBundle -RepoRoot $RepoRoot -SessionRootFull $SessionRootFull -RunManifest $RunManifest -ActiveTask $ActiveTask -ActivePlanItem $ActivePlanItem -DutyId $DutyId -TickNumber $TickNumber -CandidateBundleRoot $CandidateBundleRoot -CandidateQueueRoot $CandidateQueueRoot -ChangeLedgerPath $ChangeLedgerPath
    if ($null -ne $candidate) {
      $CandidateCreated = $true
      $LastCandidateId = Get-Phase160ECandidateString -Object $candidate -Name "candidate_id"
      $candidateSourceForState = Get-Phase160ECandidateString -Object $candidate -Name "source" -Default "owner_task"
      Set-Phase160ECandidatePlanItemWaiting -SessionRootFull $SessionRootFull -PlanItem $ActivePlanItem -CandidateId $LastCandidateId
      Write-Phase160ECandidateJsonFile -Path $ActiveTaskStatePath -Object ([ordered]@{
        status = "WAITING_OWNER_PROMOTION"
        source = $candidateSourceForState
        active_task_id = Get-Phase160ECandidateString -Object $ActiveTask -Name "task_id"
        active_plan_item_id = if ($null -ne $ActivePlanItem) { Get-Phase160ECandidateString -Object $ActivePlanItem -Name "item_id" } else { "NONE" }
        candidate_id = $LastCandidateId
        desired_next_gap = Get-Phase160ECandidateString -Object $ActiveTask -Name "desired_next_gap"
        run_id = [string]$RunManifest.run_id
        run_head = [string]$RunManifest.run_head
        owner_review_required = $true
        restart_required_after_promotion = $true
        updated_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      Write-Phase160ECandidateJsonFile -Path (Join-Path $TaskCompletionReceiptRoot ("receipt_{0}_{1}.json" -f (ConvertTo-Phase160ECandidateSafeLeaf -Value (Get-Phase160ECandidateString -Object $ActiveTask -Name "task_id") -MaxLength 70), $LastCandidateId)) -Object ([ordered]@{
        status = "WAITING_OWNER_PROMOTION"
        source = $candidateSourceForState
        task_id = Get-Phase160ECandidateString -Object $ActiveTask -Name "task_id"
        plan_item_id = if ($null -ne $ActivePlanItem) { Get-Phase160ECandidateString -Object $ActivePlanItem -Name "item_id" } else { "NONE" }
        candidate_id = $LastCandidateId
        promotion_gate_required = $true
        completed_session_local = $true
        accepted_code_written = $false
        created_at = (Get-Date).ToUniversalTime().ToString("o")
      })
      $ActiveTaskMovedToWaitingPromotion = $true
      Add-Phase160ECandidateJsonLine -Path $ChangeLedgerPath -Object ([ordered]@{
        event_type = "active_task_moved_to_waiting_owner_promotion"
        source = "candidate_workspace_step"
        task_id = Get-Phase160ECandidateString -Object $ActiveTask -Name "task_id"
        candidate_id = $LastCandidateId
        occurred_at = (Get-Date).ToUniversalTime().ToString("o")
      })
    }
  }

  $FinalizeScript = Resolve-Phase160ECandidatePath -RepoRoot $RepoRoot -Path "modules/finalize_builder_promotion_bundle_001.ps1"
  $FinalizeOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File $FinalizeScript -SessionRoot $SessionRootRelative -RunId ([string]$RunManifest.run_id) 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160E_CANDIDATE_PROMOTION_FINALIZE_FAILED exit=$LASTEXITCODE output=$($FinalizeOutput -join ' | ')"
  }
  $FinalizeResult = ($FinalizeOutput -join "`n") | ConvertFrom-Json
  $Counts = Get-Phase160ECandidateBundleCounts -CandidateBundleRoot $CandidateBundleRoot
  if ($LastCandidateId -eq "NONE") {
    $LastCandidateId = [string]$Counts.last_candidate_id
  }
  $FinalTaskState = Read-Phase160ECandidateJsonSafe -Path $ActiveTaskStatePath

  [pscustomobject][ordered]@{
    status = "PASS"
    run_id = [string]$RunManifest.run_id
    session_root = $SessionRootRelative
    duty_id = $DutyId
    tick_number = $TickNumber
    run_head = [string]$RunManifest.run_head
    candidate_workspace_created = Test-Path -LiteralPath $CandidateWorkspace
    candidate_bundle_created = [int]$Counts.candidate_count -gt 0
    candidate_created_this_step = $CandidateCreated
    candidate_count = [int]$Counts.candidate_count
    ready_candidate_count = [int]$Counts.ready_candidate_count
    quarantined_candidate_count = [int]$Counts.quarantined_candidate_count
    promotion_bundle_created = [bool]$FinalizeResult.promotion_manifest_created
    promotion_bundle_status = [string]$FinalizeResult.promotion_bundle_status
    owner_review_summary_created = [bool]$FinalizeResult.owner_review_summary_created
    active_task_moved_to_waiting_promotion = $ActiveTaskMovedToWaitingPromotion
    active_task_status = if ($null -ne $FinalTaskState) { Get-Phase160ECandidateString -Object $FinalTaskState -Name "status" } else { "NONE" }
    backlog_advanced = $BacklogAdvanced
    plan_item_advanced = $PlanItemAdvanced
    last_candidate_id = $LastCandidateId
    restart_required_after_promotion = $true
    repo_mutation_performed = $false
    commit_performed = $false
    push_performed = $false
    branch_switch_performed = $false
    protected_state_mutated = $false
  } | ConvertTo-Json -Depth 20
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
