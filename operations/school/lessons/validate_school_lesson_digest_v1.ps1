$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$reportPath="operations/reports/SCHOOL_LESSON_DIGESTION_V1.json"
if(-not(Test-Path $reportPath)){ throw "SCHOOL_LESSON_REPORT_MISSING" }
$r=Get-Content $reportPath -Raw | ConvertFrom-Json
if($r.schema -ne "school_lesson_digest_v1"){ throw "BAD_SCHEMA" }
if($r.status -ne "PASS_SCHOOL_LESSON_DIGESTION_V1"){ throw "BAD_STATUS=$($r.status)" }
if($r.runtime_ready -ne $false){ throw "RUNTIME_READY_OVERCLAIM" }
if([int]$r.lesson_count -ne 6){ throw "BAD_LESSON_COUNT" }
if([int]$r.molecule_count -ne 3){ throw "BAD_MOLECULE_COUNT" }
if([int64]$r.active_lesson_store_bytes -gt 300000){ throw "LESSON_STORE_TOO_LARGE" }
if(-not(Test-Path $r.active_lesson_index_path)){ throw "ACTIVE_LESSON_INDEX_MISSING" }
$pointer=Get-Content reports/self_development/accepted_change_memory_snapshot.json -Raw | ConvertFrom-Json
if($pointer.school_lesson_digest_status -ne "ACTIVE_SCHOOL_LESSONS_DIGESTED"){ throw "ACTIVE_POINTER_NOT_UPDATED" }
$sc=@($r.decision_use_results | Where-Object {$_.status -eq "PASS"}).Count
if($sc -ne 5){ throw "BAD_DECISION_USE_PASS_COUNT=$sc" }
foreach($domain in @("promotion_lifecycle","living_cell_growth","school_freedom_governance","attention_memory_routing","source_ladder")){
  $out=& operations/school/lessons/invoke_school_lesson_decision_v1.ps1 -TaskText "Use $domain lesson in a future task" -TopK 2 -AsJson | ConvertFrom-Json
  if($out.status -ne "PASS"){ throw "LESSON_DECISION_FAIL_$domain" }
  if($out.no_full_scan -ne $true){ throw "FULL_SCAN_RISK_$domain" }
}
& operations/active_behavior/validate_active_behavior_absorption_promotion_v1.ps1 | Out-Host
& operations/active_behavior/validate_active_behavior_task_decision_flow_v1.ps1 | Out-Host
Write-Host "VALIDATION_PASS=SCHOOL_LESSON_DIGESTION_V1"
Write-Host "LESSON_COUNT=$($r.lesson_count)"
Write-Host "MOLECULE_COUNT=$($r.molecule_count)"
Write-Host "STORE_BYTES=$($r.active_lesson_store_bytes)"
Write-Host "DECISION_USE_PASS_COUNT=$sc"
Write-Host "NO_FULL_SCAN=true"
Write-Host "RUNTIME_READY=false"