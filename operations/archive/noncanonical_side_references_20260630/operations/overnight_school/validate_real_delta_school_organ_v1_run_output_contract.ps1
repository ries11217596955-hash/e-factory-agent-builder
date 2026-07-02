param([string]$ProofPath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_SMALL_PROOF.json')
$ErrorActionPreference='Stop'
function Fail([string]$m){ throw "REAL_DELTA_SCHOOL_ORGAN_V1_RUN_OUTPUT_CONTRACT_INVALID: $m" }
if(-not (Test-Path $ProofPath)){ Fail "PROOF_MISSING=$ProofPath" }
$raw = Get-Content $ProofPath -Raw
if($raw -match '"runtime_ready"\s*:\s*true'){ Fail 'FORBIDDEN_RUNTIME_READY_TRUE_LITERAL' }
$p = $raw | ConvertFrom-Json
if($p.schema -ne 'real_delta_school_organ_v1_small_proof'){ Fail "BAD_SCHEMA=$($p.schema)" }
if($p.status -ne 'PASS'){ Fail "BAD_STATUS=$($p.status)" }
if($p.proof_label -ne 'PROVEN_LAB_PARAMETRIC_ORGAN_STAGE1_NOT_RUNTIME_INTELLIGENCE'){ Fail "BAD_PROOF_LABEL=$($p.proof_label)" }
if($p.runtime_ready -ne $false){ Fail 'runtime_ready must be false' }
if([int]$p.accepted_total -ne [int]$p.run_params.target_accepted){ Fail 'accepted_total != target_accepted' }
if([int]$p.run_params.target_accepted -ge 30000){ Fail 'STAGE1_MUST_NOT_RUN_30K' }
if($p.accepted_core_mutated -ne $false){ Fail 'accepted core mutated' }
if($p.positive_self_map_update_called -ne $false){ Fail 'positive self-map update called' }
if(@($p.protected_hashes.changed).Count -ne 0){ Fail 'protected hashes changed' }
Write-Host 'VALIDATION_PASS=REAL_DELTA_SCHOOL_ORGAN_V1_RUN_OUTPUT_CONTRACT_VALID'
Write-Host "PROOF_PATH=$ProofPath"
Write-Host "ACCEPTED_TOTAL=$($p.accepted_total)"
Write-Host 'RUNTIME_READY=false'
