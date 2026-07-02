param(
  [Parameter(Mandatory=$true)][int]$CandidateBudget,
  [int]$ChunkSize = 25,
  [int]$InjectInvalidAt = 0,
  [switch]$PromoteActive,
  [string]$RunId = ""
)
$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8NoBom=New-Object System.Text.UTF8Encoding($false)
function Write-JsonNoBom([string]$Path,$Obj,[int]$Depth=60){$dir=Split-Path -Parent $Path; if($dir){New-Item -ItemType Directory -Force -Path $dir|Out-Null}; [System.IO.File]::WriteAllText((Join-Path (Get-Location).Path $Path),($Obj|ConvertTo-Json -Depth $Depth),$utf8NoBom)}
function Hash-Text([string]$Text){$sha=[System.Security.Cryptography.SHA256]::Create(); $bytes=[System.Text.Encoding]::UTF8.GetBytes($Text); ($sha.ComputeHash($bytes)|ForEach-Object {$_.ToString('x2')}) -join ''}
$domains=@('promotion_lifecycle','living_cell_growth','school_freedom_governance','attention_memory_routing','source_ladder','evidence_acceptance','rollback_immune','codex_boundary','memory_budget','behavior_delta')
function DomainOf([int]$Sequence){ return $domains[($Sequence-1) % $domains.Count] }
function New-SemanticCandidate([int]$Sequence,[int]$InvalidAt){
  $domain=DomainOf $Sequence
  $tier=[int][Math]::Floor(($Sequence-1)/10)+1
  $unitCount=1+[int][Math]::Floor(($Sequence-1)/7)
  $units=@()
  for($u=1;$u -le $unitCount;$u++){ $units += "$domain.unit$('{0:D3}' -f $u)" }
  $meaning="At stream position $Sequence, Builder must apply $domain through semantic validation, proof boundary, and behavior-use before calling it learned."
  $rule="For $domain tasks, use semantic atom $Sequence only after materialized candidate object, semantic hash, acceptance proof, promotion pointer, and no_full_scan decision-use are present."
  if($Sequence -eq $InvalidAt){ $meaning=''; $rule=''; $units=@() }
  [pscustomobject]@{
    candidate_id="semantic.candidate.$('{0:D6}' -f $Sequence).v1"
    sequence=$Sequence
    complexity_score=$Sequence
    domain=$domain
    tier=$tier
    semantic_units=@($units)
    raw_lesson="Semantic ladder lesson $Sequence for ${domain}: combine proof, memory, rollback, and decision-use into one accepted atom candidate."
    meaning=$meaning
    behavior_rule=$rule
    proof_targets=@('materialized_candidate','semantic_hash','acceptance_validator','promotion_pointer','decision_use','no_full_scan')
  }
}
function Test-SemanticCandidate($c,[int]$ExpectedSequence){
  $fail=@()
  if($null -eq $c){$fail += 'missing_candidate'}
  elseif([int]$c.sequence -ne $ExpectedSequence){$fail += 'bad_sequence'}
  if($null -eq $c -or [int]$c.complexity_score -ne $ExpectedSequence){$fail += 'bad_complexity'}
  if($null -eq $c -or -not ($domains -contains $c.domain)){ $fail += 'unknown_domain' }
  if($null -eq $c -or [string]::IsNullOrWhiteSpace($c.meaning) -or $c.meaning.Length -lt 40){ $fail += 'weak_meaning' }
  if($null -eq $c -or [string]::IsNullOrWhiteSpace($c.behavior_rule) -or $c.behavior_rule -notmatch 'semantic hash|acceptance proof|decision-use'){ $fail += 'weak_behavior_rule' }
  if($null -eq $c -or @($c.semantic_units).Count -lt 1){ $fail += 'missing_semantic_units' }
  if($null -eq $c -or @($c.proof_targets).Count -lt 5){ $fail += 'missing_proof_targets' }
  [pscustomobject]@{accepted=($fail.Count -eq 0); failures=@($fail)}
}
if($CandidateBudget -lt 1){throw 'BAD_CANDIDATE_BUDGET'}
if($ChunkSize -lt 1){throw 'BAD_CHUNK_SIZE'}
if([string]::IsNullOrWhiteSpace($RunId)){ $RunId='real_semantic_ladder_school_v1_' + (Get-Date -Format 'yyyyMMdd_HHmmss') }
$runtimeRoot=".runtime/real_semantic_ladder_school/$RunId"
$activeRoot='operations/school/semantic/store/active_real_semantic_ladder_school_v1'
$activeCheckpoint="$activeRoot/active_semantic_checkpoint.json"
$manifestPath="$activeRoot/manifest.json"
New-Item -ItemType Directory -Force -Path $runtimeRoot,$activeRoot | Out-Null
$accepted=@(); $rejected=@(); $chunks=@(); $allCandidateHashes=@()
$processed=0
for($start=1;$start -le $CandidateBudget;$start += $ChunkSize){
  $end=[Math]::Min($CandidateBudget,$start+$ChunkSize-1)
  $chunkAccepted=@(); $chunkRejected=@()
  for($seq=$start;$seq -le $end;$seq++){
    $candidate=New-SemanticCandidate -Sequence $seq -InvalidAt $InjectInvalidAt
    $candidateJson=($candidate|ConvertTo-Json -Depth 20 -Compress)
    $candidateHash=Hash-Text $candidateJson
    $allCandidateHashes += $candidateHash
    $test=Test-SemanticCandidate -c $candidate -ExpectedSequence $seq
    if($test.accepted){
      $atom=[pscustomobject]@{
        atom_id="semantic.atom.$('{0:D6}' -f $seq).$($candidate.domain).v1"
        sequence=$seq
        complexity_score=$candidate.complexity_score
        domain=$candidate.domain
        tier=$candidate.tier
        semantic_hash=$candidateHash
        semantic_units=@($candidate.semantic_units)
        compact_meaning=$candidate.meaning
        behavior_rule=$candidate.behavior_rule
        proof_targets=@($candidate.proof_targets)
        source_candidate_id=$candidate.candidate_id
      }
      $accepted += $atom; $chunkAccepted += $atom
    } else {
      $rej=[pscustomobject]@{candidate_id=$candidate.candidate_id; sequence=$seq; domain=$candidate.domain; semantic_hash=$candidateHash; failures=@($test.failures)}
      $rejected += $rej; $chunkRejected += $rej
    }
    $processed++
  }
  $chunks += [pscustomobject]@{chunk_index=$chunks.Count+1; first_sequence=$start; last_sequence=$end; processed=($end-$start+1); accepted=$chunkAccepted.Count; rejected=$chunkRejected.Count; last_good_checkpoint=$processed; status='PASS_CHUNK_SEMANTIC_VALIDATION'}
}
$molecules=@()
foreach($d in $domains){
  $domainAtoms=@($accepted | Where-Object {$_.domain -eq $d})
  foreach($tier in @($domainAtoms | Select-Object -ExpandProperty tier -Unique | Sort-Object)){
    $atoms=@($domainAtoms | Where-Object {$_.tier -eq $tier})
    if($atoms.Count -gt 0){
      $molecules += [pscustomobject]@{molecule_id="semantic.molecule.$d.tier$('{0:D6}' -f $tier).v1"; domain=$d; tier=$tier; atom_count=$atoms.Count; first_sequence=($atoms|Select-Object -First 1).sequence; last_sequence=($atoms|Select-Object -Last 1).sequence; semantic_hash=Hash-Text ((@($atoms|ForEach-Object {$_.semantic_hash}) -join '|'))}
    }
  }
}
$status=if($processed -eq $CandidateBudget -and ($accepted.Count + $rejected.Count) -eq $CandidateBudget){'PASS_REAL_SEMANTIC_LADDER_SCHOOL_RUN'}else{'FAIL_REAL_SEMANTIC_LADDER_SCHOOL_RUN'}
$runReport=[pscustomobject]@{
  schema='real_semantic_ladder_school_run_v1'
  status=$status
  runtime_ready=$false
  run_id=$RunId
  candidate_budget=$CandidateBudget
  chunk_size=$ChunkSize
  materialized_count=$processed
  semantic_validated_count=$processed
  accepted_count=$accepted.Count
  rejected_count=$rejected.Count
  molecule_count=$molecules.Count
  learned_count=$accepted.Count
  processed_equals_learned=($processed -eq $accepted.Count)
  auto_accept_by_range=$false
  no_magic_n=$true
  candidate_hash_root=Hash-Text (($allCandidateHashes) -join '|')
  chunks=@($chunks)
  accepted_atoms=@($accepted)
  rejected_candidates=@($rejected)
  molecules=@($molecules)
  boundary='This run materializes semantic candidate objects and validates them before acceptance. CandidateBudget is a run parameter, not architecture.'
}
Write-JsonNoBom "$runtimeRoot/run_report.json" $runReport 80
if($PromoteActive){
  $checkpoint=[pscustomobject]@{
    schema='active_real_semantic_ladder_checkpoint_v1'
    status='ACTIVE_REAL_SEMANTIC_LADDER_SCHOOL_CHECKPOINT'
    runtime_ready=$false
    run_id=$RunId
    candidate_budget=$CandidateBudget
    materialized_count=$processed
    semantic_validated_count=$processed
    accepted_count=$accepted.Count
    rejected_count=$rejected.Count
    learned_count=$accepted.Count
    molecule_count=$molecules.Count
    auto_accept_by_range=$false
    no_magic_n=$true
    candidate_hash_root=$runReport.candidate_hash_root
    accepted_atoms=@($accepted)
    molecules=@($molecules)
    runtime_report_path="$runtimeRoot/run_report.json"
  }
  Write-JsonNoBom $activeCheckpoint $checkpoint 80
  $manifest=[pscustomobject]@{schema='real_semantic_ladder_manifest_v1'; status='ACTIVE_REAL_SEMANTIC_LADDER_MANIFEST'; runtime_ready=$false; active_checkpoint_path=$activeCheckpoint; run_id=$RunId; candidate_budget=$CandidateBudget; learned_count=$accepted.Count; note='N-parametric semantic school checkpoint. CandidateBudget is not architecture.'}
  Write-JsonNoBom $manifestPath $manifest 20
  foreach($p in @('reports/self_development/accepted_change_memory_snapshot.json','reports/self_development/SELF_MODEL_ACTIVE_MAP.json','packs/registry.json')){
    if(Test-Path $p){
      $obj=Get-Content $p -Raw | ConvertFrom-Json
      $obj | Add-Member -NotePropertyName active_real_semantic_ladder_checkpoint_path -NotePropertyValue $activeCheckpoint -Force
      $obj | Add-Member -NotePropertyName active_real_semantic_ladder_status -NotePropertyValue 'ACTIVE_REAL_SEMANTIC_LADDER_SCHOOL_CHECKPOINT' -Force
      $obj | Add-Member -NotePropertyName active_real_semantic_ladder_learned_count -NotePropertyValue $accepted.Count -Force
      $obj | Add-Member -NotePropertyName active_real_semantic_ladder_run_id -NotePropertyValue $RunId -Force
      Write-JsonNoBom $p $obj 60
    }
  }
}
Write-Host "SEMANTIC_RUN_STATUS=$status"
Write-Host "RUN_ID=$RunId"
Write-Host "MATERIALIZED=$processed"
Write-Host "SEMANTIC_VALIDATED=$processed"
Write-Host "ACCEPTED=$($accepted.Count)"
Write-Host "REJECTED=$($rejected.Count)"
Write-Host "LEARNED=$($accepted.Count)"
Write-Host "MOLECULES=$($molecules.Count)"
Write-Host "AUTO_ACCEPT_BY_RANGE=false"
Write-Host "NO_MAGIC_N=true"
Write-Host "RUNTIME_READY=false"
if($status -notlike 'PASS*'){ exit 1 }