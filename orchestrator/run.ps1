param(
    [ValidateSet(
        "SELF_BUILD",
        "BUILD_EXTERNAL_AGENT",
        "BUILD_FROM_RAW_IDEA",
        "BUILD_FROM_RAW_IDEA_SPECIALIZED",
        "GAP_TO_PROFILE_CANDIDATE",
        "VERIFY"
    )]
    [string]$Mode = "VERIFY",

    [string]$RunId = ("SELF_BUILD_" + (Get-Date -Format "yyyyMMdd_HHmmss")),

    [ValidateRange(1, 25)]
    [int]$MaxPacks = 1,

    [string]$SpecPath,

    [string]$OutputRoot,

    [string]$OverlayRoot = "",

    [string]$RawIdeaPath,

    [string]$DerivedSpecPath = "",

    [string]$GapReportPath,

    [string]$CandidateOutputPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot

Write-Host "AGENT_BUILDER_ORCHESTRATOR"
Write-Host "MODE=$Mode"
Write-Host "RUN_ID=$RunId"

if ($Mode -eq "VERIFY") {
    Write-Host "STATUS=PASS"
    return
}

if ($Mode -eq "GAP_TO_PROFILE_CANDIDATE") {
    if ([string]::IsNullOrWhiteSpace($GapReportPath)) {
        throw "GapReportPath is required."
    }

    . ".\modules\new_specialization_profile_candidate_brief.ps1"
    . ".\modules\new_gap_remediation_intake_report.ps1"
    . ".\modules\new_gap_remediation_program_seed.ps1"

    $ModeRoot = ".\runs\$RunId\GAP_TO_PROFILE_CANDIDATE_MODE_V1"
    New-Item -ItemType Directory -Force -Path $ModeRoot | Out-Null

    if ([string]::IsNullOrWhiteSpace($CandidateOutputPath)) {
        $CandidateOutputPath = Join-Path $ModeRoot "SPECIALIZATION_PROFILE_CANDIDATE.json"
    }

    $Candidate = New-SpecializationProfileCandidateBrief `
        -RunId $RunId `
        -GapReportPath $GapReportPath `
        -CandidateOutputPath $CandidateOutputPath

    $Intake = New-GapRemediationIntakeReport `
        -RunId $RunId `
        -ModeRoot $ModeRoot `
        -GapReportPath $GapReportPath `
        -CandidatePath $Candidate.candidate_path

    Write-Host "GAP_TO_PROFILE_CANDIDATE_STATUS=$($Candidate.status)"
    Write-Host "GAP_TO_PROFILE_CANDIDATE_PROFILE_ID=$($Candidate.candidate_profile_id)"
    Write-Host "GAP_TO_PROFILE_CANDIDATE_AGENT_KIND=$($Candidate.candidate_agent_kind)"
    Write-Host "GAP_TO_PROFILE_CANDIDATE_PATH=$($Candidate.candidate_path)"
    Write-Host "GAP_TO_PROFILE_CANDIDATE_INTAKE_REPORT_STATUS=$($Intake.status)"
    Write-Host "GAP_TO_PROFILE_CANDIDATE_INTAKE_REPORT_PATH=$($Intake.report_path)"
    return
}

if ($Mode -eq "BUILD_EXTERNAL_AGENT") {
    if ([string]::IsNullOrWhiteSpace($SpecPath)) { throw "SpecPath is required." }
    if ([string]::IsNullOrWhiteSpace($OutputRoot)) { throw "OutputRoot is required." }

    . ".\modules\invoke_external_agent_build.ps1"

    $RunRoot = ".\runs\$RunId\BUILD_EXTERNAL_AGENT_MODE_V2"

    $Build = Invoke-ExternalAgentBuild `
        -SpecPath $SpecPath `
        -OutputRoot $OutputRoot `
        -RunRoot $RunRoot `
        -OverlayRoot $OverlayRoot

    Write-Host "BUILD_EXTERNAL_AGENT_STATUS=$($Build.status)"
    Write-Host "BUILD_EXTERNAL_AGENT_PACKAGE_ROOT=$($Build.manifest.package_root)"
    Write-Host "BUILD_EXTERNAL_AGENT_OVERLAY_STATUS=$($Build.overlay.status)"
    Write-Host "BUILD_EXTERNAL_AGENT_OVERLAY_FILE_COUNT=$($Build.overlay.applied_file_count)"
    Write-Host "BUILD_EXTERNAL_AGENT_REPORT_PATH=$($Build.report_path)"
    return
}

if ($Mode -eq "BUILD_FROM_RAW_IDEA") {
    if ([string]::IsNullOrWhiteSpace($RawIdeaPath)) { throw "RawIdeaPath is required." }
    if ([string]::IsNullOrWhiteSpace($OutputRoot)) { throw "OutputRoot is required." }

    . ".\modules\invoke_agent_spec_architect_handoff.ps1"
    . ".\modules\invoke_external_agent_build.ps1"

    $ModeRoot = ".\runs\$RunId\BUILD_FROM_RAW_IDEA_MODE_V1"
    New-Item -ItemType Directory -Force -Path $ModeRoot | Out-Null

    if ([string]::IsNullOrWhiteSpace($DerivedSpecPath)) {
        $DerivedSpecPath = Join-Path $ModeRoot "DERIVED_AGENT_SPEC.json"
    }

    $Handoff = Invoke-AgentSpecArchitectHandoff `
        -ArchitectSpecPath ".\specs\applied_agents\agent_spec_architect\AGENT_SPEC_ARCHITECT_SPEC.json" `
        -ArchitectOverlayRoot ".\applied_agents\agent_spec_architect\overlay" `
        -RawIdeaRequestPath $RawIdeaPath `
        -GeneratedAgentsRoot ".\generated_agents" `
        -RunRoot (Join-Path $ModeRoot "architect_handoff") `
        -DerivedSpecOutputPath $DerivedSpecPath

    if ($Handoff.status -ne "PASS") {
        throw "Raw idea handoff failed."
    }

    $TargetBuild = Invoke-ExternalAgentBuild `
        -SpecPath $Handoff.derived_spec_path `
        -OutputRoot $OutputRoot `
        -RunRoot (Join-Path $ModeRoot "target_build")

    if ($TargetBuild.status -ne "PASS") {
        throw "Derived external agent build failed."
    }

    $Report = [ordered]@{
        report_id = "BUILD_FROM_RAW_IDEA_MODE_V1"
        run_id = $RunId
        status = "PASS"
        raw_idea_path = $RawIdeaPath
        derived_spec_path = $Handoff.derived_spec_path
        derived_agent_id = $Handoff.derived_agent_id
        architect_handoff = $Handoff
        target_build = [ordered]@{
            status = $TargetBuild.status
            package_root = $TargetBuild.manifest.package_root
            report_path = $TargetBuild.report_path
            validation_output = $TargetBuild.validation.output_result_path
        }
    }

    $ReportPath = Join-Path $ModeRoot "BUILD_FROM_RAW_IDEA_REPORT.json"
    $Report | ConvertTo-Json -Depth 100 |
        Set-Content $ReportPath -Encoding UTF8

    Write-Host "BUILD_FROM_RAW_IDEA_STATUS=$($Report.status)"
    Write-Host "BUILD_FROM_RAW_IDEA_DERIVED_AGENT_ID=$($Report.derived_agent_id)"
    Write-Host "BUILD_FROM_RAW_IDEA_DERIVED_SPEC_PATH=$($Report.derived_spec_path)"
    Write-Host "BUILD_FROM_RAW_IDEA_PACKAGE_ROOT=$($Report.target_build.package_root)"
    Write-Host "BUILD_FROM_RAW_IDEA_REPORT_PATH=$ReportPath"
    return
}

if ($Mode -eq "BUILD_FROM_RAW_IDEA_SPECIALIZED") {
    if ([string]::IsNullOrWhiteSpace($RawIdeaPath)) { throw "RawIdeaPath is required." }
    if ([string]::IsNullOrWhiteSpace($OutputRoot)) { throw "OutputRoot is required." }

    . ".\modules\invoke_agent_spec_architect_handoff.ps1"
    . ".\modules\invoke_external_agent_build.ps1"
    . ".\modules\resolve_specialization_overlay.ps1"
    . ".\modules\new_specialization_gap_report.ps1"
    . ".\modules\new_specialization_profile_candidate_brief.ps1"
    . ".\modules\new_gap_remediation_intake_report.ps1"
    . ".\modules\new_gap_remediation_program_seed.ps1"

    $ModeRoot = ".\runs\$RunId\BUILD_FROM_RAW_IDEA_SPECIALIZED_MODE_V1"
    New-Item -ItemType Directory -Force -Path $ModeRoot | Out-Null

    if ([string]::IsNullOrWhiteSpace($DerivedSpecPath)) {
        $DerivedSpecPath = Join-Path $ModeRoot "DERIVED_AGENT_SPEC.json"
    }

    $Handoff = Invoke-AgentSpecArchitectHandoff `
        -ArchitectSpecPath ".\specs\applied_agents\agent_spec_architect\AGENT_SPEC_ARCHITECT_SPEC.json" `
        -ArchitectOverlayRoot ".\applied_agents\agent_spec_architect\overlay" `
        -RawIdeaRequestPath $RawIdeaPath `
        -GeneratedAgentsRoot ".\generated_agents" `
        -RunRoot (Join-Path $ModeRoot "architect_handoff") `
        -DerivedSpecOutputPath $DerivedSpecPath

    if ($Handoff.status -ne "PASS") {
        throw "Raw idea handoff failed."
    }

    $DerivedSpec = Get-Content $Handoff.derived_spec_path -Raw | ConvertFrom-Json

    $Specialization = Resolve-SpecializationOverlay `
        -AgentKind $DerivedSpec.agent_kind `
        -PackageProfile $DerivedSpec.package_profile

    if ($Specialization.status -eq "NO_MATCH") {
        $Gap = New-SpecializationGapReport `
            -RunId $RunId `
            -ModeRoot $ModeRoot `
            -RawIdeaPath $RawIdeaPath `
            -DerivedSpecPath $Handoff.derived_spec_path `
            -DerivedSpec $DerivedSpec `
            -Specialization $Specialization

        $CandidatePath = Join-Path $ModeRoot "SPECIALIZATION_PROFILE_CANDIDATE.json"

        $Candidate = New-SpecializationProfileCandidateBrief `
            -RunId $RunId `
            -GapReportPath $Gap.report_path `
            -CandidateOutputPath $CandidatePath

        $Intake = New-GapRemediationIntakeReport `
            -RunId $RunId `
            -ModeRoot $ModeRoot `
            -GapReportPath $Gap.report_path `
            -CandidatePath $Candidate.candidate_path

        $ProgramSeed = New-GapRemediationProgramSeed `
            -RunId $RunId `
            -ModeRoot $ModeRoot `
            -GapReportPath $Gap.report_path `
            -CandidatePath $Candidate.candidate_path `
            -IntakeReportPath $Intake.report_path

        $Report = [ordered]@{
            report_id = "BUILD_FROM_RAW_IDEA_SPECIALIZED_MODE_V1"
            run_id = $RunId
            status = "SPECIALIZATION_GAP"
            raw_idea_path = $RawIdeaPath
            derived_spec_path = $Handoff.derived_spec_path
            derived_agent_id = $Handoff.derived_agent_id
            architect_handoff = $Handoff
            specialization = [ordered]@{
                status = $Specialization.status
                profile_id = $Specialization.profile_id
                profile_kind = $Specialization.profile_kind
                overlay_root = $Specialization.overlay_root
                resolution_reason = $Specialization.resolution_reason
            }
            gap_report = [ordered]@{
                status = $Gap.status
                report_path = $Gap.report_path
                diagnostic_status = $Gap.diagnostic_status
                missing_agent_kind = $Gap.missing_agent_kind
                requested_package_profile = $Gap.requested_package_profile
            }
            remediation_intake = [ordered]@{
                status = "PASS"
                candidate_status = $Candidate.status
                candidate_path = $Candidate.candidate_path
                candidate_profile_id = $Candidate.candidate_profile_id
                candidate_agent_kind = $Candidate.candidate_agent_kind
                intake_report_status = $Intake.status
                intake_report_path = $Intake.report_path
                required_build_move = $Intake.required_build_move
            }
            remediation_program_seed = [ordered]@{
                status = $ProgramSeed.status
                seed_path = $ProgramSeed.seed_path
                program_id = $ProgramSeed.program_id
                candidate_profile_id = $ProgramSeed.candidate_profile_id
                candidate_agent_kind = $ProgramSeed.candidate_agent_kind
                program_kind = $ProgramSeed.program_kind
                required_operator_move = $ProgramSeed.required_operator_move
            }
            target_build = $null
        }

        $ReportPath = Join-Path $ModeRoot "BUILD_FROM_RAW_IDEA_SPECIALIZED_REPORT.json"
        $Report | ConvertTo-Json -Depth 100 |
            Set-Content $ReportPath -Encoding UTF8

        Write-Host "BUILD_FROM_RAW_IDEA_SPECIALIZED_STATUS=$($Report.status)"
        Write-Host "BUILD_FROM_RAW_IDEA_SPECIALIZED_DERIVED_AGENT_ID=$($Report.derived_agent_id)"
        Write-Host "BUILD_FROM_RAW_IDEA_SPECIALIZED_PROFILE_ID=$($Report.specialization.profile_id)"
        Write-Host "BUILD_FROM_RAW_IDEA_SPECIALIZED_GAP_REPORT_PATH=$($Report.gap_report.report_path)"
        Write-Host "BUILD_FROM_RAW_IDEA_SPECIALIZED_REMEDIATION_CANDIDATE_PATH=$($Report.remediation_intake.candidate_path)"
        Write-Host "BUILD_FROM_RAW_IDEA_SPECIALIZED_REMEDIATION_INTAKE_REPORT_PATH=$($Report.remediation_intake.intake_report_path)"
        Write-Host "BUILD_FROM_RAW_IDEA_SPECIALIZED_REMEDIATION_PROGRAM_SEED_PATH=$($Report.remediation_program_seed.seed_path)"
        Write-Host "BUILD_FROM_RAW_IDEA_SPECIALIZED_REPORT_PATH=$ReportPath"
        return
    }
    if ($Specialization.status -ne "PASS") {
        throw "Unexpected specialization resolver status: $($Specialization.status)"
    }

    $TargetBuild = Invoke-ExternalAgentBuild `
        -SpecPath $Handoff.derived_spec_path `
        -OutputRoot $OutputRoot `
        -RunRoot (Join-Path $ModeRoot "target_build") `
        -OverlayRoot $Specialization.overlay_root

    if ($TargetBuild.status -ne "PASS") {
        throw "Specialized target external agent build failed."
    }

    $Report = [ordered]@{
        report_id = "BUILD_FROM_RAW_IDEA_SPECIALIZED_MODE_V1"
        run_id = $RunId
        status = "PASS"
        raw_idea_path = $RawIdeaPath
        derived_spec_path = $Handoff.derived_spec_path
        derived_agent_id = $Handoff.derived_agent_id
        architect_handoff = $Handoff
        specialization = [ordered]@{
            status = $Specialization.status
            profile_id = $Specialization.profile_id
            profile_kind = $Specialization.profile_kind
            overlay_root = $Specialization.overlay_root
            resolution_reason = $Specialization.resolution_reason
        }
        gap_report = $null
        target_build = [ordered]@{
            status = $TargetBuild.status
            package_root = $TargetBuild.manifest.package_root
            report_path = $TargetBuild.report_path
            validation_output = $TargetBuild.validation.output_result_path
            overlay_status = $TargetBuild.overlay.status
            overlay_file_count = $TargetBuild.overlay.applied_file_count
        }
    }

    $ReportPath = Join-Path $ModeRoot "BUILD_FROM_RAW_IDEA_SPECIALIZED_REPORT.json"
    $Report | ConvertTo-Json -Depth 100 |
        Set-Content $ReportPath -Encoding UTF8

    Write-Host "BUILD_FROM_RAW_IDEA_SPECIALIZED_STATUS=$($Report.status)"
    Write-Host "BUILD_FROM_RAW_IDEA_SPECIALIZED_DERIVED_AGENT_ID=$($Report.derived_agent_id)"
    Write-Host "BUILD_FROM_RAW_IDEA_SPECIALIZED_PROFILE_ID=$($Report.specialization.profile_id)"
    Write-Host "BUILD_FROM_RAW_IDEA_SPECIALIZED_OVERLAY_STATUS=$($Report.target_build.overlay_status)"
    Write-Host "BUILD_FROM_RAW_IDEA_SPECIALIZED_PACKAGE_ROOT=$($Report.target_build.package_root)"
    Write-Host "BUILD_FROM_RAW_IDEA_SPECIALIZED_REPORT_PATH=$ReportPath"
    return
}

. ".\modules\read_pack_registry.ps1"
. ".\modules\select_self_build_pack.ps1"
. ".\modules\execute_self_build_pack.ps1"

Write-Host "MAX_PACKS=$MaxPacks"

$Executed = 0

for ($i = 1; $i -le $MaxPacks; $i++) {
    $Queue = Get-Content ".\TASK_QUEUE.json" -Raw | ConvertFrom-Json
    $Registry = Read-SelfBuildPackRegistry -RepoRoot $RepoRoot

    if ($Mode -eq "SELF_BUILD" -and "$($Queue.active_task_id)" -eq "NONE") {
        $Phase139StepId = "PHASE139_BUILD_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_V1"
        $Phase138DProofPath = ".\proofs\self_development\PHASE138D_OWNER_APPROVED_SANDBOX_BRANCH_MERGE_V1.json"

        if (Test-Path -LiteralPath $Phase138DProofPath) {
            $Phase138DProof = Get-Content -LiteralPath $Phase138DProofPath -Raw | ConvertFrom-Json

            if ($Phase138DProof.status -eq "PASS" -and $Phase138DProof.next_allowed_step -eq "PHASE139_DELEGATED_AUTONOMY_POLICY_ENFORCEMENT_V1") {
                . ".\modules\invoke_builder_self_pack_author_conveyor_001.ps1"

                $BuilderSelfPackAuthorRoot = ".\self_build_batch\autonomy_trials\$Phase139StepId"
                $BuilderSelfPackAuthor = Invoke-BuilderSelfPackAuthorConveyor001 -RepoRoot $RepoRoot -RunId $RunId -OutputRoot $BuilderSelfPackAuthorRoot

                Write-Host "BUILDER_SELF_PACK_AUTHOR_CONVEYOR=PHASE139_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_001"
                Write-Host "SELF_PACK_AUTHOR_STATUS=$($BuilderSelfPackAuthor.status)"
                Write-Host "BUILDER_GENERATED_PACK_COUNT=$($BuilderSelfPackAuthor.builder_generated_pack_count)"
                Write-Host "BUILDER_GENERATED_PACK_ID=$($BuilderSelfPackAuthor.generated_pack_id)"
                Write-Host "GENERATED_PACK_AUTHOR=$($BuilderSelfPackAuthor.generated_pack_author)"
                Write-Host "CODEX_AUTHORED_GENERATED_PACK=$($BuilderSelfPackAuthor.codex_authored_generated_pack)"
                Write-Host "CODEX_BOOTSTRAP_USED=$($BuilderSelfPackAuthor.codex_bootstrap_used)"
                Write-Host "GENERATED_PACK_ADMITTED=$($BuilderSelfPackAuthor.generated_pack_admitted)"
                Write-Host "GENERATED_PACK_EXECUTED=$($BuilderSelfPackAuthor.generated_pack_executed)"
                Write-Host "EXTERNAL_AGENT_PRODUCTION_ALLOWED=$($BuilderSelfPackAuthor.external_agent_production_allowed)"
                Write-Host "MATERIAL_TRUSTED_COUNT=$($BuilderSelfPackAuthor.trusted_material_count)"
                Write-Host "MATERIAL_EXTERNAL_FETCH_PERFORMED=$($BuilderSelfPackAuthor.external_fetch_performed)"
                Write-Host "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=$($BuilderSelfPackAuthor.dependency_install_performed)"
                Write-Host "MATERIAL_EXECUTABLE_USED=$($BuilderSelfPackAuthor.executable_materials_used)"
                Write-Host "SELF_PACK_AUTHOR_NEXT_STEP=$($BuilderSelfPackAuthor.proposed_next_step)"
                Write-Host "STATUS=PASS_STOPPED_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_BUILT"
                return
            }
        }

        $Phase138CStepId = "PHASE138C_SANDBOX_BRANCH_MERGE_DECISION_V1"
        $Phase138BProofPath = ".\proofs\self_development\PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_V1.json"

        if (Test-Path -LiteralPath $Phase138BProofPath) {
            $Phase138BProof = Get-Content -LiteralPath $Phase138BProofPath -Raw | ConvertFrom-Json

            if ($Phase138BProof.status -eq "PASS" -and $Phase138BProof.next_allowed_step -eq $Phase138CStepId) {
                . ".\modules\invoke_sandbox_branch_merge_decision_001.ps1"

                $SandboxBranchMergeRoot = ".\self_build_batch\autonomy_trials\$Phase138CStepId"
                $SandboxBranchMerge = Invoke-SandboxBranchMergeDecision001 -RepoRoot $RepoRoot -RunId $RunId -OutputRoot $SandboxBranchMergeRoot

                Write-Host "SANDBOX_BRANCH_MERGE_DECISION=PHASE138C_SANDBOX_BRANCH_MERGE_DECISION_001"
                Write-Host "MERGE_DECISION_STATUS=$($SandboxBranchMerge.status)"
                Write-Host "MERGE_SOURCE_BRANCH=$($SandboxBranchMerge.source_branch)"
                Write-Host "MERGE_TARGET_BRANCH=$($SandboxBranchMerge.target_branch)"
                Write-Host "MERGE_RECOMMENDATION=$($SandboxBranchMerge.merge_recommendation)"
                Write-Host "MERGE_ALLOWED_NOW=$($SandboxBranchMerge.merge_allowed_now)"
                Write-Host "OWNER_APPROVAL_REQUIRED=$($SandboxBranchMerge.owner_approval_required)"
                Write-Host "PRODUCTION_ADOPTION_ALLOWED=$($SandboxBranchMerge.production_adoption_allowed)"
                Write-Host "MATERIAL_TRUSTED_COUNT=$($SandboxBranchMerge.trusted_material_count)"
                Write-Host "MATERIAL_EXTERNAL_FETCH_PERFORMED=$($SandboxBranchMerge.external_fetch_performed)"
                Write-Host "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=$($SandboxBranchMerge.dependency_install_performed)"
                Write-Host "MATERIAL_EXECUTABLE_USED=$($SandboxBranchMerge.executable_materials_used)"
                Write-Host "MERGE_DECISION_NEXT_STEP=$($SandboxBranchMerge.proposed_next_step)"
                Write-Host "STATUS=PASS_STOPPED_SANDBOX_BRANCH_MERGE_DECISION_BUILT"
                return
            }
        }

        $Phase138BStepId = "PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_V1"
        $Phase138AProofPath = ".\proofs\self_development\PHASE138A_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_V1.json"

        if (Test-Path -LiteralPath $Phase138AProofPath) {
            $Phase138AProof = Get-Content -LiteralPath $Phase138AProofPath -Raw | ConvertFrom-Json

            if ($Phase138AProof.status -eq "PASS" -and $Phase138AProof.next_allowed_step -eq $Phase138BStepId) {
                . ".\modules\invoke_review_autonomous_material_decision_stress_results_001.ps1"

                $AutonomousMaterialDecisionReviewRoot = ".\self_build_batch\autonomy_trials\$Phase138BStepId"
                $AutonomousMaterialDecisionReview = Invoke-ReviewAutonomousMaterialDecisionStressResults001 -RepoRoot $RepoRoot -RunId $RunId -OutputRoot $AutonomousMaterialDecisionReviewRoot

                Write-Host "AUTONOMOUS_MATERIAL_DECISION_REVIEW=PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_001"
                Write-Host "REVIEW_STATUS=$($AutonomousMaterialDecisionReview.status)"
                Write-Host "REVIEW_SELECTED_MATERIAL=$($AutonomousMaterialDecisionReview.selected_material_id)"
                Write-Host "REVIEW_DATASET_RECORD_COUNT=$($AutonomousMaterialDecisionReview.stress_dataset_record_count)"
                Write-Host "REVIEW_POLICY_VIOLATION_COUNT=$($AutonomousMaterialDecisionReview.policy_violation_count)"
                Write-Host "REVIEW_VIOLATION_SUM=$($AutonomousMaterialDecisionReview.violation_sum)"
                Write-Host "REVIEW_PRODUCTION_ADOPTION_ALLOWED=$($AutonomousMaterialDecisionReview.production_adoption_allowed)"
                Write-Host "REVIEW_TRUSTED=$($false)"
                Write-Host "REVIEW_EXTERNAL_FETCH_PERFORMED=$($AutonomousMaterialDecisionReview.external_fetch_performed)"
                Write-Host "REVIEW_DEPENDENCY_INSTALL_PERFORMED=$($AutonomousMaterialDecisionReview.dependency_install_performed)"
                Write-Host "REVIEW_EXECUTABLE_USED=$($AutonomousMaterialDecisionReview.executable_materials_used)"
                Write-Host "REVIEW_NEXT_STEP=$($AutonomousMaterialDecisionReview.proposed_next_step)"
                Write-Host "STATUS=PASS_STOPPED_AUTONOMOUS_MATERIAL_DECISION_REVIEW_BUILT"
                return
            }
        }

        $Phase138AStepId = "PHASE138A_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_V1"
        $Phase137ProofPath = ".\proofs\self_development\PHASE137_BUILD_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_V1.json"

        if (Test-Path -LiteralPath $Phase137ProofPath) {
            $Phase137Proof = Get-Content -LiteralPath $Phase137ProofPath -Raw | ConvertFrom-Json

            if ($Phase137Proof.status -eq "PASS" -and $Phase137Proof.next_allowed_step -eq "PHASE138_OWNER_DECISION_FOR_FIRST_MATERIAL_ADOPTION_V1") {
                . ".\modules\invoke_autonomous_material_decision_stress_lab_001.ps1"

                $AutonomousMaterialDecisionRoot = ".\self_build_batch\autonomy_trials\$Phase138AStepId"
                $AutonomousMaterialDecision = Invoke-AutonomousMaterialDecisionStressLab001 -RepoRoot $RepoRoot -RunId $RunId -OutputRoot $AutonomousMaterialDecisionRoot

                Write-Host "AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB=PHASE138A_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_001"
                Write-Host "STRESS_DATASET_RECORD_COUNT=$($AutonomousMaterialDecision.stress_dataset_record_count)"
                Write-Host "AUTONOMOUS_SELECTED_COUNT=$($AutonomousMaterialDecision.autonomous_selected_count)"
                Write-Host "OWNER_DELEGATED_SANDBOX_DECISION=$($AutonomousMaterialDecision.owner_delegated_sandbox_decision)"
                Write-Host "OWNER_MANUAL_PICK=$($AutonomousMaterialDecision.owner_manual_pick)"
                Write-Host "PRODUCTION_ADOPTION_ALLOWED=$($AutonomousMaterialDecision.production_adoption_allowed)"
                Write-Host "MATERIAL_TRUSTED_COUNT=$($AutonomousMaterialDecision.trusted_material_count)"
                Write-Host "MATERIAL_EXTERNAL_FETCH_PERFORMED=$($AutonomousMaterialDecision.external_fetch_performed)"
                Write-Host "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=$($AutonomousMaterialDecision.dependency_install_performed)"
                Write-Host "MATERIAL_EXECUTABLE_USED=$($AutonomousMaterialDecision.executable_materials_used)"
                Write-Host "MATERIAL_WRAPPER_CREATED=$($AutonomousMaterialDecision.wrapper_created)"
                Write-Host "MATERIAL_SMOKE_TEST_EXECUTED=$($AutonomousMaterialDecision.smoke_test_executed)"
                Write-Host "AUTONOMOUS_DECISION_NEXT_STEP=$($AutonomousMaterialDecision.proposed_next_step)"
                Write-Host "STATUS=PASS_STOPPED_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_BUILT"
                return
            }
        }

        $Phase137StepId = "PHASE137_BUILD_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_V1"
        $Phase136ProofPath = ".\proofs\self_development\PHASE136_IMPORT_MANUAL_MATERIAL_SCOUT_PASS_TO_CATALOG_V1.json"

        if (Test-Path -LiteralPath $Phase136ProofPath) {
            $Phase136Proof = Get-Content -LiteralPath $Phase136ProofPath -Raw | ConvertFrom-Json

            if ($Phase136Proof.status -eq "PASS" -and $Phase136Proof.next_allowed_step -eq $Phase137StepId) {
                . ".\modules\invoke_material_quarantine_evaluation_runtime_001.ps1"

                $MaterialQuarantineRoot = ".\self_build_batch\autonomy_trials\$Phase137StepId"
                $MaterialQuarantine = Invoke-MaterialQuarantineEvaluationRuntime001 -RepoRoot $RepoRoot -RunId $RunId -OutputRoot $MaterialQuarantineRoot

                Write-Host "MATERIAL_QUARANTINE_EVALUATION_RUNTIME=PHASE137_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_001"
                Write-Host "MATERIAL_QUARANTINE_EVALUATION_STATUS=$($MaterialQuarantine.status)"
                Write-Host "MATERIAL_EVALUATED_COUNT=$($MaterialQuarantine.evaluated_material_count)"
                Write-Host "MATERIAL_TRUSTED_COUNT=$($MaterialQuarantine.trusted_material_count)"
                Write-Host "MATERIAL_EXTERNAL_FETCH_PERFORMED=$($MaterialQuarantine.external_fetch_performed)"
                Write-Host "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=$($MaterialQuarantine.dependency_install_performed)"
                Write-Host "MATERIAL_EXECUTABLE_USED=$($MaterialQuarantine.executable_materials_used)"
                Write-Host "MATERIAL_REFERENCE_ONLY_EVALUATED_AS_EXECUTABLE=$($MaterialQuarantine.reference_only_evaluated_as_executable)"
                Write-Host "MATERIAL_OWNER_DECISION_REQUIRED_COUNT=$($MaterialQuarantine.owner_decision_required_count)"
                Write-Host "MATERIAL_QUARANTINE_NEXT_STEP=$($MaterialQuarantine.proposed_next_step)"
                Write-Host "STATUS=PASS_STOPPED_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_BUILT"
                return
            }
        }

        $Phase136StepId = "PHASE136_IMPORT_MANUAL_MATERIAL_SCOUT_PASS_TO_CATALOG_V1"
        $Phase135ProofPath = ".\proofs\self_development\PHASE135_RUN_MANUAL_MATERIAL_SCOUT_PASS_001_V1.json"

        if (Test-Path -LiteralPath $Phase135ProofPath) {
            $Phase135Proof = Get-Content -LiteralPath $Phase135ProofPath -Raw | ConvertFrom-Json

            if ($Phase135Proof.status -eq "PASS" -and $Phase135Proof.next_allowed_step -eq $Phase136StepId) {
                . ".\modules\invoke_material_governance_series_001.ps1"

                $MaterialGovernanceRoot = ".\self_build_batch\autonomy_trials\$Phase136StepId"
                $MaterialGovernance = Invoke-MaterialGovernanceSeries001 -RepoRoot $RepoRoot -RunId $RunId -OutputRoot $MaterialGovernanceRoot

                Write-Host "MATERIAL_GOVERNANCE_SERIES=PHASE136_MATERIAL_GOVERNANCE_SERIES_001"
                Write-Host "MATERIAL_GOVERNANCE_SERIES_STATUS=$($MaterialGovernance.status)"
                Write-Host "MATERIAL_IMPORTED_COUNT=$($MaterialGovernance.imported_material_count)"
                Write-Host "MATERIAL_CANDIDATE_COUNT=$($MaterialGovernance.candidate_material_count)"
                Write-Host "MATERIAL_REFERENCE_ONLY_COUNT=$($MaterialGovernance.reference_only_material_count)"
                Write-Host "MATERIAL_TRUSTED_COUNT=$($MaterialGovernance.trusted_material_count)"
                Write-Host "MATERIAL_EXTERNAL_FETCH_PERFORMED=$($MaterialGovernance.external_fetch_performed)"
                Write-Host "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=$($MaterialGovernance.dependency_install_performed)"
                Write-Host "MATERIAL_EXECUTABLE_USED=$($MaterialGovernance.executable_materials_used)"
                Write-Host "MATERIAL_GOVERNANCE_CATALOG_PATH=$($MaterialGovernance.material_catalog_path)"
                Write-Host "MATERIAL_GOVERNANCE_QUARANTINE_REGISTER_PATH=$($MaterialGovernance.quarantine_register_path)"
                Write-Host "MATERIAL_GOVERNANCE_USE_POLICY_PATH=$($MaterialGovernance.use_policy_path)"
                Write-Host "MATERIAL_GOVERNANCE_EVALUATION_QUEUE_PATH=$($MaterialGovernance.evaluation_queue_path)"
                Write-Host "MATERIAL_GOVERNANCE_NEXT_STEP=$($MaterialGovernance.proposed_next_step)"
                Write-Host "STATUS=PASS_STOPPED_MATERIAL_GOVERNANCE_SERIES_BUILT"
                return
            }
        }

        . ".\modules\invoke_self_model_first_runtime_entrypoint.ps1"
        $SelfModelFirstRoot = ".\self_build_batch\autonomy_trials\PHASE124_BUILD_SELF_MODEL_FIRST_RUNTIME_ENTRYPOINT_V1"
        $Entry = Invoke-SelfModelFirstRuntimeEntrypoint -RepoRoot $RepoRoot -RunId $RunId -OutputRoot $SelfModelFirstRoot

        if ($Entry.status -eq "PASS") {
            Write-Host "SELF_MODEL_FIRST_RUNTIME_ENTRYPOINT=SELF_MODEL_FIRST_RUNTIME_ENTRYPOINT_V1"
            Write-Host "SELF_MODEL_FIRST_STATUS=$($Entry.status)"
            Write-Host "SELF_MODEL_FIRST_DECISION_ID=$($Entry.decision_id)"
            Write-Host "SELF_MODEL_FIRST_ENTRY_MODE=$($Entry.entry_mode)"
            Write-Host "SELF_MODEL_FIRST_CURRENT_NEED=$($Entry.current_need)"
            Write-Host "SELF_MODEL_FIRST_NEXT_STEP=$($Entry.proposed_next_step)"

            if ($Entry.current_need -eq "NEED_CONTROLLER_GOVERNED_SELF_BUILD_TRIAL") {
                . ".\modules\invoke_trial_aware_self_model_advance.ps1"
                $TrialAwareRoot = ".\self_build_batch\autonomy_trials\PHASE126_BUILD_TRIAL_AWARE_SELF_MODEL_ADVANCE_V1"
                $TrialAware = Invoke-TrialAwareSelfModelAdvance -RepoRoot $RepoRoot -RunId $RunId -Entry $Entry -OutputRoot $TrialAwareRoot

                Write-Host "TRIAL_AWARE_SELF_MODEL_ADVANCE=TRIAL_AWARE_SELF_MODEL_ADVANCE_V1"
                Write-Host "TRIAL_AWARE_STATUS=$($TrialAware.status)"
                Write-Host "TRIAL_AWARE_CLOSED_NEED=$($TrialAware.closed_need)"
                Write-Host "TRIAL_AWARE_CURRENT_NEED=$($TrialAware.current_detected_need)"
                Write-Host "TRIAL_AWARE_NEXT_STEP=$($TrialAware.proposed_next_step)"
                Write-Host "STATUS=PASS_STOPPED_TRIAL_AWARE_SELF_MODEL_ADVANCED"
                return
            }

            if ($Entry.current_need -eq "NEED_SELF_BUILD_OPERATION_CONTRACT") {
                . ".\modules\invoke_self_build_operation_contract.ps1"
                $ContractRoot = ".\self_build_batch\autonomy_trials\PHASE127_BUILD_SELF_BUILD_OPERATION_CONTRACT_V1"
                $Contract = Invoke-SelfBuildOperationContract -RepoRoot $RepoRoot -RunId $RunId -Entry $Entry -OutputRoot $ContractRoot

                Write-Host "SELF_BUILD_OPERATION_CONTRACT=SELF_BUILD_OPERATION_CONTRACT_BUILDER_V1"
                Write-Host "SELF_BUILD_OPERATION_CONTRACT_STATUS=$($Contract.status)"
                Write-Host "SELF_BUILD_OPERATION_CONTRACT_CREATED=$($Contract.contract_created)"
                Write-Host "SELF_BUILD_OPERATION_CONTRACT_PATH=$($Contract.contract_path)"
                Write-Host "SELF_BUILD_OPERATION_CONTRACT_NEXT_STEP=$($Contract.proposed_next_step)"

                . ".\modules\invoke_operation_contract_aware_self_model_advance.ps1"
                $OperationContractAwareRoot = ".\self_build_batch\autonomy_trials\PHASE129_BUILD_OPERATION_CONTRACT_AWARE_SELF_MODEL_ADVANCE_V1"
                $OperationContractAware = Invoke-OperationContractAwareSelfModelAdvance -RepoRoot $RepoRoot -RunId $RunId -Entry $Entry -ContractOutput $Contract -OutputRoot $OperationContractAwareRoot

                Write-Host "OPERATION_CONTRACT_AWARE_SELF_MODEL_ADVANCE=OPERATION_CONTRACT_AWARE_SELF_MODEL_ADVANCE_V1"
                Write-Host "OPERATION_CONTRACT_AWARE_STATUS=$($OperationContractAware.status)"
                Write-Host "OPERATION_CONTRACT_AWARE_CLOSED_NEED=$($OperationContractAware.closed_need)"
                Write-Host "OPERATION_CONTRACT_AWARE_CURRENT_NEED=$($OperationContractAware.current_detected_need)"
                Write-Host "OPERATION_CONTRACT_AWARE_NEXT_STEP=$($OperationContractAware.proposed_next_step)"
                Write-Host "STATUS=PASS_STOPPED_OPERATION_CONTRACT_AWARE_SELF_MODEL_ADVANCED"
                return
            }

            if ($Entry.current_need -eq "NEED_SELF_BUILD_OPERATION_READINESS_GATE") {
                . ".\modules\invoke_self_build_operation_readiness_gate.ps1"
                $ReadinessGateRoot = ".\self_build_batch\autonomy_trials\PHASE130_BUILD_SELF_BUILD_OPERATION_READINESS_GATE_V1"
                $ReadinessGate = Invoke-SelfBuildOperationReadinessGate -RepoRoot $RepoRoot -RunId $RunId -Entry $Entry -OutputRoot $ReadinessGateRoot

                Write-Host "SELF_BUILD_OPERATION_READINESS_GATE=SELF_BUILD_OPERATION_READINESS_GATE_BUILDER_V1"
                Write-Host "SELF_BUILD_OPERATION_READINESS_GATE_STATUS=$($ReadinessGate.status)"
                Write-Host "SELF_BUILD_OPERATION_READINESS_GATE_CREATED=$($ReadinessGate.gate_created)"
                Write-Host "SELF_BUILD_OPERATION_READINESS_GATE_DECISION=$($ReadinessGate.decision)"
                Write-Host "SELF_BUILD_OPERATION_READINESS_GATE_PATH=$($ReadinessGate.gate_path)"
                Write-Host "SELF_BUILD_OPERATION_READINESS_GATE_NEXT_STEP=$($ReadinessGate.proposed_next_step)"

                . ".\modules\invoke_operation_trial_aware_self_model_advance.ps1"
                $OperationTrialAwareRoot = ".\self_build_batch\autonomy_trials\PHASE132_BUILD_OPERATION_TRIAL_AWARE_SELF_MODEL_ADVANCE_V1"
                $OperationTrialAware = Invoke-OperationTrialAwareSelfModelAdvance -RepoRoot $RepoRoot -RunId $RunId -Entry $Entry -ReadinessGate $ReadinessGate -OutputRoot $OperationTrialAwareRoot

                Write-Host "OPERATION_TRIAL_AWARE_SELF_MODEL_ADVANCE=OPERATION_TRIAL_AWARE_SELF_MODEL_ADVANCE_V1"
                Write-Host "OPERATION_TRIAL_AWARE_STATUS=$($OperationTrialAware.status)"
                Write-Host "OPERATION_TRIAL_AWARE_CLOSED_NEED=$($OperationTrialAware.closed_need)"
                Write-Host "OPERATION_TRIAL_AWARE_CURRENT_NEED=$($OperationTrialAware.current_detected_need)"
                Write-Host "OPERATION_TRIAL_AWARE_NEXT_STEP=$($OperationTrialAware.proposed_next_step)"
                Write-Host "STATUS=PASS_STOPPED_OPERATION_TRIAL_AWARE_SELF_MODEL_ADVANCED"
                return
            }

            if ($Entry.current_need -eq "NEED_SELF_BUILD_OPERATION_CAPABILITY_SELECTOR") {
                . ".\modules\invoke_self_build_operation_capability_selector.ps1"
                $CapabilitySelectorRoot = ".\self_build_batch\autonomy_trials\PHASE133_BUILD_SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_V1"
                $CapabilitySelector = Invoke-SelfBuildOperationCapabilitySelector -RepoRoot $RepoRoot -RunId $RunId -Entry $Entry -OutputRoot $CapabilitySelectorRoot

                Write-Host "SELF_BUILD_OPERATION_CAPABILITY_SELECTOR=SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_BUILDER_V1"
                Write-Host "SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_STATUS=$($CapabilitySelector.status)"
                Write-Host "SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_CREATED=$($CapabilitySelector.selector_created)"
                Write-Host "SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_SELECTED_NEED=$($CapabilitySelector.selected_need_id)"
                Write-Host "SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_SELECTED_CAPABILITY=$($CapabilitySelector.selected_capability_id)"
                Write-Host "SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_PATH=$($CapabilitySelector.selector_path)"
                Write-Host "SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_NEXT_STEP=$($CapabilitySelector.proposed_next_step)"

                if ($CapabilitySelector.selected_need_id -eq "NEED_MATERIAL_ACQUISITION_BOOTSTRAP") {
                    Write-Host "MATERIAL_BOOTSTRAP_AFTER_CAPABILITY_SELECTOR_V1=YES"
                    . ".\modules\invoke_material_acquisition_bootstrap.ps1"
                    $MaterialBootstrapRoot = ".\self_build_batch\autonomy_trials\PHASE134_BUILD_MATERIAL_ACQUISITION_BOOTSTRAP_V1"
                    $MaterialEntry = [pscustomobject]@{
                        status = "PASS"
                        current_need = "NEED_MATERIAL_ACQUISITION_BOOTSTRAP"
                    }
                    $MaterialBootstrap = Invoke-MaterialAcquisitionBootstrap -RepoRoot $RepoRoot -RunId $RunId -Entry $MaterialEntry -OutputRoot $MaterialBootstrapRoot

                    Write-Host "MATERIAL_ACQUISITION_BOOTSTRAP=MATERIAL_ACQUISITION_BOOTSTRAP_BUILDER_V1"
                    Write-Host "MATERIAL_ACQUISITION_BOOTSTRAP_STATUS=$($MaterialBootstrap.status)"
                    Write-Host "MATERIAL_ACQUISITION_BOOTSTRAP_CREATED=$($MaterialBootstrap.bootstrap_created)"
                    Write-Host "MATERIAL_ACQUISITION_BOOTSTRAP_PATH=$($MaterialBootstrap.bootstrap_path)"
                    Write-Host "MATERIAL_CATALOG_PATH=$($MaterialBootstrap.material_catalog_path)"
                    Write-Host "MATERIAL_TRUSTED_COUNT=$($MaterialBootstrap.trusted_material_count)"
                    Write-Host "MATERIAL_EXTERNAL_FETCH_PERFORMED=$($MaterialBootstrap.external_fetch_performed)"
                    Write-Host "MATERIAL_BOOTSTRAP_NEXT_STEP=$($MaterialBootstrap.proposed_next_step)"

                    if ($MaterialBootstrap.proposed_next_step -eq "PHASE135_RUN_MANUAL_MATERIAL_SCOUT_PASS_001_V1") {
                        . ".\modules\invoke_manual_material_scout_pass_001.ps1"
                        $ManualScoutRoot = ".\self_build_batch\autonomy_trials\PHASE135_RUN_MANUAL_MATERIAL_SCOUT_PASS_001_V1"
                        $ManualScout = Invoke-ManualMaterialScoutPass001 -RepoRoot $RepoRoot -RunId $RunId -MaterialBootstrap $MaterialBootstrap -OutputRoot $ManualScoutRoot

                        Write-Host "MANUAL_MATERIAL_SCOUT_PASS=MANUAL_MATERIAL_SCOUT_PASS_001_V1"
                        Write-Host "MANUAL_MATERIAL_SCOUT_PASS_STATUS=$($ManualScout.status)"
                        Write-Host "MANUAL_MATERIAL_SCOUT_PASS_RECORDED=$($ManualScout.scout_pass_recorded)"
                        Write-Host "MATERIAL_CANDIDATE_COUNT=$($ManualScout.candidate_material_count)"
                        Write-Host "MATERIAL_REFERENCE_ONLY_COUNT=$($ManualScout.reference_only_material_count)"
                        Write-Host "MATERIAL_TRUSTED_COUNT=$($ManualScout.trusted_material_count)"
                        Write-Host "MATERIAL_RUNTIME_EXTERNAL_FETCH=$($ManualScout.external_fetch_performed_by_runtime)"
                        Write-Host "MATERIAL_RUNTIME_DEPENDENCY_INSTALL=$($ManualScout.dependency_install_performed)"
                        Write-Host "MANUAL_MATERIAL_SCOUT_PASS_NEXT_STEP=$($ManualScout.proposed_next_step)"
                        Write-Host "STATUS=PASS_STOPPED_MANUAL_MATERIAL_SCOUT_PASS_RECORDED"
                        return
                    }

                    Write-Host "STATUS=PASS_STOPPED_MATERIAL_ACQUISITION_BOOTSTRAP_BUILT"
                    return
                }

                Write-Host "STATUS=PASS_STOPPED_SELF_BUILD_OPERATION_CAPABILITY_SELECTOR_BUILT"
                return
            }

            Write-Host "STATUS=PASS_STOPPED_SELF_MODEL_FIRST_ENTRYPOINT"
            return
        }
    }
    if ($Mode -eq "SELF_BUILD" -and "$($Queue.active_task_id)" -eq "NONE") {
        . ".\modules\invoke_self_need_detection_engine.ps1"

        $NeedOutputRoot = ".\self_build_batch\autonomy_trials\PHASE111_BUILD_NEXT_ACTION_DECISION_KERNEL_V1"
        $Need = Invoke-SelfNeedDetectionEngine -RepoRoot $RepoRoot -RunId $RunId -OutputRoot $NeedOutputRoot

        Write-Host "SELF_NEED_DETECTION_ENGINE=SELF_NEED_DETECTION_ENGINE_V1"
        Write-Host "SELF_NEED_DETECTION_STATUS=$($Need.status)"
        Write-Host "SELF_NEED_DETECTION_DIAGNOSIS=$($Need.diagnosis)"
        Write-Host "SELF_NEED_DETECTION_DETECTED_NEED=$($Need.detected_need_id)"
        Write-Host "SELF_NEED_DETECTION_MISSING_CAPABILITY=$($Need.missing_capability)"
        Write-Host "SELF_NEED_DETECTION_RECOMMENDED_NEXT_STEP=$($Need.recommended_next_step)"
        Write-Host "SELF_NEED_DETECTION_REASON=$($Need.reason)"

        if ($Need.detected_need_id -ne "NEED_DECISION_TO_ACTION_ENGINE") {
            Write-Host "PROOF_AWARE_SELF_NEED_STOP=YES"
            Write-Host "PROOF_AWARE_SELF_NEED_DIAGNOSIS=$($Need.diagnosis)"
            Write-Host "PROOF_AWARE_SELF_NEED_DETECTED_NEED=$($Need.detected_need_id)"
            Write-Host "PROOF_AWARE_SELF_NEED_NEXT_STEP=$($Need.recommended_next_step)"

            if ($Need.detected_need_id -eq "NEED_SELF_MODEL_UPDATE_ENGINE") {
                . ".\modules\invoke_self_model_update_engine.ps1"
                $SelfModelOutputRoot = ".\self_build_batch\autonomy_trials\PHASE118_BUILD_SELF_MODEL_UPDATE_ENGINE_V1"
                $SelfModel = Invoke-SelfModelUpdateEngine -RepoRoot $RepoRoot -RunId $RunId -Need $Need -OutputRoot $SelfModelOutputRoot
                Write-Host "SELF_MODEL_UPDATE_ENGINE=SELF_MODEL_UPDATE_ENGINE_V1"
                Write-Host "SELF_MODEL_UPDATE_STATUS=$($SelfModel.status)"
                Write-Host "SELF_MODEL_UPDATED=$($SelfModel.self_model_updated)"
                Write-Host "SELF_MODEL_PATH=$($SelfModel.self_model_path)"
                Write-Host "SELF_MODEL_CURRENT_NEED=$($SelfModel.current_detected_need)"
                Write-Host "SELF_MODEL_NEXT_STEP=$($SelfModel.proposed_next_step)"

                . ".\modules\invoke_self_model_aware_decision_loop.ps1"
                $DecisionLoopRoot = ".\self_build_batch\autonomy_trials\PHASE119_BUILD_SELF_MODEL_AWARE_DECISION_LOOP_V1"
                $DecisionLoop = Invoke-SelfModelAwareDecisionLoop -RepoRoot $RepoRoot -RunId $RunId -OutputRoot $DecisionLoopRoot
                Write-Host "SELF_MODEL_AWARE_DECISION_LOOP=SELF_MODEL_AWARE_DECISION_LOOP_V1"
                Write-Host "SELF_MODEL_AWARE_DECISION_STATUS=$($DecisionLoop.status)"
                Write-Host "SELF_MODEL_AWARE_DECISION_ID=$($DecisionLoop.decision_id)"
                Write-Host "SELF_MODEL_AWARE_SELECTED_NEED=$($DecisionLoop.selected_need_id)"
                Write-Host "SELF_MODEL_AWARE_TARGET_CAPABILITY=$($DecisionLoop.selected_target_capability)"
                Write-Host "SELF_MODEL_AWARE_NEXT_STEP=$($DecisionLoop.proposed_next_step)"

                if ($DecisionLoop.selected_need_id -eq "NEED_AUTONOMOUS_LOOP_CONTROLLER") {
                    . ".\modules\invoke_autonomous_loop_controller.ps1"
                    $ControllerRoot = ".\self_build_batch\autonomy_trials\PHASE120_BUILD_AUTONOMOUS_LOOP_CONTROLLER_V1"
                    $Controller = Invoke-AutonomousLoopController -RepoRoot $RepoRoot -RunId $RunId -DecisionLoop $DecisionLoop -OutputRoot $ControllerRoot
                    Write-Host "AUTONOMOUS_LOOP_CONTROLLER=AUTONOMOUS_LOOP_CONTROLLER_V1"
                    Write-Host "AUTONOMOUS_LOOP_CONTROLLER_STATUS=$($Controller.status)"
                    Write-Host "AUTONOMOUS_LOOP_CONTROLLER_CREATED=$($Controller.controller_created)"
                    Write-Host "AUTONOMOUS_LOOP_CONTROLLER_PATH=$($Controller.controller_path)"
                    Write-Host "AUTONOMOUS_LOOP_CONTROLLER_NEXT_STEP=$($Controller.proposed_next_step)"

                    . ".\modules\invoke_controller_aware_self_model_update.ps1"
                    $ControllerAwareRoot = ".\self_build_batch\autonomy_trials\PHASE122_BUILD_CONTROLLER_AWARE_SELF_MODEL_UPDATE_V1"
                    $ControllerAware = Invoke-ControllerAwareSelfModelUpdate -RepoRoot $RepoRoot -RunId $RunId -Controller $Controller -OutputRoot $ControllerAwareRoot
                    Write-Host "CONTROLLER_AWARE_SELF_MODEL_UPDATE=CONTROLLER_AWARE_SELF_MODEL_UPDATE_V1"
                    Write-Host "CONTROLLER_AWARE_SELF_MODEL_STATUS=$($ControllerAware.status)"
                    Write-Host "CONTROLLER_AWARE_CLOSED_NEED=$($ControllerAware.closed_need)"
                    Write-Host "CONTROLLER_AWARE_CURRENT_NEED=$($ControllerAware.current_detected_need)"
                    Write-Host "CONTROLLER_AWARE_NEXT_STEP=$($ControllerAware.proposed_next_step)"
                    Write-Host "STATUS=PASS_STOPPED_CONTROLLER_AWARE_SELF_MODEL_UPDATED"
                    return
                }

                Write-Host "STATUS=PASS_STOPPED_SELF_MODEL_AWARE_DECISION"
                return
            }

            Write-Host "STATUS=PASS_STOPPED_PROOF_AWARE_SELF_NEED_DETECTED"
            return
        }

        . ".\modules\invoke_decision_to_action_engine.ps1"
        $ActionOutputRoot = ".\self_build_batch\autonomy_trials\PHASE112_BUILD_DECISION_TO_ACTION_ENGINE_V1"
        $Action = Invoke-DecisionToActionEngine -RepoRoot $RepoRoot -RunId $RunId -Need $Need -OutputRoot $ActionOutputRoot

        Write-Host "DECISION_TO_ACTION_ENGINE=DECISION_TO_ACTION_ENGINE_V1"
        Write-Host "DECISION_TO_ACTION_STATUS=$($Action.status)"
        Write-Host "DECISION_TO_ACTION_DECISION_ID=$($Action.decision_id)"
        Write-Host "DECISION_TO_ACTION_ACTION_KIND=$($Action.action_kind)"
        Write-Host "DECISION_TO_ACTION_ACTION_REQUEST_PATH=$($Action.action_request_path)"
        Write-Host "DECISION_TO_ACTION_PROPOSED_NEXT_STEP=$($Action.proposed_next_step)"

        . ".\modules\invoke_decision_action_admission_bridge.ps1"
        $AdmissionOutputRoot = ".\self_build_batch\autonomy_trials\PHASE113_BUILD_DECISION_ACTION_ADMISSION_BRIDGE_V1"
        $Admission = Invoke-DecisionActionAdmissionBridge -RepoRoot $RepoRoot -RunId $RunId -Action $Action -OutputRoot $AdmissionOutputRoot

        Write-Host "DECISION_ACTION_ADMISSION_BRIDGE=DECISION_ACTION_ADMISSION_BRIDGE_V1"
        Write-Host "DECISION_ACTION_ADMISSION_STATUS=$($Admission.status)"
        Write-Host "DECISION_ACTION_ADMISSION_ID=$($Admission.admission_id)"
        Write-Host "DECISION_ACTION_ADMISSION_ADMITTED_ACTION_ID=$($Admission.admitted_action_id)"
        Write-Host "DECISION_ACTION_ADMISSION_NEXT_STEP=$($Admission.proposed_next_step)"

        . ".\modules\invoke_admitted_action_execution_engine.ps1"
        $ExecutionOutputRoot = ".\self_build_batch\autonomy_trials\PHASE114_BUILD_ADMITTED_ACTION_EXECUTION_ENGINE_V1"
        $Execution = Invoke-AdmittedActionExecutionEngine -RepoRoot $RepoRoot -RunId $RunId -Admission $Admission -OutputRoot $ExecutionOutputRoot

        Write-Host "ADMITTED_ACTION_EXECUTION_ENGINE=ADMITTED_ACTION_EXECUTION_ENGINE_V1"
        Write-Host "ADMITTED_ACTION_EXECUTION_STATUS=$($Execution.status)"
        Write-Host "ADMITTED_ACTION_EXECUTION_GENERATED_PACK=$($Execution.generated_pack_id)"
        Write-Host "ADMITTED_ACTION_EXECUTION_GENERATED_TASK=$($Execution.generated_task_id)"
        Write-Host "ADMITTED_ACTION_EXECUTION_ACTIVE_TASK_ID=$($Execution.active_task_id)"
        Write-Host "ADMITTED_ACTION_EXECUTION_NEXT_STEP=$($Execution.proposed_next_step)"
        Write-Host "STATUS=PASS_STOPPED_EXECUTABLE_MOVE_CREATED"
        return
    }
    $Pack = $Registry.packs |
        Where-Object { $_.task_id -eq $Queue.active_task_id } |
        Select-Object -First 1

    if ($null -eq $Pack) {
        Write-Host "NO_REGISTERED_PACK_FOR_ACTIVE_TASK=$($Queue.active_task_id)"
        Write-Host "STATUS=PASS_STOPPED_NO_REGISTERED_PACK"
        return
    }

    Write-Host "SELECTED_PACK=$($Pack.pack_id)"
    Write-Host "SELECTED_TASK=$($Pack.task_id)"

    $Result = Invoke-SelfBuildPack `
        -RepoRoot $RepoRoot `
        -Pack $Pack `
        -RunId "$RunId`__PACK_$i"

    Write-Host "PACK_STATUS=$($Result.status)"

    if ($Result.status -ne "PASS") {
        if ($Result.error) {
            Write-Host "PACK_ERROR=$($Result.error)"
        }
        throw "Self-build pack failed."
    }

    $Executed++
}

Write-Host "PACKS_EXECUTED=$Executed"
Write-Host "STATUS=PASS_MAX_PACKS_REACHED"





















