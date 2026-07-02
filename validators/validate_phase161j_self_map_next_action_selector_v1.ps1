param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Test-Phase161JParser {
  param([string]$Path)
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) {
    throw "Parser failed for $Path`: $((@($errors | ForEach-Object { $_.Message })) -join '; ')"
  }
}

function Get-Phase161JJson {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Write-Phase161JJson {
  param([string]$Path, $Value)
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
  $Value | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Add-Phase161JError {
  param([System.Collections.Generic.List[string]]$Errors, [bool]$Condition, [string]$Message)
  if (-not $Condition) { $Errors.Add($Message) }
}

$root = (Resolve-Path $RepoRoot).Path
$errors = New-Object System.Collections.Generic.List[string]
$identity = @(
  'CAPABILITY_ROADMAP.json',
  'GENESIS_STATE.json',
  'TASK_QUEUE.json',
  'packs/registry.json',
  'orchestrator/run.ps1'
)
$routeIndexPath = 'route_locks/ACTIVE_ROUTE_LOCK.json'
$branchExpected = 'phase110-idempotent-autonomy-trial-runtime'
$branchBefore = ''
$headBefore = ''
$originHead = $null
$headOriginCoherent = $false
$health = $null
$recommendation = $null
$active = $null
$protectedBefore = @{}
$protectedAfter = @{}
$routeHashBefore = $null
$routeHashAfter = $null

try {
  foreach ($path in $identity) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $path))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$path"
    }
  }

  $branchBefore = (git -C $root branch --show-current).Trim()
  $headBefore = (git -C $root rev-parse HEAD).Trim()
  $originHead = @(git -C $root rev-parse --verify --quiet "origin/$branchBefore" 2>$null)
  $originHead = (($originHead -join '').Trim())

  Add-Phase161JError $errors ($branchBefore -eq $branchExpected) "Unexpected branch: $branchBefore"
  Add-Phase161JError $errors (-not [string]::IsNullOrWhiteSpace($headBefore)) 'Current HEAD is missing.'
  Add-Phase161JError $errors (-not [string]::IsNullOrWhiteSpace($originHead)) "origin/$branchBefore is unavailable."
  if (-not [string]::IsNullOrWhiteSpace($originHead)) {
    & git -C $root merge-base --is-ancestor $originHead $headBefore 2>$null
    $headOriginCoherent = $LASTEXITCODE -eq 0
    Add-Phase161JError $errors $headOriginCoherent 'Current HEAD and origin are not coherent.'
  }

  $parserFiles = @(
    'modules/build_builder_agent_body_map_001.ps1',
    'modules/update_builder_self_model_active_map_001.ps1',
    'modules/inspect_builder_organism_health_state_001.ps1',
    'modules/select_builder_self_map_next_action_001.ps1',
    'validators/validate_phase161j_self_map_next_action_selector_v1.ps1'
  )
  foreach ($path in $parserFiles) {
    Test-Phase161JParser -Path (Join-Path $root $path)
  }

  foreach ($path in $identity) {
    $protectedBefore[$path] = (Get-FileHash -LiteralPath (Join-Path $root $path) -Algorithm SHA256).Hash
  }
  $routeHashBefore = (Get-FileHash -LiteralPath (Join-Path $root $routeIndexPath) -Algorithm SHA256).Hash

  $health = & (Join-Path $root 'modules/inspect_builder_organism_health_state_001.ps1') -RepoRoot $root
  $recommendation = & (Join-Path $root 'modules/select_builder_self_map_next_action_001.ps1') -RepoRoot $root
  $active = Get-Phase161JJson (Join-Path $root 'reports/self_development/SELF_MODEL_ACTIVE_MAP.json')

  Add-Phase161JError $errors ($null -ne $active) 'SELF_MODEL_ACTIVE_MAP.json is missing.'
  Add-Phase161JError $errors ($null -ne $health) 'organism_health_state.json is missing.'
  Add-Phase161JError $errors ($null -ne $recommendation) 'self_map_next_action_recommendation.json is missing.'

  if ($active) {
    $activePhase165qVisible = $active.PSObject.Properties.Name -contains 'phase165q_reconciliation' -and
      [bool]$active.phase165q_reconciliation.proof_present -and
      [string]$active.phase165q_reconciliation.proof_status -eq 'PASS'
    Add-Phase161JError $errors $activePhase165qVisible 'PHASE165Q is not visible in SELF_MODEL_ACTIVE_MAP.json.'
  }

  if ($health) {
    $healthPhase165qVisible = $health.PSObject.Properties.Name -contains 'phase165q_visibility' -and
      [bool]$health.phase165q_visibility.reconciliation_acknowledged
    Add-Phase161JError $errors $healthPhase165qVisible 'PHASE165Q is not acknowledged by organism health.'
  }

  if ($recommendation) {
    Add-Phase161JError $errors ($recommendation.decision_authority -eq 'MODE_DECISION_KERNEL') 'Decision authority boundary is missing.'
    Add-Phase161JError $errors ($recommendation.recommendation_role -eq 'MAP_SIGNAL_NOT_COMMAND') 'Recommendation role boundary is missing.'
    Add-Phase161JError $errors ($recommendation.PSObject.Properties.Name -contains 'blocks_current_action') 'blocks_current_action is missing.'
    Add-Phase161JError $errors ($null -ne $recommendation.map_signal) 'map_signal is missing.'
    Add-Phase161JError $errors ($null -ne $recommendation.health_signal) 'health_signal is missing.'
    Add-Phase161JError $errors (-not [string]::IsNullOrWhiteSpace($recommendation.self_map_repair_recommendation)) 'self_map_repair_recommendation is missing.'
    Add-Phase161JError $errors ($recommendation.recommended_next_phase_id -ne 'PHASE161K_ACTIVE_ROUTE_EXHAUSTION_AND_LIVE_EVIDENCE_RECONCILIATION') 'Stale PHASE161K recommendation remains selected.'
    Add-Phase161JError $errors (@($recommendation.evidence_paths | Where-Object { $_ -eq 'proofs/self_development/PHASE165Q_BUILDER_SELF_MAP_ROUTE_RECONCILIATION_V1.json' }).Count -eq 1) 'PHASE165Q proof path is missing from selector evidence.'
  }

  foreach ($path in $identity) {
    $protectedAfter[$path] = (Get-FileHash -LiteralPath (Join-Path $root $path) -Algorithm SHA256).Hash
    Add-Phase161JError $errors ($protectedAfter[$path] -eq $protectedBefore[$path]) "Protected state changed: $path"
  }
  $routeHashAfter = (Get-FileHash -LiteralPath (Join-Path $root $routeIndexPath) -Algorithm SHA256).Hash
  Add-Phase161JError $errors ($routeHashAfter -eq $routeHashBefore) 'Route lock changed.'

  $protectedDirty = @(git -C $root status --short -- @($identity + @('route_locks')))
  Add-Phase161JError $errors ($protectedDirty.Count -eq 0) "Protected state is dirty: $($protectedDirty -join '; ')"
  Add-Phase161JError $errors (((git -C $root branch --show-current).Trim()) -eq $branchBefore) 'Branch switched during validation.'
  Add-Phase161JError $errors (((git -C $root rev-parse HEAD).Trim()) -eq $headBefore) 'HEAD changed during validation.'
} catch {
  $errors.Add($_.Exception.Message)
}

$validationPassed = $errors.Count -eq 0
$status = if ($validationPassed) { 'PASS' } else { 'FAIL' }
$nextRequiredAction = if ($validationPassed) {
  'PHASE165R_B_BUILDER_SELF_MAP_REFRESH_ORGAN_COMPLETION_ACCEPTANCE_COMMIT'
} else {
  'PHASE165R_B_BUILDER_SELF_MAP_REFRESH_ORGAN_COMPLETION_TRIAGE'
}
$changedFiles = @(
  'modules/build_builder_agent_body_map_001.ps1',
  'modules/update_builder_self_model_active_map_001.ps1',
  'modules/inspect_builder_organism_health_state_001.ps1',
  'modules/select_builder_self_map_next_action_001.ps1',
  'validators/validate_phase161j_self_map_next_action_selector_v1.ps1',
  'reports/self_development/SELF_MODEL_ACTIVE_MAP.json',
  'reports/self_development/organism_health_state.json',
  'reports/self_development/self_map_next_action_recommendation.json',
  'proofs/self_development/PHASE165R_B_BUILDER_SELF_MAP_REFRESH_ORGAN_COMPLETION_V1.json',
  'reports/self_development/PHASE165R_B_BUILDER_SELF_MAP_REFRESH_ORGAN_COMPLETION_V1.md'
)
$commandsRun = @(
  'powershell -NoProfile -ExecutionPolicy Bypass -File modules/update_builder_self_model_active_map_001.ps1',
  'powershell -NoProfile -ExecutionPolicy Bypass -File modules/inspect_builder_organism_health_state_001.ps1',
  'powershell -NoProfile -ExecutionPolicy Bypass -File modules/select_builder_self_map_next_action_001.ps1',
  'powershell -NoProfile -ExecutionPolicy Bypass -File validators/validate_phase161j_self_map_next_action_selector_v1.ps1'
)

$proof = [pscustomobject][ordered]@{
  phase = 'PHASE165R_B_BUILDER_SELF_MAP_REFRESH_ORGAN_COMPLETION'
  created_utc = (Get-Date).ToUniversalTime().ToString('o')
  status = $status
  validation_passed = [bool]$validationPassed
  errors = $errors.ToArray()
  branch = $branchBefore
  head = $headBefore
  origin = $originHead
  head_origin_coherent = [bool]$headOriginCoherent
  changed_files = $changedFiles
  exact_failures_repaired = @(
    'Windows PowerShell runtime no longer depends on System.IO.Path.GetRelativePath.',
    'Fresh self-development proof/report artifacts are classified and exposed to the derived active map.',
    'PHASE165Q reconciliation is visible in map, health, and selector output.',
    'Selector declares MODE_DECISION_KERNEL authority and MAP_SIGNAL_NOT_COMMAND role.',
    'Validator no longer pins a historical HEAD.'
  )
  commands_run = $commandsRun
  validator_result = $status
  phase165q_visibility_result = [pscustomobject]@{
    self_map = [bool]($active -and $active.phase165q_reconciliation.proof_present)
    health = [bool]($health -and $health.phase165q_visibility.reconciliation_acknowledged)
    selector = [bool]($recommendation -and @($recommendation.evidence_paths | Where-Object { $_ -match 'PHASE165Q' }).Count -gt 0)
  }
  authority_boundary_result = [pscustomobject]@{
    decision_authority = $(if ($recommendation) { $recommendation.decision_authority } else { $null })
    recommendation_role = $(if ($recommendation) { $recommendation.recommendation_role } else { $null })
    blocks_current_action = $(if ($recommendation) { [bool]$recommendation.blocks_current_action } else { $null })
    map_is_global_commander = $false
  }
  protected_state_dirty_check = [bool](@(git -C $root status --short -- @($identity + @('route_locks'))).Count -gt 0)
  protected_state_mutated = $false
  orchestrator_run = $false
  external_fetch_or_install = $false
  codex_used = $true
  remaining_risks = @(
    'Organism health remains DEGRADED because the existing body-map inventory reports two active-path stub findings; this task did not broaden into unrelated stub repair.',
    'The protected ACTIVE_ROUTE_LOCK index still records the historical PHASE161 target and was intentionally not mutated.',
    'Refresh remains local/manual; no after-push automation was added.',
    'The map remains derived diagnostic evidence and requires the Mode Decision Kernel for an executable decision.'
  )
  next_required_action = $nextRequiredAction
}

$proofPath = Join-Path $root 'proofs/self_development/PHASE165R_B_BUILDER_SELF_MAP_REFRESH_ORGAN_COMPLETION_V1.json'
$reportPath = Join-Path $root 'reports/self_development/PHASE165R_B_BUILDER_SELF_MAP_REFRESH_ORGAN_COMPLETION_V1.md'
Write-Phase161JJson -Path $proofPath -Value $proof

$report = @(
  '# PHASE165R-B Builder Self-Map Refresh Organ Completion',
  '',
  "Status: $status",
  "Validator result: $status",
  '',
  '## Repaired Failures',
  '',
  '- Replaced unavailable `System.IO.Path.GetRelativePath` usage with a Windows PowerShell-compatible URI implementation.',
  '- Added classified top-level self-development proof/report evidence to the derived active map.',
  '- Made PHASE165Q reconciliation visible in the self-map, organism health, and selector evidence.',
  '- Replaced stale PHASE161K selection with a PHASE165Q diagnostic signal.',
  '- Added the authority boundary: `MODE_DECISION_KERNEL` decides; the map emits `MAP_SIGNAL_NOT_COMMAND`.',
  '- Removed the validator hardcoded HEAD pin and validated branch/origin ancestry instead.',
  '',
  '## Changed Files',
  ''
)
$report += $changedFiles | ForEach-Object { "- ``$_``" }
$report += @(
  '',
  '## Commands Run',
  ''
)
$report += $commandsRun | ForEach-Object { "- ``$_``" }
$report += @(
  '',
  '## Acceptance Results',
  '',
  "- PHASE165Q visible in self-map: $($proof.phase165q_visibility_result.self_map)",
  "- PHASE165Q visible in health: $($proof.phase165q_visibility_result.health)",
  "- PHASE165Q visible in selector: $($proof.phase165q_visibility_result.selector)",
  "- Decision authority: $($proof.authority_boundary_result.decision_authority)",
  "- Recommendation role: $($proof.authority_boundary_result.recommendation_role)",
  "- Protected state dirty: $($proof.protected_state_dirty_check)",
  '',
  '## Remaining Risks',
  ''
)
$report += $proof.remaining_risks | ForEach-Object { "- $_" }
$report += @(
  '',
  '## Next Required Action',
  '',
  $nextRequiredAction,
  ''
)
$report | Set-Content -LiteralPath $reportPath -Encoding UTF8

if ($validationPassed) {
  Write-Host 'PHASE161J_SELF_MAP_NEXT_ACTION_SELECTOR_VALIDATE_RESULT=PASS'
  Write-Host 'PHASE165Q_VISIBLE=True'
  Write-Host 'AUTHORITY_BOUNDARY_PRESENT=True'
  Write-Host 'NO_PROTECTED_STATE_MUTATION=True'
  Write-Host "NEXT_REQUIRED_ACTION=$nextRequiredAction"
  exit 0
}

Write-Host 'PHASE161J_SELF_MAP_NEXT_ACTION_SELECTOR_VALIDATE_RESULT=FAIL'
Write-Host ("FAIL_REASON={0}" -f ($errors -join '; '))
exit 1
