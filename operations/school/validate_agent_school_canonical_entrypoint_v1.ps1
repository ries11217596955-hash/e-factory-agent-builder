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
foreach($required in @('TargetAccepted','RunKind','PASS_REAL_FILE_ATOM_DIGEST_ABSORPTION_V1','absorb_atom_file_via_digest_pipeline_v1.ps1','raw_route_absorption_allowed')){ if($runnerText -notmatch [regex]::Escape($required)){ throw "RUNNER_DIGEST_PIPELINE_CONTRACT_MISSING:$required" } }
if($runnerText -match 'PASS_REAL_ACTIVE_ROUTE_ABSORB'){ throw 'RUNNER_STILL_CLAIMS_RAW_REAL_ABSORB' }
if($runnerText -match 'Start-Process') { throw 'RUNNER_MUST_NOT_DETACH' }
$routeBefore=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json -Raw|ConvertFrom-Json
$ledgerBefore=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json -Raw|ConvertFrom-Json
$testOut=@(& $runner -TargetAccepted $TestTargetAccepted -RunKind Test *>&1 | ForEach-Object{[string]$_})
$testStatus=($testOut|Where-Object{$_ -match '^SCHOOL_RUN_STATUS='}|Select-Object -Last 1)
$testProofPath=(($testOut|Where-Object{$_ -match '^PROOF_PATH='}|Select-Object -Last 1) -replace '^PROOF_PATH=','')
if($testStatus -ne 'SCHOOL_RUN_STATUS=PASS_TEST_STAGING_ONLY_DIGEST_REQUIRED_V1'){ throw "TEST_STATUS_BAD: $testStatus" }
$testProof=Get-Content $testProofPath -Raw|ConvertFrom-Json
if($testProof.schema -ne 'agent_school_canonical_run_v3'){ throw 'TEST_BAD_SCHEMA' }
if($testProof.digested_knowledge_mutated -ne $false){ throw 'TEST_MUTATED_DIGESTED_MEMORY' }
$realOut=@(& $runner -TargetAccepted $RealTargetAccepted -RunKind Real *>&1 | ForEach-Object{[string]$_})
$realStatus=($realOut|Where-Object{$_ -match '^SCHOOL_RUN_STATUS='}|Select-Object -Last 1)
$realProofPath=(($realOut|Where-Object{$_ -match '^PROOF_PATH='}|Select-Object -Last 1) -replace '^PROOF_PATH=','')
if($realStatus -ne 'SCHOOL_RUN_STATUS=PASS_REAL_FILE_ATOM_DIGEST_ABSORPTION_V1'){ throw "REAL_STATUS_BAD: $realStatus" }
$realProof=Get-Content $realProofPath -Raw|ConvertFrom-Json
if($realProof.schema -ne 'agent_school_canonical_run_v3'){ throw 'REAL_BAD_SCHEMA' }
if($realProof.run_kind -ne 'Real'){ throw 'REAL_BAD_RUN_KIND' }
if([int]$realProof.target_accepted -ne $RealTargetAccepted){ throw 'REAL_BAD_TARGET' }
if($realProof.accepted_core_mutated -ne $false){ throw 'REAL_MUTATED_ROUTE_CORE' }
if($realProof.digested_knowledge_mutated -ne $true){ throw 'REAL_DID_NOT_MUTATE_DIGESTED_MEMORY' }
if($realProof.raw_route_absorption_allowed -ne $false){ throw 'REAL_ALLOWED_RAW_ROUTE_ABSORB' }
if($realProof.raw_source_dependency_removed -ne $true){ throw 'REAL_RAW_DEPENDENCY_NOT_REMOVED' }
if($realProof.staged_raw_deleted -ne $true){ throw 'REAL_STAGED_RAW_NOT_DELETED' }
if([int]$realProof.staged_total -ne $RealTargetAccepted){ throw 'REAL_STAGED_TOTAL_BAD' }
if([int]$realProof.digested_cells -lt 1){ throw 'REAL_DIGESTED_CELLS_EMPTY' }
if([int]$realProof.total_memory_bytes -lt 1){ throw 'REAL_MEMORY_EMPTY' }
$routeAfter=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json -Raw|ConvertFrom-Json
$ledgerAfter=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json -Raw|ConvertFrom-Json
if([int]$routeBefore.routed_active_count -ne [int]$routeAfter.routed_active_count){ throw 'ROUTE_COUNT_CHANGED' }
if([int]$ledgerBefore.replayed_active_count -ne [int]$ledgerAfter.replayed_active_count){ throw 'LEDGER_COUNT_CHANGED' }
Write-Host 'VALIDATION_PASS=AGENT_SCHOOL_FILE_ATOM_DIGEST_PIPELINE_V1_VALID'
Write-Host "TEST_STATUS=$($testProof.status)"
Write-Host "REAL_STATUS=$($realProof.status)"
Write-Host "REAL_STAGED_TOTAL=$($realProof.staged_total)"
Write-Host "REAL_DIGESTED_CELLS=$($realProof.digested_cells)"
Write-Host "REAL_MERGED_COUNT=$($realProof.merged_count)"
Write-Host "REAL_VALIDATION_TIER=$($realProof.validation_tier)"
Write-Host "REAL_RAW_SOURCE_DEPENDENCY_REMOVED=$($realProof.raw_source_dependency_removed)"
Write-Host "REAL_TOTAL_MEMORY_BYTES=$($realProof.total_memory_bytes)"
Write-Host "ROUTE_AFTER=$($routeAfter.routed_active_count)"
Write-Host "LEDGER_AFTER=$($ledgerAfter.replayed_active_count)"
Write-Host 'RUNTIME_READY=false'