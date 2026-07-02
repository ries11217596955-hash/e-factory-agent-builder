param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Write-Phase165SC1Json {
  param([string]$Path, $Value)
  $directory = Split-Path -Parent $Path
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $json = ($Value | ConvertTo-Json -Depth 100) -replace "`r`n", "`n"
  [System.IO.File]::WriteAllText($Path, $json + "`n", [System.Text.UTF8Encoding]::new($false))
}

function Write-Phase165SC1Text {
  param([string]$Path, [string[]]$Lines)
  $directory = Split-Path -Parent $Path
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, (($Lines -join "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))
}

function Get-Phase165SC1AtomCount {
  param($Root, [string]$Property, [string]$AtomId)
  if ($null -eq $Root -or -not ($Root.PSObject.Properties.Name -contains $Property)) {
    return 0
  }
  return @($Root.$Property | Where-Object { [string]$_.atom_id -eq $AtomId }).Count
}

$root = (Resolve-Path $RepoRoot).Path
$proofRelative = 'proofs/self_development/PHASE165S_C1_CONNECT_SCHOOL_RESULT_TO_AGENT_SELF_DEVELOPMENT_LOOP_ONE_CONCEPT_PROOF_V1.json'
$reportRelative = 'reports/self_development/PHASE165S_C1_CONNECT_SCHOOL_RESULT_TO_AGENT_SELF_DEVELOPMENT_LOOP_ONE_CONCEPT_PROOF_V1.md'
$packRelative = 'reports/self_development/phase165s_inbox_small_batch/PHASE165S_B_FOUNDATION_CONCEPT_CURRICULUM_PACK_V1.json'
$phaseBProofRelative = 'proofs/self_development/PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL_V1.json'
$phaseC0ProofRelative = 'proofs/self_development/PHASE165S_C0_CURRICULUM_TO_ACCEPTED_ATOM_PIPELINE_AUDIT_V1.json'
$atomId = 'decision_rule.map_signal_not_command.v1'
$protectedPaths = @(
  'CAPABILITY_ROADMAP.json',
  'GENESIS_STATE.json',
  'TASK_QUEUE.json',
  'packs/registry.json',
  'orchestrator/run.ps1'
)
$requiredPaths = @(
  $packRelative,
  $phaseBProofRelative,
  $phaseC0ProofRelative,
  'reports/self_development/accepted_change_memory_snapshot.json',
  'reports/self_development/SELF_MODEL_ACTIVE_MAP.json',
  'packs/registry.json',
  'modules/invoke_phase162_execute_controlled_accept_core_mutation_for_atom_batch_001.ps1',
  'modules/invoke_phase162_controller_consume_controlled_accept_core_mutation_execution_proof_001.ps1'
)

foreach ($path in $requiredPaths) {
  if (-not (Test-Path -LiteralPath (Join-Path $root $path))) {
    throw "REQUIRED_PATH_MISSING=$path"
  }
}

$branch = (git -C $root branch --show-current).Trim()
$head = (git -C $root rev-parse HEAD).Trim()
if ($branch -ne 'phase110-idempotent-autonomy-trial-runtime') {
  throw "UNEXPECTED_BRANCH=$branch"
}

$protectedDirty = @(git -C $root status --short -- @($protectedPaths + @('route_locks')))
if ($protectedDirty.Count -gt 0) {
  throw "PROTECTED_STATE_DIRTY=$($protectedDirty -join '; ')"
}

$pack = Get-Content -LiteralPath (Join-Path $root $packRelative) -Raw | ConvertFrom-Json
$lesson = @($pack.lessons | Where-Object { [string]$_.lesson_id -eq 'map_signal_not_command' })
if ($lesson.Count -ne 1) {
  throw "SOURCE_LESSON_COUNT_UNEXPECTED=$($lesson.Count)"
}

$phaseBProof = Get-Content -LiteralPath (Join-Path $root $phaseBProofRelative) -Raw | ConvertFrom-Json
$phaseC0Proof = Get-Content -LiteralPath (Join-Path $root $phaseC0ProofRelative) -Raw | ConvertFrom-Json
$memory = Get-Content -LiteralPath (Join-Path $root 'reports/self_development/accepted_change_memory_snapshot.json') -Raw | ConvertFrom-Json
$selfMap = Get-Content -LiteralPath (Join-Path $root 'reports/self_development/SELF_MODEL_ACTIVE_MAP.json') -Raw | ConvertFrom-Json
$registry = Get-Content -LiteralPath (Join-Path $root 'packs/registry.json') -Raw | ConvertFrom-Json

$memoryCount = Get-Phase165SC1AtomCount -Root $memory -Property 'phase162_accepted_atom_memory_records' -AtomId $atomId
$selfMapCount = Get-Phase165SC1AtomCount -Root $selfMap -Property 'phase162_absorbed_atom_capability_notes' -AtomId $atomId
$registryCount = Get-Phase165SC1AtomCount -Root $registry -Property 'phase162_accepted_atom_references' -AtomId $atomId
$atomAbsent = ($memoryCount -eq 0 -and $selfMapCount -eq 0 -and $registryCount -eq 0)
if (-not $atomAbsent) {
  throw "ATOM_ALREADY_PRESENT memory=$memoryCount self_map=$selfMapCount registry=$registryCount"
}

$candidate = [ordered]@{
  schema = 'PHASE165S_C1_LESSON_DERIVED_ATOM_CANDIDATE_V1'
  atom_id = $atomId
  candidate_status = 'BLOCKED_BEFORE_ACCEPTANCE'
  source_lesson_id = [string]$lesson[0].lesson_id
  source_curriculum_id = [string]$pack.curriculum_id
  source_curriculum_pack = $packRelative
  source_phase_b_proof = $phaseBProofRelative
  meaning = 'The self-map or body-map may emit diagnostic and recommendation signals, but it is not the commander. A map signal must not be treated as a direct execution command. The Mode Decision Kernel or dispatcher decides action.'
  decision_rule = [ordered]@{
    input = 'self_map_recommendation'
    classification = 'MAP_SIGNAL_INPUT_ONLY'
    direct_command = $false
    decision_authority = 'MODE_DECISION_KERNEL'
  }
  required_acceptance_evidence = @(
    'memory_proof',
    'use_proof',
    'behavior_delta',
    'persistence',
    'startup_or_next_cycle_visibility'
  )
}

$targetDependency = [ordered]@{
  existing_acceptance_executor = 'modules/invoke_phase162_execute_controlled_accept_core_mutation_for_atom_batch_001.ps1'
  existing_controller_finalizer = 'modules/invoke_phase162_controller_consume_controlled_accept_core_mutation_execution_proof_001.ps1'
  atomic_write_required = $true
  target_files = @(
    'reports/self_development/accepted_change_memory_snapshot.json',
    'reports/self_development/SELF_MODEL_ACTIVE_MAP.json',
    'packs/registry.json'
  )
  forbidden_target = 'packs/registry.json'
  forbidden_by_current_task = $true
  registry_write_is_optional_in_existing_executor = $false
  safe_non_protected_parallel_registry_allowed = $false
}

$applyPlan = @(
  [ordered]@{
    step = 1
    action = 'Build one PHASE162-compatible atom candidate from the committed map_signal_not_command lesson.'
    expected_atom_id = $atomId
    mutation = 'candidate evidence only'
  },
  [ordered]@{
    step = 2
    action = 'Run freeze, readiness, usefulness, executed-use, behavior-delta, rollback, post-accept validation dry-run, and bounded runtime absorb gates.'
    expected_result = 'all pre-accept gates PASS with accepted_atom_claimed=false'
  },
  [ordered]@{
    step = 3
    action = 'Prepare and validate the controlled accepted-core mutation candidate.'
    expected_operations = @(
      'append_accepted_atom_memory_record',
      'append_absorbed_atom_capability_note',
      'record_accepted_atom_reference_after_final_authorization'
    )
  },
  [ordered]@{
    step = 4
    action = 'Obtain explicit Owner scope allowing the one-shot atomic write to packs/registry.json together with the two derived accepted-state files.'
    required_scope_change = 'temporarily permit packs/registry.json mutation for this exact atom and existing PHASE162 executor only'
  },
  [ordered]@{
    step = 5
    action = 'Execute and validate modules/invoke_phase162_execute_controlled_accept_core_mutation_for_atom_batch_001.ps1 under its one-shot authorization and rollback plan.'
    expected_result = 'one record in memory, self-map, and registry; post-real-mutation validation PASS'
  },
  [ordered]@{
    step = 6
    action = 'Run controller finalization and its validator.'
    expected_result = 'accepted_atom_claimed=true and next action VERIFY_ACCEPTED_ATOM_VISIBLE_TO_NEXT_CYCLE'
  },
  [ordered]@{
    step = 7
    action = 'Start a fresh PowerShell process and read the accepted atom through memory, self-map, and registry; run the sample map-signal classification.'
    expected_result = 'known atom count is one on all surfaces and classification is MAP_SIGNAL_INPUT_ONLY / NOT_DIRECT_COMMAND'
  }
)

$proof = [ordered]@{
  phase = 'PHASE165S_C1_CONNECT_SCHOOL_RESULT_TO_AGENT_SELF_DEVELOPMENT_LOOP_ONE_CONCEPT_PROOF'
  created_utc = (Get-Date).ToUniversalTime().ToString('o')
  status = 'BLOCKED_PROTECTED_APPLY_REQUIRED'
  branch = $branch
  head = $head
  baseline_note = 'Task text named 389ffba; actual repository baseline is 3b9ffba.'
  c0_conclusion = [string]$phaseC0Proof.conclusion
  source_lesson_reconstructed = $true
  source_lesson = $lesson[0]
  atom_candidate = $candidate
  existing_universal_acceptance_path_found = $true
  acceptance_path_reused = $false
  acceptance_path_blocked_before_execution = $true
  protected_apply_dependency = $targetDependency
  atom_presence_before = [ordered]@{
    memory_count = $memoryCount
    self_map_count = $selfMapCount
    registry_count = $registryCount
  }
  atom_candidate_created = $true
  accepted_atom_claimed = $false
  memory_proof = [ordered]@{ status = 'NOT_RUN'; passed = $false; reason = 'accepted atom write is blocked' }
  use_proof = [ordered]@{ status = 'NOT_RUN'; passed = $false; reason = 'must be executed after real acceptance' }
  behavior_delta = [ordered]@{ status = 'NOT_RUN'; passed = $false; reason = 'cannot compare accepted next-cycle behavior before acceptance' }
  persistence = [ordered]@{ status = 'FAIL_NOT_PRESENT'; passed = $false; repo_persistent_atom_count = 0 }
  startup_or_next_cycle_visibility = [ordered]@{ status = 'NOT_RUN'; passed = $false; reason = 'no accepted atom exists for fresh-process lookup' }
  pass_marker_allowed = $false
  protected_state_dirty_check = @($protectedDirty)
  protected_state_mutated = $false
  no_parallel_atom_registry_created = $true
  no_commit_or_push = $true
  exact_candidate_apply_plan = $applyPlan
  runner_path = 'modules/run_phase165s_c1_connect_school_result_to_agent_self_development_loop_one_concept_proof_001.ps1'
  validator_path = 'validators/validate_phase165s_c1_lesson_to_atom_bridge_v1.ps1'
  proof_path = $proofRelative
  report_path = $reportRelative
  next_required_action = 'OWNER_AUTHORIZE_EXACT_PHASE162_ONE_ATOM_PROTECTED_APPLY_OR_KEEP_BLOCKED'
}

Write-Phase165SC1Json -Path (Join-Path $root $proofRelative) -Value $proof

$report = @(
  '# PHASE165S-C1 Lesson To Accepted Atom Bridge',
  '',
  'Status: BLOCKED_PROTECTED_APPLY_REQUIRED',
  '',
  '## Finding',
  '',
  'The committed `map_signal_not_command` lesson was reconstructed and converted into candidate `decision_rule.map_signal_not_command.v1`.',
  '',
  'The repository has one real universal accepted-atom path: the PHASE162 controlled accepted-core executor followed by controller finalization. That executor requires an atomic write to:',
  '',
  '- `reports/self_development/accepted_change_memory_snapshot.json`',
  '- `reports/self_development/SELF_MODEL_ACTIVE_MAP.json`',
  '- `packs/registry.json`',
  '',
  '`packs/registry.json` is protected and explicitly out of scope. The existing executor does not support a registry no-op. Therefore acceptance was not executed and no PASS is claimed.',
  '',
  '## Current Evidence',
  '',
  "- Atom ID: ``$atomId``",
  "- Accepted memory count: $memoryCount",
  "- Self-map accepted note count: $selfMapCount",
  "- Registry reference count: $registryCount",
  '- Memory proof: NOT RUN',
  '- Use proof: NOT RUN',
  '- Behavior delta: NOT RUN',
  '- Persistence: FAIL_NOT_PRESENT',
  '- Fresh-process visibility: NOT RUN',
  '- Protected dirty check: empty',
  '',
  '## Candidate Meaning',
  '',
  'The self-map or body-map may emit diagnostic and recommendation signals, but it is not the commander. A map signal is `MAP_SIGNAL_INPUT_ONLY`, never a direct execution command. The Mode Decision Kernel or dispatcher decides action.',
  '',
  '## Exact Apply Plan',
  ''
)
foreach ($step in $applyPlan) {
  $report += "$($step.step). $($step.action)"
}
$report += @(
  '',
  '## Required Owner Decision',
  '',
  'Authorize the existing PHASE162 one-shot atomic executor to mutate `packs/registry.json` for this exact atom together with its accepted memory and self-map records, or keep C1 blocked.',
  '',
  '## Next Required Action',
  '',
  'OWNER_AUTHORIZE_EXACT_PHASE162_ONE_ATOM_PROTECTED_APPLY_OR_KEEP_BLOCKED'
)
Write-Phase165SC1Text -Path (Join-Path $root $reportRelative) -Lines $report

$validatorOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'validators/validate_phase165s_c1_lesson_to_atom_bridge_v1.ps1') -RepoRoot $root 2>&1 | ForEach-Object { [string]$_ })
if ($LASTEXITCODE -ne 0) {
  throw "C1_BLOCKED_VALIDATOR_FAILED=$($validatorOutput -join '; ')"
}

Write-Host 'PHASE165S_C1_STATUS=BLOCKED_PROTECTED_APPLY_REQUIRED'
Write-Host "ATOM_ID=$atomId"
Write-Host 'ACCEPTED_ATOM_CLAIMED=False'
Write-Host 'PROTECTED_STATE_DIRTY_CHECK='
Write-Host 'NEXT_REQUIRED_ACTION=OWNER_AUTHORIZE_EXACT_PHASE162_ONE_ATOM_PROTECTED_APPLY_OR_KEEP_BLOCKED'

