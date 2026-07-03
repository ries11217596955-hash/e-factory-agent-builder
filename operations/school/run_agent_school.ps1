param(
  [Parameter(Mandatory=$true)][ValidateRange(1,1000000)][int]$TargetAccepted,
  [Parameter(Mandatory=$true)][ValidateSet('Test','Real')][string]$RunKind
)
$ErrorActionPreference='Stop'
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
function EnsureDir($Path){ if(-not (Test-Path $Path)){ New-Item -ItemType Directory -Force $Path | Out-Null } }
function WriteJson($Path,$Obj,$Depth=80){ $d=Split-Path $Path -Parent; if($d){ EnsureDir $d }; [IO.File]::WriteAllText((Join-Path (Get-Location).Path $Path),($Obj|ConvertTo-Json -Depth $Depth),$utf8) }
function RemoveIfExists($Path){ if(-not [string]::IsNullOrWhiteSpace($Path) -and (Test-Path $Path)){ Remove-Item $Path -Recurse -Force; return $true } return $false }
$runId="school_factory_digest_use_{0}_{1}_{2}" -f $RunKind.ToLowerInvariant(),$TargetAccepted,(Get-Date -Format 'yyyyMMdd_HHmmss')
$proofDir=".runtime/school_runs/$runId"
$proofPath="$proofDir/AGENT_SCHOOL_CANONICAL_ENTRYPOINT_V1.json"
$routePath='operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json'
$ledgerPath='operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json'
$routeBefore=Get-Content $routePath -Raw|ConvertFrom-Json
$ledgerBefore=Get-Content $ledgerPath -Raw|ConvertFrom-Json
$batchSize=[Math]::Min(100,[Math]::Max(1,$TargetAccepted))
$factoryOut=@(& powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/curriculum/candidate_factory/generate_codex_curriculum_candidate_factory_run_v1.ps1 -TargetAccepted $TargetAccepted -RunKind Test -BatchSize $batchSize -RunId $runId *>&1 | ForEach-Object {[string]$_})
$factoryStatus=($factoryOut|Where-Object{$_ -match '^FACTORY_STATUS='}|Select-Object -Last 1) -replace '^FACTORY_STATUS=',''
if($factoryStatus -ne 'PASS_CODEX_CANDIDATE_FACTORY_GENERATION_V1'){ throw "FACTORY_NOT_PASS:$factoryStatus" }
$factoryReport=Get-Content operations/reports/CODEX_CANDIDATE_FACTORY_RUN_V1.json -Raw|ConvertFrom-Json
& operations/school/curriculum/codex_contract/validate_codex_curriculum_contract_consistency_v1.ps1 -RunDir $factoryReport.run_dir | Out-Host
$consistency=Get-Content operations/reports/CODEX_CURRICULUM_CONTRACT_CONSISTENCY_V1.json -Raw|ConvertFrom-Json
if($consistency.status -ne 'PASS_CODEX_CURRICULUM_CONTRACT_CONSISTENCY_V1'){ throw "CONTRACT_NOT_PASS:$($consistency.status)" }
& operations/school/curriculum/streaming_absorption/validate_codex_curriculum_streaming_absorption_v1.ps1 -RunDir $factoryReport.run_dir | Out-Host
$stream=Get-Content operations/reports/STREAMING_SCHOOL_TO_ABSORPTION_PIPELINE_V1.json -Raw|ConvertFrom-Json
if($stream.status -ne 'PASS_STREAMING_SCHOOL_TO_ABSORPTION_PIPELINE_V1'){ throw "STREAMING_NOT_PASS:$($stream.status)" }
if([int]$stream.ready_atoms_total -ne $TargetAccepted){ throw "READY_ATOMS_COUNT_BAD:$($stream.ready_atoms_total)" }
$base=[ordered]@{
  schema='agent_school_canonical_run_v5'
  run_id=$runId
  run_kind=$RunKind
  target_accepted=$TargetAccepted
  runtime_ready=$false
  raw_route_absorption_allowed=$false
  source_factory_status=$factoryStatus
  factory_run_dir=$factoryReport.run_dir
  factory_candidates_created=[int]$factoryReport.candidates_created
  contract_status=$consistency.status
  contract_accepted=[int]$consistency.aggregate.accepted
  contract_rejected=[int]$consistency.aggregate.rejected
  streaming_status=$stream.status
  ready_atoms=[int]$stream.ready_atoms_total
  stream_quarantined=[int]$stream.stream_quarantined_total
  codex_cli_invoked=$factoryReport.codex_cli_invoked
  api_invoked=$factoryReport.api_invoked
  route_before=[int]$routeBefore.routed_active_count
  ledger_before=[int]$ledgerBefore.replayed_active_count
  law='TargetAccepted + RunKind uses the existing candidate factory and streaming lane. Real cannot pass from digest alone; recall/use and behavior_delta proof are required.'
}
if($RunKind -eq 'Test'){
  $cleanupRemoved=@()
  foreach($target in @($factoryReport.run_dir,'operations/reports')){
    if(-not [string]::IsNullOrWhiteSpace($target) -and (Test-Path $target)){
      Remove-Item $target -Recurse -Force
      $cleanupRemoved += $target
    }
  }
  $base.status='PASS_TEST_FACTORY_STREAMING_READY_V1'
  $base.accepted_total=0
  $base.digested_knowledge_mutated=$false
  $base.recall_use_required=$false
  $base.behavior_delta=$false
  $base.retention_policy='KEEP_CANONICAL_TEST_PROOF_ONLY_V1'
  $base.cleanup_removed=@($cleanupRemoved | Select-Object -Unique)
  $base.cleanup_kept=@($proofPath)
  $base.boundary='Test validates existing factory and streaming ready lane only. It does not digest or mutate compact memory. Raw/transient factory and report traces are removed after proof embedding.'
  WriteJson $proofPath $base 80
  Write-Host 'SCHOOL_RUN_STATUS=PASS_TEST_FACTORY_STREAMING_READY_V1'
  Write-Host "PROOF_PATH=$proofPath"
  Write-Host "TARGET_ACCEPTED=$TargetAccepted"
  Write-Host "RUN_KIND=$RunKind"
  Write-Host "FACTORY_CANDIDATES=$($base.factory_candidates_created)"
  Write-Host "READY_ATOMS=$($base.ready_atoms)"
  Write-Host 'DIGESTED_KNOWLEDGE_MUTATED=false'
  Write-Host 'RECALL_USE_REQUIRED=false'
  Write-Host 'BEHAVIOR_DELTA=false'
  Write-Host 'RUNTIME_READY=false'
  return
}
$budget=[Math]::Max(80000,($TargetAccepted * 1600))
$pipeOut=@(& powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/digestion/absorb_atom_file_via_digest_pipeline_v1.ps1 -InputPath $stream.ready_lane_path -MemoryRoot '.runtime/active_compact_semantic_memory_v1' -ValidationTier Auto -SizeBudgetBytes $budget *>&1 | ForEach-Object {[string]$_})
$pipeStatus=($pipeOut|Where-Object{$_ -match '^FILE_ATOM_ABSORPTION_STATUS='}|Select-Object -Last 1) -replace '^FILE_ATOM_ABSORPTION_STATUS=',''
$pipeProofPath=($pipeOut|Where-Object{$_ -match '^PROOF_PATH='}|Select-Object -Last 1) -replace '^PROOF_PATH=',''
if($pipeStatus -ne 'PASS_FILE_ATOM_ABSORPTION_PIPELINE_V1'){ throw "PIPELINE_NOT_PASS:$pipeStatus" }
$pipeProof=Get-Content $pipeProofPath -Raw|ConvertFrom-Json
$routeMid=Get-Content $routePath -Raw|ConvertFrom-Json
$ledgerMid=Get-Content $ledgerPath -Raw|ConvertFrom-Json
if([int]$routeMid.routed_active_count -ne [int]$routeBefore.routed_active_count){ throw 'ROUTE_MUTATED_BY_REAL_FACTORY_DIGEST' }
if([int]$ledgerMid.replayed_active_count -ne [int]$ledgerBefore.replayed_active_count){ throw 'LEDGER_MUTATED_BY_REAL_FACTORY_DIGEST' }
$useTask='Night school must prove that fresh compact memory is recalled and used before Real PASS; factory output must not be treated as external world knowledge without source acquisition.'
$useOut=@(& powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/memory/validate_compact_memory_recall_use_probe_v1.ps1 -MemoryRoot $pipeProof.memory_root -Task $useTask *>&1 | ForEach-Object {[string]$_})
$useStatus=($useOut|Where-Object{$_ -match '^VALIDATION_PASS=COMPACT_MEMORY_RECALL_USE_PROBE_V1_VALID$'}|Select-Object -Last 1)
$useProofPath=($useOut|Where-Object{$_ -match '^PROOF_PATH='}|Select-Object -Last 1) -replace '^PROOF_PATH=',''
if($useStatus -ne 'VALIDATION_PASS=COMPACT_MEMORY_RECALL_USE_PROBE_V1_VALID'){ throw 'RECALL_USE_GATE_NOT_PASS' }
if([string]::IsNullOrWhiteSpace($useProofPath) -or -not (Test-Path $useProofPath)){ throw 'RECALL_USE_PROOF_MISSING' }
$useProof=Get-Content $useProofPath -Raw|ConvertFrom-Json
if($useProof.behavior_delta -ne $true){ throw 'BEHAVIOR_DELTA_NOT_PROVEN' }
$routeAfter=Get-Content $routePath -Raw|ConvertFrom-Json
$ledgerAfter=Get-Content $ledgerPath -Raw|ConvertFrom-Json
if([int]$routeAfter.routed_active_count -ne [int]$routeBefore.routed_active_count){ throw 'ROUTE_MUTATED_BY_REAL_RECALL_USE' }
if([int]$ledgerAfter.replayed_active_count -ne [int]$ledgerBefore.replayed_active_count){ throw 'LEDGER_MUTATED_BY_REAL_RECALL_USE' }
$base.status='PASS_REAL_FACTORY_DIGEST_RECALL_USE_V1'
$base.accepted_total=0
$base.digested_knowledge_mutated=$true
$base.pipeline_status=$pipeProof.status
$base.pipeline_proof_path=$pipeProofPath
$base.validation_tier=$pipeProof.selected_validation_tier
$base.digested_cells=[int]$pipeProof.digested_cells
$base.merged_count=[int]$pipeProof.merged_count
$base.raw_source_dependency_removed=$pipeProof.raw_source_dependency_removed
$base.staged_raw_deleted=$pipeProof.staged_raw_deleted
$base.normalized_digest_input_deleted=$pipeProof.normalized_digest_input_deleted
$base.total_memory_bytes=[int]$pipeProof.total_memory_bytes
$base.memory_root=$pipeProof.memory_root
$base.recall_use_status=$useProof.status
$base.recall_use_proof_path=$useProofPath
$base.used_memory_cells=@($useProof.used_labels)
$base.baseline_decision=$useProof.baseline_decision
$base.active_decision=$useProof.active_decision
$base.behavior_delta=$useProof.behavior_delta
$base.behavior_delta_definition=$useProof.behavior_delta_definition
$base.route_after=[int]$routeAfter.routed_active_count
$base.ledger_after=[int]$ledgerAfter.replayed_active_count
$cleanupRemoved=@()
$cleanupKept=@()
# Retention policy: keep active compact memory and canonical school proof only; remove raw/transient factory, streaming, digest, and recall proof traces after their results are embedded into this proof.
foreach($target in @($factoryReport.run_dir,$pipeProofPath,$pipeProof.candidate_memory_root,$useProofPath,'operations/reports')){
  if(-not [string]::IsNullOrWhiteSpace($target)){
    $removeTarget=$target
    if((Test-Path $target) -and -not (Get-Item $target).PSIsContainer){ $removeTarget=Split-Path $target -Parent }
    if($removeTarget -and (Test-Path $removeTarget)){
      Remove-Item $removeTarget -Recurse -Force
      $cleanupRemoved += $removeTarget
    }
  }
}
foreach($trashPath in @('.runtime/codex_curriculum_candidate_factory_runs','.runtime/file_atom_absorption','.runtime/memory_use_probes','.runtime/digestion_policy','.runtime/digestion_reports','operations/reports')){
  if(Test-Path $trashPath){
    Remove-Item $trashPath -Recurse -Force
    $cleanupRemoved += $trashPath
  }
}
$cleanupKept += $pipeProof.memory_root
$cleanupKept += $proofPath
$base.retention_policy='KEEP_ACTIVE_COMPACT_MEMORY_AND_CANONICAL_PROOF_ONLY_V1'
$base.cleanup_removed=@($cleanupRemoved | Select-Object -Unique)
$base.cleanup_kept=@($cleanupKept | Select-Object -Unique)
$base.boundary='Real uses existing candidate factory output, streaming ready_atoms, digest pipeline, compact memory recall, and behavior_delta proof. Raw/transient traces are removed after proof embedding. Old overnight/semantic/fresh parallel paths are not canonical.'
WriteJson $proofPath $base 100
Write-Host 'SCHOOL_RUN_STATUS=PASS_REAL_FACTORY_DIGEST_RECALL_USE_V1'
Write-Host "PROOF_PATH=$proofPath"
Write-Host "TARGET_ACCEPTED=$TargetAccepted"
Write-Host "RUN_KIND=$RunKind"
Write-Host "FACTORY_CANDIDATES=$($base.factory_candidates_created)"
Write-Host "READY_ATOMS=$($base.ready_atoms)"
Write-Host "DIGESTED_CELLS=$($base.digested_cells)"
Write-Host "MERGED_COUNT=$($base.merged_count)"
Write-Host "VALIDATION_TIER=$($base.validation_tier)"
Write-Host "RAW_SOURCE_DEPENDENCY_REMOVED=$($base.raw_source_dependency_removed)"
Write-Host "TOTAL_MEMORY_BYTES=$($base.total_memory_bytes)"
Write-Host "RECALL_USE_STATUS=$($base.recall_use_status)"
Write-Host "BEHAVIOR_DELTA=$($base.behavior_delta)"
Write-Host "USED_MEMORY_CELLS=$($base.used_memory_cells -join ';')"
Write-Host "ROUTE_AFTER=$($base.route_after)"
Write-Host "LEDGER_AFTER=$($base.ledger_after)"
Write-Host 'RUNTIME_READY=false'