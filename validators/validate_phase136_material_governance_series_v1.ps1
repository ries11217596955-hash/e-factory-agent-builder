$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

function Read-JsonOrFail {
  param([string]$Path)

  try {
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  } catch {
    Mark-Fail "JSON_PARSE_FAIL=$Path :: $($_.Exception.Message)"
    return $null
  }
}

function As-Array {
  param([object]$Value)

  if ($null -eq $Value) {
    return @()
  }
  if ($Value -is [System.Array]) {
    return $Value
  }
  return @($Value)
}

function Test-PropertyExists {
  param(
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object) {
    return $false
  }

  return $null -ne ($Object.PSObject.Properties | Where-Object { $_.Name -eq $Name } | Select-Object -First 1)
}

function Get-PropertyValue {
  param(
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object) {
    return $null
  }

  $property = $Object.PSObject.Properties | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
  if ($null -eq $property) {
    return $null
  }

  return $property.Value
}

function Assert-Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    Mark-Fail "$Name`_UNEXPECTED=$Actual EXPECTED=$Expected"
  }
}

function Assert-FalseProperty {
  param(
    [object]$Object,
    [string]$PropertyName,
    [string]$Context
  )

  if (Test-PropertyExists -Object $Object -Name $PropertyName) {
    $value = Get-PropertyValue -Object $Object -Name $PropertyName
    if ($value -ne $false) {
      Mark-Fail "$Context`_$PropertyName`_NOT_FALSE=$value"
    }
  }
}

function Assert-NoForbiddenMaterialState {
  param(
    [object]$Object,
    [string]$Context
  )

  foreach ($propertyName in @("initial_status", "status", "trust_status", "test_status", "wrapper_status")) {
    if (Test-PropertyExists -Object $Object -Name $propertyName) {
      $value = "$(Get-PropertyValue -Object $Object -Name $propertyName)"
      if (@("TRUSTED", "TESTED", "WRAPPED") -contains $value) {
        $materialId = Get-PropertyValue -Object $Object -Name "material_id"
        Mark-Fail "$Context`_FORBIDDEN_MATERIAL_STATE=$materialId::$propertyName::$value"
      }
    }
  }
}

function Assert-NoForbiddenActionFlags {
  param(
    [object]$Object,
    [string]$Context
  )

  foreach ($propertyName in @(
    "external_fetch_performed",
    "external_fetch_performed_by_runtime",
    "external_fetch_allowed",
    "dependency_install_performed",
    "dependency_install_allowed",
    "executable_materials_used",
    "executable_material_used",
    "executable_use_allowed",
    "use_allowed",
    "allow_use"
  )) {
    Assert-FalseProperty -Object $Object -PropertyName $propertyName -Context $Context
  }
}

function Assert-ContainsAll {
  param(
    [object[]]$Actual,
    [string[]]$Required,
    [string]$Name
  )

  $actualStrings = @($Actual | ForEach-Object { "$_" })
  foreach ($requiredValue in $Required) {
    if ($actualStrings -notcontains $requiredValue) {
      Mark-Fail "$Name`_MISSING=$requiredValue"
    }
  }
}

$StepId = "PHASE136_IMPORT_MANUAL_MATERIAL_SCOUT_PASS_TO_CATALOG_V1"
$RunId = "PHASE136_MATERIAL_GOVERNANCE_SERIES_001"
$NextAllowed = "PHASE137_BUILD_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_V1"
$PreviousStep = "PHASE135_RUN_MANUAL_MATERIAL_SCOUT_PASS_001_V1"

$ScoutPath = "materials/MANUAL_SCOUT_PASS_001.json"
$PreviousProofPath = "proofs/self_development/${PreviousStep}.json"
$CatalogPath = "materials/MATERIAL_CATALOG.json"
$QuarantineRegisterPath = "materials/MATERIAL_QUARANTINE_REGISTER.json"
$UsePolicyPath = "materials/MATERIAL_USE_POLICY.json"
$EvaluationQueuePath = "materials/MATERIAL_EVALUATION_QUEUE.json"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/MATERIAL_GOVERNANCE_SERIES_OUTPUT.json"
$WrongOutputPath = "self_build_batch/autonomy_trials/$StepId/MATERIAL_GOVERNANCE_SERIES_001_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$RuntimeLogPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RUNTIME_LOG.txt"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($p in @(
  "modules/invoke_material_governance_series_001.ps1",
  "orchestrator/run.ps1",
  $ScoutPath,
  $PreviousProofPath,
  $CatalogPath,
  $QuarantineRegisterPath,
  $UsePolicyPath,
  $EvaluationQueuePath,
  $OutputPath,
  $ResultPath,
  $RuntimeLogPath,
  $ReportPath,
  $ProofPath
)) {
  if (-not (Test-Path -LiteralPath $p)) {
    Mark-Fail "MISSING=$p"
  } else {
    Write-Output "EXISTS=$p"
  }
}

if (Test-Path -LiteralPath $WrongOutputPath) {
  Mark-Fail "WRONG_OUTPUT_PATH_STILL_EXISTS=$WrongOutputPath"
} else {
  Write-Output "WRONG_OUTPUT_PATH_ABSENT=$WrongOutputPath"
}

$Scout = Read-JsonOrFail -Path $ScoutPath
$PreviousProof = Read-JsonOrFail -Path $PreviousProofPath
$Catalog = Read-JsonOrFail -Path $CatalogPath
$QuarantineRegister = Read-JsonOrFail -Path $QuarantineRegisterPath
$UsePolicy = Read-JsonOrFail -Path $UsePolicyPath
$EvaluationQueue = Read-JsonOrFail -Path $EvaluationQueuePath
$Output = Read-JsonOrFail -Path $OutputPath
$Result = Read-JsonOrFail -Path $ResultPath
$Report = Read-JsonOrFail -Path $ReportPath
$Proof = Read-JsonOrFail -Path $ProofPath
$Queue = Read-JsonOrFail -Path "TASK_QUEUE.json"

try {
  $RuntimeLog = Get-Content -LiteralPath $RuntimeLogPath -Raw
  foreach ($requiredSignal in @(
    "MATERIAL_GOVERNANCE_SERIES=PHASE136_MATERIAL_GOVERNANCE_SERIES_001",
    "MATERIAL_GOVERNANCE_SERIES_STATUS=PASS",
    "MATERIAL_IMPORTED_COUNT=4",
    "MATERIAL_CANDIDATE_COUNT=3",
    "MATERIAL_REFERENCE_ONLY_COUNT=1",
    "MATERIAL_TRUSTED_COUNT=0",
    "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
    "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
    "MATERIAL_EXECUTABLE_USED=False",
    "MATERIAL_GOVERNANCE_NEXT_STEP=PHASE137_BUILD_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_V1",
    "STATUS=PASS_STOPPED_MATERIAL_GOVERNANCE_SERIES_BUILT"
  )) {
    if ($RuntimeLog -notmatch [regex]::Escape($requiredSignal)) {
      Mark-Fail "RUNTIME_LOG_SIGNAL_MISSING=$requiredSignal"
    } else {
      Write-Output "RUNTIME_LOG_SIGNAL_PRESENT=$requiredSignal"
    }
  }
} catch {
  Mark-Fail "RUNTIME_LOG_READ_FAIL=$($_.Exception.Message)"
}

try {
  $Branch = (git rev-parse --abbrev-ref HEAD).Trim()
  Write-Output "GIT_BRANCH=$Branch"
  if ($Branch -eq "main") {
    Mark-Fail "MAIN_BRANCH_ACTIVE"
  }
} catch {
  Mark-Fail "GIT_BRANCH_READ_FAIL=$($_.Exception.Message)"
}

if ($null -ne $PreviousProof) {
  Write-Output "PREVIOUS_PROOF_STATUS=$($PreviousProof.status)"
  Write-Output "PREVIOUS_PROOF_NEXT=$($PreviousProof.next_allowed_step)"
  Assert-Equals -Actual $PreviousProof.status -Expected "PASS" -Name "PREVIOUS_PROOF_STATUS"
  Assert-Equals -Actual $PreviousProof.next_allowed_step -Expected $StepId -Name "PREVIOUS_PROOF_NEXT_ALLOWED_STEP"
}

if ($null -ne $Scout) {
  Assert-Equals -Actual $Scout.status -Expected "PASS" -Name "SCOUT_STATUS"
  Assert-Equals -Actual $Scout.next_allowed_step -Expected $StepId -Name "SCOUT_NEXT_ALLOWED_STEP"
  Assert-Equals -Actual $Scout.candidate_material_count -Expected 3 -Name "SCOUT_CANDIDATE_COUNT"
  Assert-Equals -Actual $Scout.reference_only_material_count -Expected 1 -Name "SCOUT_REFERENCE_ONLY_COUNT"
  Assert-Equals -Actual $Scout.trusted_material_count -Expected 0 -Name "SCOUT_TRUSTED_COUNT"
  Assert-NoForbiddenActionFlags -Object $Scout -Context "SCOUT"
}

$CatalogMaterials = @()
$CandidateMaterials = @()
$ReferenceOnlyMaterials = @()
if ($null -ne $Catalog) {
  $CatalogMaterials = As-Array -Value $Catalog.materials
  $CandidateMaterials = @($CatalogMaterials | Where-Object { $_.status -eq "CANDIDATE" -or $_.initial_status -eq "CANDIDATE" })
  $ReferenceOnlyMaterials = @($CatalogMaterials | Where-Object { $_.status -eq "REFERENCE_ONLY" -or $_.initial_status -eq "REFERENCE_ONLY" })

  Write-Output "CATALOG_STATUS=$($Catalog.status)"
  Write-Output "CATALOG_MATERIAL_COUNT=$(@($CatalogMaterials).Count)"
  Write-Output "CATALOG_CANDIDATE_COUNT=$(@($CandidateMaterials).Count)"
  Write-Output "CATALOG_REFERENCE_ONLY_COUNT=$(@($ReferenceOnlyMaterials).Count)"
  Write-Output "CATALOG_TRUSTED_COUNT=$($Catalog.trusted_material_count)"

  Assert-Equals -Actual $Catalog.status -Expected "GOVERNED_IMPORTED" -Name "CATALOG_STATUS"
  Assert-Equals -Actual @($CatalogMaterials).Count -Expected 4 -Name "CATALOG_MATERIAL_COUNT"
  Assert-Equals -Actual $Catalog.material_count -Expected 4 -Name "CATALOG_REPORTED_MATERIAL_COUNT"
  Assert-Equals -Actual $Catalog.imported_material_count -Expected 4 -Name "CATALOG_IMPORTED_MATERIAL_COUNT"
  Assert-Equals -Actual @($CandidateMaterials).Count -Expected 3 -Name "CATALOG_CANDIDATE_COUNT"
  Assert-Equals -Actual @($ReferenceOnlyMaterials).Count -Expected 1 -Name "CATALOG_REFERENCE_ONLY_COUNT"
  Assert-Equals -Actual $Catalog.trusted_material_count -Expected 0 -Name "CATALOG_TRUSTED_COUNT"
  Assert-Equals -Actual $Catalog.default_allow -Expected $false -Name "CATALOG_DEFAULT_ALLOW"
  Assert-Equals -Actual $Catalog.next_allowed_step -Expected $NextAllowed -Name "CATALOG_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenActionFlags -Object $Catalog -Context "CATALOG"

  $Ids = @{}
  foreach ($material in $CatalogMaterials) {
    $materialId = "$($material.material_id)"
    if ([string]::IsNullOrWhiteSpace($materialId)) {
      Mark-Fail "CATALOG_MATERIAL_ID_MISSING"
    }
    if ($Ids.ContainsKey($materialId)) {
      Mark-Fail "CATALOG_DUPLICATE_MATERIAL_ID=$materialId"
    }
    $Ids[$materialId] = $true

    Assert-NoForbiddenMaterialState -Object $material -Context "CATALOG_MATERIAL"
    Assert-NoForbiddenActionFlags -Object $material -Context "CATALOG_MATERIAL_$materialId"
    Assert-Equals -Actual $material.use_allowed -Expected $false -Name "CATALOG_MATERIAL_USE_ALLOWED_$materialId"
    Assert-Equals -Actual $material.owner_decision_required -Expected $true -Name "CATALOG_MATERIAL_OWNER_DECISION_$materialId"
  }
}

if ($null -ne $QuarantineRegister) {
  $QuarantineEntries = As-Array -Value $QuarantineRegister.entries
  Write-Output "QUARANTINE_REGISTER_STATUS=$($QuarantineRegister.status)"
  Write-Output "QUARANTINE_REGISTER_ENTRY_COUNT=$(@($QuarantineEntries).Count)"

  Assert-Equals -Actual @($QuarantineEntries).Count -Expected 4 -Name "QUARANTINE_REGISTER_ENTRY_COUNT"
  Assert-Equals -Actual $QuarantineRegister.trusted_material_count -Expected 0 -Name "QUARANTINE_REGISTER_TRUSTED_COUNT"
  Assert-Equals -Actual $QuarantineRegister.next_allowed_step -Expected $NextAllowed -Name "QUARANTINE_REGISTER_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenActionFlags -Object $QuarantineRegister -Context "QUARANTINE_REGISTER"

  foreach ($entry in $QuarantineEntries) {
    $materialId = "$($entry.material_id)"
    Assert-NoForbiddenMaterialState -Object $entry -Context "QUARANTINE_ENTRY"
    Assert-NoForbiddenActionFlags -Object $entry -Context "QUARANTINE_ENTRY_$materialId"

    $catalogMatch = @($CatalogMaterials | Where-Object { $_.material_id -eq $materialId } | Select-Object -First 1)
    if (@($catalogMatch).Count -eq 0) {
      Mark-Fail "QUARANTINE_ENTRY_NOT_IN_CATALOG=$materialId"
      continue
    }

    $catalogStatus = "$($catalogMatch[0].status)"
    if ($catalogStatus -eq "CANDIDATE") {
      Assert-Equals -Actual $entry.quarantine_decision -Expected "QUARANTINE_REQUIRED" -Name "QUARANTINE_DECISION_$materialId"
    }
    if ($catalogStatus -eq "REFERENCE_ONLY") {
      Assert-Equals -Actual $entry.quarantine_decision -Expected "REFERENCE_ONLY_NOT_EXECUTABLE" -Name "QUARANTINE_DECISION_$materialId"
    }
  }
}

if ($null -ne $UsePolicy) {
  $RequiredUseGates = @(
    "OWNER_APPROVAL",
    "LICENSE_PROVENANCE_REVIEW",
    "QUARANTINE",
    "WRAPPER_DECISION",
    "SMOKE_TEST"
  )
  $PolicyRules = As-Array -Value $UsePolicy.material_rules

  Write-Output "USE_POLICY_STATUS=$($UsePolicy.status)"
  Write-Output "USE_POLICY_DEFAULT_ALLOW=$($UsePolicy.default_allow)"
  Write-Output "USE_POLICY_TRUSTED_COUNT=$($UsePolicy.trusted_material_count)"
  Write-Output "USE_POLICY_RULE_COUNT=$(@($PolicyRules).Count)"

  Assert-Equals -Actual $UsePolicy.default_allow -Expected $false -Name "USE_POLICY_DEFAULT_ALLOW"
  Assert-Equals -Actual $UsePolicy.trusted_material_count -Expected 0 -Name "USE_POLICY_TRUSTED_COUNT"
  Assert-Equals -Actual @($PolicyRules).Count -Expected 4 -Name "USE_POLICY_RULE_COUNT"
  Assert-Equals -Actual $UsePolicy.next_allowed_step -Expected $NextAllowed -Name "USE_POLICY_NEXT_ALLOWED_STEP"
  Assert-ContainsAll -Actual (As-Array -Value $UsePolicy.no_material_can_be_used_until) -Required $RequiredUseGates -Name "USE_POLICY_REQUIRED_GATES"
  Assert-NoForbiddenActionFlags -Object $UsePolicy -Context "USE_POLICY"

  foreach ($rule in $PolicyRules) {
    $materialId = "$($rule.material_id)"
    Assert-NoForbiddenMaterialState -Object $rule -Context "USE_POLICY_RULE"
    Assert-NoForbiddenActionFlags -Object $rule -Context "USE_POLICY_RULE_$materialId"
    Assert-Equals -Actual $rule.allow_use -Expected $false -Name "USE_POLICY_RULE_ALLOW_USE_$materialId"
    Assert-Equals -Actual $rule.owner_approval_required -Expected $true -Name "USE_POLICY_RULE_OWNER_APPROVAL_$materialId"
    Assert-Equals -Actual $rule.license_provenance_review_required -Expected $true -Name "USE_POLICY_RULE_LICENSE_REVIEW_$materialId"
    Assert-Equals -Actual $rule.quarantine_required -Expected $true -Name "USE_POLICY_RULE_QUARANTINE_REQUIRED_$materialId"
    Assert-Equals -Actual $rule.wrapper_decision_required -Expected $true -Name "USE_POLICY_RULE_WRAPPER_DECISION_$materialId"
    Assert-Equals -Actual $rule.smoke_test_required -Expected $true -Name "USE_POLICY_RULE_SMOKE_TEST_$materialId"
  }
}

if ($null -ne $EvaluationQueue) {
  $QueueItems = As-Array -Value $EvaluationQueue.materials
  $LegacyQueueItems = As-Array -Value $EvaluationQueue.queue_items
  $ExcludedReferenceOnly = As-Array -Value $EvaluationQueue.excluded_reference_only_materials
  $QueueItemIds = @($QueueItems | ForEach-Object { "$($_.material_id)" })
  $ReferenceOnlyIds = @($ReferenceOnlyMaterials | ForEach-Object { "$($_.material_id)" })

  Write-Output "EVALUATION_QUEUE_STATUS=$($EvaluationQueue.status)"
  Write-Output "EVALUATION_QUEUE_ITEM_COUNT=$(@($QueueItems).Count)"
  Write-Output "EVALUATION_QUEUE_EXCLUDED_REFERENCE_ONLY_COUNT=$(@($ExcludedReferenceOnly).Count)"

  Assert-Equals -Actual $EvaluationQueue.status -Expected "READY_FOR_BOUNDED_EVALUATION" -Name "EVALUATION_QUEUE_STATUS"
  Assert-Equals -Actual @($QueueItems).Count -Expected 3 -Name "EVALUATION_QUEUE_ITEM_COUNT"
  if (@($LegacyQueueItems).Count -gt 0) {
    Assert-Equals -Actual @($LegacyQueueItems).Count -Expected 3 -Name "EVALUATION_QUEUE_LEGACY_QUEUE_ITEMS_COUNT"
  }
  Assert-Equals -Actual $EvaluationQueue.candidate_material_count -Expected 3 -Name "EVALUATION_QUEUE_CANDIDATE_COUNT"
  Assert-Equals -Actual $EvaluationQueue.executable_evaluation_count -Expected 3 -Name "EVALUATION_QUEUE_EXECUTABLE_EVALUATION_COUNT"
  Assert-Equals -Actual $EvaluationQueue.reference_only_excluded_count -Expected 1 -Name "EVALUATION_QUEUE_REFERENCE_ONLY_EXCLUDED_COUNT"
  Assert-Equals -Actual $EvaluationQueue.trusted_material_count -Expected 0 -Name "EVALUATION_QUEUE_TRUSTED_COUNT"
  Assert-Equals -Actual $EvaluationQueue.next_allowed_step -Expected $NextAllowed -Name "EVALUATION_QUEUE_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenActionFlags -Object $EvaluationQueue -Context "EVALUATION_QUEUE"

  foreach ($item in $QueueItems) {
    $materialId = "$($item.material_id)"
    Assert-NoForbiddenMaterialState -Object $item -Context "EVALUATION_QUEUE_ITEM"
    Assert-NoForbiddenActionFlags -Object $item -Context "EVALUATION_QUEUE_ITEM_$materialId"
    Assert-Equals -Actual $item.status -Expected "READY_FOR_BOUNDED_EVALUATION" -Name "EVALUATION_QUEUE_ITEM_STATUS_$materialId"
    if ($ReferenceOnlyIds -contains $materialId) {
      Mark-Fail "REFERENCE_ONLY_IN_EXECUTABLE_EVALUATION_QUEUE=$materialId"
    }
  }

  foreach ($referenceId in $ReferenceOnlyIds) {
    if ($QueueItemIds -contains $referenceId) {
      Mark-Fail "REFERENCE_ONLY_MATERIAL_APPEARS_IN_QUEUE=$referenceId"
    }
  }
}

foreach ($artifactSpec in @(
  @{ Name = "OUTPUT"; Object = $Output },
  @{ Name = "RESULT"; Object = $Result },
  @{ Name = "REPORT"; Object = $Report },
  @{ Name = "PROOF"; Object = $Proof }
)) {
  $artifactName = $artifactSpec.Name
  $artifact = $artifactSpec.Object
  if ($null -eq $artifact) {
    continue
  }

  Write-Output "$artifactName`_STATUS=$($artifact.status)"
  Write-Output "$artifactName`_NEXT_ALLOWED_STEP=$($artifact.next_allowed_step)"
  Assert-Equals -Actual $artifact.status -Expected "PASS" -Name "$artifactName`_STATUS"
  Assert-Equals -Actual $artifact.next_allowed_step -Expected $NextAllowed -Name "$artifactName`_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenActionFlags -Object $artifact -Context $artifactName
  if (Test-PropertyExists -Object $artifact -Name "output_path") {
    Assert-Equals -Actual $artifact.output_path -Expected $OutputPath -Name "$artifactName`_OUTPUT_PATH"
  }

  if (Test-PropertyExists -Object $artifact -Name "imported_material_count") {
    Assert-Equals -Actual $artifact.imported_material_count -Expected 4 -Name "$artifactName`_IMPORTED_MATERIAL_COUNT"
  }
  if (Test-PropertyExists -Object $artifact -Name "candidate_material_count") {
    Assert-Equals -Actual $artifact.candidate_material_count -Expected 3 -Name "$artifactName`_CANDIDATE_MATERIAL_COUNT"
  }
  if (Test-PropertyExists -Object $artifact -Name "reference_only_material_count") {
    Assert-Equals -Actual $artifact.reference_only_material_count -Expected 1 -Name "$artifactName`_REFERENCE_ONLY_MATERIAL_COUNT"
  }
  if (Test-PropertyExists -Object $artifact -Name "trusted_material_count") {
    Assert-Equals -Actual $artifact.trusted_material_count -Expected 0 -Name "$artifactName`_TRUSTED_MATERIAL_COUNT"
  }
}

if ($null -ne $Proof) {
  Assert-Equals -Actual $Proof.runtime_executed -Expected $true -Name "PROOF_RUNTIME_EXECUTED"
  Assert-Equals -Actual $Proof.builder_runtime_invoked -Expected $true -Name "PROOF_BUILDER_RUNTIME_INVOKED"
  Assert-Equals -Actual $Proof.imported_material_count -Expected 4 -Name "PROOF_IMPORTED_MATERIAL_COUNT"
  Assert-Equals -Actual $Proof.candidate_material_count -Expected 3 -Name "PROOF_CANDIDATE_MATERIAL_COUNT"
  Assert-Equals -Actual $Proof.reference_only_material_count -Expected 1 -Name "PROOF_REFERENCE_ONLY_MATERIAL_COUNT"
  Assert-Equals -Actual $Proof.trusted_material_count -Expected 0 -Name "PROOF_TRUSTED_MATERIAL_COUNT"
  Assert-Equals -Actual $Proof.external_fetch_performed -Expected $false -Name "PROOF_EXTERNAL_FETCH_PERFORMED"
  Assert-Equals -Actual $Proof.dependency_install_performed -Expected $false -Name "PROOF_DEPENDENCY_INSTALL_PERFORMED"
  Assert-Equals -Actual $Proof.executable_materials_used -Expected $false -Name "PROOF_EXECUTABLE_MATERIALS_USED"
  Assert-Equals -Actual $Proof.queue_after -Expected "NONE" -Name "PROOF_QUEUE_AFTER"
  Assert-Equals -Actual $Proof.codex_used -Expected $false -Name "PROOF_CODEX_USED"
  Assert-Equals -Actual $Proof.main_touched -Expected $false -Name "PROOF_MAIN_TOUCHED"
}

if ($null -ne $Result) {
  Assert-Equals -Actual $Result.runtime_executed -Expected $true -Name "RESULT_RUNTIME_EXECUTED"
  Assert-Equals -Actual $Result.builder_runtime_invoked -Expected $true -Name "RESULT_BUILDER_RUNTIME_INVOKED"
  Assert-Equals -Actual $Result.queue_after -Expected "NONE" -Name "RESULT_QUEUE_AFTER"
}

if ($null -ne $Queue) {
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"
  Assert-Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "TASK_QUEUE_ACTIVE_TASK_ID"
}

if ($Ok -eq $true) {
  Write-Output "PHASE136_MATERIAL_GOVERNANCE_SERIES_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE136_MATERIAL_GOVERNANCE_SERIES_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE136 validation failed."
}
