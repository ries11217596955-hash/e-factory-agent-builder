param(
  [Parameter(Mandatory=$true)][ValidateRange(1,1000000)][int]$TargetAccepted,
  [Parameter(Mandatory=$true)][ValidateSet('Test','Real')][string]$RunKind
)
$ErrorActionPreference='Stop'
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
function EnsureDir($Path){ if(-not (Test-Path $Path)){ New-Item -ItemType Directory -Force $Path | Out-Null } }
function WriteText($Path,$Text){ $d=Split-Path $Path -Parent; if($d){ EnsureDir $d }; [IO.File]::WriteAllText((Join-Path (Get-Location).Path $Path),$Text,$utf8) }
function WriteJson($Path,$Obj,$Depth=60){ $d=Split-Path $Path -Parent; if($d){ EnsureDir $d }; [IO.File]::WriteAllText((Join-Path (Get-Location).Path $Path),($Obj|ConvertTo-Json -Depth $Depth),$utf8) }
$runId="school_digest_real_{0}_{1}" -f $RunKind.ToLowerInvariant(),(Get-Date -Format 'yyyyMMdd_HHmmss')
$proofDir=".runtime/school_runs/$runId"
$proofPath="$proofDir/AGENT_SCHOOL_CANONICAL_ENTRYPOINT_V1.json"
$routePath='operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json'
$ledgerPath='operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json'
$route=Get-Content $routePath -Raw|ConvertFrom-Json
$ledger=Get-Content $ledgerPath -Raw|ConvertFrom-Json
$base=[ordered]@{
  schema='agent_school_canonical_run_v3'
  run_id=$runId
  run_kind=$RunKind
  target_accepted=$TargetAccepted
  runtime_ready=$false
  accepted_core_mutated=$false
  raw_route_absorption_allowed=$false
  route_status=$route.status
  route_count=[int]$route.routed_active_count
  ledger_status=$ledger.status
  ledger_count=[int]$ledger.replayed_active_count
  law='Real absorption must pass through file atom pipeline -> compact semantic digestion -> raw source cleanup. Route/ledger are not intelligence.'
}
if($RunKind -eq 'Test'){
  $base.status='PASS_TEST_STAGING_ONLY_DIGEST_REQUIRED_V1'
  $base.accepted_total=0
  $base.staged_total=$TargetAccepted
  $base.digested_knowledge_mutated=$false
  $base.boundary='Test may exercise staging mechanics only. It must not claim absorption, intelligence growth, route growth, or durable memory.'
  WriteJson $proofPath $base 60
  Write-Host 'SCHOOL_RUN_STATUS=PASS_TEST_STAGING_ONLY_DIGEST_REQUIRED_V1'
  Write-Host "PROOF_PATH=$proofPath"
  Write-Host "TARGET_ACCEPTED=$TargetAccepted"
  Write-Host "RUN_KIND=$RunKind"
  Write-Host 'ACCEPTED_TOTAL=0'
  Write-Host "STAGED_TOTAL=$TargetAccepted"
  Write-Host 'RUNTIME_READY=false'
  return
}
EnsureDir "$proofDir/input"
$inputPath="$proofDir/input/real_atoms.jsonl"
$seed=@(
  @{concept_key='vehicle.car';label='car';aliases=@('automobile','auto');definition='A car is a road vehicle used to transport people or goods.';properties=@('road vehicle','wheels','transport');relations=@('is_a:vehicle','used_for:transport');uses=@('travel','delivery')},
  @{concept_key='vehicle.car';label='automobile';aliases=@('car');definition='An automobile is a vehicle for road transport.';properties=@('engine or motor','passenger cabin');relations=@('is_a:vehicle');uses=@('commuting')},
  @{concept_key='vehicle.wheel';label='wheel';definition='A wheel is a round component that rotates to help a vehicle move.';properties=@('round','rotates');relations=@('part_of:vehicle');uses=@('movement')},
  @{concept_key='vehicle.engine';label='engine';definition='An engine converts energy into motion for a machine or vehicle.';properties=@('power source','motion');relations=@('can_power:car');uses=@('propulsion')},
  @{concept_key='road';label='road';definition='A road is a prepared path used by vehicles and people for travel.';properties=@('path','transport surface');relations=@('used_by:vehicle');uses=@('navigation')},
  @{concept_key='transport';label='transport';definition='Transport is the movement of people or goods from one place to another.';properties=@('movement','people','goods');relations=@('purpose_of:vehicle');uses=@('logistics')},
  @{concept_key='vehicle.bicycle';label='bicycle';definition='A bicycle is a human-powered vehicle with two wheels.';properties=@('two wheels','human powered');relations=@('is_a:vehicle');uses=@('travel')},
  @{concept_key='vehicle.electric_car';label='electric car';definition='An electric car is a car powered by one or more electric motors.';properties=@('electric motor','battery');relations=@('is_a:vehicle.car');uses=@('low-emission travel')},
  @{concept_key='battery';label='battery';definition='A battery stores electrical energy for later use.';properties=@('stores energy','electrical');relations=@('can_power:electric car');uses=@('energy storage')},
  @{concept_key='driver';label='driver';definition='A driver controls a vehicle.';properties=@('operator');relations=@('controls:vehicle');uses=@('safe operation')}
)
$rows=@()
for($i=0;$i -lt $TargetAccepted;$i++){
  $r=$seed[$i % $seed.Count].Clone()
  $r.observation_id="school_real_$i"
  $rows += [pscustomobject]$r
}
$jsonl=($rows | ForEach-Object { $_|ConvertTo-Json -Depth 20 -Compress }) -join "`n"
WriteText $inputPath ($jsonl + "`n")
$budget=[Math]::Max(80000,($TargetAccepted * 1000))
$pipeOut=@(& powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/digestion/absorb_atom_file_via_digest_pipeline_v1.ps1 -InputPath $inputPath -MemoryRoot '.runtime/active_compact_semantic_memory_v1' -ValidationTier Auto -SizeBudgetBytes $budget -DeleteOriginalRaw *>&1 | ForEach-Object {[string]$_})
$pipeStatus=($pipeOut|Where-Object{$_ -match '^FILE_ATOM_ABSORPTION_STATUS='}|Select-Object -Last 1) -replace '^FILE_ATOM_ABSORPTION_STATUS=',''
$pipeProofPath=($pipeOut|Where-Object{$_ -match '^PROOF_PATH='}|Select-Object -Last 1) -replace '^PROOF_PATH=',''
if($pipeStatus -ne 'PASS_FILE_ATOM_ABSORPTION_PIPELINE_V1'){ throw "PIPELINE_NOT_PASS:$pipeStatus" }
$pipeProof=Get-Content $pipeProofPath -Raw|ConvertFrom-Json
$routeAfter=Get-Content $routePath -Raw|ConvertFrom-Json
$ledgerAfter=Get-Content $ledgerPath -Raw|ConvertFrom-Json
$base.status='PASS_REAL_FILE_ATOM_DIGEST_ABSORPTION_V1'
$base.accepted_total=0
$base.staged_total=[int]$pipeProof.input_atoms
$base.digested_cells=[int]$pipeProof.digested_cells
$base.merged_count=[int]$pipeProof.merged_count
$base.digested_knowledge_mutated=$true
$base.pipeline_status=$pipeProof.status
$base.pipeline_proof_path=$pipeProofPath
$base.validation_tier=$pipeProof.selected_validation_tier
$base.raw_source_dependency_removed=$pipeProof.raw_source_dependency_removed
$base.staged_raw_deleted=$pipeProof.staged_raw_deleted
$base.original_raw_deleted=$pipeProof.original_raw_deleted
$base.total_memory_bytes=$pipeProof.total_memory_bytes
$base.memory_root=$pipeProof.memory_root
$base.route_after=[int]$routeAfter.routed_active_count
$base.ledger_after=[int]$ledgerAfter.replayed_active_count
$base.boundary='Real now means file atoms digested into compact semantic memory. Raw route append remains forbidden.'
WriteJson $proofPath $base 80
Write-Host 'SCHOOL_RUN_STATUS=PASS_REAL_FILE_ATOM_DIGEST_ABSORPTION_V1'
Write-Host "PROOF_PATH=$proofPath"
Write-Host "TARGET_ACCEPTED=$TargetAccepted"
Write-Host "RUN_KIND=$RunKind"
Write-Host "STAGED_TOTAL=$($base.staged_total)"
Write-Host "DIGESTED_CELLS=$($base.digested_cells)"
Write-Host "MERGED_COUNT=$($base.merged_count)"
Write-Host "VALIDATION_TIER=$($base.validation_tier)"
Write-Host "RAW_SOURCE_DEPENDENCY_REMOVED=$($base.raw_source_dependency_removed)"
Write-Host "TOTAL_MEMORY_BYTES=$($base.total_memory_bytes)"
Write-Host 'RUNTIME_READY=false'