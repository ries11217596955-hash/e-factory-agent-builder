param(
  [Parameter(Mandatory=$true)][ValidateRange(1,1000000)][int]$TargetAccepted,
  [Parameter(Mandatory=$true)][ValidateSet('Test','Real')][string]$RunKind
)
$ErrorActionPreference='Stop'
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
function EnsureDir($Path){ if(-not (Test-Path $Path)){ New-Item -ItemType Directory -Force $Path | Out-Null } }
function WriteJson($Path,$Obj,$Depth=100){ $d=Split-Path $Path -Parent; if($d){ EnsureDir $d }; [IO.File]::WriteAllText((Join-Path (Get-Location).Path $Path),($Obj|ConvertTo-Json -Depth $Depth),$utf8) }
function RemoveTrash($Items){
  $removed=@()
  foreach($target in @($Items)){
    if([string]::IsNullOrWhiteSpace([string]$target)){ continue }
    $removeTarget=[string]$target
    if((Test-Path $removeTarget) -and -not (Get-Item $removeTarget).PSIsContainer){ $removeTarget=Split-Path $removeTarget -Parent }
    if($removeTarget -and (Test-Path $removeTarget)){ Remove-Item $removeTarget -Recurse -Force; $removed += $removeTarget }
  }
  foreach($trashPath in @('.runtime/codex_curriculum_candidate_factory_runs','.runtime/file_atom_absorption','.runtime/memory_use_probes','.runtime/digestion_policy','.runtime/digestion_reports','operations/reports')){
    if(Test-Path $trashPath){ Remove-Item $trashPath -Recurse -Force; $removed += $trashPath }
  }
  return @($removed | Select-Object -Unique)
}
$runId="school_factory_digest_use_{0}_{1}_{2}" -f $RunKind.ToLowerInvariant(),$TargetAccepted,(Get-Date -Format 'yyyyMMdd_HHmmss')
$proofDir=".runtime/school_runs/$runId"
$proofPath="$proofDir/AGENT_SCHOOL_CANONICAL_ENTRYPOINT_V1.json"
$routePath='operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json'
$ledgerPath='operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json'
$routeBefore=Get-Content $routePath -Raw|ConvertFrom-Json
$ledgerBefore=Get-Content $ledgerPath -Raw|ConvertFrom-Json
$outerChunkSize=5000
if($env:EF_SCHOOL_OUTER_CHUNK_SIZE){ $outerChunkSize=[int]$env:EF_SCHOOL_OUTER_CHUNK_SIZE }
if($outerChunkSize -lt 1){ throw 'BAD_OUTER_CHUNK_SIZE' }
$innerBatchSizeMax=100
$cleanupRemoved=@(); $chunks=@(); $totalFactoryCandidates=0; $totalReadyAtoms=0; $totalStreamQuarantined=0; $lastProof=$null; $lastUseProof=$null
$chunkIndex=0; $remaining=$TargetAccepted
try {
  while($remaining -gt 0){
    $chunkIndex++
    $ordinalOffset=$TargetAccepted-$remaining
    $chunkTarget=[Math]::Min($outerChunkSize,$remaining)
    $batchSize=[Math]::Min($innerBatchSizeMax,[Math]::Max(1,$chunkTarget))
    $totalChunks=[int][Math]::Ceiling($TargetAccepted / $outerChunkSize)
    $chunkRunId="${runId}_chunk_${chunkIndex}_of_$totalChunks"
    $factoryOut=@(& powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/curriculum/candidate_factory/generate_codex_curriculum_candidate_factory_run_v1.ps1 -TargetAccepted $chunkTarget -RunKind Test -BatchSize $batchSize -RunId $chunkRunId -OrdinalOffset $ordinalOffset *>&1 | ForEach-Object {[string]$_})
    $factoryStatus=($factoryOut|Where-Object{$_ -match '^FACTORY_STATUS='}|Select-Object -Last 1) -replace '^FACTORY_STATUS=',''
    if($factoryStatus -ne 'PASS_CODEX_CANDIDATE_FACTORY_GENERATION_V1'){ throw "FACTORY_NOT_PASS:$factoryStatus" }
    $factoryReport=Get-Content operations/reports/CODEX_CANDIDATE_FACTORY_RUN_V1.json -Raw|ConvertFrom-Json
    & operations/school/curriculum/codex_contract/validate_codex_curriculum_contract_consistency_v1.ps1 -RunDir $factoryReport.run_dir | Out-Host
    $consistency=Get-Content operations/reports/CODEX_CURRICULUM_CONTRACT_CONSISTENCY_V1.json -Raw|ConvertFrom-Json
    if($consistency.status -ne 'PASS_CODEX_CURRICULUM_CONTRACT_CONSISTENCY_V1'){ throw "CONTRACT_NOT_PASS:$($consistency.status)" }
    & operations/school/curriculum/streaming_absorption/validate_codex_curriculum_streaming_absorption_v1.ps1 -RunDir $factoryReport.run_dir | Out-Host
    $stream=Get-Content operations/reports/STREAMING_SCHOOL_TO_ABSORPTION_PIPELINE_V1.json -Raw|ConvertFrom-Json
    if($stream.status -ne 'PASS_STREAMING_SCHOOL_TO_ABSORPTION_PIPELINE_V1'){ throw "STREAMING_NOT_PASS:$($stream.status)" }
    if([int]$stream.ready_atoms_total -ne $chunkTarget){ throw "READY_ATOMS_COUNT_BAD:$($stream.ready_atoms_total)" }
    $totalFactoryCandidates += [int]$factoryReport.candidates_created
    $totalReadyAtoms += [int]$stream.ready_atoms_total
    $totalStreamQuarantined += [int]$stream.stream_quarantined_total
    if($RunKind -eq 'Test'){
      $cleanupRemoved += RemoveTrash @($factoryReport.run_dir,'operations/reports')
      $chunks += [ordered]@{chunk_index=$chunkIndex; chunk_target=$chunkTarget; ordinal_offset=$ordinalOffset; inner_batch_size=$batchSize; factory_candidates=[int]$factoryReport.candidates_created; ready_atoms=[int]$stream.ready_atoms_total; digested=$false; recall_use=$false; cleanup_after_chunk=$true}
      $partial=[ordered]@{schema='agent_school_canonical_run_v6_chunked_cumulative'; status='RUNNING_CHUNKED_SCHOOL_PARTIAL_PROOF_V1'; run_id=$runId; run_kind=$RunKind; target_accepted=$TargetAccepted; outer_chunk_size=$outerChunkSize; inner_batch_size_max=$innerBatchSizeMax; chunk_count=@($chunks).Count; chunks=@($chunks); ready_atoms=$totalReadyAtoms; cleanup_after_each_chunk=$true; cleanup_removed=@($cleanupRemoved|Select-Object -Unique); runtime_ready=$false}
      WriteJson $proofPath $partial 100
      $remaining -= $chunkTarget
      continue
    }
    $budget=[Math]::Max(1600000,([Math]::Max($TargetAccepted,1000) * 1600))
    $pipeOut=@(& powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/digestion/absorb_atom_file_via_digest_pipeline_v1.ps1 -InputPath $stream.ready_lane_path -MemoryRoot '.runtime/active_compact_semantic_memory_v1' -ValidationTier Auto -SizeBudgetBytes $budget *>&1 | ForEach-Object {[string]$_})
    $pipeStatus=($pipeOut|Where-Object{$_ -match '^FILE_ATOM_ABSORPTION_STATUS='}|Select-Object -Last 1) -replace '^FILE_ATOM_ABSORPTION_STATUS=',''
    $pipeProofPath=($pipeOut|Where-Object{$_ -match '^PROOF_PATH='}|Select-Object -Last 1) -replace '^PROOF_PATH=',''
    if($pipeStatus -ne 'PASS_FILE_ATOM_ABSORPTION_PIPELINE_V1'){ throw "PIPELINE_NOT_PASS:$pipeStatus" }
    $pipeProof=Get-Content $pipeProofPath -Raw|ConvertFrom-Json
    if($pipeProof.cumulative_memory_merge -ne $true){ throw 'PIPELINE_CUMULATIVE_MEMORY_MERGE_NOT_PROVEN' }
    $routeMid=Get-Content $routePath -Raw|ConvertFrom-Json
    $ledgerMid=Get-Content $ledgerPath -Raw|ConvertFrom-Json
    if([int]$routeMid.routed_active_count -ne [int]$routeBefore.routed_active_count){ throw 'ROUTE_MUTATED_BY_REAL_FACTORY_DIGEST' }
    if([int]$ledgerMid.replayed_active_count -ne [int]$ledgerBefore.replayed_active_count){ throw 'LEDGER_MUTATED_BY_REAL_FACTORY_DIGEST' }
    $useTask="Chunk $chunkIndex of cumulative night school must prove compact memory is recalled and used before continuing."
    $useOut=@(& powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/memory/validate_compact_memory_recall_use_probe_v1.ps1 -MemoryRoot $pipeProof.memory_root -Task $useTask *>&1 | ForEach-Object {[string]$_})
    $useStatus=($useOut|Where-Object{$_ -match '^VALIDATION_PASS=COMPACT_MEMORY_RECALL_USE_PROBE_V1_VALID$'}|Select-Object -Last 1)
    $useProofPath=($useOut|Where-Object{$_ -match '^PROOF_PATH='}|Select-Object -Last 1) -replace '^PROOF_PATH=',''
    if($useStatus -ne 'VALIDATION_PASS=COMPACT_MEMORY_RECALL_USE_PROBE_V1_VALID'){ throw 'RECALL_USE_GATE_NOT_PASS' }
    if([string]::IsNullOrWhiteSpace($useProofPath) -or -not (Test-Path $useProofPath)){ throw 'RECALL_USE_PROOF_MISSING' }
    $useProof=Get-Content $useProofPath -Raw|ConvertFrom-Json
    if($useProof.behavior_delta -ne $true){ throw 'BEHAVIOR_DELTA_NOT_PROVEN' }
    $chunks += [ordered]@{chunk_index=$chunkIndex; chunk_target=$chunkTarget; ordinal_offset=$ordinalOffset; inner_batch_size=$batchSize; factory_candidates=[int]$factoryReport.candidates_created; ready_atoms=[int]$stream.ready_atoms_total; digested=$true; digested_cells=[int]$pipeProof.digested_cells; merged_count=[int]$pipeProof.merged_count; cumulative_memory_merge=$pipeProof.cumulative_memory_merge; existing_memory_seeded=$pipeProof.existing_memory_seeded; existing_memory_cells_before=[int]$pipeProof.existing_memory_cells_before; total_memory_bytes=[int]$pipeProof.total_memory_bytes; recall_use_status=$useProof.status; behavior_delta=$useProof.behavior_delta; used_memory_cells_count=@($useProof.used_labels).Count; cleanup_after_chunk=$true}
    $lastProof=$pipeProof; $lastUseProof=$useProof
    $cleanupRemoved += RemoveTrash @($factoryReport.run_dir,$pipeProofPath,$pipeProof.candidate_memory_root,$useProofPath,'operations/reports')
    $partial=[ordered]@{schema='agent_school_canonical_run_v6_chunked_cumulative'; status='RUNNING_CHUNKED_SCHOOL_PARTIAL_PROOF_V1'; run_id=$runId; run_kind=$RunKind; target_accepted=$TargetAccepted; outer_chunk_size=$outerChunkSize; inner_batch_size_max=$innerBatchSizeMax; chunk_count=@($chunks).Count; chunks=@($chunks); ready_atoms=$totalReadyAtoms; cleanup_after_each_chunk=$true; cleanup_removed=@($cleanupRemoved|Select-Object -Unique); runtime_ready=$false}
    WriteJson $proofPath $partial 100
    $remaining -= $chunkTarget
  }
} catch {
  $cleanupRemoved += RemoveTrash @('.runtime/codex_curriculum_candidate_factory_runs','.runtime/file_atom_absorption','.runtime/memory_use_probes','.runtime/digestion_policy','.runtime/digestion_reports','operations/reports')
  $fail=[ordered]@{schema='agent_school_canonical_run_v6_chunked_cumulative'; status='FAIL_CHUNKED_SCHOOL_CLEANED_TRANSIENTS_V1'; run_id=$runId; run_kind=$RunKind; target_accepted=$TargetAccepted; outer_chunk_size=$outerChunkSize; inner_batch_size_max=$innerBatchSizeMax; chunk_count=@($chunks).Count; chunks=@($chunks); error=$_.Exception.Message; cleanup_removed=@($cleanupRemoved|Select-Object -Unique); runtime_ready=$false}
  WriteJson $proofPath $fail 100
  throw
}
$routeAfter=Get-Content $routePath -Raw|ConvertFrom-Json
$ledgerAfter=Get-Content $ledgerPath -Raw|ConvertFrom-Json
if([int]$routeAfter.routed_active_count -ne [int]$routeBefore.routed_active_count){ throw 'ROUTE_MUTATED_BY_RUN' }
if([int]$ledgerAfter.replayed_active_count -ne [int]$ledgerBefore.replayed_active_count){ throw 'LEDGER_MUTATED_BY_RUN' }
$base=[ordered]@{schema='agent_school_canonical_run_v6_chunked_cumulative'; run_id=$runId; run_kind=$RunKind; target_accepted=$TargetAccepted; outer_chunk_size=$outerChunkSize; inner_batch_size_max=$innerBatchSizeMax; chunk_count=@($chunks).Count; chunks=@($chunks); runtime_ready=$false; raw_route_absorption_allowed=$false; factory_candidates_created=$totalFactoryCandidates; ready_atoms=$totalReadyAtoms; stream_quarantined=$totalStreamQuarantined; codex_cli_invoked=$false; api_invoked=$false; route_before=[int]$routeBefore.routed_active_count; ledger_before=[int]$ledgerBefore.replayed_active_count; route_after=[int]$routeAfter.routed_active_count; ledger_after=[int]$ledgerAfter.replayed_active_count; retention_policy='KEEP_ACTIVE_COMPACT_MEMORY_AND_CANONICAL_PROOF_ONLY_V1'; cleanup_removed=@($cleanupRemoved|Select-Object -Unique); cleanup_after_each_chunk=$true; law='TargetAccepted + RunKind uses outer chunks of 5000 and inner factory batches of 100. Real uses cumulative compact semantic memory and cannot continue past a chunk without recall/use behavior_delta proof.'}
if($RunKind -eq 'Test'){
  $base.status='PASS_TEST_FACTORY_STREAMING_READY_V1'; $base.digested_knowledge_mutated=$false; $base.recall_use_required=$false; $base.behavior_delta=$false; $base.boundary='Test validates existing factory and streaming ready lane only. It does not digest or mutate compact memory.'
} else {
  if($null -eq $lastProof -or $null -eq $lastUseProof){ throw 'REAL_FINAL_PROOF_MISSING' }
  $base.status='PASS_REAL_FACTORY_DIGEST_RECALL_USE_V1'; $base.digested_knowledge_mutated=$true; $base.pipeline_status=$lastProof.status; $base.validation_tier=$lastProof.selected_validation_tier; $base.digested_cells=[int]$lastProof.digested_cells; $base.merged_count=[int]$lastProof.merged_count; $base.raw_source_dependency_removed=$lastProof.raw_source_dependency_removed; $base.total_memory_bytes=[int]$lastProof.total_memory_bytes; $base.memory_root=$lastProof.memory_root; $base.cumulative_memory_merge=$lastProof.cumulative_memory_merge; $base.existing_memory_seeded=$lastProof.existing_memory_seeded; $base.existing_memory_cells_before=[int]$lastProof.existing_memory_cells_before; $base.recall_use_status=$lastUseProof.status; $base.used_memory_cells=@($lastUseProof.used_labels); $base.baseline_decision=$lastUseProof.baseline_decision; $base.active_decision=$lastUseProof.active_decision; $base.behavior_delta=$lastUseProof.behavior_delta; $base.boundary='Real uses chunked factory output, streaming ready_atoms, cumulative compact semantic memory, recall/use proof after every chunk, and in-run transient cleanup.'
}
WriteJson $proofPath $base 100
Write-Host "SCHOOL_RUN_STATUS=$($base.status)"
Write-Host "PROOF_PATH=$proofPath"
Write-Host "TARGET_ACCEPTED=$TargetAccepted"
Write-Host "RUN_KIND=$RunKind"
Write-Host "OUTER_CHUNK_SIZE=$outerChunkSize"
Write-Host "INNER_BATCH_SIZE_MAX=$innerBatchSizeMax"
Write-Host "CHUNK_COUNT=$($base.chunk_count)"
Write-Host "FACTORY_CANDIDATES=$totalFactoryCandidates"
Write-Host "READY_ATOMS=$totalReadyAtoms"
Write-Host "CUMULATIVE_MEMORY_MERGE=$($base.cumulative_memory_merge)"
Write-Host "DIGESTED_CELLS=$($base.digested_cells)"
Write-Host "MERGED_COUNT=$($base.merged_count)"
Write-Host "TOTAL_MEMORY_BYTES=$($base.total_memory_bytes)"
Write-Host "RECALL_USE_STATUS=$($base.recall_use_status)"
Write-Host "BEHAVIOR_DELTA=$($base.behavior_delta)"
Write-Host "ROUTE_AFTER=$($base.route_after)"
Write-Host "LEDGER_AFTER=$($base.ledger_after)"
Write-Host 'RUNTIME_READY=false'