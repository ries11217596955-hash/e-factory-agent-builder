param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Add-Phase161CCheck {
  param(
    [System.Collections.Generic.List[object]]$Checks,
    [string]$Name,
    [bool]$Pass,
    [string]$Details
  )
  $Checks.Add([pscustomobject]@{
    name = $Name
    pass = $Pass
    details = $Details
  })
  if (-not $Pass) {
    throw "PHASE161C validator failed: $Name :: $Details"
  }
}

function Read-Phase161CJson {
  param([string]$Path)
  try {
    return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
  } catch {
    throw "JSON parse failed for $Path :: $($_.Exception.Message)"
  }
}

function Write-Phase161CJson {
  param([string]$Path, $Value, [int]$Depth = 20)
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
  $Value | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-Phase161CProtectedHashes {
  param([string]$Root)
  $protected = @(
    'TASK_QUEUE.json',
    'GENESIS_STATE.json',
    'CAPABILITY_ROADMAP.json',
    'packs/registry.json',
    'orchestrator/run.ps1'
  )
  $hashes = [ordered]@{}
  foreach ($path in $protected) {
    $full = Join-Path $Root $path
    if (Test-Path -LiteralPath $full) {
      $hashes[$path] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = 'MISSING'
    }
  }
  return $hashes
}

function Test-Phase161CRequiredFields {
  param($Item)
  $required = @(
    'artifact_id',
    'path',
    'artifact_type',
    'phase_hint',
    'role_guess',
    'primary_status',
    'why_status',
    'evidence_paths',
    'callers',
    'callees',
    'validators',
    'reports',
    'proofs',
    'schemas',
    'route_lock_references',
    'last_known_phase',
    'safe_to_modify',
    'owner_approval_required',
    'recommended_next_action'
  )
  foreach ($field in $required) {
    if (-not ($Item.PSObject.Properties.Name -contains $field)) {
      return $false
    }
  }
  return $true
}

$root = (Resolve-Path $RepoRoot).Path
$checks = New-Object System.Collections.Generic.List[object]
$phase = 'PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_V1'
$outputRoot = Join-Path $root 'reports/self_development'
$proofRoot = Join-Path $root 'proofs/self_development'
$routeRoot = Join-Path $root 'route_change_requests'

$requiredRoot = @(
  'CAPABILITY_ROADMAP.json',
  'GENESIS_STATE.json',
  'TASK_QUEUE.json',
  'packs/registry.json',
  'orchestrator/run.ps1'
)
$missingRoot = @($requiredRoot | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_)) })
Add-Phase161CCheck -Checks $checks -Name 'root_guard' -Pass ($missingRoot.Count -eq 0) -Details "missing=$($missingRoot -join ',')"

$branch = (git -C $root branch --show-current).Trim()
$head = (git -C $root rev-parse HEAD).Trim()
$remote = (git -C $root remote -v | Out-String).Trim()
$statusBefore = (git -C $root status --short | Out-String).Trim()

$planPath = Join-Path $outputRoot 'PHASE161C_EXECUTION_PLAN.md'
$discoveryPath = Join-Path $outputRoot 'PHASE161C_EXISTING_MAP_DISCOVERY.json'
Add-Phase161CCheck -Checks $checks -Name 'execution_plan_exists' -Pass (Test-Path -LiteralPath $planPath) -Details 'PHASE161C execution plan present.'
Add-Phase161CCheck -Checks $checks -Name 'existing_map_discovery_exists' -Pass (Test-Path -LiteralPath $discoveryPath) -Details 'PHASE161C discovery JSON present.'
$discovery = Read-Phase161CJson -Path $discoveryPath
Add-Phase161CCheck -Checks $checks -Name 'discovery_has_organs' -Pass (($discovery.organs | Measure-Object).Count -gt 0) -Details 'Existing map/self-model organs listed.'

$explicitProtected = @('CAPABILITY_ROADMAP.json','GENESIS_STATE.json','TASK_QUEUE.json','packs/registry.json','route_locks/ACTIVE_ROUTE_LOCK.json')
foreach ($path in $explicitProtected) {
  $found = @($discovery.organs | Where-Object { $_.path -eq $path })
  Add-Phase161CCheck -Checks $checks -Name "discovery_explicit_$($path -replace '[^A-Za-z0-9]+','_')" -Pass ($found.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($found[0].why_status)) -Details "$path analyzed with why_status."
}

$protectedBefore = Get-Phase161CProtectedHashes -Root $root

$newPs1 = @(
  'modules/discover_builder_existing_self_map_organs_001.ps1',
  'modules/build_builder_agent_body_map_001.ps1',
  'modules/inspect_builder_module_wiring_graph_001.ps1',
  'modules/classify_builder_agent_body_artifact_001.ps1',
  'modules/detect_builder_stub_placeholder_artifacts_001.ps1',
  'modules/detect_builder_orphaned_artifacts_001.ps1',
  'modules/build_builder_self_model_gap_chain_001.ps1',
  'modules/update_builder_self_model_active_map_001.ps1',
  'modules/inspect_builder_agent_body_map_freshness_001.ps1',
  'validators/validate_phase161c_agent_body_map_reuse_and_self_model_sync_v1.ps1'
)
$parserResults = New-Object System.Collections.Generic.List[object]
foreach ($rel in $newPs1) {
  $full = Join-Path $root $rel
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($full, [ref]$null, [ref]$errors) | Out-Null
  $parserResults.Add([pscustomobject]@{
    path = $rel
    parser_status = $(if ($errors -and $errors.Count -gt 0) { 'FAIL' } else { 'PASS' })
    errors = @($errors | ForEach-Object { $_.Message })
  })
}
$parserFailures = @($parserResults | Where-Object { $_.parser_status -ne 'PASS' })
Add-Phase161CCheck -Checks $checks -Name 'parser_checks' -Pass ($parserFailures.Count -eq 0) -Details "parser_failures=$($parserFailures.Count)"

$builderPath = Join-Path $root 'modules/build_builder_agent_body_map_001.ps1'
$builderOutput = & $builderPath -RepoRoot $root -OutputRoot 'reports/self_development' -Build
$builderResult = $builderOutput | ConvertFrom-Json
Add-Phase161CCheck -Checks $checks -Name 'body_map_builder_runs' -Pass ($builderResult.result -eq 'PASS') -Details "artifacts=$($builderResult.artifact_count)"

$requiredArtifacts = @(
  'reports/self_development/agent_body_map.json',
  'reports/self_development/agent_body_map.md',
  'reports/self_development/module_wiring_graph.json',
  'reports/self_development/function_inventory.json',
  'reports/self_development/stub_placeholder_inventory.json',
  'reports/self_development/orphaned_artifact_inventory.json',
  'reports/self_development/self_model_gap_chain.json',
  'reports/self_development/SELF_MODEL_ACTIVE_MAP.json',
  'reports/self_development/agent_body_map_update_report.md',
  'reports/self_development/safe_repair_candidates_from_body_map.json',
  'reports/self_development/unsafe_debt_backlog_from_body_map.json'
)
foreach ($artifact in $requiredArtifacts) {
  Add-Phase161CCheck -Checks $checks -Name "artifact_exists_$($artifact -replace '[^A-Za-z0-9]+','_')" -Pass (Test-Path -LiteralPath (Join-Path $root $artifact)) -Details "$artifact exists."
}

$bodyMap = Read-Phase161CJson -Path (Join-Path $root 'reports/self_development/agent_body_map.json')
$graph = Read-Phase161CJson -Path (Join-Path $root 'reports/self_development/module_wiring_graph.json')
$functions = Read-Phase161CJson -Path (Join-Path $root 'reports/self_development/function_inventory.json')
$stubs = Read-Phase161CJson -Path (Join-Path $root 'reports/self_development/stub_placeholder_inventory.json')
$orphans = Read-Phase161CJson -Path (Join-Path $root 'reports/self_development/orphaned_artifact_inventory.json')
$gapChain = Read-Phase161CJson -Path (Join-Path $root 'reports/self_development/self_model_gap_chain.json')
$activeMap = Read-Phase161CJson -Path (Join-Path $root 'reports/self_development/SELF_MODEL_ACTIVE_MAP.json')
$safeRepair = Read-Phase161CJson -Path (Join-Path $root 'reports/self_development/safe_repair_candidates_from_body_map.json')
$unsafeDebt = Read-Phase161CJson -Path (Join-Path $root 'reports/self_development/unsafe_debt_backlog_from_body_map.json')

Add-Phase161CCheck -Checks $checks -Name 'map_role_derived' -Pass ($bodyMap.map_role -eq 'DERIVED_FROM_EXISTING' -and $activeMap.map_role -eq 'DERIVED_FROM_EXISTING') -Details 'Body map and active map are derived from existing organs.'
Add-Phase161CCheck -Checks $checks -Name 'artifact_items_present' -Pass (($bodyMap.artifacts | Measure-Object).Count -gt 0) -Details "artifact_count=$(($bodyMap.artifacts | Measure-Object).Count)"

$missingRequiredField = @($bodyMap.artifacts | Where-Object { -not (Test-Phase161CRequiredFields -Item $_) } | Select-Object -First 5)
Add-Phase161CCheck -Checks $checks -Name 'artifact_required_fields' -Pass ($missingRequiredField.Count -eq 0) -Details 'Every map item includes required PHASE161C fields.'

$missingWhy = @($bodyMap.artifacts | Where-Object { $_.primary_status -notlike 'ACTIVE_*' -and [string]::IsNullOrWhiteSpace($_.why_status) } | Select-Object -First 5)
Add-Phase161CCheck -Checks $checks -Name 'non_active_why_status' -Pass ($missingWhy.Count -eq 0) -Details 'Every non-active or uncertain item has why_status.'

$activeWithoutEvidence = @($bodyMap.artifacts | Where-Object { $_.primary_status -eq 'ACTIVE_WIRED_PROVEN' -and (($_.evidence_paths | Measure-Object).Count -eq 0) } | Select-Object -First 5)
Add-Phase161CCheck -Checks $checks -Name 'active_proven_has_evidence' -Pass ($activeWithoutEvidence.Count -eq 0) -Details 'Every ACTIVE_WIRED_PROVEN item has evidence paths.'

Add-Phase161CCheck -Checks $checks -Name 'graph_nodes_edges_present' -Pass ((($graph.nodes | Measure-Object).Count -gt 0) -and (($graph.edges | Measure-Object).Count -gt 0)) -Details "nodes=$(($graph.nodes | Measure-Object).Count); edges=$(($graph.edges | Measure-Object).Count)"
$badEdges = @($graph.edges | Where-Object {
  [string]::IsNullOrWhiteSpace($_.source) -or
  [string]::IsNullOrWhiteSpace($_.target) -or
  [string]::IsNullOrWhiteSpace($_.edge_type) -or
  [string]::IsNullOrWhiteSpace($_.confidence) -or
  [string]::IsNullOrWhiteSpace($_.evidence_snippet_or_pattern)
} | Select-Object -First 5)
Add-Phase161CCheck -Checks $checks -Name 'graph_edge_fields' -Pass ($badEdges.Count -eq 0) -Details 'Every graph edge has source, target, edge_type, confidence, and evidence pattern.'

Add-Phase161CCheck -Checks $checks -Name 'function_inventory_present' -Pass (($functions.items | Measure-Object).Count -gt 0) -Details "functions=$(($functions.items | Measure-Object).Count)"
$badFunctionItems = @($functions.items | Where-Object { [string]::IsNullOrWhiteSpace($_.parser_status) -or [string]::IsNullOrWhiteSpace($_.why_status) } | Select-Object -First 5)
Add-Phase161CCheck -Checks $checks -Name 'function_inventory_fields' -Pass ($badFunctionItems.Count -eq 0) -Details 'Function inventory entries include parser status and why_status.'

Add-Phase161CCheck -Checks $checks -Name 'stub_inventory_present' -Pass ($null -ne $stubs.items) -Details "stub_count=$(($stubs.items | Measure-Object).Count)"
Add-Phase161CCheck -Checks $checks -Name 'orphan_inventory_present' -Pass ($null -ne $orphans.items) -Details "orphan_count=$(($orphans.items | Measure-Object).Count)"
Add-Phase161CCheck -Checks $checks -Name 'gap_chain_present' -Pass ((($gapChain.gaps | Measure-Object).Count -ge 5) -and (($gapChain.gaps | Measure-Object).Count -le 15)) -Details "gaps=$(($gapChain.gaps | Measure-Object).Count)"
Add-Phase161CCheck -Checks $checks -Name 'safe_and_unsafe_backlogs_present' -Pass (($null -ne $safeRepair.candidates) -and ($null -ne $unsafeDebt.debt)) -Details 'Safe repair candidates and unsafe debt backlog are present.'

$protectedAfter = Get-Phase161CProtectedHashes -Root $root
$mutatedProtected = @()
foreach ($key in $protectedBefore.Keys) {
  if ($protectedBefore[$key] -ne $protectedAfter[$key]) {
    $mutatedProtected += $key
  }
}
Add-Phase161CCheck -Checks $checks -Name 'protected_state_clean' -Pass ($mutatedProtected.Count -eq 0) -Details "mutated=$($mutatedProtected -join ',')"

$runtimeStaged = (git -C $root status --short runtime_sessions | Out-String).Trim()
Add-Phase161CCheck -Checks $checks -Name 'runtime_outputs_not_staged' -Pass ([string]::IsNullOrWhiteSpace($runtimeStaged)) -Details "runtime_status=$runtimeStaged"

$docsPath = Join-Path $root 'docs/PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC.md'
Add-Phase161CCheck -Checks $checks -Name 'docs_present' -Pass (Test-Path -LiteralPath $docsPath) -Details 'PHASE161C docs exist.'

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
  checks = @($checks.ToArray())
  required_artifacts = $requiredArtifacts
  protected_hashes_before = $protectedBefore
  protected_hashes_after = $protectedAfter
  protected_state_mutated = $false
  runtime_outputs_staged = $false
  map_role = 'DERIVED_FROM_EXISTING'
  final_recommendation = 'READY_FOR_OWNER_REVIEW'
}

$proofPath = Join-Path $proofRoot 'PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_PROOF.json'
Write-Phase161CJson -Path $proofPath -Value $proof -Depth 20

$reportPath = Join-Path $outputRoot 'PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_REPORT.md'
$report = @(
  '# PHASE161C Agent Body Map Reuse And Self-Model Sync Report',
  '',
  'Result: `PASS`',
  '',
  "Branch: ``$branch``",
  "HEAD: ``$head``",
  '',
  'PHASE161C reused existing protected state, self-knowledge, self-model, body registry, capability shelf, route, proof, and report organs as inputs. It produced a derived active map under `reports/self_development` and did not mutate protected state.',
  '',
  "Artifacts scanned: $($builderResult.artifact_count)",
  "Graph nodes: $($builderResult.graph_node_count)",
  "Graph edges: $($builderResult.graph_edge_count)",
  "Function inventory entries: $($builderResult.function_inventory_count)",
  "Stub or placeholder entries: $($builderResult.stub_placeholder_count)",
  "Orphan candidates: $($builderResult.orphaned_candidate_count)",
  '',
  'Proof:',
  '',
  '- `proofs/self_development/PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_PROOF.json`',
  '',
  'Final recommendation: `READY_FOR_OWNER_REVIEW`'
)
$report | Set-Content -LiteralPath $reportPath -Encoding UTF8

$routePath = Join-Path $routeRoot 'PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_REQUEST.md'
$route = @(
  '# PHASE161C Route Change Request',
  '',
  'Request: accept the derived body map and self-model sync artifacts as PHASE161C review candidates.',
  '',
  'No protected state mutation is requested in this phase.',
  '',
  'Primary derived map:',
  '',
  '- `reports/self_development/SELF_MODEL_ACTIVE_MAP.json`',
  '',
  'Proof:',
  '',
  '- `proofs/self_development/PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_PROOF.json`'
)
$route | Set-Content -LiteralPath $routePath -Encoding UTF8

$deliveryPath = Join-Path $outputRoot 'PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_CODEX_DELIVERY.md'
$statusAfter = (git -C $root status --short | Out-String).Trim()
$delivery = @(
  '# PHASE161C Codex Delivery',
  '',
  'Root guard result: `PASS`',
  '',
  "PWD: ``$root``",
  "Branch: ``$branch``",
  "HEAD: ``$head``",
  "Remote: ``$remote``",
  '',
  'Changed files:',
  '```',
  $statusAfter,
  '```',
  '',
  'Parser check result: `PASS`',
  '',
  'Validator output: `PASS`',
  '',
  'Proof path: `proofs/self_development/PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_PROOF.json`',
  'Report path: `reports/self_development/PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_REPORT.md`',
  '',
  'Runtime dirs created: none',
  'Runtime was cleaned: not applicable',
  '',
  "Git status after validation:",
  '```',
  $statusAfter,
  '```',
  '',
  'Protected state mutated: `False`',
  'Runtime outputs staged: `False`',
  '',
  'Final recommendation: `READY_FOR_OWNER_REVIEW`'
)
$delivery | Set-Content -LiteralPath $deliveryPath -Encoding UTF8

Write-Host 'PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_VALIDATE_RESULT=PASS'
Write-Host 'ROOT_GUARD=PASS'
Write-Host 'PLAN_FIRST_GATE_PASS=True'
Write-Host 'EXISTING_MAP_DISCOVERY_CREATED=True'
Write-Host 'EXISTING_ORGANS_REUSED=True'
Write-Host 'DERIVED_ACTIVE_MAP_CREATED=True'
Write-Host 'MAP_ROLE=DERIVED_FROM_EXISTING'
Write-Host 'WHY_STATUS_PRESENT=True'
Write-Host 'MODULE_WIRING_GRAPH_CREATED=True'
Write-Host 'FUNCTION_INVENTORY_CREATED=True'
Write-Host 'STUB_PLACEHOLDER_INVENTORY_CREATED=True'
Write-Host 'ORPHANED_ARTIFACT_INVENTORY_CREATED=True'
Write-Host 'SELF_MODEL_GAP_CHAIN_CREATED=True'
Write-Host 'SAFE_REPAIR_CANDIDATES_CREATED=True'
Write-Host 'UNSAFE_DEBT_BACKLOG_CREATED=True'
Write-Host 'PROTECTED_STATE_MUTATED=False'
Write-Host 'RUNTIME_OUTPUTS_STAGED=False'
Write-Host 'NO_COMMIT_PERFORMED=True'
Write-Host 'NO_PUSH_PERFORMED=True'
Write-Host 'FINAL_RECOMMENDATION=READY_FOR_OWNER_REVIEW'
