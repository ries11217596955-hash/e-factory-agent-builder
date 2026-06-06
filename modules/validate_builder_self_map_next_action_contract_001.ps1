param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = 'reports/self_development'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Assert-NextAction {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

$root = (Resolve-Path $RepoRoot).Path
$output = Join-Path $root $OutputRoot
$recommendation = Get-Content (Join-Path $output 'self_map_next_action_recommendation.json') -Raw | ConvertFrom-Json
$health = Get-Content (Join-Path $output 'organism_health_state.json') -Raw | ConvertFrom-Json
$active = Get-Content (Join-Path $output 'SELF_MODEL_ACTIVE_MAP.json') -Raw | ConvertFrom-Json
$memory = Get-Content (Join-Path $output 'self_map_memory_report.md') -Raw

Assert-NextAction (-not [string]::IsNullOrWhiteSpace($recommendation.why_this_step)) 'why_this_step missing.'
Assert-NextAction (-not [string]::IsNullOrWhiteSpace($recommendation.why_not_delete_first)) 'why_not_delete_first missing.'
Assert-NextAction (-not [string]::IsNullOrWhiteSpace($recommendation.why_not_connect_everything_first)) 'why_not_connect_everything_first missing.'
Assert-NextAction (-not [string]::IsNullOrWhiteSpace($recommendation.why_not_repair_all_stubs_first)) 'why_not_repair_all_stubs_first missing.'
Assert-NextAction (@($recommendation.completed_recommendations_detected | Where-Object { $_.phase -eq 'PHASE161G2' }).Count -eq 1) 'PHASE161G2 completion not detected.'
Assert-NextAction ($recommendation.recommended_next_macro_step -notmatch '(?i)review.*protected.state candidate') 'Stale protected candidate review selected.'
Assert-NextAction ($recommendation.next_action_type -ne 'CLEANUP') 'Deletion/cleanup selected first without critical proof.'
Assert-NextAction ($recommendation.delayed_scope.task_queue -eq 'DELAY') 'TASK_QUEUE delay missing.'
Assert-NextAction ($recommendation.delayed_scope.packs_registry -eq 'DELAY') 'packs registry delay missing.'
Assert-NextAction ($recommendation.delayed_scope.orchestrator_run -in @('DELAY','REJECT')) 'orchestrator reject/delay missing.'
Assert-NextAction ($active.organism_health_state -eq $health.health_state) 'Active-map health mismatch.'
Assert-NextAction ($active.recommended_next_macro_step -eq $recommendation.recommended_next_macro_step) 'Active-map recommendation mismatch.'
Assert-NextAction ($memory -match '## Organism Health State') 'Memory report health section missing.'
Assert-NextAction ($memory -match '## Recommended Next Macro-Step') 'Memory report recommendation section missing.'
if ($health.health_state -eq 'HEALTHY') {
  Assert-NextAction (@($health.critical_findings).Count -eq 0) 'HEALTHY with critical findings.'
  Assert-NextAction (@($health.healthy_criteria_failed).Count -eq 0) 'HEALTHY with failed criteria.'
  Assert-NextAction ($memory -match 'No required repair; optional improvement only\.') 'Healthy memory statement missing.'
}

[pscustomobject]@{
  result = 'PASS'
  health_state = $health.health_state
  health_score = [int]$health.health_score
  recommended_next_macro_step = $recommendation.recommended_next_macro_step
  recommended_next_phase_id = $recommendation.recommended_next_phase_id
  next_action_type = $recommendation.next_action_type
  stale_protected_review_blocked = $true
}
