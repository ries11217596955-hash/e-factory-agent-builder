param(
  [string]$MemoryRoot = '.runtime/active_compact_semantic_memory_v1',
  [string]$Task = 'Owner asks to launch a large medical candidate factory run without source acquisition; decide whether factory output can be treated as knowledge.'
)
$ErrorActionPreference='Stop'
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$queryTerms='source ladder no external brain count not learning guard generated candidates factual knowledge factory source proof'
$out=@(& powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/memory/query_compact_semantic_memory_v1.ps1 -MemoryRoot $MemoryRoot -Query $queryTerms -Top 12 *>&1 | ForEach-Object {[string]$_})
$out | ForEach-Object { Write-Host "RECALL|$_" }
if(-not ($out -contains 'MEMORY_RECALL_STATUS=PASS_COMPACT_MEMORY_RECALL_V1')){ throw 'RECALL_FAILED' }
$labels=@()
foreach($line in $out){ if($line -match '^MATCH\|\d+\|.*\|label=([^|]+\|[^|]+\|[^|]+)\|'){ $labels += $Matches[1] } }
$hasSourceLadder=@($labels | Where-Object { $_ -match 'source_ladder' }).Count -gt 0
$hasNoExternal=@($labels | Where-Object { $_ -match 'no_external_brain' }).Count -gt 0
$hasCountNotLearning=@($labels | Where-Object { $_ -match 'count_not_learning' }).Count -gt 0
if($hasSourceLadder -and ($hasNoExternal -or $hasCountNotLearning)){ $decision='BLOCK_AS_WORLD_KNOWLEDGE_REQUIRE_SOURCE_ACQUISITION' } else { $decision='INSUFFICIENT_MEMORY_FOR_DECISION' }
if($decision -eq 'BLOCK_AS_WORLD_KNOWLEDGE_REQUIRE_SOURCE_ACQUISITION'){ $status='VALIDATION_PASS=COMPACT_MEMORY_RECALL_USE_PROBE_V1_VALID' } else { $status='VALIDATION_FAIL=COMPACT_MEMORY_RECALL_USE_PROBE_V1' }
$report=[ordered]@{
  schema='compact_memory_recall_use_probe_v1'
  status=$status
  task=$Task
  query_terms=$queryTerms
  used_labels=@($labels)
  has_source_ladder=$hasSourceLadder
  has_no_external_brain=$hasNoExternal
  has_count_not_learning=$hasCountNotLearning
  decision=$decision
  boundary='This proves read-only recall/use from compact memory for a decision probe. It does not prove live autonomous behavior.'
  runtime_ready=$false
}
$proofDir='.runtime/memory_use_probes'
if(-not (Test-Path $proofDir)){ New-Item -ItemType Directory -Force $proofDir | Out-Null }
$proofPath=Join-Path $proofDir ('COMPACT_MEMORY_RECALL_USE_PROBE_V1_' + (Get-Date -Format yyyyMMdd_HHmmss) + '.json')
$report | ConvertTo-Json -Depth 60 | Set-Content -Path $proofPath -Encoding UTF8
Write-Host $status
Write-Host "PROOF_PATH=$proofPath"
Write-Host "TASK=$Task"
Write-Host "DECISION=$decision"
Write-Host "HAS_SOURCE_LADDER=$hasSourceLadder"
Write-Host "HAS_NO_EXTERNAL_BRAIN=$hasNoExternal"
Write-Host "HAS_COUNT_NOT_LEARNING=$hasCountNotLearning"
Write-Host "USED_LABELS=$($labels -join ';')"
Write-Host 'RUNTIME_READY=false'
if($decision -ne 'BLOCK_AS_WORLD_KNOWLEDGE_REQUIRE_SOURCE_ACQUISITION'){ exit 2 }