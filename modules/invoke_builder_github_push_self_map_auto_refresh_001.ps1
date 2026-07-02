param(
  [Parameter(Mandatory=$true)][string]$AcceptedSubjectHead,
  [string]$AcceptedPhase = 'GITHUB_PUSH_SELF_MAP_AUTO_REFRESH',
  [string]$TriggerReason = 'github_push_auto_refresh',
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [switch]$DryRun
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Assert-GitHubPushRefresh {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Get-GitHubPushRefreshHash {
  param([string]$Root, [string]$Path)
  return (Get-FileHash -LiteralPath (Join-Path $Root $Path) -Algorithm SHA256).Hash
}

function Get-GitHubPushRefreshChangedPaths {
  param([string]$Root)
  return @(git -C $Root status --porcelain | ForEach-Object {
    if ($_.Length -ge 4) { $_.Substring(3).Trim() -replace '\\','/' }
  } | Where-Object { $_ })
}

function Write-GitHubPushRefreshJson {
  param([string]$Path, $Value)
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
  $Value | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $Path -Encoding UTF8
}

$root = (Resolve-Path $RepoRoot).Path
$requiredRoot = @('CAPABILITY_ROADMAP.json','GENESIS_STATE.json','TASK_QUEUE.json','packs/registry.json','orchestrator/run.ps1')
foreach ($path in $requiredRoot) {
  Assert-GitHubPushRefresh (Test-Path -LiteralPath (Join-Path $root $path)) "STOP=WRONG_AGENT_BUILDER_REPO missing=$path"
}

$head = (git -C $root rev-parse HEAD).Trim()
Assert-GitHubPushRefresh ($head -eq $AcceptedSubjectHead) "HEAD $head does not match accepted subject $AcceptedSubjectHead"

$protected = @('TASK_QUEUE.json','GENESIS_STATE.json','CAPABILITY_ROADMAP.json','packs/registry.json','orchestrator/run.ps1')
$protectedStatusBefore = @(git -C $root status --porcelain -- @protected)
Assert-GitHubPushRefresh ($protectedStatusBefore.Count -eq 0) 'Protected state is modified before refresh.'
$routeStatusBefore = @(git -C $root status --porcelain -- route_locks)
Assert-GitHubPushRefresh ($routeStatusBefore.Count -eq 0) 'Route lock is modified before refresh.'
$runtimeStagedBefore = @(git -C $root diff --cached --name-only -- runtime_sessions)
Assert-GitHubPushRefresh ($runtimeStagedBefore.Count -eq 0) 'runtime_sessions is staged before refresh.'

$protectedHashes = @{}
foreach ($path in $protected) {
  $protectedHashes[$path] = Get-GitHubPushRefreshHash -Root $root -Path $path
}
$routeHash = Get-GitHubPushRefreshHash -Root $root -Path 'route_locks/ACTIVE_ROUTE_LOCK.json'

if ($DryRun) {
  return [pscustomobject][ordered]@{
    workflow_refresh_id = ('PHASE161I_DRY_RUN_' + (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss'))
    accepted_subject_head = $AcceptedSubjectHead
    accepted_phase = $AcceptedPhase
    trigger_reason = $TriggerReason
    dry_run = $true
    map_refresh_status = 'DRY_RUN_READY'
    self_knowledge_ready = $false
    map_is_ready_for_next_decision = $false
    generated_from_worktree_head = $head
    protected_state_mutated = $false
    runtime_outputs_staged = $false
    refreshed_files = @()
    created_at = (Get-Date).ToUniversalTime().ToString('o')
  }
}

$refreshModule = Join-Path $root 'modules/invoke_builder_self_map_refresh_after_acceptance_001.ps1'
$contractModule = Join-Path $root 'modules/validate_builder_acceptance_self_map_refresh_contract_001.ps1'
Assert-GitHubPushRefresh (Test-Path -LiteralPath $refreshModule) 'PHASE161E refresh module missing.'
Assert-GitHubPushRefresh (Test-Path -LiteralPath $contractModule) 'PHASE161E refresh contract module missing.'

$refresh = & $refreshModule `
  -AcceptedSubjectHead $AcceptedSubjectHead `
  -AcceptedPhase $AcceptedPhase `
  -TriggerReason $TriggerReason `
  -RepoRoot $root
$contract = & $contractModule -RepoRoot $root

Assert-GitHubPushRefresh ($contract.result -eq 'PASS') 'Self-map refresh contract failed.'
Assert-GitHubPushRefresh ($refresh.map_refresh_status -eq 'SELF_KNOWLEDGE_READY') 'Refresh result is not SELF_KNOWLEDGE_READY.'
Assert-GitHubPushRefresh ([bool]$refresh.self_knowledge_ready) 'Refresh result self_knowledge_ready is false.'
Assert-GitHubPushRefresh ([bool]$refresh.map_is_ready_for_next_decision) 'Refresh result map_is_ready_for_next_decision is false.'
Assert-GitHubPushRefresh ($refresh.accepted_subject_head -eq $AcceptedSubjectHead) 'Refresh result accepted_subject_head mismatch.'

foreach ($path in $protected) {
  $after = Get-GitHubPushRefreshHash -Root $root -Path $path
  Assert-GitHubPushRefresh ($after -eq $protectedHashes[$path]) "Protected file changed during refresh: $path"
}
$routeHashAfter = Get-GitHubPushRefreshHash -Root $root -Path 'route_locks/ACTIVE_ROUTE_LOCK.json'
Assert-GitHubPushRefresh ($routeHashAfter -eq $routeHash) 'Active route lock changed during refresh.'

$runtimeStagedAfter = @(git -C $root diff --cached --name-only -- runtime_sessions)
Assert-GitHubPushRefresh ($runtimeStagedAfter.Count -eq 0) 'runtime_sessions is staged after refresh.'

$resultRelative = 'reports/self_development/PHASE161I_AUTO_REFRESH_AFTER_PUSH_RESULT.json'
$changed = @(Get-GitHubPushRefreshChangedPaths -Root $root | Where-Object { $_ -ne $resultRelative })
$result = [pscustomobject][ordered]@{
  workflow_refresh_id = ('PHASE161I_REFRESH_' + (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss'))
  accepted_subject_head = $AcceptedSubjectHead
  accepted_phase = $AcceptedPhase
  trigger_reason = $TriggerReason
  map_refresh_status = $refresh.map_refresh_status
  self_knowledge_ready = [bool]$refresh.self_knowledge_ready
  map_is_ready_for_next_decision = [bool]$refresh.map_is_ready_for_next_decision
  generated_from_worktree_head = $head
  protected_state_mutated = $false
  runtime_outputs_staged = $false
  refreshed_files = @($changed)
  created_at = (Get-Date).ToUniversalTime().ToString('o')
}
Write-GitHubPushRefreshJson -Path (Join-Path $root $resultRelative) -Value $result
$result
