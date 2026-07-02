param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = 'reports/self_development'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Assert-BuilderContract {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

$root = (Resolve-Path $RepoRoot).Path
$policyPath = Join-Path $root (Join-Path $OutputRoot 'self_map_refresh_policy.json')
$resultPath = Join-Path $root (Join-Path $OutputRoot 'self_map_refresh_after_acceptance_result.json')
$activePath = Join-Path $root (Join-Path $OutputRoot 'SELF_MODEL_ACTIVE_MAP.json')
$reportPath = Join-Path $root (Join-Path $OutputRoot 'self_map_memory_report.md')

Assert-BuilderContract (Test-Path -LiteralPath $policyPath) 'self_map_refresh_policy.json missing'
Assert-BuilderContract (Test-Path -LiteralPath $resultPath) 'self_map_refresh_after_acceptance_result.json missing'
Assert-BuilderContract (Test-Path -LiteralPath $activePath) 'SELF_MODEL_ACTIVE_MAP.json missing'
Assert-BuilderContract (Test-Path -LiteralPath $reportPath) 'self_map_memory_report.md missing'

$policy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
$result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
$active = Get-Content -LiteralPath $activePath -Raw | ConvertFrom-Json
$reportText = Get-Content -LiteralPath $reportPath -Raw

Assert-BuilderContract ($policy.required_after_accepted_commit -eq $true) 'policy does not require refresh after accepted commit'
Assert-BuilderContract ($policy.passive_stale_allowed -eq $false) 'policy allows passive stale behavior'
Assert-BuilderContract ($result.map_refresh_status -ne 'STALE') 'result is stale'
Assert-BuilderContract ($active.map_refresh_status -ne 'STALE') 'active map is stale'
Assert-BuilderContract ($result.map_refresh_status -eq 'SELF_KNOWLEDGE_READY') 'result not SELF_KNOWLEDGE_READY'
Assert-BuilderContract ($active.map_refresh_status -eq 'SELF_KNOWLEDGE_READY') 'active map not SELF_KNOWLEDGE_READY'
Assert-BuilderContract ([bool]$result.self_knowledge_ready) 'result self_knowledge_ready is false'
Assert-BuilderContract ([bool]$active.self_knowledge_ready) 'active self_knowledge_ready is false'
Assert-BuilderContract ([bool]$result.map_is_ready_for_next_decision) 'result map_is_ready_for_next_decision is false'
Assert-BuilderContract ([bool]$active.map_is_ready_for_next_decision) 'active map_is_ready_for_next_decision is false'
Assert-BuilderContract (-not [string]::IsNullOrWhiteSpace($result.accepted_subject_head)) 'accepted_subject_head missing in result'
Assert-BuilderContract (-not [string]::IsNullOrWhiteSpace($active.accepted_subject_head)) 'accepted_subject_head missing in active map'
Assert-BuilderContract ($reportText -match 'I remember myself') 'memory report missing required phrase'
Assert-BuilderContract ($result.protected_state_mutated -eq $false) 'protected state mutated'
Assert-BuilderContract ($result.runtime_outputs_staged -eq $false) 'runtime outputs staged'

[pscustomobject]@{
  result = 'PASS'
  policy_id = $policy.policy_id
  accepted_subject_head = $result.accepted_subject_head
  map_refresh_status = $result.map_refresh_status
  self_knowledge_ready = [bool]$result.self_knowledge_ready
  map_is_ready_for_next_decision = [bool]$result.map_is_ready_for_next_decision
}
