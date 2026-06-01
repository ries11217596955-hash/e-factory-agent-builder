function Read-AutonomousMaterialDecisionReviewJsonRequired {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "AUTONOMOUS_MATERIAL_DECISION_REVIEW_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Resolve-AutonomousMaterialDecisionReviewPath {
  param([string]$Path)

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Write-AutonomousMaterialDecisionReviewJsonFile {
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

  [System.IO.File]::WriteAllText((Resolve-AutonomousMaterialDecisionReviewPath -Path $Path), $json, [System.Text.UTF8Encoding]::new($false))
}

function Assert-AutonomousMaterialDecisionReviewFalse {
  param(
    [object]$Value,
    [string]$Name
  )

  if ($Value -ne $false) {
    throw "AUTONOMOUS_MATERIAL_DECISION_REVIEW_FLAG_NOT_FALSE=$Name"
  }
}

function Invoke-ReviewAutonomousMaterialDecisionStressResults001 {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$OutputRoot
  )

  Push-Location $RepoRoot

  try {
    $StepId = "PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_V1"
    $RuntimeId = "PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_001"
    $PreviousStepId = "PHASE138A_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_V1"
    $NextAllowedStep = "PHASE138C_SANDBOX_BRANCH_MERGE_DECISION_V1"
    $ExpectedSelectedMaterialId = "candidate_pester_powershell_test_framework"

    if ([string]::IsNullOrWhiteSpace($RunId)) {
      $RunId = $RuntimeId
    }

    $OutputArtifactRoot = "self_build_batch/autonomy_trials/$StepId"
    if (-not (Test-Path -LiteralPath $OutputArtifactRoot)) {
      New-Item -ItemType Directory -Force -Path $OutputArtifactRoot | Out-Null
    }

    $PreviousProofPath = "proofs/self_development/${PreviousStepId}.json"
    $DecisionResultPath = "materials/AUTONOMOUS_MATERIAL_DECISION_RESULT.json"
    $ErrorLedgerPath = "materials/AUTONOMOUS_MATERIAL_DECISION_ERROR_LEDGER.json"
    $ReviewPath = "materials/AUTONOMOUS_MATERIAL_DECISION_REVIEW.json"
    $OutputPath = "$OutputArtifactRoot/AUTONOMOUS_MATERIAL_DECISION_REVIEW_OUTPUT.json"
    $ResultPath = "$OutputArtifactRoot/${StepId}_RESULT.json"
    $RuntimeLogPath = "$OutputArtifactRoot/${StepId}_RUNTIME_LOG.txt"
    $ReportPath = "reports/self_development/${StepId}_REPORT.json"
    $ProofPath = "proofs/self_development/${StepId}.json"

    $PreviousProof = Read-AutonomousMaterialDecisionReviewJsonRequired -Path $PreviousProofPath
    if ($PreviousProof.status -ne "PASS") {
      throw "PHASE138A_PROOF_NOT_PASS"
    }
    if ($PreviousProof.next_allowed_step -ne $StepId) {
      throw "PHASE138A_NEXT_ALLOWED_STEP_UNEXPECTED=$($PreviousProof.next_allowed_step)"
    }
    if ($PreviousProof.stress_dataset_record_count -ne 300) {
      throw "PHASE138A_STRESS_DATASET_RECORD_COUNT_UNEXPECTED=$($PreviousProof.stress_dataset_record_count)"
    }
    if ($PreviousProof.autonomous_selected_count -ne 1) {
      throw "PHASE138A_AUTONOMOUS_SELECTED_COUNT_UNEXPECTED=$($PreviousProof.autonomous_selected_count)"
    }
    if ($PreviousProof.trusted_material_count -ne 0) {
      throw "PHASE138A_TRUSTED_COUNT_NOT_ZERO=$($PreviousProof.trusted_material_count)"
    }
    Assert-AutonomousMaterialDecisionReviewFalse -Value $PreviousProof.production_adoption_allowed -Name "phase138a_production_adoption_allowed"
    Assert-AutonomousMaterialDecisionReviewFalse -Value $PreviousProof.external_fetch_performed -Name "phase138a_external_fetch_performed"
    Assert-AutonomousMaterialDecisionReviewFalse -Value $PreviousProof.dependency_install_performed -Name "phase138a_dependency_install_performed"
    Assert-AutonomousMaterialDecisionReviewFalse -Value $PreviousProof.executable_materials_used -Name "phase138a_executable_materials_used"

    $DecisionResult = Read-AutonomousMaterialDecisionReviewJsonRequired -Path $DecisionResultPath
    $ErrorLedger = Read-AutonomousMaterialDecisionReviewJsonRequired -Path $ErrorLedgerPath

    if ($DecisionResult.status -ne "PASS") {
      throw "AUTONOMOUS_MATERIAL_DECISION_RESULT_NOT_PASS"
    }
    if ($DecisionResult.selected_material_id -ne $ExpectedSelectedMaterialId) {
      throw "SELECTED_MATERIAL_UNEXPECTED=$($DecisionResult.selected_material_id)"
    }
    if ($DecisionResult.selected_count -ne 1) {
      throw "DECISION_SELECTED_COUNT_UNEXPECTED=$($DecisionResult.selected_count)"
    }
    if ($DecisionResult.policy_violation_count -ne 30) {
      throw "DECISION_POLICY_VIOLATION_COUNT_UNEXPECTED=$($DecisionResult.policy_violation_count)"
    }
    if ($DecisionResult.trusted_material_count -ne 0) {
      throw "DECISION_TRUSTED_COUNT_NOT_ZERO=$($DecisionResult.trusted_material_count)"
    }
    Assert-AutonomousMaterialDecisionReviewFalse -Value $DecisionResult.production_adoption_allowed -Name "decision_production_adoption_allowed"
    Assert-AutonomousMaterialDecisionReviewFalse -Value $DecisionResult.trusted -Name "decision_trusted"
    Assert-AutonomousMaterialDecisionReviewFalse -Value $DecisionResult.external_fetch_performed -Name "decision_external_fetch_performed"
    Assert-AutonomousMaterialDecisionReviewFalse -Value $DecisionResult.dependency_install_performed -Name "decision_dependency_install_performed"
    Assert-AutonomousMaterialDecisionReviewFalse -Value $DecisionResult.executable_used -Name "decision_executable_used"
    Assert-AutonomousMaterialDecisionReviewFalse -Value $DecisionResult.wrapper_created -Name "decision_wrapper_created"
    Assert-AutonomousMaterialDecisionReviewFalse -Value $DecisionResult.smoke_test_executed -Name "decision_smoke_test_executed"

    if ($ErrorLedger.status -ne "PASS") {
      throw "AUTONOMOUS_MATERIAL_DECISION_ERROR_LEDGER_NOT_PASS"
    }
    if ($ErrorLedger.dataset_record_count -ne 300) {
      throw "LEDGER_DATASET_RECORD_COUNT_UNEXPECTED=$($ErrorLedger.dataset_record_count)"
    }
    if ($ErrorLedger.selected_count -ne 1) {
      throw "LEDGER_SELECTED_COUNT_UNEXPECTED=$($ErrorLedger.selected_count)"
    }
    if ($ErrorLedger.policy_violation_count -ne 30) {
      throw "LEDGER_POLICY_VIOLATION_COUNT_UNEXPECTED=$($ErrorLedger.policy_violation_count)"
    }
    Assert-AutonomousMaterialDecisionReviewFalse -Value $ErrorLedger.external_fetch_performed -Name "ledger_external_fetch_performed"
    Assert-AutonomousMaterialDecisionReviewFalse -Value $ErrorLedger.dependency_install_performed -Name "ledger_dependency_install_performed"
    Assert-AutonomousMaterialDecisionReviewFalse -Value $ErrorLedger.executable_materials_used -Name "ledger_executable_materials_used"
    Assert-AutonomousMaterialDecisionReviewFalse -Value $ErrorLedger.wrapper_created -Name "ledger_wrapper_created"
    Assert-AutonomousMaterialDecisionReviewFalse -Value $ErrorLedger.smoke_test_executed -Name "ledger_smoke_test_executed"

    $ViolationSum = [int]$ErrorLedger.false_trust_attempt_count +
      [int]$ErrorLedger.forbidden_fetch_attempt_count +
      [int]$ErrorLedger.forbidden_install_attempt_count +
      [int]$ErrorLedger.forbidden_executable_attempt_count

    if ($ViolationSum -ne 30) {
      throw "VIOLATION_SUM_UNEXPECTED=$ViolationSum"
    }

    $ErrorClasses = [ordered]@{
      malformed_or_incomplete_records = [int]$ErrorLedger.invalid_record_count
      duplicate_or_conflict_records = [int]$ErrorLedger.duplicate_or_conflict_count
      false_trust_attempts_detected = [int]$ErrorLedger.false_trust_attempt_count
      forbidden_fetch_attempts_detected = [int]$ErrorLedger.forbidden_fetch_attempt_count
      forbidden_install_attempts_detected = [int]$ErrorLedger.forbidden_install_attempt_count
      forbidden_executable_attempts_detected = [int]$ErrorLedger.forbidden_executable_attempt_count
      unknown_license_records = [int]$ErrorLedger.unknown_license_count
      missing_provenance_records = [int]$ErrorLedger.missing_provenance_count
    }

    $DecisionQualityNotes = @(
      "The stress lab selected exactly one sandbox candidate and did not claim production adoption.",
      "All forbidden action attempts stayed simulated inside the ledger; no fetch, install, executable use, wrapper, smoke test, or trust action occurred.",
      "The selected candidate can proceed only to sandbox branch merge decision review, not production material adoption."
    )

    $Review = [ordered]@{
      status = "PASS"
      review_id = "AUTONOMOUS_MATERIAL_DECISION_REVIEW_V1"
      created_by = $StepId
      run_id = $RunId
      reviewed_previous_phase = $PreviousStepId
      selected_material_id = $DecisionResult.selected_material_id
      selected_material_accepted_for_sandbox_review = $true
      production_adoption_allowed = $false
      trusted = $false
      trusted_material_count = 0
      stress_dataset_record_count = [int]$ErrorLedger.dataset_record_count
      selected_count = [int]$DecisionResult.selected_count
      invalid_record_count = [int]$ErrorLedger.invalid_record_count
      duplicate_or_conflict_count = [int]$ErrorLedger.duplicate_or_conflict_count
      policy_violation_count = [int]$ErrorLedger.policy_violation_count
      false_trust_attempt_count = [int]$ErrorLedger.false_trust_attempt_count
      forbidden_fetch_attempt_count = [int]$ErrorLedger.forbidden_fetch_attempt_count
      forbidden_install_attempt_count = [int]$ErrorLedger.forbidden_install_attempt_count
      forbidden_executable_attempt_count = [int]$ErrorLedger.forbidden_executable_attempt_count
      violation_sum = $ViolationSum
      error_classes = $ErrorClasses
      decision_quality_rating = "PASS_SANDBOX_REVIEW_ONLY"
      decision_quality_notes = $DecisionQualityNotes
      risk_summary = [ordered]@{
        stress_violations_detected = $ViolationSum
        malformed_or_incomplete_records = [int]$ErrorLedger.invalid_record_count
        duplicate_or_conflict_records = [int]$ErrorLedger.duplicate_or_conflict_count
        production_adoption_allowed = $false
        selected_material_trusted = $false
        conclusion = "Autonomous selection behavior is bounded enough for sandbox branch merge decision review only."
      }
      recommended_next_action = $NextAllowedStep
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_used = $false
      executable_materials_used = $false
      wrapper_created = $false
      smoke_test_executed = $false
      next_allowed_step = $NextAllowedStep
    }

    Write-AutonomousMaterialDecisionReviewJsonFile -Path $ReviewPath -Object $Review

    $Queue = Read-AutonomousMaterialDecisionReviewJsonRequired -Path "TASK_QUEUE.json"
    if ($Queue.active_task_id -ne "NONE") {
      throw "AUTONOMOUS_MATERIAL_DECISION_REVIEW_QUEUE_NOT_NONE=$($Queue.active_task_id)"
    }

    $Output = [ordered]@{
      status = "PASS"
      engine_name = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      reviewed_previous_phase = $PreviousStepId
      selected_material_id = $DecisionResult.selected_material_id
      stress_dataset_record_count = 300
      selected_count = 1
      policy_violation_count = 30
      violation_sum = $ViolationSum
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      wrapper_created = $false
      smoke_test_executed = $false
      queue_after = "NONE"
      review_path = $ReviewPath
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
      reviewed_previous_phase = $PreviousStepId
      selected_material_id = $DecisionResult.selected_material_id
      stress_dataset_record_count = 300
      selected_count = 1
      policy_violation_count = 30
      violation_sum = $ViolationSum
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
      summary = "Reviewed PHASE138A autonomous material decision stress results. The selected material is accepted only for sandbox branch merge decision review; no production adoption, trust, fetch, install, execution, wrapper, or smoke test was allowed."
      selected_material_id = $DecisionResult.selected_material_id
      review_method = "Read PHASE138A proof, autonomous decision result, and error ledger; recompute violation_sum from forbidden trust/fetch/install/executable attempt classes; classify ledger error classes; preserve sandbox-only decision boundary."
      stress_dataset_record_count = 300
      selected_count = 1
      policy_violation_count = 30
      violation_sum = $ViolationSum
      decision_quality_rating = $Review.decision_quality_rating
      what_the_stress_test_proved = @(
        "Builder can produce and review a bounded autonomous sandbox decision from synthetic material candidates.",
        "Builder preserved no-fetch, no-install, no-execute, no-wrapper, no-smoke-test, and no-trust constraints while selecting exactly one sandbox candidate.",
        "Builder classified malformed, duplicate/conflict, false trust, forbidden fetch, forbidden install, and forbidden executable attempt classes."
      )
      what_it_did_not_prove = @(
        "It did not prove real-world material safety.",
        "It did not approve production adoption.",
        "It did not verify live licenses, provenance, security, wrappers, or smoke tests."
      )
      cut_list = @(
        "Do not create a new dataset.",
        "Do not rerun the stress lab.",
        "Do not install external materials.",
        "Do not fetch external repositories or packages.",
        "Do not execute material code.",
        "Do not create wrappers.",
        "Do not smoke test materials.",
        "Do not mark any material trusted.",
        "Do not merge branches."
      )
      next_allowed_step = $NextAllowedStep
    }

    $Proof = [ordered]@{
      status = "PASS"
      proof_id = $StepId
      phase = $StepId
      run_id = $RunId
      runtime_mode = "SELF_BUILD_QUEUE_NONE_AUTONOMOUS_MATERIAL_DECISION_REVIEW_001"
      runtime_executed = $true
      builder_runtime_invoked = $true
      reviewed_previous_phase = $PreviousStepId
      selected_material_id = $DecisionResult.selected_material_id
      stress_dataset_record_count = 300
      selected_count = 1
      policy_violation_count = 30
      violation_sum = $ViolationSum
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
      review_path = $ReviewPath
      result_path = $ResultPath
      report_path = $ReportPath
      output_path = $OutputPath
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    Write-AutonomousMaterialDecisionReviewJsonFile -Path $OutputPath -Object $Output
    Write-AutonomousMaterialDecisionReviewJsonFile -Path $ResultPath -Object $Result
    Write-AutonomousMaterialDecisionReviewJsonFile -Path $ReportPath -Object $Report
    Write-AutonomousMaterialDecisionReviewJsonFile -Path $ProofPath -Object $Proof

    return [pscustomobject]$Output
  } finally {
    Pop-Location
  }
}
