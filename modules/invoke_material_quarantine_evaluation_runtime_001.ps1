function Read-MaterialQuarantineJsonRequired {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "MATERIAL_QUARANTINE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Resolve-MaterialQuarantinePath {
  param([string]$Path)

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Write-MaterialQuarantineJsonFile {
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

  [System.IO.File]::WriteAllText((Resolve-MaterialQuarantinePath -Path $Path), $json, [System.Text.UTF8Encoding]::new($false))
}

function ConvertTo-MaterialQuarantineArray {
  param([object]$Value)

  if ($null -eq $Value) {
    return @()
  }
  if ($Value -is [System.Array]) {
    return $Value
  }
  return @($Value)
}

function Assert-MaterialQuarantineFalse {
  param(
    [object]$Value,
    [string]$Name
  )

  if ($Value -ne $false) {
    throw "MATERIAL_QUARANTINE_FLAG_NOT_FALSE=$Name"
  }
}

function Set-MaterialQuarantineProperty {
  param(
    [object]$Object,
    [string]$Name,
    [object]$Value
  )

  $property = $Object.PSObject.Properties | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
  if ($null -eq $property) {
    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
  } else {
    $property.Value = $Value
  }
}

function Invoke-MaterialQuarantineEvaluationRuntime001 {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$OutputRoot
  )

  Push-Location $RepoRoot

  try {
    $StepId = "PHASE137_BUILD_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_V1"
    $RuntimeId = "PHASE137_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_001"
    $PreviousStepId = "PHASE136_IMPORT_MANUAL_MATERIAL_SCOUT_PASS_TO_CATALOG_V1"
    $NextAllowedStep = "PHASE138_OWNER_DECISION_FOR_FIRST_MATERIAL_ADOPTION_V1"
    $ExpectedMaterialIds = @(
      "candidate_pester_powershell_test_framework",
      "candidate_psscriptanalyzer_static_checker",
      "candidate_syft_sbom_cli"
    )
    $ReferenceOnlyMaterialId = "reference_json_schema_official"

    if ([string]::IsNullOrWhiteSpace($RunId)) {
      $RunId = $RuntimeId
    }

    $OutputArtifactRoot = "self_build_batch/autonomy_trials/$StepId"
    if (-not (Test-Path -LiteralPath $OutputArtifactRoot)) {
      New-Item -ItemType Directory -Force -Path $OutputArtifactRoot | Out-Null
    }

    $PreviousProofPath = "proofs/self_development/${PreviousStepId}.json"
    $EvaluationQueuePath = "materials/MATERIAL_EVALUATION_QUEUE.json"
    $QuarantineRegisterPath = "materials/MATERIAL_QUARANTINE_REGISTER.json"
    $EvaluationResultsPath = "materials/MATERIAL_QUARANTINE_EVALUATION_RESULTS.json"
    $OutputPath = "$OutputArtifactRoot/MATERIAL_QUARANTINE_EVALUATION_RUNTIME_OUTPUT.json"
    $ResultPath = "$OutputArtifactRoot/${StepId}_RESULT.json"
    $RuntimeLogPath = "$OutputArtifactRoot/${StepId}_RUNTIME_LOG.txt"
    $ReportPath = "reports/self_development/${StepId}_REPORT.json"
    $ProofPath = "proofs/self_development/${StepId}.json"

    $PreviousProof = Read-MaterialQuarantineJsonRequired -Path $PreviousProofPath
    if ($PreviousProof.status -ne "PASS") {
      throw "PHASE136_PROOF_NOT_PASS"
    }
    if ($PreviousProof.next_allowed_step -ne $StepId) {
      throw "PHASE136_NEXT_ALLOWED_STEP_UNEXPECTED=$($PreviousProof.next_allowed_step)"
    }
    if ($PreviousProof.trusted_material_count -ne 0) {
      throw "PHASE136_TRUSTED_COUNT_NOT_ZERO=$($PreviousProof.trusted_material_count)"
    }
    Assert-MaterialQuarantineFalse -Value $PreviousProof.external_fetch_performed -Name "phase136_external_fetch_performed"
    Assert-MaterialQuarantineFalse -Value $PreviousProof.dependency_install_performed -Name "phase136_dependency_install_performed"

    $EvaluationQueue = Read-MaterialQuarantineJsonRequired -Path $EvaluationQueuePath
    $QuarantineRegister = Read-MaterialQuarantineJsonRequired -Path $QuarantineRegisterPath
    $QueueMaterials = ConvertTo-MaterialQuarantineArray -Value $EvaluationQueue.materials
    if (@($QueueMaterials).Count -ne 3) {
      throw "MATERIAL_EVALUATION_QUEUE_COUNT_UNEXPECTED=$(@($QueueMaterials).Count)"
    }
    if ($EvaluationQueue.candidate_material_count -ne 3) {
      throw "MATERIAL_EVALUATION_QUEUE_CANDIDATE_COUNT_UNEXPECTED=$($EvaluationQueue.candidate_material_count)"
    }
    if ($EvaluationQueue.trusted_material_count -ne 0) {
      throw "MATERIAL_EVALUATION_QUEUE_TRUSTED_COUNT_NOT_ZERO=$($EvaluationQueue.trusted_material_count)"
    }
    Assert-MaterialQuarantineFalse -Value $EvaluationQueue.external_fetch_performed -Name "evaluation_queue_external_fetch_performed"
    Assert-MaterialQuarantineFalse -Value $EvaluationQueue.dependency_install_performed -Name "evaluation_queue_dependency_install_performed"
    Assert-MaterialQuarantineFalse -Value $EvaluationQueue.executable_materials_used -Name "evaluation_queue_executable_materials_used"

    $QueueMaterialIds = @($QueueMaterials | ForEach-Object { "$($_.material_id)" })
    foreach ($ExpectedMaterialId in $ExpectedMaterialIds) {
      if ($QueueMaterialIds -notcontains $ExpectedMaterialId) {
        throw "MATERIAL_EVALUATION_QUEUE_MISSING_CANDIDATE=$ExpectedMaterialId"
      }
    }
    if ($QueueMaterialIds -contains $ReferenceOnlyMaterialId) {
      throw "REFERENCE_ONLY_MATERIAL_IN_EXECUTABLE_QUEUE=$ReferenceOnlyMaterialId"
    }

    $ExcludedReferenceOnlyIds = @(ConvertTo-MaterialQuarantineArray -Value $EvaluationQueue.excluded_reference_only_materials | ForEach-Object { "$($_.material_id)" })
    if ($ExcludedReferenceOnlyIds -notcontains $ReferenceOnlyMaterialId) {
      throw "REFERENCE_ONLY_MATERIAL_NOT_EXCLUDED=$ReferenceOnlyMaterialId"
    }

    $EvaluationRecords = @()
    foreach ($ExpectedMaterialId in $ExpectedMaterialIds) {
      $Material = @($QueueMaterials | Where-Object { $_.material_id -eq $ExpectedMaterialId } | Select-Object -First 1)
      if (@($Material).Count -ne 1) {
        throw "MATERIAL_EVALUATION_QUEUE_DUPLICATE_OR_MISSING=$ExpectedMaterialId"
      }

      $EvaluationRecords += [ordered]@{
        material_id = $Material[0].material_id
        name = $Material[0].name
        evaluation_status = "QUARANTINE_EVALUATED_METADATA_ONLY"
        external_fetch_performed = $false
        dependency_install_performed = $false
        executable_used = $false
        trusted = $false
        owner_decision_required = $true
        license_review_required = $true
        provenance_review_required = $true
        wrapper_required_before_use = $true
        smoke_test_required_before_trust = $true
        recommended_next_action = "AWAIT_OWNER_DECISION_FOR_FIRST_MATERIAL_ADOPTION"
      }
    }

    $RegisterEntries = ConvertTo-MaterialQuarantineArray -Value $QuarantineRegister.entries
    foreach ($ExpectedMaterialId in $ExpectedMaterialIds) {
      $Entry = @($RegisterEntries | Where-Object { $_.material_id -eq $ExpectedMaterialId } | Select-Object -First 1)
      if (@($Entry).Count -ne 1) {
        throw "QUARANTINE_REGISTER_MISSING_CANDIDATE=$ExpectedMaterialId"
      }
      if ($Entry[0].quarantine_decision -ne "QUARANTINE_REQUIRED") {
        throw "QUARANTINE_REGISTER_CANDIDATE_DECISION_UNEXPECTED=$ExpectedMaterialId::$($Entry[0].quarantine_decision)"
      }

      Set-MaterialQuarantineProperty -Object $Entry[0] -Name "quarantine_status" -Value "METADATA_EVALUATED_AWAITING_OWNER_DECISION"
      Set-MaterialQuarantineProperty -Object $Entry[0] -Name "trusted" -Value $false
      Set-MaterialQuarantineProperty -Object $Entry[0] -Name "executable_used" -Value $false
      Set-MaterialQuarantineProperty -Object $Entry[0] -Name "evaluation_status" -Value "QUARANTINE_EVALUATED_METADATA_ONLY"
    }

    $ReferenceEntry = @($RegisterEntries | Where-Object { $_.material_id -eq $ReferenceOnlyMaterialId } | Select-Object -First 1)
    if (@($ReferenceEntry).Count -eq 1 -and $ReferenceEntry[0].quarantine_decision -ne "REFERENCE_ONLY_NOT_EXECUTABLE") {
      throw "QUARANTINE_REGISTER_REFERENCE_ONLY_DECISION_UNEXPECTED=$($ReferenceEntry[0].quarantine_decision)"
    }

    Set-MaterialQuarantineProperty -Object $QuarantineRegister -Name "status" -Value "METADATA_EVALUATED_AWAITING_OWNER_DECISION"
    Set-MaterialQuarantineProperty -Object $QuarantineRegister -Name "updated_by" -Value $StepId
    Set-MaterialQuarantineProperty -Object $QuarantineRegister -Name "run_id" -Value $RunId
    Set-MaterialQuarantineProperty -Object $QuarantineRegister -Name "evaluated_candidate_material_count" -Value 3
    Set-MaterialQuarantineProperty -Object $QuarantineRegister -Name "trusted_material_count" -Value 0
    Set-MaterialQuarantineProperty -Object $QuarantineRegister -Name "external_fetch_performed" -Value $false
    Set-MaterialQuarantineProperty -Object $QuarantineRegister -Name "dependency_install_performed" -Value $false
    Set-MaterialQuarantineProperty -Object $QuarantineRegister -Name "executable_materials_used" -Value $false
    Set-MaterialQuarantineProperty -Object $QuarantineRegister -Name "reference_only_evaluated_as_executable" -Value $false
    Set-MaterialQuarantineProperty -Object $QuarantineRegister -Name "next_allowed_step" -Value $NextAllowedStep

    foreach ($Material in $QueueMaterials) {
      Set-MaterialQuarantineProperty -Object $Material -Name "status" -Value "METADATA_EVALUATED_AWAITING_OWNER_DECISION"
      Set-MaterialQuarantineProperty -Object $Material -Name "evaluation_status" -Value "QUARANTINE_EVALUATED_METADATA_ONLY"
      Set-MaterialQuarantineProperty -Object $Material -Name "trusted" -Value $false
      Set-MaterialQuarantineProperty -Object $Material -Name "executable_used" -Value $false
    }

    Set-MaterialQuarantineProperty -Object $EvaluationQueue -Name "status" -Value "METADATA_EVALUATED_AWAITING_OWNER_DECISION"
    Set-MaterialQuarantineProperty -Object $EvaluationQueue -Name "updated_by" -Value $StepId
    Set-MaterialQuarantineProperty -Object $EvaluationQueue -Name "run_id" -Value $RunId
    Set-MaterialQuarantineProperty -Object $EvaluationQueue -Name "candidate_material_count" -Value 3
    Set-MaterialQuarantineProperty -Object $EvaluationQueue -Name "executable_evaluation_count" -Value 3
    Set-MaterialQuarantineProperty -Object $EvaluationQueue -Name "reference_only_excluded_count" -Value 1
    Set-MaterialQuarantineProperty -Object $EvaluationQueue -Name "trusted_material_count" -Value 0
    Set-MaterialQuarantineProperty -Object $EvaluationQueue -Name "materials" -Value @($QueueMaterials)
    Set-MaterialQuarantineProperty -Object $EvaluationQueue -Name "queue_items" -Value @($QueueMaterials)
    Set-MaterialQuarantineProperty -Object $EvaluationQueue -Name "external_fetch_performed" -Value $false
    Set-MaterialQuarantineProperty -Object $EvaluationQueue -Name "dependency_install_performed" -Value $false
    Set-MaterialQuarantineProperty -Object $EvaluationQueue -Name "executable_materials_used" -Value $false
    Set-MaterialQuarantineProperty -Object $EvaluationQueue -Name "reference_only_evaluated_as_executable" -Value $false
    Set-MaterialQuarantineProperty -Object $EvaluationQueue -Name "next_allowed_step" -Value $NextAllowedStep

    $EvaluationResults = [ordered]@{
      status = "PASS"
      results_id = "MATERIAL_QUARANTINE_EVALUATION_RESULTS_V1"
      created_by = $StepId
      run_id = $RunId
      source_proof_path = $PreviousProofPath
      source_queue_path = $EvaluationQueuePath
      source_quarantine_register_path = $QuarantineRegisterPath
      evaluated_material_count = 3
      trusted_material_count = 0
      owner_decision_required_count = 3
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      reference_only_evaluated_as_executable = $false
      records = $EvaluationRecords
      next_allowed_step = $NextAllowedStep
    }

    Write-MaterialQuarantineJsonFile -Path $EvaluationResultsPath -Object $EvaluationResults
    Write-MaterialQuarantineJsonFile -Path $QuarantineRegisterPath -Object $QuarantineRegister
    Write-MaterialQuarantineJsonFile -Path $EvaluationQueuePath -Object $EvaluationQueue

    $Queue = Read-MaterialQuarantineJsonRequired -Path "TASK_QUEUE.json"
    if ($Queue.active_task_id -ne "NONE") {
      throw "MATERIAL_QUARANTINE_QUEUE_NOT_NONE=$($Queue.active_task_id)"
    }

    $Output = [ordered]@{
      status = "PASS"
      engine_name = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      evaluated_material_count = 3
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      reference_only_evaluated_as_executable = $false
      owner_decision_required_count = 3
      queue_after = "NONE"
      material_evaluation_queue_path = $EvaluationQueuePath
      material_quarantine_register_path = $QuarantineRegisterPath
      material_quarantine_evaluation_results_path = $EvaluationResultsPath
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
      evaluated_material_count = 3
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      reference_only_evaluated_as_executable = $false
      owner_decision_required_count = 3
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
      summary = "Metadata-only quarantine evaluation completed for three candidate materials. No external material was fetched, installed, executed, trusted, wrapped, or smoke tested. Reference-only material stayed excluded from executable evaluation."
      evaluated_material_count = 3
      evaluated_material_ids = $ExpectedMaterialIds
      trusted_material_count = 0
      owner_decision_required_count = 3
      reference_only_evaluated_as_executable = $false
      material_evaluation_queue_path = $EvaluationQueuePath
      material_quarantine_register_path = $QuarantineRegisterPath
      material_quarantine_evaluation_results_path = $EvaluationResultsPath
      cut_list = @(
        "Do not install external materials.",
        "Do not fetch external repositories or packages.",
        "Do not execute imported materials.",
        "Do not trust materials.",
        "Do not wrap materials.",
        "Do not smoke test materials in PHASE137.",
        "Do not evaluate reference-only material as executable.",
        "Do not mutate main branch or external agent folders."
      )
      next_allowed_step = $NextAllowedStep
    }

    $Proof = [ordered]@{
      status = "PASS"
      proof_id = $StepId
      phase = $StepId
      run_id = $RunId
      runtime_mode = "SELF_BUILD_QUEUE_NONE_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_001"
      runtime_executed = $true
      builder_runtime_invoked = $true
      source_proof_path = $PreviousProofPath
      material_evaluation_queue_path = $EvaluationQueuePath
      material_quarantine_register_path = $QuarantineRegisterPath
      material_quarantine_evaluation_results_path = $EvaluationResultsPath
      evaluated_material_count = 3
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      reference_only_evaluated_as_executable = $false
      owner_decision_required_count = 3
      queue_after = "NONE"
      codex_used = $false
      main_touched = $false
      result_path = $ResultPath
      report_path = $ReportPath
      output_path = $OutputPath
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    Write-MaterialQuarantineJsonFile -Path $OutputPath -Object $Output
    Write-MaterialQuarantineJsonFile -Path $ResultPath -Object $Result
    Write-MaterialQuarantineJsonFile -Path $ReportPath -Object $Report
    Write-MaterialQuarantineJsonFile -Path $ProofPath -Object $Proof

    return [pscustomobject]$Output
  } finally {
    Pop-Location
  }
}
