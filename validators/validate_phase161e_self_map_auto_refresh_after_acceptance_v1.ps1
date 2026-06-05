param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$AcceptedSubjectHead = 'a8f72a12ee931da0a8146da40259c38b3ea65438'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Assert-Phase161E {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Write-Phase161EJson {
  param([string]$Path, $Value, [int]$Depth = 30)
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
  $Value | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Test-Phase161EParser {
  param([string]$Path)
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errors) | Out-Null
  if ($errors -and $errors.Count -gt 0) {
    throw ("Parser failed for {0}: {1}" -f $Path, (($errors | ForEach-Object { $_.Message }) -join '; '))
  }
}

try {
  $root = (Resolve-Path $RepoRoot).Path
  $requiredRoot = @(
    'CAPABILITY_ROADMAP.json',
    'GENESIS_STATE.json',
    'TASK_QUEUE.json',
    'packs/registry.json',
    'orchestrator/run.ps1'
  )
  foreach ($file in $requiredRoot) {
    Assert-Phase161E (Test-Path -LiteralPath (Join-Path $root $file)) "Root guard missing $file"
  }

  $branchBefore = (git -C $root branch --show-current).Trim()
  $headBefore = (git -C $root rev-parse HEAD).Trim()
  Assert-Phase161E ($headBefore -eq $AcceptedSubjectHead) "HEAD does not match accepted subject head $AcceptedSubjectHead"
  Assert-Phase161E (Test-Path -LiteralPath (Join-Path $root 'reports/self_development/PHASE161E_EXECUTION_PLAN.md')) 'PHASE161E execution plan missing'

  $parserFiles = @(
    'modules/build_builder_agent_body_map_001.ps1',
    'modules/invoke_builder_self_map_refresh_after_acceptance_001.ps1',
    'modules/inspect_builder_self_map_refresh_readiness_001.ps1',
    'modules/write_builder_self_map_memory_report_001.ps1',
    'modules/build_builder_accepted_change_memory_snapshot_001.ps1',
    'modules/validate_builder_acceptance_self_map_refresh_contract_001.ps1',
    'validators/validate_phase161e_self_map_auto_refresh_after_acceptance_v1.ps1'
  )
  foreach ($file in $parserFiles) {
    Test-Phase161EParser -Path (Join-Path $root $file)
  }

  $refreshModule = Join-Path $root 'modules/invoke_builder_self_map_refresh_after_acceptance_001.ps1'
  $refreshResult = & $refreshModule -AcceptedSubjectHead $AcceptedSubjectHead -AcceptedPhase 'PHASE161E_SELF_MAP_AUTO_REFRESH_AFTER_ACCEPTED_CHANGE' -TriggerReason 'validator_acceptance_memory_refresh' -RepoRoot $root
  Assert-Phase161E ($refreshResult.map_refresh_status -eq 'SELF_KNOWLEDGE_READY') 'Refresh module did not produce SELF_KNOWLEDGE_READY'
  Assert-Phase161E ([bool]$refreshResult.self_knowledge_ready) 'Refresh module did not set self_knowledge_ready'
  Assert-Phase161E ([bool]$refreshResult.map_is_ready_for_next_decision) 'Refresh module did not set next decision readiness'

  $contractModule = Join-Path $root 'modules/validate_builder_acceptance_self_map_refresh_contract_001.ps1'
  $contract = & $contractModule -RepoRoot $root
  Assert-Phase161E ($contract.result -eq 'PASS') 'Acceptance self-map refresh contract failed'

  $policyPath = Join-Path $root 'reports/self_development/self_map_refresh_policy.json'
  $resultPath = Join-Path $root 'reports/self_development/self_map_refresh_after_acceptance_result.json'
  $activePath = Join-Path $root 'reports/self_development/SELF_MODEL_ACTIVE_MAP.json'
  $reportPath = Join-Path $root 'reports/self_development/self_map_memory_report.md'
  $snapshotPath = Join-Path $root 'reports/self_development/accepted_change_memory_snapshot.json'
  $liveIndexPath = Join-Path $root 'reports/self_development/live_evidence_separation_index.json'
  $gapPath = Join-Path $root 'reports/self_development/self_model_gap_chain.json'
  $hardeningPath = Join-Path $root 'reports/self_development/agent_body_map_classifier_hardening_result.json'

  foreach ($path in @($policyPath,$resultPath,$activePath,$reportPath,$snapshotPath,$liveIndexPath,$gapPath,$hardeningPath)) {
    Assert-Phase161E (Test-Path -LiteralPath $path) "Required refresh artifact missing: $path"
  }

  $policy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
  $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
  $activeMap = Get-Content -LiteralPath $activePath -Raw | ConvertFrom-Json
  $snapshot = Get-Content -LiteralPath $snapshotPath -Raw | ConvertFrom-Json
  $liveIndex = Get-Content -LiteralPath $liveIndexPath -Raw | ConvertFrom-Json
  $gaps = Get-Content -LiteralPath $gapPath -Raw | ConvertFrom-Json
  $hardening = Get-Content -LiteralPath $hardeningPath -Raw | ConvertFrom-Json
  $memoryText = Get-Content -LiteralPath $reportPath -Raw

  Assert-Phase161E ($policy.required_after_accepted_commit -eq $true) 'Refresh policy missing required_after_accepted_commit=true'
  Assert-Phase161E ($policy.passive_stale_allowed -eq $false) 'Refresh policy allows passive stale'
  Assert-Phase161E ($result.accepted_subject_head -eq $AcceptedSubjectHead) 'Result accepted_subject_head mismatch'
  Assert-Phase161E ($activeMap.accepted_subject_head -eq $AcceptedSubjectHead) 'Active map accepted_subject_head mismatch'
  Assert-Phase161E ($activeMap.classifier_version -match 'PHASE161D') 'Classifier version no longer includes PHASE161D'
  Assert-Phase161E ($activeMap.map_refresh_status -eq 'SELF_KNOWLEDGE_READY') 'Active map not SELF_KNOWLEDGE_READY'
  Assert-Phase161E ([bool]$activeMap.self_knowledge_ready) 'Active map self_knowledge_ready false'
  Assert-Phase161E ([bool]$activeMap.map_is_ready_for_next_decision) 'Active map next decision readiness false'
  Assert-Phase161E ($memoryText -match 'I remember myself') 'Memory report missing required phrase'
  Assert-Phase161E ($snapshot.next_decision_allowed -eq $true) 'Accepted change memory snapshot does not allow next decision'
  Assert-Phase161E ($liveIndex.classifier_version -match 'PHASE161D') 'Live evidence separation was not preserved'
  Assert-Phase161E (@($gaps.gaps).Count -ge 6) 'Gap chains were not preserved'
  Assert-Phase161E ([int]$hardening.active_wired_proven_count -lt 842) 'Active wired proven regressed to old over-optimistic count'
  Assert-Phase161E ($activeMap.map_refresh_status -ne 'STALE') 'Final state is stale'
  Assert-Phase161E ($result.map_refresh_status -ne 'STALE') 'Refresh result is stale'

  $protectedStatus = @(git -C $root status --short -- TASK_QUEUE.json GENESIS_STATE.json CAPABILITY_ROADMAP.json packs/registry.json orchestrator/run.ps1)
  $runtimeStatus = @(git -C $root status --short -- runtime_sessions)
  $branchAfter = (git -C $root branch --show-current).Trim()
  $headAfter = (git -C $root rev-parse HEAD).Trim()
  Assert-Phase161E ($protectedStatus.Count -eq 0) 'Protected state files modified'
  Assert-Phase161E ($runtimeStatus.Count -eq 0) 'runtime_sessions staged or modified'
  Assert-Phase161E ($branchAfter -eq $branchBefore) 'Branch switched during validator'
  Assert-Phase161E ($headAfter -eq $headBefore) 'Commit occurred during validator'

  $proofPath = Join-Path $root 'proofs/self_development/PHASE161E_SELF_MAP_AUTO_REFRESH_PROOF.json'
  $phaseReportPath = Join-Path $root 'reports/self_development/PHASE161E_SELF_MAP_AUTO_REFRESH_REPORT.md'
  $routePath = Join-Path $root 'route_change_requests/PHASE161E_SELF_MAP_AUTO_REFRESH_REQUEST.md'
  $deliveryPath = Join-Path $root 'reports/self_development/PHASE161E_SELF_MAP_AUTO_REFRESH_CODEX_DELIVERY.md'

  $proof = [pscustomobject][ordered]@{
    phase = 'PHASE161E_SELF_MAP_AUTO_REFRESH_AFTER_ACCEPTED_CHANGE_V1'
    validate_result = 'PASS'
    accepted_subject_head = $AcceptedSubjectHead
    branch = $branchBefore
    head_before = $headBefore
    head_after = $headAfter
    refresh_result_path = 'reports/self_development/self_map_refresh_after_acceptance_result.json'
    memory_report_path = 'reports/self_development/self_map_memory_report.md'
    active_wired_proven_count = [int]$hardening.active_wired_proven_count
    present_not_wired_count = [int]$hardening.present_not_wired_count
    historical_reference_count = [int]$result.historical_reference_count
    superseded_count = [int]$hardening.superseded_count
    real_stub_count = [int]$hardening.real_stub_count
    false_positive_stub_count = [int]$hardening.false_positive_stub_count
    gap_chain_count = @($gaps.gaps).Count
    protected_state_mutated = $false
    runtime_outputs_staged = $false
    no_commit_performed = $true
    no_push_performed = $true
    no_branch_switch = $true
    created_at = (Get-Date).ToUniversalTime().ToString('o')
  }
  Write-Phase161EJson -Path $proofPath -Value $proof

  $reportLines = @(
    '# PHASE161E Self-Map Auto Refresh Report',
    '',
    'Result: `PASS`',
    '',
    ('Accepted subject head: `{0}`' -f $AcceptedSubjectHead),
    'Map refresh status: `SELF_KNOWLEDGE_READY`',
    'Self knowledge ready: `True`',
    'Map ready for next decision: `True`',
    '',
    'The validator ran the acceptance refresh module, regenerated the PHASE161D map outputs, wrote the memory report and accepted-change snapshot, and confirmed the final state is not stale.',
    '',
    'Protected state was not modified. `runtime_sessions` was not staged.'
  )
  $reportLines | Set-Content -LiteralPath $phaseReportPath -Encoding UTF8

  $routeLines = @(
    '# PHASE161E Self-Map Auto Refresh Route Change Request',
    '',
    'Requested route: make accepted-change self-map refresh the normal memory cycle before next decision.',
    '',
    'Protected state promotion is not requested in this phase. The derived map remains under `reports/self_development`.'
  )
  $routeLines | Set-Content -LiteralPath $routePath -Encoding UTF8

  $deliveryLines = @(
    '# PHASE161E Self-Map Auto Refresh Codex Delivery',
    '',
    'Root guard: `PASS`',
    'Validator: `PASS`',
    ('Accepted subject head: `{0}`' -f $AcceptedSubjectHead),
    'Refresh result: `reports/self_development/self_map_refresh_after_acceptance_result.json`',
    'Memory report: `reports/self_development/self_map_memory_report.md`',
    'Proof: `proofs/self_development/PHASE161E_SELF_MAP_AUTO_REFRESH_PROOF.json`',
    'Report: `reports/self_development/PHASE161E_SELF_MAP_AUTO_REFRESH_REPORT.md`',
    'Protected state mutated: `False`',
    'Runtime outputs staged: `False`',
    'No commit performed by validator: `True`',
    'No push performed by validator: `True`',
    'Final recommendation: `READY_FOR_OWNER_REVIEW`'
  )
  $deliveryLines | Set-Content -LiteralPath $deliveryPath -Encoding UTF8

  Write-Host 'PHASE161E_SELF_MAP_AUTO_REFRESH_AFTER_ACCEPTED_CHANGE_VALIDATE_RESULT=PASS'
  Write-Host 'EXECUTION_PLAN_CREATED=True'
  Write-Host 'SELF_MAP_REFRESH_MODULE_CREATED=True'
  Write-Host 'SELF_MAP_REFRESH_POLICY_CREATED=True'
  Write-Host 'SELF_MAP_REFRESH_AFTER_ACCEPTANCE_RUN=True'
  Write-Host 'SELF_KNOWLEDGE_READY=True'
  Write-Host 'MAP_READY_FOR_NEXT_DECISION=True'
  Write-Host 'SELF_MAP_MEMORY_REPORT_CREATED=True'
  Write-Host 'ACCEPTED_CHANGE_MEMORY_SNAPSHOT_CREATED=True'
  Write-Host 'SELF_MODEL_ACTIVE_MAP_UPDATED=True'
  Write-Host 'LIVE_EVIDENCE_SEPARATION_PRESERVED=True'
  Write-Host 'GAP_CHAINS_PRESERVED=True'
  Write-Host 'NO_PASSIVE_STALE_FINAL_STATE=True'
  Write-Host 'NO_PROTECTED_STATE_MUTATION=True'
  Write-Host 'RUNTIME_OUTPUTS_STAGED=False'
  Write-Host 'NO_COMMIT_PERFORMED=True'
  Write-Host 'NO_PUSH_PERFORMED=True'
  Write-Host 'NO_BRANCH_SWITCH=True'
  Write-Host 'CODEX_DELIVERY_FILE_CREATED=True'
} catch {
  Write-Host 'PHASE161E_SELF_MAP_AUTO_REFRESH_AFTER_ACCEPTED_CHANGE_VALIDATE_RESULT=FAIL'
  Write-Host ("FAIL_REASON={0}" -f $_.Exception.Message)
  exit 1
}
