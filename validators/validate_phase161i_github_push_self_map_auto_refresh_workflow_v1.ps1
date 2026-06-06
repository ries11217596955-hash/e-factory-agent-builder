param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$ExpectedHead = '85c5e3e16c20bf8718ec1c877ea1fbe21ba0e07a'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Assert-Phase161I {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Test-Phase161IParser {
  param([string]$Path)
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) {
    throw "Parser failed for $Path`: $((@($errors | ForEach-Object { $_.Message })) -join '; ')"
  }
}

function Write-Phase161IJson {
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
    Assert-Phase161I (Test-Path -LiteralPath (Join-Path $root $path)) "STOP=WRONG_AGENT_BUILDER_REPO missing=$path"
  }

  $branchBefore = (git -C $root branch --show-current).Trim()
  $headBefore = (git -C $root rev-parse HEAD).Trim()
  Assert-Phase161I ($branchBefore -eq 'phase110-idempotent-autonomy-trial-runtime') "Unexpected branch: $branchBefore"
  Assert-Phase161I ($headBefore -eq $ExpectedHead) "Unexpected HEAD: $headBefore"
  Assert-Phase161I (Test-Path -LiteralPath (Join-Path $root 'reports/self_development/PHASE161I_EXECUTION_PLAN.md')) 'Execution plan missing.'

  $parserFiles = @(
    'modules/invoke_builder_github_push_self_map_auto_refresh_001.ps1',
    'modules/validate_builder_github_push_self_map_auto_refresh_workflow_001.ps1',
    'modules/write_builder_github_push_self_map_auto_refresh_delivery_001.ps1',
    'validators/validate_phase161i_github_push_self_map_auto_refresh_workflow_v1.ps1'
  )
  foreach ($path in $parserFiles) {
    Test-Phase161IParser -Path (Join-Path $root $path)
  }

  $workflowRelative = '.github/workflows/self-map-auto-refresh-after-push.yml'
  Assert-Phase161I (Test-Path -LiteralPath (Join-Path $root $workflowRelative)) 'Workflow file missing.'
  $workflowValidation = & (Join-Path $root 'modules/validate_builder_github_push_self_map_auto_refresh_workflow_001.ps1') -RepoRoot $root
  Assert-Phase161I ($workflowValidation.result -eq 'PASS') 'Workflow validation failed.'
  Assert-Phase161I ($workflowValidation.protected_state_not_stageable -eq $true) 'Workflow can stage protected state.'
  Assert-Phase161I ($workflowValidation.runtime_sessions_not_stageable -eq $true) 'Workflow can stage runtime_sessions.'

  $policyPath = Join-Path $root 'reports/self_development/github_push_self_map_auto_refresh_policy.json'
  $policy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
  Assert-Phase161I ($policy.trigger -eq 'push') 'Policy trigger is not push.'
  Assert-Phase161I ($policy.branch -eq 'phase110-idempotent-autonomy-trial-runtime') 'Policy branch mismatch.'
  Assert-Phase161I ($policy.automatic_refresh_required -eq $true) 'Policy does not require automatic refresh.'
  Assert-Phase161I ($policy.passive_stale_allowed -eq $false) 'Policy allows passive stale.'
  Assert-Phase161I ($policy.self_knowledge_ready_required -eq $true) 'Policy does not require SELF_KNOWLEDGE_READY.'
  Assert-Phase161I ($policy.protected_state_direct_mutation_allowed -eq $false) 'Policy allows protected state mutation.'
  Assert-Phase161I ($policy.runtime_sessions_staged_allowed -eq $false) 'Policy allows runtime_sessions staging.'
  Assert-Phase161I ($policy.pat_required -eq $false) 'Policy requires PAT.'

  $protectedBefore = @{}
  foreach ($path in $identity) {
    $protectedBefore[$path] = (Get-FileHash -LiteralPath (Join-Path $root $path) -Algorithm SHA256).Hash
  }
  $routeHashBefore = (Get-FileHash -LiteralPath (Join-Path $root 'route_locks/ACTIVE_ROUTE_LOCK.json') -Algorithm SHA256).Hash

  $dryRun = & (Join-Path $root 'modules/invoke_builder_github_push_self_map_auto_refresh_001.ps1') `
    -AcceptedSubjectHead $headBefore `
    -AcceptedPhase 'PHASE161I_GITHUB_PUSH_SELF_MAP_AUTO_REFRESH_WORKFLOW' `
    -TriggerReason 'phase161i_local_dry_run_validation' `
    -RepoRoot $root `
    -DryRun
  Assert-Phase161I ($dryRun.dry_run -eq $true) 'Wrapper dry-run flag missing.'
  Assert-Phase161I ($dryRun.map_refresh_status -eq 'DRY_RUN_READY') 'Wrapper dry-run not ready.'
  Assert-Phase161I ($dryRun.protected_state_mutated -eq $false) 'Dry-run reports protected mutation.'
  Assert-Phase161I ($dryRun.runtime_outputs_staged -eq $false) 'Dry-run reports runtime staging.'

  foreach ($path in $identity) {
    $after = (Get-FileHash -LiteralPath (Join-Path $root $path) -Algorithm SHA256).Hash
    Assert-Phase161I ($after -eq $protectedBefore[$path]) "Protected state changed during validator: $path"
  }
  $routeHashAfter = (Get-FileHash -LiteralPath (Join-Path $root 'route_locks/ACTIVE_ROUTE_LOCK.json') -Algorithm SHA256).Hash
  Assert-Phase161I ($routeHashAfter -eq $routeHashBefore) 'Route lock changed during validator.'

  $protectedStatus = @(git -C $root status --short -- @identity)
  $runtimeStaged = @(git -C $root diff --cached --name-only -- runtime_sessions)
  $branchAfter = (git -C $root branch --show-current).Trim()
  $headAfter = (git -C $root rev-parse HEAD).Trim()
  Assert-Phase161I ($protectedStatus.Count -eq 0) 'Protected state has git status changes.'
  Assert-Phase161I ($runtimeStaged.Count -eq 0) 'runtime_sessions is staged.'
  Assert-Phase161I ($branchAfter -eq $branchBefore) 'Branch switched during validator.'
  Assert-Phase161I ($headAfter -eq $headBefore) 'Commit occurred during validator.'

  $proofRelative = 'proofs/self_development/PHASE161I_GITHUB_PUSH_SELF_MAP_AUTO_REFRESH_PROOF.json'
  $reportRelative = 'reports/self_development/PHASE161I_GITHUB_PUSH_SELF_MAP_AUTO_REFRESH_REPORT.md'
  $requestRelative = 'route_change_requests/PHASE161I_GITHUB_PUSH_SELF_MAP_AUTO_REFRESH_REQUEST.md'
  $deliveryRelative = 'reports/self_development/PHASE161I_GITHUB_PUSH_SELF_MAP_AUTO_REFRESH_CODEX_DELIVERY.md'

  $proof = [pscustomobject][ordered]@{
    phase = 'PHASE161I_GITHUB_PUSH_SELF_MAP_AUTO_REFRESH_WORKFLOW_V1'
    validate_result = 'PASS'
    branch = $branchBefore
    head_before = $headBefore
    head_after = $headAfter
    workflow_path = $workflowRelative
    policy_id = $policy.policy_id
    workflow_branch_trigger_configured = $true
    workflow_contents_write_permission_set = $true
    workflow_recursion_guard_configured = $true
    workflow_calls_self_map_refresh = $true
    protected_state_not_stageable = $true
    runtime_sessions_not_stageable = $true
    local_dry_run_validation_pass = $true
    protected_state_mutated = $false
    runtime_outputs_staged = $false
    no_commit_performed = $true
    no_push_performed = $true
    no_branch_switch = $true
    protected_hashes = $protectedBefore
    route_lock_hash = $routeHashBefore
    created_at = (Get-Date).ToUniversalTime().ToString('o')
  }
  Write-Phase161IJson -Path (Join-Path $root $proofRelative) -Value $proof

  @(
    '# PHASE161I GitHub Push Self-Map Auto Refresh Report',
    '',
    'Local validation result: `PASS`',
    '',
    'The workflow targets pushes to `phase110-idempotent-autonomy-trial-runtime`, uses `contents: write`, checks out the exact pushed SHA, invokes the PHASE161E wrapper, and requires `SELF_KNOWLEDGE_READY` before an explicit allowlist commit.',
    '',
    'Recursion is prevented by `[self-map-refresh]` and normal `GITHUB_TOKEN` event behavior. No PAT is used.',
    '',
    'Remote acceptance remains pending until the workflow-generated refresh commit is observed after the functional push.'
  ) | Set-Content -LiteralPath (Join-Path $root $reportRelative) -Encoding UTF8

  @(
    '# PHASE161I GitHub Push Self-Map Auto Refresh Request',
    '',
    'Enable remote accepted-branch memory refresh on every non-refresh push.',
    '',
    'Acceptance requires a workflow-generated commit with `SELF_KNOWLEDGE_READY` for the pushed functional SHA.'
  ) | Set-Content -LiteralPath (Join-Path $root $requestRelative) -Encoding UTF8

  @(
    '# PHASE161I Codex Delivery',
    '',
    'Root guard: `PASS`',
    'Parser checks: `PASS`',
    'Local validator: `PASS`',
    'Workflow static contract: `PASS`',
    'Wrapper dry-run: `PASS`',
    'Protected state mutated: `False`',
    'Runtime outputs staged: `False`',
    ('Proof: `{0}`' -f $proofRelative),
    ('Report: `{0}`' -f $reportRelative),
    'Final recommendation: `READY_FOR_WORKFLOW_COMMIT_AND_REMOTE_PROOF`'
  ) | Set-Content -LiteralPath (Join-Path $root $deliveryRelative) -Encoding UTF8

  Write-Host 'PHASE161I_GITHUB_PUSH_SELF_MAP_AUTO_REFRESH_WORKFLOW_VALIDATE_RESULT=PASS'
  Write-Host 'EXECUTION_PLAN_CREATED=True'
  Write-Host 'GITHUB_ACTION_WORKFLOW_CREATED=True'
  Write-Host 'WORKFLOW_BRANCH_TRIGGER_CONFIGURED=True'
  Write-Host 'WORKFLOW_CONTENTS_WRITE_PERMISSION_SET=True'
  Write-Host 'WORKFLOW_RECURSION_GUARD_CONFIGURED=True'
  Write-Host 'WORKFLOW_CALLS_SELF_MAP_REFRESH=True'
  Write-Host 'GITHUB_PUSH_REFRESH_WRAPPER_CREATED=True'
  Write-Host 'AUTO_REFRESH_POLICY_CREATED=True'
  Write-Host 'PASSIVE_STALE_NOT_ALLOWED=True'
  Write-Host 'SELF_KNOWLEDGE_READY_REQUIRED=True'
  Write-Host 'PROTECTED_STATE_NOT_STAGEABLE_BY_WORKFLOW=True'
  Write-Host 'RUNTIME_SESSIONS_NOT_STAGEABLE_BY_WORKFLOW=True'
  Write-Host 'LOCAL_DRY_RUN_VALIDATION_PASS=True'
  Write-Host 'NO_PROTECTED_STATE_MUTATION=True'
  Write-Host 'RUNTIME_OUTPUTS_STAGED=False'
  Write-Host 'NO_COMMIT_PERFORMED_DURING_VALIDATION=True'
  Write-Host 'NO_PUSH_PERFORMED_DURING_VALIDATION=True'
  Write-Host 'NO_BRANCH_SWITCH=True'
  Write-Host 'CODEX_DELIVERY_FILE_CREATED=True'
} catch {
  Write-Host 'PHASE161I_GITHUB_PUSH_SELF_MAP_AUTO_REFRESH_WORKFLOW_VALIDATE_RESULT=FAIL'
  Write-Host ("FAIL_REASON={0}" -f $_.Exception.Message)
  exit 1
}
