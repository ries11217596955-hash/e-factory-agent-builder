$ErrorActionPreference = 'Stop'
$Root = (git rev-parse --show-toplevel).Trim() -replace '\\','/'
Set-Location $Root
$ProofPath = 'tests/accepted_atom_retention/USEFUL_CURRICULUM_SCHOOL_SUPERVISOR_V1_PROOF.json'
if (-not (Test-Path $ProofPath)) { throw "Proof missing: $ProofPath" }
$P = Get-Content $ProofPath -Raw | ConvertFrom-Json
function Assert-True { param([bool]$Condition,[string]$Message) if (-not $Condition) { throw $Message } }
function Has-Text { param($Value) return -not [string]::IsNullOrWhiteSpace([string]$Value) }
Assert-True ($P.schema -eq 'useful_curriculum_school_supervisor_v1_proof') 'bad schema'
Assert-True ($P.status -eq 'PASS') 'status not PASS'
Assert-True ($P.final_status -eq 'USEFUL_CURRICULUM_SCHOOL_SUPERVISOR_V1_PROVEN') 'bad final status'
Assert-True ([int]$P.target_cycle_count -eq 3) 'target cycle count bad'
Assert-True ([int]$P.cycle_count -eq 3) 'cycle count bad'
Assert-True ([int]$P.accepted_per_cycle -eq 1000) 'accepted per cycle bad'
Assert-True ([int]$P.subchunk_size -eq 100) 'subchunk size bad'
Assert-True ([int]$P.subchunk_count -eq 30) 'subchunk count bad'
Assert-True ([int]$P.accepted_total -eq 3000) 'accepted total bad'
Assert-True ([int]$P.candidate_total -ge 3600) 'candidate total too low'
Assert-True ([int]$P.rejected_total -ge 600) 'rejected total too low'
Assert-True ([int]$P.checkpoint_count -ge 3) 'checkpoint count too low'
Assert-True ($P.resume_proof_status -eq 'PASS') 'resume proof not PASS'
Assert-True ($P.stop_on_fail_guard_status -eq 'PASS') 'stop on fail guard not PASS'
Assert-True ($P.retrieval_status -eq 'PASS') 'retrieval not PASS'
Assert-True ($P.decision_reuse_status -eq 'PASS') 'decision reuse not PASS'
Assert-True ([int]$P.decision_scenario_count -ge 30) 'decision scenarios too low'
Assert-True ([int]$P.decision_changed_or_guarded_count -eq [int]$P.decision_scenario_count) 'decision guard count mismatch'
Assert-True ([bool]$P.active_stubs_unchanged -eq $true) 'active stubs changed'
Assert-True ([bool]$P.no_runtime_ready_overclaim -eq $true) 'runtime overclaim guard missing'
Assert-True ([bool]$P.runtime_bounded -eq $true) 'runtime not bounded'
Assert-True ([bool]$P.runtime_ready -eq $false) 'runtime_ready overclaim'
Assert-True ([bool]$P.n_specific_organ_limit_detected -eq $false) 'n-specific organ limit detected'
Assert-True ([bool]$P.legacy_runner_used -eq $false) 'legacy runner used'

$Cycles = @($P.cycles)
Assert-True ($Cycles.Count -eq 3) 'cycles array not 3'
foreach ($C in $Cycles) {
  Assert-True (Has-Text $C.cycle_id) 'cycle id missing'
  Assert-True (Has-Text $C.school_level) 'cycle level missing'
  Assert-True ([int]$C.accepted_count -eq 1000) 'cycle accepted not 1000'
  Assert-True ([int]$C.rejected_count -gt 0) 'cycle rejected zero'
  Assert-True ($C.retrieval_status -eq 'PASS') 'cycle retrieval not PASS'
  Assert-True ($C.decision_reuse_status -eq 'PASS') 'cycle decision reuse not PASS'
  Assert-True ($C.checkpoint_status -eq 'PASS') 'cycle checkpoint not PASS'
}

$Subchunks = @($P.subchunks)
Assert-True ($Subchunks.Count -eq 30) 'subchunks array not 30'
foreach ($S in $Subchunks) {
  Assert-True (Has-Text $S.subchunk_id) 'subchunk id missing'
  Assert-True ([int]$S.accepted_count -eq 100) 'subchunk accepted not 100'
  Assert-True ([int]$S.rejected_count -gt 0) 'subchunk rejects zero'
  Assert-True ($S.retrieval_status -eq 'PASS') 'subchunk retrieval not PASS'
  Assert-True ($S.decision_reuse_status -eq 'PASS') 'subchunk decision reuse not PASS'
}

$Atoms = @($P.accepted_atoms)
Assert-True ($Atoms.Count -eq 3000) 'accepted atoms array not 3000'
$Ids = New-Object 'System.Collections.Generic.HashSet[string]'
$Domains = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($A in $Atoms) {
  foreach ($Field in @('atom_id','cycle_id','school_level','subchunk_id','domain','concept','trigger','rule','anti_pattern','decision_use','validator_hint','source_type')) {
    Assert-True (Has-Text $A.$Field) "atom field missing $Field"
  }
  Assert-True ($Ids.Add([string]$A.atom_id)) 'duplicate atom id'
  [void]$Domains.Add([string]$A.domain)
  Assert-True (@($A.reuse_tags).Count -ge 3) 'atom reuse tags too few'
  $Blob = $A | ConvertTo-Json -Compress -Depth 10
  Assert-True ($Blob -notmatch 'placeholder|lorem|dummy|todo|counter-only|test atom') 'placeholder-like atom present'
}
Assert-True ($Domains.Count -ge 10) 'domain coverage below 10'

$Scenarios = @($P.decision_scenarios)
Assert-True ($Scenarios.Count -ge 30) 'scenario array too small'
$AllowedLabels = @('CODEX_DRAFT','PROVEN_LAB','NOT_PROVEN','BLOCKED_PREFLIGHT','OWNER_DECISION_REQUIRED','CONTEXT_MISMATCH','NOT_IMPLEMENTED')
foreach ($S in $Scenarios) {
  Assert-True (Has-Text $S.scenario_id) 'scenario id missing'
  Assert-True (Has-Text $S.cycle_id) 'scenario cycle missing'
  Assert-True (Has-Text $S.input_case) 'scenario input missing'
  Assert-True (@($S.retrieved_atom_ids).Count -ge 5) 'scenario retrieved atoms too few'
  Assert-True (@($S.retrieved_domains).Count -ge 1) 'scenario domains missing'
  Assert-True (@($S.applied_rules).Count -ge 1) 'scenario rules missing'
  Assert-True (Has-Text $S.naive_or_unsafe_decision) 'naive decision missing'
  Assert-True (Has-Text $S.governed_decision) 'governed decision missing'
  Assert-True ([bool]$S.decision_changed_or_guarded -eq $true) 'scenario not changed/guarded'
  Assert-True ($AllowedLabels -contains [string]$S.proof_label) 'bad proof label'
  Assert-True ([string]$S.proof_label -ne 'PROVEN_LIVE') 'PROVEN_LIVE present'
}

foreach ($B in @($P.baseline_files)) {
  Assert-True ([bool]$B.unchanged_by_runner -eq $true) "baseline file changed by runner: $($B.path)"
}

Write-Host 'VALIDATION_PASS=USEFUL_CURRICULUM_SCHOOL_SUPERVISOR_V1_PROVEN'
Write-Host "CYCLE_COUNT=$($P.cycle_count)"
Write-Host "SUBCHUNK_COUNT=$($P.subchunk_count)"
Write-Host "ACCEPTED_TOTAL=$($P.accepted_total)"
Write-Host "REJECTED_TOTAL=$($P.rejected_total)"
Write-Host "CHECKPOINT_COUNT=$($P.checkpoint_count)"
Write-Host "RESUME_PROOF_STATUS=$($P.resume_proof_status)"
Write-Host "STOP_ON_FAIL_GUARD_STATUS=$($P.stop_on_fail_guard_status)"
Write-Host "RETRIEVAL_STATUS=$($P.retrieval_status)"
Write-Host "DECISION_REUSE_STATUS=$($P.decision_reuse_status)"
Write-Host "DECISION_SCENARIO_COUNT=$($P.decision_scenario_count)"
Write-Host "RUNTIME_READY=$($P.runtime_ready.ToString().ToLowerInvariant())"
