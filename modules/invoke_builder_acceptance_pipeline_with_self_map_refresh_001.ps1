param(
  [Parameter(Mandatory=$true)][string]$PhaseId,
  [Parameter(Mandatory=$true)][string]$FunctionalCommitMessage,
  [Parameter(Mandatory=$true)][string]$RefreshCommitMessage,
  [Parameter(Mandatory=$true)][string]$AcceptedPhase,
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string[]]$AllowedFunctionalPaths = @(),
  [string[]]$AllowedRefreshPaths = @(),
  [string]$ValidatorCommand = '',
  [switch]$DryRun,
  [switch]$SkipPush
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Assert-BuilderPipeline {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Get-BuilderRelativeGitPaths {
  param([string]$Root)
  return @(git -C $Root status --porcelain | ForEach-Object {
    if ($_.Length -ge 4) { $_.Substring(3).Trim() -replace '\\','/' }
  } | Where-Object { $_ })
}

function Test-BuilderPathAllowed {
  param([string]$Path, [string[]]$Allowed)
  foreach ($entry in $Allowed) {
    $normalized = $entry -replace '\\','/'
    if ($Path -eq $normalized -or $Path.StartsWith($normalized.TrimEnd('/') + '/')) { return $true }
  }
  return $false
}

function Assert-BuilderSubset {
  param([string[]]$Paths, [string[]]$Allowed, [string]$Label)
  $blocked = @($Paths | Where-Object { -not (Test-BuilderPathAllowed -Path $_ -Allowed $Allowed) })
  if ($blocked.Count -gt 0) {
    throw "$Label contains paths outside allowlist: $($blocked -join ', ')"
  }
}

function Invoke-BuilderGit {
  param([string]$Root, [string[]]$Arguments)
  & git -C $Root @Arguments
  if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed" }
}

$root = (Resolve-Path $RepoRoot).Path
$requiredRoot = @('CAPABILITY_ROADMAP.json','GENESIS_STATE.json','TASK_QUEUE.json','packs/registry.json','orchestrator/run.ps1')
foreach ($path in $requiredRoot) {
  Assert-BuilderPipeline (Test-Path -LiteralPath (Join-Path $root $path)) "STOP=WRONG_AGENT_BUILDER_REPO missing=$path"
}
Assert-BuilderPipeline (-not ($SkipPush -and -not $DryRun)) 'SkipPush is allowed only in dry-run mode.'

$branch = (git -C $root branch --show-current).Trim()
$headBefore = (git -C $root rev-parse HEAD).Trim()
$protected = @('TASK_QUEUE.json','GENESIS_STATE.json','CAPABILITY_ROADMAP.json','packs/registry.json','orchestrator/run.ps1')
$protectedChanges = @(git -C $root status --porcelain -- @protected | ForEach-Object { if ($_.Length -ge 4) { $_.Substring(3).Trim() -replace '\\','/' } })
$unapprovedProtected = @($protectedChanges | Where-Object { -not (Test-BuilderPathAllowed -Path $_ -Allowed $AllowedFunctionalPaths) })
Assert-BuilderPipeline ($unapprovedProtected.Count -eq 0) "Unapproved protected changes: $($unapprovedProtected -join ', ')"

$runtimeStaged = @(git -C $root diff --cached --name-only -- runtime_sessions)
Assert-BuilderPipeline ($runtimeStaged.Count -eq 0) 'runtime_sessions is staged.'

$functionalPaths = Get-BuilderRelativeGitPaths -Root $root
Assert-BuilderSubset -Paths $functionalPaths -Allowed $AllowedFunctionalPaths -Label 'Functional worktree'

$planned = [pscustomobject][ordered]@{
  pipeline_id = ('PHASE161H_PIPELINE_' + (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss'))
  phase_id = $PhaseId
  mode = $(if ($DryRun) { 'DRY_RUN' } else { 'REAL' })
  branch = $branch
  head_before = $headBefore
  functional_commit_message = $FunctionalCommitMessage
  refresh_commit_message = $RefreshCommitMessage
  accepted_phase = $AcceptedPhase
  validator_command_supplied = -not [string]::IsNullOrWhiteSpace($ValidatorCommand)
  functional_paths = $functionalPaths
  allowed_functional_paths = $AllowedFunctionalPaths
  allowed_refresh_paths = $AllowedRefreshPaths
  sequence = @(
    'VALIDATE_FUNCTIONAL_CHANGE',
    'COMMIT_FUNCTIONAL_CHANGE',
    'PUSH_AND_VERIFY_FUNCTIONAL_COMMIT',
    'RUN_SELF_MAP_REFRESH_AGAINST_FUNCTIONAL_COMMIT',
    'VALIDATE_SELF_KNOWLEDGE_READY',
    'COMMIT_REFRESH_ARTIFACTS',
    'PUSH_AND_VERIFY_REFRESH_COMMIT'
  )
  functional_commit = $null
  refresh_commit = $null
  map_refresh_status = $(if ($DryRun) { 'PLANNED_SELF_KNOWLEDGE_READY_REQUIRED' } else { $null })
  self_knowledge_ready = $false
  map_is_ready_for_next_decision = $false
  protected_state_mutated = $false
  runtime_outputs_staged = $false
  push_performed = $false
  accepted_change_complete = $false
  created_at = (Get-Date).ToUniversalTime().ToString('o')
}

if ($DryRun) {
  $planned.self_knowledge_ready = $false
  $planned.map_is_ready_for_next_decision = $false
  $planned.accepted_change_complete = $false
  return $planned
}

if (-not [string]::IsNullOrWhiteSpace($ValidatorCommand)) {
  & pwsh -NoProfile -Command $ValidatorCommand
  Assert-BuilderPipeline ($LASTEXITCODE -eq 0) 'Functional validator command failed.'
}

foreach ($path in $AllowedFunctionalPaths) {
  if (Test-Path -LiteralPath (Join-Path $root $path)) {
    Invoke-BuilderGit -Root $root -Arguments @('add','--',$path)
  }
}
$stagedFunctional = @(git -C $root diff --cached --name-only | ForEach-Object { $_ -replace '\\','/' })
Assert-BuilderPipeline ($stagedFunctional.Count -gt 0) 'No functional files staged.'
Assert-BuilderSubset -Paths $stagedFunctional -Allowed $AllowedFunctionalPaths -Label 'Functional index'
Assert-BuilderPipeline (@($stagedFunctional | Where-Object { $_ -like 'runtime_sessions/*' }).Count -eq 0) 'runtime_sessions staged in functional commit.'

Invoke-BuilderGit -Root $root -Arguments @('commit','-m',$FunctionalCommitMessage)
$functionalCommit = (git -C $root rev-parse HEAD).Trim()
Invoke-BuilderGit -Root $root -Arguments @('push','origin',$branch)
Invoke-BuilderGit -Root $root -Arguments @('fetch','--all','--prune')
$remoteFunctional = (git -C $root rev-parse "origin/$branch").Trim()
Assert-BuilderPipeline ($functionalCommit -eq $remoteFunctional) 'Functional commit is not visible on remote.'

$refreshModule = Join-Path $root 'modules/invoke_builder_self_map_refresh_after_acceptance_001.ps1'
& $refreshModule -AcceptedSubjectHead $functionalCommit -AcceptedPhase $AcceptedPhase -TriggerReason "acceptance_pipeline_after_$PhaseId" -RepoRoot $root | Out-Null
$contractModule = Join-Path $root 'modules/validate_builder_acceptance_self_map_refresh_contract_001.ps1'
$contract = & $contractModule -RepoRoot $root
Assert-BuilderPipeline ($contract.result -eq 'PASS') 'Self-map refresh contract failed.'
Assert-BuilderPipeline ($contract.map_refresh_status -eq 'SELF_KNOWLEDGE_READY') 'Self-map refresh is not ready.'
Assert-BuilderPipeline ([bool]$contract.self_knowledge_ready) 'self_knowledge_ready is false.'
Assert-BuilderPipeline ([bool]$contract.map_is_ready_for_next_decision) 'map_is_ready_for_next_decision is false.'

$refreshChanges = Get-BuilderRelativeGitPaths -Root $root
Assert-BuilderSubset -Paths $refreshChanges -Allowed $AllowedRefreshPaths -Label 'Refresh worktree'
foreach ($path in $AllowedRefreshPaths) {
  if (Test-Path -LiteralPath (Join-Path $root $path)) {
    Invoke-BuilderGit -Root $root -Arguments @('add','--',$path)
  }
}
$stagedRefresh = @(git -C $root diff --cached --name-only | ForEach-Object { $_ -replace '\\','/' })
Assert-BuilderPipeline ($stagedRefresh.Count -gt 0) 'No refresh files staged.'
Assert-BuilderSubset -Paths $stagedRefresh -Allowed $AllowedRefreshPaths -Label 'Refresh index'
Assert-BuilderPipeline (@($stagedRefresh | Where-Object { $_ -like 'runtime_sessions/*' }).Count -eq 0) 'runtime_sessions staged in refresh commit.'

Invoke-BuilderGit -Root $root -Arguments @('commit','-m',$RefreshCommitMessage)
$refreshCommit = (git -C $root rev-parse HEAD).Trim()
Invoke-BuilderGit -Root $root -Arguments @('push','origin',$branch)
Invoke-BuilderGit -Root $root -Arguments @('fetch','--all','--prune')
$remoteRefresh = (git -C $root rev-parse "origin/$branch").Trim()
Assert-BuilderPipeline ($refreshCommit -eq $remoteRefresh) 'Refresh commit is not visible on remote.'
Assert-BuilderPipeline (@(git -C $root status --porcelain).Count -eq 0) 'Worktree is not clean after pipeline.'

$planned.functional_commit = $functionalCommit
$planned.refresh_commit = $refreshCommit
$planned.map_refresh_status = $contract.map_refresh_status
$planned.self_knowledge_ready = [bool]$contract.self_knowledge_ready
$planned.map_is_ready_for_next_decision = [bool]$contract.map_is_ready_for_next_decision
$planned.push_performed = $true
$planned.accepted_change_complete = $true

$writer = Join-Path $root 'modules/write_builder_acceptance_pipeline_refresh_delivery_001.ps1'
& $writer -RepoRoot $root -PipelineResult $planned | Out-Null
$planned
