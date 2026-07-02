param(
  [Parameter(Mandatory=$true)][string]$InputPath,
  [string]$MemoryRoot = '.runtime/active_compact_semantic_memory_v1',
  [ValidateSet('Auto','Fast','Stable','Full')][string]$ValidationTier = 'Auto',
  [int]$SizeBudgetBytes = 1048576,
  [switch]$DeleteOriginalRaw
)
$ErrorActionPreference='Stop'
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
function EnsureDir($Path){ if(-not (Test-Path $Path)){ New-Item -ItemType Directory -Force $Path | Out-Null } }
function WriteText($Path,$Text){ $d=Split-Path $Path -Parent; if($d){ EnsureDir $d }; [IO.File]::WriteAllText((Join-Path (Get-Location).Path $Path),$Text,$utf8) }
function WriteJson($Path,$Obj,$Depth=80){ WriteText $Path ($Obj|ConvertTo-Json -Depth $Depth) }
function FileSha256($Path){
  $sha=[System.Security.Cryptography.SHA256]::Create()
  $fs=[IO.File]::OpenRead((Resolve-Path $Path).Path)
  try { (($sha.ComputeHash($fs)|ForEach-Object{$_.ToString('x2')}) -join '') } finally { $fs.Dispose() }
}
if(-not (Test-Path $InputPath)){ throw "INPUT_FILE_MISSING:$InputPath" }
$resolvedInput=(Resolve-Path $InputPath).Path
$repoRuntime=(Join-Path $repoRoot '.runtime')
$runId="file_atom_absorption_$(Get-Date -Format yyyyMMdd_HHmmss)"
$runRoot=".runtime/file_atom_absorption/$runId"
$stagingDir="$runRoot/staging"
EnsureDir $stagingDir
$stagedInput="$stagingDir/raw_atoms.jsonl"
Copy-Item -Path $InputPath -Destination $stagedInput -Force
$rows=@()
$lineNo=0
Get-Content $stagedInput | ForEach-Object {
  $line=[string]$_
  if([string]::IsNullOrWhiteSpace($line)){ return }
  $lineNo++
  try { $rows += ($line | ConvertFrom-Json) } catch { throw "BAD_ATOM_JSONL_LINE:${lineNo}:$($_.Exception.Message)" }
}
if($rows.Count -lt 1){ throw 'NO_ATOMS_IN_FILE' }
foreach($r in $rows){
  $hasConcept=$false
  foreach($p in @('concept_key','concept','label','title','text')){ if($r.PSObject.Properties[$p] -and -not [string]::IsNullOrWhiteSpace([string]$r.PSObject.Properties[$p].Value)){ $hasConcept=$true } }
  if(-not $hasConcept){ throw 'ATOM_MISSING_CONCEPT_FIELD' }
}
$policyOut=@(& powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/digestion/select_compact_semantic_digest_validation_budget_v1.ps1 -RequestedTier $ValidationTier -IncomingAtoms $rows.Count *>&1 | ForEach-Object {[string]$_})
$selectedTier=($policyOut|Where-Object{$_ -match '^SELECTED_TIER='}|Select-Object -Last 1) -replace '^SELECTED_TIER=',''
if([string]::IsNullOrWhiteSpace($selectedTier)){ throw 'VALIDATION_POLICY_TIER_MISSING' }
$routeBefore=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json -Raw|ConvertFrom-Json
$ledgerBefore=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json -Raw|ConvertFrom-Json
$inputSha=FileSha256 $stagedInput
$digestOut=@(& powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/digestion/invoke_compact_semantic_digestion_organ_v1.ps1 -InputPath $stagedInput -MemoryRoot $MemoryRoot -RunId $runId -CleanupRawSource -SizeBudgetBytes $SizeBudgetBytes *>&1 | ForEach-Object {[string]$_})
$digestStatus=($digestOut|Where-Object{$_ -match '^DIGEST_STATUS='}|Select-Object -Last 1) -replace '^DIGEST_STATUS=',''
if($digestStatus -ne 'PASS_COMPACT_SEMANTIC_DIGESTION_ORGAN_V1'){ throw "DIGEST_NOT_PASS:$digestStatus" }
$manifest=Get-Content (Join-Path $MemoryRoot 'manifest.json') -Raw|ConvertFrom-Json
$index=Get-Content (Join-Path $MemoryRoot 'index.json') -Raw|ConvertFrom-Json
$cellsPath=Join-Path $MemoryRoot 'cells.jsonl'
$cells=@(Get-Content $cellsPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_|ConvertFrom-Json })
if(Test-Path $stagedInput){ throw 'STAGED_RAW_SOURCE_NOT_DELETED' }
if($manifest.raw_source_dependency_removed -ne $true){ throw 'RAW_SOURCE_DEPENDENCY_NOT_REMOVED' }
if([int]$manifest.total_memory_bytes -gt $SizeBudgetBytes){ throw 'SIZE_BUDGET_EXCEEDED_AFTER_DIGEST' }
if([int]$index.term_count -lt 1){ throw 'LOOKUP_INDEX_EMPTY' }
if($selectedTier -ne 'Fast'){
  foreach($c in $cells){
    $j=$c|ConvertTo-Json -Depth 50 -Compress
    foreach($bad in @('raw_text','source_text','ready_atoms','batch_trace','prompt_trace')){ if($j -match $bad){ throw "RAW_FIELD_SURVIVED:$bad" } }
  }
}
$originalDeleted=$false
if($DeleteOriginalRaw){
  if(-not ($resolvedInput.StartsWith($repoRuntime,[System.StringComparison]::OrdinalIgnoreCase))){ throw 'REFUSE_DELETE_ORIGINAL_OUTSIDE_RUNTIME' }
  if(Test-Path $resolvedInput){ Remove-Item $resolvedInput -Force }
  $originalDeleted=(-not (Test-Path $resolvedInput))
}
$routeAfter=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json -Raw|ConvertFrom-Json
$ledgerAfter=Get-Content operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json -Raw|ConvertFrom-Json
if([int]$routeBefore.routed_active_count -ne [int]$routeAfter.routed_active_count){ throw 'ROUTE_MUTATED_BY_FILE_ABSORPTION' }
if([int]$ledgerBefore.replayed_active_count -ne [int]$ledgerAfter.replayed_active_count){ throw 'LEDGER_MUTATED_BY_FILE_ABSORPTION' }
$report=[ordered]@{
  schema='file_atom_absorption_pipeline_v1'
  status='PASS_FILE_ATOM_ABSORPTION_PIPELINE_V1'
  run_id=$runId
  input_path=$resolvedInput
  input_sha256=$inputSha
  input_atoms=$rows.Count
  selected_validation_tier=$selectedTier
  memory_root=$MemoryRoot
  digest_status=$digestStatus
  digested_cells=[int]$manifest.cell_count
  merged_count=[int]$manifest.merged_count
  total_memory_bytes=[int]$manifest.total_memory_bytes
  size_budget_bytes=$SizeBudgetBytes
  staged_raw_deleted=(-not (Test-Path $stagedInput))
  original_raw_deleted=$originalDeleted
  raw_source_dependency_removed=$true
  lookup_term_count=[int]$index.term_count
  route_before=[int]$routeBefore.routed_active_count
  route_after=[int]$routeAfter.routed_active_count
  ledger_before=[int]$ledgerBefore.replayed_active_count
  ledger_after=[int]$ledgerAfter.replayed_active_count
  route_ledger_mutated=$false
  runtime_ready=$false
  boundary='File atoms absorbed only as compact semantic memory. Raw staging source is disposable and deleted; route/ledger are not intelligence stores.'
}
$proofPath="$runRoot/FILE_ATOM_ABSORPTION_PIPELINE_V1.json"
WriteJson $proofPath $report 80
Write-Host 'FILE_ATOM_ABSORPTION_STATUS=PASS_FILE_ATOM_ABSORPTION_PIPELINE_V1'
Write-Host "PROOF_PATH=$proofPath"
Write-Host "INPUT_ATOMS=$($rows.Count)"
Write-Host "DIGESTED_CELLS=$($report.digested_cells)"
Write-Host "MERGED_COUNT=$($report.merged_count)"
Write-Host "VALIDATION_TIER=$selectedTier"
Write-Host "RAW_SOURCE_DEPENDENCY_REMOVED=$($report.raw_source_dependency_removed)"
Write-Host "STAGED_RAW_DELETED=$($report.staged_raw_deleted)"
Write-Host "ORIGINAL_RAW_DELETED=$($report.original_raw_deleted)"
Write-Host "TOTAL_MEMORY_BYTES=$($report.total_memory_bytes)"
Write-Host "ROUTE_AFTER=$($report.route_after)"
Write-Host "LEDGER_AFTER=$($report.ledger_after)"
Write-Host 'RUNTIME_READY=false'