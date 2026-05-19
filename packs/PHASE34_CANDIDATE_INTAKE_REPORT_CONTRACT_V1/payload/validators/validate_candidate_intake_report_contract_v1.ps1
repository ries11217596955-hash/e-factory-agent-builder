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
$GapRunId = "$RunId`__GAP_SOURCE"
$CandidateRunId = "$RunId`__CANDIDATE_SOURCE"

& ".\orchestrator\run.ps1" `
    -Mode BUILD_FROM_RAW_IDEA_SPECIALIZED `
    -RunId $GapRunId `
    -RawIdeaPath $RawIdeaPath `
    -OutputRoot ".\generated_agents" |
    Out-Host

$GapFactoryReportPath = ".\runs\$GapRunId\BUILD_FROM_RAW_IDEA_SPECIALIZED_MODE_V1\BUILD_FROM_RAW_IDEA_SPECIALIZED_REPORT.json"
if (-not (Test-Path $GapFactoryReportPath)) {
    throw "Gap source factory report missing."
}

$GapFactoryReport = Get-Content $GapFactoryReportPath -Raw | ConvertFrom-Json
if ($GapFactoryReport.status -ne "SPECIALIZATION_GAP") {
    throw "Gap source must remain unsupported in this proof."
}

& ".\orchestrator\run.ps1" `
    -Mode GAP_TO_PROFILE_CANDIDATE `
    -RunId $CandidateRunId `
    -GapReportPath $GapFactoryReport.gap_report.report_path |
    Out-Host

$CandidatePath = ".\runs\$CandidateRunId\GAP_TO_PROFILE_CANDIDATE_MODE_V1\SPECIALIZATION_PROFILE_CANDIDATE.json"
if (-not (Test-Path $CandidatePath)) {
    throw "Candidate source artifact missing."
}

$ModeRoot = ".\runs\$RunId\PHASE34_CANDIDATE_INTAKE_REPORT_CONTRACT_V1\intake_report_proof"

$Intake = New-GapRemediationIntakeReport `
    -RunId $RunId `
    -ModeRoot $ModeRoot `
    -GapReportPath $GapFactoryReport.gap_report.report_path `
    -CandidatePath $CandidatePath

Write-Host "INTAKE_REPORT_STATUS=$($Intake.status)"
Write-Host "INTAKE_REPORT_PROFILE_ID=$($Intake.candidate_profile_id)"
Write-Host "INTAKE_REPORT_AGENT_KIND=$($Intake.candidate_agent_kind)"
Write-Host "INTAKE_REPORT_PATH=$($Intake.report_path)"

if ($Intake.status -ne "PASS") {
    throw "Intake report must return PASS."
}

if ($Intake.candidate_profile_id -ne "decision_support_agent_v1") {
    throw "Unexpected candidate profile id in intake report."
}

if ($Intake.candidate_agent_kind -ne "decision_support_agent") {
    throw "Unexpected candidate agent kind in intake report."
}

if (-not (Test-Path $Intake.report_path)) {
    throw "Intake report artifact missing."
}

$Proof = [ordered]@{
    proof_id = "CANDIDATE_INTAKE_REPORT_CONTRACT_V1"
    run_id = $RunId
    status = "PASS"
    source_gap_factory_report = $GapFactoryReportPath
    source_gap_report = $GapFactoryReport.gap_report.report_path
    candidate_path = $CandidatePath
    intake_report_path = $Intake.report_path
    candidate_profile_id = $Intake.candidate_profile_id
    candidate_agent_kind = $Intake.candidate_agent_kind
    required_build_move = $Intake.required_build_move
}

$Proof | ConvertTo-Json -Depth 100 |
    Set-Content ".\proofs\CANDIDATE_INTAKE_REPORT_CONTRACT_V1.json" -Encoding UTF8

$State = Get-Content ".\GENESIS_STATE.json" -Raw | ConvertFrom-Json
$Roadmap = Get-Content ".\CAPABILITY_ROADMAP.json" -Raw | ConvertFrom-Json
$Queue = Get-Content ".\TASK_QUEUE.json" -Raw | ConvertFrom-Json

$ThisCap = $Roadmap.capabilities |
    Where-Object { $_.id -eq "candidate_intake_report_contract_v1" } |
    Select-Object -First 1

$NextCap = $Roadmap.capabilities |
    Where-Object { $_.id -eq "runtime_gap_to_candidate_factory_proof_v1" } |
    Select-Object -First 1

$ThisTask = $Queue.tasks |
    Where-Object { $_.task_id -eq "TASK_CANDIDATE_INTAKE_REPORT_CONTRACT_V1_001" } |
    Select-Object -First 1

if ($State.current_phase -ne "PHASE_34") { throw "Expected PHASE_34." }
if ($State.current_capability -ne "candidate_intake_report_contract_v1") { throw "Expected candidate_intake_report_contract_v1." }
if ($Queue.active_task_id -ne "TASK_CANDIDATE_INTAKE_REPORT_CONTRACT_V1_001") { throw "Unexpected active task." }
if ($ThisCap.status -ne "ACTIVE") { throw "PHASE 34 capability must be ACTIVE." }
if ($ThisTask.status -ne "ACTIVE") { throw "PHASE 34 task must be ACTIVE." }

if ($FinalizePhase) {
    $ThisCap.status = "COMPLETED"
    $NextCap.status = "ACTIVE"

    $State.current_phase = "PHASE_35"
    $State.current_capability = "runtime_gap_to_candidate_factory_proof_v1"
    $State.completed_capabilities += "candidate_intake_report_contract_v1"
    $State.last_run_status = "PASS"

    $ThisTask.status = "COMPLETED"
    $Queue.active_task_id = "TASK_RUNTIME_GAP_TO_CANDIDATE_FACTORY_PROOF_V1_001"
    $Queue.tasks += [pscustomobject]@{
        task_id = "TASK_RUNTIME_GAP_TO_CANDIDATE_FACTORY_PROOF_V1_001"
        capability_id = "runtime_gap_to_candidate_factory_proof_v1"
        status = "ACTIVE"
        objective = "Prove Builder runtime emits both candidate brief and intake report from a real specialization gap."
        expected_gate = "RUNTIME_GAP_TO_CANDIDATE_FACTORY_PROOF_V1"
        build_task_path = "tasks/TASK_RUNTIME_GAP_TO_CANDIDATE_FACTORY_PROOF_V1_001.json"
    }

    $Roadmap | ConvertTo-Json -Depth 100 |
        Set-Content ".\CAPABILITY_ROADMAP.json" -Encoding UTF8

    $State | ConvertTo-Json -Depth 100 |
        Set-Content ".\GENESIS_STATE.json" -Encoding UTF8

    $Queue | ConvertTo-Json -Depth 100 |
        Set-Content ".\TASK_QUEUE.json" -Encoding UTF8
}

Write-Host "PASS :: candidate_intake_report_contract_v1 checks passed. run_id=$RunId"
