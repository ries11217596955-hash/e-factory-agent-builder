$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$path="operations/reports/LADDER_SCHOOL_1000_V1.json"
if(-not(Test-Path $path)){throw "LADDER_REPORT_MISSING"}
$r=Get-Content $path -Raw | ConvertFrom-Json
if($r.schema -ne "ladder_school_1000_v1"){throw "BAD_SCHEMA"}
if($r.status -ne "PASS_LADDER_SCHOOL_1000_V1"){throw "BAD_STATUS=$($r.status)"}
if($r.runtime_ready -ne $false){throw "RUNTIME_READY_OVERCLAIM"}
if([int]$r.processed_count -ne 1000 -or [int]$r.accepted_count -ne 1000 -or [int]$r.rejected_count -ne 0){throw "BAD_COUNTS"}
if([int]$r.molecule_count -ne 100){throw "BAD_MOLECULE_COUNT"}
if([int64]$r.active_ladder_store_bytes -gt 2000000){throw "LADDER_STORE_TOO_LARGE"}
foreach($cp in @(10,100,500,1000)){$x=@($r.checkpoints|Where-Object{[int]$_.checkpoint -eq $cp}); if($x.Count -ne 1){throw "MISSING_CHECKPOINT_$cp"}; if($x[0].status -ne "PASS" -or $x[0].strict_complexity -ne $true -or [int]$x[0].unique_atom_id_count -ne $cp){throw "BAD_CHECKPOINT_$cp"}}
$ptr=Get-Content reports/self_development/accepted_change_memory_snapshot.json -Raw | ConvertFrom-Json
if($ptr.ladder_school_status -ne "ACTIVE_LADDER_SCHOOL_1000_PROMOTED"){throw "ACTIVE_POINTER_NOT_UPDATED"}
foreach($task in @("promote passed school chunk","build living cell atom molecule","use memory top-k no scan","rollback immune quarantine","behavior decision stronger")){$out=& operations/school/ladder/invoke_ladder_school_decision_v1.ps1 -TaskText $task -TopK 3 -AsJson | ConvertFrom-Json; if($out.status -ne "PASS" -or $out.no_full_scan -ne $true){throw "LADDER_DECISION_FAIL=$task"}}
& operations/school/lessons/validate_school_lesson_digest_v1.ps1 | Out-Host
Write-Host "VALIDATION_PASS=LADDER_SCHOOL_1000_V1"
Write-Host "PROCESSED=$($r.processed_count)"
Write-Host "ACCEPTED=$($r.accepted_count)"
Write-Host "MOLECULES=$($r.molecule_count)"
Write-Host "STORE_BYTES=$($r.active_ladder_store_bytes)"
Write-Host "NO_FULL_SCAN=true"
Write-Host "RUNTIME_READY=false"