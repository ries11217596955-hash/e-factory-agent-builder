param(
    [string]$ProofPath = 'tests/accepted_atom_retention/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROOF.json'
)

$ErrorActionPreference = 'Stop'

$Root = (git rev-parse --show-toplevel).Trim()
Set-Location $Root

if (-not (Test-Path -LiteralPath $ProofPath)) {
    throw "Proof missing: $ProofPath"
}

$Raw = Get-Content -LiteralPath $ProofPath -Raw
$P = $Raw | ConvertFrom-Json

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Has-Property {
    param($Object, [string]$Name)
    return ($null -ne $Object -and $Object.PSObject.Properties.Name -contains $Name)
}

function Has-Text {
    param($Value)
    return -not [string]::IsNullOrWhiteSpace([string]$Value)
}

function Require-Int {
    param($Object, [string]$Name)
    Assert-True (Has-Property $Object $Name) "missing integer metric: $Name"
    return [int]$Object.$Name
}

function Require-Double {
    param($Object, [string]$Name)
    Assert-True (Has-Property $Object $Name) "missing score metric: $Name"
    return [double]$Object.$Name
}

function Assert-FalseValue {
    param($Object, [string]$Name)
    Assert-True (Has-Property $Object $Name) "missing false guard: $Name"
    Assert-True ([bool]$Object.$Name -eq $false) "$Name must be false"
}

Assert-True ($Raw -cnotmatch 'PROVEN_LIVE') 'PROVEN_LIVE claim present'
Assert-True ($Raw -notmatch '"raw_archive_dump"\s*:\s*true') 'raw archive dump flag true'
foreach ($pattern in @('"accepted_atoms"\s*:', '"raw_atoms"\s*:', '"raw_atom_archive"\s*:', '"all_atoms"\s*:', '"atom_candidates"\s*:')) {
    Assert-True ($Raw -notmatch $pattern) "raw archive dump pattern present: $pattern"
}
Assert-True ($Raw.Length -lt 2000000) 'proof JSON too large for compact proof boundary'

Assert-True ($P.schema -eq 'useful_school_30k_with_comprehension_and_delta_v1') 'bad schema'
Assert-True ($P.status -eq 'PASS') 'status not PASS'
Assert-True ($P.final_status -eq 'USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROVEN') 'bad final status'
Assert-True ((Require-Int $P 'target_accepted_count') -eq 30000) 'target accepted count bad'
Assert-True ((Require-Int $P 'accepted_total') -eq 30000) 'accepted total must be 30000'
Assert-True ((Require-Int $P 'rejected_total') -ge 3000) 'rejected total too low'
Assert-True ((Require-Int $P 'chunk_count') -eq 6) 'chunk count must be 6'
Assert-True ((Require-Int $P 'subchunk_count') -eq 300) 'subchunk count must be 300'
Assert-True ((Require-Int $P 'domain_count') -eq 10) 'domain count must be 10'
Assert-True (Has-Text $P.before_exam_manifest_hash) 'before exam manifest hash missing'
Assert-True ($P.after_exam_manifest_hash -eq $P.before_exam_manifest_hash) 'after exam manifest hash changed'

$BeforeScore = Require-Double $P 'before_score'
$AfterScore = Require-Double $P 'after_score'
Assert-True ($AfterScore -gt $BeforeScore) 'after score did not improve'
Assert-True ((Require-Int $P 'improved_case_count') -gt 0) 'improved case count must be positive'
Assert-True ((Require-Int $P 'critical_regression_count') -eq 0) 'critical regression present'
Assert-True ((Require-Int $P 'unsafe_decision_after') -le (Require-Int $P 'unsafe_decision_before')) 'unsafe decision regression'
Assert-True ((Require-Int $P 'proof_confusion_after') -le (Require-Int $P 'proof_confusion_before')) 'proof confusion regression'
Assert-True ((Require-Int $P 'understood_atom_total') -gt 0) 'understood atom total missing'
Assert-True ((Require-Int $P 'not_understood_atom_total') -ge 0) 'not understood atom total invalid'
Assert-True ((Require-Int $P 'assimilated_atom_total') -gt 0) 'assimilated atom total missing'
Assert-True ((Require-Int $P 'competence_delta_total') -gt 0) 'competence delta total missing'
Assert-True ((Require-Int $P 'promoted_delta_count') -gt 0) 'promoted delta count missing'
Assert-True ((Require-Int $P 'quarantined_delta_count') -ge 0) 'quarantined delta count invalid'
Assert-True ((Require-Int $P 'new_atoms_used_in_after_decisions') -gt 0) 'new atoms not used in after decisions'

Assert-FalseValue $P 'runtime_ready'
Assert-FalseValue $P 'legacy_runner_used'
Assert-FalseValue $P 'codex_output_treated_as_proof'
Assert-FalseValue $P 'source_material_treated_as_proof'
Assert-FalseValue $P 'counter_only_or_mechanical_templates_detected'
Assert-FalseValue $P 'proven_live_claim_present'

$Anti = $P.anti_mechanical_generation_checks
Assert-True ($null -ne $Anti) 'anti mechanical generation checks missing'
foreach ($name in @('serial_pattern_guard', 'raw_dump_guard', 'accepted_count_only_guard')) {
    Assert-True (Has-Property $Anti $name) "anti mechanical check missing: $name"
    Assert-True ([bool]$Anti.$name -eq $true) "anti mechanical check false: $name"
}

$Reject = $P.reject_classes
Assert-True ($null -ne $Reject) 'reject classes missing'
foreach ($name in @('duplicate', 'low_quality', 'conflict_or_unsafe', 'non_actionable')) {
    Assert-True (Has-Property $Reject $name) "reject class missing: $name"
    Assert-True ([int]$Reject.$name -gt 0) "reject class count not positive: $name"
}

$Chain = @($P.chunk_state_chain)
Assert-True ($Chain.Count -eq 6) 'chunk state chain count bad'
Assert-True ($P.active_state_initial_hash -eq $Chain[0].active_state_input_hash) 'initial state hash mismatch'
Assert-True ($P.active_state_final_hash -eq $Chain[$Chain.Count - 1].active_state_output_hash) 'final state hash mismatch'
for ($i = 1; $i -lt $Chain.Count; $i++) {
    Assert-True ($Chain[$i].active_state_input_hash -eq $Chain[$i - 1].active_state_output_hash) "chunk state chain broken at index $i"
}

$Chunks = @($P.chunks)
Assert-True ($Chunks.Count -eq 6) 'chunk summary count bad'
$RequiredStatuses = @('CANDIDATE_ATOM', 'ACCEPTED_ATOM', 'UNDERSTOOD_ATOM', 'NOT_UNDERSTOOD_ATOM', 'ASSIMILATED_ATOM', 'PROMOTION_REJECTED')
for ($i = 0; $i -lt $Chunks.Count; $i++) {
    $C = $Chunks[$i]
    Assert-True ([int]$C.chunk_index -eq ($i + 1)) 'chunk index mismatch'
    Assert-True ($C.active_state_input_hash -eq $Chain[$i].active_state_input_hash) 'chunk input hash mismatch'
    Assert-True ($C.active_state_output_hash -eq $Chain[$i].active_state_output_hash) 'chunk output hash mismatch'
    Assert-True ([int]$C.accepted_count -eq 5000) 'chunk accepted count must be 5000'
    Assert-True ([int]$C.rejected_count -gt 0) 'chunk rejected count must be positive'
    Assert-True ([int]$C.subchunk_count -eq 50) 'chunk subchunk count must be 50'
    Assert-True ([int]$C.understood_count -gt 0) 'chunk understood count missing'
    Assert-True ([int]$C.assimilated_count -gt 0) 'chunk assimilated count missing'
    Assert-True ([int]$C.promoted_delta_count -gt 0) 'chunk promoted delta count missing'
    Assert-True ([int]$C.quarantined_delta_count -ge 0) 'chunk quarantined count invalid'
    Assert-True ([int]$C.comprehension_sample_count -gt 0) 'chunk comprehension sample count missing'

    foreach ($status in $RequiredStatuses) {
        Assert-True (@($C.statuses_modeled) -contains $status) "chunk missing modeled status: $status"
        Assert-True (Has-Property $C.status_counts $status) "chunk missing status count: $status"
        Assert-True ([int]$C.status_counts.$status -ge 0) "chunk status count invalid: $status"
    }
    Assert-True ([int]$C.status_counts.CANDIDATE_ATOM -gt [int]$C.status_counts.ACCEPTED_ATOM) 'candidate status count must exceed accepted count'
    Assert-True ([int]$C.status_counts.ACCEPTED_ATOM -eq 5000) 'accepted status count bad'
    Assert-True ([int]$C.status_counts.UNDERSTOOD_ATOM -gt 0) 'understood status count missing'
    Assert-True ([int]$C.status_counts.ASSIMILATED_ATOM -gt 0) 'assimilated status count missing'
    Assert-True ([int]$C.status_counts.PROMOTION_REJECTED -gt 0) 'promotion rejected status count missing'

    foreach ($name in @('duplicate', 'low_quality', 'conflict_or_unsafe', 'non_actionable')) {
        Assert-True (Has-Property $C.reject_classes $name) "chunk reject class missing: $name"
        Assert-True ([int]$C.reject_classes.$name -gt 0) "chunk reject class count not positive: $name"
    }

    $Samples = @($C.comprehension_samples)
    Assert-True ($Samples.Count -eq [int]$C.comprehension_sample_count) 'chunk sample count mismatch'
    foreach ($S in $Samples) {
        foreach ($field in @('explain_back', 'apply', 'anti_apply', 'status')) {
            Assert-True (Has-Text $S.$field) "sample field missing: $field"
        }
        Assert-True ($null -ne $S.conflict_check) 'sample conflict check missing'
        Assert-True ($S.conflict_check.status -eq 'PASS') 'sample conflict check not PASS'
        Assert-True ($null -ne $S.decision_delta) 'sample decision delta missing'
        Assert-True ([bool]$S.decision_delta.changed_or_guarded -eq $true) 'sample decision not changed or guarded'
        Assert-True ([int]$S.score -gt 0) 'sample score invalid'
        Assert-True (@('UNDERSTOOD_ATOM', 'NOT_UNDERSTOOD_ATOM') -contains [string]$S.status) 'sample status invalid'
    }

    Assert-True ($C.digest_summary.status -eq 'PASS') 'digest status not PASS'
    Assert-True ([bool]$C.digest_summary.compact_delta_only -eq $true) 'digest not compact'
    Assert-True ([bool]$C.digest_summary.raw_archive_dump -eq $false) 'digest raw dump'
    Assert-True ($C.promotion_gate.validator_status -eq 'PASS') 'promotion gate validator not PASS'
    Assert-True ([double]$C.promotion_gate.chunk_local_after_score -gt [double]$C.promotion_gate.chunk_local_before_score) 'chunk local score not improved'
    Assert-True ([int]$C.promotion_gate.critical_regression_count -eq 0) 'chunk critical regression present'
    Assert-True ([int]$C.promotion_gate.unsafe_decision_after -le [int]$C.promotion_gate.unsafe_decision_before) 'chunk unsafe regression'
    Assert-True ([int]$C.promotion_gate.proof_confusion_after -le [int]$C.promotion_gate.proof_confusion_before) 'chunk proof confusion regression'
    Assert-True ([bool]$C.runtime_ready -eq $false) 'chunk runtime_ready overclaim'
}

Assert-True ($P.after_exam.same_or_paired_exam_manifest -eq $true) 'after exam manifest relation missing'
Assert-True ([int]$P.after_exam.new_atoms_used_in_after_decisions -gt 0) 'after exam new atom usage missing'

Write-Host 'VALIDATION_PASS=USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROVEN'
Write-Host "ACCEPTED_TOTAL=$($P.accepted_total)"
Write-Host "REJECTED_TOTAL=$($P.rejected_total)"
Write-Host "CHUNK_COUNT=$($P.chunk_count)"
Write-Host "SUBCHUNK_COUNT=$($P.subchunk_count)"
Write-Host "UNDERSTOOD_ATOM_TOTAL=$($P.understood_atom_total)"
Write-Host "ASSIMILATED_ATOM_TOTAL=$($P.assimilated_atom_total)"
Write-Host "PROMOTED_DELTA_COUNT=$($P.promoted_delta_count)"
Write-Host "BEFORE_SCORE=$($P.before_score)"
Write-Host "AFTER_SCORE=$($P.after_score)"
Write-Host 'RUNTIME_READY=false'
