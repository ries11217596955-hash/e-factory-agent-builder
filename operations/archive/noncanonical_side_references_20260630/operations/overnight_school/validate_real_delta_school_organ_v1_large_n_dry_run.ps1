param(
  [int]$TargetAccepted = 25,
  [int]$BatchSize = 7,
  [int]$StopAfterAccepted = 11,
  [string]$FeedPath = 'operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_DRY_RUN_FEED_25.json',
  [string]$CheckpointPath = 'tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_LARGE_N_DRY_RUN.checkpoint.json',
  [string]$ProofPath = 'tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_LARGE_N_DRY_RUN_PROOF.json',
  [string]$MetaProofPath = 'tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_LARGE_N_DRY_RUN_META_PROOF.json'
)
$ErrorActionPreference='Stop'
function Fail([string]$m){ throw "REAL_DELTA_SCHOOL_ORGAN_V1_LARGE_N_DRY_RUN_INVALID: $m" }
if($TargetAccepted -le 5){ Fail 'TargetAccepted must be > 5 for large-N dry-run layer' }
if($StopAfterAccepted -le 0 -or $StopAfterAccepted -ge $TargetAccepted){ Fail 'StopAfterAccepted must be between 1 and TargetAccepted-1' }
& operations/overnight_school/generate_real_delta_school_organ_v1_dry_run_feed.ps1 -CandidateCount $TargetAccepted -FeedPath $FeedPath | Out-Host
$feedRaw = Get-Content $FeedPath -Raw
if($feedRaw -match '"runtime_ready"\s*:\s*true'){ Fail 'feed runtime_ready true' }
$feed = $feedRaw | ConvertFrom-Json
if($feed.feed_purpose -ne 'DRY_RUN_MECHANICS_ONLY'){ Fail 'feed purpose mismatch' }
if($feed.learning_quality_claimed -ne $false){ Fail 'learning_quality_claimed must be false' }
& operations/overnight_school/validate_real_delta_school_organ_v1_candidate_feed_contract.ps1 -FeedPath $FeedPath -MinCandidates $TargetAccepted | Out-Host
foreach($p in @($CheckpointPath,$ProofPath,$MetaProofPath)){ if(Test-Path $p){ Remove-Item $p -Force } }
& operations/overnight_school/run_real_delta_school_organ_v1.ps1 -CandidateFeedPath $FeedPath -TargetAccepted $TargetAccepted -BatchSize $BatchSize -ProofMode small -CandidateSourceMode OWNER_SUPPLIED -ProofPath $ProofPath -CheckpointPath $CheckpointPath -StopAfterAccepted $StopAfterAccepted | Out-Host
if(-not (Test-Path $CheckpointPath)){ Fail 'checkpoint missing after partial dry-run' }
if(Test-Path $ProofPath){ Fail 'proof should not exist after partial dry-run checkpoint' }
$cpRaw=Get-Content $CheckpointPath -Raw
if($cpRaw -match '"runtime_ready"\s*:\s*true'){ Fail 'checkpoint runtime_ready true' }
$cp=$cpRaw | ConvertFrom-Json
if([int]$cp.accepted_total -ne $StopAfterAccepted){ Fail "checkpoint accepted_total mismatch expected=$StopAfterAccepted actual=$($cp.accepted_total)" }
& operations/overnight_school/run_real_delta_school_organ_v1.ps1 -CandidateFeedPath $FeedPath -TargetAccepted $TargetAccepted -BatchSize $BatchSize -ProofMode small -CandidateSourceMode OWNER_SUPPLIED -ProofPath $ProofPath -CheckpointPath $CheckpointPath -ResumeFromCheckpoint | Out-Host
& operations/overnight_school/validate_real_delta_school_organ_v1_small_proof.ps1 -FeedPath $FeedPath -ProofPath $ProofPath | Out-Host
$proofRaw=Get-Content $ProofPath -Raw
if($proofRaw -match '"runtime_ready"\s*:\s*true'){ Fail 'proof runtime_ready true' }
$p=$proofRaw | ConvertFrom-Json
if([int]$p.accepted_total -ne $TargetAccepted){ Fail 'final accepted_total mismatch' }
if($p.resume.used -ne $true){ Fail 'resume not used' }
if([int]$p.batch_summary.batch_count -ne [Math]::Ceiling($TargetAccepted/[double]$BatchSize)){ Fail 'batch_count mismatch' }
if($p.accepted_core_mutated -ne $false){ Fail 'accepted core mutated' }
if($p.positive_self_map_update_called -ne $false){ Fail 'positive self-map called' }
if(@($p.protected_hashes.changed).Count -ne 0){ Fail 'protected hashes changed' }
$meta=[ordered]@{
  schema='real_delta_school_organ_v1_large_n_dry_run_meta_proof'
  status='PASS'
  proof_label='PROVEN_LAB_LARGE_N_DRY_RUN_MECHANICS_NOT_LEARNING_QUALITY'
  runtime_ready=$false
  target_accepted=$TargetAccepted
  batch_size=$BatchSize
  expected_batch_count=[Math]::Ceiling($TargetAccepted/[double]$BatchSize)
  checkpoint_accepted_total=[int]$cp.accepted_total
  final_accepted_total=[int]$p.accepted_total
  resume_used=$true
  feed_path=$FeedPath
  proof_path=$ProofPath
  checkpoint_path=$CheckpointPath
  feed_purpose=$feed.feed_purpose
  generated_for_test=$true
  learning_quality_claimed=$false
  accepted_core_mutated=$false
  positive_self_map_update_called=$false
  protected_hash_changed_count=@($p.protected_hashes.changed).Count
}
$meta | ConvertTo-Json -Depth 20 | Set-Content -Path $MetaProofPath -Encoding UTF8
Write-Host 'VALIDATION_PASS=REAL_DELTA_SCHOOL_ORGAN_V1_LARGE_N_DRY_RUN_VALID'
Write-Host "TARGET_ACCEPTED=$TargetAccepted"
Write-Host "BATCH_SIZE=$BatchSize"
Write-Host "CHECKPOINT_ACCEPTED_TOTAL=$($cp.accepted_total)"
Write-Host "FINAL_ACCEPTED_TOTAL=$($p.accepted_total)"
Write-Host 'LEARNING_QUALITY_CLAIMED=false'
Write-Host 'RUNTIME_READY=false'
Write-Host "META_PROOF_PATH=$MetaProofPath"
