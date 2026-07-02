param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputPath = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Write-Json {
  param([string]$Path, [object]$Object)
  $parent = Split-Path -Parent $Path
  if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }
  $json = ($Object | ConvertTo-Json -Depth 80) -replace "`r`n", "`n"
  [System.IO.File]::WriteAllText($Path, $json + "`n", [System.Text.UTF8Encoding]::new($false))
}

function Get-GitStatusRows {
  param([string]$Root)
  $lines = @(& git -C $Root status --porcelain)
  $rows = @()
  foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $status = $line.Substring(0, [Math]::Min(2, $line.Length))
    $path = if ($line.Length -gt 3) { $line.Substring(3) } else { '' }
    $rows += [pscustomobject][ordered]@{
      status = $status
      path = $path
      raw = $line
      untracked = ($status -eq '??')
    }
  }
  return @($rows)
}

function Test-WrapperOwnedPath {
  param([string]$Path)
  return (
    $Path -eq 'modules/invoke_existing_self_map_next_action_selector_readonly_wrapper_v1.ps1' -or
    $Path -eq 'validators/validate_existing_self_map_next_action_selector_readonly_wrapper_v1.ps1' -or
    $Path -like 'reports/existing_self_map_next_action_selector_readonly_wrapper_v1_*'
  )
}

function Get-NonWrapperStatusRows {
  param([string]$Root)
  return @(Get-GitStatusRows -Root $Root | Where-Object { -not (Test-WrapperOwnedPath -Path ([string]$_.path)) })
}

function Get-PropValue {
  param($Object, [string]$Name)
  if ($null -eq $Object) { return $null }
  if ($Object.PSObject.Properties.Name -contains $Name) { return $Object.$Name }
  return $null
}

$root = (Resolve-Path $RepoRoot).Path
$selectorPath = Join-Path $root 'modules/select_builder_self_map_next_action_001.ps1'
$selectorRunnable = Test-Path -LiteralPath $selectorPath -PathType Leaf
$beforeRows = @(Get-NonWrapperStatusRows -Root $root)
$worktreeCleanBefore = ($beforeRows.Count -eq 0)
$selectorExitCode = 1
$selectorOutput = @()
$selectorError = ''
$recommendation = $null
$afterRows = @()
$trackedRows = @()
$untrackedRows = @()
$trackedRolledBack = $false
$worktreeCleanAfter = $false

if ($worktreeCleanBefore -and $selectorRunnable) {
  try {
    $selectorOutput = @(& $selectorPath -RepoRoot $root)
    $selectorExitCode = 0
    if ($selectorOutput.Count -gt 0) {
      $recommendation = $selectorOutput[0]
    }
  } catch {
    $selectorExitCode = 1
    $selectorError = $_.Exception.Message
  }

  $afterRows = @(Get-NonWrapperStatusRows -Root $root)
  $trackedRows = @($afterRows | Where-Object { -not [bool]$_.untracked })
  $untrackedRows = @($afterRows | Where-Object { [bool]$_.untracked })

  if ($trackedRows.Count -gt 0) {
    $trackedPaths = @($trackedRows | ForEach-Object { [string]$_.path } | Select-Object -Unique)
    & git -C $root restore -- $trackedPaths
    if ($LASTEXITCODE -ne 0) {
      throw "GIT_RESTORE_FAILED=$($trackedPaths -join ',')"
    }
    $trackedRolledBack = $true
  } else {
    $trackedRolledBack = $true
  }

  $worktreeCleanAfter = (@(Get-NonWrapperStatusRows -Root $root).Count -eq 0)
}

$selectorOutputCaptured = ($selectorOutput.Count -gt 0 -and $null -ne $recommendation)
$mutationsDetected = ($afterRows.Count -gt 0)
$trackedMutationsDetected = ($trackedRows.Count -gt 0)
$unexpectedUntrackedDetected = ($untrackedRows.Count -gt 0)
$safeForRuntimeHarness = (
  $worktreeCleanBefore -and
  $selectorRunnable -and
  $selectorExitCode -eq 0 -and
  $selectorOutputCaptured -and
  $trackedRolledBack -and
  (-not $unexpectedUntrackedDetected) -and
  $worktreeCleanAfter
)

$result = [ordered]@{
  status = if ($safeForRuntimeHarness) { 'EXISTING_SELECTOR_READONLY_WRAPPER_PASS' } else { 'EXISTING_SELECTOR_READONLY_WRAPPER_FAIL' }
  wrapper_mode = 'read_only_rollback'
  selector_path = 'modules/select_builder_self_map_next_action_001.ps1'
  selector_runnable = [bool]$selectorRunnable
  selector_exit_code = [int]$selectorExitCode
  selector_output_captured = [bool]$selectorOutputCaptured
  recommendation_id = [string](Get-PropValue -Object $recommendation -Name 'recommendation_id')
  selector_version = [string](Get-PropValue -Object $recommendation -Name 'selector_version')
  recommended_next_macro_step = [string](Get-PropValue -Object $recommendation -Name 'recommended_next_macro_step')
  recommended_next_phase_id = [string](Get-PropValue -Object $recommendation -Name 'recommended_next_phase_id')
  next_action_type = [string](Get-PropValue -Object $recommendation -Name 'next_action_type')
  selected_action_score = Get-PropValue -Object $recommendation -Name 'selected_action_score'
  owner_approval_required = Get-PropValue -Object $recommendation -Name 'owner_approval_required'
  mutations_detected = [bool]$mutationsDetected
  tracked_mutations_detected = [bool]$trackedMutationsDetected
  tracked_mutations_rolled_back = [bool]$trackedRolledBack
  unexpected_untracked_mutations_detected = [bool]$unexpectedUntrackedDetected
  worktree_clean_before = [bool]$worktreeCleanBefore
  worktree_clean_after = [bool]$worktreeCleanAfter
  safe_for_runtime_harness = [bool]$safeForRuntimeHarness
  protected_mutation_persisted = $false
  live_patch_done = $false
  codex_used_at_runtime = $false
  commit_done = $false
  push_done = $false
  selector_error = $selectorError
  mutations = @($afterRows)
  unexpected_untracked_mutations = @($untrackedRows)
}

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
  $outputFullPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    [System.IO.Path]::GetFullPath($OutputPath)
  } else {
    [System.IO.Path]::GetFullPath((Join-Path $root $OutputPath))
  }
  Write-Json -Path $outputFullPath -Object $result
}

$result | ConvertTo-Json -Depth 80
