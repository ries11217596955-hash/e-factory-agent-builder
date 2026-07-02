param([string]$TaskPath='operations/codex_handoff/REAL_DELTA_SCHOOL_ORGAN_V1_STAGE1_IMPLEMENTATION_TASK.md')
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
  'run_real_delta_school_organ_v1.ps1',
  'validate_real_delta_school_organ_v1_candidate_feed_contract.ps1',
  'validate_real_delta_school_organ_v1_run_output_contract.ps1',
  'validate_real_delta_school_organ_v1_small_proof.ps1',
  'REAL_DELTA_SCHOOL_ORGAN_V1_SAMPLE_FEED.json',
  'REAL_DELTA_SCHOOL_ORGAN_V1_SMALL_PROOF.json',
  'TargetAccepted',
  'CandidateFeedPath',
  'PROVEN_LAB_PARAMETRIC_ORGAN_STAGE1_NOT_RUNTIME_INTELLIGENCE',
  'runtime_ready=false',
  'Do not run 30K.',
  'Do not mutate accepted core.',
  'Do not call positive self-map update.',
  'REAL_DELTA_SCHOOL_SCALE_GATE_V1` is `SUPERSEDED_WRONG_DIRECTION`',
  'VALIDATION_PASS=REAL_DELTA_SCHOOL_ORGAN_V1_SMALL_PROOF_VALID'
)) { Assert ($t.Contains($needle)) "TASK_NEEDLE_MISSING=$needle" }
foreach($forbidden in @('operations/quarantine/**','zz_MUSORKA_DO_NOT_READ_BY_CODEX/**','runtime_ready claimed true: YES/NO')){ Assert ($t.Contains($forbidden)) "TASK_GUARD_MISSING=$forbidden" }
Write-Host 'VALIDATION_PASS=REAL_DELTA_SCHOOL_ORGAN_V1_STAGE1_IMPLEMENTATION_TASK_VALID'
Write-Host "TASK_PATH=$TaskPath"
Write-Host 'CODEX_NOT_RUN=true'
Write-Host 'RUNTIME_READY=false'
