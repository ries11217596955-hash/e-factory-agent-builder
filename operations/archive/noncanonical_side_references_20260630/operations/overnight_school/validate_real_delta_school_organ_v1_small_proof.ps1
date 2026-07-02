param(
  [string]$FeedPath='operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_SAMPLE_FEED.json',
  [string]$ProofPath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_SMALL_PROOF.json'
)
$ErrorActionPreference='Stop'
function Fail([string]$m){ throw "REAL_DELTA_SCHOOL_ORGAN_V1_SMALL_PROOF_INVALID: $m" }
& operations/overnight_school/validate_real_delta_school_organ_v1_candidate_feed_contract.ps1 -FeedPath $FeedPath -MinCandidates 1 | Out-Host
& operations/overnight_school/validate_real_delta_school_organ_v1_run_output_contract.ps1 -ProofPath $ProofPath | Out-Host
$raw = Get-Content $ProofPath -Raw
if($raw -match '"runtime_ready"\s*:\s*true'){ Fail 'FORBIDDEN_RUNTIME_READY_TRUE_LITERAL' }
$p = $raw | ConvertFrom-Json
$atoms = @($p.accepted_atoms)
if($atoms.Count -ne [int]$p.accepted_total){ Fail 'accepted atom count mismatch' }
foreach($a in $atoms){
  foreach($r in @('atom_id','domain','concept','useful_for','comprehension','before_score','after_score','improved','causal_atom_link','retrieval_used','accepted')){
    if(-not ($a.PSObject.Properties.Name -contains $r)){ Fail "ATOM_FIELD_MISSING=$r" }
  }
  if([int]$a.after_score -le [int]$a.before_score){ Fail "ATOM_NOT_IMPROVED=$($a.atom_id)" }
  if($a.improved -ne $true){ Fail "ATOM_IMPROVED_FALSE=$($a.atom_id)" }
  if($a.retrieval_used -ne $true){ Fail "ATOM_RETRIEVAL_FALSE=$($a.atom_id)" }
  if($a.causal_atom_link -ne $a.atom_id){ Fail "ATOM_CAUSAL_LINK_BAD=$($a.atom_id)" }
  if($a.accepted -ne $true){ Fail "ATOM_ACCEPTED_FALSE=$($a.atom_id)" }
}
foreach($n in @($p.negative_tests)){
  if($n.actual -ne 'BLOCKED'){ Fail "NEGATIVE_NOT_BLOCKED=$($n.id)" }
}
if($p.map_rollup_policy.atom.should_update -ne $false){ Fail 'ATOM_MAP_UPDATE_NOT_SUPPRESSED' }
if($p.map_rollup_policy.subchunk.should_update -ne $false){ Fail 'SUBCHUNK_MAP_UPDATE_NOT_SUPPRESSED' }
if($p.positive_self_map_update_called -ne $false){ Fail 'POSITIVE_MAP_CALLED' }
if(-not $p.batch_summary.digest){ Fail 'BATCH_DIGEST_MISSING' }
Write-Host 'VALIDATION_PASS=REAL_DELTA_SCHOOL_ORGAN_V1_SMALL_PROOF_VALID'
Write-Host "PROOF_PATH=$ProofPath"
Write-Host "ACCEPTED_TOTAL=$($p.accepted_total)"
Write-Host 'RUNTIME_READY=false'
