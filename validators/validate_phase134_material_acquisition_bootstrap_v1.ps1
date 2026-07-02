$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

$StepId = "PHASE134_BUILD_MATERIAL_ACQUISITION_BOOTSTRAP_V1"
$NextAllowed = "PHASE135_RUN_MANUAL_MATERIAL_SCOUT_PASS_001_V1"

$BootstrapPath = "self_control/MATERIAL_ACQUISITION_BOOTSTRAP.json"
$CatalogPath = "materials/MATERIAL_CATALOG.json"
$TemplatePath = "materials/MANUAL_SCOUT_PASS_001_INPUT_TEMPLATE.json"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/MATERIAL_ACQUISITION_BOOTSTRAP_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($p in @(
  "modules/invoke_self_model_first_runtime_entrypoint.ps1",
  "modules/invoke_material_acquisition_bootstrap.ps1",
  "orchestrator/run.ps1",
  $BootstrapPath,
  $CatalogPath,
  $TemplatePath,
  $OutputPath,
  $ResultPath,
  $ReportPath,
  $ProofPath
)) {
  if (-not (Test-Path $p)) {
    Mark-Fail "MISSING=$p"
  } else {
    Write-Output "EXISTS=$p"
  }
}

try {
  $Bootstrap = Get-Content $BootstrapPath -Raw | ConvertFrom-Json
  $Catalog = Get-Content $CatalogPath -Raw | ConvertFrom-Json
  $Output = Get-Content $OutputPath -Raw | ConvertFrom-Json
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json

  Write-Output "BOOTSTRAP_STATUS=$($Bootstrap.status)"
  Write-Output "BOOTSTRAP_ID=$($Bootstrap.bootstrap_id)"
  Write-Output "BOOTSTRAP_DEFAULT_TRUST=$($Bootstrap.default_trust)"
  Write-Output "CATALOG_STATUS=$($Catalog.status)"
  Write-Output "CATALOG_TRUSTED_COUNT=$($Catalog.trusted_material_count)"
  Write-Output "OUTPUT_STATUS=$($Output.status)"
  Write-Output "OUTPUT_NEXT=$($Output.proposed_next_step)"
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"

  if ($Bootstrap.status -ne "PASS") { Mark-Fail "BOOTSTRAP_NOT_PASS" }
  if ($Bootstrap.bootstrap_id -ne "MATERIAL_ACQUISITION_BOOTSTRAP_V1") { Mark-Fail "BOOTSTRAP_ID_UNEXPECTED=$($Bootstrap.bootstrap_id)" }
  if ($Bootstrap.default_trust -ne $false) { Mark-Fail "BOOTSTRAP_DEFAULT_TRUST_NOT_FALSE" }
  if ($Bootstrap.external_fetch_performed -ne $false) { Mark-Fail "BOOTSTRAP_EXTERNAL_FETCH_TRUE" }
  if ($Bootstrap.dependency_install_performed -ne $false) { Mark-Fail "BOOTSTRAP_DEPENDENCY_INSTALL_TRUE" }
  if ($Catalog.status -ne "READY_FOR_MANUAL_SCOUT_PASS") { Mark-Fail "CATALOG_STATUS_UNEXPECTED=$($Catalog.status)" }
  if ($Catalog.trusted_material_count -ne 0) { Mark-Fail "CATALOG_TRUSTED_COUNT_NOT_ZERO=$($Catalog.trusted_material_count)" }
  if ($Catalog.next_allowed_step -ne $NextAllowed) { Mark-Fail "CATALOG_NEXT_UNEXPECTED=$($Catalog.next_allowed_step)" }
  if ($Output.status -ne "PASS") { Mark-Fail "OUTPUT_NOT_PASS" }
  if ($Output.bootstrap_created -ne $true) { Mark-Fail "OUTPUT_BOOTSTRAP_CREATED_NOT_TRUE" }
  if ($Output.proposed_next_step -ne $NextAllowed) { Mark-Fail "OUTPUT_NEXT_UNEXPECTED=$($Output.proposed_next_step)" }
  if ($Queue.active_task_id -ne "NONE") { Mark-Fail "QUEUE_NOT_NONE=$($Queue.active_task_id)" }
} catch {
  Mark-Fail "MATERIAL_BOOTSTRAP_VALIDATE_PARSE_FAIL=$($_.Exception.Message)"
}

foreach ($p in @($ResultPath,$ReportPath,$ProofPath)) {
  try {
    $obj = Get-Content $p -Raw | ConvertFrom-Json
    Write-Output "JSON_PARSE_PASS=$p"
    Write-Output "STATUS=$($obj.status)"
    Write-Output "NEXT_ALLOWED_STEP=$($obj.next_allowed_step)"

    if ($obj.status -ne "PASS") { Mark-Fail "OUTPUT_ARTIFACT_NOT_PASS=$p" }
    if ($obj.next_allowed_step -ne $NextAllowed) { Mark-Fail "OUTPUT_ARTIFACT_NEXT_UNEXPECTED=$p :: $($obj.next_allowed_step)" }
  } catch {
    Mark-Fail "JSON_PARSE_FAIL=$p :: $($_.Exception.Message)"
  }
}

if ($Ok -eq $true) {
  Write-Output "PHASE134_MATERIAL_ACQUISITION_BOOTSTRAP_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE134_MATERIAL_ACQUISITION_BOOTSTRAP_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE134 validation failed."
}
