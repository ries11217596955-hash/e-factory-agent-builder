function Read-SandboxBranchMergeJsonRequired {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "SANDBOX_BRANCH_MERGE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Resolve-SandboxBranchMergePath {
  param([string]$Path)

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Write-SandboxBranchMergeJsonFile {
  param(
    [string]$Path,
    [object]$Object,
    [int]$Depth = 80
  )

  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $json = ($Object | ConvertTo-Json -Depth $Depth) -replace "`r`n", "`n"
  if (-not $json.EndsWith("`n")) {
    $json += "`n"
  }

  [System.IO.File]::WriteAllText((Resolve-SandboxBranchMergePath -Path $Path), $json, [System.Text.UTF8Encoding]::new($false))
}

function Assert-SandboxBranchMergeFalse {
  param(
    [object]$Value,
    [string]$Name
  )

  if ($Value -ne $false) {
    throw "SANDBOX_BRANCH_MERGE_FLAG_NOT_FALSE=$Name"
  }
}

function Invoke-SandboxBranchMergeDecision001 {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$OutputRoot
  )

  Push-Location $RepoRoot

  try {
    $StepId = "PHASE138C_SANDBOX_BRANCH_MERGE_DECISION_V1"
    $RuntimeId = "PHASE138C_SANDBOX_BRANCH_MERGE_DECISION_001"
    $DecisionId = "SANDBOX_BRANCH_MERGE_DECISION_001"
    $PreviousStepId = "PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_V1"
    $NextAllowedStep = "PHASE138D_OWNER_APPROVED_SANDBOX_BRANCH_MERGE_V1"
    $SourceBranch = "phase138a-autonomous-material-decision-stress-lab"
    $TargetBranch = "phase110-idempotent-autonomy-trial-runtime"
    $SourceHead = "c2f8b56"
    $TargetBaseHead = "6a958ed"
    $SelectedMaterialId = "candidate_pester_powershell_test_framework"

    if ([string]::IsNullOrWhiteSpace($RunId)) {
      $RunId = $RuntimeId
    }

    $OutputArtifactRoot = "self_build_batch/autonomy_trials/$StepId"
    if (-not (Test-Path -LiteralPath $OutputArtifactRoot)) {
      New-Item -ItemType Directory -Force -Path $OutputArtifactRoot | Out-Null
    }

    $PreviousProofPath = "proofs/self_development/${PreviousStepId}.json"
    $ReviewPath = "materials/AUTONOMOUS_MATERIAL_DECISION_REVIEW.json"
    $DecisionPath = "self_control/SANDBOX_BRANCH_MERGE_DECISION.json"
    $ReadinessPath = "self_control/SANDBOX_BRANCH_MERGE_READINESS_REPORT.json"
    $OutputPath = "$OutputArtifactRoot/SANDBOX_BRANCH_MERGE_DECISION_OUTPUT.json"
    $ResultPath = "$OutputArtifactRoot/${StepId}_RESULT.json"
    $RuntimeLogPath = "$OutputArtifactRoot/${StepId}_RUNTIME_LOG.txt"
    $ReportPath = "reports/self_development/${StepId}_REPORT.json"
    $ProofPath = "proofs/self_development/${StepId}.json"

    $CurrentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
    $CurrentHead = (git rev-parse --short HEAD).Trim()
    if ($CurrentBranch -ne $SourceBranch) {
      throw "SANDBOX_BRANCH_MERGE_SOURCE_BRANCH_UNEXPECTED=$CurrentBranch"
    }
    if ($CurrentHead -ne $SourceHead) {
      throw "SANDBOX_BRANCH_MERGE_SOURCE_HEAD_UNEXPECTED=$CurrentHead"
    }

    $PreviousProof = Read-SandboxBranchMergeJsonRequired -Path $PreviousProofPath
    if ($PreviousProof.status -ne "PASS") {
      throw "PHASE138B_PROOF_NOT_PASS"
    }
    if ($PreviousProof.next_allowed_step -ne $StepId) {
      throw "PHASE138B_NEXT_ALLOWED_STEP_UNEXPECTED=$($PreviousProof.next_allowed_step)"
    }
    if ($PreviousProof.selected_material_id -ne $SelectedMaterialId) {
      throw "PHASE138B_SELECTED_MATERIAL_UNEXPECTED=$($PreviousProof.selected_material_id)"
    }
    if ($PreviousProof.policy_violation_count -ne 30) {
      throw "PHASE138B_POLICY_VIOLATION_COUNT_UNEXPECTED=$($PreviousProof.policy_violation_count)"
    }
    if ($PreviousProof.violation_sum -ne 30) {
      throw "PHASE138B_VIOLATION_SUM_UNEXPECTED=$($PreviousProof.violation_sum)"
    }
    if ($PreviousProof.trusted_material_count -ne 0) {
      throw "PHASE138B_TRUSTED_COUNT_NOT_ZERO=$($PreviousProof.trusted_material_count)"
    }
    Assert-SandboxBranchMergeFalse -Value $PreviousProof.production_adoption_allowed -Name "phase138b_production_adoption_allowed"
    Assert-SandboxBranchMergeFalse -Value $PreviousProof.external_fetch_performed -Name "phase138b_external_fetch_performed"
    Assert-SandboxBranchMergeFalse -Value $PreviousProof.dependency_install_performed -Name "phase138b_dependency_install_performed"
    Assert-SandboxBranchMergeFalse -Value $PreviousProof.executable_materials_used -Name "phase138b_executable_materials_used"

    $Review = Read-SandboxBranchMergeJsonRequired -Path $ReviewPath
    if ($Review.status -ne "PASS") {
      throw "AUTONOMOUS_MATERIAL_DECISION_REVIEW_NOT_PASS"
    }
    if ($Review.selected_material_id -ne $SelectedMaterialId) {
      throw "REVIEW_SELECTED_MATERIAL_UNEXPECTED=$($Review.selected_material_id)"
    }
    if ($Review.stress_dataset_record_count -ne 300) {
      throw "REVIEW_STRESS_DATASET_COUNT_UNEXPECTED=$($Review.stress_dataset_record_count)"
    }
    if ($Review.policy_violation_count -ne 30) {
      throw "REVIEW_POLICY_VIOLATION_COUNT_UNEXPECTED=$($Review.policy_violation_count)"
    }
    if ($Review.violation_sum -ne 30) {
      throw "REVIEW_VIOLATION_SUM_UNEXPECTED=$($Review.violation_sum)"
    }
    if ($Review.trusted_material_count -ne 0) {
      throw "REVIEW_TRUSTED_COUNT_NOT_ZERO=$($Review.trusted_material_count)"
    }
    Assert-SandboxBranchMergeFalse -Value $Review.production_adoption_allowed -Name "review_production_adoption_allowed"
    Assert-SandboxBranchMergeFalse -Value $Review.trusted -Name "review_trusted"
    Assert-SandboxBranchMergeFalse -Value $Review.external_fetch_performed -Name "review_external_fetch_performed"
    Assert-SandboxBranchMergeFalse -Value $Review.dependency_install_performed -Name "review_dependency_install_performed"
    Assert-SandboxBranchMergeFalse -Value $Review.executable_materials_used -Name "review_executable_materials_used"
    Assert-SandboxBranchMergeFalse -Value $Review.wrapper_created -Name "review_wrapper_created"
    Assert-SandboxBranchMergeFalse -Value $Review.smoke_test_executed -Name "review_smoke_test_executed"

    $RiskNotes = @(
      "Sandbox stress branch contains synthetic dataset and review artifacts only; it does not authorize production material adoption.",
      "Owner approval is required before any branch merge.",
      "Selected material remains untrusted and requires later owner, license, provenance, wrapper, quarantine, and smoke-test decisions before any use."
    )

    $Decision = [ordered]@{
      status = "PASS"
      decision_id = $DecisionId
      created_by = $StepId
      run_id = $RunId
      source_branch = $SourceBranch
      target_branch = $TargetBranch
      source_head = $SourceHead
      target_base_head = $TargetBaseHead
      merge_recommendation = "MERGE_AFTER_OWNER_APPROVAL"
      merge_allowed_now = $false
      owner_approval_required = $true
      recommended_merge_mode = "REVIEWED_PR_OR_MANUAL_MERGE"
      include_stress_dataset = $true
      include_runtime_modules = $true
      include_proofs_and_reports = $true
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      wrapper_created = $false
      smoke_test_executed = $false
      risk_notes = $RiskNotes
      next_allowed_step = $NextAllowedStep
    }

    $ReadinessReport = [ordered]@{
      status = "PASS"
      report_id = "SANDBOX_BRANCH_MERGE_READINESS_REPORT"
      created_by = $StepId
      run_id = $RunId
      previous_phases_accepted = @(
        "PHASE138A_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_V1",
        "PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_V1"
      )
      source_branch = $SourceBranch
      target_branch = $TargetBranch
      source_head = $SourceHead
      target_base_head = $TargetBaseHead
      stress_dataset_record_count = 300
      selected_material_id = $SelectedMaterialId
      policy_violation_count = 30
      merge_blockers_count = 1
      merge_blockers = @("OWNER_APPROVAL_REQUIRED_BEFORE_MERGE")
      no_runtime_forbidden_actions = $true
      no_production_trust = $true
      no_dependency_install = $true
      no_external_fetch = $true
      no_executable_use = $true
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      wrapper_created = $false
      smoke_test_executed = $false
      next_allowed_step = $NextAllowedStep
    }

    Write-SandboxBranchMergeJsonFile -Path $DecisionPath -Object $Decision
    Write-SandboxBranchMergeJsonFile -Path $ReadinessPath -Object $ReadinessReport

    $Queue = Read-SandboxBranchMergeJsonRequired -Path "TASK_QUEUE.json"
    if ($Queue.active_task_id -ne "NONE") {
      throw "SANDBOX_BRANCH_MERGE_QUEUE_NOT_NONE=$($Queue.active_task_id)"
    }

    $Output = [ordered]@{
      status = "PASS"
      engine_name = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      source_branch = $SourceBranch
      target_branch = $TargetBranch
      merge_recommendation = "MERGE_AFTER_OWNER_APPROVAL"
      merge_allowed_now = $false
      owner_approval_required = $true
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      wrapper_created = $false
      smoke_test_executed = $false
      queue_after = "NONE"
      decision_path = $DecisionPath
      readiness_report_path = $ReadinessPath
      output_path = $OutputPath
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      runtime_log_path = $RuntimeLogPath
      proposed_next_step = $NextAllowedStep
      next_allowed_step = $NextAllowedStep
    }

    $Result = [ordered]@{
      status = "PASS"
      phase = $StepId
      active_line = "AGENT_BUILDER_SELF_DEVELOPMENT"
      run_id = $RunId
      runtime_id = $RuntimeId
      runtime_executed = $true
      builder_runtime_invoked = $true
      source_branch = $SourceBranch
      target_branch = $TargetBranch
      source_head = $SourceHead
      target_base_head = $TargetBaseHead
      merge_recommendation = "MERGE_AFTER_OWNER_APPROVAL"
      merge_allowed_now = $false
      owner_approval_required = $true
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      wrapper_created = $false
      smoke_test_executed = $false
      queue_after = "NONE"
      output_path = $OutputPath
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    $Report = [ordered]@{
      status = "PASS"
      report_id = "${StepId}_REPORT"
      phase = $StepId
      run_id = $RunId
      summary = "Sandbox branch merge decision gate recommends merge only after owner approval. No branch merge, branch switch, external fetch, dependency install, executable use, wrapper, smoke test, or material trust was performed."
      source_branch = $SourceBranch
      target_branch = $TargetBranch
      merge_decision_method = "Read PHASE138B proof and autonomous material review; verify sandbox-only constraints and forbidden-action flags; emit merge decision and readiness report with owner approval as the only current blocker."
      what_can_be_merged = @(
        "Synthetic stress dataset and sandbox decision artifacts.",
        "PHASE138A, PHASE138B, and PHASE138C runtime modules, validators, reports, and proofs.",
        "Sandbox-only autonomous material decision review evidence."
      )
      what_must_not_be_merged_yet = @(
        "Any production trusted material registry entry.",
        "Any dependency installation or package manager configuration.",
        "Any external agent change or GitHub workflow change.",
        "Any claim that selected material is trusted or production-adopted."
      )
      cut_list = @(
        "Do not merge branches in PHASE138C.",
        "Do not switch branches inside runtime.",
        "Do not install external materials.",
        "Do not fetch external repositories or packages.",
        "Do not execute material code.",
        "Do not create wrappers.",
        "Do not smoke test materials.",
        "Do not mark any material trusted."
      )
      next_allowed_step = $NextAllowedStep
    }

    $Proof = [ordered]@{
      status = "PASS"
      proof_id = $StepId
      phase = $StepId
      run_id = $RunId
      runtime_mode = "SELF_BUILD_QUEUE_NONE_SANDBOX_BRANCH_MERGE_DECISION_001"
      runtime_executed = $true
      builder_runtime_invoked = $true
      source_branch = $SourceBranch
      target_branch = $TargetBranch
      source_head = $SourceHead
      target_base_head = $TargetBaseHead
      merge_recommendation = "MERGE_AFTER_OWNER_APPROVAL"
      merge_allowed_now = $false
      owner_approval_required = $true
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      wrapper_created = $false
      smoke_test_executed = $false
      queue_after = "NONE"
      codex_used = $false
      main_touched = $false
      decision_path = $DecisionPath
      readiness_report_path = $ReadinessPath
      result_path = $ResultPath
      report_path = $ReportPath
      output_path = $OutputPath
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    Write-SandboxBranchMergeJsonFile -Path $OutputPath -Object $Output
    Write-SandboxBranchMergeJsonFile -Path $ResultPath -Object $Result
    Write-SandboxBranchMergeJsonFile -Path $ReportPath -Object $Report
    Write-SandboxBranchMergeJsonFile -Path $ProofPath -Object $Proof

    return [pscustomobject]$Output
  } finally {
    Pop-Location
  }
}
