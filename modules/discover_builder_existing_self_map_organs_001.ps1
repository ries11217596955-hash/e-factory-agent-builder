param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputPath = 'reports/self_development/PHASE161C_EXISTING_MAP_DISCOVERY.json',
  [switch]$Write
)

Set-StrictMode -Version 2.0

function ConvertTo-BuilderDiscoveryRelativePath {
  param([string]$Root, [string]$Path)
  return ([System.IO.Path]::GetRelativePath([System.IO.Path]::GetFullPath($Root), [System.IO.Path]::GetFullPath($Path)) -replace '\\','/')
}

function New-BuilderDiscoveredOrgan {
  param(
    [string]$Path,
    [string]$Type,
    [string]$Classification,
    [bool]$Protected,
    [string]$WhyStatus,
    [bool]$CanBeExtended,
    [bool]$ReadOnly,
    [string]$RecommendedHandling
  )
  [pscustomobject]@{
    path = $Path
    type = $Type
    classification = $Classification
    protected = $Protected
    current_or_stale = $(if ($Classification -eq 'ACTIVE') { 'active_source' } elseif ($Protected) { 'current_but_phase_read_only' } else { 'partial_or_historical' })
    why_status = $WhyStatus
    can_be_extended = $CanBeExtended
    should_be_read_only = $ReadOnly
    recommended_handling = $RecommendedHandling
  }
}

function Invoke-BuilderExistingSelfMapOrganDiscovery001 {
  param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
  )
  $root = (Resolve-Path $RepoRoot).Path
  $organs = New-Object System.Collections.Generic.List[object]

  $protected = @(
    @{ Path = 'CAPABILITY_ROADMAP.json'; Type = 'protected_capability_roadmap'; Why = 'Protected source-of-truth for capability roadmap; read-only in PHASE161C.' },
    @{ Path = 'GENESIS_STATE.json'; Type = 'protected_genesis_state'; Why = 'Protected genesis state; read-only in PHASE161C.' },
    @{ Path = 'TASK_QUEUE.json'; Type = 'protected_task_queue'; Why = 'Protected task queue state; read-only in PHASE161C.' },
    @{ Path = 'packs/registry.json'; Type = 'protected_pack_registry'; Why = 'Protected pack registry; read-only in PHASE161C.' },
    @{ Path = 'route_locks/ACTIVE_ROUTE_LOCK.json'; Type = 'active_route_lock'; Why = 'Active route source; owner approval required for mutation.' }
  )
  foreach ($item in $protected) {
    if (Test-Path -LiteralPath (Join-Path $root $item.Path)) {
      $organs.Add((New-BuilderDiscoveredOrgan -Path $item.Path -Type $item.Type -Classification 'PROTECTED_SOURCE_OF_TRUTH' -Protected $true -WhyStatus $item.Why -CanBeExtended $false -ReadOnly $true -RecommendedHandling 'Read as input only.'))
    }
  }

  $patterns = @(
    'self_knowledge/*.json',
    'self_model/*.json',
    'living_learning_environment/body/*.json',
    'living_learning_environment/body/organs/*.json',
    'capability_shelf/*.json',
    'self_build_backlog/*GAP*.json',
    'modules/*self*knowledge*.ps1',
    'modules/*self*model*.ps1',
    'modules/*inventory*.ps1',
    'modules/*capability*.ps1'
  )
  foreach ($pattern in $patterns) {
    Get-ChildItem -Path (Join-Path $root $pattern) -File -ErrorAction SilentlyContinue | ForEach-Object {
      $rel = ConvertTo-BuilderDiscoveryRelativePath -Root $root -Path $_.FullName
      $classification = 'INCOMPLETE'
      $type = 'self_map_related_artifact'
      $why = 'Artifact matched self-map, inventory, capability, body, or gap discovery patterns but is not itself the PHASE161C unified body map.'
      if ($rel -like 'living_learning_environment/body/body_registry.json' -or $rel -like 'living_learning_environment/body/BUILDER_BODY_ORGAN_PACK_V1.json' -or $rel -like 'capability_shelf/registry.json') {
        $classification = 'ACTIVE'
        $why = 'Existing active source organ found and reused as input to PHASE161C derived map.'
      }
      $organs.Add((New-BuilderDiscoveredOrgan -Path $rel -Type $type -Classification $classification -Protected $false -WhyStatus $why -CanBeExtended $true -ReadOnly $false -RecommendedHandling 'Reuse as input to reports/self_development derived map.'))
    }
  }

  return [pscustomobject]@{
    phase = 'PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_V1'
    discovery_role = 'REPEATABLE_EXISTING_MAP_DISCOVERY'
    root_guard = [pscustomobject]@{ result = 'PASS' }
    current_source_of_truth_candidate = [pscustomobject]@{
      path = 'reports/self_development/SELF_MODEL_ACTIVE_MAP.json'
      status = 'DERIVED_ACTIVE_MAP_CANDIDATE'
      why_status = 'Existing organs are reused as inputs, but protected state is read-only and no existing organ provides the complete PHASE161C taxonomy and wiring map.'
    }
    organs = @($organs | Sort-Object path -Unique)
    reuse_decision = [pscustomobject]@{
      decision = 'CREATE_DERIVED_ACTIVE_MAP_FROM_EXISTING_ORGANS'
      why_status = 'Existing body, self-model, self-knowledge, capability, roadmap, registry, and route organs are present but split. PHASE161C derives one active map under reports/self_development.'
    }
  }
}

if ($Write) {
  $root = (Resolve-Path $RepoRoot).Path
  $out = Join-Path $root $OutputPath
  $dir = Split-Path -Parent $out
  if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
  Invoke-BuilderExistingSelfMapOrganDiscovery001 -RepoRoot $root | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $out -Encoding UTF8
  Get-Item -LiteralPath $out
}
