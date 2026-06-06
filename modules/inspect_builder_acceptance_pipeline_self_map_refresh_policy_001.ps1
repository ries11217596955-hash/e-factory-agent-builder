param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$PolicyPath = 'reports/self_development/acceptance_pipeline_self_map_refresh_policy.json'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path $RepoRoot).Path
$full = Join-Path $root $PolicyPath
if (-not (Test-Path -LiteralPath $full)) {
  throw "Acceptance pipeline policy missing: $PolicyPath"
}
$policy = Get-Content -LiteralPath $full -Raw | ConvertFrom-Json

$requiredTrue = @(
  'required_after_functional_accept_commit',
  'refresh_commit_required',
  'self_knowledge_ready_required',
  'next_decision_requires_self_knowledge_ready',
  'accepted_change_is_complete_only_after_refresh',
  'functional_commit_then_refresh_commit',
  'refresh_commit_subject_is_functional_commit',
  'no_infinite_refresh_recursion'
)
$violations = New-Object System.Collections.Generic.List[string]
foreach ($name in $requiredTrue) {
  if ($policy.$name -ne $true) { $violations.Add("$name must be true") }
}
if ($policy.passive_stale_allowed -ne $false) { $violations.Add('passive_stale_allowed must be false') }
if ($policy.protected_state_direct_mutation_allowed -ne $false) { $violations.Add('protected_state_direct_mutation_allowed must be false') }
if ($policy.runtime_sessions_staged_allowed -ne $false) { $violations.Add('runtime_sessions_staged_allowed must be false') }

[pscustomobject]@{
  policy_id = $policy.policy_id
  policy_status = $(if ($violations.Count -eq 0) { 'PASS' } else { 'FAIL' })
  automatic_refresh_required = [bool]$policy.required_after_functional_accept_commit
  passive_stale_allowed = [bool]$policy.passive_stale_allowed
  two_commit_sequence_required = [bool]$policy.functional_commit_then_refresh_commit
  refresh_subject_is_functional_commit = [bool]$policy.refresh_commit_subject_is_functional_commit
  no_infinite_refresh_recursion = [bool]$policy.no_infinite_refresh_recursion
  violations = $violations.ToArray()
}
