$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$budgets=@(7,23,61)
$results=@()
foreach($b in $budgets){
  $runId="semantic_parametric_proof_$b"
  $out=& operations/school/semantic/run_real_semantic_ladder_school_v1.ps1 -CandidateBudget $b -ChunkSize 11 -RunId $runId -PromoteActive
  $report=Get-Content ".runtime/real_semantic_ladder_school/$runId/run_report.json" -Raw | ConvertFrom-Json
  $ok=($report.status -eq 'PASS_REAL_SEMANTIC_LADDER_SCHOOL_RUN' -and [int]$report.materialized_count -eq $b -and [int]$report.semantic_validated_count -eq $b -and [int]$report.accepted_count -eq $b -and [int]$report.learned_count -eq $b -and $report.auto_accept_by_range -eq $false -and $report.no_magic_n -eq $true -and @($report.accepted_atoms).Count -eq $b)
  $results += [pscustomobject]@{budget=$b; status=if($ok){'PASS'}else{'FAIL'}; materialized=$report.materialized_count; accepted=$report.accepted_count; rejected=$report.rejected_count; learned=$report.learned_count; molecules=$report.molecule_count; candidate_hash_root=$report.candidate_hash_root}
}
# Negative path: one invalid semantic candidate must be rejected, not counted as learned.
$badBudget=29; $badAt=13; $badRun='semantic_negative_rejection_proof'
& operations/school/semantic/run_real_semantic_ladder_school_v1.ps1 -CandidateBudget $badBudget -ChunkSize 11 -RunId $badRun -InjectInvalidAt $badAt -PromoteActive | Out-Host
$bad=Get-Content ".runtime/real_semantic_ladder_school/$badRun/run_report.json" -Raw | ConvertFrom-Json
$badOk=([int]$bad.materialized_count -eq $badBudget -and [int]$bad.accepted_count -eq ($badBudget-1) -and [int]$bad.rejected_count -eq 1 -and [int]$bad.learned_count -eq ($badBudget-1) -and @($bad.rejected_candidates).Count -eq 1)
$decision=& operations/school/semantic/invoke_real_semantic_ladder_decision_v1.ps1 -TaskText 'Use real semantic school proof to make a future behavior decision without full memory scan.' -TopK 4 -AsJson | ConvertFrom-Json
$scriptText=Get-Content operations/school/semantic/run_real_semantic_ladder_school_v1.ps1 -Raw
$autoAcceptPattern=($scriptText -match 'accepted=\(\$End-\$Start\+1\)')
$passCount=@($results | Where-Object {$_.status -eq 'PASS'}).Count
$status=if($passCount -eq $budgets.Count -and $badOk -and $decision.status -eq 'PASS' -and $decision.no_full_scan -eq $true -and -not $autoAcceptPattern){'PASS_REAL_SEMANTIC_LADDER_SCHOOL_V1'}else{'FAIL_REAL_SEMANTIC_LADDER_SCHOOL_V1'}
$cp=Get-Content operations/school/semantic/store/active_real_semantic_ladder_school_v1/active_semantic_checkpoint.json -Raw | ConvertFrom-Json
$report=[pscustomobject]@{schema='real_semantic_ladder_school_validator_v1'; status=$status; runtime_ready=$false; no_magic_n=$true; budgets_tested=@($budgets); parametric_results=@($results); negative_rejection=[pscustomobject]@{status=if($badOk){'PASS'}else{'FAIL'}; budget=$badBudget; invalid_at=$badAt; accepted=$bad.accepted_count; rejected=$bad.rejected_count; learned=$bad.learned_count}; active_checkpoint=[pscustomobject]@{path='operations/school/semantic/store/active_real_semantic_ladder_school_v1/active_semantic_checkpoint.json'; run_id=$cp.run_id; materialized=$cp.materialized_count; accepted=$cp.accepted_count; rejected=$cp.rejected_count; learned=$cp.learned_count; molecule_count=$cp.molecule_count}; decision_sample=[pscustomobject]@{status=$decision.status; atom_count=$decision.atom_count; molecule_count=$decision.molecule_count; first_atom=$decision.atom_ids_used[0]; no_full_scan=$decision.no_full_scan}; auto_accept_by_range_pattern_found=$autoAcceptPattern; corrected_claim='learned=N only when materialized/semantic_validated/accepted/promoted/decision-used chain is complete'}
New-Item -ItemType Directory -Force -Path operations/reports | Out-Null
$utf8NoBom=New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path 'operations/reports/REAL_SEMANTIC_LADDER_SCHOOL_V1.json'),($report|ConvertTo-Json -Depth 40),$utf8NoBom)
$lines=($results|ForEach-Object{"- budget=$($_.budget): $($_.status), materialized=$($_.materialized), accepted=$($_.accepted), learned=$($_.learned), molecules=$($_.molecules)"}) -join "`r`n"
$md=@"
# REAL_SEMANTIC_LADDER_SCHOOL_V1

Status: $status  
Runtime ready: false

## Parametric proof

This validator uses several budgets to prove that N is a run parameter, not architecture.

$lines

## Negative rejection proof

- status: $(if($badOk){'PASS'}else{'FAIL'})
- candidate budget: $badBudget
- invalid position: $badAt
- accepted: $($bad.accepted_count)
- rejected: $($bad.rejected_count)
- learned: $($bad.learned_count)

## Decision-use sample

- status: $($decision.status)
- atoms: $($decision.atom_count)
- molecules: $($decision.molecule_count)
- first atom: $($decision.atom_ids_used[0])
- no_full_scan: $($decision.no_full_scan)

## Boundary

This proves real semantic candidate materialization and validation for N-parametric school runs. It is not autonomous runtime.
"@
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path 'operations/reports/REAL_SEMANTIC_LADDER_SCHOOL_V1.md'),$md,$utf8NoBom)
Write-Host "VALIDATION_STATUS=$status"
Write-Host "PARAMETRIC_PASS_COUNT=$passCount"
Write-Host "NEGATIVE_REJECTION_PASS=$badOk"
Write-Host "DECISION_STATUS=$($decision.status)"
Write-Host "ACTIVE_LEARNED=$($cp.learned_count)"
Write-Host "AUTO_ACCEPT_BY_RANGE_PATTERN_FOUND=$autoAcceptPattern"
Write-Host "RUNTIME_READY=false"
if($status -ne 'PASS_REAL_SEMANTIC_LADDER_SCHOOL_V1'){exit 1}