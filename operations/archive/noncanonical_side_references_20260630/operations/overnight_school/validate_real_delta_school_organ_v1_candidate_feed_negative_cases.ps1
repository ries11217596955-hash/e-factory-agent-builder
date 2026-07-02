param(
  [string]$ProofPath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_FEED_NEGATIVE_CASES_PROOF.json'
)
$ErrorActionPreference='Stop'
function New-BaseFeed {
  [ordered]@{
    schema='real_delta_school_organ_v1_candidate_feed'
    candidate_source_mode='OWNER_SUPPLIED'
    runtime_ready=$false
    candidates=@(
      [ordered]@{ candidate_id='neg.atom.001'; domain='d1'; concept='c1'; useful_for='u1'; lesson='l1'; before_answer='b1'; after_answer='a1'; anti_apply='x1'; expected_use='e1' },
      [ordered]@{ candidate_id='neg.atom.002'; domain='d2'; concept='c2'; useful_for='u2'; lesson='l2'; before_answer='b2'; after_answer='a2'; anti_apply='x2'; expected_use='e2' }
    )
  }
}
function Invoke-Case([string]$Id,[scriptblock]$Mutate,[int]$MinCandidates=1){
  $tmpDir='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_FEED_NEGATIVE_CASES_TMP'
  New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
  $path=Join-Path $tmpDir ($Id + '.json')
  $feed=New-BaseFeed
  & $Mutate $feed
  $feed | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding UTF8
  try {
    & operations/overnight_school/validate_real_delta_school_organ_v1_candidate_feed_contract.ps1 -FeedPath $path -MinCandidates $MinCandidates *> $null
    return [ordered]@{ id=$Id; expected='BLOCKED'; actual='UNEXPECTED_PASS'; passed=$false; path=$path; message='validator unexpectedly passed' }
  } catch {
    return [ordered]@{ id=$Id; expected='BLOCKED'; actual='BLOCKED'; passed=$true; path=$path; message=$_.Exception.Message }
  }
}
$cases = New-Object System.Collections.ArrayList
[void]$cases.Add((Invoke-Case 'runtime_ready_true' { param($f) $f.runtime_ready=$true }))
[void]$cases.Add((Invoke-Case 'duplicate_candidate_id' { param($f) $f.candidates[1].candidate_id=$f.candidates[0].candidate_id }))
[void]$cases.Add((Invoke-Case 'duplicate_concept' { param($f) $f.candidates[1].domain=$f.candidates[0].domain; $f.candidates[1].concept=$f.candidates[0].concept; $f.candidates[1].useful_for=$f.candidates[0].useful_for }))
[void]$cases.Add((Invoke-Case 'missing_required_field' { param($f) $o=[ordered]@{}; foreach($p in $f.candidates[0].GetEnumerator()){ if($p.Key -ne 'expected_use'){ $o[$p.Key]=$p.Value } }; $f.candidates[0]=$o }))
[void]$cases.Add((Invoke-Case 'insufficient_candidates' { param($f) } 3))
$failed = @($cases | Where-Object { $_.passed -ne $true })
$status = if($failed.Count -eq 0){ 'PASS' } else { 'FAIL' }
$proof=[ordered]@{
  schema='real_delta_school_organ_v1_feed_negative_cases_proof'
  status=$status
  proof_label='PROVEN_LAB_FEED_CONTRACT_NEGATIVE_CASES_NOT_RUNTIME_INTELLIGENCE'
  runtime_ready=$false
  case_count=$cases.Count
  blocked_count=@($cases | Where-Object { $_.actual -eq 'BLOCKED' }).Count
  cases=@($cases)
  accepted_core_mutated=$false
  positive_self_map_update_called=$false
  runtime_ready_claimed_true=$false
}
New-Item -ItemType Directory -Force -Path (Split-Path $ProofPath -Parent) | Out-Null
$proof | ConvertTo-Json -Depth 20 | Set-Content -Path $ProofPath -Encoding UTF8
if($status -ne 'PASS'){ throw 'REAL_DELTA_SCHOOL_ORGAN_V1_FEED_NEGATIVE_CASES_INVALID' }
Write-Host 'VALIDATION_PASS=REAL_DELTA_SCHOOL_ORGAN_V1_FEED_NEGATIVE_CASES_VALID'
Write-Host "PROOF_PATH=$ProofPath"
Write-Host "CASE_COUNT=$($cases.Count)"
Write-Host "BLOCKED_COUNT=$(@($cases | Where-Object { $_.actual -eq 'BLOCKED' }).Count)"
Write-Host 'RUNTIME_READY=false'
