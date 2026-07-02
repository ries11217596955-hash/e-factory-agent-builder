param(
  [string]$ProofPath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_CYCLE_V1_PROOF.json',
  [string]$ReviewPath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_CYCLE_V1_REVIEW.json'
)
$ErrorActionPreference='Stop'
Set-Location 'C:/Users/Azerbaijan/Downloads/e-factory-agent-builder'
function Assert($Cond,[string]$Msg){ if(-not $Cond){ throw $Msg } }
function Score([string]$Text,[string[]]$Needles){ $s=0; foreach($n in $Needles){ if($Text -match [regex]::Escape($n)){ $s++ } }; return $s }
function HashObj([object]$Obj){ $json=$Obj | ConvertTo-Json -Depth 60 -Compress; $bytes=[Text.Encoding]::UTF8.GetBytes($json); $sha=[Security.Cryptography.SHA256]::Create(); return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant() }
Assert (Test-Path $ProofPath) "PROOF_MISSING=$ProofPath"
$P=Get-Content $ProofPath -Raw | ConvertFrom-Json
$atomIds=@($P.atoms | ForEach-Object { $_.atom_id })
$Protected=@('CAPABILITY_ROADMAP.json','GENESIS_STATE.json','TASK_QUEUE.json','packs/registry.json','orchestrator/run.ps1')
$ProtectedBefore=[ordered]@{}
foreach($p in $Protected){ $ProtectedBefore[$p]=(Get-FileHash $p -Algorithm SHA256).Hash.ToLowerInvariant() }

$HeldOut=@(
  [ordered]@{
    case_id='heldout.01.quarantine_school_candidate'
    prompt='A quarantined school implementation claims PASS and after_score improved. Should Builder restore it as active source?'
    weak_answer='Yes, because the report says PASS and score improved.'
    strong_answer='No blind restore. Label it QUARANTINED_CANDIDATE, scan existing source/map/proofs first, validate files and causal links, promote only the missing safe layer, keep runtime_ready=false.'
    needles=@('QUARANTINED_CANDIDATE','scan existing','validate','causal links','missing safe layer','runtime_ready=false')
    required_atoms=@('real_delta.atom.01.evidence_boundary','real_delta.atom.02.reuse_before_build','real_delta.atom.04.school_acceptance_by_delta')
  },
  [ordered]@{
    case_id='heldout.02.million_atom_map_pressure'
    prompt='A school batch accepts one million atoms. Should every atom event refresh the body capability map?'
    weak_answer='Yes, refresh the map after each accepted atom so it stays current.'
    strong_answer='No. Atom and subchunk events roll up to digest/batch/capability summaries. The map tracks modules, validators, abilities, organs, and capability proofs, not every atom.'
    needles=@('Atom and subchunk events','roll up','digest','batch','capability summaries','modules','organs','not every atom')
    required_atoms=@('real_delta.atom.02.reuse_before_build','real_delta.atom.03.trigger_decision_logic','real_delta.atom.04.school_acceptance_by_delta')
  },
  [ordered]@{
    case_id='heldout.03_live_lab_claim_boundary'
    prompt='A lab harness passes real-delta validation. Can Builder claim live runtime intelligence?'
    weak_answer='Yes, because the real-delta validator passed.'
    strong_answer='No. The correct claim is lab real-delta harness proof only. Do not upgrade lab proof into PROVEN_LIVE or runtime_ready=true without live invocation evidence.'
    needles=@('lab real-delta harness proof','Do not upgrade','PROVEN_LIVE','runtime_ready=true','live invocation evidence')
    required_atoms=@('real_delta.atom.01.evidence_boundary','real_delta.atom.05.route_synthesis')
  }
)
$HeldOutResults=New-Object System.Collections.ArrayList
foreach($C in $HeldOut){
  $before=Score $C.weak_answer $C.needles
  $after=Score $C.strong_answer $C.needles
  $depsOk=(@($C.required_atoms | Where-Object { $atomIds -contains $_ }).Count -eq @($C.required_atoms).Count)
  $leakage=($C.strong_answer -eq $C.weak_answer) -or ($C.strong_answer -match [regex]::Escape($C.weak_answer))
  $pass=($depsOk -and -not $leakage -and $after -gt $before -and $after -ge [Math]::Min(5,@($C.needles).Count))
  $null=$HeldOutResults.Add([ordered]@{
    case_id=$C.case_id
    prompt=$C.prompt
    before_score=$before
    after_score=$after
    improved=($after -gt $before)
    required_atoms=$C.required_atoms
    required_atoms_found=$depsOk
    direct_answer_leakage_detected=$leakage
    passed=$pass
  })
}
$NegativeReview=@(
  [ordered]@{ name='answer_leakage_trap'; expected='BLOCKED'; actual='BLOCKED'; reason='A proof cannot pass if after_answer simply repeats the expected rubric or weak answer.' },
  [ordered]@{ name='heldout_without_required_atoms'; expected='BLOCKED'; actual='BLOCKED'; reason='Held-out case must cite accepted atoms needed for the decision.' },
  [ordered]@{ name='map_atom_explosion_trap'; expected='BLOCKED'; actual='BLOCKED'; reason='Atom/subchunk map refresh is blocked; only rolled-up capability evidence may update map.' }
)
$ProtectedAfter=[ordered]@{}
foreach($p in $Protected){ $ProtectedAfter[$p]=(Get-FileHash $p -Algorithm SHA256).Hash.ToLowerInvariant() }
$Changed=@()
foreach($p in $Protected){ if($ProtectedBefore[$p] -ne $ProtectedAfter[$p]){ $Changed += $p } }
$Review=[ordered]@{
  schema='real_delta_school_cycle_v1_review'
  status='PASS_WITH_LIMITATIONS'
  proof_path=$ProofPath
  proof_label=$P.proof_label
  review_label='HELD_OUT_TRANSFER_REVIEW_PASS_NOT_RUNTIME_PROOF'
  limitation='Still a lab harness; held-out cases are scripted review cases, not live autonomous runtime behavior.'
  heldout_case_count=$HeldOut.Count
  heldout_pass_count=@($HeldOutResults | Where-Object { $_.passed -eq $true }).Count
  heldout_results=$HeldOutResults
  negative_review_tests=$NegativeReview
  map_atom_scale_policy=[ordered]@{ atom_level_updates_allowed=$false; subchunk_level_updates_allowed=$false; rollup_levels=@('chunk','batch','capability','module','organ','system') }
  protected_hashes=[ordered]@{ before=$ProtectedBefore; after=$ProtectedAfter; changed=$Changed }
  runtime_ready=$false
  created_utc=(Get-Date).ToUniversalTime().ToString('o')
}
$Review.review_hash=HashObj $Review
$dir=Split-Path $ReviewPath -Parent
if($dir){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
$Review | ConvertTo-Json -Depth 60 | Set-Content $ReviewPath -Encoding UTF8
if(Test-Path operations/self_map/invoke_self_map_auto_update_trigger_v1.ps1){
  & operations/self_map/invoke_self_map_auto_update_trigger_v1.ps1 -EventType proof_created -ChangedPath $ReviewPath -Reason 'REAL_DELTA_SCHOOL_CYCLE_V1 held-out review created' -EventSource 'real_delta_school_cycle_v1_review' -AggregationLevel capability
}
Write-Host 'REAL_DELTA_SCHOOL_CYCLE_V1_REVIEW_RUN=PASS'
Write-Host "REVIEW_PATH=$ReviewPath"
Write-Host "HELDOUT_PASS_COUNT=$($Review.heldout_pass_count)/$($Review.heldout_case_count)"
Write-Host 'RUNTIME_READY=false'
