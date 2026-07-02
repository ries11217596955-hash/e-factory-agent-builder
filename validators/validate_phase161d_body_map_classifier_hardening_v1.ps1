param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Add-Phase161DCheck {
  param(
    [System.Collections.Generic.List[object]]$Checks,
    [string]$Name,
    [bool]$Pass,
    [string]$Details
  )
  $Checks.Add([pscustomobject]@{ name = $Name; pass = $Pass; details = $Details })
  if (-not $Pass) {
    throw "PHASE161D validator failed: $Name :: $Details"
  }
}

function Read-Phase161DJson {
  param([string]$Path)
  return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
}

function Write-Phase161DJson {
  param([string]$Path, $Value, [int]$Depth = 20)
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
  $Value | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-Phase161DProtectedHashes {
  param([string]$Root)
  $paths = @('TASK_QUEUE.json','GENESIS_STATE.json','CAPABILITY_ROADMAP.json','packs/registry.json','orchestrator/run.ps1')
  $hashes = [ordered]@{}
  foreach ($path in $paths) {
    $full = Join-Path $Root $path
    $hashes[$path] = $(if (Test-Path -LiteralPath $full) { (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash } else { 'MISSING' })
  }
  return $hashes
}

$root = (Resolve-Path $RepoRoot).Path
$checks = New-Object System.Collections.Generic.List[object]
$phase = 'PHASE161D_BODY_MAP_CLASSIFIER_HARDENING_AND_LIVE_EVIDENCE_SEPARATION_V1'
$reportRoot = Join-Path $root 'reports/self_development'
$proofRoot = Join-Path $root 'proofs/self_development'
$routeRoot = Join-Path $root 'route_change_requests'

$requiredRoot = @('CAPABILITY_ROADMAP.json','GENESIS_STATE.json','TASK_QUEUE.json','packs/registry.json','orchestrator/run.ps1')
$missingRoot = @($requiredRoot | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_)) })
Add-Phase161DCheck -Checks $checks -Name 'root_guard' -Pass ($missingRoot.Count -eq 0) -Details "missing=$($missingRoot -join ',')"

$branch = (git -C $root branch --show-current).Trim()
$head = (git -C $root rev-parse HEAD).Trim()
$remote = (git -C $root remote -v | Out-String).Trim()
$statusBefore = (git -C $root status --short | Out-String).Trim()

$planPath = Join-Path $reportRoot 'PHASE161D_EXECUTION_PLAN.md'
Add-Phase161DCheck -Checks $checks -Name 'plan_exists' -Pass (Test-Path -LiteralPath $planPath) -Details 'PHASE161D execution plan exists.'

$protectedBefore = Get-Phase161DProtectedHashes -Root $root

$ps1Files = @(
  'modules/build_builder_agent_body_map_001.ps1',
  'modules/classify_builder_agent_body_artifact_001.ps1',
  'modules/inspect_builder_module_wiring_graph_001.ps1',
  'modules/detect_builder_stub_placeholder_artifacts_001.ps1',
  'modules/detect_builder_orphaned_artifacts_001.ps1',
  'modules/build_builder_self_model_gap_chain_001.ps1',
  'modules/update_builder_self_model_active_map_001.ps1',
  'modules/inspect_builder_agent_body_map_freshness_001.ps1',
  'validators/validate_phase161d_body_map_classifier_hardening_v1.ps1'
)
$parserResults = New-Object System.Collections.Generic.List[object]
foreach ($rel in $ps1Files) {
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $root $rel), [ref]$null, [ref]$errors) | Out-Null
  $parserResults.Add([pscustomobject]@{
    path = $rel
    parser_status = $(if ($errors -and $errors.Count -gt 0) { 'FAIL' } else { 'PASS' })
    errors = @($errors | ForEach-Object { $_.Message })
  })
}
$parserFailures = @($parserResults | Where-Object { $_.parser_status -ne 'PASS' })
Add-Phase161DCheck -Checks $checks -Name 'parser_checks' -Pass ($parserFailures.Count -eq 0) -Details "parser_failures=$($parserFailures.Count)"

$builderOutput = & (Join-Path $root 'modules/build_builder_agent_body_map_001.ps1') -RepoRoot $root -OutputRoot 'reports/self_development' -Build
$builderResult = $builderOutput | ConvertFrom-Json
Add-Phase161DCheck -Checks $checks -Name 'builder_runs' -Pass ($builderResult.result -eq 'PASS') -Details "classifier=$($builderResult.classifier_version); artifacts=$($builderResult.artifact_count)"

$requiredOutputs = @(
  'reports/self_development/agent_body_map.json',
  'reports/self_development/agent_body_map.md',
  'reports/self_development/module_wiring_graph.json',
  'reports/self_development/function_inventory.json',
  'reports/self_development/stub_placeholder_inventory.json',
  'reports/self_development/orphaned_artifact_inventory.json',
  'reports/self_development/self_model_gap_chain.json',
  'reports/self_development/SELF_MODEL_ACTIVE_MAP.json',
  'reports/self_development/safe_repair_candidates_from_body_map.json',
  'reports/self_development/unsafe_debt_backlog_from_body_map.json',
  'reports/self_development/agent_body_map_classifier_hardening_result.json',
  'reports/self_development/live_evidence_separation_index.json',
  'reports/self_development/historical_reference_inventory.json',
  'reports/self_development/superseded_artifact_inventory.json',
  'reports/self_development/stub_false_positive_inventory.json'
)
foreach ($rel in $requiredOutputs) {
  Add-Phase161DCheck -Checks $checks -Name "output_exists_$($rel -replace '[^A-Za-z0-9]+','_')" -Pass (Test-Path -LiteralPath (Join-Path $root $rel)) -Details "$rel exists."
}

$bodyMap = Read-Phase161DJson -Path (Join-Path $root 'reports/self_development/agent_body_map.json')
$hardening = Read-Phase161DJson -Path (Join-Path $root 'reports/self_development/agent_body_map_classifier_hardening_result.json')
$liveIndex = Read-Phase161DJson -Path (Join-Path $root 'reports/self_development/live_evidence_separation_index.json')
$historical = Read-Phase161DJson -Path (Join-Path $root 'reports/self_development/historical_reference_inventory.json')
$superseded = Read-Phase161DJson -Path (Join-Path $root 'reports/self_development/superseded_artifact_inventory.json')
$falseStubs = Read-Phase161DJson -Path (Join-Path $root 'reports/self_development/stub_false_positive_inventory.json')
$stubs = Read-Phase161DJson -Path (Join-Path $root 'reports/self_development/stub_placeholder_inventory.json')
$orphans = Read-Phase161DJson -Path (Join-Path $root 'reports/self_development/orphaned_artifact_inventory.json')

Add-Phase161DCheck -Checks $checks -Name 'classifier_version' -Pass ($bodyMap.classifier_version -eq 'PHASE161D_STRICT_EVIDENCE_V1' -and $hardening.classifier_version -eq 'PHASE161D_STRICT_EVIDENCE_V1') -Details 'Strict evidence classifier active.'
Add-Phase161DCheck -Checks $checks -Name 'active_proven_reduced' -Pass ([int]$hardening.active_wired_proven_count -lt 842) -Details "active_wired_proven=$($hardening.active_wired_proven_count)"
Add-Phase161DCheck -Checks $checks -Name 'present_not_wired_nonzero' -Pass ([int]$hardening.present_not_wired_count -gt 0) -Details "present_not_wired=$($hardening.present_not_wired_count)"
Add-Phase161DCheck -Checks $checks -Name 'orphan_inventory_nonzero' -Pass ((@($orphans.items).Count) -gt 0) -Details "orphan_candidates=$(@($orphans.items).Count)"
Add-Phase161DCheck -Checks $checks -Name 'supersession_propagated' -Pass ((@($superseded.items).Count) -gt 0 -and [int]$hardening.superseded_count -gt 0) -Details "superseded=$($hardening.superseded_count)"
Add-Phase161DCheck -Checks $checks -Name 'stub_false_positive_exposed' -Pass ((@($falseStubs.items).Count) -gt 0 -and [int]$hardening.false_positive_stub_count -gt 0) -Details "false_positive_stubs=$($hardening.false_positive_stub_count)"
Add-Phase161DCheck -Checks $checks -Name 'real_stub_count_reduced' -Pass ([int]$hardening.real_stub_count -lt 52) -Details "real_stubs=$($hardening.real_stub_count)"
Add-Phase161DCheck -Checks $checks -Name 'historical_inventory_present' -Pass ((@($historical.items).Count) -gt 0) -Details "historical=$(@($historical.items).Count)"
Add-Phase161DCheck -Checks $checks -Name 'live_evidence_index_present' -Pass ((@($liveIndex.evidence_type_counts).Count) -gt 0) -Details 'Evidence type counts present.'

$allowedEvidenceTypes = @(
  'LIVE_RUNTIME_PROVEN',
  'CURRENT_DAEMON_WIRED',
  'CURRENT_ROUTE_WIRED',
  'CURRENT_RUNNER_WIRED',
  'VALIDATOR_PROVEN',
  'PROOF_JSON_PROVEN',
  'REPORT_REFERENCED',
  'HISTORICAL_REFERENCE_ONLY',
  'SUPERSEDED_BY_ROUTE_LOCK',
  'DISCONNECTED_NOT_WIRED',
  'REAL_STUB_OR_PLACEHOLDER',
  'FALSE_POSITIVE_STUB_SIGNAL',
  'PROTECTED_RISK_LOCKED',
  'UNKNOWN_NEEDS_REVIEW'
)
$badEvidence = @($bodyMap.artifacts | Where-Object {
  [string]::IsNullOrWhiteSpace($_.evidence_type) -or
  [string]::IsNullOrWhiteSpace($_.evidence_strength) -or
  $_.evidence_type -notin $allowedEvidenceTypes
} | Select-Object -First 5)
Add-Phase161DCheck -Checks $checks -Name 'evidence_fields_present' -Pass ($badEvidence.Count -eq 0) -Details 'Every artifact has allowed evidence_type and evidence_strength.'

$badActive = @($bodyMap.artifacts | Where-Object {
  $_.primary_status -eq 'ACTIVE_WIRED_PROVEN' -and
  $_.evidence_type -notin @('LIVE_RUNTIME_PROVEN','CURRENT_DAEMON_WIRED','CURRENT_ROUTE_WIRED','CURRENT_RUNNER_WIRED')
} | Select-Object -First 5)
Add-Phase161DCheck -Checks $checks -Name 'active_proven_requires_current_or_live_evidence' -Pass ($badActive.Count -eq 0) -Details 'Active proven items use live/current evidence types only.'

$protectedAfter = Get-Phase161DProtectedHashes -Root $root
$mutatedProtected = @($protectedBefore.Keys | Where-Object { $protectedBefore[$_] -ne $protectedAfter[$_] })
Add-Phase161DCheck -Checks $checks -Name 'protected_state_clean' -Pass ($mutatedProtected.Count -eq 0) -Details "mutated=$($mutatedProtected -join ',')"

$runtimeStatus = (git -C $root status --short -- runtime_sessions | Out-String).Trim()
Add-Phase161DCheck -Checks $checks -Name 'runtime_outputs_not_staged' -Pass ([string]::IsNullOrWhiteSpace($runtimeStatus)) -Details "runtime_status=$runtimeStatus"

$statusAfter = (git -C $root status --short | Out-String).Trim()

$proof = [pscustomobject][ordered]@{
  phase = $phase
  result = 'PASS'
  pwd = $root
  branch = $branch
  head = $head
  remote = $remote
  status_before_validation = $statusBefore
  status_after_validation = $statusAfter
  parser_results = @($parserResults.ToArray())
  builder_result = $builderResult
  hardening_result = $hardening
  checks = @($checks.ToArray())
  protected_hashes_before = $protectedBefore
  protected_hashes_after = $protectedAfter
  protected_state_mutated = $false
  runtime_outputs_staged = $false
  final_recommendation = 'READY_FOR_OWNER_REVIEW'
}

$proofPath = Join-Path $proofRoot 'PHASE161D_BODY_MAP_CLASSIFIER_HARDENING_PROOF.json'
Write-Phase161DJson -Path $proofPath -Value $proof -Depth 20

$reportPath = Join-Path $reportRoot 'PHASE161D_BODY_MAP_CLASSIFIER_HARDENING_REPORT.md'
$report = @(
  '# PHASE161D Body Map Classifier Hardening Report',
  '',
  'Result: `PASS`',
  '',
  "Branch: ``$branch``",
  "HEAD: ``$head``",
  '',
  'PHASE161D reused the PHASE161C body map builder and hardened classifier behavior.',
  '',
  "Active wired proven count: $($hardening.active_wired_proven_count)",
  "Present not wired count: $($hardening.present_not_wired_count)",
  "Superseded count: $($hardening.superseded_count)",
  "False-positive stub count: $($hardening.false_positive_stub_count)",
  "Real stub count: $($hardening.real_stub_count)",
  '',
  'Proof:',
  '',
  '- `proofs/self_development/PHASE161D_BODY_MAP_CLASSIFIER_HARDENING_PROOF.json`',
  '',
  'Final recommendation: `READY_FOR_OWNER_REVIEW`'
)
$report | Set-Content -LiteralPath $reportPath -Encoding UTF8

$routePath = Join-Path $routeRoot 'PHASE161D_BODY_MAP_CLASSIFIER_HARDENING_REQUEST.md'
$route = @(
  '# PHASE161D Route Change Request',
  '',
  'Request: accept PHASE161D classifier hardening and live evidence separation as the next derived-map repair candidate.',
  '',
  'No protected state mutation is requested.',
  '',
  'Proof:',
  '',
  '- `proofs/self_development/PHASE161D_BODY_MAP_CLASSIFIER_HARDENING_PROOF.json`'
)
$route | Set-Content -LiteralPath $routePath -Encoding UTF8

$deliveryPath = Join-Path $reportRoot 'PHASE161D_BODY_MAP_CLASSIFIER_HARDENING_CODEX_DELIVERY.md'
$statusAfter = (git -C $root status --short | Out-String).Trim()
$delivery = @(
  '# PHASE161D Codex Delivery',
  '',
  'Root guard result: `PASS`',
  '',
  "PWD: ``$root``",
  "Branch: ``$branch``",
  "HEAD: ``$head``",
  "Remote: ``$remote``",
  '',
  'Parser check result: `PASS`',
  'Validator output: `PASS`',
  '',
  'Proof path: `proofs/self_development/PHASE161D_BODY_MAP_CLASSIFIER_HARDENING_PROOF.json`',
  'Report path: `reports/self_development/PHASE161D_BODY_MAP_CLASSIFIER_HARDENING_REPORT.md`',
  '',
  "Active wired proven count: $($hardening.active_wired_proven_count)",
  "Present not wired count: $($hardening.present_not_wired_count)",
  "Superseded count: $($hardening.superseded_count)",
  "False-positive stub count: $($hardening.false_positive_stub_count)",
  '',
  'Runtime dirs created: none',
  'Runtime was cleaned: not applicable',
  'Protected state mutated: `False`',
  'Runtime outputs staged: `False`',
  '',
  'Git status after validation:',
  '```',
  $statusAfter,
  '```',
  '',
  'Final recommendation: `READY_FOR_OWNER_REVIEW`'
)
$delivery | Set-Content -LiteralPath $deliveryPath -Encoding UTF8

Write-Host 'PHASE161D_BODY_MAP_CLASSIFIER_HARDENING_VALIDATE_RESULT=PASS'
Write-Host 'ROOT_GUARD=PASS'
Write-Host 'PLAN_FIRST_GATE_PASS=True'
Write-Host 'REUSED_PHASE161C_MAP_MODULES=True'
Write-Host 'EVIDENCE_TYPE_FIELDS_PRESENT=True'
Write-Host 'LIVE_EVIDENCE_SEPARATION_PRESENT=True'
Write-Host 'ACTIVE_WIRED_PROVEN_REDUCED=True'
Write-Host 'PRESENT_NOT_WIRED_NONZERO=True'
Write-Host 'SUPERSESSION_PROPAGATED=True'
Write-Host 'STUB_FALSE_POSITIVES_SEPARATED=True'
Write-Host 'PROTECTED_STATE_MUTATED=False'
Write-Host 'RUNTIME_OUTPUTS_STAGED=False'
Write-Host 'NO_COMMIT_PERFORMED=True'
Write-Host 'NO_PUSH_PERFORMED=True'
Write-Host 'FINAL_RECOMMENDATION=READY_FOR_OWNER_REVIEW'
