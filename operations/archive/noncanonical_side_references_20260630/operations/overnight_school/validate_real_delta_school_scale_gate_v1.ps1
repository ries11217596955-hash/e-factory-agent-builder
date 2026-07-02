param([string]$GatePath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_SCALE_GATE_V1.json')
$ErrorActionPreference='Stop'
function Assert($Cond,[string]$Msg){ if(-not $Cond){ throw $Msg } }
function HasText($x){ return -not [string]::IsNullOrWhiteSpace([string]$x) }
Assert (Test-Path $GatePath) "GATE_MISSING=$GatePath"
$G=Get-Content $GatePath -Raw | ConvertFrom-Json
Assert ($G.schema -eq 'real_delta_school_scale_gate_v1') 'SCHEMA_MISMATCH'
Assert ($G.status -eq 'PASS_NEXT_SCALE_ALLOWED_TO_50_ONLY') 'STATUS_NOT_PASS_TO_50_ONLY'
Assert ($G.decision -eq 'ALLOW_DESIGN_FOR_50_REAL_DELTA_LADDER_NOT_EXECUTE_30K') 'DECISION_MISMATCH'
Assert ($G.runtime_ready -eq $false) 'RUNTIME_READY_OVERCLAIM'
Assert ($G.proof_label -eq 'SCALE_GATE_PASS_NOT_SCALE_PROOF') 'PROOF_LABEL_MISMATCH'
Assert ($G.current_limit -match 'Do not run 30K') 'LIMIT_DOES_NOT_BLOCK_30K'
$checks=$G.gate_checks
foreach($name in @('base_real_delta_valid','review_valid','distinct_domains','increasing_levels','no_atom_map_updates','count_only_blocked','causal_link_required','retrieval_use_required')){
  Assert ($checks.$name -eq $true) "GATE_CHECK_FALSE=$name"
}
$blocked=@($G.blocked_paths)
foreach($path in @('jump_to_30000_or_300000','flat_50_atoms_same_domain','map_update_per_atom','runtime_ready_promotion','quarantine_blind_restore')){
  $b=@($blocked | Where-Object { $_.path -eq $path })
  Assert ($b.Count -eq 1) "BLOCKED_PATH_MISSING=$path"
  Assert ($b[0].decision -eq 'BLOCKED') "BLOCKED_PATH_NOT_BLOCKED=$path"
  Assert (HasText $b[0].reason) "BLOCKED_REASON_MISSING=$path"
}
$bp=@($G.next_50_blueprint)
Assert ($bp.Count -eq 6) 'BLUEPRINT_BAND_COUNT_NOT_6'
Assert ([int]$G.next_50_total -eq 50) 'NEXT_50_TOTAL_NOT_50'
$lastHasDeps=$false
foreach($band in $bp){
  Assert (HasText $band.band) 'BAND_NAME_MISSING'
  Assert ([int]$band.size -gt 0) "BAND_SIZE_INVALID=$($band.band)"
  Assert (HasText $band.purpose) "BAND_PURPOSE_MISSING=$($band.band)"
  if(@($band.requires_previous).Count -gt 0){ $lastHasDeps=$true }
}
Assert ($lastHasDeps -eq $true) 'BLUEPRINT_HAS_NO_DEPENDENCY_LADDER'
$gates=@($G.required_next_validator_gates)
foreach($need in @('band diversity','dependency ladder','comprehension per accepted atom','held-out transfer cases','negative false-pass traps','map rollup only','runtime_ready false','protected hashes unchanged')){ Assert ($gates -contains $need) "NEXT_VALIDATOR_GATE_MISSING=$need" }
Assert ($G.map_policy -match 'not atom/subchunk events') 'MAP_POLICY_NOT_ATOM_SAFE'
Assert (@($G.protected_hashes.changed).Count -eq 0) 'PROTECTED_HASH_CHANGED'
Write-Host 'VALIDATION_PASS=REAL_DELTA_SCHOOL_SCALE_GATE_V1_VALID'
Write-Host "GATE_PATH=$GatePath"
Write-Host "STATUS=$($G.status)"
Write-Host "NEXT_50_TOTAL=$($G.next_50_total)"
Write-Host 'RUNTIME_READY=false'
