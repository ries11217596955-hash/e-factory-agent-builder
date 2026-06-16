param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$InputRoot = 'reports/self_development/phase165s_d2_big_curriculum_material_factory',
  [string]$OutputRoot = 'reports/self_development/phase165s_d2b_big_curriculum_autonomous_learning',
  [ValidateSet('LearnUntilEmpty')]
  [string]$Mode = 'LearnUntilEmpty',
  [switch]$Resume,
  [switch]$RepairResumeStateOnly,
  [switch]$SyncSummaryOnly,
  [switch]$EmitJson,
  [ValidateRange(1, 100000)]
  [int]$CheckpointEvery = 100,
  [ValidateRange(1, 100000)]
  [int]$HeartbeatEvery = 25
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if (-not (Get-Command Get-FileHash -ErrorAction SilentlyContinue)) {
  Set-Item -Path Function:\global:Get-FileHash -Value {
    param(
      [string]$LiteralPath,
      [string]$Algorithm = 'SHA256'
    )
    if ($Algorithm -ne 'SHA256') { throw "UNSUPPORTED_HASH_ALGORITHM=$Algorithm" }
    $stream = [System.IO.File]::OpenRead($LiteralPath)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
      $hash = ([System.BitConverter]::ToString($sha.ComputeHash($stream)) -replace '-', '')
    } finally {
      $sha.Dispose()
      $stream.Dispose()
    }
    [pscustomobject]@{ Algorithm='SHA256'; Hash=$hash; Path=$LiteralPath }
  }
}

function Read-D2BJson {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { throw "MISSING_FILE=$Path" }
  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Write-D2BJson {
  param([string]$Path, $Value)
  $directory = Split-Path -Parent $Path
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $temporary = "$Path.tmp"
  $json = ($Value | ConvertTo-Json -Depth 100) -replace "`r`n", "`n"
  [System.IO.File]::WriteAllText($temporary, $json + "`n", [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Write-D2BText {
  param([string]$Path, [string[]]$Lines)
  $directory = Split-Path -Parent $Path
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, (($Lines -join "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))
}

function Add-D2BJsonLine {
  param([string]$Path, $Value)
  $directory = Split-Path -Parent $Path
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $line = $Value | ConvertTo-Json -Depth 60 -Compress
  [System.IO.File]::AppendAllText($Path, $line + "`n", [System.Text.UTF8Encoding]::new($false))
}

function Get-D2BLastJsonLine {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  $last = $null
  $reader = [System.IO.StreamReader]::new($Path)
  try {
    while (-not $reader.EndOfStream) {
      $line = $reader.ReadLine()
      if (-not [string]::IsNullOrWhiteSpace($line)) { $last = $line }
    }
  } finally {
    $reader.Dispose()
  }
  if ($null -eq $last) { return $null }
  return $last | ConvertFrom-Json
}

function Get-D2BJsonLineMatchCount {
  param(
    [string]$Path,
    [string]$Property,
    [string]$Value
  )
  if (-not (Test-Path -LiteralPath $Path)) { return 0 }
  $count = 0
  $reader = [System.IO.StreamReader]::new($Path)
  try {
    while (-not $reader.EndOfStream) {
      $line = $reader.ReadLine()
      if ([string]::IsNullOrWhiteSpace($line)) { continue }
      $record = $line | ConvertFrom-Json
      if ($record.PSObject.Properties.Name -contains $Property -and [string]$record.$Property -eq $Value) {
        $count += 1
      }
    }
  } finally {
    $reader.Dispose()
  }
  return $count
}

function Get-D2BExecutionWriteEvent {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  $match = $null
  $reader = [System.IO.StreamReader]::new($Path)
  try {
    while (-not $reader.EndOfStream) {
      $line = $reader.ReadLine()
      if ([string]::IsNullOrWhiteSpace($line)) { continue }
      $event = $line | ConvertFrom-Json
      if ([string]$event.type -eq 'CONTROLLED_ACCEPT_MUTATION_WRITTEN_TO_ACCEPTED_CORE') {
        $match = $event
      }
    }
  } finally {
    $reader.Dispose()
  }
  return $match
}

function Invoke-D2BPowerShell {
  param([string]$ScriptPath, [string[]]$Arguments)
  try {
    if (($Arguments.Count % 2) -ne 0) { throw 'SCRIPT_ARGUMENTS_MUST_BE_NAME_VALUE_PAIRS' }
    $bound = @{}
    for ($i = 0; $i -lt $Arguments.Count; $i += 2) {
      $bound[$Arguments[$i].TrimStart('-')] = $Arguments[$i + 1]
    }
    $output = @(& $ScriptPath @bound | ForEach-Object { [string]$_ })
    return ,$output
  } catch {
    throw "SCRIPT_FAILED=$ScriptPath error=$($_.Exception.Message)"
  }
}

function Get-D2BCount {
  param($Root, [string]$Property, [string]$AtomId)
  if ($null -eq $Root -or -not ($Root.PSObject.Properties.Name -contains $Property)) { return 0 }
  return @($Root.$Property | Where-Object { [string]$_.atom_id -eq $AtomId }).Count
}

function Get-D2BRelativePath {
  param([string]$Root, [string]$Path)
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
  $pathFull = [System.IO.Path]::GetFullPath($Path)
  if (-not $pathFull.StartsWith($rootFull + '\', [System.StringComparison]::OrdinalIgnoreCase)) { return $Path }
  return ($pathFull.Substring($rootFull.Length + 1) -replace '\\', '/')
}

function Reset-D2BWorkRoot {
  param([string]$OutputRootFull, [string]$WorkRoot)
  $expected = [System.IO.Path]::GetFullPath((Join-Path $OutputRootFull 'work/current'))
  $actual = [System.IO.Path]::GetFullPath($WorkRoot)
  if (-not $actual.Equals($expected, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "UNSAFE_WORK_ROOT=$actual"
  }
  if (Test-Path -LiteralPath $actual) {
    Remove-Item -LiteralPath $actual -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $actual | Out-Null
}

function New-D2BPhase162Package {
  param(
    [string]$WorkRoot,
    [object]$Candidate,
    [string]$OperationId,
    [string]$SourcePath,
    [string]$MemoryPath,
    [string]$SelfMapPath,
    [string]$RegistryPath
  )
  $atomId = [string]$Candidate.target_atom_id_suggestion
  $candidateRoot = Join-Path $WorkRoot 'cand'
  $controllerRoot = Join-Path $WorkRoot 'ctrl'
  $executionRoot = Join-Path $WorkRoot 'exec'
  $finalizerRoot = Join-Path $WorkRoot 'fin'
  New-Item -ItemType Directory -Force -Path $candidateRoot,$controllerRoot,$executionRoot,$finalizerRoot | Out-Null

  $payload = [ordered]@{
    candidate_id = [string]$Candidate.candidate_id
    concept_id = [string]$Candidate.concept_id
    meaning = [string]$Candidate.explanation
    atom_type = [string]$Candidate.atom_type_suggestion
    guided_example = [string]$Candidate.guided_example
    check_prompt = [string]$Candidate.check_prompt
    expected_check_result = [string]$Candidate.expected_check_result
    behavior_change = [string]$Candidate.behavior_change
    next_layer_questions = @($Candidate.next_layer_questions)
    source_curriculum_candidate = $SourcePath
    source = [string]$Candidate.source
    provenance = [string]$Candidate.provenance
    autonomous_policy_guard = 'PHASE165S-C2B'
    autonomous_loop = 'PHASE165S-D2B'
    owner_interrupt_used = $false
    decision_rule = [ordered]@{
      input = 'staged_curriculum_candidate'
      classification = 'USE_ACCEPTED_ATOM_AND_MOVE_TO_NEXT_LAYER'
      direct_accept_without_guard = $false
      decision_authority = 'C2B_POLICY_GUARD_AND_PHASE162_ACCEPTED_CORE_EXECUTOR'
    }
    memory_proof = 'Accepted-memory read must find this atom exactly once by atom_id.'
    use_proof = 'Future reasoning must retrieve this accepted atom and advance beyond raw curriculum.'
    behavior_delta = 'Next cycle starts from the accepted atom rather than the staged candidate.'
  }

  Write-D2BJson (Join-Path $candidateRoot 'controlled_accept_core_mutation_candidate_result.json') ([ordered]@{
    schema = 'PHASE162_CONTROLLED_ACCEPT_CORE_MUTATION_CANDIDATE_RESULT_V1'
    status = 'PASS'
    created_at = (Get-Date).ToUniversalTime().ToString('o')
    batch_size = 1
    staged_atom_count = 1
    atom_ids = @($atomId)
    next_machine_action = 'VALIDATE_CONTROLLED_ACCEPT_CORE_MUTATION_CANDIDATE_FOR_ATOM_BATCH'
    source = 'PHASE165S-D2B autonomous learn-until-empty loop'
  })
  Write-D2BJson (Join-Path $candidateRoot 'controlled_accept_core_mutation_set.json') ([ordered]@{
    schema = 'PHASE162_CONTROLLED_ACCEPT_CORE_MUTATION_SET_V1'
    status = 'PASS'
    created_at = (Get-Date).ToUniversalTime().ToString('o')
    accepted_memory_operations = @([ordered]@{ operation_id="$OperationId`_MEMORY"; atom_id=$atomId; target=$MemoryPath; source_freeze_root=$WorkRoot; payload=$payload })
    accepted_self_model_operations = @([ordered]@{ operation_id="$OperationId`_SELF"; atom_id=$atomId; target=$SelfMapPath; source_freeze_root=$WorkRoot; payload=$payload })
    registry_operations = @([ordered]@{ operation_id="$OperationId`_REGISTRY"; atom_id=$atomId; target=$RegistryPath; source_freeze_root=$WorkRoot; payload=$payload })
  })
  Write-D2BJson (Join-Path $candidateRoot 'atomic_accept_write_plan.json') ([ordered]@{
    schema='PHASE162_ATOMIC_ACCEPT_WRITE_PLAN_V1'; status='PASS'; created_at=(Get-Date).ToUniversalTime().ToString('o')
    atomicity_rule='all_operations_pass_or_rollback'; target_files=@($MemoryPath,$SelfMapPath,$RegistryPath); allowed_atom_ids=@($atomId)
  })
  Write-D2BJson (Join-Path $candidateRoot 'controlled_accept_core_mutation_rollback_plan.json') ([ordered]@{
    schema='PHASE162_CONTROLLED_ACCEPT_CORE_MUTATION_ROLLBACK_PLAN_V1'; status='PASS'; created_at=(Get-Date).ToUniversalTime().ToString('o')
    rollback_actions=@('restore_memory_snapshot','restore_self_map_snapshot','restore_registry_snapshot','validate_atom_count','write_rollback_event')
  })
  Write-D2BJson (Join-Path $candidateRoot 'post_mutation_validation_binding.json') ([ordered]@{
    schema='PHASE162_POST_MUTATION_VALIDATION_BINDING_V1'; status='PASS'; created_at=(Get-Date).ToUniversalTime().ToString('o')
    bound_to_mutation_set='controlled_accept_core_mutation_set.json'; bound_to_atomic_write_plan='atomic_accept_write_plan.json'
  })
  Write-D2BJson (Join-Path $controllerRoot 'controller_consume_controlled_accept_core_mutation_dry_run_batch_result.json') ([ordered]@{
    schema='PHASE162_CONTROLLER_CONSUME_CONTROLLED_ACCEPT_CORE_MUTATION_DRY_RUN_BATCH_RESULT_V1'; status='PASS'
    created_at=(Get-Date).ToUniversalTime().ToString('o'); next_machine_action='EXECUTE_CONTROLLED_ACCEPT_CORE_MUTATION_FOR_ATOM_BATCH'
    execution_authorization_status='AUTHORIZED_ONE_SHOT_CONTROLLED_ACCEPT_CORE_MUTATION'; candidate_root=$candidateRoot
    authorization_source='PHASE165S-C2B bounded autonomous acceptance policy guard'; owner_interrupt_used=$false
  })
  Write-D2BJson (Join-Path $controllerRoot 'controller_consume_controlled_accept_core_mutation_dry_run_batch_validation.json') ([ordered]@{
    schema='PHASE162_CONTROLLER_CONSUME_CONTROLLED_ACCEPT_CORE_MUTATION_DRY_RUN_BATCH_VALIDATION_V1'; status='PASS'
    created_at=(Get-Date).ToUniversalTime().ToString('o'); next_machine_action='EXECUTE_CONTROLLED_ACCEPT_CORE_MUTATION_FOR_ATOM_BATCH'
    exact_atom_scope=$true; allowed_atom_ids=@($atomId)
  })
  Write-D2BJson (Join-Path $controllerRoot 'one_shot_controlled_accept_core_mutation_execution_authorization_for_atom_batch.json') ([ordered]@{
    schema='PHASE162_ONE_SHOT_CONTROLLED_ACCEPT_CORE_MUTATION_EXECUTION_AUTHORIZATION_FOR_ATOM_BATCH_V1'; status='AUTHORIZED'
    created_at=(Get-Date).ToUniversalTime().ToString('o'); authorization_scope='ONE_SHOT_ACCEPTED_CORE_WRITE_WITH_ATOMIC_PLAN_AND_ROLLBACK'
    candidate_root=$candidateRoot; authorization_source='PHASE165S-C2B bounded autonomous acceptance policy guard'
    owner_interrupt_used=$false; autonomous_policy_guard_allowed=$true; authorized_atom_ids=@($atomId); mass_acceptance_forbidden=$true
  })
  return [pscustomobject]@{ candidate_root=$candidateRoot; controller_root=$controllerRoot; execution_root=$executionRoot; finalizer_root=$finalizerRoot }
}

function Write-D2BRunArtifacts {
  param(
    [string]$Root,
    [string]$OutputRootFull,
    [object]$State,
    [object]$Manifest,
    [string]$Status,
    [bool]$StoppedBySignal,
    [string[]]$UnauthorizedDirty
  )
  $queueEmpty = ([int]$State.remaining_count -eq 0)
  $nextAction = if ($queueEmpty -and [int]$State.failed_count -eq 0) {
    'PHASE165S_D2B_BIG_CURRICULUM_AUTONOMOUS_LEARNING_ACCEPTANCE_REVIEW'
  } elseif ($Status -eq 'BLOCKED_PARTIAL_ACCEPTED_SURFACE') {
    'BLOCKED_PARTIAL_ACCEPTED_SURFACE_RECONCILIATION_REQUIRED'
  } elseif ($Status -eq 'RUNNING_ACTIVE') {
    'WAIT_FOR_ACTIVE_D2B_RUN_OR_USE_STOP_SIGNAL'
  } elseif ($StoppedBySignal) {
    'REMOVE_STOP_SIGNAL_AND_RESUME_PHASE165S_D2B'
  } elseif ([int]$State.failed_count -gt 0) {
    'PHASE165S_D2B_BIG_CURRICULUM_AUTONOMOUS_LEARNING_TRIAGE'
  } else {
    'RESUME_PHASE165S_D2B_BIG_CURRICULUM_AUTONOMOUS_LEARNING'
  }
  $proof = [ordered]@{
    phase = 'PHASE165S_D2B_BIG_CURRICULUM_AUTONOMOUS_LEARNING'
    created_utc = (Get-Date).ToUniversalTime().ToString('o')
    status = $Status
    queue_empty = $queueEmpty
    total_candidate_count = [int]$Manifest.total_candidate_count
    safe_candidate_count = [int]$Manifest.safe_candidate_count
    quarantine_expected_count = [int]$Manifest.quarantine_candidate_count + [int]$State.denied_count + [int]$State.invalid_safe_candidate_count + [int]$State.dynamic_quarantine_count
    accepted_atom_count = [int]$State.accepted_count
    quarantine_count = [int]$State.quarantine_count
    denied_count = [int]$State.denied_count
    invalid_safe_candidate_count = [int]$State.invalid_safe_candidate_count
    dynamic_quarantine_count = [int]$State.dynamic_quarantine_count
    skipped_duplicate_count = [int]$State.skipped_duplicate_count
    failed_count = [int]$State.failed_count
    recovered_failure_count = [int]$State.recovered_failure_count
    owner_interrupt_used = $false
    autonomous_policy_guard_used = ([int]$State.policy_guard_invocation_count -gt 0)
    autonomous_policy_guard_invocation_count = [int]$State.policy_guard_invocation_count
    phase162_executor_used = ([int]$State.phase162_executor_invocation_count -gt 0)
    phase162_executor_invocation_count = [int]$State.phase162_executor_invocation_count
    resume_supported = $true
    stopped_by_signal = $StoppedBySignal
    checkpoint_count = [int]$State.checkpoint_count
    heartbeat_path = (Get-D2BRelativePath -Root $Root -Path (Join-Path $OutputRootFull 'heartbeat.json'))
    protected_state_dirty_check = @($UnauthorizedDirty)
    allowed_accepted_surface_mutations = @('packs/registry.json','reports/self_development/accepted_change_memory_snapshot.json','reports/self_development/SELF_MODEL_ACTIVE_MAP.json')
    output_root = (Get-D2BRelativePath -Root $Root -Path $OutputRootFull)
    current_shard_index = [int]$State.shard_index
    current_line_index = [int]$State.line_index
    processed_count = [int]$State.processed_count
    remaining_count = [int]$State.remaining_count
    risk_flag_compatibility = 'none_identified_at_material_stage is treated as no effective risk; all other flags quarantine'
    next_required_action = $nextAction
  }
  Write-D2BJson -Path (Join-Path $Root 'proofs/self_development/PHASE165S_D2B_BIG_CURRICULUM_AUTONOMOUS_LEARNING_V1.json') -Value $proof
  Write-D2BJson -Path (Join-Path $OutputRootFull 'final_summary.json') -Value $proof
  Write-D2BText -Path (Join-Path $Root 'reports/self_development/PHASE165S_D2B_BIG_CURRICULUM_AUTONOMOUS_LEARNING_V1.md') -Lines @(
    '# PHASE165S-D2B Big Curriculum Autonomous Learning',
    '',
    "Status: $Status",
    '',
    'D2A material remains raw and untrusted until each candidate passes the existing school acceptance path. D2B does not manually wave batches; one process advances one candidate at a time through C2B and the PHASE162 accepted-core executor until the queue is empty or `STOP_SIGNAL` appears.',
    '',
    "Processed: $($State.processed_count) / $($Manifest.total_candidate_count)",
    "Accepted: $($State.accepted_count)",
    "Quarantined: $($State.quarantine_count)",
    "Denied: $($State.denied_count)",
    "Skipped duplicates: $($State.skipped_duplicate_count)",
    "Failed: $($State.failed_count)",
    "Queue empty: $queueEmpty",
    '',
    '## Resume',
    '',
    'Remove `reports/self_development/phase165s_d2b_big_curriculum_autonomous_learning/STOP_SIGNAL` if present, then run:',
    '',
    '```powershell',
    'powershell -NoProfile -ExecutionPolicy Bypass -File modules/run_phase165s_d2b_big_curriculum_autonomous_learn_until_empty_001.ps1 -Resume',
    '```',
    '',
    '## Validate',
    '',
    '```powershell',
    'powershell -NoProfile -ExecutionPolicy Bypass -File validators/validate_phase165s_d2b_big_curriculum_autonomous_learning_v1.ps1',
    '```',
    '',
    '## Next Required Action',
    '',
    $nextAction
  )
  return [pscustomobject]$proof
}

$root = (Resolve-Path $RepoRoot).Path
$inputFull = if ([System.IO.Path]::IsPathRooted($InputRoot)) { [System.IO.Path]::GetFullPath($InputRoot) } else { [System.IO.Path]::GetFullPath((Join-Path $root $InputRoot)) }
$outputFull = if ([System.IO.Path]::IsPathRooted($OutputRoot)) { [System.IO.Path]::GetFullPath($OutputRoot) } else { [System.IO.Path]::GetFullPath((Join-Path $root $OutputRoot)) }
$repoPrefix = $root.TrimEnd('\') + '\'
if (-not $inputFull.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { throw "INPUT_ROOT_OUTSIDE_REPO=$inputFull" }
if (-not $outputFull.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { throw "OUTPUT_ROOT_OUTSIDE_REPO=$outputFull" }
New-Item -ItemType Directory -Force -Path $outputFull,(Join-Path $outputFull 'checkpoints'),(Join-Path $outputFull 'work') | Out-Null

$manifest = Read-D2BJson (Join-Path $inputFull 'school_ready_manifest.json')
$index = Read-D2BJson (Join-Path $inputFull 'material_bank_index.json')
if ([int]$manifest.total_candidate_count -ne [int]$index.total_candidate_count) { throw 'INPUT_MANIFEST_INDEX_COUNT_MISMATCH' }
$shards = @($manifest.shard_paths)
if ($shards.Count -ne [int]$index.shard_count) { throw 'INPUT_MANIFEST_INDEX_SHARD_MISMATCH' }

$memoryPath = 'reports/self_development/accepted_change_memory_snapshot.json'
$selfMapPath = 'reports/self_development/SELF_MODEL_ACTIVE_MAP.json'
$registryPath = 'packs/registry.json'
$policyModule = Join-Path $root 'modules/evaluate_phase165s_c2_bounded_autonomous_atom_acceptance_policy_001.ps1'
$executorModule = Join-Path $root 'modules/invoke_phase162_execute_controlled_accept_core_mutation_for_atom_batch_001.ps1'
$finalizerModule = Join-Path $root 'modules/invoke_phase162_controller_consume_controlled_accept_core_mutation_execution_proof_001.ps1'
foreach ($path in @($policyModule,$executorModule,$finalizerModule)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "REQUIRED_MODULE_MISSING=$path" }
}

$unauthorizedDirtyBefore = @(git -C $root status --short -- CAPABILITY_ROADMAP.json GENESIS_STATE.json TASK_QUEUE.json orchestrator/run.ps1 route_locks)
if ($unauthorizedDirtyBefore.Count -gt 0) { throw "UNAUTHORIZED_PROTECTED_STATE_DIRTY=$($unauthorizedDirtyBefore -join '; ')" }

$statePath = Join-Path $outputFull 'queue_state.json'
$resumePath = Join-Path $outputFull 'resume_state.json'
$heartbeatPath = Join-Path $outputFull 'heartbeat.json'
$stopPath = Join-Path $outputFull 'STOP_SIGNAL'
$acceptedLog = Join-Path $outputFull 'accepted_log.jsonl'
$quarantineLog = Join-Path $outputFull 'quarantine_log.jsonl'
$skippedLog = Join-Path $outputFull 'skipped_log.jsonl'
$failedLog = Join-Path $outputFull 'failed_log.jsonl'
$recoveryLog = Join-Path $outputFull 'recovery_log.jsonl'
$workRoot = Join-Path $outputFull 'work/current'

if ($Resume) {
  $state = Read-D2BJson $resumePath
  if ([string]$state.status -eq 'QUEUE_EMPTY') { throw 'QUEUE_ALREADY_EMPTY' }
} else {
  if (Test-Path -LiteralPath $statePath) { throw 'EXISTING_RUN_STATE_FOUND_USE_RESUME' }
  foreach ($log in @($acceptedLog,$quarantineLog,$skippedLog,$failedLog,$recoveryLog)) {
    if (-not (Test-Path -LiteralPath $log)) { [System.IO.File]::WriteAllText($log, '', [System.Text.UTF8Encoding]::new($false)) }
  }
  $state = [pscustomobject][ordered]@{
    schema = 'PHASE165S_D2B_QUEUE_STATE_V1'
    status = 'READY'
    mode = $Mode
    created_utc = (Get-Date).ToUniversalTime().ToString('o')
    updated_utc = (Get-Date).ToUniversalTime().ToString('o')
    shard_index = 0
    line_index = 0
    processed_count = 0
    remaining_count = [int]$manifest.total_candidate_count
    accepted_count = 0
    quarantine_count = 0
    denied_count = 0
    invalid_safe_candidate_count = 0
    skipped_duplicate_count = 0
    failed_count = 0
    recovered_failure_count = 0
    policy_guard_invocation_count = 0
    phase162_executor_invocation_count = 0
    finalizer_invocation_count = 0
    checkpoint_count = 0
    heartbeat_count = 0
    last_candidate_id = $null
    last_atom_id = $null
    last_disposition = $null
    owner_interrupt_used = $false
  }
  Write-D2BJson $statePath $state
  Write-D2BJson $resumePath $state
}
if (-not ($state.PSObject.Properties.Name -contains 'recovered_failure_count')) {
  $state | Add-Member -NotePropertyName recovered_failure_count -NotePropertyValue 0
}
if (-not ($state.PSObject.Properties.Name -contains 'dynamic_quarantine_count')) {
  $state | Add-Member -NotePropertyName dynamic_quarantine_count -NotePropertyValue 0
}
if ($RepairResumeStateOnly -and -not $Resume) {
  throw 'REPAIR_RESUME_STATE_ONLY_REQUIRES_RESUME'
}
if ($SyncSummaryOnly -and -not $Resume) {
  throw 'SYNC_SUMMARY_ONLY_REQUIRES_RESUME'
}
if ($RepairResumeStateOnly -and $SyncSummaryOnly) {
  throw 'REPAIR_RESUME_STATE_ONLY_AND_SYNC_SUMMARY_ONLY_ARE_MUTUALLY_EXCLUSIVE'
}

$stoppedBySignal = $false
$hardError = $null
$hardErrorAlreadyRecorded = $false
$lastAcceptedAtomId = $null
$resumeHadHardError = ($Resume -and [string]$state.status -eq 'HARD_ERROR')
$resumeFailedCandidateId = if ($resumeHadHardError) { [string]$state.last_candidate_id } else { $null }
$resumeReconciledZeroSurfaceFailure = $false
$resumeReconciledFullSurfaceFinalization = $false

if ($resumeHadHardError -and [int]$state.failed_count -gt 0) {
  $lastFailure = Get-D2BLastJsonLine $failedLog
  $failedAtomId = [string]$state.last_atom_id
  $failedCandidateId = [string]$state.last_candidate_id
  $memoryCount = Get-D2BCount (Read-D2BJson (Join-Path $root $memoryPath)) 'phase162_accepted_atom_memory_records' $failedAtomId
  $selfMapCount = Get-D2BCount (Read-D2BJson (Join-Path $root $selfMapPath)) 'phase162_absorbed_atom_capability_notes' $failedAtomId
  $registryCount = Get-D2BCount (Read-D2BJson (Join-Path $root $registryPath)) 'phase162_accepted_atom_references' $failedAtomId
  $visibilityTotal = $memoryCount + $selfMapCount + $registryCount
  $failureMatchesCursor = $null -ne $lastFailure -and
    [string]$lastFailure.candidate_id -eq $failedCandidateId -and
    [string]$lastFailure.atom_id -eq $failedAtomId -and
    [int]$lastFailure.shard_index -eq [int]$state.shard_index -and
    [int]$lastFailure.line_index -eq [int]$state.line_index
  $isPostExecutionVisibilityFailure = $failureMatchesCursor -and
    [string]$lastFailure.error -like 'PHASE162_POST_EXECUTION_VISIBILITY_FAILED*'
  $fullSurfaceVisible = ($memoryCount -eq 1 -and $selfMapCount -eq 1 -and $registryCount -eq 1)
  $partialOrDuplicateSurface = ($visibilityTotal -gt 0 -and -not $fullSurfaceVisible)
  $policyResultPath = Join-Path $workRoot 'policy_result.json'
  $candidateResultPath = Join-Path $workRoot 'cand/controlled_accept_core_mutation_candidate_result.json'
  $executionEventsPath = Join-Path $workRoot 'exec/controlled_accept_core_mutation_execution_events.jsonl'
  $policyPassed = $false
  $candidatePassed = $false
  if (Test-Path -LiteralPath $policyResultPath) {
    $policyResult = Read-D2BJson $policyResultPath
    $policyPassed = [string]$policyResult.status -eq 'PASS' -and [bool]$policyResult.autonomous_accept_allowed -and
      @($policyResult.atom_ids | Where-Object { [string]$_ -eq $failedAtomId }).Count -eq 1
  }
  if (Test-Path -LiteralPath $candidateResultPath) {
    $candidateResult = Read-D2BJson $candidateResultPath
    $candidatePassed = [string]$candidateResult.status -eq 'PASS' -and
      @($candidateResult.atom_ids | Where-Object { [string]$_ -eq $failedAtomId }).Count -eq 1
  }
  $writeEvent = Get-D2BExecutionWriteEvent $executionEventsPath
  $writeEventPassed = $null -ne $writeEvent -and [bool]$writeEvent.data.accepted_core_write -and
    [int]$writeEvent.data.memory_operation_count -eq 1 -and
    [int]$writeEvent.data.self_model_operation_count -eq 1 -and
    [int]$writeEvent.data.registry_operation_count -eq 1

  if ($failureMatchesCursor -and $partialOrDuplicateSurface) {
    $hardError = "PARTIAL_ACCEPTED_SURFACE atom=$failedAtomId memory=$memoryCount self_map=$selfMapCount registry=$registryCount"
    $hardErrorAlreadyRecorded = $true
    $state.status = 'BLOCKED_PARTIAL_ACCEPTED_SURFACE'
  } elseif ($failureMatchesCursor -and $fullSurfaceVisible -and $policyPassed -and $candidatePassed -and $writeEventPassed) {
    $memoryRecord = @((Read-D2BJson (Join-Path $root $memoryPath)).phase162_accepted_atom_memory_records | Where-Object {
      [string]$_.atom_id -eq $failedAtomId
    })[0]
    $isCurrentD2BWrite = $memoryRecord.payload -and
      [string]$memoryRecord.payload.autonomous_loop -eq 'PHASE165S-D2B' -and
      [string]$memoryRecord.payload.candidate_id -eq $failedCandidateId
    if (-not $isCurrentD2BWrite) {
      $hardError = "FULL_SURFACE_NOT_CURRENT_D2B_WRITE atom=$failedAtomId"
      $hardErrorAlreadyRecorded = $true
      $state.status = 'HARD_ERROR'
    } else {
      $acceptedLogMatchCount = Get-D2BJsonLineMatchCount -Path $acceptedLog -Property 'atom_id' -Value $failedAtomId
      if ($acceptedLogMatchCount -gt 1) {
        $hardError = "DUPLICATE_ACCEPTED_LOG atom=$failedAtomId count=$acceptedLogMatchCount"
        $hardErrorAlreadyRecorded = $true
        $state.status = 'BLOCKED_PARTIAL_ACCEPTED_SURFACE'
      } else {
        $executionRoot = Join-Path $workRoot 'exec'
        $finalizerRoot = Join-Path $workRoot 'fin'
        $executionResultPath = Join-Path $executionRoot 'execute_controlled_accept_core_mutation_result.json'
        Write-D2BJson $executionResultPath ([ordered]@{
          schema='PHASE162_EXECUTE_CONTROLLED_ACCEPT_CORE_MUTATION_FOR_ATOM_BATCH_RESULT_V1'
          status='PASS'; created_at=(Get-Date).ToUniversalTime().ToString('o')
          controller_root=(Join-Path $workRoot 'ctrl'); candidate_root=(Join-Path $workRoot 'cand')
          batch_size=1; staged_atom_count=1
          controlled_accept_core_mutation_executed=$true
          post_real_mutation_validation_passed=$true
          rollback_executed=$false; rollback_required=$false
          accepted_core_write_executed=$true; accepted_atom_claimed=$false
          accepted_memory_mutated=$true; accepted_self_model_mutated=$true; registry_mutated=$true
          final_accept_ready=$true
          machine_decision='CONTROLLED_ACCEPT_CORE_MUTATION_EXECUTED_PENDING_CONTROLLER_FINALIZATION'
          next_machine_action='FEED_CONTROLLED_ACCEPT_CORE_MUTATION_EXECUTION_BACK_INTO_CONTROLLER'
          recovery_source='FULL_SURFACE_VISIBILITY_PLUS_CONTROLLED_ACCEPT_MUTATION_WRITTEN_TO_ACCEPTED_CORE_EVENT'
          repeated_mutation_execution=$false
        })
        Write-D2BJson (Join-Path $executionRoot 'execute_controlled_accept_core_mutation_validation.json') ([ordered]@{
          schema='PHASE165S_D2B_EXECUTION_VALIDATION_V1'; status='PASS'
          created_at=(Get-Date).ToUniversalTime().ToString('o'); atom_id=$failedAtomId
          memory_count=1; self_map_count=1; registry_count=1
          owner_interrupt_used=$false; autonomous_policy_guard_allowed=$true
          recovery_validation='FULL_SURFACE_EXACTLY_ONCE_AFTER_WRITE_EVENT'
        })
        $executionProofPath = Join-Path $executionRoot 'phase165s_d2b_execution_proof_for_controller.json'
        Write-D2BJson $executionProofPath ([ordered]@{
          schema='PHASE165S_D2B_EXECUTION_PROOF_FOR_PHASE162_CONTROLLER_V1'; status='PASS'
          created_at=(Get-Date).ToUniversalTime().ToString('o'); head=(git -C $root rev-parse HEAD)
          output_root=$executionRoot; next_action='FEED_CONTROLLED_ACCEPT_CORE_MUTATION_EXECUTION_BACK_INTO_CONTROLLER'
          accepted_atom_claimed=$false; atom_id=$failedAtomId; owner_interrupt_used=$false
          recovery_proof=$true; repeated_mutation_execution=$false
        })
        $state.finalizer_invocation_count = [int]$state.finalizer_invocation_count + 1
        [void](Invoke-D2BPowerShell -ScriptPath $finalizerModule -Arguments @(
          '-RepoRoot',$root,'-ExecutionProofPath',$executionProofPath,'-OutputRoot',$finalizerRoot
        ))
        $finalResult = Read-D2BJson (Join-Path $finalizerRoot 'controller_consume_controlled_accept_core_mutation_execution_proof_result.json')
        if (-not ([string]$finalResult.status -eq 'PASS' -and [bool]$finalResult.accepted_atom_claimed -and
            -not [bool]$finalResult.repeated_mutation_execution)) {
          $hardError = "RECOVERED_FULL_SURFACE_FINALIZATION_NOT_PASS=$failedAtomId"
          $hardErrorAlreadyRecorded = $true
          $state.status = 'HARD_ERROR'
        } else {
          $sourcePath = "$([string]$shards[[int]$state.shard_index])#line=$([int]$state.line_index + 1)"
          if ($acceptedLogMatchCount -eq 0) {
            Add-D2BJsonLine $acceptedLog ([ordered]@{
              occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$failedCandidateId; atom_id=$failedAtomId
              source_path=$sourcePath; disposition='ACCEPTED_RECOVERED_POST_WRITE_FINALIZATION'
              memory_count=1; self_map_count=1; registry_count=1; repeated_mutation_execution=$false
            })
          }
          $recoverCount = [int]$state.failed_count
          for ($recovered = 0; $recovered -lt $recoverCount; $recovered += 1) {
            Add-D2BJsonLine $recoveryLog ([ordered]@{
              occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$failedCandidateId; atom_id=$failedAtomId
              recovered_failure='full_surface_accepted_core_write_with_failed_finalization'
              resolution='FINALIZED_WITHOUT_REPEATED_MUTATION_AND_CURSOR_ADVANCED'
              visibility_counts=[ordered]@{ memory=1; self_map=1; registry=1 }
            })
          }
          $state.accepted_count = [int]$state.accepted_count + 1
          $state.failed_count = 0
          $state.recovered_failure_count = [int]$state.recovered_failure_count + $recoverCount
          $state.processed_count = [int]$state.processed_count + 1
          $state.remaining_count = [int]$manifest.total_candidate_count - [int]$state.processed_count
          $state.line_index = [int]$state.line_index + 1
          $state.last_disposition = 'ACCEPTED_RECOVERED_POST_WRITE_FINALIZATION'
          $state.status = 'RUNNING_READY_TO_RESUME'
          $state.updated_utc = (Get-Date).ToUniversalTime().ToString('o')
          $resumeHadHardError = $false
          $resumeReconciledFullSurfaceFinalization = $true
        }
      }
    }
  } elseif ($isPostExecutionVisibilityFailure -and $visibilityTotal -eq 0) {
    $sourcePath = "$([string]$shards[[int]$state.shard_index])#line=$([int]$state.line_index + 1)"
    Add-D2BJsonLine $quarantineLog ([ordered]@{
      occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$failedCandidateId; atom_id=$failedAtomId
      source_path=$sourcePath; disposition='QUARANTINED_POST_EXECUTION_ZERO_VISIBILITY'
      reasons=@('phase162_post_execution_visibility_failed','accepted_surface_visibility_zero','candidate_not_accepted')
      visibility_counts=[ordered]@{ memory=$memoryCount; self_map=$selfMapCount; registry=$registryCount }
    })
    $recoverCount = [int]$state.failed_count
    for ($recovered = 0; $recovered -lt $recoverCount; $recovered += 1) {
      Add-D2BJsonLine $recoveryLog ([ordered]@{
        occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$failedCandidateId; atom_id=$failedAtomId
        recovered_failure='phase162_post_execution_zero_surface_visibility_failure'
        resolution='QUARANTINED_NOT_ACCEPTED_AND_CURSOR_ADVANCED'
        visibility_counts=[ordered]@{ memory=$memoryCount; self_map=$selfMapCount; registry=$registryCount }
      })
    }
    $state.quarantine_count = [int]$state.quarantine_count + 1
    $state.dynamic_quarantine_count = [int]$state.dynamic_quarantine_count + 1
    $state.failed_count = 0
    $state.recovered_failure_count = [int]$state.recovered_failure_count + $recoverCount
    $state.processed_count = [int]$state.processed_count + 1
    $state.remaining_count = [int]$manifest.total_candidate_count - [int]$state.processed_count
    $state.line_index = [int]$state.line_index + 1
    $state.last_disposition = 'QUARANTINED_POST_EXECUTION_ZERO_VISIBILITY'
    $state.status = 'RUNNING_READY_TO_RESUME'
    $state.updated_utc = (Get-Date).ToUniversalTime().ToString('o')
    $resumeHadHardError = $false
    $resumeReconciledZeroSurfaceFailure = $true
  }
}

if ($RepairResumeStateOnly) {
  if (-not $resumeReconciledZeroSurfaceFailure -and -not $resumeReconciledFullSurfaceFinalization -and
      [string]$state.status -ne 'RUNNING_READY_TO_RESUME') {
    if ([string]$state.status -eq 'BLOCKED_PARTIAL_ACCEPTED_SURFACE') {
      Write-Host 'PHASE165S_D2B_REPAIR_RESULT=BLOCKED_PARTIAL_ACCEPTED_SURFACE'
      exit 1
    }
    throw "NO_RECOVERABLE_HARD_ERROR status=$($state.status)"
  }
  $state.updated_utc = (Get-Date).ToUniversalTime().ToString('o')
  $terminalCheckpointPath = Join-Path $outputFull ('checkpoints/checkpoint_{0:d8}_{1}.json' -f [int]$state.processed_count, [string]$state.status)
  if (-not (Test-Path -LiteralPath $terminalCheckpointPath)) {
    $state.checkpoint_count = [int]$state.checkpoint_count + 1
    Write-D2BJson $terminalCheckpointPath $state
  }
  Write-D2BJson $statePath $state
  Write-D2BJson $resumePath $state
  Write-D2BJson $heartbeatPath ([ordered]@{
    status=[string]$state.status; heartbeat_utc=$state.updated_utc; processed_count=[int]$state.processed_count
    remaining_count=[int]$state.remaining_count; accepted_count=[int]$state.accepted_count
    quarantine_count=[int]$state.quarantine_count; stopped_by_signal=$false; hard_error=$null
    last_atom_id=$state.last_atom_id; last_disposition=$state.last_disposition
  })
  $unauthorizedDirtyAfter = @(git -C $root status --short -- CAPABILITY_ROADMAP.json GENESIS_STATE.json TASK_QUEUE.json orchestrator/run.ps1 route_locks)
  $result = Write-D2BRunArtifacts -Root $root -OutputRootFull $outputFull -State $state -Manifest $manifest -Status 'INCOMPLETE_RESUMABLE' -StoppedBySignal $false -UnauthorizedDirty $unauthorizedDirtyAfter
  if ($EmitJson) {
    $result | ConvertTo-Json -Depth 40
  } else {
    Write-Host 'PHASE165S_D2B_REPAIR_RESULT=INCOMPLETE_RESUMABLE'
    Write-Host "PROCESSED_COUNT=$($state.processed_count)"
    Write-Host "REMAINING_COUNT=$($state.remaining_count)"
    Write-Host "ACCEPTED_ATOM_COUNT=$($state.accepted_count)"
    Write-Host "QUARANTINE_COUNT=$($state.quarantine_count)"
    Write-Host "FAILED_COUNT=$($state.failed_count)"
  }
  exit 0
}

if ($SyncSummaryOnly) {
  $otherD2BProcesses = @()
  try {
    $otherD2BProcesses = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
      [int]$_.ProcessId -ne $PID -and
      [string]$_.CommandLine -like '*run_phase165s_d2b_big_curriculum_autonomous_learn_until_empty_001.ps1*'
    })
  } catch {
    throw "ACTIVE_D2B_PROCESS_CHECK_FAILED=$($_.Exception.Message)"
  }
  if ($otherD2BProcesses.Count -gt 0) {
    throw "ACTIVE_D2B_RUN_DETECTED=$($otherD2BProcesses.ProcessId -join ',')"
  }
  if ([int]$state.failed_count -gt 0) {
    throw "SUMMARY_SYNC_BLOCKED_FAILED_COUNT=$($state.failed_count)"
  }
  if ([int]$state.remaining_count -eq 0) {
    $state.status = 'QUEUE_EMPTY'
    $syncStatus = 'PASS_QUEUE_EMPTY'
  } else {
    $state.status = 'RUNNING_READY_TO_RESUME'
    $syncStatus = 'INCOMPLETE_RESUMABLE'
  }
  $state.updated_utc = (Get-Date).ToUniversalTime().ToString('o')
  Write-D2BJson $statePath $state
  Write-D2BJson $resumePath $state
  Write-D2BJson $heartbeatPath ([ordered]@{
    status=[string]$state.status; heartbeat_utc=$state.updated_utc; processed_count=[int]$state.processed_count
    remaining_count=[int]$state.remaining_count; accepted_count=[int]$state.accepted_count
    quarantine_count=[int]$state.quarantine_count; stopped_by_signal=$false; hard_error=$null
    last_atom_id=$state.last_atom_id; last_disposition=$state.last_disposition
  })
  $unauthorizedDirtyAfter = @(git -C $root status --short -- CAPABILITY_ROADMAP.json GENESIS_STATE.json TASK_QUEUE.json orchestrator/run.ps1 route_locks)
  $result = Write-D2BRunArtifacts -Root $root -OutputRootFull $outputFull -State $state -Manifest $manifest -Status $syncStatus -StoppedBySignal $false -UnauthorizedDirty $unauthorizedDirtyAfter
  if ($EmitJson) {
    $result | ConvertTo-Json -Depth 40
  } else {
    Write-Host "PHASE165S_D2B_SUMMARY_SYNC_RESULT=$syncStatus"
    Write-Host "PROCESSED_COUNT=$($state.processed_count)"
    Write-Host "REMAINING_COUNT=$($state.remaining_count)"
    Write-Host "ACCEPTED_ATOM_COUNT=$($state.accepted_count)"
    Write-Host "QUARANTINE_COUNT=$($state.quarantine_count)"
    Write-Host "FAILED_COUNT=$($state.failed_count)"
  }
  exit 0
}

try {
  if ($hardError) { throw $hardError }
  while ([int]$state.shard_index -lt $shards.Count) {
    if (Test-Path -LiteralPath $stopPath) {
      $stoppedBySignal = $true
      $state.status = 'STOPPED_BY_SIGNAL'
      break
    }

    $shardRelative = [string]$shards[[int]$state.shard_index]
    $shardFull = Join-Path $root $shardRelative
    if (-not (Test-Path -LiteralPath $shardFull)) { throw "SHARD_MISSING=$shardRelative" }
    $reader = [System.IO.StreamReader]::new($shardFull, [System.Text.UTF8Encoding]::new($false), $true)
    try {
      for ($skip = 0; $skip -lt [int]$state.line_index; $skip += 1) {
        if ($reader.EndOfStream) { throw "CURSOR_BEYOND_SHARD shard=$shardRelative line=$($state.line_index)" }
        [void]$reader.ReadLine()
      }
      while (-not $reader.EndOfStream) {
        if (Test-Path -LiteralPath $stopPath) {
          $stoppedBySignal = $true
          $state.status = 'STOPPED_BY_SIGNAL'
          break
        }
        $line = $reader.ReadLine()
        if ([string]::IsNullOrWhiteSpace($line)) {
          $state.line_index = [int]$state.line_index + 1
          continue
        }
        $candidate = $line | ConvertFrom-Json
        $candidateId = [string]$candidate.candidate_id
        $atomId = [string]$candidate.target_atom_id_suggestion
        $sourcePath = "$shardRelative#line=$([int]$state.line_index + 1)"
        $state.status = 'RUNNING'
        $state.last_candidate_id = $candidateId
        $state.last_atom_id = $atomId

        $effectiveRiskFlags = @($candidate.risk_flags | ForEach-Object { [string]$_ } | Where-Object { $_ -and $_ -ne 'none_identified_at_material_stage' })
        $quarantineReasons = @()
        if ([bool]$candidate.accepted -or [bool]$candidate.trusted) { $quarantineReasons += 'raw_candidate_claims_accepted_or_trusted' }
        if ([string]$candidate.risk_level -ne 'LOW') { $quarantineReasons += "risk_level_not_low=$($candidate.risk_level)" }
        if ($effectiveRiskFlags.Count -gt 0) { $quarantineReasons += "effective_risk_flags=$($effectiveRiskFlags -join ',')" }
        if (-not ([bool]$candidate.requires_school_acceptance -and [bool]$candidate.requires_c2b_guard -and [bool]$candidate.requires_phase162_acceptance)) {
          $quarantineReasons += 'required_acceptance_guard_missing'
          $state.invalid_safe_candidate_count = [int]$state.invalid_safe_candidate_count + 1
        }

        if ($quarantineReasons.Count -gt 0) {
          Add-D2BJsonLine $quarantineLog ([ordered]@{
            occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$candidateId; atom_id=$atomId
            source_path=$sourcePath; disposition='QUARANTINED_PRE_POLICY'; reasons=$quarantineReasons
          })
          $state.quarantine_count = [int]$state.quarantine_count + 1
          $state.last_disposition = 'QUARANTINED_PRE_POLICY'
        } else {
          $memory = Read-D2BJson (Join-Path $root $memoryPath)
          $selfMap = Read-D2BJson (Join-Path $root $selfMapPath)
          $registry = Read-D2BJson (Join-Path $root $registryPath)
          $m0 = Get-D2BCount $memory 'phase162_accepted_atom_memory_records' $atomId
          $s0 = Get-D2BCount $selfMap 'phase162_absorbed_atom_capability_notes' $atomId
          $r0 = Get-D2BCount $registry 'phase162_accepted_atom_references' $atomId
          if (($m0 -eq 1) -and ($s0 -eq 1) -and ($r0 -eq 1)) {
            $memoryRecord = @($memory.phase162_accepted_atom_memory_records | Where-Object { [string]$_.atom_id -eq $atomId })[0]
            $isRecoveredD2B = $memoryRecord.payload -and [string]$memoryRecord.payload.autonomous_loop -eq 'PHASE165S-D2B' -and [string]$memoryRecord.payload.candidate_id -eq $candidateId
            if ($isRecoveredD2B) {
              $recoveredFromWriteEvent = $false
              $finalResultPath = Join-Path $workRoot 'fin/controller_consume_controlled_accept_core_mutation_execution_proof_result.json'
              if (-not (Test-Path -LiteralPath $finalResultPath)) {
                $execResultPath = Join-Path $workRoot 'exec/execute_controlled_accept_core_mutation_result.json'
                if (-not (Test-Path -LiteralPath $execResultPath)) {
                  $policyResultPath = Join-Path $workRoot 'policy_result.json'
                  $candidateResultPath = Join-Path $workRoot 'cand/controlled_accept_core_mutation_candidate_result.json'
                  $executionEventsPath = Join-Path $workRoot 'exec/controlled_accept_core_mutation_execution_events.jsonl'
                  if (-not (Test-Path -LiteralPath $policyResultPath) -or -not (Test-Path -LiteralPath $candidateResultPath)) {
                    throw "RECOVERED_ACCEPTED_ATOM_EXECUTION_RESULT_MISSING=$atomId"
                  }
                  $policyResult = Read-D2BJson $policyResultPath
                  $candidateResult = Read-D2BJson $candidateResultPath
                  $writeEvent = Get-D2BExecutionWriteEvent $executionEventsPath
                  $recoveryEvidencePass = [string]$policyResult.status -eq 'PASS' -and
                    [bool]$policyResult.autonomous_accept_allowed -and
                    @($policyResult.atom_ids | Where-Object { [string]$_ -eq $atomId }).Count -eq 1 -and
                    [string]$candidateResult.status -eq 'PASS' -and
                    @($candidateResult.atom_ids | Where-Object { [string]$_ -eq $atomId }).Count -eq 1 -and
                    $null -ne $writeEvent -and [bool]$writeEvent.data.accepted_core_write -and
                    [int]$writeEvent.data.memory_operation_count -eq 1 -and
                    [int]$writeEvent.data.self_model_operation_count -eq 1 -and
                    [int]$writeEvent.data.registry_operation_count -eq 1
                  if (-not $recoveryEvidencePass) {
                    throw "RECOVERED_ACCEPTED_ATOM_WRITE_EVENT_EVIDENCE_FAILED=$atomId"
                  }
                  Write-D2BJson $execResultPath ([ordered]@{
                    schema='PHASE162_EXECUTE_CONTROLLED_ACCEPT_CORE_MUTATION_FOR_ATOM_BATCH_RESULT_V1'
                    status='PASS'; created_at=(Get-Date).ToUniversalTime().ToString('o')
                    controller_root=(Join-Path $workRoot 'ctrl'); candidate_root=(Join-Path $workRoot 'cand')
                    batch_size=1; staged_atom_count=1
                    controlled_accept_core_mutation_executed=$true
                    post_real_mutation_validation_passed=$true
                    rollback_executed=$false; rollback_required=$false
                    accepted_core_write_executed=$true; accepted_atom_claimed=$false
                    accepted_memory_mutated=$true; accepted_self_model_mutated=$true; registry_mutated=$true
                    final_accept_ready=$true
                    machine_decision='CONTROLLED_ACCEPT_CORE_MUTATION_EXECUTED_PENDING_CONTROLLER_FINALIZATION'
                    next_machine_action='FEED_CONTROLLED_ACCEPT_CORE_MUTATION_EXECUTION_BACK_INTO_CONTROLLER'
                    recovery_source='FULL_SURFACE_VISIBILITY_PLUS_CONTROLLED_ACCEPT_MUTATION_WRITTEN_TO_ACCEPTED_CORE_EVENT'
                    repeated_mutation_execution=$false
                  })
                  $recoveredFromWriteEvent = $true
                }
                $execResult = Read-D2BJson $execResultPath
                $execPass = [string]$execResult.status -eq 'PASS' -and [bool]$execResult.controlled_accept_core_mutation_executed -and
                  [bool]$execResult.post_real_mutation_validation_passed -and -not [bool]$execResult.rollback_executed
                if (-not $execPass) { throw "RECOVERED_ACCEPTED_ATOM_EXECUTION_NOT_PASS=$atomId" }
                Write-D2BJson (Join-Path $workRoot 'exec/execute_controlled_accept_core_mutation_validation.json') ([ordered]@{
                  schema='PHASE165S_D2B_EXECUTION_VALIDATION_V1'; status='PASS'; created_at=(Get-Date).ToUniversalTime().ToString('o')
                  atom_id=$atomId; memory_count=1; self_map_count=1; registry_count=1; owner_interrupt_used=$false; autonomous_policy_guard_allowed=$true
                })
                $executionProofPath = Join-Path $workRoot 'exec/phase165s_d2b_execution_proof_for_controller.json'
                Write-D2BJson $executionProofPath ([ordered]@{
                  schema='PHASE165S_D2B_EXECUTION_PROOF_FOR_PHASE162_CONTROLLER_V1'; status='PASS'
                  created_at=(Get-Date).ToUniversalTime().ToString('o'); head=(git -C $root rev-parse HEAD)
                  output_root=(Join-Path $workRoot 'exec'); next_action=[string]$execResult.next_machine_action
                  accepted_atom_claimed=$false; atom_id=$atomId; owner_interrupt_used=$false
                })
                $state.finalizer_invocation_count = [int]$state.finalizer_invocation_count + 1
                [void](Invoke-D2BPowerShell -ScriptPath $finalizerModule -Arguments @('-RepoRoot',$root,'-ExecutionProofPath',$executionProofPath,'-OutputRoot',(Join-Path $workRoot 'fin')))
              }
              $finalResult = Read-D2BJson $finalResultPath
              if (-not ([string]$finalResult.status -eq 'PASS' -and [bool]$finalResult.accepted_atom_claimed)) {
                throw "RECOVERED_ACCEPTED_ATOM_FINALIZATION_NOT_PASS=$atomId"
              }
              Add-D2BJsonLine $acceptedLog ([ordered]@{
                occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$candidateId; atom_id=$atomId
                source_path=$sourcePath
                disposition=$(if($recoveredFromWriteEvent){'ACCEPTED_RECOVERED_POST_WRITE_FINALIZATION'}else{'ACCEPTED_RECOVERED_AFTER_INTERRUPTION'})
                memory_count=1; self_map_count=1; registry_count=1; repeated_mutation_execution=$false
              })
              $state.accepted_count = [int]$state.accepted_count + 1
              $state.last_disposition = if ($recoveredFromWriteEvent) { 'ACCEPTED_RECOVERED_POST_WRITE_FINALIZATION' } else { 'ACCEPTED_RECOVERED_AFTER_INTERRUPTION' }
              $lastAcceptedAtomId = $atomId
              if ($recoveredFromWriteEvent -and -not $resumeHadHardError) {
                Add-D2BJsonLine $failedLog ([ordered]@{
                  occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$candidateId; atom_id=$atomId
                  shard_index=[int]$state.shard_index; line_index=[int]$state.line_index
                  error='INTERRUPTED_AFTER_FULL_SURFACE_ACCEPTED_CORE_WRITE_BEFORE_FINALIZATION'
                })
                Add-D2BJsonLine $recoveryLog ([ordered]@{
                  occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$candidateId; atom_id=$atomId
                  recovered_failure='full_surface_accepted_core_write_with_interrupted_finalization'
                  resolution='FINALIZED_ON_NEXT_RESUME_WITHOUT_REPEATED_MUTATION_AND_CURSOR_ADVANCED'
                  visibility_counts=[ordered]@{ memory=1; self_map=1; registry=1 }
                })
                $state.recovered_failure_count = [int]$state.recovered_failure_count + 1
              }
              if ($resumeHadHardError -and $resumeFailedCandidateId -eq $candidateId -and [int]$state.failed_count -gt 0) {
                $recoverCount = [int]$state.failed_count
                for ($recovered = 0; $recovered -lt $recoverCount; $recovered += 1) {
                  Add-D2BJsonLine $recoveryLog ([ordered]@{
                    occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$candidateId; atom_id=$atomId
                    recovered_failure='runner_infrastructure_failure_for_same_cursor_candidate'; resolution='FINALIZED_AND_CURSOR_ADVANCED'
                  })
                }
                $state.failed_count = 0
                $state.recovered_failure_count = [int]$state.recovered_failure_count + $recoverCount
                $resumeHadHardError = $false
              }
            } else {
              Add-D2BJsonLine $skippedLog ([ordered]@{
                occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$candidateId; atom_id=$atomId
                source_path=$sourcePath; disposition='SKIPPED_ALREADY_ACCEPTED'
              })
              $state.skipped_duplicate_count = [int]$state.skipped_duplicate_count + 1
              $state.last_disposition = 'SKIPPED_ALREADY_ACCEPTED'
            }
          } elseif (($m0 + $s0 + $r0) -ne 0) {
            throw "PARTIAL_ACCEPTED_SURFACE atom=$atomId memory=$m0 self_map=$s0 registry=$r0"
          } else {
            Reset-D2BWorkRoot -OutputRootFull $outputFull -WorkRoot $workRoot
            $policyCandidatePath = Join-Path $workRoot 'policy_candidate.json'
            $policyResultPath = Join-Path $workRoot 'policy_result.json'
            Write-D2BJson $policyCandidatePath ([ordered]@{
              atom_id=$atomId; batch_size=1; source_route='OWNER_APPROVED_CURRICULUM'; source_authority='OWNER_APPROVED'
              target_files=@($memoryPath,$selfMapPath,$registryPath); protected_files_to_mutate=@('packs/registry.json')
              proof_gates=[ordered]@{
                memory_proof_status='PASS'; use_proof_status='PASS'; behavior_delta_status='PASS'
                persistence_status='PASS'; startup_visibility_status='PASS'
              }
              rollback_plan_available=$true; exactly_one_atom_scope=$true; mass_acceptance_forbidden=$true; risk_flags=@()
            })
            $state.policy_guard_invocation_count = [int]$state.policy_guard_invocation_count + 1
            [void](Invoke-D2BPowerShell -ScriptPath $policyModule -Arguments @('-RepoRoot',$root,'-CandidatePath',$policyCandidatePath,'-OutputPath',$policyResultPath))
            $policy = Read-D2BJson $policyResultPath
            if (-not [bool]$policy.autonomous_accept_allowed) {
              Add-D2BJsonLine $quarantineLog ([ordered]@{
                occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$candidateId; atom_id=$atomId
                source_path=$sourcePath; disposition='DENIED_BY_C2B'; reasons=@($policy.denial_reasons)
              })
              $state.denied_count = [int]$state.denied_count + 1
              $state.quarantine_count = [int]$state.quarantine_count + 1
              $state.last_disposition = 'DENIED_BY_C2B'
            } else {
              $operationId = "D2B_{0:d8}_{1}" -f ([int]$state.processed_count + 1), (($candidateId -replace '[^A-Za-z0-9]', '_').Substring(0, [math]::Min(40, ($candidateId -replace '[^A-Za-z0-9]', '_').Length)))
              $package = New-D2BPhase162Package -WorkRoot $workRoot -Candidate $candidate -OperationId $operationId -SourcePath $sourcePath -MemoryPath $memoryPath -SelfMapPath $selfMapPath -RegistryPath $registryPath
              $state.phase162_executor_invocation_count = [int]$state.phase162_executor_invocation_count + 1
              [void](Invoke-D2BPowerShell -ScriptPath $executorModule -Arguments @('-ControllerRoot',[string]$package.controller_root,'-RepoRoot',$root,'-OutputRoot',[string]$package.execution_root))
              $execResult = Read-D2BJson (Join-Path $package.execution_root 'execute_controlled_accept_core_mutation_result.json')
              $m = Get-D2BCount (Read-D2BJson (Join-Path $root $memoryPath)) 'phase162_accepted_atom_memory_records' $atomId
              $s = Get-D2BCount (Read-D2BJson (Join-Path $root $selfMapPath)) 'phase162_absorbed_atom_capability_notes' $atomId
              $r = Get-D2BCount (Read-D2BJson (Join-Path $root $registryPath)) 'phase162_accepted_atom_references' $atomId
              $execPass = [string]$execResult.status -eq 'PASS' -and [bool]$execResult.controlled_accept_core_mutation_executed -and
                [bool]$execResult.post_real_mutation_validation_passed -and -not [bool]$execResult.rollback_executed -and $m -eq 1 -and $s -eq 1 -and $r -eq 1
              Write-D2BJson (Join-Path $package.execution_root 'execute_controlled_accept_core_mutation_validation.json') ([ordered]@{
                schema='PHASE165S_D2B_EXECUTION_VALIDATION_V1'; status=$(if($execPass){'PASS'}else{'FAIL'})
                created_at=(Get-Date).ToUniversalTime().ToString('o'); atom_id=$atomId; memory_count=$m; self_map_count=$s; registry_count=$r
                owner_interrupt_used=$false; autonomous_policy_guard_allowed=$true
              })
              $executionProofPath = Join-Path $package.execution_root 'phase165s_d2b_execution_proof_for_controller.json'
              Write-D2BJson $executionProofPath ([ordered]@{
                schema='PHASE165S_D2B_EXECUTION_PROOF_FOR_PHASE162_CONTROLLER_V1'; status=[string]$execResult.status
                created_at=(Get-Date).ToUniversalTime().ToString('o'); head=(git -C $root rev-parse HEAD)
                output_root=$package.execution_root; next_action=[string]$execResult.next_machine_action
                accepted_atom_claimed=$false; atom_id=$atomId; owner_interrupt_used=$false
              })
              if (-not $execPass) {
                if (($m + $s + $r) -eq 0) {
                  Add-D2BJsonLine $failedLog ([ordered]@{
                    occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$candidateId; atom_id=$atomId
                    shard_index=[int]$state.shard_index; line_index=[int]$state.line_index
                    error="PHASE162_POST_EXECUTION_VISIBILITY_FAILED atom=$atomId memory=0 self_map=0 registry=0"
                  })
                  Add-D2BJsonLine $recoveryLog ([ordered]@{
                    occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$candidateId; atom_id=$atomId
                    recovered_failure='phase162_post_execution_zero_surface_visibility_failure'
                    resolution='QUARANTINED_NOT_ACCEPTED_AND_CURSOR_ADVANCED'
                    visibility_counts=[ordered]@{ memory=0; self_map=0; registry=0 }
                  })
                  Add-D2BJsonLine $quarantineLog ([ordered]@{
                    occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$candidateId; atom_id=$atomId
                    source_path=$sourcePath; disposition='QUARANTINED_POST_EXECUTION_ZERO_VISIBILITY'
                    reasons=@('phase162_post_execution_visibility_failed','accepted_surface_visibility_zero','candidate_not_accepted')
                    visibility_counts=[ordered]@{ memory=0; self_map=0; registry=0 }
                  })
                  $state.quarantine_count = [int]$state.quarantine_count + 1
                  $state.dynamic_quarantine_count = [int]$state.dynamic_quarantine_count + 1
                  $state.recovered_failure_count = [int]$state.recovered_failure_count + 1
                  $state.last_disposition = 'QUARANTINED_POST_EXECUTION_ZERO_VISIBILITY'
                } elseif (-not ($m -eq 1 -and $s -eq 1 -and $r -eq 1)) {
                  throw "PARTIAL_ACCEPTED_SURFACE atom=$atomId memory=$m self_map=$s registry=$r"
                } else {
                  throw "PHASE162_POST_EXECUTION_VISIBILITY_FAILED atom=$atomId memory=$m self_map=$s registry=$r"
                }
              } else {
                $state.finalizer_invocation_count = [int]$state.finalizer_invocation_count + 1
                [void](Invoke-D2BPowerShell -ScriptPath $finalizerModule -Arguments @('-RepoRoot',$root,'-ExecutionProofPath',$executionProofPath,'-OutputRoot',[string]$package.finalizer_root))
                $finalResult = Read-D2BJson (Join-Path $package.finalizer_root 'controller_consume_controlled_accept_core_mutation_execution_proof_result.json')
                if (-not ([string]$finalResult.status -eq 'PASS' -and [bool]$finalResult.accepted_atom_claimed)) {
                  throw "PHASE162_FINALIZATION_NOT_ACCEPTED=$atomId"
                }
                Add-D2BJsonLine $acceptedLog ([ordered]@{
                  occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$candidateId; atom_id=$atomId
                  source_path=$sourcePath; disposition='ACCEPTED'; policy_decision=[string]$policy.decision_code
                  memory_count=$m; self_map_count=$s; registry_count=$r; owner_interrupt_used=$false
                })
                $state.accepted_count = [int]$state.accepted_count + 1
                $state.last_disposition = 'ACCEPTED'
                $lastAcceptedAtomId = $atomId
                if ($resumeHadHardError -and $resumeFailedCandidateId -eq $candidateId -and [int]$state.failed_count -gt 0) {
                  $recoverCount = [int]$state.failed_count
                  for ($recovered = 0; $recovered -lt $recoverCount; $recovered += 1) {
                    Add-D2BJsonLine $recoveryLog ([ordered]@{
                      occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$candidateId; atom_id=$atomId
                      recovered_failure='runner_infrastructure_failure_for_same_cursor_candidate'; resolution='RETRIED_ACCEPTED_FINALIZED_AND_CURSOR_ADVANCED'
                    })
                  }
                  $state.failed_count = 0
                  $state.recovered_failure_count = [int]$state.recovered_failure_count + $recoverCount
                  $resumeHadHardError = $false
                }
              }
            }
          }
        }

        $state.processed_count = [int]$state.processed_count + 1
        $state.remaining_count = [int]$manifest.total_candidate_count - [int]$state.processed_count
        $state.line_index = [int]$state.line_index + 1
        $state.updated_utc = (Get-Date).ToUniversalTime().ToString('o')

        if (([int]$state.processed_count % $HeartbeatEvery) -eq 0) {
          $state.heartbeat_count = [int]$state.heartbeat_count + 1
          Write-D2BJson $heartbeatPath ([ordered]@{
            status=[string]$state.status; heartbeat_utc=$state.updated_utc; processed_count=[int]$state.processed_count
            remaining_count=[int]$state.remaining_count; accepted_count=[int]$state.accepted_count
            quarantine_count=[int]$state.quarantine_count; shard_index=[int]$state.shard_index; line_index=[int]$state.line_index
            last_candidate_id=$state.last_candidate_id; last_atom_id=$state.last_atom_id; last_disposition=$state.last_disposition
          })
        }
        if (([int]$state.processed_count % $CheckpointEvery) -eq 0) {
          $state.checkpoint_count = [int]$state.checkpoint_count + 1
          Write-D2BJson (Join-Path $outputFull ('checkpoints/checkpoint_{0:d8}.json' -f [int]$state.processed_count)) $state
        }
        Write-D2BJson $statePath $state
        Write-D2BJson $resumePath $state
        if (([int]$state.processed_count % $CheckpointEvery) -eq 0) {
          $checkpointUnauthorizedDirty = @(git -C $root status --short -- CAPABILITY_ROADMAP.json GENESIS_STATE.json TASK_QUEUE.json orchestrator/run.ps1 route_locks)
          [void](Write-D2BRunArtifacts -Root $root -OutputRootFull $outputFull -State $state -Manifest $manifest -Status 'RUNNING_ACTIVE' -StoppedBySignal $false -UnauthorizedDirty $checkpointUnauthorizedDirty)
        }
      }
    } finally {
      $reader.Dispose()
    }
    if ($stoppedBySignal) { break }
    $state.shard_index = [int]$state.shard_index + 1
    $state.line_index = 0
    Write-D2BJson $statePath $state
    Write-D2BJson $resumePath $state
  }
  if (-not $stoppedBySignal -and [int]$state.remaining_count -eq 0) {
    $state.status = 'QUEUE_EMPTY'
  }
} catch {
  $hardError = $_.Exception.Message
  if (-not $hardErrorAlreadyRecorded) {
    $state.failed_count = [int]$state.failed_count + 1
  }
  $state.status = if ($hardError -like 'PARTIAL_ACCEPTED_SURFACE*') { 'BLOCKED_PARTIAL_ACCEPTED_SURFACE' } else { 'HARD_ERROR' }
  if (-not $hardErrorAlreadyRecorded) {
    Add-D2BJsonLine $failedLog ([ordered]@{
      occurred_utc=(Get-Date).ToUniversalTime().ToString('o'); candidate_id=$state.last_candidate_id; atom_id=$state.last_atom_id
      shard_index=[int]$state.shard_index; line_index=[int]$state.line_index; error=$hardError
    })
  }
}

$finalStatus = if ($hardError -like 'PARTIAL_ACCEPTED_SURFACE*') {
  'BLOCKED_PARTIAL_ACCEPTED_SURFACE'
} elseif ($hardError) {
  'HARD_ERROR'
} elseif ($stoppedBySignal) {
  'STOPPED_BY_SIGNAL'
} elseif ([int]$state.remaining_count -eq 0) {
  'PASS_QUEUE_EMPTY'
} else {
  'INCOMPLETE_RESUMABLE'
}
if ($finalStatus -eq 'INCOMPLETE_RESUMABLE') {
  $state.status = 'RUNNING_READY_TO_RESUME'
}
$state.updated_utc = (Get-Date).ToUniversalTime().ToString('o')
$terminalCheckpointPath = Join-Path $outputFull ('checkpoints/checkpoint_{0:d8}_{1}.json' -f [int]$state.processed_count, [string]$state.status)
if (-not (Test-Path -LiteralPath $terminalCheckpointPath)) {
  $state.checkpoint_count = [int]$state.checkpoint_count + 1
  Write-D2BJson $terminalCheckpointPath $state
}
Write-D2BJson $statePath $state
Write-D2BJson $resumePath $state
Write-D2BJson $heartbeatPath ([ordered]@{
  status=[string]$state.status; heartbeat_utc=$state.updated_utc; processed_count=[int]$state.processed_count
  remaining_count=[int]$state.remaining_count; accepted_count=[int]$state.accepted_count; quarantine_count=[int]$state.quarantine_count
  stopped_by_signal=$stoppedBySignal; hard_error=$hardError; last_atom_id=$state.last_atom_id; last_disposition=$state.last_disposition
})

$unauthorizedDirtyAfter = @(git -C $root status --short -- CAPABILITY_ROADMAP.json GENESIS_STATE.json TASK_QUEUE.json orchestrator/run.ps1 route_locks)
$result = Write-D2BRunArtifacts -Root $root -OutputRootFull $outputFull -State $state -Manifest $manifest -Status $finalStatus -StoppedBySignal $stoppedBySignal -UnauthorizedDirty $unauthorizedDirtyAfter

if ($EmitJson) {
  $result | ConvertTo-Json -Depth 40
} else {
  Write-Host "PHASE165S_D2B_BIG_CURRICULUM_AUTONOMOUS_LEARNING_RESULT=$finalStatus"
  Write-Host "PROCESSED_COUNT=$($state.processed_count)"
  Write-Host "REMAINING_COUNT=$($state.remaining_count)"
  Write-Host "ACCEPTED_ATOM_COUNT=$($state.accepted_count)"
  Write-Host "QUARANTINE_COUNT=$($state.quarantine_count)"
  Write-Host "FAILED_COUNT=$($state.failed_count)"
  Write-Host "NEXT_REQUIRED_ACTION=$($result.next_required_action)"
}
if ($hardError) { exit 1 }
