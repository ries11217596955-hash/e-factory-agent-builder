param(
  [int]$TestTargetAccepted = 10,
  [int]$RealTargetAccepted = 10
)
$ErrorActionPreference='Stop'
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$runner='operations/school/run_agent_school.ps1'
if(-not (Test-Path $runner)){ throw 'RUNNER_MISSING' }
$runnerText=Get-Content $runner -Raw
foreach($required in @('generate_codex_curriculum_candidate_factory_run_v1.ps1','validate_codex_curriculum_streaming_absorption_v1.ps1','absorb_atom_file_via_digest_pipeline_v1.ps1','validate_compact_memory_recall_use_probe_v1.ps1','PASS_REAL_FACTORY_DIGEST_RECALL_USE_V1','behavior_delta')){ if($runnerText -notmatch [regex]::Escape($required)){ throw "RUNNER_CANONICAL_NIGHT_CONTRACT_MISSING:$required" } }
foreach($forbidden in @('$seed=@(','school_real_','vehicle.car','PASS_REAL_FILE_ATOM_DIGEST_ABSORPTION_V1','PASS_REAL_FACTORY_TO_DIGEST_ABSORPTION_V1')){ if($runnerText.Contains($forbidden)){ throw "RUNNER_FORBIDDEN_PARALLEL_OR_DIGEST_ONLY_ROUTE_PRESENT:$forbidden" } }
if($runnerText -match 'Start-Process') { throw 'RUNNER_MUST_NOT_DETACH' }
$routeBefore=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json -Raw|ConvertFrom-Json
$ledgerBefore=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json -Raw|ConvertFrom-Json
$activeMemoryRoot='.runtime/active_compact_semantic_memory_v1'
$backupRoot=".runtime/validator_active_memory_backup/$(Get-Date -Format yyyyMMdd_HHmmss)"
$hadActiveMemory=Test-Path $activeMemoryRoot
if($hadActiveMemory){
  $backupParent=Split-Path $backupRoot -Parent
  if($backupParent -and -not (Test-Path $backupParent)){ New-Item -ItemType Directory -Force $backupParent | Out-Null }
  Copy-Item -Path $activeMemoryRoot -Destination $backupRoot -Recurse -Force
}
try {
  $testOut=@(& $runner -TargetAccepted $TestTargetAccepted -RunKind Test *>&1 | ForEach-Object{[string]$_})
  $testStatus=($testOut|Where-Object{$_ -match '^SCHOOL_RUN_STATUS='}|Select-Object -Last 1)
  $testProofPath=(($testOut|Where-Object{$_ -match '^PROOF_PATH='}|Select-Object -Last 1) -replace '^PROOF_PATH=','')
  if($testStatus -ne 'SCHOOL_RUN_STATUS=PASS_TEST_FACTORY_STREAMING_READY_V1'){ throw "TEST_STATUS_BAD: $testStatus" }
  $testProof=Get-Content $testProofPath -Raw|ConvertFrom-Json
  if($testProof.schema -ne 'agent_school_canonical_run_v5'){ throw 'TEST_BAD_SCHEMA' }
  if($testProof.source_factory_status -ne 'PASS_CODEX_CANDIDATE_FACTORY_GENERATION_V1'){ throw 'TEST_FACTORY_NOT_USED' }
  if([int]$testProof.ready_atoms -ne $TestTargetAccepted){ throw 'TEST_READY_COUNT_BAD' }
  if($testProof.digested_knowledge_mutated -ne $false){ throw 'TEST_MUTATED_DIGESTED_MEMORY' }
  $realOut=@(& $runner -TargetAccepted $RealTargetAccepted -RunKind Real *>&1 | ForEach-Object{[string]$_})
  $realStatus=($realOut|Where-Object{$_ -match '^SCHOOL_RUN_STATUS='}|Select-Object -Last 1)
  $realProofPath=(($realOut|Where-Object{$_ -match '^PROOF_PATH='}|Select-Object -Last 1) -replace '^PROOF_PATH=','')
  if($realStatus -ne 'SCHOOL_RUN_STATUS=PASS_REAL_FACTORY_DIGEST_RECALL_USE_V1'){ throw "REAL_STATUS_BAD: $realStatus" }
  $realProof=Get-Content $realProofPath -Raw|ConvertFrom-Json
  if($realProof.schema -ne 'agent_school_canonical_run_v5'){ throw 'REAL_BAD_SCHEMA' }
  if($realProof.source_factory_status -ne 'PASS_CODEX_CANDIDATE_FACTORY_GENERATION_V1'){ throw 'REAL_FACTORY_NOT_USED' }
  if($realProof.streaming_status -ne 'PASS_STREAMING_SCHOOL_TO_ABSORPTION_PIPELINE_V1'){ throw 'REAL_STREAMING_NOT_USED' }
  if([int]$realProof.ready_atoms -ne $RealTargetAccepted){ throw 'REAL_READY_COUNT_BAD' }
  if($realProof.digested_knowledge_mutated -ne $true){ throw 'REAL_DID_NOT_DIGEST_MEMORY' }
  if($realProof.raw_source_dependency_removed -ne $true){ throw 'REAL_RAW_DEPENDENCY_NOT_REMOVED' }
  if($realProof.behavior_delta -ne $true){ throw 'REAL_BEHAVIOR_DELTA_NOT_PROVEN' }
  if(@($realProof.used_memory_cells).Count -lt 1){ throw 'REAL_USED_MEMORY_CELLS_EMPTY' }
  if($realProof.recall_use_status -ne 'VALIDATION_PASS=COMPACT_MEMORY_RECALL_USE_PROBE_V1_VALID'){ throw 'REAL_RECALL_USE_NOT_PASS' }
  if([int]$realProof.digested_cells -lt 1){ throw 'REAL_DIGESTED_CELLS_EMPTY' }
} finally {
  if(Test-Path $activeMemoryRoot){ Remove-Item $activeMemoryRoot -Recurse -Force }
  if($hadActiveMemory){ Copy-Item -Path $backupRoot -Destination $activeMemoryRoot -Recurse -Force }
}
$routeAfter=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json -Raw|ConvertFrom-Json
$ledgerAfter=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json -Raw|ConvertFrom-Json
if([int]$routeBefore.routed_active_count -ne [int]$routeAfter.routed_active_count){ throw 'ROUTE_COUNT_CHANGED' }
if([int]$ledgerBefore.replayed_active_count -ne [int]$ledgerAfter.replayed_active_count){ throw 'LEDGER_COUNT_CHANGED' }
Write-Host 'VALIDATION_PASS=AGENT_SCHOOL_CANONICAL_REAL_RECALL_USE_GATE_V1_VALID'
Write-Host "TEST_STATUS=$($testProof.status)"
Write-Host "TEST_READY_ATOMS=$($testProof.ready_atoms)"
Write-Host "REAL_STATUS=$($realProof.status)"
Write-Host "REAL_FACTORY_CANDIDATES=$($realProof.factory_candidates_created)"
Write-Host "REAL_READY_ATOMS=$($realProof.ready_atoms)"
Write-Host "REAL_DIGESTED_CELLS=$($realProof.digested_cells)"
Write-Host "REAL_MERGED_COUNT=$($realProof.merged_count)"
Write-Host "REAL_RECALL_USE_STATUS=$($realProof.recall_use_status)"
Write-Host "REAL_BEHAVIOR_DELTA=$($realProof.behavior_delta)"
Write-Host "REAL_USED_MEMORY_CELLS=$(@($realProof.used_memory_cells).Count)"
Write-Host "ACTIVE_MEMORY_RESTORED_AFTER_VALIDATOR=$hadActiveMemory"
Write-Host "ROUTE_AFTER=$($routeAfter.routed_active_count)"
Write-Host "LEDGER_AFTER=$($ledgerAfter.replayed_active_count)"
Write-Host 'RUNTIME_READY=false'