param(
  [string]$PassportPath='operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_PASSPORT.json',
  [string]$ContractPath='operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_PARAMETRIC_CONTRACT.json',
  [string]$ScanPath='operations/overnight_school/REAL_DELTA_SCHOOL_EXISTING_BODY_SCAN_V1.json'
)
$ErrorActionPreference='Stop'
function Assert($Cond,[string]$Msg){ if(-not $Cond){ throw $Msg } }
function Has($Collection,[string]$Value){ return @($Collection | Where-Object { [string]$_ -eq $Value }).Count -gt 0 }
Assert (Test-Path $PassportPath) "PASSPORT_MISSING=$PassportPath"
Assert (Test-Path $ContractPath) "CONTRACT_MISSING=$ContractPath"
Assert (Test-Path $ScanPath) "SCAN_MISSING=$ScanPath"
$p=Get-Content $PassportPath -Raw | ConvertFrom-Json
$c=Get-Content $ContractPath -Raw | ConvertFrom-Json
$s=Get-Content $ScanPath -Raw | ConvertFrom-Json
Assert ($p.schema -eq 'real_delta_school_organ_v1_passport') 'PASSPORT_SCHEMA_MISMATCH'
Assert ($c.schema -eq 'real_delta_school_organ_v1_parametric_contract') 'CONTRACT_SCHEMA_MISMATCH'
Assert ($p.organ_id -eq 'REAL_DELTA_SCHOOL_ORGAN_V1') 'PASSPORT_ORGAN_ID_MISMATCH'
Assert ($c.organ_id -eq 'REAL_DELTA_SCHOOL_ORGAN_V1') 'CONTRACT_ORGAN_ID_MISMATCH'
Assert ($p.not_new_from_scratch -eq $true) 'PASSPORT_NOT_NEW_FROM_SCRATCH_FALSE'
Assert ($p.assembled_from_scan -eq $ScanPath) 'PASSPORT_SCAN_REF_MISMATCH'
Assert ($c.assembled_from_scan -eq $ScanPath) 'CONTRACT_SCAN_REF_MISMATCH'
Assert ($s.status -eq 'SCAN_COMPLETE_NO_NEW_ORGAN_CREATED') 'SCAN_STATUS_NOT_VALID'
Assert ($p.runtime_ready -eq $false) 'PASSPORT_RUNTIME_READY_OVERCLAIM'
Assert ($c.runtime_ready -eq $false) 'CONTRACT_RUNTIME_READY_OVERCLAIM'
Assert ($p.commit_push_performed -eq $false) 'PASSPORT_COMMIT_PUSH_OVERCLAIM'
Assert ($c.commit_push_performed -eq $false) 'CONTRACT_COMMIT_PUSH_OVERCLAIM'
Assert ($p.authority_boundary.may_mutate_live_runtime -eq $false) 'LIVE_MUTATION_ALLOWED'
Assert ($p.authority_boundary.may_set_runtime_ready_true -eq $false) 'RUNTIME_READY_TRUE_ALLOWED'
Assert ($p.authority_boundary.may_blind_restore_quarantine -eq $false) 'BLIND_QUARANTINE_RESTORE_ALLOWED'
Assert ($p.authority_boundary.may_create_per_number_validators -eq $false) 'PER_NUMBER_VALIDATORS_ALLOWED'
foreach($mode in @('OWNER_SUPPLIED','SELF_PRACTICE_DERIVED','FAILURE_DERIVED','QUARANTINE_DERIVED','REPO_CHANGE_DERIVED')){ Assert (Has (@($p.source_modes | ForEach-Object { $_.mode })) $mode) "SOURCE_MODE_MISSING=$mode" }
foreach($id in @('candidate_intake_contract','phase162_atom_acceptance_gates','phase165_lesson_to_atom_bridge','useful_curriculum_school_supervisor','useful_school_30k_full_process','real_delta_cycle_probe','real_delta_review','self_map_rollup_policy')){ Assert (Has $p.reused_components $id) "REUSED_COMPONENT_MISSING=$id" }
$excluded=@($p.excluded_or_limited_components | ForEach-Object { $_.id })
foreach($id in @('real_delta_scale_gate_50','codex_plan_comprehension_delta','quarantine_comprehension_delta_impl')){ Assert (Has $excluded $id) "EXCLUDED_COMPONENT_MISSING=$id" }
Assert (Has $c.invocation.required_params 'CandidateFeedPath') 'REQUIRED_PARAM_CANDIDATE_FEED_MISSING'
Assert (Has $c.invocation.required_params 'TargetAccepted') 'REQUIRED_PARAM_TARGET_ACCEPTED_MISSING'
foreach($forbidden in @('atom','subchunk')){ Assert (Has $c.invocation.map_aggregation_level_forbidden $forbidden) "FORBIDDEN_MAP_LEVEL_MISSING=$forbidden" }
foreach($allowed in @('chunk','batch','capability','module','organ','system')){ Assert (Has $c.invocation.map_aggregation_level_allowed $allowed) "ALLOWED_MAP_LEVEL_MISSING=$allowed" }
foreach($inv in @('N is parameter, not architecture','No validator per numeric scale','CandidateFeed is external or self-derived input; curriculum orders and tests candidates but does not magically certify them','Accepted atom requires comprehension and after-exam improvement','Causal atom link required','Retrieval/use proof required','Count-only success blocked','Atom/subchunk events do not update map','Lab proof never upgrades to live proof')){ Assert (Has $c.invariants $inv) "INVARIANT_MISSING=$inv" }
foreach($binding in @('candidate_intake','atom_acceptance','lesson_to_atom','school_supervisor_mechanics','real_delta_invariant_probe','heldout_review','map_rollup')){ Assert ($c.reuse_bindings.PSObject.Properties.Name -contains $binding) "REUSE_BINDING_MISSING=$binding" }
Assert ($c.proof_status -eq 'CONTRACT_DEFINED_NOT_RUNNER_IMPLEMENTED') 'CONTRACT_PROOF_STATUS_MISMATCH'
Write-Host 'VALIDATION_PASS=REAL_DELTA_SCHOOL_ORGAN_V1_PASSPORT_CONTRACT_VALID'
Write-Host "PASSPORT_PATH=$PassportPath"
Write-Host "CONTRACT_PATH=$ContractPath"
Write-Host 'RUNTIME_READY=false'
