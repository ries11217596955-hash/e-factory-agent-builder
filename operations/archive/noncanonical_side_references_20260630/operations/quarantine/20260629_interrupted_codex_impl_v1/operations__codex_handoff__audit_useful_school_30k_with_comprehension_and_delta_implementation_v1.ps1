$ErrorActionPreference='Stop'
$Root='C:/Users/Azerbaijan/Downloads/e-factory-agent-builder'
Set-Location $Root
Write-Host 'STEP-AUDIT_USEFUL_SCHOOL_30K_IMPLEMENTATION_V1'
$ExpectedHead='0391667e5c056eda67f2f24a350a57eabb7350a8'
$RepoRoot=(git rev-parse --show-toplevel).Trim() -replace '\\','/'
$Branch=(git branch --show-current).Trim()
$Head=(git rev-parse HEAD).Trim()
Write-Host "ROOT=$RepoRoot"
Write-Host "BRANCH=$Branch"
Write-Host "HEAD=$Head"
if($RepoRoot -ne $Root){ throw 'ROOT_MISMATCH' }
if($Branch -ne 'thin-control'){ throw 'BRANCH_MISMATCH' }
if($Head -ne $ExpectedHead){ throw 'HEAD_MISMATCH' }

$Required=@(
 'modules/invoke_useful_school_30k_with_comprehension_and_delta_v1.ps1',
 'tests/accepted_atom_retention/run_useful_school_30k_with_comprehension_and_delta_v1_proof.ps1',
 'tests/accepted_atom_retention/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROOF.json',
 'validators/validate_useful_school_30k_with_comprehension_and_delta_v1_proof.ps1',
 'operations/codex_handoff/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_IMPLEMENT_V1_REPORT.md'
)
foreach($f in $Required){ if(-not(Test-Path $f)){ throw "REQUIRED_FILE_MISSING=$f" } }

Write-Host 'STEP-PARSE_POWERSHELL'
foreach($f in @($Required[0],$Required[1],$Required[3])){
 $tokens=$null; $errors=$null
 [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $f),[ref]$tokens,[ref]$errors)|Out-Null
 Write-Host "PS_PARSE=$f ERRORS=$($errors.Count)"
 if($errors.Count -gt 0){ throw "POWERSHELL_PARSE_FAILED=$f" }
}

Write-Host 'STEP-RUN_VALIDATOR'
& 'validators/validate_useful_school_30k_with_comprehension_and_delta_v1_proof.ps1'

$Proof=Get-Content 'tests/accepted_atom_retention/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROOF.json' -Raw | ConvertFrom-Json
if($Proof.schema -ne 'useful_school_30k_with_comprehension_and_delta_v1'){ throw 'SCHEMA_MISMATCH' }
if([int]$Proof.accepted_total -ne 30000){ throw 'ACCEPTED_TOTAL_NOT_30000' }
if([int]$Proof.rejected_total -lt 3000){ throw 'REJECTED_TOTAL_TOO_LOW' }
if([int]$Proof.chunk_count -ne 6){ throw 'CHUNK_COUNT_NOT_6' }
if([int]$Proof.subchunk_count -ne 300){ throw 'SUBCHUNK_COUNT_NOT_300' }
if([int]$Proof.after_score -le [int]$Proof.before_score){ throw 'NO_AFTER_IMPROVEMENT' }
if([int]$Proof.critical_regression_count -ne 0){ throw 'CRITICAL_REGRESSION_PRESENT' }
if($Proof.runtime_ready -ne $false){ throw 'RUNTIME_READY_OVERCLAIM' }
if($Proof.legacy_runner_used -ne $false){ throw 'LEGACY_RUNNER_USED' }
if($Proof.codex_output_treated_as_proof -ne $false){ throw 'CODEX_OUTPUT_TREATED_AS_PROOF' }

$Report=Get-Content 'operations/codex_handoff/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_IMPLEMENT_V1_REPORT.md' -Raw
foreach($Needle in @('STATUS:','TASK_MODE: PHASED_IMPLEMENTATION_WITH_SELF_CHECKS','FILES_CHANGED_BEFORE_PREFLIGHT_PASS: NO','VALIDATOR_STATUS:','30K_EXECUTED:','RUNTIME_READY: false','COMMIT_DONE: NO','PUSH_DONE: NO')){
 if($Report -notmatch [regex]::Escape($Needle)){ throw "REPORT_MISSING=$Needle" }
}
if($Report -match 'RUNTIME_READY:\s*true'){ throw 'REPORT_RUNTIME_READY_OVERCLAIM' }

Write-Host 'STEP-GIT_STATUS'
git status --short --untracked-files=all
Write-Host 'VALIDATION_PASS=USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_IMPLEMENTATION_V1_AUDITED'
Write-Host 'RUNTIME_READY=false'
