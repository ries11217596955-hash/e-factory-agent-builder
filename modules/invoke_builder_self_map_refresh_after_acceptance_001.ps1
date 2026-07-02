param(
  [Parameter(Mandatory=$true)][string]$AcceptedSubjectHead,
  [string]$AcceptedPhase = 'PHASE161E_SELF_MAP_AUTO_REFRESH_AFTER_ACCEPTED_CHANGE',
  [string]$TriggerReason = 'accepted_baseline_refresh',
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = 'reports/self_development'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Write-BuilderJsonFile {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)]$Value,
    [int]$Depth = 30
  )
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
  $Value | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Set-BuilderProperty {
  param(
    [Parameter(Mandatory=$true)]$Object,
    [Parameter(Mandatory=$true)][string]$Name,
    $Value
  )
  if ($Object.PSObject.Properties.Name -contains $Name) {
    $Object.$Name = $Value
  } else {
    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
  }
}

function Get-BuilderGitValue {
  param([string]$Root, [string[]]$Arguments)
  try {
    return (& git -C $Root @Arguments 2>$null | Select-Object -First 1)
  } catch {
    return $null
  }
}

$root = (Resolve-Path $RepoRoot).Path
$outputFull = Join-Path $root $OutputRoot
if (-not (Test-Path -LiteralPath $outputFull)) {
  New-Item -ItemType Directory -Path $outputFull | Out-Null
}

$policy = [pscustomobject][ordered]@{
  policy_id = 'PHASE161E_SELF_MAP_REFRESH_AFTER_ACCEPTED_CHANGE_POLICY_V1'
  policy_name = 'Self-map refresh after accepted commit'
  required_after_accepted_commit = $true
  passive_stale_allowed = $false
  refresh_before_next_decision = $true
  protected_state_direct_mutation_allowed = $false
  derived_map_allowed = $true
  map_artifact_commit_pending_allowed = $true
  next_decision_requires_self_knowledge_ready = $true
  owner_approval_required_for_protected_state_promotion = $true
}
Write-BuilderJsonFile -Path (Join-Path $outputFull 'self_map_refresh_policy.json') -Value $policy

$selectorPolicy = [pscustomobject][ordered]@{
  schema = 'efab_self_map_next_action_selector_policy_v1'
  policy_id = 'PHASE161J_SELF_MAP_NEXT_ACTION_SELECTOR_POLICY_V1'
  selector_version = 'PHASE161J_SELF_MAP_NEXT_ACTION_SELECTOR_V1'
  status = 'ACTIVE_FOR_SELF_MAP_REFRESH'
  generated_by = 'invoke_builder_self_map_refresh_after_acceptance_001.ps1'
  trigger_reason = $TriggerReason
  accepted_phase = $AcceptedPhase
  accepted_subject_head = $AcceptedSubjectHead
  map_updates_bulk_atoms = $false
  map_updates_on = @('new_organ','new_module','new_capability','new_routing_surface','accepted_functional_change')
  map_does_not_update_on = @('bulk_atom_delta','ready_atoms_only','batch_report_only')
  created_at = (Get-Date).ToUniversalTime().ToString('o')
}
Write-BuilderJsonFile -Path (Join-Path $outputFull 'self_map_next_action_selector_policy.json') -Value $selectorPolicy

$builder = Join-Path $PSScriptRoot 'build_builder_agent_body_map_001.ps1'
if (-not (Test-Path -LiteralPath $builder)) {
  throw 'PHASE161D body map builder missing.'
}
$buildResult = & $builder -RepoRoot $root -OutputRoot $OutputRoot -Build | ConvertFrom-Json

$generatedHead = Get-BuilderGitValue -Root $root -Arguments @('rev-parse','HEAD')
$worktreeStatus = @(git -C $root status --short 2>$null)
$mapArtifactCommitPending = ($worktreeStatus.Count -gt 0)

$activeRouteLock = $null
$routePath = Join-Path $root 'route_locks/ACTIVE_ROUTE_LOCK.json'
if (Test-Path -LiteralPath $routePath) {
  try {
    $route = Get-Content -LiteralPath $routePath -Raw | ConvertFrom-Json
    $activeRouteLock = $route.active_route_lock_file
  } catch {
    $activeRouteLock = $null
  }
}

$hardeningPath = Join-Path $outputFull 'agent_body_map_classifier_hardening_result.json'
$hardening = Get-Content -LiteralPath $hardeningPath -Raw | ConvertFrom-Json
$gapPath = Join-Path $outputFull 'self_model_gap_chain.json'
$gaps = Get-Content -LiteralPath $gapPath -Raw | ConvertFrom-Json
$historicalPath = Join-Path $outputFull 'historical_reference_inventory.json'
$historical = Get-Content -LiteralPath $historicalPath -Raw | ConvertFrom-Json

$healthModule = Join-Path $PSScriptRoot 'inspect_builder_organism_health_state_001.ps1'
$selectorModule = Join-Path $PSScriptRoot 'select_builder_self_map_next_action_001.ps1'
if (-not (Test-Path -LiteralPath $healthModule)) {
  throw 'PHASE161J organism health module missing.'
}
if (-not (Test-Path -LiteralPath $selectorModule)) {
  throw 'PHASE161J next action selector module missing.'
}
$health = & $healthModule -RepoRoot $root -OutputRoot $OutputRoot
$recommendation = & $selectorModule -RepoRoot $root -OutputRoot $OutputRoot

$recommendedTasks = @()
$recommendedTasks = @([pscustomobject]@{
  gap_id = $recommendation.recommendation_id
  recommended_next_action = $recommendation.recommended_next_macro_step
  why_status = $recommendation.why_this_step
  recommended_next_phase_id = $recommendation.recommended_next_phase_id
  next_action_type = $recommendation.next_action_type
})

$protectedStatus = @(git -C $root status --short -- TASK_QUEUE.json GENESIS_STATE.json CAPABILITY_ROADMAP.json packs/registry.json orchestrator/run.ps1 2>$null)
$runtimeStatus = @(git -C $root status --short -- runtime_sessions 2>$null)

$result = [pscustomobject][ordered]@{
  refresh_id = ('PHASE161E_REFRESH_' + (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss'))
  accepted_subject_head = $AcceptedSubjectHead
  accepted_phase = $AcceptedPhase
  trigger_reason = $TriggerReason
  generated_from_worktree_head = $generatedHead
  map_artifact_head = $null
  map_artifact_commit_pending = $mapArtifactCommitPending
  map_refresh_status = 'SELF_KNOWLEDGE_READY'
  self_knowledge_ready = $true
  map_is_ready_for_next_decision = $true
  active_route_lock = $activeRouteLock
  active_organs_count = [int]$hardening.active_wired_proven_count
  present_not_wired_count = [int]$hardening.present_not_wired_count
  historical_reference_count = @(if ($historical.items) { $historical.items } else { @() }).Count
  superseded_count = [int]$hardening.superseded_count
  real_stub_count = [int]$hardening.real_stub_count
  false_positive_stub_count = [int]$hardening.false_positive_stub_count
  gap_chain_count = @($gaps.gaps).Count
  organism_health_state = $health.health_state
  health_score = [int]$health.health_score
  recommended_next_macro_step = $recommendation.recommended_next_macro_step
  recommended_next_phase_id = $recommendation.recommended_next_phase_id
  next_action_type = $recommendation.next_action_type
  recommended_next_learning_tasks = @($recommendedTasks)
  protected_state_mutated = ($protectedStatus.Count -gt 0)
  runtime_outputs_staged = ($runtimeStatus.Count -gt 0)
  refresh_result_path = 'reports/self_development/self_map_refresh_after_acceptance_result.json'
  memory_report_path = 'reports/self_development/self_map_memory_report.md'
  policy_path = 'reports/self_development/self_map_refresh_policy.json'
  created_at = (Get-Date).ToUniversalTime().ToString('o')
}

$activeMapPath = Join-Path $outputFull 'SELF_MODEL_ACTIVE_MAP.json'
$activeMap = Get-Content -LiteralPath $activeMapPath -Raw | ConvertFrom-Json
Set-BuilderProperty -Object $activeMap -Name 'phase' -Value 'PHASE161E_SELF_MAP_AUTO_REFRESH_AFTER_ACCEPTED_CHANGE_V1'
Set-BuilderProperty -Object $activeMap -Name 'classifier_version' -Value 'PHASE161D_STRICT_EVIDENCE_V1_PLUS_PHASE161E_REFRESH_V1'
Set-BuilderProperty -Object $activeMap -Name 'self_map_refresh_policy_id' -Value $policy.policy_id
Set-BuilderProperty -Object $activeMap -Name 'accepted_subject_head' -Value $AcceptedSubjectHead
Set-BuilderProperty -Object $activeMap -Name 'generated_from_worktree_head' -Value $generatedHead
Set-BuilderProperty -Object $activeMap -Name 'map_artifact_head' -Value $null
Set-BuilderProperty -Object $activeMap -Name 'map_artifact_commit_pending' -Value $mapArtifactCommitPending
Set-BuilderProperty -Object $activeMap -Name 'map_refresh_status' -Value 'SELF_KNOWLEDGE_READY'
Set-BuilderProperty -Object $activeMap -Name 'self_knowledge_ready' -Value $true
Set-BuilderProperty -Object $activeMap -Name 'map_is_ready_for_next_decision' -Value $true
Set-BuilderProperty -Object $activeMap -Name 'active_route_lock' -Value $activeRouteLock
Set-BuilderProperty -Object $activeMap -Name 'memory_report_path' -Value 'reports/self_development/self_map_memory_report.md'
Set-BuilderProperty -Object $activeMap -Name 'refresh_result_path' -Value 'reports/self_development/self_map_refresh_after_acceptance_result.json'
Set-BuilderProperty -Object $activeMap -Name 'next_decision_reason' -Value 'Self-map refresh succeeded after accepted change; next decision can use current strict map memory.'
Set-BuilderProperty -Object $activeMap -Name 'recommended_next_learning_tasks' -Value @($recommendedTasks)
Set-BuilderProperty -Object $activeMap -Name 'organism_health_state' -Value $health.health_state
Set-BuilderProperty -Object $activeMap -Name 'health_score' -Value ([int]$health.health_score)
Set-BuilderProperty -Object $activeMap -Name 'recommended_next_macro_step' -Value $recommendation.recommended_next_macro_step
Set-BuilderProperty -Object $activeMap -Name 'recommended_next_phase_id' -Value $recommendation.recommended_next_phase_id
Set-BuilderProperty -Object $activeMap -Name 'next_action_type' -Value $recommendation.next_action_type
Set-BuilderProperty -Object $activeMap -Name 'selector_policy_id' -Value 'PHASE161J_SELF_MAP_NEXT_ACTION_SELECTOR_POLICY_V1'
Set-BuilderProperty -Object $activeMap -Name 'blocked_old_recommendations' -Value @($recommendation.blocked_old_recommendations)
Set-BuilderProperty -Object $activeMap -Name 'candidate_actions_considered' -Value @($recommendation.candidate_actions_considered)
Set-BuilderProperty -Object $activeMap -Name 'next_decision_reason' -Value $recommendation.why_this_step
Write-BuilderJsonFile -Path $activeMapPath -Value $activeMap

Write-BuilderJsonFile -Path (Join-Path $outputFull 'self_map_refresh_after_acceptance_result.json') -Value $result

$writer = Join-Path $PSScriptRoot 'write_builder_self_map_memory_report_001.ps1'
& $writer -RepoRoot $root -OutputRoot $OutputRoot -AcceptedSubjectHead $AcceptedSubjectHead -AcceptedPhase $AcceptedPhase -RefreshResultPath $result.refresh_result_path | Out-Null

$snapshotBuilder = Join-Path $PSScriptRoot 'build_builder_accepted_change_memory_snapshot_001.ps1'
& $snapshotBuilder -RepoRoot $root -OutputRoot $OutputRoot -AcceptedSubjectHead $AcceptedSubjectHead -AcceptedPhase $AcceptedPhase -CommitMessageOrPhaseLabel $AcceptedPhase -MapRefreshResultPath $result.refresh_result_path | Out-Null

$result
