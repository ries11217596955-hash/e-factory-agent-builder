param([string]$PatchPath='operations/reports/MAP_PATCH_CANDIDATE_V1.json')
$ErrorActionPreference='Stop'
if(-not(Test-Path $PatchPath)){ throw 'MAP_PATCH_CANDIDATE_MISSING' }
$P=Get-Content $PatchPath -Raw | ConvertFrom-Json
function Assert($Cond,[string]$Msg){ if(-not $Cond){ throw $Msg } }
Assert ($P.schema -eq 'map_patch_candidate_v1') 'SCHEMA_MISMATCH'
Assert ($P.status -eq 'PATCH_CANDIDATE_CREATED_NOT_APPLIED') 'STATUS_MISMATCH'
Assert ($P.runtime_ready -eq $false) 'RUNTIME_READY_OVERCLAIM'
Assert (@($P.capability_entries).Count -ge 6) 'TOO_FEW_CAPABILITY_ENTRIES'
$ids=@($P.capability_entries | ForEach-Object { $_.capability_id })
foreach($required in @('useful_knowledge_ladder_5000','useful_curriculum_school_supervisor_v1','useful_school_30k_full_process_v1','active_memory_runtime_use_and_real_delta_exam','legacy_ephemeral_1000_lane')){ Assert ($ids -contains $required) "MISSING_ENTRY_$required" }
$realGap=$P.capability_entries | Where-Object { $_.capability_id -eq 'active_memory_runtime_use_and_real_delta_exam' } | Select-Object -First 1
Assert ($realGap.evidence_status -eq 'NOT_PROVEN') 'REAL_DELTA_GAP_NOT_MARKED_NOT_PROVEN'
$full30=$P.capability_entries | Where-Object { $_.capability_id -eq 'useful_school_30k_full_process_v1' } | Select-Object -First 1
Assert ($full30.evidence_status -eq 'PROVEN_LAB_MECHANICS_ONLY') '30K_OVERCLAIM'
Assert ($full30.does_not_prove -contains 'agent became smarter') '30K_MISSING_DOES_NOT_PROVE_AGENT_SMARTER'
foreach($op in @($P.proposed_patch_operations)){ Assert ($op.no_runtime_ready_promotion -eq $true) 'PATCH_OP_RUNTIME_READY_RISK'; Assert ($op.no_live_claim -eq $true) 'PATCH_OP_LIVE_CLAIM_RISK' }
Write-Host 'VALIDATION_PASS=MAP_PATCH_CANDIDATE_V1_VALID'
Write-Host "PATCH_PATH=$PatchPath"
Write-Host 'RUNTIME_READY=false'
