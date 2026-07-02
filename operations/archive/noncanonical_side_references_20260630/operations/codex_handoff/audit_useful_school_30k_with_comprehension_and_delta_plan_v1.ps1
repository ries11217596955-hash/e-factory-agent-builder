$ErrorActionPreference = 'Stop'
$Root = 'C:/Users/Azerbaijan/Downloads/e-factory-agent-builder'
Set-Location $Root

Write-Host 'STEP-AUDIT_USEFUL_SCHOOL_30K_PLAN_REPORT_V1'
$ExpectedHead = '0391667e5c056eda67f2f24a350a57eabb7350a8'
$RepoRoot = (git rev-parse --show-toplevel).Trim() -replace '\\','/'
$Branch = (git branch --show-current).Trim()
$Head = (git rev-parse HEAD).Trim()
Write-Host "ROOT=$RepoRoot"
Write-Host "BRANCH=$Branch"
Write-Host "HEAD=$Head"
if ($RepoRoot -ne $Root) { throw 'ROOT_MISMATCH' }
if ($Branch -ne 'thin-control') { throw 'BRANCH_MISMATCH' }
if ($Head -ne $ExpectedHead) { throw 'HEAD_MISMATCH' }

$TaskFile = 'operations/codex_handoff/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_PLAN_V1.md'
$ReportFile = 'operations/codex_handoff/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_PLAN_V1_REPORT.md'
if (-not (Test-Path $TaskFile)) { throw 'TASK_FILE_MISSING' }
if (-not (Test-Path $ReportFile)) { throw 'PLAN_REPORT_MISSING' }

$Report = Get-Content $ReportFile -Raw
foreach ($Needle in @(
  'STATUS:',
  'TASK_MODE: PLAN_ONLY',
  'FILES_CHANGED_BEFORE_PREFLIGHT_PASS:',
  '30K_EXECUTED: NO',
  'RUNTIME_READY: false',
  'phase-by-phase',
  'before',
  'comprehension',
  'digest',
  'competence delta',
  'promotion',
  'after',
  'critical regression',
  'stop conditions'
)) {
  if ($Report -notmatch [regex]::Escape($Needle)) { throw "REPORT_MISSING_REQUIRED_TEXT=$Needle" }
}
if ($Report -match 'RUNTIME_READY:\s*true') { throw 'RUNTIME_READY_OVERCLAIM_IN_REPORT' }
if ($Report -match '30K_EXECUTED:\s*YES') { throw 'REPORT_CLAIMS_30K_EXECUTED' }

Write-Host 'STEP-GIT_STATUS'
git status --short --untracked-files=all
Write-Host 'VALIDATION_PASS=USEFUL_SCHOOL_30K_PLAN_REPORT_V1_AUDITED'
Write-Host 'RUNTIME_READY=false'
