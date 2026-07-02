param(
  [string]$FeedPath='operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_SAMPLE_FEED.json',
  [string]$CheckpointPath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_CHECKPOINT_RESUME.checkpoint.json',
  [string]$ProofPath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_CHECKPOINT_RESUME_PROOF.json'
)
$ErrorActionPreference='Stop'
function Fail([string]$m){ throw "REAL_DELTA_SCHOOL_ORGAN_V1_CHECKPOINT_RESUME_INVALID: $m" }
if(Test-Path $CheckpointPath){ Remove-Item $CheckpointPath -Force }
if(Test-Path $ProofPath){ Remove-Item $ProofPath -Force }
$partialOut = & operations/overnight_school/run_real_delta_school_organ_v1.ps1 -CandidateFeedPath $FeedPath -TargetAccepted 5 -BatchSize 2 -ProofMode small -CandidateSourceMode OWNER_SUPPLIED -ProofPath $ProofPath -CheckpointPath $CheckpointPath -StopAfterAccepted 2 2>&1
if(-not (Test-Path $CheckpointPath)){ Fail 'checkpoint file missing after partial run' }
if(Test-Path $ProofPath){ Fail 'proof must not exist after partial checkpoint run' }
$cpRaw = Get-Content $CheckpointPath -Raw
if($cpRaw -match '"runtime_ready"\s*:\s*true'){ Fail 'checkpoint contains runtime_ready true' }
$cp = $cpRaw | ConvertFrom-Json
if($cp.schema -ne 'real_delta_school_organ_v1_checkpoint'){ Fail 'bad checkpoint schema' }
if($cp.status -ne 'CHECKPOINT_CREATED'){ Fail 'bad checkpoint status' }
if([int]$cp.accepted_total -ne 2){ Fail "bad checkpoint accepted_total=$($cp.accepted_total)" }
if($cp.accepted_core_mutated -ne $false){ Fail 'checkpoint accepted_core_mutated not false' }
if($cp.positive_self_map_update_called -ne $false){ Fail 'checkpoint positive_self_map_update_called not false' }
$resumeOut = & operations/overnight_school/run_real_delta_school_organ_v1.ps1 -CandidateFeedPath $FeedPath -TargetAccepted 5 -BatchSize 2 -ProofMode small -CandidateSourceMode OWNER_SUPPLIED -ProofPath $ProofPath -CheckpointPath $CheckpointPath -ResumeFromCheckpoint 2>&1
if(-not (Test-Path $ProofPath)){ Fail 'proof file missing after resume run' }
& operations/overnight_school/validate_real_delta_school_organ_v1_run_output_contract.ps1 -ProofPath $ProofPath | Out-Host
& operations/overnight_school/validate_real_delta_school_organ_v1_small_proof.ps1 -FeedPath $FeedPath -ProofPath $ProofPath | Out-Host
$pRaw = Get-Content $ProofPath -Raw
if($pRaw -match '"runtime_ready"\s*:\s*true'){ Fail 'proof contains runtime_ready true' }
$p = $pRaw | ConvertFrom-Json
if($p.resume.used -ne $true){ Fail 'resume.used not true' }
if($p.resume.source -ne $CheckpointPath){ Fail 'resume source mismatch' }
if([int]$p.accepted_total -ne 5){ Fail 'final accepted total not 5' }
if(@($p.protected_hashes.changed).Count -ne 0){ Fail 'protected hashes changed' }
$meta=[ordered]@{
  schema='real_delta_school_organ_v1_checkpoint_resume_proof'
  status='PASS'
  proof_label='PROVEN_LAB_CHECKPOINT_RESUME_NOT_RUNTIME_INTELLIGENCE'
  runtime_ready=$false
  checkpoint_path=$CheckpointPath
  resumed_proof_path=$ProofPath
  checkpoint_accepted_total=[int]$cp.accepted_total
  final_accepted_total=[int]$p.accepted_total
  resume_used=$true
  accepted_core_mutated=$false
  positive_self_map_update_called=$false
  protected_hash_changed_count=@($p.protected_hashes.changed).Count
}
$metaPath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_CHECKPOINT_RESUME_META_PROOF.json'
$meta | ConvertTo-Json -Depth 20 | Set-Content -Path $metaPath -Encoding UTF8
Write-Host 'VALIDATION_PASS=REAL_DELTA_SCHOOL_ORGAN_V1_CHECKPOINT_RESUME_VALID'
Write-Host "CHECKPOINT_PATH=$CheckpointPath"
Write-Host "PROOF_PATH=$ProofPath"
Write-Host "META_PROOF_PATH=$metaPath"
Write-Host 'CHECKPOINT_ACCEPTED_TOTAL=2'
Write-Host 'FINAL_ACCEPTED_TOTAL=5'
Write-Host 'RUNTIME_READY=false'
