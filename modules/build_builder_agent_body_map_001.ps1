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
  $separator = [System.IO.Path]::DirectorySeparatorChar
  if (-not $rootFull.EndsWith([string]$separator)) {
    $rootFull += $separator
  }
  $rootUri = New-Object System.Uri($rootFull)
  $pathUri = New-Object System.Uri($pathFull)
  if ($rootUri.Scheme -ne $pathUri.Scheme) {
    return ($pathFull -replace '\\','/')
  }
  return ([System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString()) -replace '\\','/')
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

function Set-BuilderObjectProperty {
  param(
    [Parameter(Mandatory=$true)]$Object,
    [Parameter(Mandatory=$true)][string]$Name,
    $Value
  )
  if ($Object.PSObject.Properties.Name -contains $Name) {
    $Object.$Name = $Value
  } else {
    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
  }
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
  if ($RelativePath -like 'operations/*' -and ($RelativePath -match '(route|replay|ledger|active_store|ready_lane|policy|guard|pointer)')) { return 'routing_surface' }
  if ($RelativePath -like 'operations/*') { return 'operation_surface' }
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

function Get-BuilderRouteLockContext {
  param([string]$Root)
  $activeRouteLockFile = $null
  $activeRouteLockText = ''
  $supersededPaths = @()
  $archivedPaths = @()
  $activeRouteLockJson = Join-Path $Root 'route_locks/ACTIVE_ROUTE_LOCK.json'
  if (-not (Test-Path -LiteralPath $activeRouteLockJson)) {
    return [pscustomobject]@{
      active_route_lock_file = $activeRouteLockFile
      active_route_lock_text = $activeRouteLockText
      superseded_paths = @()
      archived_paths = @()
    }
  }
  try {
    $routeJson = Get-Content -LiteralPath $activeRouteLockJson -Raw | ConvertFrom-Json
    $activeRouteLockFile = $routeJson.active_route_lock_file
    $supersededItems = @()
    if ($routeJson.PSObject.Properties.Name -contains 'superseded_route_locks') {
      $supersededItems = @($routeJson.superseded_route_locks)
    }
    foreach ($item in $supersededItems) {
      if ($item.file) {
        $supersededPaths += (($item.file -replace '\\','/'))
        if ($item.file -notlike 'route_locks/*') {
          $supersededPaths += (('route_locks/' + $item.file) -replace '\\','/')
        }
      }
    }
    $archivedItems = @()
    if ($routeJson.PSObject.Properties.Name -contains 'archived_reference_locks') {
      $archivedItems = @($routeJson.archived_reference_locks)
    }
    foreach ($item in $archivedItems) {
      if ($item.file) {
        $archivedPaths += (($item.file -replace '\\','/'))
      }
    }
    if ($activeRouteLockFile) {
      $activeRoutePath = Join-Path $Root $activeRouteLockFile
      if (Test-Path -LiteralPath $activeRoutePath) {
        $activeRouteLockText = Get-Content -LiteralPath $activeRoutePath -Raw
        foreach ($match in [regex]::Matches($activeRouteLockText, '(?m)^-\s+(.+)$')) {
          $value = $match.Groups[1].Value.Trim()
          if ($value -match 'AGENT_BUILDER_NEXT_15_STEPS_LOCK') {
            $supersededPaths += (($value -replace '\\','/'))
            if ($value -notlike 'route_locks/*') {
              $supersededPaths += (('route_locks/' + $value) -replace '\\','/')
            }
          }
        }
      }
    }
  } catch {
    return [pscustomobject]@{
      active_route_lock_file = $activeRouteLockFile
      active_route_lock_text = $activeRouteLockText
      superseded_paths = @($supersededPaths | Select-Object -Unique)
      archived_paths = @($archivedPaths | Select-Object -Unique)
    }
  }
  return [pscustomobject]@{
    active_route_lock_file = $activeRouteLockFile
    active_route_lock_text = $activeRouteLockText
    superseded_paths = @($supersededPaths | Select-Object -Unique)
    archived_paths = @($archivedPaths | Select-Object -Unique)
  }
}

function Test-BuilderRealStubSignal {
  param(
    [string]$Text,
    [string]$ArtifactType,
    [int64]$Length
  )
  if ($Length -lt 32) { return $true }
  if ([regex]::IsMatch($Text, 'throw\s+["'']?not implemented|NotImplementedException|TODO:\s*implement|FIXME:\s*implement', 'IgnoreCase')) { return $true }
  if ([regex]::IsMatch($Text, '(?m)^\s*#?\s*(STUB|TODO|FIXME)\b', 'IgnoreCase') -and $ArtifactType -in @('module','validator','schema_or_contract')) { return $true }
  if ($ArtifactType -eq 'validator' -and [regex]::IsMatch($Text, 'Write-Host\s+["''].*PASS', 'IgnoreCase') -and -not [regex]::IsMatch($Text, 'ParseFile|ConvertFrom-Json|Test-Path|Get-FileHash|throw|exit\s+1', 'IgnoreCase')) { return $true }
  return $false
}

function Test-BuilderFalsePositiveStubSignal {
  param(
    [string]$Text,
    [string]$ArtifactType,
    [int64]$Length
  )
  if (-not [regex]::IsMatch($Text, '(TODO|FIXME|STUB|placeholder|not implemented)', 'IgnoreCase')) { return $false }
  if (Test-BuilderRealStubSignal -Text $Text -ArtifactType $ArtifactType -Length $Length) { return $false }
  if ($ArtifactType -in @('doc','report','proof') -or $Length -gt 512) { return $true }
  return $true
}

function Get-BuilderPhaseNumber {
  param([string]$PhaseHint, [string]$Path)
  $combined = "$Path $PhaseHint"
  $match = [regex]::Match($combined, 'PHASE([0-9]+)')
  if (-not $match.Success) { return $null }
  return [int]$match.Groups[1].Value
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
    'operations',
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
      Get-ChildItem -LiteralPath $full -Recurse -File | ForEach-Object {
        $relCandidate = ConvertTo-BuilderRelativePath -Root $Root -Path $_.FullName
        $relCandidate = $relCandidate.Replace('\','/')
        if ($relCandidate -like 'operations/*') {
          $ext = [System.IO.Path]::GetExtension($_.Name).ToLowerInvariant()
          $isBulkExtension = $ext -in @('.jsonl','.before','.snapshot')
          $isBulkPath = $relCandidate -match '(^|/)archive/|(^|/)rollback/|(^|/)memory/|(^|/)store/|^operations/reports/(streaming_absorption|codex_curriculum_quarantine)/|ready_atoms|compact_atom_index|factory_ledger|coverage_map|prerequisite_graph|theme_cursor_ledger|duplicate_key_hash_index|topic_hash_index'
          $isLargeRawDump = ($_.Length -gt 200000 -and $ext -notin @('.ps1','.md'))
          if ($isBulkExtension -or $isBulkPath -or $isLargeRawDump) { return }
        }
        $files.Add($_)
      }
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
    [object]$RouteContext,
    [string]$ParserStatus = $null
  )

  $artifactType = Get-BuilderArtifactType -RelativePath $RelativePath
  $phaseHint = Get-BuilderPhaseHint -Text $Text -Path $RelativePath
  $phaseNumber = Get-BuilderPhaseNumber -PhaseHint $phaseHint -Path $RelativePath
  $isProtected = $RelativePath -in @('CAPABILITY_ROADMAP.json','GENESIS_STATE.json','TASK_QUEUE.json','packs/registry.json','orchestrator/run.ps1')
  $hasStubSignal = [regex]::IsMatch($Text, '(TODO|FIXME|STUB|placeholder|not implemented)', 'IgnoreCase')
  $realStubSignal = Test-BuilderRealStubSignal -Text $Text -ArtifactType $artifactType -Length $FileRecord.Length
  $falsePositiveStubSignal = Test-BuilderFalsePositiveStubSignal -Text $Text -ArtifactType $artifactType -Length $FileRecord.Length
  $nearEmpty = ($FileRecord.Length -lt 32)
  $hasProof = $Proofs.Count -gt 0 -or $artifactType -eq 'proof'
  $hasValidator = $Validators.Count -gt 0 -or $artifactType -eq 'validator'
  $currentCodeCallers = @($Callers | Where-Object { $_ -like 'modules/*.ps1' -or $_ -like 'validators/*.ps1' -or $_ -like 'orchestrator/*.ps1' } | Select-Object -Unique)
  $activeRouteFile = $RouteContext.active_route_lock_file
  $currentRouteRefs = @($RouteRefs | Where-Object { $_ -eq 'route_locks/ACTIVE_ROUTE_LOCK.json' -or ($activeRouteFile -and $_ -eq $activeRouteFile) } | Select-Object -Unique)
  $supersededPaths = @($RouteContext.superseded_paths)
  $isSupersededByRouteLock = ($RelativePath -in $supersededPaths) -or (($supersededPaths | ForEach-Object { [System.IO.Path]::GetFileName($_) }) -contains [System.IO.Path]::GetFileName($RelativePath))
  $isHistorical = ($phaseNumber -ne $null -and $phaseNumber -lt 160) -or ($RelativePath -like 'packs/PHASE*' -and -not ($RelativePath -match 'PHASE161'))
  $liveProofs = @($Proofs | Where-Object { $_ -match '(LIVE|RUNTIME|DAEMON|SCHOOL|OWNER|SESSION)' } | Select-Object -Unique)
  $proofJsonProofs = @($Proofs | Where-Object { $_ -like 'proofs/*.json' -or $_ -like 'proofs/*/*.json' } | Select-Object -Unique)
  $reportReferences = @($Reports | Select-Object -Unique)
  $historicalReferences = @($Proofs + $Reports + $RouteRefs | Where-Object { $_ -match 'PHASE([0-9]+)' -and ([int]([regex]::Match($_, 'PHASE([0-9]+)').Groups[1].Value)) -lt 160 } | Select-Object -Unique)
  $currentWiringSignals = @($currentCodeCallers + $currentRouteRefs | Select-Object -Unique)
  $isCurrentWired = $currentWiringSignals.Count -gt 0
  $hasOnlyWeakReference = (-not $isCurrentWired) -and ($reportReferences.Count -gt 0 -or $historicalReferences.Count -gt 0)

  $primary = 'UNKNOWN_NEEDS_REVIEW'
  $why = 'Status is uncertain because no stronger wiring, proof, validator, or source-of-truth signal was detected.'
  $evidenceType = 'UNKNOWN_NEEDS_REVIEW'
  $evidenceStrength = 'UNKNOWN_WEAK'
  $evidenceBasis = 'No current wiring, live proof, validator proof, route-lock supersession, or strong stub signal was detected.'
  $safeToModify = -not $isProtected
  $ownerApproval = $isProtected
  $next = 'Review manually and connect to validator or route evidence before relying on it.'

  if ($isSupersededByRouteLock) {
    $primary = 'SUPERSEDED'
    $why = 'Artifact is named by active route-lock supersession evidence and must not be treated as current active wiring.'
    $evidenceType = 'SUPERSEDED_BY_ROUTE_LOCK'
    $evidenceStrength = 'SUPERSEDED_STRONG'
    $evidenceBasis = 'Matched route_locks/ACTIVE_ROUTE_LOCK.json superseded_route_locks or active route lock supersedes section.'
    $next = 'Keep as historical route evidence; do not execute or promote without owner-approved route change.'
  } elseif ($ParserStatus -eq 'BROKEN_PARSE') {
    $primary = 'BROKEN_PARSE'
    $why = 'PowerShell parser reported errors, so the artifact cannot be considered wired or proven.'
    $evidenceType = 'UNKNOWN_NEEDS_REVIEW'
    $evidenceStrength = 'UNKNOWN_WEAK'
    $evidenceBasis = 'Parser failure blocks reliable evidence classification.'
    $next = 'Repair parse errors before classification upgrade.'
  } elseif ($isProtected) {
    $primary = 'RISK_LOCKED'
    $why = 'Artifact is protected source-of-truth or protected execution surface and is read-only for PHASE161D.'
    $evidenceType = 'PROTECTED_RISK_LOCKED'
    $evidenceStrength = 'RISK_LOCKED_STRONG'
    $evidenceBasis = 'Path is in protected source-of-truth set.'
    $next = 'Read only; create update candidate under reports/self_development if a state change is needed.'
  } elseif ($nearEmpty) {
    $primary = 'EMPTY_OR_NEAR_EMPTY'
    $why = 'File is too small to provide meaningful behavior or evidence.'
    $evidenceType = 'REAL_STUB_OR_PLACEHOLDER'
    $evidenceStrength = 'DISCONNECTED_WEAK'
    $evidenceBasis = 'Near-empty file length.'
    $next = 'Inspect before use; do not delete without owner approval.'
  } elseif ($realStubSignal) {
    $primary = 'STUB_OR_PLACEHOLDER'
    $why = 'Executable or near-empty artifact has a real stub/not-implemented signal.'
    $evidenceType = 'REAL_STUB_OR_PLACEHOLDER'
    $evidenceStrength = 'DISCONNECTED_WEAK'
    $evidenceBasis = 'Stub signal was found in executable context, validator pass-through context, or near-empty artifact.'
    $next = 'Repair only under a bounded task with validator coverage.'
  } elseif ($falsePositiveStubSignal) {
    $primary = $(if ($isCurrentWired) { 'ACTIVE_WIRED_UNPROVEN' } elseif ($hasValidator) { 'PRESENT_WIRED_TO_VALIDATOR_ONLY' } else { 'PRESENT_NOT_WIRED' })
    $why = 'Text contains stub/placeholder wording, but PHASE161D classified it as explanatory text rather than a real stub.'
    $evidenceType = 'FALSE_POSITIVE_STUB_SIGNAL'
    $evidenceStrength = 'REPORT_WEAK'
    $evidenceBasis = 'Stub keyword found without executable not-implemented behavior.'
    $next = 'Do not repair as stub; improve classifier evidence or connect real wiring/proof if needed.'
  } elseif ($isCurrentWired -and $liveProofs.Count -gt 0) {
    $primary = 'ACTIVE_WIRED_PROVEN'
    $why = 'Artifact has current route/daemon/runner wiring and live/runtime proof evidence.'
    $evidenceType = 'LIVE_RUNTIME_PROVEN'
    $evidenceStrength = 'LIVE_STRONG'
    $evidenceBasis = 'Current wiring signal plus live/runtime proof path.'
    $next = 'Keep as live-proven active evidence input.'
  } elseif ($isCurrentWired -and $proofJsonProofs.Count -gt 0) {
    $primary = 'ACTIVE_WIRED_PROVEN'
    $why = 'Artifact has current route/daemon/runner wiring and direct proof JSON evidence.'
    $evidenceType = $(if ($currentRouteRefs.Count -gt 0) { 'CURRENT_ROUTE_WIRED' } elseif ($RelativePath -match 'daemon') { 'CURRENT_DAEMON_WIRED' } else { 'CURRENT_RUNNER_WIRED' })
    $evidenceStrength = 'CURRENT_WIRED_STRONG'
    $evidenceBasis = 'Current code/route wiring signal plus proof JSON evidence.'
    $next = 'Keep as current wired proven evidence input.'
  } elseif ($isCurrentWired) {
    $primary = 'ACTIVE_WIRED_UNPROVEN'
    $why = 'Artifact has current route/daemon/runner wiring but lacks proof evidence.'
    $evidenceType = $(if ($currentRouteRefs.Count -gt 0) { 'CURRENT_ROUTE_WIRED' } elseif ($RelativePath -match 'daemon') { 'CURRENT_DAEMON_WIRED' } else { 'CURRENT_RUNNER_WIRED' })
    $evidenceStrength = 'CURRENT_WIRED_STRONG'
    $evidenceBasis = 'Current code/route wiring signal without proof.'
    $next = 'Add live or proof JSON evidence before marking proven.'
  } elseif ($artifactType -eq 'validator' -and -not $hasProof) {
    $primary = 'VALIDATOR_NO_PROOF'
    $why = 'Validator exists but no matching proof artifact was detected.'
    $evidenceType = 'VALIDATOR_PROVEN'
    $evidenceStrength = 'VALIDATOR_MEDIUM'
    $evidenceBasis = 'Validator artifact exists but no proof path was found.'
    $next = 'Run validator and write proof before relying on it.'
  } elseif ($hasValidator) {
    $primary = 'PRESENT_WIRED_TO_VALIDATOR_ONLY'
    $why = 'Artifact has validator evidence but no current route/daemon/runner wiring.'
    $evidenceType = 'VALIDATOR_PROVEN'
    $evidenceStrength = 'VALIDATOR_MEDIUM'
    $evidenceBasis = 'Validator reference exists without current wiring.'
    $next = 'Keep as validator-proven only until current wiring or live proof exists.'
  } elseif ($artifactType -eq 'proof' -and -not [regex]::IsMatch($Text, 'runtime_sessions|live|RUNTIME|LIVE', 'IgnoreCase')) {
    $primary = 'PROOF_NO_LIVE_EVIDENCE'
    $why = 'Proof exists, but no live or runtime evidence marker was detected.'
    $evidenceType = 'PROOF_JSON_PROVEN'
    $evidenceStrength = 'PROOF_MEDIUM'
    $evidenceBasis = 'Proof JSON exists without live/runtime marker.'
    $next = 'Treat as validator proof unless live evidence is added.'
  } elseif ($hasProof -and $liveProofs.Count -eq 0) {
    $primary = 'PROOF_NO_LIVE_EVIDENCE'
    $why = 'Artifact has proof references but no current wiring or live/runtime proof.'
    $evidenceType = 'PROOF_JSON_PROVEN'
    $evidenceStrength = 'PROOF_MEDIUM'
    $evidenceBasis = 'Proof path exists without current wiring.'
    $next = 'Keep as proof-referenced only; add current wiring evidence before marking active.'
  } elseif ($isHistorical) {
    $primary = 'PRESENT_NOT_WIRED'
    $why = 'Artifact appears historical and has no current route/daemon/runner wiring.'
    $evidenceType = 'HISTORICAL_REFERENCE_ONLY'
    $evidenceStrength = 'HISTORICAL_WEAK'
    $evidenceBasis = 'Old phase or historical pack payload without current wiring.'
    $next = 'Keep as historical reference; do not treat as active without current route evidence.'
  } elseif ($hasOnlyWeakReference) {
    $primary = 'PRESENT_NOT_WIRED'
    $why = 'Artifact has report or historical references only, not current route/daemon/runner wiring.'
    $evidenceType = 'REPORT_REFERENCED'
    $evidenceStrength = 'REPORT_WEAK'
    $evidenceBasis = 'Report or historical reference exists without current wiring.'
    $next = 'Keep as referenced artifact; connect to current wiring or classify historical before reuse.'
  } else {
    $primary = 'PRESENT_NOT_WIRED'
    $why = 'No current route, daemon, runner, validator, proof, or strong report evidence was detected by PHASE161D scanning.'
    $evidenceType = 'DISCONNECTED_NOT_WIRED'
    $evidenceStrength = 'DISCONNECTED_WEAK'
    $evidenceBasis = 'No current evidence signal.'
    $next = 'Keep as present artifact; connect or classify historically before reuse.'
  }

  $passportBlockers = New-Object System.Collections.Generic.List[string]
  $maturityClass = 'UNKNOWN_NEEDS_REVIEW'
  $passportStatus = 'CARD_CREATED_NEEDS_REVIEW'
  $mapCardRole = 'DISCOVERED_ARTIFACT'

  if ($artifactType -in @('operation_surface','routing_surface','body_organ','module','orchestrator','capability_shelf')) {
    $mapCardRole = 'ORGAN_OR_MODULE_CANDIDATE'
  } elseif ($artifactType -eq 'validator') {
    $mapCardRole = 'VALIDATOR_SURFACE'
  } elseif ($artifactType -eq 'proof') {
    $mapCardRole = 'PROOF_SURFACE'
  } elseif ($artifactType -eq 'report') {
    $mapCardRole = 'REPORT_SURFACE'
  }

  if ($primary -eq 'ACTIVE_WIRED_PROVEN') {
    $maturityClass = 'ORGAN_OR_MODULE_COMPLETE_ENOUGH_FOR_MAP'
    $passportStatus = 'PASSPORT_ISSUED_PROVEN'
  } elseif ($primary -eq 'ACTIVE_WIRED_UNPROVEN') {
    $maturityClass = 'ORGAN_OR_MODULE_INCOMPLETE'
    $passportStatus = 'CARD_CREATED_PASSPORT_BLOCKED'
    $passportBlockers.Add('missing_live_or_proof_json_evidence')
  } elseif ($primary -eq 'PRESENT_WIRED_TO_VALIDATOR_ONLY') {
    $maturityClass = 'MODULE_OR_ORGAN_CANDIDATE_VALIDATOR_ONLY'
    $passportStatus = 'CARD_CREATED_PASSPORT_BLOCKED'
    $passportBlockers.Add('missing_current_route_or_runtime_wiring')
    $passportBlockers.Add('missing_live_or_proof_json_evidence')
  } elseif ($primary -eq 'VALIDATOR_NO_PROOF') {
    $maturityClass = 'VALIDATOR_INCOMPLETE'
    $passportStatus = 'CARD_CREATED_PASSPORT_BLOCKED'
    $passportBlockers.Add('validator_has_no_matching_proof')
  } elseif ($primary -eq 'PROOF_NO_LIVE_EVIDENCE') {
    $maturityClass = 'PROOF_SURFACE_NOT_LIVE'
    $passportStatus = 'CARD_CREATED_NOT_ORGAN_PASSPORT'
    $passportBlockers.Add('proof_is_not_live_or_runtime_evidence')
  } elseif ($primary -eq 'PRESENT_NOT_WIRED') {
    if ($artifactType -in @('operation_surface','routing_surface','body_organ','module','orchestrator','capability_shelf')) {
      $maturityClass = 'ORGAN_OR_MODULE_CANDIDATE_UNWIRED'
      $passportStatus = 'CARD_CREATED_PASSPORT_BLOCKED'
      $passportBlockers.Add('missing_current_wiring_signal')
      $passportBlockers.Add('missing_validator_or_proof_evidence')
    } else {
      $maturityClass = 'DISCOVERED_ARTIFACT_UNWIRED'
      $passportStatus = 'CARD_CREATED_NOT_ORGAN_PASSPORT'
      $passportBlockers.Add('not_classified_as_organ_module_or_routing_surface')
    }
  } elseif ($primary -eq 'STUB_OR_PLACEHOLDER') {
    $maturityClass = 'INCOMPLETE_STUB_OR_PLACEHOLDER'
    $passportStatus = 'CARD_CREATED_PASSPORT_BLOCKED'
    $passportBlockers.Add('stub_or_placeholder_signal')
  } elseif ($primary -eq 'BROKEN_PARSE') {
    $maturityClass = 'BROKEN_PARSE_BLOCKS_PASSPORT'
    $passportStatus = 'CARD_CREATED_PASSPORT_BLOCKED'
    $passportBlockers.Add('parser_errors_block_reliable_classification')
  } elseif ($primary -eq 'SUPERSEDED') {
    $maturityClass = 'SUPERSEDED_REFERENCE'
    $passportStatus = 'CARD_CREATED_ARCHIVE_REFERENCE'
    $passportBlockers.Add('superseded_by_current_route_or_policy')
  } elseif ($primary -eq 'RISK_LOCKED') {
    $maturityClass = 'PROTECTED_SURFACE_REQUIRES_AUTHORITY'
    $passportStatus = 'CARD_CREATED_AUTHORITY_LOCKED'
    $passportBlockers.Add('protected_source_of_truth_or_execution_surface')
  } elseif ($primary -eq 'EMPTY_OR_NEAR_EMPTY') {
    $maturityClass = 'EMPTY_OR_NEAR_EMPTY_CANDIDATE'
    $passportStatus = 'CARD_CREATED_PASSPORT_BLOCKED'
    $passportBlockers.Add('insufficient_content_for_passport')
  }

  if ($artifactType -in @('operation_surface','routing_surface') -and @($RouteRefs).Count -eq 0) {
    $passportBlockers.Add('no_route_or_routing_reference_detected')
  }
  if ($artifactType -in @('operation_surface','routing_surface') -and @($Validators).Count -eq 0) {
    $passportBlockers.Add('no_validator_reference_detected')
  }
  return [pscustomobject]@{
    artifact_id = ($RelativePath -replace '[^A-Za-z0-9]+','_').Trim('_')
    path = $RelativePath
    artifact_type = $artifactType
    phase_hint = $phaseHint
    role_guess = $artifactType
    map_card_role = $mapCardRole
    discovery_status = 'DISCOVERED_BY_WIDE_SELF_MAP_SCAN'
    maturity_class = $maturityClass
    passport_status = $passportStatus
    passport_blockers = @($passportBlockers.ToArray() | Select-Object -Unique)
    primary_status = $primary
    why_status = $why
    evidence_type = $evidenceType
    evidence_strength = $evidenceStrength
    evidence_basis = $evidenceBasis
    evidence_paths = @($Proofs + $Reports + $RouteRefs | Select-Object -Unique)
    live_evidence_paths = @($liveProofs)
    validator_evidence_paths = @($Validators | Select-Object -Unique)
    proof_evidence_paths = @($Proofs | Select-Object -Unique)
    report_reference_paths = @($Reports | Select-Object -Unique)
    historical_reference_paths = @($historicalReferences)
    current_wiring_signals = @($currentWiringSignals)
    superseded_by = $(if ($isSupersededByRouteLock) { 'route_locks/ACTIVE_ROUTE_LOCK.json' } else { $null })
    stub_false_positive = $falsePositiveStubSignal
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
    missing_link_reason = $(if ($primary -eq 'PRESENT_NOT_WIRED') { $why } else { $null })
    placeholder_reason = $(if ($primary -eq 'STUB_OR_PLACEHOLDER') { 'Real stub/not-implemented signal detected.' } elseif ($falsePositiveStubSignal) { 'False-positive stub wording detected; not treated as real stub.' } else { $null })
    recommended_next_action = $next
  }
}

function Invoke-BuilderAgentBodyMap001 {
  param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$OutputRoot = 'reports/self_development',
    [switch]$ActiveMapOnly
  )

  $root = (Resolve-Path $RepoRoot).Path
  $outputFull = Join-Path $root $OutputRoot
  if (-not (Test-Path -LiteralPath $outputFull)) {
    New-Item -ItemType Directory -Path $outputFull | Out-Null
  }

  if ($ActiveMapOnly) {
    $activeMapPath = Join-Path $outputFull 'SELF_MODEL_ACTIVE_MAP.json'
    if (Test-Path -LiteralPath $activeMapPath) {
      $activeMap = Get-Content -LiteralPath $activeMapPath -Raw | ConvertFrom-Json
    } else {
      $activeMap = [pscustomobject][ordered]@{
        phase = 'PHASE161D_BODY_MAP_CLASSIFIER_HARDENING_AND_LIVE_EVIDENCE_SEPARATION_V1'
        map_role = 'DERIVED_FROM_EXISTING'
        source_of_truth_status = 'DERIVED_ACTIVE_MAP_CANDIDATE'
        classifier_version = 'PHASE161D_STRICT_EVIDENCE_V1'
        protected_state_mutation_allowed = $false
        accepted_repo_mutation_allowed_by_runtime = $false
      }
    }

    $evidenceFiles = New-Object System.Collections.Generic.List[object]
    $proofRoot = Join-Path $root 'proofs/self_development'
    $reportRoot = Join-Path $root 'reports/self_development'
    if (Test-Path -LiteralPath $proofRoot) {
      Get-ChildItem -LiteralPath $proofRoot -File -Filter '*.json' | ForEach-Object { $evidenceFiles.Add($_) }
    }
    if (Test-Path -LiteralPath $reportRoot) {
      Get-ChildItem -LiteralPath $reportRoot -File |
        Where-Object { $_.Extension -in @('.json','.md') } |
        ForEach-Object { $evidenceFiles.Add($_) }
    }

    $selfDevelopmentEvidence = @(
      $evidenceFiles |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 100 |
        ForEach-Object {
          $relative = ConvertTo-BuilderRelativePath -Root $root -Path $_.FullName
          $phaseHint = Get-BuilderPhaseHint -Text '' -Path $relative
          $phaseNumber = Get-BuilderPhaseNumber -PhaseHint $phaseHint -Path $relative
          $claimStatus = $null
          if ($_.Extension -eq '.json') {
            try {
              $json = Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
              if ($json.PSObject.Properties.Name -contains 'status') {
                $claimStatus = [string]$json.status
              }
            } catch {
              $claimStatus = 'UNPARSEABLE_JSON'
            }
          }
          $evidenceClass = if ($phaseNumber -ne $null -and $phaseNumber -lt 160) {
            'HISTORICAL_REFERENCE_ONLY'
          } elseif ($relative -like 'proofs/*') {
            'PROOF_JSON_PROVEN'
          } else {
            'REPORT_REFERENCED'
          }
          [pscustomobject][ordered]@{
            path = $relative
            artifact_type = Get-BuilderArtifactType -RelativePath $relative
            claim_status = $claimStatus
            evidence_class = $evidenceClass
            evidence_strength = $(if ($evidenceClass -eq 'PROOF_JSON_PROVEN') { 'PROOF_MEDIUM' } elseif ($evidenceClass -eq 'HISTORICAL_REFERENCE_ONLY') { 'HISTORICAL_WEAK' } else { 'REPORT_WEAK' })
            map_role = 'DIAGNOSTIC_EVIDENCE_INPUT_NOT_COMMAND'
            last_write_utc = $_.LastWriteTimeUtc.ToString('o')
          }
        }
    )

    $phase165qProofPath = 'proofs/self_development/PHASE165Q_BUILDER_SELF_MAP_ROUTE_RECONCILIATION_V1.json'
    $phase165qReportPath = 'reports/self_development/PHASE165Q_BUILDER_SELF_MAP_ROUTE_RECONCILIATION_V1.md'
    $phase165qProofFull = Join-Path $root $phase165qProofPath
    $phase165qProof = $null
    if (Test-Path -LiteralPath $phase165qProofFull) {
      try { $phase165qProof = Get-Content -LiteralPath $phase165qProofFull -Raw | ConvertFrom-Json } catch { $phase165qProof = $null }
    }

    Set-BuilderObjectProperty $activeMap 'generated_at' ((Get-Date).ToUniversalTime().ToString('o'))
    Set-BuilderObjectProperty $activeMap 'decision_authority' 'MODE_DECISION_KERNEL'
    Set-BuilderObjectProperty $activeMap 'map_authority_role' 'DIAGNOSTIC_MAP_SIGNAL_NOT_COMMAND'
    Set-BuilderObjectProperty $activeMap 'source_ingestion' ([pscustomobject][ordered]@{
      proof_glob = 'proofs/self_development/*.json'
      report_globs = @('reports/self_development/*.md','reports/self_development/*.json')
      evidence_count = $selfDevelopmentEvidence.Count
      historical_artifacts_are_live_proof = $false
    })
    Set-BuilderObjectProperty $activeMap 'recent_self_development_evidence' $selfDevelopmentEvidence
    Set-BuilderObjectProperty $activeMap 'phase165q_reconciliation' ([pscustomobject][ordered]@{
      proof_path = $phase165qProofPath
      proof_present = [bool](Test-Path -LiteralPath $phase165qProofFull)
      proof_status = $(if ($phase165qProof -and $phase165qProof.PSObject.Properties.Name -contains 'status') { [string]$phase165qProof.status } else { $null })
      report_path = $phase165qReportPath
      report_present = [bool](Test-Path -LiteralPath (Join-Path $root $phase165qReportPath))
      route_decision = $(if ($phase165qProof -and $phase165qProof.PSObject.Properties.Name -contains 'route_decision') { [string]$phase165qProof.route_decision } else { $null })
      next_required_action = $(if ($phase165qProof -and $phase165qProof.PSObject.Properties.Name -contains 'next_required_action') { [string]$phase165qProof.next_required_action } else { $null })
      evidence_role = 'DIAGNOSTIC_RECONCILIATION_PROOF_NOT_GLOBAL_COMMAND'
    })

    Write-BuilderJsonFile -Path $activeMapPath -Value $activeMap -Depth 50
    return [pscustomobject]@{
      result = 'PASS'
      output_root = ConvertTo-BuilderRelativePath -Root $root -Path $outputFull
      protected_state_mutation_allowed = $false
      map_role = 'DERIVED_FROM_EXISTING'
      active_map_only = $true
      evidence_count = $selfDevelopmentEvidence.Count
      phase165q_visible = [bool]$activeMap.phase165q_reconciliation.proof_present
    }
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
  $routeContext = Get-BuilderRouteLockContext -Root $root

  $modulePaths = @($textByPath.Keys | Where-Object { $_ -like 'modules/*.ps1' } | Sort-Object)
  $validatorPaths = @($textByPath.Keys | Where-Object { $_ -like 'validators/*.ps1' } | Sort-Object)
  $schemaPaths = @($textByPath.Keys | Where-Object { $_ -like 'schemas/*' -or $_ -like 'contracts/*' } | Sort-Object)
  $reportPaths = @($textByPath.Keys | Where-Object { $_ -like 'reports/*' } | Sort-Object)
  $proofPaths = @($textByPath.Keys | Where-Object { $_ -like 'proofs/*' } | Sort-Object)
  $routePaths = @($textByPath.Keys | Where-Object { $_ -like 'route_locks/*' -or $_ -like 'route_change_requests/*' -or ($_ -like 'operations/*' -and $_ -match '(route|replay|ledger|active_store|ready_lane|policy|guard|pointer)') } | Sort-Object)

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

    $item = New-BuilderArtifactClassification -FileRecord $file -RelativePath $rel -Text $text -ReferenceIndex @{} -Validators $validators -Reports $reports -Proofs $proofs -RouteRefs $routeRefs -Schemas $schemas -Callees @($calleeBySource[$rel]) -Callers @($callerByTarget[$rel]) -RouteContext $routeContext -ParserStatus $parserStatus
    $artifactItems.Add($item)
  }

  $stubItems = @($artifactItems | Where-Object { $_.primary_status -in @('STUB_OR_PLACEHOLDER','EMPTY_OR_NEAR_EMPTY') } | ForEach-Object {
    [pscustomobject]@{
      path = $_.path
      artifact_type = $_.artifact_type
      stub_signal = $(if ($_.primary_status -eq 'EMPTY_OR_NEAR_EMPTY') { 'low_size_file' } else { $_.evidence_type })
      severity = $(if ($_.primary_status -eq 'EMPTY_OR_NEAR_EMPTY') { 'medium' } else { 'high' })
      why_status = $_.why_status
      safe_repair_possible = $_.safe_to_modify
      recommended_action = $_.recommended_next_action
    }
  })

  $stubFalsePositiveItems = @($artifactItems | Where-Object { $_.stub_false_positive } | Select-Object -First 250 | ForEach-Object {
    [pscustomobject]@{
      path = $_.path
      artifact_type = $_.artifact_type
      false_positive_signal = $_.placeholder_reason
      evidence_type = $_.evidence_type
      why_status = $_.why_status
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

  $historicalReferenceItems = @($artifactItems | Where-Object { $_.evidence_type -eq 'HISTORICAL_REFERENCE_ONLY' } | Select-Object -First 500 | ForEach-Object {
    [pscustomobject]@{
      path = $_.path
      phase_hint = $_.phase_hint
      evidence_strength = $_.evidence_strength
      why_status = $_.why_status
      historical_reference_paths = $_.historical_reference_paths
      recommended_action = $_.recommended_next_action
    }
  })

  $supersededItems = @($artifactItems | Where-Object { $_.evidence_type -eq 'SUPERSEDED_BY_ROUTE_LOCK' -or $_.primary_status -eq 'SUPERSEDED' } | ForEach-Object {
    [pscustomobject]@{
      path = $_.path
      superseded_by = $_.superseded_by
      evidence_strength = $_.evidence_strength
      why_status = $_.why_status
      recommended_action = $_.recommended_next_action
    }
  })

  $evidenceGroups = @($artifactItems | Group-Object evidence_type | Sort-Object Name | ForEach-Object {
    [pscustomobject]@{
      evidence_type = $_.Name
      count = $_.Count
    }
  })
  $liveEvidenceItems = @($artifactItems | Where-Object { $_.evidence_type -eq 'LIVE_RUNTIME_PROVEN' -or $_.evidence_type -like 'CURRENT_*' } | Select-Object -First 500 | ForEach-Object {
    [pscustomobject]@{
      path = $_.path
      primary_status = $_.primary_status
      evidence_type = $_.evidence_type
      evidence_strength = $_.evidence_strength
      current_wiring_signals = $_.current_wiring_signals
      live_evidence_paths = $_.live_evidence_paths
      proof_evidence_paths = $_.proof_evidence_paths
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
      why_status = 'Artifacts with validator/proof/report references must remain separated from live-runtime proven artifacts until current wiring and live evidence are present.'
      blocking_dependency_chain = @('validator evidence', 'proof evidence', 'current route/daemon/runner wiring', 'live runtime evidence')
      recommended_next_action = 'Use live_evidence_separation_index.json before promoting any artifact to active live-proven.'
      safe_to_repair_now = $true
    },
    [pscustomobject]@{
      gap_id = 'GAP_ORPHANED_PRESENT_ARTIFACTS'
      why_status = 'PHASE161D now exposes disconnected and historical artifacts rather than suppressing them through broad proof/report matching.'
      blocking_dependency_chain = @('strict current wiring detection', 'historical classification', 'disconnected inventory', 'owner-approved repair or archival plan')
      recommended_next_action = 'Inspect orphaned_artifact_inventory.json and historical_reference_inventory.json before any cleanup.'
      safe_to_repair_now = $false
    },
    [pscustomobject]@{
      gap_id = 'GAP_STUB_PLACEHOLDER_ARTIFACTS'
      why_status = 'Stub detection must distinguish executable not-implemented behavior from documentation that merely discusses placeholder rules.'
      blocking_dependency_chain = @('real stub detection', 'false-positive stub inventory', 'bounded repair task', 'validator proof')
      recommended_next_action = 'Use stub_false_positive_inventory.json before opening repair tasks.'
      safe_to_repair_now = $false
    },
    [pscustomobject]@{
      gap_id = 'GAP_ROUTE_SUPERSESSION_PROPAGATION'
      why_status = 'Route-lock supersession must be propagated into artifact status so old route locks are not reported as current active organs.'
      blocking_dependency_chain = @('route_locks/ACTIVE_ROUTE_LOCK.json', 'active route lock supersedes section', 'superseded_artifact_inventory.json', 'body map primary_status')
      recommended_next_action = 'Keep superseded artifacts as historical evidence unless owner approves route change or archive policy.'
      safe_to_repair_now = $true
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
      evidence_type = $_.evidence_type
      evidence_strength = $_.evidence_strength
      why_status = $_.why_status
      recommended_action = $_.recommended_next_action
    }
  })

  $unsafeDebt = @($artifactItems | Where-Object { $_.owner_approval_required -or $_.primary_status -in @('RISK_LOCKED','BROKEN_PARSE','STUB_OR_PLACEHOLDER') } | Select-Object -First 100 | ForEach-Object {
    [pscustomobject]@{
      path = $_.path
      current_status = $_.primary_status
      evidence_type = $_.evidence_type
      evidence_strength = $_.evidence_strength
      why_status = $_.why_status
      owner_approval_required = $_.owner_approval_required
      recommended_action = $_.recommended_next_action
    }
  })

  foreach ($edge in $edges) {
    if (@($nodes | Where-Object { $_.id -eq $edge.target }).Count -eq 0) {
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
  $selfDevelopmentEvidence = @(
    $files |
      Where-Object {
        $relative = ConvertTo-BuilderRelativePath -Root $root -Path $_.FullName
        $relative -match '^proofs/self_development/[^/]+\.json$' -or
          $relative -match '^reports/self_development/[^/]+\.(json|md)$'
      } |
      Sort-Object LastWriteTimeUtc -Descending |
      Select-Object -First 100 |
      ForEach-Object {
        $relative = ConvertTo-BuilderRelativePath -Root $root -Path $_.FullName
        $classification = @($artifactArray | Where-Object { $_.path -eq $relative } | Select-Object -First 1)
        $claimStatus = $null
        if ($relative -like '*.json') {
          try {
            $json = $textByPath[$relative] | ConvertFrom-Json
            if ($json.PSObject.Properties.Name -contains 'status') {
              $claimStatus = [string]$json.status
            }
          } catch {
            $claimStatus = 'UNPARSEABLE_JSON'
          }
        }
        [pscustomobject][ordered]@{
          path = $relative
          artifact_type = Get-BuilderArtifactType -RelativePath $relative
          claim_status = $claimStatus
          evidence_class = $(if ($classification.Count -gt 0) { $classification[0].evidence_type } else { 'UNKNOWN_NEEDS_REVIEW' })
          evidence_strength = $(if ($classification.Count -gt 0) { $classification[0].evidence_strength } else { 'UNKNOWN_WEAK' })
          map_role = 'DIAGNOSTIC_EVIDENCE_INPUT_NOT_COMMAND'
          last_write_utc = $_.LastWriteTimeUtc.ToString('o')
        }
      }
  )
  $phase165qProofPath = 'proofs/self_development/PHASE165Q_BUILDER_SELF_MAP_ROUTE_RECONCILIATION_V1.json'
  $phase165qReportPath = 'reports/self_development/PHASE165Q_BUILDER_SELF_MAP_ROUTE_RECONCILIATION_V1.md'
  $phase165qProof = $null
  if ($textByPath.ContainsKey($phase165qProofPath)) {
    try { $phase165qProof = $textByPath[$phase165qProofPath] | ConvertFrom-Json } catch { $phase165qProof = $null }
  }

  $map = [pscustomobject][ordered]@{
    phase = 'PHASE161D_BODY_MAP_CLASSIFIER_HARDENING_AND_LIVE_EVIDENCE_SEPARATION_V1'
    map_role = 'DERIVED_FROM_EXISTING'
    source_of_truth_status = 'DERIVED_ACTIVE_MAP_CANDIDATE'
    classifier_version = 'PHASE161D_STRICT_EVIDENCE_V1'
    why_status = 'Derived from existing protected state, self-knowledge, self-model, body registry, capability shelf, route locks, modules, validators, reports, proofs, docs, packs, and orchestrator files. PHASE161D separates live evidence, validator proof, proof/report references, historical references, supersession, disconnected artifacts, and stub false positives.'
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
    phase = 'PHASE161D_BODY_MAP_CLASSIFIER_HARDENING_AND_LIVE_EVIDENCE_SEPARATION_V1'
    graph_role = 'MODULE_WIRING_GRAPH'
    why_status = 'Static graph derived from function/module name references, protected-state references, schema filename references, phase references, and discovered proof/report links.'
    nodes = $nodeArray
    edges = @($edgeArray | Select-Object -First 2000)
  }

  $activeMap = [pscustomobject][ordered]@{
    phase = 'PHASE161D_BODY_MAP_CLASSIFIER_HARDENING_AND_LIVE_EVIDENCE_SEPARATION_V1'
    map_role = 'DERIVED_FROM_EXISTING'
    source_of_truth_status = 'DERIVED_ACTIVE_MAP_CANDIDATE'
    classifier_version = 'PHASE161D_STRICT_EVIDENCE_V1'
    why_status = 'This file is the PHASE161D hardened derived active map candidate. It reuses existing organs, avoids direct protected-state mutation, and separates current/live evidence from validator/proof/report/historical references.'
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
    decision_authority = 'MODE_DECISION_KERNEL'
    map_authority_role = 'DIAGNOSTIC_MAP_SIGNAL_NOT_COMMAND'
    active_artifacts = @($artifactArray | Where-Object { $_.primary_status -like 'ACTIVE_*' } | Select-Object -First 200)
    recent_self_development_evidence = $selfDevelopmentEvidence
    phase165q_reconciliation = [pscustomobject][ordered]@{
      proof_path = $phase165qProofPath
      proof_present = [bool]$textByPath.ContainsKey($phase165qProofPath)
      proof_status = $(if ($phase165qProof -and $phase165qProof.PSObject.Properties.Name -contains 'status') { [string]$phase165qProof.status } else { $null })
      report_path = $phase165qReportPath
      report_present = [bool]$textByPath.ContainsKey($phase165qReportPath)
      route_decision = $(if ($phase165qProof -and $phase165qProof.PSObject.Properties.Name -contains 'route_decision') { [string]$phase165qProof.route_decision } else { $null })
      next_required_action = $(if ($phase165qProof -and $phase165qProof.PSObject.Properties.Name -contains 'next_required_action') { [string]$phase165qProof.next_required_action } else { $null })
      evidence_role = 'DIAGNOSTIC_RECONCILIATION_PROOF_NOT_GLOBAL_COMMAND'
    }
    evidence_type_counts = $evidenceGroups
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
  $organMaturityDiagnostics = @($artifactItems | Where-Object { $_.map_card_role -in @('ORGAN_OR_MODULE_CANDIDATE','VALIDATOR_SURFACE') -or $_.passport_status -eq 'CARD_CREATED_PASSPORT_BLOCKED' } | ForEach-Object {
    [pscustomobject]@{
      path = $_.path
      artifact_type = $_.artifact_type
      map_card_role = $_.map_card_role
      primary_status = $_.primary_status
      maturity_class = $_.maturity_class
      passport_status = $_.passport_status
      passport_blockers = @($_.passport_blockers)
      recommended_next_action = $_.recommended_next_action
    }
  })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'orphaned_artifact_inventory.json') -Value ([pscustomobject]@{ phase = $map.phase; items = @($orphanItems) })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'organ_maturity_diagnostics.json') -Value ([pscustomobject]@{ phase = $map.phase; diagnostics_role = 'DISCOVERY_WIDE_ACCEPTANCE_STRICT_PASSPORT_DIAGNOSTICS'; items = @($organMaturityDiagnostics) })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'self_model_gap_chain.json') -Value ([pscustomobject]@{ phase = $map.phase; gaps = $gapChain })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'SELF_MODEL_ACTIVE_MAP.json') -Value $activeMap
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'safe_repair_candidates_from_body_map.json') -Value ([pscustomobject]@{ phase = $map.phase; candidates = @($safeRepair) })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'unsafe_debt_backlog_from_body_map.json') -Value ([pscustomobject]@{ phase = $map.phase; debt = @($unsafeDebt) })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'live_evidence_separation_index.json') -Value ([pscustomobject]@{
    phase = $map.phase
    classifier_version = 'PHASE161D_STRICT_EVIDENCE_V1'
    evidence_type_counts = $evidenceGroups
    live_or_current_wired_items = $liveEvidenceItems
    why_status = 'Separates live/current wiring from validator, proof JSON, report, historical, superseded, disconnected, and false-positive stub evidence.'
  })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'historical_reference_inventory.json') -Value ([pscustomobject]@{ phase = $map.phase; items = @($historicalReferenceItems) })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'superseded_artifact_inventory.json') -Value ([pscustomobject]@{ phase = $map.phase; items = @($supersededItems) })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'stub_false_positive_inventory.json') -Value ([pscustomobject]@{ phase = $map.phase; items = @($stubFalsePositiveItems) })
  Write-BuilderJsonFile -Path (Join-Path $outputFull 'agent_body_map_classifier_hardening_result.json') -Value ([pscustomobject]@{
    phase = $map.phase
    classifier_version = 'PHASE161D_STRICT_EVIDENCE_V1'
    total_artifacts = $artifactItems.Count
    active_wired_proven_count = @($artifactItems | Where-Object { $_.primary_status -eq 'ACTIVE_WIRED_PROVEN' }).Count
    active_wired_unproven_count = @($artifactItems | Where-Object { $_.primary_status -eq 'ACTIVE_WIRED_UNPROVEN' }).Count
    present_not_wired_count = @($artifactItems | Where-Object { $_.primary_status -eq 'PRESENT_NOT_WIRED' }).Count
    superseded_count = @($artifactItems | Where-Object { $_.primary_status -eq 'SUPERSEDED' }).Count
    false_positive_stub_count = @($stubFalsePositiveItems).Count
    real_stub_count = @($stubItems).Count
    evidence_type_counts = $evidenceGroups
    why_status = 'PHASE161D hardened classifier reduced active/proven over-classification and separated evidence classes.'
  })

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
    "False-positive stub entries: $($stubFalsePositiveItems.Count)",
    "Orphan candidates: $($orphanItems.Count)",
    "Historical reference entries: $($historicalReferenceItems.Count)",
    "Superseded entries: $($supersededItems.Count)",
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
    '- `unsafe_debt_backlog_from_body_map.json`',
    '- `live_evidence_separation_index.json`',
    '- `historical_reference_inventory.json`',
    '- `superseded_artifact_inventory.json`',
    '- `stub_false_positive_inventory.json`',
    '- `agent_body_map_classifier_hardening_result.json`'
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
    false_positive_stub_count = $stubFalsePositiveItems.Count
    historical_reference_count = $historicalReferenceItems.Count
    superseded_count = $supersededItems.Count
    active_wired_proven_count = @($artifactItems | Where-Object { $_.primary_status -eq 'ACTIVE_WIRED_PROVEN' }).Count
    present_not_wired_count = @($artifactItems | Where-Object { $_.primary_status -eq 'PRESENT_NOT_WIRED' }).Count
    protected_state_mutation_allowed = $false
    map_role = 'DERIVED_FROM_EXISTING'
    classifier_version = 'PHASE161D_STRICT_EVIDENCE_V1'
  }
}

if ($Build) {
  Invoke-BuilderAgentBodyMap001 -RepoRoot $RepoRoot -OutputRoot $OutputRoot | ConvertTo-Json -Depth 8
}
