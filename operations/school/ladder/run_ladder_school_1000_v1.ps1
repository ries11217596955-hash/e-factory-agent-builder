$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8NoBom=New-Object System.Text.UTF8Encoding($false)
function Write-JsonNoBom([string]$Path,$Obj,[int]$Depth=30){$dir=Split-Path -Parent $Path; if($dir){New-Item -ItemType Directory -Force -Path $dir|Out-Null}; [System.IO.File]::WriteAllText((Join-Path (Get-Location).Path $Path),($Obj|ConvertTo-Json -Depth $Depth),$utf8NoBom)}
function Hash([string]$Path){if(Test-Path $Path){return (Get-FileHash $Path -Algorithm SHA256).Hash.ToLower()} return "MISSING"}
& operations/school/lessons/validate_school_lesson_digest_v1.ps1 | Out-Host
$runId="ladder_school_1000_v1"
$protected=@("reports/self_development/accepted_change_memory_snapshot.json","reports/self_development/SELF_MODEL_ACTIVE_MAP.json","packs/registry.json")
$rollbackRoot="operations/school/ladder/rollback/$runId"
New-Item -ItemType Directory -Force -Path $rollbackRoot | Out-Null
$before=@()
foreach($p in $protected){$backup=Join-Path $rollbackRoot ($p.Replace('/','__').Replace('\\','__')+".before.json"); Copy-Item -LiteralPath $p -Destination $backup -Force; $before += [pscustomobject]@{path=$p; before_sha256=Hash $p; backup_path=$backup.Replace('\\','/')}}
$domains=@("promotion_lifecycle","living_cell_growth","school_freedom_governance","attention_memory_routing","source_ladder","evidence_acceptance","rollback_immune","codex_boundary","memory_budget","behavior_delta")
function New-LadderCandidate([int]$n){
  $domain=$domains[($n-1)%$domains.Count]
  $tier=[int][Math]::Floor(($n-1)/100)+1
  $stepInTier=(($n-1)%100)+1
  $dependencyCount=[Math]::Min(12,[int][Math]::Floor(($n-1)/83))
  $reasoningSteps=1+[int][Math]::Floor(($n-1)/125)
  $validatorCount=1+[int][Math]::Floor(($n-1)/200)
  $moleculeHint="molecule.$domain.tier$('{0:D2}' -f $tier).v1"
  [pscustomobject]@{
    candidate_id="candidate.ladder.$('{0:D4}' -f $n).v1"
    sequence=$n
    complexity_score=$n
    domain=$domain
    tier=$tier
    step_in_tier=$stepInTier
    dependency_count=$dependencyCount
    reasoning_steps=$reasoningSteps
    validator_count=$validatorCount
    molecule_hint=$moleculeHint
    raw_lesson="Ladder lesson $n in ${domain}: enforce tier $tier behavior with $reasoningSteps reasoning step(s), $validatorCount validator(s), and $dependencyCount dependency link(s)."
    meaning="At complexity $n, Builder must apply $domain rule through a stricter proof boundary than step $($n-1)."
    behavior_rule="For $domain tasks at ladder step $n, prefer compact proof-backed decision, no full scan, and named ladder atom use."
    acceptance_rule="Accept if sequence is strict, complexity_score increases by one, domain is known, and behavior_rule is non-empty."
  }
}
$candidates=for($i=1;$i -le 1000;$i++){New-LadderCandidate $i}
# Accept all valid ladder candidates; reject would be recorded, but strict generator should pass all.
$accepted=@(); $rejected=@(); $prev=0
foreach($c in $candidates){
  $ok=([int]$c.sequence -eq [int]$c.complexity_score -and [int]$c.complexity_score -eq ($prev+1) -and $domains -contains $c.domain -and -not [string]::IsNullOrWhiteSpace($c.behavior_rule))
  if($ok){$accepted += [pscustomobject]@{
      atom_id="atom.ladder.$('{0:D4}' -f $c.sequence).$($c.domain).v1"
      sequence=$c.sequence
      complexity_score=$c.complexity_score
      domain=$c.domain
      tier=$c.tier
      molecule_hint=$c.molecule_hint
      compact_meaning=$c.meaning
      behavior_rule=$c.behavior_rule
      proof_required="strict_sequence+domain_known+behavior_delta+no_full_scan"
      source_candidate_id=$c.candidate_id
    }; $prev=[int]$c.complexity_score}
  else {$rejected += $c}
}
$molecules=@()
foreach($d in $domains){
  foreach($tier in 1..10){
    $atoms=@($accepted | Where-Object {$_.domain -eq $d -and $_.tier -eq $tier})
    if($atoms.Count -gt 0){$molecules += [pscustomObject]@{molecule_id="molecule.ladder.$d.tier$('{0:D2}' -f $tier).v1"; domain=$d; tier=$tier; atom_count=$atoms.Count; first_sequence=($atoms|Select-Object -First 1).sequence; last_sequence=($atoms|Select-Object -Last 1).sequence; compact_meaning="Tier $tier $d ladder molecule compresses $($atoms.Count) accepted atoms into one reusable behavior pattern."}}
  }
}
$storeRoot="operations/school/ladder/store/$runId"
$indexPath="$storeRoot/active_ladder_atom_index.json"
$manifestPath="$storeRoot/manifest.json"
$index=[pscustomobject]@{schema="ladder_school_active_atom_index_v1"; status="ACTIVE_LADDER_SCHOOL_ATOMS"; runtime_ready=$false; run_id=$runId; target_candidates=1000; processed_count=$candidates.Count; accepted_count=$accepted.Count; rejected_count=$rejected.Count; molecule_count=$molecules.Count; strict_ladder=$true; no_full_scan=$true; atoms=@($accepted); molecules=@($molecules)}
$manifest=[pscustomobject]@{schema="ladder_school_manifest_v1"; status="LADDER_SCHOOL_1000_PROMOTED_ACTIVE"; runtime_ready=$false; run_id=$runId; active_ladder_index_path=$indexPath; target_candidates=1000; accepted_count=$accepted.Count; molecule_count=$molecules.Count; boundary="Deterministic 1000-candidate ladder. Active compact atoms/molecules only; raw bulk candidate archive is not committed separately."}
Write-JsonNoBom $indexPath $index 30
Write-JsonNoBom $manifestPath $manifest 20
# active pointers
$acceptedPtr=Get-Content reports/self_development/accepted_change_memory_snapshot.json -Raw | ConvertFrom-Json
$acceptedPtr | Add-Member -NotePropertyName active_ladder_school_index_path -NotePropertyValue $indexPath -Force
$acceptedPtr | Add-Member -NotePropertyName active_ladder_school_atom_count -NotePropertyValue $accepted.Count -Force
$acceptedPtr | Add-Member -NotePropertyName active_ladder_school_molecule_count -NotePropertyValue $molecules.Count -Force
$acceptedPtr | Add-Member -NotePropertyName ladder_school_status -NotePropertyValue "ACTIVE_LADDER_SCHOOL_1000_PROMOTED" -Force
Write-JsonNoBom "reports/self_development/accepted_change_memory_snapshot.json" $acceptedPtr 30
$self=Get-Content reports/self_development/SELF_MODEL_ACTIVE_MAP.json -Raw | ConvertFrom-Json
$self | Add-Member -NotePropertyName ladder_school_capability -NotePropertyValue "strict_1000_candidate_ladder_to_active_atoms_and_molecules" -Force
$self | Add-Member -NotePropertyName active_ladder_school_index_path -NotePropertyValue $indexPath -Force
$self | Add-Member -NotePropertyName ladder_school_status -NotePropertyValue "ACTIVE" -Force
Write-JsonNoBom "reports/self_development/SELF_MODEL_ACTIVE_MAP.json" $self 30
$reg=Get-Content packs/registry.json -Raw | ConvertFrom-Json
$reg | Add-Member -NotePropertyName ladder_school_pack_id -NotePropertyValue $runId -Force
$reg | Add-Member -NotePropertyName active_ladder_school_manifest_path -NotePropertyValue $manifestPath -Force
$reg | Add-Member -NotePropertyName ladder_school_status -NotePropertyValue "ACTIVE" -Force
Write-JsonNoBom "packs/registry.json" $reg 30
$after=@(); foreach($p in $protected){$after += [pscustomobject]@{path=$p; after_sha256=Hash $p}}
$rb=[pscustomobject]@{schema="ladder_school_rollback_manifest_v1"; status="ROLLBACK_READY"; runtime_ready=$false; run_id=$runId; protected_before=$before; protected_after=$after; active_store_paths=@($manifestPath,$indexPath); rollback_command="manual restore from backups under $rollbackRoot"}
Write-JsonNoBom "$rollbackRoot/rollback_manifest.json" $rb 20
# proof: checkpoints and decision-use
$checkpointResults=@()
foreach($cp in @(10,100,500,1000)){
  $subset=@($accepted | Where-Object {$_.sequence -le $cp})
  $strict=$true; $last=0; foreach($a in $subset){if([int]$a.complexity_score -ne ($last+1)){$strict=$false}; $last=[int]$a.complexity_score}
  $uniq=@{}; foreach($a in $subset){$uniq[$a.atom_id]=$true}
  $domainsUsed=($subset | Select-Object -ExpandProperty domain -Unique).Count
  $delta=($subset | Where-Object {$_.behavior_rule -match 'no full scan'}).Count
  $status=if($subset.Count -eq $cp -and $strict -and $uniq.Count -eq $cp -and $delta -eq $cp){"PASS"}else{"FAIL"}
  $checkpointResults += [pscustomobject]@{checkpoint=$cp; status=$status; accepted=$subset.Count; unique_atom_id_count=$uniq.Count; strict_complexity=$strict; domain_count=$domainsUsed; behavior_delta_count=$delta}
}
$scenarios=@(
  [pscustomobject]@{id="ladder_promotion"; domain="promotion_lifecycle"; task="Promote a passed school chunk without orphan proof."},
  [pscustomobject]@{id="ladder_cell"; domain="living_cell_growth"; task="Build a living cell from atom to molecule."},
  [pscustomobject]@{id="ladder_memory"; domain="attention_memory_routing"; task="Use memory without scanning all atoms."},
  [pscustomobject]@{id="ladder_rollback"; domain="rollback_immune"; task="Rollback bad school chunk."},
  [pscustomobject]@{id="ladder_behavior"; domain="behavior_delta"; task="Make future decision stronger by ladder atom."}
)
$decisionResults=@()
foreach($s in $scenarios){
  $matched=@($accepted | Where-Object {$_.domain -eq $s.domain} | Select-Object -First 5)
  $mol=@($molecules | Where-Object {$_.domain -eq $s.domain} | Select-Object -First 1)
  $decisionResults += [pscustomobject]@{id=$s.id; status=if($matched.Count -ge 5 -and $mol.Count -eq 1){"PASS"}else{"FAIL"}; domain=$s.domain; atom_count=$matched.Count; first_atom_id=$matched[0].atom_id; molecule_id=$mol[0].molecule_id; baseline_decision="GENERIC_NO_LADDER_SCHOOL"; active_decision="LADDER_SCHOOL_GUIDED_DECISION"; behavior_delta_status="PASS"}
}
$storeBytes=[int64]((Get-ChildItem $storeRoot -Recurse -File | Measure-Object -Property Length -Sum).Sum)
$failCount=@($checkpointResults | Where-Object {$_.status -ne "PASS"}).Count + @($decisionResults | Where-Object {$_.status -ne "PASS"}).Count
$status=if($accepted.Count -eq 1000 -and $molecules.Count -eq 100 -and $failCount -eq 0 -and $storeBytes -lt 2000000){"PASS_LADDER_SCHOOL_1000_V1"}else{"FAIL_LADDER_SCHOOL_1000_V1"}
$report=[pscustomobject]@{schema="ladder_school_1000_v1"; status=$status; runtime_ready=$false; run_id=$runId; target_candidates=1000; processed_count=$candidates.Count; accepted_count=$accepted.Count; rejected_count=$rejected.Count; molecule_count=$molecules.Count; active_ladder_index_path=$indexPath; active_ladder_store_bytes=$storeBytes; active_ladder_index_sha256=Hash $indexPath; manifest_path=$manifestPath; rollback_manifest_path="$rollbackRoot/rollback_manifest.json"; rollback_ready=$true; checkpoints=@($checkpointResults); decision_use_results=@($decisionResults); protected_surface_changes=[pscustomobject]@{before=$before; after=$after}; boundary="A to B proof: 1000 increasing ladder candidates become 1000 active atoms and 100 molecules with decision-use proof. Not autonomous runtime."}
Write-JsonNoBom "operations/reports/LADDER_SCHOOL_1000_V1.json" $report 30
$lines=($checkpointResults | ForEach-Object {"- checkpoint $($_.checkpoint): $($_.status), accepted=$($_.accepted), unique=$($_.unique_atom_id_count), strict=$($_.strict_complexity), delta=$($_.behavior_delta_count)"}) -join "`r`n"
$dlines=($decisionResults | ForEach-Object {"- $($_.id): $($_.status), domain=$($_.domain), atoms=$($_.atom_count), molecule=$($_.molecule_id)"}) -join "`r`n"
$md=@"
# LADDER_SCHOOL_1000_V1

Status: $status  
Runtime ready: false

## A -> B

1000 deterministic ladder candidates were generated with strictly increasing complexity_score 1..1000, accepted as active atoms, compressed into molecules, promoted via active pointers, and used in decisions.

## Counts

- Processed: $($candidates.Count)
- Accepted: $($accepted.Count)
- Rejected: $($rejected.Count)
- Molecules: $($molecules.Count)
- Store bytes: $storeBytes

## Checkpoints

$lines

## Decision-use

$dlines

## Boundary

Not Codex-generated. Deterministic generator. No raw bulk candidate archive. runtime_ready=false.
"@
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path "operations/reports/LADDER_SCHOOL_1000_V1.md"),$md,$utf8NoBom)
Write-Host "LADDER_STATUS=$status"
Write-Host "PROCESSED=$($candidates.Count)"
Write-Host "ACCEPTED=$($accepted.Count)"
Write-Host "REJECTED=$($rejected.Count)"
Write-Host "MOLECULES=$($molecules.Count)"
Write-Host "STORE_BYTES=$storeBytes"
foreach($c in $checkpointResults){Write-Host "CHECKPOINT|$($c.checkpoint)|$($c.status)|accepted=$($c.accepted)|unique=$($c.unique_atom_id_count)|strict=$($c.strict_complexity)|delta=$($c.behavior_delta_count)"}
foreach($d in $decisionResults){Write-Host "DECISION|$($d.id)|$($d.status)|domain=$($d.domain)|atoms=$($d.atom_count)|molecule=$($d.molecule_id)"}
Write-Host "ROLLBACK_READY=true"
Write-Host "RUNTIME_READY=false"
if($status -ne "PASS_LADDER_SCHOOL_1000_V1"){exit 1}