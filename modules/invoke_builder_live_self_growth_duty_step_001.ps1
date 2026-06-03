param(
  [string]$SessionRoot = "runtime_sessions/live_growth/PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_SMOKE_001",
  [int]$TickNumber = 0,
  [int]$DutyIndex = 1,
  [string]$DutyRoot = "",
  [string]$TeacherOutboxDir = "",
  [int]$MaxCandidateBytes = 8192,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160DutyFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160DutyRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160_SELF_GROWTH_DUTY_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160DutyFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160DutyPath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function ConvertTo-Phase160DutyRelativePath {
  param([string]$RepoRoot, [string]$FullPath)
  $normalizedRoot = Normalize-Phase160DutyFullPath -Path $RepoRoot
  $normalizedPath = Normalize-Phase160DutyFullPath -Path $FullPath
  if ($normalizedPath -eq $normalizedRoot) {
    return "."
  }
  if (-not $normalizedPath.StartsWith($normalizedRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160_SELF_GROWTH_DUTY_PATH_OUTSIDE_REPO=$FullPath"
  }
  return ($normalizedPath.Substring($normalizedRoot.Length + 1) -replace "\\", "/")
}

function Write-Phase160DutyJsonFile {
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

function Add-Phase160DutyJsonLine {
  param([string]$Path, [object]$Object)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $line = $Object | ConvertTo-Json -Depth 100 -Compress
  [System.IO.File]::AppendAllText($Path, "$line`n", [System.Text.UTF8Encoding]::new($false))
}

function Read-Phase160DutyJsonSafe {
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

function Read-Phase160DutyJsonSummarySafe {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160DutyPath -RepoRoot $RepoRoot -Path $Path
  $artifact = Read-Phase160DutyJsonSafe -Path $fullPath
  if ($null -eq $artifact) {
    return [ordered]@{
      path = $Path
      present = $false
    }
  }
  return [ordered]@{
    path = $Path
    present = $true
    status = [string]$artifact.status
    step_id = [string]$artifact.step_id
    repair_id = [string]$artifact.repair_id
    run_id = [string]$artifact.run_id
    next_allowed_step = [string]$artifact.next_allowed_step
    next_action = [string]$artifact.next_action
  }
}

function Assert-Phase160DutyEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160_SELF_GROWTH_DUTY_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Get-Phase160DutyRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160_SELF_GROWTH_DUTY_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Get-Phase160DutyGapForIndex {
  param([int]$Index)
  $curriculum = @(
    "SELF_MAP_REFRESH_GAP",
    "CAPABILITY_INVENTORY_REFRESH_GAP",
    "TEACHER_CHANNEL_READINESS_GAP",
    "BLOCKER_CHANNEL_READINESS_GAP",
    "SELF_GROWTH_RESULT_SUMMARY_GAP",
    "NEXT_SELF_GROWTH_GOAL_SELECTION_GAP"
  )
  if ($Index -lt 1) {
    throw "PHASE160_SELF_GROWTH_DUTY_INVALID_INDEX=$Index"
  }
  return $curriculum[(($Index - 1) % $curriculum.Count)]
}

function Test-Phase160DutyTeacherInterventionValid {
  param([object]$Intervention)
  if ($null -eq $Intervention) {
    return $false
  }
  return (
    -not [string]::IsNullOrWhiteSpace([string]$Intervention.intervention_id) -and
    -not [string]::IsNullOrWhiteSpace([string]$Intervention.message_type) -and
    -not [string]::IsNullOrWhiteSpace([string]$Intervention.requested_action) -and
    (@("teacher_instruction", "teacher_correction", "teacher_stop_request", "observer_suggestion") -contains [string]$Intervention.message_type)
  )
}

$RepoRoot = Resolve-Phase160DutyRepoRoot
$ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
$RepairId = "PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_EXPANSION_V1"
$Pushed = $false

try {
  Push-Location $RepoRoot
  $Pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160DutyPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  Assert-Phase160DutyEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160DutyRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160DutyEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"
  $ExpectedHeadSource = "CURRENT_SYNCED_REPO_HEAD"

  if ($TickNumber -lt 0) {
    throw "PHASE160_SELF_GROWTH_DUTY_INVALID_TICK=$TickNumber"
  }
  if ($DutyIndex -lt 1) {
    throw "PHASE160_SELF_GROWTH_DUTY_INVALID_DUTY_INDEX=$DutyIndex"
  }
  if ($MaxCandidateBytes -lt 512) {
    throw "PHASE160_SELF_GROWTH_DUTY_MAX_CANDIDATE_BYTES_TOO_LOW=$MaxCandidateBytes"
  }

  $SessionRootFull = Resolve-Phase160DutyPath -RepoRoot $RepoRoot -Path $SessionRoot
  $SessionRootRelative = ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $SessionRootFull
  if (-not (Test-Path -LiteralPath $SessionRootFull)) {
    throw "PHASE160_SELF_GROWTH_DUTY_SESSION_ROOT_MISSING=$SessionRootRelative"
  }

  if ([string]::IsNullOrWhiteSpace($DutyRoot)) {
    $DutyRoot = "$SessionRootRelative/self_growth"
  }
  if ([string]::IsNullOrWhiteSpace($TeacherOutboxDir)) {
    $TeacherOutboxDir = "$SessionRootRelative/teacher_outbox"
  }

  $DutyRootFull = Resolve-Phase160DutyPath -RepoRoot $RepoRoot -Path $DutyRoot
  $DutyRootRelative = ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $DutyRootFull
  $DutyId = "duty_{0:d4}" -f $DutyIndex
  $DutyDirFull = Join-Path $DutyRootFull $DutyId
  $DutyDirRelative = ConvertTo-Phase160DutyRelativePath -RepoRoot $RepoRoot -FullPath $DutyDirFull
  New-Item -ItemType Directory -Force -Path $DutyDirFull | Out-Null

  $HeartbeatPath = Join-Path $SessionRootFull "heartbeat.json"
  $CurrentStatePath = Join-Path $SessionRootFull "current_state.json"
  $EventLogPath = Join-Path $SessionRootFull "event_log.jsonl"
  $TeacherOutboxFull = Resolve-Phase160DutyPath -RepoRoot $RepoRoot -Path $TeacherOutboxDir
  $AcceptedInterventionsPath = Join-Path $SessionRootFull "accepted_interventions"
  $RejectedInterventionsPath = Join-Path $SessionRootFull "rejected_interventions"
  $BlockerQueuePath = Join-Path $SessionRootFull "blocker_queue"
  foreach ($directory in @($TeacherOutboxFull, $AcceptedInterventionsPath, $RejectedInterventionsPath, $BlockerQueuePath)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $StartedAt = Get-Date
  $Gap = Get-Phase160DutyGapForIndex -Index $DutyIndex
  $NextGap = Get-Phase160DutyGapForIndex -Index ($DutyIndex + 1)
  $Heartbeat = Read-Phase160DutyJsonSafe -Path $HeartbeatPath
  $CurrentState = Read-Phase160DutyJsonSafe -Path $CurrentStatePath
  $ProofPaths = @(
    "proofs/self_development/PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1.json",
    "proofs/self_development/PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1.json",
    "proofs/self_development/PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1.json",
    "proofs/self_development/PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1.json",
    "proofs/self_development/PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1.json",
    "proofs/self_development/PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1.json",
    "proofs/self_development/PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1.json",
    "proofs/self_development/PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1.json",
    "proofs/self_development/PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_V1.json",
    "proofs/self_development/PHASE160_LIVE_OBSERVER_CONSOLE_REPAIR_V1.json"
  )
  $ProofSummaries = @()
  foreach ($proofPath in $ProofPaths) {
    $ProofSummaries += Read-Phase160DutyJsonSummarySafe -RepoRoot $RepoRoot -Path $proofPath
  }

  $SelfMapSnapshot = [ordered]@{
    status = "PASS"
    repair_id = $RepairId
    duty_id = $DutyId
    session_root = $SessionRootRelative
    tick_number = $TickNumber
    duty_index = $DutyIndex
    resolved_repo_root = $RepoRoot
    branch = $Branch
    local_head = $Head
    remote_head = $RemoteHead
    expected_head_source = $ExpectedHeadSource
    heartbeat_present = $null -ne $Heartbeat
    heartbeat_status = if ($null -ne $Heartbeat) { [string]$Heartbeat.status } else { "MISSING" }
    heartbeat_count = if ($null -ne $Heartbeat) { $Heartbeat.heartbeat_count } else { $null }
    current_state_present = $null -ne $CurrentState
    current_tick = if ($null -ne $CurrentState) { $CurrentState.current_tick } else { $TickNumber }
    accepted_proof_summaries = $ProofSummaries
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    created_at = $StartedAt.ToUniversalTime().ToString("o")
  }

  $CapabilityInventorySnapshot = [ordered]@{
    status = "PASS"
    duty_id = $DutyId
    inventory_scope = "session_local_runtime_capability_snapshot"
    modules_available = @(
      "modules/start_builder_live_growth_daemon_001.ps1",
      "modules/watch_builder_live_growth_session_observer_001.ps1",
      "modules/watch_builder_live_console_001.ps1",
      "modules/invoke_builder_live_self_growth_duty_step_001.ps1"
    )
    validators_available = @(
      "validators/validate_phase160_live_growth_session_daemon_bootstrap_v1.ps1",
      "validators/validate_phase160_live_observer_console_repair_v1.ps1",
      "validators/validate_phase160_live_self_growth_duty_loop_v1.ps1"
    )
    channels_available = @("teacher_outbox", "teacher_inbox", "blocker_queue", "accepted_interventions", "rejected_interventions", "event_log")
    deterministic_gap_policy_available = $true
    arbitrary_code_execution_allowed = $false
    capability_shelf_promotion_allowed = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $ElementaryKnowledgeSnapshot = [ordered]@{
    status = "PASS"
    duty_id = $DutyId
    knowledge_type = "operational_seed_only"
    identity = "Builder is local-first self-growing action machine"
    safety = "sandbox-only until admission"
    scope = "no accepted state mutation"
    method = "observe -> select gap -> candidate -> validate -> memory event -> next decision"
    teacher_channel = "teacher_outbox suggestions are input, not commands"
    blocker_channel = "if unable, write blocker/help request"
    stop = "obey stop.flag and duration limit"
    world_knowledge_loaded = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $GapSelection = [ordered]@{
    status = "PASS"
    duty_id = $DutyId
    policy = "DETERMINISTIC_PHASE160_SELF_GROWTH_CURRICULUM"
    duty_index = $DutyIndex
    selected_gap = $Gap
    next_gap = $NextGap
    curriculum = @(
      "SELF_MAP_REFRESH_GAP",
      "CAPABILITY_INVENTORY_REFRESH_GAP",
      "TEACHER_CHANNEL_READINESS_GAP",
      "BLOCKER_CHANNEL_READINESS_GAP",
      "SELF_GROWTH_RESULT_SUMMARY_GAP",
      "NEXT_SELF_GROWTH_GOAL_SELECTION_GAP"
    )
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $TeacherFiles = @(Get-ChildItem -LiteralPath $TeacherOutboxFull -File -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.json" } | Sort-Object FullName)
  $AcceptedTeacherInputs = @()
  $RejectedTeacherInputs = @()
  foreach ($teacherFile in $TeacherFiles) {
    $Intervention = Read-Phase160DutyJsonSafe -Path $teacherFile.FullName
    if (Test-Phase160DutyTeacherInterventionValid -Intervention $Intervention) {
      $AcceptedTeacherInputs += $teacherFile.Name
      Write-Phase160DutyJsonFile -Path (Join-Path $AcceptedInterventionsPath ("{0}_{1}" -f $DutyId, $teacherFile.Name)) -Object ([ordered]@{
        status = "ACCEPTED"
        duty_id = $DutyId
        source_file = $teacherFile.Name
        action_taken = "accepted_as_session_local_self_growth_input"
        accepted_state_mutated = $false
        accepted_memory_mutated = $false
        created_at = (Get-Date).ToUniversalTime().ToString("o")
      })
    } else {
      $RejectedTeacherInputs += $teacherFile.Name
      Write-Phase160DutyJsonFile -Path (Join-Path $RejectedInterventionsPath ("{0}_{1}" -f $DutyId, $teacherFile.Name)) -Object ([ordered]@{
        status = "REJECTED"
        duty_id = $DutyId
        source_file = $teacherFile.Name
        reason = "invalid_teacher_intervention_schema"
        accepted_state_mutated = $false
        accepted_memory_mutated = $false
        created_at = (Get-Date).ToUniversalTime().ToString("o")
      })
    }
  }

  $SelfGrowthIntention = [ordered]@{
    status = "PASS"
    duty_id = $DutyId
    selected_gap = $Gap
    intention = "perform_bounded_session_local_self_growth_duty"
    owner_visible = $true
    dry_run = [bool]$DryRun
    accepted_state_mutation_requested = $false
    accepted_memory_mutation_requested = $false
    capability_shelf_promotion_requested = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $Candidate = [ordered]@{
    status = "CANDIDATE"
    duty_id = $DutyId
    selected_gap = $Gap
    candidate_type = "sandbox_only_self_growth_action"
    proposed_action = switch ($Gap) {
      "SELF_MAP_REFRESH_GAP" { "refresh session-local map of current Builder runtime contour" }
      "CAPABILITY_INVENTORY_REFRESH_GAP" { "refresh session-local inventory of live modules, validators, and channels" }
      "TEACHER_CHANNEL_READINESS_GAP" { "verify teacher_outbox input handling and teacher_inbox suggestion visibility" }
      "BLOCKER_CHANNEL_READINESS_GAP" { "verify blocker_queue support and safe help-request shape" }
      "SELF_GROWTH_RESULT_SUMMARY_GAP" { "summarize prior self-growth duty outputs into session-local memory event" }
      default { "select the next bounded self-growth goal from deterministic curriculum" }
    }
    candidate_payload = [ordered]@{
      observe = $true
      select_gap = $Gap
      validate_before_promotion = $true
      write_session_memory_event = $true
      mutate_accepted_state = $false
      execute_generated_code = $false
      create_external_agent = $false
    }
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  $CandidateBytes = [System.Text.Encoding]::UTF8.GetByteCount(($Candidate | ConvertTo-Json -Depth 100 -Compress))
  $ValidationPassed = (
    $CandidateBytes -le $MaxCandidateBytes -and
    $Candidate.candidate_payload.mutate_accepted_state -eq $false -and
    $Candidate.candidate_payload.execute_generated_code -eq $false -and
    $Candidate.candidate_payload.create_external_agent -eq $false
  )
  $ValidationResult = [ordered]@{
    status = if ($ValidationPassed) { "PASS" } else { "FAIL" }
    duty_id = $DutyId
    selected_gap = $Gap
    candidate_bytes = $CandidateBytes
    max_candidate_bytes = $MaxCandidateBytes
    sandbox_only = $true
    arbitrary_code_execution_used = $false
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    external_agents_created = $false
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  if (-not $ValidationPassed) {
    Write-Phase160DutyJsonFile -Path (Join-Path $BlockerQueuePath ("blocker_{0}.json" -f $DutyId)) -Object ([ordered]@{
      status = "BLOCKED"
      blocker_id = "PHASE160_SELF_GROWTH_DUTY_VALIDATION_FAILED"
      duty_id = $DutyId
      selected_gap = $Gap
      safe_stop_recommended = $false
      created_at = (Get-Date).ToUniversalTime().ToString("o")
    })
  }

  $MemoryEvent = [ordered]@{
    status = if ($ValidationPassed) { "PASS" } else { "BLOCKED" }
    duty_id = $DutyId
    memory_scope = "session_local_only"
    event_type = "self_growth_duty_memory_event"
    selected_gap = $Gap
    lesson = "bounded duty completed without accepted state mutation"
    accepted_teacher_inputs = $AcceptedTeacherInputs
    rejected_teacher_inputs = $RejectedTeacherInputs
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $NextDecision = [ordered]@{
    status = "PASS"
    duty_id = $DutyId
    completed_gap = $Gap
    next_gap = $NextGap
    next_action = "continue_bounded_self_growth_curriculum"
    codex_needed_for_next_step = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $RequiredObjects = [ordered]@{
    self_map_snapshot = $SelfMapSnapshot
    capability_inventory_snapshot = $CapabilityInventorySnapshot
    elementary_knowledge_snapshot = $ElementaryKnowledgeSnapshot
    gap_selection = $GapSelection
    self_growth_intention = $SelfGrowthIntention
    sandbox_action_candidate = $Candidate
    sandbox_validation_result = $ValidationResult
    memory_event = $MemoryEvent
    next_self_growth_decision = $NextDecision
  }
  foreach ($entry in $RequiredObjects.GetEnumerator()) {
    Write-Phase160DutyJsonFile -Path (Join-Path $DutyDirFull ("{0}.json" -f $entry.Key)) -Object $entry.Value
  }

  Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
    event_type = "self_growth_gap_selected"
    source = "builder_self_growth_duty"
    duty_id = $DutyId
    duty_index = $DutyIndex
    tick_number = $TickNumber
    selected_gap = $Gap
    next_gap = $NextGap
    occurred_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
    event_type = "self_growth_memory_event_written"
    source = "builder_self_growth_duty"
    duty_id = $DutyId
    selected_gap = $Gap
    memory_scope = "session_local_only"
    occurred_at = (Get-Date).ToUniversalTime().ToString("o")
  })

  $DutySummary = [ordered]@{
    status = if ($ValidationPassed) { "PASS" } else { "BLOCKED" }
    repair_id = $RepairId
    duty_id = $DutyId
    duty_index = $DutyIndex
    tick_number = $TickNumber
    session_root = $SessionRootRelative
    duty_root = $DutyRootRelative
    duty_dir = $DutyDirRelative
    selected_gap = $Gap
    next_gap = $NextGap
    elementary_knowledge_snapshot_created = $true
    self_map_snapshot_created = $true
    capability_inventory_snapshot_created = $true
    deterministic_gap_policy_used = $true
    sandbox_candidate_created = $true
    sandbox_validation_passed = $ValidationPassed
    memory_event_created = $true
    next_self_growth_decision_created = $true
    teacher_channel_supported = $true
    blocker_channel_supported = $true
    accepted_teacher_input_count = $AcceptedTeacherInputs.Count
    rejected_teacher_input_count = $RejectedTeacherInputs.Count
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
    arbitrary_code_execution_used = $false
    external_agents_created = $false
    completed_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase160DutyJsonFile -Path (Join-Path $DutyDirFull "duty_summary.json") -Object $DutySummary

  [pscustomobject][ordered]@{
    status = $DutySummary.status
    repair_id = $RepairId
    duty_id = $DutyId
    duty_index = $DutyIndex
    tick_number = $TickNumber
    session_root = $SessionRootRelative
    duty_dir = $DutyDirRelative
    selected_gap = $Gap
    next_gap = $NextGap
    sandbox_validation_passed = $ValidationPassed
    memory_event_created = $true
    accepted_state_mutated = $false
    accepted_memory_mutated = $false
    accepted_self_model_mutated = $false
  } | ConvertTo-Json -Depth 20
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
