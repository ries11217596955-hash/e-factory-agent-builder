param([string]$TaskPath='operations/codex_handoff/REAL_DELTA_SCHOOL_ORGAN_V1_ADAPTER_WIRING_PLAN_TASK.md')
$ErrorActionPreference='Stop'
function Assert($Cond,[string]$Msg){ if(-not $Cond){ throw $Msg } }
Assert (Test-Path $TaskPath) "TASK_MISSING=$TaskPath"
$t=Get-Content $TaskPath -Raw
foreach($needle in @(
  'No file writes before `PREFLIGHT_PASS`.',
  'Files changed before PREFLIGHT_PASS: YES/NO',
  'Expected: NO',
  'Exact read list',
  'Hard cut list',
  'Allowed output/write scope',
  'No source code implementation files are allowed in this task.',
  'No validators may be created in this task.',
  'No existing files may be modified in this task.',
  'REAL_DELTA_SCHOOL_SCALE_GATE_V1` is `SUPERSEDED_WRONG_DIRECTION`',
  'Do not ingest the whole repo.',
  'Do not read:',
  'zz_MUSORKA_DO_NOT_READ_BY_CODEX/**',
  'operations/quarantine/**',
  'Do not run 30K.',
  'Do not claim live intelligence or runtime readiness.',
  'runtime_ready=false',
  'Why N is a parameter, not architecture',
  'Why atom/subchunk events must not update the map'
)) { Assert ($t.Contains($needle)) "TASK_NEEDLE_MISSING=$needle" }
foreach($required in @(
  'AGENTS.md',
  'operations/overnight_school/REAL_DELTA_SCHOOL_EXISTING_BODY_SCAN_V1.json',
  'operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_PASSPORT.json',
  'operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_PARAMETRIC_CONTRACT.json',
  'validators/validate_candidate_intake_report_contract_v1.ps1',
  'validators/validate_phase162_atom_accept_readiness_gate_v1.ps1',
  'validators/validate_phase165s_c1_lesson_to_atom_bridge_v1.ps1',
  'modules/invoke_useful_curriculum_school_supervisor_v1.ps1',
  'operations/self_map/invoke_self_map_auto_update_trigger_v1.ps1'
)) { Assert ($t.Contains($required)) "READ_LIST_MISSING=$required" }
foreach($allowed in @(
  'operations/codex_handoff/REAL_DELTA_SCHOOL_ORGAN_V1_ADAPTER_WIRING_PLAN.md',
  'operations/codex_handoff/REAL_DELTA_SCHOOL_ORGAN_V1_ADAPTER_WIRING_PLAN_REPORT.md'
)) { Assert ($t.Contains($allowed)) "ALLOWED_WRITE_MISSING=$allowed" }
Write-Host 'VALIDATION_PASS=REAL_DELTA_SCHOOL_ORGAN_V1_ADAPTER_WIRING_PLAN_TASK_VALID'
Write-Host "TASK_PATH=$TaskPath"
Write-Host 'CODEX_NOT_RUN=true'
Write-Host 'RUNTIME_READY=false'
