param(
  [Parameter(Mandatory=$true)][ValidateRange(1,1000000)][int]$TargetAccepted,
  [Parameter(Mandatory=$true)][ValidateSet('Test','Real')][string]$RunKind
)
$ErrorActionPreference='Stop'
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
function WriteJson($Path,$Obj,$Depth=40){
  $dir=Split-Path $Path -Parent
  if($dir -and -not (Test-Path $dir)){ New-Item -ItemType Directory -Force $dir | Out-Null }
  [IO.File]::WriteAllText((Join-Path (Get-Location).Path $Path),($Obj|ConvertTo-Json -Depth $Depth),$utf8)
}
$runId="school_digest_gate_{0}_{1}" -f $RunKind.ToLowerInvariant(),(Get-Date -Format 'yyyyMMdd_HHmmss')
$proofDir=".runtime/school_runs/$runId"
$proofPath="$proofDir/AGENT_SCHOOL_CANONICAL_ENTRYPOINT_V1.json"
$routePath='operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json'
$ledgerPath='operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json'
$route=$null; $ledger=$null
if(Test-Path $routePath){ $route=Get-Content $routePath -Raw|ConvertFrom-Json }
if(Test-Path $ledgerPath){ $ledger=Get-Content $ledgerPath -Raw|ConvertFrom-Json }
$base=[ordered]@{
  schema='agent_school_canonical_run_v2'
  run_id=$runId
  run_kind=$RunKind
  target_accepted=$TargetAccepted
  runtime_ready=$false
  accepted_core_mutated=$false
  digested_knowledge_mutated=$false
  raw_route_absorption_allowed=$false
  route_status=if($route){$route.status}else{'UNKNOWN'}
  route_count=if($route){[int]$route.routed_active_count}else{0}
  ledger_status=if($ledger){$ledger.status}else{'UNKNOWN'}
  ledger_count=if($ledger){[int]$ledger.replayed_active_count}else{0}
  chunks=@()
  law='Absorbed means digested into compact semantic memory with no raw-source dependency. Raw ready/candidate/staging rows are not intelligence.'
}
if($RunKind -eq 'Test'){
  $base.status='PASS_TEST_STAGING_ONLY_DIGEST_REQUIRED_V1'
  $base.accepted_total=0
  $base.staged_total=$TargetAccepted
  $base.chunks=@([ordered]@{
    ordinal=1
    target=$TargetAccepted
    mode='STAGING_PROBE_ONLY'
    raw_source_disposable_after_test=$true
    active_memory_claim=$false
    digested_knowledge_claim=$false
  })
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
$base.status='BLOCKED_DIGESTION_ORGAN_REQUIRED_V1'
$base.accepted_total=0
$base.staged_total=0
$base.blockers=@(
  'COMPACT_SEMANTIC_DIGESTION_ORGAN_MISSING',
  'NO_RAW_SOURCE_DEPENDENCY_GATE_MISSING',
  'DIGESTED_KNOWLEDGE_LOOKUP_PROOF_MISSING',
  'RAW_STAGING_CLEANUP_PROOF_MISSING'
)
$base.required_next='Build digest organ: raw candidate -> compact semantic cell -> lookup/use proof -> raw source deleted. Only then Real can accept atoms.'
$base.boundary='Real is blocked by design. Old route/ready-lane absorption is deprecated and must not mutate active memory.'
WriteJson $proofPath $base 60
Write-Host 'SCHOOL_RUN_STATUS=BLOCKED_DIGESTION_ORGAN_REQUIRED_V1'
Write-Host "PROOF_PATH=$proofPath"
Write-Host "TARGET_ACCEPTED=$TargetAccepted"
Write-Host "RUN_KIND=$RunKind"
Write-Host 'ACCEPTED_TOTAL=0'
Write-Host 'RUNTIME_READY=false'
exit 2