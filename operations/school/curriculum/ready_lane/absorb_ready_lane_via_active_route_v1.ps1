param(
  [Parameter(Mandatory=$true)][string]$ReadyLanePath,
  [string]$RoutePointerPath='operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_POINTER_V1.json',
  [string]$ReplayLedgerPath='operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_ROUTE_REPLAY_LEDGER_V1.json',
  [string]$ReplayAuditPolicyPath='operations/school/curriculum/incremental_active_store/ACTIVE_REPO_BODY_REPLAY_AUDIT_POLICY_V1.json',
  [string]$PromotionId='',
  [switch]$DryRun
)
$ErrorActionPreference='Stop'
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
function WriteJson($p,$o,$d=80){$dir=Split-Path -Parent $p; if($dir){New-Item -ItemType Directory -Force -Path $dir|Out-Null}; [IO.File]::WriteAllText((Join-Path (Get-Location).Path $p),($o|ConvertTo-Json -Depth $d),$utf8)}
function SetOrAdd($obj,$name,$value){ if($obj.PSObject.Properties.Name -contains $name){ $obj.$name=$value } else { $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value -Force } }
if(-not (Test-Path $ReadyLanePath)){ throw "READY_LANE_PATH_MISSING: $ReadyLanePath" }
if(-not (Test-Path $RoutePointerPath)){ throw "ROUTE_POINTER_MISSING: $RoutePointerPath" }
$route=Get-Content $RoutePointerPath -Raw|ConvertFrom-Json
if([string]$route.active_source -ne 'incremental_active_store_v1'){
  throw "UNSUPPORTED_ACTIVE_SOURCE_FOR_ROUTE_ENTRYPOINT: $($route.active_source)"
}
if([string]::IsNullOrWhiteSpace($PromotionId)){ $PromotionId='route_absorb_' + (Get-Date -Format 'yyyyMMdd_HHmmss') }
$readySha=(Get-FileHash $ReadyLanePath -Algorithm SHA256).Hash.ToLower()
$readyCount=(Get-Content $ReadyLanePath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Measure-Object).Count
$auditOut=& powershell -NoProfile -ExecutionPolicy Bypass -File operations/school/curriculum/incremental_active_store/select_replay_audit_policy_v1.ps1 -IncomingCount $readyCount -PolicyPath $ReplayAuditPolicyPath 2>&1
$auditExit=$LASTEXITCODE
$audit=Get-Content operations/reports/REPLAY_AUDIT_POLICY_SELECTION_V1.json -Raw|ConvertFrom-Json
if($audit.full_replay_required -eq $true -and -not $DryRun){
  throw "REPLAY_AUDIT_REQUIRED_BY_POLICY: decision=$($audit.decision); reasons=$($audit.reasons -join ',')"
}
$store=[string]$route.store_dir
$manifestPath=Join-Path $store 'manifest.json'
if((Test-Path $ReplayLedgerPath) -and ((-not (Test-Path $manifestPath)) -or ([int](Get-Content $manifestPath -Raw|ConvertFrom-Json).active_atom_count -ne [int]$route.routed_active_count))){
  & operations/school/curriculum/incremental_active_store/rebuild_incremental_active_store_from_route_replay_v1.ps1 -ReplayLedgerPath $ReplayLedgerPath -Force | Out-Host
}
if(-not (Test-Path $manifestPath)){ throw "ROUTED_INCREMENTAL_STORE_MISSING_AND_NOT_REBUILDABLE: $store" }
$manifest=Get-Content $manifestPath -Raw|ConvertFrom-Json
$before=[int]$manifest.active_atom_count
$after=$before + [int]$readyCount
$reportBase=[pscustomObject]@{
  schema='absorb_ready_lane_via_active_route_v1'
  status='DRY_RUN_ABSORPTION_ROUTE_SELECTED_V1'
  runtime_ready=$false
  active_source=$route.active_source
  ready_lane_path=$ReadyLanePath
  ready_lane_sha256=$readySha
  incoming_count=$readyCount
  before_count=$before
  after_count=$after
  promotion_id=$PromotionId
  dry_run=[bool]$DryRun
  route_pointer_path=$RoutePointerPath
  replay_ledger_path=$ReplayLedgerPath
  store_dir=$store
  route_action='incremental_delta_inverse_rollback_replay_ledger_projection'
  legacy_full_checkpoint_path_used=$false
  replay_audit_decision=$audit.decision
  full_replay_required=$audit.full_replay_required
  replay_audit_reasons=@($audit.reasons)
  replay_audit_exit_code=$auditExit
  boundary='Route-aware absorption entrypoint; dry-run does not mutate active route.'
}
if($DryRun){
  WriteJson 'operations/reports/ABSORB_READY_LANE_VIA_ACTIVE_ROUTE_V1.json' $reportBase 80
  $md=@('# ABSORB_READY_LANE_VIA_ACTIVE_ROUTE_V1','',"Status: $($reportBase.status)",'Runtime ready: false','',"Active source: $($reportBase.active_source)","Ready lane: $ReadyLanePath","Incoming: $readyCount","Before: $before","After: $after","Dry run: true",'','Boundary: no mutation.')
  [IO.File]::WriteAllText((Join-Path (Get-Location).Path 'operations/reports/ABSORB_READY_LANE_VIA_ACTIVE_ROUTE_V1.md'),($md -join "`r`n"),$utf8)
  Write-Host "ROUTE_ABSORB_STATUS=$($reportBase.status)"
  Write-Host "ACTIVE_SOURCE=$($reportBase.active_source)"
  Write-Host "READY_LANE=$ReadyLanePath"
  Write-Host "INCOMING=$readyCount"
  Write-Host "BEFORE=$before"
  Write-Host "AFTER=$after"
  Write-Host "DRY_RUN=true"
  Write-Host "RUNTIME_READY=false"
  return
}
& operations/school/curriculum/incremental_active_store/apply_ready_lane_incremental_active_delta_v1.ps1 -ReadyLanePath $ReadyLanePath -StoreDir $store -PromotionId $PromotionId | Out-Host
$delta=Get-Content operations/reports/INCREMENTAL_ACTIVE_DELTA_APPLY_V1.json -Raw|ConvertFrom-Json
if($delta.status -ne 'PASS_INCREMENTAL_ACTIVE_DELTA_APPLIED_V1'){ throw 'INCREMENTAL_DELTA_APPLY_NOT_PASS' }
if(Test-Path $ReplayLedgerPath){ $ledger=Get-Content $ReplayLedgerPath -Raw|ConvertFrom-Json } else { throw "REPLAY_LEDGER_MISSING: $ReplayLedgerPath" }
$existing=@($ledger.deltas)
$ordinal=$existing.Count + 1
$newDelta=[pscustomObject]@{
  ordinal=$ordinal
  promotion_id=$PromotionId
  ready_lane_path=$ReadyLanePath
  ready_lane_sha256=$readySha
  incoming_count=$readyCount
  before_count=[int]$delta.before_count
  after_count=[int]$delta.after_count
  rollback_mode='inverse_delta_not_full_snapshot'
  committed_source=$false
}
$ledger.deltas=@($existing + $newDelta)
$ledger.replayed_active_count=[int]$delta.after_count
SetOrAdd $ledger 'updated_at' ((Get-Date).ToString('o'))
WriteJson $ReplayLedgerPath $ledger 80
& operations/school/curriculum/incremental_active_store/write_incremental_active_store_compatibility_projection_v1.ps1 | Out-Host
$projection=Get-Content operations/reports/INCREMENTAL_ACTIVE_STORE_COMPATIBILITY_PROJECTION_V1.json -Raw|ConvertFrom-Json
$routeAfter=Get-Content $RoutePointerPath -Raw|ConvertFrom-Json
$reportBase.status='PASS_ABSORB_READY_LANE_VIA_ACTIVE_ROUTE_V1'
$reportBase.after_count=[int]$delta.after_count
SetOrAdd $reportBase 'delta_status' $delta.status
SetOrAdd $reportBase 'delta_path' $delta.delta_path
SetOrAdd $reportBase 'inverse_rollback_path' $delta.inverse_rollback_path
SetOrAdd $reportBase 'rollback_mode' $delta.rollback_mode
SetOrAdd $reportBase 'projection_active_count' $projection.routed_active_count
SetOrAdd $reportBase 'route_pointer_active_count' $routeAfter.routed_active_count
SetOrAdd $reportBase 'legacy_full_checkpoint_path_used' $false
SetOrAdd $reportBase 'boundary' 'Route-aware absorption applied to incremental store; replay ledger must be committed with ready source before durable claim.'
WriteJson 'operations/reports/ABSORB_READY_LANE_VIA_ACTIVE_ROUTE_V1.json' $reportBase 80
$md=@('# ABSORB_READY_LANE_VIA_ACTIVE_ROUTE_V1','',"Status: $($reportBase.status)",'Runtime ready: false','',"Active source: $($reportBase.active_source)","Ready lane: $ReadyLanePath","Incoming: $readyCount","Before: $($reportBase.before_count)","After: $($reportBase.after_count)","Rollback mode: $($reportBase.rollback_mode)","Legacy full checkpoint used: false",'','Boundary: incremental route absorption.')
[IO.File]::WriteAllText((Join-Path (Get-Location).Path 'operations/reports/ABSORB_READY_LANE_VIA_ACTIVE_ROUTE_V1.md'),($md -join "`r`n"),$utf8)
Write-Host "ROUTE_ABSORB_STATUS=$($reportBase.status)"
Write-Host "ACTIVE_SOURCE=$($reportBase.active_source)"
Write-Host "INCOMING=$readyCount"
Write-Host "BEFORE=$($reportBase.before_count)"
Write-Host "AFTER=$($reportBase.after_count)"
Write-Host "ROLLBACK_MODE=$($reportBase.rollback_mode)"
Write-Host "LEGACY_FULL_CHECKPOINT_USED=false"
Write-Host "RUNTIME_READY=false"