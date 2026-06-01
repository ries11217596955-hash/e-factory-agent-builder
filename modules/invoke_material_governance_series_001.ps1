function Read-MaterialGovernanceJsonRequired {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "MATERIAL_GOVERNANCE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Write-MaterialGovernanceJsonFile {
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

  [System.IO.File]::WriteAllText((Resolve-MaterialGovernancePath -Path $Path), $json, [System.Text.UTF8Encoding]::new($false))
}

function Resolve-MaterialGovernancePath {
  param([string]$Path)

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function ConvertTo-MaterialGovernanceArray {
  param([object]$Value)

  if ($null -eq $Value) {
    return @()
  }
  if ($Value -is [System.Array]) {
    return $Value
  }
  return @($Value)
}

function Assert-MaterialGovernanceFalse {
  param(
    [object]$Value,
    [string]$Name
  )

  if ($Value -ne $false) {
    throw "MATERIAL_GOVERNANCE_FLAG_NOT_FALSE=$Name"
  }
}

function Invoke-MaterialGovernanceSeries001 {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$OutputRoot
  )

  Push-Location $RepoRoot

  try {
    $StepId = "PHASE136_IMPORT_MANUAL_MATERIAL_SCOUT_PASS_TO_CATALOG_V1"
    $SeriesId = "PHASE136_MATERIAL_GOVERNANCE_SERIES_001"
    $NextAllowedStep = "PHASE137_BUILD_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_V1"

    if ([string]::IsNullOrWhiteSpace($RunId)) {
      $RunId = "PHASE136_MATERIAL_GOVERNANCE_SERIES_001"
    }

    if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
      $OutputRoot = "self_build_batch/autonomy_trials/$StepId"
    }

    $OutputArtifactRoot = "self_build_batch/autonomy_trials/$StepId"

    if (-not (Test-Path -LiteralPath $OutputArtifactRoot)) {
      New-Item -ItemType Directory -Force -Path $OutputArtifactRoot | Out-Null
    }

    $ScoutPassPath = "materials/MANUAL_SCOUT_PASS_001.json"
    $PreviousProofPath = "proofs/self_development/PHASE135_RUN_MANUAL_MATERIAL_SCOUT_PASS_001_V1.json"
    $CatalogPath = "materials/MATERIAL_CATALOG.json"
    $QuarantineRegisterPath = "materials/MATERIAL_QUARANTINE_REGISTER.json"
    $UsePolicyPath = "materials/MATERIAL_USE_POLICY.json"
    $EvaluationQueuePath = "materials/MATERIAL_EVALUATION_QUEUE.json"
    $OutputPath = "$OutputArtifactRoot/MATERIAL_GOVERNANCE_SERIES_OUTPUT.json"
    $WrongOutputPath = "$OutputArtifactRoot/MATERIAL_GOVERNANCE_SERIES_001_OUTPUT.json"
    $ResultPath = "$OutputArtifactRoot/${StepId}_RESULT.json"
    $RuntimeLogPath = "$OutputArtifactRoot/${StepId}_RUNTIME_LOG.txt"
    $ReportPath = "reports/self_development/${StepId}_REPORT.json"
    $ProofPath = "proofs/self_development/${StepId}.json"

    $PreviousProof = Read-MaterialGovernanceJsonRequired -Path $PreviousProofPath
    if ($PreviousProof.status -ne "PASS") {
      throw "PHASE135_PROOF_NOT_PASS"
    }
    if ($PreviousProof.next_allowed_step -ne $StepId) {
      throw "PHASE135_NEXT_ALLOWED_STEP_UNEXPECTED=$($PreviousProof.next_allowed_step)"
    }

    $ScoutPass = Read-MaterialGovernanceJsonRequired -Path $ScoutPassPath
    if ($ScoutPass.status -ne "PASS") {
      throw "MANUAL_SCOUT_PASS_NOT_PASS"
    }
    if ($ScoutPass.scout_pass_id -ne "MANUAL_MATERIAL_SCOUT_PASS_001") {
      throw "MANUAL_SCOUT_PASS_ID_UNEXPECTED=$($ScoutPass.scout_pass_id)"
    }
    if ($ScoutPass.next_allowed_step -ne $StepId) {
      throw "MANUAL_SCOUT_PASS_NEXT_ALLOWED_STEP_UNEXPECTED=$($ScoutPass.next_allowed_step)"
    }

    Assert-MaterialGovernanceFalse -Value $ScoutPass.external_fetch_performed_by_runtime -Name "scout_external_fetch_performed_by_runtime"
    Assert-MaterialGovernanceFalse -Value $ScoutPass.dependency_install_performed -Name "scout_dependency_install_performed"

    $ScoutMaterials = ConvertTo-MaterialGovernanceArray -Value $ScoutPass.candidate_materials
    $CandidateMaterials = @($ScoutMaterials | Where-Object { $_.initial_status -eq "CANDIDATE" })
    $ReferenceOnlyMaterials = @($ScoutMaterials | Where-Object { $_.initial_status -eq "REFERENCE_ONLY" })

    if (@($ScoutMaterials).Count -ne 4) {
      throw "SCOUT_MATERIAL_COUNT_UNEXPECTED=$(@($ScoutMaterials).Count)"
    }
    if (@($CandidateMaterials).Count -ne 3) {
      throw "SCOUT_CANDIDATE_COUNT_UNEXPECTED=$(@($CandidateMaterials).Count)"
    }
    if (@($ReferenceOnlyMaterials).Count -ne 1) {
      throw "SCOUT_REFERENCE_ONLY_COUNT_UNEXPECTED=$(@($ReferenceOnlyMaterials).Count)"
    }
    if ($ScoutPass.candidate_material_count -ne 3) {
      throw "SCOUT_REPORTED_CANDIDATE_COUNT_UNEXPECTED=$($ScoutPass.candidate_material_count)"
    }
    if ($ScoutPass.reference_only_material_count -ne 1) {
      throw "SCOUT_REPORTED_REFERENCE_ONLY_COUNT_UNEXPECTED=$($ScoutPass.reference_only_material_count)"
    }
    if ($ScoutPass.trusted_material_count -ne 0) {
      throw "SCOUT_TRUSTED_COUNT_NOT_ZERO=$($ScoutPass.trusted_material_count)"
    }

    $SeenMaterialIds = @{}
    $GovernedMaterials = @()
    $QuarantineEntries = @()
    $EvaluationItems = @()
    $ReferenceOnlyExcluded = @()

    foreach ($Material in $ScoutMaterials) {
      $MaterialId = "$($Material.material_id)"
      if ([string]::IsNullOrWhiteSpace($MaterialId)) {
        throw "SCOUT_MATERIAL_ID_MISSING"
      }
      if ($SeenMaterialIds.ContainsKey($MaterialId)) {
        throw "SCOUT_MATERIAL_ID_DUPLICATE=$MaterialId"
      }
      $SeenMaterialIds[$MaterialId] = $true

      if (@("TRUSTED", "TESTED", "WRAPPED") -contains "$($Material.initial_status)") {
        throw "SCOUT_MATERIAL_FORBIDDEN_INITIAL_STATUS=$MaterialId::$($Material.initial_status)"
      }
      if ($Material.owner_decision_required -ne $true) {
        throw "SCOUT_MATERIAL_OWNER_DECISION_NOT_REQUIRED=$MaterialId"
      }

      $IsCandidate = ($Material.initial_status -eq "CANDIDATE")
      $IsReferenceOnly = ($Material.initial_status -eq "REFERENCE_ONLY")

      if (-not ($IsCandidate -or $IsReferenceOnly)) {
        throw "SCOUT_MATERIAL_STATUS_UNEXPECTED=$MaterialId::$($Material.initial_status)"
      }

      $GovernanceState = $(if ($IsCandidate) { "IMPORTED_CANDIDATE_UNTRUSTED" } else { "IMPORTED_REFERENCE_ONLY_UNTRUSTED" })
      $QuarantineDecision = $(if ($IsCandidate) { "QUARANTINE_REQUIRED" } else { "REFERENCE_ONLY_NOT_EXECUTABLE" })
      $EvaluationStatus = $(if ($IsCandidate) { "READY_FOR_BOUNDED_EVALUATION" } else { "EXCLUDED_REFERENCE_ONLY" })

      $GovernedMaterials += [ordered]@{
        material_id = $MaterialId
        name = $Material.name
        material_type = $Material.material_type
        source = $Material.source
        provenance = $Material.provenance
        license_or_terms = $Material.license_or_terms
        risk_notes = $Material.risk_notes
        intended_use = $Material.intended_use
        imported_from_scout_pass = $ScoutPass.scout_pass_id
        imported_by = $StepId
        initial_status = $Material.initial_status
        status = $Material.initial_status
        governance_state = $GovernanceState
        owner_decision_required = $true
        license_provenance_review_required = $true
        quarantine_required = $IsCandidate
        wrapper_decision_required = $true
        smoke_test_required = $true
        trust_status = "NOT_TRUSTED"
        test_status = "NOT_TESTED"
        wrapper_status = "NOT_WRAPPED"
        executable_material_used = $false
        use_allowed = $false
        quarantine_decision = $QuarantineDecision
        evaluation_status = $EvaluationStatus
      }

      $QuarantineEntries += [ordered]@{
        material_id = $MaterialId
        name = $Material.name
        material_type = $Material.material_type
        source = $Material.source
        material_status = $Material.initial_status
        quarantine_decision = $QuarantineDecision
        trust_status = "NOT_TRUSTED"
        executable_material_used = $false
        required_before_use = @(
          "OWNER_APPROVAL",
          "LICENSE_PROVENANCE_REVIEW",
          "QUARANTINE",
          "WRAPPER_DECISION",
          "SMOKE_TEST"
        )
      }

      if ($IsCandidate) {
        $EvaluationItems += [ordered]@{
          material_id = $MaterialId
          name = $Material.name
          material_type = $Material.material_type
          source = $Material.source
          status = "READY_FOR_BOUNDED_EVALUATION"
          trust_status = "NOT_TRUSTED"
          external_fetch_allowed = $false
          dependency_install_allowed = $false
          executable_use_allowed = $false
          required_before_any_use = @(
            "OWNER_APPROVAL",
            "LICENSE_PROVENANCE_REVIEW",
            "QUARANTINE",
            "WRAPPER_DECISION",
            "SMOKE_TEST"
          )
        }
      } else {
        $ReferenceOnlyExcluded += [ordered]@{
          material_id = $MaterialId
          name = $Material.name
          reason = "REFERENCE_ONLY_NOT_EXECUTABLE"
        }
      }
    }

    $GovernedCatalog = [ordered]@{
      status = "GOVERNED_IMPORTED"
      catalog_id = "MATERIAL_CATALOG_V1"
      updated_by = $StepId
      run_id = $RunId
      source_scout_pass_id = $ScoutPass.scout_pass_id
      source_scout_pass_path = $ScoutPassPath
      source_proof_path = $PreviousProofPath
      default_trust = $false
      default_allow = $false
      material_count = 4
      imported_material_count = 4
      candidate_material_count = 3
      reference_only_material_count = 1
      trusted_material_count = 0
      quarantine_required_count = 3
      reference_only_not_executable_count = 1
      executable_materials_used = $false
      external_fetch_performed = $false
      dependency_install_performed = $false
      material_statuses = @(
        "DISCOVERED",
        "CANDIDATE",
        "QUARANTINED",
        "WRAPPED",
        "TESTED",
        "TRUSTED",
        "REJECTED",
        "REFERENCE_ONLY",
        "OWNER_APPROVAL_REQUIRED"
      )
      governance_requirements_before_use = @(
        "OWNER_APPROVAL",
        "LICENSE_PROVENANCE_REVIEW",
        "QUARANTINE",
        "WRAPPER_DECISION",
        "SMOKE_TEST"
      )
      materials = $GovernedMaterials
      next_allowed_step = $NextAllowedStep
    }

    $QuarantineRegister = [ordered]@{
      status = "GOVERNED_QUARANTINE_REGISTER_CREATED"
      register_id = "MATERIAL_QUARANTINE_REGISTER_V1"
      created_by = $StepId
      run_id = $RunId
      source_catalog_path = $CatalogPath
      material_count = 4
      candidate_material_count = 3
      reference_only_material_count = 1
      trusted_material_count = 0
      candidate_quarantine_decision = "QUARANTINE_REQUIRED"
      reference_only_quarantine_decision = "REFERENCE_ONLY_NOT_EXECUTABLE"
      entries = $QuarantineEntries
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      next_allowed_step = $NextAllowedStep
    }

    $UsePolicy = [ordered]@{
      status = "ACTIVE"
      policy_id = "MATERIAL_USE_POLICY_V1"
      created_by = $StepId
      run_id = $RunId
      default_allow = $false
      trusted_material_count = 0
      no_material_can_be_used_until = @(
        "OWNER_APPROVAL",
        "LICENSE_PROVENANCE_REVIEW",
        "QUARANTINE",
        "WRAPPER_DECISION",
        "SMOKE_TEST"
      )
      forbidden_without_all_gates = @(
        "INSTALL",
        "FETCH",
        "EXECUTE",
        "WRAP",
        "TEST",
        "TRUST",
        "USE_IN_BUILDER_RUNTIME",
        "USE_IN_EXTERNAL_AGENT"
      )
      material_rules = @($GovernedMaterials | ForEach-Object {
        [ordered]@{
          material_id = $_.material_id
          allow_use = $false
          trust_status = "NOT_TRUSTED"
          owner_approval_required = $true
          license_provenance_review_required = $true
          quarantine_required = $true
          quarantine_register_decision = $_.quarantine_decision
          wrapper_decision_required = $true
          smoke_test_required = $true
          executable_material_used = $false
        }
      })
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      next_allowed_step = $NextAllowedStep
    }

    $EvaluationQueue = [ordered]@{
      status = "READY_FOR_BOUNDED_EVALUATION"
      queue_id = "MATERIAL_EVALUATION_QUEUE_V1"
      created_by = $StepId
      run_id = $RunId
      source_catalog_path = $CatalogPath
      candidate_material_count = 3
      executable_evaluation_count = 3
      reference_only_excluded_count = 1
      trusted_material_count = 0
      materials = $EvaluationItems
      queue_items = $EvaluationItems
      excluded_reference_only_materials = $ReferenceOnlyExcluded
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      next_allowed_step = $NextAllowedStep
    }

    Write-MaterialGovernanceJsonFile -Path $CatalogPath -Object $GovernedCatalog
    Write-MaterialGovernanceJsonFile -Path $QuarantineRegisterPath -Object $QuarantineRegister
    Write-MaterialGovernanceJsonFile -Path $UsePolicyPath -Object $UsePolicy
    Write-MaterialGovernanceJsonFile -Path $EvaluationQueuePath -Object $EvaluationQueue

    if (Test-Path -LiteralPath $WrongOutputPath) {
      Remove-Item -LiteralPath $WrongOutputPath -Force
    }

    $Queue = Read-MaterialGovernanceJsonRequired -Path "TASK_QUEUE.json"
    if ($Queue.active_task_id -ne "NONE") {
      throw "MATERIAL_GOVERNANCE_QUEUE_NOT_NONE=$($Queue.active_task_id)"
    }

    $Output = [ordered]@{
      status = "PASS"
      engine_name = $SeriesId
      step_id = $StepId
      run_id = $RunId
      source_scout_pass_path = $ScoutPassPath
      source_proof_path = $PreviousProofPath
      material_catalog_path = $CatalogPath
      quarantine_register_path = $QuarantineRegisterPath
      use_policy_path = $UsePolicyPath
      evaluation_queue_path = $EvaluationQueuePath
      imported_material_count = 4
      candidate_material_count = 3
      reference_only_material_count = 1
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      queue_after = "NONE"
      codex_used = $false
      main_touched = $false
      proposed_next_step = $NextAllowedStep
      next_allowed_step = $NextAllowedStep
      output_path = $OutputPath
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      runtime_log_path = $RuntimeLogPath
    }

    $Result = [ordered]@{
      status = "PASS"
      phase = $StepId
      active_line = "AGENT_BUILDER_SELF_DEVELOPMENT"
      run_id = $RunId
      series_id = $SeriesId
      runtime_executed = $true
      builder_runtime_invoked = $true
      imported_material_count = 4
      candidate_material_count = 3
      reference_only_material_count = 1
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      queue_after = "NONE"
      catalog_path = $CatalogPath
      quarantine_register_path = $QuarantineRegisterPath
      use_policy_path = $UsePolicyPath
      evaluation_queue_path = $EvaluationQueuePath
      output_path = $OutputPath
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    $Report = [ordered]@{
      status = "PASS"
      report_id = "${StepId}_REPORT"
      phase = $StepId
      run_id = $RunId
      summary = "Imported MANUAL_SCOUT_PASS_001 into governed material catalog structures. Three candidate materials were routed to bounded evaluation readiness; one reference-only material was excluded from executable evaluation. No material was trusted, fetched, installed, wrapped, tested, or used."
      source_scout_pass_path = $ScoutPassPath
      source_proof_path = $PreviousProofPath
      material_catalog_path = $CatalogPath
      quarantine_register_path = $QuarantineRegisterPath
      use_policy_path = $UsePolicyPath
      evaluation_queue_path = $EvaluationQueuePath
      imported_material_count = 4
      candidate_material_count = 3
      reference_only_material_count = 1
      trusted_material_count = 0
      candidate_material_ids = @($CandidateMaterials | ForEach-Object { $_.material_id })
      reference_only_material_ids = @($ReferenceOnlyMaterials | ForEach-Object { $_.material_id })
      policy_summary = [ordered]@{
        default_allow = $false
        trusted_material_count = 0
        owner_approval_required = $true
        license_provenance_review_required = $true
        quarantine_required_for_candidates = $true
        wrapper_decision_required = $true
        smoke_test_required = $true
      }
      cut_list = @(
        "Do not install external materials.",
        "Do not fetch external repositories or packages.",
        "Do not execute imported materials.",
        "Do not wrap imported materials.",
        "Do not smoke test imported materials in PHASE136.",
        "Do not mark any material TRUSTED.",
        "Do not put reference-only material into executable evaluation.",
        "Do not mutate main branch or external agent folders."
      )
      next_allowed_step = $NextAllowedStep
    }

    $Proof = [ordered]@{
      status = "PASS"
      proof_id = $StepId
      phase = $StepId
      run_id = $RunId
      runtime_mode = "SELF_BUILD_QUEUE_NONE_MATERIAL_GOVERNANCE_SERIES_001"
      runtime_executed = $true
      builder_runtime_invoked = $true
      source_scout_pass_path = $ScoutPassPath
      source_proof_path = $PreviousProofPath
      material_catalog_path = $CatalogPath
      quarantine_register_path = $QuarantineRegisterPath
      use_policy_path = $UsePolicyPath
      evaluation_queue_path = $EvaluationQueuePath
      imported_material_count = 4
      candidate_material_count = 3
      reference_only_material_count = 1
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      queue_after = "NONE"
      codex_used = $false
      main_touched = $false
      result_path = $ResultPath
      report_path = $ReportPath
      output_path = $OutputPath
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    Write-MaterialGovernanceJsonFile -Path $OutputPath -Object $Output
    Write-MaterialGovernanceJsonFile -Path $ResultPath -Object $Result
    Write-MaterialGovernanceJsonFile -Path $ReportPath -Object $Report
    Write-MaterialGovernanceJsonFile -Path $ProofPath -Object $Proof

    return [pscustomobject]$Output
  } finally {
    Pop-Location
  }
}
