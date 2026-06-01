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
    "executable_used",
    "executable_use_allowed",
    "use_allowed",
    "allow_use",
    "trusted",
    "reference_only_evaluated_as_executable"
  )) {
    Assert-FalseProperty -Object $Object -PropertyName $propertyName -Context $Context
  }
}

function Assert-RequiredRecordFields {
  param(
    [object]$Record,
    [string]$Context
  )

  foreach ($field in @(
    "material_id",
    "name",
    "evaluation_status",
    "external_fetch_performed",
    "dependency_install_performed",
    "executable_used",
    "trusted",
    "owner_decision_required",
    "license_review_required",
    "provenance_review_required",
    "wrapper_required_before_use",
    "smoke_test_required_before_trust",
    "recommended_next_action"
  )) {
    if (-not (Test-PropertyExists -Object $Record -Name $field)) {
      Mark-Fail "$Context`_MISSING_FIELD=$field"
    }
  }
}

$StepId = "PHASE137_BUILD_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_V1"
$RunId = "PHASE137_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_001"
$PreviousStepId = "PHASE136_IMPORT_MANUAL_MATERIAL_SCOUT_PASS_TO_CATALOG_V1"
$NextAllowed = "PHASE138_OWNER_DECISION_FOR_FIRST_MATERIAL_ADOPTION_V1"
$ReferenceOnlyMaterialId = "reference_json_schema_official"
$ExpectedMaterialIds = @(
  "candidate_pester_powershell_test_framework",
  "candidate_psscriptanalyzer_static_checker",
  "candidate_syft_sbom_cli"
)

$PreviousProofPath = "proofs/self_development/${PreviousStepId}.json"
$EvaluationQueuePath = "materials/MATERIAL_EVALUATION_QUEUE.json"
$QuarantineRegisterPath = "materials/MATERIAL_QUARANTINE_REGISTER.json"
$EvaluationResultsPath = "materials/MATERIAL_QUARANTINE_EVALUATION_RESULTS.json"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/MATERIAL_QUARANTINE_EVALUATION_RUNTIME_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$RuntimeLogPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RUNTIME_LOG.txt"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($p in @(
  "modules/invoke_material_quarantine_evaluation_runtime_001.ps1",
  "orchestrator/run.ps1",
  $PreviousProofPath,
  $EvaluationQueuePath,
  $QuarantineRegisterPath,
  $EvaluationResultsPath,
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

$PreviousProof = Read-JsonOrFail -Path $PreviousProofPath
$EvaluationQueue = Read-JsonOrFail -Path $EvaluationQueuePath
$QuarantineRegister = Read-JsonOrFail -Path $QuarantineRegisterPath
$EvaluationResults = Read-JsonOrFail -Path $EvaluationResultsPath
$Output = Read-JsonOrFail -Path $OutputPath
$Result = Read-JsonOrFail -Path $ResultPath
$Report = Read-JsonOrFail -Path $ReportPath
$Proof = Read-JsonOrFail -Path $ProofPath
$Queue = Read-JsonOrFail -Path "TASK_QUEUE.json"

try {
  $RuntimeLog = Get-Content -LiteralPath $RuntimeLogPath -Raw
  foreach ($requiredSignal in @(
    "MATERIAL_QUARANTINE_EVALUATION_RUNTIME=PHASE137_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_001",
    "MATERIAL_QUARANTINE_EVALUATION_STATUS=PASS",
    "MATERIAL_EVALUATED_COUNT=3",
    "MATERIAL_TRUSTED_COUNT=0",
    "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
    "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
    "MATERIAL_EXECUTABLE_USED=False",
    "MATERIAL_REFERENCE_ONLY_EVALUATED_AS_EXECUTABLE=False",
    "MATERIAL_OWNER_DECISION_REQUIRED_COUNT=3",
    "MATERIAL_QUARANTINE_NEXT_STEP=PHASE138_OWNER_DECISION_FOR_FIRST_MATERIAL_ADOPTION_V1",
    "STATUS=PASS_STOPPED_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_BUILT"
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
  Assert-Equals -Actual $PreviousProof.trusted_material_count -Expected 0 -Name "PREVIOUS_PROOF_TRUSTED_COUNT"
  Assert-NoForbiddenActionFlags -Object $PreviousProof -Context "PREVIOUS_PROOF"
}

$QueueMaterials = @()
if ($null -ne $EvaluationQueue) {
  $QueueMaterials = As-Array -Value $EvaluationQueue.materials
  $QueueMaterialIds = @($QueueMaterials | ForEach-Object { "$($_.material_id)" })

  Write-Output "EVALUATION_QUEUE_STATUS=$($EvaluationQueue.status)"
  Write-Output "EVALUATION_QUEUE_MATERIAL_COUNT=$(@($QueueMaterials).Count)"
  Write-Output "EVALUATION_QUEUE_TRUSTED_COUNT=$($EvaluationQueue.trusted_material_count)"

  Assert-Equals -Actual $EvaluationQueue.status -Expected "METADATA_EVALUATED_AWAITING_OWNER_DECISION" -Name "EVALUATION_QUEUE_STATUS"
  Assert-Equals -Actual @($QueueMaterials).Count -Expected 3 -Name "EVALUATION_QUEUE_MATERIAL_COUNT"
  Assert-Equals -Actual $EvaluationQueue.candidate_material_count -Expected 3 -Name "EVALUATION_QUEUE_CANDIDATE_COUNT"
  Assert-Equals -Actual $EvaluationQueue.reference_only_excluded_count -Expected 1 -Name "EVALUATION_QUEUE_REFERENCE_ONLY_EXCLUDED_COUNT"
  Assert-Equals -Actual $EvaluationQueue.trusted_material_count -Expected 0 -Name "EVALUATION_QUEUE_TRUSTED_COUNT"
  Assert-Equals -Actual $EvaluationQueue.next_allowed_step -Expected $NextAllowed -Name "EVALUATION_QUEUE_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenActionFlags -Object $EvaluationQueue -Context "EVALUATION_QUEUE"

  foreach ($materialId in $ExpectedMaterialIds) {
    if ($QueueMaterialIds -notcontains $materialId) {
      Mark-Fail "EVALUATION_QUEUE_MISSING_CANDIDATE=$materialId"
    }
  }
  if ($QueueMaterialIds -contains $ReferenceOnlyMaterialId) {
    Mark-Fail "REFERENCE_ONLY_IN_EVALUATION_QUEUE_MATERIALS=$ReferenceOnlyMaterialId"
  }
}

if ($null -ne $EvaluationResults) {
  $Records = As-Array -Value $EvaluationResults.records
  $RecordIds = @($Records | ForEach-Object { "$($_.material_id)" })

  Write-Output "EVALUATION_RESULTS_STATUS=$($EvaluationResults.status)"
  Write-Output "EVALUATION_RESULTS_RECORD_COUNT=$(@($Records).Count)"
  Write-Output "EVALUATION_RESULTS_TRUSTED_COUNT=$($EvaluationResults.trusted_material_count)"

  Assert-Equals -Actual $EvaluationResults.status -Expected "PASS" -Name "EVALUATION_RESULTS_STATUS"
  Assert-Equals -Actual @($Records).Count -Expected 3 -Name "EVALUATION_RESULTS_RECORD_COUNT"
  Assert-Equals -Actual $EvaluationResults.evaluated_material_count -Expected 3 -Name "EVALUATION_RESULTS_EVALUATED_COUNT"
  Assert-Equals -Actual $EvaluationResults.trusted_material_count -Expected 0 -Name "EVALUATION_RESULTS_TRUSTED_COUNT"
  Assert-Equals -Actual $EvaluationResults.owner_decision_required_count -Expected 3 -Name "EVALUATION_RESULTS_OWNER_DECISION_COUNT"
  Assert-Equals -Actual $EvaluationResults.next_allowed_step -Expected $NextAllowed -Name "EVALUATION_RESULTS_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenActionFlags -Object $EvaluationResults -Context "EVALUATION_RESULTS"

  foreach ($materialId in $ExpectedMaterialIds) {
    if ($RecordIds -notcontains $materialId) {
      Mark-Fail "EVALUATION_RESULTS_MISSING_CANDIDATE=$materialId"
    }
  }
  if ($RecordIds -contains $ReferenceOnlyMaterialId) {
    Mark-Fail "REFERENCE_ONLY_IN_EVALUATION_RESULTS=$ReferenceOnlyMaterialId"
  }

  foreach ($record in $Records) {
    $materialId = "$($record.material_id)"
    Assert-RequiredRecordFields -Record $record -Context "EVALUATION_RECORD_$materialId"
    Assert-Equals -Actual $record.evaluation_status -Expected "QUARANTINE_EVALUATED_METADATA_ONLY" -Name "EVALUATION_RECORD_STATUS_$materialId"
    Assert-Equals -Actual $record.owner_decision_required -Expected $true -Name "EVALUATION_RECORD_OWNER_DECISION_$materialId"
    Assert-Equals -Actual $record.license_review_required -Expected $true -Name "EVALUATION_RECORD_LICENSE_REVIEW_$materialId"
    Assert-Equals -Actual $record.provenance_review_required -Expected $true -Name "EVALUATION_RECORD_PROVENANCE_REVIEW_$materialId"
    Assert-Equals -Actual $record.wrapper_required_before_use -Expected $true -Name "EVALUATION_RECORD_WRAPPER_REQUIRED_$materialId"
    Assert-Equals -Actual $record.smoke_test_required_before_trust -Expected $true -Name "EVALUATION_RECORD_SMOKE_TEST_REQUIRED_$materialId"
    Assert-NoForbiddenActionFlags -Object $record -Context "EVALUATION_RECORD_$materialId"
  }
}

if ($null -ne $QuarantineRegister) {
  $RegisterEntries = As-Array -Value $QuarantineRegister.entries
  Write-Output "QUARANTINE_REGISTER_STATUS=$($QuarantineRegister.status)"
  Write-Output "QUARANTINE_REGISTER_EVALUATED_COUNT=$($QuarantineRegister.evaluated_candidate_material_count)"

  Assert-Equals -Actual $QuarantineRegister.status -Expected "METADATA_EVALUATED_AWAITING_OWNER_DECISION" -Name "QUARANTINE_REGISTER_STATUS"
  Assert-Equals -Actual $QuarantineRegister.evaluated_candidate_material_count -Expected 3 -Name "QUARANTINE_REGISTER_EVALUATED_COUNT"
  Assert-Equals -Actual $QuarantineRegister.trusted_material_count -Expected 0 -Name "QUARANTINE_REGISTER_TRUSTED_COUNT"
  Assert-Equals -Actual $QuarantineRegister.next_allowed_step -Expected $NextAllowed -Name "QUARANTINE_REGISTER_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenActionFlags -Object $QuarantineRegister -Context "QUARANTINE_REGISTER"

  foreach ($materialId in $ExpectedMaterialIds) {
    $Entry = @($RegisterEntries | Where-Object { $_.material_id -eq $materialId } | Select-Object -First 1)
    if (@($Entry).Count -ne 1) {
      Mark-Fail "QUARANTINE_REGISTER_MISSING_CANDIDATE=$materialId"
      continue
    }

    Assert-Equals -Actual $Entry[0].quarantine_decision -Expected "QUARANTINE_REQUIRED" -Name "QUARANTINE_REGISTER_DECISION_$materialId"
    Assert-Equals -Actual $Entry[0].quarantine_status -Expected "METADATA_EVALUATED_AWAITING_OWNER_DECISION" -Name "QUARANTINE_REGISTER_STATUS_$materialId"
    Assert-NoForbiddenActionFlags -Object $Entry[0] -Context "QUARANTINE_REGISTER_ENTRY_$materialId"
  }

  $ReferenceEntry = @($RegisterEntries | Where-Object { $_.material_id -eq $ReferenceOnlyMaterialId } | Select-Object -First 1)
  if (@($ReferenceEntry).Count -eq 1) {
    Assert-Equals -Actual $ReferenceEntry[0].quarantine_decision -Expected "REFERENCE_ONLY_NOT_EXECUTABLE" -Name "QUARANTINE_REGISTER_REFERENCE_DECISION"
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

  if (Test-PropertyExists -Object $artifact -Name "evaluated_material_count") {
    Assert-Equals -Actual $artifact.evaluated_material_count -Expected 3 -Name "$artifactName`_EVALUATED_MATERIAL_COUNT"
  }
  if (Test-PropertyExists -Object $artifact -Name "trusted_material_count") {
    Assert-Equals -Actual $artifact.trusted_material_count -Expected 0 -Name "$artifactName`_TRUSTED_MATERIAL_COUNT"
  }
  if (Test-PropertyExists -Object $artifact -Name "owner_decision_required_count") {
    Assert-Equals -Actual $artifact.owner_decision_required_count -Expected 3 -Name "$artifactName`_OWNER_DECISION_COUNT"
  }
}

if ($null -ne $Proof) {
  Assert-Equals -Actual $Proof.runtime_executed -Expected $true -Name "PROOF_RUNTIME_EXECUTED"
  Assert-Equals -Actual $Proof.builder_runtime_invoked -Expected $true -Name "PROOF_BUILDER_RUNTIME_INVOKED"
  Assert-Equals -Actual $Proof.evaluated_material_count -Expected 3 -Name "PROOF_EVALUATED_MATERIAL_COUNT"
  Assert-Equals -Actual $Proof.trusted_material_count -Expected 0 -Name "PROOF_TRUSTED_MATERIAL_COUNT"
  Assert-Equals -Actual $Proof.external_fetch_performed -Expected $false -Name "PROOF_EXTERNAL_FETCH_PERFORMED"
  Assert-Equals -Actual $Proof.dependency_install_performed -Expected $false -Name "PROOF_DEPENDENCY_INSTALL_PERFORMED"
  Assert-Equals -Actual $Proof.executable_materials_used -Expected $false -Name "PROOF_EXECUTABLE_MATERIALS_USED"
  Assert-Equals -Actual $Proof.reference_only_evaluated_as_executable -Expected $false -Name "PROOF_REFERENCE_ONLY_EVALUATED_AS_EXECUTABLE"
  Assert-Equals -Actual $Proof.owner_decision_required_count -Expected 3 -Name "PROOF_OWNER_DECISION_REQUIRED_COUNT"
  Assert-Equals -Actual $Proof.queue_after -Expected "NONE" -Name "PROOF_QUEUE_AFTER"
  Assert-Equals -Actual $Proof.codex_used -Expected $false -Name "PROOF_CODEX_USED"
  Assert-Equals -Actual $Proof.main_touched -Expected $false -Name "PROOF_MAIN_TOUCHED"
}

if ($null -ne $Queue) {
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"
  Assert-Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "TASK_QUEUE_ACTIVE_TASK_ID"
}

if ($Ok -eq $true) {
  Write-Output "PHASE137_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE137_MATERIAL_QUARANTINE_EVALUATION_RUNTIME_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE137 validation failed."
}
