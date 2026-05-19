param(
    [switch]$FinalizePhase,
    [string]$RunId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot

. ".\modules\new_gap_remediation_intake_report.ps1"

$RawIdeaPath = ".\specs\specialization_gap_proof\RAW_IDEA_MISSING_PROFILE_FACTORY_PROOF.json"
$GapRunId = "$RunId`__GAP_RUNTIME"
$CandidateRunId = "$RunId`__CANDIDATE_RUNTIME"

& ".\orchestrator\run.ps1" `
    -Mode BUILD_FROM_RAW_IDEA_SPECIALIZED `
    -RunId $GapRunId `
    -RawIdeaPath $RawIdeaPath `
    -OutputRoot ".\generated_agents" |
    Out-Host

$GapFactoryReportPath = ".\runs\$GapRunId\BUILD_FROM_RAW_IDEA_SPECIALIZED_MODE_V1\BUILD_FROM_RAW_IDEA_SPECIALIZED_REPORT.json"
if (-not (Test-Path $GapFactoryReportPath)) {
    throw "Runtime proof gap factory report missing."
}

$GapFactoryReport = Get-Content $GapFactoryReportPath -Raw | ConvertFrom-Json
if ($GapFactoryReport.status -ne "SPECIALIZATION_GAP") {
    throw "Runtime proof source route must produce SPECIALIZATION_GAP."
}

& ".\orchestrator\run.ps1" `
    -Mode GAP_TO_PROFILE_CANDIDATE `
    -RunId $CandidateRunId `
    -GapReportPath $GapFactoryReport.gap_report.report_path |
    Out-Host

$CandidatePath = ".\runs\$CandidateRunId\GAP_TO_PROFILE_CANDIDATE_MODE_V1\SPECIALIZATION_PROFILE_CANDIDATE.json"
if (-not (Test-Path $CandidatePath)) {
    throw "Runtime proof candidate artifact missing."
}

$IntakeModeRoot = ".\runs\$RunId\PHASE35_RUNTIME_GAP_TO_CANDIDATE_FACTORY_PROOF_V1\intake_report"

$Intake = New-GapRemediationIntakeReport `
    -RunId $RunId `
    -ModeRoot $IntakeModeRoot `
    -GapReportPath $GapFactoryReport.gap_report.report_path `
    -CandidatePath $CandidatePath

if ($Intake.status -ne "PASS") {
    throw "Runtime proof intake report failed."
}

if (-not (Test-Path $Intake.report_path)) {
    throw "Runtime proof intake report missing."
}

$Candidate = Get-Content $CandidatePath -Raw | ConvertFrom-Json
$IntakeJson = Get-Content $Intake.report_path -Raw | ConvertFrom-Json

if ($Candidate.candidate_profile_id -ne "decision_support_agent_v1") {
    throw "Runtime proof candidate profile id mismatch."
}

if ($Candidate.candidate_agent_kind -ne "decision_support_agent") {
    throw "Runtime proof candidate agent kind mismatch."
}

if ($IntakeJson.required_build_move -ne "CREATE_SPECIALIZATION_PROFILE_AND_REGISTRY_MAPPING") {
    throw "Runtime proof required build move mismatch."
}

Write-Host "RUNTIME_FACTORY_CANDIDATE_PROFILE_ID=$($Candidate.candidate_profile_id)"
Write-Host "RUNTIME_FACTORY_CANDIDATE_AGENT_KIND=$($Candidate.candidate_agent_kind)"
Write-Host "RUNTIME_FACTORY_CANDIDATE_PATH=$CandidatePath"
Write-Host "RUNTIME_FACTORY_INTAKE_REPORT_PATH=$($Intake.report_path)"

$Proof = [ordered]@{
    proof_id = "RUNTIME_GAP_TO_CANDIDATE_FACTORY_PROOF_V1"
    run_id = $RunId
    status = "PASS"
    source_gap_factory_report = $GapFactoryReportPath
    source_gap_report = $GapFactoryReport.gap_report.report_path
    runtime_candidate_path = $CandidatePath
    runtime_intake_report_path = $Intake.report_path
    candidate_profile_id = $Candidate.candidate_profile_id
    candidate_agent_kind = $Candidate.candidate_agent_kind
    required_build_move = $IntakeJson.required_build_move
    conclusion = "Builder runtime now converts a specialization gap artifact into a normalized profile candidate intake path without requiring a proof-pack-only candidate generator."
}

$Proof | ConvertTo-Json -Depth 100 |
    Set-Content ".\proofs\RUNTIME_GAP_TO_CANDIDATE_FACTORY_PROOF_V1.json" -Encoding UTF8

$State = Get-Content ".\GENESIS_STATE.json" -Raw | ConvertFrom-Json
$Roadmap = Get-Content ".\CAPABILITY_ROADMAP.json" -Raw | ConvertFrom-Json
$Queue = Get-Content ".\TASK_QUEUE.json" -Raw | ConvertFrom-Json

$ThisCap = $Roadmap.capabilities |
    Where-Object { $_.id -eq "runtime_gap_to_candidate_factory_proof_v1" } |
    Select-Object -First 1

$ThisTask = $Queue.tasks |
    Where-Object { $_.task_id -eq "TASK_RUNTIME_GAP_TO_CANDIDATE_FACTORY_PROOF_V1_001" } |
    Select-Object -First 1

if ($State.current_phase -ne "PHASE_35") { throw "Expected PHASE_35." }
if ($State.current_capability -ne "runtime_gap_to_candidate_factory_proof_v1") { throw "Expected runtime_gap_to_candidate_factory_proof_v1." }
if ($Queue.active_task_id -ne "TASK_RUNTIME_GAP_TO_CANDIDATE_FACTORY_PROOF_V1_001") { throw "Unexpected active task." }
if ($ThisCap.status -ne "ACTIVE") { throw "PHASE 35 capability must be ACTIVE." }
if ($ThisTask.status -ne "ACTIVE") { throw "PHASE 35 task must be ACTIVE." }

if ($FinalizePhase) {
    $ThisCap.status = "COMPLETED"

    $State.current_phase = "PHASE_35"
    $State.current_capability = "runtime_gap_to_candidate_factory_proof_v1"
    $State.completed_capabilities += "runtime_gap_to_candidate_factory_proof_v1"
    $State.last_run_status = "PASS"
    $State.gap_remediation_intake_runtime_ready = $true

    $ThisTask.status = "COMPLETED"
    $Queue.active_task_id = "NONE"

    $Roadmap | ConvertTo-Json -Depth 100 |
        Set-Content ".\CAPABILITY_ROADMAP.json" -Encoding UTF8

    $State | ConvertTo-Json -Depth 100 |
        Set-Content ".\GENESIS_STATE.json" -Encoding UTF8

    $Queue | ConvertTo-Json -Depth 100 |
        Set-Content ".\TASK_QUEUE.json" -Encoding UTF8
}

Write-Host "PASS :: runtime_gap_to_candidate_factory_proof_v1 checks passed. run_id=$RunId"
