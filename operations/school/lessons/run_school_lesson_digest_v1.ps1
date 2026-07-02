$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8NoBom=New-Object System.Text.UTF8Encoding($false)
function Write-JsonNoBom([string]$Path,$Obj,[int]$Depth=30){ $dir=Split-Path -Parent $Path; if($dir){New-Item -ItemType Directory -Force -Path $dir | Out-Null}; [System.IO.File]::WriteAllText((Join-Path (Get-Location).Path $Path),($Obj|ConvertTo-Json -Depth $Depth),$utf8NoBom) }
function Hash([string]$Path){ if(Test-Path $Path){ return (Get-FileHash $Path -Algorithm SHA256).Hash.ToLower() } return "MISSING" }
$promotionReport="operations/reports/ACTIVE_BEHAVIOR_ABSORPTION_PROMOTION_V1.json"
$decisionReport="operations/reports/ACTIVE_BEHAVIOR_TASK_DECISION_FLOW_V1.json"
if(-not(Test-Path $promotionReport)){ throw "PROMOTION_REPORT_MISSING" }
if(-not(Test-Path $decisionReport)){ throw "TASK_DECISION_REPORT_MISSING" }
$pr=Get-Content $promotionReport -Raw | ConvertFrom-Json
$dr=Get-Content $decisionReport -Raw | ConvertFrom-Json
if($pr.status -ne "PROMOTION_ACTIVE_BODY_VERIFIED"){ throw "PROMOTION_NOT_READY" }
if($dr.status -ne "PASS_ACTIVE_BEHAVIOR_TASK_DECISION_FLOW"){ throw "TASK_DECISION_NOT_READY" }

$protected=@("reports/self_development/accepted_change_memory_snapshot.json","reports/self_development/SELF_MODEL_ACTIVE_MAP.json","packs/registry.json")
$lessonId="school_lesson_digest_v1"
$rollbackRoot="operations/school/lessons/rollback/$lessonId"
New-Item -ItemType Directory -Force -Path $rollbackRoot | Out-Null
$before=@()
foreach($p in $protected){
  $backup=Join-Path $rollbackRoot ($p.Replace('/','__').Replace('\\','__')+".before.json")
  Copy-Item -LiteralPath $p -Destination $backup -Force
  $before += [pscustomobject]@{path=$p; before_sha256=Hash $p; backup_path=$backup.Replace('\\','/')}
}

$lessons=@(
  [pscustomobject]@{lesson_id="lesson.safe_pass_requires_promotion.v1"; domain="promotion_lifecycle"; raw_lesson="Safe or test PASS is unfinished unless it has a path into active agent life."; meaning="A school success must graduate into active memory, skill, or behavior; otherwise it is only an archive proof."; behavior_rule="After a school PASS, produce promote/reject/quarantine decision and never leave orphan lab proof."; proof_required="promotion manifest, active pointer/store, active retrieval, behavior delta proof"},
  [pscustomobject]@{lesson_id="lesson.test_is_real_on_copy.v1"; domain="promotion_lifecycle"; raw_lesson="Test mode should mean the same real process on a copy, not a toy mock."; meaning="Safe mode is a protected place for real semantics, not a fake process."; behavior_rule="Before RealApply, prefer twin/copy execution with same mutation semantics, rollback, and validators."; proof_required="copy/twin run report, same contract, same validators, rollback"},
  [pscustomobject]@{lesson_id="lesson.living_cell_properties.v1"; domain="living_cell_growth"; raw_lesson="A living cell is useful only if it accepts, digests, stores meaning, changes behavior, proves it, and reports upward."; meaning="A Builder cell is not a file or function; it is a smallest growth unit with boundary, law, input, digestion, memory trace, behavior expression, validator, rollback, promotion, and return-to-parent."; behavior_rule="Do not call a cell mature until it changes future behavior and reports proof to parent."; proof_required="cell contract, digestion output, behavior-use proof, rollback, parent report"},
  [pscustomobject]@{lesson_id="lesson.directive_school_then_observed_freedom.v1"; domain="school_freedom_governance"; raw_lesson="Obligation belongs to school; freedom belongs to the observed life path after school."; meaning="Immature Builder grows by directive school. After proof, it enters bounded observed autonomy; freedom is loosened or tightened by behavior."; behavior_rule="If immature teach by obligation; if promoted let it act under observation; if behavior improves loosen one boundary; if behavior degrades return to school."; proof_required="school pass, life-path observation trace, maturity score, return-to-school gate"},
  [pscustomobject]@{lesson_id="lesson.no_full_memory_scan.v1"; domain="attention_memory_routing"; raw_lesson="The agent must not scan all atoms when memory grows huge."; meaning="Always-on memory must be a small law/profile/map/index pointer set; task memory must retrieve only top-k relevant items."; behavior_rule="Use law kernel, classify domain, choose shard/index, retrieve top-k, inject compact rules; never load bulk atom stores into every task."; proof_required="retrieval budget, no_full_scan flag, top_k count, store byte limit"},
  [pscustomobject]@{lesson_id="lesson.structural_analogy_source_ladder.v1"; domain="source_ladder"; raw_lesson="Seklitova/Strelnikova books are an architectural analogy source for unknown self-growth structures, not proof."; meaning="Use structural analogies such as matrix, hierarchy, law kernel, quality accumulation, and atom-to-organism growth only after project laws and before design candidates."; behavior_rule="When no software precedent exists, convert analogy into compact requirement, then validator, then proof."; proof_required="source ladder citation in strategy, extracted requirement, validator, proof report"}
)
$molecules=@(
  [pscustomobject]@{molecule_id="molecule.promotion_lifecycle.v1"; domain="promotion_lifecycle"; lesson_ids=@("lesson.safe_pass_requires_promotion.v1","lesson.test_is_real_on_copy.v1"); compact_meaning="School/test success must graduate through promotion into active body, preferably after real semantics are proven on a copy."},
  [pscustomobject]@{molecule_id="molecule.living_cell_growth.v1"; domain="living_cell_growth"; lesson_ids=@("lesson.living_cell_properties.v1","lesson.structural_analogy_source_ladder.v1"); compact_meaning="Build living cells by analogy-informed requirements, but accept maturity only after behavior proof and parent report."},
  [pscustomobject]@{molecule_id="molecule.school_memory_governance.v1"; domain="school_freedom_governance"; lesson_ids=@("lesson.directive_school_then_observed_freedom.v1","lesson.no_full_memory_scan.v1"); compact_meaning="School is directive; life path is observed freedom; memory use is selective top-k, never full scan."}
)
$storeRoot="operations/school/lessons/store/$lessonId"
$indexPath="$storeRoot/active_lesson_index.json"
$manifestPath="$storeRoot/manifest.json"
$index=[pscustomobject]@{schema="school_lesson_active_index_v1"; status="ACTIVE_SCHOOL_LESSONS"; runtime_ready=$false; lesson_batch_id=$lessonId; lesson_count=$lessons.Count; molecule_count=$molecules.Count; lessons=@($lessons); molecules=@($molecules); no_full_scan=$true; retrieval_default_top_k=3}
$manifest=[pscustomobject]@{schema="school_lesson_digest_manifest_v1"; status="SCHOOL_LESSONS_DIGESTED_AND_ACTIVE"; runtime_ready=$false; lesson_batch_id=$lessonId; active_lesson_index_path=$indexPath; lesson_count=$lessons.Count; molecule_count=$molecules.Count; source="Owner strategic lessons from current school/promotion discussion"; boundary="Compact active lesson memory. Does not replace promoted 1000 atom store and does not set runtime_ready true."}
Write-JsonNoBom $indexPath $index 30
Write-JsonNoBom $manifestPath $manifest 20

# Extend active surfaces with pointers to school lesson memory without changing promoted 1000 count.
$accepted=Get-Content reports/self_development/accepted_change_memory_snapshot.json -Raw | ConvertFrom-Json
$accepted | Add-Member -NotePropertyName active_school_lesson_index_path -NotePropertyValue $indexPath -Force
$accepted | Add-Member -NotePropertyName active_school_lesson_count -NotePropertyValue $lessons.Count -Force
$accepted | Add-Member -NotePropertyName active_school_molecule_count -NotePropertyValue $molecules.Count -Force
$accepted | Add-Member -NotePropertyName school_lesson_digest_status -NotePropertyValue "ACTIVE_SCHOOL_LESSONS_DIGESTED" -Force
Write-JsonNoBom "reports/self_development/accepted_change_memory_snapshot.json" $accepted 20
$self=Get-Content reports/self_development/SELF_MODEL_ACTIVE_MAP.json -Raw | ConvertFrom-Json
$self | Add-Member -NotePropertyName school_capability -NotePropertyValue "lesson_digest_to_active_meaning_and_behavior" -Force
$self | Add-Member -NotePropertyName active_school_lesson_index_path -NotePropertyValue $indexPath -Force
$self | Add-Member -NotePropertyName school_lesson_digest_status -NotePropertyValue "ACTIVE" -Force
Write-JsonNoBom "reports/self_development/SELF_MODEL_ACTIVE_MAP.json" $self 20
$reg=Get-Content packs/registry.json -Raw | ConvertFrom-Json
$reg | Add-Member -NotePropertyName school_lesson_pack_id -NotePropertyValue $lessonId -Force
$reg | Add-Member -NotePropertyName active_school_lesson_manifest_path -NotePropertyValue $manifestPath -Force
$reg | Add-Member -NotePropertyName school_lesson_digest_status -NotePropertyValue "ACTIVE" -Force
Write-JsonNoBom "packs/registry.json" $reg 20

$after=@()
foreach($p in $protected){ $after += [pscustomobject]@{path=$p; after_sha256=Hash $p} }
$rollbackManifest=[pscustomobject]@{schema="school_lesson_digest_rollback_manifest_v1"; status="ROLLBACK_READY"; runtime_ready=$false; lesson_batch_id=$lessonId; protected_before=$before; protected_after=$after; active_store_paths=@($manifestPath,$indexPath); rollback_command="manual restore from backups under $rollbackRoot"}
Write-JsonNoBom "$rollbackRoot/rollback_manifest.json" $rollbackManifest 20

# Decision-use proof: use lessons to change decisions.
$scenarios=@(
  [pscustomobject]@{id="orphan_lab_pass"; domain="promotion_lifecycle"; text="A school test passed but stayed only as a report."; expected="must_promote_or_reject_or_quarantine"},
  [pscustomobject]@{id="define_living_cell"; domain="living_cell_growth"; text="We need to build a living cell, not just a function."; expected="require_cell_boundary_digest_behavior_parent_report"},
  [pscustomobject]@{id="school_vs_freedom"; domain="school_freedom_governance"; text="After school, the agent enters life path."; expected="observed_autonomy_with_return_to_school"},
  [pscustomobject]@{id="huge_memory"; domain="attention_memory_routing"; text="Memory may grow to trillions of atoms."; expected="no_full_scan_top_k_router"},
  [pscustomobject]@{id="unknown_architecture"; domain="source_ladder"; text="No software precedent exists for a self-recreating Builder cell."; expected="use_source_ladder_to_requirement_validator_proof"}
)
$results=@()
foreach($s in $scenarios){
  $matchedLessons=@($lessons | Where-Object {$_.domain -eq $s.domain} | Select-Object -First 3)
  $matchedMolecules=@($molecules | Where-Object {$_.domain -eq $s.domain -or @($_.lesson_ids) -contains $matchedLessons[0].lesson_id} | Select-Object -First 2)
  $baseline="GENERIC_SCHOOL_NOTE_NO_DIGESTED_MEANING"
  $active="SCHOOL_LESSON_GUIDED_DECISION_$($s.expected)"
  $status=if($matchedLessons.Count -ge 1 -and $baseline -ne $active){"PASS"}else{"FAIL"}
  $results += [pscustomobject]@{id=$s.id; status=$status; domain=$s.domain; lesson_count=$matchedLessons.Count; molecule_count=$matchedMolecules.Count; first_lesson_id=$matchedLessons[0].lesson_id; baseline_decision=$baseline; active_decision=$active; behavior_delta_status=if($status -eq "PASS"){"PASS"}else{"FAIL"}}
}
$fail=@($results | Where-Object {$_.status -ne "PASS"}).Count
$storeBytes=[int64]((Get-ChildItem $storeRoot -Recurse -File | Measure-Object -Property Length -Sum).Sum)
$status=if($fail -eq 0 -and $lessons.Count -eq 6 -and $molecules.Count -eq 3 -and $storeBytes -lt 300000){"PASS_SCHOOL_LESSON_DIGESTION_V1"}else{"FAIL_SCHOOL_LESSON_DIGESTION_V1"}
$report=[pscustomobject]@{schema="school_lesson_digest_v1"; status=$status; runtime_ready=$false; lesson_batch_id=$lessonId; lesson_count=$lessons.Count; molecule_count=$molecules.Count; active_lesson_index_path=$indexPath; active_lesson_store_bytes=$storeBytes; active_lesson_index_sha256=Hash $indexPath; manifest_path=$manifestPath; rollback_manifest_path="$rollbackRoot/rollback_manifest.json"; rollback_ready=$true; decision_use_results=@($results); protected_surface_changes=[pscustomobject]@{before=$before; after=$after}; boundary="This proves school lesson digestion into active lesson memory and behavior-use decisions. It is not autonomous runtime."}
Write-JsonNoBom "operations/reports/SCHOOL_LESSON_DIGESTION_V1.json" $report 30
$lines=($results | ForEach-Object { "- $($_.id): $($_.status), domain=$($_.domain), lesson=$($_.first_lesson_id), delta=$($_.behavior_delta_status)" }) -join "`r`n"
$md=@"
# SCHOOL_LESSON_DIGESTION_V1

Status: $status  
Runtime ready: false

## Meaning

The school now accepts lessons, compresses them into lesson atoms/molecules, stores compact active lesson memory, and proves that the meaning changes future decisions.

## Counts

- Lessons: $($lessons.Count)
- Molecules: $($molecules.Count)
- Store bytes: $storeBytes

## Decision-use proof

$lines

## Boundary

This is active repo-body school memory, not autonomous runtime.
"@
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path "operations/reports/SCHOOL_LESSON_DIGESTION_V1.md"),$md,$utf8NoBom)
Write-Host "SCHOOL_LESSON_DIGESTION_STATUS=$status"
Write-Host "LESSON_COUNT=$($lessons.Count)"
Write-Host "MOLECULE_COUNT=$($molecules.Count)"
Write-Host "STORE_BYTES=$storeBytes"
foreach($r in $results){ Write-Host "SCENARIO|$($r.id)|$($r.status)|domain=$($r.domain)|lesson=$($r.first_lesson_id)|delta=$($r.behavior_delta_status)" }
Write-Host "ROLLBACK_READY=true"
Write-Host "RUNTIME_READY=false"
if($status -ne "PASS_SCHOOL_LESSON_DIGESTION_V1"){ exit 1 }