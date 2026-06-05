param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = 'reports/self_development'
)

$root = (Resolve-Path $RepoRoot).Path
$required = @(
  'agent_body_map.json',
  'module_wiring_graph.json',
  'function_inventory.json',
  'stub_placeholder_inventory.json',
  'orphaned_artifact_inventory.json',
  'self_model_gap_chain.json',
  'SELF_MODEL_ACTIVE_MAP.json'
)

$items = foreach ($name in $required) {
  $path = Join-Path $root (Join-Path $OutputRoot $name)
  [pscustomobject]@{
    path = (Join-Path $OutputRoot $name) -replace '\\','/'
    exists = (Test-Path -LiteralPath $path)
    last_write_time_utc = $(if (Test-Path -LiteralPath $path) { (Get-Item -LiteralPath $path).LastWriteTimeUtc.ToString('o') } else { $null })
    why_status = $(if (Test-Path -LiteralPath $path) { 'Derived map artifact exists.' } else { 'Derived map artifact is missing and should be regenerated.' })
  }
}

[pscustomobject]@{
  phase = 'PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_V1'
  map_freshness_status = $(if (($items | Where-Object { -not $_.exists }).Count -eq 0) { 'PRESENT' } else { 'MISSING_ARTIFACTS' })
  items = @($items)
}
