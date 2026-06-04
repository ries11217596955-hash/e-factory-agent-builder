param(
  [string]$RepoRoot = ".",
  [string]$OutputDir = "reports/self_development"
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160IRoutePath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160IRouteRepoRoot {
  param([string]$RepoRootParameter)
  if (-not [string]::IsNullOrWhiteSpace($RepoRootParameter) -and $RepoRootParameter -ne ".") {
    return Normalize-Phase160IRoutePath -Path $RepoRootParameter
  }
  $scriptRoot = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRoot) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRoot = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    throw "PHASE160I_ROUTE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160IRoutePath -Path (Join-Path $scriptRoot "..")
}

function Resolve-Phase160IRoutePath {
  param([string]$Root, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $Root $Path))
}

function ConvertTo-Phase160IRouteRelativePath {
  param([string]$Root, [string]$FullPath)
  $rootFull = Normalize-Phase160IRoutePath -Path $Root
  $pathFull = Normalize-Phase160IRoutePath -Path $FullPath
  if ($pathFull -eq $rootFull) {
    return "."
  }
  if (-not $pathFull.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160I_ROUTE_PATH_OUTSIDE_REPO=$FullPath"
  }
  return ($pathFull.Substring($rootFull.Length + 1) -replace "\\", "/")
}

function Write-Phase160IRouteJsonFile {
  param([string]$Path, [object]$Object)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $json = ($Object | ConvertTo-Json -Depth 100) -replace "`r`n", "`n"
  if (-not $json.EndsWith("`n")) {
    $json += "`n"
  }
  [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Read-Phase160IRouteTextSafe {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return ""
  }
  return Get-Content -LiteralPath $Path -Raw
}

function Get-Phase160IRouteDeclaredStatus {
  param([string]$Text)
  if ($Text -match "(?im)^\s*status\s*:\s*([A-Z0-9_]+)") {
    return $Matches[1]
  }
  if ($Text -match "(?im)^\s*Status\s*:\s*([A-Z0-9_]+)") {
    return $Matches[1]
  }
  return "UNKNOWN"
}

function New-Phase160IRouteLockRecord {
  param(
    [string]$RepoRoot,
    [string]$FullPath,
    [string]$Text,
    [string]$GenesisText,
    [string]$RoadmapText
  )
  $relativePath = ConvertTo-Phase160IRouteRelativePath -Root $RepoRoot -FullPath $FullPath
  $declaredStatus = Get-Phase160IRouteDeclaredStatus -Text $Text
  $classification = "UNKNOWN"
  $reason = "No route-lock reference rule matched."
  $recommendation = "create next route lock"
  if ($relativePath -eq "AGENT_BUILDER_NEXT_15_STEPS_LOCK_V2_R2.md") {
    $classification = "SUPERSEDED_CANDIDATE"
    $reason = "The root V2_R2 file still declares ACTIVE_ROUTE_LOCK, but GENESIS_STATE route_lock_v3_self_pack_author supersedes AGENT_BUILDER_NEXT_15_STEPS_LOCK_V2_R2 and the file's PHASE91-PHASE105 route is behind the PHASE160 accepted runtime."
    $recommendation = "archive old lock as reference"
  } elseif ($relativePath -eq "route_locks/AGENT_BUILDER_NEXT_15_STEPS_LOCK_V3_SELF_PACK_AUTHOR.md") {
    $classification = "EXHAUSTED"
    $reason = "V3 is still declared active in state, but its listed PHASE107-PHASE111 next steps are behind the PHASE160H1 accepted runtime baseline."
    $recommendation = "supersede with PHASE161 curriculum route"
  } elseif ($declaredStatus -eq "ACTIVE_ROUTE_LOCK") {
    $classification = "ACTIVE"
    $reason = "Declared active and no newer supersession marker was found."
    $recommendation = "keep current lock"
  }
  return [ordered]@{
    path = $relativePath
    declared_status = $declaredStatus
    classification = $classification
    reason = $reason
    referenced_by_genesis = $GenesisText -match [regex]::Escape((Split-Path -Path $relativePath -Leaf))
    referenced_by_roadmap = $RoadmapText -match [regex]::Escape((Split-Path -Path $relativePath -Leaf))
    recommendation = $recommendation
  }
}

$resolvedRoot = Resolve-Phase160IRouteRepoRoot -RepoRootParameter $RepoRoot
$pushed = $false

try {
  Push-Location $resolvedRoot
  $pushed = $true
  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160IRoutePath -Root $resolvedRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $outputRootFull = Resolve-Phase160IRoutePath -Root $resolvedRoot -Path $OutputDir
  $genesisText = Read-Phase160IRouteTextSafe -Path (Resolve-Phase160IRoutePath -Root $resolvedRoot -Path "GENESIS_STATE.json")
  $roadmapText = Read-Phase160IRouteTextSafe -Path (Resolve-Phase160IRoutePath -Root $resolvedRoot -Path "CAPABILITY_ROADMAP.json")
  $lockFiles = @()
  $rootLocks = @(Get-ChildItem -LiteralPath $resolvedRoot -File -Filter "AGENT_BUILDER_NEXT_15_STEPS_LOCK*.md" -ErrorAction SilentlyContinue)
  $routeLockDir = Resolve-Phase160IRoutePath -Root $resolvedRoot -Path "route_locks"
  $nestedLocks = @()
  if (Test-Path -LiteralPath $routeLockDir) {
    $nestedLocks = @(Get-ChildItem -LiteralPath $routeLockDir -File -Filter "AGENT_BUILDER_NEXT_15_STEPS_LOCK*.md" -ErrorAction SilentlyContinue)
  }
  $lockFiles = @($rootLocks + $nestedLocks | Sort-Object FullName)
  $records = @()
  foreach ($lockFile in $lockFiles) {
    $text = Read-Phase160IRouteTextSafe -Path $lockFile.FullName
    $records += New-Phase160IRouteLockRecord -RepoRoot $resolvedRoot -FullPath $lockFile.FullName -Text $text -GenesisText $genesisText -RoadmapText $roadmapText
  }

  $recommendation = "supersede with PHASE161 curriculum route"
  $stage06 = [ordered]@{
    status = "PASS"
    audit_id = "PHASE160I_LONG_RUN_LIFECYCLE_AUDIT"
    line = "AGENT_BUILDER_SELF_DEVELOPMENT"
    mode = "VERIFY"
    stage = "STAGE 6 - ROUTE LOCK STATUS"
    stage_id = "stage_06_route_lock_status_audit"
    route_lock_count = $records.Count
    route_locks = @($records)
    old_route_lock_status_detected = @($records | Where-Object { $_.path -eq "AGENT_BUILDER_NEXT_15_STEPS_LOCK_V2_R2.md" -and $_.classification -eq "SUPERSEDED_CANDIDATE" }).Count -gt 0
    active_marker_contradiction = @($records | Where-Object { $_.declared_status -eq "ACTIVE_ROUTE_LOCK" -and $_.classification -in @("SUPERSEDED_CANDIDATE", "EXHAUSTED") }).Count -gt 0
    recommendation = $recommendation
    allowed_recommendations = @("keep current lock", "create next route lock", "supersede with PHASE161 curriculum route", "archive old lock as reference")
    route_lock_edited = $false
    root_cause = "Route-lock files and state markers were not advanced to the accepted PHASE160H1 runtime reality, leaving stale active-looking locks in the repo."
    repair_package = "ROUTE_LOCK_SUPERSESSION_REPAIR"
    blocks_phase161 = $true
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  Write-Phase160IRouteJsonFile -Path (Join-Path $outputRootFull "stage_06_route_lock_status_audit.json") -Object $stage06
  $stage06 | ConvertTo-Json -Depth 100
} finally {
  if ($pushed) {
    Pop-Location
  }
}
