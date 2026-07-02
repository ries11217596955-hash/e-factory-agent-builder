param([string]$ProofPath='operations/lifecycle/BUILDER_POST_CHANGE_LIFECYCLE_V1_PROOF.json')
$ErrorActionPreference='Stop'
if(-not(Test-Path $ProofPath)){ throw 'LIFECYCLE_PROOF_MISSING' }
$P=Get-Content $ProofPath -Raw | ConvertFrom-Json
function Assert($Cond,[string]$Msg){ if(-not $Cond){ throw $Msg } }
Assert ($P.schema -eq 'builder_post_change_lifecycle_v1_proof') 'SCHEMA_MISMATCH'
Assert ($P.status -eq 'PASS') 'STATUS_NOT_PASS'
Assert ($P.self_map_trigger_invoked -eq $true) 'SELF_MAP_TRIGGER_NOT_INVOKED'
Assert ($P.protected_maps_mutated -eq $false) 'PROTECTED_MUTATION_CLAIMED'
Assert ($P.runtime_ready -eq $false) 'RUNTIME_READY_OVERCLAIM'
Assert ($P.limitation -like '*Codex/Git/OS automatic hook not installed*') 'LIMITATION_MISSING'
Write-Host 'VALIDATION_PASS=BUILDER_POST_CHANGE_LIFECYCLE_V1_VALID'
Write-Host "PROOF_PATH=$ProofPath"
Write-Host 'RUNTIME_READY=false'
