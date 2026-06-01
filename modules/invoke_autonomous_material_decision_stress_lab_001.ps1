function Read-AutonomousMaterialDecisionJsonRequired {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "AUTONOMOUS_MATERIAL_DECISION_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Resolve-AutonomousMaterialDecisionPath {
  param([string]$Path)

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Write-AutonomousMaterialDecisionJsonFile {
  param(
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $json = ($Object | ConvertTo-Json -Depth $Depth) -replace "`r`n", "`n"
  if (-not $json.EndsWith("`n")) {
    $json += "`n"
  }

  [System.IO.File]::WriteAllText((Resolve-AutonomousMaterialDecisionPath -Path $Path), $json, [System.Text.UTF8Encoding]::new($false))
}

function Assert-AutonomousMaterialDecisionFalse {
  param(
    [object]$Value,
    [string]$Name
  )

  if ($Value -ne $false) {
    throw "AUTONOMOUS_MATERIAL_DECISION_FLAG_NOT_FALSE=$Name"
  }
}

function New-StressMaterialRecord {
  param(
    [int]$Index,
    [string]$MaterialId,
    [string]$Name,
    [string]$MaterialType,
    [string]$RiskLevel,
    [string]$LicenseStatus,
    [string]$ProvenanceStatus,
    [int]$DecisionScore,
    [bool]$KnownPhase137Candidate = $false,
    [bool]$MalformedOrIncomplete = $false,
    [bool]$DuplicateOrConflict = $false,
    [bool]$PolicyViolation = $false,
    [bool]$FalseTrustAttempt = $false,
    [bool]$ForbiddenFetchAttempt = $false,
    [bool]$ForbiddenInstallAttempt = $false,
    [bool]$ForbiddenExecutableAttempt = $false,
    [string]$ConflictGroupId = ""
  )

  $unknownLicense = ($LicenseStatus -eq "UNKNOWN")
  $missingProvenance = ($ProvenanceStatus -eq "MISSING")

  return [ordered]@{
    record_id = ("stress_record_{0:D3}" -f $Index)
    material_id = $MaterialId
    name = $Name
    material_type = $MaterialType
    source = "synthetic://phase138a/$MaterialId"
    source_kind = "SYNTHETIC_STRESS_RECORD"
    risk_level = $RiskLevel
    license_status = $LicenseStatus
    provenance_status = $ProvenanceStatus
    intended_use = "Synthetic material governance stress-lab candidate; not an external runtime dependency."
    owner_decision_required = $true
    known_phase137_candidate = $KnownPhase137Candidate
    malformed_or_incomplete = $MalformedOrIncomplete
    duplicate_or_conflict = $DuplicateOrConflict
    conflict_group_id = $ConflictGroupId
    policy_violation = $PolicyViolation
    simulated_false_trust_attempt = $FalseTrustAttempt
    simulated_forbidden_fetch_attempt = $ForbiddenFetchAttempt
    simulated_forbidden_install_attempt = $ForbiddenInstallAttempt
    simulated_forbidden_executable_attempt = $ForbiddenExecutableAttempt
    unknown_license = $unknownLicense
    missing_provenance = $missingProvenance
    eligible_for_sandbox_decision = (-not $MalformedOrIncomplete -and -not $DuplicateOrConflict -and -not $PolicyViolation -and -not $unknownLicense -and -not $missingProvenance)
    decision_score = $DecisionScore
    synthetic = $true
  }
}

function New-AutonomousMaterialDecisionStressDataset {
  $records = @()

  $records += New-StressMaterialRecord -Index 1 -MaterialId "candidate_pester_powershell_test_framework" -Name "Pester" -MaterialType "LIBRARY" -RiskLevel "LOW" -LicenseStatus "APACHE_2_0_REVIEW_REQUIRED" -ProvenanceStatus "DECLARED_SOURCE_REVIEW_REQUIRED" -DecisionScore 100 -KnownPhase137Candidate $true
  $records += New-StressMaterialRecord -Index 2 -MaterialId "candidate_psscriptanalyzer_static_checker" -Name "PSScriptAnalyzer" -MaterialType "LIBRARY" -RiskLevel "MEDIUM" -LicenseStatus "MIT_REVIEW_REQUIRED" -ProvenanceStatus "DECLARED_SOURCE_REVIEW_REQUIRED" -DecisionScore 86 -KnownPhase137Candidate $true
  $records += New-StressMaterialRecord -Index 3 -MaterialId "candidate_syft_sbom_cli" -Name "Syft" -MaterialType "CLI_TOOL" -RiskLevel "HIGH" -LicenseStatus "APACHE_2_0_REVIEW_REQUIRED" -ProvenanceStatus "DECLARED_SOURCE_REVIEW_REQUIRED" -DecisionScore 72 -KnownPhase137Candidate $true

  for ($index = 4; $index -le 300; $index++) {
    $riskCycle = ($index - 4) % 3
    $riskLevel = @("LOW", "MEDIUM", "HIGH")[$riskCycle]
    $materialType = $(if ($index % 5 -eq 0) { "CLI_TOOL" } elseif ($index % 5 -eq 1) { "SCHEMA" } else { "LIBRARY" })
    $licenseStatus = $(if ($index % 13 -eq 0) { "UNKNOWN" } elseif ($index % 3 -eq 0) { "MIT_REVIEW_REQUIRED" } elseif ($index % 3 -eq 1) { "APACHE_2_0_REVIEW_REQUIRED" } else { "BSD_REVIEW_REQUIRED" })
    $provenanceStatus = $(if ($index % 17 -eq 0) { "MISSING" } else { "SYNTHETIC_DECLARED" })
    $malformed = ($index -ge 4 -and $index -le 23)
    $duplicate = ($index -ge 24 -and $index -le 43)
    $falseTrustAttempt = ($index -ge 44 -and $index -le 53)
    $fetchAttempt = ($index -ge 54 -and $index -le 63)
    $installAttempt = ($index -ge 64 -and $index -le 68)
    $executableAttempt = ($index -ge 69 -and $index -le 73)
    $policyViolation = ($falseTrustAttempt -or $fetchAttempt -or $installAttempt -or $executableAttempt)
    $decisionScore = 20 + (69 - ($index % 70))

    if ($malformed) {
      $licenseStatus = "UNKNOWN"
      $provenanceStatus = "MISSING"
      $decisionScore = 5
    }

    $records += New-StressMaterialRecord `
      -Index $index `
      -MaterialId ("synthetic_material_candidate_{0:D3}" -f $index) `
      -Name ("Synthetic Material Candidate {0:D3}" -f $index) `
      -MaterialType $materialType `
      -RiskLevel $riskLevel `
      -LicenseStatus $licenseStatus `
      -ProvenanceStatus $provenanceStatus `
      -DecisionScore $decisionScore `
      -MalformedOrIncomplete $malformed `
      -DuplicateOrConflict $duplicate `
      -PolicyViolation $policyViolation `
      -FalseTrustAttempt $falseTrustAttempt `
      -ForbiddenFetchAttempt $fetchAttempt `
      -ForbiddenInstallAttempt $installAttempt `
      -ForbiddenExecutableAttempt $executableAttempt `
      -ConflictGroupId $(if ($duplicate) { "duplicate_conflict_group_$([math]::Floor(($index - 24) / 2))" } else { "" })
  }

  return $records
}

function Invoke-AutonomousMaterialDecisionStressLab001 {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$OutputRoot
  )

  Push-Location $RepoRoot

  try {
    $StepId = "PHASE138A_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_V1"
    $RuntimeId = "PHASE138A_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_001"
    $PreviousStepId = "PHASE137_BUILD_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_V1"
    $ExpectedPreviousNextStep = "PHASE138_OWNER_DECISION_FOR_FIRST_MATERIAL_ADOPTION_V1"
    $NextAllowedStep = "PHASE138B_REVIEW_AUTONOMOUS_MATERIAL_DECISION_STRESS_RESULTS_V1"

    if ([string]::IsNullOrWhiteSpace($RunId)) {
      $RunId = $RuntimeId
    }

    $OutputArtifactRoot = "self_build_batch/autonomy_trials/$StepId"
    if (-not (Test-Path -LiteralPath $OutputArtifactRoot)) {
      New-Item -ItemType Directory -Force -Path $OutputArtifactRoot | Out-Null
    }

    $PreviousProofPath = "proofs/self_development/${PreviousStepId}.json"
    $DatasetPath = "materials/MATERIAL_DECISION_STRESS_DATASET_300.json"
    $DecisionResultPath = "materials/AUTONOMOUS_MATERIAL_DECISION_RESULT.json"
    $ErrorLedgerPath = "materials/AUTONOMOUS_MATERIAL_DECISION_ERROR_LEDGER.json"
    $OutputPath = "$OutputArtifactRoot/AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_OUTPUT.json"
    $ResultPath = "$OutputArtifactRoot/${StepId}_RESULT.json"
    $RuntimeLogPath = "$OutputArtifactRoot/${StepId}_RUNTIME_LOG.txt"
    $ReportPath = "reports/self_development/${StepId}_REPORT.json"
    $ProofPath = "proofs/self_development/${StepId}.json"

    $PreviousProof = Read-AutonomousMaterialDecisionJsonRequired -Path $PreviousProofPath
    if ($PreviousProof.status -ne "PASS") {
      throw "PHASE137_PROOF_NOT_PASS"
    }
    if ($PreviousProof.next_allowed_step -ne $ExpectedPreviousNextStep) {
      throw "PHASE137_NEXT_ALLOWED_STEP_UNEXPECTED=$($PreviousProof.next_allowed_step)"
    }
    if ($PreviousProof.evaluated_material_count -ne 3) {
      throw "PHASE137_EVALUATED_MATERIAL_COUNT_UNEXPECTED=$($PreviousProof.evaluated_material_count)"
    }
    if ($PreviousProof.trusted_material_count -ne 0) {
      throw "PHASE137_TRUSTED_COUNT_NOT_ZERO=$($PreviousProof.trusted_material_count)"
    }
    Assert-AutonomousMaterialDecisionFalse -Value $PreviousProof.external_fetch_performed -Name "phase137_external_fetch_performed"
    Assert-AutonomousMaterialDecisionFalse -Value $PreviousProof.dependency_install_performed -Name "phase137_dependency_install_performed"
    Assert-AutonomousMaterialDecisionFalse -Value $PreviousProof.executable_materials_used -Name "phase137_executable_materials_used"

    $Records = New-AutonomousMaterialDecisionStressDataset
    if (@($Records).Count -ne 300) {
      throw "STRESS_DATASET_RECORD_COUNT_UNEXPECTED=$(@($Records).Count)"
    }

    $InvalidRecords = @($Records | Where-Object { $_.malformed_or_incomplete -eq $true })
    $DuplicateOrConflictRecords = @($Records | Where-Object { $_.duplicate_or_conflict -eq $true })
    $PolicyViolationRecords = @($Records | Where-Object { $_.policy_violation -eq $true })
    $FalseTrustAttempts = @($Records | Where-Object { $_.simulated_false_trust_attempt -eq $true })
    $ForbiddenFetchAttempts = @($Records | Where-Object { $_.simulated_forbidden_fetch_attempt -eq $true })
    $ForbiddenInstallAttempts = @($Records | Where-Object { $_.simulated_forbidden_install_attempt -eq $true })
    $ForbiddenExecutableAttempts = @($Records | Where-Object { $_.simulated_forbidden_executable_attempt -eq $true })
    $UnknownLicenseRecords = @($Records | Where-Object { $_.unknown_license -eq $true })
    $MissingProvenanceRecords = @($Records | Where-Object { $_.missing_provenance -eq $true })
    $LowRiskRecords = @($Records | Where-Object { $_.risk_level -eq "LOW" })
    $MediumRiskRecords = @($Records | Where-Object { $_.risk_level -eq "MEDIUM" })
    $HighRiskRecords = @($Records | Where-Object { $_.risk_level -eq "HIGH" })
    $KnownCandidateRecords = @($Records | Where-Object { $_.known_phase137_candidate -eq $true })

    if (@($LowRiskRecords).Count -lt 30) { throw "LOW_RISK_RECORD_COUNT_LT_30" }
    if (@($MediumRiskRecords).Count -lt 30) { throw "MEDIUM_RISK_RECORD_COUNT_LT_30" }
    if (@($HighRiskRecords).Count -lt 30) { throw "HIGH_RISK_RECORD_COUNT_LT_30" }
    if (@($InvalidRecords).Count -lt 20) { throw "INVALID_RECORD_COUNT_LT_20" }
    if (@($DuplicateOrConflictRecords).Count -lt 20) { throw "DUPLICATE_OR_CONFLICT_COUNT_LT_20" }
    if (@($KnownCandidateRecords).Count -lt 3) { throw "KNOWN_PHASE137_CANDIDATE_COUNT_LT_3" }

    $EligibleCandidates = @($Records | Where-Object {
      $_.eligible_for_sandbox_decision -eq $true -and
      $_.simulated_false_trust_attempt -ne $true -and
      $_.simulated_forbidden_fetch_attempt -ne $true -and
      $_.simulated_forbidden_install_attempt -ne $true -and
      $_.simulated_forbidden_executable_attempt -ne $true
    })
    $Selected = @($EligibleCandidates | Sort-Object @{ Expression = { [int]$_.decision_score }; Descending = $true }, @{ Expression = { "$($_.material_id)" }; Descending = $false } | Select-Object -First 1)
    if (@($Selected).Count -ne 1) {
      throw "AUTONOMOUS_SELECTED_COUNT_UNEXPECTED=$(@($Selected).Count)"
    }

    $RejectedCandidateCount = @($Records).Count - 1 - @($InvalidRecords).Count
    $DecisionConfidence = "HIGH"

    $Dataset = [ordered]@{
      status = "PASS"
      dataset_id = "MATERIAL_DECISION_STRESS_DATASET_300"
      created_by = $StepId
      run_id = $RunId
      synthetic = $true
      record_count = 300
      low_risk_candidate_count = @($LowRiskRecords).Count
      medium_risk_candidate_count = @($MediumRiskRecords).Count
      high_risk_candidate_count = @($HighRiskRecords).Count
      malformed_or_incomplete_count = @($InvalidRecords).Count
      duplicate_or_conflict_count = @($DuplicateOrConflictRecords).Count
      known_phase137_candidate_count = @($KnownCandidateRecords).Count
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      records = $Records
      next_allowed_step = $NextAllowedStep
    }

    $DecisionResult = [ordered]@{
      status = "PASS"
      decision_id = "AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_RESULT_V1"
      created_by = $StepId
      run_id = $RunId
      selected_material_id = $Selected[0].material_id
      selection_reason = "Highest deterministic sandbox score among valid synthetic records, with known PHASE137 candidate provenance and no simulated policy violation."
      selected_by_builder = $true
      owner_delegated_sandbox_decision = $true
      owner_manual_pick = $false
      selected_count = 1
      rejected_candidate_count = $RejectedCandidateCount
      invalid_candidate_count = @($InvalidRecords).Count
      policy_violation_count = @($PolicyViolationRecords).Count
      decision_confidence = $DecisionConfidence
      adoption_scope = "SANDBOX_DECISION_ONLY"
      production_adoption_allowed = $false
      trusted = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_used = $false
      executable_materials_used = $false
      wrapper_created = $false
      smoke_test_executed = $false
      next_allowed_step = $NextAllowedStep
    }

    $ErrorLedger = [ordered]@{
      status = "PASS"
      ledger_id = "AUTONOMOUS_MATERIAL_DECISION_ERROR_LEDGER_V1"
      created_by = $StepId
      run_id = $RunId
      dataset_record_count = 300
      selected_count = 1
      invalid_record_count = @($InvalidRecords).Count
      duplicate_or_conflict_count = @($DuplicateOrConflictRecords).Count
      policy_violation_count = @($PolicyViolationRecords).Count
      false_trust_attempt_count = @($FalseTrustAttempts).Count
      forbidden_fetch_attempt_count = @($ForbiddenFetchAttempts).Count
      forbidden_install_attempt_count = @($ForbiddenInstallAttempts).Count
      forbidden_executable_attempt_count = @($ForbiddenExecutableAttempts).Count
      unknown_license_count = @($UnknownLicenseRecords).Count
      missing_provenance_count = @($MissingProvenanceRecords).Count
      decision_quality_notes = @(
        "Synthetic dataset includes controlled malformed, conflicting, and policy-violating records.",
        "Autonomous selection is sandbox-only and chooses exactly one valid candidate by deterministic score.",
        "No selected or rejected record is fetched, installed, executed, wrapped, smoke tested, or trusted."
      )
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      wrapper_created = $false
      smoke_test_executed = $false
      next_allowed_step = $NextAllowedStep
    }

    Write-AutonomousMaterialDecisionJsonFile -Path $DatasetPath -Object $Dataset
    Write-AutonomousMaterialDecisionJsonFile -Path $DecisionResultPath -Object $DecisionResult
    Write-AutonomousMaterialDecisionJsonFile -Path $ErrorLedgerPath -Object $ErrorLedger

    $Queue = Read-AutonomousMaterialDecisionJsonRequired -Path "TASK_QUEUE.json"
    if ($Queue.active_task_id -ne "NONE") {
      throw "AUTONOMOUS_MATERIAL_DECISION_QUEUE_NOT_NONE=$($Queue.active_task_id)"
    }

    $Output = [ordered]@{
      status = "PASS"
      engine_name = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      stress_dataset_record_count = 300
      autonomous_selected_count = 1
      owner_delegated_sandbox_decision = $true
      owner_manual_pick = $false
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      wrapper_created = $false
      smoke_test_executed = $false
      queue_after = "NONE"
      dataset_path = $DatasetPath
      decision_result_path = $DecisionResultPath
      error_ledger_path = $ErrorLedgerPath
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
      stress_dataset_record_count = 300
      autonomous_selected_count = 1
      owner_delegated_sandbox_decision = $true
      owner_manual_pick = $false
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      wrapper_created = $false
      smoke_test_executed = $false
      queue_after = "NONE"
      selected_material_id = $Selected[0].material_id
      output_path = $OutputPath
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    $Report = [ordered]@{
      status = "PASS"
      report_id = "${StepId}_REPORT"
      phase = $StepId
      run_id = $RunId
      summary = "Autonomous material decision stress lab generated 300 synthetic records, selected exactly one sandbox-only candidate, and recorded error ledger counts without fetch/install/execute/wrap/smoke/trust actions."
      dataset_generation_method = "Deterministic in-repo synthetic generator: first 3 records are PHASE137 candidates; records 4-300 cycle risk bands and inject controlled malformed, duplicate/conflict, and policy-violation flags."
      autonomous_selection_method = "Deterministic policy filter rejects malformed, conflicting, unknown-license, missing-provenance, and simulated policy-violation records, then selects the highest decision_score record inside delegated sandbox scope."
      selected_material_id = $Selected[0].material_id
      stress_dataset_record_count = 300
      autonomous_selected_count = 1
      invalid_record_count = @($InvalidRecords).Count
      duplicate_or_conflict_count = @($DuplicateOrConflictRecords).Count
      policy_violation_count = @($PolicyViolationRecords).Count
      trusted_material_count = 0
      cut_list = @(
        "Do not install external materials.",
        "Do not fetch external repositories or packages.",
        "Do not execute material code.",
        "Do not create wrappers.",
        "Do not smoke test materials.",
        "Do not mark any material trusted.",
        "Do not allow production adoption.",
        "Do not mutate main branch, package manager configs, workflows, or external agent folders."
      )
      next_allowed_step = $NextAllowedStep
    }

    $Proof = [ordered]@{
      status = "PASS"
      proof_id = $StepId
      phase = $StepId
      run_id = $RunId
      runtime_mode = "SELF_BUILD_QUEUE_NONE_AUTONOMOUS_MATERIAL_DECISION_STRESS_LAB_001"
      runtime_executed = $true
      builder_runtime_invoked = $true
      source_proof_path = $PreviousProofPath
      dataset_path = $DatasetPath
      decision_result_path = $DecisionResultPath
      error_ledger_path = $ErrorLedgerPath
      stress_dataset_record_count = 300
      autonomous_selected_count = 1
      owner_delegated_sandbox_decision = $true
      owner_manual_pick = $false
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
      result_path = $ResultPath
      report_path = $ReportPath
      output_path = $OutputPath
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    Write-AutonomousMaterialDecisionJsonFile -Path $OutputPath -Object $Output
    Write-AutonomousMaterialDecisionJsonFile -Path $ResultPath -Object $Result
    Write-AutonomousMaterialDecisionJsonFile -Path $ReportPath -Object $Report
    Write-AutonomousMaterialDecisionJsonFile -Path $ProofPath -Object $Proof

    return [pscustomobject]$Output
  } finally {
    Pop-Location
  }
}
