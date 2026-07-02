param(
  [int]$TestTargetAccepted = 10,
  [int]$RealTargetAccepted = 10
)
$ErrorActionPreference='Stop'
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$runner='operations/school/run_agent_school.ps1'
if(-not (Test-Path $runner)){ throw 'RUNNER_MISSING' }
$runnerText=Get-Content $runner -Raw
foreach($required in @('generate_codex_curriculum_candidate_factory_run_v1.ps1','validate_codex_curriculum_streaming_absorption_v1.ps1','absorb_atom_file_via_digest_pipeline_v1.ps1','PASS_REAL_FACTORY_TO_DIGEST_ABSORPTION_V1','raw_route_absorption_allowed')){ if($runnerText -notmatch [regex]::Escape($required)){ throw "RUNNER_FACTORY_DIGEST_CONTRACT_MISSING:$required" } }
foreach($forbidden in @('$seed=@(','school_real_','vehicle.car','PASS_REAL_FILE_ATOM_DIGEST_ABSORPTION_V1')){ if($runnerText.Contains($forbidden)){ throw "RUNNER_FORBIDDEN_PARALLEL_SEED_ROUTE_PRESENT:$forbidden" } }
if($runnerText -match 'Start-Process') { throw 'RUNNER_MUST_NOT_DETACH' }
$routeBefore=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json -Raw|ConvertFrom-Json
$ledgerBefore=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json -Raw|ConvertFrom-Json
$testOut=@(& $runner -TargetAccepted $TestTargetAccepted -RunKind Test *>&1 | ForEach-Object{[string]$_})
$testStatus=($testOut|Where-Object{$_ -match '^SCHOOL_RUN_STATUS='}|Select-Object -Last 1)
$testProofPath=(($testOut|Where-Object{$_ -match '^PROOF_PATH='}|Select-Object -Last 1) -replace '^PROOF_PATH=','')
if($testStatus -ne 'SCHOOL_RUN_STATUS=PASS_TEST_FACTORY_STREAMING_READY_V1'){ throw "TEST_STATUS_BAD: $testStatus" }
$testProof=Get-Content $testProofPath -Raw|ConvertFrom-Json
if($testProof.schema -ne 'agent_school_canonical_run_v4'){ throw 'TEST_BAD_SCHEMA' }
if($testProof.source_factory_status -ne 'PASS_CODEX_CANDIDATE_FACTORY_GENERATION_V1'){ throw 'TEST_FACTORY_NOT_USED' }
if([int]$testProof.ready_atoms -ne $TestTargetAccepted){ throw 'TEST_READY_COUNT_BAD' }
if($testProof.digested_knowledge_mutated -ne $false){ throw 'TEST_MUTATED_DIGESTED_MEMORY' }
$realOut=@(& $runner -TargetAccepted $RealTargetAccepted -RunKind Real *>&1 | ForEach-Object{[string]$_})
$realStatus=($realOut|Where-Object{$_ -match '^SCHOOL_RUN_STATUS='}|Select-Object -Last 1)
$realProofPath=(($realOut|Where-Object{$_ -match '^PROOF_PATH='}|Select-Object -Last 1) -replace '^PROOF_PATH=','')
if($realStatus -ne 'SCHOOL_RUN_STATUS=PASS_REAL_FACTORY_TO_DIGEST_ABSORPTION_V1'){ throw "REAL_STATUS_BAD: $realStatus" }
$realProof=Get-Content $realProofPath -Raw|ConvertFrom-Json
if($realProof.schema -ne 'agent_school_canonical_run_v4'){ throw 'REAL_BAD_SCHEMA' }
if($realProof.source_factory_status -ne 'PASS_CODEX_CANDIDATE_FACTORY_GENERATION_V1'){ throw 'REAL_FACTORY_NOT_USED' }
if($realProof.streaming_status -ne 'PASS_STREAMING_SCHOOL_TO_ABSORPTION_PIPELINE_V1'){ throw 'REAL_STREAMING_NOT_USED' }
if([int]$realProof.ready_atoms -ne $RealTargetAccepted){ throw 'REAL_READY_COUNT_BAD' }
if($realProof.digested_knowledge_mutated -ne $true){ throw 'REAL_DID_NOT_DIGEST_MEMORY' }
if($realProof.raw_route_absorption_allowed -ne $false){ throw 'REAL_ALLOWED_RAW_ROUTE_ABSORB' }
if($realProof.raw_source_dependency_removed -ne $true){ throw 'REAL_RAW_DEPENDENCY_NOT_REMOVED' }
if($realProof.staged_raw_deleted -ne $true){ throw 'REAL_STAGED_RAW_NOT_DELETED' }
if($realProof.normalized_digest_input_deleted -ne $true){ throw 'REAL_NORMALIZED_INPUT_NOT_DELETED' }
if([int]$realProof.digested_cells -lt 1){ throw 'REAL_DIGESTED_CELLS_EMPTY' }
if([int]$realProof.total_memory_bytes -lt 1){ throw 'REAL_MEMORY_EMPTY' }
$routeAfter=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json -Raw|ConvertFrom-Json
$ledgerAfter=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json -Raw|ConvertFrom-Json
if([int]$routeBefore.routed_active_count -ne [int]$routeAfter.routed_active_count){ throw 'ROUTE_COUNT_CHANGED' }
if([int]$ledgerBefore.replayed_active_count -ne [int]$ledgerAfter.replayed_active_count){ throw 'LEDGER_COUNT_CHANGED' }
Write-Host 'VALIDATION_PASS=AGENT_SCHOOL_FACTORY_TO_DIGEST_RECONCILIATION_V1_VALID'
Write-Host "TEST_STATUS=$($testProof.status)"
Write-Host "TEST_READY_ATOMS=$($testProof.ready_atoms)"
Write-Host "REAL_STATUS=$($realProof.status)"
Write-Host "REAL_FACTORY_CANDIDATES=$($realProof.factory_candidates_created)"
Write-Host "REAL_READY_ATOMS=$($realProof.ready_atoms)"
Write-Host "REAL_DIGESTED_CELLS=$($realProof.digested_cells)"
Write-Host "REAL_MERGED_COUNT=$($realProof.merged_count)"
Write-Host "REAL_VALIDATION_TIER=$($realProof.validation_tier)"
Write-Host "REAL_RAW_SOURCE_DEPENDENCY_REMOVED=$($realProof.raw_source_dependency_removed)"
Write-Host "REAL_TOTAL_MEMORY_BYTES=$($realProof.total_memory_bytes)"
Write-Host "ROUTE_AFTER=$($routeAfter.routed_active_count)"
Write-Host "LEDGER_AFTER=$($ledgerAfter.replayed_active_count)"
Write-Host 'RUNTIME_READY=false'