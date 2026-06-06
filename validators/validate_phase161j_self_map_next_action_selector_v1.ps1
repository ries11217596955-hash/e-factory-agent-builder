param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$ExpectedHead = '6a8d5f95456c534ab84a4012381759191dc5f4d4'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Assert-Phase161J {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Test-Phase161JParser {
  param([string]$Path)
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) {
    throw "Parser failed for $Path`: $((@($errors | ForEach-Object { $_.Message })) -join '; ')"
  }
}

function Write-Phase161JJson {
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
    Assert-Phase161J (Test-Path -LiteralPath (Join-Path $root $path)) "STOP=WRONG_AGENT_BUILDER_REPO missing=$path"
  }

  $branchBefore = (git -C $root branch --show-current).Trim()
  $headBefore = (git -C $root rev-parse HEAD).Trim()
  Assert-Phase161J ($branchBefore -eq 'phase110-idempotent-autonomy-trial-runtime') "Unexpected branch: $branchBefore"
  Assert-Phase161J ($headBefore -eq $ExpectedHead) "Unexpected HEAD: $headBefore"
  Assert-Phase161J (Test-Path -LiteralPath (Join-Path $root 'reports/self_development/PHASE161J_EXECUTION_PLAN.md')) 'Execution plan missing.'

  $parserFiles = @(
    'modules/inspect_builder_organism_health_state_001.ps1',
    'modules/select_builder_self_map_next_action_001.ps1',
    'modules/validate_builder_self_map_next_action_contract_001.ps1',
    'modules/write_builder_next_action_selector_report_001.ps1',
    'modules/invoke_builder_self_map_refresh_after_acceptance_001.ps1',
    'modules/write_builder_self_map_memory_report_001.ps1',
    'validators/validate_phase161j_self_map_next_action_selector_v1.ps1'
  )
  foreach ($path in $parserFiles) {
    Test-Phase161JParser -Path (Join-Path $root $path)
  }

  $policyPath = Join-Path $root 'reports/self_development/self_map_next_action_selector_policy.json'
  $policy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
  $requiredPriority = @(
    'CRITICAL_SAFETY_OR_PROTECTED_STATE_CONFLICT',
    'ACTIVE_ROUTE_OR_CURRENT_DAEMON_BROKEN',
    'FALSE_LIVE_OR_PROOF_CLAIM',
    'REQUIRED_LIVE_PROOF_FOR_ACTIVE_ORGAN',
    'REQUIRED_CONSUMER_COMPATIBILITY_FOR_ACTIVE_PATH',
    'PRESENT_NOT_WIRED_BUT_ROUTE_RELEVANT',
    'REAL_STUB_IN_ACTIVE_PATH',
    'MAP_RECOMMENDATION_LOGIC_REPAIR',
    'OWNER_APPROVAL_BACKLOG',
    'OPTIONAL_HISTORICAL_CLEANUP'
  )
  Assert-Phase161J ($policy.selector_version -eq 'PHASE161J') 'Selector version mismatch.'
  Assert-Phase161J ((@($policy.priority_order) -join '|') -eq ($requiredPriority -join '|')) 'Priority order mismatch.'
  Assert-Phase161J ($policy.deletion_is_last_resort -eq $true) 'Deletion is not last resort.'
  Assert-Phase161J ($policy.route_relevance_required -eq $true) 'Route relevance is not required.'

  $protectedBefore = @{}
  foreach ($path in $identity) {
    $protectedBefore[$path] = (Get-FileHash -LiteralPath (Join-Path $root $path) -Algorithm SHA256).Hash
  }
  $routeHashBefore = (Get-FileHash -LiteralPath (Join-Path $root 'route_locks/ACTIVE_ROUTE_LOCK.json') -Algorithm SHA256).Hash

  $health = & (Join-Path $root 'modules/inspect_builder_organism_health_state_001.ps1') -RepoRoot $root
  $recommendation = & (Join-Path $root 'modules/select_builder_self_map_next_action_001.ps1') -RepoRoot $root
  & (Join-Path $root 'modules/write_builder_self_map_memory_report_001.ps1') `
    -RepoRoot $root `
    -AcceptedSubjectHead $headBefore `
    -AcceptedPhase 'PHASE161J_SELF_MAP_NEXT_ACTION_SELECTOR' | Out-Null
  $contract = & (Join-Path $root 'modules/validate_builder_self_map_next_action_contract_001.ps1') -RepoRoot $root
  Assert-Phase161J ($contract.result -eq 'PASS') 'Next action contract failed.'

  Assert-Phase161J (Test-Path -LiteralPath (Join-Path $root 'reports/self_development/organism_health_state.json')) 'Health output missing.'
  Assert-Phase161J (Test-Path -LiteralPath (Join-Path $root 'reports/self_development/self_map_next_action_recommendation.json')) 'Recommendation output missing.'
  Assert-Phase161J (-not [string]::IsNullOrWhiteSpace($recommendation.why_this_step)) 'why_this_step missing.'
  Assert-Phase161J (-not [string]::IsNullOrWhiteSpace($recommendation.why_not_delete_first)) 'why_not_delete_first missing.'
  Assert-Phase161J (-not [string]::IsNullOrWhiteSpace($recommendation.why_not_connect_everything_first)) 'why_not_connect_everything_first missing.'
  Assert-Phase161J (-not [string]::IsNullOrWhiteSpace($recommendation.why_not_repair_all_stubs_first)) 'why_not_repair_all_stubs_first missing.'
  Assert-Phase161J (@($recommendation.completed_recommendations_detected | Where-Object { $_.phase -eq 'PHASE161F' }).Count -eq 1) 'PHASE161F completion missing.'
  Assert-Phase161J (@($recommendation.completed_recommendations_detected | Where-Object { $_.phase -eq 'PHASE161G1' }).Count -eq 1) 'PHASE161G1 completion missing.'
  Assert-Phase161J (@($recommendation.completed_recommendations_detected | Where-Object { $_.phase -eq 'PHASE161G2' }).Count -eq 1) 'PHASE161G2 completion missing.'
  Assert-Phase161J ($recommendation.recommended_next_macro_step -notmatch '(?i)review.*protected.state candidate') 'Stale protected review was selected.'
  Assert-Phase161J ($recommendation.next_action_type -ne 'CLEANUP') 'Deletion/cleanup selected first without critical proof.'
  Assert-Phase161J ($recommendation.delayed_scope.task_queue -eq 'DELAY') 'TASK_QUEUE delay not represented.'
  Assert-Phase161J ($recommendation.delayed_scope.packs_registry -eq 'DELAY') 'packs registry delay not represented.'
  Assert-Phase161J ($recommendation.delayed_scope.orchestrator_run -in @('DELAY','REJECT')) 'orchestrator reject/delay not represented.'
  if ($health.health_state -eq 'HEALTHY') {
    Assert-Phase161J (@($health.critical_findings).Count -eq 0) 'HEALTHY with critical findings.'
    Assert-Phase161J (@($health.healthy_criteria_failed).Count -eq 0) 'HEALTHY with failed criteria.'
  }

  $active = Get-Content (Join-Path $root 'reports/self_development/SELF_MODEL_ACTIVE_MAP.json') -Raw | ConvertFrom-Json
  $memory = Get-Content (Join-Path $root 'reports/self_development/self_map_memory_report.md') -Raw
  Assert-Phase161J (-not [string]::IsNullOrWhiteSpace($active.organism_health_state)) 'Active map health missing.'
  Assert-Phase161J (-not [string]::IsNullOrWhiteSpace($active.recommended_next_macro_step)) 'Active map next action missing.'
  Assert-Phase161J ($memory -match '## Organism Health State') 'Memory health section missing.'
  Assert-Phase161J ($memory -match '## Recommended Next Macro-Step') 'Memory next action section missing.'
  Assert-Phase161J ($memory -match '## Why Not Other Common Actions') 'Memory alternatives section missing.'

  foreach ($path in $identity) {
    $after = (Get-FileHash -LiteralPath (Join-Path $root $path) -Algorithm SHA256).Hash
    Assert-Phase161J ($after -eq $protectedBefore[$path]) "Protected state changed: $path"
  }
  $routeHashAfter = (Get-FileHash -LiteralPath (Join-Path $root 'route_locks/ACTIVE_ROUTE_LOCK.json') -Algorithm SHA256).Hash
  Assert-Phase161J ($routeHashAfter -eq $routeHashBefore) 'Route lock changed.'
  $runtimeStaged = @(git -C $root diff --cached --name-only -- runtime_sessions)
  $branchAfter = (git -C $root branch --show-current).Trim()
  $headAfter = (git -C $root rev-parse HEAD).Trim()
  Assert-Phase161J ($runtimeStaged.Count -eq 0) 'runtime_sessions staged.'
  Assert-Phase161J ($branchAfter -eq $branchBefore) 'Branch switched during validator.'
  Assert-Phase161J ($headAfter -eq $headBefore) 'Commit occurred during validator.'

  $reportRelative = 'reports/self_development/PHASE161J_NEXT_ACTION_SELECTOR_REPORT.md'
  & (Join-Path $root 'modules/write_builder_next_action_selector_report_001.ps1') -RepoRoot $root -OutputPath $reportRelative | Out-Null
  $proofRelative = 'proofs/self_development/PHASE161J_SELF_MAP_NEXT_ACTION_SELECTOR_PROOF.json'
  $requestRelative = 'route_change_requests/PHASE161J_SELF_MAP_NEXT_ACTION_SELECTOR_REQUEST.md'
  $deliveryRelative = 'reports/self_development/PHASE161J_SELF_MAP_NEXT_ACTION_SELECTOR_CODEX_DELIVERY.md'

  $proof = [pscustomobject][ordered]@{
    phase = 'PHASE161J_SELF_MAP_NEXT_ACTION_SELECTOR_AND_ORGANISM_HEALTH_STATE'
    validate_result = 'PASS'
    branch = $branchBefore
    head_before = $headBefore
    head_after = $headAfter
    health_state = $health.health_state
    health_score = [int]$health.health_score
    recommended_next_macro_step = $recommendation.recommended_next_macro_step
    recommended_next_phase_id = $recommendation.recommended_next_phase_id
    priority_class = $recommendation.priority_class
    selected_action_score = [int]$recommendation.selected_action_score
    stale_protected_review_blocked = $true
    task_queue_delayed = $true
    packs_registry_delayed = $true
    orchestrator_rejected_or_delayed = $true
    protected_state_mutated = $false
    runtime_outputs_staged = $false
    no_commit_performed = $true
    no_push_performed = $true
    no_branch_switch = $true
    created_at = (Get-Date).ToUniversalTime().ToString('o')
  }
  Write-Phase161JJson -Path (Join-Path $root $proofRelative) -Value $proof

  @(
    '# PHASE161J Self-Map Next Action Selector Request',
    '',
    'Adopt deterministic next-action selection and strict organism health state in every PHASE161E/I self-map refresh.',
    '',
    ('Current selected next phase: `{0}`' -f $recommendation.recommended_next_phase_id)
  ) | Set-Content -LiteralPath (Join-Path $root $requestRelative) -Encoding UTF8

  @(
    '# PHASE161J Codex Delivery',
    '',
    'Root guard: `PASS`',
    'Parser checks: `PASS`',
    'Validator: `PASS`',
    ('Organism health: `{0}`' -f $health.health_state),
    ('Recommended next phase: `{0}`' -f $recommendation.recommended_next_phase_id),
    'Completed PHASE161F/G1/G2 recommendation suppressed: `True`',
    'Protected state mutated: `False`',
    'Runtime outputs staged: `False`',
    ('Proof: `{0}`' -f $proofRelative),
    ('Report: `{0}`' -f $reportRelative),
    'Final recommendation: `READY_FOR_FUNCTIONAL_COMMIT_AND_REMOTE_AUTO_REFRESH`'
  ) | Set-Content -LiteralPath (Join-Path $root $deliveryRelative) -Encoding UTF8

  Write-Host 'PHASE161J_SELF_MAP_NEXT_ACTION_SELECTOR_VALIDATE_RESULT=PASS'
  Write-Host 'EXECUTION_PLAN_CREATED=True'
  Write-Host 'NEXT_ACTION_SELECTOR_POLICY_CREATED=True'
  Write-Host 'NEXT_ACTION_SELECTOR_CREATED=True'
  Write-Host 'ORGANISM_HEALTH_STATE_CREATED=True'
  Write-Host 'MEMORY_REPORT_NEXT_ACTION_UPDATED=True'
  Write-Host 'SELF_MODEL_ACTIVE_MAP_NEXT_ACTION_UPDATED=True'
  Write-Host 'COMPLETED_RECOMMENDATIONS_NOT_REPEATED=True'
  Write-Host 'STALE_PROTECTED_REVIEW_RECOMMENDATION_BLOCKED=True'
  Write-Host 'TASK_QUEUE_DELAY_REPRESENTED=True'
  Write-Host 'PACKS_REGISTRY_DELAY_REPRESENTED=True'
  Write-Host 'ORCHESTRATOR_REJECT_DELAY_REPRESENTED=True'
  Write-Host 'HEALTH_STATE_RULES_VALIDATED=True'
  Write-Host 'WHY_THIS_STEP_PRESENT=True'
  Write-Host 'WHY_NOT_DELETE_FIRST_PRESENT=True'
  Write-Host 'WHY_NOT_CONNECT_EVERYTHING_FIRST_PRESENT=True'
  Write-Host 'WHY_NOT_REPAIR_ALL_STUBS_FIRST_PRESENT=True'
  Write-Host 'NO_PROTECTED_STATE_MUTATION=True'
  Write-Host 'RUNTIME_OUTPUTS_STAGED=False'
  Write-Host 'NO_COMMIT_PERFORMED_DURING_VALIDATION=True'
  Write-Host 'NO_PUSH_PERFORMED_DURING_VALIDATION=True'
  Write-Host 'NO_BRANCH_SWITCH=True'
  Write-Host 'CODEX_DELIVERY_FILE_CREATED=True'
} catch {
  Write-Host 'PHASE161J_SELF_MAP_NEXT_ACTION_SELECTOR_VALIDATE_RESULT=FAIL'
  Write-Host ("FAIL_REASON={0}" -f $_.Exception.Message)
  exit 1
}
