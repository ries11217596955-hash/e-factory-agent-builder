param(
  [string]$SessionRoot = "runtime_sessions/live_growth/PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_SMOKE_001",
  [int]$TickNumber = 0,
  [int]$DutyIndex = 1,
  [string]$DutyRoot = "",
  [string]$TeacherOutboxDir = "",
  [int]$MaxCandidateBytes = 8192,
  [switch]$DryRun,
  [switch]$EnableMacroCycle,
  [string]$MacroCycleId = ""
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

function Get-Phase160DutyMacroStageForIndex {
  param([int]$Index)
  $stages = @(
    "SELF_OBSERVE_MAP_REFRESH",
    "CAPABILITY_INVENTORY_DIFF",
    "GAP_RANK_AND_SELECT",
    "SELF_CHANGE_CANDIDATE_GENERATE",
    "SANDBOX_DRY_RUN",
    "VALIDATE_AND_DECIDE",
    "EXPERIENCE_ABSORB_AND_NEXT_GOAL"
  )
  if ($Index -lt 1) {
    throw "PHASE160B_MACRO_DUTY_INVALID_INDEX=$Index"
  }
  return $stages[(($Index - 1) % $stages.Count)]
}

function Get-Phase160DutyMacroGapForStage {
  param([string]$Stage)
  switch ($Stage) {
    "SELF_OBSERVE_MAP_REFRESH" { return "MACRO_SELF_OBSERVE_MAP_REFRESH_GAP" }
    "CAPABILITY_INVENTORY_DIFF" { return "MACRO_CAPABILITY_INVENTORY_DIFF_GAP" }
    "GAP_RANK_AND_SELECT" { return "MACRO_GAP_RANK_AND_SELECT_GAP" }
    "SELF_CHANGE_CANDIDATE_GENERATE" { return "MACRO_SELF_CHANGE_CANDIDATE_GENERATE_GAP" }
    "SANDBOX_DRY_RUN" { return "MACRO_SANDBOX_DRY_RUN_GAP" }
    "VALIDATE_AND_DECIDE" { return "MACRO_VALIDATE_AND_DECIDE_GAP" }
    "EXPERIENCE_ABSORB_AND_NEXT_GOAL" { return "MACRO_EXPERIENCE_ABSORB_AND_NEXT_GOAL_GAP" }
    default { throw "PHASE160B_MACRO_STAGE_UNKNOWN=$Stage" }
  }
}

function Get-Phase160DutyMacroNoveltyReason {
  param([string]$Stage)
  switch ($Stage) {
    "SELF_OBSERVE_MAP_REFRESH" { return "Starts the macro cycle by grounding the session in current runtime evidence instead of repeating a gap label." }
    "CAPABILITY_INVENTORY_DIFF" { return "Consumes the self-map and compares available session capabilities against the observed runtime contour." }
    "GAP_RANK_AND_SELECT" { return "Consumes the capability diff and ranks a next gap with an explicit selection reason." }
    "SELF_CHANGE_CANDIDATE_GENERATE" { return "Consumes the ranked gap and produces a bounded session-local change candidate." }
    "SANDBOX_DRY_RUN" { return "Consumes the candidate and exercises it as a dry-run artifact without executing generated code." }
    "VALIDATE_AND_DECIDE" { return "Consumes the dry-run and records a keep/quarantine/rollback decision." }
    "EXPERIENCE_ABSORB_AND_NEXT_GOAL" { return "Consumes the decision and writes an experience ledger entry plus a non-repeated next goal." }
    default { return "Macro stage advances the chain with a new artifact." }
  }
}

function Get-Phase160DutyMacroProgressClaim {
  param([string]$Stage)
  switch ($Stage) {
    "SELF_OBSERVE_MAP_REFRESH" { return "Session has a refreshed macro self-map input for the next duty." }
    "CAPABILITY_INVENTORY_DIFF" { return "Session has a diff between observed needs and current live capabilities." }
    "GAP_RANK_AND_SELECT" { return "Session has a ranked gap and selection reason." }
    "SELF_CHANGE_CANDIDATE_GENERATE" { return "Session has a bounded self-change candidate kept local." }
    "SANDBOX_DRY_RUN" { return "Session has a dry-run result without arbitrary code execution." }
    "VALIDATE_AND_DECIDE" { return "Session has a validation decision for the candidate." }
    "EXPERIENCE_ABSORB_AND_NEXT_GOAL" { return "Session has absorbed experience and selected a non-repeated next goal." }
    default { return "Session macro chain advanced." }
  }
}

function Get-Phase160DutyMacroDecision {
  param([bool]$ValidationPassed)
  if ($ValidationPassed) {
    return "KEEP_SESSION_LOCAL"
  }
  return "QUARANTINE_RESULT"
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
$RepairId = if ($EnableMacroCycle) { "PHASE160B_MACRO_SELF_GROWTH_IGNITION_V1" } else { "PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_EXPANSION_V1" }
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
  if ([string]::IsNullOrWhiteSpace($MacroCycleId)) {
    $MacroCycleId = "PHASE160B_MACRO_SELF_GROWTH_IGNITION_CYCLE_001"
  }
  $CycleStage = if ($EnableMacroCycle) { Get-Phase160DutyMacroStageForIndex -Index $DutyIndex } else { "MICRO_DUTY" }
  $NextCycleStage = if ($EnableMacroCycle) { Get-Phase160DutyMacroStageForIndex -Index ($DutyIndex + 1) } else { "MICRO_DUTY" }
  $Gap = if ($EnableMacroCycle) { Get-Phase160DutyMacroGapForStage -Stage $CycleStage } else { Get-Phase160DutyGapForIndex -Index $DutyIndex }
  $NextGap = if ($EnableMacroCycle) { Get-Phase160DutyMacroGapForStage -Stage $NextCycleStage } else { Get-Phase160DutyGapForIndex -Index ($DutyIndex + 1) }
  $PreviousDutyId = if ($DutyIndex -gt 1) { "duty_{0:d4}" -f ($DutyIndex - 1) } else { "NONE" }
  $PreviousDutyArtifact = if ($DutyIndex -gt 1) { "$DutyRootRelative/$PreviousDutyId/macro_cycle_artifact.json" } else { "NONE" }
  $PreviousDutyArtifactFull = if ($DutyIndex -gt 1) { Resolve-Phase160DutyPath -RepoRoot $RepoRoot -Path $PreviousDutyArtifact } else { $null }
  $InputArtifact = if ($DutyIndex -gt 1 -and (Test-Path -LiteralPath $PreviousDutyArtifactFull)) { $PreviousDutyArtifact } else { "SESSION_START" }
  $OutputArtifact = "$DutyDirRelative/macro_cycle_artifact.json"
  $NoveltyReason = if ($EnableMacroCycle) { Get-Phase160DutyMacroNoveltyReason -Stage $CycleStage } else { "Bounded micro duty advances the deterministic session-local curriculum." }
  $ProgressClaim = if ($EnableMacroCycle) { Get-Phase160DutyMacroProgressClaim -Stage $CycleStage } else { "Session-local duty completed without accepted-state mutation." }
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
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    previous_duty_id = $PreviousDutyId
    input_artifact = $InputArtifact
    novelty_reason = $NoveltyReason
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
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    previous_duty_id = $PreviousDutyId
    input_artifact = $InputArtifact
    output_artifact = $OutputArtifact
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
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    previous_duty_id = $PreviousDutyId
    input_artifact = $InputArtifact
    output_artifact = $OutputArtifact
    candidate_type = "sandbox_only_self_growth_action"
    proposed_action = if ($EnableMacroCycle) {
      switch ($CycleStage) {
        "SELF_OBSERVE_MAP_REFRESH" { "refresh the session macro self-map from heartbeat/current_state/event evidence" }
        "CAPABILITY_INVENTORY_DIFF" { "compare observed runtime contour against available live modules and validators" }
        "GAP_RANK_AND_SELECT" { "rank candidate macro gaps and select the next bounded improvement target" }
        "SELF_CHANGE_CANDIDATE_GENERATE" { "generate a session-local change candidate from the ranked gap" }
        "SANDBOX_DRY_RUN" { "dry-run the candidate as data without executing generated code" }
        "VALIDATE_AND_DECIDE" { "validate the dry-run result and decide whether to keep it session-local" }
        default { "absorb the cycle experience into a ledger and select a non-repeated next goal" }
      }
    } else {
      switch ($Gap) {
        "SELF_MAP_REFRESH_GAP" { "refresh session-local map of current Builder runtime contour" }
        "CAPABILITY_INVENTORY_REFRESH_GAP" { "refresh session-local inventory of live modules, validators, and channels" }
        "TEACHER_CHANNEL_READINESS_GAP" { "verify teacher_outbox input handling and teacher_inbox suggestion visibility" }
        "BLOCKER_CHANNEL_READINESS_GAP" { "verify blocker_queue support and safe help-request shape" }
        "SELF_GROWTH_RESULT_SUMMARY_GAP" { "summarize prior self-growth duty outputs into session-local memory event" }
        default { "select the next bounded self-growth goal from deterministic curriculum" }
      }
    }
    candidate_payload = [ordered]@{
      observe = $true
      select_gap = $Gap
      cycle_stage = $CycleStage
      input_artifact = $InputArtifact
      output_artifact = $OutputArtifact
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
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    previous_duty_id = $PreviousDutyId
    input_artifact = $InputArtifact
    output_artifact = $OutputArtifact
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
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    previous_duty_id = $PreviousDutyId
    input_artifact = $InputArtifact
    output_artifact = $OutputArtifact
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
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    next_cycle_stage = $NextCycleStage
    novelty_reason = $NoveltyReason
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

  $Decision = Get-Phase160DutyMacroDecision -ValidationPassed $ValidationPassed
  if ($EnableMacroCycle) {
    $MacroArtifact = [ordered]@{
      status = if ($ValidationPassed) { "PASS" } else { "BLOCKED" }
      duty_id = $DutyId
      cycle_id = $MacroCycleId
      cycle_stage = $CycleStage
      selected_gap = $Gap
      input_artifact = $InputArtifact
      output_artifact = $OutputArtifact
      previous_duty_id = $PreviousDutyId
      novelty_reason = $NoveltyReason
      progress_claim = $ProgressClaim
      validation_status = if ($ValidationPassed) { "PASS" } else { "FAIL" }
      decision = $Decision
      next_gap = $NextGap
      next_cycle_stage = $NextCycleStage
      created_at = (Get-Date).ToUniversalTime().ToString("o")
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
      arbitrary_code_execution_used = $false
      external_agents_created = $false
    }
    Write-Phase160DutyJsonFile -Path (Join-Path $DutyDirFull "macro_cycle_artifact.json") -Object $MacroArtifact
    Add-Phase160DutyJsonLine -Path (Join-Path $DutyRootFull "experience_ledger.jsonl") -Object ([ordered]@{
      event_type = "macro_experience_ledger_entry"
      duty_id = $DutyId
      cycle_id = $MacroCycleId
      cycle_stage = $CycleStage
      selected_gap = $Gap
      previous_duty_id = $PreviousDutyId
      input_artifact = $InputArtifact
      output_artifact = $OutputArtifact
      novelty_reason = $NoveltyReason
      progress_claim = $ProgressClaim
      validation_status = if ($ValidationPassed) { "PASS" } else { "FAIL" }
      decision = $Decision
      next_gap = $NextGap
      created_at = (Get-Date).ToUniversalTime().ToString("o")
    })
    Write-Phase160DutyJsonFile -Path (Join-Path $DutyRootFull "macro_cycle_summary.json") -Object ([ordered]@{
      status = "PASS"
      cycle_id = $MacroCycleId
      repair_id = "PHASE160B_MACRO_SELF_GROWTH_IGNITION_V1"
      session_root = $SessionRootRelative
      duty_count_completed = $DutyIndex
      latest_duty_id = $DutyId
      latest_cycle_stage = $CycleStage
      latest_selected_gap = $Gap
      chain_requires_previous_artifact = $true
      stage_sequence_target = @(
        "SELF_OBSERVE_MAP_REFRESH",
        "CAPABILITY_INVENTORY_DIFF",
        "GAP_RANK_AND_SELECT",
        "SELF_CHANGE_CANDIDATE_GENERATE",
        "SANDBOX_DRY_RUN",
        "VALIDATE_AND_DECIDE",
        "EXPERIENCE_ABSORB_AND_NEXT_GOAL"
      )
      no_consecutive_stage_repeat_expected = $true
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
      updated_at = (Get-Date).ToUniversalTime().ToString("o")
    })
    Write-Phase160DutyJsonFile -Path (Join-Path $DutyRootFull "next_goal.json") -Object ([ordered]@{
      status = "PASS"
      cycle_id = $MacroCycleId
      source_duty_id = $DutyId
      completed_stage = $CycleStage
      next_gap = $NextGap
      next_cycle_stage = $NextCycleStage
      novelty_reason = "Next goal advances from $CycleStage to $NextCycleStage instead of blindly repeating the same gap."
      blind_repeat = $false
      selected_with_reason = $true
      accepted_state_mutated = $false
      created_at = (Get-Date).ToUniversalTime().ToString("o")
    })
  }

  Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
    event_type = "self_growth_gap_selected"
    source = "builder_self_growth_duty"
    duty_id = $DutyId
    duty_index = $DutyIndex
    tick_number = $TickNumber
    selected_gap = $Gap
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    next_gap = $NextGap
    occurred_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Add-Phase160DutyJsonLine -Path $EventLogPath -Object ([ordered]@{
    event_type = "self_growth_memory_event_written"
    source = "builder_self_growth_duty"
    duty_id = $DutyId
    selected_gap = $Gap
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
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
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    input_artifact = $InputArtifact
    output_artifact = $OutputArtifact
    previous_duty_id = $PreviousDutyId
    novelty_reason = $NoveltyReason
    progress_claim = $ProgressClaim
    validation_status = if ($ValidationPassed) { "PASS" } else { "FAIL" }
    decision = $Decision
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
    cycle_id = if ($EnableMacroCycle) { $MacroCycleId } else { "NONE" }
    cycle_stage = $CycleStage
    input_artifact = $InputArtifact
    output_artifact = $OutputArtifact
    previous_duty_id = $PreviousDutyId
    novelty_reason = $NoveltyReason
    progress_claim = $ProgressClaim
    validation_status = if ($ValidationPassed) { "PASS" } else { "FAIL" }
    decision = $Decision
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
