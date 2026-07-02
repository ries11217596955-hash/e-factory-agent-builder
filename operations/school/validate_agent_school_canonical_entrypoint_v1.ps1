param(
  [int]$TestTargetAccepted = 10,
  [int]$RealTargetAccepted = 10
)
$ErrorActionPreference='Stop'
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$forbiddenOwnerLaunchers=@(
  'tools/start_school_night_cycle_detached_v1.ps1',
  'tools/start_retention_sustained_chunked_detached_v1.ps1',
  'tools/start_retention_scale_detached_v1.ps1',
  'operations/school/semantic_overnight/start_real_semantic_overnight_school_v1.ps1',
  'operations/school/semantic_overnight/run_real_semantic_overnight_school_v1.ps1',
  'operations/school/semantic_overnight/stop_real_semantic_overnight_school_v1.ps1',
  'operations/school/semantic_overnight/watch_real_semantic_overnight_school_v1.ps1',
  'operations/school/semantic_overnight/invoke_real_semantic_overnight_decision_v1.ps1',
  'operations/school/semantic_overnight/validate_real_semantic_overnight_school_v1.ps1',
  'operations/school/overnight/start_overnight_ladder_school_v1.ps1',
  'operations/school/overnight/run_overnight_ladder_school_v1.ps1',
  'operations/school/overnight/validate_overnight_ladder_school_v1.ps1',
  'operations/school/overnight/watch_overnight_ladder_school_v1.ps1'
)
foreach($oldLauncher in $forbiddenOwnerLaunchers){ if(Test-Path $oldLauncher){ throw "DUPLICATE_OWNER_FACING_SCHOOL_LAUNCHER_PRESENT: $oldLauncher" } }
$runner='operations/school/run_agent_school.ps1'
if(-not (Test-Path $runner)){ throw 'RUNNER_MISSING' }
$runnerText=Get-Content $runner -Raw
foreach($required in @('TargetAccepted','RunKind','BLOCKED_DIGESTION_ORGAN_REQUIRED_V1','PASS_TEST_STAGING_ONLY_DIGEST_REQUIRED_V1','raw_route_absorption_allowed')){
  if($runnerText -notmatch [regex]::Escape($required)){ throw "RUNNER_DIGEST_CONTRACT_MISSING:$required" }
}
if($runnerText -match 'PASS_REAL_ACTIVE_ROUTE_ABSORB'){ throw 'RUNNER_STILL_CLAIMS_RAW_REAL_ABSORB' }
if($runnerText -match 'Start-Process') { throw 'RUNNER_MUST_NOT_DETACH' }
$routeBefore=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json -Raw|ConvertFrom-Json
$ledgerBefore=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json -Raw|ConvertFrom-Json
$testOut=@(& $runner -TargetAccepted $TestTargetAccepted -RunKind Test *>&1 | ForEach-Object{[string]$_})
$testStatus=($testOut|Where-Object{$_ -match '^SCHOOL_RUN_STATUS='}|Select-Object -Last 1)
$testProofPath=(($testOut|Where-Object{$_ -match '^PROOF_PATH='}|Select-Object -Last 1) -replace '^PROOF_PATH=','')
if($testStatus -ne 'SCHOOL_RUN_STATUS=PASS_TEST_STAGING_ONLY_DIGEST_REQUIRED_V1'){ throw "TEST_STATUS_BAD: $testStatus" }
$testProof=Get-Content $testProofPath -Raw|ConvertFrom-Json
if($testProof.schema -ne 'agent_school_canonical_run_v2'){ throw 'TEST_BAD_SCHEMA' }
if($testProof.run_kind -ne 'Test'){ throw 'TEST_BAD_RUN_KIND' }
if([int]$testProof.target_accepted -ne $TestTargetAccepted){ throw 'TEST_BAD_TARGET' }
if($testProof.accepted_core_mutated -ne $false){ throw 'TEST_MUTATED_ACTIVE_ROUTE' }
if($testProof.digested_knowledge_mutated -ne $false){ throw 'TEST_MUTATED_DIGESTED_MEMORY' }
if($testProof.raw_route_absorption_allowed -ne $false){ throw 'TEST_ALLOWED_RAW_ROUTE_ABSORB' }
if([int]$testProof.accepted_total -ne 0){ throw 'TEST_ACCEPTED_TOTAL_MUST_BE_ZERO' }
$realOut=@(& $runner -TargetAccepted $RealTargetAccepted -RunKind Real *>&1 | ForEach-Object{[string]$_})
$realStatus=($realOut|Where-Object{$_ -match '^SCHOOL_RUN_STATUS='}|Select-Object -Last 1)
$realProofPath=(($realOut|Where-Object{$_ -match '^PROOF_PATH='}|Select-Object -Last 1) -replace '^PROOF_PATH=','')
if($realStatus -ne 'SCHOOL_RUN_STATUS=BLOCKED_DIGESTION_ORGAN_REQUIRED_V1'){ throw "REAL_STATUS_BAD: $realStatus" }
$realProof=Get-Content $realProofPath -Raw|ConvertFrom-Json
if($realProof.schema -ne 'agent_school_canonical_run_v2'){ throw 'REAL_BAD_SCHEMA' }
if($realProof.run_kind -ne 'Real'){ throw 'REAL_BAD_RUN_KIND' }
if([int]$realProof.target_accepted -ne $RealTargetAccepted){ throw 'REAL_BAD_TARGET' }
if($realProof.accepted_core_mutated -ne $false){ throw 'REAL_MUTATED_ACTIVE_ROUTE' }
if($realProof.digested_knowledge_mutated -ne $false){ throw 'REAL_MUTATED_DIGESTED_MEMORY_WITHOUT_ORGAN' }
if($realProof.raw_route_absorption_allowed -ne $false){ throw 'REAL_ALLOWED_RAW_ROUTE_ABSORB' }
if([int]$realProof.accepted_total -ne 0){ throw 'REAL_ACCEPTED_TOTAL_MUST_BE_ZERO_WHILE_BLOCKED' }
$routeAfter=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json -Raw|ConvertFrom-Json
$ledgerAfter=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json -Raw|ConvertFrom-Json
if([int]$routeBefore.routed_active_count -ne [int]$routeAfter.routed_active_count){ throw 'ROUTE_COUNT_CHANGED' }
if([int]$ledgerBefore.replayed_active_count -ne [int]$ledgerAfter.replayed_active_count){ throw 'LEDGER_COUNT_CHANGED' }
Write-Host 'VALIDATION_PASS=AGENT_SCHOOL_DIGEST_GATE_V1_VALID'
Write-Host "TEST_STATUS=$($testProof.status)"
Write-Host "REAL_STATUS=$($realProof.status)"
Write-Host "TEST_TARGET_ACCEPTED=$TestTargetAccepted"
Write-Host "REAL_TARGET_ACCEPTED=$RealTargetAccepted"
Write-Host 'REAL_ABSORPTION=BLOCKED_UNTIL_DIGEST_ORGAN'
Write-Host 'RUNTIME_READY=false'