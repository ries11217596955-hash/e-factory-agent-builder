param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = 'reports/self_development'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-SelectorJson {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Set-SelectorProperty {
  param($Object, [string]$Name, $Value)
  if ($Object.PSObject.Properties.Name -contains $Name) { $Object.$Name = $Value }
  else { $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value }
}

function Write-SelectorJson {
  param([string]$Path, $Value)
  $Value | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $Path -Encoding UTF8
}

$root = (Resolve-Path $RepoRoot).Path
$output = Join-Path $root $OutputRoot
$policy = Get-SelectorJson (Join-Path $output 'self_map_next_action_selector_policy.json')
$health = Get-SelectorJson (Join-Path $output 'organism_health_state.json')
$active = Get-SelectorJson (Join-Path $output 'SELF_MODEL_ACTIVE_MAP.json')
$gaps = Get-SelectorJson (Join-Path $output 'self_model_gap_chain.json')
$liveIndex = Get-SelectorJson (Join-Path $output 'live_evidence_separation_index.json')
$snapshot = Get-SelectorJson (Join-Path $output 'accepted_change_memory_snapshot.json')
$routeIndex = Get-SelectorJson (Join-Path $root 'route_locks/ACTIVE_ROUTE_LOCK.json')
$g2 = Get-SelectorJson (Join-Path $output 'protected_state_update_candidates/PHASE161G2_APPLY_RESULT.json')
$delayed = Get-SelectorJson (Join-Path $output 'protected_state_update_candidates/PHASE161G1_DELAYED_OR_BLOCKED_SCOPE.json')
$phase165qProofPath = Join-Path $root 'proofs/self_development/PHASE165Q_BUILDER_SELF_MAP_ROUTE_RECONCILIATION_V1.json'
$phase165q = Get-SelectorJson $phase165qProofPath

if (-not $policy) { throw 'Selector policy missing.' }
if (-not $health) { throw 'Organism health state missing.' }
if (-not $active) { throw 'SELF_MODEL_ACTIVE_MAP missing.' }

$fManifest = Test-Path -LiteralPath (Join-Path $output 'protected_state_update_candidates/PHASE161F_PROMOTION_MANIFEST.json')
$g1Proof = Test-Path -LiteralPath (Join-Path $root 'proofs/self_development/PHASE161G1_LIMITED_PROTECTED_SELF_MODEL_COMPATIBILITY_PROOF.json')
$g2Applied = $g2 -and $g2.apply_status -eq 'PASS' -and $g2.genesis_state_reference_applied -and $g2.capability_roadmap_reference_applied

$completed = New-Object System.Collections.Generic.List[object]
if ($fManifest) { $completed.Add([pscustomobject]@{ phase='PHASE161F'; status='COMPLETED'; evidence='reports/self_development/protected_state_update_candidates/PHASE161F_PROMOTION_MANIFEST.json' }) }
if ($g1Proof) { $completed.Add([pscustomobject]@{ phase='PHASE161G1'; status='COMPLETED'; evidence='proofs/self_development/PHASE161G1_LIMITED_PROTECTED_SELF_MODEL_COMPATIBILITY_PROOF.json' }) }
if ($g2Applied) { $completed.Add([pscustomobject]@{ phase='PHASE161G2'; status='COMPLETED_LIMITED_APPLY'; evidence='reports/self_development/protected_state_update_candidates/PHASE161G2_APPLY_RESULT.json' }) }

$blockedOld = New-Object System.Collections.Generic.List[object]
if ($g2Applied) {
  $blockedOld.Add([pscustomobject]@{
    recommendation = 'Review derived SELF_MODEL_ACTIVE_MAP.json and approve a later protected-state update candidate if desired.'
    reason = 'PHASE161F, PHASE161G1, and PHASE161G2 completed candidate creation, review, and the approved limited apply.'
    status = 'STALE_COMPLETED_RECOMMENDATION'
  })
}

$delayedByTarget = @{}
if ($delayed -and $delayed.items) {
  foreach ($item in $delayed.items) { $delayedByTarget[$item.target_file] = $item.decision }
}

$candidates = New-Object System.Collections.Generic.List[object]
$phase165qReconciled = $phase165q -and $phase165q.status -eq 'PASS' -and
  $phase165q.route_decision -eq 'READY_FOR_FIRST_LIVE_ATOM_GROWTH_MICRO_TRIAL'
$routePending = $routeIndex -and
  $routeIndex.next_target_phase -eq 'PHASE161_BATCH_SCHOOL_FOUNDATION' -and
  -not $phase165qReconciled
if ($phase165qReconciled) {
  $candidates.Add([pscustomobject][ordered]@{
    action_id = 'PHASE165Q_RECONCILED_LIVE_ATOM_GROWTH_SIGNAL'
    macro_step = 'Use PHASE165Q reconciliation as a diagnostic signal for the Mode Decision Kernel to consider the first live atom growth micro-trial.'
    recommended_phase_id = [string]$phase165q.next_required_action
    priority_class = 'REQUIRED_LIVE_PROOF_FOR_ACTIVE_ORGAN'
    next_action_type = 'MAP_SIGNAL'
    score = 90
    route_relevant = $true
    owner_approval_required = $false
    reason = 'PHASE165Q passed route reconciliation and recorded readiness for the first live atom growth micro-trial. This is a map signal, not execution authority.'
  })
}
if ($routePending) {
  $candidates.Add([pscustomobject][ordered]@{
    action_id = 'PHASE161J_ROUTE_EXHAUSTION_LIVE_EVIDENCE_RECONCILIATION'
    macro_step = 'Reconcile accepted PHASE161 school/live evidence against the active route exhaustion rule and produce the next owner route-decision candidate.'
    recommended_phase_id = 'PHASE161K_ACTIVE_ROUTE_EXHAUSTION_AND_LIVE_EVIDENCE_RECONCILIATION'
    priority_class = 'REQUIRED_LIVE_PROOF_FOR_ACTIVE_ORGAN'
    next_action_type = 'OBSERVE'
    score = 82
    route_relevant = $true
    owner_approval_required = $false
    reason = 'The active route remains PHASE161 batch school prep and explicitly requires live smoke/exhaustion evidence before route transition.'
  })
}
$candidates.Add([pscustomobject][ordered]@{
  action_id = 'TASK_QUEUE_CONSUMER_COMPATIBILITY'
  macro_step = 'Prove TASK_QUEUE consumer compatibility before any delayed queue metadata apply.'
  recommended_phase_id = 'PHASE161K1_TASK_QUEUE_CONSUMER_COMPATIBILITY_PROOF'
  priority_class = 'REQUIRED_CONSUMER_COMPATIBILITY_FOR_ACTIVE_PATH'
  next_action_type = 'COMPATIBILITY_PROOF'
  score = 54
  route_relevant = $false
  owner_approval_required = $true
  status = $(if ($delayedByTarget['TASK_QUEUE.json']) { $delayedByTarget['TASK_QUEUE.json'] } else { 'DELAY' })
  reason = 'Queue behavior affects scheduling, but G1 explicitly delayed it and it is not the current route blocker.'
})
$candidates.Add([pscustomobject][ordered]@{
  action_id = 'PACK_REGISTRY_ADMISSION'
  macro_step = 'Keep packs registry admission delayed until a real executable pack and admission proof exist.'
  recommended_phase_id = 'UNSCHEDULED'
  priority_class = 'OWNER_APPROVAL_BACKLOG'
  next_action_type = 'COMPATIBILITY_PROOF'
  score = 24
  route_relevant = $false
  owner_approval_required = $true
  status = $(if ($delayedByTarget['packs/registry.json']) { $delayedByTarget['packs/registry.json'] } else { 'DELAY' })
  reason = 'Registry admission without a real pack would create false wiring.'
})
$candidates.Add([pscustomobject][ordered]@{
  action_id = 'ORCHESTRATOR_PROTECTED_METADATA_CHANGE'
  macro_step = 'Do not change orchestrator flow for protected self-model metadata.'
  recommended_phase_id = 'NONE'
  priority_class = 'OWNER_APPROVAL_BACKLOG'
  next_action_type = 'NO_REQUIRED_REPAIR'
  score = 0
  route_relevant = $false
  owner_approval_required = $true
  status = $(if ($delayedByTarget['orchestrator/run.ps1']) { $delayedByTarget['orchestrator/run.ps1'] } else { 'REJECT' })
  reason = 'G1 rejected an orchestrator change because protected metadata does not justify flow mutation.'
})
$candidates.Add([pscustomobject][ordered]@{
  action_id = 'BULK_HISTORICAL_CLEANUP'
  macro_step = 'Optionally review historical artifacts after current route decisions are complete.'
  recommended_phase_id = 'UNSCHEDULED_OPTIONAL_CLEANUP'
  priority_class = 'OPTIONAL_HISTORICAL_CLEANUP'
  next_action_type = 'CLEANUP'
  score = 5
  route_relevant = $false
  owner_approval_required = $true
  reason = 'Historical presence does not block current operation.'
})

$selected = @($candidates | Sort-Object @{Expression='score';Descending=$true}, action_id | Select-Object -First 1)[0]
if ($health.health_state -eq 'HEALTHY' -and -not $routePending) {
  $selected = [pscustomobject][ordered]@{
    action_id = 'NO_REQUIRED_REPAIR'
    macro_step = $policy.default_next_action_when_healthy
    recommended_phase_id = 'NONE'
    priority_class = 'OPTIONAL_HISTORICAL_CLEANUP'
    next_action_type = 'NO_REQUIRED_REPAIR'
    score = 0
    route_relevant = $true
    owner_approval_required = $false
    reason = 'Strict healthy criteria are met and remaining improvements are optional.'
  }
}

$evidencePaths = @(
  'reports/self_development/SELF_MODEL_ACTIVE_MAP.json',
  'reports/self_development/self_model_gap_chain.json',
  'reports/self_development/live_evidence_separation_index.json',
  'reports/self_development/accepted_change_memory_snapshot.json',
  'reports/self_development/protected_state_update_candidates/PHASE161G2_APPLY_RESULT.json',
  'reports/self_development/protected_state_update_candidates/PHASE161G1_DELAYED_OR_BLOCKED_SCOPE.json',
  'route_locks/ACTIVE_ROUTE_LOCK.json',
  'proofs/self_development/PHASE165Q_BUILDER_SELF_MAP_ROUTE_RECONCILIATION_V1.json',
  'reports/self_development/PHASE165Q_BUILDER_SELF_MAP_ROUTE_RECONCILIATION_V1.md',
  $routeIndex.active_route_lock_file
) | Where-Object { $_ }

$recommendation = [pscustomobject][ordered]@{
  recommendation_id = ('PHASE161J_RECOMMENDATION_' + (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss'))
  created_at = (Get-Date).ToUniversalTime().ToString('o')
  selector_version = $policy.selector_version
  decision_authority = 'MODE_DECISION_KERNEL'
  recommendation_role = 'MAP_SIGNAL_NOT_COMMAND'
  blocks_current_action = [bool]($health.health_state -eq 'CRITICAL')
  map_signal = [pscustomobject][ordered]@{
    source = 'BUILDER_SELF_MAP'
    selected_action_id = $selected.action_id
    recommended_phase_id = $selected.recommended_phase_id
    requires_mode_decision = $true
  }
  health_signal = [pscustomobject][ordered]@{
    health_state = $health.health_state
    health_score = [int]$health.health_score
    critical_finding_count = @($health.critical_findings).Count
  }
  self_map_repair_recommendation = $(if ($phase165qReconciled) { 'No self-map route reconciliation repair is currently required; preserve PHASE165Q as diagnostic evidence.' } else { 'Refresh and reconcile route evidence before relying on the map signal.' })
  organism_health_state = $health.health_state
  recommended_next_macro_step = $selected.macro_step
  recommended_next_phase_id = $selected.recommended_phase_id
  priority_class = $selected.priority_class
  why_this_step = $selected.reason
  why_not_delete_first = 'No safety-critical deletion need is proven; deletion is last resort and historical artifacts do not block the active route.'
  why_not_connect_everything_first = 'Present-not-wired artifacts must be connected only when route-relevant; bulk wiring would create false active claims.'
  why_not_repair_all_stubs_first = 'Only active-path proven stubs can outrank current route evidence work; bulk stub repair would include false positives and historical items.'
  completed_recommendations_detected = $completed.ToArray()
  blocked_old_recommendations = $blockedOld.ToArray()
  candidate_actions_considered = $candidates.ToArray()
  selected_action_score = [int]$selected.score
  evidence_paths = @($evidencePaths)
  owner_approval_required = [bool]$selected.owner_approval_required
  expected_validator_needed = $true
  next_action_type = $selected.next_action_type
  delayed_scope = [pscustomobject]@{
    task_queue = $(if ($delayedByTarget['TASK_QUEUE.json']) { $delayedByTarget['TASK_QUEUE.json'] } else { 'DELAY' })
    packs_registry = $(if ($delayedByTarget['packs/registry.json']) { $delayedByTarget['packs/registry.json'] } else { 'DELAY' })
    orchestrator_run = $(if ($delayedByTarget['orchestrator/run.ps1']) { $delayedByTarget['orchestrator/run.ps1'] } else { 'REJECT' })
  }
}
Write-SelectorJson -Path (Join-Path $output 'self_map_next_action_recommendation.json') -Value $recommendation

Set-SelectorProperty $active 'organism_health_state' $health.health_state
Set-SelectorProperty $active 'health_score' ([int]$health.health_score)
Set-SelectorProperty $active 'recommended_next_macro_step' $recommendation.recommended_next_macro_step
Set-SelectorProperty $active 'recommended_next_phase_id' $recommendation.recommended_next_phase_id
Set-SelectorProperty $active 'next_action_type' $recommendation.next_action_type
Set-SelectorProperty $active 'selector_policy_id' $policy.policy_id
Set-SelectorProperty $active 'blocked_old_recommendations' @($recommendation.blocked_old_recommendations)
Set-SelectorProperty $active 'candidate_actions_considered' @($recommendation.candidate_actions_considered)
Set-SelectorProperty $active 'next_decision_reason' $recommendation.why_this_step
Set-SelectorProperty $active 'decision_authority' $recommendation.decision_authority
Set-SelectorProperty $active 'recommendation_role' $recommendation.recommendation_role
Set-SelectorProperty $active 'blocks_current_action' $recommendation.blocks_current_action
Set-SelectorProperty $active 'map_signal' $recommendation.map_signal
Set-SelectorProperty $active 'health_signal' $recommendation.health_signal
Set-SelectorProperty $active 'self_map_repair_recommendation' $recommendation.self_map_repair_recommendation
Write-SelectorJson -Path (Join-Path $output 'SELF_MODEL_ACTIVE_MAP.json') -Value $active

$recommendation
