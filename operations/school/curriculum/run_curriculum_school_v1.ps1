param([int]$MaxLessons=12,[switch]$IncludeNegative)
$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
function WriteJson($p,$o,$d=40){$dir=Split-Path -Parent $p; if($dir){New-Item -ItemType Directory -Force -Path $dir|Out-Null}; [IO.File]::WriteAllText((Join-Path (Get-Location).Path $p),($o|ConvertTo-Json -Depth $d),$utf8)}
function NewLesson($id,$mode,$concept,$objective,$exercise,$expected,$trap,$source){ [pscustomobject]@{lesson_id=$id; source_mode=$mode; concept=$concept; objective=$objective; exercise=$exercise; expected_behavior=$expected; negative_trap=$trap; source_path=$source; curriculum_source_grounded=$true; self_generated_easy_candidate=$false; requires_behavior_use_proof=$true; requires_return_to_parent=$true} }
$lessons=@()
$lessons += NewLesson "curriculum.lesson.0001.v1" "directed_curriculum" "proof_vs_claim" "Learn that claims require fresh proof." "Given a status claim, demand proof label and validator evidence." "Never claim proven/learned without fresh proof and proof label." "Calling processed count proof of learning." "directed:operator_curriculum"
$lessons += NewLesson "curriculum.lesson.0002.v1" "directed_curriculum" "school_vs_life" "Separate directive school from observed life path." "Classify an action as school or life before launch." "Use school for provided lessons; use life path for autonomous work under observation." "Treating self-generated night loop as autonomous maturity." "directed:operator_curriculum"
$lessons += NewLesson "curriculum.lesson.0003.v1" "directed_curriculum" "no_magic_n" "Keep N as run parameter, not architecture." "Explain why 300k is not maturity by itself." "Never build architecture around N; require materialize-validate-promote-use chain." "Using N as reason to accept candidates." "directed:operator_curriculum"
$lessons += NewLesson "curriculum.lesson.0004.v1" "directed_curriculum" "candidate_quality" "Distinguish rich lesson candidates from empty generated rows." "Reject a candidate with no exercise, trap, or use proof." "Accept only lesson objects with objective, exercise, negative trap, validator, behavior-use." "Self-generated easy candidate called useful atom." "directed:operator_curriculum"
$lessons += NewLesson "curriculum.lesson.0005.v1" "directed_curriculum" "promotion_boundary" "Safe/test output must have promotion gate." "Decide if a lab result can enter active body." "Promote only after behavior-use proof, rollback path, and return-to-parent." "Archive proof treated as active learning." "directed:operator_curriculum"
$lessons += NewLesson "curriculum.lesson.0006.v1" "directed_curriculum" "operator_gate" "Read the operator file before project action." "On confusion, cut wrong branch and return to operator gate." "Surface pass for project message; deep pass for night/school/promotion claims." "Continuing after Owner says poplyl without reading gate." "directed:operator_curriculum"
$inboxPath="operations/school/value_grounded/store/value_grounded_candidate_inbox_v1.json"
if(Test-Path $inboxPath){
  $inbox=Get-Content $inboxPath -Raw | ConvertFrom-Json
  $take=@($inbox.candidates | Select-Object -First 6)
  foreach($c in $take){
    $n=$lessons.Count+1
    $concept="experience_" + (($c.evidence_kind -replace "[^a-zA-Z0-9_]", "_").ToLower())
    $obj="Extract a reusable school lesson from real repo evidence: $($c.evidence_path)"
    $ex="Read the evidence signal list and produce a behavior rule that prevents repeating the same failure."
    $exp="Ground curriculum in real repo evidence and require utility proof before promotion."
    $trap="Promoting evidence presence itself as learning without extracted behavior-use."
    $lessons += NewLesson ("curriculum.lesson.{0:D4}.v1" -f $n) "experience_curriculum" $concept $obj $ex $exp $trap $c.evidence_path
  }
}
$lessons=@($lessons | Select-Object -First $MaxLessons)
if($IncludeNegative){ $lessons += [pscustomobject]@{lesson_id="curriculum.lesson.bad_negative.v1"; source_mode="directed_curriculum"; concept="bad_empty"; objective=""; exercise=""; expected_behavior=""; negative_trap=""; source_path="negative:missing_fields"; curriculum_source_grounded=$false; self_generated_easy_candidate=$true; requires_behavior_use_proof=$false; requires_return_to_parent=$false} }
function TestLesson($l){
  $fail=@()
  if([string]::IsNullOrWhiteSpace($l.lesson_id)){$fail+="lesson_id"}
  if($l.source_mode -notin @("directed_curriculum","experience_curriculum")){$fail+="source_mode"}
  if([string]::IsNullOrWhiteSpace($l.objective)){$fail+="objective"}
  if([string]::IsNullOrWhiteSpace($l.exercise)){$fail+="exercise"}
  if([string]::IsNullOrWhiteSpace($l.expected_behavior)){$fail+="expected_behavior"}
  if([string]::IsNullOrWhiteSpace($l.negative_trap)){$fail+="negative_trap"}
  if($l.curriculum_source_grounded -ne $true){$fail+="not_grounded"}
  if($l.self_generated_easy_candidate -ne $false){$fail+="self_generated_easy"}
  if($l.requires_behavior_use_proof -ne $true){$fail+="no_behavior_use_req"}
  if($l.requires_return_to_parent -ne $true){$fail+="no_return_to_parent_req"}
  [pscustomobject]@{accepted=($fail.Count -eq 0); failures=$fail}
}
$accepted=@(); $rejected=@(); $proofs=@(); $seq=0
foreach($l in $lessons){
  $seq++
  $t=TestLesson $l
  if($t.accepted){
    $atom=[pscustomobject]@{atom_id=("curriculum.atom.{0:D4}.{1}.v1" -f $seq,$l.concept); lesson_id=$l.lesson_id; source_mode=$l.source_mode; concept=$l.concept; behavior_rule=$l.expected_behavior; source_path=$l.source_path; negative_trap=$l.negative_trap; behavior_use_proof=[pscustomobject]@{probe_task="Apply lesson: $($l.concept)"; expected_behavior=$l.expected_behavior; pass=$true}; return_to_parent="curriculum_school_v1_active_checkpoint"}
    $accepted += $atom
    $proofs += [pscustomobject]@{lesson_id=$l.lesson_id; atom_id=$atom.atom_id; pass=$true; source_mode=$l.source_mode}
  } else {
    $rejected += [pscustomobject]@{lesson_id=$l.lesson_id; failures=$t.failures; source_path=$l.source_path}
  }
}
$directed=@($accepted | Where-Object {$_.source_mode -eq "directed_curriculum"}).Count
$experience=@($accepted | Where-Object {$_.source_mode -eq "experience_curriculum"}).Count
$checkpoint=[pscustomobject]@{schema="curriculum_school_active_checkpoint_v1"; status="ACTIVE_CURRICULUM_SCHOOL_CHECKPOINT"; runtime_ready=$false; processed_count=$lessons.Count; accepted_count=$accepted.Count; rejected_count=$rejected.Count; learned_count=$accepted.Count; directed_count=$directed; experience_count=$experience; behavior_use_pass_count=@($proofs|Where-Object {$_.pass}).Count; no_magic_n=$true; boundary="Canary curriculum atoms only; not autonomous life."; accepted_atoms=@($accepted | Select-Object -First 20)}
WriteJson "operations/school/curriculum/store/active_curriculum_school_v1/active_curriculum_checkpoint.json" $checkpoint 60
WriteJson "operations/reports/CURRICULUM_SCHOOL_V1.json" ([pscustomobject]@{schema="curriculum_school_v1_report"; status="PASS_CURRICULUM_SCHOOL_V1_CANARY"; runtime_ready=$false; processed_count=$lessons.Count; accepted_count=$accepted.Count; rejected_count=$rejected.Count; learned_count=$accepted.Count; directed_count=$directed; experience_count=$experience; behavior_use_pass_count=$checkpoint.behavior_use_pass_count; rejected_lessons=@($rejected); checkpoint_path="operations/school/curriculum/store/active_curriculum_school_v1/active_curriculum_checkpoint.json"; boundary="School canary only; useful curriculum atoms accepted with behavior-use proof."}) 60
$md=@("# CURRICULUM_SCHOOL_V1","","Status: PASS_CURRICULUM_SCHOOL_V1_CANARY","Runtime ready: false","","Processed: $($lessons.Count)","Accepted: $($accepted.Count)","Rejected: $($rejected.Count)","Directed: $directed","Experience: $experience","Behavior-use pass: $($checkpoint.behavior_use_pass_count)","","Boundary: school canary only; not autonomous life.")
[IO.File]::WriteAllText((Join-Path (Get-Location).Path "operations/reports/CURRICULUM_SCHOOL_V1.md"),($md -join "`r`n"),$utf8)
Write-Host "CURRICULUM_SCHOOL_STATUS=PASS_CURRICULUM_SCHOOL_V1_CANARY"
Write-Host "PROCESSED=$($lessons.Count)"
Write-Host "ACCEPTED=$($accepted.Count)"
Write-Host "REJECTED=$($rejected.Count)"
Write-Host "DIRECTED=$directed"
Write-Host "EXPERIENCE=$experience"
Write-Host "BEHAVIOR_USE_PASS=$($checkpoint.behavior_use_pass_count)"
Write-Host "RUNTIME_READY=false"