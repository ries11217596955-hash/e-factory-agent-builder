param(
  [Parameter(Mandatory=$true)][string]$EventType,
  [string]$ChangedPath,
  [string]$Reason='post_change_lifecycle',
  [string]$ProofPath='operations/lifecycle/BUILDER_POST_CHANGE_LIFECYCLE_V1_PROOF.json'
)
$ErrorActionPreference='Stop'
Set-Location 'C:/Users/Azerbaijan/Downloads/e-factory-agent-builder'
$Protected=@('CAPABILITY_ROADMAP.json','GENESIS_STATE.json','TASK_QUEUE.json','packs/registry.json','self_model_active_map.json','accepted_change_memory_snapshot.json','orchestrator/run.ps1')
$before=[ordered]@{}
foreach($p in $Protected){ if(Test-Path $p){ $before[$p]=(Get-FileHash $p -Algorithm SHA256).Hash.ToLowerInvariant() } else { $before[$p]='MISSING' } }
$root=(git rev-parse --show-toplevel).Trim() -replace '\\','/'
$branch=(git branch --show-current).Trim()
$head=(git rev-parse HEAD).Trim()
& 'operations/self_map/invoke_self_map_auto_update_trigger_v1.ps1' -EventType $EventType -ChangedPath $ChangedPath -Reason $Reason
$after=[ordered]@{}
foreach($p in $Protected){ if(Test-Path $p){ $after[$p]=(Get-FileHash $p -Algorithm SHA256).Hash.ToLowerInvariant() } else { $after[$p]='MISSING' } }
$changed=@()
foreach($p in $Protected){ if($before[$p] -ne $after[$p]){ $changed += $p } }
if($changed.Count -gt 0){ throw ('PROTECTED_MAP_MUTATED_BY_LIFECYCLE=' + ($changed -join ',')) }
$proof=[ordered]@{
  schema='builder_post_change_lifecycle_v1_proof'
  status='PASS'
  proof_label='PROVEN_LAB_LIFECYCLE_WRAPPER_INVOKES_SELF_MAP_TRIGGER'
  created_utc=(Get-Date).ToUniversalTime().ToString('o')
  repo=[ordered]@{ root=$root; branch=$branch; head=$head }
  event_type=$EventType
  changed_path=$ChangedPath
  reason=$Reason
  self_map_trigger_invoked=$true
  protected_maps_mutated=$false
  runtime_ready=$false
  limitation='Wrapper proven in lab; Codex/Git/OS automatic hook not installed by this proof.'
}
$dir=Split-Path $ProofPath -Parent
if($dir){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
$proof | ConvertTo-Json -Depth 20 | Set-Content -Path $ProofPath -Encoding UTF8
Write-Host 'BUILDER_POST_CHANGE_LIFECYCLE_STATUS=PASS'
Write-Host "PROOF_PATH=$ProofPath"
Write-Host 'SELF_MAP_TRIGGER_INVOKED=true'
Write-Host 'PROTECTED_MAPS_MUTATED=false'
Write-Host 'RUNTIME_READY=false'
