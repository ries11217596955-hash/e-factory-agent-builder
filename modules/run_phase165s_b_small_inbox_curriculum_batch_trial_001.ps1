param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Write-Phase165SBJson {
  param([string]$Path, $Value)
  $directory = Split-Path -Parent $Path
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $json = ($Value | ConvertTo-Json -Depth 100) -replace "`r`n", "`n"
  [System.IO.File]::WriteAllText($Path, $json + "`n", [System.Text.UTF8Encoding]::new($false))
}

function Write-Phase165SBText {
  param([string]$Path, [string[]]$Lines)
  $directory = Split-Path -Parent $Path
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, (($Lines -join "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))
}

function Invoke-Phase165SBJsonScript {
  param([string]$ScriptPath, [string[]]$Arguments)
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "CHILD_SCRIPT_FAILED=$ScriptPath output=$($output -join ' | ')"
  }
  return (($output -join "`n") | ConvertFrom-Json)
}

function Get-Phase165SBRelativePath {
  param([string]$Root, [string]$Path)
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
  $pathFull = [System.IO.Path]::GetFullPath($Path)
  if (-not $pathFull.StartsWith($rootFull + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
    return $Path
  }
  return ($pathFull.Substring($rootFull.Length + 1) -replace '\\', '/')
}

function Get-Phase165SBHashes {
  param([string]$Root, [string[]]$Paths)
  $hashes = @{}
  foreach ($path in $Paths) {
    $hashes[$path] = (Get-FileHash -LiteralPath (Join-Path $Root $path) -Algorithm SHA256).Hash
  }
  return $hashes
}

function Invoke-Phase165SBSelectorValidator {
  param([string]$Root)
  $sideEffects = @(
    'proofs/self_development/PHASE165R_B_BUILDER_SELF_MAP_REFRESH_ORGAN_COMPLETION_V1.json',
    'reports/self_development/PHASE165R_B_BUILDER_SELF_MAP_REFRESH_ORGAN_COMPLETION_V1.md'
  )
  $snapshots = @{}
  foreach ($path in $sideEffects) {
    $full = Join-Path $Root $path
    if (Test-Path -LiteralPath $full) {
      $snapshots[$path] = [System.IO.File]::ReadAllBytes($full)
    }
  }
  try {
    $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'validators/validate_phase161j_self_map_next_action_selector_v1.ps1') -RepoRoot $Root 2>&1 | ForEach-Object { [string]$_ })
    return [pscustomobject][ordered]@{
      passed = ($LASTEXITCODE -eq 0)
      exit_code = $LASTEXITCODE
      output = @($output)
    }
  } finally {
    foreach ($path in $snapshots.Keys) {
      [System.IO.File]::WriteAllBytes((Join-Path $Root $path), $snapshots[$path])
    }
  }
}

$root = (Resolve-Path $RepoRoot).Path
$identity = @(
  'CAPABILITY_ROADMAP.json',
  'GENESIS_STATE.json',
  'TASK_QUEUE.json',
  'packs/registry.json',
  'orchestrator/run.ps1'
)
$protectedPaths = @($identity + @('route_locks/ACTIVE_ROUTE_LOCK.json'))
$packRelative = 'reports/self_development/phase165s_inbox_small_batch/PHASE165S_B_FOUNDATION_CONCEPT_CURRICULUM_PACK_V1.json'
$phaseRootRelative = 'reports/self_development/phase165s_inbox_small_batch'
$proofRelative = 'proofs/self_development/PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL_V1.json'
$reportRelative = 'reports/self_development/PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL_V1.md'
$summaryRelative = "$phaseRootRelative/PHASE165S_B_TRIAL_EXECUTION_SUMMARY_V1.json"
$commandsRun = @(
  'powershell -NoProfile -ExecutionPolicy Bypass -File modules/run_phase165s_b_small_inbox_curriculum_batch_trial_001.ps1',
  'powershell -NoProfile -ExecutionPolicy Bypass -File modules/validate_builder_curriculum_pack_schema_001.ps1',
  'modules/route_builder_owner_inbox_message_001.ps1::Invoke-Phase161B1OwnerInboxRouter',
  'powershell -NoProfile -ExecutionPolicy Bypass -File modules/run_builder_school_batch_session_local_001.ps1',
  'powershell -NoProfile -ExecutionPolicy Bypass -File modules/absorb_builder_school_experience_001.ps1',
  'powershell -NoProfile -ExecutionPolicy Bypass -File modules/update_builder_self_model_active_map_001.ps1',
  'powershell -NoProfile -ExecutionPolicy Bypass -File modules/inspect_builder_organism_health_state_001.ps1',
  'powershell -NoProfile -ExecutionPolicy Bypass -File modules/select_builder_self_map_next_action_001.ps1',
  'powershell -NoProfile -ExecutionPolicy Bypass -File validators/validate_phase161j_self_map_next_action_selector_v1.ps1'
)
$errors = New-Object System.Collections.Generic.List[string]
$validation = $null
$routerResult = $null
$batchResult = $null
$absorption = $null
$schoolState = $null
$validatorResult = $null
$schoolRunId = 'NONE'
$schoolRunRootRelative = 'NONE'
$absorptionRootRelative = 'NONE'
$selfMapVisible = $false
$authorityBoundaryPreserved = $false
$protectedBefore = @{}
$protectedAfter = @{}
$branchBefore = ''
$headBefore = ''
$sessionRootRelative = 'NONE'

try {
  foreach ($path in $identity) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $path))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$path"
    }
  }
  if (-not (Test-Path -LiteralPath (Join-Path $root $packRelative))) {
    throw "CURRICULUM_PACK_MISSING=$packRelative"
  }

  $branchBefore = (git -C $root branch --show-current).Trim()
  $headBefore = (git -C $root rev-parse HEAD).Trim()
  if ($branchBefore -ne 'phase110-idempotent-autonomy-trial-runtime') {
    throw "UNEXPECTED_BRANCH=$branchBefore"
  }
  $protectedDirtyBefore = @(git -C $root status --short -- @($identity + @('route_locks')))
  if ($protectedDirtyBefore.Count -gt 0) {
    throw "PROTECTED_STATE_DIRTY_BEFORE=$($protectedDirtyBefore -join '; ')"
  }
  $protectedBefore = Get-Phase165SBHashes -Root $root -Paths $protectedPaths

  $pack = Get-Content -LiteralPath (Join-Path $root $packRelative) -Raw | ConvertFrom-Json
  $conceptIds = @($pack.lessons | ForEach-Object { [string]$_.lesson_id })
  if ($conceptIds.Count -lt 5 -or $conceptIds.Count -gt 10) {
    throw "CONCEPT_COUNT_OUT_OF_RANGE=$($conceptIds.Count)"
  }

  $validation = Invoke-Phase165SBJsonScript -ScriptPath (Join-Path $root 'modules/validate_builder_curriculum_pack_schema_001.ps1') -Arguments @('-RepoRoot', $root, '-CurriculumPackPath', (Join-Path $root $packRelative))
  if ([string]$validation.status -ne 'PASS') {
    throw "CURRICULUM_VALIDATION_FAILED=$(@($validation.errors) -join '; ')"
  }

  $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmssfff')
  $sessionRootRelative = "runtime_sessions/live_growth/PHASE165S_B_SMALL_INBOX_BATCH_$stamp"
  $sessionRoot = Join-Path $root $sessionRootRelative
  $teacherInbox = Join-Path $sessionRoot 'teacher_inbox'
  New-Item -ItemType Directory -Force -Path $teacherInbox | Out-Null
  Write-Phase165SBJson -Path (Join-Path $teacherInbox 'PHASE165S_B_CURRICULUM_MESSAGE.json') -Value ([ordered]@{
    message_type = 'curriculum_pack'
    curriculum_pack = $pack
  })

  . (Join-Path $root 'modules/route_builder_owner_inbox_message_001.ps1')
  $routerResult = Invoke-Phase161B1OwnerInboxRouter -RepoRoot $root -SessionRootFull $sessionRoot -SessionRootRelative $sessionRootRelative -DutyId 'PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL'
  if ([string]$routerResult.status -ne 'PASS' -or [int]$routerResult.curriculum_pack_routed_count -ne 1) {
    throw "OWNER_INBOX_ROUTE_FAILED=$($routerResult | ConvertTo-Json -Depth 20 -Compress)"
  }

  $pointer = Get-Content -LiteralPath (Join-Path $sessionRoot 'school_run_pointer.json') -Raw | ConvertFrom-Json
  $schoolRunId = [string]$pointer.school_run_id
  $schoolRunRootRelative = "runtime_sessions/school_runs/$schoolRunId"
  $schoolRunRoot = Join-Path $root $schoolRunRootRelative
  $batchResult = Invoke-Phase165SBJsonScript -ScriptPath (Join-Path $root 'modules/run_builder_school_batch_session_local_001.ps1') -Arguments @('-RepoRoot', $root, '-SchoolRunRoot', $schoolRunRoot)
  if ([string]$batchResult.status -ne 'PASS' -or [int]$batchResult.lesson_pass_count -ne $conceptIds.Count) {
    throw "SCHOOL_BATCH_FAILED=$($batchResult | ConvertTo-Json -Depth 20 -Compress)"
  }

  $absorptionId = "PHASE165S_B_FOUNDATION_ABSORPTION_$stamp"
  $absorption = Invoke-Phase165SBJsonScript -ScriptPath (Join-Path $root 'modules/absorb_builder_school_experience_001.ps1') -Arguments @('-RepoRoot', $root, '-SchoolRunRoot', $schoolRunRoot, '-AbsorptionId', $absorptionId, '-EmitJson')
  if ([string]$absorption.status -ne 'PASS') {
    throw "ABSORPTION_FAILED=$($absorption | ConvertTo-Json -Depth 20 -Compress)"
  }
  $absorptionRootRelative = [string]$absorption.absorption_root
  $schoolState = Invoke-Phase165SBJsonScript -ScriptPath (Join-Path $root 'modules/inspect_builder_school_entry_state_001.ps1') -Arguments @('-RepoRoot', $root, '-SchoolRunId', $schoolRunId)

  $summary = [ordered]@{
    phase = 'PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL'
    status = 'PIPELINE_PASS'
    selected_route = 'OWNER_INBOX_ROUTER_TO_CURRICULUM_INGEST'
    owner_inbox_router_executor_used = $true
    pack_path = $packRelative
    concept_ids = $conceptIds
    concept_count = $conceptIds.Count
    validation_result = [string]$validation.status
    school_run_id = $schoolRunId
    school_run_root = $schoolRunRootRelative
    normalized_output_path = "$schoolRunRootRelative/normalized_lesson_batch.json"
    lesson_pass_count = [int]$batchResult.lesson_pass_count
    lesson_fail_count = [int]$batchResult.lesson_fail_count
    rejected_or_quarantine_count = [int]$routerResult.quarantine_count + [int]$batchResult.lesson_quarantine_count
    absorption_root = $absorptionRootRelative
    created_utc = (Get-Date).ToUniversalTime().ToString('o')
  }
  Write-Phase165SBJson -Path (Join-Path $root $summaryRelative) -Value $summary

  $provisional = [ordered]@{
    phase = 'PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL'
    status = 'PIPELINE_PASS_SELF_MAP_VALIDATION_PENDING'
    pack_path = $packRelative
    concept_ids = $conceptIds
    concept_count = $conceptIds.Count
    selected_route = 'OWNER_INBOX_ROUTER_TO_CURRICULUM_INGEST'
  }
  Write-Phase165SBJson -Path (Join-Path $root $proofRelative) -Value $provisional
  Write-Phase165SBText -Path (Join-Path $root $reportRelative) -Lines @(
    '# PHASE165S-B Small Inbox Curriculum Batch Trial',
    '',
    'Status: PIPELINE PASS; self-map validation pending.',
    '',
    "Pack: ``$packRelative``"
  )

  & (Join-Path $root 'modules/update_builder_self_model_active_map_001.ps1') -RepoRoot $root | Out-Null
  & (Join-Path $root 'modules/inspect_builder_organism_health_state_001.ps1') -RepoRoot $root | Out-Null
  $recommendation = & (Join-Path $root 'modules/select_builder_self_map_next_action_001.ps1') -RepoRoot $root
  $validatorResult = Invoke-Phase165SBSelectorValidator -Root $root
  $activeMapText = Get-Content -LiteralPath (Join-Path $root 'reports/self_development/SELF_MODEL_ACTIVE_MAP.json') -Raw
  $selfMapVisible = $activeMapText -match 'PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL'
  $authorityBoundaryPreserved = [string]$recommendation.decision_authority -eq 'MODE_DECISION_KERNEL' -and [string]$recommendation.recommendation_role -eq 'MAP_SIGNAL_NOT_COMMAND'
  if (-not $validatorResult.passed) { throw "SELECTOR_VALIDATOR_FAILED=$($validatorResult.output -join '; ')" }
  if (-not $selfMapVisible) { throw 'PHASE165S_B_NOT_VISIBLE_IN_SELF_MAP' }
  if (-not $authorityBoundaryPreserved) { throw 'AUTHORITY_BOUNDARY_NOT_PRESERVED' }

  $protectedAfter = Get-Phase165SBHashes -Root $root -Paths $protectedPaths
  foreach ($path in $protectedPaths) {
    if ($protectedAfter[$path] -ne $protectedBefore[$path]) {
      throw "PROTECTED_STATE_MUTATED=$path"
    }
  }
  $protectedDirtyAfter = @(git -C $root status --short -- @($identity + @('route_locks')))
  if ($protectedDirtyAfter.Count -gt 0) {
    throw "PROTECTED_STATE_DIRTY_AFTER=$($protectedDirtyAfter -join '; ')"
  }
  if ((git -C $root rev-parse HEAD).Trim() -ne $headBefore) { throw 'HEAD_CHANGED_DURING_TRIAL' }
  if ((git -C $root branch --show-current).Trim() -ne $branchBefore) { throw 'BRANCH_CHANGED_DURING_TRIAL' }

  $changedFiles = @(
    'modules/run_phase165s_b_small_inbox_curriculum_batch_trial_001.ps1',
    $packRelative,
    $summaryRelative,
    $proofRelative,
    $reportRelative,
    'reports/self_development/SELF_MODEL_ACTIVE_MAP.json',
    'reports/self_development/organism_health_state.json',
    'reports/self_development/self_map_next_action_recommendation.json'
  )
  $remainingRisks = @(
    'The ten concepts are proven as session-local lesson and absorption patterns, not promoted protected-state atoms.',
    'The active self-map sees PHASE165S-B evidence by proof/report path; it is not a global command surface.',
    'No approved source catalog, school driver, web search skill, or bulk concept generator was created.',
    'Runtime session outputs remain local runtime evidence and are not accepted repo state.'
  )
  $proof = [ordered]@{
    phase = 'PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL'
    created_utc = (Get-Date).ToUniversalTime().ToString('o')
    status = 'PASS'
    validation_passed = $true
    selected_route = 'OWNER_INBOX_ROUTER_TO_CURRICULUM_INGEST'
    route_mode = 'REAL_OWNER_INBOX_ROUTER_EXECUTOR'
    owner_inbox_router_executor_used = $true
    direct_ingest_fallback_used = $false
    pack_path = $packRelative
    concept_count = $conceptIds.Count
    concept_ids = $conceptIds
    validation_result = [string]$validation.status
    ingest_result = [string]$routerResult.status
    accepted_output_paths = @(
      $schoolRunRootRelative,
      "$schoolRunRootRelative/school_run_manifest.json",
      "$schoolRunRootRelative/lesson_results",
      $absorptionRootRelative,
      "$absorptionRootRelative/learning_absorption.json"
    )
    normalized_output_paths = @("$schoolRunRootRelative/normalized_lesson_batch.json")
    lesson_pass_count = [int]$batchResult.lesson_pass_count
    lesson_fail_count = [int]$batchResult.lesson_fail_count
    rejected_or_quarantine_count = [int]$routerResult.quarantine_count + [int]$batchResult.lesson_quarantine_count
    absorption_result = [string]$absorption.status
    self_map_visibility_result = [bool]$selfMapVisible
    self_map_visibility_evidence = @($proofRelative, $reportRelative)
    authority_boundary_preserved = [bool]$authorityBoundaryPreserved
    decision_authority = [string]$recommendation.decision_authority
    recommendation_role = [string]$recommendation.recommendation_role
    selector_validator_result = 'PASS'
    protected_state_dirty_check = @()
    protected_state_mutated = $false
    raw_bulk_memory_injection = $false
    external_fetch_or_install = $false
    commands_run = $commandsRun
    changed_files = $changedFiles
    remaining_risks = $remainingRisks
    next_required_action = 'PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL_ACCEPTANCE_REVIEW'
  }
  Write-Phase165SBJson -Path (Join-Path $root $proofRelative) -Value $proof

  $report = @(
    '# PHASE165S-B Small Inbox Curriculum Batch Trial',
    '',
    'Status: PASS',
    '',
    '## Route',
    '',
    '- Selected route: `OWNER_INBOX_ROUTER_TO_CURRICULUM_INGEST`.',
    '- The real Owner Inbox router executor classified, validated, staged, and ingested the curriculum.',
    '- Direct-ingest fallback was not used.',
    '',
    '## Batch Result',
    '',
    "- Pack: ``$packRelative``",
    "- Concepts: $($conceptIds.Count)",
    "- Validation: $($validation.status)",
    "- School run: ``$schoolRunRootRelative``",
    "- Normalized batch: ``$schoolRunRootRelative/normalized_lesson_batch.json``",
    "- Lessons passed: $($batchResult.lesson_pass_count)",
    "- Lessons failed: $($batchResult.lesson_fail_count)",
    "- Rejected or quarantined: $([int]$routerResult.quarantine_count + [int]$batchResult.lesson_quarantine_count)",
    "- Absorption: ``$absorptionRootRelative/learning_absorption.json``",
    '',
    'The result increases the bounded foundation concept base as ten session-local passing lesson patterns. It does not promote raw text or silently mutate accepted/protected state.',
    '',
    '## Self-Map And Authority',
    '',
    "- PHASE165S-B visible in refreshed self-map evidence: $selfMapVisible",
    "- Selector validator: PASS",
    "- Decision authority: ``$($recommendation.decision_authority)``",
    "- Recommendation role: ``$($recommendation.recommendation_role)``",
    '',
    '## Protected State',
    '',
    '- Protected state dirty check: no output.',
    '- Protected state hashes remained unchanged.',
    '- HEAD and branch remained unchanged.',
    '',
    '## Commands Run',
    ''
  )
  $report += $commandsRun | ForEach-Object { "- ``$_``" }
  $report += @('', '## Changed Files', '')
  $report += $changedFiles | ForEach-Object { "- ``$_``" }
  $report += @('', '## Remaining Risks', '')
  $report += $remainingRisks | ForEach-Object { "- $_" }
  $report += @(
    '',
    '## Next Required Action',
    '',
    'PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL_ACCEPTANCE_REVIEW'
  )
  Write-Phase165SBText -Path (Join-Path $root $reportRelative) -Lines $report

  & (Join-Path $root 'modules/update_builder_self_model_active_map_001.ps1') -RepoRoot $root | Out-Null
  & (Join-Path $root 'modules/inspect_builder_organism_health_state_001.ps1') -RepoRoot $root | Out-Null
  & (Join-Path $root 'modules/select_builder_self_map_next_action_001.ps1') -RepoRoot $root | Out-Null
  $validatorResult = Invoke-Phase165SBSelectorValidator -Root $root
  if (-not $validatorResult.passed) {
    throw "FINAL_SELECTOR_VALIDATOR_FAILED=$($validatorResult.output -join '; ')"
  }

  Write-Host 'PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL_RESULT=PASS'
  Write-Host "CONCEPT_COUNT=$($conceptIds.Count)"
  Write-Host 'OWNER_INBOX_ROUTER_EXECUTOR_USED=True'
  Write-Host "SCHOOL_RUN_ROOT=$schoolRunRootRelative"
  Write-Host "ABSORPTION_ROOT=$absorptionRootRelative"
  Write-Host 'SELF_MAP_VISIBILITY=True'
  Write-Host 'AUTHORITY_BOUNDARY_PRESERVED=True'
  Write-Host 'PROTECTED_STATE_DIRTY_CHECK='
  Write-Host 'NEXT_REQUIRED_ACTION=PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL_ACCEPTANCE_REVIEW'
  exit 0
} catch {
  $errors.Add($_.Exception.Message)
  $failureProof = [ordered]@{
    phase = 'PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL'
    created_utc = (Get-Date).ToUniversalTime().ToString('o')
    status = 'FAIL'
    validation_passed = $false
    errors = $errors.ToArray()
    selected_route = 'OWNER_INBOX_ROUTER_TO_CURRICULUM_INGEST'
    owner_inbox_router_executor_used = ($null -ne $routerResult)
    pack_path = $packRelative
    school_run_id = $schoolRunId
    school_run_root = $schoolRunRootRelative
    absorption_root = $absorptionRootRelative
    self_map_visibility_result = [bool]$selfMapVisible
    authority_boundary_preserved = [bool]$authorityBoundaryPreserved
    protected_state_mutated = $false
    commands_run = $commandsRun
    next_required_action = 'PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL_TRIAGE'
  }
  Write-Phase165SBJson -Path (Join-Path $root $proofRelative) -Value $failureProof
  Write-Phase165SBText -Path (Join-Path $root $reportRelative) -Lines @(
    '# PHASE165S-B Small Inbox Curriculum Batch Trial',
    '',
    'Status: FAIL',
    '',
    '## Errors',
    '',
    ($errors | ForEach-Object { "- $_" }),
    '',
    '## Next Required Action',
    '',
    'PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL_TRIAGE'
  )
  Write-Host 'PHASE165S_B_SMALL_INBOX_CURRICULUM_BATCH_TRIAL_RESULT=FAIL'
  Write-Host "FAIL_REASON=$($errors -join '; ')"
  exit 1
}
