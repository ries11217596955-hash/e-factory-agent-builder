param([string]$ReviewPath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_CYCLE_V1_REVIEW.json')
$ErrorActionPreference='Stop'
function Assert($Cond,[string]$Msg){ if(-not $Cond){ throw $Msg } }
function HasText($x){ return -not [string]::IsNullOrWhiteSpace([string]$x) }
Assert (Test-Path $ReviewPath) "REVIEW_MISSING=$ReviewPath"
$R=Get-Content $ReviewPath -Raw | ConvertFrom-Json
Assert ($R.schema -eq 'real_delta_school_cycle_v1_review') 'SCHEMA_MISMATCH'
Assert ($R.status -eq 'PASS_WITH_LIMITATIONS') 'STATUS_MISMATCH'
Assert ($R.review_label -eq 'HELD_OUT_TRANSFER_REVIEW_PASS_NOT_RUNTIME_PROOF') 'REVIEW_LABEL_MISMATCH'
Assert ($R.runtime_ready -eq $false) 'RUNTIME_READY_OVERCLAIM'
Assert (HasText $R.limitation) 'LIMITATION_MISSING'
Assert ($R.limitation -match 'lab harness') 'LIMITATION_NOT_LAB_HARNESS'
Assert ([int]$R.heldout_case_count -eq 3) 'HELDOUT_COUNT_NOT_3'
Assert ([int]$R.heldout_pass_count -eq 3) 'HELDOUT_PASS_COUNT_NOT_3'
$cases=@($R.heldout_results)
foreach($c in $cases){
  Assert (HasText $c.case_id) 'HELDOUT_CASE_ID_MISSING'
  Assert ([int]$c.after_score -gt [int]$c.before_score) "HELDOUT_NOT_IMPROVED=$($c.case_id)"
  Assert ([bool]$c.required_atoms_found -eq $true) "HELDOUT_REQUIRED_ATOMS_MISSING=$($c.case_id)"
  Assert ([bool]$c.direct_answer_leakage_detected -eq $false) "HELDOUT_LEAKAGE=$($c.case_id)"
  Assert ([bool]$c.passed -eq $true) "HELDOUT_NOT_PASSED=$($c.case_id)"
}
$names=@($cases | ForEach-Object { $_.case_id })
foreach($need in @('heldout.01.quarantine_school_candidate','heldout.02.million_atom_map_pressure','heldout.03_live_lab_claim_boundary')){ Assert ($names -contains $need) "HELDOUT_CASE_MISSING=$need" }
$tests=@($R.negative_review_tests)
foreach($n in @('answer_leakage_trap','heldout_without_required_atoms','map_atom_explosion_trap')){
  $t=@($tests | Where-Object { $_.name -eq $n })
  Assert ($t.Count -eq 1) "NEGATIVE_REVIEW_TEST_MISSING=$n"
  Assert ($t[0].actual -eq 'BLOCKED') "NEGATIVE_REVIEW_NOT_BLOCKED=$n"
}
Assert ($R.map_atom_scale_policy.atom_level_updates_allowed -eq $false) 'ATOM_LEVEL_UPDATES_ALLOWED'
Assert ($R.map_atom_scale_policy.subchunk_level_updates_allowed -eq $false) 'SUBCHUNK_LEVEL_UPDATES_ALLOWED'
$roll=@($R.map_atom_scale_policy.rollup_levels)
foreach($lvl in @('chunk','batch','capability','module','organ','system')){ Assert ($roll -contains $lvl) "ROLLUP_LEVEL_MISSING=$lvl" }
Assert (@($R.protected_hashes.changed).Count -eq 0) 'PROTECTED_HASH_CHANGED'
Write-Host 'VALIDATION_PASS=REAL_DELTA_SCHOOL_CYCLE_V1_REVIEW_VALID'
Write-Host "REVIEW_PATH=$ReviewPath"
Write-Host "HELDOUT_PASS_COUNT=$($R.heldout_pass_count)/$($R.heldout_case_count)"
Write-Host 'RUNTIME_READY=false'
