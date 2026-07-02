param([string]$ReportPath='operations/overnight_school/REAL_DELTA_SCHOOL_EXISTING_BODY_SCAN_V1.json')
$ErrorActionPreference='Stop'
function Assert($Cond,[string]$Msg){ if(-not $Cond){ throw $Msg } }
Assert (Test-Path $ReportPath) "SCAN_REPORT_MISSING=$ReportPath"
$r=Get-Content $ReportPath -Raw | ConvertFrom-Json
Assert ($r.schema -eq 'real_delta_school_existing_body_scan_v1') 'SCHEMA_MISMATCH'
Assert ($r.status -eq 'SCAN_COMPLETE_NO_NEW_ORGAN_CREATED') 'STATUS_MISMATCH'
Assert ($r.decision -eq 'DO_NOT_BUILD_FROM_SCRATCH; ASSEMBLE_PARAMETRIC_ORGAN_FROM_EXISTING_COMPONENTS') 'DECISION_MISMATCH'
Assert ($r.runtime_ready -eq $false) 'RUNTIME_READY_OVERCLAIM'
Assert ($r.commit_push_performed -eq $false) 'COMMIT_PUSH_OVERCLAIM'
$ids=@($r.components | ForEach-Object { $_.id })
foreach($id in @('candidate_intake_contract','phase162_atom_acceptance_gates','phase165_lesson_to_atom_bridge','useful_curriculum_school_supervisor','useful_school_30k_full_process','real_delta_cycle_probe','real_delta_review','real_delta_scale_gate_50','codex_plan_comprehension_delta','quarantine_comprehension_delta_impl','self_map_rollup_policy')){ Assert ($ids -contains $id) "COMPONENT_MISSING=$id" }
$scale=@($r.components | Where-Object { $_.id -eq 'real_delta_scale_gate_50' })[0]
Assert ($scale.classification -eq 'SUPERSEDED_WRONG_DIRECTION') 'SCALE_GATE_NOT_SUPERSEDED'
$q=@($r.components | Where-Object { $_.id -eq 'quarantine_comprehension_delta_impl' })[0]
Assert ($q.classification -eq 'QUARANTINE_REVIEW_ONLY') 'QUARANTINE_NOT_REVIEW_ONLY'
Assert (@($r.missing_files).Count -eq 0) ('MISSING_FILES=' + (@($r.missing_files) -join ','))
$rules=@($r.duplicate_prevention_rules)
foreach($needle in @('Do not continue scale_gate_50 path','Do not restore quarantine blindly','Map updates only on rollup/capability level')){ Assert ($rules -contains $needle) "RULE_MISSING=$needle" }
Write-Host 'VALIDATION_PASS=REAL_DELTA_SCHOOL_EXISTING_BODY_SCAN_V1_VALID'
Write-Host "REPORT_PATH=$ReportPath"
Write-Host "COMPONENT_COUNT=$(@($r.components).Count)"
Write-Host 'RUNTIME_READY=false'
