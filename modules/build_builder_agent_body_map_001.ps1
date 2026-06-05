param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = 'reports/self_development',
  [switch]$Build
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function ConvertTo-BuilderRelativePath {
  param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$Path
  )
  $rootFull = [System.IO.Path]::GetFullPath($Root)
  $pathFull = [System.IO.Path]::GetFullPath($Path)
  return ([System.IO.Path]::GetRelativePath($rootFull, $pathFull) -replace '\\','/')
}

function Write-BuilderJsonFile {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)]$Value,
    [int]$Depth = 20
  )
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
  $Value | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-BuilderPhaseHint {
  param([string]$Text, [string]$Path)
  $combined = "$Path`n$Text"
  $matches = [regex]::Matches($combined, 'PHASE[0-9]+[A-Z0-9]*')
  if ($matches.Count -eq 0) { return $null }
  return ($matches | ForEach-Object { $_.Value } | Select-Object -Unique | Select-Object -First 1)
}

function Get-BuilderArtifactType {
  param([string]$RelativePath)
  if ($RelativePath -like 'modules/*.ps1') { return 'module' }
  if ($RelativePath -like 'validators/*.ps1') { return 'validator' }
  if ($RelativePath -like 'schemas/*' -or $RelativePath -like 'contracts/*') { return 'schema_or_contract' }
  if ($RelativePath -like 'reports/*') { return 'report' }
  if ($RelativePath -like 'proofs/*') { return 'proof' }
  if ($RelativePath -like 'route_locks/*') { return 'route_lock' }
  if ($RelativePath -like 'route_change_requests/*') { return 'route_change_request' }
  if ($RelativePath -like 'docs/*') { return 'doc' }
  if ($RelativePath -like 'packs/*') { return 'pack' }
  if ($RelativePath -like 'orchestrator/*') { return 'orchestrator' }
  if ($RelativePath -in @('CAPABILITY_ROADMAP.json','GENESIS_STATE.json','TASK_QUEUE.json')) { return 'protected_state' }
  if ($RelativePath -like 'self_knowledge/*' -or $RelativePath -like 'self_model/*') { return 'self_model_or_knowledge' }
  if ($RelativePath -like 'living_learning_environment/body/*') { return 'body_organ' }
  if ($RelativePath -like 'capability_shelf/*') { return 'capability_shelf' }
  return 'artifact'
}

function Get-BuilderParserInfo {
  param([string]$Path)
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errors) | Out-Null
  if ($errors -and $errors.Count -gt 0) {
    return [pscustomobject]@{
      parser_status = 'BROKEN_PARSE'
      errors = @($errors | ForEach-Object { $_.Message })
    }
  }
  return [pscustomobject]@{
    parser_status = 'PASS'
    errors = @()
  }
}

function Get-BuilderParamNames {
  param([string]$Text)
  $names = New-Object System.Collections.Generic.List[string]
  $paramMatches = [regex]::Matches($Text, '\$([A-Za-z_][A-Za-z0-9_]*)')
  foreach ($match in $paramMatches) {
    $value = $match.Groups[1].Value
    if ($value -notin @('true','false','null','ErrorActionPreference','PSScriptRoot','PWD')) {
      $names.Add($value)
    }
  }
  return @($names | Select-Object -Unique | Select-Object -First 40)
}

function Get-BuilderSafetyOperations {
  param([string]$Text)
  $signals = New-Object System.Collections.Generic.List[string]
  $patterns = [ordered]@{
    git_commit = 'git\s+commit'
    git_push = 'git\s+push'
    branch_switch = 'git\s+(switch|checkout)\b'
    remove_item = 'Remove-Item'
    protected_state_write = 'Set-Content.+(TASK_QUEUE|GENESIS_STATE|CAPABILITY_ROADMAP|packs/registry|orchestrator/run)'
    runtime_writes = 'runtime_sessions'
    accepted_repo_writes = '(Set-Content|Add-Content|New-Item|Copy-Item|Move-Item)'
  }
  foreach ($key in $patterns.Keys) {
    if ([regex]::IsMatch($Text, $patterns[$key], 'IgnoreCase')) {
      $signals.Add($key)
    }
  }
  return @($signals | Select-Object -Unique)
}

function Get-BuilderWriteOutputs {
  param([string]$Text)
  $outputs = New-Object System.Collections.Generic.List[string]
  foreach ($match in [regex]::Matches($Text, '(Set-Content|Out-File|Export-Clixml|ConvertTo-Json|New-Item).{0,120}')) {
    $outputs.Add(($match.Value -replace '\s+', ' ').Trim())
  }
  return @($outputs | Select-Object -Unique | Select-Object -First 20)
}

function Get-BuilderScopedFiles {
  param([string]$Root)
  $scopePaths = @(
    'modules',
    'validators',
    'schemas',
    'contracts',
    'reports',
    'proofs',
    'route_locks',
    'route_change_requests',
    'docs',
    'packs',
    'orchestrator',
    'self_knowledge',
    'self_model',
    'living_learning_environment/body',
    'capability_shelf',
    'self_build_backlog'
  )
  $files = New-Object System.Collections.Generic.List[object]
  foreach ($scope in $scopePaths) {
    $full = Join-Path $Root $scope
    if (Test-Path -LiteralPath $full) {
      Get-ChildItem -LiteralPath $full -Recurse -File | ForEach-Object { $files.Add($_) }
    }
  }
  foreach ($rootFile in @('CAPABILITY_ROADMAP.json','GENESIS_STATE.json','TASK_QUEUE.json','packs/registry.json')) {
    $full = Join-Path $Root $rootFile
    if (Test-Path -LiteralPath $full) {
      $files.Add((Get-Item -LiteralPath $full))
    }
  }
  return @($files | Sort-Object FullName -Unique)
}

function New-BuilderArtifactClassification {
  param(
    [Parameter(Mandatory=$true)]$FileRecord,
    [Parameter(Mandatory=$true)][string]$RelativePath,
    [string]$Text,
    [hashtable]$ReferenceIndex,
    [string[]]$Validators,
    [string[]]$Reports,
    [string[]]$Proofs,
    [string[]]$RouteRefs,
    [string[]]$Schemas,
    [string[]]$Callees,
    [string[]]$Callers,
    [string]$ParserStatus = $null
  )

  $artifactType = Get-BuilderArtifactType -RelativePath $RelativePath
  $phaseHint = Get-BuilderPhaseHint -Text $Text -Path $RelativePath
  $isProtected = $RelativePath -in @('CAPABILITY_ROADMAP.json','GENESIS_STATE.json','TASK_QUEUE.json','packs/registry.json','orchestrator/run.ps1')
  $hasStubSignal = [regex]::IsMatch($Text, '(TODO|FIXME|STUB|placeholder|not implemented)', 'IgnoreCase')
  $nearEmpty = ($FileRecord.Length -lt 32)
  $hasProof = $Proofs.Count -gt 0 -or $artifactType -eq 'proof'
  $hasValidator = $Validators.Count -gt 0 -or $artifactType -eq 'validator'
  $hasWiring = $Callers.Count -gt 0 -or $Callees.Count -gt 0 -or $RouteRefs.Count -gt 0

  $primary = 'UNKNOWN_NEEDS_REVIEW'
  $why = 'Status is uncertain because no stronger wiring, proof, validator, or source-of-truth signal was detected.'
  $safeToModify = -not $isProtected
  $ownerApproval = $isProtected
  $next = 'Review manually and connect to validator or route evidence before relying on it.'

  if ($ParserStatus -eq 'BROKEN_PARSE') {
    $primary = 'BROKEN_PARSE'
    $why = 'PowerShell parser reported errors, so the artifact cannot be considered wired or proven.'
    $next = 'Repair parse errors before classification upgrade.'
  } elseif ($isProtected) {
    $primary = 'RISK_LOCKED'
    $why = 'Artifact is protected source-of-truth or protected execution surface and is read-only for PHASE161C.'
    $next = 'Read only; create update candidate under reports/self_development if a state change is needed.'
  } elseif ($nearEmpty) {
    $primary = 'EMPTY_OR_NEAR_EMPTY'
    $why = 'File is too small to provide meaningful behavior or evidence.'
    $next = 'Inspect before use; do not delete without owner approval.'
  } elseif ($hasStubSignal) {
    $primary = 'STUB_OR_PLACEHOLDER'
    $why = 'TODO/FIXME/STUB/placeholder/not implemented marker detected.'
    $next = 'Repair only under a bounded task with validator coverage.'
  } elseif ($artifactType -eq 'validator' -and -not $hasProof) {
    $primary = 'VALIDATOR_NO_PROOF'
    $why = 'Validator exists but no matching proof artifact was detected.'
    $next = 'Run validator and write proof before relying on it.'
  } elseif ($artifactType -eq 'proof' -and -not [regex]::IsMatch($Text, 'runtime_sessions|live|RUNTIME|LIVE', 'IgnoreCase')) {
    $primary = 'PROOF_NO_LIVE_EVIDENCE'
    $why = 'Proof exists, but no live or runtime evidence marker was detected.'
    $next = 'Treat as validator proof unless live evidence is added.'
  } elseif ($hasWiring -and $hasProof) {
    $primary = 'ACTIVE_WIRED_PROVEN'
    $why = 'Artifact has wiring/reference evidence and proof evidence.'
    $next = 'Keep; use as active evidence input.'
  } elseif ($hasWiring -and $hasValidator -and -not $hasProof) {
    $primary = 'PRESENT_WIRED_TO_VALIDATOR_ONLY'
    $why = 'Artifact has wiring and validator references but no matching proof path.'
    $next = 'Run or add proof before promoting to active proven.'
  } elseif (-not $hasWiring) {
    $primary = 'PRESENT_NOT_WIRED'
    $why = 'No caller, callee, route, validator, report, or proof reference was detected by PHASE161C scanning.'
    $next = 'Keep as present artifact; connect or classify historically before reuse.'
  } else {
    $primary = 'ACTIVE_WIRED_UNPROVEN'
    $why = 'Artifact has wiring/reference evidence but no proof evidence.'
    $next = 'Add proof or validator evidence before marking proven.'
  }

  return [pscustomobject]@{
    artifact_id = ($RelativePath -replace '[^A-Za-z0-9]+','_').Trim('_')
    path = $RelativePath
    artifact_type = $artifactType
    phase_hint = $phaseHint
    role_guess = $artifactType
    primary_status = $primary
    why_status = $why
    evidence_paths = @($Proofs + $Reports + $RouteRefs | Select-Object -Unique)
    callers = @($Callers | Select-Object -Unique)
    callees = @($Callees | Select-Object -Unique)
    validators = @($Validators | Select-Object -Unique)
    reports = @($Reports | Select-Object -Unique)
    proofs = @($Proofs | Select-Object -Unique)
    schemas = @($Schemas | Select-Object -Unique)
    route_lock_references = @($RouteRefs | Select-Object -Unique)
    last_known_phase = $phaseHint
    safe_to_modify = $safeToModify
    owner_approval_required = $ownerApproval
    missing_link_reason = $(if ($primary -eq 'PRESENT_NOT_WIRED') { 'No references found in scanned modules, validators, reports, proofs, docs, route locks, packs, or orchestrator files.' } else { $null })
    placeholder_reason = $(if ($primary -eq 'STUB_OR_PLACEHOLDER') { 'Placeholder marker detected in artifact text.' } else { $null })
    recommended_next_action = $next
  }
}

function Invoke-BuilderAgentBodyMap001 {
  param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$OutputRoot = 'reports/self_development'
  )

  $root = (Resolve-Path $RepoRoot).Path
  $outputFull = Join-Path $root $OutputRoot
  if (-not (Test-Path -LiteralPath $outputFull)) {
    New-Item -ItemType Directory -Path $outputFull | Out-Null
  }

  $files = Get-BuilderScopedFiles -Root $root
  $textByPath = @{}
  foreach ($file in $files) {
    $rel = ConvertTo-BuilderRelativePath -Root $root -Path $file.FullName
    try {
      $textByPath[$rel] = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop
    } catch {
      $textByPath[$rel] = ''
    }
  }

  $modulePaths = @($textByPath.Keys | Where-Object { $_ -like 'modules/*.ps1' } | Sort-Object)
  $validatorPaths = @($textByPath.Keys | Where-Object { $_ -like 'validators/*.ps1' } | Sort-Object)
  $schemaPaths = @($textByPath.Keys | Where-Object { $_ -like 'schemas/*' -or $_ -like 'contracts/*' } | Sort-Object)
  $reportPaths = @($textByPath.Keys | Where-Object { $_ -like 'reports/*' } | Sort-Object)
  $proofPaths = @($textByPath.Keys | Where-Object { $_ -like 'proofs/*' } | Sort-Object)
  $routePaths = @($textByPath.Keys | Where-Object { $_ -like 'route_locks/*' -or $_ -like 'route_change_requests/*' } | Sort-Object)

  $nodes = New-Object System.Collections.Generic.List[object]
  $edges = New-Object System.Collections.Generic.List[object]
  foreach ($rel in ($textByPath.Keys | Sort-Object)) {
    $nodes.Add([pscustomobject]@{
      id = $rel
      path = $rel
      node_type = Get-BuilderArtifactType -RelativePath $rel
    })
  }

  $calleeBySource = @{}
  $callerByTarget = @{}
  foreach ($source in ($textByPath.Keys | Sort-Object)) {
    $sourceText = $textByPath[$source]
    $sourceBase = [System.IO.Path]::GetFileNameWithoutExtension($source)
    foreach ($target in $modulePaths) {
      if ($source -eq $target) { continue }
      $targetBase = [System.IO.Path]::GetFileNameWithoutExtension($target)
      if ($sourceText -match [regex]::Escape($targetBase)) {
        if (-not $calleeBySource.ContainsKey($source)) { $calleeBySource[$source] = New-Object System.Collections.Generic.List[string] }
        if (-not $callerByTarget.ContainsKey($target)) { $callerByTarget[$target] = New-Object System.Collections.Generic.List[string] }
        $calleeBySource[$source].Add($target)
        $callerByTarget[$target].Add($source)
        $edges.Add([pscustomobject]@{
          source = $source
          target = $target
          edge_type = 'calls'
          confidence = 'medium'
          evidence_snippet_or_pattern = $targetBase
        })
      }
    }
    foreach ($target in @('CAPABILITY_ROADMAP.json','GENESIS_STATE.json','TASK_QUEUE.json','packs/registry.json','orchestrator/run.ps1','route_locks/ACTIVE_ROUTE_LOCK.json')) {
      if ($sourceText -match [regex]::Escape($target)) {
        $edges.Add([pscustomobject]@{
          source = $source
          target = $target
          edge_type = 'references'
          confidence = 'high'
          evidence_snippet_or_pattern = $target
        })
      }
    }
    foreach ($schema in $schemaPaths) {
      $schemaBase = [System.IO.Path]::GetFileName($schema)
      if ($sourceText -match [regex]::Escape($schemaBase)) {
        $edges.Add([pscustomobject]@{
          source = $source
          target = $schema
          edge_type = 'validates'
          confidence = 'medium'
          evidence_snippet_or_pattern = $schemaBase
        })
      }
    }
  }

  $artifactItems = New-Object System.Collections.Generic.List[object]
  $functionInventory = New-Object System.Collections.Generic.List[object]
  foreach ($file in $files) {
    $rel = ConvertTo-BuilderRelativePath -Root $root -Path $file.FullName
    $text = $textByPath[$rel]
    $parserStatus = $null
    $parserErrors = @()
    $functions = @()
    $paramNames = @()
    $writeOutputs = @()
    $calls = @()
    $safetyOps = @()
    if ($rel -like '*.ps1') {
      $parser = Get-BuilderParserInfo -Path $file.FullName
      $parserStatus = $parser.parser_status
      $parserErrors = @($parser.errors)
      $functions = @([regex]::Matches($text, 'function\s+([A-Za-z0-9_\-]+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
      $paramNames = @(Get-BuilderParamNames -Text $text)
      $writeOutputs = @(Get-BuilderWriteOutputs -Text $text)
      $calls = @($calleeBySource[$rel] | Select-Object -Unique)
      $safetyOps = @(Get-BuilderSafetyOperations -Text $text)
      $functionInventory.Add([pscustomobject]@{
        path = $rel
        parser_status = $parserStatus
        parser_errors = $parserErrors
        functions_found = $functions
        param_names = $paramNames
        exported_behavior_guess = $(if ($functions.Count -gt 0) { ($functions -join ', ') } else { 'script_or_inline_behavior' })
        write_outputs_detected = $writeOutputs
        calls_detected = $calls
        safety_sensitive_operations_detected = $safetyOps
        why_status = $(if ($parserStatus -eq 'PASS') { 'Parser passed; behavior classification is based on static scan signals.' } else { 'Parser failed; repair required before reliable behavior classification.' })
      })
    }

    $phase = Get-BuilderPhaseHint -Text $text -Path $rel
    $validators = @($validatorPaths | Where-Object {
      $vText = $textByPath[$_]
      ($vText -match [regex]::Escape($rel)) -or ($phase -and $vText -match [regex]::Escape($phase))
    } | Select-Object -Unique)
    $reports = @($reportPaths | Where-Object {
      $rText = $textByPath[$_]
      ($rText -match [regex]::Escape($rel)) -or ($phase -and ($_ -match [regex]::Escape($phase) -or $rText -match [regex]::Escape($phase)))
    } | Select-Object -Unique | Select-Object -First 25)
    $proofs = @($proofPaths | Where-Object {
      $pText = $textByPath[$_]
      ($pText -match [regex]::Escape($rel)) -or ($phase -and ($_ -match [regex]::Escape($phase) -or $pText -match [regex]::Escape($phase)))
    } | Select-Object -Unique | Select-Object -First 25)
    $routeRefs = @($routePaths | Where-Object {
      $routeText = $textByPath[$_]
      ($routeText -match [regex]::Escape($rel)) -or ($phase -and $routeText -match [regex]::Escape($phase))
    } | Select-Object -Unique)
    $schemas = @($schemaPaths | Where-Object {
      $schemaText = $textByPath[$_]
      ($text -match [regex]::Escape([System.IO.Path]::GetFileName($_))) -or ($schemaText -match [regex]::Escape($rel))
    } | Select-Object -Unique)

    $item = New-BuilderArtifactClassification -FileRecord $file -RelativePath $rel -Text $text -ReferenceIndex @{} -Validators $validators -Reports $reports -Proofs $proofs -RouteRefs $routeRefs -Schemas $schemas -Callees @($calleeBySource[$rel]) -Callers @($callerByTarget[$rel]) -ParserStatus $parserStatus
    $artifactItems.Add($item)
  }

  $stubItems = @($artifactItems | Where-Object { $_.primary_status -in @('STUB_OR_PLACEHOLDER','EMPTY_OR_NEAR_EMPTY') } | ForEach-Object {
    [pscustomobject]@{
      path = $_.path
      artifact_type = $_.artifact_type
      stub_signal = $(if ($_.primary_status -eq 'EMPTY_OR_NEAR_EMPTY') { 'low_size_file' } else { 'placeholder_marker' })
      severity = $(if ($_.primary_status -eq 'EMPTY_OR_NEAR_EMPTY') { 'medium' } else { 'high' })
      why_status = $_.why_status
      safe_repair_possible = $_.safe_to_modify
      recommended_action = $_.recommended_next_action
    }
  })

  $orphanItems = @($artifactItems | Where-Object { $_.primary_status -eq 'PRESENT_NOT_WIRED' -and $_.artifact_type -notin @('protected_state','route_lock') } | Select-Object -First 250 | ForEach-Object {
    [pscustomobject]@{
      path = $_.path
      why_orphaned = $_.missing_link_reason
      possible_role = $_.role_guess
      safe_to_delete_now = $false
      recommended_action = 'Do not delete in PHASE161C. Review historical purpose or wire to validator/proof before use.'
    }
  })

  $gapChain = @(
    [pscustomobject]@{
      gap_id = 'GAP_PROTECTED_STATE_PROMOTION_BLOCKED'
      why_status = 'Protected state files are source-of-truth but read-only in PHASE161C, so the active self-model must remain derived until owner approves promotion.'
      blocking_dependency_chain = @('CAPABILITY_ROADMAP.json read-only', 'GENESIS_STATE.json read-only', 'TASK_QUEUE.json read-only', 'packs/registry.json read-only', 'owner approval required')
      recommended_next_action = 'Review derived SELF_MODEL_ACTIVE_MAP.json and approve a later protected-state update candidate if desired.'
      safe_to_repair_now = $false
    },
    [pscustomobject]@{
      gap_id = 'GAP_SPLIT_SELF_MODEL_ORGANS'
      why_status = 'Self-model, self-knowledge, body registry, and capability shelf exist in separate places and were not one current body map.'
      blocking_dependency_chain = @('self_knowledge artifacts', 'self_model artifacts', 'body registry', 'capability shelf', 'derived map synthesis')
      recommended_next_action = 'Use PHASE161C derived map as synchronization layer.'
      safe_to_repair_now = $true
    },
    [pscustomobject]@{
      gap_id = 'GAP_VALIDATOR_ONLY_EVIDENCE'
      why_status = 'Some artifacts have validator or report references but no live/runtime proof marker, so they cannot be called live-proven.'
      blocking_dependency_chain = @('validator evidence', 'proof evidence', 'live runtime evidence')
      recommended_next_action = 'Separate validator-proven from live-proven in future acceptance tasks.'
      safe_to_repair_now = $true
    },
    [pscustomobject]@{
      gap_id = 'GAP_ORPHANED_PRESENT_ARTIFACTS'
      why_status = 'Static scan found present artifacts with no detected caller, route, validator, report, or proof reference.'
      blocking_dependency_chain = @('reference discovery', 'historical classification', 'owner-approved repair or archival plan')
      recommended_next_action = 'Classify orphans before any cleanup; do not delete in PHASE161C.'
      safe_to_repair_now = $false
    },
    [pscustomobject]@{
      gap_id = 'GAP_STUB_PLACEHOLDER_ARTIFACTS'
      why_status = 'Placeholder or near-empty artifacts exist and should not be mistaken for active organs.'
      blocking_dependency_chain = @('stub detection', 'bounded repair task', 'validator proof')
      recommended_next_action = 'Repair only when tied to a specific accepted route.'
      safe_to_repair_now = $false
    },
    [pscustomobject]@{
      gap_id = 'GAP_SAFETY_SENSITIVE_OPERATIONS_REQUIRE_REVIEW'
      why_status = 'Some scripts contain git, deletion, runtime-write, or protected-write signals; they need explicit safety review before reuse.'
      blocking_dependency_chain = @('operation detection', 'safety classification', 'owner approval for risky actions')
      recommended_next_action = 'Keep risky candidates in unsafe debt backlog.'
      safe_to_repair_now = $false
    }
  )

  $safeRepair = @($artifactItems | Where-Object { $_.safe_to_modify -and $_.primary_status -in @('PRESENT_WIRED_TO_VALIDATOR_ONLY','ACTIVE_WIRED_UNPROVEN','VALIDATOR_NO_PROOF') } | Select-Object -First 100 | ForEach-Object {
    [pscustomobject]@{
      path = $_.path
      current_status = $_.primary_status
      why_status = $_.why_status
      recommended_action = $_.recommended_next_action
    }
  })

  $unsafeDebt = @($artifactItems | Where-Object { $_.owner_approval_required -or $_.primary_status -in @('RISK_LOCKED','BROKEN_PARSE','STUB_OR_PLACEHOLDER') } | Select-Object -First 100 | ForEach-Object {
    [pscustomobject]@{
      path = $_.path
      current_status = $_.primary_status
      why_status = $_.why_status
      owner_approval_required = $_.owner_approval_required
      recommended_action = $_.recommended_next_action
    }
  })

  foreach ($edge in $edges) {
    if (($nodes | Where-Object { $_.id -eq $edge.target }).Count -eq 0) {
      $nodes.Add([pscustomobject]@{
        id = $edge.target
        path = $edge.target
        node_type = Get-BuilderArtifactType -RelativePath $edge.target
      })
    }
  }

  $artifactArray = @($artifactItems.ToArray())
  $nodeArray = @($nodes.ToArray())
  $edgeArray = @($edges.ToArray())
  $functionInventoryArray = @($functionInventory.ToArray())

  $map = [pscustomobject][ordered]@{
    phase = 'PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_V1'
    map_role = 'DERIVED_FROM_EXISTING'
    source_of_truth_status = 'DERIVED_ACTIVE_MAP_CANDIDATE'
    why_status = 'Derived from existing protected state, self-knowledge, self-model, body registry, capability shelf, route locks, modules, validators, reports, proofs, docs, packs, and orchestrator files. It is not a protected-state replacement.'
    generated_at = (Get-Date).ToUniversalTime().ToString('o')
    source_inputs = @(
      'CAPABILITY_ROADMAP.json',
      'GENESIS_STATE.json',
      'TASK_QUEUE.json',
      'packs/registry.json',
      'route_locks/ACTIVE_ROUTE_LOCK.json',
      'self_knowledge/',
      'self_model/',
      'living_learning_environment/body/',
      'capability_shelf/'
    )
    artifact_count = $artifactItems.Count
    artifacts = $artifactArray
  }

  $graph = [pscustomobject][ordered]@{
    phase = 'PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_V1'
    graph_role = 'MODULE_WIRING_GRAPH'
    why_status = 'Static graph derived from function/module name references, protected-state references, schema filename references, phase references, and discovered proof/report links.'
    nodes = $nodeArray
    edges = @($edgeArray | Select-Object -First 2000)
  }

  $activeMap = [pscustomobject][ordered]@{
    phase = 'PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_V1'
    map_role = 'DERIVED_FROM_EXISTING'
    source_of_truth_status = 'DERIVED_ACTIVE_MAP_CANDIDATE'
    why_status = 'This file is the PHASE161C derived active map candidate. It reuses existing organs and avoids direct protected-state mutation.'
    existing_organs_reused = @(
      'self_knowledge/BUILDER_SELF_MODEL.json',
      'self_model/BUILDER_SELF_MODEL.json',
      'self_knowledge/MODULE_INVENTORY.json',
      'living_learning_environment/body/body_registry.json',
      'living_learning_environment/body/BUILDER_BODY_ORGAN_PACK_V1.json',
      'capability_shelf/registry.json',
      'CAPABILITY_ROADMAP.json',
      'packs/registry.json',
      'route_locks/ACTIVE_ROUTE_LOCK.json'
    )
    protected_state_mutation_allowed = $false
    accepted_repo_mutation_allowed_by_runtime = $false
    active_artifacts = @($artifactArray | Where-Object { $_.primary_status -like 'ACTIVE_*' } | Select-Object -First 200)
    important_gaps = $gapChain
  }

  $runtimeDirNames = @()
  $runtimeRoot = Join-Path $root 'runtime_sessions'
  if (Test-Path -LiteralPath $runtimeRoot) {
    $runtimeDirNames = @(Get-ChildItem -LiteralPath $runtimeRoot -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
  }

  Write-BuilderJsonFile -Path (Join-Path $outputFull 'agent_body_map.json') -Value $map
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'module_wiring_graph.json') -Value $graph
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'function_inventory.json') -Value ([pscustomobject]@{ phase = $map.phase; items = $functionInventoryArray })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'stub_placeholder_inventory.json') -Value ([pscustomobject]@{ phase = $map.phase; items = @($stubItems) })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'orphaned_artifact_inventory.json') -Value ([pscustomobject]@{ phase = $map.phase; items = @($orphanItems) })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'self_model_gap_chain.json') -Value ([pscustomobject]@{ phase = $map.phase; gaps = $gapChain })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'SELF_MODEL_ACTIVE_MAP.json') -Value $activeMap
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'safe_repair_candidates_from_body_map.json') -Value ([pscustomobject]@{ phase = $map.phase; candidates = @($safeRepair) })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'unsafe_debt_backlog_from_body_map.json') -Value ([pscustomobject]@{ phase = $map.phase; debt = @($unsafeDebt) })

  $md = @(
    '# Agent Body Map',
    '',
    'Status: `DERIVED_FROM_EXISTING`',
    '',
    'This PHASE161C map reuses existing protected state, self-knowledge, self-model, body registry, capability shelf, route locks, modules, validators, reports, proofs, docs, packs, and orchestrator files. It is a derived active-map candidate, not a replacement for protected source-of-truth state.',
    '',
    "Artifacts scanned: $($artifactItems.Count)",
    "Graph nodes: $($nodes.Count)",
    "Graph edges: $($edges.Count)",
    "Function inventory entries: $($functionInventory.Count)",
    "Stub or placeholder entries: $($stubItems.Count)",
    "Orphan candidates: $($orphanItems.Count)",
    '',
    '## Important Gaps',
    ''
  )
  foreach ($gap in $gapChain) {
    $md += "- `$($gap.gap_id)`: $($gap.why_status)"
  }
  $md | Set-Content -LiteralPath (Join-Path $outputFull 'agent_body_map.md') -Encoding UTF8

  $updateReport = @(
    '# Agent Body Map Update Report',
    '',
    'PHASE161C produced a derived active map under `reports/self_development`.',
    '',
    'Protected state was read but not modified.',
    '',
    "Runtime directory names observed: $($runtimeDirNames -join ', ')",
    '',
    'Generated artifacts:',
    '',
    '- `agent_body_map.json`',
    '- `agent_body_map.md`',
    '- `module_wiring_graph.json`',
    '- `function_inventory.json`',
    '- `stub_placeholder_inventory.json`',
    '- `orphaned_artifact_inventory.json`',
    '- `self_model_gap_chain.json`',
    '- `SELF_MODEL_ACTIVE_MAP.json`',
    '- `safe_repair_candidates_from_body_map.json`',
    '- `unsafe_debt_backlog_from_body_map.json`'
  )
  $updateReport | Set-Content -LiteralPath (Join-Path $outputFull 'agent_body_map_update_report.md') -Encoding UTF8

  return [pscustomobject]@{
    result = 'PASS'
    output_root = ConvertTo-BuilderRelativePath -Root $root -Path $outputFull
    artifact_count = $artifactItems.Count
    graph_node_count = $nodes.Count
    graph_edge_count = $edges.Count
    function_inventory_count = $functionInventory.Count
    stub_placeholder_count = $stubItems.Count
    orphaned_candidate_count = $orphanItems.Count
    protected_state_mutation_allowed = $false
    map_role = 'DERIVED_FROM_EXISTING'
  }
}

if ($Build) {
  Invoke-BuilderAgentBodyMap001 -RepoRoot $RepoRoot -OutputRoot $OutputRoot | ConvertTo-Json -Depth 8
}
