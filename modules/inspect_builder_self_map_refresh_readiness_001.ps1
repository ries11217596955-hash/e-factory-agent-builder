param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = 'reports/self_development'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path $RepoRoot).Path
$resultPath = Join-Path $root (Join-Path $OutputRoot 'self_map_refresh_after_acceptance_result.json')
$activePath = Join-Path $root (Join-Path $OutputRoot 'SELF_MODEL_ACTIVE_MAP.json')
$reportPath = Join-Path $root (Join-Path $OutputRoot 'self_map_memory_report.md')

$result = $null
$active = $null
if (Test-Path -LiteralPath $resultPath) { $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json }
if (Test-Path -LiteralPath $activePath) { $active = Get-Content -LiteralPath $activePath -Raw | ConvertFrom-Json }

[pscustomobject]@{
  readiness_status = $(if ($result -and $result.self_knowledge_ready -and $result.map_is_ready_for_next_decision) { 'SELF_KNOWLEDGE_READY' } else { 'NOT_READY' })
  result_exists = (Test-Path -LiteralPath $resultPath)
  active_map_exists = (Test-Path -LiteralPath $activePath)
  memory_report_exists = (Test-Path -LiteralPath $reportPath)
  accepted_subject_head = $(if ($result) { $result.accepted_subject_head } else { $null })
  map_refresh_status = $(if ($result) { $result.map_refresh_status } else { $null })
  self_knowledge_ready = $(if ($result) { [bool]$result.self_knowledge_ready } else { $false })
  map_is_ready_for_next_decision = $(if ($result) { [bool]$result.map_is_ready_for_next_decision } else { $false })
  active_map_status = $(if ($active) { $active.map_refresh_status } else { $null })
}
