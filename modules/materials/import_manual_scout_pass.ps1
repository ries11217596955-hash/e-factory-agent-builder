[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$ScoutPassPath,
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
  [switch]$AllowCatalogMutation
)

$ErrorActionPreference = "Stop"

function Join-RepoPath {
  param([string]$Path)

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Get-PropertyValue {
  param(
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object) {
    return $null
  }

  $property = $Object.PSObject.Properties | Where-Object { $_.Name -ieq $Name } | Select-Object -First 1
  if ($null -eq $property) {
    return $null
  }

  return $property.Value
}

function As-Array {
  param([object]$Value)

  if ($null -eq $Value) {
    return @()
  }
  if ($Value -is [System.Array]) {
    return $Value
  }
  return @($Value)
}

if ($AllowCatalogMutation) {
  throw "PHASE80_REQUIRED_FOR_CATALOG_IMPORT"
}

$fullPath = Join-RepoPath $ScoutPassPath
if (-not (Test-Path -LiteralPath $fullPath)) {
  throw "MISSING_MANUAL_SCOUT_PASS=$ScoutPassPath"
}

$scoutPass = Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
$requiredFields = @(
  "scout_pass_id",
  "created_at",
  "created_by",
  "purpose",
  "candidates",
  "cut_list"
)

$missingFields = @()
foreach ($field in $requiredFields) {
  $value = Get-PropertyValue -Object $scoutPass -Name $field
  if ($null -eq $value) {
    $missingFields += $field
  }
}

if (@($missingFields).Count -gt 0) {
  throw "MANUAL_SCOUT_PASS_MISSING_FIELDS=$($missingFields -join ',')"
}

$candidates = As-Array (Get-PropertyValue -Object $scoutPass -Name "candidates")
$result = [ordered]@{
  status = "DRY_RUN_ONLY"
  phase = "PHASE_79"
  candidate_count = @($candidates).Count
  catalog_mutated = $false
  catalog_path = "materials/MATERIAL_CATALOG.json"
  next_allowed_step = "STEP4_MANUAL_SCOUT_PASS_001"
  full_import_phase = "PHASE80"
}

Write-Host "MANUAL_SCOUT_PASS_DRY_RUN=PASS"
Write-Host "MANUAL_SCOUT_PASS_CANDIDATE_COUNT=$($result.candidate_count)"
Write-Host "CATALOG_MUTATED=FALSE"
Write-Host "FULL_IMPORT_BELONGS_TO=PHASE80"

return [pscustomobject]$result
