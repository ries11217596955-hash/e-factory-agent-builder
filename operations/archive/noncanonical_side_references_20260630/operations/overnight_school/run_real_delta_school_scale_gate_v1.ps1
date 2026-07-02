param(
  [string]$ProofPath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_CYCLE_V1_PROOF.json',
  [string]$ReviewPath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_CYCLE_V1_REVIEW.json',
  [string]$GatePath='tests/accepted_atom_retention/REAL_DELTA_SCHOOL_SCALE_GATE_V1.json'
)
$ErrorActionPreference='Stop'
Set-Location 'C:/Users/Azerbaijan/Downloads/e-factory-agent-builder'
function Assert($Cond,[string]$Msg){ if(-not $Cond){ throw $Msg } }
function HashObj([object]$Obj){ $json=$Obj | ConvertTo-Json -Depth 80 -Compress; $bytes=[Text.Encoding]::UTF8.GetBytes($json); $sha=[Security.Cryptography.SHA256]::Create(); return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant() }
Assert (Test-Path $ProofPath) "REAL_DELTA_PROOF_MISSING=$ProofPath"
Assert (Test-Path $ReviewPath) "REAL_DELTA_REVIEW_MISSING=$ReviewPath"
$ProofObj=Get-Content $ProofPath -Raw | ConvertFrom-Json
$ReviewObj=Get-Content $ReviewPath -Raw | ConvertFrom-Json
$Protected=@('CAPABILITY_ROADMAP.json','GENESIS_STATE.json','TASK_QUEUE.json','packs/registry.json','orchestrator/run.ps1')
$ProtectedBefore=[ordered]@{}
foreach($protectedPath in $Protected){ $ProtectedBefore[$protectedPath]=(Get-FileHash $protectedPath -Algorithm SHA256).Hash.ToLowerInvariant() }

$CurrentAtoms=@($ProofObj.atoms)
$Domains=@($CurrentAtoms | ForEach-Object { $_.domain })
$Levels=@($CurrentAtoms | ForEach-Object { [int]$_.level })
$GateChecks=[ordered]@{
  base_real_delta_valid=($ProofObj.schema -eq 'real_delta_school_cycle_v1' -and $ProofObj.status -eq 'PASS' -and [int]$ProofObj.accepted_total -eq 5 -and $ProofObj.runtime_ready -eq $false)
  review_valid=($ReviewObj.schema -eq 'real_delta_school_cycle_v1_review' -and $ReviewObj.status -eq 'PASS_WITH_LIMITATIONS' -and [int]$ReviewObj.heldout_pass_count -eq [int]$ReviewObj.heldout_case_count -and $ReviewObj.runtime_ready -eq $false)
  distinct_domains=(($Domains | Select-Object -Unique).Count -eq $Domains.Count)
  increasing_levels=(($Levels -join ',') -eq '1,2,3,4,5')
  no_atom_map_updates=($ReviewObj.map_atom_scale_policy.atom_level_updates_allowed -eq $false -and $ReviewObj.map_atom_scale_policy.subchunk_level_updates_allowed -eq $false)
  count_only_blocked=($ProofObj.anti_cheat_guards.count_only_blocked -eq $true)
  causal_link_required=($ProofObj.anti_cheat_guards.causal_link_required -eq $true)
  retrieval_use_required=($ProofObj.anti_cheat_guards.retrieval_use_required -eq $true)
}
$BlockedPaths=@(
  [ordered]@{ path='jump_to_30000_or_300000'; decision='BLOCKED'; reason='Scale is not criterion of intelligence; must pass 50 real-delta ladder first.' },
  [ordered]@{ path='flat_50_atoms_same_domain'; decision='BLOCKED'; reason='Owner constraint: candidates must be useful and rising, not 50 uniform cycles.' },
  [ordered]@{ path='map_update_per_atom'; decision='BLOCKED'; reason='Atom/subchunk events must roll up; map tracks capabilities/modules/organs, not every atom.' },
  [ordered]@{ path='runtime_ready_promotion'; decision='BLOCKED'; reason='Lab harness and review do not prove live runtime intelligence.' },
  [ordered]@{ path='quarantine_blind_restore'; decision='BLOCKED'; reason='Quarantine candidates must be reconciled, validated, and promoted only as missing safe layer.' }
)
$Next50Blueprint=@(
  [ordered]@{ band='01_truth_boundary'; size=5; purpose='evidence labels, live/lab separation, false-proof rejection'; requires_previous=@() },
  [ordered]@{ band='02_reuse_and_map_literacy'; size=5; purpose='scan existing body, detect duplicates, respect source/generated surfaces'; requires_previous=@('01_truth_boundary') },
  [ordered]@{ band='03_trigger_and_scale_discipline'; size=5; purpose='roll up atom/subchunk events, update map only on capability/module/organ changes'; requires_previous=@('01_truth_boundary','02_reuse_and_map_literacy') },
  [ordered]@{ band='04_school_assimilation'; size=10; purpose='comprehension, causal atom link, retrieval/use proof, negative false-pass traps'; requires_previous=@('01_truth_boundary','02_reuse_and_map_literacy','03_trigger_and_scale_discipline') },
  [ordered]@{ band='05_quarantine_reconciliation'; size=10; purpose='use quarantined school material safely without blind restore'; requires_previous=@('01_truth_boundary','02_reuse_and_map_literacy','04_school_assimilation') },
  [ordered]@{ band='06_route_synthesis_and_transfer'; size=15; purpose='mixed operator decisions that require all previous bands'; requires_previous=@('01_truth_boundary','02_reuse_and_map_literacy','03_trigger_and_scale_discipline','04_school_assimilation','05_quarantine_reconciliation') }
)
$Total50=0; foreach($band in @($Next50Blueprint)){ $Total50 += [int]$band.size }
$ProtectedAfter=[ordered]@{}
foreach($protectedPath in $Protected){ $ProtectedAfter[$protectedPath]=(Get-FileHash $protectedPath -Algorithm SHA256).Hash.ToLowerInvariant() }
$Changed=@()
foreach($protectedPath in $Protected){ if($ProtectedBefore[$protectedPath] -ne $ProtectedAfter[$protectedPath]){ $Changed += $protectedPath } }
$GatePass=(@($GateChecks.GetEnumerator() | Where-Object { $_.Value -ne $true }).Count -eq 0 -and $Total50 -eq 50)
$Gate=[ordered]@{
  schema='real_delta_school_scale_gate_v1'
  status= if($GatePass){ 'PASS_NEXT_SCALE_ALLOWED_TO_50_ONLY' } else { 'BLOCKED' }
  proof_path=$ProofPath
  review_path=$ReviewPath
  decision='ALLOW_DESIGN_FOR_50_REAL_DELTA_LADDER_NOT_EXECUTE_30K'
  current_limit='Do not run 30K/300K/1M. Next executable scale is 50 only, with rising useful bands and held-out review.'
  gate_checks=$GateChecks
  blocked_paths=$BlockedPaths
  next_50_blueprint=$Next50Blueprint
  next_50_total=$Total50
  required_next_validator_gates=@('band diversity','dependency ladder','comprehension per accepted atom','held-out transfer cases','negative false-pass traps','map rollup only','runtime_ready false','protected hashes unchanged')
  map_policy='Map updates only on chunk/batch/capability/module/organ/system proof, not atom/subchunk events.'
  proof_label='SCALE_GATE_PASS_NOT_SCALE_PROOF'
  protected_hashes=[ordered]@{ before=$ProtectedBefore; after=$ProtectedAfter; changed=$Changed }
  runtime_ready=$false
  created_utc=(Get-Date).ToUniversalTime().ToString('o')
}
$Gate.gate_hash=HashObj $Gate
$dir=Split-Path $GatePath -Parent
if($dir){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
$Gate | ConvertTo-Json -Depth 80 | Set-Content $GatePath -Encoding UTF8
if(Test-Path operations/self_map/invoke_self_map_auto_update_trigger_v1.ps1){
  & operations/self_map/invoke_self_map_auto_update_trigger_v1.ps1 -EventType proof_created -ChangedPath $GatePath -Reason 'REAL_DELTA_SCHOOL_SCALE_GATE_V1 created' -EventSource 'real_delta_school_scale_gate_v1' -AggregationLevel capability
}
Write-Host "REAL_DELTA_SCHOOL_SCALE_GATE_V1_RUN=$($Gate.status)"
Write-Host "GATE_PATH=$GatePath"
Write-Host "NEXT_50_TOTAL=$Total50"
Write-Host 'RUNTIME_READY=false'


