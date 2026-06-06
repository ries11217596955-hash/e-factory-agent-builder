param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$ExpectedHead = '04565dae6f458f4445b1e581c245917b66623ac2'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Assert-Phase161H {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Test-Phase161HParser {
  param([string]$Path)
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) {
    throw "Parser failed for $Path`: $((@($errors | ForEach-Object { $_.Message })) -join '; ')"
  }
}

function Write-Phase161HJson {
  param([string]$Path, $Value)
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
  $Value | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $Path -Encoding UTF8
}

try {
  $root = (Resolve-Path $RepoRoot).Path
  $identity = @('CAPABILITY_ROADMAP.json','GENESIS_STATE.json','TASK_QUEUE.json','packs/registry.json','orchestrator/run.ps1')
  foreach ($path in $identity) {
    Assert-Phase161H (Test-Path -LiteralPath (Join-Path $root $path)) "STOP=WRONG_AGENT_BUILDER_REPO missing=$path"
  }

  $branchBefore = (git -C $root branch --show-current).Trim()
  $headBefore = (git -C $root rev-parse HEAD).Trim()
  Assert-Phase161H ($branchBefore -eq 'phase110-idempotent-autonomy-trial-runtime') "Unexpected branch: $branchBefore"
  Assert-Phase161H ($headBefore -eq $ExpectedHead) "Unexpected HEAD: $headBefore"

  $planPath = Join-Path $root 'reports/self_development/PHASE161H_EXECUTION_PLAN.md'
  Assert-Phase161H (Test-Path -LiteralPath $planPath) 'PHASE161H execution plan missing.'

  $parserFiles = @(
    'modules/inspect_builder_acceptance_pipeline_self_map_refresh_policy_001.ps1',
    'modules/write_builder_acceptance_pipeline_refresh_delivery_001.ps1',
    'modules/invoke_builder_acceptance_pipeline_with_self_map_refresh_001.ps1',
    'modules/validate_builder_acceptance_pipeline_self_map_refresh_enforcement_001.ps1',
    'validators/validate_phase161h_acceptance_pipeline_self_map_refresh_enforcement_v1.ps1'
  )
  foreach ($path in $parserFiles) {
    Test-Phase161HParser -Path (Join-Path $root $path)
  }

  $policyPath = Join-Path $root 'reports/self_development/acceptance_pipeline_self_map_refresh_policy.json'
  $policy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
  $policyInspector = & (Join-Path $root 'modules/inspect_builder_acceptance_pipeline_self_map_refresh_policy_001.ps1') -RepoRoot $root
  Assert-Phase161H ($policyInspector.policy_status -eq 'PASS') 'Acceptance pipeline policy failed inspection.'
  Assert-Phase161H ($policy.required_after_functional_accept_commit -eq $true) 'Automatic refresh is not required.'
  Assert-Phase161H ($policy.passive_stale_allowed -eq $false) 'Passive stale is allowed.'
  Assert-Phase161H ($policy.refresh_commit_required -eq $true) 'Refresh commit is not required.'
  Assert-Phase161H ($policy.no_infinite_refresh_recursion -eq $true) 'Infinite refresh recursion is not prevented.'

  $functionalAllowlist = @(
    'reports/self_development/PHASE161H_EXECUTION_PLAN.md',
    'reports/self_development/acceptance_pipeline_self_map_refresh_policy.json',
    'docs/PHASE161H_ACCEPTANCE_PIPELINE_SELF_MAP_REFRESH_ENFORCEMENT.md',
    'modules/inspect_builder_acceptance_pipeline_self_map_refresh_policy_001.ps1',
    'modules/write_builder_acceptance_pipeline_refresh_delivery_001.ps1',
    'modules/invoke_builder_acceptance_pipeline_with_self_map_refresh_001.ps1',
    'modules/validate_builder_acceptance_pipeline_self_map_refresh_enforcement_001.ps1',
    'validators/validate_phase161h_acceptance_pipeline_self_map_refresh_enforcement_v1.ps1'
  )
  $refreshAllowlist = @(
    'reports/self_development/SELF_MODEL_ACTIVE_MAP.json',
    'reports/self_development/agent_body_map.json',
    'reports/self_development/agent_body_map.md',
    'reports/self_development/module_wiring_graph.json',
    'reports/self_development/function_inventory.json',
    'reports/self_development/stub_placeholder_inventory.json',
    'reports/self_development/orphaned_artifact_inventory.json',
    'reports/self_development/self_model_gap_chain.json',
    'reports/self_development/live_evidence_separation_index.json',
    'reports/self_development/historical_reference_inventory.json',
    'reports/self_development/superseded_artifact_inventory.json',
    'reports/self_development/stub_false_positive_inventory.json',
    'reports/self_development/self_map_refresh_after_acceptance_result.json',
    'reports/self_development/self_map_memory_report.md',
    'reports/self_development/accepted_change_memory_snapshot.json'
  )

  $pipeline = & (Join-Path $root 'modules/invoke_builder_acceptance_pipeline_with_self_map_refresh_001.ps1') `
    -PhaseId 'PHASE161H' `
    -FunctionalCommitMessage 'Build PHASE161H acceptance pipeline self-map refresh enforcement' `
    -RefreshCommitMessage 'Refresh PHASE161H self-map after acceptance pipeline functional commit' `
    -AcceptedPhase 'PHASE161H_ACCEPTANCE_PIPELINE_SELF_MAP_REFRESH_ENFORCEMENT' `
    -RepoRoot $root `
    -AllowedFunctionalPaths $functionalAllowlist `
    -AllowedRefreshPaths $refreshAllowlist `
    -DryRun `
    -SkipPush

  $enforcement = & (Join-Path $root 'modules/validate_builder_acceptance_pipeline_self_map_refresh_enforcement_001.ps1') `
    -RepoRoot $root `
    -PipelineDryRunResult $pipeline
  Assert-Phase161H ($enforcement.result -eq 'PASS') 'Pipeline enforcement contract failed.'
  Assert-Phase161H ($enforcement.automatic_refresh_enforced -eq $true) 'Automatic refresh is not enforced.'
  Assert-Phase161H ($enforcement.functional_then_refresh_commit_enforced -eq $true) 'Two-commit order is not enforced.'
  Assert-Phase161H ($pipeline.accepted_change_complete -eq $false) 'Dry-run incorrectly accepted the change.'

  $protectedStatus = @(git -C $root status --short -- TASK_QUEUE.json GENESIS_STATE.json CAPABILITY_ROADMAP.json packs/registry.json orchestrator/run.ps1)
  $routeStatus = @(git -C $root status --short -- route_locks)
  $runtimeStaged = @(git -C $root diff --cached --name-only -- runtime_sessions)
  $branchAfter = (git -C $root branch --show-current).Trim()
  $headAfter = (git -C $root rev-parse HEAD).Trim()
  Assert-Phase161H ($protectedStatus.Count -eq 0) 'Protected state was modified.'
  Assert-Phase161H ($routeStatus.Count -eq 0) 'Route lock was modified.'
  Assert-Phase161H ($runtimeStaged.Count -eq 0) 'runtime_sessions is staged.'
  Assert-Phase161H ($branchAfter -eq $branchBefore) 'Branch switched during validation.'
  Assert-Phase161H ($headAfter -eq $headBefore) 'Commit occurred during validation.'

  $proofRelative = 'proofs/self_development/PHASE161H_ACCEPTANCE_PIPELINE_SELF_MAP_REFRESH_ENFORCEMENT_PROOF.json'
  $reportRelative = 'reports/self_development/PHASE161H_ACCEPTANCE_PIPELINE_SELF_MAP_REFRESH_ENFORCEMENT_REPORT.md'
  $requestRelative = 'route_change_requests/PHASE161H_ACCEPTANCE_PIPELINE_SELF_MAP_REFRESH_ENFORCEMENT_REQUEST.md'
  $deliveryRelative = 'reports/self_development/PHASE161H_ACCEPTANCE_PIPELINE_SELF_MAP_REFRESH_ENFORCEMENT_CODEX_DELIVERY.md'
  $acceptRelative = 'reports/self_development/PHASE161H_ACCEPT_BASELINE_COMMIT_PUSH_DELIVERY.md'

  $proof = [pscustomobject][ordered]@{
    phase = 'PHASE161H_ACCEPTANCE_PIPELINE_SELF_MAP_REFRESH_ENFORCEMENT_V1'
    validate_result = 'PASS'
    branch = $branchBefore
    head_before = $headBefore
    head_after = $headAfter
    policy_id = $policy.policy_id
    dry_run_sequence = @($pipeline.sequence)
    automatic_refresh_enforced = $true
    functional_then_refresh_commit_enforced = $true
    self_knowledge_ready_required = $true
    passive_stale_allowed = $false
    no_infinite_refresh_recursion = $true
    protected_state_mutated = $false
    route_lock_mutated = $false
    runtime_outputs_staged = $false
    no_commit_performed = $true
    no_push_performed = $true
    no_branch_switch = $true
    created_at = (Get-Date).ToUniversalTime().ToString('o')
  }
  Write-Phase161HJson -Path (Join-Path $root $proofRelative) -Value $proof

  @(
    '# PHASE161H Acceptance Pipeline Self-Map Refresh Enforcement Report',
    '',
    'Result: `PASS`',
    '',
    'The policy and dry-run pipeline enforce a functional commit followed by a PHASE161E self-map refresh commit.',
    'A change is not complete until the refresh contract reports `SELF_KNOWLEDGE_READY`.',
    'The refresh subject is the functional commit; the refresh commit does not recursively trigger another refresh.',
    '',
    'Protected state, route locks, and `runtime_sessions` were not modified or staged during validation.'
  ) | Set-Content -LiteralPath (Join-Path $root $reportRelative) -Encoding UTF8

  @(
    '# PHASE161H Acceptance Pipeline Self-Map Refresh Enforcement Request',
    '',
    'Adopt the two-commit acceptance pipeline as the normal accepted-change completion contract:',
    '',
    '`FUNCTIONAL_ACCEPT_COMMIT -> SELF_MAP_REFRESH -> REFRESH_COMMIT -> SELF_KNOWLEDGE_READY`'
  ) | Set-Content -LiteralPath (Join-Path $root $requestRelative) -Encoding UTF8

  @(
    '# PHASE161H Codex Delivery',
    '',
    'Root guard: `PASS`',
    'Parser checks: `PASS`',
    'Validator: `PASS`',
    'Dry-run two-commit sequence: `PASS`',
    'Automatic refresh enforcement: `PASS`',
    'Protected state mutated: `False`',
    'Route lock mutated: `False`',
    'Runtime outputs staged: `False`',
    ('Proof: `{0}`' -f $proofRelative),
    ('Report: `{0}`' -f $reportRelative),
    'Final recommendation: `READY_FOR_FUNCTIONAL_ACCEPT_COMMIT`'
  ) | Set-Content -LiteralPath (Join-Path $root $deliveryRelative) -Encoding UTF8

  @(
    '# PHASE161H Functional Accept Delivery',
    '',
    'Status: `VALIDATED_PENDING_FUNCTIONAL_COMMIT`',
    ('Baseline head: `{0}`' -f $headBefore),
    'Validator: `PASS`',
    'Protected state mutated: `False`',
    'Runtime outputs staged: `False`'
  ) | Set-Content -LiteralPath (Join-Path $root $acceptRelative) -Encoding UTF8

  Write-Host 'PHASE161H_ACCEPTANCE_PIPELINE_SELF_MAP_REFRESH_ENFORCEMENT_VALIDATE_RESULT=PASS'
  Write-Host 'EXECUTION_PLAN_CREATED=True'
  Write-Host 'ACCEPTANCE_PIPELINE_POLICY_CREATED=True'
  Write-Host 'ACCEPTANCE_PIPELINE_MODULE_CREATED=True'
  Write-Host 'DRY_RUN_SEQUENCE_PROVEN=True'
  Write-Host 'FUNCTIONAL_COMMIT_THEN_REFRESH_COMMIT_ENFORCED=True'
  Write-Host 'AUTOMATIC_SELF_MAP_REFRESH_ENFORCED=True'
  Write-Host 'SELF_KNOWLEDGE_READY_REQUIRED=True'
  Write-Host 'PASSIVE_STALE_ALLOWED=False'
  Write-Host 'NO_INFINITE_REFRESH_RECURSION=True'
  Write-Host 'NO_PROTECTED_STATE_MUTATION=True'
  Write-Host 'RUNTIME_OUTPUTS_STAGED=False'
  Write-Host 'NO_COMMIT_PERFORMED_DURING_VALIDATION=True'
  Write-Host 'NO_PUSH_PERFORMED_DURING_VALIDATION=True'
  Write-Host 'NO_BRANCH_SWITCH=True'
  Write-Host 'CODEX_DELIVERY_FILE_CREATED=True'
} catch {
  Write-Host 'PHASE161H_ACCEPTANCE_PIPELINE_SELF_MAP_REFRESH_ENFORCEMENT_VALIDATE_RESULT=FAIL'
  Write-Host ("FAIL_REASON={0}" -f $_.Exception.Message)
  exit 1
}
