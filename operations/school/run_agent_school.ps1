param(
  [Parameter(Mandatory=$true)][ValidateRange(1,1000000)][int]$TargetAccepted,
  [Parameter(Mandatory=$true)][ValidateSet('Test','Real')][string]$RunKind
)
$ErrorActionPreference='Stop'
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
function EnsureDir($Path){ if(-not (Test-Path $Path)){ New-Item -ItemType Directory -Force $Path | Out-Null } }
function WriteJson($Path,$Obj,$Depth=80){ $d=Split-Path $Path -Parent; if($d){ EnsureDir $d }; [IO.File]::WriteAllText((Join-Path (Get-Location).Path $Path),($Obj|ConvertTo-Json -Depth $Depth),$utf8) }
$runId="school_factory_digest_{0}_{1}_{2}" -f $RunKind.ToLowerInvariant(),$TargetAccepted,(Get-Date -Format 'yyyyMMdd_HHmmss')
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
  schema='agent_school_canonical_run_v4'
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
  law='TargetAccepted + RunKind must use the existing candidate factory and streaming lane. No synthetic seed route is allowed.'
}
if($RunKind -eq 'Test'){
  $base.status='PASS_TEST_FACTORY_STREAMING_READY_V1'
  $base.accepted_total=0
  $base.digested_knowledge_mutated=$false
  $base.boundary='Test validates existing factory and streaming ready lane only. It does not digest or mutate compact memory.'
  WriteJson $proofPath $base 80
  Write-Host 'SCHOOL_RUN_STATUS=PASS_TEST_FACTORY_STREAMING_READY_V1'
  Write-Host "PROOF_PATH=$proofPath"
  Write-Host "TARGET_ACCEPTED=$TargetAccepted"
  Write-Host "RUN_KIND=$RunKind"
  Write-Host "FACTORY_CANDIDATES=$($base.factory_candidates_created)"
  Write-Host "READY_ATOMS=$($base.ready_atoms)"
  Write-Host 'DIGESTED_KNOWLEDGE_MUTATED=false'
  Write-Host 'RUNTIME_READY=false'
  return
}
$budget=[Math]::Max(80000,($TargetAccepted * 1600))
$pipeOut=@(& powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/digestion/absorb_atom_file_via_digest_pipeline_v1.ps1 -InputPath $stream.ready_lane_path -MemoryRoot '.runtime/active_compact_semantic_memory_v1' -ValidationTier Auto -SizeBudgetBytes $budget *>&1 | ForEach-Object {[string]$_})
$pipeStatus=($pipeOut|Where-Object{$_ -match '^FILE_ATOM_ABSORPTION_STATUS='}|Select-Object -Last 1) -replace '^FILE_ATOM_ABSORPTION_STATUS=',''
$pipeProofPath=($pipeOut|Where-Object{$_ -match '^PROOF_PATH='}|Select-Object -Last 1) -replace '^PROOF_PATH=',''
if($pipeStatus -ne 'PASS_FILE_ATOM_ABSORPTION_PIPELINE_V1'){ throw "PIPELINE_NOT_PASS:$pipeStatus" }
$pipeProof=Get-Content $pipeProofPath -Raw|ConvertFrom-Json
$routeAfter=Get-Content $routePath -Raw|ConvertFrom-Json
$ledgerAfter=Get-Content $ledgerPath -Raw|ConvertFrom-Json
if([int]$routeAfter.routed_active_count -ne [int]$routeBefore.routed_active_count){ throw 'ROUTE_MUTATED_BY_REAL_FACTORY_DIGEST' }
if([int]$ledgerAfter.replayed_active_count -ne [int]$ledgerBefore.replayed_active_count){ throw 'LEDGER_MUTATED_BY_REAL_FACTORY_DIGEST' }
$base.status='PASS_REAL_FACTORY_TO_DIGEST_ABSORPTION_V1'
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
$base.route_after=[int]$routeAfter.routed_active_count
$base.ledger_after=[int]$ledgerAfter.replayed_active_count
$base.boundary='Real uses existing candidate factory output, streaming ready_atoms, and digest pipeline. Synthetic seed generation is not part of the canonical route.'
WriteJson $proofPath $base 100
Write-Host 'SCHOOL_RUN_STATUS=PASS_REAL_FACTORY_TO_DIGEST_ABSORPTION_V1'
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
Write-Host "ROUTE_AFTER=$($base.route_after)"
Write-Host "LEDGER_AFTER=$($base.ledger_after)"
Write-Host 'RUNTIME_READY=false'