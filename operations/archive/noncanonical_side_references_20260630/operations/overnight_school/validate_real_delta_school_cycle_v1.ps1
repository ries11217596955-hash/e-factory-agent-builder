param([string]$ProofPath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_CYCLE_V1_PROOF.json')
$ErrorActionPreference='Stop'
function Assert($Cond,[string]$Msg){ if(-not $Cond){ throw $Msg } }
function HasText($x){ return -not [string]::IsNullOrWhiteSpace([string]$x) }
Assert (Test-Path $ProofPath) "PROOF_MISSING=$ProofPath"
$P=Get-Content $ProofPath -Raw | ConvertFrom-Json
Assert ($P.schema -eq 'real_delta_school_cycle_v1') 'SCHEMA_MISMATCH'
Assert ($P.status -eq 'PASS') 'STATUS_NOT_PASS'
Assert ($P.proof_label -eq 'PROVEN_LAB_REAL_DELTA_HARNESS_NOT_RUNTIME_INTELLIGENCE') 'PROOF_LABEL_MISMATCH'
Assert ($P.runtime_ready -eq $false) 'RUNTIME_READY_OVERCLAIM'
Assert ([int]$P.atom_count -eq 5) 'ATOM_COUNT_NOT_5'
Assert ([int]$P.accepted_total -eq 5) 'ACCEPTED_TOTAL_NOT_5'
Assert ([int]$P.rejected_total -eq 0) 'REJECTED_TOTAL_NOT_ZERO'
$domains=@($P.domain_ladder)
Assert (($domains | Select-Object -Unique).Count -eq 5) 'DOMAINS_NOT_DISTINCT'
$levels=@($P.level_ladder | ForEach-Object { [int]$_ })
Assert (($levels -join ',') -eq '1,2,3,4,5') 'LEVEL_LADDER_NOT_INCREASING_1_TO_5'
$atoms=@($P.atoms)
Assert ($atoms.Count -eq 5) 'ATOM_RESULTS_COUNT_NOT_5'
$prev=@()
$lastLevel=0
foreach($A in $atoms){
  Assert (HasText $A.atom_id) 'ATOM_ID_MISSING'
  Assert ([int]$A.level -gt $lastLevel) "ATOM_LEVEL_NOT_INCREASING=$($A.atom_id)"
  $lastLevel=[int]$A.level
  Assert (HasText $A.domain) "DOMAIN_MISSING=$($A.atom_id)"
  Assert (HasText $A.concept) "CONCEPT_MISSING=$($A.atom_id)"
  Assert (HasText $A.useful_for) "USEFUL_FOR_MISSING=$($A.atom_id)"
  Assert (HasText $A.comprehension.explain_back) "COMPREHENSION_EXPLAIN_MISSING=$($A.atom_id)"
  Assert (HasText $A.comprehension.apply) "COMPREHENSION_APPLY_MISSING=$($A.atom_id)"
  Assert (HasText $A.comprehension.anti_apply) "COMPREHENSION_ANTI_APPLY_MISSING=$($A.atom_id)"
  Assert ([bool]$A.comprehension.dependency_satisfied -eq $true) "DEPENDENCY_NOT_SATISFIED=$($A.atom_id)"
  Assert ([int]$A.after_score -gt [int]$A.before_score) "NO_AFTER_IMPROVEMENT=$($A.atom_id)"
  Assert ([bool]$A.improved -eq $true) "IMPROVED_FLAG_FALSE=$($A.atom_id)"
  Assert ([bool]$A.accepted -eq $true) "ATOM_NOT_ACCEPTED=$($A.atom_id)"
  Assert ([bool]$A.retrieval_used -eq $true) "RETRIEVAL_USED_FALSE=$($A.atom_id)"
  Assert ($A.causal_atom_link -eq $A.atom_id) "CAUSAL_LINK_MISMATCH=$($A.atom_id)"
  $deps=@($A.depends_on)
  foreach($d in $deps){ Assert ($prev -contains $d) "DEP_NOT_PREVIOUSLY_ACCEPTED=$($A.atom_id):$d" }
  if([int]$A.level -gt 1){ Assert ($deps.Count -gt 0) "HIGHER_LEVEL_WITHOUT_DEPENDENCY=$($A.atom_id)" }
  $prev += $A.atom_id
}
$cs=@($P.cumulative_scores)
Assert ($cs.Count -eq 5) 'CUMULATIVE_SCORE_COUNT_NOT_5'
$lastScore=-1
$lastAccepted=0
foreach($C in $cs){
  Assert ([int]$C.cumulative_accepted -gt $lastAccepted) 'CUMULATIVE_ACCEPTED_NOT_INCREASING'
  Assert ([int]$C.transfer_score -gt $lastScore) 'TRANSFER_SCORE_NOT_INCREASING'
  $lastAccepted=[int]$C.cumulative_accepted
  $lastScore=[int]$C.transfer_score
}
Assert ([bool]$P.transfer_improved -eq $true) 'TRANSFER_IMPROVED_FALSE'
Assert ([int]$P.after_transfer_exam.score -gt [int]$P.before_transfer_exam.score) 'TRANSFER_SCORE_NOT_IMPROVED'
$used=@($P.after_transfer_exam.used_atom_ids)
foreach($A in $atoms){ Assert ($used -contains $A.atom_id) "TRANSFER_DID_NOT_USE_ATOM=$($A.atom_id)" }
$tests=@($P.negative_tests)
foreach($name in @('count_only_false_pass','synthetic_score_cheat','flat_duplicate_atoms','runtime_ready_overclaim')){
  $t=@($tests | Where-Object { $_.name -eq $name })
  Assert ($t.Count -eq 1) "NEGATIVE_TEST_MISSING=$name"
  Assert ($t[0].expected -eq 'BLOCKED') "NEGATIVE_EXPECTED_NOT_BLOCKED=$name"
  Assert ($t[0].actual -eq 'BLOCKED') "NEGATIVE_ACTUAL_NOT_BLOCKED=$name"
}
Assert ($P.anti_cheat_guards.count_only_blocked -eq $true) 'COUNT_ONLY_GUARD_FALSE'
Assert ($P.anti_cheat_guards.causal_link_required -eq $true) 'CAUSAL_LINK_GUARD_FALSE'
Assert ($P.anti_cheat_guards.retrieval_use_required -eq $true) 'RETRIEVAL_USE_GUARD_FALSE'
Assert ($P.anti_cheat_guards.flat_duplicate_ladder_blocked -eq $true) 'FLAT_DUPLICATE_GUARD_FALSE'
Assert ($P.anti_cheat_guards.runtime_ready_overclaim_blocked -eq $true) 'RUNTIME_READY_GUARD_FALSE'
Assert ($P.map_trigger.attempted -eq $true) 'MAP_TRIGGER_NOT_ATTEMPTED'
Assert ($P.map_trigger.status -eq 'PASS') 'MAP_TRIGGER_NOT_PASS'
Assert ($P.map_trigger.event_type -eq 'proof_created') 'MAP_TRIGGER_EVENT_MISMATCH'
Assert (@($P.protected_hashes.changed).Count -eq 0) 'PROTECTED_HASH_CHANGED'
Write-Host 'VALIDATION_PASS=REAL_DELTA_SCHOOL_CYCLE_V1_VALID'
Write-Host "PROOF_PATH=$ProofPath"
Write-Host "ACCEPTED_TOTAL=$($P.accepted_total)"
Write-Host "BEFORE_TRANSFER_SCORE=$($P.before_transfer_exam.score)"
Write-Host "AFTER_TRANSFER_SCORE=$($P.after_transfer_exam.score)"
Write-Host 'RUNTIME_READY=false'
