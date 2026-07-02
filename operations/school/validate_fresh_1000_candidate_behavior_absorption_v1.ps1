$ErrorActionPreference = "Stop"
$repoRoot = (git rev-parse --show-toplevel).Trim()
Set-Location $repoRoot
$proofPath = "operations/reports/FRESH_1000_CANDIDATE_BEHAVIOR_ABSORPTION_V1.json"
if (-not (Test-Path $proofPath)) { throw "PROOF_MISSING" }
$p = Get-Content $proofPath -Raw | ConvertFrom-Json
if ($p.schema -ne "fresh_1000_candidate_behavior_absorption_v1") { throw "BAD_SCHEMA" }
if ($p.status -ne "PASS_FRESH_1000_BEHAVIOR_ABSORPTION_LAB") { throw "BAD_STATUS=$($p.status)" }
if ($p.runtime_ready -ne $false) { throw "RUNTIME_READY_OVERCLAIM" }
if ($p.source_material -ne "fresh_generated_only_no_old_candidates") { throw "OLD_MATERIAL_USED" }
if ([int]$p.candidate_count -ne 1000) { throw "BAD_CANDIDATE_COUNT" }
if ([int]$p.accepted_count -ne 1000) { throw "BAD_ACCEPTED_COUNT" }
if ([int]$p.rejected_count -ne 0) { throw "REJECTED_NOT_ZERO" }
$expected = @(10,100,500,700,1000)
foreach ($e in $expected) {
    $r = @($p.checkpoint_results | Where-Object { [int]$_.checkpoint -eq $e })
    if ($r.Count -ne 1) { throw "MISSING_CHECKPOINT_$e" }
    if ($r[0].status -ne "PASS") { throw "CHECKPOINT_FAIL_$e" }
    if ([int]$r[0].retrieval_count -ne $e) { throw "RETRIEVAL_COUNT_$e" }
    if ([int]$r[0].behavior_delta_count -ne $e) { throw "BEHAVIOR_DELTA_COUNT_$e" }
    if ([int]$r[0].unique_atom_id_used_count -ne $e) { throw "UNIQUE_USED_COUNT_$e" }
}
if ($null -ne $p.first_failure) { throw "FIRST_FAILURE_NOT_NULL" }
if ([bool]$p.runtime_pruned_after_success -ne $true) { throw "RUNTIME_NOT_PRUNED" }
if ([bool]$p.protected_active_surfaces_unchanged -ne $true) { throw "PROTECTED_SURFACES_CHANGED" }
if ([int]$p.protected_git_status_count -ne 0) { throw "PROTECTED_STATUS_DIRTY" }
if ([int]$p.max_record_bytes -gt 7000) { throw "RECORD_TOO_LARGE" }
if ([int64]$p.runtime_bytes_before_prune -gt 5000000) { throw "RUNTIME_TOO_LARGE" }
Write-Host "VALIDATION_PASS=FRESH_1000_CANDIDATE_BEHAVIOR_ABSORPTION_V1"
Write-Host "CANDIDATE_COUNT=$($p.candidate_count)"
Write-Host "ACCEPTED_COUNT=$($p.accepted_count)"
Write-Host "FINAL_UNIQUE_ATOM_ID_USED_COUNT=$($p.final_unique_atom_id_used_count)"
Write-Host "RUNTIME_BYTES_BEFORE_PRUNE=$($p.runtime_bytes_before_prune)"
Write-Host "RUNTIME_PRUNED=$($p.runtime_pruned_after_success)"
Write-Host "RUNTIME_READY=false"