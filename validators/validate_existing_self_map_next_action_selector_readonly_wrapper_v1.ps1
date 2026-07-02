param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Ensure-Dir {
  param([string]$Path)
  if ($Path -and -not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Read-Json {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { throw "MISSING_FILE=$Path" }
  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Write-Json {
  param([string]$Path, [object]$Object)
  Ensure-Dir (Split-Path -Parent $Path)
  $json = ($Object | ConvertTo-Json -Depth 100) -replace "`r`n", "`n"
  [System.IO.File]::WriteAllText($Path, $json + "`n", [System.Text.UTF8Encoding]::new($false))
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
  $lines = @(& git -C $Root status --porcelain)
  $rows = @()
  foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $path = if ($line.Length -gt 3) { $line.Substring(3) } else { '' }
    if (-not (Test-WrapperOwnedPath -Path $path)) {
      $rows += $line
    }
  }
  return @($rows)
}

function Get-HashSnapshot {
  param([string]$Root, [string[]]$Paths)
  $snapshot = [ordered]@{}
  foreach ($rel in $Paths) {
    $full = Join-Path $Root $rel
    if (Test-Path -LiteralPath $full -PathType Leaf) {
      $snapshot[$rel] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    } else {
      $snapshot[$rel] = 'ABSENT'
    }
  }
  return $snapshot
}

function Test-SnapshotUnchanged {
  param($Before, $After, [string[]]$Paths)
  foreach ($rel in $Paths) {
    if ([string]$Before[$rel] -ne [string]$After[$rel]) { return $false }
  }
  return $true
}

function Add-Check {
  param([string]$Name, [bool]$Pass, [string]$Detail)
  $script:checks += [ordered]@{
    name = $Name
    status = if ($Pass) { 'PASS' } else { 'FAIL' }
    detail = $Detail
  }
}

$root = (Resolve-Path $RepoRoot).Path
$preExistingDirty = @(Get-NonWrapperStatusRows -Root $root)
if ($preExistingDirty.Count -gt 0) {
  throw "VALIDATION_REQUIRES_CLEAN_WORKTREE dirty=$($preExistingDirty -join '; ')"
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outputDir = Join-Path $root "reports/existing_self_map_next_action_selector_readonly_wrapper_v1_$timestamp"
$wrapperOutputPath = Join-Path $outputDir 'EXISTING_SELF_MAP_NEXT_ACTION_SELECTOR_READONLY_WRAPPER_RESULT.json'
$proofPath = Join-Path $outputDir 'EXISTING_SELF_MAP_NEXT_ACTION_SELECTOR_READONLY_WRAPPER_PROOF.json'
$reportPath = Join-Path $outputDir 'EXISTING_SELF_MAP_NEXT_ACTION_SELECTOR_READONLY_WRAPPER_REPORT.md'
$modulePath = Join-Path $root 'modules/invoke_existing_self_map_next_action_selector_readonly_wrapper_v1.ps1'

$protectedPaths = @(
  'packs/registry.json',
  'reports/self_development/SELF_MODEL_ACTIVE_MAP.json',
  'reports/self_development/accepted_change_memory_snapshot.json',
  'TASK_QUEUE.json',
  'CAPABILITY_ROADMAP.json',
  'GENESIS_STATE.json',
  'orchestrator/run.ps1'
)
$protectedBefore = Get-HashSnapshot -Root $root -Paths $protectedPaths

$wrapperJson = & $modulePath -RepoRoot $root -OutputPath $wrapperOutputPath
$wrapperResult = $wrapperJson | ConvertFrom-Json
$writtenWrapperResult = Read-Json $wrapperOutputPath
$checks = @()

Add-Check 'wrapper_status_pass' ([string]$wrapperResult.status -eq 'EXISTING_SELECTOR_READONLY_WRAPPER_PASS') "status=$($wrapperResult.status)"
Add-Check 'selector_runnable_true' ([bool]$wrapperResult.selector_runnable -eq $true) "selector_runnable=$($wrapperResult.selector_runnable)"
Add-Check 'selector_exit_code_zero' ([int]$wrapperResult.selector_exit_code -eq 0) "selector_exit_code=$($wrapperResult.selector_exit_code)"
Add-Check 'selector_output_captured_true' ([bool]$wrapperResult.selector_output_captured -eq $true) "selector_output_captured=$($wrapperResult.selector_output_captured)"
Add-Check 'worktree_clean_before_true' ([bool]$wrapperResult.worktree_clean_before -eq $true) "worktree_clean_before=$($wrapperResult.worktree_clean_before)"
Add-Check 'worktree_clean_after_true' ([bool]$wrapperResult.worktree_clean_after -eq $true) "worktree_clean_after=$($wrapperResult.worktree_clean_after)"
if ([bool]$wrapperResult.tracked_mutations_detected) {
  Add-Check 'tracked_mutations_rolled_back_true_when_detected' ([bool]$wrapperResult.tracked_mutations_rolled_back -eq $true) "tracked_mutations_rolled_back=$($wrapperResult.tracked_mutations_rolled_back)"
} else {
  Add-Check 'tracked_mutations_rolled_back_true_when_detected' $true 'no tracked mutations detected'
}
Add-Check 'unexpected_untracked_mutations_false' ([bool]$wrapperResult.unexpected_untracked_mutations_detected -eq $false) "unexpected_untracked=$($wrapperResult.unexpected_untracked_mutations_detected)"
Add-Check 'safe_for_runtime_harness_true' ([bool]$wrapperResult.safe_for_runtime_harness -eq $true) "safe_for_runtime_harness=$($wrapperResult.safe_for_runtime_harness)"
Add-Check 'protected_mutation_persisted_false' ([bool]$wrapperResult.protected_mutation_persisted -eq $false) "protected_mutation_persisted=$($wrapperResult.protected_mutation_persisted)"
Add-Check 'live_patch_done_false' ([bool]$wrapperResult.live_patch_done -eq $false) "live_patch_done=$($wrapperResult.live_patch_done)"
Add-Check 'codex_used_at_runtime_false' ([bool]$wrapperResult.codex_used_at_runtime -eq $false) "codex_used_at_runtime=$($wrapperResult.codex_used_at_runtime)"
Add-Check 'commit_done_false' ([bool]$wrapperResult.commit_done -eq $false) "commit_done=$($wrapperResult.commit_done)"
Add-Check 'push_done_false' ([bool]$wrapperResult.push_done -eq $false) "push_done=$($wrapperResult.push_done)"
Add-Check 'output_json_written_matches_status' ([string]$writtenWrapperResult.status -eq [string]$wrapperResult.status) "output_path=$wrapperOutputPath"

$protectedAfter = Get-HashSnapshot -Root $root -Paths $protectedPaths
$protectedMutationPersisted = -not (Test-SnapshotUnchanged -Before $protectedBefore -After $protectedAfter -Paths $protectedPaths)
Add-Check 'protected_hashes_unchanged_after_wrapper' (-not $protectedMutationPersisted) 'protected file hashes unchanged after wrapper rollback'

$failed = @($checks | Where-Object { [string]$_.status -eq 'FAIL' })
$status = if ($failed.Count -eq 0) { 'PASS' } else { 'FAIL' }

$proof = [ordered]@{
  schema = 'EXISTING_SELF_MAP_NEXT_ACTION_SELECTOR_READONLY_WRAPPER_PROOF_V1'
  status = $status
  created_at = (Get-Date).ToString('o')
  repo_root = $root
  wrapper_module = $modulePath
  wrapper_output_path = $wrapperOutputPath
  wrapper_result = $wrapperResult
  checks = $checks
  failed_count = $failed.Count
  protected_paths_checked = $protectedPaths
  protected_hashes_before = $protectedBefore
  protected_hashes_after = $protectedAfter
  protected_mutation_persisted = [bool]$protectedMutationPersisted
  live_patch_done = $false
  codex_used_at_runtime = $false
  commit_done = $false
  push_done = $false
}
Write-Json -Path $proofPath -Object $proof

$reportLines = @(
  '# Existing Self-Map Next-Action Selector Readonly Wrapper V1',
  '',
  "Status: $status",
  '',
  '## Wrapper',
  '',
  "- selector_runnable: $($wrapperResult.selector_runnable)",
  "- selector_exit_code: $($wrapperResult.selector_exit_code)",
  "- selector_output_captured: $($wrapperResult.selector_output_captured)",
  "- mutations_detected: $($wrapperResult.mutations_detected)",
  "- tracked_mutations_detected: $($wrapperResult.tracked_mutations_detected)",
  "- tracked_mutations_rolled_back: $($wrapperResult.tracked_mutations_rolled_back)",
  "- unexpected_untracked_mutations_detected: $($wrapperResult.unexpected_untracked_mutations_detected)",
  "- worktree_clean_after: $($wrapperResult.worktree_clean_after)",
  '',
  '## Boundary',
  '',
  '- protected_mutation_persisted: false',
  '- live_patch_done: false',
  '- codex_used_at_runtime: false',
  '- commit_done: false',
  '- push_done: false',
  '',
  '## Outputs',
  '',
  "- proof: $proofPath",
  "- wrapper_result: $wrapperOutputPath"
)
[System.IO.File]::WriteAllText($reportPath, (($reportLines -join "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))

Write-Host "EXISTING_SELECTOR_READONLY_WRAPPER_STATUS=$status"
Write-Host "SELECTOR_RUNNABLE=$(([bool]$wrapperResult.selector_runnable).ToString().ToLowerInvariant())"
Write-Host "SELECTOR_EXIT_CODE=$($wrapperResult.selector_exit_code)"
Write-Host "SELECTOR_OUTPUT_CAPTURED=$(([bool]$wrapperResult.selector_output_captured).ToString().ToLowerInvariant())"
Write-Host "MUTATIONS_DETECTED=$(([bool]$wrapperResult.mutations_detected).ToString().ToLowerInvariant())"
Write-Host "TRACKED_MUTATIONS_ROLLED_BACK=$(([bool]$wrapperResult.tracked_mutations_rolled_back).ToString().ToLowerInvariant())"
Write-Host "UNEXPECTED_UNTRACKED_MUTATIONS_DETECTED=$(([bool]$wrapperResult.unexpected_untracked_mutations_detected).ToString().ToLowerInvariant())"
Write-Host "WORKTREE_CLEAN_AFTER=$(([bool]$wrapperResult.worktree_clean_after).ToString().ToLowerInvariant())"
Write-Host "SAFE_FOR_RUNTIME_HARNESS=$(([bool]$wrapperResult.safe_for_runtime_harness).ToString().ToLowerInvariant())"
Write-Host "PROTECTED_MUTATION_PERSISTED=$(([bool]$protectedMutationPersisted).ToString().ToLowerInvariant())"
Write-Host 'LIVE_PATCH_DONE=false'
Write-Host 'CODEX_USED_AT_RUNTIME=false'
Write-Host 'COMMIT_DONE=false'
Write-Host 'PUSH_DONE=false'
Write-Host "PROOF_PATH=$proofPath"
Write-Host "REPORT_PATH=$reportPath"

if ($status -ne 'PASS') {
  exit 1
}
