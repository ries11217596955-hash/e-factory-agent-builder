param(
  [Parameter(Mandatory=$true)][ValidateRange(1,1000000)][int]$TargetAccepted,
  [Parameter(Mandatory=$true)][ValidateSet('Test','Real')][string]$RunKind
)
$ErrorActionPreference='Stop'
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
function WriteJson($p,$o,$d=100){$dir=Split-Path -Parent $p; if($dir){New-Item -ItemType Directory -Force -Path $dir|Out-Null}; [IO.File]::WriteAllText((Join-Path (Get-Location).Path $p),($o|ConvertTo-Json -Depth $d),$utf8)}
function RouteState(){
  $route=Get-Content 'operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json' -Raw|ConvertFrom-Json
  $ledger=Get-Content 'operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json' -Raw|ConvertFrom-Json
  return [pscustomObject]@{route_active=[int]$route.routed_active_count; ledger_active=[int]$ledger.replayed_active_count; delta_count=@($ledger.deltas).Count; runtime_ready=$route.runtime_ready; active_source=$route.active_source}
}
function StatusOut($status,$proofPath){
  Write-Host "SCHOOL_RUN_STATUS=$status"
  Write-Host "PROOF_PATH=$proofPath"
  Write-Host "TARGET_ACCEPTED=$TargetAccepted"
  Write-Host "RUN_KIND=$RunKind"
  Write-Host "RUNTIME_READY=false"
}
$runId='agent_school_' + $RunKind.ToLowerInvariant() + '_' + $TargetAccepted + '_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
$proofPath='operations/reports/AGENT_SCHOOL_CANONICAL_ENTRYPOINT_V1.json'
$batchSize=100
$chunkSize=4999
$before=RouteState
$proof=[ordered]@{
  schema='agent_school_canonical_run_v1'
  status='RUNNING'
  run_id=$runId
  run_kind=$RunKind
  target_accepted=$TargetAccepted
  runtime_ready=$false
  accepted_core_mutated=$false
  route_active_before=$before.route_active
  ledger_active_before=$before.ledger_active
  route_active_after=$before.route_active
  ledger_active_after=$before.ledger_active
  scheduler=[ordered]@{chunk_size=$chunkSize; batch_size=$batchSize; chunk_count=[int][Math]::Ceiling($TargetAccepted / [double]$chunkSize); batch_count=[int][Math]::Ceiling($TargetAccepted / [double]$batchSize)}
  chunks=@()
  boundary='Single owner-facing school entrypoint. Owner supplies only TargetAccepted and RunKind. Internals choose chunking, batch, ready lane, policy, and absorption.'
}
try{
  if($before.route_active -ne $before.ledger_active){ throw "ROUTE_LEDGER_MISMATCH_BEFORE: route=$($before.route_active) ledger=$($before.ledger_active)" }
  $remaining=$TargetAccepted
  $acceptedTotal=0
  $chunkIndex=0
  while($remaining -gt 0){
    $chunkIndex++
    $n=[Math]::Min($chunkSize,$remaining)
    $policyOut=& powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/curriculum/incremental_active_store/select_replay_audit_policy_v1.ps1 -IncomingCount $n *>&1
    $policy=Get-Content operations/reports/REPLAY_AUDIT_POLICY_SELECTION_V1.json -Raw|ConvertFrom-Json
    if($RunKind -eq 'Real' -and $policy.full_replay_required -eq $true){
      $proof.status=if($acceptedTotal -gt 0){'PARTIAL_STOPPED_REPLAY_AUDIT_REQUIRED'}else{'BLOCKED_REPLAY_AUDIT_REQUIRED'}
      $proof.accepted_total=$acceptedTotal
      $proof.stop_reason='REPLAY_AUDIT_REQUIRED_BY_POLICY'
      $proof.policy_decision=$policy.decision
      $proof.policy_reasons=@($policy.reasons)
      $after=RouteState; $proof.route_active_after=$after.route_active; $proof.ledger_active_after=$after.ledger_active
      WriteJson $proofPath ([pscustomobject]$proof) 100
      StatusOut $proof.status $proofPath
      exit 0
    }
    & powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/curriculum/candidate_factory/validate_codex_curriculum_candidate_factory_v1.ps1 -TargetAccepted $n -BatchSize $batchSize | Out-Host
    $validation=Get-Content operations/reports/CODEX_CANDIDATE_FACTORY_VALIDATION_V1.json -Raw|ConvertFrom-Json
    $stream=Get-Content operations/reports/STREAMING_SCHOOL_TO_ABSORPTION_PIPELINE_V1.json -Raw|ConvertFrom-Json
    if($validation.status -ne 'PASS_CODEX_CANDIDATE_FACTORY_VALIDATION_V1'){ throw "VALIDATION_NOT_PASS: $($validation.status)" }
    if($stream.status -ne 'PASS_STREAMING_SCHOOL_TO_ABSORPTION_PIPELINE_V1'){ throw "STREAMING_NOT_PASS: $($stream.status)" }
    if([int]$stream.ready_atoms_total -le 0){ throw 'ZERO_READY_ATOMS' }
    if([int]$stream.stream_quarantined_total -ne 0){ throw "STREAM_QUARANTINE_NOT_ZERO: $($stream.stream_quarantined_total)" }
    $readyLane=[string]$stream.ready_lane_path
    if(-not (Test-Path $readyLane)){ throw "READY_LANE_PATH_MISSING_FROM_STREAM_REPORT: $readyLane" }
    & powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/curriculum/candidate_factory/validate_codex_candidate_factory_hot_path_invariants_v1.ps1 -RunDir (Split-Path -Parent $readyLane) | Out-Host
    $hot=Get-Content operations/reports/FACTORY_HOT_PATH_INVARIANTS_V1.json -Raw|ConvertFrom-Json
    if($hot.status -ne 'PASS_FACTORY_HOT_PATH_INVARIANTS_V1'){ throw "HOT_PATH_NOT_PASS: $($hot.status)" }
    if([string]$hot.run_dir -ne (Split-Path -Parent $readyLane)){ throw "HOT_PATH_STALE_REPORT: $($hot.run_dir) != $(Split-Path -Parent $readyLane)" }
    $chunk=[ordered]@{index=$chunkIndex; target=$n; validation_status=$validation.status; streaming_status=$stream.status; hot_path_status=$hot.status; ready_lane_path=$readyLane; ready_atoms=[int]$stream.ready_atoms_total; quarantine=[int]$stream.stream_quarantined_total; policy_decision=$policy.decision; absorbed=0}
    if($RunKind -eq 'Real'){
      & powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/curriculum/ready_lane/absorb_ready_lane_via_active_route_v1.ps1 -ReadyLanePath $readyLane -PromotionId $runId`_chunk_$chunkIndex | Out-Host
      $abs=Get-Content operations/reports/ABSORB_READY_LANE_VIA_ACTIVE_ROUTE_V1.json -Raw|ConvertFrom-Json
      if($abs.status -ne 'PASS_ABSORB_READY_LANE_VIA_ACTIVE_ROUTE_V1'){ throw "ABSORB_NOT_PASS: $($abs.status)" }
      $acceptedTotal += [int]$abs.incoming_count
      $chunk.absorb_status=$abs.status
      $chunk.absorbed=[int]$abs.incoming_count
      $chunk.before=[int]$abs.before_count
      $chunk.after=[int]$abs.after_count
    } else {
      $acceptedTotal += [int]$stream.ready_atoms_total
    }
    $proof.chunks += [pscustomobject]$chunk
    $remaining -= $n
  }
  $after=RouteState
  $proof.route_active_after=$after.route_active
  $proof.ledger_active_after=$after.ledger_active
  $proof.accepted_total=$acceptedTotal
  $proof.accepted_core_mutated=($RunKind -eq 'Real' -and $after.route_active -gt $before.route_active)
  $proof.status=if($RunKind -eq 'Real'){'PASS_REAL_ACTIVE_ROUTE_ABSORB'}else{'PASS_TEST_READY_LANE_ONLY'}
  if($RunKind -eq 'Real' -and $after.route_active -ne $after.ledger_active){ throw "ROUTE_LEDGER_MISMATCH_AFTER: route=$($after.route_active) ledger=$($after.ledger_active)" }
  WriteJson $proofPath ([pscustomobject]$proof) 100
  $md=@('# AGENT_SCHOOL_CANONICAL_ENTRYPOINT_V1','',"Status: $($proof.status)","Run kind: $RunKind","TargetAccepted: $TargetAccepted","Accepted total: $acceptedTotal","Route before: $($proof.route_active_before)","Route after: $($proof.route_active_after)",'','Boundary: one owner-facing entrypoint only; no old launch surface.')
  [IO.File]::WriteAllText((Join-Path (Get-Location).Path 'operations/reports/AGENT_SCHOOL_CANONICAL_ENTRYPOINT_V1.md'),($md -join "`r`n"),$utf8)
  StatusOut $proof.status $proofPath
}catch{
  $after=RouteState
  $proof.status='FAIL_AGENT_SCHOOL_CANONICAL_ENTRYPOINT_V1'
  $proof.error=$_.Exception.Message
  $proof.route_active_after=$after.route_active
  $proof.ledger_active_after=$after.ledger_active
  WriteJson $proofPath ([pscustomobject]$proof) 100
  StatusOut $proof.status $proofPath
  throw
}