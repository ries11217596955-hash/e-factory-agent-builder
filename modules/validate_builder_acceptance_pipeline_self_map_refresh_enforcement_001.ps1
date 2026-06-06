param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [Parameter(Mandatory=$true)]$PipelineDryRunResult
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Assert-Enforcement { param([bool]$Condition,[string]$Message) if(-not $Condition){throw $Message} }

$root = (Resolve-Path $RepoRoot).Path
$policyInspector = Join-Path $root 'modules/inspect_builder_acceptance_pipeline_self_map_refresh_policy_001.ps1'
$policy = & $policyInspector -RepoRoot $root

Assert-Enforcement ($policy.policy_status -eq 'PASS') 'Acceptance pipeline policy failed.'
Assert-Enforcement ($PipelineDryRunResult.mode -eq 'DRY_RUN') 'Pipeline result is not dry-run.'
Assert-Enforcement ($PipelineDryRunResult.sequence.Count -eq 7) 'Pipeline sequence is incomplete.'
Assert-Enforcement ($PipelineDryRunResult.sequence[1] -eq 'COMMIT_FUNCTIONAL_CHANGE') 'Functional commit step missing.'
Assert-Enforcement ($PipelineDryRunResult.sequence[3] -eq 'RUN_SELF_MAP_REFRESH_AGAINST_FUNCTIONAL_COMMIT') 'Automatic refresh step missing.'
Assert-Enforcement ($PipelineDryRunResult.sequence[5] -eq 'COMMIT_REFRESH_ARTIFACTS') 'Refresh commit step missing.'
Assert-Enforcement ($PipelineDryRunResult.map_refresh_status -eq 'PLANNED_SELF_KNOWLEDGE_READY_REQUIRED') 'Dry-run does not require SELF_KNOWLEDGE_READY.'
Assert-Enforcement ($PipelineDryRunResult.accepted_change_complete -eq $false) 'Dry-run incorrectly marks change accepted.'
Assert-Enforcement ($PipelineDryRunResult.push_performed -eq $false) 'Dry-run performed push.'
Assert-Enforcement ($policy.passive_stale_allowed -eq $false) 'Passive stale behavior is allowed.'
Assert-Enforcement ($policy.refresh_subject_is_functional_commit -eq $true) 'Refresh subject is not functional commit.'
Assert-Enforcement ($policy.no_infinite_refresh_recursion -eq $true) 'Infinite refresh recursion is not prevented.'

[pscustomobject]@{
  result = 'PASS'
  policy_id = $policy.policy_id
  automatic_refresh_enforced = $true
  functional_then_refresh_commit_enforced = $true
  self_knowledge_ready_required = $true
  passive_stale_allowed = $false
  dry_run_no_commit = $true
  dry_run_no_push = $true
}
