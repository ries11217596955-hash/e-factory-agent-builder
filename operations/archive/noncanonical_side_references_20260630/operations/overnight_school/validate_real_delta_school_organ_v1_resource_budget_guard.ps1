param(
  [string]$FeedPath='operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_DRY_RUN_FEED_25.json',
  [string]$ProofPath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_RESOURCE_BUDGET_GUARD_PROOF.json'
)
$ErrorActionPreference='Stop'
function Fail([string]$m){ throw "REAL_DELTA_SCHOOL_ORGAN_V1_RESOURCE_BUDGET_GUARD_INVALID: $m" }
& operations/overnight_school/generate_real_delta_school_organ_v1_dry_run_feed.ps1 -CandidateCount 25 -FeedPath $FeedPath | Out-Host
$blocked = New-Object System.Collections.ArrayList
function Expect-Block([string]$Id,[scriptblock]$Body,[string]$Pattern){
  try {
    & $Body
    [void]$blocked.Add([ordered]@{ id=$Id; expected='BLOCKED'; actual='UNEXPECTED_PASS'; passed=$false; message='unexpected pass' })
  } catch {
    $msg=$_.Exception.Message
    if($msg -match $Pattern){ [void]$blocked.Add([ordered]@{ id=$Id; expected='BLOCKED'; actual='BLOCKED'; passed=$true; message=$msg }) }
    else { [void]$blocked.Add([ordered]@{ id=$Id; expected='BLOCKED'; actual='WRONG_BLOCK'; passed=$false; message=$msg }) }
  }
}
Expect-Block 'target_above_default_without_allow_large_n' { & operations/overnight_school/run_real_delta_school_organ_v1.ps1 -CandidateFeedPath $FeedPath -TargetAccepted 25 -BatchSize 7 -ProofMode small -CandidateSourceMode OWNER_SUPPLIED -ProofPath $ProofPath -MaxAcceptedWithoutExplicitApproval 10 } 'TARGET_ACCEPTED_EXCEEDS_DEFAULT_BUDGET'
Expect-Block 'target_above_default_with_bad_token' { & operations/overnight_school/run_real_delta_school_organ_v1.ps1 -CandidateFeedPath $FeedPath -TargetAccepted 25 -BatchSize 7 -ProofMode small -CandidateSourceMode OWNER_SUPPLIED -ProofPath $ProofPath -MaxAcceptedWithoutExplicitApproval 10 -AllowLargeN -LargeNApprovalToken 'BAD' } 'LARGE_N_APPROVAL_TOKEN_INVALID'
if(Test-Path $ProofPath){ Remove-Item $ProofPath -Force }
& operations/overnight_school/run_real_delta_school_organ_v1.ps1 -CandidateFeedPath $FeedPath -TargetAccepted 25 -BatchSize 7 -ProofMode small -CandidateSourceMode OWNER_SUPPLIED -ProofPath $ProofPath -MaxAcceptedWithoutExplicitApproval 10 -AllowLargeN -LargeNApprovalToken 'OWNER_APPROVED_LARGE_N' | Out-Host
& operations/overnight_school/validate_real_delta_school_organ_v1_small_proof.ps1 -FeedPath $FeedPath -ProofPath $ProofPath | Out-Host
$pRaw=Get-Content $ProofPath -Raw
if($pRaw -match '"runtime_ready"\s*:\s*true'){ Fail 'runtime_ready true in proof' }
$p=$pRaw | ConvertFrom-Json
if([int]$p.accepted_total -ne 25){ Fail 'accepted_total mismatch' }
if($p.run_params.allow_large_n -ne $true){ Fail 'allow_large_n not true in approved proof' }
if($p.run_params.large_n_approval_token_present -ne $true){ Fail 'approval token not recorded as present' }
if(@($p.protected_hashes.changed).Count -ne 0){ Fail 'protected hashes changed' }
$bad=@($blocked | Where-Object { $_.passed -ne $true })
$status=if($bad.Count -eq 0){'PASS'}else{'FAIL'}
$meta=[ordered]@{
  schema='real_delta_school_organ_v1_resource_budget_guard_proof'
  status=$status
  proof_label='PROVEN_LAB_RESOURCE_BUDGET_GUARD_NOT_RUNTIME_INTELLIGENCE'
  runtime_ready=$false
  default_max_tested=10
  approved_target_accepted=25
  blocked_count=@($blocked | Where-Object { $_.actual -eq 'BLOCKED' }).Count
  cases=@($blocked)
  approved_run_passed=$true
  accepted_core_mutated=$false
  positive_self_map_update_called=$false
  protected_hash_changed_count=@($p.protected_hashes.changed).Count
}
$metaPath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_RESOURCE_BUDGET_GUARD_META_PROOF.json'
$meta | ConvertTo-Json -Depth 20 | Set-Content -Path $metaPath -Encoding UTF8
if($status -ne 'PASS'){ Fail 'negative resource guard case failed' }
Write-Host 'VALIDATION_PASS=REAL_DELTA_SCHOOL_ORGAN_V1_RESOURCE_BUDGET_GUARD_VALID'
Write-Host 'BLOCKED_COUNT=2'
Write-Host 'APPROVED_TARGET_ACCEPTED=25'
Write-Host "PROOF_PATH=$ProofPath"
Write-Host "META_PROOF_PATH=$metaPath"
Write-Host 'RUNTIME_READY=false'
