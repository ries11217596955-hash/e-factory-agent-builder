param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = 'reports/self_development',
  [string]$AcceptedSubjectHead,
  [string]$AcceptedPhase = 'PHASE161E_SELF_MAP_AUTO_REFRESH_AFTER_ACCEPTED_CHANGE',
  [string]$RefreshResultPath = 'reports/self_development/self_map_refresh_after_acceptance_result.json'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-BuilderJson {
  param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Get-BuilderTopItems {
  param($Items, [int]$Count = 10)
  if ($null -eq $Items) { return @() }
  return @($Items | Select-Object -First $Count)
}

$root = (Resolve-Path $RepoRoot).Path
$outputFull = Join-Path $root $OutputRoot
if (-not (Test-Path -LiteralPath $outputFull)) {
  New-Item -ItemType Directory -Path $outputFull | Out-Null
}

$activeMapPath = Join-Path $outputFull 'SELF_MODEL_ACTIVE_MAP.json'
$bodyMapPath = Join-Path $outputFull 'agent_body_map.json'
$gapPath = Join-Path $outputFull 'self_model_gap_chain.json'
$hardeningPath = Join-Path $outputFull 'agent_body_map_classifier_hardening_result.json'
$liveIndexPath = Join-Path $outputFull 'live_evidence_separation_index.json'
$stubPath = Join-Path $outputFull 'stub_placeholder_inventory.json'
$falseStubPath = Join-Path $outputFull 'stub_false_positive_inventory.json'
$historicalPath = Join-Path $outputFull 'historical_reference_inventory.json'
$supersededPath = Join-Path $outputFull 'superseded_artifact_inventory.json'
$reportPath = Join-Path $outputFull 'self_map_memory_report.md'

$activeMap = Get-BuilderJson -Path $activeMapPath
$bodyMap = Get-BuilderJson -Path $bodyMapPath
$gaps = Get-BuilderJson -Path $gapPath
$hardening = Get-BuilderJson -Path $hardeningPath
$liveIndex = Get-BuilderJson -Path $liveIndexPath
$stubInventory = Get-BuilderJson -Path $stubPath
$falseStubInventory = Get-BuilderJson -Path $falseStubPath
$historicalInventory = Get-BuilderJson -Path $historicalPath
$supersededInventory = Get-BuilderJson -Path $supersededPath

$activeOrgans = Get-BuilderTopItems -Items $activeMap.active_artifacts -Count 15
$validatorOnly = @()
if ($bodyMap -and $bodyMap.artifacts) {
  $validatorOnly = Get-BuilderTopItems -Items (@($bodyMap.artifacts | Where-Object { $_.primary_status -eq 'PRESENT_WIRED_TO_VALIDATOR_ONLY' })) -Count 10
  $presentNotWired = Get-BuilderTopItems -Items (@($bodyMap.artifacts | Where-Object { $_.primary_status -eq 'PRESENT_NOT_WIRED' })) -Count 10
} else {
  $presentNotWired = @()
}

$gapItems = @()
if ($gaps -and $gaps.gaps) { $gapItems = @($gaps.gaps) }
$nextMacro = 'Refresh self-map after each accepted change before selecting the next learning or repair task.'
$nextWhy = 'The accepted baseline can then choose work from current live evidence, present-not-wired gaps, and strict stub classifications instead of stale or over-optimistic memory.'
if ($gapItems.Count -gt 0 -and $gapItems[0].recommended_next_action) {
  $nextMacro = $gapItems[0].recommended_next_action
  $nextWhy = $gapItems[0].why_status
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# Self Map Memory Report')
$lines.Add('')
$lines.Add('I remember myself; here is my current report.')
$lines.Add('')
$lines.Add(('Accepted subject head: {0}' -f $AcceptedSubjectHead))
$lines.Add(('Current baseline phase: {0}' -f $AcceptedPhase))
$lines.Add(('Map refresh status: {0}' -f $activeMap.map_refresh_status))
$lines.Add(('Self knowledge ready: {0}' -f $activeMap.self_knowledge_ready))
$lines.Add(('Map ready for next decision: {0}' -f $activeMap.map_is_ready_for_next_decision))
$lines.Add(('Active route: {0}' -f $activeMap.active_route_lock))
$lines.Add('')
$lines.Add('## Counts')
$lines.Add('')
$historicalCount = $(if ($historicalInventory.items) { @($historicalInventory.items).Count } else { 0 })
$lines.Add(('- Active wired proven: {0}' -f $hardening.active_wired_proven_count))
$lines.Add(('- Present not wired: {0}' -f $hardening.present_not_wired_count))
$lines.Add(('- Historical references: {0}' -f $historicalCount))
$lines.Add(('- Superseded: {0}' -f $hardening.superseded_count))
$lines.Add(('- Real stubs: {0}' -f $hardening.real_stub_count))
$lines.Add(('- False-positive stubs: {0}' -f $hardening.false_positive_stub_count))
$lines.Add(('- Gap chains: {0}' -f $gapItems.Count))
$lines.Add('')
$lines.Add('## Top Live Or Current Active Organs')
$lines.Add('')
foreach ($item in $activeOrgans) {
  $lines.Add(('- {0}: {1}; {2}' -f $item.path, $item.primary_status, $item.why_status))
}
$lines.Add('')
$lines.Add('## Validator-Only Organs')
$lines.Add('')
foreach ($item in $validatorOnly) {
  $lines.Add(('- {0}: {1}' -f $item.path, $item.why_status))
}
$lines.Add('')
$lines.Add('## Disconnected Or Present-Not-Wired Organs')
$lines.Add('')
foreach ($item in $presentNotWired) {
  $lines.Add(('- {0}: {1}' -f $item.path, $item.why_status))
}
$lines.Add('')
$lines.Add('## Historical Or Superseded Organs')
$lines.Add('')
foreach ($item in (Get-BuilderTopItems -Items $historicalInventory.items -Count 8)) {
  $lines.Add(('- {0}: {1}' -f $item.path, $item.why_status))
}
foreach ($item in (Get-BuilderTopItems -Items $supersededInventory.items -Count 5)) {
  $lines.Add(('- {0}: {1}' -f $item.path, $item.why_status))
}
$lines.Add('')
$lines.Add('## Real Stubs')
$lines.Add('')
foreach ($item in (Get-BuilderTopItems -Items $stubInventory.items -Count 10)) {
  $lines.Add(('- {0}: {1} {2}' -f $item.path, $item.stub_signal, $item.why_status))
}
$lines.Add('')
$lines.Add('## False-Positive Stubs')
$lines.Add('')
foreach ($item in (Get-BuilderTopItems -Items $falseStubInventory.items -Count 10)) {
  $lines.Add(('- {0}: {1}' -f $item.path, $item.why_status))
}
$lines.Add('')
$lines.Add('## Top Gap Chains')
$lines.Add('')
foreach ($gap in (Get-BuilderTopItems -Items $gapItems -Count 10)) {
  $lines.Add(('- {0}: {1}' -f $gap.gap_id, $gap.why_status))
}
$lines.Add('')
$lines.Add('## Recommended Next Macro-Step')
$lines.Add('')
$lines.Add($nextMacro)
$lines.Add('')
$lines.Add('Why this is recommended:')
$lines.Add('')
$lines.Add($nextWhy)

$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

[pscustomobject]@{
  result = 'PASS'
  memory_report_path = (($reportPath.Substring($root.Length).TrimStart('\','/')) -replace '\\','/')
  accepted_subject_head = $AcceptedSubjectHead
  accepted_phase = $AcceptedPhase
  active_organs_count = @($activeOrgans).Count
  gap_chain_count = @($gapItems).Count
}
